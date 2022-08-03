// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GREYDOLL
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                      ..:~~?Y?~::.                                                    //
//                                                .:^!?Y5GG#&&&#B55PJ~:::^~~.                                           //
//                                             :!?5GB######BGGBGGGB#&#GP5Y5Y:                                           //
//                                          :7YG##&&#####BY?5GB########BGGGP?^                                          //
//                                       .^JG#&&&#####BBPPPGB#&&########P5G##G~.                                        //
//                                     .~YB&&########BB##B####&###&######BG##&#J^.                                      //
//                                   .:?B##############&##########B#&#######BB##BY~:.                                   //
//                                  ^JG#########################BBB#&##B#####BGB#BY!:.                                  //
//                               .:JG#######BBBBB#######&&&&&###B###BGGGB####BBBB#P!~^.                                 //
//                              .~5BBB###&#BGB###################GY7!75Y5PB#######BY7!~^.                               //
//                            .!YPGGPB######################BG5J7^:::^777?YB&&&####GY?7~:                               //
//                           :75GGPGB##############&##&#BG5?!~^^::::::^~!!?YB#&####GYY?!^:                              //
//                           .75PPPG###GBBBBB###&&###BG5?7!~^^^^^^^^^^^^~~!?YG####BBG5J7~^                              //
//                            .?PPGGBBPYY5G#####BPJ?JJ7~~^^^^:^::^^^~~!!77?YY5B#B##BBGPJ!~:.                            //
//                           .:J5PP55Y55P#&&#BPJ7!!!~~^^^^::^^^~7JY5GBB############BBBP5J7^                             //
//                           .!57^^^?G####BB5J5PPP55555YJ?!~^^7Y#&#BGP555GBBPG##BBBBGGPPY7~.                            //
//                           :JGY::~YBBGYJY5G##&&&#&&&##&&#Y!!5##BPY?J555YJ!!?GPPG#BGGGG5J!:                            //
//                          .!P##J~!YJ?7!!?5####BGGBB#G5PPY7!!?PBBGB#&###BGPYY5Y5G##BBGGPY7^                            //
//                         .~GB##GYJJ?77!!~JPB########BPYYYJ?JJYB#B5GB###B##GJJ5PP##BBBBGPY~                            //
//                         .7GBB##PYPGJ77~^^~?P#####&###5JYYYY5P##Y~~YBB#BP5J7J5PG##BBBBBBP~                            //
//                         .JB#BG#P5BGYYP!^^^~JGBBBGGGBGPY?JY5B###G??7YPY?~^~?YY5GB#BBBGP5Y~                            //
//                        .:5B#BPBBGBY?5B7^^^~!?JJ?7!77????JYJYYPBG5?~~^::^^~7??YPB##BBGPJ7~                            //
//                        .~G##BGBBGGYJ5J~^^^^^^^^^^^~~!!?7?PB#BPYBG!^::::^~77??JPB##BBBGJ!^                            //
//                        .:5######BGY?5?~^^^^^^^^^^:^^^:^!?PGPY7!77~^^::^~!?JJJYPBBBBBBGPJ^                            //
//                        ..JB#####BPY?Y?^^::::^:^::^^^:::^^^~~^^~~^:^^^~~~7?YYJYPBBBBBBGG5!                            //
//                        ..JB#BGB##G5J57::~!!::::::^::::^~7?YJ?YY55J!^~~~!7?JJ5YPBBBBBBPY?~                            //
//                        .:JB#GJYBBB5JP7^^YBBY!^::::::^^^?B&&&&&&#G57~^~~7YGGJ?YPPBBBBGPJ!:                            //
//                        .^YG#BPBBBB5YGY!~^!JB#GJ~::::^!~!?Y55PPJ!~^:^^~JG##BJ?JPGBBBBGPY7:                            //
//                        .~YGBPB##BBG5B5??77~~?P#B5?~^^^^~!~~~~~^~~^^^?P##PYYJYY5GBBBBGGJ7:                            //
//                        .!PBGJG#GPBBPBP55YPPJ::!YB#BPYJ7!!!~~!^^~~^!YB&#BY!7?PPPGGBBBGPY7:                            //
//                        .!5GG!?#GGBP5BGPBPPGP!::.:!P##BPYY55?~^^^~JG##G?!~!?!5BBGGGBBGP?~.                            //
//                        .!5GG77#GBBP5GG5GGGGP5JY!. .!YJJ?J5PP?!!~!?Y?JJJYYJY?5GBBGPGBGPY~.                            //
//                        .~5BB?YGGBBG5PG5P#BGPPPPY7:.:^^^^!!!7!!!!~~^^7PGGPPGPGGBBGPGGG5?!.                            //
//                        .~5BBJGGGB#G5PGY5BBBGGPGPPY7^^^~~?Y?!~^!!!!!7JGGPPPPPGGGGGGGGG577:.                           //
//                        .!YBBJ?PGBBBP5G55BBGGPPP5YJ?~^~!!7??7!~7~~~~7PPPPP5J5GGPGGPGGGPJ^.                            //
//                        .!Y5PJ!5B##BP5BP5BBBGGGG5J!^.:^!!7YY?!~~!~^^~5PPPP5JPPGGGGGGGGPY~.                            //
//                        .!J5G5YPGB#G55GP5BBBBBGG7:.::^~!!!7?7!^^^^^::J5PPG5Y5PGPPGGGPGG57.                            //
//                        .7YPGBBPGBBP555JYBBBBBPY7::^^^~~~~!!~^^^^^^^^~?PPPGYYPBGGGBGGGPY7:.                           //
//                        .?JPGGGGGGBBP5Y7JBPJYPJ^^^^^^^^^^^~^^^^:::^:^^~!~?P55PPPGGGBGGP5J!:                           //
//                        .?Y5JPBPGB##GP5YPP~^^^^^::::::^^^~~~~~^^:::^^^^~~?YY55G55PPGGG5JYJ^                           //
//                       .:J5GYPGPBBBBGPGBBJ^^:::..:^^^^^^^^~!!~~~^^:^^^^~!?5?5PGGPPPPGP5???!                           //
//                        ^Y5PGGGPG##BGPG#B7^^::::::.::^^^^^~~~~~^^^^:^^~^~!?!YPGP?JPPGP5?7~:                           //
//                       .!5PPP5BPG###BPPBG!^^:.::...:^^^^~~~~~^^^^^^^^^~!~^^~7Y5PYY5PPPPY^.                            //
//                       ^Y5PPY5BPPB##BGP5Y~::::::..:^^^^^~^^~~~~^^^^^^^~~~^^^!JPGPPGGGGGP!.                            //
//                       ~Y5GPPPBG5B#BBG5J!^::::::::.:^^^^^^~~~~~^^^^^^~~~~~~^!7YY5PGGGGG5!.                            //
//                      .!PGBP55GBGB##B5J?7~^^::::::.:~^~~^~~^~~~^^~~~~!~^~~^^~~~~!!?5Y5Y~..                            //
//                      .!GG5YYYPBBBBBGY??!^^^^^::::.:^^^^^~~~~~~~~~~~~~^^^^^^^^^^^~!JJ5J^...                           //
//                       ~55!:?Y5BBBBBPJJ?!~^::^^::^::^^^^~~~~^^^^~~~~~~~^^^^^^^^^^!J5P5J:..                            //
//                       ~JY?:!JP#BBBBG5J7~~^^^^^^^^^~^^^^^^^^~~~~~^^~~~~~~^^^::::::^?G5Y:..                            //
//                       ^JYY775PGGBBBPJ!~~~^^::^^^^~~~^^^^^^^^^~~~^^^~~~~~~^^:::^::^!J?5^.                             //
//                       :JYJ?JPPPPB#G?^^^~~~^^^^^^^~~~^^^^^^^^^~~^^^^~~~^~^^::::^:^~!J?Y7.                             //
//                       .?Y7~55J7?GB5!^^:^~~~~^~^~~~~~^^^^::^^^^^^^^~~!~~~^:::::^^^^~?JJJ^..                           //
//                       .?Y7.:::!!??!^^^^:^^^::~^^^^^^^~^^^^^~~^^^^^^~~~~^^^:::::::::~??J^..                           //
//                       .?J7.  :~^:^::~~~~^^^:.^~~~~^~~^^^^^~~~~^^^:^^^~!^:^:::::...::~~^:..                           //
//                       .77?~.   .::::^~~~~~~^^^~~~~~^^^^^^^^^^~^^^^:^^^^^:^::^:::::::::.:.                            //
//                        ^: .     .:::^^~~~~~~~~~~~~~^^^^^^^::^^^^^^^^^^^^^^:^^^::::::::.:...                          //
//                                ....:^^~~~~~~~~~^~~~~^^:^^::^^^^:^::^^^^^::::^^::...:::::...                          //
//                                ....:::^^^^^^^~~~~~~~~^^^^^^^^~^^^^^~~~~^:::::::.....::::...                          //
//                                                                                                                      //
//                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GREY is ERC721Creator {
    constructor() ERC721Creator("GREYDOLL", "GREY") {}
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