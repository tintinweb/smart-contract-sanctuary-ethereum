// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AFIFWM
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                   .:!J5    //
//                                                                                                .^7Y555Y    //
//                                                                                             .:7Y55YJJJJ    //
//                                                                                          .:7Y5555YY5YYY    //
//                                                                                        .!Y5P555YJJJJJJY    //
//    ^.                                                                               .~J5P555Y5555YJJY55    //
//    ?7!~:.                                                                         :?5PPP555YYYYYYY55YYY    //
//    77???7!^:.                                                                  :!YPPPP55Y555YY55555555Y    //
//    ??7?7?????7~:..                               .:~7?7!~:                  :!YPGPP5P55P5YY555PPP555555    //
//    ?7!7??J?77?JJJ?7~^..                       .:~?YPGP55Y7~^.            .~YPGPPPPPPP555555PP555PP5555Y    //
//    !7??777?????JJ??J??7!^7^.                .:^?Y555Y555YJ55J!.       :JY5GPPPPPPPP55P5Y5PPPPP555PP555Y    //
//    Y?7!!?J?777?J?777777!:7?:.               ..7YYY55555PPPPPP5Y^     .5P5PPPPPPPPPP5555YPPPPPPP5555P555    //
//    YJJJ??!!7?YJ?77!!7~!~.~:..             ..:75J?J55PPPPPPP555YY:    .!JJ55PP5P555PPPPP5YPPPPPPP5555P55    //
//    Y5PY!??J?JJ77!!!~~~!^.:..              ..?5YJ?JY55Y55555YJ??J^     .!JY5555555PPPPP5P5YPPPPPP55YYYYY    //
//    YPY77J???JJ??7!~~^^^::^..          ..::^75YY??JYYJJJJ?YYJJ7!^.      :JYY5555555P55PP5555PPP5P55YJJJJ    //
//    5YJJ???JJ???7!!~~^:^~^^:..          .:7Y555J?77?YJ?JJ?J?!!^!:       :Y55555555PP5555555555555555555Y    //
//    J?????77777??7!!~~!7!~^~::.     . .:!J55Y55JJJ?J5YY5P???::!Y:       !P555PP555YYYYY5555PP555YYYYYYYY    //
//    ??????77!!~^^~!!!~!!!!^~!^:. ..!777?Y555555YJ5Y??YY5Y~~^^Y5P^      :5P555P555555YYY5PPPPPP55555YYYYY    //
//    ???JJJJJ77777??7777!~~^:~7~^..^5PY5PP5555P5YJYPJ77?J7^:!5PPP.     :5P55P5PPPPPP555PPPPPPP555555YYYYY    //
//    ?????JJJJ???J??JJ??7~!!~^!7!~^:7PPPP55PPPP55YJ555YJ?~?JYPPP5.   .~5P55PPPPPPPPPPPPPPPPPPPP55555555YY    //
//    ?JJJJ?JJJJ????J?77777!!!!~777!!?Y5555P5555YY5555555YY5J7PPP5. :!5PP55PPPPPPPP55PPP555PPPP55555555555    //
//    J???????????JJ?777??~!7~777~!777Y5YY?~?5PYYY555YJJJ5PYJ!J5Y5?7YPP55PPPP5PP555PPPPPPPPP555555555555YY    //
//    ??JJJ?JJYYYYJJJJJ?7!7???7????J??J7JY?JPPPP5P55YYJYY5PYJ77PJ555YJYPPPPPPPPP5555PPPPPP5555P5YYY5555555    //
//    ?777!7JJJJJJJJJJJ?????????J?7?J?JJ55YPP5YP5P55555YY55?Y!^P!P55PJ75PPPPPP555PPPPPPPPPP555PJ:. .~J55YY    //
//    .  :~?JJYJJJJJJJJJ????JJJJJYYYJYJYP5YYPYJ5PPPPYY555P5!Y7:Y~5555?^?5PPPPPPPPPPPPPPPPP5555??~     .~JY    //
//      .^!7JJJJJYJ??JJJJJJJJJJJYY555P5555P55J75PGGGP55PPY!?J?!~!?JYYJ?J!YPPPPPPPPPPPP55555PP5?:         .    //
//        :7?JJJJ?JJJJ???JJ77??J5555PYJ5PPGP5Y!YPPPPPGP?!7?5577!^~^Y5Y55J5P555555555555PPPPPPY~.              //
//         :7JJJJJJ???JJ?77??JYJYYY55?!YPP555YYYY5PPPY!?55?JGG77?7^??PPYJJYP55555555555555??JJ!               //
//         .::::7JJJJJ?77?JJYJJJY5Y55Y7Y555YJ5PPPPPY7~?GPY7JP5!5???!^?Y5J!!555555555555PPP7                   //
//             .!7J?7??JJYYJJJY5Y~~5PYJ5P5JJYPPPPY77YY?P5Y7YP?5P?7??7!?PJ!!5555PPPPPP555Y7~                   //
//                :~YYYYYJJJYY?:. JY5PPPGJYGPPPP!!?5J5Y5PY7555PJ5J~7J?7YY~!755PPPPPPPPY!~                     //
//                .77?YJ??Y?~.   .~.7PPPPYPGGPPPJYY55J5Y5YJPYPY5J7?7J7?J?:~JJPPPPPPPPPP!                      //
//                  .!~..:.         .7PPPPPP555YYYPY5JYJY?JYYYYY?!7Y?!~77~^..:75PJYPP~^:                      //
//                                   .^!?J??J7^JJYJ??J??JYY?JJJ?JJ!??!:!!:     .^: :7^                        //
//                                     .:^~!!^^Y5P55JJJY557JY?5JJ??JJ?^:.                                     //
//                                         .?5PGP5YYY55YY7YGJJ5JYYJ5Y?.                                       //
//                                       .7PPPPP5YPP55YJ?5GPJJYJ55Y5PJ^                                       //
//                                      ~5PPPPP55PPYY5JJ5PGYYJYYP555P57.                                      //
//                                    .?PPP5PPPPPP555YY5PGPJ5YJPGY555PY^                                      //
//                                  .^YPP55PPPPPP5PPY5PPGGY5PYYPPY5555P!.                                     //
//                                 :?5P5Y5PPPPPPPPP55PPGG5JPPJ5PPY5555P!:                                     //
//                              .^?5P5Y5PPPPPPPPPPPPPPPGPJ5P5YYY5J555Y5?^                                     //
//                           .^7YPPPYY5PPPPPPPPPPPPPPPGGYJPP55!YY?555YYJ~.                                    //
//                         .~J5PPPYJ5PP5PP5PPPPPPPPPPGG5?5PPY?7P!J555YYJ!.                                    //
//                       .!YPPPP5JYPP55555PPPPGGGGPPGGP7?YP5J!5J~Y555YYJ!.                                    //
//                     .75PPPP5JJ555555Y5PPPPGGGGPPGGP!7JJPJ!7Y7J5555YY?~                                     //
//                   .7PGPPP5J?Y5YYY5PYYPPPPGGGPPPGGP7~J?557^?JY5555YYJ7:                                     //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AF is ERC721Creator {
    constructor() ERC721Creator("AFIFWM", "AF") {}
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