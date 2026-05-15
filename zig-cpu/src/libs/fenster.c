#include "fenster.h"

#if defined(_WIN32)
// clang-format off
static const uint8_t FENSTER_KEYCODES[] = {0,27,49,50,51,52,53,54,55,56,57,48,45,61,8,9,81,87,69,82,84,89,85,73,79,80,91,93,10,0,65,83,68,70,71,72,74,75,76,59,39,96,0,92,90,88,67,86,66,78,77,44,46,47,0,0,0,32,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,17,3,0,20,0,19,0,5,18,4,26,127};
// clang-format on
typedef struct BINFO {
  BITMAPINFOHEADER bmiHeader;
  DWORD bmiMasks[3];
} BINFO;

static LRESULT CALLBACK fenster_wndproc(HWND hwnd, UINT msg, WPARAM wParam,
                                        LPARAM lParam) {
  struct fenster *f = (struct fenster *)GetWindowLongPtr(hwnd, GWLP_USERDATA);
  switch (msg) {
  case WM_PAINT: {
    PAINTSTRUCT ps;
    HDC hdc = BeginPaint(hwnd, &ps);
    BINFO bi = {0};
    bi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    bi.bmiHeader.biWidth = f->width;
    bi.bmiHeader.biHeight = -f->height;
    bi.bmiHeader.biPlanes = 1;
    bi.bmiHeader.biBitCount = 32;
    bi.bmiHeader.biCompression = BI_BITFIELDS;
    bi.bmiMasks[0] = 0x00ff0000;
    bi.bmiMasks[1] = 0x0000ff00;
    bi.bmiMasks[2] = 0x000000ff;
    SetDIBitsToDevice(hdc, 0, 0, f->width, f->height, 0, 0, 0, f->height,
                      f->buf, (BITMAPINFO *)&bi, DIB_RGB_COLORS);
    EndPaint(hwnd, &ps);
  } break;
  case WM_CLOSE:
    DestroyWindow(hwnd);
    break;
  case WM_LBUTTONDOWN:
    f->mouse |= 1;
    break;
  case WM_LBUTTONUP:
    f->mouse &= ~1;
    break;
  case WM_RBUTTONDOWN:
    f->mouse |= 2;
    break;
  case WM_RBUTTONUP:
    f->mouse &= ~2;
    break;
  case WM_MOUSEMOVE:
    f->y = HIWORD(lParam), f->x = LOWORD(lParam);
    break;
  case WM_KEYDOWN:
  case WM_KEYUP: {
    (void)wParam;
    f->mod = ((GetKeyState(VK_CONTROL) & 0x8000) >> 15) |
             ((GetKeyState(VK_SHIFT) & 0x8000) >> 14) |
             ((GetKeyState(VK_MENU) & 0x8000) >> 13) |
             (((GetKeyState(VK_LWIN) | GetKeyState(VK_RWIN)) & 0x8000) >> 12);
    f->keys[FENSTER_KEYCODES[HIWORD(lParam) & 0x1ff]] = !((lParam >> 31) & 1);
  } break;
  case WM_DESTROY:
    PostQuitMessage(0);
    break;
  default:
    return DefWindowProc(hwnd, msg, wParam, lParam);
  }
  return 0;
}

int fenster_open(struct fenster *f) {
  HINSTANCE hInstance = GetModuleHandle(NULL);
  DWORD ex_style = f->fullscreen ? WS_EX_APPWINDOW : WS_EX_CLIENTEDGE;
  DWORD style = f->fullscreen
                    ? WS_POPUP
                    : (WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX |
                       WS_MAXIMIZEBOX);
  RECT rect = {0, 0, f->width, f->height};
  int window_width, window_height;
  int x, y;
  WNDCLASSEX wc = {0};
  wc.cbSize = sizeof(WNDCLASSEX);
  wc.style = CS_VREDRAW | CS_HREDRAW;
  wc.lpfnWndProc = fenster_wndproc;
  wc.hInstance = hInstance;
  wc.lpszClassName = f->title;
  RegisterClassEx(&wc);

  if (f->fullscreen) {
    window_width = f->width;
    window_height = f->height;
    x = 0;
    y = 0;
  } else {
    AdjustWindowRectEx(&rect, style, FALSE, ex_style);
    window_width = rect.right - rect.left;
    window_height = rect.bottom - rect.top;
    x = (GetSystemMetrics(SM_CXSCREEN) - window_width) / 2;
    y = (GetSystemMetrics(SM_CYSCREEN) - window_height) / 2;
    if (x < 0)
      x = 0;
    if (y < 0)
      y = 0;
  }

  f->hwnd = CreateWindowEx(
      ex_style, f->title, f->title, style, x, y, window_width, window_height,
      NULL, NULL, hInstance, NULL);

  if (f->hwnd == NULL)
    return -1;
  SetWindowLongPtr(f->hwnd, GWLP_USERDATA, (LONG_PTR)f);
  ShowWindow(f->hwnd, SW_NORMAL);
  UpdateWindow(f->hwnd);
  return 0;
}

void fenster_close(struct fenster *f) { (void)f; }

int fenster_loop(struct fenster *f) {
  MSG msg;
  while (PeekMessage(&msg, NULL, 0, 0, PM_REMOVE)) {
    if (msg.message == WM_QUIT)
      return -1;
    TranslateMessage(&msg);
    DispatchMessage(&msg);
  }
  InvalidateRect(f->hwnd, NULL, FALSE);
  return 0;
}

