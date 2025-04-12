" vimgolf.vim - Main functionality for VimGolf plugin
" Author: VimGolf Plugin
" Version: 0.1

" Store keystroke tracking data
let s:vimgolf_keystrokes = []
let s:vimgolf_start_time = 0
let s:vimgolf_tracking = 0
let s:vimgolf_target_text = ''
let s:vimgolf_par = 0
let s:vimgolf_challenge_id = ''
let s:vimgolf_challenge_name = ''

" Helper function to get today's date in YYYY-MM-DD format (UTC)
function! vimgolf#GetTodayDate()
  return strftime('%Y-%m-%d', localtime())
endfunction

" Load a challenge from the challenges directory
function! vimgolf#LoadChallenge(date)
  let l:challenge_file = g:vimgolf_challenges_dir . '/' . a:date . '.json'
  
  if !filereadable(l:challenge_file)
    call vimgolf#FetchChallenge(a:date)
  endif
  
  if filereadable(l:challenge_file)
    let l:challenge_data = json_decode(join(readfile(l:challenge_file), "\n"))
    return l:challenge_data
  endif
  
  return {}
endfunction

" Fetch a challenge for the given date
function! vimgolf#FetchChallenge(date)
  " Ensure the challenge directory exists
  if !isdirectory(g:vimgolf_challenges_dir)
    call mkdir(g:vimgolf_challenges_dir, 'p')
  endif

  " Fetch challenge from API
  let l:challenge = vimgolf_api#FetchDailyChallenge()
  
  if empty(l:challenge)
    echoerr "Failed to fetch challenge from API"
    return {}
  endif
  
  " Save challenge to local cache
  let l:challenge_file = g:vimgolf_challenges_dir . '/' . a:date . '.json'
  call writefile([json_encode(l:challenge)], l:challenge_file)
  
  return l:challenge
endfunction

" Play today's challenge
function! vimgolf#PlayToday()
  let l:today = vimgolf#GetTodayDate()
  let l:challenge = vimgolf#LoadChallenge(l:today)
  
  if empty(l:challenge)
    return
  endif
  
  call vimgolf#PlayChallenge(l:challenge)
endfunction

