" VimGolf API configuration and functions
" Author: VimGolf Plugin
" Version: 0.1

" API Configuration
let s:api_base_url = 'https://api.vimgolf.com/v1'
let s:api_version = 'v1'

" API endpoints
let s:endpoints = {
      \ 'daily_challenge': '/challenges/daily',
      \ 'challenge': '/challenges',
      \ 'submit_solution': '/solutions'
      \ }

" Function to make HTTP requests
function! vimgolf_api#HttpGet(endpoint)
  if !executable('curl')
    echoerr "curl is required for VimGolf API calls"
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

" Function to fetch daily challenge
function! vimgolf_api#FetchDailyChallenge()
  let l:response = vimgolf_api#HttpGet(s:endpoints.daily_challenge)
  
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

" Function to fetch specific challenge by ID
function! vimgolf_api#FetchChallenge(id)
  let l:endpoint = s:endpoints.challenge . '/' . a:id
  let l:response = vimgolf_api#HttpGet(l:endpoint)
  
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