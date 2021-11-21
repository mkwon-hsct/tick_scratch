/**
 * @file q_toml.c
 * @brief Define TOML parser for q using tomlc99 (MIT License) library (Repository URL is below).
 * @link https://github.com/cktan/tomlc99
 */ 

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Load Libraries                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

#include <string.h>
#include <stdlib.h>
#include <toml.h>
#include <k.h>

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Global Variables                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/**
 * @brief One day in nanoseconds.
 */
const J ONEDAY_NANOS = 86400000000000LL;

/**
 * @brief Buffer to capture error at parsing TOML file.
 */
char ERROR_BUFFER[64];

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                   Private Functions                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/**
 * @brief Free resource of TOML document.
 * @param document: Result object of parsing a TOML file.
 */
K free_toml_document(K document){
  toml_free((toml_table_t*) kK(document)[1]);
  kK(document)[0]=0;
  kK(document)[1]=0;
  return (K) 0;
}

/**
 * @brief Get TOML boolean value.
 * @param element: TOML element.
 * @return bool
 */
K get_bool(toml_datum_t element){
  return kb(element.u.b);
}

/**
 * @brief Get TOML int value.
 * @param element: TOML element.
 * @return long
 */
K get_int(toml_datum_t element){
  return kj(element.u.i);
}

/**
 * @brief Get TOML double value.
 * @param element: TOML element.
 * @return float
 */
K get_double(toml_datum_t element){
  return kf(element.u.d);
}

/**
 * @brief Get TOML string value.
 * @param element: TOML element.
 * @return
 * - string: If the length of the string is more than 30.
 * - symbol: Otherwise.
 */
K get_string(toml_datum_t element){
  int length = strlen(element.u.s);
  if(length > 30){
    // String
    K string = ktn(KC, length);
    memcpy(kC(string), element.u.s, length);
    // String must be freed
    free(element.u.s);
    return string;
  }
  else{
    // Symbol
    char symbol[32];
    strcpy(symbol, element.u.s);
    // String must be freed
    free(element.u.s);
    return ks(symbol);
  }
}

/**
 * @brief Get TOML timestamp value.
 * @param element: TOML element.
 * @return
 * - timestamp: If year and hour exists.
 * - date: If year exists.
 * - time: If year does not exist and millisec exists.
 * - second: Otherwise.
 */
K get_timestamp(toml_datum_t element){
  if(element.u.ts->year && element.u.ts->hour){
    // Timestamp
    // yyyy-mm-dd
    J nanoseconds = ONEDAY_NANOS * ymd(*element.u.ts->year, *element.u.ts->month, *element.u.ts->day);
    // HH:MM:SS
    nanoseconds += ((*element.u.ts->hour) * 60 * 60 + (*element.u.ts->minute) * 60 + *element.u.ts->second) * 1000000000LL;
    if(element.u.ts->millisec){
      // Millisecond is optional
      nanoseconds += (*element.u.ts->millisec) * 1000000LL;
    }
    if(element.u.ts->z){
      // Offset is optional
      if((element.u.ts->z)[0] == '-'){
        // UTC - offset
        // Add offset
        nanoseconds += (60 * 60 * 1000000000LL) * (10 * ((element.u.ts->z)[1] - '0') + (element.u.ts->z)[2] - '0');
      }
      else if((element.u.ts->z)[0] == '+'){
        // UTC + offset
        // Subtract offset
        nanoseconds -= (60 * 60 * 1000000000LL) * (10 * ((element.u.ts->z)[1] - '0') + (element.u.ts->z)[2] - '0'); 
      }
      else{
        // 'Z' and 'z' are parsed as "Z0"
        // Around https://github.com/cktan/tomlc99/blob/master/toml.c#L1959 (can be changed since they don't have any release)
        // ```
        // if (*p == 'Z' || *p == 'z') {
				//   *z++ = 'Z'; p++;
				//   *z = 0;
        // }
        // ```
        // UTC
        // Nothing to do
      }
    }
    // Timestamp must be freed
    free(element.u.ts);
    return ktj(-KP, nanoseconds);
  }
  else if(element.u.ts->year){
    // Date
    int days = ymd(*element.u.ts->year, *element.u.ts->month, *element.u.ts->day);
    // Timestamp must be freed
    free(element.u.ts);
    return kd(days);
  }
  else if(element.u.ts->second){
    // Time
    int time = ((*element.u.ts->hour) * 60 * 60 + (*element.u.ts->minute) * 60 + *element.u.ts->second) * 1000;
    if(element.u.ts->millisec){
      // Millisecond exists
      time +=*element.u.ts->millisec;
    }
    // Timestamp must be freed
    free(element.u.ts);
    return kt(time);
  }
  else{
    // Hour and minute should not be in TOML
    return krr("unknown time type");
  }
}

/**
 * @brief Get TOML array value.
 * @param array: TOML array element.
 * @return
 * - empty list: If size of the array is 0.
 * - list of bool
 * - list of long
 * - list of float
 * - list of symbol
 */
