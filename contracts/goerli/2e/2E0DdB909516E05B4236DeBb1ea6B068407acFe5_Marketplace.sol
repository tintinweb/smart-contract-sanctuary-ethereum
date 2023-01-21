// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/interfaces/IERC721.sol";

contract Marketplace {
    enum Status {
        Active,
        Canceled,
        Completed
    }

    struct Listing {
        bytes32 id;
        Status status;
        address contractAddress;
        uint256 tokenId;
        uint256 price;
        address seller;
    }

    event ListingCreated(
        bytes32 id,
        address seller,
        address contractAddress,
        uint256 tokenId,
        uint256 price
    );

    event ListingPurchased(bytes32 id, address buyer);
    event Canceled(bytes32 id);

    mapping(bytes32 => Listing) public listings;
    mapping(address => uint256) public userNonces;

    function createListing(
        uint256 _price,
        uint256 _tokenId,
        address _contractAddress
    ) external {
        // Validate
        require(
            IERC721(_contractAddress).ownerOf(_tokenId) == msg.sender,
            "Sender is not owner"
        );

        // Seller shouldn't be able to put tokens for sale if contract can't transfer them to the buyer
        require(
            IERC721(_contractAddress).isApprovedForAll(
                msg.sender,
                address(this)
            ),
            "Seller hasn't approved marketplace contract"
        );

        require(_price > 0, "Price should be positive");

        // unique order id. nonces guarantees ther won't be any duplicates
        bytes32 id = generateOrderId(
            _price,
            _tokenId,
            _contractAddress,
            userNonces[msg.sender]
        );

        // Create listing
        Listing memory listing = Listing(
            id,
            Status.Active,
            _contractAddress,
            _tokenId,
            _price,
            msg.sender
        );

        // Add listing to mapping
        listings[id] = listing;

        // Increment user's nonce
        userNonces[msg.sender]++;

        // Emit event
        emit ListingCreated(id, msg.sender, _contractAddress, _tokenId, _price);
    }

    function cancelOrder(bytes32 id) external {
        // Get listing
        Listing storage listing = listings[id];

        // Validate
        require(listing.seller != address(0), "Listing doesn't exist");
        require(listing.seller == msg.sender, "Sender is not seller");

        // Change status
        listing.status = Status.Canceled;

        // Emit event
        emit Canceled(id);
    }

    function acceptListing(bytes32 id) external payable {
        // Get listing
        Listing storage listing = listings[id];

        // Perform validations
        require(listing.seller != msg.sender, "Buyer can't be seller");
        require(listing.price <= msg.value, "Not enough ETH");
        require(listing.status == Status.Active, "Listing isn't active");
        require(
            IERC721(listing.contractAddress).ownerOf(listing.tokenId) ==
                listing.seller,
            "Sender is not owner"
        );

        // Change status
        listing.status = Status.Completed;

        // Transfer NFT ownership
        IERC721(listing.contractAddress).transferFrom(
            listing.seller,
            msg.sender,
            listing.tokenId
        );

        // Pay seller
        // Note: we don't have to add reentrancy guard here since:
        // 1. We use .transfer instead of .call which limits gas
        // 2. We've completed all state changes before transfering the ETH
        payable(listing.seller).transfer(msg.value);

        // Emit event
        emit ListingPurchased(id, msg.sender);
    }

    function generateOrderId(
        uint256 _price,
        uint256 _tokenId,
        address _contractAddress,
        uint256 userNonce
    ) public view returns (bytes32 orderId) {
        return
            keccak256(
                abi.encode(
                    msg.sender,
                    _price,
                    _tokenId,
                    _contractAddress,
                    userNonce
                )
            );
    }
}