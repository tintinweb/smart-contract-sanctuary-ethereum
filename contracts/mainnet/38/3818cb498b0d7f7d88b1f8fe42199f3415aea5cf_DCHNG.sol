// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dancheong
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                   YJ:                                                  :JY                                                   //
//                                                 .JBPPY?~:...                                    ...:~?YPPBJ.                                                 //
//                                               .7PP5555PPPP55555YYJ7~:                  :~7JYY55555PPPP5555PP7.                                               //
//                                             ^?PP555555555555555555PPP5?^     ..     ^?5PPP555555555555555555PP?^                                             //
//                                           !5GP555555555555555555555555PG5!~7??JJ7~~5GP55YY55555555555555555555PG5!                                           //
//                                         ^PG5555555555555555555555555555PPJ777?????YPP55PPGBBBGGP55555555555555555GP^                                         //
//                                        !B5555555555555PPPGGGGBBGGGP5PG57~7?JJJJJJJ?7?5##########BBBGPPP555555555555B!                                        //
//                                       ^#5555555555PGB##############&G!~7JJJJJJJJJJJJ?!7G&#############BBGPP555555555#^                                       //
//                                       YGY555555PBB################&J~7JJJJJJ?JJJJJJJJJ?~J&################BGP555555YGY                                       //
//                          .:~~!!!!!!!~^PG55555GB###################7~JJJJJJ?JYYJJJJJJJJJJ!7#&#################BP55555GP^~!!77777!~:.                          //
//                         ?J?77!!!!!77777?JY5P#####################!!JJJJJ?JYPGGP5JJJJJJJJJ!!&#################&#GPP5YYJJJJ???JJJYY55?                         //
//                        !5~??JJJJJJJJJ???7!~~!?YG#&#############&77JJJJJ?J5GGGGGPP55JJJJJJJ!7&############&&#BP5J??????JJJJJJJJJ???JB!                        //
//                        P~?JJJJJJJJ?JJJJJJJJJ?7~^~75B&#########&5~JJJJJJYPGGGGGGGGGPYJJJJJJJ~5&#########&BPYJ????JJJJJJJJJ?JJJJJJJJ?5P                        //
//                       .G^?JJJJJJJJJJJJJJ????JJJJ?!^^!5#&#######~?JJJJ?5PGGGGGGGGGGGGYJJJJJJ?~#########P?7??JJJJ????????JJJJ?JJJJJJ?JB.                       //
//                       .G:7JJJJJJ5PGPPPPP55YYJJJ??JJ?!^^?B&###&5~JJJJ?JPGGGGGGGGGGGGGP5JJJJJJ^5&###&BJ77?JJ???JJJYYY55555PP5JJJJJJJ??B                        //
//                        5~7JJJJJJ5GGGGGGGGGGGGP55YJJJJJ?~:?##B&77JJJJJ5GGGGGGGGGGGGGGGGPJ?JJJ~7&##BJ!7JJ??JJY55PGGGGGGGGGGGPYJJJJJJ!?5                        //
//                   .:^~~YY^JJJJJJ?5GPGGGGGGGGGGGGGGP5JJJJ?~^5&&!7JJJ?YGGGGGGGGGGGGGGGGGG5JJJJ~~&&P77JJ?JJ5PGGGGGGGGGGGGGGPG5JJJJJJJ~5Y~~^:.                   //
//               .!J5PPPPPPB~?JJJJJJ5GGGGGGGGGGGGGGGGGGGPYJJJ7^[email protected]~7JJJ?5GGGGGGGGGGGGGGGGGGGY?JJ^[email protected]?JYPGGGGGGGGGGGGGGGGGGG5JJJJJJ?~#PPPPPP5J!.               //
//             :JPP5555555YPP~JJJJJ?JGGGGGGGGGGGGGGGGGGGGGPYJJJ7G77JJJJ5GGGGGGGGGGGGGGGGGGGY?JJ^!#?JJJYPGGGGGGGGGGGGGGGGGGGGGJ?JJJJJ~PPY5555555PPJ:             //
//           .JGP55555555555BJ!JJJJJJ5GGGGGGGGGGGGGGGGGGGGGG5JJJ5Y~JJJJPGGGGGGGGGGGGGGGGGGG5?JJ:Y5?JJ5GGGGGGGGGGGGGGGGGGGGGG5JJJJJJ!Y#55555555555PGJ.           //
//         .7GP55555555555PGB&J~JJJJJJPGGGGGGGGGGGGGGGGGGGGGGPJ?JB^?JJJPGGGGGGGGGGGGGGGGGGG5?J7:BJ?JPGGGGGGGGGGGGGGGGGGGGGGPJJJJJJ~J&#BP55555555555PG7.         //
//       ^?PP55555555555PB####&J~?JJJ?JPGGGGGGGGGGGGGGGGGGGGGGPJ?PY^JJJ5GGGGGGGGGGGGGGGGGGGY?J^YP?JPGGGGGGGGGGGGGGGGGGGGGGPJ?JJJ?^Y&####GPP5555555555PP?^       //
//    :5PPP555555555555P#######&P~7JJJ?J5GGGGGGGGGGGGGGGGGGGGGG5??G?~J?YPGGGGGGGGGGGGGGGGP5JJ~?G??5GGGGGGGGGGGGGGGGGGGGGG5J?JJJ!~P&######B#G55555555555PPP5:    //
//     ^PPY555555555555B########&B7!?JJ?JYPGGGGGGGGGGGGGGGGGGGGPY?JGJ?55GGGGBBGGGGGGBBGGGG55??GJ?YPGGGGGGGGGGGGGGGGGGGGPYJ?JJ?~7B&##########G5555555555YPP^     //
//       YG55555555555G###########&P77?JJ?J5PGGGGGGGGGGGGGGGGGGG5JJPGY???????YGBGGBGY???JJJJYGPJJ5GGGGGGGGGGGGGGGGGGGP5J?JJ?!!P&#############G555555555GY       //
//       .BP5555555555B##############P?7????JYPGGGGGGGGGGGGGGGGG55G?!7YPGGGG5J7J##J7?YPGGGGPY7?G55GGGGGGGGGGGGGGGGGPYJ?JJ?77P#################P5555555PB.       //
//        YG555555555P#################G5YJ???JJY5PGGGGGGGGGGGGGBB!!JGGGGGGGGGGJGGJGGGGGGGGGGG7!BBGGGGGGGGGGGGPP5YJJ?????YG###################G5555555GY        //
//        7B555555555P####################BG5YYYYJJJYY5PPGPPGGBB#P~7GGGGGGGGGGGG#BGGGGGGGGGGGG?~P#BBGGPPP55YYJJJYYYYY5PGB#####################B5555555B7        //
//        ^#555555555G#####&&#BG5YJ????????????J?JJYY5YYJJ5G5Y???YPYPGGGGGPGGGGG&&GGGGGPGGGGGPYPY77?J5P5JJYY5YJ??77!!!!!!!!!777?Y5GB##########B5555555#^        //
//         BP55555555P####GY?7!!77????JJJJJJJ???????77?J5G57?YY555PB##GGGGGYGGGG&&GGGGYGGGGGB#BP5YYJ?775G5?!~~!77????JJJJJJ????77!!!!?YG#&####B555555PB         //
//         ~B55555555GB5?!!7??JJJJJJJ???JJJJJJJJJJYJJJJ?GJ!PGGGGGGGGB#&#BGGPJPGG&&GGPJPGGB#&#BGGGGGGGGP7JP!?JJJYJJJJJJJJJJ?????JJJJJ??7~!?P#&#G555555B~         //
//          !GP5555G5?~!??JJJJJJ???JJYY55PPPPGGGGGGPPPPGG!YGGGGGGGGGGGB#&#BGPYPP##PPYPGB#&#BGGGGGGGGGGG5!GGPPPPGGGGGGPPPPP555YYJJJJJJJJJ?7!~?GG5555PG!          //
//           :YG5GP7~7?JJJ?JJJ?JJY5PPGGGGGGGGGGGGGGGGGGBG!JGGGGGGGPPPPGGB#&#5?!~~^~!?5#&#BGGPPPPGGGGGGGJ!GBGGGGGGGGGGGGGGGGGGGGPPYJJ??JJJJJ?!:!PG5GY:           //
//             ~BJ!?JJJJ?JJJJJY5PGGGGGGGGGGGGGGGGGGGGGGG#J!JGGGGGGGGP55555G7^^^^^:.. .!G55555PGGGGGGGGJ!J#GGGGGGGGGGGGGGGGGGGGGGGPP55YJ?JJJJJ?~:JB~             //
//            .Y?7JJJJY555PPPPGGGGGGGGGGGGGGGGGGGGGGGGGGG#5??5GGGGGGGGGGYG~^^^^^^^^^.  ^GYGGGGGGGGGG5??5#GGGGGGGGGGGGGGGGGGGGGGGGGGGGP5JJJJJJJJ?^!Y.            //
//            75~JJJJJ?JYPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGB#P5GB#########P:^^^^^^^^^. . P#########GG5P#BGGGGGGGGGGGGGGGGGGGGGGGGGGGPGGPPJ?JJJJJJJ~57            //
//            .Y7~JJJJJJ?JJ5PGGGGGGGGGGGGGGGGGGGGGGGGGGGG#577YPGGGGGGGGGYG~^^^^^^^^:.. ^GYGGGGGGGGGP5??5#GGGGGGGGGGGGGGGGGGGGGGGGGGP5YJJJJJJJJJJ!?Y.            //
//             ~BJ~?JJJJJJ??JJYPPGGGGGGGGGGGGGGGGGGGGGGG#J~JPGGGGGGGP55555G7^^^^^:. ..!G55555PGGGGGGGGJ~J#GGGGGGGGGGGGGGGGGGGGGGGPYJ????JJJJJJ7~JB~             //
//           :YG5GP?7?JJJJJJJ??JJY5PPGGGGGGGGGGGGGGGGGGBG~?GGGGGGGPPPPGGB#&#5J7!~^^!?5#&#BGGPPPPGGGGGGGJ~GBGGGGGGGGGGGGGGGGGGGP5YJ?JJJJJJJJ?!^7PG5GY:           //
//          !GP5555GPJ77?JJJJJJJJJJJJYY55PPPGGGGGGGPPPPGG!?GGGGGGGGGGGB#&#BGPYPP##PPYPGB#&#BGGGGGGGGGGG5~GGPPPPGGGGGGGPPPPPPP5YJ?JJJJJJJ?7~^?PG5555PG!          //
//         ~B5555555PGGPJ????JJJJJJJJ????JJJJYYYYJYJJJJ?GJ!5GGGGGGGGB#&#BGGPJPGG&&GGPJPGGB#&#BGGGGGGGGP7JG7?JJJYJYJJYYJJJJJJJJJJJJJ?7!~^~75G#BP555555B~         //
//         BP555555GBBG###G5YJ???????JJJJJJJJ?????7777?J5G57?Y555PPGBBGGGGGYGGGG&&GGGGYGGGGGBBGP5555Y??5G5?7!~!!77???????????77!~^^^~7YG###PGBP555555PB         //
//        ^#5555555B##########BGP5YYJJ????????????JYYYYYJJ5P5J???5PYPGGGGGPGGGGG&&GGGGGPGGGGGPYPY??JY5P5JJJY5YJ?7!!~~~~~~^^~~!7?J5GB######BGBBG5555555#^        //
//        7B5555555G######################BG5YYYYYJJJYY5PPPPGGBB#P~?GGGGGGGGGGGG##GGGGGGGGGGGG?~P#BBGGPPP55YYJJJYYYJ??YG##############B##BBGGGG5555555B7        //
//        YG55555555###################G5JJJ??JJY5PPGGGGGGGGGGGGBB!7GGGGGGGGGGGYGGJGGGGGGGGGGG7!BBGGGGGGGGGGGGPP5YJJ?7!^~JG&##########B####GGBB5555555GY        //
//       .BP55555555P################P?7????JYPGGGGGGGGGGGGGGGGG55G?7YPGGGPP5J7J#B?7J5PGGGGPY7?GGPGGGGGGGGGGGGGGGGGPYJJJ7~:!P&##########B#BGBBG5555555PB.       //
//       YG5555555555B############&P7!?JJ?J5PGGGGGGGGGGGGGGGGGGG5JJPGYJJJ?77?YGBGGBPY?77???JYGPY5GGGGGGGGGGGGGGGGGGGGP5JJJ?!:~P&##########BGBBP55555555GY       //
//     ^PPY55555555555B#########&B?!?JJ?JYPGGGGGGGGGGGGGGGGGGGGPY?JGYJY5GGGBBBGGGGGGBBGGGG55?JGJYPGGGGGGGGGGGGGGGGGGGGGPYJ?J?~.7#&#######BPBBP555555555YPP^     //
//    :5PPP555555555555G##B####&P!?JJJ?J5GGGGGGGGGGGGGGGGGGGGGG5??GJ7J?YPGGGGGGGGGGGGGGGGPY?J7JGJYPGGGGGGGGGGGGGGGGGGGGGGPY?JJ?^:P&#####BGBBG5555555555PPPY:    //
//       ^?PP55555555555PB##B#&Y!?JJJ?JPGGGGGGGGGGGGGGGGGGGGGGGY?P57JJJ5GGGGGGGGGGGGGGGGGG5JJJ!5P?JPGGGGGGGGGGGGGGGGGGGGGGG5JJJJ!.J&###BBBBP555555555PP?^       //
//         .7GP55555555555PBB&J!JJJJJJPGGGGGGGGGGGGGGGGGGGGGGGY?JB~JJJJPGGGGGGGGGGGGGGGGGGPJJJJ!BJ?JPGGGGGGGGGGGGGGGGGGGGGGGPYJJJ7.?&#B#BG555555555PG7.         //
//           .JGP5555555555YBY!JJJJJJ5GGGGGGGGGGGGGGGGGGGGGGPYJ?5Y!JJ?JPGGGGGGGGGGGGGGGGGG5JJJJ755?JJ5GGGGGGGGGGGGGGGGGGGGGGGGYJJJ?:J&BGP55555555PGJ.           //
//             :JPP5555555YPP!JJJJJ?JGGGGGGGGGGGGGGGGGGGGGP5J?J?B??JJ?YGGGGGGGGGGGGGGGGGGG5?JJJ??B?JJJYPGGGGGGGGGGGGGGGGGGGGGGPYJ?J?^PG55555555PPJ:             //
//               [email protected][email protected]?JYPGGGGGGGGGGGGGGGGGGGGG5Y?JJ?~BPPPPPP5J!.               //
//                   .:^~~Y5!JJJJJ?JPGGGGGGGGGGGGGGGGG5YJ?JJ?JG&&!?JJJJPGGGGGGGGGGGGGGGGGPJ?JJJ?!&&P!7JJ?JJ5PGGGGGGGGGGGGGGGGGGPJ?JJJ^YY~~^:.                   //
//                        5!7JJJJJYPGGGGGGGGGGGGGGP5YJ??JJ??5###&?7JJJ?YGGGGGGGGGGGGGGGGGY?JJJJ7?&#&BJ~!?JJ?JJY5PGGGGGGGGGGGGGG5JJJJJ!~5                        //
//                       .G:7JJJJYPGGGGGGGGGGPP5YJJ??JJ??7YB####&5!JJJJ?YGGGGGGGGGGGGGGGYJJJJJJ!5&###&BJ~!?JJJ?JJJJYY555555PGGPYJJJJJ7:G.                       //
//                       .G:7JJJJJYPPPPP55YJJJJ??JJJ?77JP#########~?JJJJ?YPGGGGGGGGGGGGY?JJJJJ?!#######&#57~!?JJJJ?????J?JYPP5J?JJJJJ?:G.                       //
//                        P~!JJJJJ?JJJJJ???JJJJ??7!7JPB##########&5~JJJJJ?J5GGGGGGGGGGY?JJJJJJ!5&#########&B5?!!7??JJJJJJJ5YJ??JJJJJJ7!P                        //
//                        !5^?JJJJJJJJJJ???77!!7?5G#&#############&7!JJJJJ?JYPGGGGGGGY?JJJJJJ7?&###############G5?7!77??????JJJJJJJ??7P!                        //
//                         ?JJJ?777!!!!777?JY5B#############B#######77JJJJJJ?JYPGGGGPJJJJJJJ77&####################BPYJ?77777777!!77?J?                         //
//                          .:~!!7777!!~^PG5555PB####################7!JJJJJJJ?JYPGGY?JJJJJ77####################BGP555GP^~!!!!!!!~~:.                          //
//                                       YGY555555PPGBB###############J!?JJJJJJJ?JYYJJJJJ?!Y&#################BGP55555YGY                                       //
//                                       ^#555555555555PPB########BBBB#G7!?JJJJJJJ??JJJ?!7G&##############BGPP555555555#^                                       //
//                                        !B555555555555555PPPPPPPPPPP55G5?7??JJJJJJJ?!7P###########BBBGPP555555555555B!                                        //
//                                         ^PG5555555555555555555555555555PG5JJJJ????YPPP5PPPPPPPPPP5555555555555555GP^                                         //
//                                           !5GP555555555555555555555555PG5~~?YYJ?7~!5GP555555555555555555555555PG5!                                           //
//                                             ^?PP555555555555555555PPP5?^     ..     ^?5PPP555555555555555555PP?^                                             //
//                                               .7PP5555PPPP55555YYJ7~:                  :~7JYY55555PPPP5555PP7.                                               //
//                                                 .JBPPY?~:...                                    ...:~?YPPBJ.                                                 //
//                                                   YJ:                                                  :JY                                                   //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DCHNG is ERC721Creator {
    constructor() ERC721Creator("Dancheong", "DCHNG") {}
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