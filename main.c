#include <stdio.h>
#include <SDI_compiler.h>

#include <exec/types.h>
#include <proto/exec.h>

#include <graphics/gfx.h>
#include <proto/graphics.h>
#include <devices/timer.h>
#include <proto/timer.h>

typedef unsigned long long ULONG64;

typedef void (*ini_function)(void);
typedef void (*c2p_function)(REG(a0, ULONG* from), REG(a1, ULONG* to));

typedef struct {
    ini_function init;
    c2p_function convert;
    char const*  info;
} TestCase;

typedef union {
    struct EClockVal ecv;
    ULONG64 ticks;
} ClockValue;

extern struct ExecBase * SysBase;
extern struct GfxBase * GfxBase;

ULONG clock_freq_hz = 0;

ClockValue clk_begin, clk_end;

struct TimeRequest time_request;
struct Device* TimerBase = NULL;




#define AKIKO_IDENT_ADDR ((volatile UWORD *)0x00B80002)
#define AKIKO_C2P_ADDR   (volatile ULONG *)0x00B80038
#define AKIKO_IDENT      0xCAFE

BOOL have_akiko(void) {
    return (
        GfxBase->LibNode.lib_Version >= 40 &&
        AKIKO_IDENT == *AKIKO_IDENT_ADDR
    );
}

static ULONG test_from[8] = {
    0x80808080,
    0x40404040,
    0x20202020,
    0x10101010,
    0x08080808,
    0x04040404,
    0x02020202,
    0x01010101
};

static ULONG test_to[8] = {
    0xABADCAFE,
    0xABADCAFE,
    0xABADCAFE,
    0xABADCAFE,
    0xABADCAFE,
    0xABADCAFE,
    0xABADCAFE,
    0xABADCAFE
};

extern void verify_akiko_c2p(
    REG(a0, ULONG* from),
    REG(a1, ULONG* to)
);

void verify_c2p(void) {
    verify_akiko_c2p(test_from, test_to);
    for (int i = 0; i < 8; ++i) {
        printf(
            "C[%d]: 0x%08X P[%d]: 0x%08X\n",
            i,
            test_from[i],
            i,
            test_to[i]
        );
    }
}

struct Device* get_timer(void) {
    if (OpenDevice(TIMERNAME, UNIT_MICROHZ, &time_request.tr_node, 0) != 0) {
        return NULL;
    }
    TimerBase = time_request.tr_node.io_Device;
    clock_freq_hz = ReadEClock(&clk_begin.ecv);
    printf("Got Timer, frequency is %u Hz\n", clock_freq_hz);
    return TimerBase;
}

void free_timer(void) {
    if (TimerBase) {
        CloseDevice(&time_request.tr_node);
        TimerBase = NULL;
    }
}

// This iteration sizd is equivalent to 320x256
#define BENCH_INTERATIONS 2560
#define PIXELS_PER_ITERATION 32

#define RUNS 20
#define BUFFER_SIZE (BENCH_INTERATIONS * PIXELS_PER_ITERATION)
#define BUFFER_HEIGHT (BUFFER_SIZE / 320)

extern void test_copy_320x256(
    REG(a0, ULONG* from),
    REG(a1, ULONG* to)
);

extern void test_null_c2p_320x256(
    REG(a0, ULONG* from),
    REG(a1, ULONG* to)
);

extern void test_akiko_rw_320x256(
    REG(a0, ULONG* from),
    REG(a1, ULONG* to)
);


extern void test_akiko_c2p_320x256_v1(
    REG(a0, ULONG* from),
    REG(a1, ULONG* to)
);

extern void test_akiko_c2p_320x256_v2(
    REG(a0, ULONG* from),
    REG(a1, ULONG* to)
);

extern void init_kalms_c2p_030_320x256(void);

extern void test_kalms_c2p_030_320x256(
    REG(a0, ULONG* from),
    REG(a1, ULONG* to)
);


