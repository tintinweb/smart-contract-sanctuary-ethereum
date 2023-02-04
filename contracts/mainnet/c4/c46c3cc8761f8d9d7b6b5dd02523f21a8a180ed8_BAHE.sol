// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BAGHERIHESAM
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                              //
//                                                                                                                                              //
//      __    __    _______   ________     __       ___      ___  _______       __       _______    __    __    _______   _______    __         //
//     /" |  | "\  /"     "| /"       )   /""\     |"  \    /"  ||   _  "\     /""\     /" _   "|  /" |  | "\  /"     "| /"      \  |" \        //
//    (:  (__)  :)(: ______)(:   \___/   /    \     \   \  //   |(. |_)  :)   /    \   (: ( \___) (:  (__)  :)(: ______)|:        | ||  |       //
//     \/      \/  \/    |   \___  \    /' /\  \    /\\  \/.    ||:     \/   /' /\  \   \/ \       \/      \/  \/    |  |_____/   ) |:  |       //
//     //  __  \\  // ___)_   __/  \\  //  __'  \  |: \.        |(|  _  \\  //  __'  \  //  \ ___  //  __  \\  // ___)_  //      /  |.  |       //
//    (:  (  )  :)(:      "| /" \   :)/   /  \\  \ |.  \    /:  ||: |_)  :)/   /  \\  \(:   _(  _|(:  (  )  :)(:      "||:  __   \  /\  |\      //
//     \__|  |__/  \_______)(_______/(___/    \___)|___|\__/|___|(_______/(___/    \___)\_______)  \__|  |__/  \_______)|__|  \___)(__\_|_)     //
//                                                                                                                                              //
//    .....................................................:::::.::::::::::....................::.........                                      //
//    .:!?JYYYYYYJYYYYYYYYYYYYYYYYYYJYYYJYYJYYYJJYYYY5YYYY5YJ??J?77??????JJ?JJJJJJJJJJJJJ?JJJJJJJJJJJ77!:.                                      //
//     :?B############B##B###BBBBBBB#&&@@@@@@@@&###BBGPPGPJ?7!~!7^^^^~~~~!!7?JYPGGB##&&###&##########BG?:                                       //
//     .?G#################BBBGB#&@@@@@@@&#B5J?7777^:::~!~^^^::^^::.:::::::^^^~~!77?JPPPGGGBBBB#######Y7:                                       //
//     .7PB###########BBBBBBBGG#@@@&&@#PY7~7~::::~^::^!!^::::::^.............::::^^^^!7777777?77????JYJ!.                                       //
//     .?PB###########BBBBBBG#&@@@&#@B?7!!7?J777!???J?!:...^^^~~~^.::..:::::^^:::::::^^~~~~~~~~~~~~!!?Y!.                                       //
//     .?5B########B#BBBBBGG#@@@@@&#B577!7!!?7^::^~!!::::::~~^:~77!~^^~!7??JJJ?7!~~^~~^^^^^:::::^:^^^?J7.                                       //
//     .75B#######BBBBBBBGG#@&#PYJ7!!^:::::^~~^:^!?J!::^^^^^7J?777777JG#P?!~~~~~~~^^~!!!!~^^^::::::::!Y7:                                       //
//     .75B#########BBBBBG#@@P7~~~~~!~~~~~!77?!7?YPY^:^^^^^~7Y?7!~~~!7JYJ!:...:::^^~~~!~~~^^^:^::::::^J!:                                       //
//     .75B########[email protected]@&5777?7~~~~~~!!!^:::^~~~:^^^~!!!!?YJ?77~~~~^~!~^:::::^^~^~~~~~~^^^^::::^^!J7:                                       //
//     .7PB#########[email protected]!~^^^:::.::::::....^~7J?~:^^~~!7?YYPG55YJ7!~~~~~^~~~!!77777777!!~^^^^:^:!Y7:                                       //
//     .?5B#########[email protected]!!!!!!~~^~~~~!!!7!!!!7?7^::::^^~7^:!J5#&B5J?777!!77??JJJ?JJJJJJ?7!!~~~^^7Y7:                                       //
//     .?5B#########BBBBGG&@##B5?7!~~!~^^^^^~~^:.....^:::::::^:^^:^75##BGPGGGPP5PPPPGB#####BG5YJ???77?Y7:                                       //
//     .?5B########BBBBBBG&@@&G7~~~::^::....:^:..:::::^^:::.^~^^^~~~75B&&&&&&#&&&@@@&####&&&@@&&#BBP55Y7:                                       //
//     .?5B#######BBBBBBBB&@@#PJJJJ?7??77!!7!!7!!!!!!!7??JY5PGPPGGBB#&&BP5YYY5G&@@@&BBBBBBBB###&&&&&@&Y!:                                       //
//     .?5B######BBBBBBBBB#@@&GJJJ5B#BGP555PGBBBGBBBPPP5G&&B##&#BPYYY55PP5YJ?JY#@@@#BBBBBB####BBBBBBB#Y!:                                       //
//     .?5B########BBB#BBB#@@@G?7?55J??J??JY55GBGPYJ!^~~!JY5PGPYJJ?77!~7JPGYJJ5#@@@BBBB############BBBY!:                                       //
//     .?5B#########B#[email protected]@PJ7777JPB##P#&&[email protected]&57!~^~~!7?G&BJG##G5PP5J77JJ??J&@@&BBBB###############J!:                                       //
//     .?5B###B#######[email protected]!~~~7?5PYY5PPGBY!~7!~!!7?7YGGJ5#BYYBB5J!~^!7?Y&@BGGGBB###############Y!:                                       //
//     :?5B###B#######5~?~^?G&5Y?!!!!~~~~~~!7?J?!~!?7!!!??77?JJ?7777!!!!!~~!JY5&#??7?J5B##############Y!:                                       //
//     .?YB###B#######Y7?!~7B&55?77!~~~~^^~~!~~^~!7J?7!7YY?7!7!!~^^^~~!!7???Y55&#J7^?7JP&#############Y!:                                       //
//     :?YB###########B7?~77B&G5J7!~^::^~~~~~~^~?Y?!~~~~~JJ?!!!!!!~^^^^^~!??Y5P&#J~~77G5##############Y!:                                       //
//     :?YB###########&[email protected]?!!~^^^^^^^^~?577?7^^^^!77?55?!~~~~^::::[email protected]?755B&#############Y!:                                       //
//     :?YB#######B#####J??YY##PY?77!~!~^^^~!J5??G#G5JJYPGP75#Y!~~^^:^^^~!7J5G#&Y5G??YB&##############Y!:                                       //
//     :?5BBB####BBBBB##BYY?7B&B5Y??7!7!~^~!?J?YG&&&#5P#&&&GYJ?!~^^^^~~!!7?YG&BBYGJ?JG&###############Y!:                                       //
//     :7YBBBBB##BB#BBB##B5!!P##G5J???7~~!!?5G#@@&#&@&&&&&&@&PJJ7~^~!!!!7?JG##GJ!?JYG###############B&Y!:                                       //
//     :7Y#&#####BBBBBBBB#B5YP&&#P5YJJ?77?5B#&&&@@@@##B&&&&&&@#PYJ!!!777?Y5#&BG7!7YB&################&Y!:                                       //
//     :7Y55PGB#&&&###BB#BB#BB&&&GPYJ?77!7?J???JJ55YJ77?JJ?777?YJ77!7?JJY5G#BBP77Y####################Y!:                                       //
//     :7YJ!??7JY5PPGPGGGGBBBP5Y?!~^^::::..:^.::::^^:....^:.. .^:::^^~JPPBB#B#&#######################Y!:                                       //
//     :7YJ:^^~!!!!!~~~!!!7!!~^::::.........::.::::^!!^^^!!~~~!7!!!~~~?YJYYYYPB#######################Y~:                                       //
//     :7YY^~~^~~^^^^!!7^^^:::.:......:::::::~::::::^~!??!~^^:^~:::.:::^:::^^^~P&#########BBBBBBB###B#Y~:                                       //
//     :7YY77!!~~~~^^7~~.:::..:::::::^::^::::^^::^:::..:^::....^^::::^^!!!7!!7!YPG#####BBBB#&&@@@&&#&&Y!:                                       //
//     :7Y?~~~~^^^^^^~^^.::....::^^^^^::::...:^::::.::::^J?!~^~!7777!!!!!!!!~~~^^~P#BBBBGB&&@@@@@##B&@5!:                                       //
//     .7Y7~~~^^^^~~^^^~:^::::^^^^^::::...::..:^^::^^^:::7J!~^::::^^:.....:^^^~!7?GBBBB#&&&B&@@@@&#G#@5~:                                       //
//     :!J?7!!~~~~~~^~^~:^^:::::::::::::...:::..:^::::...:^::.....:^^:^^^~!?JJ5BBGBB###@@&BBB&@@@@#P&@Y~:                                       //
//     :7J?77!!!~~!~~~^~^^::::::::^^^^::::...:::..:::::::[email protected]#&@@@@@@#GB#@@@@@[email protected]@Y~:                                       //
//     :7YJJ?777777!!~!~^^^:::::::^^~^^^^::::::^^::::::::?5!~~^^~!~^::::^^^[email protected]@@#@@@@&GPB&@@@@@[email protected]@Y^:                                       //
//     :!J###BBGGP5Y???!~~^:::::::^^^^~~~^^:::^::^:::::::^:.:.:::^^:::^~!??YPB##@@@#@@@@#PG#&@@@@@B#@&Y~:                                       //
//     :!J&@@@@@@@&#BG5J!!~~^::::::::::^^^^::::^~^:::^^^^^:::^^^~777?JJY5P#B&##&&@@#@@@@BPG&@@@@@@B#@#Y~:                                       //
//     :!Y&@@##@@@@@@@@&BY7!~~^:::.::::^^~!~~~~^!?777???J??JJY5GGG5YYY5PG##&@#G#@@&#@@@&GPB&@@@@@@B#@#5~:                                       //
//     :!J&@@[email protected]@@@&&&&@@@B5?7!~^:::^^^^~~?Y5JJY5G##&&&#&###BGG5YJYYPGB##&@@@#B##&&#@@@#PG#&@@@@@@B#@&5~:                                       //
//     :!J&@&B5#@@@&&&&&&&&@#GY?!!!~^^::::^!J5#@@&BBBGGPP55YYYY5PGBBB##&@@@@&GPB&@&#@@&BPG#&&&&@@@[email protected]&5~:                                       //
//     :!J&&&BYG&@@#&##&#B#@&&&#PJ!!~^::::::~~!J5B#BG5YYJJYPPBB#####&&@@@@&#[email protected]@@&#@@#PPB&&&##@@@[email protected]&5~:                                       //
//     :!Y&##GJP#@@B&&B#BPB&@#B#&&#G5J7~^^:^^^^:^~75B#PYPB&###&&&&##&@@@@&[email protected]@@@&#@&G5PB###[email protected]@&[email protected]#5~:                                       //
//     :!YB##BPG#@@#&@###BB#@&BBB&@@@&#BPYYJ??7!!~~!?G##@&&&&&##BB#&@@@&#B55B&&&@@##@BP5PGBBGPB&&B5B&GP!:                                       //
//     :~?YYYYYYYYYYYYYYYYYYYYYYYYYYYYYY555YY5YYYYYYJJYY5YY5YYYJJYYYYYYYYYJJYYYYYYYY5YJJYYYYYJY55YY55J?~:.                                      //
//    ......     ..  .    ..  ..    ..  .   .... ....... .............  ......... . ......................                                      //
//                                                                                                                                              //
//                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BAHE is ERC1155Creator {
    constructor() ERC1155Creator("BAGHERIHESAM", "BAHE") {}
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