// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NOMO's Contract
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXNNKKX0OOO00KKKKKK0OOkk0KKKNXXWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXKKK00K0KKOd::::lk00KK0Oo::::oO000K0KXNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWXKKKK0KKKKKKK00Oo,....;x00KOc....'lO0000000000KXWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWNXXK0OkxxxkO0KKKKK000l.....;lxkc.....:k00000000000O0KXXNWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWNXXK0Oo:,'...',cdOKK0000o.......',......:O000000Odl::;;:cokKXNWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWNXK0K0d,...;lc'....:k0KKK0l..;,.....';'...:O0000Oo,...,,....,lk0XWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWNXKKKKKx,...,xK0d,....:k00KOc.'dx,...'dd,...;k000Ol....lOOo'....:kKKNWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWNXKKKKKKKo'...'d0K0l....'d0KOo'..:xd,.'okc....'lO00x,....o0K0o'....o00KKNWMMMMMMMMMMMMM    //
//    MMMMMMMMMMWNXKKKKKKKKKx,....;x0Kd'...;k00Odccclk0kdxOOoccccldO00k;....;xKKk;....o0000KKXWMMMMMMMMMMM    //
//    MMMMMMMMWNXKKKKKKKKKKK0d,....,lo;...;d000000000000000000000000000o'....;dkd,...:k000KKKKKXNWMMMMMMMM    //
//    MMMMMMMWXKKKKKKKKKKKKKK0ko;'....',:oO000000000000000000OO00000000Od:'....'...;oO0000KKKK000NWMMMMMMM    //
//    MMMMMMWXKK00O00KKKKKK00OO00OxxxxkO00000000OOOOO00000000O00000000000OkolcccloxO00K0000000KKK0XWMMMMMM    //
//    MMMMMWXKKkc,,,;cx0KKkc,,,;d0KKKK000000000OxdoodxkkkOO0000000000000000KK000KOocd000xoc:::clldO0NMMMMM    //
//    MMMWXKKKKOo,....':dOOo'..ck0K00000000000Okoc:::cloodxkOOOOO00000000000KKK0k:.;x0kc'...,:;...lO0NMMMM    //
//    MMMNKKKKKK0l.......;oo;.,xK0000000000000Okoc:::::cccloddddxxxkOO00000000KOl..'lko.....:odoc:d00KNMMM    //
//    MMWXKKKKKK0o............,xK0000KKK000000kxolccccc::cccccclllloodxk00K0000Ol...:kx,.......,;lk000XWMM    //
//    MWKKKKKKKKKo..;do;......,xKKK0000000000OkdollllccccccccccllllllooxO0000000Oxodk0koc;'.......:OK00XWM    //
//    WXKKKKKKKK0l..;k0Od:....,xK00000000000OkxdooolllllcccccllllloooodxO0000K00KKKKKO:'cxxdl'....;kKK00XM    //
//    WK0KKKKKK0o'...:kKK0xc'.;kK00000OO000OOkkxdddddddooooollooooooodxkO0000000000KK0o'.';:;'...;x0KK00KW    //
//    XKKKKKKKK0kdooox0KKKK0kdx0KK0000OOOOOOkkOOOOOOOOkkxxddxxxxxxxddxxkO00000000000KK0xolc:::coxO0KKKK00X    //
//    K0KKKKKKKKKKKKKKKKKKKKKKKKKK000OOOOOOkkkOOO000000OOkxxkO000OOOOOOOO00000000000KKKKK00000KKKKKKKKK00K    //
//    O0KKKKKKKKKKKKKKKKKKKKKKK00K0000OkOOOkkkkkkOOOOOOOkxddkO0000000000000000000000KKKK000KKKKKKKKKKK00Ok    //
//    O0KKKKKKKKKKKKKKKKKKK00000000000OkkkkOkkkxkkkkkkxxxdoodkOOOOOOOOOO000000000000KKKK00KKKKKKKKKKKK000O    //
//    O0KKKKKKKKKKKKKKKKKKKK00000000000OkkkOOOkkkxxxxddddolldxkkkkkOOOOO000000000000KKK0KKKKKKKKK000000000    //
//    00KKKKKKKKKKKKKKKKKKK00000000000000OO0OOOOkxxxxxxxxdddxkkkxxkkOO000OOOO0000000KKKKKKKKK000000000000K    //
//    0KKKKKKKKKKKKKKKKKKK0000000000000000000OOOOkkxxxxkkOOOOOOkkkkkO0000OOO0000000KKKKKKKKK00000KKKKK000K    //
//    0KKKKKKKKKKKKKKK0KKKK00000000000000000000OOOkkkxxkOO000OOkkkOOO0000000000000000KKKK0000KKK0000000000    //
//    OKKKKKKKKKKKKKKKKKKK0000000000000000000000OOOOOkkOOOOOOOOOOOOO0000000000000000000000000KKK000000000k    //
//    0KKKKKKKKKKKKKKKK0000000000000000000000000OOOOOOOOOOOOOOOOOOO00000000000000000000000000000000000000O    //
//    X0KKKKKKKKKKKKKK000000000000000000000000000OOOOOOOOOOOOOOOOO000000000000000000000000000000000000000X    //
//    X0KKKKKKKKKKKKKKKKK00000000000000000000000000OOOOOOOOOOOOOO0000000000000000000000000000000000000000N    //
//    WK0KKKKKKK0KKK000000000000000000000000OOOOO00OOOOOOOOOOOOO000000000000000000000000000000000000000OKM    //
//    MNK0KKKKKKK0KK000000000000000000000OOOkkkOOOOOO00000000000000000OOkO000000000000000000000000000000NM    //
//    MWXK0KKKKK000K00000000000000000000OOOkdodkOOOOOOO00000000000000OOxodk0000000000000000000000000000XMM    //
//    MMWXK0KKKK000000000000000000000OO0OOkdlccoxkOOOOOOOOOOOOOOOOOOOkxoccoxO000000000000000000000000OKWMM    //
//    MMMWX0KKK000000000000000000000OOOOOkdlc:::codxkOOOOOOOOOOOOkkxdolc::cldkO000000000000000000000OKWMMM    //
//    MMMMWXKK000000000000000000000OOOOkxdlc::::::clodxkkkkkkkkxxdolcc::::::cloxkO00000000000000000OKWMMMM    //
//    MMMMMWXK000000000000000OOOOOOkkxdolc::::::::::ccloddddddoolc:::::::::::::clodxxkkkOOO00000000XWMMMMM    //
//    MMMMMMWNK00000000OOOOkkxxdddoollcc:::::::::::ccllllccccclllccc::::::::::::::ccclllooddxkkkkOXMMMMMMM    //
//    MMMMMMMMNK000OOOkxddolllcccc:::::::::::::::ccclolccc::::ccclllcccc::::::::::::::::::cccclokXMMMMMMMM    //
//    MMMMMMMMMWX0kxdollcc:::::::::::::::::::::ccccccccc:::::::c::ccccccc::::::::::::::::::::lxKWMMMMMMMMM    //
//    MMMMMMMMMMMNOoccc::::::::::::::::::::::::::::::::::::::::cc:::::::::::::::::::::::::::lONMMMMMMMMMMM    //
//    MMMMMMMMMMMMWKxl::::::::::::::::::::::::::::::::::::::::::c:::::::::::::::::::::::::lxKWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWXOoc::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::ldOXWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMN0dl:::::::::::::::::::::::::::::::::::::::::::::::::::::::::clxKWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWXOdlc::::::::::::::::::::::::::::::::::::::::::::::::::cld0XWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWX0xoc:::::::::::::::::::::::::::::::::::::::::::ccok0XWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWNKOxolc::::::::::::::::::::::::::::::::::cldk0KNMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0Okdolc::::::::::::::::::::::loodkOKXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNX0kxolcc::::::::::ccldxk0XNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NOMOs is ERC721Creator {
    constructor() ERC721Creator("NOMO's Contract", "NOMOs") {}
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