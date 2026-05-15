#ifndef FENSTER_AUDIO_H
#define FENSTER_AUDIO_H

#include <stdint.h>
#include <stddef.h>

#ifndef FENSTER_SAMPLE_RATE
#define FENSTER_SAMPLE_RATE 44100
#endif

#ifndef FENSTER_AUDIO_BUFSZ
#ifdef _WIN32
#define FENSTER_AUDIO_BUFSZ 2048
#else
#define FENSTER_AUDIO_BUFSZ 8192
#endif
#endif

#if defined(__APPLE__)
#include <AudioToolbox/AudioQueue.h>
struct fenster_audio {
  AudioQueueRef queue;
  size_t pos;
  float buf[FENSTER_AUDIO_BUFSZ];
  dispatch_semaphore_t drained;
  dispatch_semaphore_t full;
};
#elif defined(_WIN32)
#include <windows.h>
#include <mmsystem.h>
struct fenster_audio {
  WAVEHDR header;
  HWAVEOUT wo;
  WAVEHDR hdr[2];
  int16_t buf[2][FENSTER_AUDIO_BUFSZ];
};
#elif defined(__linux__)
struct fenster_audio {
  void *pcm;
  float buf[FENSTER_AUDIO_BUFSZ];
  size_t pos;
};
#endif

#ifndef FENSTER_API
#define FENSTER_API extern
#endif

FENSTER_API int fenster_audio_open(struct fenster_audio *f);
FENSTER_API int fenster_audio_available(struct fenster_audio *f);
FENSTER_API void fenster_audio_write(struct fenster_audio *f, float *buf,
                                     size_t n);
FENSTER_API void fenster_audio_close(struct fenster_audio *f);

#endif
