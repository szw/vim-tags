" vim-tags - The smart ctags genereator for Vim
" Maintainer:   Szymon Wrozynski
" Version:      0.0.1
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
"

if exists('g:loaded_vim_tags') || &cp || v:version < 700
    finish
endif

let g:loaded_vim_tags = 1

"Main tags
if !exists('g:vim_tags_project_tags_command')
    let g:vim_tags_project_tags_command = "!ctags -R 2>/dev/null &"
endif

"Gemfile tags
if !exists('g:vim_tags_gems_tags_command')
    let g:vim_tags_gems_tags_command = "!ctags -R -f gems.tags `bundle show --paths` 2>/dev/null &"
endif

fun! s:generate_gems_tags()
    let gemfile_time = getftime('Gemfile.lock')
    if gemfile_time > -1
        let gems_time = getftime('gems.tags')
        if gems_time > -1
            if gems_time < gemfile_time
                silent! exe g:vim_tags_gems_tags_command
            endif
        else
            silent! exe g:vim_tags_gems_tags_command
        endif
    endif
endfun

"Auto generate ctags
if filereadable('tags')
    au BufWritePost * silent! exe g:vim_tags_project_tags_command
    call s:generate_gems_tags()

    if filereadable('gems.tags')
        set tags += "gems.tags"
    endif
endif
