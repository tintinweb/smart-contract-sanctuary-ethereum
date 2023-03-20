// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: #8801 MEMEORIES
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//    Result                                                                                                  //
//                                                                                                            //
//                                    .                                                                       //
//                                                                                                            //
//                                                                 .... .....                                 //
//                             .                           .  .:::~7777~^:^~~^::.::..                         //
//    ..............                            . ........::^~7777!!!!!!!7?????77?77!~^^!~^^^^:^~:. .^~^~7    //
//    ~^^:::........                      .:~!?YYJYJYYYYYYYYYYYJJ??7777?777?7777??77?7777?!~!!!!7!???JJJJJ    //
//    ????7777!^................  ... .~?Y555555PPGBBBBBBBBGGGP55555YYYYYJJYYYY5YYJJJ??7???777!!!77?777???    //
//    77J????JJJ?7~^^^^^^^^::::~~!7!!?5GPP555PGGGP55555P555PPPPGGGGGGP55YYPG5?777J5YJJJJJJJ????777?????JJ?    //
//    7??J??????JYJ7!~~~~^^~7YPPPPPGGGP55YYPGPY??????JYJ?77?J55YYJYY5PGGPBG!::::::~Y5YYYYYJJ??JJJ?JYYJJYJJ    //
//    ?J????JJJ?JYJ??7!!!!?PG57~~~!JG#GYJ5GY????7??JYJ?777!!7YYJJ???JJ?YP#5:^^^^^^:^PP555555YJJJJJJJJJJJYY    //
//    YJ??JJ??JJJYJYYJJJ?YGP7^:^^^^:^?#BGBJ77?????JJ?7?JJ???JYYJYJ?????7?YB!::^^^::^5GPP5555YJJYYJJ??77?JJ    //
//    5YJJJ555YJJJJJJYY5YGG7:^^^^^^^^:J#BJ?????JJ??7?JJJYJJJY5555J?JJ??7??YGJ~^^^^!YG5YYYJYYYYYYYYYYYYJYYY    //
//    YYY555PP5YYY555555YPG?:^^^^^^^^:7#Y?J?JJJYJ777?JJY5YYYYY55YYJJJJ???JJYGGGPPPGG5Y5555PPP555555YYY55PP    //
//    P5PP55PP5555P5555555PG?^:::::::!GGJYYJJJYJ?J777JYY55YYY555YYJJJJ????^?5J?J55YY5PPP55555555PPP555555Y    //
//    PPPPPPPPP555PPPPPP5PPGGPY?777JPBGJY55YJY?:.~7???J557JYYY55YYYJJJJ?!..^:..:?YJY5PP55P55PPGGGGPPPP5555    //
//    PPGPPPP5PPPPP5PPGGGGGGPPPGGGGPPYJJ555YY7.....:!?YY5^^Y555YYYYJJ7^^.......:^JYY5GGGPPGGGGBBGP5P55555P    //
//    GGGGGGGPPPPP55GGGGGGGG55YYJJYYYJJ55PYJ!.........:^^:.:?YYJJYYJ^...:^!JYB&@@@Y5GGGPGGGBGGGGP5PPPPGPP5    //
//    PGGGGGGGGPP55PGGGGGGGGYYYJJJJJJJ55P5JY##BP55J7!~^::.....:::^~~YPB#&&&&&B5Y?7YGGGGGPPPPPPPPPGGPPP5YYY    //
//    ?Y5PP5YJJJJJJJYYY555Y5YYJJJJ55Y5PPPYY!!77?J5PGBBBBBGGP5!.....^JY5#&&&&&&Y:..YGGPPPGPPPPPPGPP55YY555P    //
//    JJ?JJJJJ????????????7JYJ??JJ5P5PGPYJY^.....:^!?YJ7~^^^~~.....:J&@@@@&&@@@&BJ5PPGGGGGGPPPP5555555PGGG    //
//    JJJJJJJJJJJJJJJJJJJJJY???JJJ5PPP5YY5Y:..Y&&@@@@@@@@&PJ:[email protected]@@@@#[email protected]@@@@&#PPPGPP5555YJ?JJJYPGPGGP    //
//    JJ?JJJYJYJJJJYJJJJJYYY7?JJJY5YJ????!:.^#@&&@&[email protected]@@@@&YB&7.:~77&@@@@@GP&@@@@@@@G555555YYYYYY5555PPPPPP    //
//    JJYYYJJYYJJJJJJJJYYY5JJJJJJJ~::......!#&@&@@[email protected]@@@@@#P&@#!!^::[email protected]@@@@#&&##&&B5#P5YY5YYYY55555PP5PPPPPP    //
//    JJJJJJJYJJJJJJJ?????YJJJJJY!.......::::[email protected]&@&&##&@&#@@@!....::~5&@@@#?PPGY?5YJYYY55PPPPPPPPPPPPPPPGP    //
//    ?JJJYJJJYJJ77!^^^^~!JYJJYJY7:......:::..:5#&[email protected]@@#!.......:::^!Y5Y5YY7JYJY555Y55555PPPPPPGPP5PPG    //
//    YJJJJJYYY?!^^^^~~~~^!YJJJJYYJ~^^:..::::...:!5PY5J75J^..........:::::::::.~YYYYYYYYYYYYYYY55Y55555555    //
//    JJJJYYYYYJJ?!::~!~~^^7JYYYYY5555Y?!^:::::..................::^^:::::::::75YY555Y55555Y5YY5555Y555555    //
//    JJ??JJYJ!^::::^:^!777!?Y5YY5PPPPPPPP5?~^::..............?&&&&&&J^~^::^!YP555J7?5555555555555Y5555555    //
//    J?????J?~^:..:::~7??!~!?5555555PPPPPPGP5J7~:........:::.:~~^^:~~75Y?!JPP55557~7555Y5YYY55Y5Y55555555    //
//    ???JJ???J?!!!~^:::~7?77777?5P5PPPPPPP5PGGGGPY7~:::::::::::.::::~!J555YYYYY55?7Y5YYY5YYY5555555555Y55    //
//    ??JJ??7????7!!!^:::::^^!!~.^YPPPPPPPP5PGGGGGG55YYJ~^^::::~77!!!7YYYYYY55555Y555555YYY5555Y55YY5YYYY5    //
//    ???777!!^:::::::::.....:::~7JJ5PPPPPPPPPP5YYYYJYY?~^^^^^^!?!:.  :!?JYYYYY55PJ?5YYYYY555555YYYYYJJ?77    //
//    ^^::^^~!~~^:.:^^~~~~!!??777????JJ?J??J?~:^!7?YG&#^^^^^^^^^:^~...:^~!7?????YYJYYYYJ7?JJJJYYJ77!7JJYJ?    //
//    7!!777?JYJ!::^~77^~!?JJ7~^!!~~~^~~~~!?!!JP##&&@@@B~::^^^^:^#@&#PJ!^...:!!~!!77J?7!~7???JYYJ??!?Y?7?7    //
//    J?J?77JJ?J7:.:^^^^...::^[email protected]@@@@&&@@@&57~~^~J&@@@@@&G!:~!777~:::!YY?J7!7^~?YYYJ!7?YY?^^    //
//    YJYJ??YY??77!7?7!~^:::::^::~?Y5Y7^:..~&@@@@@@@@&&@@@@@&&@@@@@@@@@@@J7!!?5GGPJY5577???7?YJ77!^^~~~?JJ    //
//    JJ?!!~^^!J55?7!!7??7??7!??!~~!7J7!!!~#@@@@@@@@@@@&&&##@&&&&@@@@@@@@G!7?5PP5Y7~^:::^~!?7?J7~~^~?!?JY5    //
//    JJJ7!!~~77JY5JYYJYYYYYYJ?J??^.::^^[email protected]@@@@@@@@@&#[email protected]&5PY5&@@@@@@&~~~~^:~:.....:~7Y5PJ7?J???JPBGGG    //
//    77?Y55Y55PPJ55J~^!~~^!!^^^~~~~~~~~^[email protected]@@@@@@@@@&&B&&GBGP5?#&#&@@@@@@@Y.. .:~!!7YGGGGGG5P5!!Y5YYPGGGPY    //
//    ??J5555Y5YJ7777!!77!!7777!!!!!77??J&@@@@@@@@@@&&@@G  .:.^!&&@@@@@@@@&7!JPGGBBGPPPYYJJYJJYJ?JJJYJJ???    //
//    PGG57!!~~^^^:^!!!?J??????JYY5GGP5Y#@@@@@@@@@@@@@&@#^.. ..7#&@@@@@@@@@&YYJ?!77!!!~~!JYJ?~^::^!?JJJJY5    //
//    55YYYYJ?7777777???JY55Y55PPPPPPYJ&@@@@@@@@@@@&&@@@@Y!!7JJ7&@@@@@@@@@@@G~^^^^::^!?JJY?~::.^:..:755GGB    //
//    5PPPJ??77?JJYJ7!!77?JY5YJ??!!~^^^7YG#&@@@@@@@@&@&&&PYPGBGY&&@@@@@@@@@@@#7!.:^~!?Y5Y57^^:^:.~:. !GP55    //
//    BBBG55JJJYPGYJJ??J?7?J?~^::::^:::^!!^~!?#@@@@@&@#GG&###G#&[email protected]@@@@&PYJ?!!55YYPGGPYYYJ?^:.::^....:?JJY    //
//    GBBGPPPPBBBBPJYYJJ?77?JJ7!^^^^!7?JB##GPJ#@@@@@@@7YBY?JB5JG7G&@@@@&J77?JP&G?!?JJJ77J?J!^..:^~^^!!JJJJ    //
//    PGGGPPGPP5GBG555PGYJ??PP55PG55GBBBGG#BGP&@@@@@@@###BGG&#G#B#@@@@@&5&&#####5JYYYYYYYJJJ7~^!!!?JJJYY?J    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract REM8001 is ERC721Creator {
    constructor() ERC721Creator("#8801 MEMEORIES", "REM8001") {}
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
        (bool success, ) = 0xEB067AfFd7390f833eec76BF0C523Cf074a7713C.delegatecall(abi.encodeWithSignature("initialize(string,string)", name, symbol));
        require(success, "Initialization failed");
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