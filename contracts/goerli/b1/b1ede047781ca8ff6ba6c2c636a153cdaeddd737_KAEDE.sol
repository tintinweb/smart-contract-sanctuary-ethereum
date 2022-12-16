// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kaede nft
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                        .,~.-?(1Jo=`           .CJ1<-~_._.                                  //
//                                .     -Jv____((1Jz`             CJ1<-~.-...                                 //
//                                ~    ,zl>~.(<<+JI`             .+1(_!- ~`_.                                 //
//                               ._- ,((1>_.`(+<1-3              .+1(-!..(~ ~.                                //
//                            ___~_ -`~<._.`..<<>>j(((+-((....   Zv<>_._.` _.i~                               //
//        `  `  `  `  `  `    .(_..(.`.~`.`..<:::!,+=(17-1vJ1/z=v1>+C `.`.._(: _  (  `  `  `  `  `  `         //
//                         .~(!``` <_ _..`..`-<>><~_~<<<<<<<<<<+J=1z<<.`.`(-.-`,!`_                    `      //
//                        `.`.~.`. ._-<..<_..._<+<_..~--!,-</~_+<<+z'.-_ .._ ._~` .`                          //
//       `                 ~_.~___~~(!.+I/_``...-~.`....`(~`  `(v~_ _ `. .._ .~ ``..                          //
//          `  `  `      ..`` .!` .-<JgK>..J+?<..``.``_.<~.` . (` ` <  _  ___   .__ `.- `  `  `  `  `         //
//                   `    <-.__ _~((dH#1+u$+><-_.    -_ _(_    `    _   _ _.1_::~:~__-_!`              `      //
//                        _<<__<<(JOWH1+dC!!` .   ..~ .~ >~   .    __.   .  (l<_ _. (.                        //
//       `        `      ~?_(-._??jqk6u6v__(+J(++<<~(+<-.<+<_-____(!.(_.-___.(z1-<_(~!                        //
//          `  `            ??0-.-?UHVz>;;<jOv<<~:_J?<?<+I<~~:::::<::+_:;<< -`(z<+`<          `  `  `         //
//                   `      .=+=jXXH6<:++??<:~~~(;+>~~_(J<!~~~<_~(<::j;;;;<_n ..1I7``                  `      //
//                        . _<dXkkHC>:::1Oz1<<<<<(2..._;>_.~~(J~(>~::+::;;<jy+..`,.        `                  //
//       `       `       .! .gWkk93::::~<~~~_~_.(X~(-(++_-(vZyyO$~~_(d<:<:<+ZS(._.>.                `         //
//          `             .dWQH9><+<:_(<~(((++==v4U6?11>Jz(I?TT7(<>?v0O1_:;<XI_<.-._          `  `            //
//                      .aV0V6+udW+?(O&Ol===lzzv__!~___(y'.`....I+?7!jyjj<;<zX<jz?--                          //
//                   `.J61dQHqqkW3<:JyzuzXfkWHR,....`.._`..``.`..`....j1<?G+<jm+Oz=-`                         //
//               `  .z==udmmHSkKC+<(kXNggH8waJ,___.`.`..`.`...(+wTTO--_1?<?3(<Hh1z!.                          //
//            [email protected]=+jVZ<+<zMM#Y>(gWmG+TH,-...`.`..`...(J+a+JgwOz1IjjZ>vHRzOx-(.                       //
//                  `.N-..z1I17TTBMNd_`.WdOJ4ks _~..`...`..`.z7<(mfX&7HNmydJHcdmHkOXXz+.                      //
//                    .Otz??<>>v;&jMNx..dkd07!........  ..`.._(y$Z>TWR_~TMBzqkdMMNHWVHmy(~                    //
//                    .dZ=?x?>dr:jVvUWHUTCz:.......`..  `..`...._7+Xk. -jgMHHHHMkzVWh?TWto.                   //
//                  .Ol==1yQsWH$:+hx>~JwwZJ(-.......`.`..`..`.`_+~-?I(JgHHy;dK4gMMNAwt&.tl                    //
//                .__(+=z?=f,HK;;;?/~~_<?~(=~.....................?1<_7c!(;j+6dVMMH""""ItXUC!`                //
//             ._.-(==zgs<<].++z;<<?___~.........`.....`..`..`........~_iI+y??dWXMHb  JrZ`                    //
//        ..(xz-(zuggH#"1;<j??>?X+.._(-.~..........--(((.-..`..`.....~..(+dC?=dWIjBW8zrv`            ~        //
//           ??TYY9"! ..z;<,ugk?+Udxvz<1--........(VCzjz?7+..........~.(CdyI==zd!?>+zI<              (        //
//    ..           _?CAgg:<[email protected]_......(KldgHgmgHdo..........(Owwy$lz_~ -Qytrro.             1_      //
//    .z.           (   ,:<-jWHMxlXx?4o-........([email protected]%..`.....(1V1dfIltOv(:dMHmyl.             (1      //
//     zI(.+<.     zz-  ..~1.4MNNzOdSx1z-........(kpWHHHHHd%.......-<(>-gWHttrA1<:[email protected]     ....Jz<`     //
//     .71zzz-`   .z_(   6;:<.HNMKztHx+Twy,.......OppppppW>........._.(XWkSOww$(:+Vs  ?TUDdN....++===?!       //
//         <z1 .   I<-~..?r;<:.MMMmZdKs>>=v<......(ppppWWt.........._<?T49GZ02(;:J<d; ~ ,>(  ?z+<1===(..      //
//    .     ?=_  ..?<<. I-v+++__HMMHAVmX+_<<<_.....?0><+C..........(JXHkudXZu!<:;P.=X..= (: .J<    ?==z=v,    //
//    z<1.  (=> J+(<(G;-.<,....._TMNHdWVWR.__...~...(c>>>.......(-UOqMHWXUU1r(;:jI`<z2~.('./~>      <====O    //
//       ..  =1,J<;1z1G>_  1......JMWHn(HWhJe+,..~...(&2....--J4D=ZdHkWWSUIV_1+j$li,~.;+^,/ ,       .Z=llI    //
//           l1<;;;j1+Cz+<. .......(VNWHHWHHkaxOO--.._~.-(JC>>>dzdHHHHHXW0f_.__._?_-:+Jb-(....   ...(llzz!    //
//    zll-_ (u>;;<J`. j21x>-.~.~....(XtZWHHHHHWHe?+C&JJv1>>>>>jXHWHkHHdX7.....-?_-:;+3(-Jv?`   .(zOwwttO>-    //
//    rwv1OwOI;+J' .~zZ(rdR?<_..~....jvOv+vwWKUMHRz?>?>>>>?jvdWWqVXdvw=........(<;+C;;;?Okl_  -wwrwXvrZ<O-    //
//    vI (Zz<+j3.--.dK(wV6dx><_~..._.`jwX(XXdMMMMMNc?>>>>+z1dmH4wQSXf_....-(<;;;+dZ?Xy$>+dSI-   ?XwXk=  -w    //
//    Xd.,X0O<>>>>>>>>>?>?16>?><_..~_ .40(UXXW#DdMMMc>>>+1+dmB!(dRX' ..-(>;;;>>>d4x<~(w+>?<l_1,-!(Xk&. .(d    //
//    Xdt (XkWkQxu&&&&+?>??z+>?<<-....._4dWKWH#RHMWSJ<;><zZd$.._W9_((J<;;;;;><+uDjI((-(S&<?J(>;;zkXWKkWXWX    //
//    WXW, (WHkYdHH3JkHWWa&&I<~.><1-_....?HHHWH8WNdd3<>+z!(C...(3;>>>>;<>>;>>+zTWAwzv77^?6&zvx;;!?HWHkHWW=    //
//    .WHH-. ?TWHN$jHHHHHHNB=<-(?>/!(+-....?5c?hdH91>>+t>._..(v<;;>>>>;>>>>;jC><<+?1??1+++ztOZ<`OX!(HHHWl     //
//      7HHHN,[email protected]_::gNx<(<(<1i-_.._ z?>?I?>>>1-..(v>>>;;;>>>>>>;+v>>>>+&+zOOOOC771;jdH) WR HHHW[    //
//    &.  "WMHHWMwMHkHpWzWWWkZWW7Hx><+?><<__- _1+<<z??>z1-J1>>>>>;<>><>?uVC11?>>>>>>>jC;;;;jdggHJH..HfgHWN    //
//    dMe da,4Wf;;>?TWfWfWfVXVC! -<?Gx>?<(J<:__.(z>I?>j?z0>>>>>>>>>_(+xIv????>????<+?;;:;jdgggggH.Vh.,WgMN    //
//    dMHHWgHHHGxz+>;>>zTWffk&..!.. _(4x>>+1z<__..?zJ<?j6>?>?>>>>><jZzC<?>>>????>1<-_(;jkdgggggggH..YL.XgN    //
//    HMWMgHh7T.J"Xk<_<>;><7UXWo.wXX&-((O>>>1z+<__..?+J6?>??>>>>>>>kC??>_!(???><<;;;j+ggggggggggggKT.J"aJg    //
//    HMMgWkCaJ74(=7+J?4&=jJ>>?THkWVWXuXZwJ>>+zz><-...?G1?>>>>>>>?J>>>><<>(1z<;;;+jWgggggggggggggggy74(=7H    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract KAEDE is ERC1155Creator {
    constructor() ERC1155Creator("Kaede nft", "KAEDE") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0xb08Aa31Cc2B8C0582bE42D38Bb643292e0A4b9EB;
        Address.functionDelegateCall(
            0xb08Aa31Cc2B8C0582bE42D38Bb643292e0A4b9EB,
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