// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TiTaV
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            //
//    [size=9px][font=monospace][color=#050918]█[/color][color=#060918]███████████████████████████████████████████████████████████████████████████████[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                //
//    [color=#060918]████████████████████████████████████████████████████████████████████████████████[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 //
//    [color=#060816]████████████████████████████████████████████████████████████████████████████████[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 //
//    [color=#060916]████████████████████████████████████████████████████████████████████████████████[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 //
//    [color=#050916]██████████████████████████████████████████████[/color][color=#1a0815]██████████████████████████████████[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          //
//    [color=#050b19]█[/color][color=#050a19]████████████████████████████████[/color][color=#240913]█████████████[/color][color=#2f0a10]██[/color][color=#050b1a]█[/color][color=#060a19]███████████████████████████████[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              //
//    [color=#050918]█████████████████████████████[/color][color=#190815]████[/color][color=#360f0d]█[/color][color=#290e0e]█[/color][color=#080a17]█[/color][color=#050b1a]██[/color][color=#1a0e0f]███[/color][color=#1a0f0e]█[/color][color=#080b17]█[/color][color=#050b1a]██[/color][color=#1f0e0e]█[/color][color=#42160c]██[/color][color=#050b1a]█[/color][color=#050b1a]█[/color][color=#160815]██████████████████████████████[/color]                                                                                                                                                                                                                                                                                                               //
//    [color=#050a19]█[/color][color=#050a1a]████████████████████████████[/color][color=#290913]█████[/color][color=#1a0d10]█[/color][color=#351a0d]█[/color][color=#46260c]██[/color][color=#693d0b]▓██[/color][color=#673e0b]▓[/color][color=#4a2d0c]█[/color][color=#45290d]█[/color][color=#3d200d]█[/color][color=#23120e]█[/color][color=#0f0b13]█[/color][color=#060b19]█[/color][color=#050b1a]██[/color][color=#290b10]█[/color][color=#170915]█[/color][color=#050b1a]█[/color][color=#050b1a]███████████████████████████[/color]                                                                                                                                                                                                                   //
//    [color=#060a19]█████████████████████████████[/color][color=#260a11]█[/color][color=#220b10]███[/color][color=#2c150d]█[/color][color=#301a0d]█[/color][color=#3a230d]██[/color][color=#422e0c]█[/color][color=#5d410c]█[/color][color=#573f0c]███[/color][color=#4e380c]█[/color][color=#3b2a0d]█[/color][color=#36240d]██[/color][color=#301b0d]██[/color][color=#30150d]██[/color][color=#2b0d0e]█[/color][color=#170a14]█[/color][color=#050b1a]█[/color][color=#050b1a]███████████████████████████[/color]                                                                                                                                                                                                                                          //
//    [color=#060a19]████████████████████████████[/color][color=#170814]█[/color][color=#1f0b11]█[/color][color=#32100d]█[/color][color=#441b0c]█[/color][color=#44200c]██[/color][color=#37210d]██[/color][color=#34270d]████[/color][color=#24210e]███████[/color][color=#4c290c]█[/color][color=#4a230c]█[/color][color=#401b0c]█[/color][color=#280f0e]█[/color][color=#1f0b11]█[/color][color=#150914]█[/color][color=#080817]█[/color][color=#050b1a]██████████████████████████[/color]                                                                                                                                                                                                                                                                 //
//    [color=#050a1a]██████████████████████████[/color][color=#150815]█[/color][color=#250814]█[/color][color=#2e0912]█[/color][color=#0d0915]█[/color][color=#0d0a14]█[/color][color=#1d0d0e]█[/color][color=#42200c]█[/color][color=#4c2a0c]██[/color][color=#31230d]█[/color][color=#2d230d]██[/color][color=#211e0e]█[/color][color=#0e1010]█[/color][color=#0d0f11]█[/color][color=#1c1b0e]█[/color][color=#38310d]█[/color][color=#2d260d]██[/color][color=#2f220d]█[/color][color=#51330c]█[/color][color=#4d2b0c]█[/color][color=#2f180d]█[/color][color=#120b12]█[/color][color=#0c0a15]█[/color][color=#2a0c0e]█[/color][color=#2f0b10]█[/color][color=#1d0815]█[/color][color=#050b1a]█[/color][color=#050b1a]█████████████████████████[/color]    //
//    [color=#050a1a]███████████████████████████[/color][color=#1f0814]█[/color][color=#2f0912]█[/color][color=#050b1a]█[/color][color=#160b12]█[/color][color=#59210c]██[/color][color=#050b1a]█[/color][color=#050b1a]█[/color][color=#3e280d]█[/color][color=#17120e]█[/color][color=#4e390c]█[/color][color=#40320d]█[/color][color=#372e0d]███[/color][color=#513f0c]█[/color][color=#16140e]██[/color][color=#050b1a]█[/color][color=#050b1a]██[/color][color=#652e0b]█[/color][color=#2f140d]█[/color][color=#050b1a]██[/color][color=#270a12]████████████████████████████[/color]                                                                                                                                                                     //
//    [color=#050b1a]█[/color][color=#050b1a]██████████████████████████[/color][color=#180815]█[/color][color=#240814]██[/color][color=#070a18]█[/color][color=#43150c]█[/color][color=#130b13]█[/color][color=#050b1a]█[/color][color=#050b1a]█[/color][color=#311d0d]█[/color][color=#60370c]█[/color][color=#20170e]██[/color][color=#67450b]▓[/color][color=#68470b]██[/color][color=#291f0e]█[/color][color=#4e310c]█[/color][color=#51320c]█[/color][color=#050b1a]█[/color][color=#050b1a]██[/color][color=#53200c]█[/color][color=#130b13]█[/color][color=#070a18]█[/color][color=#2f0b11]█[/color][color=#1f0814]█[/color][color=#050b1a]█[/color][color=#050b1a]██████████████████████████[/color]                                                  //
//    [color=#050b1a]████████████████████████████[/color][color=#1a0815]█[/color][color=#180815]█[/color][color=#050b1a]█[/color][color=#2c0b0f]█[/color][color=#1b0b12]█[/color][color=#050b1a]█[/color][color=#050b1a]██[/color][color=#1f120e]█[/color][color=#5f300b]█[/color][color=#44230c]█[/color][color=#2a180e]█[/color][color=#2b1a0e]██[/color][color=#64340b]██[/color][color=#060b19]█[/color][color=#050b1a]██[/color][color=#140b13]█[/color][color=#3c120d]█[/color][color=#060b1a]█[/color][color=#130815]█[/color][color=#210814]██████████████████████████[/color][color=#050a1a]█[/color][color=#050a1a]██[/color]                                                                                                                       //
//    [color=#060a19]█████████████████████████████[/color][color=#160816]███[/color][color=#260913]█[/color][color=#050b1a]█[/color][color=#050b1a]████[/color][color=#130c12]█[/color][color=#2c140d]█[/color][color=#31160d]█[/color][color=#1b0e0e]█[/color][color=#050b1a]█[/color][color=#050b1a]████[/color][color=#1d0a13]█[/color][color=#1e0a13]█[/color][color=#060a19]███[/color][color=#050b1a]████████████████████████████[/color]                                                                                                                                                                                                                                                                                                               //
//    [color=#060a18]███████████████████████████████████████████████[/color][color=#1a0816]█████████████████████████████████[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          //
//    [color=#060b17]█[/color][color=#060a17]███████████████████████████████████████████████████████████████████████████████[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          //
//    [color=#060917]████████████████████████████████████████████████████████████████████████████████[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 //
//    [color=#060a18]████████████████████████████████████████████████████████████████████████████████[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 //
//    [color=#050b19]████████████████████████████████████████████████████████████████████████████████[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            //
//    [/font][/size]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BTc is ERC721Creator {
    constructor() ERC721Creator("TiTaV", "BTc") {}
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