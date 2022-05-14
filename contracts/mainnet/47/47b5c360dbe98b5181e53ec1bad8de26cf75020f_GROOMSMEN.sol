// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Glorious Wedding of Taylor & Ben
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                        :^~!?JJYYY55YYYY55Y5Y??7!~:.                                        //
//                                  .^!7JY55YJJJ?77??7!777??7777?JYYYYYJ?~^.                                  //
//                              .~?J55J????JYYYYYYJJJ??????JJJYYYYYJJ???JY55J7~:                              //
//                          .^7YP5J??JY55JJJ???JJYJYYYJJJJJYYYYJJ????JY55YJ??Y5P57^                           //
//                        :?PPY??J5PYJ?7?J55YJJ?!~~^:::::::^^^~!?JY55YJ???Y55Y??J5P57:                        //
//                     .!5P5?7JP5J?7J55Y?7^.                       .:^!J555J7?J55J7?5GY!.                     //
//                   ^?PGJ7J55J7?5P5?~.                                  .^?5P5??YPPJ?JPP?.                   //
//                 .?GP??YP57?5P57:                                          :75G5??5G5??PP7.                 //
//                7GP?75GJ?JPP?:                                                ^JPPJ75G57?GP!                //
//              ^YBJ!YGY7JGP!.                                                    .!PGJ7JGY!JGY^              //
//             7GP!?G5!?GP!                                                         .7PG?7PG7!PG!             //
//            ?BY~5GJ~5G?.                                   .:::^^::::::^:::.        .JG5!JGY~YBJ            //
//          .YB?~PG!?GP~    7555555555555555555555J.         YGPPPPPPPGGGGGPPP5J!.      ~PG7!G5~JBJ.          //
//          JB?~GP~?BY.    ?BBGBGGGPPPPPGGP5PPGGGB5.         YGPPPPGGP5555PPGPPGGP7      :YB?!PP^?BY          //
//         JG?^PP^JBJ.    :77!!!!^~5PPPPGG^ ..:^~~.          JGPPP5P5^  ...:YPP5PPG?      .JB?^GP~JB7         //
//        !B5:5G~7BJ               YGPPPPY.                  7G55PPP7       ^P55PPP5.       JG!!GP:YG~        //
//       :PG^?B7~GP.               YPPPPGY         .:^:.     7GPPPPG~       .PPPPPGP:       .PG~JB?^GP.       //
//       ?B?^GP:PG~                JGPPPGY       ~YPYYY7     !GPPPPG^       .5PPP5GP.        ~G5^PG:JB?       //
//      .5G^JB!!BY                 !GGPGG7      ~GGP.        ^GPPPPP:       ^PPPPPG?          5B!!B?^GP.      //
//      ~GY.PP:5G~                 ?GGPPG7      ?GGP.        ^GPPPP5.    ..^YGPPPG?           !GJ:GP.YP:      //
//      7B!^GY.PP.                 7GPPPG?      :GGG^        .5PPPPP.~JY555PPPPP5~            .PP:5G:7B!      //
//      7B~~B7^G5.                 !GPPGG!       JGG5.       .PPPPP5JGBGGGGPPP5PJ:            .PP ?G^!B7      //
//      ?B~:G?^BJ                  7GGPPG7       !GGGJ  .!~  .PPPPP5~^~~~!7JPPPPGP7.          .PP ?B^~B7      //
//      ?B~^GJ.P5                  7GGPPG7     .JGJGGG! 7G^  ^PPPPPP.       7G5PPPGJ           PP.JB^~B7      //
//      !B?^G5 5G:                 7GPPPG7    .YGP.7GGP!P?   ^PPPPPP.       .55555PP^         :G5.5P:?B!      //
//      ^G5.PG:JB!                 5GPPPGJ    ~GG5. JGGG5.   ^GPPPG5.       .5P55PPG!         ?B?^G5.PP:      //
//       5G^7BJ~G5                 JPPPPG5    7GGP. :PGGY    :PP5PPP.       .5P555PG~        .5G^JB7~G5       //
//       !BJ^GG^JG~                JGPPPGY    7GGP.  7GGG7   ^PPP5PP:       :PPP55PG!        ?BJ^GP:5G~       //
//        YB!7BJ.PG~              .5PPPPGJ    .5BG7.:JPGGG~  ~GP55PP~       ~P555PPP:       ^GP:YB!!BY        //
//        ^GP^JB!~GP:             .PPPPPGY     .7Y5YY7.7Y5?  7P555PP7.    .!5PPPPPG?       ^PG^?B?^GP:        //
//         !G5:YG7!GP:            .5GPPPGP:       ..         JGP55PPPPYYY55GP5PPGGJ       ^PG!!BY:5G~         //
//          7BJ:5B7~GP~           .PGGGGG5.                 .5GGGPGPGGGGGGGGPPP5?~       !PP~?BJ^5B!          //
//           !G5~JBJ~YG?.          :^^~^^:                   ^~~!!!!!~~~!!!~^^:        .JBY~JBY^PG7           //
//            ~GP~?G5~?G5~                                                            !PG?!PP7!PG~            //
//             ^5G?!YG?!YGY^                                                        ^YGY!JG5~JBY:             //
//               ?GP!7PP775G5~                                                    !5G5!?GP775G7               //
//                ^5B5~7PP?7JG57:                                              ^75GJ!?PP7~5B5^                //
//             .~J55YJ!.!PBPY!75G57:                                       .:!5G577YGB5!:~Y5P5?~.             //
//           ~YP5J?7JYY5YJ?7?^ .^75G5?~:.                              .:!JPG5?:  ~?7JJY5YY?77J5PJ~           //
//         !5GY7?55Y?7?JYYYYYYYYJJ5PPPPPY.                            :YPGGGPYJJYYYJJYYYJ77?5P5?7YG5~         //
//       .YBY!?P5?7Y55Y7~::::...::::.....                              ....::...:::..:^~7YPPY?J5PJ7YGJ:       //
//      ^PG77PP7?PGY~.                                                                    .~YG57?PP7!GP^      //
//     ^GP^?BY~5GJ^          .~7JY5Y?~.     :!?Y5YJ!:      ^!JY5Y?!:     ^!JY5YJ!:           ^YGY~YG7~GP:     //
//    .5G~7BJ^PG!           !PGJ!~!!JGP!  .?GP?~!!?5G?   ^5GY7!!!?PG7  :YG57!!~75GY.           !GP^YB!~GY.    //
//    ?BJ^GP:5G!           !BB!      ~GG^.5BJ.      JBJ :GBJ      :PG! 5B5      .PB?            7BY:GP^YG!    //
//    JG^!B7^G5            :7!       7GG^~GP:       :PB!.77:      ^PB! !?^      :5B?             5G.?B7~GY    //
//    5G:~B~!B?                  .^!5GY^ YGP.       .PGY       .!5GP!        .~YGP?              JG:!B!:G5    //
//    YG^!B?:GY               .~?PPY?^   ?GP.       .PB7    ^J5P5?^.      ^?YPPJ~.              .5G^?B~~GY    //
//    7BJ^GP:YG~            :JPPJ~.      :PG!       !GP: .75PJ~.        !5GY!:                  7BJ:PP:5G!    //
//    .5G~7BJ:PG!          ^PBY^::::::::  ^PG?^...:?GP~ :5BP!:::::^:: .YBG7::::::::.           !G5:YB!~G5.    //
//     ^GG~7BJ~5GJ:        JPPPPPPPPPPPJ.  .75P555P5!.  7PPP5PPPPPPP5:^PPP5PPPPP5PP~         ^YGY~YB7~GP^     //
//      ~PG7!PP7?PPJ~.      ...........        .:..      ............  ......:.....       .~YGP77GP77GP:      //
//       :YGY~JGP??YPPY?!~:.........................................................::^~7YP5J??5P?!YGJ:       //
//         ~YPJ7?55YJ??JYYY5YYYYYYYYYYYYJYYYYYYYJYYYYJYYJYYYYYJYYYYJYYJYYYYJYYYYYYYYYYYJ????5P5?7JG5~         //
//           ~YP5J7?JYYJJJ??JJ????JJJ????JJJ????JJJ????JJ????JJJ????JJJ????JJJ????JJ??JY5YYJ??JPPJ~           //
//             .~J55YJ????777!!77777!77777!!77777!!77777!!77777!!7777!!77777!!77777!!7????J55YJ~.             //
//                 .^7J5Y5YYYYY55YYYY55YYYYY55YYYY55YYYYYY55YYYY55YYYYY55YYYY55YYYYYY55YYJ7~.                 //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GROOMSMEN is ERC721Creator {
    constructor() ERC721Creator("The Glorious Wedding of Taylor & Ben", "GROOMSMEN") {}
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