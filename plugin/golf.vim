" golf.vim - Play Golf challenges directly in Vim
" Author: Golf Plugin
" Version: 0.1

if exists('g:loaded_golf') || &cp
  finish
endif
let g:loaded_golf = 1

" Configuration options with defaults
if !exists('g:golf_data_dir')
  if isdirectory(expand('$XDG_CACHE_HOME'))
    let g:golf_data_dir = expand('$XDG_CACHE_HOME/golf')
  elseif isdirectory(expand('~/.cache'))
    let g:golf_data_dir = expand('~/.cache/golf')
  else
    let g:golf_data_dir = expand('~/.golf')
  endif
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
command! -nargs=0 GolfToday 
      \ echohl WarningMsg |
      \ echo "Notice: GolfToday is deprecated and will be removed in a future version. Please use 'Golf today' instead." |
      \ echohl None |
      \ call golf#PlayToday()

" Command to play a specific or random Golf challenge
" Usage:
"   :Golf             " Play random challenge (any difficulty)
"   :Golf <difficulty>" Play random challenge (easy/medium/hard)
"   :Golf tag <tag>   " Play random challenge by tag
"   :Golf date <YYYY-MM-DD> " Play challenge for a specific date
"   :Golf id <id>     " Play challenge with the specified ID
"   :Golf leaderboard " Show today's leaderboard
"   :Golf leaderboard date <YYYY-MM-DD> " Show leaderboard for a specific date
"   :Golf leaderboard id <id> " Show leaderboard for a specific challenge ID
command! -nargs=* Golf call golf#DispatchGolfCommand(<f-args>) 
