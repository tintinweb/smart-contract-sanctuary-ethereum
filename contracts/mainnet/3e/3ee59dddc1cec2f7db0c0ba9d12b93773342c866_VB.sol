// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Vittorio Bonapace
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//    J?7!^^^^~~~^:::^77^?JBBBGGGGGGGGG5YJJJJY?!!7!~~~!!?JJ??7!!^~~~77777!!!!~^:^^~~~~~~^^:75!~!!!!!^^:^~~^^^^^^^^~^::~~^:^~^^^^:^^^~~~!!777!!!^..::::::::::::::::::::::::::::::::::::::::::::^7^~~!7!7~75GP?7    //
//    ~~~~~~~^^:::!!J!Y^YGBBGGGGGGGGGGP5Y??JJJ?~~!!^^^~!7???77!~^~!~????7!!~~^:::^^~~~~~^^.!5!~!!!!!~^:^~~^^^^^^^^^:::~~^^^~~~~~~!~~~~~~~~~~^~~^..:::::::::::::::::::::::::::::::::::^^^^^^^^^!!~!~!7!7~!5G5?7    //
//    ^::^^~^~!!:~57?!PGBGGGGGGGGGGGPPPYJ?7???7~^~~^:^~~7?????7~~~!~7777!~~~~^:::^^^~~~~^^:~5!~~~~!!~^::~~^^^^^^^^^^::!!^^~77!!~~~^^^^^^^^^^^~~^..::::::::::::::::::^::::::::^^^^^^^^^^^^^^^^^!!!!!?7!7~!5PY?7    //
//    7~~!!7^!!~:7JY5PPPGGGGGGGPPPPPPPPYJ777??7~^~~^:^~!7????7!~^^~~!7777!~~~^:.::^^~~~~^^:^Y7~~~~!7~^::~~^^^^^^^~~~^^~~~~!7!~~^^^:::::::^^^^~~:..:::::::::::::::::~~~^:::^^^^^^^::^^^^^^^^^^^^^^^^~~~7~~J5Y?7    //
//    7~^^!~^!~:~P55YJ?777J5GGPPPPPPPP5YJ777777~^~~^:~!!7?7777!^:^~~!77?7!!~~^:.::^^^~~~^::^Y?~~~~!7~^^:~~~^^^^~~!7!^^~~^^~~^^:::::::::::^^^^~~:.:::::::::^^^::::^^~~~~^:^^^^^:::::::::^^^^^^^^^^^^^^^^^~?YJ?7    //
//    7~^~!~^!^.JGGP5YJJ7!~^!5PPPPPPPP5JJ777777~^~~^:~~!777777!^:^^~!77?7!!~~^:.:::^^~~~^^::Y?~~~~~7~^^:~!~~~!~!!!7~::^:::^^^::::::::::::::^^~^:.^^^^::::::::::^^~~~^^~~::::::::^^^^::^^^^^^^^^^^^^^^~^^~7???7    //
//    !^^~!^~~:^GGGGPPJY57?!:^5PPPPP555J?777777~^~~^^~!!777777^^^~^^!77??!!~~^:.:::^~~~~^^::JJ~~~~~7!^^^!77~~~~~~~~^:::::::^::::::::.::::::^^^^:.::::::::::::::~~~~~~~~~^:::::::^^^~~^^^^^^^^^^^^^^^^^^~!7!7J7    //
//    ~^~!!^!~.JBG#BGG5?Y???7~?Y5PP555YJJ?!~!~~^:^:::^~~!7!77^~~^~~^~7???7!!~^:.::^~~!!~^^^:JY~~!~!?!~^^!!!^^^:^^^^:.::::::^::::::::...::::^^^^..::::::^::::::^~^~^^^^^~^:::::^^^^^!!^^^^^^^^^^^^^^^^^~?J?!!77    //
//    ~^~!~~!^:P#GPPPGPYJ?!!!?Y?77YYY55Y55!!YJ??777!!!!~:!!!^~!~^~!!~~??J7!!!~^:::^~!!!!~^^:YP7!7~!!!~::~~~^::::::^^.:::::::::::::......:::^^^:.:::^^^~~^:::::^^^^^^^^~~~:::::^^^^~!!~^^^^^^^^^^^~~~~~JJJJ?!!!    //
//    ^^!!^!~^?B#BBPPPP5J7!^!JJ7!^?YYYYY55!?PGGGGGPPPP5Y:~!^!77~^~!!7~!?J7!7!~^::^^~!!7!~~^^YG?!!^^~~^::^~~^::::::^:.:::::::::.:::......:.::^^:.^^^~~~~~^^::..^^^^^^~~~~~^:::::::^~!!!^^^^^^~~~~~~~~~!JJJJJJY5    //
//    :~!~~!~^P##BBBPPPY7~^~55Y?~^J5YYJY5Y~7PBBGGGBGGGPY:~^~??7~:~~~!7~~?7!7!~^::^^~!!7!~~^:JP?~~^^~~^::^~~^::::::^:.:::::::::...:......:.:::^::~^^^^^^^^:.:::^^^^^^^^^~~::::::::^~~~!~^~~~~~~~~!~~!!!JYJYJYPG    //
//    ^~7~!~^!B##GBBGP5J~^^JP55Y!^?YYY5YYY~7PBGGGGGGGGPY:^^!!!~^::^^~~!^77!77~^::^^~!!!~~^^:?PJ^~~^~~^::^~~^::::::::.:::::::::............::::.:::::::::::::::::^^^^^^^^^^^^^^^^^^~~~~~~~~~~~^~~~~~!!!?JYYYY5P    //
//    ~!!~!~:5###BBBGG5P7??P5Y5P?~!YYYYYYY~7PBGGGGGGGGPJ:~!!77!^:^^^~~!7J7!77!^::^^~!!!~~^^:!5Y^~~^~~^::^~~^::::::::.::::::::.............:::..^^^^^^^~~~~~~~~~~~~~~~~~~~!!!!!!!!!77!!!!!!!!!~^!!!!!!!!?YYY5PG    //
//    ~!~!~~^G####B#BP5J77555JYGYYJYJYJYYY~7PBBGBGGGPPPJ::77??7~:^~~!!7??7~!7~^:::^^~!!!!~^:!YY~^^^^~^::^~~^:::::::::::::::::.............:::::??????????JJJJJJJJJJJJJJJJJJJJJJJJJJ?!!!!!7777~~!~!!!!!~!YY5PPG    //
//    ^!~!~^~5555PPPGPY7^~YY5JY5Y7!!JYJYYY~7GBBBBBBBGGPJ::!7??7~^^~~!!777!^~7~^::^^^~!!!~~^:^77^::::^::::^^^....:.:..::::::..............::^^.!55555555555555555555555555555555555J?!!!!!7777~^~~~!!!!!77JPGGG    //
//    ^!~!~:7J???JJ5GPJ~:~77J?JP57^~YYJYYY~75555555YYYYJ:^!??J7~~~!!!77?7!^~!!^::^^^~~!~~^^:^!!^::::::::::^^....:.::.:::.:...............:^^^.?555555555555555555P5555555555555555YJ!!777777?!~!!777?????JYYY5    //
//    :~!~^^5YJ?77?PG57^:7??P5Y55?^^?JJJYY~~????7!7777??:~!??J7~~~!!77???!~^!!^::^:^~~!~~~^:^Y5?:^^^^^^:::^^....:.::..::.................:^^::5555P55555555555Y?77??JJY55555555PP5YJ!!777777Y7!JGGGY????5YJJYY    //
//    .~!~^~PP5J?7YGPJ!::?YJPBP55J~:~JYY5J~777!!!!!!!!~^~~777??~~~!!77???!~^!7^::^:^~~!~~~^:^GBP^^~~^~^:::^^......::..:..................:^^:~PPPPP555555555?~~~~~!!7???YPPPPPPPP5YJ!!777777?7?YGB#P?????JJJJJ    //
//     ^~~^7JY55YJPG5?^::~7YPGP55J!..7YYJ7:^^~??????J?!7!~777??!~~!!!77?7!~~!7^::^:^~~!~~~^:^PGG~^~~^^~:::^^.......:..:..................^^^.7P55555555555Y7!7?JYY5P5Y5Y75PPPPPPGP5J777777777JY5PG5Y?????????J    //
//     ^~~~55JJYY5GPY7^:^~^!5PPP5Y7:.^?77~^7?77?????J?!7~!777JJ7^^~!!!!77!~~!7^::^^^~~!~~~^::5GG7:^~^^~::::^.......:..:.................:^^^.YP55555555555?7?JY5555PPPY5PJPPGGGGGP5J777777??Y5PP5J7?J?????JJ?J    //
//     :~^?#BG5JYPGPJ~::^~^^?Y?PP5?:.:!!7~!JYJ7?77?JJ?!7!7777JY?~~~!!!!77!~^!7~::^^^^~!~~~^::5BBJ:^^~^^^:::^......::..::................:^^^^555555555555Y?JJY55555YPP555PPGGGGGGP5J777!7?JY555J???JJ??JJJJJJY    //
//     .~~P#BBBG#BGPP!::~^^^!J?YBG5!:~~~7~7JYJ????JJJJ~7!!~^^^~~^^~!!!!77!~^!7~:^~^^^^!~~~^:.!??7::^^::::::^:.....::..::.....:::........:^~:!P55P5555PPPP5JYYY555555G55PYGGGGGGGGP5J7!!7JY55Y?JJJJYJJJJJJJJJJ5    //
//     .~7BBBGGB#BGGY7~~~~^^~777JJJ7~!?7J77!!7!7??JYJ?77J?7!!77!~^::^7!7!!~^!7!^^~~^^^~~^~^:.:~!!:::^::::::^:.....::..::..:..:::.....:..:^~.!JJJJJJJJYYJYYJJJJJY55PPP5BB555555YYJ?J55P5YY5YJ?!?JJJYJJJJJJJYJY5    //
//     .!7???JJJJJJYJ?77!!!~!?777?77?YPGPGG5??!:^!JJYY5YYY?!!55J77!^:~777!~~!7!^^~~^^^^~^~^:.:~!7^::^::::::::......:..::..:.::::.....:..:^^.~~~~~~~~~~~~~~~~?5Y?JYPPP5G#GJ?!!!!!77?YYY5PY????!?JJJJJJJJJJYYY55    //
//      ?GGGGBBGP5YJ?7!!~~~7YY7J??JPBBB##BBGPPY?!::7PPPG5YYPGP77???!^^~7?7!~77!~^~~^^^^~~~^:.:~77~::^^:::.:::......:..::..:.::::.....: .:^:.^^^^^^^^^^^^^^^:7YJ7?JY5P5G&#PY?JJ?Y555YYY?777777!77777?JYYYYYY55P    //
//      JBGGPPPYYYJJJJ?77^~!!~~^^!PBB#####BGGPPPY?~.?GGGG5555P5J?????~ ^!7!~77!~^~~^^^^~~~^:.:!7?7::^^^::..::...  .:..::..:.::::....::.:^^::^^~~~^~~~~~^~~~~~7!JJYY55G##BBGP5?~7??777!!!!777777777??YYYYYYY55P    //
//      !PPPP5YYYYYYY55J?~~~~^^^:YBBBB###BBGPP5YJJ7^.PBBB#B###&#Y???77..!?!~7?!~~~~^^^^~~~^:..~!7?^:^^:::.:~77!!!^::..::....::::..::::.^~^.^~~~~~~!!!!7^~7!~~!!7YJ?YY5PPP5YJ???7???7!!77777!7!777?7?YYYYYYY55P    //
//      ~GPPP555YYYYYYY??~JJJY?~:!5GBBBBGPPGGGGYYP?!:5#&@&###BBB#GY?7!^.:7!~7?7!~!!~^^^~~~~:..!~!?!:^^::!?J5BGGBG5Y?~::^:.:.:^:::.::^::^~:.~~~~!~!77777~!?!!!7!7?JJ?J555YYYYPGBBBBBGY?????7!77777?7JJ555555PPG    //
//      :PGG5P55555Y55YJJ!555P5?~:~GBB##BBGPPGGJ?J?7^?G##B####[email protected]&BPY?!^~7~!?77~!!~^^^~!!~:..~!!!!::^~?YPBBB&###BBGPJ^::.:.:^::::::^::^^::~~~!!~!?7777~!?!!!7777??JJYJJYYYG#P#P5PB#PY????!77?7?7??J?5PPGGGGBB    //
//       5GG5PP5555YJ5YJJ!55PP5Y77PB##BG5YB#P55YJ?77::!YGGG###BP5?P5YY?!??7!7?77!!7!~^^~!!~:..^~777^:^J5PBB#B#&&&&##BB5~:::.:^:::::^^:^^^.^~!!!!!7???77~!?!!!7777?????JJJY5BBYBYJP#&#J77777???????JYYYYYYYYY5P    //
//    .. YBB55Y5YJYJ?JJJJ7GPGPPPYGBB##BGGGB&G5YYJ7:.^::!5GGB&&#PY!~^::..:^:^~~!7!7?!~^^~!!~^..^!???!:~PPGGB##B#&&&&##BG5~::.:^:::::^^:^^::!!!!!!!77777?~7??7!7777777???JY55P#BBPY5PGGY?7?????J?JJJJYYYYYYYY5PP    //
//    .. 7BB5P5JJJYJ7?7??!YGGGPPGBPBBBGP5##5JYJ?7: .7?~^YB#BBG5J7~:..:         .:^!!~^~~!!~^..^!??7?:^PGG5B#B###B#####BJ:::.:^^::::^^:^^::!J55YYYJ????~~7JJ777777777???JY55PG##Y?J5PPP5JJYYYYYYYYYYY5YYYY555PG    //
//     . ^BB555Y5JJJ7?J?7~~!5GGGBBPBBBG5GBG???7~^..:J55J5BBGP5Y?!~~^^:::....    .  ..:~!!!~^..^!??7J~.?GGGB#BBBBB###BGPY~.:.:^^::::^:::^~?G#5YY55555YJ^.~J?7?777777?7??JY55PPGBP?JYPPPPPPPPPPPPPPYY5PP5YYY55PG    //
//    ~^^:PB5YYYYYJJ?JJJ??Y?YY55PGP555Y5GGP?~7J7^:7JPGGG55Y77Y555YJJJJJ?7!~~^^~::::.. :~7!~^:.^7???J7.:!5GB##BB&&5P#BGP5P7:..:^^^::^^!?JYYPBP?7??7?J5P5J~^!7?7777?7777?JY5PPPPGG??Y5PPPPPPPPPPP5575PP5P5YY5PPY    //
//    BBGPGBBGGGGGGBBBGGGGGGGGGPBBGPPPPPGP5?~!??!?5YJ????YYJ?!~JY5Y7!7JY55PPPJ7!~~~~:. .!7!^::~7!7777^...JBBBB#&#BBG##BGJ7~^^~~^::~7JY55YJ?Y5YYYY?!~!YYP5J!~!77777777??JYY5PPGGGY?J5PPPPGPPGGGPP5JYGBGBGP55Y??    //
//    ###&&#&########BBBBBB##BBB###BBBBBBGG5YJJ!77!7Y!?GGB&#BPJ7~!PB5?!77G##BPYJJ?77~^::^!!~^:!J77??7~.. .JPBBBB##B#BPYJ?77!!!7??7!!~~!!!7JBGGPPGPPY??~!J5Y?!~!777777?JYY55PPGGGP??YPPGPGPPPGGPP5JJYP##&#P5YJJ    //
//    PPG5P###BBGBBBBBBGGGGGBGBBB######BB###G???~!!J5YYGGBGPP5YY7^:7B#G5?JB#BBBG5J7~:.   .^~^^~?777?77:...::?GGP##GP55555YYJ?7!!?YYJ?!^.^?Y#GPPPPPPGG5Y7~~?JJ?!~!7???JJY5PPGGGGGPJ?J5PGPGGPPPPPP5YYYY5PGGPP5Y5    //
//    .^~.^PPYY?YGGPGGGGGGGBBGBB######B#&###BG5Y!?JY55PGGBP5P5PPY7~:!PBBG55BBGPY?!^:::..  .:^:~??????J~ ..::.^?G#####BGGGGP55YJ7!~J55J7^.!5PBG5555PPPGGP5J7!7JJ?7!7??JJY55PPGGGGYJJJY5GG5YYYYYPPPYYYY5PPPPPG5Y    //
//    .:^::Y5YJJ5PGGGGGBBBBBBBBBBBBB#BB&&###BGBGJ7Y?JPPGBBBGPPP5JJY?!^?GBP5P55YJJ?!~^^^..   :7!~~~!7?JJ: .:::..PB##&&&&#BBBGGP5YY!:?PP5J7!5Y5BG5JJY5PPPGGP5J?777????5BPGGGBBBBBGJ?JJ5PGG5Y5YY5PGP5YYYYJ?7???77    //
//    .:~^.JGGY5PGGGGGBBBBBBBB#B###BBBB&&#BBGPGBBGP!:~YGBBB##PJ5BGP5Y7^!GBGP5555?~~!!!!:....:!??7!^:..:. ...~!!PBB#&&&&&###BBBGGP5J75GGP5J7JJ5Y55YJJY55PPPPP5Y!7YYY5GBGBBBBBBBB#JJ5G55PGP5555GPPPY?77!!!!?YY?7    //
//    .:~~.!GG5YPGGGGBBBBBBBBB###BBBBBB#&&#BGB##BGP5J~:~5##BGPGGPGGGG5J~^JGGGPP5Y7^^^~~~::?7!^^~:.      .. !G#GB#####&##&####BBBGGP5Y5PP5YPP5PPPPPPYJY5Y5PPGP?JYJYJJJ5YJ5GGGGGGPPG5PY5PPPYJ5GGP5??7????JYY5YY?    //
//    .:~~:~GGP5GGBGGBBB###BBBBBBBBBBBBBB##BBGGGGGGGP5J~:!5PG#&#BPGBGGP57^7PGP5YYJ~!?J?7~!J?7~^^::.      .?PGB################BBBGG5Y55PPP############B?J5PPP5P55PP5YY55Y5PPPPPPPGY?Y5PPJ??7PG5PGGBBBBGPG5YY55    //
//    ::~!^^PGGPGBBBGGBB###BBB####BBBBBBBBBBBYJ5PGGGBGP5J~:?B####BGGGBBGPJ^~7!~~7YJ?JJ?7JPGGYJ??7!^~!7?J?YPPGGBBBBB##########BBBBBP5PPPGGGP55P5YYY5PPGGY555PGBBP5GGGPP5YYYY?YPPPPGYJY55??YPJPGPPGGB##&&&&##BP5    //
//    ::~7~:YGPGGBBBGGBB####B#####BBBBBBBBGGPPY??YPGGBBGP5J!~5B####BG5Y?7~777!?J?Y555555GBBP5YYYY5PGB##GPGGGGGGG5YGBB###########BBPGPYGGGGGPPGPPPPPGPPP5PP5PPBBP5PPPGGGPP5YJ?JPPPPJJY5J?YP5YGGGPGB##&&&&&&&&#B    //
//    ~~!?7~?PPGBBBBGGGB###########BBBBBBBGGPP5J~^5GGGBBBGPPY~?GBBGY7!77?JJYYYY?~!JPGBBBBBG55P55PBBB#BPPGGGGGG5YY75GGBBBBBBB#####B##BBBBBBBBBBBBGGGGGPPPPPPPPBBPY55PPPGGGPPP5YJYP5JJYYY5PP55GGY!7J5GBB######BP    //
//    55PPP555PPB#BBGP5B############BBBBGGPPPP5J^!BGPPPGBBBGP5?7PPYJ?JYY55YY5P5YJ7!!!!?YPGGGPGPPGB###PPGGGGGPJ??J?!5GGBBB##B#########BBBBBBBBBBBBGGGGGPPPPPPGBBGJJJJYYY5PPGGGGPYYYJ5PPPPPP5GGGJ~~??JY5PPPPPGPP    //
//    ~~7JJJ75GP5PBGPP5P#############BGGPP5555J7^?BGGGPPPGBBBBGGBBGGG5Y555PPPPGGGGGGP5Y?77?JYPGGB##BGPGPGPP5YJJ77Y?75GGBBBB##########B##BBBBBBBBBBGGGGGPPPPPGBBG7^~~~!!7?Y5PGGGGGBPPGGGGGP?7?J?!!JJJJ5PPPPPGGP    //
//    ^^!JJ?~J#BG5YGPP55P############BBBGGGPPY?~~YYBBGGBGGGGGBB##GGGGPPPGPPPPPPPPPPGGGGGPGY!!7?5PP5YPPPPPPPP555Y??5PJYPGBBBB#########B##BBBBBBBBBBBGGGGGGGPPGGB57777??????Y5PPGPGGGGBBBGP5Y?7?JJJYY5PPPGGGGGGP    //
//    ~~7YYJJB###GYJGG555B############BBBBGGP5?^?Y?5BBBBBBBGGBGBGGGGGGGGGGP55555555Y?JY5PPJYBB#BBGGGP555PGBGGGGP5YJJ??5PGBBBB########B#BBBBBBBBBBBBBGGGGGGPG55G???????????????JJY5PGBBBBG5555J7777777?????????    //
//    !!?55JG&###GP!PGP5PB###############BBGGPJ^7J7^?Y55PPGGGGGBBBGGGGGGGGGGPP5555YJ!:.:!7?JY5GYPG#BGPPY5GGGG5JJ?~~~~!7Y5PGBBB#######BBBBBBBBBBBBBBBBGGGGGGGPGBY??????JJJJJJJJJJJYGGBBBBGJ???????JJJJJJJJJJJ?J    //
//    7!?55Y5####BG?5PPPPB###########BBBBBGGP5?7YJ?7~~~~~!!!7??JJYY55555P55PPPPPPP55YJ7~:.:.....:^J5BBBBBBBBBBBGPPPPPP5PGGBBBBB#####BB###BBBBBBBBBBBBBGGGGGGB#BB?777777777????JJJJYYYYYYYJJJJJJJJYYJJJJJJJJJJJ    //
//    ?7J5P5JP###BPYPG55GB##&#############BBBPY5GBBGG57J5J?7!!!!!7?7???7!JJYJJJ?JJ???J7~^^~~!!????J5GBGBBBBBBBBBB###############BBGGYB#####BBBBBBBBBBBBGGGGGB##BBBGGPPP55555YYYYYYYYYYYJJJJJJJJJJJJJJYYYYYJJYY    //
//    YJYPP5YJG##B5?GGGPG#####&&&&#######BBBP57:7BBBBBGJJPBBGGGGGGP55YY?J5YYYYYJJY555Y555555PP5Y5PGGPGGGGPPPPGGGGGGGGGBBBBBBBBBBBBGGJB#####BBBBBBBBBBBBBBBBBB##B######&&############BBBBBGGGGGGGGGGGGGGGGPPPP5    //
//    GGPGGP5YYB#B5JGGPB################BBBBPY7^^BBBBBBBP?JPBBGGBBBBBGGBG5GGGGPPBBGBBBBBBBBBBG5PGBBBBBBGPP5YYYY5PGGGGG##############BB######BBBBBBBBBBBBBGGBB###BBBBBBBBB##&#######B######################BBBG    //
//    GGPPPPPPPPPG5YBGG#&###############BBBBGPY7~P#BBBBBBBPJYGBBBBBBGBBGPBBGPPGBBBBBBBBBBB##B5PB########GGGPP555YYPPPP#########&##&&##########BBBBBBBBBBBGBBB####BBBBBBBBBBB##&##BBB#############BB#######BBBB    //
//    55555555Y5GBPYBB##################BBBGGGBBGPGBBB######G55GBBBBBBBPGGPPGBBBB######GPPPP5P5PGGGB####BBBGGGGGGGGGPB&&&&&&&&&&&&&&##########BBBBBBBBBBBBBBB##############BBBB#&###############B##BBB#B##BBBB    //
//    P5PGGPPPYY#BP5BB#####&&###########B#######PJJJJJJJJY55PGP5PPGGBGPGBB######&##B##&BBBGG5PPPPPPPPPGGPPPPPPPPGGBB#&&&&############&&&&&&####BBBBBBBBBBBBBB###PPPPPPPGGGBBBBGGB#&###B###################BBBB    //
//    PPPGGGPP5YBBG5B######&&###########&&&###BBBBBBGGPP5YJJ????777?JYPGGPP5555#&####&#BBBBBPG#############BBBBBB#&###BBB###########BBBBB##&&&&##BBBBBBBBBBBB##GBBBBBBBGGGGGGGGGGBB#&#GGGGGGGGGBBGGBBGGGGGGGP5    //
//    PPGGGGGGG5G#GPB##############&&&&&&&&&#BGGGPGBBBBBBBBBBBGGPP55YJJY5??JJJYB#######BBBBBPG##############&&&&##BB###&&&&&&&&##&&&####BBGBB##&&&##BBBBBBBBB#BP################BBBBB###BBBBBBBBBBBBBBGGGGGPPP    //
//    GGGBBGGGBPGBGP##B####&#########&&&&####BBGG5JP55555555555555555555555PPPPPPB##########GG#############&&##BB##&&&&&&&&&&&&&&&&&B#######BBBB#&&&&#BBBBBBB#BPGGGGGGGGGBGGGGGGGGGGGB#&#GGGGGGGGGGGBBGGGGGGGG    //
//    GPPGPPPGBBBBGP#######&##################BBGPJ5555555YYYYYYYYYYY5555PPPPPGGGPGGGBBBBB##GG###########&&##BB##&&&&&&&&&&&&&&&&&&&BB##########BBB#&&&#B###GGGPBBBBBBBBBBBBBBBBBBBBBBB#&#BBBBBBBBBBBB#BBBBBBB    //
//    PGGGGGG###BBBGBB#####&&#################BBGPYGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBGB#&&&&&&&&&&&##B#&&&&&&&&&&&&&&&&&&&&##GB############BBB#&&&###BBBPBBBGGGBB###BBGGGGGGGGGGB#&#GGGBBBBBBGGBBBBBBBB    //
//    BBBBBB#####BBBBG#####&&&#################BGPYBBBBBBBBBBBBBBGGGBBBBBBBBGGGGGGGGGGGGGGGGGB#GBB##&&&&###B#&&&&&&&&&&&&&&&&&&&&#BB5###############BGB&&&#GPBBP#BGGGGB##BBGGGGGGGGGGGPPB&&BGGGGGGGP55BBBBBBBB    //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract VB is ERC721Creator {
    constructor() ERC721Creator("Vittorio Bonapace", "VB") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x2d3fC875de7Fe7Da43AD0afa0E7023c9B91D06b1;
        Address.functionDelegateCall(
            0x2d3fC875de7Fe7Da43AD0afa0E7023c9B91D06b1,
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