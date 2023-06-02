// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: COMMERSE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    :~:..::.                                                                                                //
//                                                                                                            //
//                                       ~7!7JJYY5PGP5J7^.                                                    //
//                                   .::~YBPYY!~~?^5####G5?^                                                  //
//                              .^7YPB##&&&&&&&##BGB#######B5!                                                //
//                            ^JG#&&&&&&&&&&&&&&&&@&&&###B####J                                               //
//                           J#&&&&&&&&&&&&&&&&&&&&&&&&&&#####B^                                              //
//                          ~###&&&&&&&##BBBBBBBB####&&&&&&##B#Y                                              //
//                          .P&&&&&&&BGP5YYY555PPGGBBB##&&&&&#BB^                                             //
//                           :5&&&&#BG5YYJJ?J??????JY5PGB##&&&##?                                             //
//                             !#@BGGP5YJJ??J?77!~~~~!7?JY5PB#&&P.                                            //
//                              [email protected]???JYY555P5555J??J5G&B:                                            //
//                             :YB&&&&&&&&BP7JB&&&&&&&##B5JJJY5GG!.                                           //
//                             .5G##&&&&###GJJG##&#####BGY7?JJJ7!J7.                                          //
//                              ^P#####&&&BY7!?GBBBBBB5YJ7!7??7JJ7?.                                          //
//                               ~GGGGBBBB5?777?JJYYY?!!!!7???!!J?!                                           //
//                                7PP5PGGGPY7?J7!!7!~~~~!!7??7~!!^.                                           //
//                                 !PPPPGGBPJ77!~~!!~~~~!!7??7~:.                                             //
//                                 .YPP55PPY?7~~~~~~~~~!!77?J~                                                //
//                                  :YP5PBGP5YYJJJ?7!!!!77?J?:                                                //
//                                   ^YGGGG5YYJ?7!!!!7777?J7!.                                                //
//                                    :JGGPYJJ?7!!!!7?????7!!:                                                //
//                                     :5GPYJJ?7!77??J???!!!7^                                                //
//                                      JBGGGP5YYJJ?7777!~~!?~                                                //
//                                      !GGGGGGPY7!!~!!~~~!!?7^                                               //
//                                      :P5YYPP5J?7!~~~~~!!77??!~.                                            //
//                                     .!PPYJY55Y?7!~~!!!!!!77????!~^.                                        //
//                                  .^7PGGGPYJYYYJ?77!!!!!!!!777JJ7777!!~^.                                   //
//                              .^!J5PG#GGGP5YJJJJ??777!!!!~~~!7J7!!!!777777~^:.                              //
//                        ..:~!7?JY5PGPGGPPPPY?77???777!~~~~~~7J7!777777???JJJJ?7~^:.                         //
//                    :~7777?JJJJ55PPGP55555YY?!~~!77?7!!7777JYJJJJJJ???????JJJJJJ??7!~:.                     //
//           ::::  :!?JJ?JYYJ?77?J5GGGP5YYYYYJ?!~!!??J?????JYJ777777!!!~~!7?JJJJ??JJ?JYYJ7^    ...::::.       //
//        :YB&&#&B5YYJJG#@&&&&[email protected]@&GP5YY#@&#!7&&&BJJJ75&&@Y^5&&&&&&&?!#&&&&&&#PJJ5#&&&&@B7 :#&&####P       //
//       ^&@&7::!#@&JJ#@&[email protected]@GY#@@@&P5P#@@@&[email protected]@@@[email protected]@@@[email protected]@57???77&@&YJJ#@@5J&@&Y??5GP!^&@#^^^^:       //
//       [email protected]@J    [email protected]@[email protected]@&[email protected]&[email protected]#[email protected]#[email protected]&[email protected]@B&@5?&@P&@[email protected]@####B77#@&GPG&@#J?5#&&&#BPJ7?&@&BBBB7       //
//       [email protected]@G.  :B##[email protected]@#[email protected]@[email protected]&5#@&@&[email protected]&??&@[email protected]&#@[email protected]@[email protected]@5????!7#@&[email protected]@#J7?YYJ?JY#@@[email protected]@#~^^^:       //
//        7#@&GG#@&GYJ5#@&#B&@&[email protected]@55#@@[email protected]&[email protected]@[email protected]@[email protected]@[email protected]@#BBBB?!&@&[email protected]@[email protected]&BGB&@[email protected]@&GGGG5       //
//         .^7??5BPYYJJJ5PGGGP5YYYPGPYY5G5JJY5Y!!JY?77YY7!7YY7!?YYYYYYY7!JYJ!!!JYY?77?Y555J?!!7Y55?777!       //
//              JGP5YYYYYYY5YY55YYYYYYJJJJJJ?77!!~!!77!!!!!~~!!!~!!!!!~!!~~!!!!!!!!7777!!!!!!!!!77!           //
//              YGP55YY55PPP555YYYYYYJJJJJJ??77!!!!!77!!!!!!!!!!!!!!!!!!!~~!!!!!!7777777777!!!!!77?!.         //
//              JGP55YY5PBGPP555YYYYJJJJJJ??777!!!!!7!!!!!!!!!!!!!!!!!~~~~~~~!!!!77??????7777!!!!77?~         //
//              ?BPP5YJYG#BGGP55YYYYYJJJJJ??77!!!~!!77777!!!!!!!!!!!!~~~~~~~~~!!!7?JYYYJ???77777!!77?:        //
//              !GGP5YJJG#&#GGP55YYYJJJJJ??777!!~~~!777777!!!!!!!!!!!!~~~~~~~~!!7?YGGP5YJJ???7777!7777.       //
//              ~GGP5YJYGB#&BGP55YYYJJJJ???77!!~~~~!7???777!!!!!!!!!!~~~~~~~~~!7?5BBGP5YYJ??777777!77?~       //
//              ~BGP5YJ5GB#&&BGPPP5YJJJJ??77!!!~~~~!7???7777!!!!!!!!~~~~~~~~~!!7YBP:~Y55YJ??7777777!77?^      //
//              7BGP5JJ5GB##&#GGGBPYJJJJ??77!!!~~~~!?J??7777!!!!!!!~~~~~~~~~!!7?JG7  755YJJ?77777777!77?^     //
//              JGG5YJ?5GB##&&GGGP5YYJJJ???7!!~~^^~!?JJ??77!!!!!!!!!!7??7~~~!77???.  .?P5YJJ?777777!!!77?~    //
//             :5PP5J??YGB##&BBGGP55YYJJ???77!!~~~~!7JYJJ?77!!!!!!!!7?YJ?!!!!7777:    .?P55YJ??7777!!!!7??    //
//             7GGPYJ?7?GB##GYGGGGPP5YYJJ??777!~~~~!7?JYYJ??777!!!!!!!!!!!!!!!7?!       7PP5YJ??777777777?    //
//            :PGP5J??7?PBBG7?PGGGGP55YYYYY5PPP57~!!~7??JJJ??77777!!!!!!!!!!!!7?^        !PP5YJJ?77777777?    //
//            7BGPYJ??7?GGP!:!YPGGGP555PGB######BPG?~!777?7777777!!!!!!!~!!!!7?7.         ~PGP5YJ?????777?    //
//           .5GP5YJ?7J5BGY..~J5GGGGGBBBPP#######BB5!!?7777!!!!!!!~~~~~~~~~!!77!           :YGPP5YJJJJ????    //
//           7PPPYJ??YGGBG!  :YPGGGGBBPJ!?5B#######G5?7??777!!!!~~~~~~~~~~~!!77~            .7GGP55YYYJ???    //
//          ~PP55YJ??5GBB5.  .PGGGGG#P5PJGP!G&######BGPYJJJ?77!~~~~~^^~~~~!!777:              ^PBGGPP5YJJ?    //
//         ~55YYYYJJJ5GBB7   .5GGGGGBBPJBP?Y#&&&&&&&&BB#G5YJ??7!~~~~^^~~~!!!77!.               :G#BGGPP5YY    //
//        ^55J??JYJYPGGBB~   .5GGGGGGGG555PGGGGBBBBBGGP5YJJ??????7~~~~~~!!!!77~               :^YBGGPP5555    //
//       :JYJ???JJJJYPBBB^   ^GGGGGGGGGPPPYJ????JJJJ???777777??????7!!!77777??~          ..:^!J55555YYJJJJ    //
//       J5Y?7777?JJPGB#5.   JGGGGGGGGGGBGP55YYYYYJ?77777777777777?????JJJYYY5?^^::::^^~!7?JYYYYYJJJJJ????    //
//      ~5YJ7777!777YGBG^   7GGGBGGGGGGGGG55P5PGGG5J????7777777777777777!!77777????7??????JJJ?????????????    //
//      Y5Y?7777!77YPGG!   ~PGGGGGGGGGGGBG5PP5?JY5YJJ?????77777777!!!!!!~!!!!!!7777777777777777777777?????    //
//     :P5J?77!!7775GG?   ~PGGGGGGGGGGGGBBGPG#P5PPY????????????7777!!!!~~~~!!!!!777777777777777?????????JJ    //
//     !P5Y??77!7775BY   :5GGGGGGGGGGGGGBGPYY5555P5YJ????????????77777!!!77777777777777??????????JJJJJJJJJ    //
//    .YP5J??77777JGG^   ?GGGGGPPP55PPPGGGPJ?????JJYJJJ?J??????????7777!!!777777????????J?JJJJJJJJJJJJ??7!    //
//    !PP5J?777!!75B?   .5GGPPPP55YY55PGGGGPP55555YY5YJJ????JJ?????????777777????????JJJJJJJJJ??7!!~^::.      //
//    YP5YJ?77!!7?G5.   ~GGPPPPP55YY55PP55555YY5YYJJY55YJJ???????77!7!!!!!!777??~:.::^^^^^::::.               //
//    PP5Y??77777YG^   .YBGPPPPP55Y555555YJJ??7??JJJ???7777!!!!!!~~~~~~~~~!!!77?:                             //
//    PP5J?77777JG~    7GGGGPPPP5YY555555YJ???77??JJ?77!!~~~~~~~~~~~~~~~~~~!!!77:                             //
//    55Y??7777?57    !GGPPGPP5555YY5555YYJ??77!7?5J?77!!~~~~~~~~~~~~~~~~~~~~!77^                             //
//    5YJ?7777?J?    ~P#GYYPGP5555555555YYJJ?77!!?5Y?7!!~~~~~~~~~~~~~~~~~~~~~!77!                             //
//    5J??7777??.   ^5PG&B55PP5555555555YYJJ?7777?J?77!!~~~~~~~~~~~~~~~~~~~~!!7??.                            //
//    Y??7777?7.   :Y5PYB&&#BG5555555555YYJJ??77777777!!~~~~~~~~~~~~~~~~~~!!!777?~                            //
//    J77777?!    :YPYY5JG&&&&#G5YYYYYYYYYJJJ????77777!!!~~~~~~~~~~~~~~~~!!!!!!77!:                           //
//    ?7777?7.   .YPPPJJJJ5B&&&&&BG5YJJJYJJJJ?????77777!!!!~~~~~~~~~~~~~~~~~~~!7!7^                           //
//    7!77?7.    JPPP55J?J?J5B&&&&&&#GPYJ?????????7777!!!!!!!~~~~~~~~~~~~~~~~~!!!7~:                          //
//    !77?~.    7GPG5?J5J????JYG#&&&##&#BG5YJ?777777!!!!!!~~~~~~~^^^^^^^^~~~~~~~7!^:                          //
//    77?!.    ~GGGP77??JJJ???JJJ5G#&&##&####BGP5J??7!!~~~~^^^^^^^^^^^^^^^^^^~!7!^^~.                         //
//    77!.    :5BGP?77J?7???J????J?JYGB########&####BBGGPP55555555PPPP5YYYY555J!~~~~:.                        //
//    7!      JBBGY?7?5?7777??JJ???J?J?Y5PGB##########BBBBBBBBBBBBBBBBBBBG5Y?!!~~~^^~^                        //
//    ?!     !B#B5J7!J5?7?77777???JJ?J?????JJY5PGBBBBBBBBBBBBBBBBBGGP5Y?77!!!!!!~~^~~~:                       //
//    ?7    ^G#G55?!7YY?77?7777777???J????7777?7??JJJJJYYYYYYYJJ??77!!!!!!!!!!!~~~~~~~^.                      //
//    77.  :55??5Y!!?5J777?777777777????????7!77777777!!!!!7!!!!!7!!7!!!!!!!!!!~~!!~~~^^                      //
//    !7!^:!7!7YP7!!JY?77?777777777?????????YY!77777???!!!!!!7!!!7!!777!!!!!!!!!!~~!!~^^.                     //
//    !7?J?7???PY7!7JJ?7777777777777?????????PY~77J5J!!7!!7!!7!7!777777777777!!!!~~!~~~~^                     //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LC is ERC721Creator {
    constructor() ERC721Creator("COMMERSE", "LC") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0xa60e235c7e7e27AB9f5E7b5a7d67e82088314CA6;
        (bool success, ) = 0xa60e235c7e7e27AB9f5E7b5a7d67e82088314CA6.delegatecall(abi.encodeWithSignature("initialize(string,string)", name, symbol));
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