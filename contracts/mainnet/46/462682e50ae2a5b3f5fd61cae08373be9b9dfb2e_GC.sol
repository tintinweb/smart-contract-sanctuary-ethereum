// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Gabe Checks
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&######################&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&################################&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&###&&&&&&&&&&&&##########################&@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@&&&#######&&&&&&&&&&&&#####BBB###########################&@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@&#######&&&&&&&&&&&&&&&&&#####BB###############################&@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@&&######&&&&&&@&&&&&#####&&&&#####&&&&&&&&#######################BB#&@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@&######&&&&&&&&&&&&###BB###&&&&&&&&&#######&&&&&####BB####BBBGB##BBBGG###&@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@&##B###&&&&&&&&&&&&##BBB###&&&&&&&########&&&&&&&&&&&##BB####BGGGBBBGGPPGBBB#@@@@@@@@@@@@@    //
//    @@@@@@@@@&####&###&&&&&&&&&###BGGBB########&&&#####&&&&&&&&&&&&&&&&&&&##BGGPPGGGP555GBGGG&@@@@@@@@@@    //
//    @@@@@@@@&######BB##########BBBGPPPPGB#####BBB######&&&&&&&&&&&&&&&&&&&&#BBGPPPPPGPP5Y5GPPB&@@@@@@@@@    //
//    @@@@@@@@&&###BBBBBB######BGPP5YYYY5PPGGGBBBBB##&&&&&&&&&&&&&&&&&&&&&&&&##BGPPPPP5PPPP5YPGB##&@@@@@@@    //
//    @@@@@@@@&#####BGB######BGP5YYJJJJJJJYYY5PPGGBBB##&&&&&&&&&&&&&&&&&&&&&&&&&##BGPP5YYYY55YYGB#B#@@@@@@    //
//    @@@@@@&###&&BGG#&&###BP5JJJ???777????JJJYYY5PGGBB###&&&&&&&&&&&&&&&&&&&&&&&&&#[email protected]@@@@@    //
//    @@@@@&#B#&&#B#&&&##BGYJ???77777777777?????JJJY5PGGBB#&&&&&&&&&&&&&&&&&&&&&&&&&#BPYY5PPYPGBPYYY5#@@@@    //
//    @@@@&##B&@&##&&###G5J?7777777!!!!7777777777??JJY5PPGGGB###&&&&&&&&&&&&&&#&&&&&&@&#G5YYYJYYPPY???P&@@    //
//    @@@&#&#B&&#&&&&#B5J?777777!!!!!!!!!!!77777777???JJJYYYYY5PPGB#&&&&&&&&&&&#####&&&@&&[email protected]@    //
//    @@@&#&##&&&&#BGPJ?777777!!!!!!!!!!!!!!!!!7777777??????????JJJY5PGBB##&&&&&&####&&&&&&[email protected]@    //
//    @@&#&&&&&&#GYJ???77777!!!!!!!!!!!!!!!!!!!!7777777777777???????JJJY55PPPGGBBBBBB#&&&&&&#B#BPYYPYYJJ#@    //
//    @@#&&&&&&GJ7777777777!!!!!!!!!!!!!!!!!!!!!!!77777777777777??????JJYYY5555PPPPGGGB#&&&&&&##[email protected]    //
//    @&&&&&&#5?7777777777!!!!!!!!!!!!!!!!!!!!!!!777777777777777??????JJJYYY55555PPPPPGGGB##&@&&&BGGGPGB&@    //
//    @&&&&##PJ7777777777!!!!!!!!!!!!!!!!!!!!!!77777777777777777??????JJJYYY55555555PPPPPGGGB#&@@&#BBBB&@@    //
//    @&#&##B5?777777777!!!!!!!!!!!!!!!!!!!!!!!!7777777777777777??????JJYYYYYY5555555555PPPGBB#&@&&#B#B#@@    //
//    @&####BY?7777!7!!!!!!!!!!!!!!!!!!!!!!!!!!!777777!!!7777777??????JJJYYYYYY55555555555PPPPGB#&&&BBBB#@    //
//    @&####GY?777777!!!!!!!!!!!!!!!~~~~~!!!!!!!!777!!!!!7777777??????JJJYYYYYY555555555555555PBB#&&#BBBB&    //
//    @&####B5?777777777!!!!!!!!~~~~~~~~~!~!!!!!!77!!!!!!!777777??????JJJYYYYY55555555555555PPGG##&&&B#B#@    //
//    @@####BPJ777777777!!!!!!!~~~~~~~~~~!!!!!!!!77!!!!!!!77777??????JJJJYYYYY55555555555555PGBBB#&&&####@    //
//    @@&###BGY?77777777!!!!!!!!!!!!!!!!!!!!!!!!7?7!!!7!!77777????????JJJJJYYY5555555555555PPB####&&&&##&@    //
//    @@&####B5?777777777?JYYYYJJJJJ????777777777?7!77777777????????????JJJJJYY555555555555PG##&&&&&&###@@    //
//    @@@####B5?7777777J5PPGGGPGGGBBBBBBGP5YJJ????7!7????????JJYY5555555PPPPP55YY555P55555PPB#&&&&&&&##&@@    //
//    @&5JP###P?777777?J555555PPPGBB######BBGPYYJ?7!7?YYYYY5PPGB##############BGP555P5P5555GB&&&&&&&##@@@@    //
//    @P?7?P##BJ7777?????77?JY55PGGB#BBBBGGGPP5J?!!!7?YPPPGBBB###&&&&##BGGGGBB###BGP55P5YY5G##&&&&&&B5G&@@    //
//    @G557?G#BJ777777777?YPGGP5G#[email protected]&B#P5PGP55J7!~~~7?YPGGGBBBBBBPB#[email protected]#B#BBGPPPGGGGGPP55JJYPB##&&&#B5J7J&@    //
//    @&JY?7YBBY77777777?J55YJ???5PGPP5YY5P5J??7!~~~!7JPGGGGPBGGY?YB#&#B#GB##BGPPPPPP5YYJ?J5GB#&&#GP5PPY#@    //
//    @@P?7~!P#5777!!!!77??7?????JJJJYY5555YJ777!~~!7?JPGGGGPP55YYJY5PPPPPPGBBGGPPPPP55YJJJ5G#&#GP555PP5&@    //
//    @@&J!~!Y#P?77!!!!!!!!!!!777???JJJJJJ?7777!!~!!7?J5PGGGGP5YYYYYY55PPPGGGGGPPP55555YYYYPB##P5555PP55&@    //
//    @@@Y~!7YGG?77!!!!!!!!!!!!!~!!!!7777!!!!!!!!~!!7?Y5PPPPPP5YJJJJJYYY555PPPP5555555YYYY5G#&[email protected]@    //
//    @@@?!7JJ?5?77!!!!~~~~~~~~~~~~!!!!!~~~~!!!!!~!!7JY5PPPPP55YJJJ???JJJJYYYYYYYYYYYYJYY55B##[email protected]@@    //
//    @@#7!?J7!YJ77!!!!~~~~~~~~~~~~~~~~~~~~~!!!!~~~!7JY5PPPP555YYJJJ??????JJJJJJJJYYYJJJY5PBBYPBGGPY?Y#@@@    //
//    @@#7~7J7!YJ777!!!!~~~~~~~~~~~~~~~[email protected]@@@    //
//    @@&?!!!7?YJ777!!!!~~~~~~~~~~~~~~~[email protected]@@@    //
//    @@@P!!!!7JJ?7!!!!~~~~~~~~^~~~~~~![email protected]@@@    //
//    @@@&J!!!!JJ77!!!!!~~~~~~~~~~~~!7?JJ?!~~~^^^^[email protected]@@@@    //
//    @@@@&J!!7JJ?7!!!!!!~~~~~~~~~~!7?J??!~~~~^^^^~!!7?JYYYYY5GGGPYJJ?????JJJJYYY5555YYJJJJJ?J5YJ7?5&@@@@@    //
//    @@@@@&Y!!JJ?77!!!!!!~~~~~~~!!!777!~~!?55J7!!77?J5PPGPP5PPPGGP5YJJJJJJYYYY5555555YYJYJJ??55Y?Y&@@@@@@    //
//    @@@@@@@B5YJ?777!!!!!!!!~!!!!!7!!~~!!!7J5YJJY55PGGGBBBBGGPPPPPP5YJJJJJYY5555555555YYJYY?JYYY5&@@@@@@@    //
//    @@@@@@@@@#J?7777777!!!!!!!!![email protected]@@@@@@@@    //
//    @@@@@@@@@#J???777777!!!!!!!777?????JJJJJJJYPPP5PPPPGBBBBGGGGGGPP5YYYYY55P5PPPPPPP5YYYJJP&@@@@@@@@@@@    //
//    @@@@@@@@@@5J???7777777!!![email protected]@@@@@@@@@@@    //
//    @@@@@@@@@@BJJJ??????777!77?JY5YJJ??7777!!!7777777?JJYY555PPGGGGGGPPYY55PPP55PPPPPP55P5Y#@@@@@@@@@@@@    //
//    @@@@@@@@@@@PJJJ???????777?JY5GPP5555YYYYYYYYYY55PPPPPGGGGGGGGGGGGGPYY5PPGGPPPGGGGP5PP55&@@@@@@@@@@@@    //
//    @@@@@@@@@@@@PJJJ???J??77[email protected]@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@GYJJJJJJ??[email protected]@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@BYJJJJJ???7?JJ?777777777??JJY555Y555555PPPPGPPPP555555PGGGGGGGGGGGPGGG#@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@#YJJJJJ????JJ???77777??JY55PPPPPGGGGGGGGGPPPPPPP555PPGGGGGGGGBBGGGG#@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@#5J??????JJJJ??7777777??JJJYY5P55P5555555PPPGGPPPPPGGGGGGGBBGGGGB&@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@GYJ????JYJJJJ?77777777?????JJYY5555YYY5PPGGGGGGGGGGGGGBBBGGB#@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@#5JJJ?JJJJJJJ?7777777777????JYY5555P555PGGGGGGGBBBBBBBGGG#@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@BPYYJJJJYYJ???J??????777?JJJJY5555PPPPGBBBBBBBBBGGGB#&@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@&BPYYJJJ??7????J????????JY5555PPPGGGGGBBBBBBBGGB#@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@&B5YJJ???????????JJJYYY5PPPGGGGGGGGBBBBBBB#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@&BG5YJJJ??JJYY555YY55PPGGGGGBBBBBBB#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#BGG555PPPPGGGGGGBBBBBB###&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&############&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GC is ERC721Creator {
    constructor() ERC721Creator("Gabe Checks", "GC") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x2d3fC875de7Fe7Da43AD0afa0E7023c9B91D06b1;
        Address.functionDelegateCall(
            0x2d3fC875de7Fe7Da43AD0afa0E7023c9B91D06b1,
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