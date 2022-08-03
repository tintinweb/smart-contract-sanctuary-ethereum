// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./HelperOwnable.sol";
import "./storage/LibHelperFeatureStorage.sol";


contract AggTraderHelper is HelperOwnable {

    event FeatureFunctionUpdated(bytes4 indexed selector, address oldFeature, address newFeature);

    function registerFeature(address feature, bytes4[] calldata methodIDs) external onlyOwner {
        unchecked {
            LibHelperFeatureStorage.Storage storage stor = LibHelperFeatureStorage.getStorage();
            for (uint256 i = 0; i < methodIDs.length; ++i) {
                bytes4 selector = methodIDs[i];
                address oldFeature = stor.impls[selector];
                stor.impls[selector] = feature;
                emit FeatureFunctionUpdated(selector, oldFeature, feature);
            }
        }
    }

    function registerFeatures(address[] calldata features, bytes4[][] calldata methodIDs) external onlyOwner {
        require(features.length == methodIDs.length, "registerFeatures: mismatched inputs.");
        unchecked {
            LibHelperFeatureStorage.Storage storage stor = LibHelperFeatureStorage.getStorage();
            for (uint256 i = 0; i < methodIDs.length; ++i) {
                // register feature
                address feature = features[i];
                bytes4[] calldata featureMethodIDs = methodIDs[i];
                for (uint256 j = 0; j < featureMethodIDs.length; ++j) {
                    bytes4 selector = featureMethodIDs[j];
                    address oldFeature = stor.impls[selector];
                    stor.impls[selector] = feature;
                    emit FeatureFunctionUpdated(selector, oldFeature, feature);
                }
            }
        }
    }

    function getFeature(bytes4 methodID) external view returns (address feature) {
        return LibHelperFeatureStorage.getStorage().impls[methodID];
    }

    /// @dev Fallback for just receiving ether.
    receive() external payable {}

    /// @dev Forwards calls to the appropriate implementation contract.
    fallback() external payable {
        bytes memory data = msg.data;
        bytes4 selector;
        assembly {
            selector := mload(add(data, 32))
            // Solidity does not require us to clean the trailing bytes.
            // We do it anyway
            selector := and(selector, 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)
        }

        address feature = LibHelperFeatureStorage.getStorage().impls[selector];
        require(feature != address(0), "Not implemented method.");

        (bool success, ) = feature.delegatecall(data);
        if (success) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                return(0, returndatasize())
            }
        } else {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function rescueETH(address recipient) external onlyOwner {
        if (address(this).balance > 0) {
            (bool success,) = payable(recipient).call{value: address(this).balance}("");
            require(success, "_transferEth/TRANSFER_FAILED");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

pragma solidity ^0.8.15;

import "./storage/LibHelperFeatureStorage.sol";


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract HelperOwnable {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        if (owner() == address(0)) {
            _transferOwnership(msg.sender);
        }
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return LibHelperFeatureStorage.getStorage().owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) private {
        LibHelperFeatureStorage.Storage storage stor = LibHelperFeatureStorage.getStorage();
        address oldOwner = stor.owner;
        stor.owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./LibHelperStorage.sol";


library LibHelperFeatureStorage {

    struct Storage {
        address owner;
        // Mapping of function selector -> function implementation
        mapping(bytes4 => address) impls;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        // uint256 storageSlot = LibStorage.STORAGE_ID_FEATURE;
        assembly { stor.slot := 0 }
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

pragma solidity ^0.8.15;


library LibHelperStorage {
    uint256 constant STORAGE_ID_FEATURE = 0 << 128;
}