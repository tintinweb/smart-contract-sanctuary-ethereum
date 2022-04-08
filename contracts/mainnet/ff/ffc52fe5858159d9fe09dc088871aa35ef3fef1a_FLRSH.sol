// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: / / FLOURISH / /
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                               //
//                                                                                                                               //
//                          .7PGBBBBBBBBGY?!^::...    .::...  ....:::::::::::.                                         .::::^    //
//                        ^YGBBBBBBBBGPYJ7~^^:...       ..  .:^^^~~!!!!7??JJJJ?7!~^^^:..                                ..:.:    //
//    BP?~:...        ..7G#######BBG5YJ7!~^:::.....::.. .......::^^~~~^^^^^~~7!!??!~~~^:.                                 ...    //
//    ######BBBGGGGGBBB######BBBGGP5Y?7~~^^::::::^::::.  ......:~7?JJ??7!!~^^~~^^^^~~~^:.                                        //
//    GGPGGGGGGGBBBBBGBBBGGPPP555YYJJ?7!~~^^^::::...:::.::::::^~!7JY55PP5YYJ?7^^^^~^~~~^:.                                       //
//    PPGBGGGPGGGP55YY55PP55PGGPP555YYYJJJJ???77777!77?????7777!~^::::^~7JYYY7:^^:::^~~~^..                                      //
//    JYPPGPYYY55YJ?YYYJ?JJ???JJJY5PGGBBGGGP5YJ???????JJYJJ?7!!!!!!!!~^:...:^~~~^::^^^^^^:..                                     //
//    Y555YYY55555Y5J??77!!!!!!!777??JJJJYY555PPPGGGP5YJ?77?JJ?7!~~~~~~~~~^:.  ..::....::....                                    //
//    ?J?JY5JYJJJJJJ75J~~~~!!!!!!!!!!7777???????????JY5PGGPJ!~!?JJ7!~^^^^^^^^:..    ..........                             ..    //
//    77?JYYYPPPPPP5YPG5~^^~!7???777!!!!!!!!!!777777?777?J5GG5?~^^!??7!~^:::::...        .....                      . .......    //
//    7J?Y5PGGPP5Y5YY5G5:....:^7?JYYYYJJJJ??777!!!!!!!!!7?77?5GG5?~::^!77!~^::......   .....                               ..    //
//    77J5PGP5PYYY5?Y5JP5~.....:^~!7?JJYYY555YYYJJ?77!!!!!!7?77?5PP5?~...:^^^~~~~~~~~^:.::::..                              .    //
//    !?Y55P5P???YYJ~Y5?J5Y7^:...:^~!!7??JJYYYYYYYYYYYJJ?77!!!7?77?JYYY7~:..^7??!~^^^^::~^^:...                                  //
//    ?JJJJY5J~~~?7?7~7JJ??JYYJ7~^:::^~~!777??JYYYYJJJJYP5Y??7!!!777!!!!77!!!!!~^^~!!!~::::......                           .    //
//    7!777YY::.::~~~!~~~!77777????7!~~~~~~~~~7?JJ?!~!JY5GGG5Y?7!!!~!~~~^^^^:...:^~~!7!^.........                       ..       //
//    ~!!!!!: .  ..:::^^^^^^^^~~~~~^^^^^....::~77~~~!J5PPPGGGGPY7~~~~^^::::...  .:^^^~!^ .....                       ..  ..::    //
//    .....    ...:::^^^~~~!!~~^^^^~^^:^^^^:::^^^:^!?JJYYYY5555PP5J!^:::.....:!7!^:. .::        ...    .                  ..?    //
//            ..:^~!7??JJJJYYYYYYYYYYYYY55555YY?7!~~!!!!!!77??7777!!~^^~::^^~7!!!~^:.  .    ..........                   ..^7    //
//        ..:^~~!!77??JY55PPGGBBBBBBBBBGGGGGGGBBBPY?~^:^^~~~~~~^.    ......^^:^~~^:..     .............  .             ...^~~    //
//      ..:^~!7?JY5PGGGBBBBBBBBB###########BBBBB#&###G57^......:....          ........:.    ..    ...... .              .:^~!    //
//    .:^^~~!7???JJY55PGGBBB####&&&&&#############&#&&##B5?!.  ....:.   ...    ...                .. . . . .           ..^^:.    //
//    :^^~!!77?JYYY55PPPGGGGGGBBBB###&&&&&###&&&&&&&&&#&#BG?^^..:.....  ..::........           ..  .   .  .::..     ....:.       //
//    ~~~!7777??JJYYY5555PPPPGGGGBBB####&&&&&#&&&&&&&&&&&#P5Y??J?^.....         ..             ........   ..:::.  .  ..          //
//    !~^^^~7?????JJJJJ^.............:::::::::::::::::::::........                                          ..:.. .              //
//    ?7~~^^^~!777?JYYY.                                                                                   .~~!!!~^:.            //
//    !??!~~^:^~!!7??JJ.                                                                                    :^~!!!!77^.          //
//    ..^~~~~~^^^~~~~~~.       !~~~.    ~.       .!!!^     .~  .!     7!~~.    .~     :~!^     ~   ~        ^!!!!!~^^^^^:.       //
//    ...:~~~~!~^^::.::        @J!!.    #!      ^&: .5G    !#  :&    [email protected]~:PB    ^&     #Y!~     &J:^@:       .~77!!!!7???7!~.     //
//        ..^^^^~!???JJ.       @!:^     #?..    ^&^ .YG    ^&. JB    [email protected]!Y&:    ^&     ~~?&:    &J:^@:       .:~?YYJ7!!!7!~~~^    //
//           ^~~~^~!7?J.       !        ~!!!.    .!!!^      :7!~      !  ^^    .~     ^~~^     ~   ~        .:~~7Y55Y?!^^~!~~    //
//    :     .. :!7?7?YP:                                                                                    .:~!77J555YY?^:!!    //
//    JJ!.     ..?~JY5?.                                                                                    ^^^!????Y55YY57^^    //
//    J5YP?..    ~?Y5J7^... .            .......::::::::::::..                                   .         :!!~~7JJJ?J555Y5Y!    //
//    !?JYPY:.  .:7YP?Y?YJ!7!~~~^:...  ~!Y5GPGGB##&&&&&&&&##BJ ..    ..         .....::..::::^^~~!7~:....::!?77!77JYJJJ555Y55    //
//    :^!7?5Y:..:.~Y5!?YY~?~~^:..!^.: :7Y5PGGBB###&&&&&&###BB~.:    .      ..   ....:::...:::::^~~~!7~:...^^7J?7!?7JYYJJ5PP55    //
//    ..^~!7YJ..^ .J????.^~. :~J!?~!^!Y5PPBBBB##&&&&&&&&##BGY!7:   .     ....  ..:..::.....:^^::^^7~~7!:...~!JY??!??JYYYY5PPP    //
//      .:^~!Y7.:.:!!7J!^~~7~JP5Y?Y55PP5PBBBB#&&&&&&&&&##BPYYY~.....  ..:.........:...   . .:~~~^~^?!~7!:..~!7JYJ?7??JYYYY5PP    //
//        .^^!Y~:^~777JYY?7P5P555PPPPPGBBB##&&&&&&&&&&#BP?7J?!7!~^^:...:...^^^.::.       .^!~~!7?~!:Y!~7!: .?!JYJJ77??JYYYY5P    //
//         .^^!J^~!7?J55Y55YYY5PPGBBB####&&&&&&&&&&&#B5!::~!!!~~~~~~^^^^:.  .    .:^~^::^^J5PJ?YY!?!~P!!!!. 77JJYJJ!???YYYYYY    //
//          .::!7!?Y5YY!JPGBB######&&&&&&&&&&&&&&&#GJ^..:~~~~~~^^....::::.       .:~!?7JYPPGBPYJY~~5^JP!7~~ ~J??YJJ?~??7YY55Y    //
//      ..  ...^??YPGGPGGPBBB#&&&&&&&&&&&&&&&&&#GY~.  .:^^::^^~~!!~~~~~~^::.....:^~!77?JY5PGBG5JJ?:JY~P577~..57JJJJJ7~J77YJYY    //
//    .......:.:~Y?YYY5?5YJGB#&&&&&&&&&&&&&#BP?^.   .:^^~^~~^^^^~~!!~~~~~^^^^^^^:~!~~~^~~!7JYPG5J?!^7?7PY?!^ 7??7YJJ?~~J77YJY    //
//    ...::..^.:~?7!~775~!J!!JGB########BP?~.    ..^~~~~~^^^^~~~^^^~~~~~~~~^^^^::...   ....::^!?JYYYJJ?JYJJ!^:Y7??J??7^~?!!YJ    //
//    ...:^:...:~!~^~:!!5~:!7!^^~7?JJJ7~:.    ..^~~!!~!77!!~^^^~~!~^^^^~~!!777!!~^:.....         ..:^~!7?JYY555555555YJ!?J!!J    //
//     ..::::..:^!!^~::~^??^:^~~~^:..       ..^~^~!!^:^^^^^^:~!~~~~!!~^:.......::::.....                   ....::^^~~!7??JY??    //
//      .:::...::~!~~^..^::~~^:...         ..:^^~~^:..     .:.~!??7!~~~~~~^^:::.......                                    ...    //
//     .:^::...:::^::.........     ...... .  ..:.....          :~7JYY?!~^^^^^:::......                                           //
//     .^::.....:.............^^.:!7~^~~^:.          .          .~7JYPPP5YJ??7!!!!~~~^::.                                  .     //
//    ..:.... ........^~~~~!!~:  :7???JJ?!:       ...         ....^!?JY5PPPPPPPPP555YJ7~:.                                 ..    //
//    ......  ....:^::......      .^!?Y5Y?:                   ..:^^^~~!7777777!!!~~~~^^::...                                     //
//    .......  .^~~.....             .YP5J:                  ....::^^^^^:::...............                                       //
//     ...      .....                 ^YPY.                   ....:..........                                                    //
//                                     :G5.                   .......                                                            //
//                                     .?5:        ......                                                                        //
//                            .... ..   7GJ      ...... ....                                                                     //
//                       .    ~^^::^!   ?P5~     ...    ...                                                                      //
//                                                                                                                               //
//                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FLRSH is ERC1155Creator {
    constructor() ERC1155Creator() {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC1155Creator is Proxy {

    constructor() {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x142FD5b9d67721EfDA3A5E2E9be47A96c9B724A4;
        Address.functionDelegateCall(
            0x142FD5b9d67721EfDA3A5E2E9be47A96c9B724A4,
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/Proxy.sol)

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
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
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
     * If overriden should call `super._beforeFallback()`.
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