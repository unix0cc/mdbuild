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

Three more, found once the `#pragma ident` noise stopped hiding them (same
date):

- `mdgen/mdmain.c`: `outfnp` was declared without an initialiser and read
  unconditionally at `if (outfnp != NULL)`. It is assigned only by `-o` /
  `--outfile`, so the *documented* default — `-o | --outfile : output file
  (default=stdout)` — read an indeterminate pointer, and would have passed it
  to `fopen()` had the stack slot held anything but zero. A real bug that this
  project never tripped over only because its Makefiles always pass
  `--outfile`. Now initialised to `NULL`.
- `mdgen/{mdmain,output_dot}.c`, `mdlint/mdlint.c`: printed `uint64_t` values
  with `%llx`/`%lld`. That is correct only where `uint64_t` is `unsigned long
  long`; on an LP64 host it is `unsigned long`, so format and argument
  disagree. Now `PRIx64`/`PRId64` from `<inttypes.h>`. Output is unchanged on
  this platform — both spellings render the same digits — which the byte-for-
  byte rebuild below confirms.
- `mdgen/output_dot.c`: both property switches omitted `PE_data`, so a data
  property was silently skipped and nothing distinguished that from an
  oversight. Both now handle it explicitly, with a comment on why nothing is
  drawn for it.

Finally, the dead code the warnings were pointing at (same date), after which
a clean build is **completely silent**:

- `mdlint/mdlint.c`: `brief_sanity()` byte-swapped `nextidx`, `val`, `offset`
  and `len` out of every element and then never read any of them, and declared
  an `i` it never even assigned — the residue of a deeper check that was never
  written. Removed. (`output_text()` has identically named locals that it does
  use; those are untouched.) The checks `brief_sanity` really performs — node
  nesting and name-length agreement — are unchanged, and its output on a valid
  MD is byte-identical before and after.
- `mdgen/mdparse.c`: `uint64_t d` in `do_assignment()`, never used; and
  `pair_entry_t pp` in `parse_dag()`, initialised then abandoned.
- `mdgen/output_text.c`: `int fh`, never used; and `int list_end_offset`,
  assigned once after the node-offset loop and never read.
- `mdgen/mdlex.l`: added `%option noinput nounput`. `mdgen` calls neither
  `input()` nor `yyunput()`, so flex was emitting both purely to sit unused.
  Suppressing generation beats silencing the warning — the dead functions
  leave the binary. `mdlex.c` itself is generated, not stored, so the fix has
  to live in the `.l`.

None of these had a reader, so removing them is behaviour-neutral; `mdgen`
still reproduces Sun's 2006 binaries byte for byte and all eleven downstream
configs rebuild unchanged.

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

**Modified files:** eight files differ from Sun's original release.

Little-endian fixes: `mdgen/output_bin.c`, `mdlint/basics.h`, `mdlint/mdlint.c`.
Format, init and switch-coverage fixes: `mdgen/mdmain.c`, `mdgen/output_dot.c`,
`mdlint/mdlint.c`.
Dead-code removal: `mdgen/mdparse.c`, `mdgen/output_text.c`, `mdgen/mdlex.l`,
`mdlint/mdlint.c`.
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
A clean build is silent — any warning is a regression.

## Install

```sh
make install                       # -> $HOME/mdbuild/bin/
make install PREFIX=/usr/local     # -> /usr/local/bin/
make install DESTDIR=/tmp/stage    # staged, for packaging
make uninstall                     # same PREFIX/DESTDIR as the install
```

Destination is `$(DESTDIR)$(PREFIX)/bin`. `PREFIX` defaults to
`$HOME/mdbuild` rather than the usual `/usr/local`, because that is where this
tool's one known consumer looks: every config Makefile in
[`unix0cc/md`](https://github.com/unix0cc/md) hardcodes
`MDGEN ?= $(HOME)/mdbuild/bin/mdgen`. So a bare `make install` does the useful
thing here, and needs no root.

### `install` vs `install-links`

```sh
make install-links                 # symlinks into this checkout, not copies
```

`install` copies, which is what you want for a permanent install: the
destination is then independent of this working tree.

`install-links` symlinks instead, for a machine that builds from this checkout
and wants the installed tools to keep tracking it. That is worth having because
a copy goes stale silently — on the development box here the installed `mdgen`
sat four commits behind the source before anyone noticed, and nothing about a
stale copy looks wrong from the outside. Symlinking makes that drift impossible
rather than merely detectable.

The trade: `make distclean` then breaks the links. That is the better failure —
loud and immediate, rather than quietly building with an old compiler. Downstream
`scripts/verify.sh` in `unix0cc/md` reports the dangling case as "cannot verify"
(exit 2) rather than passing.

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
