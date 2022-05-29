// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: animal account prototype one
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G~75~^!7JG&@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&BGGGGG#@@@@@@@@@@@@@@@@@@@@@@@@@?!JY^!!~:[email protected]@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#PY57! :7JB#@@@@@@@@@@@@@@@@@@@@@@#5G5BJJ~:!7PBGB&@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BGP?JJJ7?G#BG#@@@@@@@@@@@@@@@@@@@@&PPGJJYJJ?5##GBPJ!J#@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&Y!~^[email protected]@@@@@@@@@@@@@@@@@@&57!!~:~!GP?7?G?^^^~~P&@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&##BPY7~~7Y&PJ555PGB#&@@@@@@@@@@@@@@&5?77!^:[email protected]    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#GY??7^:::^!7?G&BBBY~~:^!!?J##&@@@@@@@@@P7!~~!~!7J##B&#YJ?7JJP#@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&GJ~!~7#G:^^^!7J~~!!~Y7!!!YBB5PPGG&&@@@@@&#&7^~^[email protected]@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#5?!!!P#GB#JY55GG7^^~^~PGJ!!~^7Y7^[email protected]@@#P&PJ55PBY77??7P&B&@@@@@@@@    //
//    @#&@@@@@@@@@@@@@@@@@@@@@@@@@@BJ!J5P##BBB&BBBJ?!~~!!!!7#&GG5JYYJ?7!~7Y5#&BGG##GBPJJ7?J5G#&@@@@@@@@@@@    //
//    &?!?P&&@@@@@@@@@@@@@@@@@@@&B5~J^75##5??Y#G?77~^7~~~!!P&&G&5Y5J??7!~~JB#BJ?YG#Y?JJ?YG#@@@@@@@@@@@@@@@    //
//    &P5PGG7?Y5#@@@@@@@@@@@@#PJ!^J?JJ!!5&BPPB&P?J!^Y?~7!JBG#GPJ7?Y7????77?Y#&J?5B#YY5P#@@@@@@@@@@@@@@@@@@    //
//    #&BB#5YJY!G#BB5PPB&B5J7!~!7?JJ5J??75&&P&P5YPJP&#GGPPG&#5J??J?JJ5YJ5J?7?B&[email protected]@@@@@@@@@@@@@@@@@@@@@    //
//    Y&&&GJ??Y##P&P!~~7G5!7JJYYYY!!77JJ77G&#&Y??JG&G#&Y?7JG&5J5555PP5JJ???~:?&#&[email protected]@@@@@@@@@@@@@@@@@@@@    //
//    #&@&G5?YG&&#&GPY5#GJ77JJYJ7YJYJJ?~7JJBB5YJJP#&#&&GG5B#PYYY555?JJ???J7^^7G&[email protected]@@@@@@@@@@@@@@@@@@@    //
//    @@@&#G5J?G&#P7777?G###?777?7555PGGPBJ!!~~~~~YBGGY??J?YBGGY7!7!!7?Y5GBPGP55!^^^:[email protected]@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@&BPGJ7?7~!!?GPYPGPGJ5B5YJ5##J:::^^^^:^!?~~^~^^^7?7JPPPYYGGYYYB#Y~:^[email protected]@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@B?JJ7~:~5?77?PP~!YY7?JPGPG!!~~~!^^!P!~7!~::7Y777YB7^[email protected]@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@G5?~7?G#BGP577~~~~~^!B&#BPBPYPPYPPGP??:^?J#BBPPJ7~~~~~^^Y&&[email protected]@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@&5JP##GBGY7^:7JY7~~:Y&BBPJJYP5PGP?YYJ?JB&BGBP?~:~?JJ!~^^#&[email protected]@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@#YJJGJ~~^!~!~!7?PPG#PBY?J7J?!7!^:!JBY77YG~~^~~~!~77YG5#[email protected]@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@G5PP7!~!77?!:~YG#GGYGJ?J???77~^^!Y#PJY5?!~!77??^:?P#BB5YJ?JJJJJJJ&@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@&5J?!?!77?J!YJJ5Y?GJ?JJ!!!!!~!7G&B#&P77~!7!77Y!?5JY5?JY??Y?77?PBBB&&@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@&PYJB#GBB#BBB55JJ57?&G^~~~7J57!JJ?P?7775#BPBBBB#P5Y?7J!G&?^^~?7?JYYYP#&@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@&BYJ5P7755YJ?JJG#GB#YY55GG7~~!~!PGJ!!!~7Y?~J55J?!?J#GG#57~~??55JYPGBB&@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@&BGYJ????JYB#BGB&BBBJ?!~!!!!!7#&GG5JYYJ??7~77?PGBGPGGP5?^^75#&@@&@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@&P?!!~!Y##5??Y#G?77~^7~~~!!P&&G&5Y5J??!~^^7YPG5JY?????JJJPB#@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@&B5Y??P&#PGB&P?J!^Y?~7!JBG#[email protected]@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&[email protected]&G&GP5GYP&#GGPPB&#5YJYYJ55G5YP5G#&@###[email protected]@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@@&&[email protected]#@PJJYB&GYPPGGBB##&@@@@@@@@#PJ~77?G#BGB&&&&@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@&&#BBB#&@@@@@@@@@@@@@@@@@@&#&@@&&@##G#@&BB#&@@@@@@@@@@@@@@#!!!75YJPBG5GG#&#&@@@@@@@@@    //
//    @@@@@@@@@@@@@&B?777??YY55B#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&#PP5^::::^7JY7~~!!?PB&&G#&@@@@    //
//    @@@@@@&&&&@&&#G!~77JPJJ5PBB#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&PYJYY!:..::.:::!5!~!~^^:[email protected]@    //
//    @@@&#BYG##BBBBP5Y~^~JG&&@&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@GYY7!?PP5J!!!!7~^~7?!??7!^~5?!~~YP!J&    //
//    @@BBGPPGGBGPY?JJ????YB#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#!J7^^5&&BGBB5Y5J7777!?J???G&BGP5!7J7?    //
//    @@&5YP555P5J?~^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BYG7!~~&#5YJ?JJJYY7^^~?JJJJYYG&P?^^YPY    //
//    @@@&&&&&&#B#BG?7777J55YY55&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&JY55B5YJJY55555557!!J555555YJJYY??5?G    //
//    @@@@@@@@@@@@B5!~775B#GG#&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@55GG555P555555555?!J5555555PPPPP5P#@    //
//    @@@@@@@@&#G?~!JP5JJJ?77YJPP#@&@@@@@@@@@@@@@@@@@@@@@@@&&#BBBB&&@@@&[email protected]@@    //
//    @@@@@BY?!!!!:::~^!!^^^^7JJJYGG#&#&@@@@@@@@@@@@@@@@@&#Y7777?JYY5G#&#Y?77!7!5G???J?JPY???7??!!!!YG#@@@    //
//    @@@G&57?JY5?^:.:.!PJ!~!^~??:^[email protected]@@@@@@@@&&&@&&&BJ~~??55JYPGB#B5J!!7P5?5J???7??!^~~^!YJ~^!!?&@@@    //
//    @#BBGP5B5??!!!!!~~JPBG55Y5YJ?7~^7JP##&@@@@##5PB##BBBG5Y7^~?P#&@@&@#JP5B#BBG#BPGY!!^^^~~~!5&[email protected]@@@    //
//    &YPJP#Y7??7?JJJJ?7J??J55PP5YJ7!~75B&[email protected]@#BGGPGGBGP5J?J????JG#&@@@@@YYG&GJ?JG#Y!7!^~!~^~!?&&G#B5&@@@@    //
//    &B#B##YJYJ?JJJYYYJ!^[email protected]#[email protected]@&BJP555PPJ?7^7?J?Y5PPPPJ#@@&JJ#&GPG##J??^75~!7!PBG#[email protected]@@@@    //
//    @@B#&[email protected]@@@@@&&&&&#[email protected]@@&5J#@B##5555J#&GGPPG#@[email protected]@@@@@    //
//    @@&&[email protected]@@@@@@@@@@@@@#P?~77JG#BGB&&&&@@@@[email protected]&&GJJJ5&&[email protected]&&B&@@@@@@@    //
//    @@@&[email protected]@@@@@@@@@@@@&P!!JPJ~~7Y?JJYB##&@@@@@@@@&GYP#@@&@#BBB&@@@@@@@@@@@    //
//    @@@&7~^^~YP5Y7!??7JPGPJ?7777??7J5G#@@@@@@@&GG##PJ7^^^~!7J7!^~~!!?Y5G#@@@@@@@@@&&@@@@@@@@@@@@@@@@@@@@    //
//    @@@@5?7!^:~?!~~~~^[email protected]@@@@@BY7!~~!7^!~^..^7YJYPPPY?55!!75BP5#@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@#7?7^!JY^!7~^.^[email protected]@@@@J!7~::[email protected]@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@GGP5G5BJJ!:!?P#[email protected]@@@@#PGP5YPPGGJY????Y?7777JJ???7!~5&&GPBG&@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@BGGBYJYJJ75##GBG57^:[email protected]@@@@55GGPPBBP5YJJJJYYY7^^~?JJJJJJ??&&[email protected]@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@GJJ7~!7GG?7?GJ~~~7!?7?JY#@@@@@@&55GY55JJY5555555Y!~!J555555YJYB###YP&@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@&GJ7?J##5YPP?77JYJ5YY#@@@@@@@@@&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@&[email protected]&&@&555Y5PB&&@@@@@@@@@@@@@P?77?JY555PPPPP?7Y555555YYJJJ?5#@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G~~~~7?7!???J??7?YP5JPPPYY?77!7&@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&5P5P5^^^~^^7??!~~~!7!^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&BYJ!~~~~~~!B#GPY?JYJ?77!?5P#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#YJ7~7~~~!!P&&G&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BJ!5J!7!JBG#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]#BBPPB&#5J????JY55Y5Y5&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@PYJYB&GYPPGGGG5J5G#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#G#&GYY5GG#BBB#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ACC is ERC721Creator {
    constructor() ERC721Creator("animal account prototype one", "ACC") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x80d39537860Dc3677E9345706697bf4dF6527f72;
        Address.functionDelegateCall(
            0x80d39537860Dc3677E9345706697bf4dF6527f72,
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