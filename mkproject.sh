#!/usr/bin/env bash

set -o errexit
# set -o nounset
set -o pipefail

# Tired of copying the conanfile.py from somewhere just to
# knockup a quick test using some 3:rd party thing. 
# Alternatives like 'apt install boost' just feels so wrong and it doesn't
# always let you test different versions of the dependency since what you get
# is (usually) what was bundled with the Linux distribution, homebrew offers
# different versions a bit more but I don't feel it's convenient enough.
#
# Generate a C++ project with CMake and optionally conan
# mkproject.sh -n name -s NN -c compiler
#
# -s XX may be any valid C++ standard, defaults to 17
# -c which compiler to use, defaults to clang++ on macOS and gcc on Linux.
# -p don't use conan (defaults to use conan)
#
# using clang++ will default to libc++ and g++ to libstdc++(11)
#
#

print_usage() {
  echo "usage: $0 -n NAME [-s <98 | 11 | 14 | 17 | 20 | 23> ] [ -c <clang | gcc>] [-p] [-h]"
  echo "-c the compiler. Tested with clang, default on macOS, and gcc, default on Linux"
  echo "-p do not use conan"
  echo "-h print this help"
  echo
  echo "This script creates a project with a cpp example, CMakeLists.txt and optionally a conanfile.py,
running again overwrites the files."
  echo "When using conan, a conan profile is created, that is useful for subsequent builds for the same settings".
  echo "the main.cpp file contains some verifications that the requested compiler and C++ standard is actually used"
  exit 1
}

contains_element () {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  print_usage
}

# defaults
case "$(uname -s)" in
    Darwin)
        NAME=darwin_test
        COMPILER=clang
        STD_LIB=libc++
        ;;
    Linux)
        NAME=linux_test
        COMPILER=gcc
        CPP_STD=17
        STD_LIB=libstdc++
        ;;
    *)
        NAME=wthaw_test
esac

CPP_STD=17
USE_CONAN=1

while getopts ":c:s:n:hp" opt; do
  case $opt in
    c)
      COMPILER=$OPTARG
      ;;
    s)
      CPP_STD=$OPTARG
      ;;
    p)
      USE_CONAN=0
      ;;
    n)
      NAME=$OPTARG
      ;;
   h | *)
      print_usage
      ;;
  esac
done
shift $((OPTIND - 1))

echo "Create project $NAME, C++ standard $CPP_STD, compiler $COMPILER"
# check if the compiler is installed and in PATH
if ! command -v $COMPILER &> /dev/null
then
    echo "Compiler $COMPILER could not be found"
    exit 1
fi

# if compiler was specified, make sure it's a known one
if [ $CPP_STD -ne 17 ]; then
  STANDARDS=("98" "03" "11" "14" "17" "20" "23")
  contains_element "$CPP_STD" "${STANDARDS[@]}"
fi

if [ $USE_CONAN -eq 1 ] && [ $CPP_STD -lt 17 ] || [ $CPP_STD -eq 98 ]; then
  echo "Setup boost"
  BOOST_CONAN_REQ='self.requires("boost/1.76.0")'
  BOOST_INCLUDE='#include <boost/utility/string_view.h>'
  BOOST_FIND_PACKAGE='find_package(Boost REQUIRED)'
  BOOST_ALIAS_TARGET='Boost::boost'
else
  BOOST_CONAN_REQ=""
  BOOST_INCLUDE=""
  BOOST_FIND_PACKAGE=""
  BOOST_ALIAS_TARGET=""
fi
#echo $CPP_STD

if [ $USE_CONAN -eq 1 ] && [ $CPP_STD -ne 98 ]; then
  echo "Setup fmt"
  FMT_CONAN_REQ='self.requires("fmt/9.0.0")'
  FMT_INCLUDE='#include <fmt/core.h>'
  FMT_FIND_PACKAGE='find_package(fmt REQUIRED)'
  FMT_ALIAS_TARGET='fmt::fmt'
else
  FMT_CONAN_REQ=""
  FMT_INCLUDE=""
  FMT_FIND_PACKAGE=""
  FMT_ALIAS_TARGET=""
fi

if [ "$COMPILER" == "g++" ] || [ "$COMPILER" == "gcc" ]; then
  if [ $CPP_STD -eq 98 ]; then
    STD_LIB=libstdc++
  else
    STD_LIB=libstdc++11
  fi
fi


if [ $USE_CONAN -eq 1 ]; then
###############################################
## dump out a simple conanfile.py

echo 'from conans import ConanFile, CMake


class '${NAME}'Conan(ConanFile):
    name = "'$NAME'"
    settings = "cppstd", "os", "compiler", "build_type", "arch"
    generators = "cmake_find_package", "CMakeToolchain"
    default_options = {
        "fmt:header_only": True,
        "boost:zlib": False,
        "boost:header_only": True,
        "libssh2:shared": False,
        "openssl:shared": False,
    }
    
    def requirements(self):
        '${FMT_CONAN_REQ}'
        '${BOOST_CONAN_REQ}'

    def build_requirements(self):
        self.requires("cmake/3.21.4")

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()
' > conanfile.py

    CONAN_MOD_PATH='list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_BINARY_DIR})'
    [[ $CPP_STD -gt 98 ]] && USE_FMT=USE_FMT
