# mkproject

Create a simple project with a CMakeLists.txt, a conanfile.py and a main.cpp with verifications.

Tired of copying the conanfile.py from somewhere just to knockup a quick test using some 3:rd party thing. Alternatives like 'apt install boost' just feels so wrong and it doesn't always let you test different versions of the dependency since what you get is (usually) what was bundled with the Linux distribution, homebrew offers different versions a bit more but I don't feel it's convenient enough.

Boost and libfmt are downloaded if necessary and made available unless conan is disabled, else no 3:rd party dependencies are automatically available.

Conan is optional, pass `-p` to skip it, otherwise make sure conan is installed, https://conan.io/downloads.html. try it, it's good stuff

## Why?
Because it's not very straight-forward starting a C++ project with cmake and conan. `conan new some_name/1.0`, is nice for setting up a conan project for publishing something one wants to share but if you only want to smash together a project to CONSUME shared resources you are left with a rather overwhelming mass of mess at first glance. That's not a nice experience.
It's understandable that conan focuses on publishing to help creators fill up the conan-store with good things, but the user/consumer side is somewhat lacking IMHO.

## Usage
Assuming only the compiler you request is available and works. Tested with gcc and clang, on macOS and Linux

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

## Next step,
Delete all the spam in the cpp file and add your own, don't cargo-cult. Also the CMakeLists.txt file might need some tidying up too.

Have fun!
