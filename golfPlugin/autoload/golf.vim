" golf.vim - Main functionality for Golf plugin
" Author: Golf Plugin
" Version: 0.1

" Store keystroke tracking data
let s:golf_keystrokes = []
let s:golf_start_time = 0
let s:golf_tracking = 0
let s:golf_target_text = ''
let s:golf_par = 0
let s:golf_challenge_id = ''
let s:golf_challenge_name = ''
let s:golf_original_buffer = 0

" Show success message and score
function! golf#ShowSuccess() abort
  " Mark that success has been shown so we don't duplicate it.
  let b:golf_success_shown = 1

  " Count all keystrokes except START
  let l:keystroke_count = len(s:golf_keystrokes) - 1

  " Calculate score and elapsed time.
  let l:score = golf#CalculateScore(l:keystroke_count)
  let l:time_taken = localtime() - s:golf_start_time
  let l:minutes = l:time_taken / 60
  let l:seconds = l:time_taken % 60

  " Determine an appropriate emoji based on the score.
  let l:emoji = '⛳'  " default for Par or Bogey
  if l:score.value <= -2
    let l:emoji = '🦅'  " Eagle
  elseif l:score.value == -1
    let l:emoji = '🐦'  " Birdie
  elseif l:score.value >= 3
    let l:emoji = '😖'  " Triple bogey or worse
  elseif l:score.value >= 2
    let l:emoji = '😕'  " Double bogey
  endif

  " Create a new buffer for the success message
  only | enew
  setlocal buftype=nofile bufhidden=wipe noswapfile nonumber norelativenumber signcolumn=no nocursorline nocursorcolumn
  execute 'file Golf:Success'

  " Submit solution and get leaderboard
  call golf#SaveResults(l:keystroke_count, l:time_taken, l:score)
  let l:leaderboard = golf_api#FetchLeaderboard(s:golf_challenge_id)

  " Build the success message with vertical centering.
  let l:lines = []
  let l:screen_lines = &lines
  let l:message_lines = 20  " Increased to accommodate leaderboard
  let l:padding = (l:screen_lines - l:message_lines) / 2
  for i in range(l:padding)
    call add(l:lines, '')
  endfor
  call add(l:lines, '╔═══════════════════════════════════════════════════════════════╗')
  call add(l:lines, '║                   🎉  CHALLENGE COMPLETE!  🎉                  ║')
  call add(l:lines, '╠═══════════════════════════════════════════════════════════════╣')
  call add(l:lines, '║  Challenge: ' . s:golf_challenge_name)
  call add(l:lines, '║')
  call add(l:lines, printf('║  Keystrokes: %d  |  Par: %d  |  Score: %s %s', l:keystroke_count, s:golf_par, l:score.name, l:emoji))
  call add(l:lines, printf('║  Time: %d minutes %d seconds', l:minutes, l:seconds))
  call add(l:lines, '║')
  call add(l:lines, '║  Great job! Your solution matches the target perfectly! 🎯')
  call add(l:lines, '║')
  call add(l:lines, '╠═══════════════════════════════════════════════════════════════╣')
  call add(l:lines, '║                        LEADERBOARD 🏆                          ║')
  call add(l:lines, '╟───────────────────────────────────────────────────────────────╢')
  
  " Add leaderboard entries
  if !empty(l:leaderboard)
    let l:rank = 1
    for entry in l:leaderboard[0:4]  " Show top 5
      let l:entry_time = entry.time_taken
      let l:entry_minutes = l:entry_time / 60
      let l:entry_seconds = l:entry_time % 60
      
      " Add the rank and stats line
      call add(l:lines, printf('║  %d. %s - %d strokes (%dm %ds)', 
            \ l:rank,
            \ entry.user_id,
            \ entry.keystrokes,
            \ l:entry_minutes,
            \ l:entry_seconds))
      
      " Check if keylog exists before trying to format it
      if has_key(entry, 'keylog') && !empty(entry.keylog)
        " Format the keystrokes nicely
        let l:keystrokes = []
        for k in entry.keylog
          if k.key ==# '<Space>'
            call add(l:keystrokes, '␣')
          elseif k.key ==# '<CR>'
            call add(l:keystrokes, '⏎')
          elseif k.key ==# '<Esc>'
            call add(l:keystrokes, '⎋')
          elseif k.key ==# '<BS>'
            call add(l:keystrokes, '⌫')
          elseif k.key ==# '<Tab>'
            call add(l:keystrokes, '⇥')
          elseif k.key ==# '<Left>'
            call add(l:keystrokes, '←')
          elseif k.key ==# '<Right>'
            call add(l:keystrokes, '→')
          elseif k.key ==# '<Up>'
            call add(l:keystrokes, '↑')
          elseif k.key ==# '<Down>'
            call add(l:keystrokes, '↓')
          else
            call add(l:keystrokes, k.key)
          endif
        endfor
        
        " Add the keystrokes line, indented and wrapped nicely
        let l:keystroke_str = join(l:keystrokes, '')
        let l:max_width = 50  " Maximum width for keystrokes display
        while len(l:keystroke_str) > 0
          let l:line_part = strpart(l:keystroke_str, 0, l:max_width)
          let l:keystroke_str = strpart(l:keystroke_str, l:max_width)
          call add(l:lines, printf('║    %s%s', l:line_part, repeat(' ', l:max_width - len(l:line_part))))
        endwhile
      else
        " Show message when keylog is not available
        call add(l:lines, '║    (Keystrokes not available)')
      endif
      
      " Add a separator between entries
      if l:rank < len(l:leaderboard[0:4])
        call add(l:lines, '╟───────────────────────────────────────────────────────────────╢')
      endif
      let l:rank += 1
    endfor
  else
    call add(l:lines, '║  No entries yet - you might be the first!')
  endif
  
  call add(l:lines, '║')
  call add(l:lines, '║  Press any key to exit...                                      ║')
  call add(l:lines, '╚═══════════════════════════════════════════════════════════════╝')

  " Display the success message in the new buffer.
  call setline(1, l:lines)

  " Apply syntax highlighting for improved visibility.
  syntax match GolfSuccessHeader /^║.*CHALLENGE COMPLETE.*║$/
  syntax match GolfSuccessStats /^║\s\+Keystrokes.*║$/
  syntax match GolfSuccessTime /^║\s\+Time.*║$/
  syntax match GolfSuccessBorder /[║╔╗╚╝╠╣═]/
  syntax match GolfLeaderboardHeader /^║.*LEADERBOARD.*║$/
  syntax match GolfLeaderboardEntry /^║\s\+\d\+\./
  highlight GolfSuccessHeader ctermfg=yellow guifg=#FFD700
  highlight GolfSuccessStats ctermfg=cyan guifg=#00FFFF
  highlight GolfSuccessTime ctermfg=green guifg=#00FF00
  highlight GolfSuccessBorder ctermfg=white guifg=#FFFFFF
  highlight GolfLeaderboardHeader ctermfg=magenta guifg=#FF00FF
  highlight GolfLeaderboardEntry ctermfg=cyan guifg=#00FFFF

  " Set the buffer as read-only and move cursor to the top
  setlocal readonly nomodifiable
  normal! gg
  redrawstatus!

  " Temporarily allow modifications for getchar()
  setlocal modifiable

  " Wait for any key press
  echo "Press any key to exit..."
  call getchar()

  " Close all Golf buffers and return to original file
  call golf#CloseAllBuffers()
