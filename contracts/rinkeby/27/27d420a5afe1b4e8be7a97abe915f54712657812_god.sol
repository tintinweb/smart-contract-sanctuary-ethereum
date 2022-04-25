// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: alifathinozar
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//    00010110110101101010101111100001001001110010110101100010010001101011100110111110001101101101111001001000000100100111101001001    //
//    01110110110000111000101001000110100010111101011001010000110011101011000111001110110101010010110110111100101010010010001111000    //
//    01100111010011101101011011001100101000000011010001110101110110101101001101110000010101001100011011000100011011110100101100100    //
//    10011101011111110000011101010101101100000100110101010001010000101000100111101111110000011111110011101010111111111101110111011    //
//    00111111000111111001000101101101011111111010001000110001000011101100111011100110000101111101001000011001011010110101011101011    //
//    10110100010101100101010110001111011101110001010001001101100110000100000111011011101001010101101000110110101011010010000110100    //
//    10010110111011010101100100100111011111000001100000011101110001000001000011010100111011110011100101000011001000110100110111101    //
//    00000001111001110101011110111001011110111100000001010011001011110111101110000000001000010011111010011011110110010001101110001    //
//    10110110000111101010100000011000100111111011100001101001010001110011011111001000001000111101111011011110101110011001000101110    //
//    10001101011001101000010010001011000010101001010001001001011011111101111111101110001110110101101001011101001101001111011111111    //
//    10100000011110110011111100111101000010110011000100110110010100011110010110111010010101001101101100010110110101010110000000010    //
//    11001010111110011010110101111010101110100001100101010101010001101001010001110111110100110011001011101011110101101000100001010    //
//    00010011110110000001000001000001101110101100001110010100000101101110011010010110110011001010111100011010100111110111010111111    //
//    00010101001110100111101101110100010101100100011000101010010101001011110111010001111101111100111010101010011101111100100100000    //
//    11100111100011100011111001110110100101011001111111111100110011010110101001000001010110010001111011110010011011010101000101010    //
//    01011011001010010101001011101110101011011011000101111110010001011101111100111000111100100010111000100011101101101100001001100    //
//    00101000000110001010100110101010010010010110011010111100111101000111001100110010001101011000111010100011111100000100011011100    //
//    11011010010100101011111110111000000000101111111001000111000000000101000001000000111000011100001110100110000001101111101100001    //
//    00000000011000011100000101001000100110000000000110100011110101010001001001000011010000010011100101000000011101111110110010000    //
//    00000101110010111110111111001011010101100100101011011001000000001001100011110101110010010001010111000100100010001110001001100    //
//    11001010000001000111010011000101001110101001010111101101110100111100101111111111001001001111111110001111000001110111000110010    //
//    10111011010100100000010110010001011001000000111001011010011001000100001110001000100011101111000011110000000010010110000111011    //
//    11011100110110001001001001101101000101001110100011001011011101101010110011010101001111111000110000010010011010011111001100100    //
//    11000100111111100000010101110000001010110101111101101011110001010001100001010001110010010101100010100011000111010101100010011    //
//    10111101011101010010111010010010110101010010011010111001111111101111010111000001111111110111101000100011111001100101100010101    //
//    01001001011010000010001111011110010010110100010111001111101010100010110100101001101101100010110101100101110001011101101100000    //
//    11010001000100111011011101000011100000111100110000101011100010000111011010110000001111011100111000000100100001010110111101010    //
//    10110000001000100111100100110001111111011001110100001111110000100111010110101111000111011111110110011111111101001100010100001    //
//    01100100101101100110110011011111100010000111101011100110010000001011110100110101100111001001100000000010000011000011001010101    //
//    10011011000100001000000111111010101000110000100110110100111111001100011111110111000010110111001000111100100100101101011000111    //
//    01110010010010000110111111011110010100100111000100001011101101100010110101111001000101100110110100000111001000110001001001110    //
//    01011110000000101010010000000110100011110010001000101111100001101110010001010001111010111001101001010011010000001110000000110    //
//    11000000011100100111100010010000101011111101011001101010000110001001010111100001000100111000100111100110000000000100110011000    //
//    01111011101110101011110101010111100111000100101011111001110010000011011000111111000001011111100001101001011001000101011010110    //
//    11010111110100101000000110100110001101110000001000111110100000111000000100011100110000110110000010011010110010010101101011000    //
//    00111111011010100111100100110011010110111010001000011010110111001100110001000111100011001110000000110111110000000011000010000    //
//    11001001000011111001000100100111000110110001100011011101001010011010101000010100010010100000000110111001010111101100111101111    //
//    01010000000101000000111100100111011111001001000000110001001100110000101000010010001000011001100110111100000101101011011100111    //
//    00000101010100100101000010111001111110000000001010010110110010100010011001011011111101101100010101110010010011101111100100100    //
//    01010001001010110000001010101000110100100001000001001010100010100010110111100000000011010011000101001111010001001101111000110    //
//    11100001011000001010000010000010110011111101001001000010111011100011011010101101010010110100110001110101111101001010101100010    //
//    11010111001000100010010011000001001000101010001111111001111101010000100010010011111100010010000011111101111100000110000000011    //
//    11101101101010100111111110000010000001011000110100101101110101110010001011100011001011000011011110000110011101100011001010100    //
//    00111111110011010010010110100100000111110110000100011011001010101001110011100110001000110010101011000011011010000110010010011    //
//    01110110101110110100111110011010011111101101011110110011100010110010111010011110100100110101011010111110100001000100001100011    //
//    00011111100001111001011100110110100100011111001110010010100010111110111100000111100000101110101101100000000111001011000111000    //
//    01001001000111011010110001100010100100010100101100010110101100100110101111100100111000011001110010111101010110110001100000110    //
//    01011111000110001101000000001011101110000111001011100110101011110101011111111011000011100000011011000101100000100010111101100    //
//    10010001101111000000110100010110010101111111001010110110101110100001101010000110011010010111011001011011101011011110111000010    //
//    01101000101011111111011111100000111111111000110010101101000010101010100010010111101001001011111011111010011111111111110101111    //
//    00111100010100011001111011101101001100100011010110010000101100011110111011000000111101000100011111001011110110111100111100000    //
//    01011010111100011100000111111101000001010010011001101110011011001001111100101000111000000011110101001111100000101001111011101    //
//    11011111110100011011111110110011001110011000000010000101100010000101001100111010011101011101010100111100011110101011100000010    //
//    11000010101010101001111101111111001110010110101110010000000100111110100100000101101101111000100111101001100011010110111101100    //
//    00111111001001000100010110001101000101110101010111000100001011011001001111110000111110010101100110000001000011000010000001001    //
//    01100101000110101100110101010011000101111111100101000101011100010000011000111111000010001011110100110111011001000100110111101    //
//    01100100101011111100110011100111111100010011100101100110100011010010101101111101011001010010110110011010010010010100100100110    //
//    10111101110001001111010011001000001000111011101111101010110001100010010111011110000100111110011010011110010010010010111100111    //
//    10100100111011111001111101100111000111111101011001101011111101001010110011101010101111000110001101000111010011011011111110111    //
//    10000100011001100001000000101100100110010101111111011111100001001001001010110011100010000111101100111101000010110110111001100    //
//    10100111000001111001000010101100110010101111101011010110110000111000111000100011001101001100100011100010110101000101001101110    //
//    11100000111100000010101111101101010101100001010011110100110001110010101100001001011000000000000001000011110001110100111011100    //
//    10010001111110110001011110100001101001000011100111001110111011011011101000110111111111100011100011111010100111010000110000110    //
//    11001000100010001010001010011000010011111000010101101001000001101101100001100100100100110110000011101100001100001000110001000    //
//    10110001011000011101110001011100100010000011110100001001100001100101001001110001001011110101100111010110011010001001000100000    //
//    11100101111100000010011001111010010010100100101100001000000100111101100111110001100001101110000110000100111110101101111111011    //
//    10100011100101100100100100110001000100001010010000010101001101011111101000010010000000111011100111011001110011001000110011001    //
//    11000100101000101101000100101100110110111111101000011100010010110110111011110011110011011100011111010011110101001101001000011    //
//    10110100110101101100100101010010100010001000100100000011101100110000010110101001110110110011011000010101000100010101111110001    //
//    00000010010100010001001101111101011000111011101100010000011100110100100101011111110011110111111110100011100001110011000110100    //
//    01101100110111011010111001000101100011011101110111000010110101110000100110000001011101011110000000101100110000100001111011100    //
//    01100000100100111010000010010100111101101111000100010010100011110111100011000111100000011010000010001100101001100110101100011    //
//    10100101011111110000011100110001110010100111000100110000110101001000110010011010111000010100000001001010100111010101101010000    //
//    00010101110011011001101011100101001010011000110100111111010010101000111011111101010010101011010011110001001000110000101100111    //
//    01100100011011110100100110100110101111111100001101000110111010111101111110011111001001110000010111110011010011110001101100100    //
//    00011110010000001001011101011100100100000110100111101100010101101100110111111110001001100001010110000001000110010111101110010    //
//    11001010100100010001010100001100100101001010111010101110011000011000000000001111111001010010011010010010001110101010010000000    //
//    11001111000000011110000111111000010000100111110010001011010010110101011011011001100001111110111010010110010011101001001010110    //
//    00101101110010100100001110100001110111110000000000100010110111000111011110001111000001111000110000110011001001101100000011001    //
//    10101000001100111111111010010011000110000110110010001110111110000110010100000001010110111001000111011111100011000001010100111    //
//    11001110110101101110110111111100001001011101110001110100010001101001100000010011101111001000101011110000010101100100101001000    //
//    10011101100000100110000111101010110111100111101100100110000011110100110110000111101110000010000010010010101011101100001110000    //
//    01100100111001000100011001101111100000001111011010100011001011011010011101010010110101000000101001101101101111001010110010101    //
//                                                                                                                                     //
//                                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract god is ERC721Creator {
    constructor() ERC721Creator("alifathinozar", "god") {}
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