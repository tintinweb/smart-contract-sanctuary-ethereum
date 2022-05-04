// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Merchants
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                             WWKxxkxON                                          //
//                                                                              Kx0WWXkdK                                         //
//                                                                             XxOWWW WOd0W                                       //
//                                                                            NkkN      KdkN                                      //
//                                                        WNXK0OOOOOOOOOOkkO00xdK      WXkokOKW  WW  W                            //
//                                                   WNKOOOOOO00KXXNNWWNXKK00OkxOOOO0XNOxKNNKkx0NWW                               //
//                                             WWWNKOkO0KXW             WWW    WWWXKOkxlxN  WWOlxOOOOOKNW                         //
//                                             WXOkk0N                          W  W  N0kkOKXXxxXWNXK0OOk0NW                      //
//                                            W0xONWW          W                         NOdlokN       W0d0 W                     //
//                                           XxxX        W  W  WW                          WXOx0W   WW  0xX                       //
//                                          XxkNW         WWKxxxOW               WNW          KdkN   WX0OKW                       //
//                                         NxkW           Nk:cocxN              NkodOX         XxxKK0O0KW                         //
//                                        WkdX            WXldXXxkKN         WX0kko;ckN        WXodKKN                            //
//                                        Ndk              W0dO0xONWW        NdxNNkdxON         WkdX                              //
//                                        Kd0               WX00XW           W0xOkON             KoO                              //
//                                        0oK             WNW                  WXNW              KoO                              //
//                                        0d0          WWNOxkON                   W              Xdk                              //
//                                        XdO           WNxkXOkkOKXN WXKXWWW    WWXKXW           Ndk                              //
//                                        WkxN           WKxxKNKOkkkkkOkxkOKXXX0OOOddK           XoO                              //
//                                         0d0           W N0kkkkOOk0NW WKkkOOOkkOOOXW           0o0                              //
//                 WWW            WWW      NxxW               WX0O0kok0OOOOOO000O0XW            WxxW                              //
//             W N0OOO0OOOOO0000OOKXKXNW    Kd0WW               WWW X0O0XWWWNWW                WOdX                               //
//              NkkNWWWWNXKKkodOK0ddkkOOOO00Kxo0W              W                               0d0W                               //
//             WOkN        NOONW WOkW  WNK00xdxdxOOX           W                              KokW                                //
//             0kX        W0kN WW0kKW       Xkxld0xdOOKNKKN     W                           WKdkNWW        WW                     //
//            NxOW        NxO  XkONWW        WXOOOddOOkkkkk00OOXWWWW                WW  WWNOxx0NNNNNNK00KNNNNNW                   //
//            OxX         WxkWNkOW   W           WN0O0OkkOxokOdxKK0OO0K0OkKXXKKXX00NX0KKOO0Odx0OO0OOxxKX0xdk0OOOOOOO0KXW          //
//           XxOW          OxX0xK                      WXXKOOOxxO00dlxkllOkod00xdOxx0OdxKxdO0X      XkK WN0kK WNNXKK00kON         //
//           OkN           Xx0XdOW                            WNKKXX0OOxkOkxkOOdxOkkOOkk00XWW       W0xX  WOxX        Nk0         //
//          Nk0           NOkXWOdX                                       WWW  WXKKXWWW               WOkX  XkK         OOW        //
//          XkKW        WKk0NWNkkN                                           WW   W                   WkkW XkK         0kN        //
//          0xX       WKO0N N0k0NW                              WWNNNW        W                        0xX 0kX         KkK        //
//          0kN       Xk0  XkON                               WK00K0000X                              WOOWWkOW         Nk0        //
//          OxNW      0xX WOkN                               WOkNWWWWW0xK                             KxK KxK          WOOW       //
//          KdOWW     0xX  OxN                               NxkW WWWWNkO                             XxOWKxK           OkN       //
//          WKxk0XW   NkOW Kd0                               WKkOOOO0OkON                              XxONkxX          0kN       //
//            WKOkkkOOKxdK NxO                                 WNXKK0KNW                                KxKNxkW         0OW       //
//                WX0OOkddkOodXW                                                                        XxO 0dX        Nk0        //
//                      WNK00OkkkOKNW                                                                   KxK KxK        KkX        //
//                      W      WX0OkOO0N                                                               WOkN KxK       WOOW        //
//                                  N0dOW                                                              XkK WOOW       KkK         //
//                                    OxN                         WWW                              W   0xK KkXW     WXkOW         //
//                                    Xx0                      WNXKKNW                         N0OOOOOOkdxkddO00000Okk0W          //
//                                    NkO                     N0O0KKKkK                        0xKXNNNNNWNXXK00000KKXW            //
//                                    NxO                   WKO0N W W0x0W                      0OW                                //
//                                    Xx0                   0kX W    WkxN                     WO0                                 //
//                                    KxK                   Kxx0W WWNkd0W                     Nk0                                 //
//                                    0xX                    WKOOkkOkkX                       WkO                                 //
//                                   WkkW                      WWXKXW                          OxN                                //
//                                   Xx0                                                       XxOW                               //
//                                  NkOW                                                        Kd0W                              //
//                              W  NkkN                                                         WOdK                              //
//                                NkxX                                                           WkxN                             //
//                               WkdX                                                             NxxN                            //
//                              WOxX                                                               NxxN                           //
//                             NkxX                                                                 NxxX                          //
//                            XxxX                                                                   NkxXW                        //
//                          N0k0W                                                                     WOd0 WW                     //
//                      WWKkdkN W                                                                      W0dOW                      //
//                       0xOkkk0W                                                                      WKdxxON                    //
//                      WkkNWNKkxOXWW      WNK0OOKW            W     W                 WK0KW          N0OX 0o0WW                  //
//                     NOdd0WWWWXOkkkOOOOOOOOOO00xxKW              WX0KN          W  WXOO0Okk0XW    WKO0NWNkoxK                   //
//                    NkkNKxkOKNW WWNXKKKKXX0kxONW0dkXW         WNX0O0xxKW  W    WWWX0OKWW WX0OOOO0000XWWNkkXOxK                  //
//                    OxX WWX0OkOOkO00000OOOOXNkkN N0kkkO0KXNNWNKOOKWWW0xkO0KXXXK0000KKOkOkOKW WNXKXW  XOk0W WOxN                 //
//                    KxkXWW    WX00OOOO0XNW   Nkx0W WNK00OOO00O0KKOON  WX0OOOOO0KXWW0xOXWXOkkkO0KKKK0OO0NWW WOxN                 //
//                     N0kkO0KNW WW            WNKkkOKNW  W   N0OOkOxx0NW      WW N0kOX      NK0OOOOO0XNNWNK0kOX                  //
//                       WNK0OOkxkXW             WWN0OOOOOOOkOOOXW  WXOkOO0KXXXK0OO0XW       WW       WKdoxO0XW                   //
//                    WW    N0Okk0NW                   WWNXXXN     W   WNK0OOOOO0XW                    WN0kk0N                    //
//                    WW  W0kOKW WW                                                                  WNK00K0OkkKN                 //
//                     W XkOXWWWNKK0KNW                       XOO00KXNW                             N0OKKKkOWNKkx0W               //
//                      Xk0W  N0O0KK0k0W                     NxxOOOOkOOOkON                         0xX   Kx0 WW0d0W              //
//                     WOkW   XkkX WWOkW                    NkkN W   WWNOd0                         KxOKK0xkN   WOxX              //
//                     WOkWW  WXOxO0OkK                    NkkN         NxkW                        WN0000XWWW   NxO              //
//                      XxOW     NK0KN                WW  KxOW          WKxOW                                    XxO              //
//                       KxkXW                        WWNOkKW           WWKdOW                                  NkxNWW            //
//                        NOxkOKXNW                  NKOkON                Xkx0N                              N0xON               //
//                          WKOOOOOOOOOO000KKKKK000OOOO0N                  WWXOkk0N                      WNK0OkOXWW               //
//                                WNXXKK00OOOOO000KXNW                         WKkkOOOKXNWWWWWWNXKKK000OO00O0XNW W  W             //
//                                                   W                           WWNKOOOOOO000OOOOOO00KKNW                        //
//                                                                                  WW                                            //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MOD is ERC721Creator {
    constructor() ERC721Creator("Merchants", "MOD") {}
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