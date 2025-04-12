" vimgolf.vim - Play VimGolf challenges directly in Vim
" Author: VimGolf Plugin
" Version: 0.1

if exists('g:loaded_vimgolf') || &cp
  finish
endif
let g:loaded_vimgolf = 1

" Configuration options with defaults
if !exists('g:vimgolf_data_dir')
  let g:vimgolf_data_dir = expand('~/.vimgolf')
endif

if !exists('g:vimgolf_challenges_dir')
  let g:vimgolf_challenges_dir = g:vimgolf_data_dir . '/challenges'
endif

" Create data directories if they don't exist
function! s:EnsureDirectories()
  if !isdirectory(g:vimgolf_data_dir)
    call mkdir(g:vimgolf_data_dir, 'p')
  endif
  
  if !isdirectory(g:vimgolf_challenges_dir)
    call mkdir(g:vimgolf_challenges_dir, 'p')
  endif
endfunction

" Initialize the plugin
call s:EnsureDirectories()

" Command to play today's VimGolf challenge
command! -nargs=0 VimGolfToday call vimgolf#PlayToday()

" Command to verify solution
command! -nargs=0 VimGolfVerify call vimgolf#VerifySolution()

" Command to show target text
command! -nargs=0 VimGolfShowTarget call vimgolf#ShowTargetText()

" Command to copy the shareable summary
command! -nargs=0 VimGolfShareSummary call vimgolf#CopyShareableSummary() 