K get_array(toml_array_t *array){
  // List to return
  K list = (K) 0;

  int size = toml_array_nelem(array);
  if(!size){
    // Empty list
    return ktn(0, 0);
  }

  char item_type = toml_array_kind(array);
  if(item_type != 'v'){
    // Array of table, nested array and mixed array are not supported.
    return krr("nyi");
  }

  // Get value type
  item_type = toml_array_type(array);
  switch(item_type){
    case 'b':
      // Bool list
      list = ktn(KB, size);
      for(int i = 0; i!= size; ++i){
        kG(list)[i] = (G) toml_bool_at(array, i).u.b;
      }
      break;
    case 'i':
      // Long list
      list = ktn(KJ, size);
      for(int i = 0; i!= size; ++i){
        kJ(list)[i] = toml_int_at(array, i).u.i;
      }
      break;
    case 'd':
      // Float list
      list = ktn(KF, size);
      for(int i = 0; i!= size; ++i){
        kF(list)[i] = toml_double_at(array, i).u.d;
      }
      break;
    case 's':
      {
        // Symbol list
        list = ktn(KS, size);
        // Assume the length of symbol does not exceed 64.
        char symbol[64];
        kS(list)[0] = ss(symbol);
        for(int i = 1; i!= size; ++i){
          toml_datum_t item = toml_string_at(array, i);
          strcpy(symbol, item.u.s);
          free(item.u.s);
          kS(list)[i] = ss(symbol);
        }
      }
      break;
    default:
      // List of timestamp is unlikely to exist
      // Compound list is not supported
      return krr("nyi");
  }

  return list;
}

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                       Interface                       //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/**
 * @brief Parse a TOML file.
 * @param file_path_: File handle to a TOML file.
 * @return foreign: Parsed document.
 */
K load_toml(K file_path_){

  // Trim preceding ":"
  K file_path = k(0, "{[path] `$1 _ string path}", r1(file_path_), (K) 0);
  
  // Open file
  FILE *file = fopen(file_path->s, "r");

  // Free file path which is no longer necessary
  r0(file_path);

  if(!file){
    // Error in opening file
    return krr("failed to open file");
  }

  // Parse file
  toml_table_t* document = toml_parse_file(file, ERROR_BUFFER, sizeof(ERROR_BUFFER));

  // Close file
  fclose(file);

  if (!document) {
    // Parse error
    return krr(ERROR_BUFFER);
    //return krr("failed to parse");
  }

  // Create a foreign object
  K foreign = ktn(0, 2);
  kK(foreign)[0]=(K) free_toml_document;
  kK(foreign)[1]=(K) document;
  foreign->t = 112;

  return foreign;
}

/**
 * @brief Get all keys in a document.
 * @param document_: Result object of parsing a TOML file.
 * @return list of symbol: Keys in the document.
 */
K get_keys(K document_){

  // Restor original type
  toml_table_t *document = (toml_table_t*) kK(document_)[1];

  // List of keys
  K keys = ktn(KS, 0);
  int i = 0;
  while(1){
    const char* key = toml_key_in(document, i);
    if(!key){
      break;
    }
    else{
      js(&keys, ss((S) key));
      ++i;
    }
  }
  return keys;
}

/**
 * @brief Get an TOML element from a document with a key.
 * @param document_: Result object of parsing a TOML file.
 * @param key: Key of an element to retrieve.
 * @return
 * - bool
 * - long
 * - float
 * - symbol
 * - timestamp
 * - date
 * - second
 * - list of bool
 * - list of long
 * - list of float
 * - list of symbol
 * - foreign: Table.
 */
K get_toml_element(K document_, K key){
  toml_table_t *document = (toml_table_t*) kK(document_)[1];

  // Look for table
  toml_table_t* table = toml_table_in(document, key->s);
  if (table) {
    K foreign = ktn(0, 2);
    // Do not free since this table is dependent on the document
    kK(foreign)[0] = (K) 0;
    kK(foreign)[1] = (K) table;
    foreign->t = 112;
    return foreign;
  }

  // Look for bool
  toml_datum_t element = toml_bool_in(document, key->s);
  if(element.ok){
    return get_bool(element);
  }

  // Look for int
  element = toml_int_in(document, key->s);
  if(element.ok){
    // int is int64
    return get_int(element);
  }

  // Look for double
  element = toml_double_in(document, key->s);
  if(element.ok){
    return get_double(element);
  }

  // Look for string
  element = toml_string_in(document, key->s);
  if(element.ok){
    return get_string(element);
  }

  // Look for timestamp
  element = toml_timestamp_in(document, key->s);
  if(element.ok){
    return get_timestamp(element);
  }

  // Look for array
  toml_array_t* array = toml_array_in(document, key->s);
  if (array) {
    return get_array(array);
  }

  // Specfied key does not exist
  return krr("no such element");
}
