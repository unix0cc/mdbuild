# GNU-make build for mdgen/mdlint (sun4v Machine Description compiler/linter).
#
# Ported from the original 2006 Sun Microsystems Sun-Studio/Solaris build
# (Makefile.master + per-tool Makefile using $(TOP), $(COMMON_INC), Sun cc
# -erroff flags) to a plain, portable GNU make + gcc build. Source is
# otherwise unmodified except for two latent little-endian bugs fixed in
# output_bin.c and mdlint.c (see README.md) -- both invisible on Sun's
# native big-endian SPARC build hosts, where host and network byte order
# happen to coincide.

CC      ?= gcc
FLEX    ?= flex
CFLAGS  ?= -O2 -g -Wall

# Sun's sources carry SCCS version stamps as `#pragma ident "@(#)file 1.1 ..."`,
# which gcc does not implement and -Wall reports once per translation unit that
# sees them -- 65 warnings on a clean build, enough to bury real ones. The
# stamps are provenance (each file's version and date at Sun) and are kept, so
# the warning is silenced instead. Appended rather than folded into the ?= above
# so it survives a CFLAGS supplied from the environment.
CFLAGS  += -Wno-unknown-pragmas

INCLUDE := -Iinclude

BINDIR  := bin

MDGEN_SRC := \
	mdgen/mdmain.c mdgen/mdparse.c mdgen/mdlex.c \
	mdgen/output_bin.c mdgen/output_text.c mdgen/output_dot.c \
	mdgen/allocate.c mdgen/warning.c mdgen/fatal.c mdgen/vfatal.c
MDGEN_OBJ := $(MDGEN_SRC:.c=.o)

MDLINT_SRC := \
	mdlint/mdlint.c mdlint/allocate.c mdlint/warning.c \
	mdlint/fatal.c mdlint/vfatal.c
MDLINT_OBJ := $(MDLINT_SRC:.c=.o)

.PHONY: all clean distclean

all: $(BINDIR)/mdgen $(BINDIR)/mdlint

$(BINDIR):
	mkdir -p $(BINDIR)

$(BINDIR)/mdgen: $(MDGEN_OBJ) | $(BINDIR)
	$(CC) $(CFLAGS) -o $@ $(MDGEN_OBJ)

$(BINDIR)/mdlint: $(MDLINT_OBJ) | $(BINDIR)
	$(CC) $(CFLAGS) -o $@ $(MDLINT_OBJ)

# mdlex.c is generated from mdlex.l (Sun's Makefile used -Pmdlex to avoid
# yy* symbol clashes if ever linked into something with another lexer;
# kept for fidelity though mdgen is a standalone binary).
mdgen/mdlex.c: mdgen/mdlex.l
	$(FLEX) -Pmdlex -o $@ $<

%.o: %.c
	$(CC) $(CFLAGS) $(INCLUDE) -c -o $@ $<

clean:
	$(RM) $(MDGEN_OBJ) $(MDLINT_OBJ) mdgen/mdlex.c

distclean: clean
	$(RM) -r $(BINDIR)
