// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Good Morning  (GM)
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//    #################################################################################################BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGBGGGGGGGGGGGGGGGGGGGG    //
//    ################################################################################BBBB#########BBBBBBBBBBBBBBBBGGGGGGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGGGGGGGGGGGGGGGGGGGGGGGGGGG    //
//    #######BBBBBBB###############################################################BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGGGGBBBBBBBBBBBBBBBBBBBBBBBBBBGGGBBBBGBBBBBBBBBBBBBBBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG    //
//    ###########BBBBBBBBBBBBBBBBBB#BBBB#############################B#########BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGGGGGGBBBBBBBBBBBBBBBBBBBBBBBBGGGGGGGGGGGGGGBBGGBBBBBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPPPP    //
//    ##############BBBBBBBBBBGGGGBBBBBBBBBBBBBBBBBBBBBBBBBBB######BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGGGGGGGGGGGGGGBBBGGGGGGBBBBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPPPPPPPPPPPPP    //
//    #############BBBBBBBBBBBBBGGBBBBBBBBBBBBBBBBGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPPPPPPPPPPPPPPPPPPP    //
//    ####BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGGGGGGGGGGGGGGGGGBBBBBBBBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPPPPPGGGGGGGGGGPPPPPPPPPPPPPPPP55555555    //
//    ###BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGGGGGGGGGGGGGGGGGPPGGGGGGGGGGGGGGGGGGGPPPGGPPPGPPPPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPPPPPPPPPPGPPPPPPPPPPPPPPPPP555555555555555    //
//    BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGGGGGGBBBBBBBBBBBBBBGGGGGGGBBBBGGGGGGGGGGGGGGGGPPPPPPP55PP555PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPGGPPPPPPPPGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5555555555555YYYYY55    //
//    BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPPPPPPPPP555555P555555555555YY555555PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5555555555YYYYY55555PPPPP    //
//    BBBBBBBBBBBBBBBBBBBBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPPPPPPPPGPPPPPPPPPPPPPPPPPPPPPPPPP55555555YYYYJYYYYYJJJJJY55PPPPPPPPPPPPPPPPPPPPPPPPPPPPPP55PPPPPPPPPPPPPPP555555555YYYYYYYYYY55PPPGGGGGB    //
//    BBBBBBBBBBBBBBBBBBGGGGGGGGGGGGGGGGGPPGGGGGGGGPPPPPGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP55555555555555555555555555YJ???JJJYYY55555555PPPPPPP5555PPPPPP5PPPPPPPPPP5555555555YYYYYYYYYYY55PPGGBBBBBBB#    //
//    BBBBBBBBBBBBBBBBGGGGGGGGGGGGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5PPPPPPPP5555555555555555YYY555555555555555555YYYJJ????7???JJJJYY5555555Y555555555555P5555555555555YYY55555555PPGGBBBBBBB#####    //
//    BBBBGGGBBBBBBBGGGGGGGGGGGGPPPPPPPPPPPPPPPPPPP555PPPPPPPPPPPPPPPPPPPPPPPPGGGGGGGGPPPPP555P5YYYYYYY555555555555555555555YYYYYYYYYYYYYY55YJJJJY5555YYY5555555555555555555555555555PPPPPGGGGGBBBBBBBBB######    //
//    BBBBBBGGGGGBBBGGGGGGGGGGGPPPPPPPPPPPPPP5555555555555555555PPPPPPPPPGGGGPPP555555PPPGPPPPPPYYYYYYYY555PPPP555PP55YYYYYYYYYYJJYJJJJJY555PPPPPP5555YYYYY5555555YYYYYYY5555555555PPPGGGGBBBBBBBBBBBBBBBBBB##    //
//    BBBBBBBBBBGGGBBBGGGGGPPPPPPPPPP5555555555555555555555555555555PPGGGGPP55555YYY555555PPPPPPYYYYYJJJJJYY5555555555YYYYYJJJ???JJJJJJJY55555555YYYYYYYYYYYYYYYYYYYYYYYYYY5555PPPPPGGGGGGGGGGBBBB#&#BBBBBBGGB    //
//    BBBBBBBBBBBBBBGGGGGGGGGPPPPPPP5555555555555YYYYYYYYYYYYY55555PGGGGPP555555555YYY5YYYY5PPPPYJJJJJJJYYYYY555Y55555YYYJJJJJJJJJJJJJYY55Y555555YYYYYYYYYYYYYYYYYYYYYYYYYYYY555PPGGGGBBGGGGGGGGGG#&#BGPPPPPPP    //
//    ##BBBBBBBBBBBBBGGGGGPGGGGGPPPPPP5555YYYYYYYYYYYYYYYYYYYYYYYY5PPPPP5YY55YY5555YYYYYYYJJ5555YJJJYYYYYYYYY55YYY55YYYYJJJJJJJJJJJJJJY55YJY55555YJJJJJJJJJJJJJJJJJJJJJJJJJYYYYYY55PGGGGPPPPP555PGB##GBG555PG#    //
//    ###########BBBBBGGGGPPPPPPPPPPPPPP555YYYYYYYYYYJJJYYYYYYYYY555555YYYYYYYYYYYYYYYYYYJJJY555YJJYYYYYYYYYY55YYYYYYYYYJJJJJJJJJJJJJJYYYJJY5555YJJJJJJJJJJJJJJJJJJJJJJJJJJY5555YJYY555P5PPGGPPPGGGB##PPPPPGB#    //
//    ###############BBBBBGGPPPPPPPPPPPPPP555YYYYJJJJJJJJJJJJJJJY55555YJJJJJJJJJJJJJJJJJJJJJJJYYJJJJJYYYYYYYYYYYJJJYYYYYY???????????JYYJ???YYY55Y????????????????????????JJJYJJYYJJYYY5555PB#G5Y5PBB##G5Y55PB#    //
//    ####################BBGGPPPPP55555PPP5555YYYJJJ?????JJJJJJ555555J????????????????????JJJJJJJJJJJJJJJJJJYYJJJJJYYYYYJ??????????JYJ?77?JYYYYY77777777777????777??????JJJJ?????JJJYJJJJ5GBG5YYPBBBBBGPGB&&&    //
//    GGGGBBBB##B#########BBGGGGGPPPPPP55555555YYYYYJJJJ???????J555555J?77777777????77777?JJJJJJJJJJJJJJJJJJJJJJ????JJJJJJ????77777?JJ77777JJYYYY7777777777777777??J????JJJJPYJYJJJJJ??JYPGBBBGGGGBBBB&&#B##&&    //
//    GGGGGGGGGGGGGGGGGGBBBBGPPPPP55555555555YYYYYYYYJJJJ????77JYYYYYY?7777777!!!!!!!!!777?JJJYYYJJJJJ???777?JJ?7777??JJJJ??777??7???777!!!?JJJYJ!!!!!777777777JY5PGPPP5PPPGBGGGGGGGGGBG#BB##&#######&&&&####&    //
//    #BBBB#BBBGGPPPPPPPPPPPPPPPPP555555555YYYYYYYJJJJJJ?????77?YYYYYY?7777!!!!!!!!!???JJJJJJJJYYJJJJJJ?7!!!7JJ?!!!!!7?J????777777??!~~~~~~?JJYYJ!77!!!7777???JGGBBBBBBBBBGB#BGGGGGGB#&B###&&&###B###&&&&&&#&#    //
//    ####&&####BBGPPPPPPPPPPPPPPP555555555YYYYYYYJJJJJJJ?????7?YYYYYY?777777!!!!!!!7???JJYYYYYYJJ???????77!7?J?!!~~~!7??????!!!!??7~~~~~~~JYYYYY?JJJJJJJJJJY5GBBGGBBBBGGBBB##BB###B#&&&#&&&&&&&&##&&@&&&&&#&&    //
//    ####&&#BBGBBBGPPP555PPPP55555555YYYYYYYYYYYYYYJJJJJJ??????JYYYYYJ7777777777777777??JJYYYYYJJ?JJJJJJJJJJJJJJ??77777??????????????77777JYYYYYJJY55PPPP55GGBBBGGGGGGGBBBB###B#&#BB#&&#&&&&&&&&&&&@@@@@&&&&#    //
//    B##&&&BBBGGGGGGPPPP5PGBGP55YY555P555YYYYYYYYYYYYYYYYYJJJ???JYYYJJ?7777777?JJYJJJY5555YYYYJJJJJJJYYYYYYYJJJYYYJJ?????????????JJJJJ?JJJJYYYY5PPGBBB##BB##B#####BBGGGGGGBB###&&#BB#&&&&&&&&&@@&&@@@@&@@@&&&    //
//    ##&&&&#BB#BBBBBBBBGGGBBBGPP555PBBP555555555555YYYYYYYYJJJJJJJJJJJJ???JJ?JY5PPPPPPPPPP555555555YJJJJJY5YJJJYYYYYY?7??????????JJJJJYYY5PPGPGBGGBBB###BBB########&&#&&&&&&&&&&&&&&&&@@&@@&@&@@&@@@@@@@@@@@@    //
//    ##&&&&##&&####BB####&&##BBGGGPGBGP5555G555555YYY5YYJJJJJYYJJJJJJJJJJY5PPPGGGGGGGGGGPP5PPGGGP5P55YJJ5PP55YYY5555YYJ?77777????JJJY5PGBBGBBGB#BGBBBBB#####&&#B#&&&&&&&&&&&&&&&&&&&&&@@@@@@@&&&@@@@@@@@@@@@@    //
//    ##&&&###&&##&#B#&###&&&#BBBBBB#&BGPPPG#PPPP5555PG5YYYYYYPGYYY5YYJJJJJYPGGGGGGGGGGGGGPPGGGGBGGPPPPPPPP5YY5PPPGGGP5YJ????????JYPGB#BG#BBBBBGGGGGGPPPPPPPPGGB#BB####&&&&@&&&&&&&@&&&@@@@@@@&&@@@@@@@@@@@@@@    //
//    ##&@@#B#&&#B&BB&&##&&@&BBGGBB#&&#GGPGB#GPGGPPGGBBGPPPPPPBBPPPPGPP5YJJJY55PPGGGBB######B#GGBBGGBGPPGPPP5YJJY5GBBBGGPYJJY5PGGB##&&&##########BBBGGBGGGGGGGGB&#GBB###&&&&&&&&&&&@@&@@@@@@@@@&@@@@@@@@@@&@@@    //
//    #&@@@&#&@@##&#&&&##&&@&#BGB#&&&&&#BPGBBP5GP555P##BBB#BB#&#BGGGBBGGGGGPPGGBB##&&&&&&&&&####&##&&&###BGB#BG5YG##B#BGBGGGB##&&&&&&&&&&&&&&&&&&&&###&&&&&&&#&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@&&&@@@    //
//    @@@@@&&@@@&&&&@@@&&&&@&&#B&&&&@&&&BB#B#GB#BB##&&&&&&&&#&&&&&&#&&&&&&&&&&&&&&&&&&&&&&&&&&#&&&&&&&&&&&&&&#BBB#########&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@&&&&&&&&@&@&&@@@@@@@&&@@@@@@@@@@@&&&&@@    //
//    @@@@@@@@@@&&&@@@&@@@@@&&&&&@@@@@@&&&&&&#&&&&&&&@&&&&&&&&&&&&&&&&&&&&&&#&&&&&&&&&&&&#&&&&&&#&&&&&&&&&&&&######&##&##&&&&&#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@&&@&@&@@@@@&&&@@@@@@@@@@&&&&@@    //
//    @@@@@@@@@@@@@@@@@@@@@&&&&&@@@@@@@&@@&&&&&&&&&&&&&&&&&&&&&&&&&&&&###&&##&&&&&&&&&&&##&##&&&###&&&&&&&&###########&#####&##&#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@&&&&&@@&&@&&&&&@@&&&&&@&&&@&@@@@&@&@@    //
//    @&&&&@@@@@@@@@@@@&@&&&&&@@@@@@@@@@&&&&&&&&&&&&&&&&&&&&#####&&##&#######&#####&&################################################&&&#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@&&@&&&&&&&&&&&&@&&&&&&&&&#&##&&&&&&&&    //
//    &&&&&&&&##&&&&#&&&&&&&&&&&&&&&&&&&&&&&#&&&&&&#####################BBB#####BB########BBB##BBBBBBBBBBBBBBB##BBBBBBBB###B######################&###&#&&&&&#&&&&&&&&&&&&&&&&&&&&&&&&&&&####B##BBGBGBB#&#B###    //
//    BB#BBBBBBB#B##BBBBBBBBBBBBBBBBBBBBBBBGGGGGGGGGGPPPPPPPGBBGGBGBGBGPPPPBBBGG555PPPPPBBG5PGGPPPP55555PPP5555PGPPPPPGGGGGPPGGPPPPGPPPPPPPPGPPPPPPPPGGGGGGGGGGGGGGBBBBB##BBB###BBBBBGGGGGGBBBBB#BBBBBB#&&##&#    //
//    BBBBBBBBBBBBGBGGGGGGGGGGGGGGGGGGGGGPPPPPPPPPPPPPPPP555555555555555555555555555YY5555YY55555Y55Y555555YYYY55YYYYYY5YYYYYYYYYYY555555555555555555555555PPPPPPPPPPPGGGGGGGGGGGGGGGGGGGGGBB###BBBBBBBBBBB###    //
//    BBBBBBBBBBBBBBBBBBGGGGGGGGGGGGGGGGGGGGPPPPPPPPPPPPPPPPPP555555555555555555555555555YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY555555555555555555555PPPPPPPPPPPPPPPPPGGGGGGGGGGGGGGBBBBBBB###&&&&&&&&&&&&&#    //
//    BBBBBBBBBBBBBBBBBBBGGGGGGGGGGGGGGGGGGGPPPPPPPPPPPPPPPPPP5555P5555555555555555555555555555555YYYYYYYYYYYYYYYYYYYYYYYYYYYY55555555555555555555555555PPPPPPPPPPPPPPPPPGGGGGGGGGGGGGGGGGGBBBBBBBBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBBBBBBBGGGGGGGGGGGGGGGGPPPPPPPPPPPPPPPPPPPP5PP5P5555555555555555555555555555555Y555555YYYYYYYYYYYYYYY555555555555555555555555555555555PPPPPPPPPPPPPPPPPPPPGGGGGGGGGGGGGGGGGGGBBBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBBBGGGGGGGGGGGGGGGGGGGPPPPPPPPPPPPPPPPPPP5P55555555555555555555555555555555555555555555555Y5555555555555555555555555555555555555555555PPPPPPPPPPPPPPPPPPPGGGGGGGGGGGGGGGGGGGGGGBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBGGGGGGGGGGGGGGGGGGGGGPPPPPPPPPPPPPPPPPPPPPPP5555555555555555555555555555555555555555555555555555555555555555555555555555555555PP5P55PPPPPPPPPPPPPPPPPPPPGGGGGGGGGGGGGGGGGBBGGBBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBGGGGGGGGGGGGGGGGGGGGGGGPPPPPPPPPPPPPPPPPPPPPPP5555555555555555555555555555555555555555555555555555555555555555555555555P5555555555555PPPPPPPPPPPPPPPPPPPPPPGGGGGGGGGGGGGGGBBBBBBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBGGGGGGGGGGGGGGGGGGGGGGPPPPPPPPPPPPPPPPPPPPP5555555555555PP555555PPP5555555555555555555555555555555555555555555555PPP55PPP5555PPPPPPPPPPPPPPPPPPPPPPPGGGGGGGGGGGGGGGGGGGGGGGGGBBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBBGGGGGGGGGGGGGGGGGGGGGGPGGGGPPPPPPPPPPPPPPPPPPPPP5PP55PPP555P555PPP5555P55555555555555555555555555555P555P55PP555PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPGGGGGGGGGGGGGGGGGGGGGGGBBBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBBBBGGGGGGBBGGGGGGGGGGGGGGGGGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5555PP55555P555555555PP55555P555555PP55PPPPPPPPPP55PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPGGGGGGGGGGGGGGGGGGGGBBBBBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBBBGGGGGBBBGGGGGGGGGGGGGGGGGGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP55PPPPPPPPPPPP5PPPPPP55555555555PP55P55PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPGPGGGGGGGGGGGGGGGGBBGGGGBBBBBBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBBBBBBBBGGGGGGGGGGGGGGGGGGGGGPPGGGGGGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPGPPPPPPPPPPPPGGGGGGGGGGGGGGGGGGGGBBBBBBBBBBBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBBBBBBBBBBBBGGGGGGGGGGGGGGGGGGGGPPPPPPPPPPPPPPPPPPPPPPGGGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPGPPPPPPPPPPPPPPPPPPPPPPGPPGGGGGGGGGGGGGGGGGGGGGGGGGGBBBBBBBBBBBBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBBBBBBBBBBBGGGGGGGGGGGGGGGGGGGGGGGGGGPPPPPPPPPPPPPPPGGPPPPPPPPPPPPPPPPPPPPPPPPPPPPGPPPPPGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBBBBBBBBBBBBBBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBBBBBBBBBGGGGGGGGGGGGGGGGGGGGGGGGGGGGPPPPPPPPPPPPPPPPPPPPPPGPPPPPPPPPPPPPPGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPGGGGGGGGGGGGGGGGGGGGGGGBBBGGGBBBBBBBBBBBBBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGGGGGGGGGGGGGGGGGGGGPPPPPPGGGGGGGGGGGPGGGGGPPPPPPPPPPPPGGGGGPPPPPPPPPPPPGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPGGGGGGPPPPGGPPPGGGGGGGGGGGGGGGGGGGGGGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBBBBBBBBBBBBBBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPPPPPGGGPPPPPPGPPPPPPPPPPPPPPGPGGGGPPPPGGGGGPPGGGGGPPPPPPPPPPPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBBBBBBBBBBBBBBBBBBBBBBBB###    //
//    BBBBBBBBBBBBBBBBBBBBBBBBBGGGGGGGGGGBBBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPPPPPPPGGGGGPPPPPGGGGGGGGGGGGGPGGGGGGGGGGGPPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBBBBBBBBBBBBBBBBBBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBBBBBBBBBBBBGGGGGGGGBBBBGGGGGGGGGGGGGGBGGGGGGGGGGGGGGGGGGGGGGGGPGGGGGGGGGGGGGGGGGGGGPPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBBBBBBBBBBBBBBGGGGGBBBBBBGGGGGGGGGGBBBBBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBBBBGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB    //
//    BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGGGGGGBBBBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBGGGGBBBBBBBBBBBBBBBBBBBBBBBBBBBB##B####    //
//    BBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGBBBBBBGGGGGGGGGBBGGGGGGGBBBBGGGGGGGGGGGGGGGBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBBBGGGGGGGBGGGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB########    //
//    BBBBBBBBBBBBBBBBBBBBBBBBBBBBGGGBBBBBGGGGGGGGGGBBGGGGGGGGGBBGGGGGGGGGGGBBBBBBBBGGGGGGGGGGGGBGGGGGGGGGGGGGGGBBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB######    //
//    BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGGGGGGBBBBBBBBGGGGGGGGGGGGGGBBBBBBBBBBBBBBGGGGGGGGGGGGGGGGGGGGGGGGGGGGBGBBBGGGBBBBBGBBBBBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB##BBBB####    //
//    ######BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGGGGGGGGGGBBBBBBBBBBBBBBBGGGGGGGGGGGGBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBBGGGGBGGGGGGBBBBBBBBBGGGGGGGGGBGGGGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB##########    //
//                                                                                                                                                                                                                //
//    Created by Shane Garyk aka Stoic The Photographer                                                                                                                                                           //
//    stoicthephotographer.eth                                                                                                                                                                                    //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GMMTN is ERC1155Creator {
    constructor() ERC1155Creator("Good Morning  (GM)", "GMMTN") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0xb08Aa31Cc2B8C0582bE42D38Bb643292e0A4b9EB;
        Address.functionDelegateCall(
            0xb08Aa31Cc2B8C0582bE42D38Bb643292e0A4b9EB,
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