// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AlinaLanue
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                9M9,:32i                                                                              //
//                         r&H##@#@@###BHA3,                                                                            //
//                    ;hB#B###@@@@@@@@@@#####MA;                                                                        //
//                  iHH##M##@@@@@@@@@@@@@@MMMMM#MBG                                                                     //
//                [email protected]###@@@@@@@@@@@@@@@##MMM#####M5                                                                  //
//               iAMBBB##M#@@@@@@@@@@@@@@@##M####@@###M5r2                                                              //
//              sBBBBBH##[email protected]@@@@@@@#3         .SHM##@@##MMG3                                                             //
//              h3MGMBM####@@@@#A.                 &#[email protected]#MMB3r;                                                         //
//            .22&MMBBB##@@@@#X                   5B   3##MMMMAX.                                                       //
//            5MXM#H9#B##@@@#i                    &     3#@#MMMMMM2S:                                                   //
//            M&[email protected]##@@@#.                    ;     :##@##MBHBMHMM#M&                                                //
//           2h#&[email protected]####@@@#r                          SM  G,  rB9&###@@#BB                                              //
//           MMMBB#@@#@@@#9                        .  ##S.       MM#@@@##B#                                             //
//           #AABHM##@@@#&                         , .             B##@@@@M2                                            //
//           MAAGBM#####H5                                          [email protected]##@@#M                                            //
//           ,MMhG9M####M.                i                           ###@##                                            //
//            [email protected]@#XBM###B,               9                   i        ,[email protected]##9                                           //
//             B#@@@###@Ms             ,                     i         [email protected]@#M                                           //
//            .H######@#M9            ;       5s           B       rX:  ;##@B,B                                         //
//          hHAGMM#@@@@@#9                  #             5      .2&h;. :G##HrM                                         //
//        BB9  [email protected]@@@##Mhr          ,     #@#                   5 :  .;sMH#hh#                                         //
//       MB   [email protected]###H9XA.              Ms:                   S     .  ,[email protected]                                        //
//       Ah   [email protected]#M#&3BMBS,             M.                   ;,.         [email protected]#B9                                      //
//       G   MH#M##MH5&MBHB&9;                                 B.           ##@##h9X                                    //
//          3AMMB##MG&MH&##MM3S;                              &S            [email protected]@##AAMBH                                  //
//          BBM&B##Hh#[email protected]@#BA&BS                            .              #@@@MMBM#MM                                 //
//         iGABMMM#3B#3A#@@MBM3MBS:                                        [email protected]@@@M###@#5h                                //
//         9hBBM#[email protected]@##BHG##A2                                      @@@@@@MB#@@#H2                                //
//         S59AM#H&A#[email protected]###[email protected]@#3&                                 [email protected]@@@@@@@[email protected]@#Ms                                //
//         ;&3hMMHBBMAG&[email protected]@#@#BB5##@#B&3r                            XG#@@@@@@@@#####Hhr                                //
//         :9H;BAHBMMA&[email protected]@@##MMHA##@##GG2:                        [email protected]@@@@@@@@@##G2X                                 //
//         rGA 3HhH&MA2G&@@@#@###XB#@#BMBH2                     :2i    s#######@@@MX5Sr.                                //
//          GB:rMABX&&[email protected]@@M#[email protected]#MMM####MrB     hr            ii.       3#M##M####AhhB9,                                //
//          iM GG&B&BGB&&##@[email protected]#@#MMM#####MHA.  i    ,:ri::::           XHMM2B####hMMMB .                               //
//             HGhB&BHMHM#@#H#[email protected]@###M######MHBhhG9X                     X3M23A###BH###B . r                             //
//             2GA&BMBMM###@H#[email protected]@@@####M#MM####HhhMBH                   [email protected]@#HMM###MA  s. i399iiX3                   //
//              .hG&MHMA###@M#[email protected]@@@@##@##MMGSiBM#MM###MG:              [email protected]@#MH#MM#MB&s &hh52X5S5S5X                  //
//                BBMMMM###@[email protected]@@@@#######Bh2AM##B##HABMB            ;2M&M#MHBh##M##MAS. :52S2335S23X                 //
//                &M##MMMM####M#@@@@@####BAGBMMMMM#@#@&s 22B.           rh#MGXB#M###M#MHA5   G5XX22iSri2                //
//                MM##HMHM#H#M##@@@@@[email protected]@@##GBMBM###@@@H  ,XX            3MGXH#######BBGGS:   2iX5SX33933               //
//                MMM#MM&[email protected]#M#[email protected]@@@@@@@@@@#@BHMM#[email protected]@@@@@M99&            s&hMBB#####MBX92h532 ,22h22AAAA3               //
//                HMB#[email protected]#M#[email protected]@@@@##@@@#@@S iM##M3###@#M##r           iGAMMAM#MhMMMA5X932H93iHMMB&hAh9.              //
//                ABB#&[email protected]#H#[email protected]@@@@@@@@@@#X;AA##    B####HGr;,         55i25&BMMGAMBAG9&h&9BHH##MMMMM#&2              //
//                HGM#MHh#@M#[email protected]@@@@@@@@#@@X92Hi,      3s;,,.r,         Si.,  2hBMB&9M#HB&&&BMBMHM#MHHHAGM              //
//               sA9MM9A9#@[email protected]#@@@@@@@@#9h&S          :                i;.  S&BMMMMMM#M#MHAMMB#MM#MBHAXA5             //
//               ,[email protected]##@[email protected]@@@@@@#Gh3AS            : ..    .        .:    GBHHHMMMMHMBHMM&BMMM###MBh&             //
//            GB :[email protected]@[email protected]@@@@@@M9S              .   .     .         .,  :hSSi3ABH&HBGAM&MBM####@#HX             //
//           2M5,iXHMMAA&[email protected]#G#@@@@@@92                ,.                   s.SH,..;33A9H3GHBB###M##@##H2             //
//         :H9S; S3M#HH&[email protected]##@@@@@#[email protected]                    .;  ,            . :#H,  :52AB&H#[email protected]@@@####M3r             //
//         2MH , ,3BBAHBHA#[email protected]@@@@@#@@                        ,.             ; H#S    :[email protected]#@@@@######H.            //
//        r2MMsi,GABBMAMhh#XAMG#@@@@#@@                           s5           X  h#A    sMAMM#@@@@@##G23Mhi            //
//        i.BH5 shHG5AH3hM#9&[email protected]@@@@@@,                            2,          ; r  G#r    MH###@###MM&3h9&             //
//          MHX ;[email protected]@@@@@@#                          .  39                 2;   M&B####M&9HBBBBB2           //
//         B##9S:MMhGG&3G#&3MB#@@@@@@@@                           :  G:                   i. B2B##M#Ms9BBBMMMS          //
//          HBM&XBHHA&&XB#&[email protected]@@@@@##@                           A   X,                    5 r,5HBMBBH32BM&BGX         //
//            #AMMMBMMh&B#&####@@@@@##@r                          2B .h.                     S2.rXXGBMMMA3A9GAh3        //
//              MHMMM#&HM#M###@@@@##[email protected]                           #. r:                      :;2r2SX&GMMM2ABHH35       //
//               ####[email protected]#####@@@@##[email protected]@                            &  i                       95hh5S:iG5G#hG#M&3       //
//               h##@[email protected]#@@##@@@@#[email protected]@;                        2i B  ;                        &ihX2SSss9rH3H#MG       //
//                #@HMG#@#@@@#@@@@#M.M#r                          s3;.                            5SS:;:..Ss9H&#B       //
//                @#H&[email protected]@@@@##@@@@## B                           . ,i.;.                           55r:, ..,SBHBM       //
//               ###BM#@@@@@@@#@@@[email protected],G                            :rA r                              SS.... :XMMM       //
//               M##B#@@@@@@@##@@@##,&                           ,,5S..                            ,  2,. , ,:X##       //
//              ;A#M&#@@@@@@@#M#@@@@5H#                          ,,:&:,.                           ;  B5 ..  ;s#B       //
//            ;:,2B&##@##@##@###@@[email protected]@#@                         ,r&Sr.                            ;  2s,.. ,SM        //
//           is,,;2A#@5#BB#######@#Mi&[email protected]@#r                       .:2S,                            .   s;;   ;B3        //
//          ss:, i5&M#MMh.hMMMHH###59MM#@A;                      ,.i35 ,,           LANUE          .  s..,. .i&:        //
//          25,, :59h## 2:X&[email protected]@:;#H#@@X                      , ;sh.:                              ;.:.,.,3;         //
//         5s;,   ir9M# A [email protected]@# X###@@@                       ,:;B,.                         .    ,   .;hs          //
//        55X ,   :,GMM:M,5&@M,53#Hs#M##@@@                       .,iB,.                         .   .,.,,rhG           //
//        5X;      ,SM# M2hh## 3 M,[email protected]##@@#,                      .:rM;.                        :,   :r,;iAh            //
//        BS       r.&M MrA3#@33 M;@@B##@@##                      :i5#iSsr                    .:;,:. ;;:3BB             //
//         .       ;:HM [email protected]#92:9#@@[email protected]#@@@#                      ,s2#2s:;                   ,r;r5i  :,&MH              //
//                ;,S# &39XH#BSGrG#@@[email protected]@@@@#                     ..:S#X;i:r              ...,rssii  i:A#                //
//            .  : .9M,5,,5#M2r3SB#@#[email protected]@@@@@#                      ;SM&;r::        :sr .,.:ri:      ,5                  //
//            ,: ,r.H B,2&BMM r22M#@M##@@@@@#                     :;SHMs;:.   r2XX5s;s;.;ir:       :3                   //
//                :GXSGAAMM#3,5;9M##M#@@@@@M2                    s irsMG9HHBHHhA3h23X32SS.        .                     //
//               .235MB#MM##S3isBM####@#M##ABB                    ,:[email protected]#AH&GAAGGG&9X2s.                                 //
//                Xr#AM##@#H99:9HMMs##@##M#BHB;                   ::2X##&h93X59Ss:,...                                  //
//                 rMM##@@#BMXXMBMBH##@##B#M3MM                  .;SSiH#H5SSS2Sis; ,.,                                  //
//                   @##@@#MBMBMM#r#####AB#MB#A                   ;;[email protected]#MMAA&&A2s;;:;:.                                //
//                      :#M#BM#@@G###@##MXHHM#H                 rr ; ;s5r,B#MM###A3X53                                  //
//                           [email protected]@MH#@#@##MMBGMM2                 ,      r9      [email protected]                                     //
//                               M#@@@@@MMA2#                   ,,   ,                                                  //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LANUE is ERC721Creator {
    constructor() ERC721Creator("AlinaLanue", "LANUE") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x2d3fC875de7Fe7Da43AD0afa0E7023c9B91D06b1;
        Address.functionDelegateCall(
            0x2d3fC875de7Fe7Da43AD0afa0E7023c9B91D06b1,
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