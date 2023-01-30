// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

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

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.17;

import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {IERC2981} from "openzeppelin-contracts/contracts/interfaces/IERC2981.sol";

contract LiquidDelegateMarket {

    address public immutable LIQUID_DELEGATE;

    struct Bid {
        address bidder;
        uint256 rightsId;
        uint256 weiAmount;
    }

    struct Listing {
        address seller;
        uint256 rightsId;
        uint256 weiAmount;
    }

    mapping(uint256 => Bid) public bids;
    mapping(uint256 => Listing) public listings;

    uint256 public nextBidId = 1;
    uint256 public nextListingId = 1;

    event BidCreated(uint256 indexed bidId, address indexed bidder, uint256 indexed rightsId, uint256 weiAmount);
    event BidCanceled(uint256 indexed bidId, address indexed bidder, uint256 indexed rightsId, uint256 weiAmount);

    event ListingCreated(uint256 indexed listingId, address indexed seller, uint256 indexed rightsId, uint256 weiAmount);
    event ListingCanceled(uint256 indexed listingId, address indexed seller, uint256 indexed rightsId, uint256 weiAmount);

    event Sale(uint256 indexed rightsId, address indexed buyer, address indexed seller, uint256 weiAmount);

    constructor(address _liquidDelegate) {
        LIQUID_DELEGATE = _liquidDelegate;
    }

    function bid(uint256 rightsId) external payable {
        bids[nextBidId] = Bid({
            bidder: msg.sender,
            rightsId: rightsId,
            weiAmount: msg.value
        });
        emit BidCreated(nextBidId++, msg.sender, rightsId, msg.value);
    }

    function cancelBid(uint256 bidId) external {
       // Move data into memory to delete the bid data first, preventing reentrancy
        Bid memory bid = bids[bidId];
        uint256 rightsId = bid.rightsId;
        uint256 bidAmount = bid.weiAmount;
        address bidder = bid.bidder;
        delete bids[bidId];

        require(msg.sender == bidder, "NOT_YOUR_BID");
        _pay(payable(bidder), bidAmount, true);
        emit BidCanceled(bidId, bidder, rightsId, bidAmount);
    }

    function list(uint256 rightsId, uint256 weiAmount) external {
        listings[nextListingId] = Listing({
            seller: msg.sender,
            rightsId: rightsId,
            weiAmount: weiAmount
        });
        emit ListingCreated(nextListingId++, msg.sender, rightsId, weiAmount);
    }

    function cancelListing(uint256 listingId) external {
        // No re-entrancy possible here, no external calls
        Listing memory listing = listings[listingId];
        require(msg.sender == listing.seller, "NOT_YOUR_LISTING");
        emit ListingCanceled(listingId, msg.sender, listing.rightsId, listing.weiAmount);
        delete listings[listingId];
    }

    function buy(uint256 listId) external payable {
        Listing memory listing = listings[listId];
        address seller = listing.seller;
        uint256 listPrice = listing.weiAmount;
        uint256 rightsId = listing.rightsId;
        delete listings[listId];

        address currentOwner = IERC721(LIQUID_DELEGATE).ownerOf(rightsId);
        require(msg.value == listPrice, "WRONG_PRICE");
        require(currentOwner == seller, "NOT_OWNER");
        IERC721(LIQUID_DELEGATE).transferFrom(currentOwner, msg.sender, rightsId);
        (address receiver, uint256 royaltyAmount) = IERC2981(LIQUID_DELEGATE).royaltyInfo(rightsId, listPrice);
        _pay(payable(receiver), royaltyAmount, true);
        _pay(payable(currentOwner), listPrice - royaltyAmount, true);
        emit ListingCanceled(listId, seller, rightsId, listPrice);
        emit Sale(rightsId, msg.sender, currentOwner, listPrice);
    }

    function sell(uint256 bidId) external {
        // Move data into memory to delete the bid data first, preventing reentrancy
        Bid memory bid = bids[bidId];
        uint256 rightsId = bid.rightsId;
        uint256 bidAmount = bid.weiAmount;
        address bidder = bid.bidder;
        delete bids[bidId];

        address currentOwner = IERC721(LIQUID_DELEGATE).ownerOf(rightsId);
        require(currentOwner == msg.sender, "NOT_OWNER");
        IERC721(LIQUID_DELEGATE).transferFrom(currentOwner, bidder, rightsId);
        (address receiver, uint256 royaltyAmount) = IERC2981(LIQUID_DELEGATE).royaltyInfo(rightsId, bidAmount);
        _pay(payable(receiver), royaltyAmount, true);
        _pay(payable(currentOwner), bidAmount - royaltyAmount, true);
        emit BidCanceled(bidId, bidder, rightsId, bidAmount);
        emit Sale(rightsId, bidder, currentOwner, bidAmount);
    }

    /// @dev Send ether
    function _pay(address payable recipient, uint256 amount, bool errorOnFail) internal {
        (bool sent,) = recipient.call{value: amount}("");
        require(sent || errorOnFail, "SEND_ETHER_FAILED");
    }
}