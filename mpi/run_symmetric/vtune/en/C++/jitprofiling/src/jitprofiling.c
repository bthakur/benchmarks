/*****************************************************************************
 *
 * Copyright 2011 Intel Corporation All Rights Reserved.
 *
 * The source code contained or described herein and all documents related
 * to the source code ("Material") are owned by Intel Corporation or its
 * suppliers or licensors.  Title to the Material remains with Intel
 * Corporation or its suppliers and licensors.  The Material contains
 * trade secrets and proprietary and confidential information of Intel
 * or its suppliers and licensors.  The Material is protected by worldwide
 * copyright and trade secret laws and treaty provisions.  No part of the
 * Material may be used, copied, reproduced, modified, published, uploaded,
 * posted, transmitted, distributed, or disclosed in any way without
 * Intel's prior express written permission.
 *
 * No license under any patent, copyright, trade secret or other
 * intellectual property right is granted to or conferred upon you by
 * disclosure or delivery of the Materials, either expressly, by
 * implication, inducement, estoppel or otherwise.  Any license under such
 * intellectual property rights must be express and approved by Intel in
 * writing.
 *
 ****************************************************************************/

#include "jitprofiling.h"

#ifdef _WIN32
#include <tchar.h>
#endif
#include <stdio.h>
#include <stdlib.h>
#include <malloc.h>
#include <memory.h>

#ifdef _WIN32
#include <windows.h>
#endif

#ifdef _WIN32
#define decl _cdecl
#else
#define decl
#endif

typedef void (decl *FNSPLITHOTSPOT)(void**, unsigned);
typedef void (decl *FNHOTSPOT)(void);

extern void split_proc();
extern void dyn_hotspot1();
extern void dyn_hotspot2();
extern unsigned g_split_proc_size;
extern unsigned g_dyn_hotspot1_size;
extern unsigned g_dyn_hotspot2_size;

void* allocate_code_range(unsigned size)
{
    void* addr = 0;
    if(size)
    {
    #ifdef _WIN32
        addr = VirtualAlloc(NULL, size, MEM_COMMIT, PAGE_EXECUTE_READWRITE);
    #else
        addr = malloc(size);
    #endif
    }
    return addr;
}

void free_code_range(void* p)
{
#ifdef _WIN32
    VirtualFree(p, 0, MEM_RELEASE);
#else
    free(p);
#endif
}

void* create_jit_proc_body()
{
    void* addr = allocate_code_range(g_split_proc_size);
    memcpy(addr, (void*)split_proc, g_split_proc_size);
    return addr;
}

void copy_jit_code_range(void* dest, const void* code, unsigned int code_size)
{
    if (dest) memcpy(dest, code, code_size);
}

int main()
{
    unsigned range_num = 3;
    unsigned i = 0;
    void** ranges = 0;
    FNSPLITHOTSPOT jit_func = 0;

    /* The profiler stuff */
    int rc = 0;
    iJIT_IsProfilingActiveFlags agent;
    iJIT_Method_Load jmethod = {0};

    /* Get the current mode of the profiler and check that it is sampling */
    agent = iJIT_IsProfilingActive();
    if(agent != iJIT_SAMPLING_ON)
    {
        printf("JIT profiler is not active\n");
    }

    /*Fill method information */
    jmethod.method_id = iJIT_GetNewMethodID();
    jmethod.method_name = "SplitProc(void)";
    jmethod.class_file_name = "JITter";
    jmethod.source_file_name = "jitter.cpp";

    jit_func = (FNSPLITHOTSPOT)create_jit_proc_body();

    jmethod.method_load_address = jit_func;
    jmethod.method_size = g_split_proc_size;
    jmethod.line_number_size = 0;

    iJIT_NotifyEvent(iJVM_EVENT_TYPE_METHOD_LOAD_FINISHED, (void*)&jmethod);

    jmethod.method_id = iJIT_GetNewMethodID();
    jmethod.method_name = "DynamicHotspotFunction(void)";
    jmethod.class_file_name = "JITter";

    /* Create several non-overlapped code ranges allocated at different addresses */
    ranges = (void**)malloc(range_num * sizeof(void*));
    for (i = 0; i < range_num; i++)
    {
        ranges[i] = allocate_code_range(g_dyn_hotspot1_size);
        copy_jit_code_range(ranges[i], dyn_hotspot1, g_dyn_hotspot1_size);

        /* Send method load notifications for all code ranges */
        jmethod.method_load_address = ranges[i];
        jmethod.method_size = g_dyn_hotspot1_size;
        jmethod.line_number_size = 3;
        jmethod.line_number_table =
            (LineNumberInfo*)malloc(sizeof(LineNumberInfo)*jmethod.line_number_size);
        jmethod.line_number_table[0].Offset = 5+i;
        jmethod.line_number_table[0].LineNumber = 2+i;
        jmethod.line_number_table[1].Offset = 8+i;
        jmethod.line_number_table[1].LineNumber = 5+i;
        jmethod.line_number_table[2].Offset = 11+i;
        jmethod.line_number_table[2].LineNumber = 8+i;

        iJIT_NotifyEvent(iJVM_EVENT_TYPE_METHOD_LOAD_FINISHED, (void*)&jmethod);

        free(jmethod.line_number_table);
    }

    printf("The hotspot function is executing ...\n");
    jit_func(&ranges[0], range_num);
    printf("Executed the hotspot function\n");

    /* One of the code ranges is rejited while the jit function is executed.
       The re-jited code range is started from the same location when it
       took prior */
    copy_jit_code_range(ranges[i - 1], dyn_hotspot2, g_dyn_hotspot2_size);

    /* Send method load notifications for re-jited code range */
    jmethod.method_load_address = ranges[i - 1];
    jmethod.method_size = g_dyn_hotspot2_size;
    jmethod.line_number_size = 2;
    jmethod.line_number_table =
        (LineNumberInfo*)malloc(sizeof(LineNumberInfo)*jmethod.line_number_size);
    jmethod.line_number_table[0].Offset = 7;
    jmethod.line_number_table[0].LineNumber = 5;
    jmethod.line_number_table[1].Offset = 15;
    jmethod.line_number_table[1].LineNumber = 25;

    iJIT_NotifyEvent(iJVM_EVENT_TYPE_METHOD_LOAD_FINISHED, (void*)&jmethod);

    free(jmethod.line_number_table);

    printf("One of ranges has been re-jited. The hotspot function is executing again ...\n");
    jit_func(&ranges[0], range_num);
    printf("Executed the hotspot function\n");

    /* Destroy the profiler */
    iJIT_NotifyEvent(iJVM_EVENT_TYPE_SHUTDOWN, NULL);

    for (i = 0; i < range_num; i++)
    {
        free_code_range(ranges[i]);
    }
    free(ranges);
    free_code_range(jit_func);

    return 1;
}
