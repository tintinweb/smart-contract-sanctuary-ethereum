// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: IdeaSimulated
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    B5YPBY7PBGP5!7B#BY5B#GYYGBG55YYY5GGPYJY5P5J~J55J~5#BGP5Y5BJJGPG5!GGPPP55YYJYY5Y5PPGGP!5BGP?YGYY55PBG?!5P?~5PYJJ??Y55YY55Y?JYYY5GGPY?J5G5~?5PGG?7PPYJPB    //
//    &#BP5PY7PP5GG7?#BJPBGYYPPPYJJYPP55YJ?JJJJJJ?~?5Y?!J5YY5Y5Y?BBBG!Y##G5YYJJ???JJJJY5G##J7BBBGJYYYY5YY7!Y5J~J5YJYYJ??JYYJJYYJ?7YYJYPPP?YBP!JBPPP?755YPB##    //
//    &##&#G5Y7?GBGP?7B#PYYPP5Y?JYYYYJJJ??YYYJJJ5P5~?GPY!7Y555PJPGGGJ7GG5YJ?JJJJJJJJJJJYY5GG75GGG5?5YY5Y!75P5~?YJ5P5PYYJJJ??J?Y55?7Y5YJJ5G#P7JPGB57?55G###BB    //
//    &&#####G5??5B##J!P#BP555Y7555PP5PPP55YYPPGGGGY!?PG5775GG5YBB#G!JP5YJJYYYJJJJYJYYYYYY5PJ7BBGPJ5GGY!JGPY~7JYP55P5555PGP5JYYYYY7JJJPGBBY!5BGPJ7JPG######B    //
//    &&&###BB#B5?P#&#P7?5PPPPY75PPP5PPP55PBGPPPPPGGG7?5JJ?!55Y5PGB5755JJJJJJJJ???JJJJJJJJJYY75BGPJYPY!?JJY!?GPPP5PPPBBGPPPP5PPPPPY?Y55P577PBBBJ75BBBBB####B    //
//    &&&&#BB####GYYB&&BY7J5Y5P5JY5P5555GGPGBP5GGGPYY?!7JJP57PPYBGY?J5YYJJYJ?7!!~~~!!7JJJYJJ5?7YGGYGY755?J~~?JJ5PPPPPPP5GGP5YYPPYPGP55YJ7YGBB5?JGBBBBGBB###B    //
//    &&&#B#&&#####GYYB&#GJ?YGBGYYJJY5GPPG5PP5P55J7!7J7~7PPPY?JPG55JYYYYYY?!!!777!!77!7?YJJJY??Y5GPJ?555J!~??!!?YYY55PG5GGPGPYJYYY5GGY?JG#BPJJPBBBB#BBBGBBBB    //
//    &&B#&&&&&&&&#&#PY5B&#P??Y5PPPYJJPGPPGPYYYJ?!7JJ7!!!J5PPP?YP55JYJJJYJ77?JJ??7???7!7?JJ?Y??5YGYJGP55?!!~7J7!7JJ?Y55PG5P5JY5PPP5J?JPB#GYJPBBBBBB#BBBBBB##    //
//    #B#&&&&&&&&###&&#G55GBGY7J5Y5PG5YPGPP5YJ7!~7J7!7J5J!J5PPGJY55JYJ?JJ??7J?7!!~!7?7777?J?J?J5YJJGPP5?75PJ7!??~!77?JYPG5JJYP5Y55J?5BBGYYPB#BBBB####BB#BBBB    //
//    B#&&&&&&&&#########GYYPBPJ5G5Y5PP5YY5Y??7~7?!!?55YY?!?P55PJJ??JYJ??77777?7!!7?7777?J??Y????JP55P7!J5Y5Y7!!?!~7J?Y5YJ5P5YYPGYYGBPYYPBBBBBBBBB########BB    //
//    &&&&&&&&&###########BG55GGJ5G5JYPPYJJJ?7!!?!~7YY555P5!!Y555JJ?7YJ???77!7?????77777J??YY77?JY5PY!!5P555J?!!!?!7????JYP5JY5PYYGG55GGBBBBBB###BB########B    //
//    &&&&&&&###&&&&##BB#BBBBG5PPJYP55YYYY?7?7!7!!7JJJJJJJJYJ~755JJ?77J?777!!!!!!!!!777777JJ!7?JJ55?!7J?J?YJ??J?!!?!???YYYJ?PJYYYPPPGBBBBGGBB#####BBB#######    //
//    &&&&&&&##&&####B#B####BGBPP5?5PP5J??7?7~?7!7JJJ?77?JJJYY!~JYJ7!7!7?!!~!!!~77~!!~!!7?7~!!7JJJ~!Y5P5J?77?JJY?!7?!?7?JJ?Y5YYJGPGGGB###BGBB######BBB######    //
//    &&&&&##&&&&###B#BGB###BGBBGPJJYJJYJJYJ7JJ!?YYY????JJJYYPP?^!7!!!!~!~^^^^::5Y::^^~~!!~!!!!7!~?PGPYJJ?????JY5J~??!?JJYJYYJJPGGGGBGB#BBBB###############B    //
//    &&&######&##BB#####BGBBBBBGPGYJY55YJY??57!5YJ?77?7?JJJ55PGY!~~~^^^^~^:...:JJ....:^!~^^~!~~!YG5YJ?JJJ?777??Y57!5J?JY5PPYJ5GGGPGBBGGB#####BB######B####B    //
//    &&#########BBBBB####B#BBGBGGGP55Y55YJ?J5!?G5J?7JJ7?JJ?JYY57?J7~~~^^:.:~!77!!7!!~::^^^~!~7J?7YJYJ?YJ?7JJ7?JYGY!5J7YY5P5YYYYPGBBBBGGBB#BBBBBB######B###B    //
//    &&####&&&#######BGBBBBGBGBBBBGGP5YY5Y?YY?!P5YJ?7??JYY55YJ?J7??~::^!7JYYYYYJYYJYYYJ7!^^:^??7J?Y555YYJ?77?JYY57?YJ7YYJJY5P5YJPGGBGGBBGBB###BBB##########    //
//    &#####&&&###B####BBBBPPPGPYYY555J?!?YYY?J7!J555YY5PYJYPJ!?5?~^^^!Y5YJ?7!!!~!7!77?JY5J!^^~~75?!J5YJY5YYYYY5J!7Y?YYY?!??JJJJJY5PPPGGBBB###BBB####&&&####    //
//    &####&&&#####BBBBBBBPJJ?7!~~~~~!!?J?JYJY55Y!7JPP55P5YYJ7?7J!~^~?5J??7!~~!!777!~~~7??Y5?^^~7Y777JYY5P555PJ!7YP5JJYYJY?!~^^^~~~!?JYPPGGGBBB#####&&&&&###    //
//    &##&&&&########BBBGPYJ7~^^^^^~^^^^~7?JY5PYY5Y7!?Y55PPP5PYY?~!~75J77!!77??7777??7!!777J5!~!~JYYPYGGPPPY?!?5P5YYYJJJ7~^^^^^~^^^^~!?Y5PGBB#######&&&&&###    //
//    ##&&&&&###BBB#B#BGGY?7~~^!77~!77^^~~JY5Y5JYYYP5?7?J555PPYJ~^~~YY77!!?7?7!!~~!!??77!7??5Y~~~~Y5PPY5YJ?7JPG5Y555YYJ?~~^^!7!~7?7^~~7?YPGBBBBBBB###&&&&&&#    //
//    #&&&&&&###&&#BB#GPP5J7!~~?J?!!?J7^~~7JPPYYY5PPGG5J7?JJ5P5Y!!^~Y?77!77??77!:^!7!7777777JY~~~!5PP5Y??JJYGGG5PPJYPY?!~~^!??!!?JJ7~~7?YPBB#BB######&&&&&&&    //
//    #&&&&&#######B#BBGG5YJ7!~!?J???7~~~~7JY555J?J5GBGPPJJ???JJ~^^~J77?777J??7777777??77??7JJ~^^~YJ??5PPGGYGB5J?J55Y?7!~~~~7?????7~~!JYPGGB##B#######&&&&&&    //
//    &&&&&&######BB#BGBGG5J?7!~~~~~~~~~!?JJJ7?YPPY??YPBBP5JJ5P57~!~7?77?7!7JJ?J???????77?7?J!~!~?55PY5P5G#GY??Y55J?7????!!!~~~~~~~~!?J5PGBGGBBB######&&&&&&    //
//    &&&&&&##########BBGGG5YY?7777!!!777???JJJ5PPPBPJ?YYYPP5?YP57~~~!??77!!!7?77?7?777??7JJ!~~~?PPYJ5GGPJJJYPGPPP5J?JJJJ??J777777??J5PGGGBGBBB##&#####&&&&&    //
//    &&&&&###BBBBB##B#BBBGGPP5YYYJ?J???7777?YYJ55GGG#BPJJYPG5YYP5?!~^~7??777!7~!!77?777??7~~~!J5PYY5GG5JYPB#GGP5YJJJ????JYYYYY5PPGPGGBBBBBBBB#BBBB####&&&&&    //
//    &&&&&#########B##B##BBBGGGPYJJYJ??J7?77YPP5YYYY5GB#BPPPY5YYYYY7~~^~!7?77777777??77!~~~!?YY5555Y5PGBBBG5YYYY5P57!77?JY55PPPGGGGGBBBBBB#BB#GB######&&&&&    //
//    &&&&&#######BBBBBGBBBBBBBGGP5555YYJ??JJ?JY5GGPP5YJYPP55P55YJJJYJ!~!~~^~~!7777!~^^~~!!7JYJJJYYYP5PPPYYY5PGGP5YJ?77!!?JY5PGGGGGBBBBBBBGBBB#BB######&&&&&    //
//    &&&&&######BB#BBBBBBBBGGGGGGP5Y??7777JYY55YY5PGBBGPP5PPPGGPYJ??J??!~~!~?J7~~7?7~!!!7JYJ??J5PGGPPPPPPGBBGP55YPPY5?7777??Y5GGGBBBBBBBBB#BB##B#BBB##&&&&&    //
//    &&&&&#####&###BBBGBBGGGGGGGPYJ?????J?7Y5GGGPP5GPPP5PPPGPPGBBBGGPPPPJ!~!JYYYYYYJ!!75GPPGGBBBBGGPGGGP5P5GGPPPGBPYJ??J?JJJ?JJPGBGGBBBBBB##B##&&#&###&&&&&    //
//    &&&####BB######BBBBBGGGBBGPYYYYYJYYYYJJ?YBBGPGGGGPPPGGGP555GB#####BBPJ!!?JJYY?!!YGB######BGP55PPBGGPPPGGGPPBGJJJYYYYYYYYYYJ5BBBBBB#########BB#B##&&&&&    //
//    ################BGBBBBBBB5YYY5YY55YYJYY??PGGGGBBBBBBGGPP5YJY5GBB####BGY!!!~!!7!YB#####BBGPYYY55PPGGBBBBBGGGG5?JYJYYY555Y5YYY5B######B#####&&&&###&&&&&    //
//    ################BB#B#BBBB5YY55Y5YJ7??JJ?JJYPGBBBBBBBBG55G5BPP5PBBB###BPJ!~^^^7JPB###BBGP5PPG5G55BBBBBBBBBGP5JYJJ7??JJYPY55Y55B######&&#&&#&&&&#&&&&&&&    //
//    &#######BBBB#######B####B55555YPYJ????Y5P5JYY5GGGGBBGPJ?JJJJ??J5PP5GBG5J~^^~^!?5GGP5P5YJ7?JJJ?7YPGBBGGGG5YYYPP5J??JJJYPY5P555B#&&&#B##&&&######&&&&&&&    //
//    #&&&&&##############B#BBB55555Y55JJJ?J5PGBG5J?YPGP5GGGP5JJJJYYYJ?7?Y5YJ?~^^^:~?JYYJ77?JYYJJJJYY5PGGPPGPY?J5BGGPJ?JJJY5555P55P#######B##&#&&&&#&&&&&&&&    //
//    #&&&&&&#####BBB#########BG55555Y55YY?J55PGPP5YJJYY55PPPPP5YJ?7!!!7??JY5?~:^^:~?YJ??!77!7?JJY55P555555YJJ55PGGP5Y?5555P5P5555B###&####&##B#######&&&&&&    //
//    #&&&&&&###BBB####B##BB####B5555555557JJJPGG555555YYYJJ???77!!!!!!777JY5?~::^^~?5YJ?7!!!!!!!7777?JYYYY5P5555GG5J?J55555PP5PPB&&&&#B####&#&&&#B&&&&&&&&#    //
//    ##&&&&&###B####BB#BB#BB####BGP5P5555?JYJ5PPP55GPPG5YYYY?777!777?7??JY55?!^^^^7?YYY?7?777!!!77?JYYYYPPPPG5PPPP5J??5PP5P5PPB###########&#&&&&&#&&&&&&&&#    //
//    ###&&#####BBBBGGGB##BBB###BBBBGPPPPPY?P5YJY5GPPGGGP5YYJJJJJJJ?JJJYYJYPYJ7~~~~?JYYYYYYJ???JJ?JJYJJYPPGGG5PP5YYY5YJ5PPPGBB###########&&#####&###&&&&&&&&    //
//    &########BBBGBB#BBB#BBBBBBB###BBBGGGP?5YJY5YYBP5GGGPP55JJ55YYYJJYYY5PPY?!~~~~7JYP5YYYYJJJYYY5YY5PPGGGGPPGYY5YJ5YYPGGB#####&&&&B#&#&&##&&&#B&&&&&&&&&&&    //
//    &###########BB##BBGBBBBBB#BBBBBBBBBBBY5G5Y55YPPPPPGPPPPPP5YYJYYJY5555YY?~~!~~!?5Y5P55YYYJJJJ5PPPPPPGGGGPPY55Y5GJPGBBGGBB#####&&#####B&&&&###&&&&&&&&&&    //
//    #############BBGGBBBBBBBBBGBBBBBBBGBBP?GBBBG5GPPGGPGP55PP55YY5YYPPJ7?JYJ7!^^!7?YJ??Y5PJY5YY55PPPPGGGGGPPG5GBGGPJGGBGBB####&&#B#&&&#&&&###&&&&&&&&&&&&@    //
//    &############BBBBBBBGBBBBGBBGGGGBBBBGPYJBBBBP5BGGPPPGGPPPP5YYYYPG5JJ5GGY?!!7?JYPPYJJPGPYYY55PPPPGGPPGGGB5PBBBPJ5PGGGBBB#&#B#####&B#&&&&##&&&@@&&&#&&&&    //
//    &&&###########BBBBBGGBBBBBBBBBBBBBGPPGGJYBBBG5GGGBGGPPGPPPPP55555PB####BGP5PGB####BGP55P5PPPPPPGGGGGBGGB5GBBBYYGGPBBBBBBB#####&##&###&#&&&&@@@&&#&&&&&    //
//    &&&&###########BBGBBBBBBGBBBBBBGBBPPBBBYJYPGBPPGPGBGGGGGGGP5PPPP555G#############GPP55PPPPPGGGGBBGBBPPB5GBGP5YYBBGP##B######&&BB&&&&##&&&&&@&&&#&&&&&&    //
//    &&&&###############B##BGGGBBBBBBBPPGBGYYBGPPP55PGBGGGBBGGGGGPPPPYJJYPGBB#####BBGPY?JJ55PPPGGGGBBBGGBGPPYPPPPGB5YGBPP#BB####&#B#&###&&&&&@@@&&#&&&##&&&    //
//    &&&&&###############BGBBBBGGBGGGGPBBGY5BBBBBBGPPPGBBGGGGGGGGGGPY5Y?JYPPGBB##BBP5Y?7?Y5YPGGGGGGGGBGBBPGPPG#BBBBBPYGBPG#BBGBBBB#&&&##&&&&&&&&#&&&&&&&&&&    //
//    ##&&&&&&&&&&&&&#######BBGPYJ??7?JYPPYPBBBBB#BBBPBGPGBBBGGGGGGGG5JJ??JYYJY5PP5YJ?J??JJJ5PPPGGGGGBBBGPGGPBBB######GYPBPYJ???JYPGBBB#&&&&&&&&#&&&&@@@@@&#    //
//    #B#&&&&&&&&&&&&&&####BBG5J7!7777!!??5BBBBBBB###GPBBBGGBBGGGGGPPP55PPGBBGPP55PPGGGPP555PPPGGGGGBBGGBBBPB#######B##BYJ?!????7!7YPBB#&&&&&##&&&@@@@@@@&##    //
//    &&###&&&&&&&&&&&&&&##BBPJ7!YY?!YY77?5GGBBGB#####GPGB#BGGBBBGBB####BBGGGBB####BGGGGGGB###BGGBBBGGBBBGPG#B###B#&#B##5?7Y5?!Y5?!?YGB#&&&&&&&&@@@@@@@&##&@    //
//    &&&&###&&&&&&&&&&&&&#BGPY?!?JJJJJ7?JPB##BB##BB##BGPGBBBBBBGGGGGGBGPP5YJ?J?YY????JY5PGGGPGGGGBBBBGGPPBB#BB&&BB&&&BB5?7?YYJJJ?7J5GB#&&&&&&&@@@@@@&##&&@&    //
//    &&&&&&###&&&&&&&&&&&&BBG5J777!!!!?Y5PBBB####B##BBBGPGBBBGBBBBGBGGB#BBBGPP5YY55PGGBB#BGGGGBGBGBBBBPPBB#####&&&###BG55J7!!7!7?JYPBB#&&&&&@@@@@@&##&&@&&&    //
//    &&&&&&&&###&&&&&&&&&&&#GGG5YYJ??YPGPPPGGGB#######BBBGGBBBGGGBBBBGGGGB###&&BG&&##BGGGPPGBBBGGGBBGGB#BB#&#&&&#BGGPPGGBG5JJY55PGGG#&&&&@@@@@@&&##&&&&&&&&    //
//    &&&&&&&&&&####&&&&&&&&&#####BGPY5B##BBGB#GPBGP########BBBB#BGBBBBBBBBB####PP####BBBGGBBBGGBBGGGB##BBB#&BGBGG##BBB####P5GB##B###&&&&@@@@@&##&&&&&&&&&&&    //
//    &&&&&&&&&&&&&####&&&&&&&&&&&&&&#55##&&##B#&&&&&######&#BGGGBBGBBBBBB#BBGBB55BBBBBBBBBBBBGBBGGGB#&#BBBB#&&&&###&&&&&#PG&&&&&&&&&&&&@@@&###&@@@@@@&&&&&&    //
//    &&&&&&&&&&&&&&&&####&&&&&&&&&&&&&G5B&&&&&&&&&&&######&&##BGGBBBBBBBBBBBBPP55PGBBBBBBBGBBBBGGBB##&#####&&&&&@@&&&&&B5B&&&&&&@@@@@@@&&#&&@@@@@@@@@@@&@@&    //
//    &&&@@@&&&&&&&&&&&&#####&&&&&&&&&&&#5G&&&&&&&&&&&&###&&###&#BBBBBGG##BBGGPGPPGGGGBBBBGGBBBB##&#######&#&&&&&&&&&@&GP#&&&&@@@@@@&&##&&@@@@@@@@@@@@@@@@@@    //
//    &&@@@@&&&&&&&&&&&&&&&&####&&&&&&&&&&P5#&&&&&&&&&&##&&BB##&&&&#BBBBGBBGGPPP55P5PPGBBPBBBB#&&&&##B#&##&&&&&&&&&&&#PG&@@@@@@@&&&##&&@@@@@@@@@@@@@@@@@@@@@    //
//    &&@@@@@@@&&&&&&&&&&&&&&&&&####&&&&&&&#PG&&&&&&&&&###B####&&&&&&##BGGGGBGGY775GPPPGGG###&&&&&&#B#B#&##&&&&&&&@&GP#@@@@@&&&#&&&@@@@@@@@@@@@@@@@@&&@@@@@@    //
//    @@@@@@@@@&&&&&&&&&&&&&&&&&&&&&####&&&&&BPB&@&&&###BB#&B##&&&&&&&&#BBGGB5GPY5PP5GGGGB&&&&&&&&##B##BB###&#&&&&[email protected]@&&&###&&@@@@@@@@@@@@@@@@@@@&&&&&@@@@@    //
//    @@@@@@@@@@&&&&&&&&&&&&&&&&&&&&&&&&&####&&GPG#&###GB&&#B##&&&&&&&&&#BGPPP55JJY5G5PGG#&&&&&&&&&#BB&&#BB###&#G5G&&###&&&@@@@@@@@@@@@@@@@@@@@@@@@&&&@@@@@@    //
//    @@@@@@@@@@&&&&&&@@@@@@@&&&&&&&&&&&&&&&&&&#BP5PB&BB&##BBB&&&&&&&&&&#BBGP5555Y555PGBB#&&&&&&&&&#BG#&&#G&#GP5P#&&&&@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@&&&&&@@@@@@@@@@@@@@@@@@@@@@@@#GPPGGP555B###G###&&&#&&&&&#&#BBGPPPPPPGB#&&&&&&&##&&&###G#&#G555PPPPPG&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&@    //
//    @@@@@@@@@@@&&@@@@@@@@@@@@@@@@@@@@@@@@&GY5Y?77J5GG55PGB&&#&&###&&&#&&&&&#BBGPB##&&&&&#&&&#B#&##&&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@&&@@@@@@@&#GGPPJ7?????JPGBGPB##B##&&####&&&&&&&&&GG&&&&&&&&&##B#&&&#B##GGBBGY?????7!J5YPB&@@@@@&&&&&&@@@@@@@@@@@@@@@@@&&&&&&&    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@&&@@@@&#BPPGBB5JBGP5GGYJG#BG&&B###&&&##&&&&&&&&&&GG&&&&&&&&&&B#&&&##B#&GB&#PJPGP5GGP?PGPPPGB&&@@@&&&&&@@@@@@@@@@@@@@@@@@&&@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@&#BGPPPPGG##G5GGGPGGP5B#&GB&##&&###B&&&&&&&&&&&[email protected]&&&&&&&&&#B###&&###P#&#B5GGGPGBP5B#G5PP5Y5GB&&@@&&&@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@#BGP5PPGP5PB#BB#BPY77?5G##&##GB#GB#&#G#&&&&&&&&#&&GG&&&&&&&&&&&BG#&#GB#PB&&&#BPJ77Y5PB#GGGP55PGPYYPGB#@@@@@@@@@@@&&&&&@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@&#GPPGPYB#BP5PGBBBBG##BPPGB#&##&&#P#GG###GB&&&&&&&#P#&GG&#G&&&&&&&&BG###PBBP##&####BPPGB#BPBBBGPYJ5B#GJ5P55GB&@@@@@&&&&&&&@@@@@@@@    //
//    @@@@@@@@@@@@@@&&#BBP55PGBBBPP5P#&BGGBGG#&&##B######&##G#&&&#B#B#&&&&&&&&&&&&&&&&&&&&&&#B#B#&&&#BB#&&###BBB#&&#BPGBGPG#GJ55Y5GGP5YY5G###&&&@@@@@@@@@@@@    //
//    @@@@@@@&&#BGGGPGP55PPGGGGPGBP5PGGBBGPPPGGGB#&&&&#####G&&&#BB&&&B&&&&&&&&&&&&&&&&&&&&&#G&&&BB#&&&B####&&&&BGGGGBP55PGGPG5J5P555PPGP555PPPPPPGB#&@@@@@@@    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract IDEA is ERC721Creator {
    constructor() ERC721Creator("IdeaSimulated", "IDEA") {}
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