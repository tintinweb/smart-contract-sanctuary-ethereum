// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CryptoNicOgNFTs
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
//    &@@@@@@@@@@@@&&@@GJJ7??JPB#&@@@@@@@@&GPGBB##&@&&&&#BB#B#GG&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#####&########BPPG##&&&&&&&&&&&&&&&&&&&&&&@@@@&&&&&&&&@G555555555555J5PPGBBBGGGBBB##&&&&&&&@&&&&@@@&&B?JJJGBJJ5YJY555JJ7JBP7JP#[email protected]@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                        //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@#[email protected]@@@@@@#P##B&&&&&&&&&&#GBGG#@&&&&&&&&&&&&&&&&&&&&&&&&&&##&###BBP55PBYPBBBY?Y5??B##&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&5Y5555555GGGGPPGGB##[email protected]@@@@&&@@&&5JPBG7^YGGGGB#&P5PY?BP7YJ#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B5YY55YJJ?J5GBB#@@@@@@@@@&&#BPB###GG#&#&##@&@&&&&&&&&&&&&&&&&&&&&&&&##GB###B5J!Y577!PGGJ7GBGJ!5B###&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@BY55555PG###G5JPBB##[email protected]@@@@&@&#&&&BJ^: ?BBPPB&#BP55?Y5?55P&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@&&@&@@&&&&&&@@&@@@@@@&@@@@&P#&@5^.YB! .:P&#@@@@&@@@@BG5J?J?JYJ5GB&&&&&&&&&&#####BG5GP5Y5GB#####B5!GBBG?!7?PG5~!YP5!55Y?JJ!GB####&&&&&&&&&&&&&&###&&&&&&&&&&&PYY555PGGP5YYJY5BBBPY?J5G##P!YPPGGG&@&@&&&###GPGGJ. [email protected]@@&&@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&@#[email protected]&@@@@@@@@@?. . ^BB^.:!YB&&&&&&##PB##BPJ7~??5PJ?B55BBBG5?JJJ7!YPGBGP!YJJ!!JYYPP!JB55####&&#&#&&&&&&&&&&&&#&&&&&&&&#YY5555PGPY?!7J?YBBGP5Y5PB##[email protected]&&&&@&Y!~YY5GYJPBB&&&&@@&@@~::^7P55&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&P&@#[email protected]##&#&&&&&&&&G:^JJ~:77:~!..G&##&&##BJJYYJJ5Y^JGBB57GJ5GP?J7YGPP!5BBBGGJ7P5P!YGGGG7~55~YBB##&&###BB##&&&&&&&&#&&&&&&&&GY555PP5Y?7~!J7JB#&[email protected]@&&@@@#GPGGP5JPPJG##&B&&##[email protected]@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@@&&&@@&&&@@@&BB##&##BB#&&&&&&&5~~?GY7:~YGY!~5YYBBBBGBBGPPGGG7JGGGGJ?Y!PP!YGYYPGP!5GGGG?^J?7P??PP5?~!J7YBB##&&&&&##B###################555PGGY7!!!~^7!B#&BY?YY?JYPBGY7!77J&&&&&&&&&&@@&&BG?~:G&@&#GPPPPG?^~7YG&#&@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@&&&&&&###G5JJG##&&&&#JG5Y5!~~~757??Y!?5GJ?J?PGGGGP?^5GGPP7Y??P?7PPGY!PP??PPPY!?JYPPPJJ?7?~7YGBB##&#&###########BBBBBBBBBBBBBG55PP5JJ7!~~~!?P#&&GY7!?JY5PPGPY?7!5&&&&&&&&&&&&&&&&#P5&@@@B5P55PPY [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&##JY##BY!YPY!5PB###GP#GYJ!77!!??5Y?!PPJ7PP!YP5PP?!!PPPP5!5!JY!!JY?7YPPPJ????5PPPPPPPJ!Y?!PGB###BPYJJY55PPG######GGGGGGGGGGGP5GP?!J5P5J7~Y#&&&#B5J?JYY557PPPYY?B&&&&&&&&&&&&&&&&@@@@&@@#?5PY57!!!YPP#&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@&&&&&&&#G~YBBJ!PBGJ!?~!5GBGY7YGY!G5~JY??P7?G5~5P7~Y?7YJ!77J??J77YJ??JYJJJYYYYYYYYYYYYYYYYY55JJJPBB#BPY7~~^^^^^~~7JPB##GYYYYYYYYYYY5GPY7^Y&&&&######&#B5??JY5P?~YPPPPG&&&&&&&&&&&&&&&&&@@&&@@@Y!5BP5PPPPPB&@@@@@@@@@@&@@@@@@@@@@&@@@@@@@@@@@@@@@@&@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&@@@@@@@@@@@@@@&&&&&&&&&&#B?755~J5J?JPG7!Y!JGJ7GG7JG?!PY^?J~YP7~YJ7JJJJ5Y7!??JJ?77Y555555PGGGGPGGGGGGGGGGPPPBBBBBBB#57!~^^::::::^^^~~75##BGGGGGGGGG5?555?:7#&&&#&##B###BGGGGGGG?!~Y5PPB&#&&&&&&&&&&&&&&&&&&&&&&#&&&&&##GY&@@@@@@@@@@@@@@&@@@&&&&&@@&@&@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@&&&&&&&&&##PY7~Y5PGBBP~5P!YP~JGY~5Y~7Y??YYJ?JY5YYPGP5J5?7?55YYY5Y75PPPP55PGBBBBBBBBBBBBBGPB#BB#BB#P7~^^:::::::::::^~!!Y#BBBBBBBBBB577Y7^7P&&#&##BBBB##BB5~^!5PY7~755P##&&&&&&&&&&&&&&&&&&#BB#@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@&&&&&###?7BBBBBG7JBP!J?7?J!~?7!Y5PBBBBBBBBBBGGG5J???5YYYY5YJYYGGPGPPYGB###########BGG##B&BGB#Y!~^::::::::.:!?55J?7J#BB######B?J7~~P#&&###BBBBB####5::^YPP5?7~Y5G&&&&&&&&&&&&@@@@@&&BG##[email protected]@@@@@&@@@@@@@@@&&&&@@@@@@@&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@&&@&@&&@@@@@@@@@@@@@@@@@@&&&&&&##5~5GGG5?JBBBP55Y??!?5??BB##########BBGG5Y?!7YYYYY555P?55YPPG55B##########BBGB&BB&GPB#Y!~~~^^:::::755Y?!7?J!J#BB###&&G7??~P&&&####BBBB#&&#Y7~~?PP5P57~75#&&&&&&&&&&&&&&&&&@#G&#&&GB&@&&&@@&&&@&&@&BB#BG&@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&#PJJYY5G######Y~YJ?GBYG##&###&&&&&##BBG5JYJJJYP5?JPPP55YYYPG55B&&&&&&&###GGB#&GB&G5B&BPPP5YY?^::~???YGBP5G7~YBGB&&&&#GGPJY&&&###BBGGBB#P~!Y~^!PGGGBY?^Y&&&&&&&&&@@&@@&&@&&G&###&#BB&@@@@@@@@@&#BB#&&&[email protected]@@@@@@@@@@@&&@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@@@&&&&&&&&&##&&##&&&##BYY5B#B5Y5B&##&&&&###BBGG5J5Y55YPY55?YGYY5JJYPYG#&&&&&&&&#BPBB##G#&GYG&BJ!!!777!~:~7?J?55?77~~!5PP&B5BG5YJJ5G##BB###BBB#[email protected]&&&&&@@@@@&&&@@&#BB&##B####GB#&&&&&&&#BB&&#B&#G&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@&&@@@@@&&@@@@@@@@@@@&@@@@@@@&&&&&&&&&&&&&&&&&&&&&&&BJ~^^^~Y&&&&&&&##BBGG5JP5Y5PPPGBP5YYYY?J55G###B##BBB5??GB##BB#&G5P#&BPBGY?7~!^:!7~~~~~~~~~~?55P!:.7J?77J?Y??BBB####BBGGGP?JJ5GGGBPJ7P#&&&&&&&&&&&&&&&&&G#&####&###BB###BBB#&###BBB#&G#@&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@&@@&&&&&&&&@&&&&&&&&&@#Y~^[email protected]&&&&&##BBBG5JPGP55PPP5YYJJ??~~?5BB5?!^^^!^~7JBB##BB##B5G#BP?JJ!~^^!!^^!!^^^^^~~~!7YY?^^7?!:!YJJYY75#PB&####BGGPJ5GGBB#######&&&&&&&&&&&&&&&&#G&&##&#BGGBB#&@##BBB&&#BB###&G#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@&&&@@@@@@@@@@@&@@@@@&@@&@@G^:^:::[email protected]@@@@&&&&&&&&&&&&&&&&&5~:^7??YJ~!?&&&&&###BBBB5JPGBBG55YJ~!!^~^?Y7!^^:     .  :7P55GPG&#P55BY!~~^^^^^~!!^~!!^^^^~~!!7Y7!J5?5Y  PJJY55JGG#&###BBGGPJ5GGBB###&&&&&&&&&&&&&&&&&&&&###&##BP55PGB#&&#BBGPGB##B&##&G#@&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@&@&@@@@@@@&@@@@@@@&@@&@@@@&&&@@&&&&&&@?:^!~^:::[email protected]@@&@@&&&&&&&###&&P!:^~!7JJYY!!!B&&&&###GP5Y??5Y555?..  ~55PGBB5!.   .~^ :JY:.5YP5##&BJ55B57~^^:::^!777!??!^^^^~!!7Y7?PYJJ7!~??Y5JPY55B##BBBBGGPJ5GGGBBB#&&&########&&&&&&&&&BB#BG55555PGB#&#BBPPP55G#&##&#BB&&&&&&&@&&&&&&@@@&&@@@@@@@@@@@@@@@@&&@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&!:~7!^^::::[email protected]@@@@@@@@@@@@@#J^^^!7?JYYYY7!!YPY5GPPP7..  ^7777!^^7^ :B####GY^.75.J&#^:Y5~~5PYP5#&PYY5BP?!~^^::^~7?7!~~^:^^~~!!J5Y?YPPGGGBBGYJ5P55PBBBBBBBGPP?5PGGGBB##############&&&&&&GY?7~~~~!!!?YG#&#GP555555PB####BG&&@&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&!:^7?!^^^:::^?B#BBGP55YYYYJ~^^!??JJY555P?~!!!!J5J55J. !Y7?JY555PPJ. Y###PGPY~~?.:!~~..~JP#55B5B&5YYYGGY?!~~^^:::^~~~7?777!~!7Y?J555PY~.:7YJYP55G##BBBGGGPP5?YPPPGBB#####BPYJJYGB##&&&#P7^^!7???7!~^^75PY7!~!!!77?YP#&BGB&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&@@@@&7:^7??!^^^^::::^:::::::::::^^^~7?JJY55Y?J5P555Y7!JP5^ ~PP55PPPYJP5?.~###GB#BB5JY?::^::^~!7?5BB##GYYYY#PJ?7!~^~!7J5YY55Y?~~~!YJ7P5GPYPY?J55PP5JJPPP55555Y?7!~~!~~YGBBBBBGP7:!^^5PGB###G7~^7JY555YYJ7^^!!^^!7777!~~^~?B#GB&&&&&&&&&@&&&#&&&&@@@@@@@@@&&&@@@@&&@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Y:^!??7~^^:::::::::::::^^^^^~~~~~7?J55Y7!!!~~~^~!YPP7 75PYYP555GP55!.G###B#B#&&P^.: : !PY7..5#&##YYY?B#PJ?7!~~!7?????7~^^~!!7??YYPY?5YJ?7Y55J!^^^!!~^^?7:~!^:7!:!PGBBBBGP?:^~7!!YGB###5~^!JYY555YJ7^~!~^7JYYYYYYJ7^^?GGB&&&&&&@&&@@&@@@@&@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@@@B^:!???7^:::::::^^::::^^~:~~~^^~^~77Y5PY~~!!~~!J7!5PY.!5YYP7!Y~7!:7! J&##&&BB#? ^P7 !! 7GGJ ~P5P#[email protected]@B5J77!~^^^^^:::^^!!!!!7?JYJJJ?~::7JYYJJ~:7J?~:7?~7J~:7J7JPGBBBPPJ~~~^^~J5PPB&&PJ!^~!77?77~^!?J!^7JYY555YJ7^^[email protected]@@@&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@&&@@@@@@@@@@@@@@@@@@@@@&&&&&&Y:~7??!:::::^7^7~^^~~~!77J7!77?7^!7?5PJ^7J~^?~~^.!P5~.7~:: ^7^.:!!  ^#####BBG. 5G? 7B! .~! !PP!~GJ5JP&@@@#P5YJ?7!!~~~!!!!!!!!777Y!!!!:^~:!?YP5!:^~~:^?YYYJ!:!YPPGGBBGP5^^J?~:^7!~PGBBBBGPJ!!~~~~!7J55J!^~7?JJJ?!^^!PBGB&&&###&&&&&&&&&&&&@@@@&&&&&&&@@@@@@@@&@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&?~7?~:::^~!77???77!!!7?Y5P55Y5PY7~~YPY^.. ^J^ .!5PP?  :~!!!!7??7!7?JB#BB##JP? !?::YY:^J?7~:?J^^5J5J5&@@@&GYYYYJJJJ??7!!!~!7??7??!!!~:^~^:~755?^^JJ7:~?JJJ!:^?J5PGGGGGPJ~~~!??!7JGB##BG5JYJ7J?777J555Y?!!~~~~~~~!JP#BB&&&&&&&&@@@@@@@&&&&@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@&?~!:::!5JY55G5?~^::^^7YGPY5YJJ?7?7J5PPY?!!~!?Y5YYJ?!??Y5?!7!!~Y#BBB#####B~PB7.:.:^:~5GPPPPJ?JYJJJJP&@@@&BY?7777!!!~~~7!77777!J??!!^:~~~^:~7J7^:~7?^^^7J7^^^~!?JJ5GGGGGP55PGGGBB####G?~~7?!!~~^YBP&BPB?~????7?P#&&&[email protected]@&&@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@&@@@@    //
//    @@@@@@@@@@@@@@@@&&&&@@@@@@@@@@@@@@@@@@@&&&&&&&@@J^^:^!7!77!7!:..::::..~!7!!!~~!777YJJJ?YY5555!::::Y#BGP55555557^YBB#####Y777J7?7YPGGPPPGGPPYYJJJJP#@@&##P?!~~~~~~~~77777777!7J7~^^^~!~^^^~~^~~^~~~~~^!?~^~^:~~:!55YJ???JPGBBB######B7JY5Y!~:~YB&@&B#7:77!!!~!5#&&B#&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@&&&&&&&@&@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@&&&&&&#~!^^^::::^^. :?PGB#GY: .^~~~^^::::^::::7?7777~~~^:!BBY:~!!~^^:::7BB#######G5J7?YGPGGPPP5555YYYJP5GB&&&###GJ!~~~~~~77!77??7!~7J7~~!~^^^~~^::~??7^:7?7~:7^~?!:7J~~Y7:!77^!5PGBB####&&#G##5J?!~7YB&&#GJ~:^7??~^75#&&##&&&&&&&@&&&&&&@&&&@&&&&&&&&@@@@&&@&&&&&&&    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@&@@@@@@@@@@@@@@5^!^:::::::.  ?&&@@@&#!   ...      .::~!~!7777!!!!::PBG~:::::::~^~YGB#&###G?J?7JY5PP5555PPPY5PY5BGBG&&&#B##B57~~~!777????7!!?JYJ!!!~~^::^!^:!J5Y!:!!:~!?!?J?:!YY557^~~~^~JPB####&&&&&&##&#5?Y5#&##&BP??JYJ77?G&&&B#&@&&&&@@&@@@@@@@&&@@@&&&&&&@@@&@@@@@@@@@@@    //
//    @@@@@@@@@@@@@&@@@@@@@&@@@&&&&&&&&&&&&&&&@@@&&@@!!!.         .~5#&&&#57.    :~.    .::~!!!!!!!~!!7!:?BP!:!?~::~7^.~PB####B?7Y?7?5P5555PGP5555YYGG##P#BBB#BGGG5?!777?????7!!JJ?JJ!!!!!~:~^^~:~7557:^~:!YY?YYJ^^Y5P5!^777!:7PGBBBBB####&#P#&#7~55GGBBPY5JJYP#&&&&#GB&&&&&&&&&&&&&&&&&&&&&&@@&&&&&&&&@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&&&&&@@7~!:    :!^..^75GBBBBGY!:  ~GB~    :^:77!7?7!~?Y7!7~~BG!..:.~5^. .7BBBB#B?!!?J77Y55YP555PPP5Y5PGPB#PP#BBGBBGPG5?777???77!7JJJ??J?!!!!~:~~^::~7?5?:^?!J5Y?J?!^:~!YP?~!~~!!JGGBBBBBBBBB##JG&&5!JPPPP5?~!5#@&BBBB###&&&&&&&&&&&&&&&&&&&&&&@@&&&&&@&@@&@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#~!~:   ^5G?~7PP5#&&#5J#Y!YBP~    ^77:!!~!7^!Y^^:.!~:5BG?^:.:^::!YBBBB##J!!~!J??YYY55555G55YGPPB#GGBYG##BBB#GPGY?77?7777?JJJJ??YJ!!!!~::^~^:~77!^^^^7555?7J~!!77?JJJ??J7JY#####&&&&&&&#P5GB#BYYY55JYPB&&#BB#BB&&&&@@@@@@@@@&&@@@@&&@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@&&&&@@@&&&&&&&&@G~~~:. .:?PPJGB?Y555YY5~7Y!.   .:!??^^~^.. ^!:.:~~::7BBBGP5YY5GBBBBB#B57!!~!!?JYYYYY5Y5B555BP5PBBGBP5G##BBBBP5JY77777?YJJYYJ?JY7!!!~^^^^!!~!77!JY55PPP5J?P?J55Y?7??7YJY5B##&&&&&&&#&&B?5#####BBBB#&&###BBBGB&&&&&&&&&&&&&@@@@&&&&&@@@@@&@@@@@@@@@@@@@@@&@@@@    //
//    @@@&&&&&&&&&&&&&@@@&@@@&@@@&@&&&&&&&&&&&&&&&&&&&@P:~~^.. ..~!~?G#&&&#J^::      .~7?Y?::^~~~~~!?7!!7??PPPPGGGBGGGGGGGGG?7!!!!!!7YYJJY5Y5G555GGY5PBB#B5PBBBBBGPJ?YJ?7?YJ??!!!Y5Y7!!!!!!!!!!!!!777JPPPPPP5JYJY55J7!??!?J5PG######BBBB#&#&5YPPB&&&&&&###&##BBGP###&&&#&&&&&&&@&&&&&&&&&&&&&&&&&&&@@&@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@J^!!!^.......:^7JJ?!:.       .:~!J5!~7JYP5JPGB55J5YY5555PPPPGGGGPPPPJ7!!!!!!!7?YJ?YPYJPPY5G#PYPBB##GPBGGBBGY77JYJJYY7J??!7PY7!!!!~~~~~~!!!!77775PPPPP5J5J5??Y5?!~?5?^7B&#BB#PGB#&&BG##PYY#&&##B&#GPB#P5GPBBPPGB##&&&@@@&&&&&&@&&&@&&&@@@@@@@@@@&@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@&@@@@@@@@@@@@@&&@Y:^~~~:..........          ..:^^~5P??YPPGGY##PY5PGGGP5PYYYYYYYYYYYYYJJ?J??J???JYYJJYYJY5Y55P5Y5555GP5555P55JJJJJYJJJY5YJJJY????????77??????JJJ?JJJJYYYJ5P?.:^::YG?:^~~P#GGGGB##B#&BGB&&BB&&####&BGBBGGGB5JJJ5GBBB#&&####&&@@@@&&&&#&&@@@@@@@@@&&&@@@@@@@@&&    //
//    @@@@@@@@@@@@@@@@@@@&@@@@@@@&&&@@@@@@@@@@&&&@@&&&&P:~:::^:........         ..::~!!7JPP55GB#BB&BYPGB#GJ?YJG575B57JJJ???!7Y7??7?!J7777J77YJG?7JGB#BBBG?7?B###G7~~J~!!?!^^~~^^~:^:~^~^~^^^!~^~!~^^!JJYJJY5J?J#B55J!!JPJ?Y55P##5PB&BB&&&#GPG#&&&&##B#&#B#BBPY77JY5PBB#######&&&&&&&&&&&&&&&&&&&&@@@@&&&&&&&&&&&&&    //
//    @@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@&&&&@&&@@@@&&@Y:~::^:...           ....:^~!7???JYB##GGPPB5YYY?~JG?YPP5GGGB5^~!~^^^::~.^7:!~:.~^~!::7^5^~^G####BG?^75B#Y?::.!.7?JY:^7...: ^~!:^:~::.~::.^!.^[email protected]&@@&#BBBG55PG#@&YG#BB&#BB#&#GPPG#&###&##BBBGJ!~!?J5GG##BBB&&@&&&&&&@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@Y^^^:::...::........:::^^^~!!777?JYGBBPPPP7..:!??:JGYYPYJPPPGPJYY55YYJ7JY?P?7JPY???5YY5Y55YP#####GG7:?JJP??YJYY!7JJ5?77!~~^~7?77~~~!!~^~^~^!~!J5?7YPB5PGP&####&&#5~:J#GP5~JB#GBPGB&###&###&##B#BGB###Y!!!?YPPGB#BBP5PG#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Y:~:.:::.::::^::::::::::::^^^~~!!7JYYY?J75B~ : 7GP7BG5YPJYY5PYYJY5BBBBG5YPJYB#Y5P!?PB#BB####G55YPG5GJ777!!!755555#BGJ^:::~?!^7!!!!7!777^~~~~!~!~~~!PPJ?5GBBBGBBPJ~:75BB???:YBBBGBB&&#BB#&&&&###&&&@&&5??7?PGGBBBBG5555555G#&&&&@@@@@&&&&&&@&&&@@@@&@@@@@@@@@@    //
//    &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@P:~^^^^^:::...:::..        ..:^!7?????7!YY~:.:~:.^7B&P55PPJ?JJ55Y55GGPBGP5J5YJJPY5PPB##&&&&BP?J7JJ?Y5??YPP5B#G7^YB##G57:~J7J??7???!!JJJ?7!!777~~!7!~!?7JYY###&#P!:7G#BGG7?7~GBBG&##&#BBBB#&&&&#&&&BP#GYPYJBBB#BBGP555Y?!^^^7&@@@@&&@&&&@@@@@@@@@@@&@@@@@@@@@@@    //
//    &&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&~^^^^^::........            ..:^!7???7!??JJJYJJJ7G&&&G5J7!?JBJJJJ?!7J?GP5PJ:7!??J?55?5&G555&BYY5JJ!YGY^^?YB#@BY:JP?BGYY?7JY5YYYP5!Y5Y?7^77!YJJJ?J55~:5555G###P!:7P#&BBBB?7?JBBB&&B#BB#BBBBB#&&&&&B!7G5BGYB##BG5Y5YYJ7^:^!JYP&@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&@@Y:^^^^::^::...:.            ..:^^~!!7!!????J5P7~YYJGB&G5GYP#G#G!?P??!!Y?~J!5?7??^~!GGG5!J#555#&&&#BPPG!!77YB#BPGJPP&#5JYY???J5PPPPY5P5Y7?J?^JYY5Y5YB?:J5#G##P7:!P###&GBBB#P5GBB&&B#GG5PPBB##B#&&&#??PB#&GG#BG5J?JYY?~:~?5G##&&&&&@&&@&&@@@@@@@@&&@@@@@@@@@@@@@@    //
//    @@@@@@&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&!^^^^::::^^:~^^.    .     ..:^~~!~77??!7YJJJ55:.7Y?YBBPPB&@#B#&B5GP~^?PJ.:7B7~?G5?#BG#Y5PP5YY5&###B&&GP55PG5GGYJJYG#BGYJJ!!7?5PP5PYYP5G5J5PJJ55P5YJ5!:??PGG7:!5&&#&&&BGBB##BB&#&##PBBBPBB5GPG&&&B7!5P&&#PG5YYYYYYJ7^:75GGPPP&&&&&&&&&&&&@&@@@@@@@@@@@@@&@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#^^^^^^^^^^~~7!!:.......                                                                                                                                                                                                                                            //
//                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CNOG is ERC1155Creator {
    constructor() ERC1155Creator("CryptoNicOgNFTs", "CNOG") {}
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