" Start the VimGolf challenge
function! vimgolf#PlayChallenge(challenge)
  " Store challenge information
  let s:vimgolf_target_text = a:challenge.targetText
  let s:vimgolf_par = a:challenge.par
  let s:vimgolf_challenge_id = a:challenge.id
  let s:vimgolf_challenge_name = a:challenge.name
  
  " Create a new buffer for the challenge
  enew
  setlocal buftype=nofile
  setlocal bufhidden=hide
  setlocal noswapfile
  execute 'file VimGolf:' . a:challenge.id
  
  " Clear content and insert fresh starting text
  normal! ggdG
  call setline(1, split(a:challenge.startingText, "\n"))
  
  " Reset success state when loading/reloading challenge
  let b:vimgolf_success_shown = 0
  call vimgolf#ClearSuccessHighlight()
  
  " Start tracking keystrokes
  call vimgolf#StartTracking()
  
  " Set up status line
  setlocal statusline=%{vimgolf#StatusLine()}
  
  " Create a split showing the target text
  call vimgolf#ShowTargetText()
  
  " Return focus to the main challenge buffer
  let l:challenge_win = bufwinnr('VimGolf:' . a:challenge.id)
  if l:challenge_win != -1
    execute l:challenge_win . "wincmd w"
  endif
endfunction

" Function to intercept keystrokes
function! s:KeyStrokeTracker(key)
  if s:vimgolf_tracking
    call vimgolf#RecordKeystroke(a:key)
  endif
  return a:key
endfunction

" Start tracking keystrokes
function! vimgolf#StartTracking()
  let s:vimgolf_keystrokes = []
  let s:vimgolf_start_time = localtime()
  let s:vimgolf_tracking = 1
  
  " Reset success state on starting/restarting tracking
  let b:vimgolf_success_shown = 0
  call vimgolf#ClearSuccessHighlight()
  
  " Set up mappings to intercept keystrokes in all modes
  " Normal mode mappings
  for i in range(33, 126) " printable ASCII characters
    execute "nnoremap <expr> <char-" . i . "> <SID>KeyStrokeTracker('<char-" . i . ">')"
  endfor
  
  " Special keys in normal mode
  for key in ['<Space>', '<CR>', '<Esc>', '<BS>', '<Tab>', '<Left>', '<Right>', '<Up>', '<Down>']
    execute "nnoremap <expr> " . key . " <SID>KeyStrokeTracker('" . key . "')"
  endfor
  
  " Simple auto-verification after any buffer changes
  augroup VimGolfModeTracking
    autocmd!
    autocmd TextChanged,TextChangedI * call vimgolf#AutoVerify()
  augroup END
  
  " Record initial state
  call vimgolf#RecordKeystroke('START')
  
  " Set a buffer variable to indicate we're tracking
  let b:vimgolf_tracking = 1
endfunction

" Record a keystroke
function! vimgolf#RecordKeystroke(key)
  if s:vimgolf_tracking
    call add(s:vimgolf_keystrokes, {
          \ 'key': a:key
          \ })
  endif
endfunction

" Stop tracking keystrokes
function! vimgolf#StopTracking()
  let s:vimgolf_tracking = 0
  
  " Remove all our mappings
  for i in range(33, 126)
    execute "nunmap <char-" . i . ">"
  endfor
  
  " Special keys
  for key in ['<Space>', '<CR>', '<Esc>', '<BS>', '<Tab>', '<Left>', '<Right>', '<Up>', '<Down>']
    execute "nunmap " . key
  endfor
  
  " Clean up autocommands
  augroup VimGolfModeTracking
    autocmd!
  augroup END
  
  " Remove the buffer variable
  if exists('b:vimgolf_tracking')
    unlet b:vimgolf_tracking
  endif
  
  echo "VimGolf tracking stopped."
endfunction

" Automatically verify solution as user types
function! vimgolf#AutoVerify()
  " Only if we're tracking and in a VimGolf buffer
  if !s:vimgolf_tracking || !exists('b:vimgolf_tracking')
    return
  endif
  
  " Get current buffer content
  let l:current_text = join(getline(1, '$'), "\n")
  
  " Simple direct comparison with target text
  if l:current_text ==# s:vimgolf_target_text
    " We match! Show success if not already shown
    if !exists('b:vimgolf_success_shown') || b:vimgolf_success_shown == 0
      call vimgolf#ShowSuccess()
    endif
  else
    " We don't match. Clear success indication if it was shown
    if exists('b:vimgolf_success_shown') && b:vimgolf_success_shown == 1
      call vimgolf#ClearSuccessIndication()
    endif
  endif
endfunction

" Show success message and score
function! vimgolf#ShowSuccess()
  let b:vimgolf_success_shown = 1
  
  " Count keystrokes (ignoring tracking events)
  let l:keystroke_count = 0
  for keystroke in s:vimgolf_keystrokes
    if keystroke.key != 'START' && keystroke.key != 'END' &&
         \ keystroke.key != 'InsertEnter' && keystroke.key != 'InsertLeave' &&
         \ keystroke.key != 'CmdlineEnter' && keystroke.key != 'CmdlineLeave' &&
         \ !matchstr(keystroke.key, '<.\+>') " Ignore special keys
        let l:keystroke_count += 1
    endif
  endfor

  " Calculate score
  let l:score = vimgolf#CalculateScore(l:keystroke_count)

  " Success message
  echohl MoreMsg
  echo "SUCCESS! Solution matches target."
  echo "Keystrokes: " . l:keystroke_count . " | Par: " . s:vimgolf_par . " | Score: " . l:score.name
  echohl None

  " Set highlighting to indicate success
  highlight VimGolfSuccess ctermbg=22 guibg=#005500
  let w:vimgolf_match_id = matchadd('VimGolfSuccess', '.*')

  " Force status line update
  redrawstatus!
endfunction

" Clear the success indication
function! vimgolf#ClearSuccessIndication()
  let b:vimgolf_success_shown = 0
  call vimgolf#ClearSuccessHighlight()
  " Force status line update
  redrawstatus!
endfunction

" Helper function to clear success highlighting
function! vimgolf#ClearSuccessHighlight()
  if exists('w:vimgolf_match_id')
    try
      call matchdelete(w:vimgolf_match_id)
    catch
      " Ignore errors if match doesn't exist
    endtry
    unlet w:vimgolf_match_id
  endif
endfunction

" Calculate score based on keystrokes and par
function! vimgolf#CalculateScore(keystroke_count)
  let l:par = s:vimgolf_par
  
  if a:keystroke_count <= l:par - 3
    return {'name': 'Eagle (-2)', 'value': -2}
  elseif a:keystroke_count <= l:par - 1
    return {'name': 'Birdie (-1)', 'value': -1}
  elseif a:keystroke_count == l:par
    return {'name': 'Par (0)', 'value': 0}
  elseif a:keystroke_count <= l:par + 2
    return {'name': 'Bogey (+1)', 'value': 1}
  else
    return {'name': 'Double Bogey (+2)', 'value': 2}
  endif
endfunction

" Generate a shareable summary of the solution
function! vimgolf#GenerateShareableSummary(keystroke_count, score)
  let l:summary = "VimGolf Challenge: " . s:vimgolf_challenge_name . "\n"
  let l:summary .= "Date: " . vimgolf#GetTodayDate() . "\n"
  let l:summary .= "Keystrokes: " . a:keystroke_count . "\n"
  let l:summary .= "Par: " . s:vimgolf_par . "\n"
  let l:summary .= "Score: " . a:score.name . " " . a:score.emoji . "\n"
  
  return l:summary
endfunction

" Save results to a file
function! vimgolf#SaveResults(keystroke_count, time_taken, score)
  let l:results = {
        \ 'challenge_id': s:vimgolf_challenge_id,
        \ 'challenge_name': s:vimgolf_challenge_name,
        \ 'keystrokes': a:keystroke_count,
        \ 'time_taken': a:time_taken,
        \ 'score': a:score,
        \ 'date': strftime('%Y-%m-%d %H:%M:%S'),
        \ 'keylog': s:vimgolf_keystrokes
        \ }
  
  let l:results_dir = g:vimgolf_data_dir . '/results'
  if !isdirectory(l:results_dir)
    call mkdir(l:results_dir, 'p')
  endif
  
  let l:results_file = l:results_dir . '/' . s:vimgolf_challenge_id . '.json'
  call writefile([json_encode(l:results)], l:results_file)
  
  echo "Results saved to " . l:results_file
  echo "Shareable summary:"
  echo vimgolf#GenerateShareableSummary(a:keystroke_count, a:score)
endfunction

" Status line function
function! vimgolf#StatusLine()
  let l:status = ''
  if exists('b:vimgolf_success_shown') && b:vimgolf_success_shown == 1
    let l:status .= '[SUCCESS] '
  endif

  if s:vimgolf_tracking
    let l:keycount = 0
    for keystroke in s:vimgolf_keystrokes
      if keystroke.key != 'START' && keystroke.key != 'END' &&
           \ keystroke.key != 'InsertEnter' && keystroke.key != 'InsertLeave' &&
           \ keystroke.key != 'CmdlineEnter' && keystroke.key != 'CmdlineLeave' &&
           \ !matchstr(keystroke.key, '<.\+>') " Ignore special keys
          let l:keycount += 1
      endif
    endfor
    return l:status . 'VimGolf: ' . s:vimgolf_challenge_name . ' | Keystrokes: ' . l:keycount . ' | Par: ' . s:vimgolf_par
  endif
  return l:status
endfunction

" Show target text in a split window
function! vimgolf#ShowTargetText()
  " Check if we're in a VimGolf buffer
  if !exists('b:vimgolf_tracking') && s:vimgolf_target_text == ''
    echo "No active VimGolf challenge. Start one with :VimGolfToday"
    return
  endif
  
  " Save the current buffer number for reference
  let l:current_buffer = bufnr('%')
  
  " Create a new vertical split with the target text
  vnew
  setlocal buftype=nofile
  setlocal bufhidden=hide
  setlocal noswapfile
  execute 'file VimGolf:Target'
  
  " Set a clear header to show this is the target
  call setline(1, "TARGET TEXT - GOAL")
  
  " Insert the target text after the header
  call append(1, split(s:vimgolf_target_text, "\n"))
  
  " Set syntax highlighting for the header (before making buffer readonly)
  if has('syntax')
    syntax match VimGolfTargetHeader /^TARGET TEXT - GOAL$/
    highlight VimGolfTargetHeader cterm=bold,underline ctermfg=green gui=bold,underline guifg=green
    
    " Set a different color for the target split to make it stand out
    highlight VimGolfTarget ctermbg=17 guibg=#000040
    setlocal background=dark
  endif
  
  " Set window options for better comparison
  setlocal scrollbind
  setlocal cursorbind
  setlocal wrap
  
  " Make buffer read-only (after all modifications)
  setlocal readonly
  setlocal nomodifiable
  
  " Go back to the original buffer and enable scrollbind there too
  execute bufwinnr(l:current_buffer) . "wincmd w"
  setlocal scrollbind
  setlocal cursorbind
  
  " Sync the scroll position
  syncbind
endfunction

" Copy the shareable summary to the clipboard
function! vimgolf#CopyShareableSummary()
  " Check if we have results
  if empty(s:vimgolf_keystrokes)
    echo "No VimGolf results to share. Complete a challenge first."
    return
  endif
  
  " Count real keystrokes
  let l:real_keystrokes = []
  for keystroke in s:vimgolf_keystrokes
    if keystroke.key != 'START' && keystroke.key != 'END' && 
         \ keystroke.key != 'InsertEnter' && keystroke.key != 'InsertLeave' &&
         \ keystroke.key != 'CmdlineEnter' && keystroke.key != 'CmdlineLeave'
      call add(l:real_keystrokes, keystroke)
    endif
  endfor
  
  let l:keystroke_count = len(l:real_keystrokes)
  let l:score = vimgolf#CalculateScore(l:keystroke_count)
  
  " Generate summary
  let l:summary = vimgolf#GenerateShareableSummary(l:keystroke_count, l:score)
  
  " Check if we have clipboard support
  if has('clipboard')
    let @+ = l:summary
    echo "Shareable summary copied to clipboard!"
  else
    echo "Clipboard not supported. Here's your summary:"
    echo l:summary
  endif
endfunction 