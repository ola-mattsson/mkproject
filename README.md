# mkproject

C++ is hard, starting a new project with or without 3:rd party dependencies can be too, but doesn't have to be.

Tired of copying the conanfile.py from somewhere just to knockup a quick test using some 3:rd party thing. Alternatives like 'apt install boost' just feels so wrong and it doesn't always let you test different versions of the dependency since what you get is (usually) what was bundled with the Linux distribution, homebrew offers different versions a bit more but I don't feel it's convenient enough.

Boost and libfmt are downloaded if necessary and made available unless conan is disabled, else no 3:rd party dependencies are automatically available.

Conan is optional, pass `-p` to skip it, otherwise make sure conan is installed, https://conan.io/downloads.html. try it, it's good stuff

## Why?
Because it's not very straight-forward starting a C++ project with cmake and conan. `conan new some_name/1.0`, is nice for setting up a conan project for publishing something one wants to share but if you only want to smash together a project to CONSUME shared resources you are left with a rather overwhelming mass of mess at first glance. That's not a nice experience.
It's understandable that conan focuses on publishing to help creators fill up the conan-store with good things, but the user/consumer side is somewhat lacking IMHO.

## Usage
Assuming that the compiler you request is available and works. Tested with gcc and clang, on macOS and Linux

```
$ mkproject.sh
```
Makes a project using conan, clang on macOS or gcc on Linux and C++17

```
$ mkproject.sh -s 11 -c clang 
```
Makes a project with conan, clang on any plattform and C++11.

```
$ mkproject -p
```
Makes a project without conan, i.e. no 3:rd party dependencies.

Your new project is built and the requested settings are tested.

## possible issues
Required cmake version might be newer than what is installed on your disto, edit the script and change cmake_minimum_required to what cmake just told you.

## Next step,
Delete all the spam in the cpp file and add your own, don't cargo-cult. Also the CMakeLists.txt file might need some tidying up too.
Other dependencies are found at https://conan.io/center/, or with `conan search zlib` for example. Add them to the conanfile.py in the requirements function, then rerun `conan install . -if cmake-build-debug

## Hints
If you are a bit new in unix land
Don't spam places like `/usr/local/bin` with your own scripts. Make a `~/bin` and put it in PATH with `export PATH=~/bin:$PATH`. Put scripts like this one there. (the `~` char is short hand for current users home folder, same as environment variable `$HOME`)
It's good practice to always set CC and CXX to the preferred compiler e.g. `export CXX=/usr/bin/clang++`, this helps when you have edited the c++ code and build again with for example `conan build . -bf cmake-build-debug` or `cmake --build cmake-build-debug`
Clean up the build files with `rm -fr cmake-build-debug/* `, then recreate with `conan install . -if cmake-build-debug` (or from inside the build folder ommit the `-if cmake-build-debug`, then `cmake . -B cmake-build-debug`.
Optimised release build: `mkdir cmake-build-release` `conan install . -if cmake-build-release -s settings.build_type=Release` and `conan build . -bf cmake-build-release`, or just with cmake still need to run `conan install . -if cmake-build-release` then `cmake . -B cmake-build-release -DCMAKE_BUILD_TYPE=Release` and `cmake --build -B cmake-build=release`
Confused yet? Look at the conanfile.py, the build function does cmake configure and build. Try the above and find your own way of working.

## disclaimer of sort
The script is not very polished, and I make no claims it's correct in every aspect, it helps me though. Let me know if you have suggestions to improve it.

Have fun!
