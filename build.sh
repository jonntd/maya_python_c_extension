#!/usr/bin/env bash

# This is the GCC build script for the Maya example Python C extension.
# usage: build.sh [debug|release]

StartTime=`date +%T`;
echo "Build script started executing at ${StartTime}...";

# Process command line arguments
BuildType=$1;

if [ "$BuildType" == "" ]; then
    BuildType="release";
fi;


# Define colours to be used for terminal output messages
RED='\033[0;31m';
GREEN='\033[0;32m';
NC='\033[0m'; # No Color


# If cleaning builds, just delete build artifacts and exit immediately
if [ "$BuildType" == "clean" ]; then
    echo "Cleaning build from directory: $BuildDir. Files will be deleted!";
    read -p "Continue? (Y/N)" ConfirmCleanBuild;
    if [ $ConfirmCleanBuild == [Yy] ]; then
       echo "Removing files in: $BuildDir...";
       rm -rf $BuildDir;
    fi;

    exit 0;
fi;


# Create a build directory to store artifacts
BuildDir="${PWD}/linuxbuild";
echo "Building in directory: $BuildDir";
if [ ! -d "$BuildDir" ]; then
   mkdir -p "$BuildDir";
fi;


# Set up globals
MayaRootDir="/usr/bin/autodesk/maya2018";
MayaIncludeDir="$MayaRootDir/include";
MayaLibraryDir="$MayaRootDir/lib";

ProjectName="maya_python_c_ext";

MayaPluginEntryPoint="${PWD}/${ProjectName}_plugin_main.cpp";
PythonModuleEntryPoint="${PWD}/${ProjectName}_py_mod_main.cpp";

# Setup all the compiler flags
CommonCompilerFlags="-DBits64_ -m64 -DUNIX -D_BOOL -DLINUX -DFUNCPROTO -D_GNU_SOURCE -DLINUX_64 -fPIC -fno-strict-aliasing -DREQUIRE_IOSTREAM -Wall -std=c++11 -Wno-multichar -Wno-comment -Wno-sign-compare -funsigned-char -pthread -Wno-deprecated -Wno-reorder -ftemplate-depth-25 -fno-gnu-keywords";

# Add the include directories for header files
CommonCompilerFlags="${CommonCompilerFlags} -I${MayaIncludeDir} -I${MayaIncludeDir}/python2.7";

CommonCompilerFlagsDebug="-ggdb -O0 ${CommonCompilerFlags}";
CommonCompilerFlagsRelease="-O3 ${CommonCompilerFlags}";

MayaPluginIntermediateObject="${BuildDir}/${ProjectName}_plugin_main.o";
PythonModuleIntermediateObject="${BuildDir}/${ProjectName}_py_mod_main.o";

MayaPluginCompilerFlagsDebug="${CommonCompilerFlagsDebug} -c ${MayaPluginEntryPoint} -o ${MayaPluginIntermediateObject}";
MayaPluginCompilerFlagsRelease="${CommonCompilerFlagsRelease} -c ${MayaPluginEntryPoint} -o ${MayaPluginIntermediateObject}";

PythonModuleCompilerFlagsDebug="${CommonCompilerFlagsDebug} -c ${PythonModuleEntryPoint} -o ${PythonModuleIntermediateObject}";
PythonModuleCompilerFlagsRelease="${CommonCompilerFlagsRelease} -c ${PythonModuleEntryPoint} -o ${PythonModuleIntermediateObject}";

# As per the Maya official Makefile:
# -Bsymbolic binds references to global symbols within the library.
# This avoids symbol clashes in other shared libraries but forces
# the linking of all required libraries.
CommonLinkerFlags="-Bsymbolic -shared -lm -ldl -lstdc++";

# Add all the Maya libraries to link against
CommonLinkerFlags="${CommonLinkerFlags} ${MayaLibraryDir}/libOpenMaya.so ${MayaLibraryDir}/libOpenMayaAnim.so ${MayaLibraryDir}/libOpenMayaFX.so ${MayaLibraryDir}/libOpenMayaRender.so ${MayaLibraryDir}/libOpenMayaUI.so ${MayaLibraryDir}/libFoundation.so ${MayaLibraryDir}/libclew.so ${MayaLibraryDir}/libImage.so ${MayaLibraryDir}/libIMFbase.so";

