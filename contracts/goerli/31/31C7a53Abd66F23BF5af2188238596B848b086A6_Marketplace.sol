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

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

error AlreadyListed(address nftAddress, uint tokenId);
error NotListed(address nftAddress, uint tokenId);
error NotOwner(address nftAddress, uint tokenId, address caller);
error ZeroPrice(address nftAddress, uint tokenId, uint newPrice);
error NotEnoughETH(uint listingPrice, uint buyerAmount);
error MarketplaceNotApproved(address nftAddress, uint tokenId);

contract Marketplace {
    struct Listing {
        uint price;
        address owner;
    }

    mapping(address => mapping(uint => Listing)) private listings;

    event listingCreated(
        address owner,
        uint tokenId,
        uint price,
        address nftAddress
    );

    event listingDeleted(address owner, uint tokenId, address nftAddress);
    event listingUpdated(
        address owner,
        uint tokenId,
        address nftAddress,
        uint newPrice
    );
    event listingBought(
        address buyer,
        uint tokenId,
        address nftAddress,
        uint price
    );

    modifier notListed(uint tokenId, address nftAddress) {
        if (listings[nftAddress][tokenId].price > 0) {
            revert AlreadyListed(nftAddress, tokenId);
        }
        _;
    }

    modifier isListed(uint tokenId, address nftAddress) {
        if (listings[nftAddress][tokenId].price <= 0) {
            revert NotListed(nftAddress, tokenId);
        }
        _;
    }

    modifier isOwner(
        uint tokenId,
        address nftAddress,
        address caller
    ) {
        IERC721 nft = IERC721(nftAddress);
        if (
            listings[nftAddress][tokenId].owner != caller ||
            nft.ownerOf(tokenId) != caller
        ) {
            revert NotOwner(nftAddress, tokenId, caller);
        }
        _;
    }

    modifier marketplaceIsApproved(uint tokenId, address nftAddress) {
        IERC721 nft = IERC721(nftAddress);
        if (nft.getApproved(tokenId) != address(this)) {
            revert MarketplaceNotApproved(nftAddress, tokenId);
        }
        _;
    }

    function createListing(
        uint tokenId,
        uint _price,
        address nftAddress
    ) external notListed(tokenId, nftAddress) {
        Listing memory listing = listings[nftAddress][tokenId];

        require(_price > 0, "Need to mint with a price greater than 0");
        listing.price = _price;
        listing.owner = msg.sender;

        IERC721 nft = IERC721(nftAddress);
        nft.approve(address(this), tokenId);
        emit listingCreated(msg.sender, tokenId, _price, nftAddress);
    }

    function deleteListing(
        uint tokenId,
        address nftAddress
    )
        external
        isListed(tokenId, nftAddress)
        isOwner(tokenId, nftAddress, msg.sender)
    {
        delete listings[nftAddress][tokenId];
        emit listingDeleted(msg.sender, tokenId, nftAddress);
    }

    function getListing(
        uint tokenId,
        address nftAddress
    )
        public
        view
        isListed(tokenId, nftAddress)
        marketplaceIsApproved(tokenId, nftAddress)
        returns (Listing memory)
    {
        Listing memory listing = listings[nftAddress][tokenId];
        return listing;
    }

    function updateListing(
        uint tokenId,
        uint newPrice,
        address nftAddress
    )
        public
        isListed(tokenId, nftAddress)
        isOwner(tokenId, nftAddress, msg.sender)
        marketplaceIsApproved(tokenId, nftAddress)
    {
        if (newPrice <= 0) {
            revert ZeroPrice(nftAddress, tokenId, newPrice);
        }
        Listing memory listing = listings[nftAddress][tokenId];
        listing.price = newPrice;
        emit listingUpdated(msg.sender, tokenId, nftAddress, newPrice);
    }

    function buyListing(
        uint tokenId,
        address nftAddress
    )
        external
        payable
        isListed(tokenId, nftAddress)
        marketplaceIsApproved(tokenId, nftAddress)
    {
        if (msg.value < listings[nftAddress][tokenId].price) {
            revert NotEnoughETH(listings[nftAddress][tokenId].price, msg.value);
        }
        IERC721 nft = IERC721(nftAddress);
        nft.safeTransferFrom(
            listings[nftAddress][tokenId].owner,
            msg.sender,
            tokenId
        );
        delete listings[nftAddress][tokenId];
        emit listingBought(msg.sender, tokenId, nftAddress, msg.value);
    }
}