# mkproject

Create a simple project with a CMakeLists.txt, a conanfile.py and a main.cpp with verifications.

Tired of copying the conanfile.py from somewhere just to knockup a quick test using some 3:rd party thing. Alternatives like 'apt install boost' just feels so wrong and it doesn't always let you test different versions of the dependency since what you get is (usually) what was bundled with the Linux distribution, homebrew offers different versions a bit more but I don't feel it's convenient enough.

Boost and libfmt are downloaded if necessary and made available unless conan is disabled, else no 3:rd party dependencies are automatically available.

Conan is optional, pass `-p` to skip it, otherwise make sure conan is installed, https://conan.io/downloads.html. try it, it's good stuff

## Usage
```
$ mkproject.sh
```
Makes a project using conan, clang on macOS or gcc on linux and C++17

```
$ mkproject.sh -s 11 -c clang 
```
Makes a project with conan, clang on any plattform and C++11

```
$ mkproject -p
```
Make a project without conan, no 3:rd party dependencies

Your new project is built and the reqested settings are tested.

## Next step, delete all the spam in the cpp file and add your own.
