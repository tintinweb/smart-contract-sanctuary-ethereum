// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Back on it
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    GB#BBBBB#####GJ7~:.......!7........^[email protected]@B!.5P!7Y5?75B&B5:.....................:^JGBG#@#GGPPPPPGBGB#    //
//    ##BBBB###GY7!^:........^[email protected] .5GJ^ 7BGP!~P&?.!77~::G57^:...................:[email protected]&&@@@@&&&&#GPPGGGG    //
//    #BB###PY?~...........:^?P5&&^ 7PY#?~5PP7 .^^.  :~?Y~ ..................:^77GB#BGJ7^[email protected]@&&&@#GPPGBB5PG    //
//    #BGYJJ~.............. !PP5G&G..PY^?PY!P7 .....75PPP~......~JYY7..:^[email protected]&[email protected]&&&@@@B5GB    //
//    5?!^:......^~7Y!...  .JPY75P#7 :^~P5::5Y.....JPPJJPJ:...:?P575J^~7Y5B5J!~^[email protected]@@@@@@@&&@@    //
//    ::.. ^7~..:5J?P5~.~Y7~PP7^!5PY^ :5Y^ .YP^  .JP5!.7PY:..!5PJ::55PB&B5#GJ5P5GGGBBBG#Y7Y77Y&@@@@@@@@@@@    //
//    ..:!P&@5..~PJ.!5P?P#7?PY::.^5P5!7P~ ..?P? :YP7. .YP!.:?PYJ?:[email protected]@B?&5Y55P5B#[email protected]@@@@@@@@@@@    //
//    .7#@&P!...~PY?~^JPPGYY5^... !PPP5Y....?PY^YP7. .^P5~75P?JY?:JPG#&@B?JJY5PP!GBP5YJ?~?PB:[email protected]@@@@@@@@@@@    //
//    .^P#5. ...!P55Y?^!5P5PY......7PPP?.:!~!PP55!  .:7P5JPJ~J55J:Y5#@@@575PJ55!:PGP5YG!!##Y:[email protected]@@@@@@@@@@@    //
//    .~55P5^ ..7PP?7~:.:?PPY:......~Y5^^7!!.Y5?^:!?J7?PPJ~^[email protected]#YYPJ~7P? [email protected]!PY!75&@@@@@@@@@@@    //
//    .Y5^~??!: ?PP?::....7PP7...:~~!P!..^!^:^7!YP#&&?7PY7JJPPGB#5PJJYJ5Y7:~55:^PGGB#&&&GJ7~77#@@@@@@@@@@@    //
//    !P7   ~YY?YP5Y#^....^7!~!..~7!5Y!^..:!?5B&&&&&&#GB#BGP#&&@#PP~^JPY7Y^YP!^G##BPY5#@@&[email protected]@@@@@@@@@@    //
//    JP^ ...~?Y5P5Y7..:..~!J5^...:?5^^~7YG&@@@&&&&&&&&&&&PYBGGBGPY!YJYGGGPPY:G&[email protected]@&#&?^GB#&@@@@@@@@    //
//    J5:.... :^?PYJ^..55:!?BJ!:...??5B#&@@&&&&&&#&&&&&&&@G5&#G55PP5J~YGBGPP7^Y7?55??5PPJ?5&B.JJ?7JB&@@@@@    //
//    JY....... !P7....:PGJG7~^^^75B#@@&&&&&&&&&&&&&&&&&&@PP&@&&BB###BGG5PP57~?YP!.~55?YB&@@G~5&&#[email protected]@@@@    //
//    YP: ......:J~......5&?:7PB&@@@@&&&&&&&&&&&&&&&&&&&&&##&&&&@@&&&&&G:~Y5YPGB? !5P#@@@@@5^5G#@@@@@@@&&&    //
//    !5^ ..............~?JGGBBBBB######&&&&&&&&&&&&&&&&&&&&&&@@&&&&&&&&7 [email protected]&?.7PP#@@&&@[email protected]@@#&&&&&    //
//    .^:............:^^^~~^:::::~J55PG##B&@&&&&&&&&&&&&&&&&55P#@&&&&&&@#^ :G#! 7PP#@@@&@B!#@@@[email protected]@&&&&&&    //
//    . .........:^^^^:.   .:^^::. ..:^7PGG#@&&&&&&&&&&&&&&5YP5Y5#@&&&&&&J .~:[email protected]@@&&&[email protected]&&&@&[email protected]&&&&&&    //
//    ........^!YJ!^.  :75GBBBGGP5Y: :^ ^G#PBBBGBBBBBBBB&@@#G5Y55Y5B&&&&&J . [email protected]@&#B&@@&&&&&&5&&&&&&&    //
//    .... ^?P##?^.. .J#@&&&BGBB&Y#5 :~. [email protected]&&&&&GPBGGGPPPJJYY?G&&&@5 [email protected]@&##&&[email protected]&#&@@&&&&&&    //
//    ... :[email protected]@B!:.. :G&&##BBGG#&G7#G.^P. !&&&&#&&&&&&&#J^^:.....:!5PB&&&&7 [email protected]@&P5B&@@#P5P&@@&&&&&&&&&&    //
//    J:  :[email protected]~^:...5&&#GPPY5B&@[email protected] ~5. ?&&&B&&&&&&&P::7~. ..:.. .!G#&&#^ [email protected]@@@#5PB#G55B&@@@&&@&&&&##&    //
//    &7 . :Y?Y^.. [email protected]#?B&^.J! ^P&&B#&&&&&&#::?^ .!?7!~7.. !B##B:.:[email protected]@@@@@&BB55P#@@@@@&&@@@##&&&    //
//    &G: ...YB?. [email protected]#7 :: [email protected]&G&&&&&&&J.!^ ^5Y7?7~J:..:5G&B.. ^&@@@@@@#GGPB&&@@@@@&&@@@&&&&&    //
//    &@P. ..!BB?~ . ~5GGPGPPGPJJ~   ^5#Y#&&G&&&&&##!.: .JJ?5J7!^.. ^#&@P . [email protected]&&@@#GB#PGBB#G#@@@&&@@@@&&&&    //
//    &&@~ ..:?#5J!.  .^7JY5YJ!:. .~?#@BYB&&G&&&&#&&~ ..:^^~?!::... Y&&@?  [email protected]&&&#GG#BP&@G5#&G#@@@&@@@&&&&&    //
//    &&#~ ..!GBGJJ7^..      ..^7YB&&&&J!#@&G&&&&&&@Y .:^~^^~~::.. 7&&@Y. ~&@@#PG#&PG&@&PP&@G#@@@&@@@&&&&&    //
//    B&B:..~?PP5GBGG555Y!JJ5PB&@@&&&&?  7B&#&&B#&&&&7  .^!!7~...:?GG57. ^B&&BP#@&PB&#BB5#&B&@&#[email protected]@@&&&&&    //
//    ^!J7..!JJ:.:[email protected]&&&&&&&&@P .. [email protected]&&&##&&&&Y^.     ...:7~~: .~5GP5G&@@P5GBB#@GPB##BGGB&@@@&&&&&    //
//    :::^. :?GP^   ..^~..!&&&&&&&&&&! ... :[email protected]&&&&&&&&@BJ:.:^..:~!^.  :?^:7BB&@@@##&@5^7PBGBBB#&@@@@@&&&&&    //
//    ^::^:. ~YBG!:  .~!7^.J&&&&&&&&#: .::. :[email protected]&&&&&&G5??^.:~^^~!^..:~55.  7&@@@@@@@#:  J#PPPB&#@@@@@@&&&&    //
//    ^^^^!^ .~75B5^^.  7~.^5#&&&&&@5 . ^7 . :[email protected]&&#Y?^^^::?PY~..  :7YGBB^ . [email protected]@@@@@@Y . JGPPP5!^7&@@@@@&&&    //
//    ^^~^^^.. .JPJ777~:...:!G&&&&@B~ . :Y::. ^[email protected]#5:  :?PPPJ7:...:Y5G#B&! .. [email protected]@@@@@? . 7P5P5~  .5&@@@@@&&    //
//    ^^^^^^: . :P55G5YJ!...:G##&&&P^ ...Y?^:. ^57~^ .:GB5^.  .....^YBB&Y :.. [email protected]@@@5....!JJ~... ~&@@@@&@&&    //
//    ::^^!YP~ . .^:!PGGJ...?5B&#5?Y^ ...:^.... .7P! ..7!. .~7. ^Y7:.^?BG ^!.. YG5!....:~..:^..:[email protected]@#[email protected]@&&&    //
//    ::~5B##J .. ....?BG. .G&5PBP~G?^. .:^:..   Y&! ...  :?GB7 .!BB5!..~..5?.  .:7Y~  .:!?!..:[email protected]&?:^&@@@&    //
//    ::!PG#B7~...  ...~!. ^[email protected]?:JGPBGGP5!B#BGPY7Y&@7 . .7J7GGBBJ. :?#&BJ^.^B&PYJP#5^  :7?~..^[email protected] [email protected]@@&    //
//    :!7YBBPP?^.:::.. . . ~#&B~?G#B&&&&5#GG&@&[email protected]@&##BBBP7: .7P&&B&@@@@@@@P7JJ!:.^7J5YJYY:...#@&@&    //
//    ~7^Y#PBG?:::~7~:::.. :[email protected]@BJG&&&@@@@&#BBBPJ7?^ [email protected]##BGGG5!  ^JPB#&&&&&&@@@7  .??~:    .. :&@@@@    //
//    7^^JPGBP5::::?J^5Y~ ..^77?~7??JJJJYJJ??7!^^~:.....^75G&5YJ????~.    .!#@&&&&&&&#?^^:::~?P5P7  [email protected]&#@@    //
//    77:^5PBG5~~^:~!~GP~ ..                      ....?PB&@@P7     .^7??7JG#&@@@&@@@@@@@&BGPGGGPJ. [email protected]#G&@    //
//    ??7^?G##5:!Y5??5BY^...:?J7..~!: ~?J5~ :~:::::. :G&@&&&&#Y~.  .:7?JY5G#@&B#&#&&PY?!^:.......:7#@@&B&@    //
//    [email protected]&&&&&5 ..:[email protected]&^ [email protected]! [email protected]&@P..::!7JY: ~&&&&&&&&@&BY?^:..   .:7PPG#P?^   .:^[email protected]@@@#&@    //
//    55YGBBB#B#&&&&&&&@[email protected]&~ [email protected]&&&~ ^P##&?  ?&###&&&&&&@@@BPB5?J~   ^:?5^. .75G5JJ55B&#PPP#@@@&#&    //
//    P5PBBGB&#&&&&&&&&&B....7&@! ~&B: [email protected]&&J [email protected]##&J~ 7###&&&&&&&&##BPBGG7:...!7GJ^: !#&#5JJY5B&[email protected]@@@&&    //
//    5PGGBPB&&&&&&&&&&&&~ . J&@7 [email protected]~ [email protected]@G ^&@@@P? :[email protected]@@&&&&&&&GBBBPY~~^~..PPPPJ: !###PPPPYB&GPPP#@@@@&&    //
//    PGBBBBB#&&&&&&&&&&@? . ?BB7  7&7  J&#G:.YYJJ~: .P&###&&&&&P5BB57:!YY7 .^[email protected]&J. !BBB5YYYYPG5YYYB##&@@&    //
//    PGBBBBB#&&&&&&&&&&@G^   ... ....  .:.. ...^^7JJPBBGBBBBBBY!5G!:?PB##? .~7B&J  !GBB55555G#P55PBGPPG&&    //
//    5GBBBBBGB&&&&&&&&&&&GJ?77?!^...:~7??7JJJ5PGGB##BPBBBBBBG5!!?:^5P####J. J#PP5. !P#&GP5P55#PPPG##BG55&    //
//    5GBBBBY~?PG#&&&&#GGGB&&&&P5GPGG#&&BBGY&####BBG5JYBBGP5JJ5Y^:?BBG#B##Y. [email protected]@@G. ^GPGB5?55~PP?5G#BB5YY&    //
//    BBBBB?^:7YPB###PPB#GY7!~~:~75#@@@#BBP7JJ??777!.^5PYYJJJY7:^5BBBGB#BY?. [email protected]&@5...~B#[email protected]    //
//    BB#G7:^~J5GPYYYPBJ~~7YGBBBGJ~:!PBPP5Y55PPGGP57?^:^!!~:.^.:?BBBGG#PYG5  [email protected]&@Y. ?7^G&B5YYJ~JYYY5PY?JY&    //
//    BB5~:^^[email protected]@@@GY77G&&######&&&###BY~.!PY~:?JPBB#G5J5##7  [email protected]@&! .J#!^G&GPPP77P55G&GJ??5    //
//    B?^::^YB5!5##?^YP5GG#@@@&P?~:JGGGGY?YG&&&@@@@&&B#BJ.7&#77&&#&#PYG##B:  [email protected]@B:..5##!:G#PPP5^JPPG##P?77    //
//    !:^^^Y#G??&B~?#@&@@@&B57^~JG5J?J~JB#P?7?5PG#&#P?!?5J [email protected]~#@@&&##&##P.. [email protected]@5..^5##B^~#BPPPJ!?PPGB&G?~    //
//    :^^~5##PJPB~?BGGGPY7~^!?^G#BBBBB7?PPBBG5!~~^:^^^::^:.^[email protected]@@&@@&&&? . [email protected]&?. !5###5.?#GPPPB5?55PGBG7    //
//    :^75###G757:^^::::.::!77:~!!!!~!^^!~!7?Y!^?J?JY?~^::!.:?7B&#&&&&&&#^ [email protected]&!  !5####~:PG5Y5PBBPGGPGBB    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BOI is ERC1155Creator {
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