endfunction

" Function to close all Golf buffers
function! golf#CloseAllBuffers()
  " Find all Golf buffers
  let l:buffers = filter(range(1, bufnr('$')), 'bufexists(v:val) && bufname(v:val) =~# "^Golf:"')
  
  " Close each Golf buffer
  for l:buf in l:buffers
    execute 'bwipeout! ' . l:buf
  endfor

  " Return to original buffer if it exists
  if bufexists(s:golf_original_buffer)
    execute 'buffer ' . s:golf_original_buffer
  endif
endfunction

" Helper function to get today's date in YYYY-MM-DD format (UTC)
function! golf#GetTodayDate()
  return strftime('%Y-%m-%d', localtime())
endfunction

" Load a challenge from the challenges directory
function! golf#LoadChallenge(date)
  " Always fetch fresh challenge from API
  let l:challenge = golf_api#FetchDailyChallenge()
  
  if empty(l:challenge)
    echoerr "Failed to fetch challenge from API"
    return {}
  endif
  
  return l:challenge
endfunction

" Fetch a challenge for the given date
function! golf#FetchChallenge(date)
  " Always fetch fresh challenge from API
  return golf_api#FetchDailyChallenge()
endfunction

" Play today's challenge
function! golf#PlayToday()
  " Store the current buffer number
  let s:golf_original_buffer = bufnr('%')
  
  let l:today = golf#GetTodayDate()
  let l:challenge = golf#LoadChallenge(l:today)
  
  if empty(l:challenge)
    return
  endif
  
  call golf#PlayChallenge(l:challenge)
