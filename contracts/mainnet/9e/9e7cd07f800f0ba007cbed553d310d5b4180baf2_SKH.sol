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

pragma solidity ^0.8.0;

/// @title: SKETCHES
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    BBBBG5Y5YY??JJJJJ?JJJJJJJJJJJJYYJJYY?YYYJYYY5YJJJJJJYYY555JJYJJJJJYYYY5YJJJJJJJJYYJJYJJYY55PP5PPPPP5    //
//    BBBBG5YYJ??JJJ?JJJJJJJJJJJ?JJJJJJJJYY5Y55Y5YJJJJJJ?J??J55Y5PP5JJJJYJYY5YJYJJJJJJYYYYJYY5YY5555P55PP5    //
//    BBBBG5???J???JJJJJJJJJJJJ???YJJ?JJJYYY55YJYYYJ?JJJJJ??J5YJJ5PP5YYJYJJJJJJJYJJJJJYJYYYYYYYYYY5GPPPPPP    //
//    BBBBPY??JJJJ?JJJJJJJJJJJJJJYYJJJJJJJJYYJ?JYY5JJJJJJJJJJ55555555Y55YJJJJJJJ5YJJJJYJJYJJJJY5PPPGPPPPP5    //
//    BBBPY??JJJJJJJJYJJJJJJJJJ?JJJYYJJJJJJJJJJYYJJJJJ5JJJJJJ55YY55YJJJJJJYJJ?YPYJYJYYYYJYYJY55PPPP55555Y5    //
//    BBGPYJ?JJJYJYYYYYJJJJJJJ?JJJJYJJJJYYYJJJYYYY55555555YYJJJYJY55JJJYJYYJYPGY?JYY555YY55555PYYY5555YYYP    //
//    BBBP5YJ??J55YYYJJJJJJJJJJJJJJ5PYJJYJJYJYYJJJYYYYYY5YJYYJJYJYYJYYJYY5Y5#GYYYYYJY5Y5Y55PY5PY5555Y55P55    //
//    BBBP5YJJJY5Y5YYJJJJJJJ?YYJJJJJPPYJJJJJYYJ?JJJJJJJJJJJYYYJJJYYYYYYYY5G#P55Y55YYJYJYJY5P5P5YYY555555Y5    //
//    BBBP5Y5YJYYJY5YJJJJJJ??JJJJ?JJ?PGJJJJJYYYJJJJYJJJJJJ?JJYYJJYYYYYJYGBB5YYJJYJJJJYYYJY55Y555Y5PPYYY555    //
//    BBBG5Y5YYJJJ5JJJJ??JJJJJJJJJJJ?JGGJ?JYYYJJJJYYYYY5JYYJJYYY5YYJYYYG#BYJJJJJJJJJJY5PP5PYY5Y55PP55555YY    //
//    BBBG5PYJYYJYJJJJJ?JJJJJJJJ?J?JJJYBBYJYYJJJJJJYYYPP5555YY555YYYYPB#B5YYYYYY555YY5PP55YYYYY555P5JY5YYY    //
//    B#BBPPYJJYJJJJ?J??JJJJJJ??JJJJJJJYB#5Y5YJJYJJJJJG5JYJJJJYYYJY5B##G5YY5YY55YYYYYYY555YY5JJ55555JY5JJJ    //
//    BBBBP5JJYJ?JY5JJ??JYJ?J??JJJJJJJJJP#B5JJJJJJJJJJGYJJJJJJJJJJPBBG5JYJYYYYYYYJJJYYYY5Y555YJY55555Y5YYY    //
//    BBGG5YYJJ?JJJYP5YYJJJ?J?JJJJJJJJJJJP#BYJJYJJJJJ5BJJJYJJJJJ5GBBPJYYYJJJJJJJJJJYYYYYY5PP55Y55Y55YYYYY5    //
//    BBGP5YYJJ?JYJJY5PPY????JJJJYJJJJJJJJB##5JJJJJJJP#YJJYJJJ5GBBGYJJ55YYYYYJYJJY5YJY5PGGYJYY55YJJYJYYYYY    //
//    BBB5YYJJJJJYYYJJJPGP5JJJJ??JJJJJJ?JJY##BGJJJJJ?G#YJJJJYG##BGYJJYYJYJJ5YYYJJY5PPP5JJYJJJJYPYYYJJY5YJY    //
//    BBP5YYJ?JJJYJJJJJ?J5GBPYJ?JJJ?J?JJ??JG&B#BYJJJ5#BJJ?JP#&&#PYJ?JJJYYYYJJYY5PGG5YJJJJYJ?JYY55JJYJY5YYY    //
//    BG5YYJJ?JJJJJJ?JJJJJJYPGB55JJJJ??????JG##&BYY5B#BJYPB&&&#GJJJJ?JYJJJY5PBGG55JJJJJJJYYJY55YY5YY5YYYJJ    //
//    BG5JJJJJJJJJJJ?JJJJ??JJJJG#BPYJ???????J###&#GB#BB##&#&#&#Y?JJJJJY5PGBBGYJJYYJJJJ?JJJJYY5YYYY5YYYJJJJ    //
//    BPYJJJJJ??J?J??JJJ?7JJJJ?YPB&#G5J??????G####&&&&&&&&&&###PYYYYPGB##BPYJJJJJJJJYYJJJJJJJYJJYYYYYJJJJJ    //
//    P5YYJJJJ??J?J??JJJ?7YJ???J?J5B&&BP5YJJJP##&&&@@@@&&&&@@&&&#B####BG5J?JJJJJJJYJJYJJJJJJJYJJJJJYJJJJJJ    //
//    P5YJJJJ??JJ?J?J?JJ7?YJ??YJ???YG#&&&#B#&&&&@@@@@&&@&&&&&@@@&&&B##G55Y555PPPPPYJYYJJJYJJJJYJJYYJJJJJJJ    //
//    5YJJJJYJ?JJJYJJJJJ!JJJ??Y??????5#&&&@@@@@&@@@&&&&&&&@&&@&&&&&####BGPPYYYJJJJJJJJJJJJYJJJJJYJYYYJJ?JJ    //
//    JJJJJJJJJJJJ555P55Y5YJ7JJ???????P&@&&@&@@@&&@&&&&&&&&&&@&@&&&&&#5YJJJ???JJJJJJJJJJYJJYJJJJJJYYY5YJJJ    //
//    5J??JJJJJJ????JJJ?YPPPPBGPPP55YYG&&&#&&&&&@&&&&&&&&&&&&@&@&&&&####BGP55YYYYJYYJ?JYYJJJJJ??JJJ?JYYJJJ    //
//    G5J??JJJJJ?JJ??JJ??JJ?J5YPPGB#B###&&&&&&&&@@&&&@&&@&&&&&&&&&&&&#####B##BBBBBGBGPPPGGPP55555Y5Y5YJJY5    //
//    BP5JJJJJJJJJJJJJJJJJ?7YJJJJ?Y5G#####&&&&&@&&&&&&&&&&&&&&&&&&&&&#BBBP555YY55YY5P55Y5GP55JYYYY55P5YYY5    //
//    BG555YYJYYJ?JJJJ?JYJ?7YJJJJJJJJJYG###&&#&@&&&&&@&&&&@&&&&&&&&&BYJYYJJJJJJJJJJJJJJJJJJJ5JJ?JYYY5YYYY5    //
//    GP55PPP5PPYJJJJJ?YJJ?JYJJYYJ?JJJY#&#BB###&&&&&&&&&&&&&&&&&&&&BBGPJ?JJJJJJJJJJJJJJJJJJYYYJJYYJYY55555    //
//    PJYYYYYYY5PP5YJ?JYJJ7YY?JJJ??JYP#####BB#####&&&&&&&&&&&&&&&&#55PPGPYJ?JJJJJJJJJJJJ?JJYYYYJJYJYYYYYYJ    //
//    GYYYYYYYJJJJY5PJYJJJ75J??JJJJJP#B#&&####&&&&&##&&&&&&&&&&&##BY??JJY5P5YJJJJJJJJJJJJJJ5YYYJ?YJYJYJY5Y    //
//    GP55YY5YYYYJJYYYP5Y?JYJJ?J??YG##B&&####&####&&&&&&&&&&#######BYJJJ??JJYYJJJJJJJJJJJJJJYJ5J?JYJJY555Y    //
//    PP555PPPP5Y5555YYPPYPY???JJ5B##B############BBBB#####PYYY5GB##BPYJJ?JJJJJJJJJJJJJJJJ??JJJJJJYJJ5G5YJ    //
//    PPY5555YYYY55PGGPPPGGP5555G##BBBBBGG######BG5YJJ5BB#G?JJJJJYGBB##GYJ?JJJJJJJJJJJJJJJJJ?JJJJ?YJJ55JYJ    //
//    GPYYYYYYY5555PGGBGPBGGGGGGGBGGGGGGGGGGGBB#GYJ????5##PJ?JJJYJJ5GGBB#G5YJJJJJJJJJJJJJJJJJJJJJ?YJJYJJYJ    //
//    G5YYYYYYY5555555PPBGPGGPGPGBP5PPGGGGGGGGGGY????J?JG#5J?JJJJJJJJJJY5B#BPYJJJJJJJJJJJJJJJJJJ??YYJJJJJJ    //
//    P5YYYYYYYY5Y5555YYBBBGPPPPGP55555PPPPGGPP5????JJ??5BY?JJJJJJJJJJ??JJ5GB#PJYJJ?JJJJJJJJJJJJJJYYYJYJYJ    //
//    P55YY55YYY55555YY5G5GBGP5PPP555555555PPP5YJ???JJJJ5BJJJJJJJJJJJJJJJJJJJP#BPY??JJJJJJJJJJYYJJYYJYYYYJ    //
//    P555YY5YYYY5555YJPP55PPGPPPPP555555PP55PPP5YJ?J???JGYJJJJJJJJJ??JJJJJJJJY5GBG5JJJJJJJJJJJJJJYJYYYJJJ    //
//    P5YY5YY5Y555555YYP555555PPPPPPP555PP5555PGG5YYJJ???5YJJJJ?JJJJ??JJJJJJJJJJ?J5GG5JJYJJJJJJJJJJJYJJJJJ    //
//    55YY5Y555555555YP55555PPPPPPP5PPP55PPPPPPPPGG555YJ???JJJ?JJJJJJJJ?JJJJJJJJJJ?JJPGPYJJJYJJJJJJJJJJJJJ    //
//    P555555555555555P55PPPP555555555PPP5PPPP5PP5PP5555YJ???J?JJJJ?JJ?JJ??JJJJJJJJJJJJYGPJJJJJJJJJ?JJJJJJ    //
//    P5PP5555555555Y55PPP55555Y55Y555555PPP5555555P555P55YJJJ?J?J?JJ??JJJJJJJJJJJJJJJ??JJ55JJ?JJJ?JJYYJJJ    //
//    555555555555555PPPP5555555YYYYYY55Y55PP55PP555PP555555YYYJJJJ???J?JJJJJJYJJJJJJJJ?JJJJJJJJJJJJJYYYJJ    //
//    55PPP55555555PPP555555Y5YYYYYYYYYYYYY5Y555555555555YYYY55555YJJJJJJJJJJJJJJJJJJJ?JJJJJJJJJJJJJJYYYYJ    //
//    5PPPPPP55555PP5555555YY55YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY5PPPP5YJJJJJJJJJJJJJJJJJJJJJJYJJJYJJJJJJJY    //
//    55PPPPPPP5PGP555555YYYYYYYY5YYYYYYYYYYYY5YYYYYYYYYYYYYY555555PPGGPYJJJJJJJJJJJJJJJJJJJJJJJ?JJJJJJJJY    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SKH is ERC721Creator {
    constructor() ERC721Creator("SKETCHES", "SKH") {}
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