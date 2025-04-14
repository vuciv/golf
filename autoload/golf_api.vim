" golf_api.vim - API configuration and functions
" Author: Joshua Fonseca Rivera
" Version: 0.1

" API Configuration
let s:api_base_url = 'https://golf-d5bs.onrender.com/v1'
let s:api_version = 'v1'

" API endpoints
let s:endpoints = {
      \ 'daily_challenge': '/challenges/daily',
      \ 'challenge': '/challenges',
      \ 'submit_solution': '/solutions',
      \ 'leaderboard': '/solutions/leaderboard'
      \ }

" Function to make HTTP requests
function! golf_api#HttpGet(endpoint)
  if !executable('curl')
    echoerr "curl is required for Golf API calls"
    return {}
  endif

  let l:url = s:api_base_url . a:endpoint
  let l:cmd = printf('curl -s -H "Accept: application/json" "%s"', l:url)
  let l:response = system(l:cmd)
  
  if v:shell_error
    echoerr "API request failed: " . l:response
    return {}
  endif

  try
    return json_decode(l:response)
  catch
    echoerr "Failed to parse API response"
    return {}
  endtry
endfunction

" Function to make POST requests
function! golf_api#HttpPost(endpoint, data)
  if !executable('curl')
    echoerr "curl is required for Golf API calls"
    return {}
  endif

  let l:url = s:api_base_url . a:endpoint
  let l:json_data = json_encode(a:data)
  let l:cmd = printf('curl -s -X POST -H "Content-Type: application/json" -H "Accept: application/json" -d %s "%s"', shellescape(l:json_data), l:url)
  let l:response = system(l:cmd)
  
  if v:shell_error
    echoerr "API request failed: " . l:response
    return {}
  endif

  try
    return json_decode(l:response)
  catch
    echoerr "Failed to parse API response"
    return {}
  endtry
endfunction

" Get today's date in YYYY-MM-DD format (UTC)
function! s:GetTodayUTC()
  return strftime('%Y-%m-%d', localtime() - strftime('%z') * 36)
endfunction

" Function to fetch daily challenge
function! golf_api#FetchDailyChallenge()
  let l:response = golf_api#HttpGet(s:endpoints.daily_challenge)
  
  if empty(l:response)
    echoerr "Failed to fetch daily challenge"
    return {}
  endif

  " Get the date from response or fallback to today's UTC date
  let l:date = get(l:response, 'daily_date', '')
  if empty(l:date)
    let l:date = s:GetTodayUTC()
  endif

  " Transform API response to match expected challenge format
  let l:challenge = {
        \ 'id': get(l:response, 'id', ''),
        \ 'name': get(l:response, 'title', ''),
        \ 'startingText': get(l:response, 'start_text', ''),
        \ 'targetText': get(l:response, 'end_text', ''),
        \ 'par': get(l:response, 'par', 0),
        \ 'date': l:date
        \ }
  
  return l:challenge
endfunction

" Rename for clarity, this fetches by difficulty
function! golf_api#FetchRandomChallengeByDifficulty(difficulty)
  let l:endpoint = s:endpoints.challenge . '/random?difficulty=' . a:difficulty
  let l:response = golf_api#HttpGet(l:endpoint)

  if empty(l:response)
    echoerr "Failed to fetch random " . a:difficulty . " challenge"
    return {}
  endif

  " Transform API response to match expected challenge format
  let l:challenge = {
        \ 'id': get(l:response, 'id', ''),
        \ 'name': get(l:response, 'title', ''),
        \ 'startingText': get(l:response, 'start_text', ''),
        \ 'targetText': get(l:response, 'end_text', ''),
        \ 'par': get(l:response, 'par', 0),
        \ 'difficulty': get(l:response, 'difficulty', a:difficulty),
        \ 'date': s:GetTodayUTC()
        \ }

  return l:challenge
endfunction

