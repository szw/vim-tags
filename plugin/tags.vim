" vim-tags - The Ctags generator for Vim
" Maintainer:   Szymon Wrozynski
" Version:      0.1.0
"
" Installation:
" Place in ~/.vim/plugin/tags.vim or in case of Pathogen:
"
"     cd ~/.vim/bundle
"     git clone https://github.com/szw/vim-tags.git
"
" License:
" Copyright (c) 2012-2014 Szymon Wrozynski and Contributors.
" Distributed under the same terms as Vim itself.
" See :help license
"
" Usage:
" :help vim-tags

if exists('g:loaded_vim_tags') || &cp || v:version < 700
  finish
endif

let g:loaded_vim_tags = 1

" Auto generate ctags
if !exists('g:vim_tags_auto_generate')
  let g:vim_tags_auto_generate = 1
endif

if !exists("g:vim_tags_ctags_binary")
  let g:vim_tags_ctags_binary = "ctags"
endif

" Main tags
if !exists('g:vim_tags_project_tags_command')
  let g:vim_tags_project_tags_command = "{CTAGS} -R {OPTIONS} {DIRECTORY} 2>/dev/null"
endif

" Gemfile tags
if !exists('g:vim_tags_gems_tags_command')
  let g:vim_tags_gems_tags_command = "{CTAGS} -R {OPTIONS} `bundle show --paths` 2>/dev/null"
endif

" Ignored files and directories list
if !exists('g:vim_tags_ignore_files')
  let g:vim_tags_ignore_files = ['.gitignore', '.svnignore', '.cvsignore']
endif

" The pattern used for comments in ignore file
if !exists('g:vim_tags_ignore_file_comment_pattern')
  let g:vim_tags_ignore_file_comment_pattern = '^[#"]'
endif

" A list of directories used as a place for tags.
if !exists('g:vim_tags_directories')
  let g:vim_tags_directories = [".git", ".hg", ".svn", ".bzr", "_darcs", "CVS"]
endif

" The main tags file name
if !exists('g:vim_tags_main_file')
  let g:vim_tags_main_file = 'tags'
endif

" The extension used for additional tags files
if !exists('g:vim_tags_extension')
  let g:vim_tags_extension = '.tags'
endif

" Should be the Vim-Dispatch plugin used for asynchronous tags generating if present?
if !exists('g:vim_tags_use_vim_dispatch')
  let g:vim_tags_use_vim_dispatch = 0
endif

" Should the --field+=l option be used
if !exists('g:vim_tags_use_language_field')
  let g:vim_tags_use_language_field = 1
endif

if !exists("g:vim_tags_cache_dir")
  let g:vim_tags_cache_dir = expand($HOME)
endif

" Add the support for completion plugins (like YouCompleteMe or WiseComplete) (add --fields=+l)
if g:vim_tags_use_language_field
  let g:vim_tags_project_tags_command = substitute(g:vim_tags_project_tags_command, "{OPTIONS}", '--fields=+l {OPTIONS}', "")
  let g:vim_tags_gems_tags_command = substitute(g:vim_tags_gems_tags_command, "{OPTIONS}", '--fields=+l {OPTIONS}', "")
endif

command! -bang -nargs=0 TagsGenerate :call s:generate_tags(<bang>0, 1)

let s:locations = {}
let s:dirty_locations = 0

function! s:load_tags_locations()
  let cache_file  = g:vim_tags_cache_dir . "/.vt_locations"

  if filereadable(cache_file)
    for line in readfile(cache_file)
      let s:locations[line] = 1
      silent! exe 'set tags+=' . line
    endfor
  endif
endfunction

call s:load_tags_locations()

function! s:save_tags_locations()
  let cache_file = g:vim_tags_cache_dir . "/.vt_locations"
  call s:load_tags_locations()
  call writefile(keys(s:locations), cache_file)
  let s:dirty_locations = 0
endfunction

function s:add_tags_location(location)
  let location = substitute(a:location, '^\./', '', '')

  if exists("s:locations[location]")
    return
  endif

  silent! exe 'set tags+=' . location
  let s:locations[location] = 1
  let s:dirty_locations = 1
endfunction

function! s:generate_options()
  let options = ['--tag-relative']

  let s:custom_dirs      = []
  let s:files_to_include = []
  let s:tags_directory   = ""

  " Exclude ignored files and directories (also handle negated patterns (!))
  for ignore_file in g:vim_tags_ignore_files
    if filereadable(ignore_file)
      for line in readfile(ignore_file)
        if match(line, '^!') != -1
          call add(s:files_to_include, substitute(substitute(line, '^!', '', ''), '^/', '', ''))
        elseif strlen(line) > 1 && match(line, g:vim_tags_ignore_file_comment_pattern) == -1
          call add(options, '--exclude=' . shellescape(substitute(line, '^/', '', '')))
        endif
      endfor
    endif
  endfor

  " Estimate s:tags_directory
  for tags_dir in g:vim_tags_directories
    if isdirectory(tags_dir)
      let s:tags_directory = tags_dir
      break
    endif
  endfor

  if empty(s:tags_directory)
    let s:tags_directory = '.'
  endif

  " Add main tags file to tags option
  call s:add_tags_location(s:tags_directory . '/' . g:vim_tags_main_file)

  call add(options, '-f ' . s:tags_directory . '/' . g:vim_tags_main_file)

  for f in split(globpath(s:tags_directory, '*' . g:vim_tags_extension, 1), '\n')
    let dir_name = f[strlen(s:tags_directory) + 1:-6]

    if isdirectory(dir_name)
      call add(options, '--exclude=' . shellescape(dir_name))
      call add(s:custom_dirs, dir_name)
    endif

    call s:add_tags_location(f)
  endfor

  return join(options, ' ')
