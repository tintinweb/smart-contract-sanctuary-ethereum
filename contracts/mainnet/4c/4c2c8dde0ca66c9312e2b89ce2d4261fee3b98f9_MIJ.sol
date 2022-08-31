// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: UnknownGallery
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    &&&BGGGGP!JJPP~J!JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJY!!!7??JPB5PGPPPPP555PP    //
//    &@&&5YY5J~?JY5~7!7JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ7~~!777J5PJJYJJJYJJJJYY    //
//    &&&&G????~?YYYJ!?!JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJY5P57YPPP5555PPGGGGBBB#    //
//    &&&&#J777^!JJJJ~?~JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJY?5Y!Y55YGBBBBBBBBBBBB#    //
//    &&&&&G!!7~~???J~7!?JJJJJJJJJJJJJJJJJJJJJJJJJJJYJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ?7J7JYYYYPPPPPPGGGPGGGB    //
//    &&&&&&J~757!7?7~!!?JJJJJJJJJJJJJJJJJJJJJJJYJJJYJJJYJJJYYJJJJJJJJJJJJJJJJJJJJJ!7!!JJYJY5PPPGPGPPGPGGB    //
//    &&&&&&B!!5?!!77~~77JJJJJJJJJJJJJJJJJJJJJJJYJJJ5YJYPJYYP5YYYYJJYJJJJJJJJJJJJJJ7!?JJJJ?Y5GGGPGGGGGGGGB    //
//    &&&&&&&5~J7~!777^?7JJJJJJJJJYJJJJYJ5PJJJJY5JJJ5YY5GYPPGPPP5YJYYJYJJYJJJJJJJJJ?!??????J5PPPGGGGPGGPGG    //
//    &&&###&#77!~!7!7^7!JJJJJJJJJYYJJJ55PGYJ5GPP5YPGGPGBGGGGGGGPPP55YYJJ5JJJJJJJJJJ!~!!7?YY5GGGGGGGBGGGGB    //
//    &&####&&P~!~!7!7^!!?JJJJJJJJJYYYJ5GGBGPGBBBBGBGBGGGBBGPGGGPPGPP5YJY5JJJJJJJJJJJ!??JYYJ5GGPGBPPGGGBGG    //
//    &&&&&&&&&J~~!!!7^!!?JJYPYJYYYPPG5PBBBBBBGBGBBGGGGGGGGGPPPPPPPPPP5PP5YJJJJJJJJJJ?!7JYJJ5BBBBBGGBBBBBB    //
//    &&&&&&&&&B!~~!!!~!7?JJ5P5Y5PPGBBBGBGGBBGGBGGBGGGGGGGGPPPPPPPPP5PPPPP5JJYJJJJJJ?J77!7?JPBGGGPGGGPGGGG    //
//    &&&&&&&&&@5~~!!!^~7?JJ5GGPGBGPGBBGBGGGBGGGPGGGPPGGGGGPPPPPP5PP555PP55JJYJYYJJ?????7???PGGPPPPGPGGGGG    //
//    #&&&&&&&&&#!~!!~~~~7JJ5PGBGGP5PGGGGPGGGGPGPGGGPPGPGGGPPPPP5555555PP555555Y5YJ?J???????5GGP55PPPGPPGG    //
//    B#&&&&&&&&&5~!!!!~~7Y555PPG5YJYPGGG5PGGPPGPGGGPPPPGGPP5PPP555555555555555555JJJ??????J5GBBBGGG5PGBBG    //
//    GB#&&&&&&&&#7~~!!~~?GGYY555YJJJ5PPG5PGGP5G5PGPPPPPPGP55555555YY5Y55Y55555Y5YJJJ???????5PPPGGBBPGB##B    //
//    GGB#&&&&&&&&P~~!!~~!PPYJ5YYJJJJY5PG5PGG5YG5PGPPPPPPGP5Y555YYYYYYY55YY55YYYYJ?JJ??????JGGPPPGGG5PGGGB    //
//    GPGB&&&&&&&&&?~77~~!55JJYJYJYPP5Y5G5GGP5YP5PGP5PPPPP5YJYYYJYYJJYYYYYY55YYYYJ??JJJJ???JGGBBB#G5Y5GBBB    //
//    PPPGB&&&&&&&@G~!7~~~YYJJY5YBBBBGGGGGGP55JPPPPP5PPP55YJJJJJJJJJJYJJYJY5YYYYYJ??JYY5YJ??PBGBBB#GBBB###    //
//    PPPGGB&&&&&&&&?~?!~^JYJYPP5BBBBBBGGBG55G5PPPP5Y5P5Y5JJJJJJJJJJJJJJJJJYYJYJJGBG5YJY55YJPGGGBBBGPPG&&&    //
//    PPPGGG#&@@&&&&G~77~^7PGBGBBBBBGGGGPGG5PGBG55P5Y555YYJJ?77!!!7??JJJJJJYYJJJJPGB#&#BGGGPGBB###PPGG####    //
//    PPPGPPB#&&&&&&&?!7~^7BBBGBBBBGGGGGPGG5PGBG5Y5YYY5YYJ7^:::::::::~?JJJJJJJJJJ55PGG##&##BGGBB#########&    //
//    PPPP55GP#&&&&&&P~?!~~GBGGGBBGGPGGP5GGPGPBPG55JJYYJY!:::::::::::..~?J?!!!?J?5GPPPPGB#&BBG########&&##    //
//    P55PYJPYG&&&&&&&?7?!^GBBPGGGGGBGGP5GPGGGBPGG5YJJJJJ:.::~!^~^~^^:..:7PJ!^^7?PPPGPPPGG#BBB########&&&&    //
//    555PYJPYYB&&@&&&G!J!^PGGPGGGPGBPGP5GPGGGGPPG5GBYJP5::^7JY~!!~~~^::..YBBPYJJ555PPPGBBB#BBB##BB###&&#&    //
//    5555YJ5JJ5B&@&&&&J!?^5GGPGGGPPGPPPYP5PPGG5PG5G#BPBG~:~7?J!~J!~!!^^:.7PPGBBGP5Y5PBBBBB##########&#&##    //
//    5555YJ5JJYGB&&&&&B!?~JGGPPGPPPPPPPPP5GPPG5PG5GB####7:~!7?!^??~~~^^:.JPPPPGBBGBGGGBG#B##B##&&&&&####&    //
//    Y5Y5J?5??YPGB&@&&&5!~7GGGGPPPGPPP5PP5GPPG5GGGBB###G^:~~7?7~7?~~~^~^:?55555GGGBB##BPBB##B##&#&&&&&&&#    //
//    Y5YYJ?Y??J5PPB&@&&#7J~PPPPP5PP555555YP5PP5GGGG###B!::^~7?Y?7J?!777!^^?Y55PGGGBBBB#B###B###&&##&&&&&&    //
//    YYYYJ?Y77J5555B&@&&PJ~5P55P5555Y5Y55Y555555555P#B!:::^^!7J?!7!!!7!~^^^7PGBBBGBBBGBG&&&####&&&&&&&&&&    //
//    YYYYJ?J!7JYYYYP#@@&#Y!JPY55555Y??!!!!?JYYYYYYY5G~:^:^^:^~?7^^^^!!~^::::7GGBBG###BBB&&&&&&&&&&&&&&&&&    //
//    [email protected]&&P?Y5YYYYYY5?!~!J!^~?JJJYJJY~::^^^^::^!?^:^^~::.::.::!JPB#####B#&#&&&&&&&&&&&&&&&    //
//    JJJJ??JJ!?YJJYYY5#@@&5J5YJJJYJPY??YJ?J??JJJJJJ^::::.:::::7PPJJ~~~::!7....!Y?J5G#&##&&&&&&&&&&&&&&&&&    //
//    JJJJ??JBY?JJ?JYYYP&@@#5YJJJJJP55G#B?Y#BY?JJJ?^::::..::::?P5PJYJ7JYYYY!:...5#G5J?YG#&&&#&#&@&&&&&&&&&    //
//    JJJJ??JP??JJ?7JJYP&@@@GJ!!!!!Y5J5G5BPG5????7:::::::::::~Y55PJJY7J55YJJJ~..^G###GPYY5GB####&&&&&&&&&&    //
//    JJJJ?7JP7?JJY7?JJ5&@@@BY~^^^^~5#G5J5Y5!^^^~::^^:^:.:^::^J55P?JY7?55YJJYY!..?####&@&#######&&&&&@@@@@    //
//    JJJJ77?5!7??J77?JY#@&@#57^^^!!!YYY?YYPP5?^:::^^::^:^^^:^J55P7?Y!?Y5YJJJYY7^^G&##&&&&&&&&&&&&&&&&&&&&    //
//    J????Y?5~7??777??J#@@@&5?!J5G?.~JY5J7Y5J!^^^:::^:^^^^^:^?Y55?7J!?YYYJJJYJJ7:?&##&&&&&&&&&&&&&&&&&&&&    //
//    [email protected]@@@P?::^~^:???5J7~~~~^^::::^^^~~~^^^7YY5?!7~7YYJ??JJJJJ~:G&#&&&&&&&&&&&&&&@&&&&&    //
//    ????5BJP#[email protected]@@&&G!.......:::::^^^::::::^^~~!~^^^~JY57!!~7YYJ??JJ??J7:7##&&&&&&&&&&&&&&&&&&&&    //
//    ????YGJ5BGYY55YY5P&@@@#&@Y:.:~77^::^^:^::::^::?7~~!~~~^^~7Y57!~~7YY?77?J???7:^P&&&&&&&&#5B#&&&&&&&&&    //
//    ???7YG?5BB5&@@@@@@@@&#P#@Y::::?PPY!^~^~~^^^:~JBP?7~~~~^:^~J57!~~!JY?77?J?77!::!#&&&&&&@&5G#GJB&#&&&&    //
//    ??77YP?5GB5#&&&&###BBGG&@?::..:7Y5G5?!~~!!~JGGGGGJ^~~~~^^~?Y7!~~!JJ?777?77!!^:^Y&&&&&&&&&&&G7G#B#&&&    //
//    ??77YP7YGBGBBGGGGPPGG#&BY~^::::^~!5PGG55J.~GGGGGY^^^^^^^:^7Y!!~~!??777!?77!~^:^!#@&#BB#&#&&P?5B###&&    //
//    ??77YPYYGBB#GGGPPPPGGBG?~~~^::::^~75PGGG7.JGGGGG7^~^~^^^::~J!~~^~7?777!77!~~~:^^P&##J7G&&&&G?JB###&&    //
//    7777JGGYPGBBGPPP55PPGG57??7~^:::^~~7YPPP~!GGGGG5!~~~~^^^^:^?!~~^~777!7!!!~^^~^:^7&##P5BBPPGP55B#BB#&    //
//    7777JPPYPPGBGPPP55PPPPGG5PP5!~^^:^~~~?5?.!PPGPJ!~!~~^^^^^:^7!~~^~!!!!!~~~^^^^^:^~PG###BPBGPGG##BBBB#    //
//    [email protected]&55J!!~~~^^~^^!~.:7J?7~~~~~~^^^^^^:!~~~^^!~^~~^^^:^^^^:^~?5PGBBY55PBBBBBBB#&    //
//    7777?5YJ555PPP5555PPPPP&&P5?~~~^^^^^^^!~~~~!^:~!~~~~^^^::::^~~^^^~~^^^::^:^^^^:^^!J5P5YJ5#&&&&&&&@@@    //
//    77!!?YYJYYY5PP55555PPGB#&GJ7~^^^^^^:^^!~^^~!^^7!~~~~~~^:::::~^^^:~~^^^:::^^^^^:^^~!5P5YJ5GGGGBBB####    //
//    !!!!JPY?YJY55555YY5PPPBB&B?J!^^^^^~^^^~::::^^~7!~^~~~~~^::::^^^^:^~^^^:::^^^^^:^~^~J5Y??PBBBGGGGBBBB    //
//    !~~7B#57JJGP5P5YYY5PPPGB#B??!~^^^^^^^^^^:...^77!~^~^^^~~^:::^^^^:^~~^^^:::^^^^^^!^~?GGPP#GGGGGGGGBBG    //
//    ?!JG###J?P##GGPYYY555PGB##?7~~^^^^^^^^^^:...:7!!~^^^^^^~^^::^^^^^^^!^^^^::^^^^^^!~^!GBBBBBBBBBBBGBBB    //
//    #BB##&&#5##BBBPYYYY555GB#&Y7!!~^^^^:^!^^^^::~7!~~~~^^^^~^^^:^~^^^^^~~^^^^:^^^^^^!!^~JPPGGGGPPGGGBB##    //
//    ##BB#&&&####B#GYYYY555GBB&P7777^^^^^^!7!~~^^7!!~~~~^^^^~~^^::^^^^^^~~^^^^^^^^^^^~7~~?55PPPPPPPGB####    //
//    ##B###&&&###B#BYJYY55YGB#&P!!!!~^^^:~!!!~^^~!!~~~!~~^^^~~^:::^^^^^^~~^^^^^^^^^^^~!!^!Y5555GBB#####&&    //
//    ####B#&&&######5JJJYGBGBB&G~~~~~^^^!!~~~~^^~~!~~!~~~~~^~~^:^:^~^^^^~~^^^^^^^^^^^~!!^~?Y55GB#########    //
//    ######&&&&&&###BYJ?YB####&B~~~~~^^!!~~~~~^^~~~~~~~~~~~~~~~^^:^~^^^^~~~^^^^^^^~^^~~~~^?##BBBB#BGPPGBB    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MIJ is ERC721Creator {
    constructor() ERC721Creator("UnknownGallery", "MIJ") {}
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