static TestCase test_cases[] = {
    {
        NULL, test_copy_320x256,
        "Copy\n\tVanilla Fast to Chip Copy, 8 longwords at a time."
    },
    {
        NULL, test_null_c2p_320x256,
        "Null C2P\n\tChunky read from Fast and planar write to Chip, but no conversion."
    },
    {
        NULL, test_akiko_rw_320x256,
        "Akiko C2P (Limit)\n\tRegister to Akiko to Register throughput"
    },
    {
        NULL, test_akiko_c2p_320x256_v1,
        "Akiko C2P (Naive)\n\tChunky read from Fast, planar write to Chip."
    },
    {
        NULL, test_akiko_c2p_320x256_v2,
        "Akiko C2P (Buffer)\n\tChunky read from Fast, planar write to Chip, register buffer to/from Akiko."
    },
    {
        init_kalms_c2p_030_320x256, test_kalms_c2p_030_320x256,
        "Kalms C2P (c2p1x1_8_c5_030_2)\n\tChunky read from Fast, planar write to Chip."
    }
};

void benchmark_test_cases(void) {
    puts("Running Test Cases");

    UBYTE* fast_alloc = AllocVec(BUFFER_SIZE + 16, MEMF_FAST);
    if (!fast_alloc) {
        printf("\tFailed to allocate Fast Buffer (needed %d bytes)\n", BUFFER_SIZE + 16);
        goto fail;
    }

    UBYTE* chip_alloc = AllocVec(BUFFER_SIZE + 16, MEMF_CHIP);
    if (!chip_alloc) {
        printf("\tFailed to allocate Chip Buffer (needed %d bytes)\n", BUFFER_SIZE + 16);
        goto fail;
    }

    ULONG* fast_align = (ULONG*)(((ULONG)fast_alloc + 15) & ~15);
    ULONG* chip_align = (ULONG*)(((ULONG)chip_alloc + 15) & ~15);

    printf(
        "\tAllocated aligned fast buffer at %p\n\tAllocated aligned chip buffer at %p\n",
        fast_align,
        chip_align
    );

    for (int c = 0; c < sizeof(test_cases)/sizeof(TestCase); ++c) {
        ULONG total_ticks = 1; // Avoids an ugly zero check for a tiny numeric distortion

        printf("Case %d: %s\n", c, test_cases[c].info);

        // If there's any initialisation to be done, do it.
        if (test_cases[c].init) {
            puts("\tInitialisation");
            test_cases[c].init();
        } else {
            puts("\tNo initialisation needed.");
        }

        for (int i = 1; i <= RUNS; ++i) {
            printf("\tRun %d/%d...\r", i, RUNS);
            ReadEClock(&clk_begin.ecv);
            test_cases[c].convert(fast_align, chip_align);
            ReadEClock(&clk_end.ecv);
            total_ticks += (ULONG)(clk_end.ticks - clk_begin.ticks);
        }

        ULONG total_ms = (total_ticks * 1000) / clock_freq_hz;
        if (total_ms) {
            printf(
                "\n\tElapsed: %u ticks, %u ms [%d frames, %u fps]\n",
                total_ticks,
                total_ms,
                RUNS,
                (RUNS * 1000)/total_ms
            );
        } else {
            printf(
                "\n\tElapsed: %u ticks [%d frames]\n",
                total_ticks,
                RUNS
            );
        }
        ULONG64 dividend = (BUFFER_SIZE * RUNS) * (ULONG64)clock_freq_hz;
        printf("\tPerf   : %u bytes/second\n\n", (ULONG)(dividend/total_ticks));
    }

fail:
    if (fast_alloc) {
        FreeVec(fast_alloc);
    }
    if (chip_alloc) {
        FreeVec(chip_alloc);
    }
}

int main(void) {
    if (have_akiko()) {
        puts("Akiko Detected");
        verify_c2p();
        if (get_timer()) {
            benchmark_test_cases();
            free_timer();
        }
    }
    return 0;
}
