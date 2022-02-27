// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";

contract ReDDrop is ERC1155Receiver {
    
    /// ============ Storage ============

    // Boolean that represents if the contract has been initialized
    bool private _initialized;
    // {SliceCore} address
    address private immutable _sliceCoreAddress;
    // The account who receives ETH from the sales
    address private immutable _collector; 
    // The account who sent the slices to the contract
    address private _slicesSupplier; 
    // The tokenId related to the slicer linked to this contract
    uint256 private _tokenId;
    // Price of each slice
    uint256 private SLICE_PRICE = 2 ether;
    
    /// ============ Errors ============
    
    /// @notice Thrown if contract has been initialized
    error Initialized();
    /// @notice Thrown if contract has not been initialized
    error NotInitialized();
    /// @notice Thrown if contract receives ERC1155 not related to slicers
    error NotSlicer();
    /// @notice Thrown if caller doesn't have the right permission
    error NotAuthorized();
    /// @notice Thrown if the value sent is not sufficient to claim
    error InsufficientPayment();

    /// ============ Events ============

    /// @notice Emitted when slices are claimed
    event Claimed(address indexed to, uint256 amount, uint256 _tokenId);
    /// @notice Emitted when the sale is marked as closed
    event SaleClosed(address slicesSupplier, uint256 slicesAmount);

    /// ============ Constructor ============

    /**
     * @notice Initializes the contract.
     *
     * @param sliceCoreAddress_ {SliceCore} address
     * @param collector_ Address of the account that receives ETH from sales
     *
     * @dev Claims will revert once there are no more slices in the contract.
     */
    constructor(
        address sliceCoreAddress_,
        address collector_
    ) {
        _sliceCoreAddress = sliceCoreAddress_;
        _collector = collector_;
    }

    /// ============ Functions ============

    /**
     * @notice Sends all ETH received from the sale to the appointed collector.
     */
    function releaseToCollector() external {
        (bool success, ) = payable(_collector).call{value: address(this).balance}("");
        require(success);
    }

    /**
     * @notice Sends all slices received back to the address who supplied them.
     *
     * @dev Safe measure in case the sale needs to be cancelled, or it has unclaimed slices.
     * @dev Can only be called by the slices supplier.
     */
    function _closeSale() external {
        if (msg.sender != _slicesSupplier) revert NotAuthorized();
        uint256 slices = IERC1155Upgradeable(_sliceCoreAddress).balanceOf(address(this), _tokenId);
        IERC1155Upgradeable(_sliceCoreAddress).safeTransferFrom(address(this), _slicesSupplier, _tokenId, slices, "");
        _initialized = false;
        emit SaleClosed(_slicesSupplier, slices);
    }

    /// @notice Returns information about the sale.
    function saleInfo() external view returns(
        uint256 tokenId,
        address collector,
        uint256 slicePrice
    ) {
        return (_tokenId, _collector, SLICE_PRICE);
    }

    function slicesLeft() external view returns(uint256) {
      return IERC1155Upgradeable(_sliceCoreAddress).balanceOf(address(this), _tokenId);
    }

    /**
     * @notice Allows users to claim slices by paying the price.
     *
     * @param quantity Number of slices to claim.
     */
    function claim(uint256 quantity) external payable {
        if (!_initialized) revert NotInitialized();

        // Revert if value doesn't cover the claim price
        if (msg.value < SLICE_PRICE * quantity) revert InsufficientPayment();

        // Send slices to his address
        IERC1155Upgradeable(_sliceCoreAddress).safeTransferFrom(address(this), msg.sender, _tokenId, quantity, "");
        
        // Emit claim event
        emit Claimed(msg.sender, _tokenId, quantity);
    }

    /**
     * @notice Initializes the contract upon reception of the first transfer of slices.
     *
     * @dev Supports only slice transfer, not mint.
     * @dev Can only receive slices once.
     * @dev Can only receive Slice ERC1155 tokens
     */
    function onERC1155Received(
        address, 
        address from, 
        uint256 tokenId_, 
        uint256, 
        bytes memory
    ) 
        external 
        virtual 
        override 
        returns (bytes4) 
    {
        if (msg.sender != _sliceCoreAddress) revert NotSlicer();
        if (_initialized) revert Initialized();
        _initialized = true;
        _slicesSupplier = from;
        _tokenId = tokenId_;
        return this.onERC1155Received.selector;
    }

    /**
     * @dev See `onERC1155Received`
     */
    function onERC1155BatchReceived(
        address, 
        address, 
        uint256[] memory, 
        uint256[] memory, 
        bytes memory
    ) 
        public 
        virtual 
        override 
        returns (bytes4) 
    {
        revert(); 
    }

    /**
     * @notice Allows receiving eth.
     */
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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