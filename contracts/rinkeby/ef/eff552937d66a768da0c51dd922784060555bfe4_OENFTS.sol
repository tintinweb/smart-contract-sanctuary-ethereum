// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: One-Eyed NFTs
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//    00011100000011010100000100010110001111001100011101000101100001000010010100101111110000100101011110110000001011000111011100110    //
//    00110101111111110001010101100010110001001111110110001001011101000110110000111000000110110110101100010001111000101001111111000    //
//    10100000000010011000100111111100110100110011101101000000111101011011000100011011001110011101110011001001010000101111111110110    //
//    10100101110010001010001001011111110100010101100011011101110000000000110110100000111010101100111111001110001101000111010011001    //
//    10000011111010011000010111110110110011100111110100111001000101010001010111010001101001000110100111110110111100000011100000111    //
//    01010100111001110001111001010110100001110101010000101011000111011011100011100101010000001010101010011101000100110010000001111    //
//    11011000100101100010000011110001111101101101101001011101011111001001011111011110011011011010000111011100010111001101001011011    //
//    10011011111111010100001001000100110011011110101001101001011000100100111100100101000111100111101000110100010101011110110000101    //
//    11001101101101110101101011010010010110110100000111010101011011100001111110000101110000011111111001101111111010110011111010001    //
//    00000000111011111000111011000011000111101101000011011110110111010100010101110101000111110101111010101010110101100110100010001    //
//    01101100001000010001011011001011110000101100001101000111001000111000000100000000101010000111001110001010011110001110111000011    //
//    01111001000010000111100101101000101010101110111111011001010001000001011100111010110010111111100110100001010011011100001011111    //
//    10111100100010010001010101110001111001111010010010101011000100011111111101100110100101100101010110110001111010010101000111111    //
//    11110101011100101110101111110101010001010100101010101111010000101101100001001011001101111000001010001111101101111110111010110    //
//    01101000011111001100010000111010011010010101111111110110000110110011010000101100100010001010011101101111000000010010111101000    //
//    00100001011110110111010011100111111110010101100111101110100010000011010010010000101011000101001100101110000000000010010000010    //
//    00001000010110010000011101101111100111001001100000101000001110011001000000001010101100110101111101010010111001101101111111111    //
//    10010101100011000100111011010000010110101010111000110010011010001110101010001011110101111100110001100110101001100000100000000    //
//    00101111110111000001000100111010000011110000010110111110000101011110111001011010010011011111111110101111101010111011000100111    //
//    10101001010111100101101001010100110000001111000101110000000001110111111011111001011011011101000110101010101010111011011110100    //
//    01111010000111011110010100111000000000100000001010100110010111001011101000110000100100111101110000100100110110101111010001111    //
//    11110111010100100011110100110010000111000101001011101001101010110010111110011101010001010110011010001101001010010001001011011    //
//    10010001101011001000001001001100111100100110100111011010001010110101101001111101001000111110110001000001001000100100001111001    //
//    01110010010101010010001111111000010111000010110111011101010100011001001000101101111010001111000111111110011111111110011011010    //
//    00100011000101111011010011100110100110010001100101100010000000010110010011110010111111000001101000100100110010001001101100111    //
//    11011100011100001111101011101110001100110011010100011000011110100001010011001010001100000100111110001010001011110000100110111    //
//    01101011001100011100010100001101100010011100010101110011010001110010011101011110001101100110110110101110100010100000000111011    //
//    00111011000101010000011000011111100010010101100010110101100100101110010110000001111100001010000010011011010011101101010110110    //
//    00000100001000110001111001100001000101101100110001010011101001000010100100100001011101111011000100100111001010001011100110101    //
//    01110001000110100001001000010011101000100000100110101100110110010100000100000011101101101110100101101111000110101100111100101    //
//    00111000000011011010000011011100001001111101010010010001000001010101100110011001011000001110111001100100000000100000010001110    //
//    11011110000110000100110111110111111110010011100010111010001111001100101011101111000010001010101000000000000010101011000001111    //
//    11011110110011011110111100010010110011010000101000101110010010000110101110100000011001111000100001100100000000010101100010101    //
//    01111001000001010100011010001101011111100000101101001011011101111010111110110000111001010011011100111000101111110111011101000    //
//    01001010111000101001011110011011001010001011101100100001100101001100111111111001001011001011110001111100011010000001000101111    //
//    10000011001001101011010110100000010011101001100001111100100110011001010100101111011111110101011101110000000100011010110101111    //
//    00011000000000100011010001110111001011011101110000011101111011010101010011101011001010011011010100110011101000101010000101000    //
//    10100110010011110110101100101110111101000100101011101110000111001010111011011000101000110010111100111100010100011000111001001    //
//    00011110010111101010011000011101001010011011011001010000100110000010110011100111001110000101010000001011010110100011011000110    //
//    10110110110001001111001110100000000110001000010101100010000011000010011100101101110010001111110111110100101101100011101010101    //
//    11000010111000101010100001011101010011110010101001101110111011101001000111111100111100000001111101111011100100111010100001010    //
//    00000111010100010011101000011101111111100101001000010011100111011010110000010000110101101100010011011110100001010011001000000    //
//    10000001001101010111101010101110011111010010001000000001111111001101100001100001001011000110010111000000110000111111010100100    //
//    01111100100111101011001011010111111000000001010010001000011000000100010101110111000101100011000011111001011110110101000100100    //
//    01101111110011001110001100010111111000101100010111000000010011010110011111110100001010110110100000101000111000001001011111010    //
//    10010001100010000111010001010000100001101101111111101000001100111110100101101101001011101100010001001111011011001000101111010    //
//    10110110101000111011000110010111110101111011000010011111100001101101000010010011111000001101101100100000010001101111011011111    //
//    11010010100111000000000110101011000101110001101111000000100010010000111001000111011001001101110100001110110100100001101101001    //
//    00010000011111010111010100111111011001101110001000111010011100110011100111111100111010000100110001100011010011000100111111011    //
//    10011101111000100011010010110010001110010011011011001001111111101001101000100001101100011001111011010001100110111000101100010    //
//    01100101110001001100100101011111010110100010010111011011011110010111111101100101110110111100000111010110100001100100110010110    //
//    00010101010011001010100111111001101110100111001000100110001111011110111011111111011111000010111110011000100110010110111000100    //
//    01100000010011101001100010100100100010111011011010000111101010011101100011000010110010011011011010100110100101011000110000000    //
//    01110101011011101011011110100010011100001001111100010100100001110100010101111101111101101110110011000001100010111110001101110    //
//    11110100100100110110110000011011101110101100101100100001100100011010101101110100000101011101111110101001110111111101010111010    //
//    10000000000111100110100001111101101100001000101010111001011101100101000100101110010101001001001111001001001011110111000000010    //
//    11000101000111100011010000100001101111100010111110001100100010000110011011111101010000010011001101010000101001111011011010000    //
//    00010101011001110101101111011010001000100111011110011000011010100011001110101000011101101111010001101100101001111000101001000    //
//    10010101010101011100011111110110011011100111010101010110100010111000010010101010000101101110001001110111010111001111010011001    //
//    10011001100000110100101100000110010010001111000100011001100101001011100001001110011100110001100000000111101111011110101100010    //
//    10001000000101000101001100000000010011100101011010101000011001011011100011100010001100111011010010010100011101010110011100101    //
//    00000111101110111100101110001101001101001011011110010111011001001110011011111110011010111110111001000110111001001001110011100    //
//                                                                                                                                     //
//                                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract OENFTS is ERC721Creator {
    constructor() ERC721Creator("One-Eyed NFTs", "OENFTS") {}
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