// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: !floradenza
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                           //
//                                                                                                                                           //
//    !floradenza~^^^^^^^^^^~~~~~^^^^~~~~^^^^^~!!!7!!YBBBG#BP!77!!!J5Y?7?55Y7~~~!!!~~~~~~~~~~^^^^^^^~~~~~~~~~~?55J~!!!~^~!~~~~~~~~~~~~!!!    //
//    ~^^^^^:::^^^~~~~^^^^^~~^^^^^^~~~!!!!YBBBG#GP!77!~!J55?7!?YY?~~~~~~~~~~~~~~^^^^^~~^^^^~~~~~~~J5JJ7!~~!7!~~!!~~~~~~~~~~~!!               //
//    ^^^^^^^^^^^^^^^^^^^^~^~^^^^^^~~~!!!!YBBBPBGG!!!~~~?5Y?!!!?J?!~~~~~~~~~~~^^^^^^^~~~~~~^~~~~~JY??!!7!~~~7?7??!~~~~^^~~~~~!               //
//    ^^^^^^^^^^^^^^^^^^^!7~!^^^^^^~~~!!!!5BBGPBPG!!!~^~?5Y?!!!!77!~~~~~~~~~~~^^^^^^^!!~~~!!~!~!?JYJ!~~!77!~~!??7~~~~^^~~~~~~~               //
//    ^^^^^^^^^^^^^^^^^^^~7!?J?~^^^~~~!!!!PBGP5GYG!!!~^~7YY?!!!!7!!~~~~~~~~~~~~~~~~~^!!^~~^!!~JY?YJ~^~~~7777!7Y5?~~~^^~~~^~!~~               //
//    ~~~~~~~~^^^^^^^^^^~!7?YYYJ^^^~~~!!!!5GGP5PYG!~~~~~!JY?~~~!777!~~~~~~~~^^^^^^^^^!~^^~~^!7J5?7~~~~^^~!77?Y5YJ7!~~~~~^^~!!!               //
//    ~~~~~~~~^^^^^^^^^^!????JYJ~^^^~~!~!!YPP555YG!~~7?77JYJ~~~~7777~^^^^^^^^^^^^^^^^!~^^^^!YYJY!~~~~^~~~^^~7?????!~7!~^^^^~~!               //
//    ~~~~~~~^^^^^^^^^^^~!!77?J7^^^~~~~~~~J5PY55YG7~!JY?JJYY!^^~!??7~^^^:^^^^^^^^^^^^~~^^^^J5JJ?~^^^^^~!77!~~!~~7??~~~7JJ?!77!               //
//    ^^^^^^^^^^^^^~^^^!!~~~~!~^^^^~~~~~~~?55Y5PYG?!7Y5YY5Y57^^~!??7~^^^^^^^^^^^~^^^^!?^^^7Y??J~^^^^^^~~~!7!~^^^^!Y7~!Y5??J7!!               //
//    ^^^^^^^^^^^^^^^^^^^~!!^~~^^^^^~^~^^^75P555JGJ!?PPPYG5PJ~^^!777~^^^~~^^^^^~~^^^~?Y7^~J?JJ7^^^^^^~~^^~!!~~~^~!77!~!77J!~~~               //
//    ^^^^^^^^^^^^^^^^^^^^!!^!~^^^^^~^~^^^~5P55PJG57YBGGPBPPP7!~~?7!~^^~^^^~~~~!!^^^~JJ?^!???J~^^^^^^^^^^^~!~~^~~~^^^^^7?7~!77               //
//    ^^^^^^^^^^^^^^^^^^^^^7~7^^^^^^~~~^^^^JP5YPYGP7YBGGGBGGBJ7!!7?!~~~^:::~~~~~7!^^~?7~7YYJ?7^^^^^^^^^~~~!!!7777~^^^^^~?!!?YY               //
//    ^^^^^^^^^^^^^^^^^^^^^~!7^^^^^^~~~~^^^J55Y5YPG?YBPPB#GB#J7!7J?!~~::::^^^^^^^7!~^~^!JYYYJ!^^^~^^^^~~~!!~~~~^^^^^^^^^7J5P55               //
//    ^^^~~~^^^^^^^^^^~^^^^^77!^^^^^~~~~~^^?55YYYY5JYGPYG#BGPJ?~7YJ!~~...:^^^^^^::~~^^^!?7?77~^^^~^~~!!!!!~^^^^^^^^^^^^7555P5Y               //
//    ^^77?J?!!~^^^^^^!!~^^^777^^^:^^~~~~^^7YJJJJ???JPP?YGBPY??~?J7~~!~::^^^~7!^:^::::^~~!!!!~^^^7~^~7!!!7!^^~~^^^^^^^?5YPP5Y5               //
//    ^^7???JJJJ!^^^^^^77~::!?7^::::^^~~~~~!JJ??????7JY?J5GPY?7~?7~^^!?7!^^^~!~^^^^^^:^~~~~!~^^^^~~~7Y!!77!~~~!!^^^^^!5YPG5Y5G               //
//    ^^!???JJ?JJ~^^^^:^7?~:~J?^:::::^~~~~~~??777?JY77J?7J5PYJ7!7!^^^^Y?7!^::^::^^^^^::^^~!~^^^^^^:^!7777!~^^~!!~^^^~?Y5G5YYBB               //
//    ^^~77777777~^^^^^::~7!^?7::::::^~!!!!~7J?77?Y5J7JJ77J5PJ777^^^^~5J??::::::::::^^~^~!7!^^^::::::~!~~^^~~~^~~^^^~JJPPYJPBG               //
//    ^^^~~!!~~^^^^^^^^::::~~77:::::::~!!!!~!YJ7??J55J?Y?7?J55JJ!~PY!PP55!:::::::^7?7??7!!!!^^^:::::::::^:^^~^:::::^~?J5YJYGP5               //
//    ^^^~!7!^::::^^^^:::::::~7:::::::^~!!!~~JY??JJ5PY?JY77?YPYY?J##5BGG?.::::::^J?Y5Y?!~~~~^^~::::::::::^^^^::::::^~??YJJY5YJ               //
//    ~~!!!~^:::::::^:^:::::::~^:::::::^~~~~~75Y?JY5PPYJ5Y7?J55YJP##GGGGPJ7~::::~JJ5YJJJJ?7~^~!^:::^^:::^^^:::::^^~~~?YYY5P5J7               //
//    ~~^^^^^^:::::::::^^::::::^::::::::^^~~~~JPYJY5PGGYYPY?JYP55GB#GB#BPP5Y~::^^~?5GGPGGP7~^~7^~Y55YY?~^^::::::^~~!!J555GPJ7!               //
//    ^^^^^^^^^^^^^::::::^^::::^^:::::::^^~~~~75P5Y5PGGG5PG5Y5PG5PGBGGGPP5YJ?!^^:^^^!5GGGY7^:~!^^?G5J?J7^:::::::^~!!75PPPGYJ?!               //
//    ^^^^^^^^^^^^^^^::^?557^:::^^:::::^^~~~~~~?PBG555GGG5GBP5GGGPPPYY55555Y7!!~^^^^^!?J!~~::^7!^:!?JJ!^:^:::::::^!7Y5PPPPJ?!~               //
//    ~~~^^^^^^^^^^^~~~?YYJ?!^^^^^^^^^^^^~~^~!~7YGBBP5PGGP5G#GGBPJJYPGBGPY?77!~~^^^^^~^^:^::::!!!~::7?~:^:::::::::^~PBGP55YY7^               //
//    ~!!!!!!~^^^^^^^~7J7?7!!^^^^::::^^^^~~~77!!J5YJJ5PGBBBGBBB5?JJYGPY?!~~~~^^^^^^^^:::::::::~!7!^:^77^:::::::^^^^!GBGP5P5J~^               //
//    ~77777777~^^^^^^^7~~!7~^^^^^:::^^^^^~~!!!~!77J5PPGGBBBBBBJY5Y55JJJYY?^^^^^^^^~!!~::::::::!7!!!^!?^:::::::^!^^JBBPPPP5?^:               //
//    ~7??7???7!^^^^^^^~^^^!^^~!!!!!^:::^^~~~!7!~~!?5Y~!?PBBBBGY55PPP5JJ5PG7^^^^^^7PGP!:^::::::^~^^^~~7~:::::::^7!!PBGPPGPY!::               //
//    ~~!~~~~~^^^^^^~!!~~^~7!7777!~^::^^!~~!~!77~^^^~^^^^JP5BGG55PPGGGPPGGP7~~^^^^~JY!^^^^::::::::::::!~::::::^:~7YGPPPPGP?^::               //
//    ^^^^^^^^^^^^^^~!!~~7YYYJ!^^~~^^~~~~^^~!!77!^^^^^^^^!?JGP55YPGBBGGBBGY?!~~^^^^!~^^^^^^^^:::::::::~!^^^^^^^^^!5P55PGGJ~^^^               //
//    ~~~^^^^^^^::::^:::^J55YY?^^^^~~~!~^^^~!!!7!~^^^^^^^^^75P55J7YGGGGGG5J!~!?!^^!!^^^^^^^^^^^^^:::::~!^^^^^^^^^?55Y5GGP!^^^^               //
//    7?7!^^^^^^^::::::::!????7^^~7!~^~~^^^^!!!77!~^^^^~~~~!Y55YY~~!J5JYY??7!!7J?!!^^^^^^^^^^^^^^^^:::~!^^^^^^^^!Y555GGBY^^^^^               //
//    7YJ7~~~~~^^^:^^^:::^~~7~^^^:~?J7~~^^^^~!7777!^~~7?77!!Y55JY7~~?7?Y?7P5?77JY?7!!!!!^^^^^^^^^^^^^^~7~^^^^^^~YPP5PGBB7^^^^^               //
//    ~77777!~~~!7~^^^^^^^^^?~^^^^:^?J7~~^^^~!7?77!~!7JJJ7~!JY5JY?~??^!7~755?7!7777?7!!!!^^^^^^^^^^^^^~7~^^^^^^7PGPGBGBP!^^^^^               //
//    !~~~~^^^^^^!?7~^^^^^^^77^^::^^^7J!~~~~~!7??77!~!JYY7~!JY5YYJ?J~:~!~~~?7~^~~~!!77!~!~^^^^^^^^^^^^~J7^^^^~!5G5PBGBG?~^^^^^               //
//    ~^^^^^!!~^^^^7?~^^^^^!JYJY?~^^^^!?7~~~~!7????!~~!?!^^~JY5YYYJ7^:~7~^!~^^^^^~~~!7~~!!!7~^^^^^^^^^~Y?^^^^!JG5P#BGBJ!~^^^^^               //
//    ^^^^^7GPY7^^^^~!^^^^!GPJJYP5J7~^^~!7~~~~7JJJ?7~~~~~^^~J5555YJ!^^!?~!~^^^^^^~~~~!7!^^^^^^^^^^^^~!!??~~~~?PP5B#BBY!!!!!~~~               //
//    ^^~~^~?J?!7~^^^^^^^^?PPPPPPG5JJ?!!!77!~~?YYJJ7~!!~~^^^?PPP5JJ7^^!?77~^^^^^~~^^~!!~^^^^^^~~~~~~~?7~!!~~75G5G#BGY77?J?!!JY               //
//    ^^^~~~~~~~!7!^^^^^^^~YPPPB57!?7!~~!!77~~?YYYJ7^!7~~^^^?GPPJJY?~^!??7~^^^^~!~^^^!~^^^^~!!!~~777!??!77775G5P#BPY7!~!~^^?5Y               //
//    ~~~!!~~~^^^^~!^^^^^^^~?55J^~!!!~^^!7!^.:!JY5Y!^^7~^^^^?GPY?JYJ~^7?7~^^^^:^!!~^^!^^^~77!~^^!???JYYJ?7?YPP5B#GY?~~^~~~~5P5               //
//    ~!7!!~~!~^^^^^~^^^^^^^^7~~!~^^^:^^~^::::^7?J?~^^~~^^^^?GPYJY5J~^??~^^^^^^:~!!^~!^~?7!~^^^^~?JYYP5J??J5P55#G5J!~~~~~~!5PJ               //
//    ~!!!~~!~^^^^^^^^^^^^^^^77~^^^^^^^^::::::~!7?!^^^^~^^^^?G5YY55J~!J^^^^^^^^^^!!~7!!7~^^^^^^^^~5PYG5JYJY5PYPB5J7~~~!!!!!77!               //
//    ~~~~!~~^^^^^^^^^^^^^^^^7~^^^^^^^^^^:::::^J5Y~^^^^~~!~^?P55555J!J?^^^^^^^^^^^!!?77^^^^^^^^^~YBYYGY5JY555YG5J!!!!7??7777!~               //
//    ~~~~~^^^^^^^^^^^^^^^^^~?^^^^^^^^^^^^::::~YY?^^~!7~!7~^?P555PGJ?P!:^^^^^^^^^^~7J!^^^^^^^^^~5BPJGGPYJ55555PY7~!!!???777!!!               //
//    ~~~~~~~~~^^^^^^^^^^^^^~?^^^^^^^^^^^^::::~JJ~~7?!^^^~^^?P5Y5PGYYP!!7!7??7!!~~^7?^^^^^^^^^~YBGJ5BB5J5PP55P5?~~!!!7?77!77!?               //
//    ~^~~~~~~~~~~~^^^^^^^^^!?^^^^^^^^^^^^^::^!J!~~~^^^^^~~~?P5YPPP5PY?J7?J?!~^^~~~7!^^^^^^^^^?GGY?BBGJYPPP5PPY~~~!!!7!!7~7!~^               //
//    ~^~^^^^~~~~~~~~~~~~~~^7?^^^^^^^^^^^^^::~77^^^^^^^^~!~^J5YYGP5Y5YY57!~^^^^^^^~7~^^^^^^^^~YP5?Y#BPJPPPP5557^~~~~!!~~~^!~^^               //
//    ~~~^^^^^~~~~~~~~~~~~~~?7^^^^^^^^^^^^::^!!^^^^^^^^^~^^^JYYJB55YJJY5!^^^^^^^^^^7~^^^^^^^^7YYY7GBGYYPGGP555!^^~~^~~^~^~!~^^               //
//    ~~~^^^^^^^^^^^^~~~~~~!J!^^^^^^^^^^^::^~!^^^^^^^~~~~^^~JJJJBY55755Y~^^^^^^^^^^7!^^^^^^^^7JJ??PPY?5GGPP5YJ~^^~^^^^:::^^^::               //
//                                                                                                                                           //
//                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract flrdnza is ERC721Creator {
    constructor() ERC721Creator("!floradenza", "flrdnza") {}
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