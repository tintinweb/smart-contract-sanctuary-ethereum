// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: exp#hamad1997_the_prophecy
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                     //
//                                                                                                                                                     //
//                                                                                                                                                     //
//        _  _        _        __  __        _        ___                                                                                              //
//       FJ  L]      /.\      F  \/  ]      /.\      F __".                                                                                            //
//      J |__| L    //_\\    J |\__/| L    //_\\    J |--\ L                                                                                           //
//      |  __  |   / ___ \   | |`--'| |   / ___ \   | |  J |                                                                                           //
//      F L__J J  / L___J \  F L    J J  / L___J \  F L__J |                                                                                           //
//     J__L  J__LJ__L   J__LJ__L    J__LJ__L   J__LJ______/F                                                                                           //
//     |__L  J__||__L   J__||__L    J__||__L   J__||______F                                                                                            //
//        _  _          ____                                                                                                                           //
//       FJ  LJ        F __ ]                                                                                                                          //
//       J \/ F       J |--| L                                                                                                                         //
//       /    \       | |  | |                                                                                                                         //
//      /  /\  \  __  F L__J J                                                                                                                         //
//     J__//\\__LJ__LJ\______/F                                                                                                                        //
//     |__/  \__||__| J______F                                                                                                                         //
//                                                                                                                                                     //
//      ...  ..  ...  ..  ...  ..  ...  ..   ..  ...  ..  ...  ..  ...  ..  ...  ..  ...  ..   ..  ...  ..                                             //
//    ..  ...  ... ...  ...  ..  ...  ..  ...  ..  ...  ..  ...  ...  ..  ... ...  .......  ...  ..  ...                                               //
//      .....:..:..::..:..::..:..:..::.... .:.::::::.....:..::..:...:..:..:...:..:..!J77Y~.::..:..::..  ..                                             //
//    ..  .:...:.....:..::..::....::..:^~7??JJJ?JJJJJ?7!^:....:...:..::....::..::.~57.  7P...:...:......                                               //
//      .....:........::...:.......:~?JJ?!~~~^^^^^^^^~!7JYY!....:.....:::....::..JY:   :5~.:...::.....  ..                                             //
//    ..  .:::.... ....::::..:.. :7YJ!~^^^^^^^^^^^^^~7J5PGBBP7....:~7JJJY5^....:57    ~P5!..::::.::.....                                               //
//      ...:..:..^!!~^...:..:...75?^^^^^~~~~!!!7?J5PGGGPPPPPPBP~~?JJ???JJ?:.:.^P~     . .5?..::.::..:.  ..                                             //
//    ... ......JJ~^~Y?.......:YP7?JYY5PPPGGGGGGGGPPPPPPPPGGBBB5YJJ?7!~:..::.~P^      ..:Y?.......:.....                                               //
//      .......!P     ?J!.....:#GGGGGPPPPPPPPPPPPPPGGGGGPPP55YJY55!....:::..?5:   .~7??77~........:.:. ...                                             //
//    ... ...^!57      .?Y:....5BPPPPPPPPPPPPPGGGG5YYJJJJ?7!^:.  :JJ:.....^Y?  .~?J7^.....:..:...:..:.....                                             //
//    .....~J?~:         ~??7!~7&PPPPPPPPPGBG5Y??JJ?7~^.           ~5~.:~?J^ :7J7^...:..:..::..:...:......                                             //
//    ... 75.          !!~^:^~~~7BPPPPPBBPJ7!7J?!^.                 :5J?7: :JJ~:...:.........:::.:........                                             //
//    ... !5^:.....:^~JJ~!!7?77!^YBPGBGJ!!?J?~...                    .B! .7Y~..::..:.........::..:........                                             //
//      ...:!777?7777~^.......:^!Y&GY!!?J7^ .?G#&#GY~             ^JPPBB?J7...:..::..:..:..::..:...:.. ...                                             //
//    ... ...................^!?J?!^!PY:   ?&@@@@@@@@G:         [email protected]@@@@@&~..:......:..::..:.........:...                                               //
//      ......:..::........:JY7~^^7YJ7P.  [email protected]@@@@@@@@@@#.        [email protected]@@@@@@@G...:........:::.:.........:.  ..                                             //
//    ..  ..:...:...:......JP^^!?YJ^..!P: [email protected]@@@@@@@@@@@:        [email protected]@@@@@@@&?7^.......::..::..:.....:.....                                               //
//      ...:..:...:..::.::.~JJJ?!:..:..~5!!&@@@@@@@@@@J         .5&@@@@@#! ^P!..:.::..:...::.::.::..:.  ..                                             //
//    ..  .:::..:...:..::::..::...:..::.:?JJB&@@@@@&P~          !P5?Y?!^. .~5!.:::..::..::..::::.::.....                                               //
//      .....:....:...::...:....:...::....:7JYYJ?7~.        :^^^JBY..:^!?JPG:.:..::...:....:...::...:.  ..                                             //
//    ..  .:...::...::...:..::....::..::.....^!77!~~~^^~!7Y5JJ#Y?77JY5Y7^ !5...::..::..::::..:...::.....                                               //
//      .....::.::::..::..::..::::..::..::..:....~G!~~YP~:Y?  7J          J5^:...::..::::..::..:...::.  ..                                             //
//    ..  .:...::...::...:...::...::..::..::...:.5J . ?J  Y7   5~         GJ!??!^.......::...:..........                                               //
//      .....::...:...::...:...::...::..::...:..:G!!!!P5!!GY!7!JG!~~^^:..:#:  :~7J?~:.........:~!!7~:.  ..                                             //
//    ..  .:::..:...:..::::..::..::..::::..:....7P~!!!GJ!7GJ!~~:G7:^~~!!!5B       :!??7^::^!???!~:^7Y^..                                               //
//      ...:..:...:..::....::..::..::.:..::..:. J?.:.75 . 57:^~!5P!!^.   5Y          .^7??7~:      :P!  ..                                             //
//    ..  ..:...:...:........::..::........::..!#5^: ?7   Y!    :G.^~7?7!#?^^^^^^^^::.          .?J7^...                                               //
//      ......:.:::...:.......::::..:....:...:JJP?!?JYJ!~.Y7     5!    .7G~!~!!!!77!7??7~.      .?5^..  ..                                             //
//    ..  .:..::.::..:...:..:..::.::..:.....!5! 5~   .:~!7PP77~^.!5     57............:^!Y7       ~G:...                                               //
//      .....:.....:...:..::..:.....::....~Y?.  P!        ^!.^!?JY#7~: :G:....:..::..:....YJ    .!Y!.. ...                                             //
//    ... .:.........:..::.......:!J?7??7J?:   JB7               .?!!?J#7......::..:.......?J77??7:.....                                               //
//      ...:.........:.:::......7Y!.   ...    5775                    JJ........::.:.........^^:...... ...                                             //
//    .......:..:..::..:..:...^57            Y?.:G.                 ~5!...::..:..:...:..:...:..:..::......                                             //
//    ........:..::.........:.7P.::^~7.     75...JJ               ^YJ:..::..:......:..::..:.........:.....                                             //
//    ........:.:::.:.........:!777!7B      G~.:..JJ:           ~JJ^.::::::::::......::::.:.......:.:. ...                                             //
//    ... ......:...:.........:.....^G.    ~P..:...~J?~:.....^7J?^..::::::::.:::....::..::..:.....:.....                                               //
//      ...:..:...:..::.::..:..::..:.7J7!!7Y~....:...^!7????7!~:..:..:..::..::.::..:..::..:..::.::..:. ...                                             //
//    ..  ........ ....................:~^:............ ... ............. .......................... ...                                               //
//      ...  ..  ...  ..  ...  ..  ...   .   ..  ...  ..  ...  ..  ...  ..  ...  ..  ...  ..   ..  ...  ..                                             //
//    ..  ...  ... ...  ...  ..  ...  ..  ...  ..  ...  ..  ...  ... ...  ...  ..  ...  ..  ...  ..  ...                                               //
//      ...  ..  ...  ..  ...  ..  ...  ..   ..  ...  ..  ...  ..  ...  ..  ...  ..  ...  ..   ..  ...  ..                                             //
//        ___      ____         _  _     __     _  _      ___         ____                                                                             //
//       F _ ",   F ___J       FJ / ;    FJ    F L L]    F __".      / _  `.                                                                           //
//      J `-'(|  J |___:      J |/ (|   J  L  J   \| L  J |--\ L    J_/-7 .'                                                                           //
//      | ,--.\  | _____|     |     L   |  |  | |\   |  | |  J |    `-:'.'.'                                                                           //
//      F L__J \ F L____:     F L:\  L  F  J  F L\\  J  F L__J |    .' ;_J__                                                                           //
//     J_______JJ________L   J__L \\__LJ____LJ__L \\__LJ______/F   J________L                                                                          //
//     |_______F|________|   |__L  \L_||____||__L  J__||______F    |________|                                                                          //
//      _  _    ____      _  _      ___       ___      ____      _         ____                                                                        //
//     FJ  LJ  F __ ]    FJ  L]    F _ ",    F __".   F ___J    FJ        F ___J                                                                       //
//     J \/ F J |--| L  J |  | L  J `-'(|   J (___|  J |___:   J |       J |___:                                                                       //
//     J\  /L | |  | |  | |  | |  |  _  L   J\___ \  | _____|  | |       | _____|                                                                      //
//      F  J  F L__J J  F L__J J  F |_\  L .--___) \ F L____:  F L_____  F |____J                                                                      //
//     |____|J\______/FJ\______/FJ__| \\__LJ\______JJ________LJ________LJ__F                                                                           //
//     |____| J______F  J______F |__|  J__| J______F|________||________||__|                                                                           //
//                                                                                                                                                     //
//                                                                                                                                                     //
//                                                                                                                                                     //
//                                                                                                                                                     //
//                                                                                                                                                     //
//    WHAT YOU SEE HERE IS THE REASON WHY ITS HAMADS WORLD                                                                                             //
//                                                                                                                                                     //
//                                                                                                                                                     //
//    EACH IS A DAILY                                                                                                                                  //
//                                                                                                                                                     //
//    NO REFERENCE                                                                                                                                     //
//                                                                                                                                                     //
//    AT LEAST 1 HOUR WAS SPENT ON EACH                                                                                                                //
//                                                                                                                                                     //
//    ALL 3D ARTWORK                                                                                                                                   //
//                                                                                                                                                     //
//    HAMAD                                                                                                                                            //
//                                                                                                                                                     //
//                                                                                                                                                     //
//                                                                                                                                                     //
//                                                                                                                                                     //
//                                                                                                                                                     //
//                                                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract EXP is ERC721Creator {
    constructor() ERC721Creator("exp#hamad1997_the_prophecy", "EXP") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x5133522ea5A0494EcB83F26311A095DDD7a9D4b6;
        (bool success, ) = 0x5133522ea5A0494EcB83F26311A095DDD7a9D4b6.delegatecall(abi.encodeWithSignature("initialize(string,string)", name, symbol));
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

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
 * ```solidity
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
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
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

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
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

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}