endfunction

" Start the Golf challenge
function! golf#PlayChallenge(challenge)
  " Store challenge information
  let s:golf_target_text = a:challenge.targetText
  let s:golf_par = a:challenge.par
  let s:golf_challenge_id = a:challenge.id
  let s:golf_challenge_name = a:challenge.name
  
  " Create a new buffer for the challenge
  enew
  setlocal buftype=nofile
  setlocal bufhidden=hide
  setlocal noswapfile
  execute 'file Golf:' . a:challenge.id
  
  " Clear content and insert fresh starting text
  normal! ggdG
  call setline(1, split(a:challenge.startingText, "\n"))
  
  " Reset success state when loading/reloading challenge
  let b:golf_success_shown = 0
  call golf#ClearSuccessHighlight()
  
  " Start tracking keystrokes
  call golf#StartTracking()
  
  " Set up status line
  setlocal statusline=%{golf#StatusLine()}
  
  " Create a split showing the target text
  call golf#ShowTargetText()
  
  " Return focus to the main challenge buffer
  let l:challenge_win = bufwinnr('Golf:' . a:challenge.id)
  if l:challenge_win != -1
    execute l:challenge_win . "wincmd w"
  endif
endfunction

" Start tracking keystrokes
function! golf#StartTracking()
  let s:golf_keystrokes = []
  let s:golf_start_time = localtime()
  let s:golf_tracking = 1
  
  " Reset success state on starting/restarting tracking
  let b:golf_success_shown = 0
  call golf#ClearSuccessHighlight()
  
  " Set up mappings to intercept keystrokes in all modes
  " Normal mode mappings
  for i in range(33, 126) " printable ASCII characters
    execute "nnoremap <expr> <char-" . i . "> <SID>KeyStrokeTracker('<char-" . i . ">')"
  endfor
  
  " Insert mode mappings
  for i in range(32, 126) " Include space (32) for insert mode
    execute "inoremap <expr> <char-" . i . "> <SID>KeyStrokeTracker('<char-" . i . ">')"
  endfor
  
  " Special keys in normal and insert mode
  for key in ['<Space>', '<CR>', '<Esc>', '<BS>', '<Tab>', '<Left>', '<Right>', '<Up>', '<Down>']
    execute "nnoremap <expr> " . key . " <SID>KeyStrokeTracker('" . key . "')"
    execute "inoremap <expr> " . key . " <SID>KeyStrokeTracker('" . key . "')"
  endfor
  
  " Simple auto-verification after any buffer changes
  augroup GolfModeTracking
    autocmd!
    autocmd TextChanged,TextChangedI * call golf#AutoVerify()
  augroup END
  
  " Record initial state
  call golf#RecordKeystroke('START')
  
  " Set a buffer variable to indicate we're tracking
  let b:golf_tracking = 1
endfunction

" Function to intercept keystrokes
function! s:KeyStrokeTracker(key)
  if s:golf_tracking
    call golf#RecordKeystroke(a:key)
  endif
  return a:key
endfunction

" Record a keystroke
function! golf#RecordKeystroke(key)
  if s:golf_tracking
    call add(s:golf_keystrokes, {
          \ 'key': a:key
          \ })
  endif
endfunction

" Stop tracking keystrokes
function! golf#StopTracking()
  let s:golf_tracking = 0
  
  " Remove all our mappings
  for i in range(33, 126)
    execute "nunmap <char-" . i . ">"
  endfor
  
  " Remove insert mode mappings
  for i in range(32, 126)
    execute "iunmap <char-" . i . ">"
  endfor
  
  " Special keys
  for key in ['<Space>', '<CR>', '<Esc>', '<BS>', '<Tab>', '<Left>', '<Right>', '<Up>', '<Down>']
    execute "nunmap " . key
    execute "iunmap " . key
  endfor
  
  " Clean up autocommands
  augroup GolfModeTracking
    autocmd!
  augroup END
  
  " Remove the buffer variable
  if exists('b:golf_tracking')
    unlet b:golf_tracking
  endif
  
  echo "Golf tracking stopped."
endfunction

" Normalize text for comparison
function! s:NormalizeText(text)
  " Split into lines and remove trailing whitespace
  let l:lines = split(a:text, '\n', 1)  " Keep empty lines
  let l:lines = map(l:lines, 'substitute(v:val, "\\s\\+$", "", "")')
  
  " Remove any trailing empty lines
  while len(l:lines) > 0 && l:lines[-1] =~ '^$'
    call remove(l:lines, -1)
  endwhile
  
  " Join lines back together with Unix-style line endings
  return join(l:lines, "\n")
endfunction

" Automatically verify solution as user types
function! golf#AutoVerify()
  " Get current buffer content, normalized
  let l:current_text = s:NormalizeText(join(getline(1, '$'), "\n"))
  
  " Normalize the target text as well
  let l:target_text = s:NormalizeText(s:golf_target_text)

  " Compare normalized texts
  if l:current_text ==# l:target_text
    if !exists('b:golf_success_shown') || !b:golf_success_shown
      let b:golf_success_shown = 1
      call golf#ShowSuccess()
    endif
  else
    call golf#ClearSuccessHighlight()
    let b:golf_success_shown = 0
  endif
endfunction

" Clear the success indication
function! golf#ClearSuccessIndication()
  let b:golf_success_shown = 0
  call golf#ClearSuccessHighlight()
  " Force status line update
  redrawstatus!
endfunction

" Helper function to clear success highlighting
function! golf#ClearSuccessHighlight()
  if exists('w:golf_match_id')
    try
      call matchdelete(w:golf_match_id)
    catch
      " Ignore errors if match doesn't exist
    endtry
    unlet w:golf_match_id
  endif
endfunction

" Calculate score based on keystrokes and par
function! golf#CalculateScore(keystroke_count)
  let l:par = s:golf_par
  
  if a:keystroke_count <= l:par - 3
    return {'name': 'Eagle (-2)', 'value': -2}
  elseif a:keystroke_count <= l:par - 1
    return {'name': 'Birdie (-1)', 'value': -1}
  elseif a:keystroke_count == l:par
    return {'name': 'Par (0)', 'value': 0}
  elseif a:keystroke_count <= l:par + 2
    return {'name': 'Bogey (+1)', 'value': 1}
  elseif a:keystroke_count <= l:par + 3
    return {'name': 'Double Bogey (+2)', 'value': 2}
  else
    return {'name': 'Triple Bogey (+3)', 'value': 3}
  endif
endfunction

" Save results to a file
function! golf#SaveResults(keystroke_count, time_taken, score)
  " Submit to API
  let l:api_response = golf_api#SubmitSolution(
        \ s:golf_challenge_id,
        \ a:keystroke_count,
        \ s:golf_keystrokes,
        \ a:time_taken,
        \ a:score.value
        \ )

  if !empty(l:api_response) && has_key(l:api_response, 'error')
    echoerr "Failed to submit solution to API: " . l:api_response.error
  endif
