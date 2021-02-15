/
* @file: simple_join.q
* @overview: Examples of joining tables.
\

employees:([region:`hokkaido`tokyo`tokyo`tokyo`osaka`osaka`fukuoka; id:0 0 1 2 0 1 0] name:`bear_sato`tower_hisamitsu`raimon_kimijima`dome_ota`glico_nakai`kuidaore_kondo`mentai_takenaka; position:`sales`sales`engineer`director`director`part_time`soumu);

/
* @brief Table of information of employees.
\
employees_base:([] region:`hokkaido`tokyo`tokyo`tokyo`osaka`osaka`fukuoka; id:0 0 1 2 0 1 0; name:`bear_sato`tower_hisamitsu`raimon_kimijima`dome_ota`glico_nakai`kuidaore_kondo`mentai_takenaka; position:`sales`sales`engineer`director`director`part_time`soumu);

/
* @brief Table of private information.
\
person:flip `person`id`birthday`hobby!(`kuidaore_kondo`raimon_kimijima`tower_hisamitsu`shachihoko_osada`mentai_takenaka`kiritampo_kiryu; /
                                       til 6; /
                                       1989.05.12 2000.01.01 1977.10.09 1993.01.25 1988.12.30 1997.08.07; /
                                       `cooking`magic`praising_god`drive`pray`dance);
/
* @brief Records of expense by employees.
\
expense:flip `person`item`price`date!(`bear_sato`bear_sato`bear_sato`tower_hisamitsu`tower_hisamitsu`tower_hisamitsu`glico_nakai`raimon_kimijima`raimon_kimijima`mentai_takenaka; /
                                      `salmon`melon`merry_go_round`ra_men`udon`yakiniku`caramel`jinrikisha`taxi`mentaiko; /
                                      5000 5000 2000 1200 1000 3000 500 1000 3000 800; /
                                      2019.10.01 2019.10.13 2019.10.28 2019.10.03 2019.10.20 2019.10.30 2019.10.18 2019.10.02 2019.10.20 2019.10.07)
