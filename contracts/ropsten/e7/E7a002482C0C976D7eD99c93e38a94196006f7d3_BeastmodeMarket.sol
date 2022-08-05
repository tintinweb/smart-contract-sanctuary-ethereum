// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

error NotOwned();
error AlreadyListed();
error NotListed();
error BidAlreadyPlaced();
error BidDoesNotExist();
error RejectedToBid();
error RejectedForListingOwners();
error InsufficientValueSent(uint256 required, uint256 sent);
error NothingToWithdraw();
error UnexpectedError(string error);

contract BeastmodeMarket is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _counter;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    // listingId => Listing
    mapping(uint256 => Listing) listings;

    // nftAddress => tokenId => listingId
    mapping(address => mapping(uint256 => uint256)) activeListings;

    // bidderAddress => listingId => Bid
    mapping(address => mapping(uint256 => Bid)) biddings;

    uint256 LISTING_FEE = 0.0025 ether;

    enum ListingStatus {
        UNDEFINED,
        OPEN,
        CANCELLED,
        SOLD,
        FAST_SOLD,
        NFT_SWAP
    }

    enum BidType {
        UNDEFINED,
        CURRENCY,
        NFT
    }

    struct Listing {
        uint256 tokenId;
        uint256 buyNowPrice;
        uint256 minPrice;
        ListingStatus status;
        address nftAddress;
        address seller;
    }

    struct Bid {
        uint256 bidValue;
        uint256 tokenId;
        address nftAddress;
        BidType bidType;
    }

    function createListing(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _minPrice,
        uint256 _buyNowPrice
    )
        external
        payable
        nonReentrant
        isNotListed(_nftAddress, _tokenId)
        isNftOwner(msg.sender, _nftAddress, _tokenId)
    {
        if (msg.value != LISTING_FEE) {
            revert InsufficientValueSent(LISTING_FEE, msg.value);
        }

        IERC721(_nftAddress).transferFrom(msg.sender, address(this), _tokenId);

        _counter.increment();
        uint256 listingId = _counter.current();

        listings[listingId] = Listing(
            _tokenId,
            _buyNowPrice,
            _minPrice,
            ListingStatus.OPEN,
            _nftAddress,
            msg.sender
        );
        activeListings[_nftAddress][_tokenId] = listingId;
    }

    function cancelListing(uint256 _listingId)
        external
        isListed(_listingId)
        isListingOwner(_listingId, msg.sender)
    {
        Listing memory listing = listings[_listingId];
        try
            IERC721(listing.nftAddress).transferFrom(
                address(this),
                msg.sender,
                listing.tokenId
            )
        {} catch {
            revert UnexpectedError("Failed while transferring NFT");
        }

        listings[_listingId].status = ListingStatus.CANCELLED;
        delete activeListings[listing.nftAddress][listing.tokenId];
    }

    function placeBidCurrency(uint256 _listingId)
        external
        payable
        nonReentrant
        isListed(_listingId)
        bidDoesNotExist(_listingId, msg.sender)
        notListingOwner(_listingId, msg.sender)
    {
        Listing memory listing = listings[_listingId];

        if (msg.value < listing.minPrice) {
            revert InsufficientValueSent(listing.minPrice, msg.value);
        }

        biddings[msg.sender][_listingId] = Bid(
            msg.value,
            0,
            address(0),
            BidType.CURRENCY
        );
    }

    function placeBidNFT(
        uint256 _listingId,
        address _nftAddress,
        uint256 _tokenId
    )
        external
        isListed(_listingId)
        bidDoesNotExist(_listingId, msg.sender)
        notListingOwner(_listingId, msg.sender)
        isNftOwner(msg.sender, _nftAddress, _tokenId)
    {
        IERC721(_nftAddress).transferFrom(msg.sender, address(this), _tokenId);
        biddings[msg.sender][_listingId] = Bid(
            0,
            _tokenId,
            _nftAddress,
            BidType.NFT
        );
    }

    function fastBuy(uint256 _listingId)
        external
        payable
        isListed(_listingId)
        notListingOwner(_listingId, msg.sender)
    {
        Listing memory listing = listings[_listingId];

        if (msg.value == listing.buyNowPrice) {
            revert InsufficientValueSent(listing.buyNowPrice, msg.value);
        }

        _processListing(
            _listingId,
            msg.sender,
            Bid(msg.value, 0, address(0), BidType.CURRENCY),
            ListingStatus.FAST_SOLD
        );
    }

    function acceptBid(uint256 _listingId, address _bidder)
        external
        isListed(_listingId)
        isListingOwner(_listingId, msg.sender)
        isBidExists(_listingId, _bidder)
    {
        Bid memory bid = biddings[_bidder][_listingId];
        ListingStatus listingStatus = ListingStatus.SOLD;

        if (bid.bidType == BidType.NFT) {
            listingStatus = ListingStatus.NFT_SWAP;
        }

        _processListing(_listingId, _bidder, bid, listingStatus);
    }

    function withdraw(uint256 _listingId) external {
        Bid memory bid = biddings[msg.sender][_listingId];

        if (bid.bidValue != 0) {
            payable(msg.sender).transfer(bid.bidValue);
        } else if (bid.nftAddress != address(0)) {
            IERC721(bid.nftAddress).transferFrom(
                address(this),
                msg.sender,
                bid.tokenId
            );
        } else {
            revert NothingToWithdraw();
        }

        delete biddings[msg.sender][_listingId];
    }

    function _processListing(
        uint256 _listingId,
        address _bidder,
        Bid memory _bid,
        ListingStatus _status
    ) private {
        Listing memory listing = listings[_listingId];

        if (_bid.bidType == BidType.CURRENCY) {
            uint256 bidValue = _bid.bidValue;

            if (_checkRoyalties(listing.nftAddress)) {
                bidValue = _deduceRoyalties(
                    listing.nftAddress,
                    listing.tokenId,
                    bidValue
                );
            }

            payable(_bidder).transfer(bidValue);
        }

        if (_bid.bidType == BidType.NFT) {
            IERC721(_bid.nftAddress).transferFrom(
                address(this),
                listing.seller,
                _bid.tokenId
            );
        }

        IERC721(listing.nftAddress).transferFrom(
            address(this),
            _bidder,
            listing.tokenId
        );

        listings[_listingId].status = _status;

        delete activeListings[listing.nftAddress][listing.tokenId];
        delete biddings[_bidder][_listingId];
    }

    function _deduceRoyalties(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _grossPrice
    ) internal returns (uint256 netPrice) {
        (address royaltyReceiver, uint256 royaltyValue) = IERC2981(_nftAddress)
            .royaltyInfo(_tokenId, _grossPrice);

        if (royaltyValue > 0) {
            payable(royaltyReceiver).transfer(royaltyValue);
        }

        return _grossPrice - royaltyValue;
    }

    function _checkRoyalties(address _contract) internal view returns (bool) {
        bool success = IERC721(_contract).supportsInterface(
            _INTERFACE_ID_ERC2981
        );
        return success;
    }

    modifier isNftOwner(
        address _sender,
        address _nftAddress,
        uint256 _tokenId
    ) {
        IERC721 nft = IERC721(_nftAddress);
        address owner = nft.ownerOf(_tokenId);
        if (_sender != owner) {
            revert NotOwned();
        }
        _;
    }

    modifier isNotListed(address _nftAddress, uint256 _tokenId) {
        if (activeListings[_nftAddress][_tokenId] != 0) {
            revert AlreadyListed();
        }
        _;
    }

    modifier isListed(uint256 _listingId) {
        if (listings[_listingId].status != ListingStatus.OPEN) {
            revert NotListed();
        }
        _;
    }

    modifier isListingOwner(uint256 _listingId, address _sender) {
        if (listings[_listingId].seller != _sender) {
            revert NotOwned();
        }
        _;
    }

    modifier isBidExists(uint256 _listingId, address _bidder) {
        if (biddings[_bidder][_listingId].bidType == BidType.UNDEFINED) {
            revert BidDoesNotExist();
        }
        _;
    }

    modifier bidDoesNotExist(uint256 _listingId, address _bidder) {
        if (biddings[_bidder][_listingId].bidType != BidType.UNDEFINED) {
            revert BidAlreadyPlaced();
        }
        _;
    }

    modifier notListingOwner(uint256 _listingId, address _sender) {
        if (listings[_listingId].seller == _sender) {
            revert RejectedForListingOwners();
        }
        _;
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