CommonLinkerFlagsDebug="${CommonLinkerFlags} -ggdb -O0";
CommonLinkerFlagsRelease="${CommonLinkerFlags} -O3";

MayaPluginExtension="so";
PythonModuleExtension="${MayaPluginExtension}";

MayaPluginLinkerFlagsCommon="-o ${BuildDir}/${ProjectName}_plugin.${MayaPluginExtension} ${MayaPluginIntermediateObject}";
PythonModuleLinkerFlagsCommon="-o ${BuildDir}/${ProjectName}.${PythonModuleExtension} ${PythonModuleIntermediateObject}";

MayaPluginLinkerFlagsRelease="${CommonLinkerFlagsRelease} ${MayaPluginLinkerFlagsCommon}";
MayaPluginLinkerFlagsDebug="${CommonLinkerFlagsDebug} ${MayaPluginLinkerFlagsCommon}";

PythonModuleLinkerFlagsRelease="${CommonLinkerFlagsRelease} ${PythonModuleLinkerFlagsCommon}";
PythonModuleLinkerFlagsDebug="${CommonLinkerFlagsDebug} ${PythonModuleLinkerFlagsCommon}";


if [ "$BuildType" == "debug" ]; then
    echo "Building in debug mode...";

    MayaPluginCompilerFlags="${MayaPluginCompilerFlagsDebug}";
    MayaPluginLinkerFlags="${MayaPluginLinkerFlagsDebug}";

    PythonModuleCompilerFlags="${PythonModuleCompilerFlagsDebug}";
    PythonModuleLinkerFlags="${PythonModuleLinkerFlagsDebug}";
else
    echo "Building in release mode...";

    MayaPluginCompilerFlags="${MayaPluginCompilerFlagsRelease}";
    MayaPluginLinkerFlags="${MayaPluginLinkerFlagsRelease}";

    PythonModuleCompilerFlags="${PythonModuleCompilerFlagsRelease}";
    PythonModuleLinkerFlags="${PythonModuleLinkerFlagsRelease}";
fi;


# Now build the standalone Python module first
echo "Compiling Python module (command follows)...";
echo "g++ ${PythonModuleCompilerFlags}";
echo "";

g++ ${PythonModuleCompilerFlags};

if [ $? -ne 0 ]; then
    echo -e "${RED}***************************************${NC}";
    echo -e "${RED}*      !!! An error occurred!!!       *${NC}";
    echo -e "${RED}***************************************${NC}";
    exit 1;
fi;


echo "Linking Python module (command follows)...";
echo "g++ ${PythonModuleLinkerFlags}";
echo "";

g++ -v ${PythonModuleLinkerFlags};

if [ $? -ne 0 ]; then
    echo -e "${RED}***************************************${NC}";
    echo -e "${RED}*      !!! An error occurred!!!       *${NC}";
    echo -e "${RED}***************************************${NC}";
    exit 2;
fi;


# Now build the Maya plugin
echo "Compiling Maya plugin (command follows)...";
echo "g++ ${MayaPluginCompilerFlags}";
echo "";

g++ ${MayaPluginCompilerFlags};

if [ $? -ne 0 ]; then
    echo -e "${RED}***************************************${NC}";
    echo -e "${RED}*      !!! An error occurred!!!       *${NC}";
    echo -e "${RED}***************************************${NC}";
    exit 3;
fi;

echo "Linking (command follows)...";
echo "g++ ${MayaPluginLinkerFlags}";
echo "";

g++ -v ${MayaPluginLinkerFlags};

if [ $? -ne 0 ]; then
    echo -e "${RED}***************************************${NC}";
    echo -e "${RED}*      !!! An error occurred!!!       *${NC}";
    echo -e "${RED}***************************************${NC}";
    exit 4;
fi;


echo -e "${GREEN}***************************************${NC}";
echo -e "${GREEN}*    Build completed successfully!    *${NC}";
echo -e "${GREEN}***************************************${NC}";


EndTime=`date +%T`;
echo "Build script finished execution at ${EndTime}.";

exit 0;
