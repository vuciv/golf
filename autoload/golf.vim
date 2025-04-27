"********************************************************************
" Golf Plugin - Main functionality
" Author: Joshua Fonseca Rivera
" Version: 0.1
"********************************************************************

"========================================================================
" Global Variables & Initial State
"========================================================================
let s:golf_keystrokes        = []
let s:golf_start_time        = 0
let s:golf_tracking          = 0
let s:golf_target_text       = ''
let s:golf_par               = 0
let s:golf_challenge_id      = ''
let s:golf_challenge_name    = ''
let s:golf_original_buffer   = 0

"========================================================================
" Challenge Management Functions
"========================================================================

" Get today's date in YYYY-MM-DD format (UTC)
function! golf#GetTodayDate() abort
  return strftime('%Y-%m-%d', localtime())
endfunction

" Load a challenge from the challenges directory (fetch fresh from API)
function! golf#LoadChallenge(date) abort
  let l:challenge = golf_api#FetchDailyChallenge()
  if empty(l:challenge) || empty(get(l:challenge, 'id', '')) || empty(get(l:challenge, 'targetText', ''))
    echoerr "Failed to fetch challenge from API"
    return {}
  endif
  return l:challenge
endfunction

" Fetch a challenge for the given date (alias to always fetch fresh challenge)
function! golf#FetchChallenge(date) abort
  return golf_api#FetchDailyChallenge()
endfunction

" Play today's challenge
function! golf#PlayToday() abort
  " Save the current buffer number
  let s:golf_original_buffer = bufnr('%')

  let l:today = golf#GetTodayDate()
  let l:challenge = golf#LoadChallenge(l:today)
  if empty(l:challenge)
    return
  endif
  call golf#PlayChallenge(l:challenge)
endfunction

" Play a random challenge by difficulty
function! golf#PlayChallengeByDifficulty(difficulty) abort
  let l:valid_difficulties = ['easy', 'medium', 'hard']
  let l:difficulty = tolower(a:difficulty)

  if index(l:valid_difficulties, l:difficulty) == -1
    echoerr "Invalid difficulty: " . a:difficulty . ". Please use 'easy', 'medium', or 'hard'."
    return
  endif

  " Save the current buffer number
  let s:golf_original_buffer = bufnr('%')

  echo "Fetching " . l:difficulty . " challenge..."
  let l:challenge = golf_api#FetchRandomChallengeByDifficulty(l:difficulty)
  if empty(l:challenge) || empty(get(l:challenge, 'id', '')) || empty(get(l:challenge, 'targetText', ''))
    echoerr "Failed to fetch " . l:difficulty . " challenge."
    return
  endif

  call golf#PlayChallenge(l:challenge)
endfunction

