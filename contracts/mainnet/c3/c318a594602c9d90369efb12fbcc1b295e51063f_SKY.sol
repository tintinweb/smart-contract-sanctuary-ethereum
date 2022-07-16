// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nick de Jonge Editions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    ~~~~~~~~~~~~~~^^^^^^^^^~^~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~~~~~~    //
//    ?????????????777777777??7777???777?7777!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!7777777777777777???    //
//    PPPPPP55555555555555555555555555555555555Y55555555YYYYYYYYYYYYYYYYYYYYY5555555555555555555PPPPPPPPPP    //
//    PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5PPPPGGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPGGGGGGGGGG    //
//    PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5YJ?7??7!~~~~7JYPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPGGGGGGG    //
//    GPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5Y?7!!!!!7!~~!7!!~^~~~!!7J5PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPGGGGGGGGG    //
//    GGGGPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5?!~~!!!777!!??77!~~^^^^^^:~7J55PPPPPPPPPPPPPPPPPPPPPGGGGGGGGGGGGGG    //
//    GGGGGGPPPPPPPPPPPPPPPPPPPPPPPPPJ7~!7?JJ77JJJ5PJ?7?7!~~~~^^^^^^^^75PPPPPPPPPPPPPPGGGGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGPPPPPPPPPPPPPPPPPPPJ!^!?77JJY555YYJJ?77~!777!~~~~^^~^:!YPPPPPPPPPPPGGGGGGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGPPPPPPPPPPPPPPPPPY!~!!7??JJP5YYJJJY???7777!!!!!~^^~~!~!5PPPPPPPPGGGGGGGGGGGGGGGGGGGGGGGG    //
//    GGGGGGGGGGGGGPPPPPPPPPPPPPPP5!~!?7!7!?Y5J??JJ?????????7!!!!77~^~~~~YPPPPPPPPPPPPPPGGGGGGGGGGGGGGGGGG    //
//    GGGGGGPPPPPPPPPPPPPPPPPPPP55?!77?7!777YY????JYYYYYYJYYYJ??7JJJ7!!~!JPPPPPPPPPPPPPPPPPPGGGGGGGGGGGGGG    //
//    PPPPPPPPPPPPPPPPPPPPPPPPPP5577?77J7??JY??JJJJJ???????7777!!!!!~~^^75PPPPPPPPPPPPPPPPPPPPPPGGGGGGGGGG    //
//    GGPPPPPPPPPPPPPPPPPPPPPPPPP5?JY??YJJ5YJ?J???JJ??????77777!!!~~^^:^!5PPPPPPPPPPPPPPPPPPPPPPGGGGGGGGGG    //
//    GGGGPPPPPPPPPPPPPPPPPPPPPPP577YY5P55YYJYJ!??J??7777777!!!!!!!~^^::?PPPPPPPPPPPPPPPPPPPPPPGGGGGGGGGGG    //
//    GGGGGPPPPPPPPPPPPPPPPPPPPPPY775PGYPPY555YYYJ?777!!777???7?777?J?7~?PPPPPPPPPPPPPPPPPPPPPGGGGGGGGGGGG    //
//    GGGGPPPPPPPPPPPPPPPPPPPPPP555JP555GBBGGGP5J???JYYY5PGGGPY?!!YYYPY!YPPPPPPPPPPPPPPPPPPPPPGGGGGGGGGGGG    //
//    PPPPPPPPPPPPPPPPPPPPPPPPPPPPP5Y5P5PGBBGP5???J5555Y5PPP55Y?!~7?7!^:?PPPPPPPPPPPPPPPPPPPPPPPPGGGGGGGGG    //
//    PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPY5YYPGPPP5?77777777777??JJ??7!^^^^^:!PPPPPPPPPPPPPPPPPPPPPPPPGGGGGGGGG    //
//    PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5YYP5J5G5J?77!!!!!!!!!7?J??77!^~~^::YPPPPPPPPPPPPPPPPPPPPPGGGGGGGGGGG    //
//    PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPYJJJJYPP5Y??77777!!7?JYYY5YJ?!!?7~^?PPPPPPPPPPPPPPPPPPPGGGGGGGGGGGGG    //
//    PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP55Y????J55JJJJJJYJJJYJJ?JY555?~^!J?!YPPPPPPPPPPPPPPPPPPPPPPPPPPPPGGGG    //
//    PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5Y5YYJJJJYY5G5YYYJJJJJJ????!!~!7?PPPPPPPPPPPPPPPPPPPPPPPPPPPPPGGGG    //
//    PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5P5JJYYYY5YPYJYYPGPYYJ7!!!!?7!!5PPPPPPPPPPPPPPPPPPPPPPPPPPPPGGGGG    //
//    PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPY?JJ555P555YJJJJJJYJJ?77~^~!YPPPPPPPPPPPPPPPPPPPPPPPPPPPPPGGGGG    //
//    PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP57?JY5PPPP55JJJJJYYYJJ?7~^~YPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPGGGGG    //
//    PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5PPPY7?JJY5PPP5YYJ?????????!^^7PPPPPPPPPPPPPPPPPPPPPPPPPPPPPGGGGGGG    //
//    PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5555?7??JJY555PPP55YYJJJ?7??!75555PPPPPPPPPPPPPPPPPPPPGGPPGGGGGGGGG    //
//    PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPJ!7??JJJYJYY5PGGGGGP5YJ?75PPPPPPPPPPPPPPPPPPPPPPPPGGGGGGGGGGGGGG    //
//    PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP55Y?!!7??JJJJ?JJYY5PP5Y?!~~^~PPPPPPPPPPPPPPPPPPPPPPPPPPGGGGGGPPPGGGG    //
//    PPPPPPPPPPPPPPPPPPPPPPPPPPPPP5YJ?7!!!!7??JJJJJJYYYYJ?77!~~~^^?JY55PPPPPPPPPPPPPPPPPPPPPGGPPPPPPPPGGG    //
//    PPPPPPPPPPPPPPPPPPPPPPPP55YYJ?JYY7~!!!77?????JJJJJJJ7!~~~~~^^:7!7??JY555PPPPPPPPPPPPPPPPPPPPPPPPPPPG    //
//    PPPPPPPPPPPPPPPGGPP5YYJJJJYJYYY55Y7!!77???????JJJJJ?7!~~~~^^^:7??J7??77??JYY5PPPPPPPPPPPPPPPPPPGGGGG    //
//    PPPPPPPPPPPGPP5YJJJJJJ?J55YYY5YY555J777???????JJJJJ?7!!!!~~^^~??JJ??YY????????JJY55PPPPPPPPGGGGGGGGG    //
//    PPPPPPPPP5YYJJ?JJJYYJJY5YYYY55YYY5555J?7???JJ?JJJJJ?777!!~~~!?JJJJY?JYYJJJJJJJJJJ????YPPPPPPPGGGGGGG    //
//    PPPPPP5YJ??JYYYYYYYYY5YYYYYYYYYYYYY5555YJ??????JJJJ??77!!!7?JJJJJJYJJJJJYYYJJJJYYYJ??77?YPGPGGGGGGGG    //
//    PPPP5J??JYYYYYYYYYYY5YYYYYYYYYYYYYYYYY55555YYJJJJJJ????JJYYYYJJJJJJJJJJJY55YYYYYYYYYJ??7!75GGGGGGGGB    //
//    PP5J?JJJYY5YYYYYYYYYYYYY5555555555YYYYY5555555555Y5Y5555YYYYJJYYJJJJJJJJYY5555YYYYYYYJJ??77JGGGGGGGB    //
//    PPJJYY5555555YYY555YY555Y55555555555555YYYYYYYYYYYYYYYYYYYYYJJYYJJJJJJYYY55555555555YYYJJ??7YGGGGGGG    //
//    PYJY55PPPPPPP555555555555555555555555555Y5YYYYYYYYYYYYYYYYYYYYYYYYJJJJJYYY555PP555PP555YYJJ?75GGGGGG    //
//    YYY5PPPPPGGGGP55555P555555555555555555555555YYYYYYYYYYYYYYYYYYYYYYYYJJJYYYY55P55PPPP55Y55Y5Y7?PPPGGG    //
//    Y55PPPPGGGGGGGPP5PPP555555555555555555555555YYYYYYYYYYYYYYYYYYYYYYYYYJYYYYY55P5Y5PGPPPY555PPJ7YGGGGG    //
//    55PPPPPGGGGGGBPP55PPP55555555555555555555YYYYYYY5555Y55YYYYYYYYYYYYYYYYJJYYY5P5Y5PGPPGYP55PG5??GGGGG    //
//    5PPPPGGPGGGGGBGP5PPPPP555555555555555555Y55YYY5555555555555555YYYYYYYYYJJYYYY5P5YPGPGP5P5PGGP??5GGGG    //
//    PPPPPGGGGGGGGBGPPPPPPP55555555555555555555555555555555555555555YYYYYYYYYJJYYJY5P55BPBP5PPPGGGJ?JPGGG    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SKY is ERC721Creator {
    constructor() ERC721Creator("Nick de Jonge Editions", "SKY") {}
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