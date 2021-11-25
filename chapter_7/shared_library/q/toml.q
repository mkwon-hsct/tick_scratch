/
* @file toml.q
* @overview Load a shared library to parse TOML file.
\

/
* @brief Parse a TOML file.
* @param file_path_ {symbol}: File handle to a TOML file.
* @return foreign: Parsed document.
\
load_toml: `:lib/qtoml 2: (`load_toml; 1);

/
* @brief Get all keys in a document.
* @param document_ {foreign}: Result object of parsing a TOML file.
* @return list of symbol: Keys in the document.
\
get_keys: `:lib/qtoml 2: (`get_keys; 1);

/
* @brief Get a TOML element from a document with a key.
* @param document_ {foreign}: Result object of parsing a TOML file.
* @param key {symbol}: Key of an element to retrieve.
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
\
get_toml_element: `:lib/qtoml 2: (`get_toml_element; 2);
