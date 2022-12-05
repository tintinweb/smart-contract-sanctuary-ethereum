// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sun City Poms Edition
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    ......................................................................................................................................................    //
//    ......................................................................................................................................................    //
//    ......................................................................................................................................................    //
//    ................................................^7~.::................................................................................................    //
//    ...............................................::!YJ:7~:..............................................................................................    //
//    ...............................................^?YJ5YJ5?:.:........^::^~~^:...........................................................................    //
//    ................................................:?PG5PPY!?:......~J???7~^.............................................................................    //
//    ................................................:~7J55GP57....^JYPPPY?7^:.......::^~~!~:..............................................................    //
//    .............................:^~!7777!^:.......:^!JYYPPG5~7:7JGGPPGPJ~:^!7JJJYYY5PPJ?!:...............................................................    //
//    ...........................~?5GGGGGGGGPPYJ?7~^:.:!Y55PPGP5!7GGGPPP57~75GGGGGGGGGGP?^:.................................................................    //
//    ........................:!YPPP5Y5555Y55PPPPGPPPY7^?GGGPGGY!GPPPGP?~?PGGPPPPPP5YY7~:...................................................................    //
//    ......................~?5PP5YYYY5YYYYY5PP5555PPPP57~YP5PP!5P5PGY!^YGGGP5J??7~~:.......................................................................    //
//    ...................^75PGP5??YJ5Y??Y??Y5555P55Y55555JJ555?JP55PY~!PGPGGGGPP5Y7~:.......................................................................    //
//    .................~YPPJ5Y!^?5?5PJ?5J7YYJJ??7JPPPPPPPPPPPP5PP5Y!~YGGGP5PJ!!!77!~!!!!!~~^:...............................................................    //
//    ...............:!YY?!?J??YPPPPPPPPPPPPP555Y5P577YP555PPPPPY?7JP555PP55Y55PPGGGGGGGGGPYJ7^.............................................................    //
//    .........::^!7?YPPPPGGGGGGGGGGGGPGGGGPPPPPPPP555?77Y55PPY7?Y5YY55GGGGGGGGGGGGGGGGGGGPPPP57:........:~~:...............................................    //
//    .......:~7??YPBGGGGGGPPPP5PGG5YYPGGGGPGPPPGPPPPPP5J7J55Y?Y5Y5Y5JY?57JP55GPP5G5YGGGGGGGGPP5J!~^.....:~?5J!.............................................    //
//    ..........:!????JYJ?JYYJY55J7JPGGP5PPGPGGGGGGGGGPPP55555YJJJ?7J??!77!7!!YYYYJG?YBGPGGPGGGGGG5J7!...:?PPGP7::..........................................    //
//    ..............^~^:.~~^!7!^:!?PY77J55GGPPPGGPGPYJPPPPPP555555J~75YYYYYYJJJYYY?JY~5P5JG?5P55PPPPPPY:..~5GGGP!!..........................................    //
//    .....................::...^::::!J7~??77!77777?JPPGPP555PP55YP5J?Y555555YJYYY55YYJJ?7?7?PP5555555GP~:7YYPPP5!J^........................................    //
//    ..............................:^...:.....^7?5PGPP5Y5PPPPPPPYYPGYPYYPPP55Y55555PPPPP5Y!^YJ755YPP55GG~:YP5PPPPG^........::~^~~:.........................    //
//    .....................................:~?5PPPPPPYY5PGG5JGGPP555GPPYJJ55GPP55P5PPPPPP5P5?!?JYPJ5PP5PPP~7PPPPGG5:....:^~?Y5PY7:..........................    //
//    ...................................^?5GGPPPPPYYPPPGGG55YPGP5P5GGPPY~7~Y5GPPPPPPPGPPP5PG5J555PPPP555P5!YPP5P5~.:~:??5PGPY?~:...........................    //
//    ..................................~J5PPPPGPYYPGPPGPPG7~YGGPPP5GGGPP7:.:JPPP5?G55PP5PPPPPPPJYY5GGGGGPP5JPP5PJ.^Y?YPPPY?!:..............................    //
//    ................................:75PGGPGP5YPGG5PG55P?!PBBPPPYPPGGPPPJ^.:?7P!^GJ5JPJ5Y5PPPPYYY5PPPPPPPPP5555~^55555Y?^.:::::...........................    //
//    ...............................:75GGGPP5Y5GGP55PJJY5?JPGPPP5Y5P5PP5Y7?^.^!5??P5P5P555Y55555YYJJJ5PPPPPP5YYY7J5J?!~^~!?JJ?JJ!~^........................    //
//    ...............................~YPPPPP5YPGGGPPPJ?Y5J!YYPPPP5P5P5PPPPJ~?JJ7?JYPPPGPGGGP5555555?JY5555PPP55Y5Y?!7?77JY555555PPP5J?!~:...................    //
//    ..............................^YGGGGP55GBGG5GYP7Y5P7!!5BGPPGGGGPGGGPJ?~^^7YJJ5GGGGPPP555PPPPP55P5Y555PP5Y5YJJY5YYYJJY5P5J??5PPPYJJ7~:.................    //
//    .............................!PBGGGP5PGBP5PJ5:^?5PP^!PPP5PGGGGGPGGP5P!..:~:^Y5JJJ7?J77YP5555555YYJJJY5YY555555555YYJ??????7!?YY5YJ?!^:................    //
//    ............................:YGGGPPPPPPB7J77^.^Y5PY~!!7!5GGGGGPGGGGJY5:....:^^:::!JJY5PPPPPPPPPPP5YYYY5YJY5YY5PG5PPPPPP5Y?!!:^~~!^!!:.................    //
//    ...........................^5BGPPPGPB?PP.~....?Y5G7..::JPGGGPGPGGGGP:7?.......:!5PGGG5GP5GGGPGYYPP55555555P5JJ7YYJ5?GPGGGPPY7:........................    //
//    ..........................!5JP5PGGPJY~B~.....:YY5P^...~YBP?PGGGGGGGG~.!:...:~JPGGGGG?YYJJJPPPPP?JY5JJYP5PPPGGGG557?!PYPGGGP5YY?^......................    //
//    .........................^!:7575PG?!^?7......~YYP5:...?G?:?5GGGGGGP5:.....!JGBGGGJ5?^^^7YPGGPJJ!Y5?^75GPPGPPGPGGGGPJ?!5GPGGG5?JJ^.....................    //
//    ...........................^5!5!J5:..^.......?Y5PY...:7:.!!?PPGGGPP~......~5PYYJ~:^.~YGGBGG5YJ7J5?.:JGGP55P5PPGPGPPBGY7J!Y5GGPJ77:....................    //
//    ...........................~^!Y.7!..........:JYYP?......:.7G55PPPPP^......!7^:^...:7YGGBBJY???Y57.:JJ5P555555Y55PPPPPPP?^!?Y5GY7^:....................    //
//    .............................!!.^:..........^YY5P7.......~GPY55PG?P:.....::.....^?YPGBPPP~!~?Y5!..^!?GGPPY5?JJ?5GPGGGPPG5~^J?PY7~.....................    //
//    .............................::.............~YY5G!.......YB55G?!G~!............~?YGGGG???.~J55~....:YBP?P!YP7~:!YGGGGGGGBP7:^J?^:.....................    //
//    ............................................!YY5G~.......55JGP~.^^............^?YGB5?Y^::!Y5P~.....^5Y!YGY~5J~..~7YY5PGGGBP^.!:.......................    //
//    ............................................7YYPG~.......7~55~................!PGGY~:^..7Y5P~.....:!!7PGGG7~7~....7!Y?GGGGBJ..........................    //
//    ............................................7YYPG~........:Y^................:JPY7.....7Y5P!........!JYG5YY::::....^~?G5BGBP^.........................    //
//    ............................................7YYPG~.........^.................:~~^.....7Y5P7........^~JPG!?7!.........7JJGGGB7.........................    //
//    ............................................?YYPG!...................................7YYP?.........:!7?5:^:~.........::Y!JYP7.........................    //
//    ............................................7YYPG!..................................!YYPJ..........::.7~..............:~::^~:.........................    //
//    ............................................7YY5G7.................................~YY5Y:.............:...............................................    //
//    ............................................7YJY5J................................^JJY5^..............................................................    //
//    ............................................!YJYPY...............................:?YY5!...............................................................    //
//    ............................................~YY5PP:..............................7YYP?................................................................    //
//    ............................................^YYYPG~.............................~YYP5:................................................................    //
//    ............................................^YYYPG7............................:JY5P~.................................................................    //
//    ............................................:JYY5GY............................7Y5P?..................................................................    //
//    .............................................JYY5PP^..........................^Y5PY:..................................................................    //
//    .............................................7YY5PG7..........................?55P~...................................................................    //
//    .............................................!YYY5GY.........................!Y5P?....................................................................    //
//    .............................................^YYY5PP~.......................^Y555:....................................................................    //
//    .............................................:JJY55P?.......................?55P!.....................................................................    //
//    ..............................................7JJJY5Y^........^^...........~YY5Y.:^...................................................................    //
//    ..............................................~YJJYY57.......!?:..........^JYYP??!:...................................................................    //
//    ..............................................:JYYY55Y^.....7Y~..........:?YY5P?^.....................................................................    //
//    ...............................................7YYY555?....75?:..^:......7YY5P?!~.....................................................................    //
//    ...............................................:YYYY555!..!5J?:..^?^....!YYYPPY!......................................................................    //
//    ................................................7555Y55Y~J5JJ!.:77~5^..^YYYY5Y^.:.....:::.............................................................    //
//    ................................................:Y55YY5555YJ7:!JJ:.YY:^JYYY5J!!!^:^~!!^:..............................................................    //
//    .............................................:::.!5P555P5YJ?!JJ!!J775J7555Y5YJ77??7~:.................................................................    //
//    ..............................................:~?!JP5555JJYJ?7!7JYPJYYJ5P5Y55YY?~:....................................................................    //
//    //////////////////////////////////////////////:^~~~~~?555555J?YJ77?JY5555J5?Y5YY55Y?!^:///////////////////////////////////////////////////////////////    //
//    lllllllllllllllllllllllllllllllllllllllllllllll:^!777777777!!!!~~!77777!777!!777777~:lllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    ......................................................................................................................................................    //
//    ......................................................................................................................................................    //
//    ......................................................................................................................................................    //
//    ......................................................................................................................................................    //
//    ......................................................................................................................................................    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SCPED is ERC721Creator {
    constructor() ERC721Creator("Sun City Poms Edition", "SCPED") {}
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