endfunction

function! s:find_project_root()
  let project_root = fnamemodify(".", ":p:h")

  if !empty(g:vim_tags_directories)
    let root_found = 0

    let candidate = fnamemodify(project_root, ":p:h")
    let last_candidate = ""

    while candidate != last_candidate
      for tags_dir in g:vim_tags_directories
        let tags_dir_path = candidate . "/" . tags_dir
        if filereadable(tags_dir_path) || isdirectory(tags_dir_path)
          let root_found = 1
          break
        endif
      endfor

      if root_found
        let project_root = candidate
        break
      endif

      let last_candidate = candidate
      let candidate = fnamemodify(candidate, ":p:h:h")
    endwhile

    return root_found ? project_root : fnamemodify(".", ":p:h")
  endif

  return project_root
endfunction

fun! s:execute_async_command(command)
  let command = substitute(a:command, "{CTAGS}", g:vim_tags_ctags_binary, "")

  if g:vim_tags_use_vim_dispatch && exists('g:loaded_dispatch')
    silent! exe 'Start!' command
  else
    silent! exe '!' . command '&'
  endif
endfun

fun! s:generate_tags(bang, redraw)
  let handle_acd = &acd
  set noacd

  let old_cwd = fnamemodify(".", ":p:h")

  let project_root = s:find_project_root()
  silent! exe "cd " . project_root

  let options = s:generate_options()

  "Remove existing tags
  if a:bang
    for f in split(globpath(s:tags_directory, '*' . g:vim_tags_extension, 1), '\n') + [s:tags_directory . '/' . g:vim_tags_main_file]
      call writefile([], f, 'b')
    endfor
  endif

  if !filereadable(s:tags_directory . '/' . g:vim_tags_main_file)
    if s:dirty_locations
      call s:save_tags_locations()
    endif

    silent! exe "cd " . old_cwd

    if handle_acd
      set acd
    endif

    return
  endif

  "Custom tags files
  for dir_name in s:custom_dirs
    let file_name = s:tags_directory . '/' . dir_name . g:vim_tags_extension
    let dir_time = getftime(dir_name)

    if (getftime(file_name) < dir_time) || (getfsize(file_name) == 0)
      let custom_tags_command = substitute(g:vim_tags_project_tags_command, '{DIRECTORY}', shellescape(dir_name), '')
      let custom_tags_command = substitute(custom_tags_command, '{OPTIONS}', '--tag-relative -f ' . shellescape(file_name), '')
      call s:execute_async_command(custom_tags_command)
    endif
  endfor

  "Project tags file
  let project_tags_command = substitute(g:vim_tags_project_tags_command, '{OPTIONS}', options, '')
  let project_tags_command = substitute(project_tags_command, '{DIRECTORY}', '.', '')
  call s:execute_async_command(project_tags_command)

  " Append files from negated patterns
  if !empty(s:files_to_include)
    let append_command_template = substitute(g:vim_tags_project_tags_command, '{OPTIONS}', '--tag-relative -a -f ' . s:tags_directory . '/' . g:vim_tags_main_file, '')
    for file_to_include in s:files_to_include
      call s:execute_async_command(substitute(append_command_template, '{DIRECTORY}', file_to_include, ''))
    endfor
  endif

  "Gemfile.lock
  let gemfile_time = getftime('Gemfile.lock')

  if gemfile_time > -1
    let gems_path = s:tags_directory . '/Gemfile.lock' . g:vim_tags_extension
    let gems_command = substitute(g:vim_tags_gems_tags_command, '{OPTIONS}', '-f ' . gems_path, '')
    let gems_time = getftime(gems_path)

    call s:add_tags_location(gems_path)

    if !exists("s:gemfile_correctness")
      let s:gemfile_correctness = { "time": 0, "error": 0 }
    endif

    " check if bundle works fine
    if s:gemfile_correctness.time != gemfile_time
      silent! exe '!bundle check &>/dev/null'
      let s:gemfile_correctness.error = v:shell_error
      let s:gemfile_correctness.time  = gemfile_time
    endif

    if !s:gemfile_correctness.error
      if gems_time > -1
        if (gems_time < gemfile_time) || (getfsize(gems_path) == 0)
          call s:execute_async_command(gems_command)
        endif
      else
        call s:execute_async_command(gems_command)
      endif
    endif
  endif

  if a:redraw
    redraw!
  endif

  if s:dirty_locations
    call s:save_tags_locations()
  endif

  silent! exe "cd " . old_cwd

  if handle_acd
    set acd
  endif
endfun

if g:vim_tags_auto_generate
  au BufWritePost * call s:generate_tags(0, 0)
endif
