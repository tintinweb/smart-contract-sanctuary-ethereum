// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Web3 Artist's & Builders Club
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
//    #B#BB###BBBBBBBGBBGPGBY5GPPGGBBBBG5555PBBGBGGGGGGPG57~~!?JJJJJJ??7??????7777777??7?5GGGGGGGGGGGGGGGGGGGG5PPPPGBGBBBBBBBBBBBBBBBBPGGGGPPP5YYY5J!~!!!!!!!!!!!!!!!!!7?JY55YY5555555YYYYYYYY55555YYYY??????JJJY55?777777?777!!!777777777777777??7?77777777777777777777777777777777777777777777777!!777!!777!!       //
//    PB#####BBBBBBBBBBBBGGGGBG5PGP55PGBBGP5555GGGGGGGGGGGPPP5J?!?JJJYYYYYYYYY5Y55555555YJ??5GGGGGGGGGGGGGGGGGGGP5PPPGGGGGGBBBBBBBBBBBBBBPGGGPPPPPYYYYJ!~!!!!!!!!!!!!!!!!!J55555YY555Y555YYJYYYYYY5555YYYY???JJJJJYY55PPPPGGGGPGG5?!?5PY55J?7????Y5JJJJ???JY???????JY???????JYYYJJJJJJJJJJJJJJJJJJJJJJ7!JYY!7YYY7!    //
//    GBBB#####BBBBBBBBBBBGGPPGBGGP555PBGP5555PPGGGGGGGPGPP5PPPP?!5GGGGGGGGGGGGGGGGGGGGGP5YJ5GGGGGGGGGGGGGGGGGGGPPPPGGGBBBBBBBBBBBBBBBBBBGGGGPPPPPYYYYJ!~~!!!!!!!!!!!!!!!!J55555YY5555YYYYJJYYYYYY5555YYYY??JJJJJYY555PPPPGGGGGGGGG5J77JPP77!7777Y57777777JY7777777JY7777777JYJ77777777777777777777777!!JYY!7YYY7!    //
//    BBBBBBB####BBB#BBBGGBBBGPPGGP5555PP5555PPPGGGGGGGPPP555PPPJ!5GGGGGGGGGGGGGGGGGGGGGGGPY5GGGGGGGGGGGGGGGGGGGPPGGGGGGBGBBBBBBBBBBBBBBBPGGGPPP55YYYYJ!~~~!~~!!!!!!!!!!!!JY55555Y55YYY55YJJJYYYYY5555YYYYJJJYYYYYY555PPPPGGGGGGGGPPGPJ!?JJ?????JJJJJJ???????????????????????77?YYYYYYYYYYYYYYYYYYYYYY?!JYY!7YYY7!    //
//    5GGPPGBBBBB####BBBBBBBBBGPPPPP5PP5PPPPPPBBBBGGGBGGPG5Y5PPPJ!5GGGGGGGGGGGGGGGGGGGGGGGGYPGGGGGGGGGGGGGGGGGGGPPGGGGGBGBBBBBBBBBBBBBBBBGGGGGGPPPYYYYY7~~!!~~~~~~!!!!!!!!JY5555YY55YYYYYYJJJYJJYY5555YYYYJJYYYYYY5555PPPPGGGGPGGGGPPPPYYJJ?7???JJJJJ?????????????????????????YYYYYYYYYYYYYYYYYYYYYYYY?!JYY!7YYY7!    //
//    5PGP55PGGGB#BBGGGGGGGGGBBBGPPPPPPPPPPPPGBBBBBGGGPPPGPY5PPPY!YGGGGGGGGGGGGGGGGGGGGGGGG5PGGGGGGGGGGPGGGGGGGGPPPPGGGBGGBBBBBBBBBBBBBBGGGGGGGPP5YYYYJ7!!!!!!^~~~~!~!!!~!?Y55555Y55YYYYYJJJJJJJYY5555YYYYJYYYYYY555PPPPPPGGGGPGGGGPPGP5PPPYJYYY55PP5YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY7!JYY!7YYY7!    //
//    PPGGGPPGGGBBBGBBBBBBGGPPGGGPPPPPPPPPPPGBBBBGPPPPPGGGPY55PPJ~YGGGGGGGGGGGGGGGGGGGGGGGG5PGGGGGGGGGGGGGGGGGGGPPGPGGGGGGBBBBBBBBBBBBBBGGGPGGGPPP5Y5YY?~!!!!!~^~~~~~~!!~!?Y5555YY5YYYYYYJJJJJJJYY5555YYYYYY5555555PPPPPPPGGGGGGGGGPPGP5PPPYJYYY555PYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYJ77?Y?7!?YYY7!    //
//    BGGBBBGGGGGBGBBBBGPPGGPPPPPPPPPPPPPPPPGGGPPPPPPPPPPPP55555J!YGGGGGGGGGGGGGGGGGGGGGGGG5PGGGGGGGGGGGGGGGGGGGPPPPGGGGGBBBBBBBBBBBBBBBGGGPGPGP55YYYYJ?!~~~!!~~~~~~~~!!~!?Y55555YYYYYYYJJJJJJJJYY5555YYYYYY5555555PPPPPPPGGGGPPG55YY5YY5PPYJYYY555PYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYJ77?J?7!?YYYYY7!    //
//    GPPPPPGGGGGGPGBPPGGGGBBBGGGPPPPPPPPPPPPPPPPPPGGGGGGGPPPPPPY~YGGGGGGGGGGGGGGGGGGGGGGGG5PGGGGGGGGGGGGGGGGGGGPGPPGGPGGGBBBBBBBBBBBBBBGGGGGPGPPPYYYJJ?!~~~~!~~~~~~~~~~~!?Y55555YYJ?JJJJJJJJJJJYY5555YYYYYY555555PPPPPPPPGGPPGPPPP5555JY5PYJYYY555PYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY?77?J?!7?YYYYJ?7!!    //
//    PPGGGGGGPGBBBBBBGGGGB#BBGGGPPPPPPPPPPPPPPPPPPPPPGGGGG5555PY!YGGGGGGGGGGGGGGGGGGGGGGGG5PGGGGGGGGGGGGGGGGGGGPPPPGGGBBBBBBBBBBBBBBBBBGGGGGPGPP55YYYYJ!~~~~~~~~~~~~~~~~!?Y55555YYJ???JJJJJJJJJYYY555YYYYYY555555PPPPPPPPGGGGGPPPPPPPPPP5PYJYYY555PYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYJ77JJ?!7JYYYYJ?!7J7!    //
//    PPPGGGGGPGGPPPPPGBBGGBPPPPPPPPPPPPPPPPPPPPGGGGPPPPPPP55555Y!YGGGGGGGGGGGGGGGGGGGGGGGP5PPPGGGGGGGPGGGGGGGGGPPGGGBGGGBBBBBBBBBBBBBBBGPPPGPGPP55JY55Y7!!!~~~~~~~~~~~~~!?Y5Y55YYYJ???JJJJJJJJJYYY555YYYYYY555555PPPPPPPPGGGGGGGPPPPPPPPPPYJYYY555P5YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY7!J?!7JYYYYYY!7JYY7!    //
//    GGGGBBGGGGGGGGGGGGBBBGGGPPGPPPPPPPPPPPPPPPPPPGGGPGGPPP5555Y!YPPPGGGGGGGGGGGGGGGGGGGGP5PGGGGGGGGGPGGGGGGGGGPPPPGGGGGBBBBBBBBBBBBBBBGGGGGPP55Y5JYYYY7!!!!!~~~~~~~~~~~!?Y5555YY5J???JJJJJJJJJYYY555YYYYYY555555PPPPPPPPGGGGGPGPGPPGGPPPPYJJYY55555YYYYYYYYJJYYYYYYYJYYYYYYYYYYYYYYYYYYYYYYY7!!7JYYYYYYYJ!?YYY7!    //
//    GGGGGGGBBBGGGGGGGGGBBBBGGPGGGPGGGGGGGGGGGGGGGGGGGGGGGPPP55Y!YPPPPPPPGGGGGGGGGGGGGGGPP5PGGGGGGGGGPGGGGGGGGGPPGGGGGGGBBGBBBBBBBBBBBBGPGGGGGGP55JYYYY7!!!!!~~~~~~~~~!!!JYY555Y55J???JJ?JJJJJJYYY555YYYYYY555555PPPPPPPPGGPPGGPPPPPPPPPPPYJJYY5555PYYYYYYYYJJJJJJJYJJJYYYYYYYYYYYYYYYYYYYYYY7!JYYYYYYYYYJ!?YYY7!    //
//    BGGGGGGGB###BBGGPPPGGBGGGPGGGGPGGGGGGGGGGGGGGGGGGGGGG55P55Y!YPPPPPPPPPPPPPPPPPPPPPPPP5PPGGGGGGGGPGGGGGGGGGPPPPPPGGGBGGGGGPGBGGBGGGGPGPGPGPP5YYYYYY!~~~!~~~~~~~~~~~~!JYYY55YYYJ?7??J??JJJJJYYY55YYYYYYY5555555555555PPGPGGPGPPPPPPPPPPYJJYY5555P5YJJJJJJJJJYYYYYJJJYYYYYYYYYYYYYYYYYYYYY57!YYYYYYYYJ?!7JYYY7!    //
//    ##BBBGGGGGBBBBBBBBGGGGGGGPGGGGPGGGGGGBBBGGGGGGGGGGGGG555555J5PPPPPPPPPPPPPPPPPPPPPPPPPPGGGGGGGGGGGGGGGGGGPPPGGGGGGGGGGGGPPGGGGGGGGGGGPPPGPPPP55555YJJJJJJJJJJJJJJJJY5555PP5555YYYY5YYY5555555555555555P55555PPPPPPPPPPPPPPPPPPPPPPPPP5YY5555555555YJJJJJJJJJJJJ???JJJJYYYYYYYYYY555555557!?Y5555Y?!7J55YY5?!    //
//    BBBBBBGGGGGBBBBBBBBGGGGGGGGGGPPGGGGGGGGGGGGGGGGGGGGGG55555PPPPPPPPPPPPPPPPPPPPPPPPGPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5555555555555555555YYYYJJJJJJJJJ???JJJJJJJJJJJJYYYYYYY5557!77J5Y?!?555555P#?!    //
//    BBBBBBBBBGGBBBBBBGBGBBBGPPGPPPPGGGGGGGGGGGGGGGGGGGGGGP5555YYYYYYYYYYYYY55555555555555555555PP55555555555PPPPPPPPPPPPPPPPPPPGGGGGPPPPPPPPPPPPPPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBPYJJJJYYYYYYJJ??JJJJJJJJJYYYYYYYYYJJYY7!YJ!!!?5555555GP?!!    //
//    BBBBBBBBBBBBBBBBBBBBGBBGGPGPPPPGGGGGGGGGGGGGGGGGGGGGP555555JJJJJJJJJYYYYYYY5J!?55555JY55555JJ55555555555555555555555PPPP5YY?????YPPPPPPPPPPPPPPY?5GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBGBBBBBBBBBBBBBBBBBBBBBBBP^^YBBBBB#############################GPP55YJJJYJYYJJ??J??JJJYYYYYYYYYYYYYYY57!Y55Y?77JYYYG5??P?!    //
//    PPPPPPPPPPGGGGGGBBBBBBBGGGGPPPPGGGGGGGGGGGGGGGGGGGGGP5555555YYJJJJJJYYYYYY55:  ~5P5^ .?P5P7 :PPPPP555555555555555PPPPPPJ. ..:^  .JPPPPPPPPPPPG!  .YGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBBBBBBBBBBBBBBBGGGJ   YGBBBBBBBB#####################BGPPPPPPPYYYYYYYJ?7??????JJJYYYYYYYYYY55557!YYYYYJ!!YGB#77##?!    //
//    BBBBBBBBBBBGGGGGGGGGGGGGGGGPPPPGGGGGGGGGGGGGGGGGGGPGP555555Y5555YYYYYY55555P~   ?P5.  .5PP^ ~PPPPPPPPPPPP5PPPPPPPPPPPPPY..5PPP^  :PPPPPPPPPGGJ    7GGGGGGGGGGGGGGGGGGGGGGGGGGBGGGBGGGGGBBBBBBBBBBBBBBBGPPPP?  .5BBBBBBBBBBBBBBBBBBBBBGGGGGGGPPP5PPPPPPPPP55YYYJ?777????JJYYYYYYYYY555Y557!Y5YYY5J!P###77##?!    //
//    BBBBBBGGGGGGGGGGGGGGGGGGGBGPPPPPBGGPP5PY55YPGGGGGGPPP555555Y555555555555PPPPJ   ~PP:   JG5. ?GPPJ??7!!!7YPY77??777JY5555YJP5P5.  :55555555PPP^    ~PPPP5~~~^~~!!7JPPPJ??7!!7!!YPJJYP5PPJ???JJY555???7!!7!~5P!:^5PPY????JJPPPPPPPPPPPP555YY5555P5PPPPPPPPPPP555Y?77?????JYYYYYYYYYYYYYY557!Y55PPGJ!G#BY!J##?!    //
//    BBBBBBBBBBBBBBBBBBBBBBBGGGPPPPPPBGPPP5P5PPPPPPPPPPPPP5YYYYYYYYYYYYYYYYY5555P5:   Y5.   !GJ :PPP^   :!!77J5^   .^~~..^JYYY55PP!   !PP555555PP?   ~ .5PPP~   ~7!!.  ~55^..    ^~YY.  75Y^  .^:  !5Y:..    ~!5GGP55P7.  ^^. ^5GPPPPPPPPPPPPP55PPPP5PPPPPPPPPPPPP55YJJJ???JYYYY5555YYYYYYY5P?!PPGBBBJ!5J7JGBBB?!    //
//    BBBBBBBBBBBBBBBBBBBBBBBGGGPPP55PBGPPPPP55PPPPPPPPPPP5YYYJJJJJJJJJJJJJYYY5555P!   7?    :P~ !55Y.   JGGGGP5:   !P5P7  ^555Y!!^   !G#########G.  .5: YBBB!   ?GBG^   JBBG5   .5PPJ   :5!   JP5?..YPP5J   .PGGGPYYY?   !PPY: JGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP55555YYYYYY555PPPPP5PG?!GBGGGBJ!!JGBBBBB?!    //
//    BBBBBBBBBBBBBBBBBBBBBBBBBG555YJ5BGPPPPPY5555555555555YJJJ???JJJJJJJJJJYYY555P?   ^^    .J. JPP5.   5GGGGP5.   JPPP7  :555Y^:.. :5B########B?   ~G! !GBG!   ~J7^   .5BBBY   .5PPJ   ^P?   .!Y5YY555PJ   .PGGGGGPPY:   ^?55JYYYY55PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP55555PPPPPPPPPPPPPPP5GB?!PBGGGBJ!5BBBBBBB?!    //
//    BBBBBBBBBBBBBBBBBBBBBBBGGGYYYJ?YBBPPPPP5555??????JJYYYJJJ????JJJJJJJJJJYYYYY5Y.    .^   ^ .PGGY    ~!!7Y5Y.   !77~   ?P55555GG!  JB#######G:   5GP..5BG~        .7PBBBB7   ^55P?   ~PPJ^   .!Y55555!   ^GGPYPB###G!.   ^YGP5YJ???JY55PPPPPPPPPPPPPPPPPPPPP55555YJJJJJJYYYYY555P5555555GG?!PGGGGGJ!PBBBBBBB?!    //
//    BBBBBBBBBBBGGGGGGGGGGGGGGPYYJJJYBBPPPPP5555?77777??JJJJJ??77?JJJJJJJJJJ??JY5PG~    :Y     ~GGP?    ^~!7J5Y.   ^7~~:  !555555GB7   JBBBBBBB?   .!77. !GG~   7P5Y. !GGGGG7   ~P5P?   ^PPPPJ!:  .?5555!   ~PG5YJJ5GB##GJ~   ?####BP5J????YPPPGPPP5555P5Y5555555YYY?77!77777???J55555YYYYYGG?!PGPGGGY!?PBBBBBB?!    //
//    BBBBBBBBBBBBBBBBBBBGGGGGGPYYJJJYBBPPPPPY5Y5?77777??JJJJJ??77?JJJJJJ????YPB####?    7G^    ?P557   :555555Y.   JGPG7   Y55555557   ~5YYYYYY.   ????~ :55^   ?P5P^  !5555!   !P5P?   ^PPP55P5~   J555!   !5Y555YJJYPB##BJ   7#&&&&&&#G5J???Y5PPPP555P5Y555555YYYY?7!!!!!!!77?JY5555YYYYYPG?!PPPPPPGPJ7?PBBBB?!    //
//    GGGGGGGGGGGGGPPPPPPPPPPPP5YYJJJYBBPPPPP5555J???????JJJJJ??777?JJ???J5G#&&&&&##P    5G7   :555PJ   ^5555555.   ?PP5:   J55!^J55~   !5YYYY5?   ~5555Y..Y5^   ?555:  ^5555!   !555J   ^55?7YYY~   7555~   !5YYJY555Y?~J5PJ   ~##&&&&@@@@&BPJ???J555P5P5YJJJYYYYYYJ?77!!7777???JYY55JJJYJYPG?!5PPPPPPPPPY7?5BB?!    //
//    GGGGGGGGGGGGGGGGGGGGGGGGGPYYYJJ5BBGGGPP5555JJJJJJJJYYYJJ??777???YPB&@@&&&#BGGPP^  :55Y:  :PPP55^  .^^~^!Y5~   ^!^:   ^555: ~!.   :J5YYYY5^   J55555?.~57   J555^  :5555?   !555Y:  :55:  .    :J555?   !5YYYJJYYP7  .     75555PGB##&@@@@&G5???JYYPPY?JJYYYJJJJ?7777???JJJJJJJYYJJJJYYPP5?7J5PPPPPPGBGY775?!    //
//    GGGGGGGGGGGGGGGGGGGGGPGGGPY555YP#BGGGGGP55PYJYYJJJJYYYJJ????JYPB##BP55YJJ???JJYJ?7JPGGG5J5BBGGBPJ7!!777JGGGJ!77!~^~!JGGGGP!^^^7J5GBGGGGGG57~?GGGGGGBP5GGY~7GGGGGYJPGGGGGY?75BGGBP7!?GG577??JJYGBGGBGY??PBBBBBBBGBGJ??JJJJ5P5YJ???????JY5PGB##G5J??JJJYYYYYYJJJJJ??????7!!~~~7JJ!!7!!77PPPP5?7?5PPPGGGGGG5?!!    //
//    ############################################BBBBBBBBPY????7?JJJ??777??JJY5PGBB##&&&&&&&&&&&&####################################################################################################################&&&&&&&&&&&&&##BGP5YYJ??7777??JJJ?777?J55PGP5P55YYJJJYJ7J??7JYJJ?J?Y?JGGGGYJ777?55PGGGGGGP7!    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&###&&&&&&&&&&&&&&&#PYJJJJJJJJYYY5PPGB##&&&&&&&&&&&#######&&&&&BPGGGBGPPPPPPPPPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGGPP#&&&&&&&&&&&&&&&&&&&&&&&#BBGP55YYJJJJJJJJY5PGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPJ7?5GGGGGGG?!    //
//    ###&########################&&&#######&&&&&&&#&&&B5555GBB##&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#5Y555J7?????????????????????????????????JJJJJJJYYYYYYJYYY5YYYYYYYYYYYYYYYYY55555555555555555PPPPPPPPPPPPP555YYYYG&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&###BBP555Y?????????????Y55555555555555555555555Y?7?YYYYYY7!    //
//    #################################################[email protected]@@&&&&&&#&&&&&&&&&&&&&@&####B####&&&&@B55555JJJJJJJJJJJJJJJJJJJJJYYYYYYYYYYYYYYYY55555PY7^. ..:?PPPPPPPPPPPPPPPPPPPPPPPPPPPGGGGGGGGGGGGGGGGGGGGPP5555P&@&&&#########&@&&&&&&&&&&&&&#&&&&&&@@@@P555J^^^^^^^^^^^^~!77???????????????77?777777!!!77!!!!    //
//    #################################################[email protected]&&&GY555555B#5Y55PPPPG&&55PPPPPPPG&&&&&GPPPPJ?JJJJJJJJJJJJJJJJJJJJJJJJYYYYYYYYYYY5555PY.  .!!!. ?PP5555555PPPPPPPPPPPPPPPPPPPPPPPGGGGGGGGGGGPPPPPPPPP#&&&&#[email protected]#GPPP55YYB#P5555555#&&@@P555J777777????????JJJJJJYYJJJJYYYYYJJJJJJJJJJJJ7!7J7!    //
//    GB####################BBB#BBBBB##BBBBBBBBBBBB####[email protected]&&&5?JJJJYYG#5?JY5PPPP#@GY55PPPPPPB###&#GGGB5???????????JJJJJJJJJJJJJJJJYYYYYYYYY5555P7   ^PPPY?5PP555555555PPPPPPPPPPPPPPPPPPPPPPGGGGGGGGGPPPPPBGGGB&&###GPPPPPP5YY&@GPPP5YJ??B#5YYJJJJ?B&&&&PY55PGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG5?7!!    //
//    [email protected]&&&Y7???JJJP#[email protected]#JJY55PPPPP###&&#B##BJ??????????JJJJJJJJJJJJJJJYYYYYYYYYY5555P!   !PPPPPPP555555555PPPPPPPPPPPPPPPPPPPPPPGGGGGGGGGGGPPPG##BB&&###[email protected]&PPP5YJ?7?BBYJJ???77B&&&&5YY5GBBBBBBBBBBBBBBBBBBB###BBBBBBBBBBBB###B#####BBBG7!    //
//    !JBBBBBBBBBBBBBBGGGGGGGGGGGGGGBBBGGGGGGGGGGGGGBBBGGYYY5&@&&G7!77???5#G!7??JY5PP&&J?JJY55PPPB&&&@@&&&&Y???????JJJJJJJJJJJJJJJJJYYYYYYYYYYY5555P5^  ~5PPPPPPP555555PPPPPPPPPPPPPPPPPPPPPGGGGGGGGGGGGGGGPP#&&&&@&&&&[email protected]?7!?#BJ??77!!J&&&@BYYYP################################################?!    //
//    !JGGGGGGGGGGGGGGGGGGGGGGGGGGGGBBBGGGGGGGGGGGGGGGGGG5YYY5#&&&#PYY555G&#5555PPGGB&@[email protected]@@@@@@@@G?JJJJJJJJJJJJJJJJJJJJYYYYYYYYYYYYY5555PPP7   ..^JPPPPPPPPPPPPPPPPPPPPPPPPPPGGGGGGGGGGGGGGGGGGGGGG&@@@@@@@@&BBBGGGPP55&@#BGGPP55YP&#P555Y5G&&@&GYYYYB################################################?!    //
//    7?JJJJJJJJJJJJJJJJJJJJJJJJJJJYPP5YYYYYY5555555555555YYYYY5B#&&&&&@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&777777777777777777??????????????JJJJYY55?    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&@@@&&&&&#G5YYYYP###########################################BBBBBB?!    //
//    77!!777777777???????????JJJJJY55YJJJJYYYYYYYYYYYYYYYJYYYYJJYY55PPPGGBBB###########################B###Y?JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJYYYY555P~   ^PY::!55555YYYYYYYYYY5555555555555555555555555555555G##############################BBBBGPPP55YYJJYYYYYPBBBBBBBBBBBBGGGGGGGGGGGPPPPPPPPPPPPP5PPPPPPPPPPPP7!    //
//    7!:::::::::::^:^:::::::::::::~7!^::::::::::::::::::^~J55YYYJJJJJJJJJYYYY55PPPPGBBBBBBBBBBBBBBBBBP5YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY55555P5:   ?P7   !5555555YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY5PGBBBBBBBBBBBBBBBBGGPPPP5YYYYYJJJJJJJJJYY5557JG5JJ???7777!!!!!!!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!!    //
//    7!:..........................^~^.................. .~!Y55555YYJJ????JJJYYYYYYYYYYYY55PPPGBB##GP5YYYY555555555555555555555555555555555555555PPP~   JP~   7PPP55555555555555555555555555555555555555555555YYYYY5PB#BBGGPPP55YYYYYYYYYYYJJJJ???JJYYY55555?~?P5J7!~^^:::::::..................................~!    //
//    !77!7???????7777777777777777?JJJ??????????????????J7~~!Y55555555YYYJ??77???JJJJYYYYYYYYYYYYYYYYYYYYYYB&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&###B?. 75.   J####&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&PYYYYYYYYYYYYYYYYYYYYYYJJJ???777??JYY555555555?~~!PPGPPP5YYYJJ?????777777!!!!!!!!!!!!!!!!!!!!!!!!!!!7    //
//    7?YJ7?Y5PPPPPPPPPPPPPPPPPPPPPPPPPPPPPP555PPPPPPPPPP?~~~!J5555Y5555555YYJ??777777???JJJJYYYYYYYYYYYYYJY&@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&##GJ77!!!?B#&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@GJYYYYYYYYYYYYYJJJJ???7777777?JYYY5555YY55Y55Y?~~~~5PPPPPPGPPPGGGGGPPPPPGGGPPPPGPPPPPPPPPPPPPPPPPPPPPP    //
//    !JPPPJ7?5PPPPPPP5555YYYJJJJJJJJJJJJJYYYYYYYY55555557~~!!!?YYYYYYYYYYYYY55YYYJ??7777777777??JJJJJJJJJJJ5&@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&&&&&&&&&&#####&&&&&&&&&&&&&&&&&@@@@@@@@@@&&&&&&&&&&@@@@@@@@@#JJJJJJJJJJJ???777!!!!!77??JYYY5YYYYYYYYYYYYYJ7!!~~~YGGGGGGGGGGGGGGGGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP    //
//    7?5YYYJ7!7J?777777???JJJYYY555PPPPPPGGGGGGGGGGGGGGG!~~!!!!!?YYYYYYYYYYYYYYY5555YYJ??77777!!77777???JJJJP&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#YJJJ???7777!!!!!!!!77?JYYYYYYYYYYYYYYYYYYYYJ7!!!!~~~YGGGGGGGGGGGBBGGGBBBBGGGGGGGGGGGGGGGPPPPPPPPPPPPPPP    //
//    7!~~!!!7?J?!7Y5PPPGGGGGGGGGGGGGGGGGGGGGGGPPPPPPGPGG!~~!!!!!!7?JYYYYYYYYYYY5555555555YYJ??7777777777777?5&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&BJ77777777777777??JJYYYYYYYYYYYYYYYYYYYYYYJ7!!!!!!~~~YBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGGGGGGPP    //
//    !JGGGGGGGGG5?7YPGGGGGGGGGGGGGGGGGGGGGGBGGGGGGGGGGBB?~~!!!!!!!!77?JJYYYYYY55!^~^~~!?Y555YYYJJ???77777JP#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#Y7!~~!Y#&&&&&&&&&&&B5?77777???JJYYYYYYYYYYYYYYYYYYYYYYJJ??77!!!!!!!~~~P############BBBBBBBBB##########BBBBBBBBBBBBBBBBBBB    //
//    !7?5GBBBBBBBBPJ7JPBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB5~~!!!!!!!777777??JYYY5Y   :!~  .J55555YYYYYJJJ5B&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&##&&####&&&&&&&&&&&&&&&&&&&&&&&&&&&&&B~ .!7?! !#&&&&&&&&&&&&&BYJJYYYYYYYYYYYYYYYYYYYYYYYJJJ???77777!!!!!!!~~7B####                                                  //
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract WABC is ERC1155Creator {
    constructor() ERC1155Creator("Web3 Artist's & Builders Club", "WABC") {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC1155Creator is Proxy {

    constructor(string memory name, string memory symbol) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x6bf5ed59dE0E19999d264746843FF931c0133090;
        Address.functionDelegateCall(
            0x6bf5ed59dE0E19999d264746843FF931c0133090,
            abi.encodeWithSignature("initialize(string,string)", name, symbol)
        );
    }

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
     function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal override view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }    

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}