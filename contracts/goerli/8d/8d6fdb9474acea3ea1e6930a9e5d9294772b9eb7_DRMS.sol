// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dreams in Another Land
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                           //
//                                                                                                                                                           //
//                                                                                                                                                           //
//                                                                                                                                                           //
//                                                                                                                                                           //
//                                                                       . ......... .                                                                       //
//                                                          .......................................                                                          //
//                                                   ..................... . . . . . . ...................                                                   //
//                                              ............. . .                           . ..............:....                                            //
//                                         ............. .         . ......::.:..:.:......           . ..........:..                                         //
//                                     ...:..........     .....:::i:irLYLY1sJ7s17vJvJ7JqSvrii::.:..       ..............                                     //
//                                  ..::........       .:i:772sLrrrrrv7rirrrr21UPvu7rv7sds7vYYrvLJvrri::..     .............                                 //
//                               .:::........     ..:i75EvIssr7rrr7777r7viiiYPqirPvi77vvv77:rLs77rvLSsvsj7r::..   ..........:..                              //
//                             .::........   ..:ir7vSgPXId7r:ris7rr7LY7virr7r7v7r7i:iii7:ii7rri7vrii:rir7L7LsLri.... ............                            //
//                          .:i:....... . ...rUPXEBggd1riirrrr7vvii:::.::::rr:.irvriiiiiii::ir7rY7rr777r777ir7Lr7ii:............::.                          //
//                        .:::........  .:iLudd5LY77r7v7::v7iri:iiri::iii::rr7i7r7rirrirrii::ri:....:77Lj7r7r77v7sr77r:. ..........:.                        //
//                      .:i:........  .:LvJ2Pjrriir7r:ir7::r7i7i:r7r7ri:r7::rr57:v7:r:r7virii7rrL7::rri:rrriiirrri77v77r:.........:.::.                      //
//                     :::........ ..i7EbIY1vvSXJi.:iv::iLii77iv:i::rr:irvr::v::7D7Yii7iir::i7:r7rrurrr7irrYri:rrrrivriviri:.....:...:::.                    //
//                    i::........ :r7KDK22sr1I2vr7rr7ri7rvi:::rr7rii:iiii:::i.7:rrrrirr:i:i:::rrLIPS5vrrr:rrrrririiirii:rirrr:......:.:.:.                   //
//                  .i:..........:YgZS257YEZKPvriir::ir7rir::r7i:iii::...:ii::::::.::riii:ri::irrUYvv7ri::ii:ri7v7irrririr:ir7i........::::.                 //
//                 :i:..........rbBQRggSjv77Pri:rLXv7i::iiririr:::::::i:ii7r7i..:.::.:i:iriiJ::..i::::r7vi7vrrrs7iii7:irirr:sLir:...:...::::.                //
//                :i:.........:7MBQBQBBRDEUri:7vvI7rr77r:iirii:.:rrr77rirr7i::....:i...:.r:rDi:i....:rir7rvYiririiir7ii7rirri2iri:.......::i:.               //
//               :i::.:......:vZS5IjEPPPdqP7j7r7777iirv:::i::... ...:.:..::::i777iiii:....:iYi::..:r7rrrYi:ruv7i77rirIrr7rriirY7:rr....:..:::i.              //
//              .i::.........rdQgbjrr77Ysju1r7rrivvirs: .iri.:::.....  .LP:rvvii7BgqXgRgJr:..:.::iir77rr77rr77riivri77rriirrrLvvi:ri...:.:.::::              //
//              r::.:......:7LIddEZdKIDbPXSbIvu5Krrii7i::...:i..:iirrriibriSr.r7jKZDgiirdBBP7:.:77r:::ir7vqv7:iiriiiJvrrLii:rir.ivir:...:.:.:::.             //
//             :i:::.......iPESDgP1S57iEDEDQZs:ri7Lv::rr:..     .i:.:i7EKEgP7rYPi:::iriiruPgM7:...::.ir7iiiiiirL7L..:rriri:rir::7J:ii:...:.:::::.            //
//             i:::.......::s1USPI5qIv:.i7iiII7i77iri:i:i:. ..::riiii:7KEPv::LZQMSririrrrir75PES7..:rir7s22uvririrY: :iirr7rrriivi7iri:.:::.::i::            //
//             r::.:.:....rLvvvLsJvYLLr:iJr:iriir7rirri::..iiiJsiirvUPPbd5i7:7PSu1sPPSvYiii1PdEBBP.:ri.iirrrir:ir77v777rrv7:rriri:b::r.:.::::::i:            //
//            .i:::.......r1S1UXSuIU5uY7IIPuvrvrir7iiir777i. rXuJr7USXPPgDQgQQZvr::rs2KPDqqqPKX1XDr.iiiiirjY1u27Ud7P5117irviir7i7iD7:r:...::::iii            //
//            .r::::.:....rgQP2KuYjsvPRBQDEgDKU21Js7rvLv7L7: vgPXjs5KEDRgDZDgRDggQQMdPPZddKK5KKPKbr.ir7vr7JdPL77iuiq2rr77SJ7ivr:7UiXLr::.::::::ir            //
//            .r:::.:.....7Mg2P52Ys1UPgDgdEZMZZq21vrr.:7rir: :BDdPZdgERMgPdZRZZgMMQRQgQMMggDZdEZQQr.::ii7ri7riirvrr:iii:7rririi:rLrBIri..:::::iir            //
//             r::::.:....iUqPdE55vuJ5Xrivii:rv7:ri77ririir7i.1QdPPZEDDgZdbRMZPbPDZQRQQQQQRQQBQBB2.i7vrrirrr:r7ii11Yrrirr7r7rivriJ5j7i::.::::iiii            //
//             ri::::.....:7dEK5X2Jriii..::iiijXUvv7L77rrrrii:.rBBMDRDMDggQRQgMgRDRQQQQQBQBQBBBBr.:iiir7uXXs1JJ55SQPKbg55Yvrr7v:idQsr::.::::iiii:            //
//             :r:::.:.....rdRZbdES2sYruIsIqXqUbPXJYrrr7riirii:::5BBBBQRRBQRDgDZ55dREdPEERRBBBsi.:irii::rKJuJSKgZBggSsirJLrrrr:7gPMvr::::::i:iir.            //
//              7i:::::....:vXd2SqqXq5dDZXqPqIUs1111UJvrrir7vrr:..:iqBBBBBQggdZDbPQBBQBQQQQI:..:vL2uu77iir775uuISI11iir7iii:rJEBBQ5ri:::::i:iiri             //
//              .v::::::....:5RBRMqSJj15uXqPIsir7ssuvrii71Y777rrii:::::rLjKQggQBQBQQK27ri:::.::i:irvLj1Er:i7r517::qdvPg22DXI5dZRQK7i:::::::iir7              //
//               :7:::::::...:ugDK5SqPdK5KDEdKIjSKqUUuIUUuYYsrvSbjrr7rr:..:.i::::.::::. .:ri77Y77rri::irvLsUPSMQDU7sqSdbRBBQRgMbPr::::i:iiiir7.              //
//                i7::::::....:vZQRBBBQMEIJ1SdqPI2PPbgZE52LuYXPX77rrrsr::rvILi:i:.:7LSIr:r7Sj7YSPqU2Sbsr7dBBRMggEgDM57uI1PRQgQBBJ::::::i:iirv:               //
//                 ivii:::::...:2QBQMDd2jYuZgPZDREdD7:rvr::JYri:rJ1rvvr:7IS7rir7sii7YUbX7r7JPSsiiiJUJrLiiri7ZDERgDMEdDgdEKEPRQD7::::i:iiiirJ:                //
//                  :Yri::::::...i1gdPXEPEDdPdZgPILLi::v7vPZXPIjqbU5PuivJ2vir7rubP7rrL7jXujUI2UrijIbEuisU7ii:r72DqPdZQQBQBQBBPi::::iiiirivs.                 //
//                   .L7iii::::...:rDBBQBMZXqI2SPb1ri7KJvgBZdgQPPj15Rsu2Xvrrv77jS5PSs7LsquuUrirSMBBRQQqsJqDS77PdPuXDgEQQBBBgv:::i:iiiirrJv                   //
//                     rY7ii::::::..:rXBBBQgZDS1sLJqqKvjZP1JPqXKv::iivZQPXPdUPMPPMKdZSJSPqUY:2J2MKPBBRMBbr1QPJYXPgQRDQQBQPi:.::iiririrv1i                    //
//                      .7Jri:i:i::...:iIgBDdZZ215dPXSPPdssPquKs7ii:iPgMDDQZgEvvU2gZSbPZQQR7i:i7KgP2EDPPg2YSMgXSDgREgBQIr::::iiirirrL1v                      //
//                        .vY7ii::::::...irbBBBBRMERggERZ2SdSU7UqDZ2PdbqdggPbMMBQE2qXPPdRQMqKEULrUPKUIUKEDEZEgggMBBBPYi::::iirirr7YIv.                       //
//                          :v1vriiii:::....iLQQBBBQRgBQgbRXI1dQRgggggdPRgEUZQQgMBgJPPgDRMggDgMPZX2IXdEKMRQQBBBBBZIi::::iirirrr715v.                         //
//                            .rJJ7riiii:::....:iqgBBBBBgggRZKUPZggZEMZP2XvdRgDRgBQXqdgggZZQgMZgDgZgEMQQQBBBQQKvi::::iirrrr77jKIr                            //
//                               :Luuv7irii::::...::rJPQBBQQBMDqRQQZMgZDgPSdMbPbgEXbMggEQgQDMQQQBDEMBBBBBE5vi:::::iirrrr77jPKL:                              //
//                                  :J1Uv7rririi::::...::rL2dRRBBBQQdMQBBBQgRQQBMgEQRQEBQBQBQBBBBBRgDqY7i::::iirrrr77vLXEbY:                                 //
//                                     :vu5uY77rrriii:::::::::iir7u1UXgBBBBBBBBQBBBBBQBBgPbqI11vriii::::iiiirr7777sSggK7:                                    //
//                                        .iLIKKjY77rrrririi:::::::::::::iiiirrrrriiiiii:i:::::i:iiiirr7777vvUXgQQXY:.                                       //
//                                            .:vJXddXuLv77r7rririiii:i:i:::i:::::i:iiiiiiririrr7r77vLjUPDQQBEUr:                                            //
//                                                 .:rY2PgMREPX5jsvv7777r7r7rrr7r7r777r77vLYJ1IqPMQBBBQR5Yi:                                                 //
//                                                        .:rvuUEMBBBBBBBQBQBQQRQRBQBBBBBBBBBBBDSY7i:.                                                       //
//                                                                   ..::iir77777v77rri::...                                                                 //
//                                                                                                                                                           //
//                                                                                                                                                           //
//                                                                                                                                                           //
//                                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


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