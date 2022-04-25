// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: alifathi nozar
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                     //
//                                                                                                                                     //
//    10000001101010100000100000100110001101100110000000101111010011100101100011000100110100111000110110100011000100110111111110111    //
//    11100010110000011011011110100000001011000011010110100000111011111001111011101001110110101111011100101101011000011100001000100    //
//    10001101111101011011100010010111010011011110110001101000000011001011000010011010001111011100011111000010000011011000000110010    //
//    10101111010001011011000100011101101101101101101001100010011010011101100001110100011100100011111110001111001110100011001110001    //
//    11101101001001000110010000010110000010001010100101011101000001110000001101010000100110011001010110001011110010111011101011000    //
//    10100011111110001011110011011110001101100101101101011000011111101111101011110010010111111111110100010110000110000010011100101    //
//    00010000000011000101001100001100110010110111011001010111101101100011100101100110101110111000000110101001101000101001010110100    //
//    00010000101100111000011011110110010100010100101101111110000001000100000110101111111101011100001111100010111010100001001010011    //
//    01000010011111110001000101001001100100010000000101111000010001110010010001010001010100001001101000000011010010101010011111011    //
//    11111000111111010100101010000100000100110001000111100001111000001111000010101010001001111010110110110100111111111111100011010    //
//    01001001111111000111111111101001100111111101100101111000111010110111110100000100110101100010100000111110000000110011010110001    //
//    10011110100110101101101000101000101001000100110111101101101111001100110111000101011001110110101100000010110011010100110100011    //
//    00100100001001110111000110111110000000001110111011010101100000000110010111111110010111010101001001000011110001000001111110011    //
//    11000101111010110010011100111000110101001010100011000000000011011101100110110011011101001011000100010101101100011100100110101    //
//    10011001010000110000101000001111110010010110000010111110101010010100001100011101110100110011010000011111111100111001101100001    //
//    00001110101000011001100011101110001101011110001110000101101110100000100100100000111000111011111110110000110110101011000101110    //
//    00000100110100001111101000000101001100001110011100101000100001110101110011010001010110011011001100001111110000101110110011010    //
//    00111010000111101100000110100110000101010011000001001011100100101011001001000010011110110000001000111111101111111100001000000    //
//    10101010010011110000111010101010101000011100001101101100101011000001110010010101010110000111111010000100000000000100111001111    //
//    11011000100001000001000111110110110001110010011001000000010111010010110001000111010110101010101011101000110101111101000001001    //
//    10001100010010000101011011011010100010001111010101110001110000000000100000100111100110110101001111101111011100000110011100010    //
//    11101000000001110101110000101101101010100011111010011110110010110010101001001100100001010101001100111101111100100001011000001    //
//    00110011011011000100011111011001101111101110011101111100000110000000011011101011011111101110111101000111001000111110111000111    //
//    11100110101100110100001011011101101111000000100000101001000000010001110011000111100001100101010110100000111100011011011011111    //
//    00111011010111101001111011111111110110011111101100000010011000001010010001010011100100110101001010010111110011000101011110000    //
//    10010011100100011010110000011000101000011000010110011011111001100111110100011101101111111111100000010011010100011010101110101    //
//    01001100110110110001011010001100110001100001000101010110100000011110001101001000001101101000000011111111000000001100100010100    //
//    11101100011100110001101010111010110100110011100000101010111011101111000010001010110100000111010110000011100000110010011001001    //
//    11011111000111000001101010111001000100100010100101101010100100100011101111111011100000000000000001001011100010100110101000101    //
//    10111011110011010100111000110100111011111011011111100100111010000011110100011111100000101101000001001011101100101001100100110    //
//    01010000101010110001010110101000010101111010110010000110010100101010110100110101011010010011000101011001101010011001101111110    //
//    10111000101010011001001100110010110000001001101111100100111111111011010111001010001011000111100100011101100110000010111011110    //
//    10000110010011010000000001000001111111011001000010010010100001000001100011011010101010110101011011110011111010011000000100110    //
//    00000000100000101011010111010100111110010110111010001010011011110011011111001000110100010100001000111100111011111000101110010    //
//    01011110110110000000001111010011000010011010000001110111100001010010101001100100001001101111101111010001100111001011100010000    //
//    10101100110000010001001010110011000111000010000100011101001001110111100111010001101110001100100111111110011101011001000101001    //
//    01110111001010011110011011010010001000111111100101110001001110111111000100001011011111000011010001110011100111010011111000000    //
//    01100110001010011101011100011011110010000011010100000101010100101110111101100001100000010101010110100111101100011000001110101    //
//    01001010001101111011011101010100011110100111000101111011011001001011011111101010100001000101110000111000101100111011001111100    //
//    11101000000000111010011001001101100011011011101010011110000000001111000111100101111000111010110000100001000101110011001101101    //
//    10100110101011001001101000010000000110111111001101001111101100100000000111010001001100001011100110010000001001100101110101001    //
//    10110111101001000111011000110101110000111010001101011111001101101000010111101101110011111001011100110011110010111001110101111    //
//    00011001101000111111101110011001010011000111111110011101101100011110001111001001111110101100010110101100110010000011010111010    //
//    11010100110001101011101010101010101001010111111010110100001011010101011111001110100011111100010100010100000000100010111000010    //
//    01101011110100010110100011011001001111111111010011110101000011110111000110001011111001111001101101011110010000010101111011001    //
//    01011010010011010001101001100100101100111011110101010010000011100011111110001110000110100011011011101000001010010111111010100    //
//    11011000010111001000101001011010110111100000101110100101110010001101011110110110110100011100110101100010001011000000001011000    //
//    01111110001100101000001101001010111011001111001101000110010000001001000110110010101011110101111111001011011011101111010100000    //
//    11100000111101010011110001001010011010011010000111101010100001100010100001011111110000011010011111010101111011101110000011101    //
//    00101000011001000100111100101111101100010011101101010011111101100111100011100001111110000010011000011110011101011111011000110    //
//    10110010001011111000111100110100101000100100000001101010111010110010101100001110101011001111010101000101000110000100010000111    //
//    01010010110100110100001001111110010111111011110100000001101110010011000110010010011001000100000111001000111111111000101001101    //
//    10010000010101100011111010101001010001100001110000101111100011100011110110101010111110111110110111001001010001011111010000101    //
//    10110111001110001010100000100010000011001001110001011101110000000111110010011100001001011101100010100111011011011000111100011    //
//    00000011010111000101111111001101111000111010010010110001000010111101100011000111011001011010110010001101001000011001111001100    //
//    01101101101011111000001001101111110110101111110011101000001000111000101101101110100101001001100000101000101000011110101100100    //
//    11010010100110101011100011110010101111100101101101011101100011101101100001100101001101000100111110100111011110010101001111011    //
//    10110010110000101000000010101011111000010011110000101001000111100001011001100111011000100000000100001101100111111101011101000    //
//    10001000111100101111101111010100010000100111000000010111000011000010000111011001100000000000011011110110000010001111010011000    //
//    10100001011000110111100111110111010000010010111000110100110111111110111011100000000010001010101010110111010010011011011111101    //
//    01101110010010101011101011100010010001010111100110000101001111101011001001001110101110101100010000011111100110100101111010111    //
//    01100001111101111100100000101111101100001100100010001111000101101000110101010111001000100011100010001111011001110000110100111    //
//    11010000110000100111111000101100001100010000110110011101000101110111101100001110010010110001101111000000011001001001011001100    //
//    00001001110001101010011100000011101100111010000011011000000001111001000100000101111101010011100101111101010100000101110101110    //
//    00111110000111100100101100011001010101111000001111100011111000100011100110010000111100111101000011000011001110111111111011010    //
//    11110010101011001000110111110101100110011011010011001110010111011010101010100000011100010100101101110001000001100100110000000    //
//    01110100101010011001111101011110000000001100110000000111111100111000111100100101111110011110111100010101000111011011100111001    //
//    00110110010011110111000111010011001011010100011000000111000010100100010111110011101110101100011100011001011000111010111000110    //
//    11011101100111011100111001101010001100110010000011111000000101100100110011101010000100100101111100111110001101000001110111100    //
//    01101011000010110010110001100011000100010110101101000000000110010100001101001101000110000110010000011100001010111101101110100    //
//    01101111001111011110101101101000000000101110101001111110111001111000010011011101111010001000000011100100001010100010101101001    //
//    11110000011111110111101111100110000010011001011011111010101101010011000100111100011001101111000001111101000101100000000111010    //
//    11001101101110100101110111000110011001111111111111000111110010110011111111100001101010101000011100000011000010101011001001110    //
//    00110011001000100001111101100011000111101010111011111111101110110110010010001001100100101011001000001111010000001000000110011    //
//    11110100000011000011000000110110011101001101111010000001111110111001111000011111111001101101000010101101110110001110100110111    //
//    01101111000011001001011111001111101111111010000011010101010010101111111111111100111001100110000110111110000110110110101111110    //
//    00111111101110000100000110110011111100101011010010101000000110000010011011000010000000110110010000111000100101000001011000010    //
//    00000001001000111111000100100001000001100000001101100000111110011110101110110110100110011101010100110000000010101010011100111    //
//    11111011010101101000011011000100100011100110111011110101110000110010001110011000000011010100111110000010011110000100100111110    //
//    11100101110111000101011101111000010000000000110000111010011100111001110110000011010001001011010011001011110111100100101111110    //
//    01011101100101110011000101110101111110000010011001110110111011110100010001101101011111100010101010011111110111010110100000001    //
//    10011000110111011011011100011001000110001100111001101011100010000001010111100100000001010110101101011110110010010100110111101    //
//    00110011000101101110010010110110101011011000010101000101001010100010101110111001000111101010001001000110000000110011111111101    //
//                                                                                                                                     //
//                                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ali is ERC721Creator {
    constructor() ERC721Creator("alifathi nozar", "ali") {}
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/Proxy.sol)

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
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
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
     * If overriden should call `super._beforeFallback()`.
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