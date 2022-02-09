// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: My Baby
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      //
//    [size=9px][font=monospace][color=#beccd6]▒[/color][color=#c0ced8]▒[/color][color=#c0cdd7]▒▒╢[/color][color=#c6d0db]╢[/color][color=#c6d1dc]╣[/color][color=#c4ced9]▒[/color][color=#c9d0d6]▒[/color][color=#c7ced5]╢[/color][color=#c4cdd5]╢[/color][color=#bfcbd6]╣[/color][color=#bccad7]▒▒▒▒[/color][color=#bbc6d3]▒[/color][color=#bac6d3]▒▒[/color][color=#b8c6d1]▒▒▒[/color][color=#bbc4ce]▒[/color][color=#bbc4ce]▒[/color][color=#bccad0]▒[/color][color=#bfcdd2]▒[/color][color=#c0cad2]▒▒[/color][color=#bfc8d1]▒[/color][color=#bec8d1]▒▒[/color][color=#b8c7cf]▒[/color][color=#b8c2cf]▒[/color][color=#b7c0cf]▒[/color][color=#b7c0cd]▒▒▒[/color][color=#bdc6d0]▒[/color][color=#bdc7d0]▒[/color][color=#c1cbd3]▒[/color][color=#d6dbdb]▓[/color][color=#dce0dc]▓[/color][color=#dee1dc]▓[/color][color=#e2e2de]▓[/color][color=#e3e2de]▓[/color][color=#e5e2dd]▓[/color][color=#e6e3de]▓[/color][color=#e7e2df]▓[/color][color=#e8e1e1]▓▓▓▓▓▓▓▓▓[/color][color=#e9e3e1]▓▓▓▓[/color][color=#eae4de]▓▓▓▓▓▓▓▓▓▓[/color][color=#ebe7e1]▓▓[/color][color=#ece5da]▓[/color][color=#ece5da]▓▓▓▓▓▓▓▓▓[/color][color=#ede4df]▓▓▓▓[/color][color=#ece7e3]▓[/color][color=#ece8de]▓▓[/color][color=#ede7dd]▓▓▓▓▓[/color][color=#efe6dd]▓▓▓▓▓▓▓▓[/color][color=#f0e6de]█▓▓██[/color][color=#f0e7de]█████[/color][color=#f1e8df]███████[/color]                                                                                                                                                                  //
//    [color=#cbd3d8]╢[/color][color=#d0d7dd]╢[/color][color=#d2d8de]▓▓╢▓╢[/color][color=#d4d8de]▓▓▓▓▓▓[/color][color=#d8dce1]▓[/color][color=#dbdde1]▓[/color][color=#dddee1]▓▓▓▓▓[/color][color=#d6dddf]▓▓[/color][color=#dfe2e5]▓[/color][color=#dcdfe2]▓[/color][color=#d3dade]▓[/color][color=#cdd6d9]╣[/color][color=#cad3d6]╢[/color][color=#d1d8dd]▓[/color][color=#d3dae1]▓[/color][color=#d3dbe1]▓▓[/color][color=#d0d8df]▓[/color][color=#cdd9e0]▓[/color][color=#c9d6dd]▓[/color][color=#c2cfd7]╣[/color][color=#becbd3]▒[/color][color=#bdcad3]╢[/color][color=#becad6]▒[/color][color=#bfcbd7]▒╣╢[/color][color=#c6d0d8]▒[/color][color=#cad3da]▓[/color][color=#c9d1d9]▒[/color][color=#c9d0d7]▒[/color][color=#c9cfd6]▒▒[/color][color=#cdd2d8]╢[/color][color=#d0d3d6]╢╢▒▒▒[/color][color=#d0d5d9]▒[/color][color=#d2d4da]▒[/color][color=#d4d5db]▒[/color][color=#dadbda]▓[/color][color=#dbdcd9]▓[/color][color=#dcddda]▓[/color][color=#dddfdb]▓[/color][color=#dfe0dc]▓[/color][color=#e0e1dd]▓[/color][color=#e1e3de]▓[/color][color=#e3e3df]▓[/color][color=#e5e3de]▓[/color][color=#e6e2df]▓[/color][color=#e7e3de]▓▓[/color][color=#e8e4de]▓▓▓▓▓▓[/color][color=#e9e5de]▓▓▓▓▓[/color][color=#eae3de]▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓[/color][color=#ece5dd]▓[/color][color=#ede4db]▓▓▓▓▓▓▓▓▓▓▓▓▓▓[/color][color=#eee5dc]▓[/color][color=#eee6dc]▓[/color][color=#efe7dd]█████[/color][color=#f0e7de]███[/color]                                                                                                //
//    [color=#c6d3dd]╢[/color][color=#c6d4dd]╢╢╢╢╢╢╢╣╢╢╢[/color][color=#c9d4df]▓[/color][color=#cdd5e0]▓▓[/color][color=#d0d4dc]╣[/color][color=#cfd3de]╣╢╣▓╣[/color][color=#d1d6de]╣[/color][color=#d4d7df]▓[/color][color=#d5d7df]▓▓▓[/color][color=#cfd7dc]▓[/color][color=#cfd7dd]╣╣▓▓▓▓▓[/color][color=#cad5dc]╣[/color][color=#c8d3d9]╣[/color][color=#c5d0d7]╣╢[/color][color=#cad4dc]╢[/color][color=#cbd5de]╢[/color][color=#d1d7dd]▓[/color][color=#d4d8de]▓[/color][color=#d5d9df]▓[/color][color=#d7dbe1]▓[/color][color=#d8dce0]▓[/color][color=#dadee1]▓[/color][color=#dadde1]▓▓[/color][color=#dadfe3]▓▓▓[/color][color=#d2dae0]▓[/color][color=#cfd8df]▓[/color][color=#cfd6de]▓▓[/color][color=#d2d6e0]▓[/color][color=#d6d9df]▓▓[/color][color=#d6dadf]▓▓[/color][color=#d2d5dc]▓[/color][color=#cfd2da]╢[/color][color=#d0d3da]╢╣╢[/color][color=#c9d2d9]╢[/color][color=#cad3d8]╢╢[/color][color=#d0d6da]╢[/color][color=#d4d8db]╢[/color][color=#d5d9dc]╢[/color][color=#d7dadc]╣[/color][color=#d9dcda]╣[/color][color=#dadcd9]╢[/color][color=#dcdedb]▓[/color][color=#dddedb]▓╢▓[/color][color=#e0dedb]▓[/color][color=#e1dfdd]▓[/color][color=#e3e2de]▓[/color][color=#e4e2de]▓▓▓[/color][color=#e6e2de]▓[/color][color=#e7e2de]▓▓[/color][color=#e8e3df]▓[/color][color=#e8e5df]▓▓▓▓▓[/color][color=#eae4e0]▓[/color][color=#eae5e0]▓▓▓[/color][color=#ebe4da]▓[/color][color=#ebe5da]▓▓▓▓▓▓▓▓▓▓▓▓▓▓[/color][color=#ede4db]▓[/color][color=#eee5dc]▓▓▓▓▓▓[/color][color=#efe6dd]▓[/color]    //
//    [color=#c7d2da]╣[/color][color=#c8d3db]╢╢╣╢╣╢╢╣[/color][color=#c8cfd8]╢[/color][color=#c7d0d9]╢╢[/color][color=#c7d1db]╢[/color][color=#c9d2dc]╣[/color][color=#cbd3dc]╢[/color][color=#ced4dd]╢╢╢╣[/color][color=#c6d2da]╢[/color][color=#c7d3da]╣[/color][color=#c6d1d8]╣╢╣[/color][color=#cdd4dc]╣[/color][color=#cdd6de]▓[/color][color=#ccd5de]▓[/color][color=#c6d0d9]╣[/color][color=#c4ced8]╢[/color][color=#c4cdd7]╣[/color][color=#c4cbd6]╢╢[/color][color=#cbd1dc]╢[/color][color=#ccd3dd]╣[/color][color=#ccd3dd]╣[/color][color=#cfd6df]▓[/color][color=#d1d8e0]▓▓╣╣▓▓[/color][color=#ced6dd]▓[/color][color=#cfd7de]▓╬╣▓[/color][color=#d1d9de]▓▓[/color][color=#d6d8de]▓▓▓▓▓[/color][color=#d6d9df]▓[/color][color=#d8dadf]▓▓▓╣▓[/color][color=#dbdde0]▓[/color][color=#dadce0]▓▓▓▓[/color][color=#d5dadf]▓[/color][color=#d6dade]▓▓▓[/color][color=#dcddde]▓[/color][color=#dddedf]▓[/color][color=#e0e0e1]▓▓▓[/color][color=#dde2e1]▓▓▓▓[/color][color=#dedfde]▓[/color][color=#dedfde]▓▓▓▓▓▓▓▓[/color][color=#e1dcda]▓[/color][color=#e2deda]▓▓▓▓[/color][color=#e2deda]▓▓▓▓[/color][color=#e5dfd8]▓[/color][color=#e5dfd7]▓▓[/color][color=#e7e0d9]▓[/color][color=#e8e2da]▓▓[/color][color=#e9e3da]▓▓[/color][color=#e4dcd6]▓[/color][color=#e4dcd6]▓[/color][color=#e7dfd9]▓[/color][color=#e9e1da]▓[/color][color=#eae3db]▓[/color][color=#ebe3dc]▓▓▓[/color][color=#ece4dc]▓▓[/color][color=#ede6dc]▓▓▓▓▓▓[/color]                                                                         //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      //
//    [/font][/size]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MB is ERC721Creator {
    constructor() ERC721Creator("My Baby", "MB") {}
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
// OpenZeppelin Contracts v4.4.1 (proxy/Proxy.sol)

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
     * This function does not return to its internall call site, it will return directly to the external caller.
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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