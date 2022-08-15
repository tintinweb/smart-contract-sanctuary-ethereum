// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NEW HERE: X Marks the Spot Solutionists
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                                                                                        //
//                                                                                                                                                                                                                                                                                                                                                                                                                        //
//    .....:......................................................:..:............:::::...........................................:....::.:..::::.....:.............::::......::...........:::.............::...................................................::.................................:.:.......:.::.....:...:::.:.:::::......:::::::::::::::::......:.::.::::::.::::::::::::::...:...:::.:.::::::..::...    //
//    ..............................................:.............:.............................................::...........::...:::..::::...::....::..:::.....:::.............:...........................::..............................:....................:......:..........:::.............:::...::....::.:..:.::::.:::::::::...........:.:::::.::.:::::::.:::::.:::::::::::::..:.:..:.:::::...:::::::::....::    //
//    :...:::...:......::...........::......::..::..:................::...................................::......:.......:..::::::...::::..::::......:.::::......::...:.:......:...:::............:.:.:::....:.............................:........::.....:::::::.........:.................::...:::.::....::::::::::::::::::...:.::......^~::::::::::::::::::::::::::::::::::::::::.::..:.....::......:....:...::..    //
//    ::::::::...........::...........:::..................:.......:.::..................:......................:.....::::::.:::.....:::::...:..::::::.::.::::.....::..::.:.:........::.................:::..:...........::.............................:....::::::...........................::..:::::....:...:....:::...::..................:......^:....:.::.:::::::::::::::::::::^^:~~^:^~~^^!~!~~^!~^!77!~!!:::::    //
//    ::::::.::..:...................::...::...:::.....::..:::.....:......:.....:....::....::.........:..::::::::...::::::::..:::....:::::...:::::::::.:::::.......::..:::.::.:...::....:..............::::.::..............................................................................::::.::..::::^!~~!~~~::~!~~~!77!!!!!~!!7~!~:::^:7JJ77JJ?JJJY??JYY55?J?77!^^::::::::^~^!5PPGGGBG5PBGGGBBBBBGBBB#BBBGGBG~:::    //
//    ......::....................:..:....:.......:::.:::::::........:.::...................:..:...........::::::...::.....::::::::::::.:::...:::.:::...:......::...::.::........:..::..:::^^:::::^::::.::.:::::^::^^~^~~^...:.:::~~~~~~!!!!?7~^..........:::^:^?J?JJYYJJJJ?~:.....:^^~Y55YY555P5PP57~^^JPGGGBGGGGGBBGGB#BBGBGBBGBBGBBGJ^~^:PBB#BBBBBBB&BGBB##BB#&##BGGYJ!^::::^!:~G##############&########B###BBG~.:.    //
//    :....:::...::...:.::...........................:......:...:::.....::.........:::.:......::::::::....:::::^~~!!^^~~~~^^:::::::::^^^~~7!~~!7!!~:^^^!777????J????JJ?JYJJJJYYJJ5Y?JJ!^~?Y5555555P5555!..:~^^?5PPPPPPPGPP7:.:^^^?PGGGGGGGGGGPPJ^..........:^^:!5GBBBBBGGGGB5^.....:^.:YGGGGBBGGBBGGJ~:.YBBBBBBB#######&####BBBBGB#GGGGY~^.^PGB##B#BBBBBB#BB##BBB#B###&BBBP?^::^~.!G####&#####&########&#B&#&BBBBG?.::    //
//    :.:::::::::.^!~::::...:^^^!!?J?7~:....::::^!7!!!!!777?7!~::::.....:^^~?JJJJYY5YYY5J?!:....:::::::...:^^!YPPGBGGGGGGPG5?^:::::~~~YGBGB##BBBBBP!~^!PBBBGBBBBBBBGGGGGBBBBBBGGGB#BBGJ^^JPGBBBBGBBBBBGY^.^~:^5GGBGGGGGGBBP7.^~.^YGBBBBBBBGGGP5?^:.........:^^.~5BGGGGGGBBGGP~..:..:^:.JBGPBBBBBGGGB5!:^YGBGGBBB##B######&#BB#BB##B#BBGY^~::YGB#BGBBBBBBBBGBB##BGB#B#BBBBBB#G~.^~.7BBB#&###&&&BB&&&&&&&#####&#BB#B?.^:    //
//    :^~^!YP55PP55PP5PY~.:^~7Y5GGGGGGGP?:.:^~:!5GGGGGGBBBBBGGP!::::::.^~^~YGGGBGBBBBBBGGGP!:..::::::::::::^:^YBGGBGB#BBBGBBBY~.:::^^:?GBB##BGBBBGGJ~:^PBBBBBBBBBGBBGGBBBBBBB##BBBGBBGY~:~5GGBBBGGBBBBGP7.~^.?GGGGGBBBBBBBB5^:~.^5GGBGGBBGGGGPY~:...........::.~5GGBGGGBBBGGP!:..:.:^:^YGGBBGBBBBBGG57^:?GBBB####&&#BB#&#G##BBGBBB###BG5~^::YGBBBB#####BBBB#BB###B&#BBBB###B#G!:~:~P#&###&&##BB###&@&#&&#BB###B#BBY:::    //
//    :~~:^5BG##BBBBGGGP7^~~75GGBGGBBGBBP?:.~~.JGGBBGGBGGGGGGBG5!.:::::~~^?PGGGGBBBGBBBGGBG7.::::::::::::::~:^YGGB#BG##BBBGBBBP7:::~^.7GBGGB#B#BBBBY!:^5BB##B#BBBBBGGB#BBBB#BBBBBBGBBGJ~^^75PGGBBBBBGGGGY~~:^5GGGGGGGGBBGGBGJ!^:?PGPGB###BGGGPJ::...........:~::YBBBBGGPGGGG5~.:::::^::JGGBBBB#B#BBGPJ^.?GGBBBB###&&#BB#######BBBB##GGG5!~: YBBBBBBB###BBBBBBBGB#BBGBB#####BB#P!~.^G###B########BP5YYYYYYJJ??JYJ?7~.::    //
//    :^~:^YGGB###BGGGGP?!~^?GGBBBGGBBBBB5~:~^^5GGGGBBBBGPGBB##GJ^.:::~~:!5GGGGBBBBBBBBBBBP?:::..:::::::::^~:^5BBB##B##B##BBBBBBY^:~^:?BBBG#&#BBBBBY~:~5B##&#BGB##BBBB#BBBBBBBBBBBBBBBJ~!^:JGGGBBBBBBBBBGJ^:JGGPPGGBGBBBGGBBP7:~YPPGGB#BBBGGG5!::...........^^:~YGGGGGBBGGBGP!..:..:^:.JGBBBBB###BGGGJ^:JGBBBBBB&###BBPY5JJJJ?7??7?7777~^~:.YBGBBBBBBGGBBGJ~~!7!!PBB####&GG##BB5~.:G##B###&&&##B5!~~!7!7!!!!!!7~^:.:::    //
//    ::^:^YGGBB#BBGGGBB7^~^~YGPGB#BBBBBG5!^~::5BBGGGGGGGBBBBGBBG?:.:^!^^YGGGGGGGGBBBBBBBBGY^::.:::::::...^~:^5BBBB##B###BB##BBBBY^~^:7GB###&###BBB5!::YGB#BBBGB###BBGGGGGGGGGGGBGGGGPJ~~^.!PBGGGGBBBGBBGJ::YBBGGBGBBGGBGGBBGJ:~5GGGGGGGGGGPPJ^.........:...^^.^YGGGGBBGBGGBGJ^^^^^!7!~5BBGB#####BBBG7^.7GB##BB&&#BBBBJ~777!!!!~7!~!!~~::~^.JBBBBBBGBBBBGG7.:.^^.?BB###&#BBBBGB5~::PB##B#B#&&&###BBGBBBB#BBB##BBGY~:::    //
//    ::^:^YBBGGBBBBGBGG?:^~^!YPGGBGBBBGP7::^:^5B##BGGBBBBB##BBBBP!:^~^^YBGBBBGGGBB##BBBBBG?:.:::::::::::.^!::YB###&#&&####&&#B##BY!^.7BBB&&##BBBBG5!:^YG#&&BBBBBBBBGJ!!~~~!~^~7!^~^^^::^~^.?GBBBBBBBBBBB5^!GGB##BGGGGGGGGBGGP7JGGGGGGGGGGGPP7:.........:...:^:^YGBBBBBGGBBGGGPPPGGGBBGGB#BB#B####BGG7^:?BBB##BB##B##BBBBBBBBBGB##BBGGB?:~^.7GBGB#BB#B#BBGJ~^^~77JGBGB#BB#&#BBBP!^~5BB#&&####BB#&&##BBB#&&###&BGGG~:::    //
//    :^^:.Y#BGBBBBBGBGG?.::^~777YGGGGGP?^::^.:5GBBGGGBBBBB#B#BBBGP7~~:7PGGGBBGGBBB####BBBGY^::::::::::::.:!^:JG#BB##&#####&#B##B#B5!.7GB#&#####BBB5!:^5B#####BBBBBBGYYJ?5YYYYJJYJJJY?^::~^.^5GGGBBBBBBBGP?YBBGBBBBBGGGGGGGGBGPPGGBGGGBBGGGG5~::............:^::JGBBBBBBBBBBBBBBBGBBB###BBBBBBBBBBGGP?^:?GBBBB#####B##BB###B#BB##&&BB#GJ^~^.?GBBBBB#BGBBBBGGGPGBBBBBBBBB###B##GP7:^P&###&######BB##B&&&##&&&&#BGBG~..:    //
//    :^~:.YBGGBGGBBBBGGY^.:^!!75GBBGPJ!:.:^~^:YPPGGGBBBBBBGGGGGBGB57~7PGGGBGGGBBBBB##BBBGGP!..::::::::::::^:.?GBBB&####BB####B#BB#BP7JGGB####BBBB#5!^:YGBB#######BBBB########BBBBBBBG7:::~:.?GBBBBBBBBBBP5GGBB#BBBBGGBGGGPPGGGGGGGGGBBGGGGP7:....:...:^:...:^:^YGBGBBBBBBGGBGGBBBBB####BBBBB###BBGGP?~:7GBB#B###BBBBBB#&####BBB###BB#BY^~^.?GBBB#B##BBBB###BBBB#BBBBB#BGGBBBBP!!:^PBB#&#&&#&&&&&##&&##&#B####BGGG7:.:    //
//    :^~:.7GGGGGGBGGGGGJ::~~~JGGGP5J~:.:::^~^:YGBGGBBBBBBBBGGPGBBBBJ~JGGBBBBBB##B##BGGGBBBP7.::::::::.::::~^:?GB#######B#BG#&#BBGBB#BPG&&###&#BB#BP7^:JBB###BB#&###GB&&&#BB##BBBBBBBP7:::^~:~5GGBBBBBBB##BB###BGGGBGGGGGBBGB##BGGGGGGGGGGPJ^:..............:^::JGBBBBBBBBBGGGGGBBBBBB#B##BB#&#BBBBGPJ~.7GBBBBBGBB#BBB#&#B##B#####BBB#BJ:^^.!GBBGBBB#BGBBBBBBBBGBBBGGGBB#BGBB5~:~::5G###B&&##&&&##B####BB##BBBGGGG?.::    //
//    .:^:.7B#BGGGGGGGGGJ^:^^^!!!~~:....:::^~^7PBBGGBBBBGGBBBGPPB##BPPPGBBBBGBB#&##BGGGGBBGPJ^:::.:::..:..:~^:?GB######B##BG##BB##BB##B#&#BBB#BGBBB5!^:JB#####B##B##BBB##B##BBBBBBGBBG7::::^^:?PGGBBBBBB##B#BB#BBBBBBGGGGGBBB##BBGGGGBPPPG5?^.:.............:^::JGGBBBBGBBBBBBBBBBBBB###BBBBBBBBBGGGGJ^:7GBBBB#BGBB##BB#BB##BBBB####BBBY^^^.!GBBBGGB##BBBBBBGB##B#BGB##BBBGG5^.^~^:YGB#B##&&####BG55YYYPP55YJJYYJ?:.::    //
//    ::^:.?BBBGPGGGGGGG5!::.....:::::....:^::7PGPGGBGGGBGGGGBBGGGBGBBBBBBBBGGBBBB##BBBBBGGPJ^.::...:..::.:~^:?GB#BB#&#BB#BJJGBGBBBBBBBBBBGGB##B#BBP7::JGB##&&BB##BGBBBBBBGBBB##BBB#BG7::::^~:^YBBBGGBBBB###B#BBBBBGGGGBGBBBBBBGGGGGBGGPGGY~:::.............::.:JGBGB#BGBBBBBP5555YY5YJ5GBB###BBGGBBGJ^.7GBBBBB###BBBBPY5YYYJJYYJJ???7!~:^^.7GBGBBBGBBBB##BGBBB###BGB##BBBY^^..:!:.YBB#BB#&&&BB#G?~^^^^~~~!!~^^^^~^^::    //
//    .:^::?GGGGGGGGGGGGY~:::::.:::::::...:^^:7PGGGGGGGGGBBGGBBBBPPBBBBB##BBGGGGGB#BBGGGGBBGJ^:.::::::..:::^^:?GBBBBBB#BBBB?^YGBGGB###GGBBBBBB#&BGGP?^.?GBBBBB#BBBBBBBBBGBBGGGGGBGPPP57:::::^^.7GBGBBBB#BB##BBB##BBGYJPGBBBGGGBBBBBBBGGPPP?:................:^::?GGGBBBBBGGGG?::::.:~^:7GG##&&#BGGBBGJ^.~PBBB###&#BBBGJ^^^!~^:^!~^!~^~~!~~^.!GB##BBGBBGBBBGPGGBBBBBGGGB#BBG?.:::!::JGB###&##&#B#BGGGGGGGBBB#BGGBGBGJ..    //
//    ..^:.?GBBGPGPGGGGG?::....:::....::...^^:~PGBBBBBGGGGPPPGBBBBGBBGGGBBBGGGBGGGB##BBBBBBGJ^::::.::...:.:~^:JGBBBBBBBB#BBY^^?PBBBBBBBBBBBGGGBGBGBP?^.!GB#BGBBBBBBBGY7~!?7J7!~~!!~^^^..::::^^:~5GBBBB#####BBBBB###P!!5BBBBBBBGGBBB##GGGPY!:................:^::?PGGGGBBGGGGGJ^:..::^^.7GBB##&###BGGPJ~:!PB###BBBBB###BGGBBGGPGBGGBGGGGGP7^.~GB#BGBBBGGBGGY^!PGGBGB#GBB#BGGG?:.:~::5B#&&####&#B###&###&##&&&##BBBBBY.:    //
//    .:^:.?GGGPPPGGGGPP?:::.:::.:::...::.:^^:!PBBGBBBBGGGYJ5GGGBGGGGBBBGGGGGGG5YGB####BBBGGP7:.:::.....:::^:^YGBBBB###BGBBY7~:7PBGGPB#BBBBBB###B##G?^:7GGBBBBB##BBBGY77?JJJ??J?JJ?JJJ?!:::::^:.7PGBBBBGBBBBBBGGGGG5!:7GBGGGBBBBBGBBBGPPP?:.................:^::JPGGBBBBBBBGGJ^..:::~^.!GBGGGBB##BBGPJ~.~PBBBBB#BBBBGGBBB###BBBBBGBBGBGGP?^.!GBBBBBBBGGGGGY~:!5GGBGBBBBBGBB#BY~.~^:YB#&#&&B###BB#########&&###BBGGGY:.    //
//    ::^:.7PPBGGGPGGPPGY~::..........::..:^~:!5GGGGGGBBBGY!?PGGGGGGBBBBGGBBBG5!?GB##BBBGGGGGJ:::^::.::::.:~:.?PGGGB##BBGGBY^~~^~YGBBGB##B#GB####BBP?^:JGGBBBBBB###BBBB####BBBB#BGB#BGG5~::::^~:^JGBBGBBBBBBBGGGGG5?~::7PBBB###BBBBBGGGPY^..................:^::?GGGBBBBBBBBBY~:::::^^^?GGBBBGGGGGGBG7^.~PBBGGBBB#BBGBBBBB##BBBGGBGBBBBBP7^.~PGB#B#BBGGGGG?~~:~YGBGGBBBBBBBBBBP!~^.7GB####BBBB&##BB##BB####BB##BBBG5^.    //
//    .:~:.7GGGBBGGGGGGPY~::....::....:...:~^^JPPGBGGGBGGG5!~JGGGGBBGGGGGGGGGP?^7PGB##BBBGPGGJ:.:^::::.::::^^.7GGBBGGB####B5^:~!^:JBBGB##BBBBBGBBBBP7^.7GBBB#B########BB###BBGPGBBBBGGGY^...::~^:!5GBGBBBBBBGBBBGGJ^~^:!5GBBBBBBBBBBGGG57::.................::::7GBPBBBPGGGGBY^...::^^:7PBB#BGBGGGBBGJ~.^PGGGGGGBBBBBBBBGGBGBBBBBGGGBBBBP7^:!PBBBB#BBGGGGPJ.:~^^?GBBGGGBGPGGGBGG5^ ?BBBBBBB##B#&####BB#&#BB#BBBBBBBJ..    //
//    ..^:.!PBBBGGGPGGGG5~..:.....:.......:^:~YGPPGGB#BBGG5?:~YGGGGGGGGGGGGPPY~:7PGBBBGGBBGGP?:::::::..::::^^.~PGGBBBB###BBJ^.:~~::?GBBBBBBBBBBGGBBP7^.7BBBBB###BBB#B##BBB#BBBBBBBBBGGGY:.:...:~:.!PGBBGGGGGBBBGG5~.:~^:7PBB#BGGGBGGGGGY~::.........::.......:::?GBGGPPBBGGGGJ^.....^^.!GBBBBB#BGGBBP7~:!PGGGBBBGGBBBBBBBGGGB#BGGBBBBBBBP!^.!GGGGBBBBGGGGPJ: .~^:7PGGGGGGBBGPGGGP!:?PGBP5PPPGBBGGPPPGGPGP5555PP5J5Y!.:    //
//    ..^^.!PPGBGPGGGPPG5~:....:......:::.:^::JGGGGGBBBGGGP?^:!PGPGGGPGBGPPG5?^:7GBBGGGGGGBGGJ:.::::....:..~^.!GGGBBBBBBBBBJ.:::^~^^?GBBBBBBBGBBGGBP?^.7G#BBBGG##BB#BB#BB##BGGBBGBBBGBB5~.:....~~:^5GGBGGPPPGBBBP7:..^~:~5GGGGGGGGGGGGP7....................:^::!5PGPPGGPGPPP?:....:^~:~5PPPPPP5PGP5J7~^^J5P555YYY5555YY55YYYYJYJYYYJ?7?7:^:^7??!77777?~^~:...::::^^~~~~^!!~~~^^^::::~~:::::^^^^^^^^^^^~:...:::..::.::    //
//    .:^:.!5GGGGGPPGGGP5!.............:..:^::?GPPGGGGGGGGY~^::?555PGGGGGGG5!^::!PGBBGBGPGGPPJ:.:.:::.....:^^.7GBBGBBBBB#BG?:.::::~^:?PGGGBGBBGGBBGP7^.!GBBBBBBBGGBBBBGBBGGGGGBGGBGGBGPY^......:^^:?PGPPPPP5PP55?^...:^^^7YY5YYYYYYYJJ7^.................:...:::^!!~!7!~~~~^::.......:::^^~^^^^:^^:....::.:~:.::::::::::::...........::..:...............:.:.:..... ... .  ..............::.......:...:..::.......::..    //
//    .:^:.~5GPGGGGPGGGG5~................:^::?GPPGGGGBGGBY^:^:~J5PPPPPPPP5?:^^^?PPPGGGGGGGPP?.....:::....:^~:!YP55PP55PPPY7:...:.:~^^7Y5YYYYYJJJJ?7~^^~7JJJJ??7?77???7?7!7!!7!!!!!7~^~^:.......::::^~^^~~:::^^:::....::::..:::.:::....................................  ......................:.......:.......::.......::.:...:.:............::..:...:::..:.......:...........:.................::..:.::.::.:...:::..    //
//    ..^~:!Y5P55PGP55Y5J^.................~~^7JJ?JYYJJJ??!::^^:^^~^^~~^^^::.:::^~~~~~~!!!!~^::........:::::::^^^^^^^:::...:::..::..::..............:::........................................::.......:.....:.........................................................................:.::::.......:::.................::::....................::...:..............................:......::..::......:::.:::.:::::.    //
//    ..::::::::::^~^^::::................:::...:.:::...............  ............ ...........:.....:..::....................::.....::.....::.....::....:::....:::....:......::..:::.::.........:............::..................::.........................................................::........:..::.......:::.......:.....................:................:.......::.....................:...:..::.:::..::.::    //
//    ............................................................................................................................::::.:::.:::..:..::::..:::....:....:..........:..:::........................:.................................:.........................................::.....:::.....:.........:...................................::...........................................:::......::....:..    //
//    ...............................::.........................................................:...............::......:............:.:::...::::.::::......::...::::..........::..::.:......................::...........:...................................................................:..:::.....::..........:::...................:....:..:.........................................::.....:::........:......    //
//    ..........................................................................................::..................::::..........::................:..........:......:...:..:..:..:................................................................:..............................................:..................:......................:..:..:....:::...::...:::........................::......::::..:..:.::...    //
//    ...........................................................................................................:.................::::.........::..........::::.....................................................................................................................................:..........:...........:............::..............:.............::................:...............::...:.:...::    //
//    ................................................................................:...........................................::........:....:.......:...:::...........:.............:.....................................................:.............::.................................:.....................................................:..:.::.:......................:....................:::...:.....    //
//    .................................................................................................................:::....................::................::.......................:::::............... ......................................................................:..................:..........::..::.........:..............::..:.......:.....:.:.......:.:::...............:...:......:::....:::.    //
//    .............................::.................................................................:................:...................:::::.............::..::::.............:.................................................................................................:.............:..................:..............:::............:...........::.....:.......:.......................x marks the spot    //
//    ....................................................................................................:......::..............................:..................:.................:........................................................:......:.......................................................:................:.....::......:......::...........:.::.....:...............................solutionists    //
//                                                                                                                                                                                                                                                                                                                                                                                                                        //
//                                                                                                                                                                                                                                                                                                                                                                                                                        //
//                                                                                                                                                                                                                                                                                                                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NHXS is ERC721Creator {
    constructor() ERC721Creator("NEW HERE: X Marks the Spot Solutionists", "NHXS") {}
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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