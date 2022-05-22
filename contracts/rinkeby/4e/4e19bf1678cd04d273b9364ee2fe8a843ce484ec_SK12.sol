// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SINSIN
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                     //
//                                                                                                                                     //
//    01100011101011101011100011001101011100101011111010100100100001010011011001000110001111010001000101100010010001110110001111000    //
//    10100010101110100000001100100101011001101000100101101010000111001010000001001111011101110011101001101110110101100010100100010    //
//    01010000110101110010100101111011101110010011001001001001001000000110001100010001110000111101110010100110101110000101001111111    //
//    01001000010101001010101101010000010100010110100110010010001110101001111010011101010011100010111001100100000110010100100001010    //
//    11100101010111110110000001000001010001110100101011101010010110011101101011010010110001001111111110111111000010111100110010011    //
//    01001101001000010011010001101010001110110100001001111001101110100010011101100001111111000010000010110101100010000000101110001    //
//    00001010110001111000111111101111000101101011001000000011101100110100100100111101000010001110110100000001110000111110010110011    //
//    01100111000111011100001001010011011001101110100101011000001100011000101110000001111011101010111110001100000100010100101111111    //
//    11001111010000111010011110110011110001111111010110100100010110000101110010111110111101101111011101011011010011010111000111101    //
//    11110001111111000111101111100101100100101110001111001101100001101100000101001110100111110011100000110001101101001111101100111    //
//    11010101111110100001001010010111011000011010011111111010000010000001101111001010011001101001100101010011110011001011011001000    //
//    11101100111000000010000100101011111101100011101011101111110100011110010000101111000010101000110100001011010100101001001111011    //
//    01100100011100110101010000001110100101001110001100000000110001001111010101001010001000000111001010111011001101001101101011010    //
//    01101101111000101000111000001111010100010010001100100101000101111010111000000010110011101111110110011001101010110010010110011    //
//    00111011001100101011110101000111110100001011001100011000000100111011101011100001010011110011100101111000101110100101101000110    //
//    10000111011010110011001001000100001011010011110001110001100010111101110000101111011000000110111011011100100000000110011100110    //
//    11101110011001101011111010011101110110100011110100011111000111010100110000000100000010100011111110001101111100101111110010011    //
//    01111110101011001101111010000010110101010111011101011101011100101111100100101001111110110110101100110101100011010110000111101    //
//    00011000001001001000100101010000010110010010001110000011101111110100000111001000010111000011010010011110011100110001100101001    //
//    10001001101000000110010000110001001110011111001111101110001011111101001001011111000001110001101100111011001001100011101100001    //
//    10101010010010001100111011000001100011110011110111010000000011111100011010111100000011001000001000001100011001011010010111101    //
//    01100110101100010011101111100111001111001011110101010010011000111100111100100010011010000110111101001100011000011110001111101    //
//    10110011100001011001011010001001111001000101011001100111101110011001011000001100110010011011100011111111101110100000000010001    //
//    00111100001010000001111001000011011011001000101011001001010110000000101001110110101111100101001000100001111000011110101010010    //
//    10001000101111000001110010101000101100111001001001011010101101001011000010100011100111111011010011110101101001100011100011100    //
//    11010101100001100001111010001111000100000000001110011100001010010010011110011010100000011000001001111010110100000111001001100    //
//    10010111111001100101011111100100001100011011011001101101111011101000010100001000010110001110011011001000100010010001100101011    //
//    00110011101010011010100011110010100100101101101101000110000100110010000111011011101011001010011100110111001001001000000111110    //
//    11001101000100010010101100000100111010011100111111100001101110011001010110010011010110101000110110111010111000001101101000010    //
//    01010000111001001001100000101110001110011000001100100111101010111100100001011111111100001101101101010100110000111111111010101    //
//    10110011000111000011110110010100010100101111001010010111101110011001100111001010100110000110101011101111001001111110011110111    //
//    11100111101001100100001001111000011111101000101001001000010100100110010111010100011101011011010011011010100001111100001110011    //
//    10010011001101011110000000001011001000000011011110101111110010110101011110110011101011111010000110010010111010010111011111111    //
//    01100101111010100100100011110000110010100110001010100110101100000111111010100110010011110100100011000000101000010111010100100    //
//    11000001010010000000000100101010111101010110111100110111001111111010110000110010110001011010000010011101111010010010000010100    //
//    01001100000011001011010100000001100010100111011110000110101111101010010011100110110111000110001011010010011000100110010101001    //
//    00100001101111001011001110101011101100010100101111000010101110110000100010111101000101010100011101101011111110010010011110000    //
//    11111010011001001010100001000110101001100100011101011101110110100101000110001011001101101110110000010010010101000111100011101    //
//    10111011010110100111101111001001111000111010011010101101111110111010101010100110011101001001010010101110101100101010011111010    //
//    11111010111000100011010001001000000101011010111000111101100001111001100000111001110000110000011110010100111001000101100110110    //
//    01000001000110000001001010101000101011100000110100000000010111000011110011010000101111101101110011011001110011010001111011001    //
//    01100010000001110011000011011010110011101000010010110010110111110000100101100110101000001101010011101101100110010100001110111    //
//    10011000000011001111010110011111010001110100110000010111011100001100000110110000111100010010100001000010110010101101001011111    //
//    10011100011000000011110001011110101110011000111100011111000001001101101100110111000001001101100001010010000111101111010110011    //
//    10110111011100001011100110001000111011111111010101011110011010011001010000110000101100100001001000000111001010100111001110000    //
//    11111000000101100000011100001100110000010000100001001110001100011110010101001101011011101000001000010101001001011111000001000    //
//    01000100110101100101110101111100001010100000111100110100010001010110100111101111011001010100110101101111100101110010010110010    //
//    00011100111000011111110011000000011100011100110100011111010000011101010000111101011010001110000111010001001011101000100000101    //
//    10111000000001101111011010110101110100001010100110010100100010000000110100001001110000101010100000001000101111000111010011001    //
//    00000011111010101101101111101100101110100101111111010000001000010101001001110110100111110000000110110100110011101100000101100    //
//    01010111100100010000111101010001001101010010101011111110100101001110100100100001010001001000110111010010100011011100101011011    //
//    01011010111011011001101000111011000001001010001001111110110010010010101010010101111111001111100001111011011111011001111101010    //
//    11000000101100011001111110011011010111110001100111110010100111111111011001111010011011010110100001100010001111100001101101111    //
//    01111001101001011111010000010011100010010001010001000010001011100100111001011101101100001010010011111000110110011000110110101    //
//    10110000110101010011110011111110001000111011101001111111011001000100111111100011111011001101011111110001010100000010001011100    //
//    10110010110000100000101001011000101100011011101110000011100101110011101010110011000101101010101110010000000010100001010001000    //
//    01011110100011110111100111101000010100010101110101010110000100001000011100011111001001010110100110111010100000011011100111010    //
//    00101010011001011100010100000010010011100110101101101000100010101100001010100110101001101000110100001011110000100110001110011    //
//    11010010110010110011010011101100000101100100101011101001110101000111100000111111110000100110100000001000111111001100100111010    //
//    01010011100101101111101010111101001101100001101100111011000100110110010110001110110100001100010111000110110110110100001001010    //
//    11011001111110100010000101001011100110000011010100110010111000001100111101111101111010001101100000101110100011110000000111111    //
//    11011000100100110011000111010010011101011011011101100110000100001010001111010000110011001100110111111010111001001100011100110    //
//    10100010110110011010110000011110010101100110100110011101101010101111000001010001111011101001011101110101101010111110100100111    //
//    01110000011100000010011010011010100000010011001001000100000101000110011101101100000000101011010010000110110100111110100100101    //
//    01010011110001010001010100101001010111110001010110101010100101111001000000101100010011101000110110101010100001100001000110101    //
//    11101111110101000010111000110100001010111100111000001000111101011100011111101000100100101111001011011111111111100111101101101    //
//    01110011101100111001110001111010000100100110100011011101111111010001100001100010110001001011001101000100010010010100000001100    //
//    00010001111111010011001001111001110111101111011110101001000100000010011001001100001111010010000001110101110010111110101110111    //
//    01100101111101001101111000101110011101110110100101101001100101001101101101101001111000010111111101100001001000110001111000101    //
//    01000110111101010110010001110101010100000011101010110011000011001101010101100100100010100101010011011110110001111011101001101    //
//    11001010001010100100000111110011110010100110101101000011010011001001100100011000010101100100111100111110011011001000100010110    //
//    00111001001011111100001100101110100111010011110010001011001010110110011110101011000010001000111111001000100101101001011000011    //
//    01111000000010011110000001001010111100001100001101111110101001000010001000000111010011100001110110011110010000000010000011100    //
//    11100011100110111111000111010111111110011101010100110000100111011111110011101011110100100100001100101110101110011100000100111    //
//    10110100011100001100011000011010110111111111001111000000011100111010111110101110001100110101101011100111001001010111111001110    //
//    10010111110001110001000001101010001110101101000111001011100100101111001101011101110000100100101111110101011000111010001110100    //
//    10100010110010100011101110011010110011010010000110101011000100111100010110111111110001010000010100000100000010011011010011110    //
//    01001000011101000101111000100010011101001011000001011100011010001001101111100001010111001110011000111000000110001110010010010    //
//    10011111101101110000111000010001010101100000000011000110001101010000101001011010100111010110110001111011011111001000010000010    //
//    00011010000001100100001101011111111010010111001011111010010100011010110111010011010011011010001000111011011010110011010010010    //
//    01000111100100011100111001111000010000000101011111101111110110110000100010100011101111111001101000111011101011101000000110110    //
//    00110001010010100011000010110010101000001100100110101001001011011111000111100000101100110111110101110101010100100100101011111    //
//    10100010010001001111011001001110010100100011111010011111000001011101110001000111010101100111001011010101001011001100001010010    //
//    11010011111001010011010001100001100011001011010101001100001010111110011011100011101101100001000111010001001001011011101000100    //
//    01011001111011010001101010001111011000001010101000101011111010010100101110110110111001100001010001011100111001000001011110010    //
//    01110010110100011010010011111000011101010000010011100001100101111001010011110000101110010111011111000001101010100000101011100    //
//    10001011101001000000101110010101011111101000001011011001010000111001100110100010000001111101111001000110001110000110000000100    //
//    11100000001111001010110000011111110111110101111010000001111101110101000000001000011110111001101011101011001010001001001100100    //
//    10111011000001001000101111000010011110001011100010110001011100111101110111110101110000111010010110101100100001001000000100101    //
//    11100100001001011000101101101000110101101111110100010001011001010010010101010010100111010011000001001110101110010110111111100    //
//    01011001110001010001110101100101100011110100100111010111001100111001010010111101111000010001001111000000000101100011111111011    //
//    00001111011101011011000111000011001011100001100010110111001001011110010101011011110100101010101100100101101001100110011100001    //
//    00011110001001001000010111001001100011011110011110001011001111110111110111000101110010111000101100110111010101010100011100010    //
//    00101010100001100001010011111100001011101010110011110001100010110011111111111000111110011101100010110011000110011101001011111    //
//                                                                                                                                     //
//                                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SK12 is ERC721Creator {
    constructor() ERC721Creator("SINSIN", "SK12") {}
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