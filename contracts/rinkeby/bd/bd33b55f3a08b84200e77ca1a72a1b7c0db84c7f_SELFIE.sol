// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SELF PORTRAIT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                  .:~!7?JYJ????7!~^:.                                                                                           //
//                                                                                             :~7YPB#&&&&&&&&&&&&&&&#BGP5Y7~^..                                                                                  //
//                                                                                        :~?5G#&&&@&&&&&&@&&&&&&&&&&@@@@@@@&&#BGGGGGGPY7:                                                                        //
//                                                                                    .~JP#&&@&&B#&&@@@@@&@@@@@@@@@@@@@@&&&&&&&@@@@&&&&&&#P?~:.                                                                   //
//                                                                                :~JP#&&&&&&&&#&@@@@@@@@@@@@@@@@@@@@@@@@@&&&@@@&&&&&&&&&&&&&#BPJ!:                                                               //
//                                                                             .7P#&@&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&@@@@@@@&&&&&&&&&&&&&&#P7.                                                            //
//                                                                           ^YB&&&&&&&&&&@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&&&&&&&BY!^                                                         //
//                                                                        .!P&&&&&&&&@@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@&&&@@&&#######&&&&&&&&&&&&&&&&&&&BP7:                                                      //
//                                                                     .!YB&&&&&&&&&@@@@&@&@@@@@@@@@@@@@@@@@&&@&#&&@@&######BBBBBBBBB###&&&&&&&&&&&&&&&&###G?:                                                    //
//                                                                  ^?5B&&&&&&&&&&&@@@@@&&@@@@@@@@@@@@@&B#&@@@#BB#&@@&&##BBBBBB#BBBBBGGGGGB############&####BP?:                                                  //
//                                                              .~JG#&&##&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@&##&&&#&&&&&&&&&&##BBBBBBBBGP5YY55PGGPP5YYYYY5PPGGBB#BGPY~                                                 //
//                                                            :?G&&&&&&&&@@@&&&&@@@@@@@@&&@@&@@@@@@@@@@&&@@&B&@&&&&&&&&&&&&###BBGP55YYYYYJ?7777777??JJYY5PGBBGYYY^                                                //
//                                                         .~5#&&&&&&&@@@@@@@@@@@@@@@@@&B&@&#@@@@@@@@@@@@@@&##&&&&&&&&&&&&&&##BPP5YYJ??77!!!!!7777???JYYY5PGBB5JY7                                                //
//                                                      :!JG#&##&&&&@@@@@@@@@@@@@@@@@@@@&@@&&@@@@@@@@@&&#@@&&&&######&&&#&&#BGPYJ?77!!!!!!!77777777?JJYYYY5PBBGY5J                                                //
//                                                     !B&###&B##&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##&&#GPPPGB###&&&&##BGPY?7!!!!!!!!7??JYY55YYJJJYYYYY5PBBGP5Y.                                               //
//                                                     :G&&#B#&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&PYYJ?J55PGB###BGPYJ77!!!!!777??JJYY55PGGGPP55YYY5PG#G55Y~                                                //
//                                                     ~555B&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&BJ????Y5YJJYPPP5YJ7!!!!!!!77JY5PPPPPPPGBBPYJ?JJY5GB#B7!7:                                                 //
//                                                         ?&&&##&&@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&BJ?7JYJJJ??JY55Y?7!!!!!!!!77??JY5PPPG##BBGJ7!!?YG###P.                                                    //
//                                                        ^G&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&#5???J?JJ?7?JJJ?77!!!!!!!!!7777??J55PPPPJ??7!!7?G#G5!                                                     //
//                                                      ~YB&###BBGGB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&##&#PJ??7777777??77777!!!!!!!!7777??JJY55J777!!!!7JG7                                                       //
//                                                  .^?P#&#[email protected]@@@@@@@@@@@@@@@@@@@@@@@&&&&########B5J??7777777777777!!!!!!!77777???JJJ??77!!!!77J^                                                       //
//                                               .~YG##BGGP555555PP55Y5G#&@@@@@@@@@@@@@@@@@@@@&&&&&#BGGPP5YYY5PG5??7777!!7!777777!!!77777????JJJ?77!!!77?JJ:                                                      //
//                                            .^JPB#BBGGGPPPPPPPPPPPP5YY5PG#@@@@@@@@@@@@@@@@@@&&###BGP5YJ?77777?JJ??77777777777777777777????JJYJ??7??JJJ?J5Y                                                      //
//                                          .?G#&&#&&&&&&&&&@@&&&&##BBGP55PB&&&@@@@@@@@@@@&&&&&&##BGP5YJ??77!!!7?JJ??777777777777777777????JJJ?77?JJY5PP5J7^                                                      //
//                                        .?G&&&&&&&&&&&&&&@@@@@@@@@@@@&&#&&&&&&&&@@@@@@&&##&&&&##BPYJJ??77!!!777??????777777777777777?????JJJ?7777?JYB#P                                                         //
//                                      .JB&&&&&&&&&#&&&&&@@@@@@@@@@@@@&&@@@@@@@@@@@@@@@&&&@&&&##BP5J??77!!!!!!!!77?????7777777777777777?JY5PP5555P55PB#!                                                         //
//                                     :G&#&&&&&&&&&&&&&&&@@@@@@@@@@@@@@&&&&@@@@@@@@@@@@@@@@&&&&#B5J?777!!!!!!!!!7777??????7777777777777?????JY5GGGBBBB?                                                          //
//                                     P&####&&&&&&&&&&&&&&&@@&&@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&##PJ?7777!!!!!!!!!!77777?????????777777777777?J5PPPPGBG7                                                           //
//                                    ~######&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&GY?777!!!!!!!!!!!!!!7777???????????777777777?JY5PPGG5^                                                            //
//                                    7&###&&&&&&&&&&&&&&&@&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&BY?777!!!!!!!!!!!!!!77777????JJJJJJJJJ????77777??J5G5                                                              //
//                                    ~##&&&&&&&&&&#GP5J??JP#&&&&&&@@@@@@@@@@@@@@@@@@@@@@@&&&&#Y?777!!!!!!!!!!!!!!!77777???JJYYYY55YYYYYYJJ??JJY5PGY^.                                                            //
//                                    ^BGYYJ??7!~~~^.       :7YG##&&&&@@@@@@@@@@@@@@@##BB#BB#GJ777!!!!!!!!!!!!!!!!!77777??JJYY55PPPPPPPPPP55PPPGGB#&&BJ^                                                          //
//                                     :.                      .:^75B&&&@@@@@@@@@@&#PYJJJ55YJ?777!!!!!!!!!!!!!!!!!!7777???JYY55PPGGGGBBBBBB###&&&&&&&&&#Y.                                                        //
//                                                                  !G#&&&@@@@@&&GY??777JYY?77!!!!!!!!!!!!!!!!!!!!!777777???JJJY5PGB#&&&&&@@@@@@@@&&&&&&&G:                                                       //
//                                                                   .J###&@@@&&&GJ?77?JJ?77!!!!!!!!!!!!!!!!!!!!!!!777777777???JY5G#&&&&&&@@@@@@@@@@@&&&&&B7                                                      //
//                                                                     !G&&&&&&&#5??77??7!!!!!!!!!!!!!!!!!!!!!!!!!7777777777???JYPB##&&&@@@@@@@@@@@@@@&&&&&&P~                                                    //
//                                                                      .?G#&@&&#?!77777!!!!!!!!!!!!!!!!!!!!!!!!!!!777777777??JYYYYY5PGB#&&@@@@@@@@@@@@&&&&&&&P7                                                  //
//                                                                   .755PGBB###BY?77777!!!!!!!!!!!!!!!!!!!!!!!!!!!77!!!7777????7!!?J?J5GB#&&&&&&&&@&&&&&&&&&&BJ.                                                 //
//                                                               .^~?GBBGGGGGPGPPGGP55YJJ?777!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!77775GGGBBBB#####&&&&&&&&&&&BPY7:                                               //
//                                                         :^!?YPGGGGPP55PPPPPPPPP5PPPPGG5YY?7!!!!!!!!!!!!!!!!!!!!!!!!!!!!!7YYJY555Y5PP5PGP5PBBBBBBBBBBB#######&&&#PJ~::::                                        //
//                                                 .^^^~7YPGGGGGPPPP5555YYYY555555555YYYJYY5PP5?777!!!!!~!!!!!!!!!!!!!!!!7?J5GPJ?JY5YYY5GG55PPGGGGGGGGBBBBBB##B##BBB##BBBGJ!!!~~~!77??!~:.                        //
//                                              :!YPBBBBGGGPPPPP555YYYYJJJJJJJJJYYYYYYYYJJ???JYYY5YYJ7777??77!!7777!!!77JY55PPJ?JJJJJY5PGP5P55555P5PPPPPPPGGGGGGBBBBBGGGG#PJJJ???777????7!!7~.                    //
//                                           .~YGBBBBGGGPPP5YYYY55YYYYYJJ??JJJJJJJJYYYYYYYYJ??7?JY5PP5YYY55Y?JJYYYYYJYY555555J??JJJJJY5PP55Y5PPP55555555555PPGGGGBBGGGGGGBP7JJ??5J?JYYJJJJJJJJ7!^.                //
//                                 ...:^~~~!JGBBBGGGPPPP55YJJ?JY5Y5YJJYJ??7777??JJJYYYYYYJJ??J??JJJYJJ5YJJJYYYJJJJ?JY5YJJJJJ???????JY5PP555Y5PP55555YYYYY555PGGGGGPPPPPGPPB5JYJYP5?777777777777?JJ                //
//                            :~7JYYYY55Y5P##BBBGGGPPPPP55YJJ??J?JPPYJJJ??77!77777?YYYYYYYJ?7777?JYY??Y55YJ?777777???J?????????JJ?JY5PG5YY55555555YYY5YY5555PPPPPPP55PP555B##P55YY77777!!!!!!!!!7^                //
//                         .^?YYY55YJY55PGBBBBBGP55555555YJJJJJJ7?P5!!7???JJ?777777JJJ??JYYJJ?777?JYYJJY555YJ?7?YBB#B??777?Y7?JYJ?JYPG5YY555555YYYYY55555PPPPPPPPPP5555P5PB##BY!!7777777777!!!!!7:                //
//                        ~5JJJ55PP5JJY5GBGGG5JY?JJYY5YYJ???777!!!7YY?!7?77JYYYJ777??????7???????77?JYYYYYYY55Y??5GBGYJ?77YJ!J55?JJ5G5JY5555YYYYYY55555P5YY5P55555555555PPPGBG5!777777777?????Y?5PJ7~~^.          //
//                       ~GG5J?J7?Y55PYY55YY???JYYJJJJ??777!!!!!!!!!?J?7JJ!7?JYY????7???77?????JJYJ???J555YJJY55Y?777?JJ?J5!75PJ??JGPJJY5YYYYYYYYY5555555Y?7J55YYYY55YY5555PPJ577!!!!!!!!!777?G#####BGPY7:        //
//                       :JGG5JY5?J5JYYJGBG5??Y55J???7777777!!777!!!!!7??Y??77?J???7777777777??JYP5YJ??JJYYJJ??JY5YJ77?JJYJ!YG5???55J?J5YYYYYYY5YYY5555555YJYYYYYJJJYYY5PP5Y5Y??777!!!!!!7!!75######GP55YY^       //
//                       JGBGGGPG5Y5YJY5YPGGJ77?YJJ??777777777?J??777!!7?JYY?7777!!!!!!7777777777?Y5P5YJ???JJYJJJY555PGP5J!?GGY?7YY??J5P5YYYJJY555555555555YYYYJJJ??J5J7777JPGY??777777!!!7YB######BPJJY5P?       //
//                  .:::~GGGGGGBBBBG5YJPGY??????777?77?????JJJJJJ?J777???????JJ777!!!!!!7!!77???7!!77JYPGPP5YJJJY55JJJPBPY!YBPJ?JJ???555YJYYJ?77?JY55555555YYJJYJ???55P5YJ?55YJJ??77777!?PB####BBGGG5J?YYYJ       //
//             .:~!7????J????J5PGGBBBBBGGBGY7!777?JJJJJ??JJJ?J???7!!7?YP55YJ?JJ?777!!!!!!!!!!!!77???777?J5PGBBGPYJYYJ?77JJ?PG5JJ?777JY77?JYYJ77!!7?Y555YYYJJJJJJYJJYYY555Y5J7JYYJJ?77!75B#####BGPYJJJ??YBG5:      //
//          :!7?????????77777777JY555555PPGBG5?77??JYPGGGGB5??????777?J5GGP5YJ?777!!!!!!!!!!!!!!!!77????????J5GB#BG5JJJY?7JY5YJ77!7??!!77????77!!!!?JJYJJ??JJYJ?JY5YJYY5PBB5JJ555JJ??YG######BG5J??77!7?55:       //
//         .JJ777777??77777777???????77?JJ?Y5GGPY7!777?J5PGBGGGGGG5J7777J5PGP5JJ?77!!!!!!!!!!!!!!!!77777?JYYJ??J5GB##G5JYYJYPY?7!7?7!!!77?JJ?777!!!!!77?JJY5PPY7?JYJY5P5YPPYJ5GBBG5GBGP5PGBGGP5J???77777777^      //
//          ~5J???????????77777777!777??777JJYY5GGPJ777777?5PGB####BPJ?77J5PP5Y?7777!!!!!!!!!!!!!!!7777777?JY55YYYYJYPBBPJJJ5G5JJY?!!!!!!77????7777!!!!!7?5GGGP5YY5PGP?!7P5Y????JYJJJYYJYGGP55Y?77777777?YBB~     //
//           ?B5YYYPY?777777!!!7!!!7???77?Y5JJJJYPGB5J?77777JJJ5555PGBBP5Y5PPP5J??J??7!~!!!!!!!!!!!!7777?777???JY5PP555B#BPJ?PB5Y?!!!!!!!!!!!7??JJJ?77!!77?YJ??JPB##GY775P5YJ??777!!!!!J###BPYJ??777!!7JG###5:    //
//           :GBP5YYPG5J?77777!!!!7777777?5JY55Y?7?Y5Y5YJY?7??7?7777?JYGB55PPPP55YYY?77!!!!!!!!!!!!!!!!!!!~!!!77?JYYYJ7JYYPBGYYYYJ7!!!!!!!!!!!!7?JY555YJ777!7?JJJ5P5JJ5GBGPY????7777777G###PJ77777??YPGB####P!    //
//            ~BBGP55GBBPYJ??7777777777777JJ7?J5Y777??YPGGBY?J77?JJJ???5JJJJ5P5YY?777!77!!!!!!!!!!!!!!!!~~~~~!!!77????7????YGBPJJYJ?!!!!!!!!!7?JJJJJJJ?77?JJJJJJJJYJ?YPBBGPJ?777???7JPG##B5777?J???5B#####G7.     //
//             ^5BBGPPGGBBPY??7?77777777777Y777YYY?7JJ777J5GPY??5BBBG5YJ55J??J???7!!!7?????777!!!!!!!!!~~~~~~~!!777777??????YPPGGGG5!!!!77777JYJ???????Y55YYJJJ?77JYYY5B#GPPYJ77???JB#BB#GY????7?YG#####P7.       //
//               !PBBPPPPGBBPY???JJJ????777?J77YJ?YYYY?77???5GGBBG5YPB#BGGGPP5JJ?7!!!7?Y5Y?????777777!!!!!!!!!!!!!7J????JJYPPGPB##B5JJ???J55PP5J???JJJYYJ????77?JJY5PPPG#GPPYJJ???5P5J?5GGY7!!7YPB#P5Y?^          //
//                .!PBBP55PGBBPYJJJ????JJJY5PPYJJ!7YYY??77777J555J777?PBBGP5PGP5J??????77777???77???JJ??77!!!77777?JJJ??JY5GGGBBB#BG5YJJJ?77?J55YYJ?7777?J??YYJY55555555BG55YYYYYYJ7!!?5Y?!7J5PGB#5               //
//                  .~?5GG5PGGGBG5YJ????JJJY5PBGY5B5?JY7777777777!77777JPGPYGP?7??????J???7777777777???!!!!!!!!7777??????JJYY5G##PYYJJJ?JJ7!7?J??YPGG5YYYYJ?JJYY5555PP55G#P55PPY?7!!7J5GY?YPGB####P:              //
//                      :YBGPPPGBBG5YJJJ?JJ5BPPPGBBPJYP?777777!!!!!77777?YP5P57!77!!!!7777777777??77??J7!!!!7777!77?JJY5YYJYPPG#B5J777JJY55YJJ5GBBGPPG5?777??JYY555PPPP5P###BPJ777?5GP5JYPBB####BJ!:              //
//                       .JPBBBGGBBBGPP5YPB##BPYY5Y55GGJ!!!77!!!!!!!!!77?JJYPJ!!!!!!!!!!!!!!!!77??77?????????JJJJJJYY5PPPPPGGBBB##BGJYPGGGGGGGGP5J?777777???JJYYY55PPPPPG#BPJ??JYGBBP55G########5                 //
//                         :~!7YBBBBBBBBB###&&#GPBBBPGPYJJJ??77!!!!!!!!77JYYPJ77!!!!!!!!!77!!!!777!7!!!7777777777777777?????JJYYYB########BBGP5J??77777777???JJYY55PPPPPGBP55PGP5BBGGGB#####BBBB5.                //
//                             .PGGGGGGGGPPPGGBGGGP5PBGB####BBGPP5YJJ?777JJJYJ777!!!!!!!77!!!!!!!!!77777777777777777777777??YGGG5J5PGGP5YJ??7777777777777?????JJYYPPGPPB#######GGBGGGPPPPPPGGGGBG:                //
//                           !YPGGBBBP555YJJ?JYYYY55PPGGGBBBBBBB##BB##BGP5Y557777!!!!!77777!!!!!!!!!7777777777777777777777??5B##P7????777!!!!!7!!7777777????JJJJ5PGGGGG######BGPYJJ?????JJY55PPPG~                //
//                           .:~JBBBBBBBBBGGPP55555555YYY555PPGGBBGB######BGJ777777777777777777777777777777777777777777777!777JYJ??77777777777777777777???JJJJJYPGGGGB#####BP5J?77777777???JJY55PY                //
//                              !PGGGGPPP5YJJ????7777777??JJY55PGGBB#BBBGGPY????777777777?777777777777777777777777???7777777!!7YJ?????7777??77777777777??JJJJJYPGGGBB####BGPYJ?77777777777???JYY5P.               //
//                              ?PP55YYJJJ?777777777777777??JJYYYPBBBP5YJJJ???????7777????????777777??77777777777777????????JJJ5JJJJ????????77777??????JYYYY55PPGGB??&##BGPYJ?7777777777777??JJY5P7               //
//                             .JYYYJ????7777777777777777???JYYY5BGPPPPYJJJ??????????JJ?J????????????????????????????????JJB##&GJJ?777???JJJJJJJJJ?JJJJJYYY5PPGGBB! :##BGPYJ??77777!!7777777??JJY55.              //
//                             :JJJJ???77777777777777777???JJY55?YBP5YYYJJJJJJJJ?????J?????????????????J???????JJJJJJJJJJJJ5PGBGYJJJYYYYYYYYJJJ???JJJ??JJYPGBBB#5:   Y#BP5YJ?7777777!!777777???JYYP?              //
//                             ~JJJ???77777!!!!!!77777???JJYY55J  JBG5YYJJJJ??JJJ????????J?????????????J????????JJJJJJJJJJYY??J??JJJ?????????7???JJJJJJ5PBBBBBB?     ^BGP5J??7777777777777777??JJY5P^             //
//    ::^^~!!7???JJJJ5555555P55GBGGGGGPP555P5YYYYYYYYYY55555PPY.   ^5GP5YJJJJJJJ??JJ??????JJ????????????J???????????777777777?J7777777777777????JJJJY5GBBBBBBG~       ?BP5YJ?77777777!7777777???JYYPJ             //
//    GBGB#####&&&&&BG#GBB##G5GB&&&&&Y????JP#&&BGPG###GGGB####G55YJ??G#BGPYYYYYJJJ??????????J????????????J??JJJJJJJJ?????JYGGBG?7777                                                                              //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SELFIE is ERC721Creator {
    constructor() ERC721Creator("SELF PORTRAIT", "SELFIE") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x80d39537860Dc3677E9345706697bf4dF6527f72;
        Address.functionDelegateCall(
            0x80d39537860Dc3677E9345706697bf4dF6527f72,
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