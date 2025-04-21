" golf.vim - Play Golf challenges directly in Vim
" Author: Golf Plugin
" Version: 0.1

if exists('g:loaded_golf') || &cp
  finish
endif
let g:loaded_golf = 1

" Configuration options with defaults
if !exists('g:golf_data_dir')
  let g:golf_data_dir = expand('~/.golf')
endif

if !exists('g:golf_challenges_dir')
  let g:golf_challenges_dir = g:golf_data_dir . '/challenges'
endif

" Create data directories if they don't exist
function! s:EnsureDirectories()
  if !isdirectory(g:golf_data_dir)
    call mkdir(g:golf_data_dir, 'p')
  endif
  
  if !isdirectory(g:golf_challenges_dir)
    call mkdir(g:golf_challenges_dir, 'p')
  endif
endfunction

" Initialize the plugin
call s:EnsureDirectories()

" Command to play today's Golf challenge
command! -nargs=0 GolfToday call golf#PlayToday()

" Command to play a specific or random Golf challenge
" Usage:
"   :Golf             " Play random challenge (any difficulty)
"   :Golf <difficulty>" Play random challenge (easy/medium/hard)
"   :Golf tag <tag>   " Play random challenge by tag
"   :Golf date <YYYY-MM-DD> " Play challenge for a specific date
"   :Golf id <id>     " Play challenge with the specified ID
command! -nargs=* Golf call golf#DispatchGolfCommand(<f-args>) 