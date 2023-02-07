// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: test
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    YYYYYYYYYYYYYYYYYY5555555555555555555555555YYYYYYYYYYYYYYYYY55555555555555555555555555555555PPPPPPPG    //
//    YYYYYYYYYYYYYYY555555555555555555555555555555YYYYYYYYYYYYY55555555555555555555555555555555PPPPPPPPPG    //
//    YYYYYYYYYYYYYYYYY55555555555555555555555555555555555555555555555555555555555555555555555PPPPPP5PP55P    //
//    YYYYYYYYYYYYYYY5YY55555555555555555555555555555555555555555555555555555555555555555555PPPPP5PP5PP55P    //
//    555Y5YYYYYYYYY555555555555555555555555555555555555555555555555555555555555555555555PPPPPPPP5PP55P555    //
//    YYYYYYYYYYYYYY555555555555555555555555555555555555555555555555555555555555555555PPPPPPPP5PP55P555555    //
//    YYYYYYYYYYYYYYYYYYYY55555555555555555555555555555555555555555555555555555YJY5PPPPPPPPPPP55P5555555YY    //
//    YYYYYYYYYYYYYYYYYYYYYYYYYY555555555555555555555555555555555555PPPPPPPPY?!^:!PPGPGPPPPPPP55P5555555YY    //
//    YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY5555Y??JY55555555555555555PPPPPPPPPP5J!^::^:~PPPPPPPPP55P5555555Y55YY    //
//    JJJJJJJJJJJJJJYYYYYYYYYYYYYYYYYYYY5J^:^^~7?Y5555555PPPPPPPPPPPPPPY7^::^^^^:~PGGPPPPPP55P5555555Y55YY    //
//    JJJJJJJJJJJJJJJJJJJJYYYYYYYYYYYYYYYY~:^:::^^~!?Y5555YYJJ??JYY55Y!::^::..:^:~PGGGPPPP555P5555555YY55Y    //
//    JJJJJJJJJJJJJJJJJJJJJJJJYYYYYYYYYYYY7:^:..::^::^~!!!!!!!!?5GBBBGY?~::::::^:~PGGGPPP5555PP55P555YY55Y    //
//    JJJJJJJJJJJJJJJJJJJJJJJJJJJYYYYYYYYYJ:::..:::::~7Y5PGBB#BGGB######GJ!^:::::!PPGGPPP55555P5555Y5YY55Y    //
//    ???????????????JJJJJJJJJJJJJJJYYYYYYY!:::::::!YPPG###BPYJ?77?YPGGGBBGJ7~:::~5PPPPPP55555P5555Y55Y55Y    //
//    ???????????????????JJJJJJJJJJJJJYYYYYJ:::::~YGBGB##GY7!~~~~~~!!?YY5PGPYY?!^::7PPPPP55555P5555Y55Y55Y    //
//    ?????????????????????JJJJJJJJJJJJJYYY?^::^?5PGBB##GJ!~~~^^^^^^~~!JJJY5YYY5J7^.^5PPP55555P5555555Y55Y    //
//    ???????????????????????JJJJJJJJJJJJY?::^!JPGGBBB#G57!~^^^::::::^^!?JJYYYYPGG5! :YPP55555P5555555Y555    //
//    ??????7777777????????????JJJJJJJJJJJ^:^?5GB#GPBBBPJ7~~^^:::....:^~7?YPPPPGB#B57!YPP55555PP555555Y555    //
//    777777777777777???????????JJJJJJJJJ!:^JG#B&#B5GPPY7!~^^::::....::^!?YGBBBBB?77!!?PPP55555P55P5555555    //
//    77777777777777777??????????JJJJJJJJ??Y?Y#&&&#GPPG5YJ7!~^^^:::^~!7JYYPPBB#BB!::^~!??JY5555PP55555555P    //
//    77777777777777777????????????JJJJ?77?77JB&@@&##BB5PYYYJ?!~^:^~777!~^7JPB#PG!^::^^^~:~Y555PP55P55555P    //
//    77777???7777!77??JJYJJJJJJYYYYYJ7^:^~!!7P&&@###BB??7^~!7?!^:^^~!7???J5BGGPY!:::^^.^:.^J55PP55P55555P    //
//    77777??????J?77???JYYYYYY555PP5?^:::~~!~!P&&B#&&#P55?!~^!!^::::7Y5PPGG5?JYP?:..^^.:^..^J5PP55555555P    //
//    7777777??JJYYJ?7??JY55YYY55GBBY7^:::^~!~~!GBPGBBBG5?~::^!!^::::::::^^:::^!??:..:^:^^:::!5PPP5555555P    //
//    7777777????JJJJJJJJYY55555PB#B?7~:::^~~!~~JG5YJ?7~^::::!7!^:::::::...::^^~!~^:::^:^~:::75PPP5555555P    //
//    ?7777777???JY555555555PPPPPGBBY?7::^^~~!~~7G5J?!~^^::::!?7~::^^^^:::.:^^~!!~^::^^:^~::^J5PPP55555555    //
//    ??7777777?JJY5PGPPPPPPPPPGGGBBPYJ^^^^!~!~~7GG5Y?7~~^:::?YP5?!7!^:::::^^~!!7~^^:^~:~~:^?55PPP55555555    //
//    ?????77777?Y555PPPPPPPPGGGGBBB5Y5!~^^!~!!!?PBGP5J?!~^^^~7?J!^::::::~~~!!!!!~~^^!~~?~~?5555PP55555555    //
//    JJJ????????JY55PGGGBGBBBBBBB#B5JYY?!^7?!J?YP#BGGP5J?7!~^^^~!~~~~^^^^~!!!!7?!!!7?JPY?Y55555PPP5555555    //
//    5555Y55YJJJJJJ5PGGGBBB######&&PJ?J5PPGPJ5PPG##PPPPYJ????YY?????7?7~^^~!!~JGPPPGB#G55555555PPP55555Y5    //
//    JJJJJJJ????JJJJJYYYYYYY5555555YJJJJJYP5GB&&&&@GPP55YJ??JYYJ7!!!!7!~~~!!!7#@@@@@@#PP5555555PPP55555Y5    //
//    [email protected]@@@@@@[email protected]@@@&&&&GP5555555PPP55555YY    //
//    ????????????????????????JJJJJJJJJJJJY57B&@@@@@@@&BGPP5YJ?7777!~^^^~~!JP#&@@&&&&&&B555555555P555555YY    //
//    ????????????????????JJJJJJJJJJJJJJJJYJ?#&&&&&&&@@@@#GP5J?!~^^::^^~7YGBB&&@@&&&&&&&G55555555P555555YY    //
//    YYYYYYYYYYYYYYYYYYYYYYY?7YYYYYYYYYYYY!P#&##&#B&&@@@&#BGP5YJ?77??JYPBBG#&&@@&&&&&&&BP55Y5YY5PP55555YY    //
//    BBBBBBBBBBG5!!JGBBBBBGJ^^YBBBBBBBBGBJJ####BBGB#B&@@@#BBGGGGGGPP5JJPGPP&&&&&&&&#BGGBG5YYYYY5PP55555YY    //
//    BB###BBBBBG7~^^5BBBB#5^^:7BBBBBBBBBP7B##BBGGGGGB&@@&#BGGGGGP5J?7!7PGPB&&&&&###BGGPGGBPYY555PP55555YY    //
//    ######BBBBB?~^^?BBBB#?^^:?BB##BBBBB7GBBBGPPPPPG#@@&#BGGP5YJ?7!!~!?PGG&@&&&&##B###&##BBP5555PP55555YY    //
//    ###########J^^:~BBB#G~^::Y#B##BBB#JY#BGP5PP5PB&&#BGPP5Y?77!!!!!~!?JB#&&&&&&&&&###&&####G555PP555555Y    //
//    ###########J~^::5#B#J^^:^5#####B#5?BGP555PGB#&&BJJJJ??77!~~~~!~~!!!G&&&&&#&&&&&&&&&&&##&B55PPP55555Y    //
//    ###########J~^::?##P~^::^P######G?BG55PGB##&&&#BJ77JJ???777!^^!!7?JPB&&&&B#&&#&&&&&&&&&&&P????77???J    //
//    ##&&#######J~^::7##?^^::~G###BBB?PPPPGB#&&&&#55P5YG#BPJ7!?JJ?~!77!!?YG##&#GB#&&&&&&#&&&&&#J~~~~~~^^~    //
//    ##&&#######J^^::~BB!^^^^7YY5PGGYYPGGBB#&&&&@Y!77?YPB#PPY7?JYJ!!!~~!7?JG###BBGB##&####&&&&#G7~~~~^^^^    //
//    ##&&#######P~^^:~GJ~^:^^?J?J5GP5PG###&&&&&&B7!!!!!7?5GP7^!J7!~~~~~!!7?JG####&&#BBBBBB&&&&&#Y~~~^^^^^    //
//    ###########G~^^^~!^^::^^??J5BGGG####&&&&&#GJ^!!!!!~~7J~:::~~~~~~~~~~!!7JG&&&&&&#&&#GPB&&&&&5~~~^^^^^    //
//    #####PJ7?Y57^^^~!~^^^^^^7JPBBGB####&&&&#BGJ:~!!!~~~77^..^~^~~~~~~~~~~~~!JB#&&&&&&&#BBB#&&&#G!~^^^^^^    //
//    ####Y!~^:^^^^^^!!~~~~^^^!PBB##&####&##BGP?:.~~~~~~~!!!^:::^~~~!~~~~~~~~~7YG&&&&#&&B#B#&&&##B7~^^^^^^    //
//    ####Y!~^^^~~~~~7!~~!^^^^^?B####BGPBBBGGY~...~~~~~~~~!!^:..^!!!!!~~~~~~^^~!Y#&###&&##B#&&&##B7~~^^^^^    //
//    BBPY5?~~^^^~~~~~~~~^^^^^^^J##BBGGGGPP5?^...:~~~!7?7~::~!~~!7!!!!~~~~~~^^~:!B###&#&####&&##BG!~~~^^^^    //
//    BG7!?5?7!~~~~~^^^^^~~~~^^^~G#B###GY5Y7:....:~~!??777~~!??7!!77!!!~~~~^^^^ :YBB##B##B##&####Y!!~~~~~~    //
//    BB5J?YGGPY?77!!!!~~~^~~^^^~P##&#GYYJ!:......~!777?JYY?!!7????7!!!~~~~^^^: .7PGB#B##B#&&####?!!~~~~~~    //
//    ###G5J?J55J77J5P5YJ?!!~~~~~Y&&#G5J?~:.......~77?JYYYYYJ?7?YYJ?7!~~~~^^^^  .^YPG#####&#&##&B?!!~~~~~~    //
//    ####BPJ77??77PB#GGP5?7!!!!~?&#B5Y7^:....... !YYYYYYY5PP5J??YJ?7!!~~^^^^: ..:?5PB#&#B##&##&G?7!!~~~~^    //
//    #####BBG5Y?75BBBGYJ??77!!!~?#B5Y!:::........J5YYY5PPPPPP5J?YY?7!~~~^^^^. ...~Y5B#&#G###G&&5?7!!~~~~^    //
//    BB###BBGG5YJJJYPGPYJ?7777!!Y#PY!...........!YY5PPGPPPPPPPPYP5?7!~~^^^^. ....:JPG#&#BBBBB&#Y?7!!~~~^^    //
//    BBBBBBBG5J?77!77Y55J????7!!PGP7...........^JY5GGPPPPPPPPPPPG5?7!!~^^^^......:~PB###BBGB#&BY?7!!~~~^^    //
//    BB#####B5?7!!!!!!J55YJ?7!!7GP?::..........?555PGGPGPPPPPPPPGPJ7!!~^^^......::^YBB##BBGG#&GY?7!!~~~^^    //
//    #########PJ7!!!7!!?JJJ?7!!7B5^:::::......~55555PGGPGGPPPP5YPGJ?!!~~^:....:..::JGBB#GGGB##PJ?7!!~~^^^    //
//    #######&&#GPYJ?77!!!!!!!!!JB7^:::::::...:?Y55555PGGGGGP5J?7JBY?7!~~^.....:...:JGGGBGPGB#B5J77!~~~^^^    //
//    ######&&&&BP5YJ?7!!!~!!!!?GP!^^::::::::.~J?Y555555GGPYJ????7GPJ7!!^...:..:..:^YBGGGGGG#&BY?7!!~~~^^^    //
//    ##&&&&&&&&B5J?777!!!!!!7?5#5!~^^::::::::?JJ?Y555555YJ???JY?!JB5?!~:.::::::.::^YBPGBBGG#&GY?7!!~~~^^^    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract hello is ERC1155Creator {
    constructor() ERC1155Creator("test", "hello") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0xb08Aa31Cc2B8C0582bE42D38Bb643292e0A4b9EB;
        Address.functionDelegateCall(
            0xb08Aa31Cc2B8C0582bE42D38Bb643292e0A4b9EB,
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