// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: noOne
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                          //
//                                                                                                                                          //
//      ... .:. ...  ..  .:. .:.  ..  ... .:. ...  ..  .:. .:.  ..  ... .:. ...  ..  .:. .:.  ..  ... .^^ ... ::::..:. .:.  ..  ... .:.     //
//    ..  ... ...  ..  ... ... ...  ..  ... ...  ..  ... ... ...  ..  ... ...  ..  ... ... ...  ..  ..:!^..  .!!!~:. ... ...  ..  ... ..    //
//      ... ... ...  ..  ... ...  ..  ... ... ...  ..  ... ...  ..  ... ... ...  ..  ... ...  ..  ...:~!~^^^^~7!^. ... ...  ..  ... ...     //
//    ..  ... ...  ..  ... ... ...  ..  ... ...  ..  ... ... ...  ..  ... ...  ..  ... ... ...  ..  .^~!7YJ7~^.  ... ... ...  ..  ... ..    //
//      ... ... ...  ..  ... ...  ..  ... ... ...  ..  ... ...  ..  ... ... ...  ..  ... ...  ..  ..:^~~JJ...  ..  ... ...  ..  ... ...     //
//    ..  ... ...  ..  ... ... ... .:.  ... .!.  ..  ... ... ...  ..  ... ...  ..  ... ... ...  .. .^^~7Y!.  ..  ... ... ...  ..  ... ..    //
//      ... ... ...  ..  ... ...  .^^^^^^^^^7!:^:..... ... ...  ..  :^^:::.  ..  ..  ... ...  ..  .^~~!7Y: ..  ..  ... ...  ..  ... ...     //
//    ..  ... ...  ..  ... ... .......  .:.^7:^:^^^^^:.. ...  .. .~7!~!?J~^^:  ..  ... ... ...  ..:~^~!7J:.  ..  ... ... ...  ..  ... ..    //
//      ... ... ...  ..  ... ... .:.  ... .7:  ....::  .....::^~7YJ!~^~!7!7J?:.  ..  ... ...  ...:^^^~!JJ. ..  ..  ... ...  ..  ... ...     //
//    ..  ... ...  ..  ... ... .::. ..  ..!~ ...:..  ..  .:^^~Y5GP7?J?JJJ555Y^ ..  ..  .:::^^^^::^^:^~7Y?..  ..  ... ... ...  ..  ... ..    //
//      ... ... ...  ..  ... ..:: ..  .. :7.. ..:  ..::^^~~77J5PP!^755YJ55Y55:.  .. .^~!!!!!!!!^~~^^^!?5!. ..  ..  ... ...  ..  ... ...     //
//    ..  ... ...  ..  ... ....~^:::^^^^~J7~~~!!!^.  ..:.^~!7J5PJ^^~~JPGGPPGP~ .::^~!777!!!77!~~!!~~!?Y?!7^  ..  ... ... ...  ..  ... ..    //
//      ... ... ...  ..  ... .!77777777?YY7777!777!!~^:::77?JJJ7~^!7!7J5PGGG?:::^~!77!~^^^~~^^~!7!^~J5?!7??!: .::. ... ...  ..  ... ...     //
//    ..  ... ...  ..  ... ...!77!!7777J5?7777!!7!7!!~!!^^^^^~~^^~!~^^^^~!7~:^^!7J57^^^^^^~!!!!7?JJYY?7?????!~!!!~~: ... ...  ..  ... ..    //
//      ... ... ...  ..  ... .!7!!7!77?5?!!!!!!7??~^^~~~~~~~~!!!~~~^^^^^^::^^!?J5GPJ7~^^~!?JJJYYYJ??77?7??7!!!!!!!!!~. ...  ..  ... ...     //
//    ..  ... ...  ..  ... ...:!!!7!!!YJ!!!!!7JJJ7!?7J!~^^~~!77!^^^^~~~~~~!?JJY5PPPP57!7JY555YJ?7!~~!!77777!!!!!!~!??7:. ...  ..  ... ..    //
//      ... ... ...  ..  ... ..~!!!!!?5!!!~!7?JJ?7?5P7^^^^~!7!!~^^^~~!7?JYYYYYPP55PPPPP555YJ?!!!77!!!!!7777!!!!!!7777?~ ..  ..  ... ...     //
//    ..  ... ...  ..  ... ... .~!!!75?~!!7?????JJYPJ^!!!~!?7~~^^^^^^~7J5P5YY5G5Y5PP5J?77777??77?7777777!!!7!77777777?~. ...  ..  ... ..    //
//      ... ... ...  ..  ... ... :!!Y5777??77!!?Y5PY!J5?77??7!!!!~~~!!~~7Y5P55555GPJ!!!!77!!~^~~^^~!!77777777!~!!!!777:...  ..  ... ...     //
//    ..  ... ...  ..  ... ... ... ~Y~~!!77JJJJY5PGJ7J?7?J?77??JJJ????77J555555PP5?~!7!!~:  ..  ..  .:::^^^:...  :!77!:. ...  ..  ... ..    //
//      ... ... ...  ..  ... ...  :Y^  ..^J55555PP577!!!!!~~!7?JJ???JY55PPPP55PP5!~~~^:. ...  ..  ... ...  ..  .. ~77^ ...  ..  ... ...     //
//    ..  ... ...  ..  ... ... ...7?:~7JYPP55555Y7~^~!!~^^^^^~!777!7?YPPPPPPPP5?~:::.  ... ...  ..  ... ...  ..  .:^~!^. ...  ..  ... ..    //
//      ... ... ...  ..  ... ... ^P?Y5PPPP55PPJ7^^~^^~^^^^~~~!~~~~~!7J55PPPP5?:  ..  ... ...  ..  ... ... ...  ..  ..^:...  ..  ... ...     //
//    ..  ... ...  ..  ... ...  ^5Y7JPPPPPPGP7!!!!~~~~~!!!7??777??JYY555PGPJ~  ..  ... ... ...  ..  ... ...  ..  ... ... ...  ..  ... ..    //
//      ... ... ...  ..  ... ..~5PJJYPPPPPPY!~^!7777!77!!7???77?JY55P5PP5Y~. ..  ..  ... ...  ..  ... ... ...  ..  ... ...  ..  ... ...     //
//    ..  ... ...  ..  ... .:^!JP55PPPP5J7::^^^~777!77?JJY5YYY5PPPPPPPPPY  ..  ..  ... ... ...  ..  ... ...  ..  ... ... ...  ..  ... ..    //
//      ... ... ...  ..  ..~!!JGGP5J?7!^. ~!~~777?JY5YYJ???JY5PGGGGGPGGPP7. ...  ..  ... ...  ..  ... ... ...  ..  ... ...  ..  ... ...     //
//    ..  ... ...  ..  ...:7?!5P7^. ..  ..!~!7?YJJ?5J????JY5PGGPPPGBGGPPP5:..  ..  ... ... ...  ..  ... ...  ..  ... ... ...  ..  ... ..    //
//      ... ... ...  ..  :!J77G~  ..  ...:~^~7YY5777?YYJ777JYJY5PPPPGPPBGP^ ...  ..  ... ...  ..  ... ... ...  ..  ... ...  ..  ... ...     //
//    ..  ... ...  ..  ..!75JYY...  ... .^^^^!?57^7YJ!^^^^~!??JY5PP555PBBG!..  ..  ... ... ...  ..  ... ...  ..  ... ... ...  ..  ... ..    //
//      ... ... ...  ..  ~7PGP!. ...  ..^^^^~!?J~!YJ^^~~^~!!!!!75GPP55GGPJ:  ..  ... ... ... ...  ... ... ...  ... ... ... ...  ... ...     //
//    ... ... ... ...  ...^?P7....  .. ^~^~!!!??~YJ!^^^^~!7JYJ!!7PGPPGGGG5YJ~  ..  ... ... ...  ... ... .......  ... ... ...  ... ... ..    //
//      ... ... ...  ... .:5! .. ...  .~~~^^~~!?!Y5~^^^~~7JY5PGP55GGPBGGBGGPPJ:  ..  ... ... ...  ...::::::::^~!!~.... ... ...  ... ...     //
//    ... ... ... ...  .. ?Y.. ...  ...!~^^^^^~7JJY~::^~!7JY55PPP5PBPBGGGGGPPPJ!.^^^^. ... ...  ...^^^^^:::::^^7JJ^  ... ...  ... ... ..    //
//      ... ... ...  ... ^5^ ... ...  .!^^^^^~7JY5?:^!?YYJY55P5JYPPGGGPGPPPPP55PJ7JY55Y?77^. .^^::::::::::^~~~^~5Y:... ... ...  ... ...     //
//    ... ... ... ...  ..Y! .. ...  .. :^~^^~7J555!:7Y555555P57.~PPGGP55PP5PPPPPPP5555PGY5Y~:~?J7!^::^^^::!7~^^^JJ?!:... ...  ... ... ..    //
//      ... ... ...  .. !Y.. ... ...  ..~!~~!?J55P?~YP555P5555!..!PPPPP55PPPPPPGGGGGP5YYJJY5?^^7?7!!!!!!~~~^^~!7J??JY! ... ...  ... ...     //
//    ... ... ... ...  ^5: ... ...  ... ^7~!?J5PPP5~J5555PPPP5P5! !5PPPP55555555PPP5YYJJJJYYPPY!!!7!77!~~!!7?JY5555557.. ...  ... ... ..    //
//      ... ... ...  ..~~... ... ...  ..^^^~!?5YYP?.:!YPP55PPP5PP7 :?PPP555YYY5555YY5YYYYYPP5P5Y5PP5Y5J?YYYYYYYYY?!~^. ... ...  ... ...     //
//    ... ... ... ...  ... ... ...  ... ^!??JJJJY5J  .:!?JJY5P55PP7. :Y5P55555P55555Y5555PPYYYYYY5PPP555YYYYJYYYY~.  ... ...  ... ... ..    //
//      ... ... ...  ... ... ... ...  ..:JY5YYYYJ55:.. ..~!7?Y55PPP~..~YYP55PPP5PP55YY55PP55YYYYYYY5P5YY7?YYJJJJY^ ... ... ...  ... ...     //
//    ... ... ... ...  ... ... ...  ... .~?555YY5555~... .^!!7?Y55PY. .7Y5PP555PP5YYY555JJYYJJYY555Y5P5Y7^^7JYJJ7:.. ... ...  ... ... ..    //
//      ... ... ...  ... ... ... ...  ... :?55555Y5PP?.... ^!!!?Y555!.  7Y5PPPPP5YYYYY7: .::..!JY5P55P5YYJ7~!JJ7:  ... ... ...  ... ...     //
//    ... ... ... ...  ... ... ...  ... ....75PP555P5PY^ ... .^!?Y555!...^7J5PP5YY?7~. ... ... ^?YY5P5YYYYYJJ?!. ... ... ...  ... ... ..    //
//      ... ... ...  ... ... ... ...  ... ..:75PP55PP555!. ... :!7JYYY?: ...^!7!~^.  ... ... ....:!!~!?JJ??7!. ... ... ... ...  ... ...     //
//    ... ... ... ...  ... ... ...  ... ... .^75PP55PPP55~.. ...~?7JJJ5Y^ ...  ..  ... ... ...  ..  .....:.  ..  ... ... ...  ... ... ..    //
//      ... ... ...  ... ... ... ...  ... ... ^75PP55PP5P7 ... .?55PP555Y!. ...  ... ... ... ...  ... ... ...  ... ... ... ...  ... ...     //
//    ... ... ... ...  ... ... ...  ... ... ...^75PP55P55J:. ...^?55555555^.. ...  ... ... ...  ... ... ... ...  ... ... ...  ... ... ..    //
//      ... ... ...  ... ... ... ...  ... ... ..^7YPP555557 .. ..::^?5555Y~ ...  ... ... ... ...  ... ... ...  ... ... ... ...  ... ...     //
//    ... ... ... .... ... ... ... .... ... ...  .~?5P55555: ...  ...^~~:.... .... ... ... ... .... ... ... .... ... ... ... .... ... ..    //
//      ... ... ... .... ... ... .... ... ... ...  :~?55555J.. .... ..  ... ... .... ... ... .... ... ... ... .... ... ... .... ... ...     //
//    ... ... ... .... ... ... ... .... ... ... ...  :!JY555?:.. .... ... ... .... ... ... ... .... ... ... .... ... ... ... .... ... ..    //
//      ... ... ... .... ... ... .... ... ... ... ...  :!JJYJJ!.... ... ... ... .... ... ... .... ... ... ... .... ... ... .... ... ...     //
//    ... ... ... .... ... ... ... .... ... ... .... .. .!7??J5J~.... ... ... .... ... ... ... .... ... ... .... ... ... ... .... ... ..    //
//      ... ... ... .... ... ... .... ... ... ... .... ..^:^7Y5557  ... ... ... .... ... ... .... ... ... ... .... ... ... .... ... ...     //
//    ... ... ... .... ... ... ... .... ... ... .... ... ~^:7YY?~.... ... ... .... ... ... ... .... ... ... .... ... ... ... .... ... ..    //
//     .... ... ........ ... ... ........ ... ........ ..!!^!J!........ ... ........ ... ... ........ ... ........ ... ... ........ ...     //
//    ... ... ... ........ ... ........ ... ... ........ ^!^!?....... ... ... ........ ... ........ ... ... ........ ... ........ ... ..    //
//    ..... ... ........ ... ... ........ ... ........ ..^!~?~ ........ ... ........ ... ... ........ ... ........ ... ... ........ ...     //
//    ....... ............ ... ............ .............~7!: ........... ............ ... ............ ............ ... ............ ..    //
//    ...................................................!~:............................................................................    //
//                                                                                                                                          //
//                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract helpme is ERC721Creator {
    constructor() ERC721Creator("noOne", "helpme") {}
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