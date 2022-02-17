// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: orbgasm
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                         --                                                                         //
//                                                        .               .66.               .                                                        //
//                                                        *R_             O99O             _R*                                                        //
//                                                        *99r.          ^9999^          .r99*                                                        //
//                                                        *9996*  ..._= -999999- =_...  *6999*                                                        //
//                                                        *99999B=_R99O.39966993.O99R_=B99999*                                                        //
//                                         =O+,         ,.*9996999b_^B.b999^^999b.B^_b9996999*.,         ,+O=                                         //
//                                          O99Ro-   -r39-+999oo9999* =9996..6999= *9999oo999+-93r-   -oR99O                                          //
//                                           B99996b*+oO6-+999O +699O..b99o  o99b..O996+ O999+-6Oo+*b69999B                                           //
//                                           _99999996O^*.=3996  ,R99= ^99_  _99^ =99R,  6993=.*^O69999999_                                           //
//                                            *999B^B9999+  B99=  ,9O   ,b6**6b,   O9,  =99B  +9999B^B999*                                            //
//                                         .oB b999r -b699O ,+bBR^R3      -33-      3RoRBb+, O996b- r999b Bo.                                         //
//                              -=_..     ,O99R 3999b   +69.   .-o6o.  ._-*33*-_.  .o6o-.   .93+   b9993 O99O,     .._=-                              //
//                              ,r9963BObro^**^,.ob99B_. b9      _33r+rRr*+--+*rRr+r33_      9b ._B99bo.,^**^orbOB3699r,                              //
//                                _O999999999996=. *rOORO36_.,=*++_ ,r+.        .+r, _++*=,._63OROOr* .=699999999999O_                                //
//                                  =B9996boO39999O     . r9R^-.   ,R_            _R,   .-^R9r .     O99993Oob6999B=                                  //
//                                   .*6996b-  _=o9o     -b*.      ^*  .,_,__,_,.  *^      .*b-     o9o=_  -b6996*.                                   //
//                                  ,3r-r9999R=   r9=  ,o^.        ro+*++-^RR^-++*+or        .^o,  =9r   =R9999r-r3,                                  //
//                                  O96O,,rrb99BRROOOOBb_       .+^*B-   =b..b=   -B*^+.       _bBOOOORRB99brr,,O69O                                  //
//                                ._***^rr_..,,,.    3O        *o=  _r+.*o    o*.+r_  =o*        O3    .,,,.._rr^***_.                                //
//                        _*rbORB369999999999R_     _r       ,b+      =OO+=--=+OO=      +b,       r_     _R999999999963BRObr*_                        //
//                        .=oB9999999Rb^***^*r3r,  .b,      _R_       bR*o*==*o*Rb       _R_      ,b.  ,r3r*^***^bR9999999Bo=.                        //
//                            .=rB9999Bb^-.   +96^O6^       R_      .Rb,        ,bR.      _R       ^6O^69+   .-^bB9999Br=.                            //
//                                =*b3999999BBO^_,r6,      +^      _B=            =B_      ^+      ,6r,_^OBB9999993b*=                                //
//                                BBr*=^*=*o=.     r.     .r*--_, -Br              rB- ,_--*r.     .r     .=o*=*^=*rBB                                //
//                                33b*-*+-+^-      o.  .+^+O*_-=+ORr^              ^rRO+=-_*O+^+.  .o      -^+-+*-*b33                                //
//                                =*r3999999BBO*,,o6, =b=. +^   ^^,^3_            _3^,^^   *+ .=b= ,6o,,*OBB9999993r*=                                //
//                             -oB69993O^=,   *96^R9+_O.   .R. r+   _3+.        .+3_   +r .R.   .O_+9R^69*   ,=^O39996Bo-                             //
//                        .-^R9999999Rr^*++++^3b,  ,rO_     -Ob^,__-,bOrb^=--=^brOb,-__,^bO-     _Or,  ,b3^++++*^rR9999999R^-.                        //
//                        -^bORB3699999999999B-     _3.      -B*--==-b*_++====++_*b-==--*B-      .3_     -B9999999999963BROb^-                        //
//                               .,-***obb-.,,..     3R       .^^,  _b            b_  ,^^.       R3     ..,,.-bbo***-,.                               //
//                                  O63O,,oor99BRRbbbR3O=       ,*ooO,            ,Ooo*,       =O3RbbbRRB99roo,,O36O                                  //
//                                  ,6b-r9999B*   r9+  _OR*--_--=*^+=**+=-_____=+**=+^*=--_--*RO_  +9r   *B9999r-b6,                                  //
//                                   .+3996b-  ,-^9o     =b^_____.    .,_--==--_,.    ._____^b=     o9^-,  -b6993+.                                   //
//                                  =R9996bobB6999R       r9b=,                          ,=b9r       R9996Bbob6999R=                                  //
//                                ,b999999999999+, +obOOO36_,_+*+-.                  .-+*+_,_63OOObo+ ,+999999999999b,                                //
//                              ,r99963ROrr^**^_.^r99B-, O9     .-BR^=--_,,..,,_--=^RB-.     9O ,-B99r^._^**^rrOR36999r,                              //
//                              -+-,.     ,O69R B999O   =39.    _^6r,.,_-=+BB+=-_,.,r6^_    .93=   O999B R96O,     .,-+-                              //
//                                         .r3.r999b _r399R .=rBRoBB      _66_      BBoRBr=. R993r_ b999r.3r.                                         //
//                                            +999B^R9999+  R99+  ,9O   ,r6^^6r,   O9,  +99R  +9999R^B999+                                            //
//                                           ,99999999Ro*.-B996. ,O99= *69-  -96* =99O, .699B-.*oR99999999,                                           //
//                                           B99996O^*ob3-+999R =699O. b99^  ^99b .O996= R999+-3bo*^O69999B                                           //
//                                          b99Br=.  -b69=+999^^9999^ =9996..6999= ^9999^^999+=96b-  .=rB99b                                          //
//                                         =O*_         _.*9996999O-*R O999**999O R*-O9996999*._         ,*O=                                         //
//                                                        *999993+_R99O.69966996.O99R_+399999*                                                        //
//                                                        *9996^  .,,_+ -999999- +_,,.  ^6999*                                                        //
//                                                        *99b,          o9999o          ,b99*                                                        //
//                                                        *B-             R99R             -B^                                                        //
//                                                        ,               .66.               ,                                                        //
//                                                                         ==                                                                         //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ORB is ERC721Creator {
    constructor() ERC721Creator("orbgasm", "ORB") {}
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/Proxy.sol)

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
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
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
     * If overriden should call `super._beforeFallback()`.
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