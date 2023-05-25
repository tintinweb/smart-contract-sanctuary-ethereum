// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CuratedArtists.sol";
import "./NFTMarketBase.sol";
import "./NFTMarketAuction.sol";
import "./NFTMarketOffers.sol";
import "./NFTMarketDrops.sol";
import "./NFTMarket.sol";

contract NFTMarketplace is CuratedArtists, NFTMarketBase, NFTMarketAuction, NFTMarketOffers, NFTMarketDrops, NFTMarket {
    
   
        // Constructor logic, if any
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFTMarketBase.sol";

contract NFTMarket is NFTMarketBase {
  

   
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFTMarketBase.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTMarketDrops is NFTMarketBase {
    using Counters for Counters.Counter;

    struct Drop {
        uint256 listingId;
        uint256 startTime;
        uint256 endTime;
        uint256 price;
        bool active;
    }

    Counters.Counter private dropIds;
    mapping(uint256 => Drop) public drops;

    event DropCreated(uint256 indexed dropId, uint256 indexed listingId, uint256 startTime, uint256 endTime, uint256 price);
    event DropPurchased(uint256 indexed dropId, uint256 indexed listingId, address indexed buyer, uint256 price);

    modifier onlyActiveDrop(uint256 dropId) {
        require(drops[dropId].active, "Drop is not active");
        _;
    }

    

  

    function createDrop(uint256 listingId, uint256 startTime, uint256 endTime, uint256 price) external onlyApprovedArtist {
        require(nftListings[listingId].active, "Listing is inactive");
        require(startTime < endTime, "Invalid drop duration");

        dropIds.increment();
        uint256 dropId = dropIds.current();

        drops[dropId] = Drop(
            listingId,
            startTime,
            endTime,
            price,
            true
        );

        emit DropCreated(dropId, listingId, startTime, endTime, price);
    }

    function purchaseFromDrop(uint256 dropId) external payable onlyActiveDrop(dropId) {
        Drop storage drop = drops[dropId];
        require(block.timestamp >= drop.startTime, "Drop has not started yet");
        require(block.timestamp <= drop.endTime, "Drop has already ended");
        require(msg.value >= drop.price, "Insufficient payment amount");

        NFTListing storage listing = nftListings[drop.listingId];
        require(listing.active, "Listing is inactive");

        delete nftListings[drop.listingId];
        delete drops[dropId];

        (bool success, ) = listing.seller.call{value: drop.price}("");
        require(success, "Failed to send payment to the seller");

        IERC721(listing.nftContract).safeTransferFrom(address(this), msg.sender, listing.tokenId);

        emit DropPurchased(dropId, drop.listingId, msg.sender, drop.price);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFTMarketBase.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTMarketOffers is NFTMarketBase {
    using Counters for Counters.Counter;

    struct Offer {
        uint256 listingId;
        address buyer;
        uint256 price;
        bool active;
    }

    Counters.Counter private offerIds;
    mapping(uint256 => Offer) public offers;

    event OfferCreated(uint256 indexed offerId, uint256 indexed listingId, address indexed buyer, uint256 price);
    event OfferAccepted(uint256 indexed offerId, uint256 indexed listingId, address indexed buyer, uint256 price);
    event OfferCancelled(uint256 indexed offerId, uint256 indexed listingId, address indexed buyer);

    modifier onlyActiveOffer(uint256 offerId) {
        require(offers[offerId].active, "Offer is not active");
        _;
    }

  

    function createOffer(uint256 listingId, uint256 price) external {
        require(nftListings[listingId].active, "Listing is inactive");

        offerIds.increment();
        uint256 offerId = offerIds.current();

        offers[offerId] = Offer(
            listingId,
            msg.sender,
            price,
            true
        );

        emit OfferCreated(offerId, listingId, msg.sender, price);
    }

    function acceptOffer(uint256 offerId) external onlyApprovedArtist onlyActiveOffer(offerId) {
        Offer storage offer = offers[offerId];
        require(offer.buyer != msg.sender, "You cannot accept your own offer");

        NFTListing storage listing = nftListings[offer.listingId];
        require(listing.active, "Listing is inactive");

        listing.active = false;
        delete nftListings[offer.listingId];
        delete offers[offerId];

        (bool success, ) = offer.buyer.call{value: offer.price}("");
        require(success, "Failed to send payment to the buyer");

        IERC721(listing.nftContract).safeTransferFrom(address(this), offer.buyer, listing.tokenId);

        emit OfferAccepted(offerId, offer.listingId, offer.buyer, offer.price);
    }

    function cancelOffer(uint256 offerId) external onlyActiveOffer(offerId) {
        Offer storage offer = offers[offerId];
        require(offer.buyer == msg.sender, "Only the buyer can cancel the offer");

        NFTListing storage listing = nftListings[offer.listingId];
        require(listing.active, "Listing is inactive");

        delete offers[offerId];

        emit OfferCancelled(offerId, offer.listingId, offer.buyer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFTMarketBase.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract NFTMarketAuction is NFTMarketBase, ERC721Holder {
    using Counters for Counters.Counter;

    struct Auction {
        uint256 listingId;
        address seller;
        uint256 startTime;
        uint256 endTime;
        uint256 startPrice;
        address highestBidder;
        uint256 highestBid;
        bool active;
    }

    Counters.Counter private auctionIds;
    mapping(uint256 => Auction) public auctions;

    event AuctionCreated(uint256 indexed auctionId, uint256 indexed listingId, address indexed seller, uint256 startTime, uint256 endTime, uint256 startPrice);
    event AuctionBidPlaced(uint256 indexed auctionId, uint256 indexed listingId, address indexed bidder, uint256 amount);
    event AuctionEnded(uint256 indexed auctionId, uint256 indexed listingId, address indexed winner, uint256 amount);

    modifier onlyActiveAuction(uint256 auctionId) {
        require(auctions[auctionId].active, "Auction is not active");
        _;
    }

  

    function createAuction(uint256 listingId, uint256 startTime, uint256 endTime, uint256 startPrice) external onlyApprovedArtist {
        require(nftListings[listingId].active, "Listing is inactive");
        require(startTime < endTime, "Invalid auction duration");
        require(startPrice > 0, "Auction start price must be greater than zero");

        auctionIds.increment();
        uint256 auctionId = auctionIds.current();

        auctions[auctionId] = Auction(
            listingId,
            msg.sender,
            startTime,
            endTime,
            startPrice,
            address(0),
            0,
            true
        );

        emit AuctionCreated(auctionId, listingId, msg.sender, startTime, endTime, startPrice);
    }



    function placeBid(uint256 auctionId) external payable onlyActiveAuction(auctionId) {
        Auction storage auction = auctions[auctionId];
        require(block.timestamp < auction.endTime, "Auction has ended");
        require(msg.sender != auction.highestBidder, "You are already the highest bidder");
        require(msg.value > auction.highestBid, "Your bid must be higher than the current highest bid");

        if (auction.highestBidder != address(0)) {
            // Refund the previous highest bidder if applicable
            (bool success, ) = auction.highestBidder.call{value: auction.highestBid}("");
            require(success, "Failed to refund the previous highest bidder");
        }

        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;

     
    }

    function endAuction(uint256 auctionId) external onlyApprovedArtist onlyActiveAuction(auctionId) {
        Auction storage auction = auctions[auctionId];
        require(block.timestamp >= auction.endTime, "Auction has not ended yet");

        NFTListing storage listing = nftListings[auction.listingId];
        require(listing.active, "Listing is inactive");

        listing.active = false;
        delete nftListings[auction.listingId];
        delete auctions[auctionId];

        address winner = auction.highestBidder;
        uint256 amount = auction.highestBid;
        (bool success, ) = listing.seller.call{value: amount}("");
        require(success, "Failed to send payment to the seller");

        IERC721(listing.nftContract).safeTransferFrom(address(this), winner, listing.tokenId);

        emit AuctionEnded(auctionId, auction.listingId, winner, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CuratedArtists.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTMarketBase {
    using Counters for Counters.Counter;

    struct NFTListing {
        address seller;
        address nftContract;
        uint256 tokenId;
        uint256 price;
        bool active;
    }

    Counters.Counter private listingIds;
    mapping(uint256 => NFTListing) public nftListings;

    CuratedArtists public curatedArtists;

    event NFTListed(uint256 indexed listingId, address indexed seller, address indexed nftContract, uint256 tokenId, uint256 price);
    event NFTSold(uint256 indexed listingId, address indexed seller, address indexed buyer, address nftContract, uint256 tokenId, uint256 price);
    event NFTListingCancelled(uint256 indexed listingId, address indexed seller, address nftContract, uint256 tokenId);



    modifier onlyApprovedArtist() {
        require(curatedArtists.isArtistApproved(msg.sender), "Only approved artists can perform this action");
        _;
    }

    function listNFT(address nftContract, uint256 tokenId, uint256 price) external {
        require(price > 0, "Price must be greater than zero");
        require(
            IERC721(nftContract).ownerOf(tokenId) == msg.sender,
            "Only the owner can list their NFT"
        );

        listingIds.increment();
        uint256 listingId = listingIds.current();
        nftListings[listingId] = NFTListing(
            msg.sender,
            nftContract,
            tokenId,
            price,
            true
        );

        emit NFTListed(listingId, msg.sender, nftContract, tokenId, price);
    }

    function buyNFT(uint256 listingId) external payable {
        NFTListing storage listing = nftListings[listingId];
        require(listing.active, "Listing is inactive");
        require(msg.value >= listing.price, "Insufficient payment amount");

        address seller = listing.seller;
        address nftContract = listing.nftContract;
        uint256 tokenId = listing.tokenId;
        uint256 price = listing.price;

        listing.active = false;
        delete nftListings[listingId];

        IERC721(nftContract).safeTransferFrom(address(this), msg.sender, tokenId);
        (bool success, ) = seller.call{value: price}("");
        require(success, "Failed to send payment to the seller");

        emit NFTSold(listingId, seller, msg.sender, nftContract, tokenId, price);
    }

    function cancelNFTListing(uint256 listingId) external {
        NFTListing storage listing = nftListings[listingId];
        require(listing.active, "Listing is inactive");
        require(listing.seller == msg.sender, "Only the seller can cancel the listing");

        listing.active = false;
        delete nftListings[listingId];

        emit NFTListingCancelled(listingId, msg.sender, listing.nftContract, listing.tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CuratedArtists {
    address public owner;
    mapping(address => bool) public approvedArtists;

    event ArtistApproved(address indexed artist);
    event ArtistRevoked(address indexed artist);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can perform this action");
        _;
    }

    function approveArtist(address artist) external onlyOwner {
        approvedArtists[artist] = true;
        emit ArtistApproved(artist);
    }

    function revokeArtist(address artist) external onlyOwner {
        approvedArtists[artist] = false;
        emit ArtistRevoked(artist);
    }

    function isArtistApproved(address artist) external view returns (bool) {
        return approvedArtists[artist];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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