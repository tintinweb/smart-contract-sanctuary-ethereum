// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MujeresNFT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                         //
//                                                                                                         //
//                                                                                                         //
//                                                                                                         //
//     _                _        ______ _                                                                  //
//    | |              (_)       |  _  (_)                                                                 //
//    | |    _   _  ___ _  __ _  | | | |_  __ _ ____                                                       //
//    | |   | | | |/ __| |/ _` | | | | | |/ _` |_  /                                                       //
//    | |___| |_| | (__| | (_| | | |/ /| | (_| |/ /                                                        //
//    \_____/\__,_|\___|_|\__,_| |___/ |_|\__,_/___|                                                       //
//                                                                                                         //
//                                                                                                         //
//                                                                                                         //
//    As an NFT owner, you do not have the right to copy, remix, and do other creative things with         //
//    the artwork linked to your NFT. Under this license, you can not incorporate your NFT                 //
//    artwork into other items or derivative work. This collection does NOT come with full commercial      //
//    use rights.                                                                                          //
//                                                                                                         //
//    If you would like full commercial use rights, please feel free to contact us to discuss.             //
//                                                                                                         //
//    This NFT shouldn’t be used for -- illegal, racist, sexist, violent, homophobic stuff... (read        //
//    section 2.4 below). However, this license does NOT give you ownership of the underlying art,         //
//    brands, or other intellectual property associated with project/publisher organization.               //
//                                                                                                         //
//    The General NFT License below is a legally binding agreement between you and us, so                  //
//    please review this document carefully before deciding whether to acquire a Mujeres NFT.              //
//                                                                                                         //
//    MUJERES NFT License Agreement                                                                        //
//    This General NFT License (the “License”) states the terms and conditions governing each              //
//    NFT that is offered, sold, or transferred to any person (which may be an individual or an            //
//    entity). If you sell, purchase, transfer, or acquire an NFT, you agree to be bound by the            //
//    terms of this License.                                                                               //
//                                                                                                         //
//    Definitions                                                                                          //
//    Art - means any art, design, drawing, fictional character, illustration, image, vector, video, 3D    //
//    asset, template asset, or other pictorial or graphic work associated with the NFT.                   //
//                                                                                                         //
//    Economic Activity - means any activity engaged in to obtain income, regardless of whether            //
//    or not the activity is aimed at making a profit.                                                     //
//                                                                                                         //
//    NFT - means the NFT created or issued on the project/publisher web site (“we” or “us”) or            //
//    minted directly via smart contract that is linked via metadata with specific Art, including but      //
//    not limited to a specific visual character.                                                          //
//                                                                                                         //
//    NFT - means an Ethereum-based non-fungible token complying with the ERC-721 standard,                //
//    ERC-1155 standard, or other similar non-fungible token standard. Is a unit of data stored on         //
//    a digital ledger, called a blockchain, that certifies a digital asset to be unique and therefore     //
//    not interchangeable.                                                                                 //
//                                                                                                         //
//    1. Intellectual Property Ownership                                                                   //
//    1.1 You own an NFT if your ownership of the NFT is cryptographically verified on the                 //
//    Ethereum blockchain. As an NFT owner, you own the non-fungible token — i.e., the digital             //
//    token recorded on the blockchain — but you do not own the Art associated with the token.             //
//                                                                                                         //
//    1.2 You acknowledge and agree that we own all legal right, title, and interest in and to all         //
//    elements of the Art. You acknowledge that the Art is protected by, as applicable, copyright,         //
//    patent, or trademark laws or other relevant intellectual property and proprietary rights.            //
//                                                                                                         //
//    1.3 You do not have a right to use any trademarks or logos owned by us.                              //
//                                                                                                         //
//    1.4 Mujeres NFT relinquises rights to reproduce the Art as any additional NFT format. If             //
//    found in violation, Minter may use all options under the law to recoup what it may consider          //
//    as lost revenue.                                                                                     //
//                                                                                                         //
//    1.5 You do not have the right to reproduce the Art as any additional NFT format (or creating         //
//    other collections on NFT marketplaces with our Art). If found in violation, we may use all           //
//    options under the law to recoup what we may consider in fines and lost revenue.                      //
//                                                                                                         //
//    2. Your License                                                                                      //
//    2.1 If you own an NFT (section 1.1), then we grant you a personal, non-sublicensable,                //
//    non-exclusive license to use the specific art associated with the NFT which you own, subject         //
//    to the restrictions described in Section 2.4 below.                                                  //
//                                                                                                         //
//    2.2 You may NOT use the Artwork for economic activity without previous consent and agreement         //
//    with Creator and/or Artist.                                                                          //
//                                                                                                         //
//    2.3 Transferring Your NFT. You may sell or transfer your NFT digitized token, and upon               //
//    such sale or transfer, we retain a 6% comission of the net profit of the sale and your entire        //
//    license to the Art and any associated rights will transfer to the new owner. The new owner           //
//    will enjoy the license and any associated rights described in this section, provided that the        //
//    new owner’s ownership of the NFT is cryptographically verifiable on the Ethereum                     //
//    blockchain.                                                                                          //
//                                                                                                         //
//    2.4 Restrictions. You agree to not use the Art in any way that is unlawful, pornographic,            //
//    defamatory, abusive, harassing, obscene, libelous, harmful to minors, racist, sexist,                //
//    homophobic, hate speech, gender discrimination, violence, depicting the use of drugs or              //
//    cigarettes or otherwise objectionable to any persons under the age of 18.                            //
//                                                                                                         //
//    You shall indemnify and defend Mujeres NFT against any claims, damages, proceedings,                 //
//    loss or costs arising from such use. User shall not use the Mujeres NFT Licensed Materials           //
//    in any way that could be construed as being adverse or derogatory to the image of Mujeres            //
//    NFT or any of its subjects featured in the NFTs.                                                     //
//                                                                                                         //
//    3. Digital Collectible Not A Security                                                                //
//    THE DIGITAL COLLECTIBLE IS INTENDED FOR CONSUMER ENJOYMENT, USE AND CONSUMPTION ONLY. IT IS NOT      //
//    A “SECURITY,” AS DEFINED UNDER THE SECURITIES ACT OF 1933, AS AMENDED, THE SECURITIES EXCHANGE       //
//    ACT OF 1934, AS AMENDED, THE INVESTMENT COMPANY ACT OF 1940, AS AMENDED, OR UNDER THE SECURITIES     //
//    LAWS OF ANY U.S. STATE.                                                                              //
//                                                                                                         //
//                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MUJ is ERC721Creator {
    constructor() ERC721Creator("MujeresNFT", "MUJ") {}
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