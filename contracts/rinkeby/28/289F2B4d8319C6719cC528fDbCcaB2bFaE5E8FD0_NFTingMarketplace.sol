// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./NFTingAuction.sol";
import "./NFTingOffer.sol";

contract NFTingMarketplace is NFTingAuction, NFTingOffer {
    struct Listing {
        address nftAddress;
        uint256 tokenId;
        uint256 amount;
        uint256 price;
        address payable seller;
        uint256 collectionIndex;
        uint256 sellerIndex;
    }

    mapping(bytes32 => Listing) private listings;
    mapping(address => bytes32[]) private collectionToListings;
    mapping(address => bytes32[]) private sellerToListings;

    event ItemListed(
        bytes32 indexed saleId,
        address indexed seller,
        address indexed nftAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 price
    );

    event ItemUpdated(bytes32 indexed saleId, uint256 price);

    event ItemUnlisted(bytes32 indexed saleId);

    event ItemBought(
        bytes32 indexed saleId,
        address indexed buyer,
        uint256 price
    );

    modifier isListedOnSale(bytes32 _saleId) {
        if (listings[_saleId].seller == address(0)) {
            revert NotListed();
        }
        _;
    }

    modifier isTokenSeller(bytes32 saleId, address _seller) {
        if (listings[saleId].seller != _seller) {
            revert NotTokenSeller();
        }

        _;
    }

    modifier isNotTokenSeller(bytes32 saleId, address _addr) {
        if (listings[saleId].seller == _addr) {
            revert TokenSeller();
        }

        _;
    }

    modifier isNotZeroPrice(uint256 _price) {
        if (_price == 0) {
            revert PriceMustBeAboveZero(_price);
        }

        _;
    }

    // ----- START ----- Listing -----

    function _createListingOnSale(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _price
    ) private returns (bytes32 saleId) {
        saleId = keccak256(
            abi.encodePacked(
                _nftAddress,
                _tokenId,
                _amount,
                _msgSender(),
                block.number,
                block.timestamp
            )
        );

        Listing storage newListing = listings[saleId];
        newListing.nftAddress = _nftAddress;
        newListing.tokenId = _tokenId;
        newListing.amount = _amount;
        newListing.price = _price;
        newListing.seller = payable(_msgSender());
        newListing.collectionIndex = collectionToListings[_nftAddress].length;
        newListing.sellerIndex = sellerToListings[_msgSender()].length;

        collectionToListings[_nftAddress].push(saleId);
        sellerToListings[_msgSender()].push(saleId);

        emit ItemListed(
            saleId,
            _msgSender(),
            _nftAddress,
            _tokenId,
            _amount,
            _price
        );
    }

    function listOnSale(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _price
    )
        external
        isValidAddress(_nftAddress)
        isTokenOwnerOrApproved(_nftAddress, _tokenId, _amount, _msgSender())
        isNotZeroPrice(_price)
        isApprovedMarketplace(_nftAddress, _tokenId, _msgSender())
    {
        bytes32 saleId = _createListingOnSale(
            _nftAddress,
            _tokenId,
            _amount,
            _price
        );

        _transfer721And1155(
            _msgSender(),
            address(this),
            listings[saleId].nftAddress,
            listings[saleId].tokenId,
            listings[saleId].amount
        );
    }

    function _deleteListingOnSale(bytes32 _saleId) private {
        Listing storage listedItem = listings[_saleId];

        bytes32[] storage cListings = collectionToListings[
            listedItem.nftAddress
        ];
        bytes32[] storage sListings = sellerToListings[listedItem.seller];

        if (cListings.length > 1) {
            cListings[listedItem.collectionIndex] = cListings[
                cListings.length - 1
            ];
        }
        cListings.pop();

        if (sListings.length > 1) {
            sListings[listedItem.sellerIndex] = sListings[sListings.length - 1];
        }
        sListings.pop();

        delete listings[_saleId];
    }

    function unlistOnSale(bytes32 _saleId)
        external
        isListedOnSale(_saleId)
        isTokenSeller(_saleId, _msgSender())
    {
        Listing storage listedItem = listings[_saleId];
        _transfer721And1155(
            address(this),
            _msgSender(),
            listedItem.nftAddress,
            listedItem.tokenId,
            listedItem.amount
        );

        _deleteListingOnSale(_saleId);

        emit ItemUnlisted(_saleId);
    }

    function buyItem(bytes32 _saleId)
        external
        payable
        isListedOnSale(_saleId)
        isNotTokenSeller(_saleId, _msgSender())
    {
        Listing storage listedItem = listings[_saleId];
        if (msg.value < listedItem.price) {
            revert NotEnoughEthProvided();
        }

        if (!listedItem.seller.send(msg.value)) {
            revert TransactionError();
        }

        _transfer721And1155(
            address(this),
            _msgSender(),
            listedItem.nftAddress,
            listedItem.tokenId,
            listedItem.amount
        );

        _deleteListingOnSale(_saleId);

        emit ItemBought(_saleId, _msgSender(), msg.value);
    }

    function updateSalePrice(bytes32 _saleId, uint256 _newPrice)
        external
        isListedOnSale(_saleId)
        isTokenSeller(_saleId, _msgSender())
    {
        listings[_saleId].price = _newPrice;

        emit ItemUpdated(_saleId, _newPrice);
    }

    function getListing(bytes32 _saleId)
        external
        view
        isListedOnSale(_saleId)
        returns (
            address,
            uint256,
            uint256,
            uint256,
            address
        )
    {
        return (
            listings[_saleId].nftAddress,
            listings[_saleId].tokenId,
            listings[_saleId].amount,
            listings[_saleId].price,
            listings[_saleId].seller
        );
    }

    function getListingsByCollection(address _nftAddress)
        public
        view
        returns (bytes32[] memory)
    {
        return collectionToListings[_nftAddress];
    }

    function getListingsBySeller(address _seller)
        public
        view
        returns (bytes32[] memory)
    {
        return sellerToListings[_seller];
    }

    // ----- END ----- Listing -----

    // ----- START ----- Auction -----

    function createAuction(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _durationInMinutes,
        uint256 _startingBid
    ) external {
        _createAuction(
            _nftAddress,
            _tokenId,
            _amount,
            _durationInMinutes,
            _startingBid
        );
    }

    function createBid(bytes32 _auctionId) external payable {
        _createBid(_auctionId, msg.value);
    }

    function updateBid(bytes32 _auctionId) external payable {
        _updateBid(_auctionId, msg.value);
    }

    function finishAuction(bytes32 _auctionId) external {
        _finishAuction(_auctionId);
    }

    // ----- END ----- Auction -----

    // ----- START ----- Offer -----

    function makeOffer(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _amount,
        address _seller
    ) external payable {
        _makeOffer(_nftAddress, _tokenId, _amount, _seller);
    }

    function updateOffer(bytes32 _offerId, uint256 _newPrice) external payable {
        _updateOffer(_offerId, _newPrice);
    }

    function acceptOffer(bytes32 _offerId) external {
        _acceptOffer(_offerId);
    }

    function declineOffer(bytes32 _offerId) external {
        _declineOffer(_offerId);
    }

    function cancelOffer(bytes32 _offerId) external {
        _cancelOffer(_offerId);
    }

    function getOfferDetailsById(bytes32 _offerId)
        external
        isValidOffer(_offerId)
        returns (
            address,
            uint256,
            uint256,
            address,
            uint256,
            address
        )
    {
        return (
            offers[_offerId].nftAddress,
            offers[_offerId].tokenId,
            offers[_offerId].amount,
            offers[_offerId].buyer,
            offers[_offerId].price,
            offers[_offerId].seller
        );
    }

    // ----- END ----- Offer -----
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
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./utilities/NFTingBase.sol";

contract NFTingAuction is Ownable, NFTingBase {
    struct Auction {
        address nftAddress;
        uint256 tokenId;
        uint256 amount;
        address creator;
        uint256 startedAt;
        uint256 endAt;
        uint256 maxBidAmount;
        address winner;
        mapping(address => uint256) biddersToAmount;
        address[] bidders;
    }

    mapping(bytes32 => Auction) internal auctions;

    event AuctionCreated(
        bytes32 _auctionId,
        address indexed _nftAddress,
        uint256 _tokenId,
        uint256 _amount,
        address indexed _creator,
        uint256 _startedAt,
        uint256 _endAt
    );
    event BidCreated(bytes32 _auctionId, address _bidder, uint256 _amount);
    event BidUpdated(bytes32 _auctionId, address _bidder, uint256 _amount);
    event AuctionFinished(bytes32 _auctionId);

    modifier isValidAuction(bytes32 _auctionId) {
        Auction storage auction = auctions[_auctionId];
        if (auction.creator == address(0)) {
            revert NotExistingAuction();
        } else if (auction.endAt < block.timestamp) {
            revert ExpiredAuction();
        }

        _;
    }

    modifier isExistingBidder(bytes32 _auctionId) {
        Auction storage auction = auctions[_auctionId];
        if (auction.biddersToAmount[_msgSender()] == 0) {
            revert NotExistingBidder(_msgSender());
        }

        _;
    }

    modifier isExpiredAuction(bytes32 _auctionId) {
        Auction storage auction = auctions[_auctionId];
        if (auction.startedAt == 0) {
            revert NotExistingAuction();
        } else if (auction.endAt >= block.timestamp) {
            revert ValidAuction();
        }

        _;
    }

    modifier isBiddablePrice(bytes32 _auctionId, uint256 _price) {
        Auction storage auction = auctions[_auctionId];
        if (
            auction.maxBidAmount >=
            _price + auction.biddersToAmount[_msgSender()]
        ) {
            revert NotEnoughPriceToBid();
        }

        _;
    }

    modifier isAuctionCreatorOrOwner(bytes32 _auctionId) {
        if (
            auctions[_auctionId].creator != _msgSender() ||
            owner() != _msgSender()
        ) {
            revert NotAuctionCreatorOrOwner();
        }
        _;
    }

    function _createAuction(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _durationInMinutes,
        uint256 _startingBid
    )
        internal
        isValidAddress(_nftAddress)
        isTokenOwnerOrApproved(_nftAddress, _tokenId, _amount, _msgSender())
        isApprovedMarketplace(_nftAddress, _tokenId, _msgSender())
    {
        if (
            _amount == 0 ||
            (_amount > 1 &&
                _supportsInterface(_nftAddress, INTERFACE_ID_ERC721))
        ) {
            revert InvalidAmountOfTokens(_amount);
        }

        bytes32 auctionId = keccak256(
            abi.encodePacked(
                _nftAddress,
                _tokenId,
                _amount,
                _msgSender(),
                block.number
            )
        );
        Auction storage newAuction = auctions[auctionId];
        newAuction.nftAddress = _nftAddress;
        newAuction.tokenId = _tokenId;
        newAuction.creator = _msgSender();
        newAuction.startedAt = block.timestamp;
        newAuction.endAt =
            newAuction.startedAt +
            _durationInMinutes *
            60 seconds;
        newAuction.maxBidAmount = _startingBid;
        newAuction.amount = _amount;

        _transfer721And1155(
            _msgSender(),
            address(this),
            newAuction.nftAddress,
            newAuction.tokenId,
            newAuction.amount
        );

        emit AuctionCreated(
            auctionId,
            newAuction.nftAddress,
            newAuction.tokenId,
            newAuction.amount,
            _msgSender(),
            newAuction.startedAt,
            newAuction.endAt
        );
    }

    function _createBid(bytes32 _auctionId, uint256 _price)
        internal
        isValidAuction(_auctionId)
        isBiddablePrice(_auctionId, _price)
    {
        Auction storage auction = auctions[_auctionId];
        auction.biddersToAmount[_msgSender()] = _price;
        auction.winner = _msgSender();
        auction.maxBidAmount = _price;
        auction.bidders.push(_msgSender());

        emit BidCreated(_auctionId, _msgSender(), _price);
    }

    function _updateBid(bytes32 _auctionId, uint256 _additionalPrice)
        internal
        isValidAuction(_auctionId)
        isExistingBidder(_auctionId)
        isBiddablePrice(_auctionId, _additionalPrice)
    {
        Auction storage auction = auctions[_auctionId];
        uint256 newAmount = auction.biddersToAmount[_msgSender()] +
            _additionalPrice;
        auction.biddersToAmount[_msgSender()] = newAmount;
        auction.winner = _msgSender();
        auction.maxBidAmount = newAmount;

        emit BidUpdated(_auctionId, _msgSender(), newAmount);
    }

    // Need to consider ERC1155, several tokenId
    function _finishAuction(bytes32 _auctionId)
        internal
        isExpiredAuction(_auctionId)
    {
        Auction storage auction = auctions[_auctionId];
        for (uint256 i; i < auction.bidders.length; i++) {
            address bidder = auction.bidders[i];
            if (bidder != auction.winner) {
                if (!payable(bidder).send(auction.biddersToAmount[bidder])) {
                    revert TransactionError();
                }
            } else {
                _transfer721And1155(
                    address(this),
                    auction.winner,
                    auction.nftAddress,
                    auction.tokenId,
                    auction.amount
                );
            }
        }

        delete auctions[_auctionId];

        emit AuctionFinished(_auctionId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./utilities/NFTingBase.sol";

contract NFTingOffer is NFTingBase {
    struct Offer {
        address nftAddress;
        uint256 tokenId;
        uint256 amount;
        address payable buyer;
        uint256 price;
        address payable seller;
    }

    mapping(bytes32 => Offer) internal offers;

    event OfferCreated(
        bytes32 _offerId,
        address indexed _nftAddress,
        uint256 _tokenId,
        uint256 _amount,
        address indexed _buyer,
        uint256 _price,
        address indexed _seller
    );
    event OfferUpdated(bytes32 _offerId, uint256 _newPrice);
    event OfferAccepted(bytes32 _offerId);
    event OfferDeclined(bytes32 _offerId);
    event OfferCancelled(bytes32 _offerId);

    modifier isValidOffer(bytes32 _offerId) {
        Offer storage offer = offers[_offerId];
        if (offer.seller == address(0)) {
            revert NotExistingOffer(_offerId);
        }

        _;
    }

    function _makeOffer(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _amount,
        address _seller
    )
        internal
        isValidAddress(_nftAddress)
        isTokenOwnerOrApproved(_nftAddress, _tokenId, _amount, _seller)
    {
        if (_seller == _msgSender()) {
            revert InvalidAddressProvided(_seller);
        } else if (msg.value == 0) {
            revert PriceMustBeAboveZero(msg.value);
        } else if (
            _amount == 0 ||
            (_amount > 1 &&
                _supportsInterface(_nftAddress, INTERFACE_ID_ERC721))
        ) {
            revert InvalidAmountOfTokens(_amount);
        }
        bytes32 offerId = keccak256(
            abi.encodePacked(
                _nftAddress,
                _tokenId,
                _amount,
                _seller,
                _msgSender(),
                block.number
            )
        );

        Offer storage newOffer = offers[offerId];
        newOffer.nftAddress = _nftAddress;
        newOffer.tokenId = _tokenId;
        newOffer.amount = _amount;
        newOffer.buyer = payable(_msgSender());
        newOffer.price = msg.value;
        newOffer.seller = payable(_seller);

        emit OfferCreated(
            offerId,
            _nftAddress,
            _tokenId,
            _amount,
            _msgSender(),
            msg.value,
            _seller
        );
    }

    function _updateOffer(bytes32 _offerId, uint256 _newPrice)
        internal
        isValidOffer(_offerId)
    {
        if (offers[_offerId].buyer != _msgSender()) {
            revert PermissionDenied();
        } else if (_newPrice > offers[_offerId].price) {
            if (msg.value < _newPrice - offers[_offerId].price) {
                revert InsufficientETHProvided(msg.value);
            }
        } else if (_newPrice == 0) {
            revert PriceMustBeAboveZero(msg.value);
        } else if (_newPrice == offers[_offerId].price) {
            revert PriceMustBeDifferent(_newPrice);
        }

        offers[_offerId].price = _newPrice;
        if (_newPrice < offers[_offerId].price) {
            if (
                !offers[_offerId].buyer.send(offers[_offerId].price - _newPrice)
            ) {
                revert TransactionError();
            }
        }

        emit OfferUpdated(_offerId, _newPrice);
    }

    function _acceptOffer(bytes32 _offerId)
        internal
        isValidOffer(_offerId)
        isApprovedMarketplace(
            offers[_offerId].nftAddress,
            offers[_offerId].tokenId,
            offers[_offerId].seller
        )
    {
        if (offers[_offerId].seller != _msgSender()) {
            revert PermissionDenied();
        }

        if (!offers[_offerId].seller.send(offers[_offerId].price)) {
            revert TransactionError();
        }

        _transfer721And1155(
            _msgSender(),
            offers[_offerId].buyer,
            offers[_offerId].nftAddress,
            offers[_offerId].tokenId,
            offers[_offerId].amount
        );

        emit OfferAccepted(_offerId);
    }

    function _declineOffer(bytes32 _offerId) internal isValidOffer(_offerId) {
        if (offers[_offerId].seller != _msgSender()) {
            revert PermissionDenied();
        }

        if (!offers[_offerId].buyer.send(offers[_offerId].price)) {
            revert TransactionError();
        }

        delete offers[_offerId];
        emit OfferDeclined(_offerId);
    }

    function _cancelOffer(bytes32 _offerId) internal isValidOffer(_offerId) {
        if (offers[_offerId].buyer != _msgSender()) {
            revert PermissionDenied();
        }

        if (!offers[_offerId].buyer.send(offers[_offerId].price)) {
            revert TransactionError();
        }

        delete offers[_offerId];
        emit OfferCancelled(_offerId);
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
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
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./NFTingErrors.sol";

contract NFTingBase is Context, IERC721Receiver, IERC1155Receiver {
    bytes4 internal constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 internal constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    modifier isValidAddress(address _addr) {
        if (
            !_supportsInterface(_addr, INTERFACE_ID_ERC1155) &&
            !_supportsInterface(_addr, INTERFACE_ID_ERC721)
        ) {
            revert InvalidAddressProvided(_addr);
        }

        _;
    }

    modifier isTokenOwnerOrApproved(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _amount,
        address _addr
    ) {
        if (_supportsInterface(_nftAddress, INTERFACE_ID_ERC1155)) {
            if (
                IERC1155(_nftAddress).balanceOf(_addr, _tokenId) < _amount &&
                !IERC1155(_nftAddress).isApprovedForAll(_addr, _msgSender())
            ) {
                revert NotTokenOwnerOrInsufficientAmount();
            }
            _;
        } else if (_supportsInterface(_nftAddress, INTERFACE_ID_ERC721)) {
            if (
                IERC721(_nftAddress).ownerOf(_tokenId) != _addr &&
                IERC721(_nftAddress).getApproved(_tokenId) != _addr
            ) {
                revert NotTokenOwnerOrInsufficientAmount();
            }
            _;
        } else {
            revert InvalidAddressProvided(_nftAddress);
        }
    }

    modifier isApprovedMarketplace(
        address _nftAddress,
        uint256 _tokenId,
        address _owner
    ) {
        if (_supportsInterface(_nftAddress, INTERFACE_ID_ERC1155)) {
            if (
                !IERC1155(_nftAddress).isApprovedForAll(_owner, address(this))
            ) {
                revert NotApprovedMarketplace();
            }
            _;
        } else if (_supportsInterface(_nftAddress, INTERFACE_ID_ERC721)) {
            if (
                !IERC721(_nftAddress).isApprovedForAll(_owner, address(this)) &&
                IERC721(_nftAddress).getApproved(_tokenId) != address(this)
            ) {
                revert NotApprovedMarketplace();
            }
            _;
        } else {
            revert InvalidAddressProvided(_nftAddress);
        }
    }

    function _transfer721And1155(
        address _from,
        address _to,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _amount
    ) internal virtual {
        if (_amount == 0) {
            revert ZeroAmountTransfer();
        }

        if (_supportsInterface(_nftAddress, INTERFACE_ID_ERC1155)) {
            IERC1155(_nftAddress).safeTransferFrom(
                _from,
                _to,
                _tokenId,
                _amount,
                ""
            );
        } else if (_supportsInterface(_nftAddress, INTERFACE_ID_ERC721)) {
            IERC721(_nftAddress).safeTransferFrom(_from, _to, _tokenId);
        } else {
            revert InvalidAddressProvided(_nftAddress);
        }
    }

    function _supportsInterface(address _addr, bytes4 _interface)
        internal
        view
        returns (bool)
    {
        return IERC165(_addr).supportsInterface(_interface);
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external virtual override returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external virtual override returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external virtual override returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256[],uint256[],bytes)"
                )
            );
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            type(IERC1155Receiver).interfaceId == _interfaceId ||
            type(IERC721Receiver).interfaceId == _interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
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
pragma solidity ^0.8.4;

// Common Errors
error WithdrawalFailed();
error NoTrailingSlash(string _uri);
error InvalidArgumentsProvided();
error PriceMustBeAboveZero(uint256 _price);
error PermissionDenied();
error InvalidTokenId(uint256  _tokenId);

// NFTing Base Contract
error NotTokenOwnerOrInsufficientAmount();
error NotApprovedMarketplace();
error ZeroAmountTransfer();
error TransactionError();
error InvalidAddressProvided(address _invalidAddress);

// PreAuthorization Contract
error NoAuthorizedOperator();

// Auction Contract
error NotExistingAuction();
error ExistingAuction();
error NotExistingBidder(address _bidder);
error NotEnoughPriceToBid();
error ExpiredAuction();
error ValidAuction();
error NotAuctionCreatorOrOwner();
error InvalidAmountOfTokens(uint256 _amount);

// Offer Contract
error NotExistingOffer(bytes32 _offerId);
error PriceMustBeDifferent(uint256 _price);
error InsufficientETHProvided(uint256 _value);

// Marketplace Contract
error NotListed();
error NotEnoughEthProvided();
error NotTokenOwner();
error NotTokenSeller();
error TokenSeller();

// NFTing Single Token Contract
error MaxBatchMintLimitExceeded();
error AlreadyExistentToken();
error NotApprovedOrOwner();
error MaxMintLimitExceeded();

// NFTing Token Manager Contract
error AlreadyRegisteredAddress();

// NFTingSignature
error HashUsed(bytes32 _hash);
error SignatureFailed(address _signatureAddress, address _signer);