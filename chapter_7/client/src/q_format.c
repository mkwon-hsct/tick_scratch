//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Load Libraries                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

#include <stdio.h>
#include <time.h>
#include <sys/time.h>
#include <string.h>
#include <q_format.h>

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Global Variables                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

char BUFFER[2048];

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                         Macros                        //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/**
 * @brief Format simple atom object and proceed cursor.
 * @param object: K object.
 * @param fmt: Format to stringify the object.
 * @param inner: Inner value of the object.
 * @return 
 * - -1: Error.
 * - other: Current location in the output buffer.
 */
#define format_simple_atom(object, fmt, inner) \
  int written = sprintf(BUFFER+cursor, fmt, inner); \
  return (written < 0)? -1: cursor + written;

/**
 * @brief Format list object without delimiting by spaces and proceed cursor.
 * @param object: K object.
 * @param fmt: Format to stringify an element of the list.
 * @param accessor: Macro to convert K object to an array.
 * @return 
 * - -1: Error.
 */
#define format_list_no_space(object, fmt, accessor) \
  for(int i = 0; i!= size; ++i){ \
    written = sprintf(BUFFER + cursor, fmt, accessor(object)[i]); \
    if(written < 0){ \
      return -1; \
    } \
    else{ \
      cursor += written; \
    } \
  }

/**
 * @brief Format list object delimiting by spaces and proceed cursor.
 * @param object: K object.
 * @param empty: String to display in case of an empty list.
 * @param fmt1: Format to stringify an element of the list with a space.
 * @param fmt2: Format to stringify an element of the list without a space.
 * @param accessor: Macro to convert K object to an array.
 * @param tail: Suceeding type indicator of a list.
 * @return 
 * - -1: Error.
 * - other: Current location in the output buffer.
 */
#define format_list(object, empty, fmt1, fmt2, accessor, tail) \
  int written = 0; \
  int size = object->n; \
  if(size == 0){ \
    written = sprintf(BUFFER + cursor, empty); \
    return (written < 0)? -1: cursor + written; \
  } \
  for(int i = 0; i!= size-1; ++i){ \
    written = sprintf(BUFFER + cursor, fmt1, accessor(object)[i]); \
    if(written < 0){ \
      return -1; \
    } \
    else{ \
      cursor += written; \
    } \
  } \
  written = sprintf(BUFFER + cursor, fmt2, accessor(object)[size-1]); \
  if(written < 0){ \
    return -1; \
  } \
  else{ \
    cursor += written; \
  } \
  if(cursor < sizeof(BUFFER) - 1){ \
    BUFFER[cursor++] = tail; \
    BUFFER[cursor] = '\0'; \
  } \
  return cursor;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                   Private Functions                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// %% Pre-declaration %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

int format_q(K object, int cursor);

// %% Formatter %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

int format_error(K object, int cursor){
  format_simple_atom(object, "'%s", object->s)
}

int format_bool(K object, int cursor){
  format_simple_atom(object, "%db", object->g)
}

int format_byte(K object, int cursor){
  format_simple_atom(object, "0x%02x", object->g)
}

int format_short(K object, int cursor){
  format_simple_atom(object, "%dh", object->h)
}

int format_int(K object, int cursor){
  format_simple_atom(object, "%di", object->i)
}

int format_long(K object, int cursor){
  format_simple_atom(object, "%dj", object->j)
}

int format_real(K object, int cursor){
  format_simple_atom(object, "%7fe", object->e)
}

int format_float(K object, int cursor){
  format_simple_atom(object, "%7ff", object->f)
}

int format_char(K object, int cursor){
  format_simple_atom(object, "\"%s\"", object->g)
}

int format_symbol(K object, int cursor){
  format_simple_atom(object, "`%s", object->s)
}

