<p align="center">
	<a href="#"><img src=".github/assets/logo.png" alt="CM-SS13" align="center"></a>
</p>
<hr />

<p align="center">
	<a href="https://github.com/cmss13-devs/cmss13/actions?query=workflow%3A%22CI+Suite%22"><img src="https://github.com/cmss13-devs/cmss13/workflows/CI%20Suite/badge.svg"></a>
 	<a href="https://github.com/cmss13-devs/cmss13/actions/workflows/generate_documentation.yml"><img src="https://github.com/cmss13-devs/cmss13/actions/workflows/generate_documentation.yml/badge.svg"></a>
</p>

<p align="center">
	<a href="https://www.monkeyuser.com/assets/images/2019/131-bug-free.png"><img src="https://img.shields.io/badge/Built_with-Resentment-orange?style=for-the-badge&labelColor=%23D47439&color=%23C36436" width=260px></a>
	<a href="https://user-images.githubusercontent.com/8171642/50290880-ffef5500-043a-11e9-8270-a2e5b697c86c.png"><img src="https://img.shields.io/badge/Contains-Technical_Debt-blue?style=for-the-badge&color=5598D0&labelColor=62C1EE" width=280px></a> 
	<a href="https://www.reddit.com/r/SS13/comments/5oplxp/what_is_the_main_problem_with_byond_as_an_engine/dclbu1a"><img src="https://user-images.githubusercontent.com/5211576/29499758-4efff304-85e6-11e7-8267-62919c3688a9.gif"></a>
</p>


> [!IMPORTANT]
> CM-SS13 cannot be compiled exclusively using BYOND - **you must use our build tool**.<br>
> Firstly, you need to install [BYOND](https://www.byond.com/download/), and run the `bin/server.cmd` file to start the server.<br>
> You can learn more in our [Installation Guide](tools/build/README.md).

* **Website:** https://forum.cm-ss13.com/
* **Code:** https://github.com/cmss13-devs/cmss13
* **Wiki:** https://cm-ss13.com/wiki/Main_Page

This is the codebase for the CM-SS13 flavoured fork of SpaceStation 13

Space Station 13 is a paranoia-laden round-based roleplaying game set against the backdrop of a nonsensical, metal death trap masquerading as a space station, with charming spritework designed to represent the sci-fi setting and its dangerous undertones. Have fun, and survive! CM-SS13 has wildly adapted this idea into a strategic roleplay-based team deathmatch game.

## :exclamation: How to compile :exclamation:

On **2022-04-06** we have changed the way to compile the codebase.

**The quick way**. Find `bin/server.cmd` in this folder and double click it to automatically build and host the server on port 1337.

**The long way**. Find `bin/build.cmd` in this folder, and double click it to initiate the build. It consists of multiple steps and might take around 1-5 minutes to compile. If it closes, it means it has finished its job. You can then set up the server normally by opening `colonialmarines.dmb` in DreamDaemon.

**Building colonialmarines in DreamMaker directly is now deprecated and might produce errors**, such as `'tgui.bundle.js': cannot find file`.

**[How to compile in VSCode and other build options](tools/build/README.md).**

## Contributors
[Guides for Contributors](.github/CONTRIBUTING.md)

[Setting up a Development Environment](https://cm-ss13.com/wiki/Guide_to_Git)

## LICENSE

The code for CM-SS13 is licensed under the [GNU Affero General Public License v3](http://www.gnu.org/licenses/agpl.html), which can be found in full in [/LICENSE-AGPL3](/LICENSE-AGPL3).

Assets including icons and sound are under the [Creative Commons 3.0 BY-SA license](https://creativecommons.org/licenses/by-sa/3.0/) unless otherwise indicated. Authorship for assets including art and sound under the CC BY-SA license is defined as the active development team of CM-SS13 unless stated otherwise (by author of the commit).

All code is assumed to be licensed under AGPL v3 unless stated otherwise by file header. Commits before 9a001bf520f889b434acd295253a1052420860af are assumed to be licensed under GPLv3 and can be used in closed source repo.
