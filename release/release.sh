#!/bin/bash

if test "$#" -lt 3; then
  echo "Usage: release.sh refname solvers64dir solvers32dir [compat64dir compat32dir]"
  exit 1
fi

# You need a 64 bit machine to fully build a release

if test `uname -m` != "x86_64"; then
  echo "Please run release.sh on a 64 bit machine"
  exit 1
fi

# You also need to be running it in the root ESBMC dir
stat .git > /dev/null 2>/dev/null
if test $? != 0; then
  echo "Please run release.sh in the root dir of ESBMC"
  exit 1
fi

# Check to see whether or not there's an instance for
# this version in release notes
# (Start by removing leading v)
vernum=`echo $1 | sed s#v\(.*\)#\1#`
grep "\*\*\*.*$vernum.*\*\*\*" ./release/release-notes.txt
if test $? != 0; then
  echo "Can't find an entry for $1 in release-notes.txt; you need to write one"
  exit 1
fi

satdir64=$2
satdir32=$3

# Tell the user about what version of Z3 we're about to compile with

sat64z3vernum=`$2/z3/bin/z3 -version | cut "--delim= " -f 3`
sat32z3vernum=`$3/z3/bin/z3 -version | cut "--delim= " -f 3`
echo "Compilng with Z3 versions $sat64z3vernum and $sat32z3vernum for 64 and 32 bits"

# Work out whether we're going to build compat versions.

buildcompat=0

which gcc34 > /dev/null 2>&1
if test $? = 0; then
  which g++34 > /dev/null 2>&1
  if test $? = 0; then
    buildcompat=1
  fi
fi

# If we're compiling compat, work out whether we'll be re-using the normal
# SMT solver directories, or whether there are compat-specific ones on the
# command line.
# Protip: gcc34 won't link against libgomp for some reason.
if test $buildcompat = 1; then
  satdir64compat=$4
  satdir32compat=$5
  if test "$satdir64compat" = ""; then
    satdir64compat=$sat64dir
  fi
  if test "$satdir32compat" = ""; then
    satdir32compat=$sat32dir
  fi
fi

# Find whatever the current head is
CURHEAD=`git symbolic-ref HEAD`

if test $? != 0; then
  # Not checked out a symbolic ref right now
  CURHEAD=`cat .git/HEAD`
fi

# Strip "refs/heads/" or suchlike from CURHEAD
CURHEAD=`basename $CURHEAD`

# Then, checkout whatever we've been told to release
git stash > /dev/null
git checkout $1 > /dev/null

if test $? != 0; then
  echo "Couldn't checkout $1"
  exit 1
fi

# And wrap all our modifications into a function, so that upon error we can
# cleanly remove all changes to the checked out copy.

function dobuild () {

  # Install our configuration files.
  cp ./release/config.inc .
  cp ./release/local.inc .

  # And build build build
  rm -rf .release
  mkdir .release

  # Use 64 bit libraries
  export SATDIR=$satdir64

  echo "Building 64 bit ESBMC"
  make clean > /dev/null 2>&1
  make > /dev/null 2>&1

  if test $? != 0; then
    echo "Build failed."
    return 1
  fi

  cp esbmc/esbmc .release/esbmc

  if test $buildcompat = 1; then
    echo "Building compat 64 bit ESBMC"
    export SATDIR=$satdir64compat
    make clean > /dev/null 2>&1
    env CC=gcc34 CXX=g++34 make > /dev/null 2>&1

    if test $? != 0; then
      echo "Build failed."
      return 1
    fi

    cp esbmc/esbmc .release/esbmc_compat
  fi

  # Try for 32 bits
  echo "Building 32 bit ESBMC"
  export SATDIR=$satdir32

  buildfor32bits=0
  make clean > /dev/null 2>&1

  env EXTRACFLAGS="-m32" EXTRACXXFLAGS="-m32" LDFLAGS="-m elf_i386" make > /dev/null 2>&1

  if test $? != 0; then
    echo "Buildling 32 bits failed; do you have the right headers and libraries?"
    return 1
  else
    buildfor32bits=1
    cp esbmc/esbmc .release/esbmc32
    if test $buildcompat = 1; then
      echo "Building 32 bit compat ESBMC"

      export SATDIR=$satdir32compat

      make clean > /dev/null 2>&1

      env CC=gcc34 CXX=g++34 EXTRACFLAGS="-m32" EXTRACXXFLAGS="-m32" LDFLAGS="-m elf_i386" make > /dev/null 2>&1

      if test $? != 0; then
        echo "Building 32 bit compat ESBMC failed"
        return 1
      fi

      cp esbmc/esbmc .release/esbmc32_compat
    fi
  fi

}

function cleanup () {
  echo "Cleaning up"
  make clean > /dev/null 2>&1

  # Clear anything we left behind
  git reset --hard

  # Check back out whatever ref we had before.
  git checkout $CURHEAD
  git stash pop
}

# If we get sigint/term/hup, cleanup before quitting.
trap "echo 'Exiting'; cleanup; exit 1" SIGHUP SIGINT SIGTERM

dobuild

# We now have a set of binaries (or an error)
if test $? != 0; then
  echo "Build failed"
fi

cleanup

# fini