" Function to fetch completely random challenge (any difficulty)
function! golf_api#FetchRandomChallengeAny()
  let l:endpoint = s:endpoints.challenge . '/random'
  let l:response = golf_api#HttpGet(l:endpoint)

  if empty(l:response)
    echoerr "Failed to fetch random challenge"
    return {}
  endif

  " Transform API response to match expected challenge format
  let l:challenge = {
        \ 'id': get(l:response, 'id', ''),
        \ 'name': get(l:response, 'title', ''),
        \ 'startingText': get(l:response, 'start_text', ''),
        \ 'targetText': get(l:response, 'end_text', ''),
        \ 'par': get(l:response, 'par', 0),
        \ 'difficulty': get(l:response, 'difficulty', 'unknown'),
        \ 'date': s:GetTodayUTC()
        \ }

  return l:challenge
endfunction

" Function to fetch random challenge by tag
function! golf_api#FetchRandomChallengeByTag(tag)
  let l:endpoint = s:endpoints.challenge . '/random?tag=' . substitute(a:tag, ' ', '%20', 'g')
  let l:response = golf_api#HttpGet(l:endpoint)

  if empty(l:response)
    echoerr "Failed to fetch random challenge with tag: " . a:tag
    return {}
  endif

  " Transform API response to match expected challenge format
  let l:challenge = {
        \ 'id': get(l:response, 'id', ''),
        \ 'name': get(l:response, 'title', ''),
        \ 'startingText': get(l:response, 'start_text', ''),
        \ 'targetText': get(l:response, 'end_text', ''),
        \ 'par': get(l:response, 'par', 0),
        \ 'difficulty': get(l:response, 'difficulty', 'unknown'),
        \ 'tag': a:tag,
        \ 'date': s:GetTodayUTC()
        \ }

  return l:challenge
endfunction

" Function to fetch challenge by specific date
function! golf_api#FetchChallengeByDate(date)
  let l:endpoint = s:endpoints.challenge . '/date/' . a:date
  let l:response = golf_api#HttpGet(l:endpoint)

  if empty(l:response)
    echoerr "Failed to fetch challenge for date: " . a:date
    return {}
  endif

  " Get the date from response or use requested date
  let l:date = get(l:response, 'daily_date', a:date)

  " Transform API response to match expected challenge format
  let l:challenge = {
        \ 'id': get(l:response, 'id', ''),
        \ 'name': get(l:response, 'title', ''),
        \ 'startingText': get(l:response, 'start_text', ''),
        \ 'targetText': get(l:response, 'end_text', ''),
        \ 'par': get(l:response, 'par', 0),
        \ 'difficulty': get(l:response, 'difficulty', 'unknown'),
        \ 'date': l:date
        \ }

  return l:challenge
endfunction

" Function to submit a solution
function! golf_api#SubmitSolution(challenge_id, keystrokes, keylog, time_taken, score)
  let l:solution_data = {
        \ 'challenge_id': a:challenge_id,
        \ 'keystrokes': a:keystrokes,
        \ 'keylog': a:keylog,
        \ 'time_taken': a:time_taken,
        \ 'score': a:score,
        \ 'user_id': 'anonymous'
        \ }

  return golf_api#HttpPost(s:endpoints.submit_solution, l:solution_data)
endfunction

" Function to fetch leaderboard for a challenge
function! golf_api#FetchLeaderboard(challenge_id)
  let l:endpoint = s:endpoints.leaderboard . '/' . a:challenge_id
  return golf_api#HttpGet(l:endpoint)
endfunction

" Function to fetch specific challenge by ID
function! golf_api#FetchChallenge(id)
  let l:endpoint = s:endpoints.challenge . '/' . a:id
  let l:response = golf_api#HttpGet(l:endpoint)
  
  if empty(l:response)
    return {}
  endif

  " Transform API response to match expected challenge format
  let l:challenge = {
        \ 'id': get(l:response, 'id', ''),
        \ 'name': get(l:response, 'title', ''),
        \ 'startingText': get(l:response, 'start_text', ''),
        \ 'targetText': get(l:response, 'end_text', ''),
        \ 'par': get(l:response, 'par', 0),
        \ 'date': strftime('%Y-%m-%d', localtime())
        \ }
  
  return l:challenge
endfunction 