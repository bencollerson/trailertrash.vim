" trailertrash.vim - Trailer Trash
" Maintainer:   Christopher Sexton
"
" Ideas taken from numerous places like:
" http://vim.wikia.com/wiki/Highlight_unwanted_spaces
" http://vimcasts.org/episodes/tidying-whitespace/
" http://blog.kamil.dworakowski.name/2009/09/unobtrusive-highlighting-of-trailing.html
" and more!
"
" Options for extra whitespace checks can be enabled by adding these two lines
" to your .vimrc file:
"
" let g:trailertrash_embedded_tabs = 1
" let g:trailertrash_leading_spaces = 1

" Exit quickly when:
" - this plugin was already loaded (or disabled)
" - when 'compatible' is set
if exists("g:loaded_trailertrash") || &cp
  finish
endif
let g:loaded_trailertrash = 1

" Add some extra optional behaviours
let s:trailertrash_embedded_tabs   = exists('g:trailertrash_embedded_tabs') && g:trailertrash_embedded_tabs
let s:trailertrash_leading_spaces  = exists('g:trailertrash_leading_spaces') && g:trailertrash_leading_spaces

let s:cpo_save = &cpo
set cpo&vim

" Code {{{1

function! KillTrailerTrash()
    " Preparation: save last search, and cursor position.
    let _s=@/
    let l = line(".")
    let c = col(".")
    let expandtab = &expandtab
    " Do the business:

    " Remove trailing spaces
    execute (a:firstline) . "," . a:lastline . 's/\s\+$//e '

    if s:trailertrash_embedded_tabs
	" remove embedded tabs
	set expandtab
	execute (a:firstline) . "," . a:lastline . 'retab ' . &tabstop
	set noexpandtab
    endif

    if s:trailertrash_leading_spaces
	" fix up indenting
	execute (a:firstline) . "," . a:lastline . 'normal =='
    endif

    " Clean up: restore previous search history, and cursor position
    let &expandtab = expandtab
    let @/=_s
    call cursor(l, c)
endfunction

command! -bar -range=% Trim :<line1>,<line2>call KillTrailerTrash()
"nmap <silent> <Leader>sa :call KillTrailerTrash()<CR>

" User can override blacklist. This match as regexp pattern.
let s:blacklist = get(g:, 'trailertrash_blacklist', [
\ '__Calendar',
\])

function! s:TrailerMatch(pattern)
    if(&modifiable)
        let bufname = bufname('%')
        for ignore in s:blacklist
            if bufname =~ ignore
                return
            endif
        endfor
        exe "match" "UnwantedTrailerTrash" a:pattern
    endif
endfunction

" Create autocommand group
augroup TrailerTrash
augroup END

" Syntax
function! ShowTrailerTrash()
    if exists("g:show_trailertrash") && g:show_trailertrash == 1
        hi UnwantedTrailerTrash guifg=NONE guibg=NONE gui=NONE ctermfg=NONE ctermbg=NONE cterm=NONE
        au! TrailerTrash ColorScheme *
        let g:show_trailertrash = 0
    else
        hi link UnwantedTrailerTrash Error
        au TrailerTrash ColorScheme * hi link UnwantedTrailerTrash Error
        let g:show_trailertrash = 1
    end
endfunction
command Trailer :call ShowTrailerTrash()
call ShowTrailerTrash()
"nmap <silent> <Leader>s :call ShowTrailerTrash()<CR>

" various bits of regexes:
let s:REGEX_TRAILING_WHITESPACE        = '\s\+$'
let s:REGEX_TRAILING_WHITESPACE_INSERT = '\s\+\%#\@<!$'
let s:REGEX_EMBEDDED_TABS              = '[^\t]\zs\t\+\ze'
let s:REGEX_LEADING_SPACE              = '^ \+'

let s:search_patterns_normal = [ s:REGEX_TRAILING_WHITESPACE ]
let s:search_patterns_insert = [ s:REGEX_TRAILING_WHITESPACE_INSERT ]

if s:trailertrash_embedded_tabs
    let s:search_patterns_normal += [ s:REGEX_EMBEDDED_TABS ]
    let s:search_patterns_insert += [ s:REGEX_EMBEDDED_TABS ]
endif

if s:trailertrash_leading_spaces
    let s:search_patterns_normal += [ s:REGEX_LEADING_SPACE ]
    let s:search_patterns_insert += [ s:REGEX_LEADING_SPACE ]
endif

let s:regex_normal = '/\(' . join (s:search_patterns_normal, '\|') . '\)/'
let s:regex_insert = '/\(' . join (s:search_patterns_insert, '\|') . '\)/'

au BufEnter    * call s:TrailerMatch(s:regex_normal)
au InsertEnter * call s:TrailerMatch(s:regex_insert)
au InsertLeave * call s:TrailerMatch(s:regex_normal)

" }}}1

let &cpo = s:cpo_save

" vim:set ft=vim ts=8 sw=4 sts=4:
