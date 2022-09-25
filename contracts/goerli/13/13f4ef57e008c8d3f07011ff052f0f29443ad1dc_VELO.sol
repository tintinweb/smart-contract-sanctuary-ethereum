// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: All Knowing
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    B#######BBBBBBBBBBBBGGGGGGGGP5PPPGB##########&&&######BBG555PGPGPYJA~^::^!!JPPPPP5YY5PGP5Y?~^^:^^!JY5PGPPP5PGGB###&##&&&#########BBBGP55PGGGGGGGGGBBBB    //
//    B##BBBBBBBBBBBBGGGGPPPGGGGGP55PGGB########BB##########BGPGGBBBGP5YYY?!~~!777YY55Y5YY55YJ?YJ!!~~!7JYY55GBBBGPGGBB###########B######BBGGP55PPGGGGPPPGGGB    //
//    B#BBBBBGBBBBGGPPP5555PPPPPYYPGGGGB###################BBBGBBGBBGY5PPGPP55Y5??Y5PP5PP555P5YJ?JY55PPGPP55PGBBBBBBBB###############&&###BBGGP555PGGP5555PG    //
//    BBBBBBGGGBBGP55555555PPPPP5PPPGBB###&B#&&&##########BGBBBBBBBGGGGBBBGGGPY??PPGGGGGGGGGGGG5??Y5PGBBGGGGGGBBBBB#BBBB##B#######&&&&&&###BBGPPPPPPPPP55555    //
//    BBBBGGGGGGGP555PPPPGBBBGPPGGGGGB###&&&&&&###&&#####BBB####BBBBBBBBBBBBBP5Y5PGGGBBBBBBBGGBP555GGBBBB##BBBBBBBB###GG#######&&&#&&&&&##BBGGGGGGGGGBBGPPP5    //
//    BBBGPGGGGGP555PPPPGB####GB##BBGGB#&#&&&&&#&&&&&&&&&&###########BBBBBBBG5PGPGGGBBBBBBBBGPGGPP5PGGBBBBBBB####B########&&&&&&&&##&&&&&#BBGGBBBBBBB##BBGPP    //
//    BBBGPGGGGP5PP5PGP5GBB#########BB##&B#&&&&&&&&&&##&&##B#######BBBGGPPP555GBBBGGBBB###BGGGBBGBGPPPPPPGGBBB#######B#&&&&##BBBGGB#&&&#&&#BBB###B#####GGPP5    //
//    BBBGGPPPPPPPPPPPP55BB#BBBGGB########GP555PPGBB####BBBB#####BBBGGGBGGPGGB##BGBBBBBBGGGGGBBBB##BGGPGGBGPBBBB####BBB##G5YJ?????JJ5GBB#######BBGB###BGPPPP    //
//    BGGGPPP5PPPPPPPPPGGBBBBBGPPPPGBBBBGY?77777777??YGBGPGB##BGGBBBBB###&##BPB#B#B##B#####B##BBBBBB#BBB###BB##BBB###BPYJ???????????JJGBBBBBBBGPPGGGBBBBGGPP    //
//    BBGGGPP55PPPPPGGGGGGB#BB##BBB#####P?????????7777?5B######&&&&&&&&#####&##B########B#&###BBGGGGGBBB###&##&&&&&&GY?????????????7??P#######B#BB###BBBBGGP    //
//    #BBBGPP555P55PPPPGPGGBBB#BBBB#####Y??J???777777777JP#BB##&#&&&##&#&&&&&&##&&&#&&####&###BGPY??5PGB###&&####&BY??????77777????JJJYB########BB##BGBGGPPP    //
//    BBBGPP555Y555555PPPPPPGBBBBB#B###BJ7??777!!!!!!!!!!7?5B###B##&&&##&&&&&&&&&&#&&&##&&####GPY7:^?5GBBBBB###&B5J????7777777777??JJJYBB####BBBBBBBGPPPPPPP    //
//    GGGGGPP55JJY5555PPP55GGGBBB##BB#BBY777777!!!!!!!!!7777YG#######&##&&&&&&&&&&&#&&&&#&&###BGP5YY5PGBB####&#GJ??????7777777?????JJY5####BBBBBBBBBGPPPPPP5    //
//    GGPPPPP55YYY55PPPPPGGGGBBBBB#####BY77?7777!!!!!!!!!!77!?5B#&&##&&&&###&&&&&&##&#GB&@&####BBBBBBB###&#&&BY??????77777777?7????JJJ5B#######BBBBGGGGPPPPP    //
//    PPPP5555555555PPGGPGBBBBBB#####&##P77?7!!!!!~~~!~~~!!!!!7?P###GB#&&B##&&#&&#&&&###&&&&&&##########&&##PJ????????77777777?7???JJJP#&&&&#####BB#BBBGGGPP    //
//    GPPP5555555555PPPPPGBBBB#B#####&&#B?77!!!!!77!!!!!!!!!!!777?5BBB##&&#&###&&&&&#&&&&#&&&&&&&&&#&&##&&GJ?????????777777????????JJJG#&&&&#####BB#BBGGGPPP    //
//    GP5PPPPPPPPPPP55PPPGGBBBBBB####&&&B?!!!!!7777!!~~~~!!!!!77??7?P#&&&&&#######&#&&&&&&&&@&&&####&&#&&GJ????????77???7??????????JJJGB#&&#####BBBBBBBGPP55    //
//    5P55PPPGGPPPPP5PPGBBBBBBBBBBBB#&&##Y!7!!!!77!!!!~~~!!!!!77???77YB#BBGYJ5GB#####B########GP55PB###BYJ???????7777777????????????J5BB#&&###BBBBBBBBBGGPPP    //
//    PPPPPGGGGGGPPPPPPPGBB#BBBBBBB#&&&&#G77!!~~!!!77777!!!!!777?????JY5YYYYYJJY5YJ55YYY5P555YJJYY555555J??????????????????????777?JJGB#&&&####BBB#B##BBGP55    //
//    GGGGGBBBGGBGGGG55PGB###########&&&##J7!!!!!!!!7777777777777??JJJYYYYYYYYYJJJJJY5YYYYYJJJJYYY555555YJJJJ??????????????????????JJB#&&&&############BGPP5    //
//    GGBBBBBBBBBBGGP5PPGB#######&&##&&&&#J!!!!!!777777!7!!7777777??JJJYYYYYYY5YYYYJY5YYY5YYJJYY555Y555YYJJJJ?????????????????????JJYG##&&#&#&#&&&#####BGPP5    //
//    BBB###BBBBGGBGPPPGGGB##&&&&##&&&&&&#GY7!!!!!!!!!!!!!!!!77777JJJJYYYYYYYYYJ???JJYYYY5Y???JY5555555JYYYJJJ????????77777?7?????JYP##&&&&&&&&&&&&&&#BBGPP5    //
//    #######B##BBBBGGPGBB##########&&&&&&#P?7!!!!!!!!!77!!7777????YJJJJJJJJYYJJ?7??YYYYYYJ?7?JY555555YJYYYJJJJJ???????7777???????J5P#&&&&&&###########BGGGP    //
//    ####&#B##B###BBBB#BBB&&&&&#&&&#&&BB#B577777!!!!!777?????7??7?7???JJJYJJJJYJ?7?JJJYYJ??7JYYYYYYYYJJJJJJJ?J????????????????JJJJYG&&BG#&&&&&#&#&&&GPBBBBG    //
//    ###B#&####&#BBBBB#B#G###&&#&&@&&&##&BJ777777777?7?77777?7777777????JYJ??YYJ?7?JJJJYJ?7?YY???JYJJJJJ???????????????????????J??J5#@##&#&@@&&&&&######BBB    //
//    &&B?G&&#&&&#####BB&&&&&&&&&&&@@&&@@&B7!!!777777777?7777777777777??JJJ?77JYY???JJJJYJ??J5Y?77?JYYJJ?7??????????????????????????Y#&&@@&&&&&&&&&&&&###BBB    //
//    &&&B&&&&&####&##BGB#B#&&&&&&&&@@@&&&#57!!!!!7777777!777777??7!~!7?JYJ7!7?YY??JJYJJYYJJYYJ?!!7JYYYJ?777??J???????????????????JYG#&&&&&@&&&&&&&&&#BBBGBB    //
//    &&&&&###BBBBGBBGPPGGBB####&&&&&#&&&&##P7!!777777!777!777?J?77!~!?JYYY7!77JYJ7??JYJJJJYYJJ7!!7JY5YJ?777JJJ?????7??????7?????JYB##&&&&##&&&&&####BBPPGGG    //
//    &##BBGPPPPGGGPGGPPPGB###&&&&&&BB&&&#&#G??????777!!!!!!!!77?7!~~~7J55J7777JJ???77?????JJJ??7!7Y55YJ7!7?JJJ?????777???????JJJJYG###&&#B##&&@&&&##BBGPGGP    //
//    ##BP55YYYY55PGGBBBBB###&&&####BB##&#B5J??????7777!!!!~~~~~!~~~^~~?5Y?777??777777?77777?JJ?7!!JYY?7!!!777777777777?????JJJJJJJYB#B&######B&&&&####BBGBB    //
//    BGYJYYYYYYY55PGBB#B#B##&&#&&&#&&&&#PJ?J?????????77!~~~!!!!~~~~^^^~77!!!?J??77!!!7!!!77?J??7!!77!~~~!!777777777777?????JJJJJJJJYPB#&&&&#&&&&&&&#####BBB    //
//    BGY55?7!7JYYY5GBBBB###B####&&#####5YJJJJJJ??????????JY55PPPP55J?!~~~~!!7?JJ?7!!!!!!!77???7!~~~~!7?Y5PP55JJ5YJ??????JJJJJJJJJJJJYY5B##&#&&#######BBBBBB    //
//    GGPPY?~^~7YYY5PGBPGGBBGBB###B##BG5YYYYYYYYJJ??JJYY5PPGGP5555Y5PPPPJ!~~~!7J???7!!7!!!77??7!^^^~?YP5YYJJYJ?YPPPP5YJJJJJJJJJJYYYYYYJY5G##########B#BBGBGG    //
//    PPPPY7~^^~7YJY5PGGBGGBBB#BBBBG5YYJYYYYYY5PPP5YYJJJ7JY??7777!~^~!7YPP?~^~7JJ?77!77!!!7???7~^^~?YJ?!~~^^^~~~!7Y5J??JY5555YYYYYYYYYYYYYPPGGBBBBBBGBGGGPGG    //
//    PGPPY?~:^~?YJY5PGGBPG#BBBBBBG5YYYYYYYYY5GGGP5Y?!~~~~!!~~~~~~^::~~!?Y5!^^!?YJ?77??777????7~^^!?77!~~~^~~~~!!!!?!~777J55PPPPP5YYYYYYYYY5GGBGBGBBBGGGBGPP    //
//    BGGPY?!^^!JYYY5GGGGGBBBBBBBG5Y5YYYYYJY5PPPPYJ?7~^:^~!7~~!!!~~:^~7!~7YJ~^~?JJ?7????????J?7~^^!?!!!!!~^^!77!~!7?7!!!!7JY55PPP5YYYYYYYYYYYGBB##BBBBGGBGPG    //
//    BG5YYYJ?7?Y5YYPGGGGBBBGG###BP555555YY5PPPPPP5YJ7!^^^~!!!~~!!~~~!!!7?5J!~!?J????J????7???7~~~7J?7!!!!!!!7?7!7?7!~~!7?JYY555P55YYY555Y55YP#BBBBBBBGBGGGB    //
//    #BP5JJYYYY5YY5GGGBBBBBBB##BBPP555555PPGGPPPPP55YYJ?7~^~!!~!!!~~~!7JYY?77?J?????JJ???7????7!!?JJJ?7!!!!777777!~!7?JYY55555555555Y5Y55555PBBBBBBBBBBBBGB    //
//    ##BGGP5JJJYY5PGGBBBGB###&#GPPPP55Y55GGGPPPPPP55YYYYYJ7~^^~!!!!!!!77JJJJYJJ?????JYJ???????JJJJJ77777777777!!!7?JY55555555YJYY555555Y5555PB#####BB##BBGB    //
//    ###BBBBGPPPGPPGGGGBGBBBB##BGPP55PPPPGPPP5555P55YYYJJJJJ?!~^^^^^~!77?J55P5YJJ????JYJ????JJYY5P5JJ?7!!~~~~!!?JJYY5YYYYYYYYJJYY5PPP5555555PB####BBBBBGGPB    //
//    ###B###BBGGGPGGGPPPGGBGGB#BGGGP55PGPPP5555Y555555YJJJJJ???7!~^:^!?JY5GPP5YJJJJJJJYJJJJJJJY5PPGP5Y?!~^~!?JYYYYYYYYYYYYYJ??JJYY5PPPP5555P5G#BBBBBGGGPPGG    //
//    #BBB##BGBBBBGGGGGGGP5GBBBBBGGGPPPGGPP555PPP5YYY5YYYJJJ???????7!!7?Y5PPPPP5YYYYJJJYYYYYYYY5555PPP5Y7!7?JYYYYYYYYYJJJJJJJJJJJJYY5PPPPPPPPP5BBBBBBGGGPPGG    //
//    BBBBBBBGBBBBBBBGBGBGGBBBBBGPPGGGBGGP5555GGPP5YYYY55555YJJJJJJ?77?JY5YY5PP55YYJJJJJJYYYYY5P55YY555YJJJJYYYYYYYYYYYJJJJJYYYYYYYYY5PPGGGPPP5PBBBBBBBBGGBB    //
//    BGBGGGBBBGBBGGGGGGBB#B#BBBGGGBBBBGGP5Y55PGPGGP5YJY55PP555YYJJ??JJYJJJY5PPP5YJJ?????JJJYY5P5YJJJYYYYJJJYYYYYYYJYY5555PPP555YYJYYY5PPGGGPPP5PBB#####BGGG    //
//    GGGGGGGBGGGGGGBGGGB#B#B##BGPGGGGGGP5YYY55PGGBBGGPP55PPPP5YYJJJJYYJJJJYY5YYJ??777777777?JYYYYJJ?JJJYJJJJJYYY5YYYYY5PPPPPPPP5YJJJY55PGGGGPGP5P###B##BGGG    //
//    GGGGGGGGGGGPGGGGGGBBB#B##BGPGGGGGGP5YY55PPPGGGGGGGGPPPP5YYYYYYYYJ??J?JYYY???77!!!!!!!!77?JJJJ?????JYYYYJYJYY555YJY555555PPP55YYYY55PGPPPPPPPB###BBBGGG    //
//    PPPGGGGGGGGGGPPPGGGPGBB##BGGGGGBBGPP55PPPGPGGGGGGGGGP5YYYY55555JJJJ???JYYJJ???7777777??JJYJ777????JJY555YJJJJJYYYYJJYYY5PPP555YJY55PPPPPPPPG###BGGGPPP    //
//    PPPPPGGGGPGGGPP555GGBB####BGBBBBBBGPPPPPPGGP55YY5PPP5YYYY5PPP55YYYJ?7~!?J555Y???777?JJYJJ?!^^!7??JYY555555J?????J???JJYY555PP55YY55PPP55PPP###BGPGPP5Y    //
//    5P55PPPGGPPPP5P5??5GGGB###BGGGBB##BGPPGGGP5YYJJJYYYYYYYY5P5555YYYYJ?7!~^^!7J55YJ??JJYY?!~^^^~!7?JJJYYYYY5YYJ????JJJJJJJJYY5PPPP55PPPGPP555B##BBBBP5YYY    //
//    PP5555PPP5PPPP55YYPGGB#####G75#BBBB5PGGGGPPP555555YYJY5555YYYJJJ?J???7!~~^^~!?YYYYJJ?!~^^^~~!!77777?????JJJJ?77?JY55YYYYY555PPPPPPGGGPPP55B####BGPP5YY    //
//    PPP55555555555555PPGBBB####&####BBBBBBBBGGPPPP55YYJJJYJJ???JJ??JJJYJJJ77!~~^~!JY55YJ7~^^^~~!7??JJ????JJJ????777?JJYYY555PPPPPPPGGGGGGGGB#######BGGGPPP    //
//    GP5P55PP555555PPPPGGGB#############BB#BBBGGGPPP55555JY5Y5555YJJJ?????77!!!!~~~!7JYJ?!~~~~~~~~!!77777????JYJJ?7?JJJYYYY555PPGGGGGGGGGBB#########BBGGPGP    //
//    PPPPPPPP5YY555PPPPPPGGGB#&&&&######BBB#BBBBBBBGGP555YY55Y5YYJ???????????77777!!!7??7777777!7777777777????J??7??JJY55PPPGGGGGGGGGGGGBB####&&##BB5PPPPPP    //
//    BGGGGPP5YJYY555PPPPP5PGGB##&@&&&&####B#######BGGGGGGGGP5PP5P5YYJ???????????77777?JJ??777?777777777????JJJJJJJJJYY5PPPGGGG5J5GGGGGGBB##&&&&&#BBG55PPPPP    //
//    BBBGGPP55Y55P55PPG5PGGGB#####&&&&&&&&#B##&##BBBBBBBBBGGGGPPPPYJYJJJJJJJ???????JJJ55YJJ????7777?77?J??JJYYYYYY5555PGGGGGGG55PGGGGB###&&&&#####BBBPPPPP5    //
//    BBBGPPP555P5PPPPPGPGBBB########&&&&#############BBBBGBBGGGGGPPPP5555YYYJJJYYYYYYYYYYYYYYYJJ??JJJJJYYYYYYYYY55555PPGGGGGGGGBBBB######&&&###BB###BGGGPPP    //
//    BBBGPPP55PP5PPPPGGGBBBBBBBB#B##&##BB###########BBGGGBBBBBGGGGGGGGGPPP5555555YYJ???J??JJYYY55YJYY5555555PP55PPGGGGGPPGGGGBBBB#BB#########BBBBB##BBBBPPG    //
//    BBGPGP55PPPPGPPPGPPGGBBBGGG5GGGBBBBBBBGGGB#####GGGGGGGB#BBBGGBGGGGBGGGGGGP5YJJJJJJJJ????JJYPPPPPPGGGGPGGGPGGBBBGGGBBGGGBBBBBBBBBB##BBB#BGGGPGBBBBBGPPP    //
//    BBGGGGPPPP5P5GPPP5PGBB####B#&&###&######&######&&&&##BBB######BGGGGPGGGGGGPP55YY5555YYYYY5PGGGPGGGPPGGGGBB####BGB#&##########&#############BB####GPPP5    //
//    BBGGPPPGGGPP55PPG5PBB####B###BBGB##&&&&&&&&&&&&&&&&&##########BBBBGGGP55PBBGBGPGGGGGGGGGGBBGGGP5PGBGGBB#########&&&&&&&&&&&&&&&&&&###BBB#########BGGP5    //
//    BBBGGGPGGBPP5P5PPPPGB###GPGBGBGGB###&&&&###&&&&&####B##&#######B#####BGGGPPGGGGBBBBBBBBGGGPYPGGBBBB#####BB#############&&&&###&&&&&#BGGGGBBGGGB##GGGPP    //
//    #BBBGGGGGBGP5555P555PGGGGPPPPPGGB###&&&&&&##########BBBB###BBBBGBBBBBBBG5YYPPGGGBGBBBBBGPP5Y5PGBBBBBBBBBBBB###BBBB########&&&&&&&&###BGGPGPPPGGGGP555P    //
//    #BBGBBGGGBGBG555P555P5PPPP55PGGGBB####&&#####B###BBBBBBBBBBBBBGGPGGGGGGGPYJY5GGGPPGGGGPGP5JJ5PGGGGGGGGGBBBBBBBBBBBB##########&&#####BBGGG5555PP55P5Y5P    //
//    #BBBBBBGBBBBBGGGPPPPPPPPGGP555PGGB####&&########&&&&&#BBGBGBBBBP55PPG55YJJJ?J5PPPPPPPGPP5J??YYY5PPP55PPBBBBBGB#####&&&#############BBGPP555PGGGP55PPPP    //
//    ##BBBBBBBBBBBGBBBBGGPPPGGGGPP55PPGBB################BBBBGPPGGGGGP5YJ?7!~~!7?YY5555YY5P55YYJ7~~~!??J5PPGBBGPPGBB#####&&&##B########BBGP555PGGBGGPPGGGBB    //
//    BBBBBBBBBBBBBBBBBBBBBGGGGGGGGPPP5PGBBB####B##&&#&&&#####BBP55PGGP5Y?!~^^^~~J5PPPP5YYPPPP5JJ7~::~!~7YPPGPP55GBB###B####&#&########BBGPPPPPGGGGGGGGBBBBB    //
//    BBBBBBBBBBBBBBBBBBBBBBBGGGGPPPGGPPPPGBB###BB####&&&&&&&###BGP5Y555Y?7!~~!7?J5PGGGGPPGGGGG5Y?!!!~!7JY55Y55GGB###&&&&&&&####BBB#BBBGPPPGGGGPPPGGGBBBBBBB    //
//    BBBBBBBBBBBBBBBBBBBBBBBBBBGGGGGGGGGPPPPGBBBBB#####&&&&&&&&###BGP5555YYYY55PPGGGGGBBBBGGGGGPP55YYJY555PPGB###&&&&&&&&&##BBBBBBBGGP5PPGGGGGPGGBBBBBBBBBB    //
//    BBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGGGBGGGGGGGGPGGGGBB#######&&&####BBGGGGGGGGGGGBBBBBB##B#BBBBBGGGGGPGGGGBB####&&&&&####BBBGGGPPGGGGGGGGBGGGGGBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGPPPPGGGBBBB######BBBBBGGGGGGGBBBBBBBBB#BBBBBBBGGGGGGGGBBBBBB#####BBBBBGGPPPPGGBBBBBBBBBBBBBBBGPPGGGGGGGBB    //
//    BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGPPPPPGGGGGGBBBBBGBBBBGBBBGBBBBBBB##BBBBBBBBGBBBBBGGBBBBBBGGGGGGPPPPPGGBBBBBBBBBBBBBBBBBBB!.:~~77??JPP    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract VELO is ERC721Creator {
    constructor() ERC721Creator("All Knowing", "VELO") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x03F18a996cD7cB84303054a409F9a6a345C816ff;
        Address.functionDelegateCall(
            0x03F18a996cD7cB84303054a409F9a6a345C816ff,
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