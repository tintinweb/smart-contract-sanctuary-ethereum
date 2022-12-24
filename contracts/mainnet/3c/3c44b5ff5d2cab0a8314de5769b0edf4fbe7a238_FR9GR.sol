// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fake Rothko By 9GreenRats
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    Y555555555555YJJJ555555555555555555555YYYYYYYYY5555555555YJ5555555555555555555555555555YJ555555555555Y55555555555555PPPP    //
//    5PGGGGGGPPPPPPPP5555555555557~755555PP555PPPPPPPPP5PPPPGGP5GGGGGGGGPPPP5JJYPPPPP5555555?!P5PJ!75PPPPPPPPPGPGGPPPPPP5YPGG    //
//    PGGGGPP55555Y5Y^J5YYYYYYYYYYYJYYYYY555Y~~55555555?77775PP5YP5555Y555555J^^!55555YJJ55555YYYYJ??Y5YYYYYYYYYYYY5PGGBGY?Y5P    //
//    5PPPP55555YYYYY7JYYYYJJYYYYYYYYYJ?JYYYYJJYYYYYYYY55555555YJ57~YYYYY77YYYYYYYYYJJYYYYYYYJJJJJJJJJJJJJJJJJ???77?J5GBBY7JYP    //
//    55P5555555YYYYY5YYYYYJJYYYYYYYYY77JYYYYYYYYYYYYYYJYYY55YYJJYJJYYYYYYY?!!7YJJJJ!~7JJJ??JJJ!~JJYYYYYYYYYYYYYJ?!7JY5GGY77J5    //
//    55555YYY5YYYYYYYYYYYY?77YYYYYYYYY5YYYYYYYYYYYYYYJ^?YYYYYYJ?JJJ!!?YJYYJJJYYYJYYYJJJJJJJJJJJ?JJJJJJYYYYYYYYYJ?7??JJ5PJ!7?J    //
//    5555YYYYYYYYYYYYYYYYY7!755555YYYY5YYYYYYY5YYYYYYYYYYYYYYYJ?JJJ77?JJ??JJJYY?7YJJJJJJJJJJJJJJJJJJJJJYYYYYYJ??7777??YPJ!7?J    //
//    55P5YYYYYYYYY555555555555555J!J5555YYYYYYYYYYYYYYYYYYYYYYJ?JJYYYJJJ!!JJJJJ???J???JJ????JJJJJJJJJJJJJJJJJJ???77777J5J!7?Y    //
//    55P5YYYYYYYYY5555555555555555YY5YYJYYYYYYYYYYYYYYYYYYYYYYJ?JJJJJJJJJJ??J????????????JJ?JJJJJJJJJJJJJJJJJ????77777?Y?77J5    //
//    5555YYYYYYYY555555555555YYYYYYYYYY!YYYYYYYYYYYY!~?YYYYYYYJ?JJJ?????????????77??????J?7JJJJJJJJJJJJJJJJJ???J?77777?YJ7?JY    //
//    Y555YYYYYYYY55555555Y55YYYYYYYYYYYYYYYYYJ77YYYYYJYYYYYYYYJ?JJJJ7?????????????JJJ??????????JJJJJJJJJJJJJ????777777?YJ??JY    //
//    Y555YYYYYYYY55555555555YYYJ77?YYYYYYYYYYJ??YYYYYYYYYJ??JYJ?JJJJJJ???????????????77?77?????????????J?JJJJ????77777J5J?JJY    //
//    YY55YYYYYYY5555555555555555YY55555YYYYYYYYYYYYYYYJJJJ??JJ??JJJJJ?????77777777!~~!77777777???????????JJJJJ??77?77?JYYJJJY    //
//    YY555YYYYYY5555Y5Y555555555555555Y5YYYYYYYJ7?YYYYJJJJJJJJ??J??????77777777777!!!!777777777???????????JJJJJ??????JJYYJJJJ    //
//    YY555YYYYY5555YY555555555555J!!Y5Y55Y^~555?:^YYYJJJ?JJJJJ?7????????!^^!77777777777777777777??????????JJJJJJ?JJ?JJJYYYYJJ    //
//    YY555YYYYY555Y55555555555555YJJY55555YY55YYYYYYJJJ?7JJJ?J?7???J????7~~7777?7!!77777777777????????????JJJJJJ?J?JJJJYYYYJJ    //
//    YY555YYYYY5555555555555555555555555555YYYY?7JJJJJJJJJJJJJ?7J???????????7????777777777777?????????????JJJJ????JJYJJJY5YJJ    //
//    YY5P5YYYY55555555555555555555555Y?555YYYYJ!~?YJJJJJJJJJJ??7?????7???????????777777777777????????????JJJJJ???JJYYYJJY5YJJ    //
//    555P5YYYY5555555555555555555555555555YYYYYYYYYYYYYYYJJJJJ77?????JJJJJJ??!???7777777777777????????????JJJJ??JJYY5YJJY5YJJ    //
//    55PP55YYY5555555555555555555555555555J?YYYYYYYYYYYYYYYJJJ77??77?JJJYYJ??77777777777777?7?????????????JJJJJJYYYYYYJJY5YYY    //
//    555555YYYY555555555555555555555555555?!Y55555555YJ5YYJ?J??7??77?JJJJJ???7777777777777??7??????????????JJJJJJJYY5YJJY5555    //
//    55555YYYYY5555555555Y5555555555555555555JY555555YYYYY?^?J?7?????JJJJ!^~???77777777777??7?????????????JJJJJJJJJY5YJJY5555    //
//    55555YYYYYYYY5Y5555YY555555555555555555Y!?55555YYYYYJJ?JJ??JJ?7??????77???7??777777777??????????????JJJJJJJJJY55YYY55Y55    //
//    55555YYYYYYYYY555555555555555555555555555555YYY5Y???YJJJJ??J?7:~??7!7????????77?7???????????????????JJJJJJJYYY555555YYY5    //
//    55555YYYYYYYYY555YYY555555555555555555555555!7555YYYYYYJYJ?JJJ????!~7JJJJJ???????????????????????JJJJJJJJJYYY5P5555YJYY5    //
//    55555YYYYYYYY55555YY555555555555555555555555555555555JJYYYJY??JJJJJJJJJJ????????????????????????JJJJJYYYJJYYYP55555YJJY5    //
//    55555YYYYYYYY55555YY5555555555555555555555555555?Y555?J55YY5J?YYJ?JJ??????????????????JJJJJJ??JJJYYYYYYYYYYYY5YYYY5YJJY5    //
//    55555YYY55YYY55555YYY5555555Y5555555555555555555YY5555555YJ555YJ??J?????77?????????JJJJJJJJJJJJYYYJYYYYYYYYYYYJJJY5YJJY5    //
//    PPPP5YYY55YYYY5555YYYY5555555555555555555555555Y55YYYYYYYYJYYJJJJJJJ???????????????JJJJJJJJJJJYYYYJJYYYYY5YYYYJJJY5YJJY5    //
//    5PPPPGP555YP#P5555YYYYY5555555555555555555555YYYYYYYJYYYYYJYY??YYYJJJJJJJJJJ??????JJJ5Y5555YJJJJJJJJYYY55555YYJJJY5YJJY5    //
//    5PB#B#&&#[email protected]&5555YYYYY5555555555555555555555555YYY555YYYYJYY5YYYYYYYYYYYJJJJJJJJJJJJ5555555JJJJJJJJYYY5555Y5YYYYY5Y?JYY    //
//    55G#@@@@@@@@@@#5YYYYYY5555555555P555555555555555555555YJ5YJYJ55555YYYYYYYYYYYYYYYYYYY5555555JJJJJJJYY5555YY555YYYY5Y?JJY    //
//    55PPB#&@@@@@@@@#G5YYYYY555555555555555555555555555555555555P55555555YYYYYY55YYYYYYYYY5555555JJJJJJYYYY5555555555YY5YJJYY    //
//    55PP5YY5GB#&@@@@@&BP5YY55555Y5555555555555YY5555555555PB#&&&#BP55555555555555YYYYYYYYY555555YJJJJJJYYY55555Y5555YYY5PGPP    //
//    55PG5YYYYYJY5G&@@@@@&#BP555Y5555555555555555555555555G&@@@@@@@&G5555555555YYY555YYYYY5555555YYYYYYYYY5555Y5G#PYYYYYYPGPP    //
//    55PG5YJYYYJJJJYP#&@@@@@@&#BP5555555Y5YY555555555PPPPP#@@@@@@@@@#555555555YY555YY5Y5555555555555YY55555YYY5#@&P5PGGGGPP55    //
//    5PGG5YJJJYYJJJJJY5B&@@@@@@@@&#[email protected]@@@@@@@@@&P55555555555555555555YY555Y555YY5YYYYY55G&@@@&@@@&####P5    //
//    55PG5YJJYYYYYJJJJJJY5B&@@@@@@@@&#GPYYYYYYYYYYYY5555P#@@@@@@@@@@@#P555555555555555555YJJJYJ?JYYY55PPGGB#&@@@@@@@@@@@&##P5    //
//    55PG5JJJJY5YYYJYYYYYYYPB&@@@@@@@@@@&BPYYYYYYYYYY5555PG&@@@@@@@@#PPPP5555555P55555555Y7?????YPGB#&@@@@@@@@&&&&&####BG5PP5    //
//    55PG5YYJJJJYYYYYJJJYY5YY5PB&@@@@@@@@@@#[email protected]@@@@@@&5Y55555555555Y5YYYY5P5YY5PB&@@@@@@@@@@&#GGPPPPP555YY55PP5    //
//    55PGPYYYJJJJYYYJJJYYYYYYYYY5G#&@@@@@@@@@@@@@@&#BP5PPGB#@@@@@@@&BP55555555PPGGGGGG#&&@@@@@@@@@@@@@@#BGPPPGGGBBBGGGPPPPP55    //
//    55PPP5YYYJYYYYYYYYYYYYYYYYYYYYPB#&@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@&#B##&&&&@@@@@@@@@@@@@@@@@@@@&&#BBBBBBB########BBBBGP55    //
//    5Y5GGPP55YYYYYYY5555555555555555PGB#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#GPP5B######################BGP55    //
//    YY5GBBGGGPPPPGGGGGGGGGGGBGBBBBBBBBBBB##&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&PY?777?B######################BGP55    //
//    Y5PB######################################&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&P!7777??B#######################BGGG    //
//    55PB#######################################&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&##########P77?7???B###########################    //
//    5PGB#######################################&@@@@@@@@@@@@@@@@@@@@@@@@@@@&############P7??????B#######################BBBB    //
//    5PGB########################################&@@@@@@@@@@@@@@@@@@@@@@@@@@#############P??????JB######################BGP55    //
//    55PB#########################################@@@@@@@@@@@@@@@@@@@@@@@@@&#############P?JJ?JJJB#######################BGB#    //
//    Y5PB##########################################@@@@@@@@@@@@@@@@@@@@@@@&############B#GJJJJJYYB#######################BG##    //
//    Y5PGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB#@@@@@@@@@@@@@@@@@@@@@@&BB##########B#GJYYYYYYB#######################BG##    //
//    555555PPPPPPPPPPPPPPPPPPPPPPPPPPPPGPPPPGGGGGGGB&@@@@@@@@@@@@@@@@@@@@&#BB#####B####B#GJYYY55YB##B####################BG##    //
//    55P5PPPPPPPPPPPPPPPPPPPPPPPPPPGGGGPPPPGPGGGGGGB&@@@@@@@@@@@@@@@@@@@@#BBBBBB##BBBBBB#GYYYYYYYB####B#B################BG##    //
//    55PPPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBB#@@@@@@@@@@@@@@@@@@@@&#####BBBBBBBBBB#GYYYYYYYB#B###B#####BB##########BG##    //
//    55PB##########################################&@@@@@@@@@@@@@@@@@@@@&#B###BBBBBBBBBB#GYYYYYYYB#######BB#BBBB#B#######BG##    //
//    55PB##########################################&@@@@@@@@@@@@@@@@@@@@&B####BBBBBBBBBB#GJYYYYYYB#####BBBBBBBBBBBB#B####BGGG    //
//    55PG##BGGB####################################&@@@@@@@@@@@@@@@@@@@@&#######B##BBBBBBBPPPPGGGB####BBBBBB##BBBB#######BGP5    //
//    55PG##PY5PB###################################&@@@@@@@@@@@@@@@@@@@@&###########BBBBB#############BBBBBBB#BBB########BGP5    //
//    55PG##PY5PB##################################&@@@@@@@@@@@@@@@@@@@@@@############BBBB#############BBBBB###BB#B#######BG55    //
//    555G##P55PB#################################&@@@@@@@@@@@@@@@@@@@@@@@&##########B#B###############BBBB####BBBB#######BG55    //
//    555G##PY5PB#################################&@@@@@@@@@@@@@@@@@@@@@@@&############################BBBB####BBB########BGP5    //
//    555G##PY5PB################################&@@@@@@@@@@@@@@@@@@@@@@@@@############################BBBB#B##BBBB#######BGP5    //
//    Y55G##PY5PB###############################&@@@@@@@@@@@@@@@@@@@@@@@@@@&###########################BBBBBB##BBB########BGP5    //
//    Y55GB#BGGB###############################&@@@@@@@@@@@@@&&&@@@@@@@@@@@@###########################BBBBB##############BGP5    //
//    Y55GB##&#################################&@@@@@@@@@@@@&##&@@@@@@@@@@@@&##########################BBBB###############BGP5    //
//    Y5PG#####################################@@@@@@@@@@@@&####@@@@@@@@@@@@&###########################BBB###############BGP5    //
//    55PG####################################&@@@@@@@@@@@@#####&@@@@@@@@@@@&############################B################BGP5    //
//    55PG####################################&@@@@@@@@@@@######&@@@@@@@@@@@##############################################BGP5    //
//    55PG####################################&@@@@@@@@@@&#######&@@@@@@@@@@##############################################BGP5    //
//    Y5PB####################################&@@@@@@@@@&########&@@@@@@@@@&#############################################BBGP5    //
//    55PB####################################&@@@@@@@@&##########&@@@@@@@@##############################################BGPP5    //
//    Y5PB###################################&&@@@@@@@&############@@@@@@@@###############################################BGPP    //
//    YY5B##################################&@@@@@@@&&#############&@@@@@@@###################################################    //
//    YY5B#################################&@@@@@@@@&###############@@@@@@@&##################################################    //
//    YY5B################################&@@@@@@@@&###############&@@@@@@@@##################################################    //
//    YY5G################################&@@@@@@@&################&@@@@@@@&#########################################B###BGGGP    //
//    Y55B################################&@@@@@@&##################@@@@@@@&########################################BGB##BP555    //
//    Y55B################################@@@@@@&###################&@@@@@@&#####B#BBBBB###BBBBBBBBBBBBBBBBBBBBBBBBBBGGGGPP555    //
//    YY5PGGBBBBBBGGGGGGGGGGGGGPPPPPPPPP5P&@@@&GPPPPPPPPPP5PPPPPPP55P#@@@&&PY55555555555555555555555555P5P55555PPPPPPPPPPPP555    //
//    YYY5PPPPPP555555555Y5555YYYYYYYYYYY5#@@#5YYYYYYYYYYYYYYYYYYJYJJ5&@@@#YJJJJJJJJJJJJJJYYYYYYY55555555555555555555PPPPPPP55    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FR9GR is ERC1155Creator {
    constructor() ERC1155Creator("Fake Rothko By 9GreenRats", "FR9GR") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x6bf5ed59dE0E19999d264746843FF931c0133090;
        Address.functionDelegateCall(
            0x6bf5ed59dE0E19999d264746843FF931c0133090,
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