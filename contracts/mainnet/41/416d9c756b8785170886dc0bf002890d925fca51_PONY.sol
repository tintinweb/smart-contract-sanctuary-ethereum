// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: i am Pony
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                //
//                                                                                                //
//    XS%8 [email protected]@@@[email protected]@[email protected]@[email protected]@[email protected]@8888888888888888888888888    //
//    8S8888888:[email protected]@[email protected]@[email protected]@[email protected]@[email protected]    //
//    [email protected]@X8 Stt%[email protected]@[email protected]@@@[email protected]@[email protected]@[email protected]@[email protected]@@[email protected]@[email protected]    //
//    @888;88888888 8X88SS888St8. ..;[email protected]@@S8X;[email protected]@@[email protected]@@@[email protected]@@@[email protected]    //
//    88888%X8888888888%8X888888;t.:8%;@@[email protected]@S;St  [email protected]@[email protected]@[email protected]@[email protected]@    //
//    [email protected]@%;[email protected];[email protected]%;8X;[email protected] :8. ;[email protected]@[email protected]@[email protected]@@[email protected]@@8    //
//    [email protected]@88888X8888%S%[email protected] [email protected];  % [email protected]@[email protected]@[email protected]@[email protected]    //
//    [email protected]%Xt;.%8X8888:88;;t. [email protected]@[email protected]@8X88X88X8S888X    //
//    @[email protected]:[email protected]@.:8%X8XX88  t..: [email protected]@@@@[email protected]@[email protected]@@[email protected]    //
//    8X888888%;[email protected]@88888%: 88888X8S:;8 ... [email protected]@[email protected]@8X888    //
//    [email protected];[email protected]@8888.. [email protected] @88X tS; [email protected];[email protected]@[email protected]    //
//    @[email protected];8888X88888888888;888 SS8 :.S8SX8 .: . [email protected]%[email protected]@[email protected]@8XX8    //
//    @@[email protected];;X:8%[email protected]: ...  :SX88SS8S888S888X888S:[email protected]    //
//    [email protected]%[email protected]%88.:S%@8X:8:8:::::: .t;[email protected]%[email protected]@S8S8S    //
//    [email protected]@[email protected]@S8  8888888: S::.::[email protected] [email protected] @[email protected]@@8888888S8    //
//    [email protected]@@S88S888.888888888888888 @%%%8t;%@:t::;:.88t8 .%[email protected]@[email protected]    //
//    [email protected]@[email protected]@88X:8X88X88:88888888888SX:t.    .:;::tXt;@.:. S: 888SX8SS88888888X888S88888X888    //
//    8888888XXS8XX8XS88888;[email protected]%8888888t:S88; .::::;@S:88X;. 88S;@[email protected]@[email protected]@@@    //
//    [email protected]@[email protected]:::::;%@X::%@;. t [email protected]@S%%[email protected]@[email protected]    //
//    [email protected]@888888888 t.S:.::;%St;::.:[email protected]  .;@[email protected]@SSS8    //
//    [email protected]@[email protected]@t888888888888  ;;t%%:::..::;%[email protected]%:.t8 ;;tSS%[email protected]@88XS8    //
//    [email protected]:@@88:[email protected]@   t;;t::..:....:@@[email protected];8%8.tS8S.X.:%SX%%%%[email protected]    //
//    8888888888X..X8S %[email protected]@88S% .:........:;8%S8S:8XtttS8X8 :.  ..;%ttX%[email protected]    //
//    [email protected]::t%X%%.8%8888 8 8:888 @888SX% .:........:...8tS8:.:;t888%S88t:8;::;:%[email protected]    //
//    [email protected]@[email protected]@.X:8t8X88888.;8.888%[email protected]:88: .:.......:..:t8%S  ....:[email protected]% 88:8%S%tS88%    //
//    8888XXXX8XS 8.X :S888888t%8:8:[email protected] :.....::....;t;; .  ...:;:%@:;8 .8888.%@88%%8    //
//    [email protected]@8X8S [email protected];X:88::[email protected]::88 %888 8;:..:::.:.:.;XX [email protected]%.. ......:. ;8Xt8X.88.8888XX%@    //
//    [email protected]:@8 .%8%S :%@S8XSSXtt88;:; 8:%;:.  ;::::;X88X;; 8S.::.......:..X;88t .888SS88X%%    //
//    88888XXXXSt ..:S  [email protected]%%t88t  .%8X; .. :;;;::[email protected];;@@S:...........:t% ;S 8:88;tS8XXS    //
//    [email protected]@X%;..:t  888X8SSS%:.t: Xt :8  .:;;;:X%t8.888888X8 .:;%;....:.:[email protected]: 888:8;:tXXS%    //
//    [email protected]@ S..X ::.;888%8XS;tt :88Xt::88% .;;[email protected]:t%;;%:...:.:. :@8S8.8888%tt%t    //
//    8888SX%tt.8:.:X:[email protected];S888S.t :. ; :%;88888888888888X:;;.:::.:..:.:.  . : 888..:;;:    //
//    [email protected]%%t.;.;.t  X888SXXStSX88888X8 ;8: 8:888888888888888 t.;:..::.....::..   ;[email protected];:..:    //
//    88XSSS.X. S8%t:@ @@[email protected]@@@88888X888:88;[email protected]@8;:::t8;;:.:..:::.    %8 88888    //
//    [email protected]%8%[email protected]@X%;8%[email protected]@[email protected]%;@[email protected]@88888X%88X 88;8:8888S8888888X ::%@:[email protected]::::    ;8.8.88    //
//    @8SX S%X .;%%X::%.%S%%t . .8S88X888X8XX :; 88%@88.8888.888 @%%;888 8:S;:...::::.  S888.8    //
//    SSX t:XS 8;8%:..:;.8%@;;X  @88S8S8SS;[email protected]: @.8888888888888X88 X8888 S8;:.::::::  X8;8:    //
//    SS: 88XX @@ 8S...::;S.tt 8t; 88S888%[email protected]@8.88S%888 [email protected]@;[email protected] t;::::;::. .;.8;    //
//    tS @;Xt;%. St:.. .:%.;SX:@[email protected];8:88%[email protected]@SX8;[email protected]@8  888:88888%8: [email protected] ;St:;:::.. :8:8    //
//    t;%@8XXS.. ; %;.....:S8X8St8: :88;X% [email protected]@88:S.88 888S888888;88888888888t ;8t:.:::  X88    //
//    ;[email protected] SS8%[email protected];t  ...:[email protected]:X8  ;8XS8..%;8S88t8888XS888S8888:888 %888X8.8S:8.8;::.::::. %     //
//    ;. 8S ;: : 8tSt8%. ...:St%t; :: XX;X::S8S888::[email protected]  . S8X8888:888888888888:8 @  :..:::tX:     //
//    ; X::t S X;  t;[email protected]@  ....S8;..%:%%;8X%::8t;8%8; 8888 [email protected];@[email protected] 8:   .::.%SX888    //
//    StS8:8:8S S @:S%S8X  ...:%:. [email protected];%;[email protected]%t;88 88t;[email protected]@ [email protected]@8888 8;..   :::88S8888    //
//    XX %;SX: S%8%8SX%:t%. ...:[email protected] S:;S8 S8; @ X%X;8888888 [email protected]@8888:.    .;X%  @[email protected]    //
//    SS%S.X88.S   ;%Xt; XX. [email protected]  ;8%[email protected]::t;  88;X8  88 88:88888XXS 8X:.  .   @:   8 [email protected]    //
//    %XSS:8tX% :: X%%%;@8 ;.....: XX:[email protected] ;8 t..8t;8:88;;t%S8:888888X 8%:.  .   ;:::.    S 8     //
//    SXX%[email protected] %8 ;8%[email protected]%8:S;.t:..tt88 @8%8:; ;[email protected];:8.  ...88t 88X8S;.  .  ;8t  %S%:   S 88    //
//    SX%XXSt:.XS%[email protected]; S  8S8.  t;;8;t;X;@; ;.:8:..::.  . .:@    8t.. . t8t8SS% :SXS:     8    //
//    %%[email protected]%%%%.;88SSSXX   ;t%88 8XS.; 8%XX8%XS... .:%t  .   .. .;%8.. :%[email protected]   :%S8t:@X8SXS    //
//    %[email protected]%S;XSt:.. S  :t;[email protected];%.;t%X:%%88t:%X8tX88:  .    .  ;8%8S; ;8 8  :[email protected]@%[email protected]:.:    //
//    %SS%t%SSXXXS%.         .;[email protected] t;tt8: : ;:S8S%:.%X%@ 888tS.. .S8SStS% t%8  .;[email protected]%t 88: @ :    //
//    ;t:: .;tSXXS: tSS   8 8 88..:@ .;.8X%t%@[email protected]%XSX;@8: :;8. [email protected] [email protected]  :;%%;: ;tt8. X:    //
//                                                                                                //
//                                                                                                //
//                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////


contract PONY is ERC721Creator {
    constructor() ERC721Creator("i am Pony", "PONY") {}
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