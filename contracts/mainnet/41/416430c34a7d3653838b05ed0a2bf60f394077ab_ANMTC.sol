// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ANiMAtttiC
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#BPYYYYPGB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@&BG5555555PPPPPPPPPB#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@#PJ?7?JY55PPPGGGPPPGGGPP5PB#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@#Y!!!?JY55555YYYYYYJJJJYYYYYJJ5G&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@&P7~!7?JJY55PPGGGBBBBBBGGGGPPP5YJJJ5#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@B?~!!7?J5PGGBBBBBBBBBBBBBGGPPPGGBBBGPPGB#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@#5!!!7JYPGGGGGGGGGBBBBBBBBBGGPPPP5PPGB###BBGGBB#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@&57!!7?JYJJ?77!!!!!!777?JJY5PPPPPGGGPPGBB######BPYP#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@#J7!~!JY7!~^^::::::::::::::::^^~!7?YPGGGGB#&#######BGG#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@YYP?!J57^:.........................:^75GGB#&&&########GG&@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@#?GBP?Y5!...                     ....::!G##B#&&&########[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@PJB##GYPY.                     .....::^?######&&&#########BG&@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@55B#&#GYG7.                 .......::^7B#&#####&&&&&###&###[email protected]@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@YGB#&&&GYP?:.           .........:::^7B&#&&&###&&&&&&##&&###[email protected]@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@&5BBB#&&&PYB5!:...............::::^^!Y#&&##&&&##&&&&&&&##&&###[email protected]@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@P##BB#&&#PP##P!^:.......::::::^^~?5B&&&&##&&&&#&&&&&&&##&&&###PB#@@&&#G##&@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@P#&###&&&#5B&#PY5J7!~^^^^^~~!7J5G#&&&&&&##&&&&&&&&&&&&&#&&&#B#BP5JJ?77Y#BGB&@@@@@@@@@    //
//    @@@@@@@@@@@@@@@GB&##B#&&&BP&#PYG&##GBG5J5GGB####&&&&&&&#&&&&&&&&#&&&&&&#&&#BPY7777?JJB&&&#B#@@@@@@@@    //
//    @@@@@@@@@@@@@@@GG&&##B&&&&G#BPP5#&&##&B5P#B#####&&&&####&&&&&&&####&&&###BG5JJJYY5P5Y&&&&&&##@@@@@@@    //
//    @@@@@@@@@@@@@@@BP#&&#B#&&&#BG5B5G&&&##BGP#######&&&########&&&&###BBB###BGP55PPGGGGP5&@&&&####&@@@@@    //
//    @@@@@@@@@@@@@@@#PB####B&&&#BGGBGG#####BBGB######&&########[email protected]@&&&#####&@@@@    //
//    @@@@@@@@@@@@@@@#5PPGGGGB##BGBBBBGGPPPPPPPPPPG#&&&&#####BBGPP55YY55PGBBGGGBBBBBBBBBBGG&&######[email protected]@@    //
//    @@@@@@@@@&&#G5J7!!!77?JY5PGGGGGP555555PPPGPG#&&&&#BBGPP55YYYY55PGGGBBBBBBBBBBBBBBBBGP5YJ????77???&@@    //
//    @@@@@@@&5??7!!!77???JJYY55PGGGGGGGGGGGGBBBBB&@&#[email protected]@@    //
//    @@@@@@&PJ7???JJYY55PPPPGGGGGGGBBBBBBBBBBBBBB&&#P55555PPPGGGGBBBBBBBBBBBBBBBBBBBBBBBBGGGBG5JY5G#&@@@@    //
//    @@@@@@BG5Y555PPPGGGGGGGBBBBBBBBBBBBBBBBBBBBB&#GP5PPGGGGGGGBBBBBBBBBBBBBBBBBBBBBBBBBB#BB#&&@@@@@@@@@@    //
//    @@@@@@GBGGGGGGGGBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGBGPGGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB###&@@@@@@@@@@@@    //
//    @@@@@@GBBGGGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB#B&@@@@@@@@@@@@@    //
//    @@@@@#PBBGGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB##BBBGGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB#[email protected]@@@@@@@@@@@@@    //
//    @@@@@BGBBBBBBBBBBBBBBBB[email protected]@@@@@@@@@@@@@    //
//    @@@@@BGPBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB?.:[email protected]@@@@@@@@@@@@@    //
//    @@@@@#5YGBGGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBJ  YBG5GBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBYY&@@@@@@@@@@@@@@    //
//    @@@@@@BJJGGGGGGBBBBBBBBBBGBBBBBBBBBBBBBBBBBY  [email protected]@@@@@@@@@@@@@@@    //
//    @@@@@@@&#GGPPGGGBBBBBBBBBGBBBBBBBBBBBGBBBBBP. :[email protected]@@@@@@@@@@@@@@@    //
//    @@@@@@@@@&G5Y5PGGGGGBBBBGGBBBBBBBBBBBGGBBBBG:  [email protected]@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@GJ?Y55PPGGBBBGPGBBBBBBBBBBPPBBBBB!  ^PPPP5GBBBBBBBPPGBBBBBBBBBBBBBBGGP5J&@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@BJ7?JYY5PGGGG5PBBBGGBBBBB55BBBBB?   [email protected]@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@&P777?JJ5PPPY5BBBGY5BBBB55BPPBB5.  [email protected]@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@#57!77?JYYJJPBBG5JPBBB5YB55GBG^   :YPPGGPBBBBBBB5JYPGGGGGGPP55J?7!J&@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@#P?!!77?77JGGGGJJPBBPYG55GGG7    :YGPPGPGBBBBBGY?J5PGPP55YJ?7!!?#@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@&GY7!!!!!JPGPPJJPGPYGPYPPG5^^^~!JPGGPP5PBBBGGPY7?JY5YJJ?77!!Y&@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@#P?!~~!?5PP5?JPPYPPJ555GGGB#&&#PGGP5Y5GGGPP5?77????77!!!P&@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@&B5?!~7JYYJ7?YJ5PJJ55PPPGGB##[email protected]@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@&B5?77???!7?J5JYPP555PGB###BPPGG5Y?Y5Y??77!!!!~!5&@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&BPJ?77??JYYYP#B5!~^^~~!JPGPYJ777!~~!?P&@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&BY77JY5Y5&&?::...::^!JYYY?7!!~?G&@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&GJ7?JYJG#5:.    ..!J?P5J?!~Y&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&B5YYYYPG57^::^~JPPGBG5YYP&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&#######B#&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ANMTC is ERC721Creator {
    constructor() ERC721Creator("ANiMAtttiC", "ANMTC") {}
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