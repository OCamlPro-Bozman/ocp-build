#include <caml/mlvalues.h>

#ifdef _WIN32

#include <winsock2.h>
#include <windows.h>
#include <sys/types.h>

#endif

#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/signals.h>

#ifndef CAML_UNIXSUPPORT_H
#include <caml/unixsupport.h>
#define CAML_UNIXSUPPORT_H
#endif

/* Versions before 4.02.0 use unix_ prefixes for these functions */

#if OCAML_VERSION_OCP == 4010001
#define win_cleanup unix_cleanup
#define win_filedescr_of_channel  unix_filedescr_of_channel
#define win_inchannel_of_filedescr  unix_inchannel_of_filedescr
#define win_outchannel_of_filedescr unix_outchannel_of_filedescr
#define win_startup unix_startup
#define win_waitpid unix_waitpid
#endif

/* There is a test in win_starup/win_cleanup, so there is no
   problem if unix.cma is linked and these functions are called twice. */
CAMLprim value minUnix_startup(value unit_v)
{
#ifdef _WIN32
  win_startup(unit_v);
#endif
  return Val_unit;
}

CAMLprim value minUnix_cleanup(value unit_v)
{
#ifdef _WIN32
  win_cleanup(unit_v);
#endif
  return Val_unit;
}


CAMLprim value minUnix_filedescr_of_fd(value vfd)
{
#ifdef _WIN32
  int crt_fd = Int_val(vfd);
  /* PR#4750: do not use the _or_socket variant as it can cause performance
     degradation and this function is only used with the standard
     handles 0, 1, 2, which are not sockets. */
  value res = win_alloc_handle((HANDLE) _get_osfhandle(crt_fd));
  CRT_fd_val(res) = crt_fd;
  return res;
#else
  return vfd;
#endif
}

#ifdef _WIN32

#define CAMLREDIR1(new_name, win_name, unix_name) \
  CAMLprim value win_name(value s_v); \
  CAMLprim value new_name(value s_v) { return win_name(s_v); }

#define CAMLREDIR1WIN(new_name, win_name) \
  CAMLprim value win_name(value s_v); \
  CAMLprim value new_name(value s_v) { return win_name(s_v); }

#define CAMLREDIR2(new_name, win_name, unix_name) \
  CAMLprim value win_name(value arg1_v, value arg2_v);			\
  CAMLprim value new_name(value arg1_v, value arg2_v) { return win_name(arg1_v, arg2_v); }

#else

#define CAMLREDIR1(new_name, win_name, unix_name) \
  CAMLprim value unix_name(value s_v); \
  CAMLprim value new_name(value s_v) { return unix_name(s_v); }

#define CAMLREDIR1WIN(new_name, win_name) \
  CAMLprim value new_name(value s_v) { \
   uerror(#win_name" not implemented", Nothing);\
}

#define CAMLREDIR2(new_name, win_name, unix_name) \
  CAMLprim value unix_name(value arg1_v, value arg2_v);			\
  CAMLprim value new_name(value arg1_v, value arg2_v) { return unix_name(arg1_v, arg2_v); }

#endif

CAMLREDIR1(minUnix_lstat, unix_stat, unix_lstat)
CAMLREDIR1(minUnix_inchannel_of_filedescr, win_inchannel_of_filedescr, caml_ml_open_descriptor_in)
CAMLREDIR1(minUnix_outchannel_of_filedescr, win_outchannel_of_filedescr, caml_ml_open_descriptor_out)
CAMLREDIR1(minUnix_filedescr_of_channel, win_filedescr_of_channel, caml_channel_descriptor)

CAMLREDIR1WIN(onlyWin32_findfirst, win_findfirst)
CAMLREDIR1WIN(onlyWin32_findnext, win_findnext)
CAMLREDIR1WIN(onlyWin32_findclose, win_findclose)
CAMLREDIR1WIN(onlyWin32_system, win_system)

CAMLREDIR2(minUnix_waitpid, win_waitpid, unix_waitpid)

#include <time.h>
#include <string.h>

#define OUTSTR_SIZE 200
value minUnix_strftime(value format_v, value tm_v)
{
  CAMLparam2(format_v, tm_v);
  CAMLlocal1(ret_v);
  struct tm tm;
  char outstr[OUTSTR_SIZE];
  size_t size;

  /* Clear tm: some tm have a tm_zone that should be NULL, or they
     will generate a segfault with some formats (%Z) */
  memset(&tm, 0, sizeof(tm));
  tm.tm_sec = Int_val(Field(tm_v, 0));
  tm.tm_min = Int_val(Field(tm_v, 1));
  tm.tm_hour = Int_val(Field(tm_v, 2));
  tm.tm_mday = Int_val(Field(tm_v, 3));
  tm.tm_mon = Int_val(Field(tm_v, 4));
  tm.tm_year = Int_val(Field(tm_v, 5));
  tm.tm_wday = Int_val(Field(tm_v, 6));
  tm.tm_yday = Int_val(Field(tm_v, 7));
  tm.tm_isdst = Int_val(Field(tm_v, 8));

  size = strftime(outstr, OUTSTR_SIZE, String_val(format_v), &tm);
  outstr[size] = 0;
  ret_v = caml_copy_string(outstr);

  CAMLreturn(ret_v);
}

