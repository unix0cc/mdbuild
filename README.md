# mdgen / mdlint (sun4v Machine Description tools) generator


`mdgen` compiles a human-authored `.pdesc`/`.hdesc` Machine Description source file
(after `cpp` preprocessing) into the binary MDESC blob a sun4v guest/hypervisor
consumes. 

`mdlint` reads/validates/dumps an already-built binary MD.

## Provenance

Real 2006 Sun Microsystems C source, part of the OpenSPARC T1 hypervisor release
(`hypervisor/src/md/{mdgen,mdlint}`). Unmodified except for two latent
little-endian portability bugs, fixed here (both invisible on Sun's original
big-endian SPARC build hosts, where host byte order and MD wire byte order
happen to coincide, masking missing/incomplete byte-swap logic):

- `mdgen/output_bin.c`: no byte-swap definitions at all existed for a
  little-endian host; added `hton*/ntoh*` via `<byteswap.h>`. Separately, the
  `PE_int` (scalar property value) case wrote `prop_val` without calling
  `hton64()` at all, even after the macro was added — a real omission, not
  just a missing platform branch.
- `mdlint/mdlint.c`: compared the raw MD header `transport_version` field
  directly instead of byte-swapping it first, so every binary was rejected as
  `"Unrecognised transport version"` on a little-endian host.

## License

Every one of the 26 source files in this repository (verified individually,
byte-for-byte identical terms across all of them) carries Sun's original 2006
license header, reproduced from `BSD+_License.txt` in the official OpenSPARC
T1 release. That text is effectively BSD 3-Clause plus one additional clause
("not designed, licensed or intended for use in... any nuclear facility").
Note: this is *not* the license the broader OpenSPARC T1 release is best
known for — the RTL/Verilog hardware model and SPARC Architecture Simulator
(the bulk of that release by far) are GPLv2, but the hypervisor source this
repository is drawn from (`hypervisor/src/`) is not; confirmed no file under
`hypervisor/src/` contains any GPL text.

The top-level `LICENSE` file is the closest standard template match, BSD
3-Clause, for tooling/license-detector compatibility. It omits Sun's nuclear
clause, which is preserved verbatim in every individual file's own header —
those per-file headers are the authoritative full text.

**Modified files:** two files differ from Sun's original release —
`mdgen/output_bin.c` and `mdlint/mdlint.c`, each fixing a latent
little-endian portability bug (see below). Both carry an explicit `NOTICE:`
comment immediately after their original Sun header stating what changed.
All other files are unmodified from the original release.

## Build (GNU make)

The original Sun Makefiles targeted Solaris/Sun Studio (`$(TOP)/Makefile.master`,
a hardcoded `flex` path, Sun-cc-only flags) and don't run as-is elsewhere. This
tree has a single portable top-level `Makefile` instead:

```sh
make            # -> bin/mdgen, bin/mdlint
make clean      # remove objects + generated lexer
make distclean   # also remove bin/
```

Requires `gcc`, GNU `make`, and `flex` (only `mdgen` needs the lexer).

## Usage

```sh
cpp -traditional-cpp input.pdesc input.pp
bin/mdgen --binary --outfile output-md.bin input.pp

bin/mdlint -t output-md.bin       # dump/validate a built MD as text
```

See `bin/mdgen --help` / `bin/mdlint --help` for full option lists
(`--text`, `--dot <arc>` graph output, etc.).

## Context

Built and used as part of the qemu-sparc64 Niagara/T1000 emulation project,
based on Sun's Legion simulator source (the OpenSPARC T1 hypervisor/OBP
firmware this repository's tools were originally built to serve). This
project is provided "as is," without warranty of any kind, express or
implied — see LICENSE.
