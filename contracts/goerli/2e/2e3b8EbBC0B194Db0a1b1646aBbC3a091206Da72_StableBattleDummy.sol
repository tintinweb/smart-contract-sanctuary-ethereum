// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165 } from './IERC165.sol';
import { ERC165Storage } from './ERC165Storage.sol';

/**
 * @title ERC165 implementation
 */
abstract contract ERC165 is IERC165 {
    using ERC165Storage for ERC165Storage.Layout;

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return ERC165Storage.layout().isSupportedInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ERC165Storage {
    struct Layout {
        mapping(bytes4 => bool) supportedInterfaces;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC165');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function isSupportedInterface(Layout storage l, bytes4 interfaceId)
        internal
        view
        returns (bool)
    {
        return l.supportedInterfaces[interfaceId];
    }

    function setSupportedInterface(
        Layout storage l,
        bytes4 interfaceId,
        bool status
    ) internal {
        require(interfaceId != 0xffffffff, 'ERC165: invalid interface id');
        l.supportedInterfaces[interfaceId] = status;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title ERC165 interface registration interface
 * @dev see https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 {
    /**
     * @notice query whether contract has registered support for given interface
     * @param interfaceId interface id
     * @return bool whether interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155 } from '../IERC1155.sol';

/**
 * @title ERC1155 base interface
 */
interface IERC1155Base is IERC1155 {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155Internal } from '../IERC1155Internal.sol';

/**
 * @title ERC1155 enumerable and aggregate function interface
 */
interface IERC1155Enumerable is IERC1155Internal {
    /**
     * @notice query total minted supply of given token
     * @param id token id to query
     * @return token supply
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @notice query total number of holders for given token
     * @param id token id to query
     * @return quantity of holders
     */
    function totalHolders(uint256 id) external view returns (uint256);

    /**
     * @notice query holders of given token
     * @param id token id to query
     * @return list of holder addresses
     */
    function accountsByToken(uint256 id)
        external
        view
        returns (address[] memory);

    /**
     * @notice query tokens held by given address
     * @param account address to query
     * @return list of token ids
     */
    function tokensByAccount(address account)
        external
        view
        returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155Internal } from './IERC1155Internal.sol';
import { IERC165 } from '../../introspection/IERC165.sol';

/**
 * @title ERC1155 interface
 * @dev see https://github.com/ethereum/EIPs/issues/1155
 */
interface IERC1155 is IERC1155Internal, IERC165 {
    /**
     * @notice query the balance of given token held by given address
     * @param account address to query
     * @param id token to query
     * @return token balance
     */
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @notice query the balances of given tokens held by given addresses
     * @param accounts addresss to query
     * @param ids tokens to query
     * @return token balances
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @notice query approval status of given operator with respect to given address
     * @param account address to query for approval granted
     * @param operator address to query for approval received
     * @return whether operator is approved to spend tokens held by account
     */
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    /**
     * @notice grant approval to or revoke approval from given operator to spend held tokens
     * @param operator address whose approval status to update
     * @param status whether operator should be considered approved
     */
    function setApprovalForAll(address operator, bool status) external;

    /**
     * @notice transfer tokens between given addresses, checking for ERC1155Receiver implementation if applicable
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @notice transfer batch of tokens between given addresses, checking for ERC1155Receiver implementation if applicable
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param ids list of token IDs
     * @param amounts list of quantities of tokens to transfer
     * @param data data payload
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165 } from '../../introspection/IERC165.sol';

/**
 * @title Partial ERC1155 interface needed by internal functions
 */
interface IERC1155Internal {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155Base } from './base/IERC1155Base.sol';
import { IERC1155Enumerable } from './enumerable/IERC1155Enumerable.sol';
import { IERC1155Metadata } from './metadata/IERC1155Metadata.sol';

interface ISolidStateERC1155 is
    IERC1155Base,
    IERC1155Enumerable,
    IERC1155Metadata
{}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title ERC1155 metadata extensions
 */
library ERC1155MetadataStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC1155Metadata');

    struct Layout {
        string baseURI;
        mapping(uint256 => string) tokenURIs;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155MetadataInternal } from './IERC1155MetadataInternal.sol';

/**
 * @title ERC1155Metadata interface
 */
interface IERC1155Metadata is IERC1155MetadataInternal {
    /**
     * @notice get generated URI for given token
     * @return token URI
     */
    function uri(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC1155Metadata interface needed by internal functions
 */
interface IERC1155MetadataInternal {
    event URI(string value, uint256 indexed tokenId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../Facets/DiamondCut/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct DiamondStorage {
        // maps function selectors to the facets that execute the functions.
        // and maps the selectors to their position in the selectorSlots array.
        // func selector => address facet, selector position
        mapping(bytes4 => bytes32) facets;
        // array of slots of function selectors.
        // each slot holds 8 function selectors.
        mapping(uint256 => bytes32) selectorSlots;
        // The number of function selectors in selectorSlots
        uint16 selectorCount;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    bytes32 constant CLEAR_ADDRESS_MASK = bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

    // Internal function version of diamondCut
    // This code is almost the same as the external diamondCut,
    // except it is using 'Facet[] memory _diamondCut' instead of
    // 'Facet[] calldata _diamondCut'.
    // The code is duplicated to prevent copying calldata to memory which
    // causes an error for a two dimensional array.
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        // Check if last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8" 
        if (selectorCount & 7 > 0) {
            // get last selectorSlot
            // "selectorSlot >> 3" is a gas efficient division by 8 "selectorSlot / 8"
            selectorSlot = ds.selectorSlots[selectorCount >> 3];
        }
        // loop through diamond cut
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            (selectorCount, selectorSlot) = addReplaceRemoveFacetSelectors(
                selectorCount,
                selectorSlot,
                _diamondCut[facetIndex].facetAddress,
                _diamondCut[facetIndex].action,
                _diamondCut[facetIndex].functionSelectors
            );
        }
        if (selectorCount != originalSelectorCount) {
            ds.selectorCount = uint16(selectorCount);
        }
        // If last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8" 
        if (selectorCount & 7 > 0) {
            // "selectorSlot >> 3" is a gas efficient division by 8 "selectorSlot / 8"
            ds.selectorSlots[selectorCount >> 3] = selectorSlot;
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addReplaceRemoveFacetSelectors(
        uint256 _selectorCount,
        bytes32 _selectorSlot,
        address _newFacetAddress,
        IDiamondCut.FacetCutAction _action,
        bytes4[] memory _selectors
    ) internal returns (uint256, bytes32) {
        DiamondStorage storage ds = diamondStorage();
        require(_selectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        if (_action == IDiamondCut.FacetCutAction.Add) {
            enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Add facet has no code");
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                require(address(bytes20(oldFacet)) == address(0), "LibDiamondCut: Can't add function that already exists");
                // add facet for selector
                ds.facets[selector] = bytes20(_newFacetAddress) | bytes32(_selectorCount);
                // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8" 
                // " << 5 is the same as multiplying by 32 ( * 32)
                uint256 selectorInSlotPosition = (_selectorCount & 7) << 5;
                // clear selector position in slot and add selector
                _selectorSlot = (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) | (bytes32(selector) >> selectorInSlotPosition);
                // if slot is full then write it to storage
                if (selectorInSlotPosition == 224) {
                    // "_selectorSlot >> 3" is a gas efficient division by 8 "_selectorSlot / 8"
                    ds.selectorSlots[_selectorCount >> 3] = _selectorSlot;
                    _selectorSlot = 0;
                }
                _selectorCount++;
            }
        } else if (_action == IDiamondCut.FacetCutAction.Replace) {
            enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Replace facet has no code");
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));
                // only useful if immutable functions exist
                require(oldFacetAddress != address(this), "LibDiamondCut: Can't replace immutable function");
                require(oldFacetAddress != _newFacetAddress, "LibDiamondCut: Can't replace function with same function");
                require(oldFacetAddress != address(0), "LibDiamondCut: Can't replace function that doesn't exist");
                // replace old facet address
                ds.facets[selector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(_newFacetAddress);
            }
        } else if (_action == IDiamondCut.FacetCutAction.Remove) {
            require(_newFacetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
            // "_selectorCount >> 3" is a gas efficient division by 8 "_selectorCount / 8"
            uint256 selectorSlotCount = _selectorCount >> 3;
            // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8" 
            uint256 selectorInSlotIndex = _selectorCount & 7;
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                if (_selectorSlot == 0) {
                    // get last selectorSlot
                    selectorSlotCount--;
                    _selectorSlot = ds.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                } else {
                    selectorInSlotIndex--;
                }
                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;
                // adding a block here prevents stack too deep error
                {
                    bytes4 selector = _selectors[selectorIndex];
                    bytes32 oldFacet = ds.facets[selector];
                    require(address(bytes20(oldFacet)) != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
                    // only useful if immutable functions exist
                    require(address(bytes20(oldFacet)) != address(this), "LibDiamondCut: Can't remove immutable function");
                    // replace selector with last selector in ds.facets
                    // gets the last selector
                    // " << 5 is the same as multiplying by 32 ( * 32)
                    lastSelector = bytes4(_selectorSlot << (selectorInSlotIndex << 5));
                    if (lastSelector != selector) {
                        // update last selector slot position info
                        ds.facets[lastSelector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(ds.facets[lastSelector]);
                    }
                    delete ds.facets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    // "oldSelectorCount >> 3" is a gas efficient division by 8 "oldSelectorCount / 8"
                    oldSelectorsSlotCount = oldSelectorCount >> 3;
                    // "oldSelectorCount & 7" is a gas efficient modulo by eight "oldSelectorCount % 8" 
                    // " << 5 is the same as multiplying by 32 ( * 32)
                    oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }
                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = ds.selectorSlots[oldSelectorsSlotCount];
                    // clears the selector we are deleting and puts the last selector in its place.
                    oldSelectorSlot =
                        (oldSelectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                    // update storage with the modified slot
                    ds.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    // clears the selector we are deleting and puts the last selector in its place.
                    _selectorSlot =
                        (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }
                if (selectorInSlotIndex == 0) {
                    delete ds.selectorSlots[selectorSlotCount];
                    _selectorSlot = 0;
                }
            }
            _selectorCount = selectorSlotCount * 8 + selectorInSlotIndex;
        } else {
            revert("LibDiamondCut: Incorrect FacetCutAction");
        }
        return (_selectorCount, _selectorSlot);
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            return;
        }
        enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");        
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { IAccessControl } from "./IAccessControl.sol";

contract AccessControlDummy is IAccessControl {
  function addAdmin(address newAdmin) external {}

  function removeAdmin(address oldAdmin) external {}
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { Role, ClanRole } from "../../Meta/DataStructures.sol";

library AccessControlStorage {
  struct State {
    mapping (address => Role) role;
    //knightId => ClanRole
    mapping (uint256 => ClanRole) clanRole;
  }

  bytes32 internal constant STORAGE_SLOT = keccak256("AccessControl.storage");

  function state() internal pure returns (State storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface IAccessControlEvents {
  event AdminAdded(address newAdmin);
  event AdminRemoved(address oldAdmin);
}

interface IAccessControlErrors {
  error AccessControlModifiers_CallerIsNotAdmin(address caller);
}

interface IAccessControl is IAccessControlEvents, IAccessControlErrors {
  function addAdmin(address newAdmin) external;

  function removeAdmin(address oldAdmin) external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { ClanRole } from "../../Meta/DataStructures.sol";
import { IClan } from "./IClan.sol";

contract ClanFacetDummy is IClan {
  function createClan(uint256 knightId, string calldata clanName) external {}

  function abandonClan(uint256 clanId, uint256 ownerId) external {}

  function setClanRole(uint256 clanId, uint256 knightId, ClanRole newRole, uint256 callerId) external {}

  function setClanName(uint256 clanId, string calldata newClanName) external {}

// Clan stakes and leveling
  function clanStake(uint256 clanId, uint256 amount) external {}

  function clanWithdraw(uint256 clanId, uint256 amount) external {}

  function clanWithdrawRequest(uint256 clanId, uint256 amount) external {}

//Join, Leave and Invite Proposals
  function joinClan(uint256 knightId, uint256 clanId) external {}

  function withdrawJoinClan(uint256 knightId, uint256 clanId) external {}

  function approveJoinClan(uint256 knightId, uint256 clanId, uint256 callerId) external {}

  function dismissJoinClan(uint256 knightId, uint256 clanId, uint256 callerId) external {}
  
  function kickFromClan(uint256 knightId, uint256 clanId, uint256 callerId) external {}

  function leaveClan(uint256 knightId, uint256 clanId) external {}


  
  function getClanLeader(uint clanId) external view returns(uint256) {}

  function getClanRole(uint knightId) external view returns(ClanRole) {}

  function getClanTotalMembers(uint clanId) external view returns(uint) {}
  
  function getClanStake(uint clanId) external view returns(uint256) {}

  function getClanLevel(uint clanId) external view returns(uint) {}

  function getStakeOf(address benefactor, uint clanId) external view returns(uint256) {}

  function getClanLevelThreshold(uint level) external view returns(uint) {}

  function getClanMaxLevel() external view returns(uint) {}

  function getClanJoinProposal(uint256 knightId) external view returns(uint256) {}

  function getClanInfo(uint clanId) external view returns(uint256, uint256, uint256, uint256) {}

  function getClanConfig() external view returns(uint256[] memory, uint256[] memory) {}

  function getClanKnightInfo(uint knightId) external view returns(uint256, uint256, ClanRole, uint256) {}

  function getClanName(uint256 clanId) external view returns(string memory) {}
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import { Clan, ClanRole } from "../../Meta/DataStructures.sol";

library ClanStorage {
  struct State {
    uint[] levelThresholds;
    uint[] maxMembers;
    uint256 clansInTotal;

    //Clan => clan leader id
    mapping(uint256 => uint256) clanLeader;
    //Clan => stake amount
    mapping(uint256 => uint256) clanStake;
    //Clan => amount of members in clanId
    mapping(uint256 => uint256) clanTotalMembers;
    //Clan => level of clanId
    mapping(uint256 => uint256) clanLevel;
    //Clan => name of said clan
    mapping(uint256 => string) clanName;
    //Clan name => taken or not
    mapping(string => bool) clanNameTaken;
    
    //Knight => id of clan where join proposal is sent
    mapping (uint256 => uint256) joinProposal;
    //Knight => end of cooldown
    mapping(uint256 => uint256) clanActivityCooldown;
    //Knight => clan join proposal sent
    mapping(uint256 => bool) joinProposalPending;
    //Kinight => Role in clan
    mapping(uint256 => ClanRole) roleInClan;
    //Knight => kick cooldown duration
    mapping(uint256 => uint) clanKickCooldown;

    //address => clanId => amount
    mapping (address => mapping (uint => uint256)) stake;
    //address => withdrawal cooldown
    mapping (address => uint256) withdrawalCooldown;
    //address => allowed withdrawal
    mapping (address => uint256) allowedWithdrawal;
  }

  bytes32 internal constant STORAGE_SLOT = keccak256("Clan.storage");

  function state() internal pure returns (State storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { ClanRole } from "../../Meta/DataStructures.sol";

interface IClanEvents {
  event ClanCreated(uint clanId, uint256 knightId);
  event ClanAbandoned(uint clanId, uint256 knightId);
  event ClanNewRole(uint clanId, uint256 knightId, ClanRole newRole);
  event ClanNewName(uint256 clanId, string newClanName);
  event ClanNewLevel(uint256 clanId, uint256 newLevel);

  event ClanStakeAdded(address user, uint clanId, uint amount, uint256 clanStakeTotal, uint256 walletStakeTotal);
  event ClanStakeWithdrawRequest(address user, uint256 clanId, uint256 amount, uint256 cooldownEnd);
  event ClanStakeWithdrawn(address user, uint clanId, uint amount, uint256 clanStakeTotal, uint256 walletStakeTotal);
  event ClanLeveledUp(uint clanId, uint newLevel);
  event ClanLeveledDown(uint clanId, uint newLevel);

  event ClanJoinProposalSent(uint clanId, uint256 knightId);
  event ClanJoinProposalWithdrawn(uint clanId, uint256 knightId);
  event ClanJoinProposalAccepted(uint clanId, uint256 knightId, uint256 callerId);
  event ClanJoinProposalDismissed(uint clanId, uint256 knightId);
  event ClanKnightKicked(uint clanId, uint256 knightId, uint256 callerId);
  event ClanKnightLeft(uint clanId, uint256 knightId);
  event ClanKnightQuit(uint clanId, uint256 knightId);
  event ClanKnightJoined(uint clanId, uint256 knightId);
}

interface IClanErrors {
  error ClanModifiers_ClanDoesntExist(uint256 clanId);
  error ClanModifiers_KnightIsNotClanLeader(uint256 knightId, uint256 clanId);
  error ClanModifiers_KnightIsClanLeader(uint256 knightId, uint256 clanId);
  error ClanModifiers_KnightInSomeClan(uint256 knightId, uint256 clanId);
  error ClanModifiers_KnightOnClanActivityCooldown(uint256 knightId);
  error ClanModifiers_KnightNotInThisClan(uint256 knightId, uint256 clanId);
  error ClanModifiers_AboveMaxMembers(uint256 clanId);
  error ClanModifiers_JoinProposalToSomeClanExists(uint256 knightId, uint256 clanId);
  error ClanModifiers_KickingMembersOnCooldownForThisKnight(uint256 knightId);
  error ClanModifiers_ClanOwnersCantCallThis(uint256 knightId);
  error ClanModifiers_ClanNameTaken(string clanName);
  error ClanModifiers_ClanNameWrongLength(string clanName);
  error ClanModifiers_UserOnWithdrawalCooldown(address user);
  error ClanModifiers_WithdrawalAmountAboveStake(address user, uint256 clanId, uint256 withdrawalAmount);
  error ClanModifiers_NotClanOwner(uint256 knightId);

  error ClanFacet_InsufficientStake(uint256 stakeAvalible, uint256 withdrawAmount);
  error ClanFacet_CantJoinAlreadyInClan(uint256 knightId, uint256 clanId);
  error ClanFacet_NoProposalOrNotClanLeader(uint256 knightId, uint256 clanId);
  error ClanFacet_CantKickThisMember(uint256 knightId, uint256 clanId, uint256 kickerId);
  error ClanFacet_CantJoinOtherClanWhileBeingAClanLeader(uint256 knightId, uint256 clanId, uint256 kickerId);
  error ClanFacet_CantAssignNewRoleToThisCharacter(uint256 clanId, uint256 knightId, ClanRole newRole, uint256 callerId);
  error ClanFacet_NoJoinProposal(uint256 knightId, uint256 clanId);
  error ClanFacet_InsufficientRolePriveleges(uint256 callerId);
}

interface IClanGetters {
  function getClanLeader(uint clanId) external view returns(uint256);

  function getClanRole(uint knightId) external view returns(ClanRole);

  function getClanTotalMembers(uint clanId) external view returns(uint);
  
  function getClanStake(uint clanId) external view returns(uint256);

  function getClanLevel(uint clanId) external view returns(uint);

  function getStakeOf(address user, uint clanId) external view returns(uint256);

  function getClanLevelThreshold(uint level) external view returns(uint);

  function getClanMaxLevel() external view returns(uint);

  function getClanJoinProposal(uint256 knightId) external view returns(uint256);

  function getClanInfo(uint clanId) external view returns(uint256, uint256, uint256, uint256);

  function getClanConfig() external view returns(uint256[] memory, uint256[] memory);

  function getClanKnightInfo(uint knightId) external view returns(uint256, uint256, ClanRole, uint256);
  
  function getClanName(uint256 clanId) external view returns(string memory);
}

interface IClan is IClanGetters, IClanEvents, IClanErrors {
  function createClan(uint256 knightId, string calldata clanName) external;

  function abandonClan(uint256 clanId, uint256 ownerId) external;

  function setClanRole(uint256 clanId, uint256 knightId, ClanRole newRole, uint256 callerId) external;

  function setClanName(uint256 clanId, string calldata newClanName) external;

// Clan stakes and leveling
  function clanStake(uint256 clanId, uint256 amount) external;

  function clanWithdraw(uint256 clanId, uint256 amount) external;

  function clanWithdrawRequest(uint256 clanId, uint256 amount) external;

//Join, Leave and Invite Proposals
  function joinClan(uint256 knightId, uint256 clanId) external;

  function withdrawJoinClan(uint256 knightId, uint256 clanId) external;

  function approveJoinClan(uint256 knightId, uint256 clanId, uint256 callerId) external;

  function dismissJoinClan(uint256 knightId, uint256 clanId, uint256 callerId) external;
  
  function kickFromClan(uint256 knightId, uint256 clanId, uint256 callerId) external;

  function leaveClan(uint256 knightId, uint256 clanId) external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { Pool, Coin } from "../../Meta/DataStructures.sol";
import { IDebug } from "../Debug/IDebug.sol";

contract DebugFacetDummy is IDebug {
  function debugSetBaseURI(string memory baseURI) external {}

  function debugSetTokenURI(uint256 tokenId, string memory tokenURI) external {}

  function debugEnablePoolCoinMinting(Pool pool, Coin coin) external {}

  function debugDisablePoolCoinMinting(Pool pool, Coin coin) external {}

  function debugSetCoinAddress(Coin coin, address newAddress) external {}

  function debugSetACoinAddress(Coin coin, address newAddress) external {}

  function debugSetKnightPrice(Coin coin, uint256 newPrice) external {}

  function debugSetLevelThresholds(uint[] memory newThresholds) external {}
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { Pool, Coin } from "../../Meta/DataStructures.sol";

interface IDebug {
  function debugSetBaseURI(string memory baseURI) external;

  function debugSetTokenURI(uint256 tokenId, string memory tokenURI) external;

  function debugEnablePoolCoinMinting(Pool pool, Coin coin) external;

  function debugDisablePoolCoinMinting(Pool pool, Coin coin) external;

  function debugSetCoinAddress(Coin coin, address newAddress) external;

  function debugSetACoinAddress(Coin coin, address newAddress) external;

  function debugSetKnightPrice(Coin coin, uint256 newPrice) external;

  function debugSetLevelThresholds(uint[] memory newThresholds) external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { IDiamondCut } from "./IDiamondCut.sol";

contract DiamondCutFacetDummy is IDiamondCut {
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { IDiamondLoupe } from "./IDiamondLoupe.sol";
import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";

contract DiamondLoupeFacetDummy is IDiamondLoupe, IERC165 {
    function facets() external override view returns (Facet[] memory facets_) {}

    function facetFunctionSelectors(address _facet) external override view returns (bytes4[] memory _facetFunctionSelectors) {}

    function facetAddresses() external override view returns (address[] memory facetAddresses_) {}

    function facetAddress(bytes4 _functionSelector) external override view returns (address facetAddress_) {}
    
    function supportsInterface(bytes4 _interfaceId) external virtual override view returns (bool) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { StorageSlot } from "@openzeppelin/contracts/utils/StorageSlot.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { LibDiamond } from "../../Diamond/LibDiamond.sol";

interface IEtherscan {
  function setDummyImplementation(address newImplementation) external;
  function getDummyImplementation() external view returns (address);
  event DummyUpgraded(address newImplementation);
}

contract EtherscanFacet is IEtherscan {

  bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  function setDummyImplementation(address newImplementation) external onlyOwner {
    require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
    StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    emit DummyUpgraded(newImplementation);
  }

  function getDummyImplementation() external view returns (address) {
    return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
  }

  modifier onlyOwner() {
    LibDiamond.enforceIsContractOwner();
    _;
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { IEtherscan } from "../Etherscan/EtherscanFacet.sol";

contract EtherscanFacetDummy is IEtherscan {
  function setDummyImplementation(address newImplementation) external {}
  function getDummyImplementation() external view returns (address) {}
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { DiamondCutFacetDummy } from "../DiamondCut/DiamondCutFacetDummy.sol";
import { DiamondLoupeFacetDummy } from "../DiamondLoupe/DiamondLoupeFacetDummy.sol";
import { OwnershipFacetDummy } from "../Ownership/OwnershipFacetDummy.sol";
import { ItemsFacetDummy } from "../Items/ItemsFacetDummy.sol";
import { ClanFacetDummy } from "../Clan/ClanFacetDummy.sol";
import { KnightFacetDummy } from "../Knight/KnightFacetDummy.sol";
import { SBVHookFacetDummy } from "../SBVHook/SBVHookFacetDummy.sol";
import { TreasuryFacetDummy } from "../Treasury/TreasuryFacetDummy.sol";
import { GearFacetDummy } from "../Gear/GearFacetDummy.sol";
import { EtherscanFacetDummy } from "../Etherscan/EtherscanFacetDummy.sol";
import { DebugFacetDummy } from "../Debug/DebugFacetDummy.sol";
import { AccessControlDummy } from "../AccessControl/AccessControlDummy.sol";
import { SiegeFacetDummy } from "../Siege/SiegeFacetDummy.sol";
import { ConfigEvents } from "../../Init&Updates/SBInit.sol";

import { IStableBattle } from "../../Meta/IStableBattle.sol";
import { IERC165 } from "@solidstate/contracts/introspection/ERC165.sol";

/*
  This is a dummy implementation of StableBattle contracts.
  This contract is needed due to Etherscan proxy recognition difficulties.
  This implementation will be updated alongside StableBattle Diamond updates.
  
  To get addresses of the real implementation code either use Louper.dev
  or look into scripts/config/(network) in the github repo
*/

contract StableBattleDummy is
  IStableBattle,
  DiamondCutFacetDummy,
  DiamondLoupeFacetDummy,
  OwnershipFacetDummy,
  ItemsFacetDummy,
  ClanFacetDummy,
  KnightFacetDummy,
//SBVHookFacetDummy,
//TreasuryFacetDummy,
//GearFacetDummy,
  EtherscanFacetDummy,
  DebugFacetDummy,
  AccessControlDummy,
  SiegeFacetDummy
{
  function supportsInterface(bytes4 interfaceId)
    external
    view
    override(DiamondLoupeFacetDummy, ItemsFacetDummy, IERC165)
    returns (bool)
  {}
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { gearSlot } from "../../Meta/DataStructures.sol";
import { IGear } from "./IGear.sol";

contract GearFacetDummy is IGear {

//Gear Facet
  function createGear(uint id, gearSlot slot, string memory name) external {}

  function updateKnightGear(uint256 knightId, uint256[] memory items) external {}

  function mintGear(uint id, uint amount, address to) external {}

  function mintGear(uint id, uint amount) external {}

  function burnGear(uint id, uint amount, address from) external {}

  function burnGear(uint id, uint amount) external {}

//Gear Getters
  function getGearSlotOf(uint256 itemId) external view returns(gearSlot) {}

  function getGearName(uint256 itemId) external view returns(string memory) {}

  function getEquipmentInSlot(uint256 knightId, gearSlot slot) external view returns(uint256) {}

  function getGearEquipable(address account, uint256 itemId) external view returns(uint256) {}

  function getGearEquipable(uint256 itemId) external view returns(uint256) {}
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import { gearSlot } from "../../Meta/DataStructures.sol";

library GearStorage {
  struct State {
    uint256 gearRangeLeft;
    uint256 gearRangeRight;
    //knightId => gearSlot => itemId
    //Returns an itemId of item equipped in gearSlot for Knight with knightId
    mapping(uint256 => mapping(gearSlot => uint256)) knightSlotItem;
    //itemId => slot
    //Returns gear slot for particular item per itemId
    mapping(uint256 => gearSlot) gearSlot;
    //itemId => itemName
    //Returns a name of particular item per itemId
    mapping(uint256 => string) gearName;
    //knightId => itemId => amount 
    //Returns amount of nonequippable (either already equipped or lended or in pending sell order)
      //items per itemId for a particular wallet
    mapping(address => mapping(uint256 => uint256)) notEquippable;
  }

  bytes32 internal constant STORAGE_SLOT = keccak256("Gear.storage");

  function state() internal pure returns (State storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { gearSlot } from "../../Meta/DataStructures.sol";

interface IGearEvents {
  event GearCreated(uint256 id, gearSlot slot, string name);
  event GearMinted(uint256 id, uint256 amount, address to);
  event GearBurned(uint256 id, uint256 amount, address from);
  event GearEquipped(uint256 knightId, gearSlot slot, uint256 itemId);
}

interface IGearErrors {
  error GearModifiers_WrongGearId(uint256 gearId);
}

interface IGearGetters {
  function getGearSlotOf(uint256 itemId) external view returns(gearSlot);

  function getGearName(uint256 itemId) external view returns(string memory);

  function getEquipmentInSlot(uint256 knightId, gearSlot slot) external view returns(uint256);

  function getGearEquipable(address account, uint256 itemId) external view returns(uint256);

  function getGearEquipable(uint256 itemId) external view returns(uint256);
}

interface IGear is IGearEvents, IGearErrors, IGearGetters {
  function createGear(uint id, gearSlot slot, string memory name) external;

  function updateKnightGear(uint256 knightId, uint256[] memory items) external;

  function mintGear(uint id, uint amount, address to) external;

  function mintGear(uint id, uint amount) external;

  function burnGear(uint id, uint amount, address from) external;

  function burnGear(uint id, uint amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ISolidStateERC1155 } from "@solidstate/contracts/token/ERC1155/ISolidStateERC1155.sol";

interface IItemsEvents {}

interface IItemsErrors {
  error ItemsModifiers_DontOwnThisItem(uint256 itemId);
}

interface IItemsGetters {}

interface IItems is ISolidStateERC1155, IItemsEvents, IItemsErrors, IItemsGetters {}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { IItems } from "../Items/IItems.sol";

contract ItemsFacetDummy is IItems {

//ERC165 openzeppelin thing
  function supportsInterface(bytes4 interfaceId) external virtual view returns (bool) {}

//ERC1155
  function balanceOf(address account, uint256 id)
    external
    view
    returns (uint256) {}
      
  function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
    external
    view
    returns (uint256[] memory) {}
      
  function isApprovedForAll(address account, address operator)
    external
    view
    returns (bool) {}
      
  function setApprovalForAll(address operator, bool status) external {}
  
  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes calldata data
  ) external {}
  
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] calldata ids,
    uint256[] calldata amounts,
    bytes calldata data
  ) external {}

//ERC1155Enumerable
  function totalSupply(uint256 id) external view returns (uint256) {}
  
  function totalHolders(uint256 id) external view returns (uint256) {}
  
  function accountsByToken(uint256 id)
      external
      view
      returns (address[] memory) {}
      
  function tokensByAccount(address account)
      external
      view
      returns (uint256[] memory) {}

//ERC1155Metadata
  function uri(uint256 tokenId) external view returns (string memory) {}
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { Coin, Pool, Knight } from "../../Meta/DataStructures.sol";

interface IKnightEvents {
  event KnightMinted (uint knightId, address wallet, Pool p, Coin c);
  event KnightBurned (uint knightId, address wallet, Pool p, Coin c);
}

interface IKnightErrors {
  error KnightFacet_InsufficientFunds(uint256 avalible, uint256 required);
  error KnightFacet_AbandonLeaderRoleBeforeBurning(uint256 knightId, uint256 clanId);
  error KnightFacet_CantAppointYourselfAsHeir(uint256 knightId);
  error KnightFacet_HeirIsNotKnight(uint256 heirId);
  error KnightFacet_HeirIsNotInTheSameClan(uint256 clanId, uint256 heirId);

  error KnightModifiers_WrongKnightId(uint256 wrongId);
  error KnightModifiers_KnightNotInAnyClan(uint256 knightId);
  error KnightModifiers_KnightNotInClan(uint256 knightId, uint256 wrongClanId, uint256 correctClanId);
  error KnightModifiers_KnightInSomeClan(uint256 knightId, uint256 clanId);
}

interface IKnightGetters {
  function getKnightInfo(uint256 knightId) external view returns(Knight memory);

  function getKnightPool(uint256 knightId) external view returns(Pool);

  function getKnightCoin(uint256 knightId) external view returns(Coin);

  function getKnightOwner(uint256 knightId) external view returns(address);

  function getKnightClan(uint256 knightId) external view returns(uint256);

  function getKnightPrice(Coin coin) external view returns (uint256);

  //returns amount of minted knights for a particular coin & pool
  function getKnightsMinted(Pool pool, Coin coin) external view returns (uint256);

  //returns amount of minted knights for any coin in a particular pool
  function getKnightsMintedOfPool(Pool pool) external view returns (uint256 knightsMintedTotal);

  //returns amount of minted knights for any pool in a particular coin
  function getKnightsMintedOfCoin(Coin coin) external view returns (uint256);

  //returns a total amount of minted knights
  function getKnightsMintedTotal() external view returns (uint256);

  //returns amount of burned knights for a particular coin & pool
  function getKnightsBurned(Pool pool, Coin coin) external view returns (uint256);

  //returns amount of burned knights for any coin in a particular pool
  function getKnightsBurnedOfPool(Pool pool) external view returns (uint256 knightsBurnedTotal);

  //returns amount of burned knights for any pool in a particular coin
  function getKnightsBurnedOfCoin(Coin coin) external view returns (uint256);

  //returns a total amount of burned knights
  function getKnightsBurnedTotal() external view returns (uint256);

  function getTotalKnightSupply() external view returns (uint256);

  function getPoolAndCoinCompatibility(Pool p, Coin c) external view returns (bool);
}

interface IKnight is IKnightEvents, IKnightErrors, IKnightGetters {
  function mintKnight(Pool p, Coin c) external;

  function burnKnight (uint256 knightId, uint256 heirId) external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { Coin, Pool, Knight } from "../../Meta/DataStructures.sol";
import { IKnight } from "./IKnight.sol";

contract KnightFacetDummy is IKnight {

//Knight Facet
  function mintKnight(Pool p, Coin c) external {}

  function burnKnight (uint256 knightId, uint256 heirId) external {}

//Knight Getters
  function getKnightInfo(uint256 knightId) external view returns(Knight memory) {}

  function getKnightPool(uint256 knightId) external view returns(Pool) {}

  function getKnightCoin(uint256 knightId) external view returns(Coin) {}

  function getKnightOwner(uint256 knightId) external view returns(address) {}

  function getKnightClan(uint256 knightId) external view returns(uint256) {}

  function getKnightPrice(Coin coin) external view returns (uint256) {}

  //returns amount of minted knights for a particular coin & pool
  function getKnightsMinted(Pool pool, Coin coin) external view returns (uint256) {}

  //returns amount of minted knights for any coin in a particular pool
  function getKnightsMintedOfPool(Pool pool) external view returns (uint256 knightsMintedTotal) {}

  //returns amount of minted knights for any pool in a particular coin
  function getKnightsMintedOfCoin(Coin coin) external view returns (uint256) {}

  //returns a total amount of minted knights
  function getKnightsMintedTotal() external view returns (uint256) {}

  //returns amount of burned knights for a particular coin & pool
  function getKnightsBurned(Pool pool, Coin coin) external view returns (uint256) {}

  //returns amount of burned knights for any coin in a particular pool
  function getKnightsBurnedOfPool(Pool pool) external view returns (uint256 knightsBurnedTotal) {}

  //returns amount of burned knights for any pool in a particular coin
  function getKnightsBurnedOfCoin(Coin coin) external view returns (uint256) {}

  //returns a total amount of burned knights
  function getKnightsBurnedTotal() external view returns (uint256) {}

  function getTotalKnightSupply() external view returns (uint256) {}

  function getPoolAndCoinCompatibility(Pool p, Coin c) external view returns (bool) {}
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import { Pool, Coin, Knight } from "../../Meta/DataStructures.sol";

library KnightStorage {
  struct State {
    mapping(uint256 => Knight) knight;
    mapping(Coin => uint256) knightPrice;
    mapping(Pool => mapping(Coin => uint256)) knightsMinted;
    mapping(Pool => mapping(Coin => uint256)) knightsBurned;
  }

  bytes32 internal constant STORAGE_SLOT = keccak256("Knight.storage");

  function state() internal pure returns (State storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC173 } from "./IERC173.sol";

contract OwnershipFacetDummy is IERC173 {
    function transferOwnership(address _newOwner) external override {}

    function owner() external override view returns (address owner_) {}
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface ISBVHook {
  function SBV_hook(uint id, address newOwner, bool mint) external;

  event VillageInfoUpdated(uint id, address newOwner, uint villageAmount);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { ISBVHook } from "./ISBVHook.sol";

contract SBVHookFacetDummy is ISBVHook {
  function SBV_hook(uint id, address newOwner, bool mint) external {}
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface ISiegeEvents {
  event SiegeNewWinner(uint256 clanId, uint256 knightId, address user, uint256 reward);
  event SiegeRewardClaimed(address user, uint256 amount);
}

interface ISiegeErrors {
  error ClaimAmountExceedsReward(uint256 amount, uint256 reward, address user);
  error NoRewardToClaim(address user);
}

interface ISiegeGetters {
  function getSiegeRewardTotal() external view returns(uint256);
  function getSiegeReward(address user) external view returns(uint256);
  function getSiegeWinnerClanId() external view returns(uint256);
  function getSiegeWinnerKnightId() external view returns(uint256);
  function getSiegeWinnerAddress() external view returns(address);
  function getSiegeWinnerInfo() external view returns(uint256, uint256);
  function getSiegeYield() external view returns(uint256);
  function getYieldTotal() external view returns(uint256);
}

interface ISiege is ISiegeEvents, ISiegeErrors, ISiegeGetters {
  function setSiegeWinner(uint256 clanId, uint256 knigthId, address user) external;
  function claimSiegeReward(address user, uint256 amount) external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { ISiege } from "../Siege/ISiege.sol";

contract SiegeFacetDummy is ISiege {
  function getSiegeRewardTotal() external view returns(uint256) {}
  function getSiegeReward(address user) external view returns(uint256) {}
  function getSiegeWinnerClanId() external view returns(uint256) {}
  function getSiegeWinnerKnightId() external view returns(uint256) {}
  function getSiegeWinnerAddress() external view returns(address) {}
  function getSiegeWinnerInfo() external view returns(uint256, uint256) {}
  function getSiegeYield() external view returns(uint256) {}
  function getYieldTotal() external view returns(uint256) {}

  function setSiegeWinner(uint256 clanId, uint256 knigthId, address user) external {}
  function claimSiegeReward(address user, uint256 amount) external {}
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface ITreasuryEvents {
  event BeneficiaryUpdated(uint village, address beneficiary);
  event NewTaxSet(uint tax);
}

interface ITreasuryErrors {
  error TreasuryModifiers_OnlyCallableByCastleHolder();
  error TreasuryFacet_CantSetTaxAboveThreshold(uint8 threshold);
}

interface ITreasuryGetters {
  function getCastleTax() external view returns(uint);
  function getLastBlock() external view returns(uint);
  function getRewardPerBlock() external view returns(uint);
}

interface ITreasury is ITreasuryEvents, ITreasuryErrors, ITreasuryGetters {
  function claimRewards() external;
  function setTax(uint8 tax) external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { ITreasury } from "./ITreasury.sol";

contract TreasuryFacetDummy is ITreasury {

//Treasury Facet
  function claimRewards() external{}

  function setTax(uint8 tax) external{}

//Public Getters
  function getCastleTax() external view returns(uint){}
  
  function getLastBlock() external view returns(uint){}

  function getRewardPerBlock() external view returns(uint){}
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

library TreasuryStorage {
  struct State {
    uint8 castleTax;
    uint lastBlock;
    uint rewardPerBlock;

    //Villages information
    uint256 villageAmount;
    mapping (uint256 => address) villageOwner;
  }

  bytes32 internal constant STORAGE_SLOT = keccak256("Treasury.storage");

  function state() internal pure returns (State storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.10;

interface ConfigEvents {
  event ClanNewConfig(uint[] levelThresholds, uint[] maxMembersPerLevel);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.10;

import { LibDiamond } from "../Diamond/LibDiamond.sol";
import { Coin, Pool, Role } from "../Meta/DataStructures.sol";

import { ClanStorage } from "../Facets/Clan/ClanStorage.sol";
import { KnightStorage } from "../Facets/Knight/KnightStorage.sol";
import { MetaStorage } from "../Meta/MetaStorage.sol";
import { TreasuryStorage } from "../Facets/Treasury/TreasuryStorage.sol";
import { GearStorage } from "../Facets/Gear/GearStorage.sol";
import { AccessControlStorage } from "../Facets/AccessControl/AccessControlStorage.sol";
import { ERC1155MetadataStorage } from "@solidstate/contracts/token/ERC1155/metadata/ERC1155MetadataStorage.sol";

import { IERC1155 } from "@openzeppelin/contracts/interfaces/IERC1155.sol";
import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";
import { IERC173 } from "../Facets/Ownership/IERC173.sol";
import { IDiamondCut } from "../Facets/DiamondCut/IDiamondCut.sol";
import { IDiamondLoupe } from "../Facets/DiamondLoupe/IDiamondLoupe.sol";

import { ConfigEvents } from "./ConfigEvents.sol";

uint256 constant BEER_DECIMALS = 1e6;

contract SBInit is ConfigEvents {
  struct Args {
    address AAVE_address;

    address USDT_address;
    address USDC_address;
    address EURS_address;

    address AAVE_USDT_address;
    address AAVE_USDC_address;
    address AAVE_EURS_address;

    address BEER_address;
    address SBV_address;
  }

  function SB_init(Args memory _args) external {
  // Assign supported interfaces
    LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
    ds.supportedInterfaces[type(IERC165).interfaceId] = true;
    ds.supportedInterfaces[type(IERC173).interfaceId] = true;
    ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
    ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
    ds.supportedInterfaces[type(IERC1155).interfaceId] = true;

  // Assign Meta Storage
    // Token & Villages
      MetaStorage.state().BEER = _args.BEER_address;
      MetaStorage.state().SBV = _args.SBV_address;
    //AAVE
    MetaStorage.state().pool[Pool.AAVE] = _args.AAVE_address;
    
    MetaStorage.state().coin[Coin.USDT] = _args.USDT_address;
    MetaStorage.state().coin[Coin.USDC] = _args.USDC_address;
    MetaStorage.state().coin[Coin.EURS] = _args.EURS_address;
    
    MetaStorage.state().acoin[Coin.USDT] = _args.AAVE_USDT_address;
    MetaStorage.state().acoin[Coin.USDC] = _args.AAVE_USDC_address;
    MetaStorage.state().acoin[Coin.EURS] = _args.AAVE_EURS_address;

    MetaStorage.state().compatible[Pool.AAVE][Coin.USDT] = true;
    MetaStorage.state().compatible[Pool.AAVE][Coin.USDC] = true;
    //Test
    MetaStorage.state().compatible[Pool.TEST][Coin.TEST] = true;

  //Knight facet
    //Knight enumeration begins from type(uint256).max
    ///for better compactibility with adding new item types in the future
    KnightStorage.state().knightPrice[Coin.USDT] = 1e9;
    KnightStorage.state().knightPrice[Coin.USDC] = 1e9;

  //Gear Facet
    //all items in [256, 1e12) are gear
    GearStorage.state().gearRangeLeft = 256; //type(uint8).max + 1 See unequipGear in GearFacet
    GearStorage.state().gearRangeRight = 1e12;
  
  //Totem Facet
    //all items in [1e12, 2e12) are totems
    //TotemStorage.state().totemRangeLeft = 1e12;
    //TotemStorage.state().totemRangeRight = 2e12;

  //Items & ERC1155 Facet
    ERC1155MetadataStorage.layout().baseURI = "http://test1.stablebattle.io:5000/api/nft/";

  //Clan Facet
    ClanStorage.state().levelThresholds = [
      0, 
      40000  * BEER_DECIMALS,
      110000 * BEER_DECIMALS,
      230000 * BEER_DECIMALS,
      430000 * BEER_DECIMALS,
      760000 * BEER_DECIMALS
    ];
    ClanStorage.state().maxMembers = [10, 20, 22, 24, 26, 28, 30];
    emit ClanNewConfig(ClanStorage.state().levelThresholds, ClanStorage.state().maxMembers);

  //Treasury Facet
    TreasuryStorage.state().castleTax = 37;
    TreasuryStorage.state().lastBlock = block.number;
    TreasuryStorage.state().rewardPerBlock = 100;

  //AccessControl Facet
    AccessControlStorage.state().role[msg.sender] = Role.ADMIN;
    AccessControlStorage.state().role[0xFcB5320ad1C7c5221709A2d25bAdcb64B1ffF860] = Role.ADMIN;
    AccessControlStorage.state().role[0xdff7D2C6E777aE6F15782571a17e5DEE8aa21326] = Role.ADMIN;
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

enum Pool { NONE, TEST, AAVE }

enum Coin { NONE, TEST, USDT, USDC, EURS }

struct Knight {
  Pool pool;
  Coin coin;
  address owner;
  uint256 inClan;
}

enum gearSlot { NONE, WEAPON, SHIELD, HELMET, ARMOR, PANTS, SLEEVES, GLOVES, BOOTS, JEWELRY, CLOAK }

struct Clan {
  uint256 leader;
  uint256 stake;
  uint totalMembers;
  uint level;
}

enum Role { NONE, ADMIN }

enum ClanRole { NONE, PRIVATE, MOD, ADMIN, OWNER }

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { IDiamondCut } from "../Facets/DiamondCut/IDiamondCut.sol";
import { IDiamondLoupe } from "../Facets/DiamondLoupe/IDiamondLoupe.sol";
import { IERC173 as IOwnership } from "../Facets/Ownership/IERC173.sol";
import { IItems } from "../Facets/Items/IItems.sol";
import { IClan } from "../Facets/Clan/IClan.sol";
import { IKnight } from "../Facets/Knight/IKnight.sol";
import { ISBVHook } from "../Facets/SBVHook/ISBVHook.sol";
import { ITreasury } from "../Facets/Treasury/ITreasury.sol";
import { IGear } from "../Facets/Gear/IGear.sol";
import { IEtherscan } from "../Facets/Etherscan/EtherscanFacet.sol";
import { IDebug } from "../Facets/Debug/IDebug.sol";
import { IAccessControl } from "../Facets/AccessControl/IAccessControl.sol";
import { ISiege } from "../Facets/Siege/ISiege.sol";
import { ConfigEvents } from "../Init&Updates/ConfigEvents.sol";

interface IStableBattle is
  IDiamondCut,
  IDiamondLoupe,
  IOwnership,
  IItems,
  IClan,
  IKnight,
//ISBVHook,
//ITreasury,
//IGear,
  IEtherscan,
  IDebug,
  IAccessControl,
  ISiege,
  ConfigEvents
{}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import { Coin, Pool } from "../Meta/DataStructures.sol";

library MetaStorage {
  struct State {
    // StableBattle EIP20 Token address
    address BEER;
    // StableBattle EIP721 Village address
    address SBV;

    mapping (Pool => address) pool;
    mapping (Coin => address) coin;
    mapping (Coin => address) acoin;
    mapping (Pool => mapping (Coin => bool)) compatible;
  }

  bytes32 internal constant STORAGE_SLOT = keccak256("Meta.storage");

  function state() internal pure returns (State storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}