endfunction

" Status line function
function! golf#StatusLine()
  let l:status = ''
  if exists('b:golf_success_shown') && b:golf_success_shown == 1
    let l:status .= '[SUCCESS] '
  endif

  if s:golf_tracking
    let l:keycount = len(s:golf_keystrokes) - 1  " Subtract 1 for START
    return l:status . 'Golf: ' . s:golf_challenge_name . ' | Keystrokes: ' . l:keycount . ' | Par: ' . s:golf_par
  endif
  return l:status
endfunction

" Show target text in a split window
function! golf#ShowTargetText()
  " Check if we're in a Golf buffer
  if !exists('b:golf_tracking') && s:golf_target_text == ''
    echo "No active Golf challenge. Start one with :GolfToday"
    return
  endif
  
  " Save the current buffer number for reference
  let l:current_buffer = bufnr('%')
  
  " Create a new vertical split with the target text
  vnew
  setlocal buftype=nofile
  setlocal bufhidden=hide
  setlocal noswapfile
  execute 'file Golf:Target'
  
  " Set a clear header to show this is the target
  call setline(1, "TARGET TEXT - GOAL")
  
  " Insert the target text after the header
  call append(1, split(s:golf_target_text, "\n"))
  
  " Set syntax highlighting for the header (before making buffer readonly)
  if has('syntax')
    syntax match GolfTargetHeader /^TARGET TEXT - GOAL$/
    highlight GolfTargetHeader cterm=bold,underline ctermfg=green gui=bold,underline guifg=green
    
    " Set a different color for the target split to make it stand out
    highlight GolfTarget ctermbg=17 guibg=#000040
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