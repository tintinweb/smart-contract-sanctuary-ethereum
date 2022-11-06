// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DEVIL WARRIORS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    :. ...............:!??^.:... ...:JJ?^.. .:!77~:... ...^7J7!^:..:~?5?.....::^^~?J7^............... ..    //
//    .                  :7?!:  .     ^J?!^.    :~?7:.     .~77~:.   .^7JJ    ..^^!??7^                       //
//    .                   ^!J7:.. .   7J7!^:     .!J7:    .^7?!:.   .:^!?Y:....:^~7?!^                        //
//    .             .     .~?J7^... .^?J7!~^..    ^7J7:   :!??:.   :^^~!JJ7:::::^7?!^.                        //
//    .              ..    :!!?7^....^7J?77!:.   ..~??~. .!?7^.   .^~!7?J!.:::^^77!^                          //
//    .               .     :!?J7^:..:^?YY?7~:.::^:^!?J! ~JJ!^^::^^!7???!^:..^~!?7^.                     .    //
//    .               :.     ~7?J7~~^..:7!?7~^...:.:^~YJ^7J!~^::^^^^~~!!^ :^^~!7?~.     ..               .    //
//    . ..            ^:      ^!JYJ!:..:~?^^:^^::.:^^^~^.^^::::^:~^^^:7!~:.:^7J?!^     .:.            .  .    //
//    .  :.           :!.     :!7JY5?!!~??!:  :^^!!~:!!!~~!!^~!!~^. .:~?77??JYJ!~^. ..^^.            ..  .    //
//    .   ^:           ~~. .. :~~?YY5?77!^!!^.    .~!JJ?J7?J!~.    .^~!!7!?J5YJ?7..:77:            ...   .    //
//    :    ^~:          ~77~::^!7JY?!~!!!~^7~^       :~:~^~:.     .^~7~^!7!~7YYJJ^~!!:            .:.         //
//    .     ^7~:.        :7J?~?JJJ5JJYJ!~~~^:~~.      .~!~.     .:^::~!777JY!~YY55YY~:^.:..     .^^.     .    //
//    .      ^7?7~:.       ^?JY5J7!5PYJJ7~....^~!~:. .:77!:. .:^~~:..:!7??7YP7!YYP5P?^7!^.   .^~~^.      .    //
//    :     . .!?J??7^..     ^~!^7YJ5YPPPPP?~::..:^!~::~7~^:~!^...^~?555PPP55Y!^~!^^:.    :^!777^        .    //
//    . ...  .. .~?JJJJ77~~^.:::??!^~!?55Y?77??J?!7?777Y7J!7YJ?7JJ?!~75P5Y??7?7~~.....:~!77?J7~::.       .    //
//    :.......... .^!JYYYY5YYJ?JY?~....~J5Y7!7YPPGGGPPP?^75GPGGGP5J7!J5Y7:^^:^!?7^~7?JYJJJJ?!: :^........:    //
//    ^......:^.. ....:^7J55YYY55PJ!^. .:~!!!?JJJJ?YYY?^.^J555??JYJ?!~^::..:^~?5YYJYYJJ??7!?!~^~^..:.::::^    //
//    ^::...::...:. .::^!?J5Y??5PP5P57:      ..:^~!7.:.   :.^J!~::.       ^!?J555Y5JJY5Y?J7!~!77~^~!~^^^^^    //
//    ^:^:^:.::~^:^!7?JJY5Y??55PPPPPPGY~.  ..:!JJ~::~:    :!~.~J5J!:.....~YYJYY55JJJPPP5YY5?!:.:^~~!?J?!~~    //
//    ~^^::::~~^^7J55555Y775PPPPPYPP5PPPY?^:~JP?^^^:~!:.  ^7^^!!~J5J!:^!YP555Y?PGPPPPPPP5J7Y5J?7~. :^7JJ7~    //
//    ^:^!~!!^..7YYG5PPJ~?55J55YP5Y55PP5PPY?Y5!.:?Y55?J?77?JYPY!..~55JJ555P555?5GPGPPY5GPP5JJPPY?!:.::~7YJ    //
//    :^7??7~:..~J5GGPJ^JG5?5P55P5?YPPPGPPG557: .:^!J55P5P55J!:.. .~YP555PP5Y??5PPGP5J5PPGP5JJPPP5YY?!7!!7    //
//    ~!7!~..~?JJY5PPY~YPGJ~Y5PPGG??5YPGP5PY!:....   :~?J?!^: ....::!JY5PPPPY~7PPPPP5J?Y5PPP5YJ55P5?!7??!^    //
//    ?!^.  .:?PPPPPPY5PPYJ.^J7~?YJ7YYPG5J5J^^~^:^^^:. ::. .^^^^~~~^~?J?5PPYJ^?PGPPP5P5????Y5P5Y5PPPJ77??^    //
//    7^^~.:~~!J5PPPYPPJ7??^ .~Y5?5Y55Y5Y^7??J?Y55Y5YYJ???JJYYYYY577??!^YPYYJ^?J5Y5PPY:Y?7YY55P5Y5PPP5YJY!    //
//    ?77!~7JYYJ5P555?!?Y5?^. 75!5G5YPJJJ^75PY?!^JY7J?JY5YJYY7JJ:^7Y5Y~.?Y?P??PJ5Y!?J::P5??PPP55J7!7Y5PP5?    //
//    ?Y?!?YY5PP555J??5G5JJ7~. ~YPPG55557^7GJ.   JP:JP^!P!~PJ:5?   ^5P!:~555?5PPPPJ^. !PPGJ?P5PP5YJ77JPGPJ    //
//    JY?JYP55GG55YY5PPJ?YP?!^..?PP??555J?!G7. .?PGY5GY5PYYP5YG57.  ?G!!75PP555GPP!..!7YPPGYJPPP555YJJYPP?    //
//    Y555PPPPG5PPPPPJ??PG5J!7~. ~J^^P55PPJP5?^7?PPGBBGGGGGGGGP5?^:7PG7YJYGJ7PPGJ^ :!!?PPPGPY5PPP5555YJPY~    //
//    P55PPPGP5?7?77!J5PP5JP5J?7^.~~:?P555YGGPY!^PGGGGGGBBGGGBGY:!YPGGY5JJ57.JJ~ .~7?J5PJ?5PGPPPP5PP5P5?^:    //
//    PGPPPP5?~:~~!JYPGPJJPPP5?J7!?J!:~JPPY5?!^~?5GGGBBGBBGGGGG57^!J5GYJY57^.: .^!7?Y55P5?!7JJ5GPPP5P57!7!    //
//    PGPPPJ!!7!?JY5PPJ7YGPYPPPJ!?JPJ^::^?^.^!?P5?PGGGGGPGBBGPJJ5Y!^^~!Y?.^?77^^J?JJPGPP5PY???JPP5555?7JY7    //
//    55YJJ?YYJJ555YYJ?Y5Y7YGGGGYJ7J7^~:  ~~7PPY?~~PPGBGBBBG5J.77P5?::^..^~P57?!?JPG5YGPP55Y?Y5YPP5JY5PP5J    //
//    YJ??JYJJJ55555YYYJ77PGGGGGPYJ?JY5Y!^7Y5GPP??:!P5PYYJYY~.^?YPGP??^.^?!J5?J?YPGPPYJYPPYYJJ?555P5PPP555    //
//    5JJYJY555P55555JJ?Y5GGGGGPPG5Y5Y5GPY55GG555Y?!7~!~^~!7!?Y55PPPG??7YGY?JJ75BGGPGGPJJ5PP5YYY5PP55PPPPJ    //
//    55PPYPPPP5PGY5555PGGPGGGGGGG55575PGPPGGPP5?~!!!7777777???JYYPGP555GGG5J?JGGBGGPGGP5Y5PPPPPPPPPPPPGPY    //
//    5PPPPPPPPPGPPP55PG5J?J5PPGBGGB55GGGGBGGP55Y7!~^^:.:::^^^~7J?PGPPPPGP5YY?GGGGGPPPGPPPPPGPPPPPPPPPPGG5    //
//    PPPGGGPPPPPPPGPPP5JJYY5GGPGBGGGBBGGGGGGPPP55555JJJ?JJJYJYYJ5GGPGGGGPPJYPGGGPPPPPPPPPPGGGPGGPP5PPPPP5    //
//    PGGBBPGGGGPPGGPPPGPPPPGGGGGGGGGGGGGBGGGGGPPPPPGPPGGGBPPPYY5PGPGGGBBBGBGGBGGGPPPPPPPPPPPGGGPGPPPPGPP5    //
//    GPGBBPPGGGPGGGBBGGGGGGGPPGGGBGGGBGBBBGGGGGG55YJ?7?77777JY5PPGGBGGBBGGBGGBBGGGBGGGGGGPPPPGGGGPPGPPPG5    //
//    55PGPPGBPGGGPGGGGGGGGGGPP5YYYPGGGGGBGGGBGGG5YJJ7!!~^!!!?555GGGGGGBGGGBBGGGPGGGGGPPPPPGPPPPPP55PGPGPY    //
//    5PGPPP5Y5PPGPPGPPGGPPP55YYJ77YPPPGGGGBBGGGGGP5PPPP555YY5PPPGBGGBBBPPGPP55PPGPPPPGGPPPPPYPPYY55PGPP5?    //
//    PPPPPPP5J?J555PGGGPGGGPGGPPPPPPGGGPBGGBGGGGGPGGGGBGGGGPGGGGGGPGGGGGPGPPPGPGGPPGPGGPPPY??YJY5PPGPPP5J    //
//    PGGGGPPP5Y??!!~7?5PPGBGGBGPGPPPPP5YPPPBBGGBBGGBGGGGBGGGGGGBGGGGPP5P5YJY5PPGPGPGGGG55?!7?Y5PGPPPPGG5J    //
//    PGPGPPGP5PPJ7~^..^!JPGPPGPGGGGPP5J!!!7?YPGGGGGGGBGGBGBGGBGGPPPY?!~^~!JY5PGGGGPBPPP5J?YJ5PGPPPPPP555?    //
//    PPPPPPPPP5P5P5YYJ~!!?Y5PGGGGGGPPPYJ7~^~7J5PGGGGBBBGGGBGGBGPP5?!^.:^!J5555PGGPPGP5P5Y555PP5PP5YJY55P?    //
//    PPGGGPPGPPGPPPGGPPB55G5PPGGPGPPGPPP5J??Y55PGGGBBBBBBGBBPGGP5J77~!!7JPYJ5GGGGPPPPPP5P55PYYPP5?JJ5GP5?    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DEVIL is ERC721Creator {
    constructor() ERC721Creator("DEVIL WARRIORS", "DEVIL") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x03F18a996cD7cB84303054a409F9a6a345C816ff;
        Address.functionDelegateCall(
            0x03F18a996cD7cB84303054a409F9a6a345C816ff,
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