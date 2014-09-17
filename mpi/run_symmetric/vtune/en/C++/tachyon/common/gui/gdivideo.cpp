/*
    Copyright 2005-2009 Intel Corporation.  All Rights Reserved.

    The source code contained or described herein and all documents related
    to the source code ("Material") are owned by Intel Corporation or its
    suppliers or licensors.  Title to the Material remains with Intel
    Corporation or its suppliers and licensors.  The Material is protected
    by worldwide copyright laws and treaty provisions.  No part of the
    Material may be used, copied, reproduced, modified, published, uploaded,
    posted, transmitted, distributed, or disclosed in any way without
    Intel's prior express written permission.

    No license under any patent, copyright, trade secret or other
    intellectual property right is granted to or conferred upon you by
    disclosure or delivery of the Materials, either expressly, by
    implication, inducement, estoppel or otherwise.  Any license under such
    intellectual property rights must be express and approved by Intel in
    writing.
*/

// common Windows parts
#include "winvideo.h"
// include GDI+ headers
#include <gdiplus.h>
// and another headers
#include <stdio.h>

// tag linking library
#pragma comment(lib, "gdiplus.lib")

// global specific variables
Gdiplus::Bitmap *           g_pBitmap;           // main drawing bitmap
ULONG_PTR                   gdiplusToken;
Gdiplus::GdiplusStartupInput gdiplusStartupInput;// GDI+

//! display system error
bool DisplayError(LPSTR lpstrErr, HRESULT hres)
{
    static bool InError = false;
    int retval = 0;
    if (!InError)
    {
        InError = true;
        LPCSTR lpMsgBuf;
        if(!hres) hres = GetLastError();
        FormatMessage( FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                               NULL, hres, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), (LPTSTR) &lpMsgBuf, 0, NULL );
        retval = MessageBox(g_hAppWnd, lpstrErr, lpMsgBuf, MB_OK|MB_ICONERROR);
        LocalFree( (HLOCAL)lpMsgBuf );
        InError = false;
    }
    return false;
}

//! Win event processing function
LRESULT CALLBACK InternalWndProc(HWND hwnd, UINT iMsg, WPARAM wParam, LPARAM lParam)
{
    switch (iMsg)
    {
        case WM_MOVE:
            // Check to make sure our window exists before we tell it to repaint.
            // This will fail the first time (while the window is being created).
            if (hwnd) {
                InvalidateRect(hwnd, NULL, FALSE);
                UpdateWindow(hwnd);
            }
            return 0L;

        case WM_PAINT:
            {
                PAINTSTRUCT ps;
                Gdiplus::Graphics graphics( BeginPaint(hwnd, &ps) );
                // redraw just requested area. This call is as fast as simple DrawImage() call.
                if(g_video->updating) graphics.DrawImage(g_pBitmap, ps.rcPaint.left, ps.rcPaint.top, ps.rcPaint.left, ps.rcPaint.top,
                                    ps.rcPaint.right, ps.rcPaint.bottom, Gdiplus::UnitPixel);
                EndPaint(hwnd, &ps);
            }
            return 0L;

        // Proccess all mouse and keyboard events
        case WM_LBUTTONDOWN:    g_video->on_mouse( (int)LOWORD(lParam), (int)HIWORD(lParam), 1); break;
        case WM_LBUTTONUP:      g_video->on_mouse( (int)LOWORD(lParam), (int)HIWORD(lParam), -1); break;
        case WM_RBUTTONDOWN:    g_video->on_mouse( (int)LOWORD(lParam), (int)HIWORD(lParam), 2); break;
        case WM_RBUTTONUP:      g_video->on_mouse( (int)LOWORD(lParam), (int)HIWORD(lParam), -2); break;
        case WM_MBUTTONDOWN:    g_video->on_mouse( (int)LOWORD(lParam), (int)HIWORD(lParam), 3); break;
        case WM_MBUTTONUP:      g_video->on_mouse( (int)LOWORD(lParam), (int)HIWORD(lParam), -3); break;
        case WM_CHAR:           g_video->on_key( (int)wParam); break;

        // some useless stuff
        case WM_ERASEBKGND:     return 1;  // keeps erase-background events from happening, reduces chop
        case WM_DISPLAYCHANGE:  return 0;

        // Now, shut down the window...
        case WM_DESTROY:        PostQuitMessage(0); return 0;
    }
    // call user defined proc, if exists
    return g_pUserProc? g_pUserProc(hwnd, iMsg, wParam, lParam) : DefWindowProc(hwnd, iMsg, wParam, lParam);
}

///////////// video functions ////////////////

bool video::init_window(int sizex, int sizey)
{
    assert(win_hInstance != 0);
    g_sizex = sizex; g_sizey = sizey;
    if (!WinInit(win_hInstance, win_iCmdShow, gWndClass, title, true)) {
        DisplayError("Unable to initialize the program's window.");
        return false;
    }
    ShowWindow(g_hAppWnd, SW_SHOW);
    Gdiplus::GdiplusStartup(&gdiplusToken, &gdiplusStartupInput, NULL);
    g_pImg = new unsigned int[sizex*sizey];
    g_pBitmap = new Gdiplus::Bitmap(g_sizex, g_sizey, 4*g_sizex, PixelFormat32bppRGB, (BYTE*)g_pImg );
    running = true;
    return true;
}

void video::terminate()
{
    if(g_pBitmap) { delete g_pBitmap; g_pBitmap = 0; }
    Gdiplus::GdiplusShutdown(gdiplusToken);
    g_video = 0; running = false;
    if(g_pImg) { delete[] g_pImg; g_pImg = 0; }
}

//////////// drawing area constructor & destructor /////////////

drawing_area::drawing_area(int x, int y, int sizex, int sizey)
: start_x(x), start_y(y), size_x(sizex), size_y(sizey), pixel_depth(24),
    base_index(y*g_sizex + x), max_index(g_sizex*g_sizey), index_stride(g_sizex), ptr32(g_pImg)
{
    assert(x < g_sizex); assert(y < g_sizey);
    assert(x+sizex <= g_sizex); assert(y+sizey <= g_sizey);

    index = base_index; // current index
}

drawing_area::~drawing_area()
{
    if(g_video->updating) {
        RECT r;
        r.left = start_x; r.right  = start_x + size_x;
        r.top  = start_y; r.bottom = start_y + size_y;
        InvalidateRect(g_hAppWnd, &r, false);
    }
}
