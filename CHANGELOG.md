# Changelog

Notable changes to the `mdgen`/`mdlint` port. Newest first. Every change to the
Sun 2006 C source is listed here; the source is otherwise unmodified. See the
`NOTICE:` comment in each touched file for the same information at the point of
change.

An entry that touches the tools always states whether output changed. "Verified
behaviour-neutral" means the rebuilt `mdgen` still reproduces Sun's 2006 binaries
byte for byte and all downstream configs in `github.com/unix0cc/md` rebuild
unchanged — checked, not assumed.

## 2026-07-23

### Added
- `make install`, `make install-links`, `make uninstall`. Destination is
  `$(DESTDIR)$(PREFIX)/bin`; `PREFIX` defaults to `$HOME/mdbuild` because that is
  where the one known consumer (`unix0cc/md`'s config Makefiles) looks. See
  README for `install` (copies) vs `install-links` (symlinks that track this
  checkout).

### Fixed — portability (latent on Sun's platform, live under glibc/LP64)
- **Missing `<string.h>`** in `mdgen/{mdmain,mdparse,output_bin,output_dot}.c`.
  Sun's sources include only `<strings.h>` (BSD/POSIX: `bcopy`, `strcasecmp`,
  `index`); on Solaris that also exposed the ISO C string functions, under glibc
  it does not, leaving `strlen`, `strcmp`, `memcpy`, `memmove`, `memset`,
  `memcmp` *implicitly declared* — assumed to return `int`, truncating `strlen`'s
  64-bit result and the `mem*` pointer returns. It worked only because gcc
  substitutes its own built-in prototypes; `-fno-builtin`, another compiler, or
  C23 (no implicit declarations) would break it. Behaviour-neutral.
- **Uninitialised `outfnp`** in `mdgen/mdmain.c`. Declared without an
  initialiser and read at `if (outfnp != NULL)`, but assigned only by
  `-o`/`--outfile`. The documented default (write to stdout) therefore read an
  indeterminate pointer and would have handed it to `fopen()` had the stack slot
  been non-zero. Never tripped here only because the config Makefiles always pass
  `--outfile`. Now initialised to `NULL`.
- **`uint64_t` printed with `%llx`/`%lld`** in `mdgen/{mdmain,output_dot}.c` and
  `mdlint/mdlint.c`. Correct only where `uint64_t` is `unsigned long long`; on an
  LP64 host it is `unsigned long`. Now `PRIx64`/`PRId64` from `<inttypes.h>`.
  Identical digits on this platform; behaviour-neutral.

### Fixed — correctness
- **`PE_data` unhandled** in both property switches of `mdgen/output_dot.c`, so a
  data property was silently skipped from dot output. Now handled explicitly.

### Removed — dead code (behaviour-neutral; makes a clean build silent)
- `mdlint/mdlint.c`: five unused locals in `brief_sanity()` (`nextidx`, `val`,
  `offset`, `len` byte-swapped and never read; `i` never assigned) — residue of a
  deeper check never written. The checks it does perform (node nesting,
  name-length agreement) are unchanged; output on a valid MD is byte-identical.
  `output_text()`'s identically named locals, which it does use, are untouched.
- `mdgen/mdparse.c`: `uint64_t d` (`do_assignment`), `pair_entry_t pp`
  (`parse_dag`).
- `mdgen/output_text.c`: `int fh`, `int list_end_offset`.
- `mdgen/mdlex.l`: added `%option noinput nounput` — `mdgen` calls neither
  `input()` nor `yyunput()`, so flex was emitting both to sit unused. Suppressing
  generation (rather than the warning) drops them from the binary. Fixed in the
  `.l` because `mdlex.c` is generated, not stored.

### Changed — build
- `Makefile` passes `-Wno-unknown-pragmas`. Sun's SCCS `#pragma ident` stamps
  (kept as provenance) are unimplemented by gcc and drew 65 `-Wall` warnings on a
  clean build, which had been burying the real ones above. A clean build is now
  silent; any warning is a regression.

**Net result:** clean-build warnings 105 → 0; two genuine bugs (`<string.h>`,
`outfnp`) fixed; byte-identity with Sun's 2006 binaries preserved throughout.

## 2026-07-22

### Fixed
- **Endianness branch keyed on OS, not byte order**, in the `hton*/ntoh*` macros
  of `mdgen/output_bin.c` and `mdlint/basics.h`. The original `#elif
  defined(__linux__)` swapped unconditionally on any Linux host, corrupting
  output on a big-endian Linux host (PowerPC BE, s390x), whose in-memory values
  are already correctly ordered. Now keys on the compiler's actual
  `__BYTE_ORDER__`/`__ORDER_BIG_ENDIAN__`/`__ORDER_LITTLE_ENDIAN__`. Output
  unchanged on x86_64 Linux (the only host built on here); this only affects a
  big-endian Linux host, which nobody had built on.

## Initial port (Sun 2006 source → portable GNU make + gcc)

Ported from Sun's Solaris/Sun-Studio build (`Makefile.master`, `$(TOP)`,
hardcoded `flex`, Sun-cc `-erroff`) to a single portable `Makefile`. The C source
was left as-is except for the latent little-endian byte-swap bugs below — all
invisible on Sun's big-endian SPARC hosts, where host and MD-wire byte order
coincide.

### Fixed
- `mdgen/output_bin.c`: no byte-swap definitions existed for a little-endian
  host; added `hton*/ntoh*` via `<byteswap.h>`. Separately, the `PE_int` case
  wrote `prop_val` without any `hton64()` — a real omission, not just a missing
  branch.
- `mdlint/basics.h`: the same missing `hton*/ntoh*` block (one copy per tool).
- `mdlint/mdlint.c`: compared the raw header `transport_version` instead of
  byte-swapping it first, so every binary was rejected as `"Unrecognised
  transport version"` on a little-endian host.
