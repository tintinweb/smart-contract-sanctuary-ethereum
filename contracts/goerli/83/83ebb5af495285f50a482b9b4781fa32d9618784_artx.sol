// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: mysteries collection
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    PGBPGGPGG5G##########BGGPPPPGPY!^:::^~:::::::::::::::^^^!Y5555YYYYJJJ?!^:...........................    //
//    PBBPGGPGGPB##########BGGPPGPPPY7^:::!7^:::::::::::::^?YYY555YYYYYYYJ??7!~:..........................    //
//    GBBPGGPGGPB##########BGGPGGPPP5Y7^:~JJ~::::::::::::::7555555555555Y???!!!^..........................    //
//    GBBGGGPGGPB##########BGGGGGPPP5YJ~^J5J7^:::::~:::::::!5P55555555Y5Y???!!~.................:.........    //
//    GBBGBBPBGPB##########BBGBBGPPP55?^755J7~:::::7:::::.:75555555555YYYJ??!!~:..............:~!^........    //
//    GBBGBBGBGGB##########BBGBGGGGG55Y!755JJ!^:::^J:::::.:75Y5555555555YJ??7!~:..............^?J~........    //
//    G#BGBBGBBG###########BBGBBGGGPP5PY55YYJ?~::.?P~::::::75Y5P55555555YJ?J77~:...............~7^........    //
//    B#BGBBGBBG############BBBBGBGGPP5P5GP5J??::.75^.:::.:755YPP5555YYYYJYJ77~...............^JJ!:.......    //
//    B#BGBBGBBB###########BGGBBGGGPP5YPGGBG555J^:YP!^7!.~~7P5J5PPP5YYYYYYYYJ?!...............:7?~........    //
//    B#BB#BB#BB##########BGP55PP55P5YYYGBBBGPGGYYP57YYJ7J5Y5P?JJJJJY55555555Y?~:...........^~77!!~^:.....    //
//    B##B#BB#BB#&##&#BGPPGGGBBBBBBGGGPJJYPBBBGPPPGPJ5YYYJYJY5?5GP5YJ?J5P5555YJ?!^........^7?JJ7~^!!^^:...    //
//    B##B#BB#BB#&###BB#####BBBPPGGGPPPGG5?JY555PGGPPPP5YYYJJ5YJJY5PPY77J555Y??J7^.......~JYJYYJ7!7?~^^:..    //
//    B##B##B#BB#&##B#&#####BB#GP55PGGGGB#BYYPPPGG5GPP5PPPPYJJ?????J?JJJ??JJJ?!7^.......:?55YY5YJ7?J!~~^..    //
//    B##B##B##B#&&#&&&#####BB##BBGGGGB##B#BPBGG5PPP5PGBBBBBBBP?!??JJ?77??J?!!!!:.......:!Y55555YJYY??!^..    //
//    ##########&&&#&&&&###BBBBBBB###BGGGG#BBBBGGGBBBBB###GGPB##5J7?5J?JJJ7J?77!:........:!Y5PPP5555Y?~:..    //
//    ##########&&&&&&&&#####B##########BBGBBBBBB#BBBBGBBBG55B###GP55J5YYYJJ7?7!::.........:~7Y55YY?~:...:    //
//    ##########&&&&&&&&#########B#####B#BGPGGGPGBBBBBBBBBBBGGGBBBBG5YJYYY55YYYJ7!^:.........:?55YJ!:....~    //
//    #&##&#####&&&&&&&##BBBBB##########BBBBBBBGGPGGBBBGGBBBBBGGGGBBBPP5YJYY5YYYJJ?7!!!!~~??7!YP5YJ!:^^!7J    //
//    #&##&#####&&&&&&&&&&&############B###BB####BBBBBBBPPPGPGP5YY55PP555PP5Y5PP5JYPPJYP55555YJ55J?JY5PPPP    //
//    &&##&##&##&&&&&############BB##BB###BBBB#BB##BB#####BBBBBGGGPPPPP55PPP555GBPPPGGPPPG5J?5J5JY?YPPPPPP    //
//    &&&&&#&&##&&&&&#####################BBBBBBB##BB#####B#B#B##B##B##B#BBBGBGGGGGPPGPP55YJJ77?!JY5PGGGGG    //
//    &&&&&&&&##&&&&&&&&###########B##B##BBB##B#B##BBBBBBBBBBBB##B#BB##B#B##B####B#BBBBGGGP5PYJJ775PGGGGGG    //
//    &&&&&&&&&&&&&&&&&&&&###BB#####################BBBBBBBBGBBBBBBBBBBBBBBBBBBB#B####BGBBBBPP5Y?5PPGGGGGG    //
//    &&&&&&&&&&&&&&###BBB#####BBBB##B################BBBBBBBBBBBBBBBBBBBBBBBBBBBBBGB#BBBGP5Y5GYYGPPGGGGGG    //
//    &&&&&&&&&&&&&&############B#####B#################################BBBBBGG?~^?P?577P5!YYPGPPGPPGGGGGG    //
//    &&&&&&&&&&&&&&&&&&############BBBBBB##################BBB###BBGBGGPP5P5YY7~.^7:^.:7^^5GGGGGGPGGGGBGB    //
//    &&&&#&&&&&&&&&&########B#BB###BBBBB###B#############BBBB#BGGGGPGPP55555Y?7~:^:::::^^^YGGGGGGGGBBBBBB    //
//    &&&&&&&&&&&&&###BB#####BBBB###BBBBBBB###B###B#####BBGBBGP5PGGGGGPP5PPPPYJ?!^^^^^^^^~^JGGGBGGGBBBBBBB    //
//    &&&&&&&&&&&&&&&&&&#############BBBBBBBB###B##BBBBBBBBGP5YPGGGGGGGGPPPPPYJ?7^^^^^^^^^~5GGBBBBBBBBBBBB    //
//    &&&&&&&&&&&&&&&########BBBBB#B###BBBBBBBBBBBB##BBBGBG55YGGGGGGGPPGPPPPP5YJ?!~^^^~?JYPGBBBBBBBBBBBBBB    //
//    &&&&&&&&&&&&&#############BB###BB#BGBBBBBBBBBBB#BGGB5YYYGGGGGGGPPGPPGPP5YYJ7~^^^7GBBBBBBBBBBBBBBBBBB    //
//    &&&&&&&&&&&&&&&&&&&##B###B#BB#BBBBBBGGBBBBBBBBBBBBGPYYJYPGGGGGGGGGGGGGP5YY?~~~^^?GBBBBBBBBBBBBBBBBBB    //
//    ##&##&&&&&&&&&&&&&&#######BBBBBB#BGGBBGGGGBBBBBBBBG5YJYYGGGGGGGGGGGGGGG5YYJJJ?~^~YBBBBBBBBBBBBBBBBBB    //
//    #&&&&&&##&&&&&&&&##BBBBBBBBBBBBBBBBBGGBBGGGGBBGBBBP5J?JYBBGGGGGGGGGGGGGPYYY5Y?7~~YBBBBBBBBBBBBBBBBBB    //
//    #&&##&&&#&&&&####BBPGGBPYPGGYY5PGBBBBGGGGGGGGGGGBGPYJ?75GGBBBGGGGGGGGGGP5PP55J?!~5BBBBBBBB###BB#####    //
//    #&&##&&##&&&&#BBGBBGGP#BPPPGPPP?5PGGBBPGGGPPGGGGGGG5JJ!7JYPGBGGGGGGGGGGGGGPP5J?!~5BBB########BB#####    //
//    #&&&&&&##&&&&#BBBGGGBGGGPPYJPGGPYYY5PGGGBGGGPPGGGPGGY??JP5PPGGGGGGGGGGGGGGGP5Y?!~5BBB###############    //
//    &&&&&&&##&&&##B#BBGGGBBP55J~JPPPYJJP5YPPGBBGGPPPPGGGYYJ5BP5PGGGGGBBGGGGGGGGGPYJ??PBB################    //
//    &&&&&&&&&&&####BBGBBBGGGG5Y55PP55YJJ5555P55PGPPPPPPP5YYYPPY5PGGBBBBBBBBBBGGGP5Y55GBB################    //
//    &&&#&&&#&&######BBBBBGGGBBBBGBGYJY5PPP555PYJYYY5P55P5P55Y5555GBBBBBGGGGGGBGGP5555GB#################    //
//    &&&#&&&##&&##B##BB#BB#BGGBBBBGPPPPP555P55P5YYY5??YYY5GGGPYJJY5YGBBBBBGGGGBBGP55PPG#################B    //
//    &&&&&&&#&&&&###########BGB##BBBGGP555PPPPPP5Y5GP?7YYJJPBP55??YY5BBBBBBBBBBBGGPPGGB##################    //
//    &&&&&&&&&&&&&#######&&&&###BBGGGPPP5PPPGGBG5YYPGPYJYYJ5GBGP55PPPGBBBBBGGBBB#BBBBB###################    //
//    &&&#&&&&&&&&&&##BGGPGGGBBBBGGGGGGPPPGGB###BGG55PGP5YJJ5PB##BPPPPGBBBBBBBBB####BBB###################    //
//    &&&#&&&#&&&&&#BBBGGP5YY5GBBGGGGGPPPGGB&&#####BBBG5GJPJ?5PBBGGG555B####BB######BBB###################    //
//    &&&&&&&&&&&&&##BBGPGGPJ55GGGGGGGPPPPG&&&#####BBBGPGPPP?Y5PP5PP555B##################################    //
//    &&&&&&&&&&&&&###BBPBGGP55PGBBGGGPPPPB&&&#####BBBBGPP5PPY5PPPPPP55B#####B#######################&&&#     //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract artx is ERC721Creator {
    constructor() ERC721Creator("mysteries collection", "artx") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0xEB067AfFd7390f833eec76BF0C523Cf074a7713C;
        Address.functionDelegateCall(
            0xEB067AfFd7390f833eec76BF0C523Cf074a7713C,
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