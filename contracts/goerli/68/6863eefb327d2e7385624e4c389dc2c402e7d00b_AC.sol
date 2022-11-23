// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: COLLIGNON-MINT-TECHNOLOGIES
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////
//                                                                      //
//                                                                      //
//                                                                      //
//    ░█▀▀█ █▀▀▄ ▀▀█▀▀ █▀▀█ ░▀░ █▀▀▄ █▀▀ 　                              //
//    ▒█▄▄█ █░░█ ░░█░░ █░░█ ▀█▀ █░░█ █▀▀ 　                              //
//    ▒█░▒█ ▀░░▀ ░░▀░░ ▀▀▀▀ ▀▀▀ ▀░░▀ ▀▀▀ 　                              //
//                                                                      //
//    ▒█▀▀█ █▀▀█ █░░ █░░ ░▀░ █▀▀▀ █▀▀▄ █▀▀█ █▀▀▄                        //
//    ▒█░░░ █░░█ █░░ █░░ ▀█▀ █░▀█ █░░█ █░░█ █░░█                        //
//    ▒█▄▄█ ▀▀▀▀ ▀▀▀ ▀▀▀ ▀▀▀ ▀▀▀▀ ▀░░▀ ▀▀▀▀ ▀░░▀                        //
//    ┌─────────────────────────────────────────                        //
//    │ Minting trippy crypto arts since 2021                           //
//    └──                                                               //
//    _________ad88888888888888888a,                                    //
//    ________a88888"888888888888888888,                                //
//    ______,8888"__"P8888888888888888888b,                             //
//    ______d88_________`""P888888888888888,                            //
//    _____,8888b_______________""888888888888,                         //
//    _____d8P'''__,aa,______________""888888888b                       //
//    _____888bbdd888888ba,__,I_________"88888888,                      //
//    _____8888888888888888ba8"_________,8888888b                       //
//    ____,888888888888888888b,________,8888888888                      //
//    ____(88888888888888888888,______,88888888888,                     //
//    ____d888888888888888888888,____,8___"888888b                      //
//    ____88888888888888888888888__.;8'"""__(888888                     //
//    ____8888888888888I"8888888P_,8"_,aaa,__888888                     //
//    ____888888888888I:8888888"_,8"__`b8d'__(88888                     //
//    ____(8888888888I'888888P'_,8)__________888088                     //
//    _____88888888I"__8888P'__,8")__________880888                     //
//    _____8888888I'___888"___,8"_(._.)_______808888                    //
//    _____(8888I"_____"88,__,8"_____________,8888P                     //
//    ______888I'_______"P8_,8"_____________,88808)                     //
//    _____(88I'__________",8"__M""""""M___,8888988'                    //
//    ____,8I"____________,8(____"aaaa"___,888888                       //
//    ___,8I'____________,888a___________,888888)                       //
//    __,8I'____________,888888,_______,888888888                       //
//    _,8I'____________,8888888'`-===-'888888888'                       //
//    ,8I'____________,8888888"________88888888"                        //
//    8I'____________,8"____88_________"888888P                         //
//    8I____________,8'_____88__________`P888"                          //
//    8I___________,8I______88____________"8ba,.                        //
//    (8,_________,8P'______88______________88""8bma,.                  //
//    _8I________,8P'_______88,______________"8b___""P8ma,              //
//    _(8,______,8d"________`88,_______________"8b_____`"8a             //
//    __8I_____,8dP_________,8X8,________________"8b.____:8b            //
//    __(8____,8dP'__,I____,8XXX8,________________`88,____8)            //
//    ___8,___8dP'__,I____,8XxxxX8,_____I,_________8X8,__,8             //
//    ___8I___8P'__,I____,8XxxxxxX8,_____I,________`8X88,I8             //
//    ___I8,__"___,I____,8XxxxxxxxX8b,____I,________8XXX88I,            //
//    ___`8I______I'__,8XxxxxxxxxxxxXX8____I________8XXxxXX8,           //
//    ____8I_____(8__,8XxxxxxxxxxxxxxxX8___I________8XxxxxxXX8,         //
//    ___,8I_____I[_,8XxxxxxxxxxxxxxxxxX8__8________8XxxxxxxxX8,        //
//    ___d8I,____I[_8XxxxxxxxxxxxxxxxxxX8b_8_______(8XxxxxxxxxX8,       //
//    ___888I____`8,8XxxxxxxxxxxxxxxxxxxX8_8,_____,8XxxxxxxxxxxX8       //
//    ___8888,____"88XxxxxxxxxxxxxxxxxxxX8)8I____.8XxxxxxxxxxxxX8       //
//    __,8888I_____88XxxxxxxxxxxxxxxxxxxX8_`8,__,8XxxxxxxxxxxxX8"       //
//    __d88888_____`8XXxxxxxxxxxxxxxxxxX8'__`8,,8XxxxxxxxxxxxX8"        //
//    __888888I_____`8XXxxxxxxxxxxxxxxX8'____"88XxxxxxxxxxxxX8"         //
//    __88888888bbaaaa88XXxxxxxxxxxxXX8)______)8XXxxxxxxXX8"            //
//    __8888888I,_``""""""8888888888888888aaaaa8888XxxxxXX8"            //
//    __(8888888I,______________________.__```"""""88888P"              //
//    ___88888888I,___________________,8I___8,_______I8"                //
//    ____"""88888I,________________,8I'____"I8,____;8"                 //
//    ___________`8I,_____________,8I'_______`I8,___8)                  //
//    ____________`8I,___________,8I'__________I8__:8'                  //
//    _____________`8I,_________,8I'___________I8__:8                   //
//    ______________`8I_______,8I'_____________`8__(8                   //
//    _______________8I_____,8I'________________8__(8;                  //
//    _______________8I____,8"__________________I___88,                 //
//    ______________.8I___,8'_______________________8"8,                //
//    ______________(PI___'8_______________________,8,`8,               //
//    _____________.88'____________,[email protected]___________.a8X8,`8,              //
//    _____________([email protected]@@_________,a8XX88,`8,               //
//    ____________([email protected]'_______,d8XX8"__"b_`8,            //
//    ___________.8888,_____________________a8XXX8"____"a__`8,          //
//    __________.888X88___________________,d8XX8I"______9,__`8,         //
//    _________.88:8XX8,_________________a8XxX8I'_______`8___`8,        //
//    ________.88'_8XxX8a_____________,ad8XxX8I'________,8_____`8,      //
//    ________d8'__8XxxxX8ba,______,ad8XxxX8I"__________8___,___`8,     //
//    _______(8I___8XxxxxxX888888888XxxxX8I"___________8___II___`8      //
//    _______8I'___"8XxxxxxxxxxxxxxxxxxX8I'____________(8___8)____8;    //
//    ______(8I_____8XxxxxxxxxxxxxxxxxX8"_____________(8___8)____8I     //
//    ______8P'_____(8XxxxxxxxxxxxxxX8I'________________8,__(8____:8    //
//    _____(8'_______8XxxxxxxxxxxxxxX8'_________________`8,_8_____8     //
//    _____8I________`8XxxxxxxxxxxxX8'___________________`8,8___;8      //
//    _____8'_________`8XxxxxxxxxxX8'_____________________`8I__,8'      //
//    _____8___________`8XxxxxxxxX8'_______________________8'_,8'       //
//    _____8____________`8XxxxxxX8'________________________8_,8'        //
//    _____8_____________`8XxxxX8'________________________d'_8'         //
//    _____8______________`8XxxX8_________________________8_8'          //
//    _____8________________"8X8'_________________________"8"           //
//    _____8,________________`88___________________________8            //
//    _____8I________________,8'__________________________d)            //
//    _____`8,_______________d8__________________________,8             //
//    ______(b_______________8'_________________________,8'             //
//    _______8,_____________dP_________________________,8'              //
//    _______(b_____________8'________________________,8'               //
//    ________8,___________d8________________________,8'                //
//    ________(b___________8'_______________________,8'                 //
//    _________8,_________a8_______________________,8'                  //
//    _________(b_________8'______________________,8'                   //
//    __________8,_______,8______________________,8'                    //
//    __________(b_______8'_____________________,8'                     //
//    ___________8,_____,8_____________________,8'                      //
//    ___________(b_____8'____________________,8'                       //
//    ____________8,___d8____________________,8'                        //
//    ____________(b__,8'___________________,8'                         //
//    _____________8,,I8___________________,8'                          //
//    _____________I8I8'__________________,8'                           //
//    _____________`I8I__________________,8'                            //
//    ______________I8'_________________,8'                             //
//    ______________"8_________________,8'                              //
//    ______________(8________________,8'                               //
//    ______________8I_______________,8'                                //
//    ______________(b,___8,________,8)                                 //
//    ______________`8I___"88______,8i8,                                //
//    _______________(b,__________,8"8")                                //
//    _______________`8I__,8______8)_8_8                                //
//    ________________8I__8I______"__8_8                                //
//    ________________(b__8I_________8_8                                //
//    ________________`8__(8,________b_8,                               //
//    _________________8___8)________"b"8,                              //
//    _________________8___8(_________"b"8                              //
//    _________________8___"I__________"b8,                             //
//    _________________8________________`8)                             //
//    _________________8_________________I8                             //
//    _________________8_________________(8                             //
//    _________________8,_________________8,                            //
//    _________________Ib_________________8)                            //
//    _________________(8_________________I8                            //
//    __________________8_________________I8                            //
//    __________________8_________________I8                            //
//    __________________8,________________I8                            //
//    __________________Ib________________8I                            //
//    __________________(8_______________(8'                            //
//    ___________________8_______________I8                             //
//    ___________________8,______________8I                             //
//    ___________________Ib_____________(8'                             //
//    ___________________(8_____________I8                              //
//    ___________________`8_____________8I                              //
//    ____________________8____________(8'                              //
//    ____________________8,___________I8                               //
//    ____________________Ib___________8I                               //
//    ____________________(8___________8'                               //
//    _____________________8,_________(8                                //
//    _____________________Ib_________I8                                //
//    _____________________(8_________8I                                //
//    ______________________8,________8'                                //
//    ______________________(b_______(8                                 //
//    _______________________8,______I8                                 //
//    _______________________I8______I8                                 //
//    _______________________(8______I8                                 //
//    ________________________8______I8,                                //
//    ________________________8______8_8,                               //
//    ________________________8,_____8_8'                               //
//    _______________________,I8_____"8"                                //
//    ______________________,8"8,_____8,                                //
//    _____________________,8'_`8_____`b                                //
//    ____________________,8'___8______8,                               //
//    ___________________,8'____(a_____`b                               //
//    __________________,8'_____`8______8,                              //
//    __________________I8/______8______`b,                             //
//    __________________I8-/_____8_______`8,                            //
//    __________________(8/-/____8________`8,                           //
//    ___________________8I/-/__,8_________`8                           //
//    ___________________`8I/--,I8________-8)                           //
//    ____________________`8I,,d8I_______-8)                            //
//    ______________________"bdI"8,_____-I8                             //
//    ___________________________`8,___-I8'                             //
//    ____________________________`8,,--I8                              //
//    _____________________________`Ib,,I8                              //
//    ______________________________`I8I                                //
//                                                                      //
//                                                                      //
//                                                                      //
//////////////////////////////////////////////////////////////////////////


contract AC is ERC721Creator {
    constructor() ERC721Creator("COLLIGNON-MINT-TECHNOLOGIES", "AC") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x03F18a996cD7cB84303054a409F9a6a345C816ff;
        Address.functionDelegateCall(
            0x03F18a996cD7cB84303054a409F9a6a345C816ff,
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