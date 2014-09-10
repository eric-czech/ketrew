
Development Documentation
=========================

Build
-----

### Getting Just The Dependencies

Ketrew depends on

- `nonstd`: nano-library providing a portable extract of `Core_kernel`
- `pvem`: error monad
- `docout`: logging with `smart-print`
- `sosa`:  String module/functor
- `pvem_lwt_unix`: `Lwt_unix` wrapped in a `Pvem.t` (error monad) with more
precise error types.
- `uri`:
parse [RFC-3986](http://www.ietf.org/rfc/rfc3986.txt)-compliant URIs
(`uri` itself depends on `camlp4`).
- `cmdliner`: command line parsing
- `yojson`: JSON parsing/printing
- `atdgen/atd`: definition of serialization formats (used with `Yojson`).
- `toml`: config-file parsing
- `dbm`: unix key-value database
- `cohttp.lwt`, `ssl`, and `conduit`: HTTP server and client
- `findlib` + `dynlink`: dynamic loading of plugins 

and uses the `ocp-build` build system.

The `please.sh` script can call `opam` itself:

    ./please.sh get-dependencies

### Build

Then you may setup and build everything:

    ./please.sh build

(for incremental compilation while developping please use: `ocp-build <target>`
directly)

### Install

For now, `ketrew` uses a custom install/uninstall procedure:

    ./please.sh install <prefix>

and uninstall with:

    ./please.sh uninstall <prefix>


If you use Opam ≥ *1.2.0~beta4*, you don't need a custom opam-repository:

    ./please.sh local-opam
    opam pin add -k path ketrew .


### Build The Documentation

The documentation depends on [omd](https://github.com/ocaml/omd),
[higlo](http://zoggy.github.io/higlo/),
and Graphviz's `dot`:

    please.sh doc

and check-out `_doc/<branch>/index.html` (unless branch is `master`, then
`_doc/index.html`).

### Run a Toplevel

One can start an ocaml-toplevel (`ocaml` or `utop`) with Ketrew loaded-in:

    ./please.sh top

Tests
-----

### Automated Tests

Run the tests like this:

```bash
    ketrew_test_ssh=<Host> _obuild/ketrew-test/ketrew-test.asm [-no-color] ALL
```

where `<Host>` is often an entry in your `.ssh/config` file.

The test will indeed look for the environment variable `ketrew_test_ssh`; if
not defined it will use `"localhost"`. But for the test to succeed it should be
an SSH host for which the user running the test does not need password.
The test will run some commands on that host and create files and directories
in its `/tmp` directory.

### The `cli` Test

There is also a more interactive test:
[`src/test/cli.ml` ](../test/cli.ml) which provides
workflows to be created from the command line.

### Generating a Test Environment

In order to not impact a potential “global” installation of Ketrew, one can
use:

    ./please.sh test-env

```goodresult
Using package lwt.react add findlin-plugin
Compiling the Dummy-plugin and its user

Creating cert-key pair: _obuild/test-cert.pem, _obuild/test-key.pem
Creating _obuild/test-config-file.toml
Creating _obuild/test-authorized-tokens
Creating _obuild/test.env
```

then sourcing `_obuild/test.env` will give a few aliases to run the tests (like
`kttest`, `ktapp`, etc. see inside the file).
