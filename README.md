Laptop
======

Laptop is a script to set up a Mac OS X or Linux laptop for Rails development.

Requirements
------------

### Mac OS X

Install a C compiler:

For Snow Leopard (10.6): use [OS X GCC
Installer](https://github.com/kennethreitz/osx-gcc-installer/).

For Lion (10.7) or Mountain Lion (10.8): use [Command Line Tools for
XCode](https://developer.apple.com/downloads/index.action).

For Mavericks (10.9): run `xcode-select --install` in your
terminal and then click "Install".

### Linux

We support:

* [14.04: Trusty Tahr](https://wiki.ubuntu.com/TrustyTahr/ReleaseNotes),
* [13.10: Saucy Salamander](https://wiki.ubuntu.com/SaucySalamander/ReleaseNotes),
* [12.04 LTS: Precise Pangolin](https://wiki.ubuntu.com/PrecisePangolin/ReleaseNotes),
* Debian stable (currently [wheezy](http://www.debian.org/releases/stable/)).
* Debian testing (currently [jessie](http://www.debian.org/releases/testing/)).

Install
-------

### Mac OS X

Read, then run the script:

    curl -fsSL https://raw.github.com/redsquirreldev/laptop/master/mac | bash

### Linux

Read, then run the script:

    bash <(wget -qO- https://raw.github.com/redsquirreldev/laptop/master/linux)

What it sets up
---------------

* Zsh as your shell
* Babushka (primarily to manage apps)
* Bundler gem for managing Ruby libraries
* Foreman gem for serving Rails apps locally
* Heroku Config plugin for local `ENV` variables
* Heroku Toolbelt for interacting with the Heroku API
* Hub gem for interacting with the GitHub API
* Homebrew for managing operating system libraries (OS X only)
* ImageMagick for cropping and resizing images
* Postgres for storing relational data
* Rails gem for writing web applications
* rvm for managing versions of the Ruby programming language
* Redis for storing key-value data
* Ruby Build for installing Rubies
* Ruby stable for writing general-purpose code
* The Silver Searcher for finding things in files
* Tmux for saving project state and switching between projects

It should take less than 15 minutes to install (depends on your machine).

Setup common apps
-----------------

To install common apps create ~/.laptop.local - or download the template.

    curl -OfsSL https://raw.github,com/redsquirreldev/laptop/master/mac-components/local-template && mv local-template ~/.laptop.local
	
If you do this before running laptop the apps will be installed as part of the bash script.  If you do it after having already run the laptop script, source the file:

    source ~/.laptop.local

Make your own customizations
----------------------------

Put your customizations in `~/.laptop.local`. For example, your
`~/.laptop.local` might look like this:

    #!/bin/sh

    brew tap phinze/homebrew-cask
    brew install brew-cask

    brew cask install dropbox
    brew cask install google-chrome
    brew cask install rdio

Credits
-------

Although customised specifically for how Red Squirrel works, this is 99% thanks to the peeps at [thoughtbot, inc](http://thoughtbot.com/community)

Thank you, [contributors](https://github.com/redsquirreldev/laptop/graphs/contributors)!

Contributing
------------

Please see [CONTRIBUTING.md](https://github.com/redsquirreldev/laptop/blob/master/CONTRIBUTING.md).

License
-------

Laptop is © 2014 Red Squirrel. It is free software, and may be
redistributed under the terms specified in the LICENSE file.
