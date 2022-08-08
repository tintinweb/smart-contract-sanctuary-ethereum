// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Eyal Carmi
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    &&@@@@@@&&&&&&###B##&&BBBBBGGGGGGGGPGGGGPPPPPPPPPGGPP555P5YYYY5PPPGGGGGP55PGGGGGGGGGBBBGPGGP555555YJ    //
//    &&&&@@@&#####BBBBBB###B###BGGGGGGGGGPPPPPPPPPPPPGGPP55555YYYYY5555PG5P5YYY5PGBGPPGGGGGGGPPPPP5PPPP55    //
//    &&&&@@&&&#####BBGGBB#BBBBBBGGGGGGGGGGPPPPGGPPPPGGGP555Y55Y5555PPPPPP55YJJJY5GGGPPPPGGPPPPPP5PPPPPPPP    //
//    &&@@@@&&&#####BGGBBGGBBBBBBBGGGGGGGGGGGGGPPGGGBBBBGP555GP5PPPPP55PP55YYJJJY5PGPPPPPPPP5555555PPPPPPP    //
//    @&&&@&&&###BBBBGPGGP5PGGGGGGGGPGGGGGGGGBBB#&######BBGGGBGGBBBGPPPP555YYJY5Y55555555PPP555Y55PPPPPGPP    //
//    &&##&&&&#BBGGGGBGPPP55GGGGPPGPPGGGGBB##&&&&&#B###BBBGGGBB###B#BBGGPP5JJJYY5P5YYYY5PPPPP5Y55PGGGGGGGG    //
//    B###&#&&&&#BBGGPP5555YY55P55PPPPGB#&&&#&&##B###BGBGGGGGBBBB####BBBBBPY5YYYY5P55YY5PPPGGPPPPGBBBBBBBB    //
//    B#&&#&&&&##BGPYYJJJJJJJJJY5555PB##&&&&&###BBBBBBBBPGGGGGGBBBBGGPPGBGPPP5YYYY55PPPP555PGBBBGGBBBB####    //
//    ##&&&##BBGP5P5555YJJJJYYYJY5PPGB#########&#BBBBBBBPGBGGGGGGGP555YYJYYYYPPPPPPPPGBGPGGGGGGBB#########    //
//    &&@&&###BBBGGPP5555YYYYYYJ5PPPGGGGB######&###BBBBBPGGGGGGPPP5YYJ7!!!!7?YP###BGGPPPGGGBBBBB###&&&&&&&    //
//    &&@&&&&###BBGPPPPP555Y5555P55PPPPPGBB##B##&&####BBGGGGGPP5YY7!~~:...::^~JGB##BGGGGGGGBBBB##&&@&@@&&&    //
//    &&@@@&&##BBGP555PPPPPPPGGPGP555PPPPGGGGB##&&&#&#BGPPGGGG5J?!^^::.. ..^^~?5GBB#BGGGBBBBBBB##&@@@@@@@@    //
//    #&@@@&###BGGPPGBBBGGGGGGPP555Y55PPPGGGGB##&&###BGGPPPPP5J?77!!!^^^:^~!7!JYPGG##BBBBBBBBB##&&@@@@@@@@    //
//    #&#&&&###BBGGGBBGGGP5555YYYY5Y5555PPPGGBB###BBGP55PPPPY?7!77!!!!7~!??????JJYPPGBGG#&#B##&&&@@@@@@@@@    //
//    &#BB#####BBGBBBBP5555YYYYY55555555PPPPGGGGGPP5YYJJJJJJ7!~~~!!!7?J?5555YJJ?JPGPBGPG#&&&&@@&&@@@@@@@@@    //
//    #BBGBB####BBBBBBGGGPP55YY??JYYYY55555555YYJJJJJ???777777777!77?JYJPGGP5PP55PBBBBB##&##&&&@@@@@@@@@@@    //
//    BBBBB##B##BGBBBGGGGGGP5YYJ?JJYYJJJJ?????????????????JYJJJJ????JYYYPPPPPPPPPPGBBBBBBB##&##&@@@@@@@@@@    //
//    BBGB##BBBBGPGGGGPGGGBPYY5555YJ?J?777!!~!!!!!!7777!77?JJJJYYYYYYYYY5PPGPPPGGBBBB##BBBBB###&@@@@@@@@@@    //
//    BBBBBBBBBBGGGGGGGPPGGYJJYYYJJ?J?77!!~^^^^^^~^^~!~~~~~!7??YYYYYYY5555PPPPGGBBBB###GGGBBB###&&@@@@@@@@    //
//    B###B##BBBBGGGGGGPPGPY?777?7??7!777!~^^^^:^^^^^^^^^^^~!7?JJJYYYY55P55PPGGGBBBB#&#GGGGGBBB#&&@@@@@@&&    //
//    ##BBB##BBBGGBGGGGGGBPPY?7!!!!7!!777~~^^^~~~!~!!!~!!~~!7??JJYYYJY5YJJY5PGGBBB##&&#BGGGGGBB##&&&@&@@&&    //
//    #BBBBBBBBGGGGGGBBBBBBPYJ?777!!~!!!!!~~~~~!!!7!!!7??777?????JJJJJJJ??JYPPGBPG#&&&BGGGGGGBB###&&&&&&&&    //
//    ####BBBBBGGGGBBBBBGGBB5Y??777777!!~!!~~~~~~!!!!!77!!!!!!!!777??JJYJ???JYPGGB##&BGGPJYPPGGBB##&&&##&&    //
//    ####BBBBBBBB##BBBBBGB#P5J??7!~~!~~~~~^^^~~^^~~~~~^^^:^~^^~~~~!7JJYJJ???J5PGB#BGPGGPYYY5GGBBBBB###B##    //
//    &@@&####B#########BBB#G5YJ?7!~~!~!!~~~~~^^^::::::::::^^^^^~~~!!7?????!!!7JGBBG5PPPYY5PPGGGGGGBBBBBGG    //
//    @@@&###&####&##&&###BBBP5J77~!~~~~~~!~~^^^^:..:^^:::::^^:^^^^~!!777?7!~:^!5BB5YPPPP55PPPGGGGPGGGPPPP    //
//    @@&&&&&@&&&&@@@@&&##B##BB5?!^^~~~^~~!!~^::^:..:^::.. ...  ...:^!7???7~^::~JGGJYPPPP5PGGPPPPPPPP555P5    //
//    B&##BGBBBB##&&@&&&#&&##B57^....:::::^~~~.:^~. ..:...:^:::..   .~7?JJ?7!~^!YGG??5P5PPGGGGPPPP5555555P    //
//    B####BBBBB##BPGGB#&&&&&GJ7~^^:.:~!!!~!!~:^!7~::~~~~~!7~~^^^^^^^^~7?JJ??77?YGPY5PP55PPPGGPPGGPP55YYY5    //
//    GB##BGBBPPG#BYYYG#&&&@@#GY7~~^:^^!!??!7?77^~!?7~77!7?J7~!!!77!!!7??Y5YYYJJ5GYGG55PPPPPPPPP5PPPP55555    //
//    5Y5B#GPGGPPPGPYPBBBBB#&&##GY?7?J5YJ?7!7J77~!7J77YY??JY555P55Y7~~?J!JY5PPYJY55PJJPPPPPPPP55555PP55P55    //
//    PPYJPBPP#&BBGGB&##B####PG555PPGGGPPP5YYYY?JY5GPPY5YJYYJJYYY5YJ~7J7:~7?JYGGPPPYY5PPPPPPPP555555555555    //
//    GGP5J5!?PBB#BBP5##&&&&#PP57!!7!~~!7?P5Y5J77?Y?J5JY5555YYYYY5YYJJ?::~7?JJ5PPGP5PPPPP555555555555555YY    //
//    GPPP5Y??YPB#BBP5B&#&#&&#G5!^::..::^~!P5?^~?GP??55YYYYJJJYYYYYYJ!. :^!?77J5GGPPP55555555YYYY555YYY5YY    //
//    GBG#GGGPGB&&#BB#@@#B#&&#G5!^..      .7~.. :7?Y557?!!!!!~~!!!~^.   .^!7?YPG#BBGGPPPP5555YYYYYYYYYYYYY    //
//    PPB#GGB####BB#&@@@@#&&#&&GJ!^.  .^^.:!!~.  ^!!JYJ!^:^!7!~~~~~~^:..:~?Y5PBB##BBGGGGPPP55555555YYYYYY5    //
//    JY5GBBB##&#B#@@@@@@@@@&&&#P?7~:..:~!7...   :7!~!JY!~~!YY??7!7!~~~!7Y5PBB##&#BGGGGGGGPPPPPPP55YY55555    //
//    J?J5G#&&###B&@@@@@@@@@@@@&&#GY??JY55?^:    .~^::7Y???7??????Y5Y??Y5PGB#&&&&GGGGGGGGGGGPPPPP55YYYY555    //
//    G5PBB#@@&##G&@@@@@@@@@@@@@@@@#PGPGBGGJ7:...^^~7J5Y7JJJYJJYJB&#PY??5G###&##BGBGGGGGGGGPPPPPP5YYYYYYYY    //
//    B##&&#&&#[email protected]@@@@@@@@@@@@@@@@@#GBB#&&&P7!!7JJ5BGYJ7YY5Y7JP5PPY?JJJPB#&&@&#G5GBBGGGGGGGGPP5555YYYYYYY    //
//    ####&&BB###&@@@@@@@@@@@@@@@@@@@#BG&#&@#G#####GBB5J?PG5PGBB5JJJJJJ5GB##B&##PYYGBBBGGGGGGGGPP5YYYYYY55    //
//    B###&#BG#@@@@@@@@@@@@@@@@@@@@@&GGPBBB&GB&&B&#BPGGGBGGGGGBBG5P5YYY5B###&###PY??5BBBBBBBGGGPP555555YY5    //
//    BG###BBB&@@@@@@@@@@@@@@@@@@@@@&#BGPG#P?5PPY5Y5P55YJYJYPGBPPP#GPPPB#####&&BPY777J5GBBBBGGGGGPPPPPP555    //
//    PPGGGGB&@@@@@@@@@@@@@@@@@@@@@@&##BBGGG7~JY7!?YYJJJ7777Y5#B#PPP5#B#&&&@&#&#GY??777?YPGGGGGGGGPPPPP555    //
//    5PPGB&@@@@@@@@@@@@@@@@@@@@@@@@@&##GPB#Y?JJ7!777!~!7YYJYPB##GPPB##&&@@&&&&#G5JJ?7!!!!!77??JPGGGGGGPPP    //
//    PG#&@@@@@@@@@@@@@@@@@@@@@&#BBGP5PBBGGGBPPPPP555JYYYPGGP5PGBGPGB&&&&&&&&&##PYJ?77!!!!~~^^::~?YPGGGGGG    //
//    &&@@@@@@@@@@@@@@@@@&#G5J7~^:....~5GGGGP5PGB&&&&#####BGPGGPPPG##&&#&@&&&#BB5J?7777777!~^^. ...:~?PGGG    //
//    @@@@@@@@@@@@@@@&B5?~::.   .::^^:^7YPBGPP5YG##&#BGB#BBBGGGBGB&@&&&&@&&&&&#G5J?7777777!!~:.....   :!YP    //
//    @@@@@@@@@@@@&#5!^. .:.  ..^!7!~!77Y#&#G55GBB#BBBBBBB#B#B#&###&&@&@@&&&&BGP5Y???J?77~!~^:::..     .:~    //
//    @@@@@@@@@&BY?^^~:.::....:!?J7^[email protected]@&##G#BBBGPG#####&&###&#&&&&&&&&&&&BG55P55PY?!~~^^^^:.        .:    //
//    @@@@@@&PJ7!~.^~^~!::^~^~?Y5?:^!^!P&@@@@&&&##&#G#&&#&###&B#&&&&#####@@@&##GGGPY?!^^^^^:...               //
//    @@@@&5!!!~~.^~^77~^!7!!JPGY!~^77YB&&@@@@@@@&@@&@@@@@&&&&&&&&&&&&&&&@@@&&#G57!~~~^^^:.                   //
//    @@@#?^J?^~:~?!??!7?JJ?JG#GY?^[email protected]@@@@@@@@@@@@@@@@@@@@@&##&&&&&&@@@&&BPY7~^^^^^:..                     //
//    @@B!^5?:7^~5?5Y?JY5YY5B##G577JPPPB&@@@&@@@@@@@@@@@@@@@&&######&&@&BPY?!~~^^^::.....                     //
//    @#7^GG777!5P55J5PPP5G##BBPJJPPPGGB#&&&@&&@@@@@&&@@@@@&&&##&###BG5J7!~~^^^:...   ..                      //
//    @G~5#G5Y?P&&GJGBGPPP#&BBPJ?G##BBGB##&&@@@@@@@&&&@@@@@@@&&&#GP5?7!!~^^::..    .                          //
//    #Y!GB&GGB&@&P#&BP5P#&BGP5JP&@@&BGB#####&@@@@@@&&&&&&##BBGPY?7!^::::...                          ....    //
//    B?5B#&G#&@&G&@&B5P#&BGGPYG&@@@@#GGB##BGGBBBGGGPPPPP55YJ??7!~~^^:::..:....                      .^^:.    //
//    PYB#&#B#&&[email protected]@#P5B&#GPG5P&@@@@@#BBBBBBGGGGP5Y5YYYYYYJ?77!!!!~~~~^^^^::...                      .::::    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract EC is ERC721Creator {
    constructor() ERC721Creator("Eyal Carmi", "EC") {}
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