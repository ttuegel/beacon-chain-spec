K Semantics of Eth2.0 Beacon Chain
==================================

Building
--------

### Dependencies

These dependencies are pulled from [KEVM](https://github.com/kframework/evm-semantics), but with `git-lfs` added.

```sh
apt install --yes                                                           \
    autoconf bison clang-6.0 cmake curl flex gcc git-lfs libboost-test-dev  \
    libcrypto++-dev libffi-dev libjemalloc-dev libmpfr-dev libprocps-dev    \
    libsecp256k1-dev libssl-dev libtool libyaml-dev lld-6.0 llvm-6.0-tools  \
    make maven opam openjdk-8-jdk pandoc pkg-config python3 python-pygments \
    python-recommonmark python-sphinx time zlib1g-dev protobuf-compiler     \
    libprotobuf-dev
```

Build K and K's dependencies.

```sh
make deps
```

### Building

```sh
make build
```

### Testing

Get YAML test vectors:

```sh
make test-split
```

Run the tests:

```sh
make test
```