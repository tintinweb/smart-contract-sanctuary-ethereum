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

pragma solidity ^0.8.0;

/// @title: Smears
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                  [email protected]&&@#&Y!                                                                                                  //
//                                              PB#&&#P&&@#B&B5G&&^&?5:                                                                                         //
//                                           ~J#&@@@@@B55~~G#[email protected]##^GB&&&P&J:       :.    .                                                                    //
//                                         !YP#&&@@@&7B^^GGJ#&JP5G7#@Y&5~ Y#[email protected]^B7~..  :5!^ ~^                                                                //
//                                          ~??P#&&@@B##GPJ5!?5^?PJB&^P~B!G7!#[email protected]^&@@&@@B&@&@@&Y 7~7                                                             //
//                                            !75B&@@#&BP7GBBBBBG?55J.7G&[email protected]@@@B&##B?#B?&&&@@&^!?:                                                          //
//                                              .:~7#@B!P#~5#&&[email protected]&G#G~7&B&[email protected]&#@##GG#7BP?5&[email protected]&@&BP^^                                                        //
//                                                .^P&#~^Y.^.^.!G&&#@@BP#[email protected]&@B#JPBBGP#7Y#PG&B5GB&@&&@@#B#G^                                                     //
//                                              ..!#P&&~.  ^   ^~GBG&&@@&@YB&&#G5:[email protected][email protected]&G#@&@@@@@@@&B:                                                //
//                                        !~77!7##GJ! ...:.   . :5&PGG^:75YP&@&&B?Y&#YB7P##P5Y5YB###&@@@@@#&&&@@&&JJ                                            //
//                                 [email protected]@@@@@&@&&&#@P7~5GY~::  .:7&??:.^.~^~&@@@&&BG75&#[email protected]#J&&JG#@@@&?&#@&@@@B&B#@@&5G??                                        //
//                                 #@@@@@@&@[email protected]&&@BPBG5#YJJ&J5B7J^!BGYJ:...^?Y5#5&#&[email protected]@@&&GGB##B5&B##&&@#5GG:                                     //
//                              !:~^[email protected]#@@@@[email protected]&@@@#PG5!YB7^.^!7P!7P!?^~:^[email protected]@@@@GB.?~?~!~B5#B#@@#@@G&@##&&[email protected]&@@@@&@G#G                                  //
//                                  .J&@@@@@@#&&[email protected]&&Y&.J5?7P~?Y5?#&&#&#BY7^?P&GB&@&@@#&:5:?&#&&&@@@@&&[email protected]@&[email protected]&Y#5!&!BP&@&@@@@@&P~^                            //
//                                     :[email protected]@@@PY^^[email protected]@@&@@@&&B&@&@B&@@@&5GPPP5G&B?B#&@&?P?:YY##[email protected]&@@&[email protected]^5GYG~?G##&#&&&@@&GJ                          //
//                                    [email protected]@@@&@@@[email protected]@@@@@@@&#@@@@?#@@[email protected]@@@@@J^~YYB7PG&@&G5::5G#@@55B#G##BPYG#@@&&@[email protected]#5###PGB&&[email protected]@@~                       //
//                  7P5&##&BB&GB&B#&#P#B5&@@@@@@@@@@@@@@@&B&G#@@@@@@@&Y:B&&&[email protected]&&[email protected]!B&B&&Y#[email protected]@@@@@@&&[email protected]#Y&P#JB&@&G&[email protected]@@&G.                    //
//               [email protected]@#P&B&&&@&[email protected]@&@@#Y#&@@@@@@&&[email protected]#&[email protected]@&&B&[email protected]@@@@@BG^ [email protected]@@@@#@#@@@?PBG&[email protected]&P#GB#.~G~YJGJ5P&&@@@@@@@@@[email protected]@#[email protected]@[email protected]@#J&B&&&@@@B                  //
//            G:[email protected]##BB#@5&[email protected]&@@@#@@&@@@@[email protected]@@@##[email protected]@@@@@@#[email protected]@@@@@@@&&@@@@@@@#[email protected]@#GG#[email protected]@@&&GY#P#@@7^ .5&&@@&@G&[email protected]&&&@@@&@&@&&&@P#[email protected]@&&@@P                //
//             B&[email protected]#BG.YGB##P: ^@@BY [email protected]@@@@@@&&[email protected]@@@@@BB#BP?&&@&@@&@@&@@@@@@@!  :[email protected]&@[email protected]&[email protected]@@@@@@&@@&@BB&&@@&@Y&G.:.?Y&@@@@@@@@#@@@&G#@&@&@@@@7              //
//              [email protected]@#&GP5G B~#5  [email protected]    !&@&     Y&@&@@J   YY#@@@@@#[email protected]&@@@@@@@&Y^ [email protected]@@&&#@@&&&@!?&@#@@&#&&Y&@@@#PY?G   [email protected]@@@@@@@@@@@@&@@#@@@@@@@&             //
//             :^G&@@@#&[email protected]@&&@@&P     [email protected]@&B  5##7^^       [email protected]@@@@&&&@@&@@&@&&&@[email protected]@@@G#B&@@@&@[email protected]#BJ!B?P&P&@@@@@@&^J    :#@@@#  [email protected]@@: [email protected]@&@@@@@@@@@.           //
//               .^@@@@@&@5G&@[email protected]&@@@P5P&[email protected]@@@7!: #@@J       :&@@&G^^Y   Y&@&@@#[email protected]@@@@@&   BB&@@@@@[email protected][email protected]@@@@@&#    &@@&B5. [email protected] [email protected]#  [email protected]@@@@@B?          //
//                 [email protected]@ ^[email protected]@@&[email protected]@&@@&&&@@@&@&@J&&@@@@@&#G^  ^#&&#GB      :[email protected]^&@@@@@@@@&##&B&@@@@@@@[email protected]##GY:&[email protected][email protected]#[email protected]@&&[email protected]@@&#B   [email protected]#7Y    ^[email protected]#@@@@G:         //
//                 [email protected]      @  ^@@&@&&@@@@@@@@@5&[email protected]@@&@&&&@&@@@@@@@G5P    B&~ JJB#@&J?:[email protected]@@@@@B!PBBJ5#[email protected]@^[email protected]&[email protected]&@@@##&?~  &@#7    [email protected] :@@&~^.        //
//                 [email protected]               #@@@&@@@@@#&[email protected]&@@@@&###&@@@@&#Y##@#[email protected]? [email protected]#@&&&##[email protected]@@@@@@@&~~^&YBYBBBP#5GG#G?5!GBG&&@@@@@@#:.&@Y    :[email protected]#   [email protected]           //
//                 [email protected]               ^@!P:P#@@@Y?  [email protected]@@@#[email protected]@@@@B#@#&@@@@@&@##&&@@@@[email protected]&#@@@&&[email protected]&@@@?B#[email protected]##P5&BYBJ###GP7BG#@@@@@&[email protected]&5      BG5  .&@           //
//                 @.                 .B   [email protected]@&J  [email protected]&G     [email protected]@@@&&@B&&&@@@@@@@@@[email protected]@@@&&[email protected]#[email protected]&@@&^PB!G#B##JB&G?B&@P&[email protected]&@@@@&&             Y7           //
//                @5                    @B [email protected]@@@^   #@&&      @@@@[email protected]@@@@@##@@@&@#@@@[email protected]&@@@@#&#[email protected]&&JY7&&#&5&#Y#G#&[email protected]##@YGP5&G&@&[email protected]@@5           .B            //
//                                       [email protected] @@@     #&[email protected]@.   Y&@@@@@@@@@#@&&@&&@&GG#@@@#  J&#@&&Y#@&G&&@@@##5#G&5&[email protected]#@@#&[email protected]@@@&@5        [email protected]             //
//                                        [email protected]@@5.     [email protected]@[email protected]@B   :@^[email protected]@#@@@@&@@B&G#BG&@@@&&&~?!?&@&@@@@@@@@@&&#@&#5J&&GB#^[email protected]#&&&#[email protected]@@@&B      :J              //
//                            ^B&[email protected]##&BY5 ^[email protected]@&   77#@&@@@&J     @:@@??&&@&@@&@##[email protected]@&@&&BBB#G.7^[email protected]@@@@@@@&@@[email protected]@&B&GBBYB##G&@#GGY##G&[email protected]@&@5     ?&              //
//               .^?P&@@&@@@@@@@[email protected]&@G&@@@@@@@@@&@@@@@@@@@@&@@@@@&@[email protected]@!?P#&##&&##&&@@@@&#@55BBP .:7J&@@@@@@@@@@@[email protected]@@@@@&&@@@B&G&&@@G&&@#@@@                      //
//          ^?#&@@@@@@@B&5&&&@BG#7&#[email protected]&@@##@@@@@@@#@@@@@@@&#&#B#@@@@@@^B5B&@@@#@P#&#@@#B&[email protected]#[email protected]@@@&@@@@@@@@@@@@@@@@@@@@@@@@#@@@@@@                       //
//         G&@@[email protected]@&@&&@&@&&@@@@@#G&[email protected]@&[email protected]@@@@&&#@@&@@@@@@&[email protected]&B&[email protected]@@@@&@&@&@@#@#@@#@@@@&&&5#GB#[email protected]@&G  &@G^?&&@@@@@@@@@@@@@@@@@@@@&@@@@Y                         //
//         &&@&&@@@@&&B&&&@@@[email protected]@B#@@&[email protected] .J&@@G?##@#@@@@&Y#&&#&[email protected]@@@@@@@@&GB&&&@&@@@&G5&GP&&&&&@@&@:[email protected]@ .7P&@@&@@@@@#B&&[email protected]@?.7^@@@                            //
//         [email protected]&@@@@@@@&[email protected]@@Y&@@&#@@@@@@&&@P   [email protected]:   .&@B     .&&&@@@@@@G#[email protected]#@#&[email protected]&@@@@&@Y5GY#BG&#@@@@@&Y   :G&#@@@GB?777 @@G   #JB                            //
//           [email protected]@@@@&@@@@@[email protected]@@[email protected]@@@@@@@@@@@@!   &P   @@          #@@@@@&@&~#P&[email protected]@[email protected]&&&@@#BG#G#[email protected]@[email protected]@@J:    .#@@@&PJ 7^ ^&@     ?                             //
//            :[email protected]@@@@@@@@[email protected]@@@@#@5&#@#@@@#@@@@&[email protected] [email protected]            :&&B~Y&@@&@G#[email protected]#&GB#&&#&B##&&&@&&&@@@&    :[email protected]@@@.7     G&                                    //
//               [email protected]@&[email protected]@&@@@@@@@@@&G&#@@&BB#[email protected]@@@@@[email protected]@             .#@^  [email protected]@@#[email protected]@B&&&#@B&#@@[email protected]#&@@@@@@&##@@@&!J    [email protected]                                     //
//                .&:  :@[email protected] ^@@@@@@@@@&&@@&@##[email protected]@@@@&B             #@    .&&##@&[email protected]?B#&&#&@@@@&&@&@@@@#@@@@@#::       ^@@                                       //
//                :@7   [email protected]#    [email protected]@7.&@@@@@@@@@@&@&@@@@[email protected]@@@@B      .:G~   G&   :@@@@@#@@&@@@@@@&&@@@@@&@@@@@B         #@B                                       //
//                .&     @@?    &Y  :@&[email protected]@[email protected]@&@@@@#@@G&[email protected]#&@&#G [email protected]   PB      [email protected]@@@@@&@@@@@@@@@@@@@@                                                     //
//                [email protected]    ^@[email protected]@@@@@@@@@@@B&@PG&@@@@@@#@&#GG&BB#@@##@@#@@   &#            [email protected]@@&@@@@@&@&@@@7:&                                                      //
//                      [email protected]@@[email protected]#@@@@@@@@&@@@@@@@@@@#&&&&&[email protected]@&&@@@#.7#              [email protected]@@@B  @@G&@#5&                                                        //
//                      [email protected]&@@@P5G#B&@&@@@@@@@@@@&##&&YG#[email protected]#@#@@G#@@&@@@@&              ^@@@!     &&@@?                                                         //
//                       [email protected]@@@[email protected]@#@@[email protected]@[email protected]@@@@@@@@@&@&#&@@&@@&@@&#B&@@@@@@!             :#&#      [email protected]@                                                          //
//                          &&[email protected]&@@@@&@@@&~G&[email protected]@@@##P&&&&&@@[email protected]@@@@@@@7              [email protected] [email protected]@                                                           //
//                          .J&@@@@@@@@@@B?       .&&@@@@@@&@@@@@&@@@@@@@@               7&        &@                                                           //
//                             #@@@[email protected]@GG:          ^&&?&@@@@@@@&@@@@@@@[email protected]@:              #@         &&                                                          //
//                               &@@@@@@                 [email protected]@@@@@@@@@@&[email protected]@&              [email protected]          @~                                                         //
//                               .Y&[email protected]@                  [email protected]@@@&@@@@@   [email protected]@               @          .#                                                         //
//                                &@!.#@:                  [email protected]@@@@ [email protected]@   .&@               @&         :@B                                                        //
//                                 5Y ^[email protected]^                 ^&@## :5 &@G :B.               Y&         [email protected]@                                                        //
//                                 ?G  [email protected]                 :[email protected]#7     @& B#                [email protected] [email protected]                                                         //
//                                 J   P&!                  [email protected]@      [email protected]                @@                                                                    //
//                                 ?   ?#~                  ^#@      [email protected]&                 @#                                                                    //
//                                :@    !                   &@@       @G:               :[email protected]&                                                                    //
//                                 P  7#J                  [email protected]@@      [email protected]@               [email protected]@&                                                                     //
//                                B.  7?                   :&5&      [email protected]#!             [email protected]@                                                                       //
//                               .& ^#                    .P& [email protected] [email protected]                                                                                        //
//                               Y:!?:                    .BJ   @    ^@                                                                                         //
//                              :5&.!                     #P     @?  [email protected]                                                                                         //
//                               [email protected]                     ~&     ^@@  :##                                                                                        //
//                              !& Y                    .G      :@@  ^@@                                                                                        //
//                               &                      [email protected] [email protected]@. [email protected]@#                                                                                       //
//                               &@.                    .&      [email protected]@  ^#@@.                                                                                      //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SMEARS is ERC1155Creator {
    constructor() ERC1155Creator() {}
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