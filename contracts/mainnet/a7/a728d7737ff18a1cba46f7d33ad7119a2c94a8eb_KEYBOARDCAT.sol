// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Keyboard Cat
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//    J????JG&BG#&############BPPP5PG#&######&&#B###BBGPPPPP5?7JJYP#&#######&&####&&#######&####&&#####&##    //
//    ?????JG&BGB#########&&##5YPP55Y5G##B##BBBBGGGGP5PPPPP5?7?JJ5G#&&#B##&##&####&&###&&####&##&&&###&&##    //
//    ?????JP&#G###&&#####&###YYPP5YYYJYPPPPPP5555YYYY5PPGP????Y5B#######&&&##&&&######&&&##&&&####&##&&##    //
//    ?????J5&#GB&&#####&###&&GYY555YJJYYYY555YYYY55555YY5J?JJ?YG#&&##&&####&#&&&###&&####&##&&###&&&###&&    //
//    ?????JP&#GB&&###&#######B5Y555YJJJY55YYYYYJYY555555YJJJJ?5#&&###&&&##&&&###&##&&###&&&####&##&&###&&    //
//    ?????JP##BB#####&###&#BPPP55YYYYY55555YYYYYYYY5JY5YYYYJJJY5PB#&#######&&###&&####&##&&###&&&###&&#&&    //
//    ??????YB&#B###&######GPPPPGPP5PPYYYYYYYYYYYYY55YYY5YJ5JJJJJJY5G####&&######&&&##&&&###&&#&&####&&###    //
//    ??????JB&#B#######&#PPPGGPGGGPPP55555YYYY5YYYP5?YYY5YJJYJ???JJJ5#&#&&###&&####&#&&&##&&&&##&&&#&&###    //
//    ??????JG&#B#&###&##GPPGGPPP5555555555555YJJYJYP??JJJJJ?JJ???JYYJP&&######&###&&&###&&#&&###&&&&##&&&    //
//    ??????JG&#G#####&&#BPPP5PP5555YY555YY55YJJJYYYY??JJ?JJ?Y??JJ?YYJ5#&##&&####&##&&###&&###&&&#&&###&&&    //
//    ??????JP&BG###&#####BP55555YYYY5555555Y????JJYYYY7??JJJJJYJ?JJ??5#&&######&&&###&&#&&###&&&###&&##&#    //
//    ??????JP&#G#&#&####&#BP55YYYJYY555YYYJJJ?????JJJP5????J55JJ?????5#&&#######&&###&&&##&&&#&####&&&###    //
//    ??????JP&#G#&&#####&#G5555YYJJJJJJJJJJJJJ????JJJYYYJ???YYJ?7???JY5GB#####&###&&##&###&&&###&&#######    //
//    ??????YB&#B#&&##&&##PYY55555YJJJ????JJJJJ??????JJ??JYYJJ?7??Y??YYJJYYYYYY5GGG######&##&####&&&##&&&#    //
//    ??????5B##B######&#5YYYYYY55YJJYJ??????JJJ??????JJ???J5J7?JJYY7YYJJ??????JJJJJJYPB#&&###&&##&###&&&&    //
//    ?????JGB##BB##&&#B5YYYYYYYJJJJJJJ???J??7?J???????JJJ?JJ?JYJJJYJYYJJ?????YYJJ??77?JPBBB###&&##&&&#&##    //
//    ?????5BB&&BB&&##BYJJYJJJJJJJJJ????J?JJ?777777??????????JYJYJJ55YJJJ????Y5Y5Y7???????JJJY5PB###&&###&    //
//    ????JGB#&&#B#&&BY?JJJJJJJJJ?JJ???????JJY?77777????????JJJ??YY5PYJJ????J5555J?J?7???JJ?????JY5GB####&    //
//    ???J5BB&&&####BYJJJJJJJJJJJ??????7??7??55??J???JJ??????JJYY555P5?J????YPYYJJJJ777??JYJJJJ?????JJJY5G    //
//    JJJJPB#B#&###GYJJJJJJJJJ????JYYJ?????77YP???77?YY??????J5PPP555PYJJJJY55YJJJ??777??J5J?JJ?JJ????????    //
//    JJJJ5BBPG&##GYJYYJJJJJJ?J5G5JJYY55YJJJJYY?77???J??????JYPPPPPPPPGP5YY5PPYJYJJ?77???J5J???JJJ????????    //
//    JJJJJY5YP&&GYJYJYYJJJJJJ5GPJ?J5P5YYYYYJJJJJ???????????YGPPPPPPPG#&#BGGGBBPP55YJ????JJYJJJYYYJ??????7    //
//    JJJJJJJJP&BYYYYYJYJJJJJ??JJJJY5YJJJ?JJJYYJJJYJ?????JJYPPPPPGP55&&&&#&&&####BB#BGGPGPP5PPGGGGPYJ?????    //
//    JJJJJJJJYPPY??JYYYYYJJJJJJYYYYJ??????Y5YJJJYYJJJJJJJYPPPPGG5Y5B&&&&&&&&##&&&&#&&#&&&###&&####BBPYJJ?    //
//    JJJJJJJJJP5JJYJJJJJJJJJJYJYY5J??????JYJ???JJJJJJJJJJJY5PGG5J5#&&##&&###&&&&&##&&&######&&####&&&##G5    //
//    JJJJJJJJ5PYJYJ????JJJJJJJYJJYY??JJJ????????JJJJJJYYYYJJJ55YG&&#&&&#&###&&###&&&&&###&&&##&&&&&##BBBG    //
//    ?JJJJJJYP5Y7JJ?????????JJJJJJYYJJJJ????????????JJYYYYYYJ?JYGB##&&&##&&&&&###&&###&&&&&#BBBGPP5YYJJJJ    //
//    ?JYYY55555Y?7YJ???????????JJJJJJYYYYYJJJJJJJJ??JJJJJYYJJ?????5#&&&##&&&##&&&&###BGGP5YY?????????????    //
//    B####P5YY55J7?YYJ??????????JJJJJJJJJJJJJJJJJJ?JJJJ??YJ7???????Y#&&&&#####BGP5YYJ?777777777777???????    //
//    &&&#5YYYYYY?7??Y5YJJJJJJJJJJJJJ???????????????JY????Y?7??JJ???YB##GPYYJ?J7777777777777?????7???YGBP5    //
//    &&#YJP5Y55YJJJ??JYYJJJJJJYYYYYYJJJJJJYYYYY555PPP5YYYY????YJ?JJJ???777777777777777777777JGBG5J?5&&&&&    //
//    &&5?5G5YY55YYYYJJ??JJJJ?JJJYYY5555555PPPPGGGGGGGGP5YJ???YY?J??77777777777777?J?7777???Y#&####BGPGB&&    //
//    &GJ?GGYY?5PPYYYYYYYJJYYYYYYYY555555555PPP5555JJ??????7777???77777??JJJ??77JG##B5J7!7??JYPB###&&&BGPP    //
//    BYJJGG5YJY5P5YJJJJYYYYY555555555555YYJ???7777777777777777?????????5B#BPY?JG&&&&&#BPJ7777??YPB#&&&&#B    //
//    5YJYPG5YYYYYJJJJY5P5YYYYYYYYYYJ???77777777777777777777JYJ?7?????J5#&&###BPYY5B#&&&&#B5J7!77??J5G#&&&    //
//    5YYYPG555YYJJY5J?JY555J?777777777777777777777?JJ?77??P###G5J??JJJJYPB#&&#&&BPYJ5B&&&&&#B5?!!777?J5G#    //
//    G5JJ555PYJYYJJJ?777777777777777777777??77777YB##B5J?5#&&&&&#G5J??JJJJYPB#&&&&#BY?J5B#&&&&#PJ7777??J5    //
//    BPJJJJJ????777777777777777777777777JPBBGY77Y#&&#&&#G5JYG#&&&&&#GY?7?J??JYPB#&&&#BP?7J5B#&&&#B55PGB##    //
//    J?777?77777777777777777?7777777777JB#####BPJJ5#&&&&&##PYJ5B&&&&&&B5?77?????YPB###&#GJJ5B&&##########    //
//    !777777777777777777775B#B5?!!77????YG#####&#GY?YG#&&&&&#GY?JP#&&&&&#P?7??????YG&####################    //
//    77777777777J5PY?!77?G&###&#PJ7!7?????J5B####&&B5??5B&&&&&&BY??YG#&&&&#PJ5PGB########################    //
//    ?77777777?5B###B5?7?YG#&##&&&BY7!77?????YP####&&#5?7JP#&&&&&B5?J5#&&################################    //
//    G5J?77777JG##BB###PJ77JP####&&&B57!!7??77?JPB###&&#P?7JG&&####B#####################################    //
//    P55P5J7777?JPB#BB###GY77?5B####&&B5?!!7???77?YG##&&&BGGB######################B########&&###########    //
//    YYYY5P5J77777JP##BB###GJ77?YG####&&B5777??JY5PG#########################################&&&&########    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract KEYBOARDCAT is ERC1155Creator {
    constructor() ERC1155Creator("Keyboard Cat", "KEYBOARDCAT") {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC1155Creator is Proxy {

    constructor(string memory name, string memory symbol) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x6bf5ed59dE0E19999d264746843FF931c0133090;
        Address.functionDelegateCall(
            0x6bf5ed59dE0E19999d264746843FF931c0133090,
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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