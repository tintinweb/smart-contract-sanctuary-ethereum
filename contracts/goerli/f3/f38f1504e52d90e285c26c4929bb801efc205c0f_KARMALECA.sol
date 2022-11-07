// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC1155Creator is Proxy {

    constructor() {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x0C2F5313E07C12Fc013F3905D746011ad17C109e;
        Address.functionDelegateCall(
            0x0C2F5313E07C12Fc013F3905D746011ad17C109e,
            abi.encodeWithSignature("initialize()")
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

pragma solidity ^0.8.0;

/// @title: Karma_Extasis By LECA
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    BBBBGGG5J??7777??YYYYY55YYYYYYYYYYYYYYYYJJ?!~^^~~!7J55?~~~~~~!7?JJJJJJJJJJJJJJJJYYYYYJ??7777777YPGGG    //
//    BBBBGGG5J??77777?YYYYYYYYYYYYYYYYYYYYYYYJJ7!^^^~~7JJ!?Y7~~^~~!7?JJJJJJJJJJJJJJJJJYYJYJ?777!!777YPGGG    //
//    GGGGGGG5J??77????YYYYYYYYYYYYYYYYYYYYYYJJJ7!^^^~~!!!^~77!~^^~!7?JJJJJJJJJJJJJJJJJJYJYJ??7777777JPPGG    //
//    GGGGGGG5555G5Y5PP5YYYYYYYYYYYYYYYYYJJJJJJJ?!~~~~~7!?YJ7!!~~~~7??JJJJJJJJJJJJJJJJJJJJJJPG5Y5PP5YYPPGG    //
//    GGGGGGG5J7?YP5PPJJYYYYYYYYYYYYYYYJJJJJJJJJJJ??????YP5P5??????JJJJJJJJJJJJJJJJJJJJJJJJJJJP5PP?77YPPPP    //
//    PPPPPPP5J7?YGPJ77JYYYYYYYYYYYYYYJJJJJJJJJJJJJJJJJY5GPGPYJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ?!7JPPJ!!YPPPP    //
//    PPPPPGP5Y5G5?7!7?JYYYYYYYYYYYYYYJJJJJJJJJJJJJJY5PGGP5P5555YJJJJJJJJJJJJJJJJJJJJJJJJJJJJ!!!!JPGY55PPP    //
//    GGGGGGG5Y5G5?7!77JYYYYYYYYYYYYJJJJJJJJJJJJJJJ5GGGP5PP555PGG5JJJ???JJJJJJJJJJJJJJJJJJJJ?!!!!JPPJ55PGP    //
//    GGGGGGG5J7?YPPJ77JYYYYYYYYYYJJJJJJJJJJJJJJ555PPP55YYYJYYJJJJ??YJ?????JJJJJJJJJJJJJJJJJ?77JPP?!!55PGG    //
//    GGGGGGG5J777JGP?7JYYYYYYYYYJJJJJJJJJJJJJYPG5J?????777!~~^^^~7?5PYY?????JJJJJJJJJJJJJJJ?!?PG?!!!55PGG    //
//    GGGGGGG5Y!7JGP?!7JYYYYYYYYJJJJJJJJJJJJJ5PPGY???77!!JJJ!^^^^~7?5PG5??????JJJJJJJJJJJJJJ?!!7PBY!!55GGG    //
//    GGGGGGG5Y!!7?5G5?JYYYYYYYJJJJJJJJJJJJJYG5PG5??777~~?YY~^^^~7?J5PG5JJ?????????JJJJJJJJJ?75P5?!!!P5GGG    //
//    55555555Y7!!!!7YPPYYYYYJJJJJJJJJJJJJJJYPPGG55YJ?7!^~Y7^~!7JYP55PGPYJJ?????????JJJJJJJJYPY7!~~!!5Y5PP    //
//    ?????77777!!!!!?GPYJYYJJJJJJJJJJJJJJJJY5BPGPYJYYYJ?!J!!JYYJ??J5PPP5YJJ????????JJJJJJJJ5GJ!~~~~~7777?    //
//    777777777777775GJ?JJYYYJJJJJJJJJJJJJJJY5PJGG5J7!!~~~Y!~!~~~~7JPG555YJJ???J????JJJJJJJJ?7PP?!!!!!!!!!    //
//    Y?77?PPPPPPPPGGJ7JJJJJJJJJJJJJJJJJJJJJYYPPPBPYJ?!~~!57^^^^^!?YGPG5JYJ???J??????JJJJJJ??!!PGPPPPP5!!!    //
//    P?77?GGP??7YGGP?7JJJJJJJJJJJJJJJJJJJJJJJY5PBG5Y?77~?YJ7^^^~7J5PPPY?????????????JJJJJJ??!!5GG?7?PP7!!    //
//    5?77?PG5!!~YGGP?7JJJJJJJJJJJJJJJJJJJJJJJJJYY5G5YJ?JYJJYJ~~7J5JJJJ??7???????????JJJJJ???!!5GG7~!PP7!!    //
//    5?77?GBG555PGBP?7JJJJJJJJJJJJJJJJJJJJ????????YPPYJJYJJJ?7?Y5?77777777???????????JJJJ???!!5BBGPPGG7!!    //
//    Y?77?555555555Y77JJJJJJJJJJJJJJJJJJ??????????7?5GP5YJJJYGB5?77777777?????????????JJJ???!~?JJJJJJJ!!!    //
//    77777!!!!!!!!!!!7JJJJJJJJJJJJJJJ?JJJ???JJYJYY5PGBBGPPPPPPPPPPP5JJ??777??????????JJJJ???!!~~~~~~~~!!!    //
//    J?777?JJJJJJJJJ?7?JJJJJJJJJJJJ?JPGP555GG55YYYGBBBBGGGGGGGGGGP5?7??JJ??JJJ??????JJJJJ???!!?JJJJJY?!!!    //
//    G?777JGBPPGPGGBP7?JJJJJJJJJJJJYPGP5Y5B#5YYJJ???JJY55555YYJ?7!~!!7??5GGGJJ5Y????JJJJJJ??!~YBGPPGBY!!!    //
//    G?777JGBGGGGP5GP7JJJJJJJJJJJJJGGGP5Y5#BYJJ?7777!!!!~~^^^^^^^^^^~7??5GGP??J5Y???JJJJ????!~YBPPGGBY!!!    //
//    Y?7777JJJJJ5GGBP7JJJJJJJJJJJJPGP5YJ?PBGYJ??7!!!!~~~7JJ7^^^^^^^^~!7?5PP55Y??5J??JJJJJ???7~YBGGY?J7!!!    //
//    77777!!!!!!!75BG?JJJJJJJJJJ?YGGP5YJJPGGY??77!!~~~^J555Y?^^^^^^^~!??YJPP5YY55Y??JJJJJ???77PGY!~~~~~!!    //
//    77777!!!!!!~~~?PGYJJJJJJJJJ?5BGP55YPYPB5??7!!~~~^~5J??5!^^^^^^^~7??Y?5PP55YYY???JJJJJ??YGY7~~~~~!!!!    //
//    YJJYJJJJJ!!!~~~7GGJJJJJJJJ?JPGPYJ?5P?5BPJ?7!!~~~!!?YYY7!!~^^^^^~77?Y?JGP5YJY5J??JJJJ??YB5!~~~~~7YYYY    //
//    PPPPPPP55!~~~!JP5JJJJJJJJJ?YGGP5YYPJ?JBGY?7!!~~YBGGGGGGGBY^^^^^~77JY??PGP55Y5J??JJJJJ??J5PJ!~~~?P5PP    //
//    GGGGGGG55!!!JP577JJJJJJJJJ?PBG5YYP5???PBPJ?7!!~PBGP555YPB5^~^^~!77Y???YPPYYYYY???JJJJ??7!7YPJ!~?P5GG    //
//    GGGGGGGP57!75GY77?JJJJJJJ?JGGP5JJPJ???JBG5J?7!!PB5PPPPPYB5^~~~~!7?Y7???PP5YJYY???JJJJ???!!JPP?!?P5GG    //
//    GGGGGGGP57!!!YBP7?JJJJJJJ?YBGP555PJ????PBPY?77!5B5PPPPP5G5^~~!!77JY7???PP5YJYY?????JJ???!JBP!~~?P5GG    //
//    GGGGGGPP57!?PPJ!!?JJJJJJJ?5GG5YJY5?????JGG5JJ?7PBGP5PPPGB5^~~!777Y?77??5GGYY5Y????J?J???!!?5PJ!?P5GG    //
//    GGGGGGGP57JGP7~~!?JJJJJJJ?5BGGGPGJ??????YBPYJJ?YPPPPPPPPPJ^~!!77JY77???JPGP5PPP?????J???!!~!YGJ?P5GG    //
//    GGGGGGGP57!?5GJ!!?JJJJJJJJGBBGPGB5???????5BG5YJ??77!!~^^^^^~!77?Y?7777?75GBBBGPJ????J???!~7557!7P5GG    //
//    GGGGGGGP57!!!JGP7?JJJJJJ?YB5Y?!~JY???????JGGPP5YJJ?77!!!!!77?JY5Y777777?Y#B5?!~J????J???7?PY!!!7P5GG    //
//    GGGGGGGP57!!?PPJ7?JJJJJJJ?PPY?!^!Y????????PGGGGGPPPP555PPPPPPPPGJ7777????55J?~^!J?????J?7JG57!!755PP    //
//    PPPPPPPP57?5GJ!!!?JJJJJJJJGPYJ!^~YJ???????5GGPP5555555555555PPPP?777??????55Y7~^!J????J?7!7YPY7755PP    //
//    PPPPPPPP55BP7!!!!?JJJJJJJJGP5J7~~JJ???????YGBGGPP555555PPPPPPGGP77777?????JP5J7~^?J???J?7!!~75GY55PP    //
//    GGGGGGGPY?JPPY7!!?JJJJJJJJPG5J7~^JJ???????JGGPPPPP5555YYYJJ??J5Y77777??????YPY?!~^?J??J?7!!7YPY?55GP    //
//    GGGGGGGP5?77?PG5?7JJJYJJJJPG5YJ!^?55Y55YYYYGGP55YJ????7???JY5PGP555YYYJJ????5PYJ?77YJ?J?!7YGY7!755GG    //
//    GGGGGGGPY???JP5YG5JYYYYJJJ5G55J7~!GGPGPGPGGGGGGPPP555555PPPPGGGGPP555PPPP5YJ?PGP?~~75JJJ55J55J7755GG    //
//    GGGGGGGPYJY5P5YJY55YYJJJY5PGP5Y?775P5PP5PPPP555PGGGGGGGGGGGGGGGGPP5YYYY5PPPPP55J?!^~JJJP5YYYPP5J5PGG    //
//    GGGGGGGP5??77777!7JY5PPGGBBGGGGPPPPG5Y5P55GGP5YYJJJJJJJ????J5PGGGGPPP55555YYY5P555Y5JJJ?!777777?5PGG    //
//    GGGGGGGP5??77!77?YPGBGGPGPGBP5Y55YJYGPY5GPGG5?!!?YYJJJJY?~~!J5PBP5YYYYYYYYJJJYGP555YYYPGY?!!777?55GG    //
//    GGGGGGGP5J7?J5PGGBGPP5PPGPG5YPPJJY5?5BPPP5PG57~?PGYYPBY557~~!YPP5Y??777!!!!!!7J55YJY5PGGGG5J777JY5GG    //
//    GGGGGGGP5YPGBBGGGPPPPP5GGGBJ5PP7^7JJ5PYYJJ5GY7~?PGGG##GPP?~~~75PGG5YYJJ??777!77J5PPP55PPPGGG!^~7?J5P    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract KARMALECA is ERC1155Creator {
    constructor() ERC1155Creator() {}
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