// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error PriceMustBeAboveZero();
error NftNotApprovedForMarketplace();
error NftAlreadyListed(address nftAddress, uint256 tokenId);
error NftNotListed(address nftAddress, uint256 tokenId);
error NotNftOwner();
error PriceNotMet(address nftAddress, uint256 tokenId, uint256 price);
error NoNFTSold();

contract NftMarketplace is ReentrancyGuard {
    //Type declartion
    struct Listing {
        uint256 price;
        address seller;
    }

    //Contract Variables
    //NFT Contract address -> tokenId -> listing (Since we need price and seller info, we are using custom Type `Listing`)
    mapping(address => mapping(uint256 => Listing)) private s_listings;

    // NFT seller address -> Amount earned selling NFT
    mapping(address => uint256) private s_sellerMoney;

    // Events
    event ItemListed(
        address indexed seller,
        address indexed marketplaceAddress,
        uint256 indexed tokenId,
        uint256 price
    );
    event ItemBought(
        address indexed buyer,
        address indexed marketplaceAddress,
        uint256 indexed tokenId,
        uint256 price
    );
    event ListingCancelled(
        address indexed marketplaceAddress,
        uint256 indexed tokenId,
        address seller
    );

    ////////////////
    // Modifiers //
    //////////////
    modifier notListed(address nftContractAddress, uint256 tokenId) {
        Listing memory listing = s_listings[nftContractAddress][tokenId];
        if (listing.price > 0) {
            revert NftAlreadyListed(nftContractAddress, tokenId);
        }
        _;
    }

    modifier isListed(address nftContractAddress, uint256 tokenId) {
        Listing memory listing = s_listings[nftContractAddress][tokenId];
        if (listing.price <= 0) {
            revert NftNotListed(nftContractAddress, tokenId);
        }
        _;
    }

    modifier isOwner(
        address nftContractAddress,
        uint256 tokenId,
        address sender
    ) {
        IERC721 nft = IERC721(nftContractAddress);
        address owner = nft.ownerOf(tokenId);
        if (owner != sender) {
            revert NotNftOwner();
        }
        _;
    }

    /////////////////////
    // Main Functions //
    ///////////////////

    /*
     * @notice Method for listing NFT
     * @param nftContractAddress Address of NFT contract
     * @param tokenId Token ID of NFT
     * @param price sale price for each item
     */
    function listItem(
        address nftContractAddress,
        uint256 tokenId,
        uint256 price
    )
        external
        notListed(nftContractAddress, tokenId)
        isOwner(nftContractAddress, tokenId, msg.sender)
    {
        if (price <= 0) {
            revert PriceMustBeAboveZero();
        }
        //Listing can be done in 2 ways
        // 1. Send the NFT to the contract, doing transfer (contract holds NFT) - This could be gas expensive
        // 2. Owners can hold their NFT and give the marketplace approval to sell the NFT for them. (We will use this method).
        IERC721 nft = IERC721(nftContractAddress);
        if (nft.getApproved(tokenId) != address(this)) {
            revert NftNotApprovedForMarketplace();
        }
        s_listings[nftContractAddress][tokenId] = Listing(price, msg.sender);
        emit ItemListed(msg.sender, nftContractAddress, tokenId, price);
    }

    /*
     * @notice Method for buying listing
     * @notice The owner of an NFT could unapprove the marketplace,
     * which would cause this function to fail
     * Ideally you'd also have a `createOffer` functionality.
     * @param nftContractAddress Address of NFT contract
     * @param tokenId Token ID of NFT
     */
    function buyItem(address nftContractAddress, uint256 tokenId)
        external
        payable
        nonReentrant
        isListed(nftContractAddress, tokenId)
    {
        Listing memory listedItem = s_listings[nftContractAddress][tokenId];
        if (msg.value < listedItem.price) {
            revert PriceNotMet(nftContractAddress, tokenId, listedItem.price);
        }

        // instead of sending money to Seller, we want them to withdraw
        // https://fravoll.github.io/solidity-patterns/pull_over_push.html - read more about it
        s_sellerMoney[listedItem.seller] += msg.value;

        delete (s_listings[nftContractAddress][tokenId]); //delete listing from market
        IERC721(nftContractAddress).safeTransferFrom(listedItem.seller, msg.sender, tokenId);
        emit ItemBought(msg.sender, nftContractAddress, tokenId, msg.value);
    }

    /*
     * @notice Method for cancelling listing
     * @param nftContractAddress Address of NFT contract
     * @param tokenId Token ID of NFT
     */
    function cancelListing(address nftContractAddress, uint256 tokenId)
        external
        isOwner(nftContractAddress, tokenId, msg.sender)
        isListed(nftContractAddress, tokenId)
    {
        delete (s_listings[nftContractAddress][tokenId]);
        emit ListingCancelled(nftContractAddress, tokenId, msg.sender);
    }

    /*
     * @notice Method for updating listing
     * @param nftContractAddress Address of NFT contract
     * @param tokenId Token ID of NFT
     * @param newPrice Price in Wei of the item
     */
    function updateListing(
        address nftContractAddress,
        uint256 tokenId,
        uint256 newPrice
    )
        external
        isListed(nftContractAddress, tokenId)
        isOwner(nftContractAddress, tokenId, msg.sender)
    {
        s_listings[nftContractAddress][tokenId].price = newPrice;
        emit ItemListed(msg.sender, nftContractAddress, tokenId, newPrice);
    }

    /*
     * @notice Method for withdrawing proceeds from sales
     */

    function withdrawSellerMoney() external {
        uint256 amount = s_sellerMoney[msg.sender];
        if (amount <= 0) {
            revert NoNFTSold();
        }
        s_sellerMoney[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer Failed!");
    }

    ///////////////////////
    // Getter Functions //
    /////////////////////
    function getListing(address nftContractAddress, uint256 tokenId)
        external
        view
        returns (Listing memory)
    {
        return s_listings[nftContractAddress][tokenId];
    }

    function getProceeds(address seller) external view returns (uint256) {
        return s_sellerMoney[seller];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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