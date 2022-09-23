// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Strangers
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    &WWW&&WW&&WWMWWWWWMMMz#MMMWWMMM##MWMWW8&&&&&&WWWM#M&88&&8&8&&&WWW&&&WMWW&WMMWWM#####MMMM##MMMW#MWMMW    //
//    WWW##W&W&W&&&W&&####W&WMMMMWMWWWWWWWW&&&&M##W&&&&&&88888&&&M##M&WWWW&WW&W####W&WM#M##MWM#MWWMWWMMM##    //
//    &&WMM&&&&&&&&&&&WWMWWW&&&&WWWMWWWWWWWWW&&M#M&&&&&&&&W#M&&88&WM&&&&WWMMW&WWWMW&&&MMMMMM##MMMMW&&WMMM#    //
//    WW&&&&&&&###MWW&&&&&&&M##WW&WWWWWWWMM&&8&&&&&&&8&&&&MMM&&88&&&&&&WM###&&&&W&WW&M*#MMMMMMMMWMWWWWWWW#    //
//    &8&*M&&88WMW&W&&&&WW&WM#MWWMMW###W&WMW88&&&&&&&WMMW&&&8&&&&&&&&&&&WMMW&8&&&&&&WM##MWMMM###WW&WWWWWW#    //
//    &M##M888&&&&&&&&&WWWW&W&&&WWWWM##WWWMMM##&8&&&&####WWW&&&&M##M&&WWW&&&&&W&&&&&&&&WWWWWMW#MW&&WWW##MM    //
//    &M#MW&&8&&&&8&&W##MW&&W&&8W&WMWWWWWWWMWMW8W8&W&WMWW&&&&W&WM##MWW&&&&&&&&&##M&&W&&&&WWMWMW#WWWMWMMMMW    //
//    &8&&&&&&&&&&&&WWMMWWMW&WW&WWMMWWWWMMWW&&&&&WWW&&WWWWWWW&&&&&&&&&&&&&&&&&&MMWWW&WWW&&WWWWW&WM#xWWWW&W    //
//    ##M&&8888&&&8WW&&&&W&MWWW&WM#MMMWM##MW&&&WMMWWW&&WMW&&&&&##M&&&&&&&W&&&W&W&W&WWWWWWWW&&W&&###MWWWWWM    //
//    WWW&&8&&&&&8W##W&&&WM##&WWMMMMMWWW&&WW8&&M##MW&&&###&&&&&MMM&&&&W&W&&W##W&&&WM##MWWWW&&&WW&W&W&W&WM#    //
//    8&&&&&WMW&&&&WW&&&&WMMMWMMM#MMWW&&&&&W&&Wz{1M8&&&WM&&<'lMW&&&88WMMWW&&WW&&*&&WMMWWWW##MM&&W&&&WWW&WW    //
//    &8&&&&###&8&&888&&WWWWWWWMM##MWWW##WWW&&8i  'WWW&&88"   /W&&&8/[c#MW&&&&&&WW&&&&&WWW###WW&&&WMWWW&MW    //
//    &&&&8&&&888&&&&M#MWWWWWWMMMMW&&&<  "##&&%x   ]&&&88-   iWWWWx'  ^&&&&&W&M#MW&WWWW&WW&WWW&W&M###M&WMW    //
//    &&&&&888&&&&&8WM##WWWWWWWWMM&W&8|.  ;W88%r   '+}1};    >WW&1   `vW&&&W(~n##W&&&&WW&W&&&&&&&&MMMW&&WM    //
//    &W&W&8888&W&88&8&&&&&W&&v}c##M&&8f   "]~,                .'   ,&&WW&_.  ?&&&&W&&&&&MM##W&&&8&&&&&M##    //
//    &&&&&&8M&MMW88&&&&WWM#W8\  ^|MW&8/                            "jWW{'  ^n&&&W&M#MWW&WMMM&&888&&WWWMMM    //
//    ##M&&888&M#M8888&&&&MM&8B]   `\r~.                               .  '{&&&&W&WM#W&&&&&8&&8&&###WWWWWM    //
//    M##W888&&8&8888WMM&&88888%z,                                       .W&&&#M#f}\WWWWW&&&&&&&&MMMW*#ccc    //
//    W&&&8&8&&88888M###W88%%88&W&]                                       `uW|,'   .&&&&&###M&&&&&WWW&&WWM    //
//    &&WM&&&WW&&&888WWv.'~n888WM/                                             .^~)W&&W&M###W&&M&&&W&&WM##    //
//    MMWW&&M#MW8888888%]`  .`"I;                                            'u88MMMWWWW&WW&&W&WMM&W&#MM#M    //
//    ##M&&&&&&&88888&8&W&u<"'                                               '*Mx1]<++~\##W&&&&W##&&&&&&&&    //
//    MW&&888&8&8888888&8888%%u                                                       .'nMM88&88W&MW&88&88    //
//    88&&8888&M#M888888&888%B[                       .'`.         '''         ,<_|xcW8&&&W8&88&W&W&&W###&    //
//    &&&8&&88&WW&8888&#ctjj1~.                      I*MMz"      .fWM#{.      ,8MM#&88&WWWW###&WW&W&WWM#MW    //
//    88&W&&&&888&8888&&.                            :*MMu^      '\#M*}.       :[nM&&&WWWWW##MMW#MWW&W*WMW    //
//    &&###&8&8&888&&&8%*(+i>i,                       .''.         '``            .^l(*&WMMMMWWW&WMM##W#M&    //
//    &M&WW88888W##W8888%8%8&&%{                                             '}}_!^'..<WWMMM#M##MMMMWW#W8&    //
//    8888&88888M##W8888888&#M%B^                                            ]&8W&&&&W#WWWMWM####MM#WMM&&&    //
//    88&WW88888888888WMMW8888fI                                              `<u###*MWWWMW**z*#MM&&WWMMWW    //
//    88W##&%8&88888%%M##M8Mi.                                           ';,`.   :*M#WW&WM#**zz###WMMMM###    //
//    8&8888888&WW&8%%888%%('',_tMB|.                                   ^M&&8%x;. ^8WWMW#MMMM#MMWW&W&WWWM#    //
//    &8&888888###W8%8888%%8WMM&#88%&'                                   ^|MW&8%BvW&&###M#MMWM#W&&&W&WWWWW    //
//    &&W&888888&&888&888%88&&&8888%)                               ~?I.   !&&&&&88&WWMMMMWWMM##M&8&8&#M&W    //
//    8####%8%8&88&8&8WW8888%%8888t,  't%M1"                   .    :W%8{"  ~W&WMW&&&&&WMW&&MWWWWW&&&W##&W    //
//    8&W&88%88888888&##W%%%%%88%/..`_&88%Bc.  .::'    .`^'   !B|.   .n%%BtI{8&##M8&&W&&&&8&&8&&&&&W&&MMW&    //
//    WW8888888&&88%%8&&%%%%%%%%&%%%%88W#M*.  .z8%t   ,8%B8'   n&&_.   }&8888&8WW&&&&WWW&&&&8&88W##MW&WW#M    //
//    ###888&888&88WM8%%%%8&8%%%88&&88&WW&,  `#W#W8   |WMW%r   !#M%8]'.i88&&MMW&&&&&WW&W&&88&8&8WMM&&8&8M#    //
//    &&8%%%88%888&##8%%%%###8%888888&88%%l,/%8&W&8   W###%B]  `888%%%%%8&&&##&8888M##&WW&&&&&8&888&&&&8W#    //
//    %8%%%8###&88%%8888%%8&%%%M&##M8888W8W&88888%#`':8&&8%%B};|88&88M##&88888&&&888W&8&&&###8&&&&&8888&&8    //
//    888%%%WWW8%%%%%&88%%%%%8%%&WM&&%%88WMM8888%88&%888888%8%%%88888WMW8&888%&&&&888888&8WM#W888&W#M&&88&    //
//    %%%%%8%%%8%%%%8###M%%%%%%%8%%%%%%8&###8%88%888%8888888%%888888888&&8%%%8###W%%%%%&8888888&&&###W8888    //
//    %8%%%%%%%8%%%%%&W&%%%%%%%%%8W888%%8%8%%%8WMW8%%The&###8%%8888%%88%%88%8%&MW888%8%%88&W&88888&&W8&&MM    //
//    %%%%%%%%%&%%%8%%%%%%88%%%%W###88%88%8%%%&###MutantsWMW%%%%8888%%%888&%%%888%%88%8%%8###8888&8%888&##    //
//    8&8%%%%%&##W8%%%%%%8##&&%%88888%8%&W&%%8%%%%%%%8%%8%%%%%2022%88%%&##W%8888%%8##M&M&88&88&88&WW8%8&88    //
//    ###&%%%%%WW&%%8%%%%%&&%%%%8%8%88%&###8%%%%%%by%8%%%8%%%%%###&%%8%%&#z%%%8&8888&%%%%%8888%8&###&88&88    //
//    &WW%8%%%%%%%%%&###&%%%%%%8&&&%8%%%8&8%%8%%%%%%8%%%Awadoy%&W&8%888%%%%%%8###W%%%%%%%8&&88888&&&88888&    //
//    888%%%%%%8%%%%&##M88%8%%%W###W%888%8%%%%8W&&8%%%%%M##8%8%%%8888888&888%8###W%8%8%8W###W%%888W88888W&    //
//    %8%%%%WMM&%%%%%%8%8&88&88&WW&8%88%%%%%%%M##8%%8%%888%%%%8%%8%%%&MMW8%%%%%8%8&%%%%%8&W&8%%888%8&88M##    //
//    ##W&8%&W&&%%%%%%%%###8888W&%%%%8M#W8%%%%8&8%%%%88%888888WM#&8%88WW&%%8%8888###8%%8&8888%%W#M8%888&WW    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract STRANGERS is ERC721Creator {
    constructor() ERC721Creator("The Strangers", "STRANGERS") {}
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