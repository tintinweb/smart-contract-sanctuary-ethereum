// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Unknown Art
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    &&#&&&&&GY!~7!JG&G5Y5PY5#@@@@#GGGGBGB&@@@&&&GBBP5PBB#BG55#@@@&#&@@@@&&@@&@&BBGGGP&&&#&&@&&BP#@@@@&BB    //
//    &&&&&&#PPG!^!7?JBBG5##5Y5#@@#[email protected]@@@#BPGPPPPGB&&#BBP&@@&GB#&#B#&@@&#B&#GPGB&####B##B&BB#&@@@@&    //
//    @@&&&GPB&G~^!7??P&B5GG5J?Y#@&BBBGGG5G&@@&B5PPY5P5GGG&@&&BP5#@@&#GBB#@@&BBGGGGB#@@@@@@@@&&BGB##B#@@@@    //
//    Y#&#PP#&#J~^777??5&P?YGP577P#@@@&@@@@@&#BPGGP5JJYY5GGPGPG#BGG#@&&&@@@&BB#BGB&@@@@@@@@@@@@@#G#&#BB#&&    //
//    YG&BB&#GP?~^7!7?77?5?JBGP5J?7YGB##&BB&G&#GB&G55GB#&&&#BPG#&#PG&B#BB#&BGBB#&@@@@@@@@@@@@@@@@@#&&GGGPP    //
//    P#&&&B5YJ!~^7!7???YPBB##GPY?7???7YBYP&GGBBPG#&@@@@@@@@@@&&B55B&#&B###P5B&@@@@@@@@@@@@@@@@@@@&#&#BGGB    //
//    &&&B5J??!!~^!!PGB&@@@@@@&&#BP??J5YGP#&GYY5#@@@@@@@@@@@@@@@&#GB&BPB&BG5B&@@&@@@@@@@@@@@@@@@@@&B##B#&@    //
//    &#5?!7Y?~!!~!!#@@@@@@@@@@@@@@#5YPG#&&&5JP&@@@@@@@@@@@@@@@@@@&##B#BPPGP#@@#PGPG#&&@@@@@&&@@@@&[email protected]@@    //
//    Y7!~??Y?~~!~!!#@@@@@@@@@@@@@@@&BP55B#BJY&@@@@@@@@@@@@@@@@&&@@&BGGGGG#G&@&57^:^75&@#GPJJB#@@@#[email protected]@&#    //
//    ^[email protected]@@@@@@@@@@@&@@@&[email protected]&&@@&@@@@@@@@&BB##@@@BPPPBGBG&@@#PY7?P#&&G?^:^!5#@@P5B#@@&#    //
//    GPPJJ7~7?Y~^[email protected]&@@@@@@@@@&&@&@@#P??Y5P&@#[email protected]@B&&&@@&#GJ77YYB&@&GGB#BBP#@@@@&B&@@@&@#PJ5PB&@#JPB&@&&B    //
//    &&#BP?!?55~^!!P#G#&@@@@@@&BGBG&@&#57?JJ&@&PG?~~7?G&&G~.::^[email protected]@#B##BBPG&@@@@@@&&&#&&@B&@@@&55&#&&@&P    //
//    #&&GBG7755!^!777!7YB&@&BY7~~!J#&@#[email protected]&57!^~!?B#@&#PYYG#@@@@#[email protected]@@@&#######&@@@@&#G##B#[email protected]@@    //
//    #&&PG#57?Y!^!!!::^!P&@BBY!:^?JP#&[email protected]@@&&#BP#@&&@@@@@@@@@@&BBGBBP55P&@@&BGB###GB&@@@&PP5PGPPB#@@    //
//    #GG5P&#Y7?!^!!G#GB#&&@[email protected]&#G&&&@@GY7GBBGB&@@@@@&@&#G&&&&@@@@@&P5B&&&&GP5P#@&&&&#####&@@&G55GGBP5&&&@    //
//    ~:^!5##Y!7!~!7#@&@@@@@#&@@@@@@@@&P7?P5J?JG#&@@@@&B#GBBB#&@@@##Y5P#@&&&G55B&@@@@&&@@@@&BBGBPGBBP5B&&&    //
//    !~~?P##P77~~!7#@@&@&&##@##@@@@&&GY???GY??YB&#&@&#5PBBBBPB&@&&PJYGB#&#BGP5P&@&@@@@@@&@#GBBPGB#BBPP#@@    //
//    #G#&##[email protected]&#[email protected]@@&&BY7J?Y#[email protected]&@&&#B##GBB&&@@GJJPBGBBBG555P&@&###&@&&@&&#B&@#BBPGGG#&    //
//    ##&&#[email protected]&#GBB##BB&@@&&#P5?JPGBYB#JJJP#@@@@@@&#&@@@&&PJ5PGGBBGGGP5PB#BGPGB&&&@#B###&&#BB&&BPG    //
//    BG#BGGPJ77!^[email protected]&#5GGGGBG&@&@#JY5YYGGP55Y??GGJ5G&@@@@@@&#G5&BPPB#&&&&@@@&##B5PGGG&#B&#GPBPB&&B&&###B    //
//    PGBPGPYY5J!^!!5#@&BBGGGB&@@#PYY?YY5GB#GPY5JJJJYP&GG&B##BGYPBB#&@&@@@@@@@@@@&#BP5G#BG&#GGPG###B#BB###    //
//    B#BGP?7JY?!~!!7?5#@@@&@@@&BJ??5YPGB#&&&&###BG55P5Y5#5BB#P55P&@@@@@@@@@@@@@@@@@&GPBBG&GGG#&&&@@@@@&&&    //
//    #GJYG?^7??!~!!PJ~J&GB#@BY5PJY5PG##@@@@@@@@@@@&BGJYYBPBG5PP5#@&@@@@@@@@@@@@@@@@&&#BBBBPG&@@@@@@@@@@&@    //
//    J?!~~~!7JJ!^!!5J!J#?7JGP7J?7?5B&@@@@@@@@@@@@@@@@BP5GP#BGP5#@&&@@@@@@@@@@@@@@@@@&GPGGG#&@@@@@@@@@@@&#    //
//    ^~7?Y5PB#B!^[email protected]@@@@@@@@@@@@@@@@@@#BGPP#[email protected]@###B##&&@@@@&&@@@&@@GG#B&@@@@@@@@@@@@@#&    //
//    YG#&@@@@@#7^[email protected]&#[email protected]&@@@@@@@@@@@@@@@@@@@&BPPP5G#@@B?^:^!5#@#P?775#&&@@GGB#@@@@@@@@@@@@@@&G    //
//    @@&&@@@@@@?^[email protected]@@@&PJYP?5PP&@#@@@@@@@@@@@@&@@@&@@@#555J5#@@&B5J55B#@#J~:^75#&@#PB#&@@@@@@@@@@@@@@@#    //
//    #GB#@@@@@@Y:[email protected]@@@@#5YJJG#@@@B&@@&@@@@@@@@B&&&#&@@&P55Y5G&@@@@@@@&#@@@#GB&&@@&55G#&@@@@@@@@@@@@@@@&    //
//    B!^~?B&@@@Y:[email protected]@@@@&PY?5PY&@@#&@BPPGB&@@#Y~~7YB&@@&PPB#55B&&@@@@&#[email protected]@&@@@@@&&BY&&BG&@@@@@@@@@@@@@@@    //
//    #5^..Y#&@@J^^[email protected]@@@@&[email protected]@&GJ^::7G#@&B7^[email protected]@@&GPY5YYB&&&@&#BBB####@@@&#&PPB#BG#@@@@@@@@@@@@&#G    //
//    @&G55G#@@@Y^[email protected]@@@@@#[email protected]@&G5YY5G&&&@@&##&@@@@@&GG55PGG#@&&&GPPBPYPG&@@@&BPB##GG#&&@@@@@@@&GY7!7    //
//    @&&&&&&BB&[email protected]@@@@&G5YY5PG&@@@@@&@@@&B&@@@@@@@@@@#BBPPP#BP#@@@&&#####&@@@&#GGB&&#BGB&&@@@@@&&G!^~!    //
//    #&@@@#5^:[email protected]@@@#[email protected]@@@@@@&&BG&&&&&@@@&&#BB#&GGGPYP#@@@@@@@@@@&#BBGPGGPGB#GBBB#&@@@&#5?YG    //
//    @@@@@@B?::[email protected]@&GJ?7JGBBB5Y5##&@@@@#B5555PP&@@&B#GPB#BGPPPPY5###&@@@&&@#GPGGGB#P#&&&#BGGGB#&@@&&@@    //
//    #&@@@&&&G?7^~!Y&GJ???J5PGGBBPYG##&@@&#G#&&&&B#@@&&G5PPBBGPPGGBBGGPPB#&#&@#GGBBBGBPPBB#&####BGBBB&@@@    //
//    &@@@@@@@@&?:!7?J777??JYJYY5PP5YB##@@@&BGGBBPPB&@@&YYY5YY5J555PGGBGPGGGP#@#&&BGGGBBB&&&&&&&&#BBGGGBG#    //
//    @@@@@@@@@#?!!7?JYPGGBBBJ?BG5PG5YPP#@@@&B#&&&&@@&B#5P5Y5PGB#&##GGGPGPGB#&@B##B#&&@@@@@@@@@@@@&&#BBBGB    //
//    GGGGGGPGJ!!7Y#@@@&&&&[email protected]#7#@&BPY?77J#@@@@@@@&&##B&&[email protected]@@@@@@@@@@&#PPG#@&[email protected]@@@@@@@@&&&&&&@@@@@&##&    //
//    J???YGGY~!!J&@BB##&&&[email protected]@[email protected]@@&[email protected]#PGBB#BGPGBGPP#@@@@@@@@@@@@@@@&GPG&#G#@@@@@@@@@@@@@&&&&@@@@@@&&    //
//    [email protected]@G#&&#B#G&@[email protected]@@@@[email protected]#YJY5B##[email protected]@@@@@@@@@@@@@@@&@#GG&##@@@@@@@@@@@@@@@@@#GPP&@@@@    //
//    &&#[email protected]@#&&#&#&#&@[email protected]@@@@#5JJY&BJPP5##BP55G&@@@@@@@@@@@@@@@@&@@#BB#&@@@@@@@@@@@@@@&#[email protected]@@@@    //
//    #@@#BP!!7!!?&@##&B&BB##@[email protected]@@@@@P!!7#BY5PPPGPPGG&@@&&@@@@@@@@@@&@@#&@&B#&&@@@@@@@@@@@@@@@#?~?G&@@@@@    //
//    #@@&B5!!7!!7#@BG&&&&&BG#[email protected]@@@@@577JBBBPPGPGPPPP#@&&B55PB&@@&B5J5G#&@&#BB#&@@@@@@@@@@@@@@&BB&@@@@&@@    //
//    &@@&G7!77!!7#@&G#&#&#GY&P?#&@@@&?Y5GB#&[email protected]&B?^^7Y#@&BJ~^!5B&@#BP5P#&@@&&@@@@&&P??5&@@@@@@&&#    //
//    &@@&[email protected]&B#&&&[email protected][email protected]@@&Y7?G&&&BBBB##G555P&@&&BB#&@@&#&###&@@&#[email protected]@&&&&&@&Y~^:?#@@@&&&&PP    //
//    G&@@P7!!77!7#@&[email protected]&BPP#&@GJ&@@#Y?J5B&&&###&&&BP5PPB&@@@@@@&@@&&@@@@@@###&#BGGB#@@@&#&#?^~Y#&@@@&&&[email protected]    //
//    &@@&Y!!!77!7#@&GPJG&@@@@[email protected]&5!?5B#&@@@@@@@@&&GYJJ5#&@@@@&B#BB#B#@@@&B###BP5PBPB#&@@@@GY#&@@@@@@@@B#&    //
//    @@#BJ!!!77!7#@@[email protected]@@@@@B?BJ!JP&@@@@@@@@@@@@@&B55YP&&&@&B5PGGP5G&@@&#B#&##BG#P5BBB#&@@&@@@@@@@@@@@&&    //
//    @BGP?!7777!?B&[email protected]@&&&@@@#7775#@@@@@@@@@@@@@@@@@&[email protected]@@&&BBBBB#@&@@#PB##BPPP55PG##BG###&&@&&&&@@@@@@    //
//    #G5777777!!?G#&@&#BB#&&@&775&@@@@@@@@@@@@@@@@@@@#PPPG&@@&@@@@@@@@@#BPGB#B##&&&#BBBBBBBGPG#BBBB#&&&&&    //
//    [email protected]@&#B##G#G&&??#@&&@@&@@@@@@@&&@#&@@&BG#GP#@@@@@@@@@&#GGG#&@@@@@@@@@@&###GBGGBGGB#B####&    //
//    [email protected]@#BB#[email protected]@&#GGPB&&@#&#B#&B&@@@BGBP5P&&&&&@@&&BBB#&@@@@@@@@@@@@@@@&&&GG#BB&&&&BGGG    //
//    ????JYY5YJ???P&&#[email protected]@#5!^~!P&&@P!~!JG&@@@BBGP55#BGB&&&B#BB&@@@@@@@@@@@@@@@@@@&#BPB###&&&###&    //
//    J?J5BBBB##5?JJYYYYY5G#[email protected]@@&GPGB&&&@#G5YB&&@@#GBB#&#BGG#&&#BB#&@@&&@@@@@@@@@@@@@@@@&#GB#&#@@@@@@@    //
//    5#&@@@@@@@5^??YBBBP55PGYYJY#&@@@@@@@&#@@@@@@@@&&PPB###&#GB&&@&#&#@@@&&@@@@@@@@@@@@@&@@&BGB##&&@@@@@@    //
//    @@@@@@@@@@[email protected]@&&#GP5YYJ?Y#&@@@@&#BG###&@@@&&BG#BGGBBGGPG#@&#&&@@&#B5YPB&@@&GYYG&&@@&B5G#&@&&@@@@@    //
//    ##&@@@@@@@[email protected]@@@@&#B5YY?7P&#&@&#PPPPPG&&&#&GG##B#&&#&#GG#&###&@&#GY!~?P#@&G?77YG#@@&&GP#&@&&&#BB&    //
//    #&@@@@@@@@Y!77J&@@@@&##P555?JG&#@&&#&&&&B&@&&GG#&@@@@@@@@@&&&BBGB&@@&&&&&&&&@&&&&&@@@&&@GG&@&#GY!~7G    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Unk is ERC1155Creator {
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