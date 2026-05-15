#ifndef FENSTER_H
#define FENSTER_H

#if defined(_WIN32)
#include <windows.h>
#else
#define _DEFAULT_SOURCE 1
#include <X11/XKBlib.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/keysym.h>
#include <time.h>
#endif

#include <stdint.h>
#include <stdlib.h>

struct fenster {
  const char *title;
  const int width;
  const int height;
  uint32_t *buf;
  int keys[256]; /* keys are mostly ASCII, but arrows are 17..20 */
  int mod;       /* mod is 4 bits mask, ctrl=1, shift=2, alt=4, meta=8 */
  int x;
  int y;
  int mouse;
  int fullscreen;
#if defined(_WIN32)
  HWND hwnd;
#else
  Display *dpy;
  Window w;
  GC gc;
  XImage *img;
#endif
};

#ifndef FENSTER_API
#define FENSTER_API extern
#endif

FENSTER_API int fenster_open(struct fenster *f);
FENSTER_API int fenster_loop(struct fenster *f);
FENSTER_API void fenster_close(struct fenster *f);
FENSTER_API void fenster_sleep(int64_t ms);
FENSTER_API int64_t fenster_time(void);

#define fenster_pixel(f, x, y) ((f)->buf[((y) * (f)->width) + (x)])

#ifdef __cplusplus
class Fenster {
  struct fenster f;
  int64_t now;

public:
  Fenster(const int w, const int h, const char *title)
      : f{.title = title, .width = w, .height = h} {
    this->f.buf = new uint32_t[w * h];
    this->now = fenster_time();
    fenster_open(&this->f);
  }
  ~Fenster() {
    fenster_close(&this->f);
    delete[] this->f.buf;
  }
  bool loop(const int fps) {
    int64_t t = fenster_time();
    if (t - this->now < 1000 / fps) {
      fenster_sleep(t - now);
    }
    this->now = t;
    return fenster_loop(&this->f) == 0;
  }
  inline uint32_t &px(const int x, const int y) {
    return fenster_pixel(&this->f, x, y);
  }
  bool key(int c) { return c >= 0 && c < 128 ? this->f.keys[c] : false; }
  int x() { return this->f.x; }
  int y() { return this->f.y; }
  int mouse() { return this->f.mouse; }
  int mod() { return this->f.mod; }
};
#endif

#endif