int format_timestamp(J timestamp, int cursor){
  time_t sec = timestamp / 1000000000;
  int nanos = timestamp % 1000000000;
  struct tm *time=localtime(&sec);
  int written = sprintf(BUFFER+cursor, "%4d.%02d.%02dD%02d:%02d:%02d.%09d",
                time->tm_year+1930,
                time->tm_mon+1,
                time->tm_mday-1,
                time->tm_hour,
                time->tm_min,
                time->tm_sec,
                nanos
                );

  return (written < 0)? -1: cursor + written;
}

int format_date(I days, int cursor){
  int yyyymmdd = dj(days);
  int year = yyyymmdd / 10000;
  int month = (yyyymmdd %= 10000) / 100;
  int day = (yyyymmdd %= 100) / 100;
  int written = sprintf(BUFFER + cursor, "%d.%02d.%02d", year, month, day);

  return (written < 0)? -1: cursor + written;
}

int format_bool_list(K object, int cursor){
  int written = 0;
  int size = object->n;
  if(size == 0){
    written = sprintf(BUFFER + cursor, "`boolean$()");
    return (written < 0)? -1: cursor + written; 
  }
  format_list_no_space(object, "%d", kG)
  if(cursor < sizeof(BUFFER) -1){
    BUFFER[cursor++] = 'b';
    BUFFER[cursor] = '\0';
  }
  return cursor;
}

int format_byte_list(K object, int cursor){
  int written = 0;
  int size = object->n;
  if(size == 0){
    written = sprintf(BUFFER + cursor, "`byte$()");
    return (written < 0)? -1: cursor + written; 
  }
  if(cursor < sizeof(BUFFER) - 2){
    BUFFER[cursor++] = '0';
    BUFFER[cursor++] = 'x';
  }
  format_list_no_space(object, "%02x", kG)
  return cursor;
}

int format_short_list(K object, int cursor){
  format_list(object, "`short$()", "%d ", "%d", kH, 'h')
}

int format_int_list(K object, int cursor){
  format_list(object, "`int$()", "%d ", "%d", kI, 'i')
}

int format_long_list(K object, int cursor){
  format_list(object, "`long$()", "%d ", "%d", kJ, 'j')
}

int format_real_list(K object, int cursor){
  format_list(object, "`real$()", "%7f ", "%7f", kE, 'e')
}

int format_float_list(K object, int cursor){
  format_list(object, "`float$()", "%7f ", "%7f", kF, 'f')
}

int format_string(K object, int cursor){
  int size = object->n;
  if(sizeof(BUFFER) - cursor < size + 3){
    return -1;
  }
  else{
    BUFFER[cursor++] = '"';
    strncpy(BUFFER + cursor, kC(object), size);
    cursor += size;
    BUFFER[cursor++] = '"';
    BUFFER[cursor] = '\0';
    return cursor;
  }
}

int format_symbol_list(K object, int cursor){
  int written = 0;
  int size = object->n;
  if(size == 0){
    written = sprintf(BUFFER + cursor, "`symbol$()");
    return (written < 0)? -1: cursor + written; 
  }
  format_list_no_space(object, "`%s", kS)
  return cursor;
}

int format_timestamp_list(K object, int cursor){
  int size = object->n;
  if(size == 0){
    int written = sprintf(BUFFER + cursor, "`timestamp$()");
    return (written < 0)? -1: cursor + written; 
  }
  for(int i = 0; i != size-1; ++i){
    cursor = format_timestamp(kJ(object)[i], cursor);
    if(cursor < 0){
      return -1;
    }
    else if (cursor < sizeof(BUFFER) - 1){
      BUFFER[cursor++] = ' ';
    }
  }
  return format_timestamp(kJ(object)[size-1], cursor);
}

int format_date_list(K object, int cursor){
  int size = object->n;
  if(size == 0){
    int written = sprintf(BUFFER + cursor, "`date$()");
    return (written < 0)? -1: cursor + written; 
  }
  for(int i = 0; i != size-1; ++i){
    cursor = format_date(kI(object)[i], cursor);
    if(cursor < 0){
      return -1;
    }
    else if (cursor < sizeof(BUFFER) - 1){
      BUFFER[cursor++] = ' ';
    }
  }
  return format_date(kI(object)[size-1], cursor);
}

