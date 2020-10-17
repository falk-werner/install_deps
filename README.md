# install_deps

Install C/C++ dependencies from source.

---

## Usage

    ./install_deps.sh -f deps.sh -s -c

### Command Line Options

| Option      | Description                                               |
| ----------- | --------------------------------------------------------- |
| -f filename | speficy dependency file (default: deps.sh)                |
| -s          | use `sudo` to install packages                            |
| -c          | use `checkinstall` to install packages                    |
| -d          | enable debug mode (preserves intermediate files on error) |
| -h          | print usage and exit                                      |

### Local installation (DESTDIR)

    DESTDIR=deps ./install_deps

The environment variable `DESTDIR` should be used to install packages to a
specified location. The variable will be used by `cmake` and / or `meson`
during installation.

Use of `DESTDIR` is recommendet for development purposes to not _pollute_
the system. Typicalle `DESTDIR` point to a directory next to the current
project.

### Use `checkinstall` to install packages system-wide

    ./install_deps -c -s

When packages should be installed system-wide, `checkinstall` is recommendet.
This will create a installable packages, e.g. a .deb-file, and installs it
using the package manager.  
This allows to update and or remove the package on later time.

Name and version of the installed package are taken from the dependency file.

**Note:** without `-c` flag, packages will be installed directly using
`meson` and / or `cmake` wich may _pollute_ the system.

Further information about `checkinstall` can be obtained here:  
[https://en.wikipedia.org/wiki/CheckInstall](https://en.wikipedia.org/wiki/CheckInstall)

---

## Dependency file (deps.sh)

    PACKAGES="gtest jansson fuse"
    
    gtest_VERSION=1.10.0
    gtest_URL=https://github.com/google/googletest/archive/release-${gtest_VERSION}.tar.gz
    gtest_MD5=ecd1fa65e7de707cd5c00bdac56022cd
    gtest_DIR=googletest-release-${gtest_VERSION}
    gtest_TYPE=cmake

    fuse3_VERSION=3.10.0
    fuse3_URL=https://github.com/libfuse/libfuse/archive/fuse-${fuse3_VERSION}.tar.gz
    fuse3_MD5=22aec9bc9008eea6b17e203653d1b938
    fuse3_DIR=libfuse-fuse-${fuse3_VERSION}
    fuse3_TYPE=meson
    fuse3_MESON_OPTS=-Dexamples=false

A dependency file is a `bash` script that contains the packages to install and further
information of each package. It will be sourced by install_deps.sh.

### Packages

The variable `PACKAGES` contains an ordered list of the packages to install.

The listed packages will be installed in the order they are provided. Therefore independent
packages must precede depenent ones. There is no further management of dependencies.

### Package Properties

| Property                   | Required | Description                                         |
| -------------------------- | -------- | --------------------------------------------------- |
| &lt;package&gt;_VERSION    | required | version of the package                              |
| &lt;package&gt;_URL        | required | URL of the sources; Must lead to a tar.gz file      |
| &lt;package&gt;_MD5        | required | MD5 checksum of the source package (tar.gz)         |
| &lt;package&gt;_DIR        | required | root directory of the sources of the package        |
| &lt;package&gt;_TYPE       | required | build type; must be either `cmake` or `meson`       |
| &lt;package&gt;_CMAKE_OPTS | optional | cmake only; contains cmake options (default: empty) |
| &lt;package&gt;_MESON_OPTS | optional | meson only; contains meson options (default: empty) |

---

## Embedding in github/.travis projects

    # ...
    before_install:
    - bash <(curl -s https://raw.githubusercontent.com/falk-werner/install_deps/main/install_deps.sh)

To embed `install_deps` into your github/travis project,

- create a file `deps.sh` in the root directory of your project
- add the line shown above to the `before_install` section of the `.travis` file

---

## Restrictions

Currently, only `cmake` and `meson` dependencies are supported.
