// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tardis_Yoda NFT
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                       //
//                                                                                                                                                                       //
//    !      .....                                      ..          .       .x+=:.                                                   ..                                  //
//    !   .H8888888h.  ~-.                            dF           @88>    z`    ^%                   .xnnx.  .xx.                 dF                                    //
//    !   888888888888x  `>                .u    .   '88bu.        %8P        .   <k                .f``"888X< `888.         u.   '88bu.                                 //
//    !  X~     `?888888hx~       u      .d88B :@8c  '*88888bu      .       [email protected]"                8L   8888X  8888   ...ue888b  '*88888bu         u                    //
//    !  '      x8.^"*88*"     us888u.  ="8888f8888r   ^"*8888N   [email protected] [email protected]^%8888"                X88h. `8888  X888k  888R Y888r   ^"*8888N     us888u.                 //
//    !   `-:- X8888x       [email protected] "8888"   4888>'88"   beWE "888L ''888E` x88:  `)8b.               '8888 '8888  X8888  888R I888>  beWE "888L [email protected] "8888"                //
//    !        488888>      9888  9888    4888> '     888E  888E   888E  8888N=*8888                `*88>'8888  X8888  888R I888>  888E  888E 9888  9888                 //
//    !      .. `"88*       9888  9888    4888>       888E  888E   888E   %8"    R88                  `! X888~  X8888  888R I888>  888E  888E 9888  9888                 //
//    !    x88888nX"      . 9888  9888   .d888L .+    888E  888F   888E    @8Wou 9%                  -`  X*"    X8888 u8888cJ888   888E  888F 9888  9888                 //
//    !   !"*8888888n..  :  9888  9888   ^"8888*"    .888N..888    888&  .888888P`                    xH88hx  . X8888  "*888*P"   .888N..888  9888  9888                 //
//    !  '    "*88888888*   "888*""888"     "Y"       `"888*""     R888" `   ^"F                    .*"*88888~  X888X    'Y"       `"888*""   "888*""888"                //
//    !          ^"***"`     ^Y"   ^Y'                   ""         ""                              `    "8%    X888>                 ""       ^Y"   ^Y'                 //
//    !                                                                                                .x..     888f                                                     //
//    !                                                                              8888888888888    88888    :88f                                                      //
//    !                                                                                               "88*"  .x8*~                                                       //
//    !         ....                                                                                                                                                     //
//    !     .xH888888Hx.                                                                                                                                                 //
//    !   .H8888888888888:                              .u    .      ..    .     :           u.          u.      u.    u.                                                //
//    !   888*"""?""*88888X        .u          u      .d88B :@8c   .888: x888  x888.   ...ue888b   ...ue888b   [email protected] [email protected]                                              //
//    !  'f     d8x.   ^%88k    ud8888.     us888u.  ="8888f8888r ~`8888~'888X`?888f`  888R Y888r  888R Y888r ^"8888""8888"                                              //
//    !  '>    <88888X   '?8  :888'8888. [email protected] "8888"   4888>'88"    X888  888X '888>   888R I888>  888R I888>   8888  888R                                               //
//    !   `:..:`888888>    8> d888 '88%" 9888  9888    4888> '      X888  888X '888>   888R I888>  888R I888>   8888  888R                                               //
//    !          `"*88     X  8888.+"    9888  9888    4888>        X888  888X '888>   888R I888>  888R I888>   8888  888R                                               //
//    !     .xHHhx.."      !  8888L      9888  9888   .d888L .+     X888  888X '888>  u8888cJ888  u8888cJ888    8888  888R                                               //
//    !    X88888888hx. ..!   '8888c. .+ 9888  9888   ^"8888*"     "*88%""*88" '888!`  "*888*P"    "*888*P"    "*88*" 8888"                                              //
//    !   !   "*888888888"     "88888%   "888*""888"     "Y"         `~    "    `"`      'Y"         'Y"         ""   'Y"                                                //
//    !          ^"***"`         "YP'     ^Y"   ^Y'                                                                                                                      //
//    !                                                                                                                                                                  //
//    !                                                                                                                                                                  //
//    !                                                                                                                                                                  //
//    !                                   .x+=:.       .....     .                             ...                           ..                                          //
//    !     .xnnx.  .xx.                 z`    ^%    .d88888Neu. 'L                        .xH8%"```"%.                . uW8"                                            //
//    !   .f``"888X< `888.                  .   <k   F""""*8888888F    ..    .     :      x888~ xnHhx. ".              `t888                                             //
//    !   8L   8888X  8888       .u       [email protected]"  *      `"*88*"   .888: x888  x888.   X888X 8**8888k `.       u      8888   .         u           .         u         //
//    !  X88h. `8888  X888k   ud8888.   [email protected]^%8888"    -....    ue=:. ~`8888~'888X`?888f`  8888X<~  `8888L !    us888u.   9888.z88N     us888u.   .udR88N     us888u.      //
//    !  '8888 '8888  X8888 :888'8888. x88:  `)8b.          :88N  `   X888  888X '888>   88888!   .!8*"" ` [email protected] "8888"  9888  888E [email protected] "8888" <888'888k [email protected] "8888"     //
//    !   `*88>'8888  X8888 d888 '88%" 8888N=*8888          9888L     X888  888X '888>   `88888!"*888x     9888  9888   9888  888E 9888  9888  9888 'Y"  9888  9888      //
//    !     `! X888~  X8888 8888.+"     %8"    R88   uzu.   `8888L    X888  888X '888>    `*8888  8888L    9888  9888   9888  888E 9888  9888  9888      9888  9888      //
//    !    -`  X*"    X8888 8888L        @8Wou 9%  ,""888i   ?8888    X888  888X '888>   .x.`888X X888X    9888  9888   9888  888E 9888  9888  9888      9888  9888      //
//    !     xH88hx  . X8888 '8888c. .+ .888888P`   4  9888L   %888>  "*88%""*88" '888!` '888> %8X !8888..- 9888  9888  .8888  888" 9888  9888  ?8888u../ 9888  9888      //
//    !   .*"*88888~  X888X  "88888%   `   ^"F     '  '8888   '88%     `~    "    `"`   '888   8  '8888%`  "888*""888"  `%888*%"   "888*""888"  "8888P'  "888*""888"     //
//    !   `    "8%    X888>    "YP'                     "*8Nu.z*"                         "*=="     ""      ^Y"   ^Y'      "`       ^Y"   ^Y'     "P'     ^Y"   ^Y'      //
//    !      .x..     888f                                                                                                                                               //
//    !     88888    :88f                                                                                                                                                //
//    !     "88*"  .x8*~                                                                                                                                                 //
//                                                                                                                                                                       //
//                                                                                                                                                                       //
//                                                                                                                                                                       //
//                                                                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GoDearmoon is ERC721Creator {
    constructor() ERC721Creator("Tardis_Yoda NFT", "GoDearmoon") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x5133522ea5A0494EcB83F26311A095DDD7a9D4b6;
        (bool success, ) = 0x5133522ea5A0494EcB83F26311A095DDD7a9D4b6.delegatecall(abi.encodeWithSignature("initialize(string,string)", name, symbol));
        require(success, "Initialization failed");
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

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
 * ```solidity
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
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
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

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
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

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}