// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BUDDHA
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                          //
//                                                                                                                                          //
//    BPBGB#BBBG&#BBGP5GBB#BGBBGGPGB#&@@@@@@#GPG#######BG5PBBBBGJJ5#&&&&#5?YG##G55B#BBBB###BBGB&@@@@@@&#BB#BBBBG##BGG5GPBB#B####B###&#&@    //
//    GPGGB#BBB#&B##GBGGB###BGBB#BBGBB#&@@@@BPPB###BBB#BP5B##BBGGPP#&&&&BYJYGG##GYJGBBG#####GGB&@@@@##BBBB###BBBB#BBGPGGBBBGB#########&@    //
//    PPGBGGBB#BBGBBGGGGGBBGBGGBBBBBGBBB#@@@BGGG####BBGGPBB#B5PGBBB#&&&##GGYPBBGGGPPPGGBBBBBGGB&@@@#GGGBBBBBBBBBBBGGBBBGBBBPGB##BB#BB##&    //
//    GB#BG5GB#BGGGGBGGPGB#BPBBGB#BGBGGGP#@@BPGPBBBBGGBBBBBP5Y5PB&##GBB#B##PG##PBB#[email protected]@@BGPGBBBG#BBBGPBBGBGBB####BGB##B#######    //
//    ###&#BBBBGBBGG##GPPGGP5BBBBGGGBGGGPG&&#PPPBB#BGPPB#BG5J?JYB#&####&#&#BGBBGBBB#G5GBBGBGPGB&##PGPPBBGPGB#BG5PPBBBGB######BBB#&&##&##    //
//    #######BGBBGGGGGGGG5BGP5PPGBGGBGPGPPG&&PP5GPGGG5PBBBB5555PBB&BGBB#&##BGGG5B#BBGGGBGGBPPP&&BPGGPGBBBGGGGGGBGBBB#BBB#####B####&###BB    //
//    #&B####[email protected]&#BG##B##GGG??PPPGBGPBBGG55P&@GBPPGG#BGGGGGBBBGG##BPGGB#BBBB#&####&#B#    //
//    &&###BB#BGGBPPJJ?JGP5J?JYPPPP5PBBGGPP5&#555PPGPPPG55PP?J5GB###GGGBBGP555??GGYP55PGBGG5PG&#PP5PGB#PPBGGGGGGGB&#BPGB##BB#BGB####&&B#    //
//    &&&##BGPGBPG5BBY7YPGGB5??5PGBBBGGP5555G&P5Y5P5555P5PGP?JYGB#PP5P5PPBG55J7JGGPYPGGPGG55PG#5555PGPG#&BGGPGGB#B##GGGB##GB##PG###&&&##    //
//    #&####BGPBGBG#BPY?7JJGB5JJPPGGPYY5GGP55GP5YYPGPPGPYPGBY?YGB#5YYPYJ5BGPJ?7YGGP55P5GGPY5PB5555P55Y5GBGGPPGGBBBGBPPGB#&B###PB#B####B#    //
//    B##BB#BPPGBBBPYJ??J?YPYP5?Y5P55YJYYPG5YYPYJJ5Y5P5PP55PJ7J5YYY?YP5?5PPGJ??YJ7JY55Y?P5Y5GP55Y5P5PYPPGGPPGBGPBBBBBGBB##GG##GGBBB###B#    //
//    B##BB#BGBBGGB#G5PPPP555YPP5YGP5JYYYY5555YYYJ5JJ??7777YY77Y5YY55GPPPP5GJ??YJJJ?Y?J55YJYG5PY55555P5GP5PPGBBGGGGB#BGG###BB###B##&#B#&    //
//    #BB#B#BGBBGGBBYJGGYYYJPBBPJ7YP5YJJY?J5Y5YYJJ555J5YJY5P5!!JP55PPGGPGP5PJ?JYYJYY5YPG5J5PP55Y5JYYYP5P5Y5GGBPGBBB##BGGBGBB##PB##&#GB&@    //
//    &BGB###GB##GGG55GPPPPPP5PGYJ?Y?77777Y5YJJYYY5P5J?7777J5YYYPP5P5PPYP5PPYY5J?77777?Y5Y5P55Y5G5JJ???Y55PBGYPGGGB#BGGGGBG#&&###BBBB&@@    //
//    @&BGGB##B##PGG5Y55PP55PPPGGYJ?J?J?YJY555JJYYY577777?JJY5PPGPPP5P5J55PPPGPYPJ77JJ?JPJ5PY5YYYJJY555PPPPGY5GGPPBBGGGGB#PBGGG#BBG#&@@@    //
//    &@&BGGBBGGPPGPPYJ5YP5PGGBBBGY?YJ?77!!7?YYJJYJY?JJ?7JY5Y5PP55PGGGGGPPP5PGGP5YJYYP55PY55P5J?J????YPPGPGBGBBGGGBGGGGGPGGPPPBBGG#&@@@@    //
//    BB#&BGPGPPPPPPP5Y?JYGPBBBGBB5JPY7?7!777JYYJJY55P55YY5YY55?!7YYYYYYY5J7YP5YJYJYYPY55Y55G55YYJ?YJYPGPPBBBBBB##GPPP55GPPGBGBGG#&&@&&&    //
//    GGGB##PPGGPPPY??5J?Y5GBGGGGBGY5PYY?7?J5YYYJJJJ5YYYYYYPGGPP5P55555YY5PPPPGGP5PY5PYP5555YJ5PP5555PGP5GBGBGBBBGPPPYJJ5555GGGB#&&&#B##    //
//    BGBBG#BGPG55J?JYYYYJYY5PGPPGGPYY55YYYYYYJJJJYY555PPPY55PGPGBBGGPGGPGBGPP5P55GGPP5P55Y55YPPP5PGPPYYP#BBGGBGPPP5YY5P5YPPGGB&@&###BB#    //
//    #BGGGGGBGP5PP5Y???J55YJ55J5?J?77J55P55PP5J??Y5Y5PP5P55PPP5Y5555?YPP5555P5P5PP5PPPP5YY55P#BPPGGP5YYPPGGGBBP5GP5YJJYP#BGB#&&#BBBBBB#    //
//    BBBBBGBPGGPGGJ7??JYJ5Y?7?7777?YPGP5GG5PGPJYJJYJ5P5PPPP5PP55YJ555555Y5PPPP5PGPP55PP5Y5PPGBPPPGGPB#BGGGGG55PPGP5JYYJYGGB&&#BBBB#BBB#    //
//    GGBBBGGGPPP5P5JJ?JYJJYJ??JYPBBGGG55P555555YYJYJ5PPYPGPGGGPGPPP555PPGBGGGGP5PP55PPPYYYPPPGGGPPPPBBBBB#BBG5PGPPPPP55PGB###BBBB&####&    //
//    #BBBBBGGGPP5PPPP55YY5P5PGBGPY5YY??J5PPBPY5Y55P55PGGGGGGGGPGPPGPPPPPGBBGGGGGGGGGGGBPGGPPPGGBBGBGPGBBBBB#BGPBGGGPPPPGB#BBBBBBBBB####    //
//    BBGGP#BGGPP5PP5P555P555P55???J55PGGGGGGPPPPGGGGGGPGGP5Y5YY5YYYYY5YYY5YY5PGGGPGBGGBGGGBBBBBGGBBGBBBBBPPGGGGGBBGGPGBBBBBGGBBB#B##&&@    //
//    ##BBBBGP5YPGGP5PP5PBP55P55Y55555PGGPPGPPPPPPPGPGGP55Y?J5YJJJ55YYJJY5PYJY5PPP5PBBBGGGGGGGGGBBBBGGGGGBBGGGGGG##GPPGGGGGBBGGPGB#B#@@&    //
//    ##&##BP5JJPGPG55PPP5PPBGPPPG5YJY###BP5PPGGGGGGB#PYYJJJ5PP5JYPG55JY5PP5Y55YY55555GBGGGGGGGBBBBB##G5Y5GGBGGBGGGGPGPGGPPGBBGBBB##&&&#    //
//    ##BB#GY55P5JJYY5P5P5P55??YPPPGG5B##BGGGBBBBGBBBGGGP55YY555YJY5YJJY555YYY5YJ5PPPPGBGGBBBBBBBB##&PYPGPGP5JJ5GGGPPPGGBPYPGBBBB###&&#B    //
//    ##BB##BBPYJJJJJY5555PP5!?5GPPP5YGB###BBBB#BPBBGGGBBBGGPPPP5Y5555YYYY5PPPPPPGGGGGGGGGGBBBB#B####PYPP5YPG5?YBBGPGPPGPPP5YG#&&#&#####    //
//    ##&##BBBG55YYYPP555YP5P5JY55GP55G5Y##BBBBB##&&&&&&&&&&&&&&###BB#BBBGB##&&&&&&&&&&&&&####BBB##&GGGYPBPPPPPGBGGGPP55YYPGB&&#B#&###&&    //
//    &&&#BGGGGBGPPGGPPP555GGG5JYPGGYPGJ7B##&&&&&&&&#####BBBBBBBBBBBBBGGBGG############&&&&&@@&&&###5PB5YGPGGGGBGPBGPGPYPPP#&&##&&####&#    //
//    &###BBBBBP55GGGPGGP55GGPPPJJY5JGGPB&&&&##BGPP55555Y555YYYYJJJJJJJJJYYYYYYYYY55555PPGGBB##&@@&&G5PPJGG5JGBBBGGGGBBGGB###BB#&&&&&&##    //
//    &&##B#BB#G5P#BBGGGGPGGGPGBPJ?JP#&&&BBGPP55555555YYYYYYYYYJJJJJJJJJJJJYYYYYYY5555555PPPGGGGGB#&@&#BP5YJYBBBBB##B##BGB#BBBBB#&&&##PG    //
//    GGB#BBBBPP####BBGBBGGGGBBB#BGB&&&#GP555555555YYYYYYYYYYJJJJJJJJJJJJJJJJJYYYYYYYYY55PPPPPGGGGGB#&@&#BB###BBB##BB##BPB##BBB##&#PYGGG    //
//    5PGBB#P5B&&####B#BGGBGBBB#BGB&&#BPP55555555YYYYYYYYYYJJJJJJJJJJJJJJJJJJJJJJJYYYYYY555PPPPGGGGGGB#&@#B#####B###BB#&#######BBPPPY5PG    //
//    GGGBB##B#&&&&#B#BGBGBBBGGGGB&&#GPP555555YYYYYJJJJJJJJJJJJ?????????????????JJJJYYYYY555PPPPPGGGGGGB&@&BB########B#&&&#BG##BPYYGGPG#    //
//    GB#####B######GGGBBGPGBGGGB&&#GPPP555Y5YYYYYYJJJJJJJJ?????????????77?????????JJJYYYY555PPPPPGGGGGGB&@#BB########&###&#B#GG555PBB#B    //
//    #BBB###BB###GBBBBGPG55BGGB&&#GGP5555YYYYYYYJJJJJJ??????7777777777777777777?????JJJJYY555PPPPPPPPGGGB&&#BBBPGB######B#B#BBBPPG###BB    //
//    #GB&#B5YPGPGBGG#GPPP55BGB&&#GGPP555YYYYYYYJJJ???????77777!!!77777!7!7!!77777????JJJJYY55555PPPPPPPGG#@&BBP5GBBBB&&BBBBBGGB##&&BGP#    //
//    GP#&@#Y5B#G5GGGBP5PP55BB&&#GPPP555YYYYYYYYYYYYJJ??7777!!!!!!!!~!!~!!!!!!!7777???JJJJYYY555555555PPPGB&@#BP5PGBBG##B&GPBPY5&#B#PPPB    //
//    BGB&&@&#BBGYYGBBBG5YY5B#@&BPPP5555YY555YYYJYYYY555YYJ7!!!~~~~!~77~~~!!!!!!!7?JY5PPPPPPPPGPPP555555PGG#@&BGGBBBBBB#GGPB##PP&&BGBPBB    //
//    GBGGB&BB#&B5#BB#GGPY5PB&&#GPPP55555YJ77!!!7777777??JJJJ?!~~~^^^~~^^~~~!!7?JY5555YYYYYYYYYY555555555PG#@&BBGGGGBB#BBGYG#&&@&#BB#BB#    //
//    PGBGBB55PGPBBB&&#BGGGBB&&#GPP555YJ?77!!!!!!!!!!!!777?????7~~~~~~~~~~~!!?JYYJJJJJ??JJJJJJJJJJJJYY555PPB&@#BGGBBB#&&BBPP&#G#BGBBGPB#    //
//    GGBBBPPGG###BGPPPGGBBBG&&#GGP55Y?7777777777777!!!~~~~!77777!~~~!!!!!7?JJJJ??7!7777?JJJJJJJJJJJJJJY5PPB&@&B#####&###B#GGGPBG5B##PB&    //
//    PPG#BGBGB###BBBGP555PGG&&#GGP55J?????JJJJJJJJJ???7!!~~~~!777!!!777?JJJJJ7!~!!77??JJYY55555YYJJJJJY55PG&@&BBBGGBBGBBBGBBBBBBGBBP5##    //
//    G##B##BBG#####BGGGGP5Y5#&#GP55YJJJJJYYYYYJJJJ????7777!!~~~!777777?YYYJ7~^~!!777??JJJYY5555555YYYYY55PG&&BP55GGBBB##BGGB#BBB#BGPYGG    //
//    BBB###BB#&##BBBP5GBGP55G&#GP55YYYYYYJ?7777?J??77!!!!!!!~~^!7?????Y55Y?~^~~~~!!!!7??JJJJJJJYYYYYYYY55PG&B5YPGBBGPPBBBGGG###BB#&###B    //
//    B###B###GB#BG5PYYGGGGGPB&&GP55YYYYJ7~^^:::~JJY7J~::^^~^^^^!?JJJ?J5P55?^^~~!~~~!J?Y5JJ^^^~~~7JYYYYYY5PG&GPGGBBBPJYGPGGGB#######&#BG    //
//    #BB&&&&BPP#GPJY5YYYYPGGB##GP55YYYYY7!!~~^^^!7??!::::^!!::^7JJJJ?JPPP5?~:!7~^::^!JJJJ!~~!!77?YYJYYY55PG&#GGGGGGP?YP55GGGB&&&#####BB    //
//    @&&&@@@BPP#G5J?YJ??JY5PYJPGP55YYJJJ??77!!~!!!!~~^^^^^~~^^!?JJJJ?JPPPPY!^7!~^^^~~!7777??JJJJJYYYYYY55PG##BGGPYYJ?P5J5GGPG#@&##BPBB#    //
//    @@@@@@@#PPG#PYJY5JJJYJ???5GP55YYJJJ??77!~~~~~~~~^^^^^^~~!?JJJJJ?J5PPP5J7!^^::^^^~!!77??JJJYYYYYYYY5PPGP5PGPYJ??5GJJPGGPB&@@&&##&&&    //
//    @@@@@@@&GPP#G55Y5P5YYJ???YGP55YYYJJ???77!!!!!!~~~~~~~~!7???JJJ?7J5PPP5YJ7!~~^^~~~~!77??JJYYYYYYYY55PGG5JY55JJJ5G5J5GGG5B&@@@@@@@&&    //
//    @@@@@@@@BPPBBP5YYPP55Y???JGP55YYJJ???77!!!!!!!~~~^^^^~!!77?JJJ?7J5PP55Y?7!~~~~~~~!!77??JJJJJYYYYY55PGGYJY55JYPGPYYPGBPP#@@@&&&@@&B    //
//    @@@@@@@@#GGB#G55YYPP5YJ?7?PP55YYJJ??77!!!~~~~~~^^^^^^^~!?JYJJJ77J5PPPPY?!~^^^^^~~~!!77??JJJJJYYY55PPGGJJY5YYPGG5YPGGG5G#@@@@@@@@&G    //
//    @@@@@@&&&GGG#B55555PPJJ?775PP5YYJ??77!!~~~~~~^^^^^:::^~?JJ????!!?55555P5!~^^^^^^^~~!!77??JJJJJYY55PPGP?JYYJPGGP5PGGBGPG&@@@@@@@&&#    //
//    &@@@@@@@@BGPGBP55P5PP5Y?!!YPP5YJJ?77!!!~~~~~~~^^^^:::^!JJ???JJ??Y55YYY5P?~^^^^^^^~~!!777??JJJJYYY5PPG5?J555GGPPPPGBBPPB&@@@@@@@&&&    //
//    ###&&@@@@&PPPBPPYYPP55J?77JPP5YJ??77!!!!!!!~~~~~~~~^^^~7????JJJYYYYJ??JJ7~~~~~~~~~~!!77????JJJYYY5PPGY?J5GGGGGGPGG#GPP#@@@@&&##BB#    //
//    P55GB#&@@&P5YGGPYYYY55Y?7!75P5YJ??77!!!!!!!!!!!!!!!~~~~~~!!!!!!!!!!!!!~!!!!!!!!!!!!!!777???JJJJYY5PPPJJ5PGBBBGGGG##GPG&@@&#BGGGGGG    //
//    PPGGGG##&&BYYPBG5YJYJJJ7~~75P5YJ??777!!!7777777!!!!!~~!!77777777777?????77777!!777777777???JJJYY55PP5??YPGGGGPPGB#BGGG&@&&BGGGGGGG    //
//    PGGGGPGB#&B5YYGG5YJJJY?!~!YGP5YJJ?777!!!7777777!!!!!!!777?777??77???JJYYYJ??777777777777??JJJJYY55PGP?!75PPPPPGGB#PPPB&&&#GGGGGGPG    //
//    GGPPGP5PPGB5JJPP5YJ7?Y?!~75#GP5YJ??77777!!!!!!!!!!7????JYYYYJJ??JJYYY55555YJ?77777777777??JJJYYY5PPB#J!!YPPP5PGBB#PGP#&BGGGGGGGGGG    //
//    &GP5PPPJ5P5GJJ5GYYJ!?Y?!!75&#P5YJJ?77!!!!!!!~~~~~~7J5PPPPPP55555PPPPPPPPPPP5?777!!!!!!77??JJJYY5PPG#&57!JPGY5PGBBBPPP#BPJYP5GPG#&&    //
//    #GPPPP57J55BYJYB55J!?J?!!75&&GP5YJ??7!!!!!~~~~~~~~~!7JY55555YYYYYY5555PPPP5J77!7!!!!!!77??JJYY5PPG#&&P?7?5GJYPBB#BGPG#GY!?PPGGG#&&    //
//    [email protected]@&GP5YJ?77!!!~~~~~~~~~~~~!?JJYYYYYYYYYYYY55P5YJ?7!!7!!!!!!77?JJYY5PPGB&@@PJ77YGJYGBB#GGGG##G5PGGGGGGB#    //
//    55PGPP5PB&&[email protected]@@#GP5YJ??7!!!~~~~~~~~~~~~!7?JJJJJJJJJJYYYYJ??77!7777!!!777?JJYY55PGB&@@@GJ?7YG5YGBGGPGGG&&#BBBGGGGGGG    //
//    PPPPPPG#&@@BJ5GB5P55#[email protected]@@@#GP5YJ??77!!~~~~~~!!!~~~^^^^~~~~~~~~~!!~~!!777777777777??JYY5PPG#&&@@@[email protected]@@&##GGGGGGG    //
//    PPGGB#&&#BGGGPYG5YJJGPPJ?JP&@@@@#GP5YYJ??7!!~~~~~!!!!~~~^^::::.....:::^~~!7777?7777???JYY55PGB#&@@@@@B5P5G&GGB5#B5YB#@@@@@&#GGGGGG    //
//    PGB##&#P5YPP5!7J7JG5JPB5?JJYP#@@@#BP55YYJ??7!!!!!~~!~~~~^^::::::.:::^^^~!77????????JJYY55PPGB#B&@@@&#BG#BB#G55GGGB###&@@@@@@&#BBBB    //
//    5PPGPP5Y??GPY~^^!5J?YPPPJYPPJ?P&@###GP55YYJJ??77!!~~~~^^^:::::::::::^^^~~!7??JJJJYYYY55PPGB#&#[email protected]@&#GPPG&BGGPGGGBGYPBGB#&@@@&&##BBB    //
//    7!?JY5YY7?YY5555GGYY5YJ??5GBB?7Y#&#@#BGPP55YYYJJ?77!!~~^^^^^^^^^^^^^^^~~!77?JYY5555PPPGGB#&@@#&@&GPPPPPBBBGBGGY55?7GPG####BBGGGGPP    //
//    JJ??YP5YJJYPBBGB#[email protected]@&#BGGPP55555YYJJ???77777!!!!!!!!!7??JYY5PPPPPGGBB##&&@&&#@#5Y5GP5PGGBB###BBP5PGGPBBBBBGP5Y5Y5    //
//    YYYJYYYJJYG#[email protected]@&&&#BBGGPPPPP5555YYYYYYYJJJJJJJYYYY55PPPGGGGBB###&&&&&&BB#PYJYPPPGGGGGGPB&@&&#BGGBB##BGP5PP5P    //
//    [email protected]&&&#BBBBGGGPPP555YYYYYYYYYYYYYY555555PPPGGGBBBBBGGB#&&&###55YJ5B##GGYJ5GGB&&&##&#BGGBBBBGGGPGG    //
//    ??5PYY?JGGG5?JGYPP55PBBBBY!?P?JJ!~?&&##BGPP55YJJJYYYY555YYYYYYYYYYYYY555555555YYYYY5PPGB#&&&&GY5P5PBBGGBPPGB##&##BGB&#G55PYGBGG555    //
//    JJPP57?GBPY?JP55G55YP&@@@#777~!77!?BBB#BGP5YJ?7!~~~~!!!!!!!!!!!!!!!!!!!!!!!777??JJYYPPGB#&&@&PJPPPPP55#&&&&##B####BB###GPGBG#BGB##    //
//    JYJJ??PBPJJY5555P5GG&&&&&#?!7!?J?7?BBBBGPP5YJ?7!!!~~~~^^^^^^^:::^^^^~~~!!!!77??JJYY55PPBB#&@&Y?YPPYYY5B#@@&#BBB##&&BGB##GPB##BPG#&    //
//    5??JJ5#G555JYPPP5G#&@@@@&B7!!7Y5J!Y##BGPP55Y?77!!!!!!!~~~~~~~~~~~~~~!!!7777????JYYY55PPGGB#&&YJYPGP5JP&&@@@&&BGGGB&&#BB&#GG#BGPPBG    //
//    5JJ?JG&#GPP5PPYYP&@@@@@&BJ!7???7!!G#BGPP55Y?777!!!!!!!!!!~~~~~~~~!!!!!!77777???JJJYY55PPGB#&&[email protected]@@@@@@#PPB#BB#&&&&#BBG5GGBB    //
//    YJJY5#&#[email protected]@&###P?7?JJJ?77P#BGPP55J??7777!!!!!!!!!!!!!!!!!!!!77777777????JJJY555PGGB#&5?JY55555#@@@@@@@PYPPGBBB#&@@&#BGBBBB    //
//    555YP#&BP5BBYYP#@&&#BGY?J??Y5J??PBGPP55YJ???777777777!!!!!!!~~~~~!!!!!!7777????JJJYY5555PPGB&#?JP#P5555B&@@@@@&B55GB#BGB&@&#GGB##G    //
//    P5YYGBB55Y5Y5G&&&BG5YJYYJJYYJ?5GGPP55YJ???7777777!!!!!!!!!!!!!!!!!!!!777777??????JJYYYY55PGGB#GJY5Y5YBGPPB#&@@@@&BGGBBB##&&#BGGBB#    //
//    YYYPBGGP55P5PP555YYPGP55YJJ?5GPPP55YJ????777777777!!!!!!!!!!!!!!!!!!!!!77777?????JJJJJYY55PPPGGG5JJYPGBBGPPPGB#&&&&BGPG##&##BBGGGB    //
//    GGGPPGPPPGP5Y5Y5PJJ55Y?J??5BBG?Y55YJJ?????77777777!!!!!!!!!!!!!!!!!!!7777777???????JJJJYYY55PP5G#B5YJY5GGGPP5PGGGGB##BB##BGGBBPGBB    //
//    PGGBBGPGBBP5GBP5YYYJ7?JPGBBGP5J??JJYYYJ?77777777!7777!!!!!!!!!!!!!!!77777777777??7????JJYY5P55GGGB5GP5JYPP5PPGBBBPGBBGGGGBG5PBB#&#    //
//    #&###BGPGGGPPP55YYYY?5GBGGGPPP5YYJ????JJJJ??777!!!!!!!!!!!!!!!!!!!!~!!!!!!!!!!!77??JJYYY5555GGBBBB5P##G55555PGBBGGGBGGG55B##BBB###    //
//    &&##BBGGGGGGPPPPPGPPJ5BBGGGGGPPP55YJ????77777?777?777!!!!!!~~~~~~~~~!!!!7777????JJJJY5YYYPPPGBBBBBPYB####BGPPPP5555GBGGGGPPGBB####    //
//    ######BBBBGGGGPGGGGG5YB#BBGGGGPPP5YJYYYJJ???77!!!!!!!7!!!77777777?777?777?777J?7?JJJYY55YY5GBBBBBBPJB########BG55PPGGGGGBGGBBB#BGB    //
//    BGB##BBBBBBGGGGGBBBBGY5B##BGGBGP55Y555555YJ??7!!!?7777!!!!!7777???!!!77!7???JJ???YYYY5555YYGBBBBBBGYG########BBGPGGBBBBBBBPG#BB###    //
//    GB#BBBBBBBGBBGGB###BP5J5###BBBBGPJ5PPP5555YJJ?!!!7?Y77!7!77?77J?7?J?7?77J5?!7JJJJYY55PPP5YYPGBBBBBBPP#######BBBBGPGGGBBGBBBGGBBBB#    //
//    ##BGBGBBGBBBB####BGGBBPJ5###BBBG5J5GGPPP55YYJ??777!~~!7?7??J7?5Y77YJ???!!!!7?JJJYYY55PPP5YYPGGBBBGPGPB#####B#BBBBGPPGGGGBBBGGGGGBB    //
//    GGGGGGGGGGBB####GPG###BPJ5#&#BGGPYJGBPPP5YYJJJ??7!~~~~!!~~!J77????Y77J77777????JJYYYY555555GGGGBG5PG5PGGGGGGGGBBBBBPPPPPGGGGGGGPGG    //
//    PGGGGGGGGB#####GPB#####BGYYB&#BGP5J?Y5PPYJ??JJJ?J??77!!!~77JJJYYJJJ77777?777???JJJJYY55YYYYPPPPP5GGBGPP55?!!!!!7?YGBPPPGPGGGGGGG5P    //
//    55PPPPGGPB&&##GPB######BBGYYG##GPP5J?JJJJYJJJ??J?J?JJ?7!!!!7?JYYJ???7!7777?77?????JYYJJJ55Y555J?GGGBBBBBBP7!!!~~!7YBBGPPP5PGGGGGGP    //
//                                                                                                                                          //
//                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BUD is ERC721Creator {
    constructor() ERC721Creator("BUDDHA", "BUD") {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC721Creator is Proxy {
    
    constructor(string memory name, string memory symbol) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0xe4E4003afE3765Aca8149a82fc064C0b125B9e5a;
        Address.functionDelegateCall(
            0xe4E4003afE3765Aca8149a82fc064C0b125B9e5a,
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

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
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}