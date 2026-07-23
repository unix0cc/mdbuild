# mdgen / mdlint (sun4v Machine Description tools) generator


`mdgen` compiles a human-authored `.pdesc`/`.hdesc` Machine Description source file
(after `cpp` preprocessing) into the binary MDESC blob a sun4v guest/hypervisor
consumes. 

`mdlint` reads/validates/dumps an already-built binary MD.

## Provenance

Real 2006 Sun Microsystems C source, part of the OpenSPARC T1 hypervisor release
(`hypervisor/src/md/{mdgen,mdlint}`). Unmodified except for latent
little-endian portability bugs, fixed here (all invisible on Sun's original
big-endian SPARC build hosts, where host byte order and MD wire byte order
happen to coincide, masking missing/incomplete byte-swap logic):

- `mdgen/output_bin.c`: no byte-swap definitions at all existed for a
  little-endian host; added `hton*/ntoh*` via `<byteswap.h>`. Separately, the
  `PE_int` (scalar property value) case wrote `prop_val` without calling
  `hton64()` at all, even after the macro was added — a real omission, not
  just a missing platform branch.
- `mdlint/basics.h`: same missing `hton*/ntoh*` definitions as
  `mdgen/output_bin.c` (a separate copy of the identical macro block, one per
  tool).
- `mdlint/mdlint.c`: compared the raw MD header `transport_version` field
  directly instead of byte-swapping it first, so every binary was rejected as
  `"Unrecognised transport version"` on a little-endian host.

A second, unrelated portability defect was fixed on 2026-07-23 — this one a
header-visibility difference rather than an endianness one:

- `mdgen/{mdmain,mdparse,output_bin,output_dot}.c`: added `#include
  <string.h>`. Sun's sources include only `<strings.h>`, the BSD/POSIX header
  (`bcopy`, `strcasecmp`, `index`). On Solaris that also made the ISO C string
  functions visible; under glibc it does not, so `strlen()`, `strcmp()`,
  `memcpy()`, `memmove()`, `memset()` and `memcmp()` were all *implicitly
  declared* — assumed to return `int`, which truncates the 64-bit return of
  `strlen` and the pointer returns of the `mem*` family. It built and ran
  correctly only because gcc recognises these as built-ins and uses its own
  prototypes (hence its `incompatible implicit declaration of built-in
  function` warnings). That is luck, not correctness: `-fno-builtin`, a
  different compiler, or C23 — where implicit declarations were removed from
  the language — would break it. Verified behaviour-neutral: after the fix
  `mdgen` still reproduces Sun's 2006 binaries byte for byte, and all eleven
  configs in `github.com/unix0cc/md` rebuild unchanged.

**Endianness fix, corrected (2026-07-22):** the `hton*/ntoh*` macros in both
`output_bin.c` and `basics.h` originally branched on `#elif defined(__linux__)`
to decide whether to byte-swap — conflating "which OS" with "which byte
order." That's wrong on a genuine *big-endian* Linux host (PowerPC BE,
s390x, etc.): such a host's in-memory values are already correctly ordered,
same as the `_BIG_ENDIAN` case, but the old branch swapped them anyway
since it only checked the OS name, silently corrupting output. Both files
now check the compiler's actual `__BYTE_ORDER__`/`__ORDER_BIG_ENDIAN__`/
`__ORDER_LITTLE_ENDIAN__` (real GCC/Clang builtins, independent of OS)
instead. Verified byte-identical output unchanged on x86_64 Linux (the only
host this project actually builds on) after the fix — this only changes
behavior on a big-endian Linux host, which nobody had actually built on
before.

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

**Modified files:** six files differ from Sun's original release.

Little-endian fixes: `mdgen/output_bin.c`, `mdlint/basics.h`, `mdlint/mdlint.c`.
Missing `<string.h>`: `mdgen/mdmain.c`, `mdgen/mdparse.c`, `mdgen/output_dot.c`
— and `mdgen/output_bin.c` again, which carries both.

Each modified file carries an explicit `NOTICE:` comment immediately after its
original Sun header stating what changed, except `mdlint/basics.h`, which
predates that convention and has only the `hton*/ntoh*` fix. All other files
are unmodified from the original release.

**A note on `#pragma ident`:** Sun's files carry SCCS version stamps as
`#pragma ident "@(#)file.c 1.1 05/03/31 SMI"`. gcc does not implement that
pragma and `-Wall` reports it once per translation unit that sees one — 65
warnings on a clean build, enough to bury the real ones (the missing
`<string.h>` above sat under exactly that noise). The stamps are provenance,
so they are kept and the Makefile passes `-Wno-unknown-pragmas` instead.

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
