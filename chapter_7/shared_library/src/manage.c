/**
 * @file manage.c
 * @brief Examples to demonstrate memory management.
 */

#include <k.h>
#include <stdio.h>
#include <memory.h>

/**
 * @brief Generate int andpass to q.
 * @return int: Internally generated int value.
 */
K no_input(){
  K atom = ki(10000);
  return atom;
}

/**
 * @brief Take an argument from q and return it.
 * @param something: Argument to return.
 * @return any: Argument itself
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
 * @return general null
 */
K nullify(){
  return (K) 0;
}

/**
 * @brief Generate an object but return null.
 */
K pure_waste(){
  K time = kt(60*60*1000);
  // Changed the mind
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
 * @brief Create a string.
 * @return string
 */
K create_string(){
  return kp("this is a string.");
}

/**
 * @brief Create a string with the first 14 characters.
 * @return string
 */
K create_string2(){
  return kpn("cannot see whole message!", 14);
}

/**
 * @brief Create a timestamp list.
 * @return list of timestamp.
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
 * @return list of timestamp.
 */
K simple_list2(){
  K list = ktn(KP, 3);

  // Store nanoseconds since 2000.01.01D00:00:00
  J times[3]={86400LL * 1000000000LL,  -86400LL * 1000000000LL, 172800LL * 1000000000LL};
  memcpy((void*) kJ(list), (const void*) times, 3 * sizeof(J));

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
  kS(list)[1]=sn("2nd element", 3);
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
 * @return dictionary
 */
K create_dictionary(){

  K keys = ktn(KS, 3);
  kS(keys)[0]=ss("chars");
  kS(keys)[1]=ss("longs");
  kS(keys)[2]=ss("seconds");

  K value1 = kp("ab");

  K value2 = ktn(KJ, 2);
  kJ(value2)[0]=1000000LL;
  kJ(value2)[1]=2000000LL;

  K value3 = ktn(KV, 2);
  kI(value3)[0]=210;
  kI(value3)[1]=wi;

  // Create a compound list from three lists
  K values = knk(3, value1, value2, value3);

  return xD(keys, values);
}

/**
 * @brief Create a table from a dictionary.
 * @return table
 */
K create_table(){
  return xT(create_dictionary());
}

/**
 * @brief Convert a table into a keyed table.
 * @return keyed table
 */
K enkey(){
  // Hold as an object
  K table = create_table();
  K keyed_table = knt(1, table);
  // Free the table
  r0(table);
  return keyed_table;
}

/**
 * @brief Convert a keyed table into a table.
 * @return table
 */
K unkey(){
  K keyed_table = enkey();
  return ktd(keyed_table);
}

/**
 * @brief Build a keyed table from two tables.
 * @return keyed table
 */
K artificial_keyed_table(){

  // Table1
  K keys1 = ktn(KS, 1);
  kS(keys1)[0]=ss("chars");

  K value1_1 = kp("ab");

  // Everything is moved!!
  K key_table = xT(xD(keys1, knk(1, value1_1)));

  // Table2
  K keys2 = ktn(KS, 2);
  kS(keys2)[0]=ss("longs");
  kS(keys2)[1]=ss("seconds");

  K value2_1 = ktn(KJ, 2);
  kJ(value2_1)[0]=1000000LL;
  kJ(value2_1)[1]=2000000LL;

  K value2_2 = ktn(KV, 2);
  kI(value2_2)[0]=210;
  kI(value2_2)[1]=wi;

  // Everything is moved!!
  K value_table = xT(xD(keys2, knk(2, value2_1, value2_2)));
  
  return xD(key_table, value_table);
}

/**
 * @brief Create a compound list by adding elements.
 * @return compound list
 */
K add_to_compound(){
  K list = ktn(0, 0);
  jk(&list, ks("1st"));
  for(int i = 1; i!= 4; ++i){
    jk(&list, ki(i));
  }
  return list;
}

/**
 * @brief Create a symbol list by adding elements.
 * @return list of symbol
 */
K add_to_symbol_list(){
  K list = ktn(KS, 0);
  js(&list, ss("majesty"));
  js(&list, ss("glory"));
  return list;
}

/**
 * @brief Create a simple list by adding elements.
 * @return list of time
 */
K add_to_simple(){
  K list = ktn(KT, 2);
  kI(list)[0] = 15;
  kI(list)[1] = 30;
  I forty_five = 45;
  I sixty = 60;
  ja(&list, (void *) &forty_five);
  ja(&list, (void *) &sixty);
  forty_five*=4;
  ja(&list, (void *) &forty_five);
  return list;
}

/**
 * @brief Concatenate two same type of lists.
 * @param mode {bool}: Flag to switch result type:
 * - true: Return compound list.
 * - false: Return simple list.
 * @return
 * - compound list: If `mode` is true.
 * - simple list: If `mode` is false.
 */
K concat_list(K mode){
  if(mode->t != -KB){
    return krr("mode must be bool type");
  }
  switch(mode->g){
    case 1:
      {
        K list1 = knk(3, kg(0x4d), ke(1.23), ktj(-KP, 130980641756951));
        K list2 = knk(2, kh(-8), kc('k'));
        jv(&list1, list2);
        // Free unnecessary list
        r0(list2);
        return list1;
      }
    default:
      {
        K list1 = ktn(KF, 2);
        kF(list1)[0]=15.982;
        kF(list1)[1]=3.16;

        K list2 = ktn(KF, 2);
        kF(list2)[0]=100.0315;
        kF(list2)[1]=-0.349;
        jv(&list1, list2);
        // Free unnecessary list
        r0(list2);
        return list1;
      }
  }
}

/**
 * @brief Build dictionary while validating keys and values.
 * @return
 * - dictionary: In case of validation success.
 * - general null: In case of validation failure.
 */
K deligate(){
  K keys = ktn(KI, 3);
  for(int i = 0; i!= keys->n; ++i){
    kI(keys)[i]=i;
  }

  K values = ktn(KM, 3);
  for(int i = 0; i!= values->n; ++i){
    kI(values)[i]=12 * i;
  }

  // Call `check` function with `keys` and `values` and get boolean result.
  K ok = k(0, "check", r1(keys), r1(values), (K) 0);

  if(ok->g){
    r0(ok);
    return xD(keys, values);
  }
  else{
    r0(ok);
    r0(keys);
    r0(values);
    return (K) 0;
  }
}
