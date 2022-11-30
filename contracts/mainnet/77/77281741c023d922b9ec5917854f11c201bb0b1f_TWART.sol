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

/// @title: Tom Wüstenberg Art
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//           ~PP^. .........                                  .:.:^^::::.~JJYY55PP5PPPPPPPPPP5:  ..^^^~!7?    //
//           ~P5^                                                  ......!JJYY555P5PPPPPPPPPGY:...:^^~~7?J    //
//           !P5^                                                      .:!JYY5555P55PGGGGGGPGJ^::::^~~!!7J    //
//          .7PY:                                                       .!?JY555555PPGGGPGPPP?^^~!~^:::^!5    //
//          .7PY:                                        .:::^:..       :7JYY55PPP5PGGGPGGPPP7!!77~..:^:~J    //
//          .?GJ.                                     ^7?Y5P555Y?!~^:.. .7JYJ555PP55GGGPGPPPY~~!!!!^:^~^7Y    //
//    !^^::::JG?.                         ..      .~7?5GGGBGGGGGGGGGGPY7~?YYY555PP5PGGGPGPGP?^^::^^::7J!YP    //
//    J7!?77?5GY~^~~:::::...        ..    ..     .!5GGBBBBBBBBBBBBBBB##BGPP5Y555555PGPGPGPGP!. ..   ^!7!J5    //
//    5YYYJ7J5GY77JJ!!JY55J?7!!~::::!~:...  .    .?5PGBBBBGGPPPPPPPGB######BP555PP5GP5GGPPG5^      .^^~7Y5    //
//    BBBBBGP5GJ!!7?7!?YPPYYYYJ?77!~?YJJ!^.^77!~~~?5P5555YJJJJJJYYY5PB###&&#B555PPPP55GGPPPJ.     ..^~:~Y7    //
//    BBBBBBGPPJ?7?J?77YP5JYYY?7777!?J?Y?^.75P5YY55PJ???????JJJJJYYY5GB####&#P55PPPP5PGPPPP!    ..^:77:!5!    //
//    BBBBBBGPGGGP5Y?77J55JYJYJ77??!J7~JJ^:!JY5PPGGY???JJ??JJJJJJJYYYPGBB###B555PPP5PPGPPP5:    .::~??^75~    //
//    GGGGGGGPGGGP5YY?77YPYYYYY?JY?!Y55GY::7?YJ5PPBJ?J?JJJ?JJJJYYYYYYY5GBBBBG555PPPPPGGPPP?.    ...^7::7Y^    //
//    YYYYYY5GGPYY5YYJ77Y5JYYYYJJY?75B#B?:^?YY!?5PB5PP5YJJY5PPGGPP555YYPGGP55555PPPPPGPPGP!. .....:~7..??:    //
//    555555PGGP55555Y?J5PPPP5J?JY77PB#B!:!5PY?JPGGPPGGP5JJ55PPPPP55YYY5PP555555PPPPPGPPG5^.......^^~::J?:    //
//    P55555PGG5YY555YJYPGGPPYYYYY??GB#G~:JBP55GBBB5JJYYYJYYYYYJJJJJYYY5PPY5555PPPGGGPPGGJ~!^:!77?J?JJJ5J:    //
//    BBGGPPGGG5J7!!?J?J555YJJJYYY?JB##5^^YGP5PGBBB5?JJJJYYYYYJ???JJY55PP5YYY5PPPPGGGPPGGJ7J?7?YY5PP5PPGJ:    //
//    #BGGPPGGGP55Y?!~!7??JJ?77???!7GBBJ:~Y5JJJJ?JJ?JJYYYY5P55YJJJJYY5PPPP555PPPPGGBGGGPP5JJ!7?5PPPPPGGG7:    //
//    YJJJ??5GGJ??J7~~~!77?JJ???7!^^7JY!:!55JJ?7????JY5PGGGGGPP5YYY55PPPP55PGGGGP5YY5GGGGPY?!?7!7J555PGP!^    //
//    ??J??JPBGJ??J7^::!?JJ777777!~~!77^:^~!~!!!7??77YPPPPPPPPPP555PPPPGP5GBBBGPY??Y5GP5P5J7~7!^~7JYJYP5~:    //
//    YYYJY5GBBJ!!7J!~~!?YJ!!!77777!~~^::::::^^^~~~~^JPYYPGP5YY55GPGGBBP55B##BBGGPYG#B55PP57!??7?JJYJY5Y^:    //
//    PPGPY5B#BJ!777!!!!7J7~~!YY????7?YYJ7!77?!!7!!?!JPPPPPPPPGGGB###BP5Y5B##BBB####BPGGPP5J77JJJ7JJ?J5?^^    //
//    YYGP5G###G5GGGGPPPGPPPPPBPP555Y?JJJJJJJY?777??77Y5GBBBB######BGP555YPGPGB######G5PGGGYJ77?Y55J7?YJ^~    //
//    ###BGBBB#BGBJ?7~~7Y!~!!JP5GGG5J7?JY5YYYJJ?!!?????7!JGBB##BBGP5555YJJ7~~?YPGB##BBBG5PPYJ??YGPJ7!!!7!!    //
//    GBP!~JPGP5YY!~~::7!....7~~Y!JJJJJJJYYJJJJJJJJJJJ?^^7YYY5555YYY55PJ^^^^^..:^!????J??55JJPGGPJ7!!!~7!7    //
//    JJ7!!~!?~:::!5GJ?Y~^!^^J!!?!JJJJJJYYYYY5555YYPP5?^~7JYYYYYYYYY55Y!^^^^::..:^~~~~~~~~!!?J?!!~~~~~!??5    //
//    YYYY5Y~!~!~^7G#GGJ~!77?5?7?JJJJYY5PP5YYY5PGG#&#GPYY55YYYYYYYYJ?!!~~~~~^^^^~~~~~~~~^^~~!!!~~!~^^!??!J    //
//    PPPPPPPPPPY?77?JP7!?5JJPYYYJJJJJJYY555BBGP5P&&#YP5555YY55YJ7!~~~!!!~~~~~~^~~~~~~^^~~~~!!!77?7?Y5GP55    //
//    BBBBBBBBGPY5PP55J77JY!!55YYJJYY5YJ??JYPG&&&&&&B55555555YJ7!!!!!!!!~~!!~~^~~~~~~^~~~~~~!!!!7J5GGGBB57    //
//    #BBBBBBBG55P55J7~!!!7?JYJJJJJYYJ7!!~~~J5P555PGPP5555YJ7!7777!!!!!!!~~~~~~~~~~~^~~~~~~~!!!!77PGG55Y?J    //
//    ###BBBBGPJ?~:..:!7JJYYYYYYYJJ?7!~!!~~~!!!!!!?5P55Y?7~^~!77!!!!!!!~~~~~~~~~~~~~~~~~~~~~!!!!77?JY5YYY5    //
//    ##BBBGGP5Y?~^~7?JJYYYYYYYYY7~~~~!!!~~!!~~!7?5P5Y?~^^^!!!!!!!!!!~~~~~~~~~~~~~!~~~~~~~~~!!!!7777Y55PGP    //
//    5PPGGPPPPJ~~J5YJYYYYYYYY5Y?!!!!!!!!!!!!!!~75P5J~^^^^!!!!!!!!~~~~~~~~~~~~~~!77~~~~~~~~!!!!!!7775GBGBB    //
//    GGGGGG5J~::?G5JJYYYYYYYYJJJ77!!!777!!7!!~~~J57^^^^~!~~~~~~~~~~~~~~~~~~~~~!7?!~~~~~~~~!!!!!!777YBBB#B    //
//    BGPPPY!^::^5G5YYYYYYYYJJYY?7!!!!7!77!!!!~~~~~^::^~~~~~~~~~~~~~~~~~~~~~~~!7?J!~~~~~~~~~~~!!!!!!?GBBGG    //
//    BGP5J^^^:::JG5YYYYYYYY?7??!!!~!!!!!!!~~~~~~:^^:^~~~~~~~~~~~~~~~~~~~~~~~!7?J7~~~~~~~~^^~~!!!!!~!P####    //
//    BGP5~^^^:::!PP55YYYYY?7!!~~~~~~~~~~~~~~~~~::::^~~~~~~~^^^^~~^^^~~~~~~~!7?J?~~~^~~~~^^^~!!!!!!~!P####    //
//    BBP7:^^^::^~7?JJYJ????Y?~~~~~~~~~~~~~~~~~:::::~~~~^^^^^^^^^^^^~~~~~~!!!7?J7~~^^~~~~^^^~!!!!!!!7B&###    //
//    BBG?^^^^^^~^^~~!!!77JY?~~~~~~~~~~~~~~~~~^::::^~~~~^^^^^^^^^^^~~~~~~!!!7??J7~^^^~~~~~~~~!!!!~~!?#&#&#    //
//    BBBY^^^^^^^^~~!!!!77?J!~^~~~~~~~~~~~~~~^::::^~~^^^^^^^^^^^^^~~~~~!!!!7??JJ7~^^^~~~~~^^~~!!!~~!J#&&#&    //
//    BBBGJ~::::^^~~!!!77?J57^^^^~~~~~~~~~~~^:.::^~~~^^^^^^^^^^^~~~~~~!!!!7??JJJ!~^^^~~^::...^~!!!~!Y&&&&&    //
//    BBBBBGY77?JY55555PPP5?~^^^^^^^^^^^^^~~::::^~~^^^^^^^^~~~^~~~~!!!!!!7??JJJ?~~^^^^:.    .^~!!!!!Y&&&&&    //
//    #BBBBBBBBBBBBBBBGY?!~~~^^^~~~^^^^^^^^::::^~~~^^^^^^~~~~~~~~!!!!!!!77?JJYJJ~~^^^^:    :^~!!!!!75&&&&&    //
//    #BBBBBBBBBBBBBG?~^^~~~~~~^^~~~^^^^^^:::^~~^^^^^^^^~~~~~~~!!!!!!!!!7??JYYJJ~~~^^^:...:^~~!!!7775&&&&&    //
//    #B######B###BY~^^^^^^~~^^^^^~~~~~^:::^^^^^^^^^^^^~~~~~!!!!!!!!!!!7?JJJYJYJ~~~~~~^^^~~~~!!!!777JGBBBB    //
//    ######B#BGPYJ~^^^^^::^^^^^^^^^^^^::^^^^^^^^^^^^~~~!!!!!!!!!~!!!!77?JJYYY5J~~~~~~~~~~~~~!!!!!!77YP5JJ    //
//    #BGPY?7!!~^::^!~^^~^^^^^^^^^^^::^^^^^^^^^~~~~!!!!!!!!!!!!!~!!7!!7?JYYYY5P5!~~~~~~~~~~~!!!!!!!!75Y!^~    //
//    J!~^:::::::::::~!^^~~~^^::::::^^^^^^^~~~!!!!!!!!!!!!!!!~~~~!7777?JJJYYY5GG7~~~~~~~~~~~!!!!!!!7Y57:^7    //
//    ::::::^:::::::::^~::~!^:::::^^^~~~~!!!!!!!!!!!!!!!~~~~~~~~!!777?????Y55G#BJ~~~~~~~~~~~~~!~~!7YPJ~^!J    //
//    ::::::^^^^^:::::::::^^^^::^^~~~~~~~~~~~~!!!!~~~~~~~~~~!!!!!77777777?J5G#BG?~~~^~~~~~~~~~~~!7?JY!~7JY    //
//    ::::::::^~~^^^::::.::^^^^~~~~~~~~~~~~~~~~~~~~~~~~~~~!!!~~~!!!!!!!???5B#BGP?~~~~~~~~~~~~!!!!7777?JY55    //
//    ::::~7JYJ?7!!~~^^^^~^^^^~~~^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!!7?J5G&&BGGY!~^^^^~~~~~~!!7777777?5555    //
//    :~~!7?JYJJ77777777??~^^^~~~^^^^^^~~~~~~~~~~~~~~^^~~~~~~~~~~~!7J5GBB#BBGPP?^::::::::^^^~~!!77?JJYPP5Y    //
//    !?!!!7777777???J???777!~~~~~~~~~^^^^^^^^^^^^^^^^^^^^~~~~!!77?5##BGGGPPP55?^::::::::^^^^~~!!7YPPPP5YY    //
//    77?JYYYYYJJJ?????JJJJJ??!^^^~~!!!!!~~^^^^^^^^^^~~~~~!!!7777??YBGP555P555Y!:::::::::^^^~~~~!7?GP55YYY    //
//    JY5YJ??7777?????????JJYYY7^^^~!!!!!!777!!~^^^~~~!!!!!!!!!!77J5P55YYYYYYY?^:::::::^^^^^~~~!!7JG55YYJJ    //
//    5J???7!!!!!!!77777??JJ??JJ!^^^~!!!!!!7?JJJ?7!~~~~!!!!!!!~!7J55YYYJJJJYYY??JJJJ???777!!!!!!!?5PYYJJJJ    //
//    ?7777!!!!!!!!!7!77777??JJYJ?!~~~!7!!!77??JYYJ?7~~~^~~~~~!7JYYJJJJJJJJJYYY5P5555PPPPPPGGP5YPPPYJJJJJJ    //
//    YYYYYYYYJJ?7!!7777777????JY55J??JYYJJ?????JJY555Y?!^^~!!?YYJJJJJJJJJJJYY5PP555PPPPPPGB&&BGGPYJJJJJJJ    //
//    YYYYY5555555Y?7777?????JJJJJ5P5J??????????JYPB&B5J??77?J5YJJJJJJJJJJJJYY5PPPPPPPPPGGB#&BPP5YJJJJJJJJ    //
//    5555555PPPPP55Y??????JJJJJJYYYPPJJ????????J5G#&PJJ??JY555YJJJJJJJJJJJJY5PPPPPPPPPGGGB&#P5YJJJJJJJJJJ    //
//    PPPPPPPPPPPPPPPY???JJYYJJJJYYYY5PYJJJJ??JJJYP#@#P555PPPP5YYYJJJJJJJJJYY5PPPPPPPPPGGB&#G5YJJJJJJJJJJJ    //
//    PPPPPPPPPPPPPPPPY?JJJYYJJJYYY55Y5PYJJJJJJJJ5G&@@#PG#&BGP555YYYJJJ??JJYYPPPPPPPGGGGB##G5YJJJJJJJJJJY5    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TWART is ERC721Creator {
    constructor() ERC721Creator(unicode"Tom Wüstenberg Art", "TWART") {}
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