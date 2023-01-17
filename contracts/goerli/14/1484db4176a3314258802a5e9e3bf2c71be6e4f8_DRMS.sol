// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dreams in Another Land
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                   //
//                                                                                                                                                                   //
//                                                                                                                                                                   //
//                                                                                                                                                                   //
//                                                                                                                                                                   //
//                                                                   . ...........................                                                                   //
//                                                         ..................................................                                                        //
//                                                 ................. . .                         . . ..........:....                                                 //
//                                            ..:.......... .         .   ...................           . . ..............                                           //
//                                       ..:.:...... .       .....:i:i:iivLsvjJsL7JSvLLYLLv5Pu7rii::::..         . ........:..                                       //
//                                   ...:........       ..:iiiYLIJYrr7rrvvrrririLKI7duK77LYsqXL7vJuvYYJsv7rii::..     ..........:..                                  //
//                                .:.:........    ...:i7LqBgSPv7ir77r77L7L7Jrrr7YPPrr57ii7rv7r7rirv777i77YJvv1JYr7r:.. . ..........:..                               //
//                            ..:::........    .irssDPdQQu77srri7rjYri:i7iii:ii7i:irr7r:iiiri::irr7rvJvrrirrrrvvv7sLYii:... . ......:.:..                            //
//                          .:::........   .:r7KRQKSPKS11Yi:is7rrririii...:i:.:7ri.7ivrri7:irri::iir::.::i7v7uv7rrr77vLLrri:.. ..........:.                          //
//                        ::::.......   .:77Y5dSrrrirrriii7iiirrrri:r7rrrii:vi.:r7I7i7v:riirYrrrir7rrrr..:riirrrriiir7rrv7Y7ri:...........:.:.                       //
//                      .i::........ ..i7Ed5s1jvU5sr:::rr::rvii7riv:ii:rrr:rrv:::v:irDsv7:7riri::rr:7Y7rs7irrrir7vri:rrrrrvriLrri:.. ..:...:::..                     //
//                    .i:........  .i7udDq2S171ISur7ri7rrr7r7ii:irrrrir:r:::::::::r:rrirrr7iiiii::ir7vqbdXJrrr::7irrrirrirrii:rirrri......:.:::::                    //
//                   i::........ ..7gQdqX2rYqZDd7iiirr:iirrrir:irvii:i:::..::iiri:::::..:iiiiir7i::iirYvr7rrii:iiiirrsLrirrrir:ri:ivii.......:::::.                  //
//                 .r::.........:7QBBBBBQbPUvivii:rjPLLrr:iirrriii:.i:iiriiir77i7:....:::.i::i7:Lu::..:...ii7L7727rir7riir7:irririrD7i7:. .....:::i:                 //
//                :i::.........:YKDMZQBQQRgDPvrrr1u77iii7L:::iii:...:::rii::.ii:.:::::.i:... .:iLS:ii...:rriivrir77rirrrirrLi77ri7:r77iri:...:.:.::::.               //
//               :i::.........:1Qgb17ivLsj21Sv7vriirjri77..:rri..::  ...   :77:i77rrjDPuY1IY7::::::::.:i777rr77iiru7rirvr:rv7rririrvvu7:r7:...:.:.::::.              //
//              .r::.:.......r75DDDDbPuKdPSX2EU7uuI7ri:vr:.::..:i:.::iii:i:vDriKi:ir7EMQQUrJPBQbri..:77ri::ii77KJ7r::iiiirJvrrvrii:7ii.7rrr:...:..:::::              //
//              r::.:.......:SgIZDDSKK5i7EDbgMgUirrrvLr.iri..      .:i.:irKqPdE5rr2Er:::riiirLXDQgr::..::.ir7rirririv7vr. :rr:7iiirri::Yv:ii....:.::::::             //
//             :i:.:.......::vuUJKIu2Su7.::7iij1rirviriii:::...:.:iriiirirIdZIi::JDBgdvrriiriiirJqdZPv..:riirvu2jvri:7i7v:.iiii7rrrriir7iv:r::.::::::i:i.            //
//             i:::.:......rJvvL11usJssLi:7JJ:ii7iir7iirriri:.i:r21rirsUPPddZ1JJ7IEJv7iJXX211r7YqbdbRBR::ii.::ririrrrrUYJsj7vrrrLiirri7:rg::r::..:::::ii:            //
//             r::::.:.....rSZPU5Sj22U1XXdbPZEIJsurr77ir777v7r..vdIXv7USPddggQRQBBd5sjvjUSSdZDPqXqXKUSZ7.irrrirUbZKK5rsPiBPsYsr7Jvir7ii17U7rri...::::::r:            //
//             r:::.:......rRQbXPI1Y1YIgBBBMgRBgEqPS57viivLr7r: 7QgbqqPPDDQRgEDgQggMBQBQQRRMRDMDbqPPZgB7.:ii77ri717ir7rrirririLssrrr7::77iBj7::.::::::iii            //
//             ri:::.:.:...r5Z5dPSUusX2dSsJ1vriLj1irrrrr:rrii7r:.EQDbDEgDgMMEdEQMDPbEggQQQQQRQRQRQQBBBE.:rrrirrrri:rrirY7iirirrrrrrir7irsSqvi:..:::::iir:            //
//             :r::::.:....:7qgPPqXUvrr7i.:::::iY11777vJL7rrriii:.7BBQMgMDRgMgQQQgMgMZMQBQQQBQBBBBBBB7..irrrvvS2uvYv1u1PBPXqdI2u77rrIr:rQd7i::::::::iiir.            //
//              ri::::::....ibggPddP5usLr11L2K5P5PdP2J7rr77r:rrr::::7QBBBBBBQBQRgMDgKXdQggEDDQQBBBE7i::riiii:r2KJ12XERQBgD5sirYLrri7:i5gZgrr:::::::iiiri             //
//              .7i::::::.:.:rXZP5PPPqKIEZdqPdX21vj1juUsvrrirr777ii...:ibQBBBBBBQgQQMQBBBBBBQEZ2i...:rvjSXsLviir7LIujsLuS2iivvrii:isqQBBQJr:::::::i:ir7              //
//               :7i::::::....rDQBRbSUJ2551qPZPU7rv1u2uvrrrjUsvLrrr7ri:::::::i7uUUSd52qUrr:..::::i:riiirrrr75JiiisJPKj:r2qUDQPKBQDEDDEgRLr:::::i:i:irv.              //
//                :vi::::::....:2PZbZRQMRgZKd5PPPSS5PX5dDDb5SJusU5DP1rr7L7i...iii:.:. :::ir..:rr7rYUU25L7rrrr7IZRMEEQQRP1SXLIPDRBBQRBBRsi:::i:i:iiirL.               //
//                 .7r::::::....:IBBBBQBDPSjvqdZdEEdERD7711viiJssvii7jrr77::7I52rri7r:ivYKdPri7JPPJvrsvUUIUSrir22QBQRQDMQQbqqKISdDgBQQui:::i:iiiir7Y.                //
//                  .7vii::::::...iYRgEPPXSqDZZPggMPUu7::i7ir2bU2vrUEX1XKrr725LirrrsdS7rrvsuSuJYIKKUi:vjPPYirL7i::rvuPgPZPgQQQBQQBBBUi:.::iiiiri7J7                  //
//                    :Y7rii::::....iSQBQBBBZbPXIqqdIvirvK71QBgZQBEE11IRSYIXU7rrvv7IXqqXYL7sUqLIjriLKgBBQBBbu1IZqs:JKPX2KRgMMBBBBBqi:::i:iiiirrJY:                   //
//                      iYvii:i::::...:rPBBBBDZDPujLjSPK5YSDb12PKPPY:::irKQgbKDP5dgSPgddgPU5PEK2r:Iv5MbPBBQRBMjrDgqsUKdgBgMQBBBP7:::::iirirr7su:                     //
//                        isvrii:i:::....i7EQQgQMd5PbZbPPEEbvjPP1UY77v:i5gggbQRggEvI52PQSPbZRBQdr7ii71Ed5qbPqgPU2EggqbgQRRRBZji:.::iirirr7vUsi                       //
//                          :7uv7ii:i:::....:7dBBBBBQQBRRQQdqbP21sPgQQdEZDPdQMM2DBBQBQb1bPgEgQRgdZQPus1X52X5XZMgQQQRBQBQBEYi::::iirirr771UY.                         //
//                            .rsuv7riii:::....:iuEBBBQBBBRMDQPPIqgRDMgMggdPbP1PRQMRgBBSSbEMgQDRRMgggRZPPPEQDQBBBBBBQE1r:::::iirrrr7v2Sui                            //
//                               .rsUJvrriiii::....:ii1dRBBBBQBQgqqMQQMgQDgPPI2MQbEERRDPDgQZMggMQRBRBRMZQBBBBBBBgSYii:::iirirrr7vJqX1i.                              //
//                                   i7U1uv7rriii:::.....:irsSPQQBQBBBBRgQBBQBRMQRQBMgPQQQgQBBQBQBBBBBBQQBgKjYi::::::iirr7rvL2PDUL:                                  //
//                                      .iL151uv7rririi::::...::iirrvJSuSdBBBBBQBBBQBBBBBQBBQEdPPUIJsrrii:::::::iirr77vL5PRgXLi                                      //
//                                           :rJ2KX5Jsv7rririi::::::.:.::::::::iiiiiiiii:iii:::::::::i:iiiirr7rvLIKDQBRPsr.                                          //
//                                                .ivj5PDdPS1YL77rriririiiiii:iii:i:i:iiiiiirirrrr7r77vY1SbZQBBBQbu7i.                                               //
//                                                      .:i7sUKgRBBBQQgDbPXSU21Uu1juj112USSPPEZQQBQBBBBBQg2Jri..                                                     //
//                                                                ..ii77ss2IqdggMRQRQMQgMZZqXuuYvri::.                                                               //
//                                                                                                                                                                   //
//                                                                                                                                                                   //
//                                                                                                                                                                   //
//                                                                                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DRMS is ERC1155Creator {
    constructor() ERC1155Creator("Dreams in Another Land", "DRMS") {}
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