" Start the Golf challenge using the challenge details provided
function! golf#PlayChallenge(challenge) abort
  " Store challenge information for later use
  let s:golf_target_text    = a:challenge.targetText
  let s:golf_par            = a:challenge.par
  let s:golf_challenge_id   = a:challenge.id
  let s:golf_challenge_name = a:challenge.name

  " Create a new buffer for the challenge
  enew
  setlocal buftype=nofile bufhidden=hide noswapfile
  execute 'file Golf:' . a:challenge.id

  " Clear buffer and insert starting text
  normal! ggdG
  call setline(1, split(a:challenge.startingText, "\n"))

  " Reset success state and clear any highlighting
  let b:golf_success_shown = 0
  call golf#ClearSuccessHighlight()

  " Begin tracking keystrokes
  call golf#StartTracking()

  " Set up a status line for display
  setlocal statusline=%{golf#StatusLine()}

  " Create a split that shows the target text for reference
  call golf#ShowTargetText()

  " Return focus to the challenge buffer window
  let l:challenge_win = bufwinnr('Golf:' . a:challenge.id)
  if l:challenge_win != -1
    execute l:challenge_win . "wincmd w"
  endif
  normal! gg
endfunction

"========================================================================
" Keystroke Tracking Functions
"========================================================================

function! golf#StartTracking() abort
  let s:golf_keystrokes    = []
  let s:golf_start_time    = localtime()
  let s:golf_tracking      = 1
  let b:golf_success_shown = 0
  call golf#ClearSuccessHighlight()

  " record the START event
  call golf#RecordKeystroke('START')

  " modes → mapping commands (now includes command-line 'c')
  let l:modes = {
        \ 'n': 'nnoremap',
        \ 'i': 'inoremap',
        \ 'v': 'vnoremap',
        \ 'x': 'xnoremap',
        \ 'o': 'onoremap',
        \ 's': 'snoremap',
        \ 'c': 'cnoremap'
        \ }

  " map printable ASCII 32–126
  for code in range(32, 126)
    let ch  = nr2char(code)
    let lhs = (ch ==# '|') ? '<Bar>' : ch
    for mode in keys(l:modes)
      let cmd = l:modes[mode]
      execute printf(
            \ '%s <buffer> <expr> %s golf#RecordAndReturn(%s)',
            \ cmd, lhs, string(ch)
            \ )
    endfor
  endfor

  " map special keys
  let l:specials = ['<Space>','<CR>','<Esc>','<BS>','<Tab>',
        \ '<Left>','<Right>','<Up>','<Down>']
  for sp in l:specials
    for mode in keys(l:modes)
      let cmd = l:modes[mode]
      execute printf(
            \ '%s <buffer> <expr> %s golf#RecordAndReturn(%s)',
            \ cmd, sp, string(sp)
            \ )
    endfor
  endfor

  " auto‑verify on any change
  augroup GolfModeTracking
    autocmd!
    autocmd TextChanged,TextChangedI <buffer> call golf#AutoVerify()
  augroup END
endfunction

" helper to record the key AND immediately refresh statusline
function! golf#RecordAndReturn(key) abort
  if s:golf_tracking
    call golf#RecordKeystroke(a:key)
    redrawstatus
  endif
  return a:key
endfunction

function! golf#StopTracking() abort
  let s:golf_tracking = 0

  " we just need the mode‑letters for unmapping
  let l:modes = ['n','i','v','x','o','s','c']

  " unmap printable ASCII
  for code in range(32, 126)
    let ch  = nr2char(code)
    let lhs = (ch ==# '|') ? '<Bar>' : ch
    for m in l:modes
      execute printf('%sunmap <buffer> %s', m, lhs)
    endfor
  endfor

  " unmap special keys
  let l:specials = ['<Space>','<CR>','<Esc>','<BS>','<Tab>',
        \ '<Left>','<Right>','<Up>','<Down>']
  for sp in l:specials
    for m in l:modes
      execute printf('%sunmap <buffer> %s', m, sp)
    endfor
  endfor

  augroup GolfModeTracking
    autocmd!
  augroup END

  echo "Golf tracking stopped."
endfunction

" Add a keystroke event to the tracker
function! golf#RecordKeystroke(key) abort
  if s:golf_tracking
    call add(s:golf_keystrokes, {'key': a:key})
  endif
endfunction

"========================================================================
" Auto-Verification & Success Handling Functions
"========================================================================

" Normalize text by removing trailing whitespace and empty trailing lines.
function! s:NormalizeText(text) abort
  let l:lines = split(a:text, '\n', 1)   " Keep empty lines
  let l:lines = map(l:lines, 'substitute(v:val, "\\s\\+$", "", "")')
  while len(l:lines) > 0 && l:lines[-1] =~ '^$'
    call remove(l:lines, -1)
  endwhile
  return join(l:lines, "\n")
endfunction

" Automatically verify user's solution; show success if match found.
function! golf#AutoVerify() abort
  let l:current_text = s:NormalizeText(join(getline(1, '$'), "\n"))
  let l:target_text  = s:NormalizeText(s:golf_target_text)
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

" Display the success message including score, leaderboard, and stats.
function! golf#ShowSuccess() abort
  " Set flag so that we do not duplicate the success message
  let b:golf_success_shown = 1

  " Count keystrokes (subtracting the initial "START" record)
  let l:keystroke_count = len(s:golf_keystrokes) - 1

  " Calculate score and elapsed time
  let l:score      = golf#CalculateScore(l:keystroke_count)
  let l:time_taken = localtime() - s:golf_start_time
  let l:minutes    = l:time_taken / 60
  let l:seconds    = l:time_taken % 60

  " Determine an appropriate emoji based on score value
  let l:emoji = '⛳'
  if l:score.value <= -2
    let l:emoji = '🦅'
  elseif l:score.value == -1
    let l:emoji = '��'
  elseif l:score.value >= 3
    let l:emoji = '😖'
  elseif l:score.value >= 2
    let l:emoji = '😕'
  endif

  " Create a new scratch buffer for the success message
  only | enew
  setlocal buftype=nofile bufhidden=wipe noswapfile nonumber norelativenumber
  setlocal signcolumn=no nocursorline nocursorcolumn
  execute 'file Golf:Success'

  " Save results and fetch leaderboard from API
  call golf#SaveResults(l:keystroke_count, l:time_taken, l:score)
  let l:leaderboard = golf_api#FetchLeaderboard(s:golf_challenge_id)

  " Build the success message with vertical centering and leaderboard entries
  let l:lines = []
  let l:screen_lines = &lines
  let l:message_lines = 20  " Adjust based on content
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
  call add(l:lines, '║  Like golf.vim? Follow @joshycodes on X for updates & dev logs ⚡')
  call add(l:lines, '║')
  call add(l:lines, '╠═══════════════════════════════════════════════════════════════╣')
  call add(l:lines, '║                        LEADERBOARD 🏆                          ║')
  call add(l:lines, '╟───────────────────────────────────────────────────────────────╢')
  
  " Add leaderboard entries (top 5)
  if !empty(l:leaderboard)
    let l:rank = 1
    for entry in l:leaderboard[0:4]
      let l:entry_time    = entry.time_taken
      let l:entry_minutes = l:entry_time / 60
      let l:entry_seconds = l:entry_time % 60
      call add(l:lines, printf('║  %d. %s - %d strokes (%dm %ds)', 
            \ l:rank, entry.user_id, entry.keystrokes, l:entry_minutes, l:entry_seconds))
      if has_key(entry, 'keylog') && !empty(entry.keylog)
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

        " Wrap the formatted keystrokes to a maximum width
        let l:keystroke_str = join(l:keystrokes, '')
        let l:max_width = 50
        while len(l:keystroke_str) > 0
          let l:line_part = strpart(l:keystroke_str, 0, l:max_width)
          let l:keystroke_str = strpart(l:keystroke_str, l:max_width)
          call add(l:lines, printf('║    %s%s', l:line_part, repeat(' ', l:max_width - len(l:line_part))))
        endwhile
      else
        call add(l:lines, '║    (Keystrokes not available)')
      endif
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

  " Display the message in the new buffer and set syntax highlighting
  call setline(1, l:lines)
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

  setlocal readonly nomodifiable
  normal! gg
  redrawstatus!

  " Allow modifications temporarily to capture key input
  setlocal modifiable
  echo "Press any key to exit..."
  call getchar()

  " Cleanup: close Golf buffers and return to the original file
  call golf#CloseAllBuffers()
endfunction

" Clear any success indication and update the status line
function! golf#ClearSuccessIndication() abort
  let b:golf_success_shown = 0
  call golf#ClearSuccessHighlight()
  redrawstatus!
endfunction

" Helper: Remove existing success highlight if set
function! golf#ClearSuccessHighlight() abort
  if exists('w:golf_match_id')
    try
      call matchdelete(w:golf_match_id)
    catch
      " Ignore errors if the match doesn't exist
    endtry
    unlet w:golf_match_id
  endif
endfunction

" Calculate the score based on keystroke count and par
function! golf#CalculateScore(keystroke_count) abort
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

" Save results by submitting to the API; report errors if any
function! golf#SaveResults(keystroke_count, time_taken, score) abort
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

" Build the status line content based on challenge state and keystrokes
function! golf#StatusLine() abort
  let l:status = ''
  if exists('b:golf_success_shown') && b:golf_success_shown == 1
    let l:status .= '[SUCCESS] '
  endif

  if s:golf_tracking
    let l:keycount = len(s:golf_keystrokes) - 1  " Subtract the "START" keystroke
    return l:status . 'Golf: ' . s:golf_challenge_name . ' | Keystrokes: ' . l:keycount . ' | Par: ' . s:golf_par
  endif
  return l:status
endfunction

" Close all Golf-related buffers and return to the original file buffer, if available.
function! golf#CloseAllBuffers() abort
  let l:buffers = filter(range(1, bufnr('$')), 'bufexists(v:val) && bufname(v:val) =~# "^Golf:"')
  for l:buf in l:buffers
    execute 'bwipeout! ' . l:buf
  endfor
  if bufexists(s:golf_original_buffer)
    execute 'buffer ' . s:golf_original_buffer
  endif
endfunction

"========================================================================
" Display Functions
"========================================================================

" Display the target text in a vertical split for user reference
function! golf#ShowTargetText() abort
  if !exists('b:golf_tracking') && s:golf_target_text == ''
    echo "No active Golf challenge. Start one with :GolfToday"
    return
  endif

  let l:current_buffer = bufnr('%')
  vnew
  setlocal buftype=nofile bufhidden=hide noswapfile
  execute 'file Golf:Target'
  call setline(1, "TARGET TEXT - GOAL")
  call append(1, split(s:golf_target_text, "\n"))

  " Set syntax highlighting for target header
  if has('syntax')
    syntax match GolfTargetHeader /^TARGET TEXT - GOAL$/
    highlight GolfTargetHeader cterm=bold,underline ctermfg=green gui=bold,underline guifg=green
    highlight GolfTarget ctermbg=17 guibg=#000040
    setlocal background=dark
  endif

  setlocal scrollbind
  setlocal cursorbind
  setlocal wrap
  setlocal readonly nomodifiable

  " Return to the original buffer window with synced scrolling
  execute bufwinnr(l:current_buffer) . "wincmd w"
  setlocal scrollbind
  setlocal cursorbind
  syncbind
endfunction

" Play a challenge by its ID
function! golf#PlayChallengeById(id) abort
  let s:golf_original_buffer = bufnr('%')
  echo "Fetching challenge with ID: " . a:id . "..."
  let l:challenge = golf_api#FetchChallenge(a:id)
  if empty(l:challenge) || empty(get(l:challenge, 'id', '')) || empty(get(l:challenge, 'targetText', ''))
    echoerr "Failed to fetch challenge with ID: " . a:id . "."
    return
  endif
  call golf#PlayChallenge(l:challenge)
endfunction

" Dispatcher for the :Golf command based on arguments
function! golf#DispatchGolfCommand(...) abort
  let l:argc = a:0
  if l:argc == 0
    " :Golf (no args) -> Play random challenge (any difficulty)
    call golf#PlayRandomChallenge()
  elseif l:argc == 1
    " :Golf <difficulty>
    let l:arg1 = tolower(a:1)
    if l:arg1 == 'easy' || l:arg1 == 'medium' || l:arg1 == 'hard'
      call golf#PlayChallengeByDifficulty(l:arg1)
    elseif l:arg1 == 'leaderboard'
      " :Golf leaderboard -> Show today's leaderboard
      call golf#ShowTodaysLeaderboard()
    elseif l:arg1 == 'today'
      " :Golf today -> Play today's challenge
      call golf#PlayToday()
    elseif l:arg1 == 'help'
      " :Golf help -> Show available commands
      call golf#ShowHelp()
    else
      echoerr "Invalid argument: " . a:1 . ". Use 'easy', 'medium', 'hard', 'today', 'leaderboard', 'tag <tag>', 'date <YYYY-MM-DD>', 'id <id>', or 'help'."
    endif
  elseif l:argc == 2
    let l:arg1 = tolower(a:1)
    let l:arg2 = a:2
    if l:arg1 == 'tag'
      " :Golf tag <tag>
      call golf#PlayChallengeByTag(l:arg2)
    elseif l:arg1 == 'date'
      " :Golf date <YYYY-MM-DD>
      if l:arg2 =~ '^\d\{4}-\d\{2}-\d\{2}$'
        call golf#PlayChallengeByDate(l:arg2)
      else
        echoerr "Invalid date format: " . l:arg2 . ". Use YYYY-MM-DD format."
      endif
    elseif l:arg1 == 'id'
      " :Golf id <id>
      call golf#PlayChallengeById(l:arg2)
    elseif l:arg1 == 'leaderboard' && tolower(l:arg2) == 'date'
      " Prompt for date when just :Golf leaderboard date is entered
      let l:date = input('Enter date (YYYY-MM-DD): ')
      if l:date =~ '^\d\{4}-\d\{2}-\d\{2}$'
        call golf#ShowLeaderboardByDate(l:date)
      else
        echoerr "Invalid date format: " . l:date . ". Use YYYY-MM-DD format."
      endif
    elseif l:arg1 == 'leaderboard' && tolower(l:arg2) == 'id'
      " Prompt for ID when just :Golf leaderboard id is entered
      let l:id = input('Enter challenge ID: ')
      if !empty(l:id)
        call golf#ShowLeaderboardById(l:id)
      else
        echoerr "Challenge ID cannot be empty."
      endif
    else
      echoerr "Invalid command structure. Use ':Golf', ':Golf <difficulty>', ':Golf today', ':Golf leaderboard', ':Golf tag <tag>', ':Golf date <YYYY-MM-DD>', ':Golf id <id>', ':Golf leaderboard date <YYYY-MM-DD>', ':Golf leaderboard id <id>', or ':Golf help'."
    endif
  elseif l:argc == 3
    let l:arg1 = tolower(a:1)
    let l:arg2 = tolower(a:2)
    let l:arg3 = a:3
    
    if l:arg1 == 'leaderboard' && l:arg2 == 'date'
      " :Golf leaderboard date <YYYY-MM-DD>
      if l:arg3 =~ '^\d\{4}-\d\{2}-\d\{2}$'
        call golf#ShowLeaderboardByDate(l:arg3)
      else
        echoerr "Invalid date format: " . l:arg3 . ". Use YYYY-MM-DD format."
      endif
    elseif l:arg1 == 'leaderboard' && l:arg2 == 'id'
      " :Golf leaderboard id <id>
      call golf#ShowLeaderboardById(l:arg3)
    else
      echoerr "Invalid command structure. Check the documentation for valid commands."
    endif
  else
    echoerr "Too many arguments. Use ':Golf help' to see available commands."
  endif
endfunction

" Play a completely random challenge
function! golf#PlayRandomChallenge() abort
  let s:golf_original_buffer = bufnr('%')
  echo "Fetching random challenge..."
  let l:challenge = golf_api#FetchRandomChallengeAny()
  if empty(l:challenge) || empty(get(l:challenge, 'id', '')) || empty(get(l:challenge, 'targetText', ''))
    echoerr "Failed to fetch random challenge."
    return
  endif
  call golf#PlayChallenge(l:challenge)
endfunction

" Play a random challenge by tag
function! golf#PlayChallengeByTag(tag) abort
  let s:golf_original_buffer = bufnr('%')
  echo "Fetching random challenge with tag: " . a:tag . "..."
  let l:challenge = golf_api#FetchRandomChallengeByTag(a:tag)
  if empty(l:challenge) || empty(get(l:challenge, 'id', '')) || empty(get(l:challenge, 'targetText', ''))
    echoerr "Failed to fetch random challenge with tag: " . a:tag . "."
    return
  endif
  call golf#PlayChallenge(l:challenge)
endfunction

" Play the challenge for a specific date
function! golf#PlayChallengeByDate(date) abort
  let s:golf_original_buffer = bufnr('%')
  echo "Fetching challenge for date: " . a:date . "..."
  let l:challenge = golf_api#FetchChallengeByDate(a:date)
  if empty(l:challenge) || empty(get(l:challenge, 'id', '')) || empty(get(l:challenge, 'targetText', ''))
    echoerr "Failed to fetch challenge for date: " . a:date . "."
    return
  endif
  call golf#PlayChallenge(l:challenge)
endfunction

"========================================================================
" Leaderboard Functions
"========================================================================

" Display leaderboard for a challenge
function! golf#DisplayLeaderboard(leaderboard, challenge_name) abort
  " Create a new scratch buffer for the leaderboard
  enew
  setlocal buftype=nofile bufhidden=wipe noswapfile nonumber norelativenumber
  setlocal signcolumn=no nocursorline nocursorcolumn
  execute 'file Golf:Leaderboard'

  " Build the leaderboard display
  let l:lines = []
  call add(l:lines, '╔═══════════════════════════════════════════════════════════════╗')
  call add(l:lines, '║                        LEADERBOARD 🏆                          ║')
  
  if !empty(a:challenge_name)
    call add(l:lines, '╠═══════════════════════════════════════════════════════════════╣')
    call add(l:lines, '║  Challenge: ' . a:challenge_name)
  endif
  
  call add(l:lines, '╠═══════════════════════════════════════════════════════════════╣')
  
  " Add leaderboard entries
  if !empty(a:leaderboard)
    let l:rank = 1
    for entry in a:leaderboard
      let l:entry_time    = entry.time_taken
      let l:entry_minutes = l:entry_time / 60
      let l:entry_seconds = l:entry_time % 60
      call add(l:lines, printf('║  %d. %s - %d strokes (%dm %ds)', 
            \ l:rank, entry.user_id, entry.keystrokes, l:entry_minutes, l:entry_seconds))
      if has_key(entry, 'keylog') && !empty(entry.keylog)
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

        " Wrap the formatted keystrokes to a maximum width
        let l:keystroke_str = join(l:keystrokes, '')
        let l:max_width = 50
        while len(l:keystroke_str) > 0
          let l:line_part = strpart(l:keystroke_str, 0, l:max_width)
          let l:keystroke_str = strpart(l:keystroke_str, l:max_width)
          call add(l:lines, printf('║    %s%s', l:line_part, repeat(' ', l:max_width - len(l:line_part))))
        endwhile
      else
        call add(l:lines, '║    (Keystrokes not available)')
      endif
      if l:rank < len(a:leaderboard)
        call add(l:lines, '╟───────────────────────────────────────────────────────────────╢')
      endif
      let l:rank += 1
    endfor
  else
    call add(l:lines, '║  No entries yet for this challenge!')
  endif
  
  call add(l:lines, '║')
  call add(l:lines, '║  Press any key to exit...                                      ║')
  call add(l:lines, '╚═══════════════════════════════════════════════════════════════╝')

  " Display the leaderboard in the buffer
  call setline(1, l:lines)
  syntax match GolfLeaderboardHeader /^║.*LEADERBOARD.*║$/
  syntax match GolfLeaderboardEntry /^║\s\+\d\+\./
  syntax match GolfLeaderboardBorder /[║╔╗╚╝╠╣═]/
  highlight GolfLeaderboardHeader ctermfg=magenta guifg=#FF00FF
  highlight GolfLeaderboardEntry ctermfg=cyan guifg=#00FFFF
  highlight GolfLeaderboardBorder ctermfg=white guifg=#FFFFFF

  setlocal readonly nomodifiable
  normal! gg
  redrawstatus!

  " Allow modifications temporarily to capture key input
  setlocal modifiable
  echo "Press any key to exit..."
  call getchar()

  " Close the buffer
  bwipeout!
endfunction

" Show today's leaderboard
function! golf#ShowTodaysLeaderboard() abort
  echo "Fetching today's leaderboard..."
  let l:today_challenge = golf_api#FetchDailyChallenge()
  if empty(l:today_challenge) || empty(get(l:today_challenge, 'id', ''))
    echoerr "Failed to fetch today's challenge."
    return
  endif
  
  let l:leaderboard = golf_api#FetchLeaderboard(l:today_challenge.id)
  call golf#DisplayLeaderboard(l:leaderboard, l:today_challenge.name)
endfunction

" Show leaderboard for a specific date
function! golf#ShowLeaderboardByDate(date) abort
  echo "Fetching leaderboard for date: " . a:date . "..."
  let l:challenge = golf_api#FetchChallengeByDate(a:date)
  if empty(l:challenge) || empty(get(l:challenge, 'id', ''))
    echoerr "Failed to fetch challenge for date: " . a:date . "."
    return
  endif
  
  let l:leaderboard = golf_api#FetchLeaderboard(l:challenge.id)
  call golf#DisplayLeaderboard(l:leaderboard, l:challenge.name)
endfunction

" Show leaderboard for a specific challenge ID
function! golf#ShowLeaderboardById(id) abort
  echo "Fetching leaderboard for challenge ID: " . a:id . "..."
  let l:challenge = golf_api#FetchChallenge(a:id)
  let l:challenge_name = empty(l:challenge) ? "Challenge #" . a:id : l:challenge.name
  
  let l:leaderboard = golf_api#FetchLeaderboard(a:id)
  call golf#DisplayLeaderboard(l:leaderboard, l:challenge_name)
endfunction

" Show help information with available commands
function! golf#ShowHelp() abort
  " Create a new buffer for the help information
  enew
  setlocal buftype=nofile bufhidden=wipe noswapfile nonumber norelativenumber
  setlocal signcolumn=no nocursorline nocursorcolumn
  execute 'file Golf:Help'

  " Build the help content
  let l:lines = []
  call add(l:lines, '╔═══════════════════════════════════════════════════════════════╗')
  call add(l:lines, '║                        GOLF.VIM HELP                          ║')
  call add(l:lines, '╠═══════════════════════════════════════════════════════════════╣')
  call add(l:lines, '║  PLAYING CHALLENGES:                                          ║')
  call add(l:lines, '║    :Golf today                 - Play today''s challenge       ║')
  call add(l:lines, '║    :Golf                       - Play random challenge        ║')
  call add(l:lines, '║    :Golf easy                  - Play random easy challenge   ║')
  call add(l:lines, '║    :Golf medium                - Play random medium challenge ║')
  call add(l:lines, '║    :Golf hard                  - Play random hard challenge   ║')
  call add(l:lines, '║    :Golf tag <tag>             - Play challenge with tag      ║')
  call add(l:lines, '║    :Golf date <YYYY-MM-DD>     - Play challenge from date     ║')
  call add(l:lines, '║    :Golf id <id>               - Play challenge by ID         ║')
  call add(l:lines, '║                                                               ║')
  call add(l:lines, '║  VIEWING LEADERBOARDS:                                        ║')
  call add(l:lines, '║    :Golf leaderboard           - Today''s leaderboard         ║')
  call add(l:lines, '║    :Golf leaderboard date <YYYY-MM-DD>                        ║')
  call add(l:lines, '║    :Golf leaderboard id <id>                                  ║')
  call add(l:lines, '║                                                               ║')
  call add(l:lines, '║  HELP:                                                        ║')
  call add(l:lines, '║    :Golf help                  - Show this help information   ║')
  call add(l:lines, '║                                                               ║')
  call add(l:lines, '║  Note: The legacy command :GolfToday is still supported       ║')
  call add(l:lines, '║  but will be deprecated in a future version.                  ║')
  call add(l:lines, '╚═══════════════════════════════════════════════════════════════╝')

  " Display the help content in the buffer
  call setline(1, l:lines)
  syntax match GolfHelpHeader /^║.*GOLF.VIM HELP.*║$/
  syntax match GolfHelpSection /^║\s\+[A-Z].*:$/
  syntax match GolfHelpCommand /^║\s\+:[A-Za-z]\+/
  syntax match GolfHelpBorder /[║╔╗╚╝╠╣═]/
  highlight GolfHelpHeader ctermfg=yellow guifg=#FFD700
  highlight GolfHelpSection ctermfg=green guifg=#00FF00
  highlight GolfHelpCommand ctermfg=cyan guifg=#00FFFF
  highlight GolfHelpBorder ctermfg=white guifg=#FFFFFF

  setlocal readonly nomodifiable
  normal! gg
  redrawstatus!

  " Allow modifications temporarily to capture key input
  setlocal modifiable
  echo "Press any key to exit..."
  call getchar()
  bwipeout!
endfunction