int format_compound_list(K object, int cursor){
  int size = object->n;
  if(cursor < sizeof(BUFFER) - 1){
    BUFFER[cursor++] = '(';
  }
  for(int i = 0; i!= size-1; ++i){
    cursor = format_q(kK(object)[i], cursor);
    if(cursor < 0){
      return -1;
    }
    else if (cursor < sizeof(BUFFER) - 1){
      BUFFER[cursor++] = ';';
    }
  }
  cursor = format_q(kK(object)[size-1], cursor);
  if(cursor < 0){
    return -1;
  }
  else if(cursor < sizeof(BUFFER) - 2){
    BUFFER[cursor++] = ')';
    BUFFER[cursor] = '\0';
    return cursor;
  }
}

int format_dictionary(K object, int cursor){
  cursor = format_q(kK(object)[0], cursor);
  if(cursor < 0){
    return -1;
  }
  else if (cursor < sizeof(BUFFER) - 1){
    BUFFER[cursor++] = '!';
  }
  return format_q(kK(object)[1], cursor);
}

int format_table(K object, int cursor){
  if(cursor < sizeof(BUFFER) - 1){
    BUFFER[cursor++] = '+';
  }
  return format_dictionary(object->k, cursor); 
}

int format_null(K object, int cursor){
  int written = sprintf(BUFFER + cursor, "::");
  return (written < 0)? -1: cursor + written;
}

int format_unsupported(K object, int cursor){
  int written = sprintf(BUFFER + cursor, "unknown type");
  return (written < 0)? -1: cursor + written;
}

/**
 * @brief General inner formatter of q object.
 * @param cursor: Current location in the output buffer.
 * @return
 * - -1: Error
 * - other: Current location in the output buffer.
 */
int format_q(K object, int cursor){
  switch (object->t){
    case -128:
      return format_error(object, cursor);
    case -KB:
      return format_bool(object, cursor);
    case -KG:
      return format_byte(object, cursor);
    case -KH:
      return format_short(object, cursor);
    case -KI:
      return format_int(object, cursor);
    case -KJ:
      return format_long(object, cursor);
    case -KE:
      return format_real(object, cursor);
    case -KF:
      return format_float(object, cursor);
    case -KC:
      return format_char(object, cursor);
    case -KS:
      return format_symbol(object, cursor);
    case -KP:
      return format_timestamp(object->j, cursor);
    case -KD:
      return format_date(object->i, cursor);
    case 0:
      return format_compound_list(object, cursor);
    case KB:
      return format_bool_list(object, cursor);
    case KG:
      return format_byte_list(object, cursor);
    case KH:
      return format_short_list(object, cursor);
    case KI:
      return format_int_list(object, cursor);
    case KJ:
      return format_long_list(object, cursor);
    case KE:
      return format_real_list(object, cursor);
    case KF:
      return format_float_list(object, cursor);
    case KC:
      return format_string(object, cursor);
    case KS:
      return format_symbol_list(object, cursor);
    case KP:
      return format_timestamp_list(object, cursor);
    case KD:
      return format_date_list(object, cursor);
    case XT:
      return format_table(object, cursor);
    case XD:
      return format_dictionary(object, cursor);
    case 101:
      return format_null(object, cursor);
    default:
      return format_unsupported(object, cursor);
  }
}

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                       Interface                       //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/**
 * @brief Formatter of q object.
 */
void format(K object){
  int cursor = 0;
  if(format_q(object, 0) < 0){
    // Error happened.
    // Maybe buffer overflow.
    fprintf(stderr, "buffer is too small.\n");
  }
  else{
    // Successfully formatted.
    printf("%s\n", BUFFER);
  }
}
