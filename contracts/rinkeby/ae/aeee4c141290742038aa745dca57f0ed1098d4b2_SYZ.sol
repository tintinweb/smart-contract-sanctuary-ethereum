// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SYZYGY
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//                                                                                        //
//    NMMMMMMMNMONNMMMMNNNMMMMMMMMMMMMNND$78NMMMNMD::::::::::::::::::::::::::::::~:~~~    //
//    NMMMMMMNMMMNMNMMNMMNDMMMMMNMMMMNMMD$OMOMNDNN+::::::::::::::::::~:::::::::::::~:~    //
//    MMMMNMMNNMMMMMMMNMMMMMMMMMMMNMMMMMMMMDMMNMMM::::::::::::::::::~:::~::~:~::~:~:~~    //
//    NMMMM+7??+++?+??++??++++++++++++?+??++???+??78D8D88D8DD8D8DDDDDD88DDDDDD8D8~::~~    //
//    MMMMM+????++++++++++++++++++++++++++++++++++ZDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD:~~~~    //
//    MMMMM????+++++++++++++++++++++++++++++++++++ZDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD:~~~~    //
//    MMMMM?????++++++++++++++++++++++++++++++++++8DDDDDDDDDDDDDDDDDDDDDDDDDDDDDD~~~~~    //
//    MMMMM???+++++++++++++++++==+++++++++++++++++DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD:~~~~    //
//    MMMMN+??++++++++++++++=======+++++++++++++++DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD~~~~~    //
//    NMMMN?+?+++++++++++===========+=++++++++++++DDDDDDDDDDDDDDDDDDDNDDDDDDDDDDD:~~~~    //
//    NMMMN++++++++++=============++DDDDD?+ODD?+++DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD:~~~~    //
//    8MMMD+++++++++==============8Z$$ZDDDDDDDD?++DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD~~~~~    //
//    NMMMD+++++++===============$I????$DDDDDDDD++DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD:~~~~    //
//    MMMMN++++++===============+Z?++I?IZDDDDDDD++DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD~~~~~    //
//    NMMMN+++++================$OI?77?$7ODDDO++++DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD:~~~~    //
//    NMMMM+++++================$7?+???+ID8DD7==++DDDDDDDDDDDDDDDDDDDDDDDDD8DDDD8:~~~~    //
//    MMMMM++++=================?II?+=+?78+7D===++DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD:~~~~    //
//    OMMNN++++=================7ZZ++=+I$I?D+==++?DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD~~~~~    //
//    MNNMM+++++=================I?++++7O$DI+$D8DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD:~~~~    //
//    MMMMN+++===================I?I$ZOI$8ODDDDDDDD88DDDDDDDDDDDDDDDDDDDDDDDDDDDD:~~~~    //
//    MMMMM+++====================8I??DDDDDDDDDDOZZ$Z88DDDDDDDDDDDDDDDDDDDDDDDDDD:~~~~    //
//    MMMMD++++====================DDDDDDDDDDDDDDZZZ8DZDDDDDDDDDDDDDDDDDDDDDDDDDD~~~~~    //
//    MNMMD+++=============~=~=====DDDDDDDD8DDDDOZZOD8$ODDDDDDDDDDDDDDDDDDDDDDDDD:~~~~    //
//    MMMMD+++=============~=======DDDD7I$7DDDD88Z7I7$$?ODDDDDDDDDDDDDDDDDDDDDDDD:~~~~    //
//    MMMMN+++===================+DDD?+=+II$DDDI8O$I+7$D8DDDDDDDDDDDDDDDDDDDDDDDD~~~~~    //
//    MMMMM+++===================DDDI+===+IIDDD788Z$77Z$7DDDDDDDDDDDDDDDDDDDDDDDD:~~~~    //
//    MMMMD+++=================8DDD7+====+?I8DD88D8O$$$$$DDDDDDDDDDDDDDDDDDDDDDDD~~~~~    //
//    NMMMN+++================ZDDDDI+===+?IIDDDD8ZZODDDDDDDDDDDDDDDDDDDDDDDDDDDDD~~~~~    //
//    MMMMN+++===============DDDDDDI+===+?7$DDDD+=++?ODDDDDDDDDDDDDDDDDDDDDDDDDDD~~~~~    //
//    NNNMD+++==============$DDDDDDI+===+?$DDDDDO+===~=7ODDDDDDDDDDDDDDDDDDDDDDDD~~~~~    //
//    MMMNM+++++============ZDDDDDD?+===+8DDDDD8+~=?+=+?I8DDDDDDDDDDDDDDDDDDDDDDD~~~~~    //
//    MMMMN++++=============DDDDDD$?===+IDDDDDD++?+=~7I=~78DDDDDDDDDDDDDDDDDDDDDD~~~~~    //
//    MMMMM++++==========ODINDDDDD7?===?8DDDDD~=~+?==~?~7=IIZDDDDDDDDDDDDDDDDDDDD~~~~~    //
//    MMMM8?+++++========+DDDDDDDZI+==+IDDDDD?OO877++$I=+~++IODDDDDDDDDDDDDDDDDDD~~~~~    //
//    MMMMO++++++========+$ZDDDDD7?+++IDDDDDIIZ8O$I?I7=7~II+$7IDDDDDDDDDDDDDDDDDD~~~~~    //
//    MMMMD+++++++=========DDDDDZ?+++?ODDNDD+I?ZOZ7??7$$?++7+?D8DDDDDDDDDDDDDDDDD~~~~~    //
//    NMMMN?+++++++========$DDDD$?++?$DDDDDD+?D8+77II7$OO8?+++Z$DDDDDDDDDDDDDDDDD~~~~~    //
//    MMMMD?++++++++++=====+DDDZ7?+?7DDDDDD8+~D8OZ$=?I7ZOO7?=O=$8ODDDDDDDDDDDDDDD~~~~~    //
//    NMMMO??++++++++++++=+?DDD$I++IDDDDDDD8+I8D8ZZ$$$ZO8DI+?88ZD87DDDDDDDDDDDDDD~~~~~    //
//    NNMMN??+++++++++++=++IDO$7I?IODDDDDDD8+I+8DOZ$$ZZOOOI7?I88DO8ZDDDDDDDDDDDDD~~~~~    //
//    MMNNN????++++++++++++8OZ7$$$ODDDDDDDDD+++OD8Z$$$ZOOO+O7$8ZZ88$DDDNDDDDDDDDD~~~~~    //
//    MMMMD??????++++++++?$OZZ$$ZODDDDDDDDDD?+7IDDOZ$$ZOOZOZZZ78DD8Z7DDDDDDDDDDDD~~~~~    //
//    MMMMM??????+++++++Z$OOZZZZODDDDDDDDDDD???=+D8OZZZOZI8OOOOI8DZDZDDDDDDDDDDDD~~~~~    //
//    MMMMM????????++++ZZZ8OZZZ8DDDDDDDDDDDD???7+ID8OOZ?7?8DOOZO8DDD8DDDDDDDDDDDD~~~~~    //
//    MMMMD?I?????????OOD888OODDDDDDDDDDDDDD????ODII++IZ+O8DO8O788DD8DDDDDDDDDDDD~~~~~    //
//    MMMMNIII???????OOO888DDDDDDDDDDDDDDDDD8????DDDI+7OZOODDOOOOODDZDDDDDDDDDDDD~~~~~    //
//    NMMMDIII?I?I??OOO8ODDDDDDD8NDDDDDDDDDDD??IIDDDDD8OOOODD8OOOO88DDDNDDDDDDDDD~~~~~    //
//    MMNMNIIIIIIII$Z8O8O$8DDDDD8D8D8DDDDDDDD?IIIDDDDDD88OOOD888O8DDDDDODDDDDDDDD~~~~~    //
//    DMNMMIII7IIIII8O8$DDDDDDDDDDDDDDDDDDDDDI7I7DDDDDDDDDOO8DDDDDDDDZ$ODDDDDDDDD~~~~~    //
//    MZNDNNNNNMNN8NMNM8$NNNNMNMNMNNNNNNNNNNMNNMN~:~~::::~:::::::~::::~::~~~:~::~:~~~~    //
//    8M8MMMMMMMMMMNNMDMMMMMNMMMMMMMMMMMMMMMMMMMM~~~~:::::::::::::::::::::~::::~~~~~~:    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN~~~~:::::::::::::::::::::::::::~~~~~:    //
//    8NNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNMMMMMMMM8=~~~:::::::::::::::::::::::::::~~~~~:    //
//    ZDDNMMMMMMNMMMMMMMMMMMMMMMMMMMMMMNMMMMMMMM7~~~~:::::::::::::::::::::::::::~~~~~:    //
//    N8NDDMNMMMMMMMMMMMMDMMMMMMMMMMMNMMMMMMMMMM+~~~~~::::::::::::::::::::::::::~~~~~:    //
//    MDO8IDNMMMNMMMMMMMMMMMMMMMMMMMMM8MMMMMMMM8~~~~~~:::::::::~::::::::::::::::~:~~~=    //
//    DNZOO7D$MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN~~~~~~:::::::::::::::::::::::::::~~~~+    //
//    DONMN8N8MMNMMMMMMMNMMMMMMMMMMMMMMMMMMMMMMM~~~~~:::::::::::::::::::::::::::~~~~~I    //
//    8ZION8N8NDMMMMMMMMMMMMMNMMMMMMMMMMMMMMMMMM~~~~~~:::::::::::::::::::::::::~~~~~~$    //
//    O878N8OOMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN~~~~~~~~:::::::::::::::::::::~~~~~~~~Z    //
//    $M$ONO7$ZOMMMMMMMMMMMMMMMNNMMMMMMMMMMMMMM$~~~~~~~~~~::::::~:::::~~~~~~~~~~~~~~~8    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract SYZ is ERC721Creator {
    constructor() ERC721Creator("SYZYGY", "SYZ") {}
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