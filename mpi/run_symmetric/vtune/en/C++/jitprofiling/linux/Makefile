# Copyright Intel Corporation 2012
#
# To compile with the GNU* C/C++ compiler, creating executables with the
# extension ".gcc" for binary instrumentation, issue:
#
#   > make
#

SHELL = /bin/sh
srcdir = ../src

ifeq ($(shell uname -m),x86_64)
ARCHITECTURE=intel64
CFLAGS +=-m64 
LDFLAGS +=-L$(VTUNE_AMPLIFIER_XE_2013_DIR)/lib64 
else
ARCHITECTURE=x86
CFLAGS +=-m32
LDFLAGS +=-L$(VTUNE_AMPLIFIER_XE_2013_DIR)/lib32
endif

GCC      = gcc
CFLAGS  += -g -O3 -I$(VTUNE_AMPLIFIER_XE_2013_DIR)/include
LDFLAGS += -lpthread -ljitprofiling -ldl

EXE = jitprofiling

all: $(EXE)

OBJS = $(srcdir)/jitprofiling.o $(srcdir)/linux/dyncode_$(ARCHITECTURE).o

jitprofiling: $(OBJS)
	$(GCC) -g $(OBJS) -o $@  $(LDFLAGS)

clean:
	$(RM) $(OBJS)

.PHONE: all clean

# * Other names and brands may be claimed as the property of others.