void fenster_sleep(int64_t ms) { Sleep(ms); }

int64_t fenster_time(void) {
  LARGE_INTEGER freq, count;
  QueryPerformanceFrequency(&freq);
  QueryPerformanceCounter(&count);
  return (int64_t)(count.QuadPart * 1000.0 / freq.QuadPart);
}

#else
// clang-format off
static int FENSTER_KEYCODES[124] = {XK_BackSpace,8,XK_Delete,127,XK_Down,18,XK_End,5,XK_Escape,27,XK_Home,2,XK_Insert,26,XK_Left,20,XK_Page_Down,4,XK_Page_Up,3,XK_Return,10,XK_Right,19,XK_Tab,9,XK_Up,17,XK_apostrophe,39,XK_backslash,92,XK_bracketleft,91,XK_bracketright,93,XK_comma,44,XK_equal,61,XK_grave,96,XK_minus,45,XK_period,46,XK_semicolon,59,XK_slash,47,XK_space,32,XK_a,65,XK_b,66,XK_c,67,XK_d,68,XK_e,69,XK_f,70,XK_g,71,XK_h,72,XK_i,73,XK_j,74,XK_k,75,XK_l,76,XK_m,77,XK_n,78,XK_o,79,XK_p,80,XK_q,81,XK_r,82,XK_s,83,XK_t,84,XK_u,85,XK_v,86,XK_w,87,XK_x,88,XK_y,89,XK_z,90,XK_0,48,XK_1,49,XK_2,50,XK_3,51,XK_4,52,XK_5,53,XK_6,54,XK_7,55,XK_8,56,XK_9,57};
// clang-format on
int fenster_open(struct fenster *f) {
  f->dpy = XOpenDisplay(NULL);
  int screen = DefaultScreen(f->dpy);
  int x = (DisplayWidth(f->dpy, screen) - f->width) / 2;
  int y = (DisplayHeight(f->dpy, screen) - f->height) / 2;
  if (x < 0)
    x = 0;
  if (y < 0)
    y = 0;
  f->w = XCreateSimpleWindow(f->dpy, RootWindow(f->dpy, screen), x, y, f->width,
                             f->height, 0, BlackPixel(f->dpy, screen),
                             WhitePixel(f->dpy, screen));
  f->gc = XCreateGC(f->dpy, f->w, 0, 0);
  XSelectInput(f->dpy, f->w,
               ExposureMask | KeyPressMask | KeyReleaseMask | ButtonPressMask |
                   ButtonReleaseMask | PointerMotionMask);
  XStoreName(f->dpy, f->w, f->title);

  XSizeHints hints = {0};
  hints.flags = PMinSize | PMaxSize;
  hints.min_width = hints.max_width = f->width;
  hints.min_height = hints.max_height = f->height;
  XSetWMNormalHints(f->dpy, f->w, &hints);

  XMapWindow(f->dpy, f->w);
  XSync(f->dpy, f->w);

  f->img = XCreateImage(f->dpy, DefaultVisual(f->dpy, 0), 24, ZPixmap, 0,
                        (char *)f->buf, f->width, f->height, 32, 0);
  return 0;
}

void fenster_close(struct fenster *f) { XCloseDisplay(f->dpy); }

int fenster_loop(struct fenster *f) {
  XEvent ev;
  XPutImage(f->dpy, f->w, f->gc, f->img, 0, 0, 0, 0, f->width, f->height);
  XFlush(f->dpy);
  while (XPending(f->dpy)) {
    XNextEvent(f->dpy, &ev);
    switch (ev.type) {
    case ButtonPress:
    case ButtonRelease: {
      int pressed = (ev.type == ButtonPress);
      if (ev.xbutton.button == 1) {
        if (pressed)
          f->mouse |= 1;
        else
          f->mouse &= ~1;
      } else if (ev.xbutton.button == 3) {
        if (pressed)
          f->mouse |= 2;
        else
          f->mouse &= ~2;
      }
      break;
    }
    case MotionNotify:
      f->x = ev.xmotion.x, f->y = ev.xmotion.y;
      break;
    case KeyPress:
    case KeyRelease: {
      int m = ev.xkey.state;
      int k = XkbKeycodeToKeysym(f->dpy, ev.xkey.keycode, 0, 0);
      for (unsigned int i = 0; i < 124; i += 2) {
        if (FENSTER_KEYCODES[i] == k) {
          f->keys[FENSTER_KEYCODES[i + 1]] = (ev.type == KeyPress);
          break;
        }
      }
      f->mod = ((m & ControlMask) != 0) | (((m & ShiftMask) != 0) << 1) |
               (((m & Mod1Mask) != 0) << 2) | (((m & Mod4Mask) != 0) << 3);
    } break;
    }
  }
  return 0;
}

void fenster_sleep(int64_t ms) {
  struct timespec ts;
  ts.tv_sec = ms / 1000;
  ts.tv_nsec = (ms % 1000) * 1000000;
  nanosleep(&ts, NULL);
}

int64_t fenster_time(void) {
  struct timespec time;
  clock_gettime(CLOCK_REALTIME, &time);
  return time.tv_sec * 1000 + (time.tv_nsec / 1000000);
}
#endif
