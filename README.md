Vim-Tags
========

Vim-Tags version 0.1.0
----------------------

The Ctags generator for Vim

Copyright (c) 2012-2014 Szymon Wrozynski and Contributors


About
-----

Ctags support is a great feature of Vim. One approach to make use of Ctags is
the way of Tim Pope's plugins. For example in Rails projects, Ctags are
generated automatically while Bundler is running and installing new gems.

Vim-Tags plugin treats Ctags like more tightly coupled within a concrete
project. It creates '.tags' files directly in the root project directory. Also,
it can perform tags creation upon each file save through forking - available
under Unix-like operating systems. This option, however, may require some
tweaking under Windows.

Vim-Tags is under active development. Currently, besides its main features, it
provides some support for Ruby/Rails projects (it can generate tags for gems
listed in 'Gemfile.lock' file).


Installation
------------

Place in ~/.vim/plugin/tags.vim or in case of Pathogen:

    cd ~/.vim/bundle
    git clone https://github.com/szw/vim-tags.git

In case of Vundle that would be:

    Plugin 'szw/vim-tags'

placed in your `.vimrc` file

Moreover, Vim-Tags requires `ctags` utility. On Ubuntu you can install it with:

    sudo apt-get install exuberant-ctags

On Mac OSX you could use Homebrew:

    brew install ctags

Please, don't forget to star the repository if you like the plugin.
This will let me know how many users it has and then how to proceed with further
development :).


Ruby Manager
------------

