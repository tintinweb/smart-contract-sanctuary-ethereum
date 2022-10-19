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

/// @title: RARE KRAZI
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    ~~!7~?JYYYYYJ??7!!?J??JJ?!77!!77??JJYYYJJYYYY5555Y7?!!~!!!~~~!!!~~~!~777!!7^!!~!~?!!7!!~~!!777?. ..~    //
//    ^^^7~!?JJJJJ77775BGBG5?J?7~!???7?J5PP55555PPPPP55J~!!~~~!~~~^!Y7!~J7^~7!~~!~7?JJYJYJ7!~~~~^~::!:...:    //
//    ^^~7!77???YJ???7JYJJJY???777?77YPPGGGGGGGBBBBBGGGY^^^^^^^~~^^!?7!7J!:^:::^^!YPPPG5YJPY7~!~~!!:7J????    //
//    ^^^77J???J5?5YY??!~~~~!!!7?7777JJJYYYY5PPPGBBBBBBG?J?~:^~!7^~J?!J5Y!:^:::^^7Y555PY!P5?^:.^7757?7!77?    //
//    ^::7JYYJ!JY5557!?7!~~~!!77?~7?~^!!~7!~777???JJY5PPJ7?^^77Y57~?7?J5JP:^!7^^^^^~!JP5?YP5!!^77?J!?:.:^~    //
//    :::!Y55Y!?555P5JJ5Y5PG5^!!7~~7!7!!~?!^?7^~~^~!!!7?JJ?^!!7Y5P5J75PYPB!!~?J!~~^^^?55YYJ5??5Y!J?~~^:::!    //
//    :::!Y555J77YYY55YY5PBBB7!7??JJJJ77??77J?7~!!!!~~7?Y???J?7!YYYY5PPBB5!75Y?!!77!~~!!~7J7~?P575?J:.:.~~    //
//    :.^!J555Y:JJJJ5555PGB#GY??777??J5?!!?!^J7!577J7??J5J????!~?JJY5PG#57J7~^^^^~!~?7^~^~??!77??JJP!.::~     //
//    :.^77555! ?JJJJYYPG##J!!!!!!!!!~!5Y~7777^^!!?P5YJJYJ7!?7~!JJY5PGBP~^^:....:~!~!7?!~~?7!!:^!??5?.:~^:    //
//    ::^7!55~^^7?YYYPGGBB!^^:^!!!!!~^~~5J!!JY!7JPGGPP5YYYYJYJ?!YYPGGB57!!??7777?J7!7J#?:^J7~^::7??YY:^7!7    //
//    ::~!!Y5J??JYYJ5GGJ#Y^^75~:!!!~^YJ:!P77Y57777755YYJJ7!!!?JJYYGGJGYJ!^7?7^^:~J7~!J5!^~7J7~^^!J7JJ^~~!!    //
//    ~^^~~Y5Y!!Y5YY5PPYBY~^75~^!!!^^J!:!G?JY?7~!!!JYYYYJ?7^^~~77YPP5G7!777!^:...~7777J~^~!??^^~?7~77^~~!!    //
//    ~!7^!YYY??5YJY5PPPB577?!!!7777!~!!7P?JJ???77~JYYYYJ77!!?7!!YPPPG?.:::...........J77??YY?Y????J5~!~~^    //
//    ::~Y7JJYJ5YJJJ5PPPG5!!B!7?J7??J7Y?7GGY7J?7??7Y5YYYJ?~^~YJ~^?PJPPY:......:.......5YY5555J?YJ??Y?~~~^^    //
//    !~7BY5555P55YYPGGGGB5?GYJ?JYY??5P5P#PY?JJJYY?5P5P55Y5J?YJ?77PYPGG?~~^~~!~~~!~~^JBG5Y5PP?5PPPY?J777!!    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@&&@@@@@&&&&&&&&&@@@@@@@@@@@@@@@@&###&@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@&~:^:[email protected]@@@@@@@Y::[email protected]@~::::......:~75&@@@@@@@@@@#: . :#@@@@@@@@@!.:::::::^^^^:[email protected]@Y:^:~&@@@@@@@    //
//    @@@@@@@&.   [email protected]@@@@@@G    [email protected]@^   :!77!!~:   [email protected]@@@@@@@&^     ^&@@@@@@@&~~~~~~~~~.    [email protected]@J   :&@@@@@@@    //
//    @@@@@@@@^   [email protected]@@@@@B.   [email protected]@@!   [email protected]@@@@@&5.   [email protected]@@@@@@!  .7   [email protected]@@@@@@@@@@@@@@@5.  :[email protected]@@Y   ^@@@@@@@@    //
//    @@@@@@@@~   [email protected]@@@@G:  [email protected]@@@7   [email protected]@@@@@@@7   [email protected]@@@@@?   [email protected] [email protected]@@@@@@@@@@@@&7   7&@@@@P   ^@@@@@@@@    //
//    @@@@@@@@!   JGP5J~   7#@@@@@?   [email protected]@@@@@@&~   [email protected]@@@@Y   [email protected]@@~   [email protected]@@@@@@@@@@B^  [email protected]@@@@@G   [email protected]@@@@@@@    //
//    @@@@@@@@7          [email protected]@@@@@@?   ?55PP55?:   [email protected]@@@@P   [email protected]@@@#:   [email protected]@@@@@@@@5.  ^[email protected]@@@@@@G   [email protected]@@@@@@@    //
//    @@@@@@@@!   ?GGG7   !&@@@@@@?             ?#@@@@@#.   5#####Y   :#@@@@@@&7   7&@@@@@@@@G   [email protected]@@@@@@@    //
//    @@@@@@@@~   [email protected]@@@?   ~#@@@@@!   ?BBBBG^   [email protected]@@@@@~               ^&@@@@B^  [email protected]@@@@@@@@@P   ^@@@@@@@@    //
//    @@@@@@@@^   [email protected]@@@@J   :[email protected]@@@~   [email protected]@@@@#:   [email protected]@@@?   :777777777^   [email protected]@@Y   ^#@@@@@@@@@@@Y   :@@@@@@@@    //
//    @@@@@@@&:   [email protected]@@@@@5.   7#@@^   [email protected]@@@@@B.   [email protected]@5   :#@@@@@@@@@&:   [email protected]    ~7!!!!~~^:[email protected]@J   .&@@@@@@@    //
//    @@@@@@@&^.:[email protected]@@@@@@B~...^#@~.:[email protected]@@@@@@G:.:.J#:[email protected]@@@@@@@@@@G:::.G5............. [email protected]@J.:.^&@@@@@@@    //
//    @@@@@@@@&&&&@@@@@@@@@@&&&&@@&&&&&@@@@@@@@&&&&&&&&&&@@@@@@@@@@@@@&&&&&@&&&&&&&&&&&###@@@&&&&&@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    &&&#&&&&###&&&&&&&@&&&&&&&&&&&&&&&&&############&#&&@&&&#&###&@&&###&###&&&#####&&&&&&&&&&&&&&&#&&&@    //
//    5Y7^JGYJ!!~!?JGGGGBP555J7?5P55555PGB55Y?J!~!7J77Y??Y55557?!?!5PYY?7!!~!7JJJ!~^~7YG5YP55PPPP5P5Y!!77?    //
//    !~:.JGJ7!75J?7PGGPBG555JJJ??5YY?5PPB5PP55Y55YJ5YGP?JJ?J?777?JJJJP??55PPPPPPPYY??PPG5GPYJJYYJ5PJ~~!~!    //
//    ^^^^7J7~:^?!~^!??YYP5PPGY777J!555JPPJYJYYJ7JJ?JYY7JYJYY5YJYPGYYY5GJ55YP5PPPP5575#YPYGJJYY55YJPY^~~~!    //
//    ^^^^.  .:..::.     .?GPP55?!JY555PY^~~^^:......  .?YJJ5J?7JYP555PBBPY??Y5YY77?5BB55YGYJYYP5YJGJ~~~!!    //
//    ^:::.  ::.....       :!7P5PPPP5PJ! .::.   . .    .?YYY55YYYYPP5PGGGBP55?JJ?PGGP5PBGGPP5PPGGPPP?~~~7J    //
//    ^^^^.  ...          .:~!?YPP5JYJ~   ....   ..    .?YYY55555Y5PPPGBGPJJ5777?YYJ5PPBG555Y5JJY555?~~~7?    //
//    ::::. . .        .^7J?J?7J55J77??7!^  ..         .?YYYY5PP55Y5PGGPJ??7!777??7??5PBG555Y555PG5YJ~~~~!    //
//    :^^:.          .!?J?7777!?JJJ7?7777J?. ...  ..    ?YYYY5P555YPGPJ777777777777?JJYPG555YY5J7P5JJ~~~!?    //
//    ^^:^^^:7:!7.:!?J????7777777????77?77??:^^:::::::::~JYYYYYY5YPGJ?7?!!??777!!!!77?JJ5P55JJY5YYYYJ!~!7!    //
//    ::::JP!B7J577YGP77?777!!!!7?7????7777J57?7777YGPG5^^::^^^75YG57??7!7?7777!!!!!77?JYGPJ?JY55YYYJ~~!7!    //
//    ~^^^JG??~!?PPPG57777?7!!!!77??????777??!7!^~?PGGGP~~^ .  ~YYGJ77J7!7777!7!!!!7!??JYPP~!YYYYYYY7^^^^^    //
//    JJJ!?Y7:.:^77!YJ777??77777777?????777?5YJ7?JJ?PPP5~PGJ7!7JJYB77?J?J?7?7!!!77!7!7?7JG5J?YYJJYYJ^~7!^~    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RAREKRAZI is ERC721Creator {
    constructor() ERC721Creator("RARE KRAZI", "RAREKRAZI") {}
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