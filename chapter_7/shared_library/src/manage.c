#include <k.h>
#include <stdio.h>
#include <memory.h>

/**
 * @brief Generate int andpass to q.
 * @return
 * - int: Internally generated int value.
 */
K no_input(){
  K atom = ki(10000);
  return atom;
}

/**
 * @brief Take argument from q and return it.
 * @param something: Argument to return.
 * @return
 * - any: Argument itself
 */
K sonomama(K something){
  return r1(something);
}

/**
 * @brief Manipulate on int and rejects all the other types.
 * @param something: Object to feed.
 * @return 
 * - int: Seven-folded value of the original argument.
 * - general ull: If the argument is an atom of bool, GUID and byte.
 * - error: Otherwise.
 */
K picky(K something){
  switch(something->t){
    case -KB: case -UU: case -KG:
      {
        K null = ka(101);
        null->g = 0;
        return null;
      }
    case -KI:
      if(something->i >= wi / 7){
        something->i = wi;
      }
      else if(something->i == ni){
        // nothing to do
      }
      else if(something->i <= -wi / 7){
        something->i = -wi;
      }
      else{
        something->i = 7 * something -> i;
      }
      return r1(something);
    default:
      return krr("I don't like this.");
  }
}

/**
 * @brief Return general null.
 * @return
 * - general null
 */
K nullify(){
  return (K) 0;
}

/**
 * @brief Generate a object but return null.
 */
K pure_waste(){
  K time = kt(60*60*1000);
  // Change the mind
  r0(time);
  return (K) 0;
}

/**
 * @brief Copy a given argument and edit, but return null.
 */
K complex_waste(K garbage){
  K new_garbage=garbage;
  new_garbage->i += 1;
  return (K) 0;
}

/**
 * @brief Create a timestamp list.
 * @return 
 * - list of timestamp.
 */
K simple_list(){
  K list = ktn(KP, 3);
  printf("length: %d\n", list->n);

  // Store nanoseconds since 2000.01.01D00:00:00
  kJ(list)[0] = 86400LL * 1000000000LL;
  kJ(list)[1] = -86400LL * 1000000000LL;
  kJ(list)[2] = 172800LL * 1000000000LL;

  return list;
}

/**
 * @brief Create a timestamp list with copy.
 * @return 
 * - list of timestamp.
 */
K simple_list2(){
  K list = ktn(KP, 3);

  // Store nanoseconds since 2000.01.01D00:00:00
  J times[3]={86400LL * 1000000000LL,  -86400LL * 1000000000LL, 172800LL * 1000000000LL};
  memcpy((void*) kJ(list), (const void*) times , 3 * sizeof(J));

  return list;
}

/**
 * @brief Create a symbol list.
 * @return 
 * - list of symbol
 */
K symbol_list(){
  K list = ktn(KS, 2);
  kS(list)[0]=ss("1st");
  kS(list)[1]=ss("2nd");
  return list;
}

/**
 * @brief Create a compound list by allocating an array first and then substitute elements.
 * @return 
 * - compound list
 */
K compound_list(){
  K list = ktn(0, 4);

  // (bool; GUID; symbol; ::)
  kK(list)[0]=kb(1);
  U guid = {{0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15}};
  kK(list)[1]=ku(guid);
  kK(list)[2]=ks("symphony");
  kK(list)[3]=ka(101);
  kK(list)[3]->g=0;

  return list;
}

/**
 * @brief Create a compound list from elements.
 * @return 
 * - compound list
 */
K compound_list2(){
  
  // (short; char; month; list of timespan)
  K list = knk(4, kh(-172), kc('q'), ka(-KM), ktn(KN, 2));
  kK(list)[2]->i = 36;
  kJ(kK(list)[3])[0]=60*60*1000000000LL;
  kJ(kK(list)[3])[1]=15*60*1000000000LL;

  return list;
}

/**
 * @brief Create a dictionary.
 */
K create_dictionary(){

  K keys = ktn(KS, 3);
  kS(keys)[0]=ss("chars");
  kS(keys)[1]=ss("longs");
  kS(keys)[2]=ss("seconds");

  K values = ktn(0, 3);
  K value1 = ktn(KC, 2);
  kC(value1)[0]='a';
  kC(value1)[1]='b';

  K value2 = ktn(KJ, 2);
  kJ(value2)[0]=1000000LL;
  kJ(value2)[1]=2000000LL;

  K value3 = ktn(KV, 2);
  kI(value3)[0]=210;
  kI(value3)[1]=wi;

  K values_[3]= {value1, value2, value3};
  memcpy((void*) kK(values), (const void*) values_, 3 * sizeof(K));

  return xD(keys, values);
}

/**
 * @brief Create a table from a dictionary.
 */
K create_table(){
  return xT(create_dictionary());
}