If you are using a Ruby Manager such as
[chruby](https://github.com/postmodern/chruby),
[rvm](http://rvm.beginrescueend.com/),
[rbenv](https://github.com/sstephenson/rbenv) etc, be sure to have your Ruby
Manager integrated with Vim.

* [Integrating chruby with Vim](https://github.com/postmodern/chruby/wiki/Vim)
* [Integrating rvm with Vim](http://rvm.io/integration/vim)

A simple way to check this is by executing `bundle show --paths` in your Vim in
the command-line mode.

    :!bundle show --paths

If it shows your current Gems (based on your Gemfile) it is probably working fine.


Usage
-----

The plugin has only one command and a few options described in the
[Configuration](#configuration) section.

### `:TagsGenerate`

This command will generate one or more tags files but only if the main tags file
exists. The presence of that file acts as an indicator actually. By the _main
tags file_ I mean the "tags" file collecting tags from all files and
subdirectories of the project root directory.

Moreover, this command will also update the `tags` setting of Vim with all new
tags files found in the project root as Vim-Tags caches relative tags paths and
updates `tags` settings automatically.

By default, this command is also executed upon each file save. 

Besides the main "tags" file the project may have more tags files for different
directories and a special `Gemfile.lock.tags` file for tags gathered from
a Bundler project.

For the first time, when there are no `tags` files in your project yet, you can
force generating them by the `bang` version of the `:TagsGenerate` command:

    :TagsGenerate!

The `bang` version of the command forces generation for all "tags" files.

Additionally, you can exclude some directories from the main "tags" file,
especially if they contains rarely changed and heavy content, i.e. third-party
libraries. Those directories must be placed directly at the project root.

To exclude them, make empty files named exactly after those directories with
".tags" suffixes: e.g. "vendor.tags" for the "vendor" directory. Then, the
plugin will be watching modification times of those directories and
corresponding tags files and perform tags generation only if necessary.

Vim-Tags can read files containing patterns to exclude from tags generation. By
default it seeks among '.gitignore', '.svnignore', and '.cvsignore' files in the
current directory. You can change this behavior by setting proper configuration
options explained later.

The last but not least feature is the Ruby Bundler support. It is easy and
straightforward. If your project root contains "Gemfile.lock" file, the plugin
will be generating tags for all your Bundler gems referenced in the Gemfile.
Here, "Gemfile.lock" modification time will be taken to find out whether the
tags generation is required, just like in the custom directories case explained
earlier. The plugin will create "Gemfile.lock.tags" file automatically


Configuration
-------------

Vim-Tags assumes that you have 'ctags' utility available in your shell. However
it is possible to change or improve shell commands used by the plugin, e.g. in
case you have to point a proper binary with absolute path or tweak some options.

Vim-Tags can be configured by setting some global variables in your '.vimrc'
file. If you want to have some custom settings valid only for the current
project create a local '.vimrc' file with those settings and add the following
snippet to your main '.vimrc' file:

    set exrc
    set secure

This will allow Vim to use your custom .vimrc in the current working directory.

The Vim-Tags available variables are:


* `vim_tags_auto_generate`

    * Default: `1`

    If enabled, Vim-Tags will generate tags on file saving

        let g:vim_tags_auto_generate = 1


* `vim_tags_ctags_binary`

    * Default: `ctags`

    This is the Ctags binary which will be substitued to the commands generating
    ctags files. Sometimes needs to be customized, e.g. for MacVim I had to set
    it Homebrew's ctags binary: `/usr/local/bin/ctags`.


* `vim_tags_project_tags_command`

    * Default: `"{CTAGS} -R {OPTIONS} {DIRECTORY} 2>/dev/null"`

    This command is used for main Ctags generation.

        let g:vim_tags_project_tags_command = "({CTAGS} -R {OPTIONS} {DIRECTORY} 2>/dev/null) \&\& ({PLACE_TAGS})"


* `vim_tags_gems_tags_command`

    * Default: ``"{CTAGS} -R {OPTIONS} `bundle show --paths` 2>/dev/null"``

    Command used for Gemfile tags generation.

        let g:vim_tags_gems_tags_command = "{CTAGS} -R {OPTIONS} `bundle show --paths` 2>/dev/null"


* `vim_tags_use_vim_dispatch`

    * Default: `0`

    [`Vim-Dispatch`](https://github.com/tpope/vim-dispatch) is a plugin allowing
    asynchronous calls of system commands. `Vim-Tags` will try to use it (if
    found) to perform asynchronous tags generation.  Otherwise `Vim-Tags` will
    make asynchronous calls by adding `&` to ctags commands.

        let g:vim_tags_use_vim_dispatch = 0


* `vim_tags_use_language_field`

    * Default: `1`

    Use `ctags` with `--field=+l` option necessary for the tag completion in the
    [`YouCompleteMe`](https://github.com/Valloric/YouCompleteMe) or similar plugins.

        let g:vim_tags_use_language_field = 1


* `vim_tags_ignore_files`

    * Default: `['.gitignore', '.svnignore', '.cvsignore']`

    Files containing directories and files excluded from Ctags generation.

        let g:vim_tags_ignore_files = ['.gitignore', '.svnignore', '.cvsignore']


* `vim_tags_ignore_file_comment_pattern`

    * Default: `'^[#"]'`

    The pattern used to recognize comments in the ignore file.

        let g:vim_tags_ignore_file_comment_pattern = '^[#"]'


* `vim_tags_directories`

    * Default: `[".git", ".hg", ".svn", ".bzr", "_darcs", "CVS"]`

    The default directories list where the tags files will be created. The first
    one found will be used. If none exists the current directory (`'.'`) will be
    taken. The plugin will use that directories as root markers - indicating by
    their presence the current project root directory.

        let g:vim_tags_directories = [".git", ".hg", ".svn", ".bzr", "_darcs", "CVS"]


* `vim_tags_main_file`

    * Default: `'tags'`

    The main tags file name.

        let g:vim_tags_main_file = 'tags'


* `vim_tags_extension`

    * Default: `'.tags'`

    The extension used for additional tags files.

        let g:vim_tags_extension = '.tags'


* `vim_tags_cache_dir`

    * Default: `$HOME`

    The directory for cache files (`.vt_location`).

        let g:vim_tags_cache_dir = expand($HOME)


Authors and License
-------------------

Vim-Tags plugin was written by Szymon Wrozynski and Contributors. It is licensed
under the same terms as Vim itself. For more info see `:help license`.
