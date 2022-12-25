// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The TwilightZone
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!!~!!!!!!!!!!!!!~~!!!!~!!!!!!!!!!!!!!~~!!!!!!~!~~~~~~~~~~~~~~~~~           //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!~~~~~~~~~~~~~~~~~~~~~^~~^~^~~^^^^^^^^^^^^^^^^~~^^~~^^~^^^^^^^^^^^^^^~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^    //
//    !!!!!!!!!!!!!~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    !!~~~!~~~!!!!~~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    ~~~~~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!~~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//     ......::::^^^~~~~~~!!!!!!!!!!!!!!!!!!!!!!!!!7!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    ..                ......:::^^^~~~~~!!!!!!!!!!!777!!!!!!!!!!!!!!!!!!!!!!!!!!!77??JJJJYJJJJ?????777777777!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    ..................               ........::::^^^^~~~~!!!!!!!!!!!!!!!!!!7?JJY5YJ?77!~~~~^^^^^^:::^^^^^~~~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    ::::::::..:........................                  ......::::::^~?5GBB#&5~::::^^^^^^^^~~~~~~~~~^^^:::::::^~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    :::::::::::::::::::::::::::..........................         .^JGBPJ!~^^75BG!~~~~!7JY5PPP55YYYYYYYYYYYJ?7~^:..:^!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::.......^?G&BJ!^::^^^~~~~5#JJPGGGP5YJYYPPGB#&&&&&&&&&&&&##G57^:::^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ^^^:::::::::::::::::::::::::::::::::::::::::::::::::::..:7G#BJJG7:^~~~~~~~!7YB&G5YJJYPB#&&&@@@@@@@@@@@@@@@@@@@@@&#P7^:^!!!!!!!!!!!!!!!7777777777777777    //
//    ~~~~~~~~~~~~~~^^^^^^^^^^:::::::::::::::::::::::::::::.:Y##Y~^^^!#J^~~~~~!YGGPY5YYPG#&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&G7^^!7777777777777777777!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!~~~!!~~~~~~~~~~~~^^^^^^^^^^^:::::::J&B?^^^~~~^!#!~~~?PBPYJYY5PB&&&@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&&G!.......................          //
//    ????????77777777777777!!!!!!!!!!!!!!!!!!!!!!!!!!!!!7##?^~~~~~~!!~GP~JGB5JJYYY5B&&&@@@@@@@@&&&&&&&&&&&&&&&###BBBBGGGBGGGGGY:  .........................    //
//    ???????????????7777??777777777777777777777777777!!Y&5~~!!!!!!!!!!J&BGYJJJJYPB&&@@@@@@@@@&&&&&&&&######BBGGPP55555Y5Y555555Y~..::::::::::::::::::::::::    //
//    ???????????J?777???7777777777??77777????????????7G&7^~~~~~~~~~~!?B#Y?JJJYPB&&@@@@@@@@&&&&&&#####BBBGGP55YYYYYJJJJJJJJJJJJJJJ!..:::::::::::::::::::::::    //
//    ??777777???7777???77777777??777777777777777???7?#&JJ555YYYYYYY5G#G????Y5B&&@@@@@@@&&&&###BBBBGGGPPP55YYJJJJJJJ?????JJJ???????!..::::::::::::::::::::::    //
//    ??777?????7777??777777777?7!!7777777777???7??77#&::~!7?JY5PPPGGGJ7??J5G#&@@@@@@@&&##BBBBGGGGP55555YYYJJJJJ??7??777???7777777!!~.:!~~~~~!!!!!!!!!!!!!!!    //
//    ??77???7!777??7777777?77?7!777777777???7?77777##::^^~~~~!!7?JPP?7?7YP#&&@@@@@@&&BBGGGGGGPPPPP5555YJJ?777777!!7!!!777!!!!77!~~!!!.~?777777??????777?77?    //
//    ????77!777??7777777777777777777777???77?????7B&::~~~~~~~~!7JPG?7775G#&&@@@@@&&BGGGGPPPPPPPP55555YJ?77!~~~^~~~~~!~~^^~^~~!~~!!77!~.!?777777777777777777    //
//    77777777777777777777777777777777??77777????75&~:^^^~~~~~~7JPB?77?PG#&&@@@@&&#GPPPPP5555PP55YJYJ??77!~^:::.::^~~^:::::::^~~~~~~~^^:.7777777777777777777    //
//    777777777777777777777?77777777??77777????77?&Y.^~~~~~~~~!?5BY77?PG#&&@@@@&#GPPPP5555555YYYY5YY?777!~^^::::^~^^:::::::::::^^^^^^^^^.:77????????????????    //
//    7777777777777777777??777777777777777777777!GB::^^^^^^^~~!JBP7?7PG#&&@@@&&BPP555555YYYJYJYJJJ??77!!!~~!!777!~~^^::::::::::::^:^^:::..!?????????????????    //
//    77777777777777777?7777777?77777777?Y5PGGGGG&B5555YYJ7~^~?P#?775GB&&@@&&#BPPP55555YYYJJJJJ???7777777?????77!!~^^::::::::::::::::::::..7????????????????    //
//    [email protected]@@&&&&&&&&&&&&&@@@&Y!JB577YGB#&&&&#BGGGGGGPPPPP5555YYYYYYYJJYJJJJJJ??77!~^^^^^^^:^:^^^^:::::^^^~~.!????????????????    //
//    777777777777777777777?77777777777&@BB##########[email protected]&JYBJ?JPG#&&&&#BBBBGGGGPPPGPPP555555555YYYYYYJJ?JJ??77!~!~~~~~~^^~^^^~^:^~~!!!^:????????????????    //
//    7777777777777777777?7777777777777&@[email protected]@@&@@@@@@@@@[email protected]@Y5G??5GB#&&#BBBBBBBBGGGGGGGGGGPPPPP5555555555YYYYJ?J??777777!!!~^~^~!!!!7!7?77:7???????????????    //
//    77!!77777777777777777777777777777&@#@@@&@@@@@&@@@B#&P&&YP5?JGGB&&&###BBBBBBBBBBGGGGGGGGGGGGPPPPPPPP55P5YJJJJYJJJJ??77!~~!~!7???JJYJYJ~~?????????????77    //
//    !!!!!!!!!!!!!!7777!!7777777777777&@&@@@&@@&@@&@@@BB#P&&5PY?YBG#&&&&&#######BBBBBBBBGBBBBBBBBBBBBGGGGPPPPPP555555YYYJ???77777?JYY5555Y7^???????????????    //
//    !!!!!!!!!!!!!77!!!777777777777777&@&@@@@@@@@@@@@@##&G&&5PY?5GG#&&&&&&&&###############BBBBB##B#B#BBBGBBGGGGPP5P55555YYYYYJ?JY55PPPP55J^7??????????????    //
//    !!!!!!!!!!!77!!!!!!!!777777777777&@&@@@@@@&@@@@@@##&G&&YPY?PBB#&&&&&&&&&&#######&###################BBBBBBGBGGGPPGPPPPPPP5555PPGPPPPP5^7??????????????    //
//    !!~!!!!!!77!!!!!!!!!!777!!!77777!&@#@@@&@@&@@&@@@#B&B&&YPY?5BB#&&&&&#&&&&&&&#&&&&&###B#&&&&&##B#&&##&###BBBBGGGGPGBBGBGGGPGGPGGGGGGGPP!!??????????????    //
//    !!!!!!!7!!!!!!!!!!!!7!!!!!!!!!!!!&@#@@@&&@&@@&@@@B&&B&&Y55?YBB#&&&&&##&&&&&###&&&&&##B#&&&&&&###&&&&#&&&&&#BBBGPGPG#BGBGGGGGGBBBBGBGGG7~??????????????    //
//    !!!!!!!~~!!!!!!!!!!!!!!!!!!!!!!!!#@#@@@@&@&@@&@@@BGBP&&Y55?JGGB&&@&&##&&&&&&#GB&&&&&#BG#&&&&&#BB#&&&#G#&&&&B5YY?!?PGB##BBGGPGGBBBBBBGG?~?77????7??????    //
//    ~~~~~~~~~!~~~!!!!!!!!!!!!!!!!!!!~#@PB&&&&@&@@&&&&57?J&&YYP??GGB&@@&&&#B&&&&&#GPB&&&&#BGGB&&&&#BGB&&&#BB###G5B###G7^YG###BGPPPGBBB#BGGG7!??777????7????    //
//    ~~~~~~~~~~~~!!!!~~!!!!~!!!!!!!!!~#@[email protected]&YYGJ75BG#&@&&&#GB&&BP5YJYB&&&&BGPY#&#&&#BGPGBGGGGGPPG#####G?~YBB##BGPPPPBB#BBGG!!7??7777???77??    //
//    ~~~~~~~!!!!!~~~~~!!!~~!!!!!!!!!!~J&@&&&&&&#&#BBBBBB#&&P?JP57?GGG#&@&&&BGP?7YGB#B55#&##GPYYGB#&##PJ?BBBBBBYG#BB##BG5??PGB#BGP5Y5PBGBBBP^777?77777??7777    //
//    ~~~~~~~~~~~~~~~!!!~~~!~~~!!!~~!!!~!7YJJJ?P#PYYYJJYJJ?7~!JYG?7JGPB&@@&&#G?7P#&&&&#P5BGGPBPYP###&&B5Y5#BB#BPPGP5GBBGP5?YGGGBGGPPYYPBBBBJ~7777777777?7777    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!!~~~~!~~~~7BY~~~?55555?~!?JP57!5GPB&@@&#B55G#&&&&#5G&&#B#G5JG##&&#G5YG#&&&#GY?JGGBBGP5J5PPGBBGP5Y55GBB!!7777777777?7777    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!!~~~!!~~~~~5B!~~7?????7~!!JYBY!!5GPB&@&&#BPBBB##B5P#GPG#BG5YYB####B5YYBBB###GY7YBBGGBGJJ5PPGGGGPYY55GY~??777777777?7777    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!!~~~!!~~~~~!B5~~7BBBBBP~!!7J5BJ!!YPPB&@@##B##BBGGBBPPPG##BBP?5#&&&#B5Y?GGB###GY7YGBBGBBYJPPPGBGGPYP5J!7?7777777777?7777    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!!~~~!!~~~~~~?#?~~!!?????!!!7?5B?~~JPPG#@@&B&&#GGGBGYP#&###B5J?P#####P5Y7PGBBBGPJ?PPGP555?JPPPPPPPYPP7!??777777777??7777    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!!~~!!~~~~~~~^Y&7~~~5GGGG?!!!7?YBJ~~755PB&@&&##BBBBBGPG#&#BGGPJ!B&B##BPJJ!J####BB5GGP5GGP5YYJ5PGGJ?Y?~??7777777777?77777    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!!!!!!~~~~~~~~5#7~~~~~~~!!!!!7?JB5~^~?55G&@&&####B&GG#&&#BBBG57J&&&#BBB57Y5B&&&&#GP#&###BG5JJ55PGG?!??77777777777777777    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!!!!!!!~~~~~~~Y#?~~~~~~~?7!7777?PG?~^~?5PB&@&&&##&#B&&&######BG&&&&&&##BBBB&@&&&&B#&&&&&###BBG5B5~??777777777777777777    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!!!!!!~~~~~~^?&5~~~~~~!55777777JG57^^~J5G#@@&&@@@&B#&&&&&&&&&&@@@&&&&&&&&@@&&&&&&&&&&&&&&&&&&5^777777777777777777777    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!!!!!!~~~~~~^!BB!~!!!~!YB5777777YG57^^~?5G#&@@@&&&&&&&@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&@@&@@@P^!777777777777777777777    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!!!!!!~~~~~~~P&Y~!!!7775BP?77777YP57^^~7YPB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&@@@@@@@&J^!7777777777777777777777    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!!!!!!~~~~~~^7#B7777777?5GGY?7777YGGJ~^^!?5G#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&5~~!!777777777777777!777777    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!!!!!!~~~~~~^[email protected]??JPBP?~^~!J5GB#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&BJ~~!777777!77777777!!!77777!!    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!~~~~~!!!!!!!!~~7P#&@&GPP5555PGB#&&&#BP55PB#GJ!~~!7JY5PGB##&&@@@@@@@@@@@@@@@@&&&#GY7~~!77777!!!777777!!!777777!!!77    //
//    [email protected]!!~~~~!7JPB####BBB&&&BPJ7~~~~!7?JJY55PPGGGGGGGGP55YJ?77!~!77777!!!!7777!!!!!7777!!!!!7777    //
//    [email protected]&55?7777JJ?777!!!!!!77?JY5PGGGB#&&&&&BG5J?7!!~!!!!!!!!!!!!7JJ^.:!?7!7777!!!!777!!!!!!777!!!!!!!7777!    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!!~~~~?#@577Y#Y!7!!7???7777777????????????JY5GB#&&&&&&##BGGPPPPPGB#&&P^       .~!!!!!77!!!!!!!77!!!!!!7777!!!!    //
//    [email protected]#7777!?&5~!!!!7?????????????????????7777??JY5PGBB##&&&&&&&B5!. ........ .~7!!7!!!!!!!77!!!!!!777!!!!!!7    //
//    [email protected]!!!!!!~7&Y~!!!!!!77????????????????77???JJJJJJYYYYYY555YYJJ?7!~:..........!!!!!!!!!77!!!!!!!77!!!!!!!!!    //
//    [email protected]!!^^^^~!~~#J~!!!!!!!!!7777??????77?7JGPP&G55YYYJJJ????7777777!~~Y~.........:!!!!!!!!!!!!!!!!77!!!!7!!!!!    //
//    ~~~~~~~~~~~~~~~~~~~~~~!~~~~!~~~~!~~~~~~!~~G&?!!^^::.:~PGJ#!!!!!!!!!!!!!!!!!!!!!!!7#?!7#Y?J?JJJJJJJYYY5555PPP!:^5:::.......^!!!!!!!!!!!!!!7!!!!!!7!!!!!    //
//    ~~~~~~~~~~~~~~~~~~~~~~!~~~~!~~~~!~~!~~~~^[email protected]!^::::...G&#5~!!!!!!!!!!!!!!!!!!!!!?&^5BG7??7777777777777777?7~^YY::::::....:~!!!!!!!!!!!!!!!!!!!!!!!!!!    //
//    [email protected]@@&#GY!::[email protected]#~!!!!!!!!!!!!!!!!!!!!!!GP~~~^^^^^^~~~~~~!!!777??J5GJ:::::::::...^!!!!!!!!!!!!!!!!!!!7!!!!!!    //
//    [email protected]#&&#Y~....&&!!!!!!!!!!!!!!!!!!!!!!!!YGGBGBBBBBBGGGGGGGPPGGGP5Y7!!!~^::::::..:~!!!!!!!!~!!!!!!!!!!!!!!!!    //
//    [email protected]!^:...:!5&@&Y^[email protected]!!!!!!!!!!!!!!!!!!!!!!!!!!!!JJ???77??!!!~~PP?JJJJJJYJYJ?!:^^:..::~!!!!!!!!!!!!!!!!!!~!!!!!!    //
//    [email protected]&5J7~^:::....^5&@[email protected]!!!!!!!!!!!!!!!!!!!!!!!!!!YP755555~JJ!!~B&^G#PP5YJJJJJ!5~^^:.::.~!~~!!!!!!!!!!!!~~!!!!!!!!    //
//    [email protected]###BP7^:[email protected]@@7777777777777!!!!!!!!!!!!!~J#[email protected]^@5^~~7J7~~~~G7^::!^..~!!!!!!!!!!!~~~~!!!!!!!~~~    //
//    [email protected]?7~^~75#&#Y^.......&@YYJJJJJJYYYYYYYYJ7!!!!!!!!YY?J?77!!!~^[email protected][email protected]~~?&&[email protected]?!YGP^..~!!!!!!!!~~~~~~!!!!~~~~!!!    //
//    !!!!!~~!!!~!!~~~~!!!!!!!!!!!!!!!!!!&@#BPJ!^:..^J#&B?:... B&[email protected]~::::::::::^&@&[email protected]@G!!777P&#Y#?5GY7!7?5!!!!!!~~~~~~!!!!!!~~!!!!!    //
//    77777777777777777777777!!!777!!7!!#&PYYPB&&#5!:..^Y&&5^..&&J!!!~~!!!!!!!!!!!!!!!!!!!!!&B^^~^^^~~~^:[email protected]&###&GGBBBBGG&@BGP5J7!~:!!!!!!!!!!!!!!!!!!~~!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!777777777777#&?7^^^^^!JB&&G7:..7#@Y:&#J!!~~~~~~~~~~~!!!!!!!!!!!!!#@~^~~~~~~~!^[email protected]#BBGPPY?7!^::GY7?JYYJ^..:7~!!!!!!!!!!!!!!!~!!!!!!    //
//    [email protected]^^::::..:[email protected]&Y:..7&&@&#[email protected]^~^^~~^[email protected][email protected]^::::^~~....7#BBBPY7~:..:?!!!!!!!!!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!~#&77!:::........:[email protected]@Y:.:&&[email protected]?:^JP~^^[email protected][email protected]!...:BPJ7!!~^^:...!77!77!!!!7!!777!!!!!!!!    //
//    [email protected]@#BG5J7~:........:[email protected]&[email protected][email protected]::G&?::[email protected][email protected]~~^:::::::PP???77~^^^:....~777777777777!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!&&5Y?JYPB##GJ~:...:^.:#@[email protected][email protected]::G&Y:[email protected][email protected]^~!!7?Y5P#@5YJ??7~^^^^~!7?5?!!!!!!!!!!!!!!!!!!!!    //
//    [email protected]?!^:::::~75GB57:.7PJ:[email protected]@&#[email protected]::P&[email protected]^&&[email protected]&####BBBB#BPY!:.~????????????????????    //
//    [email protected]?~^^^^^::::^75G5!:!!^@&[email protected]::[email protected][email protected]^@G^^:::::^~5BPP5YJJ??7!~^^:.. ~7!!!!!!!!!!!!!!!!!!    //
//    ~~~~~~~~~~~~!!!!!!!!!777777777#@YJ??!^^::::::....^7Y!.:@#[email protected]::Y&P:[email protected]^@P~?YPGB#BB#&55Y?777!!!~~~~^:^YJ!!!!!!!!!!!!!!!!!!    //
//    [email protected]@&&#BG5YYY55PPPP5J7~~^.&&[email protected]::7JY:[email protected]:&&BPY?!^:...##5YJ?77YGB###BG5Y?~!77777777777777777    //
//    [email protected]@GYYPB&&&&#BP5YJJYY55!.&@&#GP5YJ?7!!!!!!!!!!!!!!!!!!!!J&B::7GG::[email protected]:&5....::^^[email protected]???JYYJ7~~~~!!?J7777777777777777    //
//    [email protected]&B&@&B5J77??JYYYYJ7~:. [email protected]##&&&&###BGGP5YJ???7!!!!?&#::7&#::^@5:&P~?JYPPGGGPYJ?GYYJJ?75BB#####PJ~^7!!!!!!!~~!!~!!!    //
//    !!!!!~~~~~~~~~~~~~~~~~~~~!!!!~7&@@#5?JP#&#BPY?7!!~^:.. .&#Y7!!!!!!77?JJYY555555YJ?!!!!?&#::7&#^:^@P:&#55YJ7!^::::..5PYYJJJJJJJJ??7:. ~?!!!!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!~#@PJG&@#PJ??7~:::...:^[email protected]&GP5YJ??7!!~~~~~~!!!!!!!!!!!?&&^:7&&^:^@P:&5:^~!7J5PGG7..7GY5555YYJJYY55P~ ^?!!!!!!!!!!!!!!!    //
//    ~~~~~~~~~~~~~~~~~~~!!!!!!!!!!!!#@@@@GJ?JJ?!~^^~7YGBBGY7~:[email protected]?7!!!!!!!!!!!?&&^:7&&^.^@P:&&BBGG5J7~^:.:.7G5PP5PPGGGGG5J!:..7?!!!!!!!!!!!!!!    //
//    [email protected]&YJJJ?7!!?5#&&GJ!^::...  [email protected]?7!!!!!!!7777!!!!!!!!!!!?&&^:!&&^:^@G:@P::::^~!?J5PPP&#PPYJ??7!!~~^^:..^Y7!!!!!!!!!!!!!!    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^[email protected]#YYYJ?JP&@&P7~^^^^::..:^!7&@G?!!~~!!!!!!!!!!!!!!!!!!?&&^:!&&^:^@G:@BYPGBBBGPY?!^:.~PGP555YYY5555PPGGY~!!!!!!!!!!!!!!    //
//    [email protected]@&#PP#@@B?~^^^^^^~7YGBG57^.!#@BPYJ77!!!!!!!!!!!!!!!!?&&^:~BG^:^@G^@B77~^:::^~!?YY55#GPG#####BGPY7^..J!!!!!!!!!!~!!!!    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~7&&B&@@G?77!~~!YG#&#57^:....  Y&BBBBGGGPPPPPPP5555YY?7&&^^^~~^:^@B^@Y:~!?5G##BPY7~:::5GGP5JJ?77!!~^^YJ!!!!!!!!!~!~!!~    //
//    [email protected]@@BYJJ??YG&&#P?~^::::::....:#@GJ?7!!7777???JJJYYY?7&&^:7?Y?:[email protected]^@#PBBG5?~^:::::.. :BGGGBBBBBBGPY?~!!!!!!!!!!~!!!~!    //
//    [email protected]&@#57~^^^^^^^^::~JPG5!^5#577!!!!!!!!!!!!!!!?&&^^7BB!:[email protected]^@B~^:::::^^^~!7!7JYGP55Y?7!!~^::. .?!!!!!!!!!!!!!!    //
//    [email protected]@#G#@@B5?7!!~~~~^^^7P##P7^:.. ~#5!!!!!!!!!!!!!!!!?&&^^~~~^:[email protected][email protected]::^~!?YGBBBPY7!J#P55J7!~~~~^^:. ~7!!!!!!!!!!!~!    //
//    [email protected]@&B555YJ?7!~~~~5&&P7^^^^:[email protected]?77!!!!!!!!?&&^^~??^:[email protected][email protected]~?YGB#BPJ!^:::.. JB55J7!~~~^^:...:Y7JJJJJJJYYYYY    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^[email protected]&P555555YJ77G&#J~~^^::.:!YGP??&&B&&&&&&#[email protected]&^^~GG^:[email protected][email protected]&GGPJ!:...:^^~~:. 5#55Y????JJY5555J?YPPPPP5555555    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~7&@#P55555P#@#Y!!!~^:^?B#G?^.. :[email protected]#::!#B^:[email protected][email protected]:....::^~77?JJ?JP&555PPGPP5J?!~^. .?!!!!!~~~~~~~    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~J&@&BPP#&#PJJ?7~^7B&#J~:::::. .J#[email protected]::?&#^:[email protected][email protected]:^!7J5GBBBGP5J7!:?G55Y!~~^^:::::.. !!~!!~~~~~~~!    //
//    [email protected]@&&#GPPP5J?5&&G7^^^^^^^^:.. :[email protected]::J&B^:[email protected][email protected]~::...::..:G555?!~~~^^^^^:. ~7~!!!~!!~~!!    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!~~~!!!!!!~~7&J75&@&BGPB&&P7~~~~~~^~~^:..:!P&[email protected]:^[email protected]::[email protected][email protected]~^:..:^~7J5GBGY::.JG55Y7!~~~^^^^::7Y!~!!!!!!!!!!    //
//    YYYJJJJJJ?????777777!!!!!!!!!!!~~~~!!~!!~~~J#~~!!JB&@@&P?7!~~~~~~~^^^[email protected]:^?P?^^#@^[email protected]!:!?YGB##BPY7~^::.~GPPBGPYY55PPGGG5!~7!!!!!!!!!!!    //
//    55555P5PPPPPPPPPPPP5P5555555555YYYYYJJJJJ??P#[email protected]@PJJ7!~~~^^~JG&#5!^:...:[email protected]?^~!~~~^B#:[email protected]?!^::::::^~?PB&BPGGBBBBGP5?!:...?!!!!!!!!!!!    //
//    JJJYYYYY55555555PPPPPPPPPPPPPPPPPPPPPPPPPPPP&7~!777??Y&@BYJ!~~!Y#&#57~~!7~^^..:J77??JJ#@!~!!~~~~77^[email protected]~::::^^^~!7YPBBGJ^[email protected]&#GP5YYJ?!~^:..~P55555555555    //
//    ~~~~~~~~~~~!!!!!!777777????JJJYYYYYY55555555#&[email protected]&5?5#@&P?!!77??7P&@Y. ^PJJJJJ&&~~!~YB&#~^^[email protected]!!777?YG#&#GJ!:.....J#@@&&#BBGP5Y5PGGPPGPPPPPPPPP    //
//    [email protected]#PB&&&#BG5Y&                                                                                                //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TTZ is ERC721Creator {
    constructor() ERC721Creator("The TwilightZone", "TTZ") {}
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