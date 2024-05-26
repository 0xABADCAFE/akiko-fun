#include <stdio.h>
#include <SDI_compiler.h>

#include <exec/types.h>
#include <proto/exec.h>

#include <graphics/gfx.h>
#include <proto/graphics.h>
#include <devices/timer.h>
#include <proto/timer.h>

typedef unsigned long long ULONG64;

extern struct ExecBase * SysBase;
extern struct GfxBase * GfxBase;

typedef union {
    struct EClockVal ecv;
    ULONG64 ticks;
} ClockValue;

ClockValue clk_begin, clk_end;

struct TimeRequest time_request;

struct Device* TimerBase = NULL;

extern void test_akiko_c2p(
    REG(a0, ULONG* from),
    REG(a1, ULONG* to)
);

extern void bench_akiko_rw(REG(d0, ULONG reps));

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

void verify_c2p(void) {
    test_akiko_c2p(test_from, test_to);
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
    return (TimerBase = time_request.tr_node.io_Device);
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

void benchmark_rw(void) {
    ULONG total_ticks = 0;
    ULONG freq = ReadEClock(&clk_begin.ecv);
    printf(
        "Benchmarking Akiko Read/Write (reg -> hw -> reg) with %d loops, %d bytes per loop.\n"
        "Using EClock, reported rate is %u Hz\n",
        BENCH_INTERATIONS,
        PIXELS_PER_ITERATION,
        freq
    );

    for (int i = 1; i <= RUNS; ++i) {
        printf("Run %d/%d...\n", i, RUNS);
        ReadEClock(&clk_begin.ecv);
        bench_akiko_rw(BENCH_INTERATIONS);
        ReadEClock(&clk_end.ecv);
        ULONG elapsed = (ULONG)(clk_end.ticks - clk_begin.ticks);
        ULONG elapsed_ms = (elapsed * 1000) / freq;

        printf(
            "\tBegin:   %llu ticks\n"
            "\tFinish:  %llu ticks\n"
            "\tElapsed: %u ticks (%u ms)\n",
            clk_begin.ticks,
            clk_end.ticks,
            elapsed,
            elapsed_ms
        );
        total_ticks += elapsed;
    }

    ULONG total_ms = (total_ticks * 1000) / freq;
    printf(
        "\nElapsed: %u ticks, %u ms [%d frames, %u fps]\n",
        total_ticks,
        total_ms,
        RUNS,
        (RUNS * 1000)/total_ms
    );
    ULONG64 dividend = (BENCH_INTERATIONS * PIXELS_PER_ITERATION * RUNS) * (ULONG64)freq;
    printf("\nPerf:    %u bytes/second\n", (ULONG)(dividend/total_ticks));
}

int main(void) {
    if (have_akiko()) {
        puts("Akiko Detected");
        verify_c2p();
        if (get_timer()) {
            benchmark_rw();
            free_timer();
        }
    }
    return 0;
}
