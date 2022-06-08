// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: D277
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
//                                                                                     //
//    (require 'disp-table)                                                            //
//                                                                                     //
//    (defgroup iso-ascii nil                                                          //
//      "Set up char tables for ISO 8859/1 on ASCII terminals."                        //
//      :prefix "iso-ascii-"                                                           //
//      :group 'i18n)                                                                  //
//                                                                                     //
//    (defcustom iso-ascii-convenient nil                                              //
//      "Non-nil means `iso-ascii' should aim for convenience, not precision."         //
//      :type 'boolean                                                                 //
//      :group 'iso-ascii)                                                             //
//                                                                                     //
//    (defvar iso-ascii-display-table (make-display-table)                             //
//      "Display table used for ISO-ASCII mode.")                                      //
//                                                                                     //
//    (defvar iso-ascii-standard-display-table nil                                     //
//      "Display table used when not in ISO-ASCII mode.")                              //
//    ;; Don't alter iso-ascii-standard-display-table if this file is loaded again,    //
//    ;; or even by using C-M-x on any of the expressions.                             //
//    (unless iso-ascii-standard-display-table                                         //
//      (setq iso-ascii-standard-display-table                                         //
//    	standard-display-table))                                                        //
//                                                                                     //
//    (defun iso-ascii-display (code string &optional convenient-string)               //
//      (if iso-ascii-convenient                                                       //
//          (setq string (or convenient-string string))                                //
//        (setq string (concat "{" string "}")))                                       //
//      ;; unibyte                                                                     //
//      (aset iso-ascii-display-table code string)                                     //
//      ;; multibyte                                                                   //
//      (aset iso-ascii-display-table (make-char 'latin-iso8859-1 (- code 128))        //
//    	string))                                                                        //
//                                                                                     //
//    (iso-ascii-display 160 "_" " ")   ; NBSP (no-break space)                        //
//    (iso-ascii-display 161 "!")   ; inverted exclamation mark                        //
//    (iso-ascii-display 162 "c")   ; cent sign                                        //
//    (iso-ascii-display 163 "GBP") ; pound sign                                       //
//    (iso-ascii-display 164 "$")   ; general currency sign                            //
//    (iso-ascii-display 165 "JPY") ; yen sign                                         //
//    (iso-ascii-display 166 "|")   ; broken vertical line                             //
//    (iso-ascii-display 167 "S" "(S)")   ; section sign                               //
//    (iso-ascii-display 168 "\"")  ; diaeresis                                        //
//    (iso-ascii-display 169 "C" "(C)")   ; copyright sign                             //
//    (iso-ascii-display 170 "_a")  ; ordinal indicator, feminine                      //
//    (iso-ascii-display 171 "<<")  ; left angle quotation mark                        //
//    (iso-ascii-display 172 "~")   ; not sign                                         //
//    (iso-ascii-display 173 "-")   ; soft hyphen                                      //
//    (iso-ascii-display 174 "R" "(R)")   ; registered sign                            //
//    (iso-ascii-display 175 "=")   ; macron                                           //
//    (iso-ascii-display 176 "o")   ; degree sign                                      //
//    (iso-ascii-display 177 "+-")  ; plus or minus sign                               //
//    (iso-ascii-display 178 "2")   ; superscript two                                  //
//    (iso-ascii-display 179 "3")   ; superscript three                                //
//    (iso-ascii-display 180 "'")   ; acute accent                                     //
//    (iso-ascii-display 181 "u")   ; micro sign                                       //
//    (iso-ascii-display 182 "P" "(P)")   ; pilcrow                                    //
//    (iso-ascii-display 183 ".")   ; middle dot                                       //
//    (iso-ascii-display 184 ",")   ; cedilla                                          //
//    (iso-ascii-display 185 "1")   ; superscript one                                  //
//    (iso-ascii-display 186 "_o")  ; ordinal indicator, masculine                     //
//    (iso-ascii-display 187 ">>")  ; right angle quotation mark                       //
//    (iso-ascii-display 188 "1/4") ; fraction one-quarter                             //
//    (iso-ascii-display 189 "1/2") ; fraction one-half                                //
//    (iso-ascii-display 190 "3/4") ; fraction three-quarters                          //
//    (iso-ascii-display 191 "?")   ; inverted question mark                           //
//    (iso-ascii-display 192 "`A")  ; A with grave accent                              //
//    (iso-ascii-display 193 "'A")  ; A with acute accent                              //
//    (iso-ascii-display 194 "^A")  ; A with circumflex accent                         //
//    (iso-ascii-display 195 "~A")  ; A with tilde                                     //
//    (iso-ascii-display 196 "\"A") ; A with diaeresis or umlaut mark                  //
//    (iso-ascii-display 197 "AA")  ; A with ring                                      //
//    (iso-ascii-display 198 "AE")  ; AE diphthong                                     //
//    (iso-ascii-display 199 ",C")  ; C with cedilla                                   //
//    (iso-ascii-display 200 "`E")  ; E with grave accent                              //
//    (iso-ascii-display 201 "'E")  ; E with acute accent                              //
//    (iso-ascii-display 202 "^E")  ; E with circumflex accent                         //
//    (iso-ascii-display 203 "\"E") ; E with diaeresis or umlaut mark                  //
//    (iso-ascii-display 204 "`I")  ; I with grave accent                              //
//    (iso-ascii-display 205 "'I")  ; I with acute accent                              //
//    (iso-ascii-display 206 "^I")  ; I with circumflex accent                         //
//    (iso-ascii-display 207 "\"I") ; I with diaeresis or umlaut mark                  //
//    (iso-ascii-display 208 "-D")  ; D with stroke, Icelandic eth                     //
//    (iso-ascii-display 209 "~N")  ; N with tilde                                     //
//    (iso-ascii-display 210 "`O")  ; O with grave accent                              //
//    (iso-ascii-display 211 "'O")  ; O with acute accent                              //
//    (iso-ascii-display 212 "^O")  ; O with circumflex accent                         //
//    (iso-ascii-display 213 "~O")  ; O with tilde                                     //
//    (iso-ascii-display 214 "\"O") ; O with diaeresis or umlaut mark                  //
//    (iso-ascii-display 215 "x")   ; multiplication sign                              //
//    (iso-ascii-display 216 "/O")  ; O with slash                                     //
//    (iso-ascii-display 217 "`U")  ; U with grave accent                              //
//    (iso-ascii-display 218 "'U")  ; U with acute accent                              //
//    (iso-ascii-display 219 "^U")  ; U with circumflex accent                         //
//    (iso-ascii-display 220 "\"U") ; U with diaeresis or umlaut mark                  //
//    (iso-ascii-display 221 "'Y")  ; Y with acute accent                              //
//    (iso-ascii-display 222 "TH")  ; capital thorn, Icelandic                         //
//    (iso-ascii-display 223 "ss")  ; small sharp s, German                            //
//    (iso-ascii-display 224 "`a")  ; a with grave accent                              //
//    (iso-ascii-display 225 "'a")  ; a with acute accent                              //
//    (iso-ascii-display 226 "^a")  ; a with circumflex accent                         //
//    (iso-ascii-display 227 "~a")  ; a with tilde                                     //
//    (iso-ascii-display 228 "\"a") ; a with diaeresis or umlaut mark                  //
//    (iso-ascii-display 229 "aa")  ; a with ring                                      //
//    (iso-ascii-display 230 "ae")  ; ae diphthong                                     //
//    (iso-ascii-display 231 ",c")  ; c with cedilla                                   //
//    (iso-ascii-display 232 "`e")  ; e with grave accent                              //
//    (iso-ascii-display 233 "'e")  ; e with acute accent                              //
//    (iso-ascii-display 234 "^e")  ; e with circumflex accent                         //
//    (iso-ascii-display 235 "\"e") ; e with diaeresis or umlaut mark                  //
//    (iso-ascii-display 236 "`i")  ; i with grave accent                              //
//    (iso-ascii-display 237 "'i")  ; i with acute accent                              //
//    (iso-ascii-display 238 "^i")  ; i with circumflex accent                         //
//    (iso-ascii-display 239 "\"i") ; i with diaeresis or umlaut mark                  //
//    (iso-ascii-display 240 "-d")  ; d with stroke, Icelandic eth                     //
//    (iso-ascii-display 241 "~n")  ; n with tilde                                     //
//    (iso-ascii-display 242 "`o")  ; o with grave accent                              //
//    (iso-ascii-display 243 "'o")  ; o with acute accent                              //
//    (iso-ascii-display 244 "^o")  ; o with circumflex accent                         //
//    (iso-ascii-display 245 "~o")  ; o with tilde                                     //
//    (iso-ascii-display 246 "\"o") ; o with diaeresis or umlaut mark                  //
//    (iso-ascii-display 247 "/")   ; division sign                                    //
//    (iso-ascii-display 248 "/o")  ; o with slash                                     //
//    (iso-ascii-display 249 "`u")  ; u with grave accent                              //
//    (iso-ascii-display 250 "'u")  ; u with acute accent                              //
//    (iso-ascii-display 251 "^u")  ; u with circumflex accent                         //
//    (iso-ascii-display 252 "\"u") ; u with diaeresis or umlaut mark                  //
//    (iso-ascii-display 253 "'y")  ; y with acute accent                              //
//    (iso-ascii-display 254 "th")  ; small thorn, Icelandic                           //
//    (iso-ascii-display 255 "\"y") ; small y with diaeresis or umlaut mark            //
//                                                                                     //
//    (define-minor-mode iso-ascii-mode                                                //
//      "Toggle ISO-ASCII mode.                                                        //
//    With a prefix argument ARG, enable the mode if ARG is positive,                  //
//    and disable it otherwise.  If called from Lisp, enable the mode                  //
//    if ARG is omitted or nil."                                                       //
//      :variable ((eq standard-display-table iso-ascii-display-table)                 //
//                 . (lambda (v)                                                       //
//                     (setq standard-display-table                                    //
//                           (cond                                                     //
//                            (v iso-ascii-display-table)                              //
//                            ((eq standard-display-table iso-ascii-display-table)     //
//                             iso-ascii-standard-display-table)                       //
//                            (t standard-display-table))))))                          //
//                                                                                     //
//    (provide 'iso-ascii)                                                             //
//                                                                                     //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////


contract D277 is ERC721Creator {
    constructor() ERC721Creator("D277", "D277") {}
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