fi

###############################################
## dump out a simple CMakeLists.txt

echo 'cmake_minimum_required(VERSION 3.22)

if (CMAKE_EXPORT_NO_PACKAGE_REGISTRY)
message(STATUS " Conan provided variables:
   CMAKE_EXPORT_NO_PACKAGE_REGISTRY ${CMAKE_EXPORT_NO_PACKAGE_REGISTRY}
   CMAKE_INSTALL_BINDIR ${CMAKE_INSTALL_BINDIR}
   CMAKE_INSTALL_DATAROOTDIR ${CMAKE_INSTALL_DATAROOTDIR}
   CMAKE_INSTALL_INCLUDEDIR ${CMAKE_INSTALL_INCLUDEDIR}
   CMAKE_INSTALL_LIBDIR ${CMAKE_INSTALL_LIBDIR}
   CMAKE_INSTALL_LIBEXECDIR ${CMAKE_INSTALL_LIBEXECDIR}
   CMAKE_INSTALL_OLDINCLUDEDIR ${CMAKE_INSTALL_OLDINCLUDEDIR}
   CMAKE_INSTALL_SBINDIR ${CMAKE_INSTALL_SBINDIR}
   -------------------------------
   CONAN_CMAKE_CXX_EXTENSIONS ${CONAN_CMAKE_CXX_EXTENSIONS}
   CONAN_CMAKE_CXX_STANDARD ${CONAN_CMAKE_CXX_STANDARD}
   CONAN_COMPILER_VERSION ${CONAN_COMPILER_VERSION}
   CONAN_CXX_FLAGS ${CONAN_CXX_FLAGS}
   CONAN_C_FLAGS ${CONAN_C_FLAGS}
   CONAN_EXPORTED ${CONAN_EXPORTED}
   CONAN_IN_LOCAL_CACHE ${CONAN_IN_LOCAL_CACHE}
   CONAN_LIBCXX ${CONAN_LIBCXX}
   CONAN_SHARED_LINKER_FLAGS ${CONAN_SHARED_LINKER_FLAGS}
   CONAN_STD_CXX_FLAG ${CONAN_STD_CXX_FLAG}
   CONAN_COMPILER ${CONAN_COMPILER}")
endif()

#set(CMAKE_CXX_COMPILER ${CONAN_COMPILER})
#set(CXX_STANDARD ${CONAN_CMAKE_CXX_STANDARD})
project('$NAME'_Project LANGUAGES CXX)

'$CONAN_MOD_PATH'
'$FMT_FIND_PACKAGE'
'$BOOST_FIND_PACKAGE'

# setup compiler, depend on this for all targets unless you need something else elsewhere.
# put this in its own file and include it with "include(your_own_compiler_setup.cmake)"
add_library(compiler INTERFACE)
add_library(compiler::compiler ALIAS compiler)
# the chosen C++ standard
set(STD '$CPP_STD')
set(CMAKE_CXX_STANDARD 98) # this must be initialised, it will be the minimal standard
set(CMAKE_CXX_STANDARD_REQUIRED ON)
# this will only work (be inherited by consumers) if CMAKE_CXX_STANDARD was set to something
target_compile_features(compiler INTERFACE cxx_std_${STD})
#set(CMAKE_CXX_EXTENSIONS OFF)

# Platforms such as Linux where libc++ is not the default needs some help
#set(LIBCPP "$<IF:$<BOOL:${APPLE}>,,-stdlib=libc++;libc++abi>")
set(LIBCPP "")

set(LINUX $<STREQUAL:${CMAKE_SYSTEM_NAME},Linux>)
set(DARWIN $<STREQUAL:${CMAKE_SYSTEM_NAME},Darwin>)

find_package(Threads REQUIRED)
target_link_libraries(compiler
        INTERFACE
        Threads::Threads
        ${LIBCPP}
        )
target_compile_options(compiler
        INTERFACE
        ${LIBCPP}
        )
target_compile_definitions(compiler
        INTERFACE
#        $<${LINUX}:LINUX>
#        $<${DARWIN}:DARWIN>
        '$USE_FMT'
        $<$<CONFIG:Debug>:LIBCXX_ENABLE_ASSERTIONS=ON>
        )

add_executable('$NAME')

target_sources('$NAME'
        PRIVATE
        main.cpp
        )

target_link_libraries('$NAME'
        PRIVATE
        compiler::compiler
        '$FMT_ALIAS_TARGET'
        '$BOOST_ALIAS_TARGET'
        )
' > CMakeLists.txt

###############################################
## dump out a simple CMakeLists.txt
echo '
// generated by '$0' @ '$(date)'
/* 
    Test the setup, this is just verifying that stuff was made available
    as requested, compiles and links.
    IF conan is requested
        IF < C++17
            get string_view from boost
        ELSE
            use std::string_view
        IF fmt is requested
            include fmt
        else use iostream
    else no conan
        use no 3:rd party

    Just delete what is not needed
    libfmt is awesome and in the C++20 standard but not implemented in all compilers

    Tested with gcc and clang on macOS and Linux
*/

#include <vector>
#include <iostream>

#if defined USE_FMT
# include <fmt/core.h>
#endif

#if '$USE_CONAN'
# if __cplusplus < 201703L
#  include <boost/utility/string_view.hpp>
   typedef boost::string_view string_view;
# else
#  include <string_view>
   typedef std::string_view string_view;
# endif
#else
  typedef std::string string_view;
#endif


int main(int argc, char** argv) {
  std::vector<string_view> args(argv, argv + argc);
#if __cplusplus < 201103L
    std::cout << "Hey! " << __cplusplus << " Seriously, :/ !\n";

# if defined __clang__
    std::cout << "compiler is clang++" << "\n";
# elif __GNUC__
    std::cout << "compiler is g++" << "\n";
# endif

#else
# if defined __clang__
    if (args.at(1) == "clang") {
        std::cout << "compiler is " << args.at(1) << "\n";
    } else {
        std::cout << "\033[0;31mCompiler NOT THE REQUESTED " << args.at(1) << "/'$COMPILER' \033[0m\n";
    }
# elif __GNUC__
    if (args.at(1) == "gcc") {
        std::cout << "compiler is " << args.at(1) << "\n";
    } else {
        std::cout << "\033[0;31mCompiler NOT THE REQUESTED " << args.at(1) << "/'$COMPILER' \033[0m\n";
    }
# endif
    std::cout << "Hey C++ " << __cplusplus << ", lets go!\n";

#endif
}
' > main.cpp
if [ "$COMPILER" == "gcc" ]; then
  # CONAN_COMP_VER=$($COMPILER -dumpversion)
  # gcc is clang on macOS by default, this is convenient in some cases but if
  # the real gcc is required gcc needs to be installed separatedly, e.g. with Homebrew or MacPorts.
  # Still, conan will prefer the one pointed to by env var CXX find the clang-wrapped one even if it's first found in PATH.
  # So, lets help conan find the real one, this assumes running gcc in the command
  # line finds the real gcc, i.e. for homebrew /usr/local/bin and for MacPorts /opt/local/bin is
  # before /usr/bin in PATH.
  GLOBAL_CXX=$CXX
  CXX=$(which g++)
  CC=$(which gcc)
  if [[ "$($CXX --version | grep -i "free software")" ]]; then
    echo "found $CXX"
    if [[ "$CXX" != $GLOBAL_CXX ]]; then
        echo -e "\033[0;31mThe CXX variable is not set to gcc. conan install/build may find compiler from CXX if $CXX is not passed with -e"
        echo -e "\033[0;32m This script will run conan install/build with -e $CXX but unless you do that, the project will build with \$CXX=$GLOBAL_CXX instead"
        echo -e "\033[0;32m Also, if opening the project in clion, make sure to pick a toolchain you expect since that will do the same thing as \$CXX."
        echo -e "\033[0;34m--------------------------------------------------------------------------------------------------------------------------\033[0m"
    fi
  else
    echo "\033[0;31mfound clang wrapped gcc! You may need to install gcc"
  fi
elif [ "$COMPILER" == "clang" ]; then
  CXX=$(which clang++)
  CC=$(which clang)
fi

PROFILE_NAME=$(basename -- "$0")
PROFILE_NAME="file_${PROFILE_NAME%.*}"
if [[ $USE_CONAN -eq 1 ]]; then
    conan profile new --detect --force $PROFILE_NAME
    [[ "$COMPILER" == "gcc" ]] && conan profile update settings.compiler.libcxx=libstdc++11 $PROFILE_NAME

    conan profile update settings.cppstd=$CPP_STD $PROFILE_NAME

    test -d "cmake-build-debug" || mkdir cmake-build-debug
    conan install . -if cmake-build-debug --build=missing -pr $PROFILE_NAME || exit 1

    conan build . -bf cmake-build-debug || exit 1

    echo -e "\e[3;28mCreated conan profile\e[0m \e[4;28m$PROFILE_NAME.\e[0m\e[5;33m Use\e[0m it with \e[3;28m\`conan install . -if cmake-build -pr $PROFILE_NAME\` \e[0m"
else
    mkdir cmake-build-debug
    cmake . -B cmake-build-debug -DCMAKE_BUILD_TYPE=Debug
    cmake --build cmake-build-debug
fi
echo -e "\033[0;31m Test it ------------------------"
cmake-build-debug/$NAME $COMPILER $CPP_STD || exit 1
echo -e "\e[3;28m------------------------\033[0m"
