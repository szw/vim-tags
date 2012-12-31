" vim-tags - The Ctags generator for Vim
" Maintainer:   Szymon Wrozynski
" Version:      0.0.2
"
" Installation:
" Place in ~/.vim/plugin/tags.vim or in case of Pathogen:
"
"     cd ~/.vim/bundle
"     git clone https://github.com/szw/vim-tags.git
"
" License:
" Copyright (c) 2012 Szymon Wrozynski. Distributed under the same terms as Vim itself.
" See :help license
"
" Usage:
" https://github.com/szw/vim-tags/blob/master/README.md

if exists('g:loaded_vim_tags') || &cp || v:version < 700
    finish
endif

let g:loaded_vim_tags = 1

"Auto generate ctags
if !exists('g:vim_tags_auto_generate')
    let g:vim_tags_auto_generate = 1
endif

"Main tags
if !exists('g:vim_tags_project_tags_command')
    let g:vim_tags_project_tags_command = "ctags -R {OPTIONS} {DIRECTORY} 2>/dev/null &"
endif

"Gemfile tags
if !exists('g:vim_tags_gems_tags_command')
    let g:vim_tags_gems_tags_command = "ctags -R -f Gemfile.lock.tags `bundle show --paths` 2>/dev/null &"
endif

command! -nargs=0 TagsGenerate :call s:generate_tags(1)

" Generate options and custom dirs list
let options = []
let s:custom_dirs = []

for f in split(globpath('.', '*.tags', 1), '\n')
    let dir_name = f[:-6]
    let clean_name = substitute(dir_name, '^\./', '', '')

    if isdirectory(dir_name)
        call add(options, '--exclude=' . shellescape(clean_name))
        call add(s:custom_dirs, dir_name)
    endif

    silent! exe 'set tags+=' . clean_name . '.tags'
endfor

let s:options = join(options, ' ')

fun! s:generate_tags(redraw)
    "Custom tags files
    for dir_name in s:custom_dirs
        let file_name = dir_name . '.tags'
        let dir_time = getftime(dir_name)

        if (getftime(file_name) < dir_time) || (getfsize(file_name) == 0)
            let custom_tags_command = substitute(g:vim_tags_project_tags_command, '{DIRECTORY}', shellescape(dir_name), '')
            let custom_tags_command = substitute(custom_tags_command, '{OPTIONS}', '-f ' . shellescape(file_name), '')
            silent! exe '!' . custom_tags_command
        endif
    endfor

    "Project tags file
    let project_tags_command = substitute(g:vim_tags_project_tags_command, '{OPTIONS}', s:options, '')
    let project_tags_command = substitute(project_tags_command, '{DIRECTORY}', '', '')
    silent! exe '!' . project_tags_command

    "Gemfile.lock
    let gemfile_time = getftime('Gemfile.lock')
    if gemfile_time > -1
        let gems_time = getftime('Gemfile.lock.tags')
        if gems_time > -1
            if gems_time < gemfile_time
                silent! exe '!' . g:vim_tags_gems_tags_command
            endif
        else
            silent! exe '!' . g:vim_tags_gems_tags_command
            set tags+=Gemfile.lock.tags
        endif
    endif

    if a:redraw
        redraw!
    endif
endfun

if filereadable('tags') && g:vim_tags_auto_generate
    au BufWritePost * call s:generate_tags(0)
endif
