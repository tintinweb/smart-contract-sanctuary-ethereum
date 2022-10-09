// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OCTOPUSSY GANG
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    55P5Y!^Y#G55555PGY5PBBPP55555555555P55555555555555555PGBG5YY#P555555PP555555555555555555555555555555    //
//    YPP?^:5B5555555GP?JJJYPBB5Y555555GPG555555555555555PGGYJJJJJPP555555GP555555555555555555555555555555    //
//    5GY: J&55555555#PJJJJJYY5GP555555555555555555555Y5BPYJ?JJJJ?P#55555555555555555555555555555555555555    //
//    PG?^.J&55555555#PJJJPYY55J5BG5555555555555555555PG5J5PPGGJJJP#55555555555555555555555555555555555555    //
//    5GYJ??B55555555BGJJ?P5 .5GY5BBPPPPPGGGPPPGGPPPPPBP5BGG55BYJJP#55555555555555555555555555555555555555    //
//    5PGJJ!~P5555555PP?JJJBJJPPPYYYJJJJJJJJJJJJJJJJJJJYYY5P5JBY??P#55555555555555555555555555555555555555    //
//    55PGY~.^Y555555GBYJYPG5YJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ?JYYJYYPG55555555555555555555555555555555555555    //
//    555PGJ! .?P55555BGGPYJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJYPBP5P555555555555555555555555555555555555    //
//    55555G57~~7Y555YPBYJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ?JJJJJJJJJJJPB5GP55555555555555555555555555555555555    //
//    555555PGY7.75PPPB5?JJJJJ?JJJ??JJJJJJJJJJJJJJJ?!~??77?5YJJJJ?5#5Y555555555555555555555555555555555555    //
//    55555555PY!JJJJPB5JJJYYY??JJ?Y??JJJJJJJJJJJJ777~!^:::!!JYPP55BP5555555555555555555555555555555555555    //
//    ??Y5555555PP5YJ5BBGGPJ^: .:.::^??7?JJJJJJJJ!!!:::~~^:  .!Y5G##G?7?7555555555555555555555555555555555    //
//    Y~!~J55555555PGG#P5P5!   ?P~~^  . :!7?J?!^~.. .~!!~!Y^ .!~?PG#B555Y^YP555555555555555555555555555555    //
//    P55J^~P5555G5PPPGG55PJ.  ^P~!~      ..~^      .~~!???~^~7?J5###555Y 7G555555555555555555555555555555    //
//    555P7^^Y555PG55YP#P55Y!^ .7~~:        ..       ..:7JJ!.:^7YBGG5YJ^.!5555555555555JYYYYY5555555555555    //
//    5555Y7.^B55555555GBG?^.    ..                    :^:   :^YBB5Y!:^7Y555555555P5JJ7~77:^7!~^7?Y5555555    //
//    G555Y?:~5555555555GGG5Y7!::.                   .:::!!?YPPBG55PB555555555555PJ555Y555Y5PY5J7~^!?Y5555    //
//    #P55Y7 ~P55555555555GBGGGPP5JJJJ?~^^^^^^^~?JJJJPPPGPGP5PBPP555555555555555PPJ55555555555555P5J~^!555    //
//    GG557: ~G5555555555555PGPPGPGGGGGPBPYYYYYGBPGGGPYYY!!~~.:^7J5P5555555555555PY7P555555555555555P5?!YP    //
//    P555!!~P555555555555555555555PBBPPGYJJJJJ5P55PPYYYYY5P5J?J~..~YP55555555555YGY!G5555555555555555P57J    //
//    5GG5555Y5J!Y5YP555555555555PG5JJJJJJJJJJJJJ5YJJYY555P5YY555Y!~^!5P55555555555Y!GY555555555555555Y5PY    //
//    YG5J?^^P5P555???555555555GGYJJJJJJJJJJJJJJJJJJ5GG5PP55PPP5YJ5PY: !Y555555555G!7G5555555555555555555B    //
//    5PGJ7 .Y555555PJ:?555555GPJJJJJJJJJJJJJJJJJJ7: ^PP5555555PGPYJ55~ ~5G55555Y577P55555555555555555555B    //
//    5YG5?: ~P555555BJ:P55YPGYJJJJJJJJJJJJJJJJJJJ!   ~G5555555555G5JYPJ: !J!!?J7YY5555555555555555555555G    //
//    555GY^ :7PP5555P? Y55GGYJJJJPJJJJJJJJJJJJJJJ?.  ^G55555555YJYPGJJPY: ~PYY5555555555555555555555555PG    //
//    5555BP?!?JY555P5!!YY5YJ?JYPG5JJJJJJJJJJJJJJJJ!  :555555555?7JYPPYJPY:.~P5555555555555555555555555PY!    //
//    555555GPYJJ?^:~.:!???JY5P5YJJJJJ5B5JJJ?YGGJJ?!^ ^G55555555555555GYJG?^.~P5555555555555555555Y5PYYJ!Y    //
//    55555555PPP5!^~~~?YY5PY~7??JJJ5BBYJJJJ5GPGPJ?.:.^G55555555555555P5JYP!.:?P555555555555P5J555Y5PG5PPY    //
//    55555555555P5PPGPPGP?:  ^?JJ5GG5JJJJJGGJJGPJ?. .55555555555555555BYJP^ .JP555555555555YJJ55555GYYG55    //
//    555555555555555Y5GJ:    .75GBPJJJJJYG#5?JGPJ?. ~P5555555555555555BYJPJ~:JP5555555555Y~7555555GYYP555    //
//    PJJJ555555555555PY^.!!!^~5GB5JJJ?JPY^PPJJBYJ7. 55555555555555555PPJYPJ: JP555555555P~JG55555GYYP5555    //
//    55PJJ5555555555PJ7.^7JJPPBPJJJJJ5P577PBYYGJJ~ !P555555555555YY55GY?5PJ7~P555555555P7^G55555PYJG55555    //
//    555P??P5555555GJ!:.:!JPPG5JJJJ5P5YGBP5PPP5J~. JP5555555555555Y5PY?JGY!~55555555555J.?G5555PG5P555555    //
//    5555~5555555YG5J!..?JPPG5J?JPBPY5PP5555GBJJ^  JPPGY5555555555P5J?YPJ~~55555555555PY JB55555555555555    //
//    55P7!P5555555GYJ7.:?5GBY~!?PGPPGG55555YG#JJ^  !P5P55555555P55YJJ5Y^.!5555555555555J. ?P5555555555555    //
//    555~P555555YGBJJ7.~?P#5~^7PGPPGG55555555P5J?^  5PPP5PP5Y555JJJ5Y!:!PP5555555555555B! ^B555555555555P    //
//    55Y~G55555555GYJ!. .?#Y .5GPPGG5555555555GJJ~..^PY?7?!~:.!JJ557775P555555555555PPYG7 :PG55555555555B    //
//    55Y~G5555555YG5J7^.  JB!~GPPPB55555555555GPJJ~. :5?~7!!??55YYYY5P55555555555555555PP: .PB5555555555B    //
//    55P~555555555PGJJJ::  ?5GGPPBP555555555555G5JJ^. .JBGGGGGG555555555555555555555555YG7^~Y#P5555555555    //
//    55P7~P55555555GPJJ!~.  .7PBGB55555555555555P5J7~:  ^JGP555555555555555555555555555YGY?77BB5555555555    //
//    555P!7P55555555G5JJ?7^.  :!JPP55555555555555PPYJ7^.  ^~J555555555555555555555555555PY! ~BP5555555555    //
//    5555P7~?Y5555P7.7GYJJJ?7::.:^^?5P55555555555Y5BPJ5?:    ^7YY555555555555555555555YG5J7::G55555555555    //
//    555555Y!~7!~~~!Y55555YJJ?7J7.  :?55P55555555555PPGPJ!^: .  .!?Y555555555555555555PPYJ7..G55555555555    //
//    5555555PP55555555555PGP5YJJJ7^..:.^!J5555555555555GG5Y?77~:   ..^7JY55555555555PG5YJ!. YB55555555555    //
//    5555555Y555555555555555PPPPYJJ???~   ^!YP55555555555PGP5YJJ!7~~~^:...~7YYJ5PPPPY??~: .JB55555P555555    //
//    GGGP555P55555555555PG55555PPG5YJJ?7!. .:755555555555555PPPP5YYJJJJ?7~:    :^^^^.   .7GB55555P5555555    //
//    77JYGGGBGP555555555PP555555555GGPYJJ~.:  :5P5555555555555555PGBPP5YYJJ7!!!7^ ::^^!YPBG55555555555555    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract OPG is ERC721Creator {
    constructor() ERC721Creator("OCTOPUSSY GANG", "OPG") {}
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