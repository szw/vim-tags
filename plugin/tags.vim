" vim-tags - The Ctags generator for Vim
" Maintainer:   Szymon Wrozynski
" Version:      0.0.5
"
" Installation:
" Place in ~/.vim/plugin/tags.vim or in case of Pathogen:
"
"     cd ~/.vim/bundle
"     git clone https://github.com/szw/vim-tags.git
"
" License:
" Copyright (c) 2012-2013 Szymon Wrozynski and Contributors.
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

" Main tags
if !exists('g:vim_tags_project_tags_command')
    let g:vim_tags_project_tags_command = "ctags -R {OPTIONS} {DIRECTORY} 2>/dev/null &"
endif

" Gemfile tags
if !exists('g:vim_tags_gems_tags_command')
    let g:vim_tags_gems_tags_command = "ctags -R {OPTIONS} `bundle show --paths` 2>/dev/null &"
endif

" Ignored files and directories list
if !exists('g:vim_tags_ignore_files')
    let g:vim_tags_ignore_files = ['.gitignore', '.svnignore', '.cvsignore']
endif

" The pattern used for comments in ignore file
if !exists('g:vim_tags_ignore_file_comment_pattern')
    let g:vim_tags_ignore_file_comment_pattern = '^[#"]'
endif

" A custom directory for tags files
if !exists('g:vim_tags_directory')
    let g:vim_tags_directory = '.'
endif

" The main tags file name
if !exists('g:vim_tags_main_file')
    let g:vim_tags_main_file = 'tags'
endif

" The extension used for additional tags files
if !exists('g:vim_tags_extension')
    let g:vim_tags_extension = '.tags'
endif

command! -bang -nargs=0 TagsGenerate :call s:generate_tags(<bang>0, 1)

" Generate options and custom dirs list
let options = ['--tag-relative']
let s:custom_dirs = []

" Exclude ignored files and directories
for ignore_file in g:vim_tags_ignore_files
    if filereadable(ignore_file)
        for line in readfile(ignore_file)
            if strlen(line) > 1 && match(line, g:vim_tags_ignore_file_comment_pattern) == -1
                call add(options, '--exclude=' . shellescape(substitute(line, '^/', '', '')))
            endif
        endfor
    endif
endfor

" Add main tags file to tags option
silent! exe 'set tags+=' . substitute(g:vim_tags_directory . '/' . g:vim_tags_main_file, '^\./', '', '')
call add(options, '-f ' . g:vim_tags_directory . '/' . g:vim_tags_main_file)

for f in split(globpath(g:vim_tags_directory, '*' . g:vim_tags_extension, 1), '\n')
    let dir_name = f[strlen(g:vim_tags_directory) + 1:-6]

    if isdirectory(dir_name)
        call add(options, '--exclude=' . shellescape(dir_name))
        call add(s:custom_dirs, dir_name)
    endif

    silent! exe 'set tags+=' . substitute(f, '^\./', '', '')
endfor

let s:options = join(options, ' ')

fun! s:generate_tags(bang, redraw)
    "Remove existing tags
    if a:bang
        for f in split(globpath(g:vim_tags_directory, '*' . g:vim_tags_extension, 1), '\n') + [g:vim_tags_directory . '/' . g:vim_tags_main_file]
            call writefile([], f, 'b')
        endfor
    endif

    "Custom tags files
    for dir_name in s:custom_dirs
        let file_name = g:vim_tags_directory . '/' . dir_name . g:vim_tags_extension
        let dir_time = getftime(dir_name)

        if (getftime(file_name) < dir_time) || (getfsize(file_name) == 0)
            let custom_tags_command = substitute(g:vim_tags_project_tags_command, '{DIRECTORY}', shellescape(dir_name), '')
            let custom_tags_command = substitute(custom_tags_command, '{OPTIONS}', '-f ' . shellescape(file_name), '')
            silent! exe '!' . custom_tags_command
        endif
    endfor

    "Project tags file
    let project_tags_command = substitute(g:vim_tags_project_tags_command, '{OPTIONS}', s:options, '')
    let project_tags_command = substitute(project_tags_command, '{DIRECTORY}', '.', '')
    silent! exe '!' . project_tags_command

    "Gemfile.lock
    let gemfile_time = getftime('Gemfile.lock')
    if gemfile_time > -1
        let gems_path = g:vim_tags_directory . '/Gemfile.lock' . g:vim_tags_extension
        let gems_command = substitute(g:vim_tags_gems_tags_command, '{OPTIONS}', '-f ' . gems_path, '')
        let gems_time = getftime(gems_path)
        if gems_time > -1
            if (gems_time < gemfile_time) || (getfsize(gems_path) == 0)
                silent! exe '!' . gems_command
            endif
        else
            silent! exe '!' . gems_command
            silent! exe 'set tags+=' . substitute(gems_path, '^\./', '', '')
        endif
    endif

    if a:redraw
        redraw!
    endif
endfun

if filereadable(g:vim_tags_directory . '/' . g:vim_tags_main_file) && g:vim_tags_auto_generate
    au BufWritePost * call s:generate_tags(0, 0)
endif
