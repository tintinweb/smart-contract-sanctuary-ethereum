// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@manifoldxyz/libraries-solidity/contracts/access/AdminControlUpgradeable.sol";
import "./MarketplaceCore.sol";

contract MarketplaceUpgradeable is AdminControlUpgradeable, MarketplaceCore, ReentrancyGuardUpgradeable {

    /**
     * Initializer
     */
    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        _setEnabled(true);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControlUpgradeable) returns (bool) {
        return interfaceId == type(IMarketplaceCore).interfaceId
            || AdminControlUpgradeable.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IMarketplace-setFees}.
     */
    function setFees(uint16 marketplaceFeeBPS, uint16 marketplaceReferrerBPS) external virtual override adminRequired {
        _setFees(marketplaceFeeBPS, marketplaceReferrerBPS);
    }
    
    /**
     * @dev See {IMarketplace-setEnabled}.
     */
    function setEnabled(bool enabled) external virtual override adminRequired {
        _setEnabled(enabled);
    }

    /**
     * @dev See {IMarketplace-setSellerRegistry}.
     */
    function setSellerRegistry(address registry) external virtual override adminRequired {
        _setSellerRegistry(registry);
    }

    /**
     * @dev See {IMarketplace-setRoyaltyEngineV1}.
     */
    function setRoyaltyEngineV1(address royaltyEngineV1) external virtual override adminRequired {
        _setRoyaltyEngineV1(royaltyEngineV1);
    }

    /**
     * @dev See {IMarketplace-cancel}.
     */
    function cancel(uint40 listingId, uint16 holdbackBPS) external virtual override nonReentrant {
        _cancel(listingId, holdbackBPS, isAdmin(msg.sender));
    }

    /**
     * @dev See {IMarketplace-withdraw}.
     */
    function withdraw(uint256 amount, address payable receiver) external virtual override adminRequired nonReentrant {
        _withdraw(address(0), amount, receiver);
    }

    /**
     * @dev See {IMarketplace-withdraw}.
     */
    function withdraw(address erc20, uint256 amount, address payable receiver) external virtual override adminRequired nonReentrant {
        _withdraw(erc20, amount, receiver);
    }

    /**
     * @dev See {IMarketplace-withdrawEscrow}.
     */
    function withdrawEscrow(uint256 amount) external virtual override nonReentrant {
        _withdrawEscrow(address(0), amount);
    }

    /**
     * @dev See {IMarketplace-withdrawEscrow}.
     */
    function withdrawEscrow(address erc20, uint256 amount) external virtual override nonReentrant {
        _withdrawEscrow(erc20, amount);
    }

    uint256[50] private __gap;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./IMarketplaceCore.sol";
import "./IMarketplaceSellerRegistry.sol";

import "./libs/MarketplaceLib.sol";
import "./libs/SettlementLib.sol";
import "./libs/TokenLib.sol";

abstract contract MarketplaceCore is IMarketplaceCore, IERC721Receiver {
    using EnumerableSet for EnumerableSet.AddressSet;

    bool private _enabled;
    address private _sellerRegistry;
     
    uint40 private _listingCounter;
    mapping (uint40 => MarketplaceLib.Listing) private _listings;
    mapping (uint40 => mapping (address => MarketplaceLib.Offer)) private _listingOffers;
    mapping (uint40 => EnumerableSet.AddressSet) private _listingOfferAddresses;
    mapping (address => mapping (address => uint256)) private _escrow;

    // Marketplace fee
    uint16 public feeBPS;
    uint16 public referrerBPS;
    mapping (address => uint256) _feesCollected;

    // Royalty Engine
    address private _royaltyEngineV1;

    uint256[50] private __gap;

    /**
     * @dev Set enabled
     */
    function _setEnabled(bool enabled) internal {
        _enabled = enabled;
        emit MarketplaceEnabled(msg.sender, enabled);
    }

    /**
     * @dev Set seller registry
     */
    function _setSellerRegistry(address registry) internal {
        require(ERC165Checker.supportsInterface(registry, type(IMarketplaceSellerRegistry).interfaceId), "Invalid input");
        _sellerRegistry = registry;
        emit MarketplaceSellerRegistry(msg.sender, registry);
    }

    /**
     * @dev Set royalty engine
     */
    function _setRoyaltyEngineV1(address royaltyEngineV1) internal {
        require(_royaltyEngineV1 == address(0), "Invalid state");
        emit MarketplaceRoyaltyEngineUpdate(royaltyEngineV1);
        _royaltyEngineV1 = royaltyEngineV1;
    }

    /**
     * @dev Set marketplace fees
     */
    function _setFees(uint16 feeBPS_, uint16 referrerBPS_) internal {
        require(feeBPS_ <= 1500 && referrerBPS_ <= 1500, "Invalid config");
        feeBPS = feeBPS_;
        referrerBPS = referrerBPS_;
        emit MarketplaceFees(msg.sender, feeBPS, referrerBPS);
    }

    /**
     * @dev Withdraw accumulated fees from marketplace
     */
    function _withdraw(address erc20, uint256 amount, address payable receiver) internal {
        require(_feesCollected[erc20] >= amount, "Invalid amount");
        _feesCollected[erc20] -= amount;
        SettlementLib.sendTokens(erc20, address(this), receiver, amount);
        emit MarketplaceWithdraw(msg.sender, erc20, amount, receiver);
    }

    /**
     * @dev Withdraw escrow amounts
     */
    function _withdrawEscrow(address erc20, uint256 amount) internal {
        require(_escrow[msg.sender][erc20] >= amount, "Invalid amount");
        _escrow[msg.sender][erc20] -= amount;
        SettlementLib.sendTokens(erc20, address(this), payable(msg.sender), amount);
        emit MarketplaceWithdrawEscrow(msg.sender, erc20, amount);
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
        require(operator == from, "Unauthorized");
        (
            MarketplaceLib.ListingDetails memory listingDetails,
            MarketplaceLib.TokenDetails memory tokenDetails,
            MarketplaceLib.DeliveryFees memory deliveryFees,
            MarketplaceLib.ListingReceiver[] memory listingReceivers,
            bool enableReferrer,
            bool acceptOffers,
            bytes memory listingData
        ) = abi.decode(data, (MarketplaceLib.ListingDetails, MarketplaceLib.TokenDetails, MarketplaceLib.DeliveryFees, MarketplaceLib.ListingReceiver[], bool, bool, bytes));
        require(msg.sender == tokenDetails.address_ && tokenId == tokenDetails.id && tokenDetails.spec == TokenLib.Spec.ERC721, "Invalid config");
        _createListing(from, listingDetails, tokenDetails, deliveryFees, listingReceivers, enableReferrer, acceptOffers, listingData, false);
        return this.onERC721Received.selector;
    }

    /**
     * @dev See {IERC721Receiver-onERC1155Received}.
     */
    function onERC1155Received(address operator, address from, uint256 tokenId, uint256 count, bytes calldata data) external virtual returns(bytes4) {
        if (operator != address(this)) {
            require(operator == from, "Unauthorized");
            (
                MarketplaceLib.ListingDetails memory listingDetails,
                MarketplaceLib.TokenDetails memory tokenDetails,
                MarketplaceLib.DeliveryFees memory deliveryFees,
                MarketplaceLib.ListingReceiver[] memory listingReceivers,
                bool enableReferrer,
                bool acceptOffers,
                bytes memory listingData
            ) = abi.decode(data, (MarketplaceLib.ListingDetails, MarketplaceLib.TokenDetails, MarketplaceLib.DeliveryFees, MarketplaceLib.ListingReceiver[], bool, bool, bytes));
            require(msg.sender == tokenDetails.address_ && tokenId == tokenDetails.id && tokenDetails.spec == TokenLib.Spec.ERC1155 && count == listingDetails.totalAvailable, "Invalid config");
            _createListing(from, listingDetails, tokenDetails, deliveryFees, listingReceivers, enableReferrer, acceptOffers, listingData, false);
        }
        return this.onERC1155Received.selector;
    }

    /**
     * @dev See {IMarketplaceCore-createListing}.
     */
    function createListing(MarketplaceLib.ListingDetails calldata listingDetails, MarketplaceLib.TokenDetails calldata tokenDetails, MarketplaceLib.DeliveryFees calldata deliveryFees, MarketplaceLib.ListingReceiver[] calldata listingReceivers, bool enableReferrer, bool acceptOffers, bytes calldata data) external virtual override returns (uint40) {
        return _createListing(msg.sender, listingDetails, tokenDetails, deliveryFees, listingReceivers, enableReferrer, acceptOffers, data, true);
    }

    function _createListing(address seller, MarketplaceLib.ListingDetails memory listingDetails, MarketplaceLib.TokenDetails memory tokenDetails, MarketplaceLib.DeliveryFees memory deliveryFees, MarketplaceLib.ListingReceiver[] memory listingReceivers, bool enableReferrer, bool acceptOffers, bytes memory data, bool intake) private returns (uint40) {
        require(_enabled, "Disabled");
        require(_sellerRegistry == address(0) || IMarketplaceSellerRegistry(_sellerRegistry).isAuthorized(seller, data), "Unauthorized");

        _listingCounter++;
        MarketplaceLib.Listing storage listing = _listings[_listingCounter];
        listing.marketplaceBPS = feeBPS;
        if (enableReferrer) {
            listing.referrerBPS = referrerBPS;
        }
        MarketplaceLib.constructListing(seller, _listingCounter, listing, listingDetails, tokenDetails, deliveryFees, listingReceivers, acceptOffers, intake);

        return _listingCounter;
    }

    /**
     * @dev See {IMarketplaceCore-modifyListing}.
     */
    function modifyListing(uint40 listingId, uint256 initialAmount, uint48 startTime, uint48 endTime) external virtual override {
        MarketplaceLib.Listing storage listing = _getListing(listingId);
        MarketplaceLib.modifyListing(listingId, listing, initialAmount, startTime, endTime);
    }

    /**
     * @dev See {IMarketplaceCore-purchase}.
     */
    function purchase(uint40 listingId) external payable virtual override {
        _purchase(payable(address(0)), listingId, 1, "");
    }
    function purchase(uint40 listingId, bytes calldata data) external payable virtual override {
        _purchase(payable(address(0)), listingId, 1, data);
    }
    
    /**
     * @dev See {IMarketplaceCore-purchase}.
     */
    function purchase(address referrer, uint40 listingId) external payable virtual override {
        _purchase(payable(referrer), listingId, 1, "");
    }
    function purchase(address referrer, uint40 listingId, bytes calldata data) external payable virtual override {
        _purchase(payable(referrer), listingId, 1, data);
    }

    /**
     * @dev See {IMarketplaceCore-purchase}.
     */  
    function purchase(uint40 listingId, uint24 count) external payable virtual override {
        _purchase(payable(address(0)), listingId, count, "");
    }
    function purchase(uint40 listingId, uint24 count, bytes calldata data) external payable virtual override {
        _purchase(payable(address(0)), listingId, count, data);
    }
  
    /**
     * @dev See {IMarketplaceCore-purchase}.
     */
    function purchase(address referrer, uint40 listingId, uint24 count) external payable virtual override {
        _purchase(payable(referrer), listingId, count, "");
    }
    function purchase(address referrer, uint40 listingId, uint24 count, bytes calldata data) external payable virtual override {
        _purchase(payable(referrer), listingId, count, data);
    }
    
    function _purchase(address payable referrer, uint40 listingId, uint24 count, bytes memory data) private {
        MarketplaceLib.Listing storage listing = _getListing(listingId);
        SettlementLib.performPurchase(_royaltyEngineV1, referrer, listingId, listing, count, _feesCollected, data);
    }

    /**
     * @dev See {IMarketplaceCore-bid}.
     */
    function bid(uint40 listingId, bool increase) external payable virtual override {
        _bid(msg.value, payable(address(0)), listingId, increase, "");
    }
    function bid(uint40 listingId, bool increase, bytes calldata data) external payable virtual override {
        _bid(msg.value, payable(address(0)), listingId, increase, data);
    }

    /**
     * @dev See {IMarketplaceCore-bid}.
     */
    function bid(address payable referrer, uint40 listingId, bool increase) external payable virtual override {
        _bid(msg.value, referrer, listingId, increase, "");
    }
    function bid(address payable referrer, uint40 listingId, bool increase, bytes calldata data) external payable virtual override {
        _bid(msg.value, referrer, listingId, increase, data);
    }

    /**
     * @dev See {IMarketplaceCore-bid}.
     */
    function bid(uint40 listingId, uint256 bidAmount, bool increase) external virtual override {
        _bid(bidAmount, payable(address(0)), listingId, increase, "");
    }
    function bid(uint40 listingId, uint256 bidAmount, bool increase, bytes calldata data) external virtual override {
        _bid(bidAmount, payable(address(0)), listingId, increase, data);
    }

    /**
     * @dev See {IMarketplaceCore-bid}.
     */
    function bid(address payable referrer, uint40 listingId, uint256 bidAmount, bool increase) external virtual override {
        _bid(bidAmount, referrer, listingId, increase, "");
    }
    function bid(address payable referrer, uint40 listingId, uint256 bidAmount, bool increase, bytes calldata data) external virtual override {
        _bid(bidAmount, referrer, listingId, increase, data);
    }

    function _bid(uint256 bidAmount, address payable referrer, uint40 listingId, bool increase, bytes memory data) private {
        MarketplaceLib.Listing storage listing = _getListing(listingId);
        SettlementLib.performBid(listingId, listing, bidAmount, referrer, increase, _escrow, data);
    }

    /**
     * @dev See {IMarketplaceCore-offer}.
     */
    function offer(uint40 listingId, bool increase) external payable virtual override {
        _offer(msg.value, payable(address(0)), listingId, increase, "");
    }
    function offer(uint40 listingId, bool increase, bytes calldata data) external payable virtual override {
        _offer(msg.value, payable(address(0)), listingId, increase, data);
    }

    /**
     * @dev See {IMarketplaceCore-offer}.
     */
    function offer(address payable referrer, uint40 listingId, bool increase) external payable virtual override {
        _offer(msg.value, referrer, listingId, increase, "");
    }
    function offer(address payable referrer, uint40 listingId, bool increase, bytes calldata data) external payable virtual override {
        _offer(msg.value, referrer, listingId, increase, data);
    }

    /**
     * @dev See {IMarketplaceCore-offer}.
     */
    function offer(uint40 listingId, uint256 offerAmount, bool increase) external virtual override {
        _offer(offerAmount, payable(address(0)), listingId, increase, "");
    }
    function offer(uint40 listingId, uint256 offerAmount, bool increase, bytes calldata data) external virtual override {
        _offer(offerAmount, payable(address(0)), listingId, increase, data);
    }

    /**
     * @dev See {IMarketplaceCore-offer}.
     */
    function offer(address payable referrer, uint40 listingId, uint256 offerAmount, bool increase) external virtual override {
        _offer(offerAmount, referrer, listingId, increase, "");
    }
    function offer(address payable referrer, uint40 listingId, uint256 offerAmount, bool increase, bytes calldata data) external virtual override {
        _offer(offerAmount, referrer, listingId, increase, data);
    }

    function _offer(uint256 offerAmount, address payable referrer, uint40 listingId, bool increase, bytes memory data) private {
        MarketplaceLib.Listing storage listing = _getListing(listingId);
        SettlementLib.makeOffer(listingId, listing, offerAmount, referrer, _listingOffers[listingId], _listingOfferAddresses[listingId], increase, data);
    }

    /**
     * @dev See {IMarketplaceCore-rescind}.
     */
    function rescind(uint40 listingId) public virtual override {
        MarketplaceLib.Listing storage listing = _getListing(listingId);
        MarketplaceLib.ListingType listingType = listing.details.type_;

        // Can only rescind offers if
        // 1. Listing is NOT an OFFERS_ONLY type
        // 2. Listing has been finalized
        // 3. Listing IS an OFFERS_ONLY type that has ended over 24 hours ago
        // it has been finalized, or it has been 24 hours after the listing end time
        require(
            listingType != MarketplaceLib.ListingType.OFFERS_ONLY ||
            MarketplaceLib.isFinalized(listing.flags) ||
            (listing.details.endTime+86400) < block.timestamp,
            "Cannot be rescinded yet"
        );
        SettlementLib.rescindOffer(listingId, listing, msg.sender, _listingOffers[listingId], _listingOfferAddresses[listingId]);
    }
    function rescind(uint40[] calldata listingIds) external virtual override {
        for (uint i; i < listingIds.length;) {
            rescind(listingIds[i]);
            unchecked { ++i; }
        }
    }
    function rescind(uint40 listingId, address[] calldata offerAddresses) external virtual override {
        MarketplaceLib.Listing storage listing = _getListing(listingId);
        require(listing.seller == msg.sender, "Permission denied");
        for (uint i; i < offerAddresses.length;) {
            SettlementLib.rescindOffer(listingId, listing, offerAddresses[i], _listingOffers[listingId], _listingOfferAddresses[listingId]);
            unchecked { ++i; }
        }
    }

    /**
     * @dev See {IMarketplaceCore-accept}.
     */
    function accept(uint40 listingId, address[] calldata addresses, uint256[] calldata amounts, uint256 maxAmount) external virtual override {
        uint256 addressLength = addresses.length;
        require(addressLength == amounts.length, "Invalid input");
        MarketplaceLib.Listing storage listing = _getListing(listingId);
        MarketplaceLib.ListingType listingType = listing.details.type_;
        require(msg.sender == listing.seller && !MarketplaceLib.isFinalized(listing.flags), "Invalid listing");

        // Mark as finalized first to prevent re-entrancy
        listing.flags |= MarketplaceLib.FLAG_MASK_FINALIZED;
        // End the listing
        if (listing.details.startTime == 0) listing.details.startTime = uint48(block.timestamp);
        if (listing.details.endTime > block.timestamp) listing.details.endTime = uint48(block.timestamp);
        uint24 totalPerSale = listing.details.totalPerSale;

        if (MarketplaceLib.isAuction(listingType)) {
            require(!MarketplaceLib.hasBid(listing.flags), "Cannot accept offers when bid has been made");
            require(addressLength == 1, "Too many offers accepted");
            listing.totalSold += totalPerSale;
            _accept(listingId, listing, payable(addresses[0]), amounts[0], maxAmount);
        } else if (MarketplaceLib.isOffer(listingType)) {
            require(addressLength*totalPerSale <= listing.details.totalAvailable, "Too many offers accepted");
            listing.totalSold += uint24(totalPerSale*addressLength);
            for (uint i; i < addressLength;) {
                _accept(listingId, listing, payable(addresses[i]), amounts[i], maxAmount);
                unchecked { ++i; }
            }
        }
    }

    function _accept(uint40 listingId, MarketplaceLib.Listing storage listing, address payable offerAddress, uint256 expectedAmount, uint256 maxAmount) private {
        require(_listingOfferAddresses[listingId].contains(offerAddress), "Invalid address");
        MarketplaceLib.Offer storage currentOffer = _listingOffers[listingId][offerAddress];
        require(currentOffer.amount == expectedAmount, "Invalid state");
        if (listing.token.lazy) {
            SettlementLib.deliverTokenLazy(listingId, listing, offerAddress, 1, expectedAmount, 0);
        } else {
            SettlementLib.deliverToken(listing, offerAddress, 1, expectedAmount, false);
        }
        // Settle offer
        SettlementLib.settleOffer(_royaltyEngineV1, listingId, listing, currentOffer, offerAddress, _feesCollected, maxAmount, _escrow);
    }

    /**
     * @dev See {IMarketplaceCore-collect}.
     */
    function collect(uint40 listingId) external virtual override {
        MarketplaceLib.Listing storage listing = _getListing(listingId);
        require(msg.sender == listing.seller && !MarketplaceLib.isFinalized(listing.flags), "Invalid listing");
        require(listing.details.startTime != 0 && listing.details.endTime < block.timestamp, "Invalid state");

        // Only tokens in custody and individual auction types allow funds collection pre-delivery
        require(!listing.token.lazy && listing.details.type_ == MarketplaceLib.ListingType.INDIVIDUAL_AUCTION, "Invalid type");
        
        MarketplaceLib.Bid storage bid_ = listing.bid;
        require(!bid_.settled, "Invalid state");
        
        // Settle bid
        SettlementLib.settleBid(_royaltyEngineV1, bid_, listing, _feesCollected);
    }

    /**
     * Cancel an active sale and refund outstanding amounts
     */
    function _cancel(uint40 listingId, uint16 holdbackBPS, bool isAdmin) internal virtual {
        MarketplaceLib.Listing storage listing = _getListing(listingId);
        require(!MarketplaceLib.isFinalized(listing.flags), "Invalid listing");
        require(holdbackBPS <= 1000, "Invalid input");

        if (!isAdmin) {
           // If not admin, must be seller, must not have holdbackBPS, auction cannot have started
           require(listing.seller == msg.sender, "Permission denied");
           require(holdbackBPS == 0, "Invalid input");
           require(!MarketplaceLib.hasBid(listing.flags), "Invalid state");
        }
        
        // Immediately end and finalize to prevent re-entrancy
        if (listing.details.startTime == 0) listing.details.startTime = uint48(block.timestamp);
        listing.details.endTime = uint48(block.timestamp);
        listing.flags |= MarketplaceLib.FLAG_MASK_FINALIZED;

        // Refund open bids
        if (MarketplaceLib.hasBid(listing.flags)) {
            if (listing.details.type_ == MarketplaceLib.ListingType.INDIVIDUAL_AUCTION) {
                SettlementLib.refundBid(listing.bid, listing, holdbackBPS, _escrow);
            }
        }

        if (!listing.token.lazy) {
            // Return remaining items to seller
            SettlementLib.deliverToken(listing, listing.seller, 1, 0, true);
        }
        emit MarketplaceLib.CancelListing(listingId, msg.sender, holdbackBPS);
    }

    /**
     * @dev See {IMarketplaceCore-finalize}.
     */
    function finalize(uint40 listingId) external payable virtual override {
        MarketplaceLib.Listing storage listing = _getListing(listingId);
        MarketplaceLib.ListingType listingType = listing.details.type_;
        require(!MarketplaceLib.isOffer(listingType), "Invalid type");
        require(!MarketplaceLib.isFinalized(listing.flags), "Invalid listing");
        require(listing.details.startTime != 0 && listing.details.endTime < block.timestamp, "Invalid state");

        // Mark as finalized first to prevent re-entrancy
        listing.flags |= MarketplaceLib.FLAG_MASK_FINALIZED;

        if (!MarketplaceLib.hasBid(listing.flags)) {
            if (!listing.token.lazy) {
                // No buyer, return to seller
                SettlementLib.deliverToken(listing, listing.seller, 1, 0, true);
            }
        } else if (listingType == MarketplaceLib.ListingType.INDIVIDUAL_AUCTION) {
            listing.totalSold += listing.details.totalPerSale;
            MarketplaceLib.Bid storage currentBid = listing.bid;
            if (listing.token.lazy) {
                SettlementLib.deliverTokenLazy(listingId, listing, currentBid.bidder, 1, currentBid.amount, 0);
            } else {
                SettlementLib.deliverToken(listing, currentBid.bidder, 1, currentBid.amount, false);
            }
            
            // Settle bid
            SettlementLib.settleBid(_royaltyEngineV1, currentBid, listing, _feesCollected);
            // Mark delivered
            currentBid.delivered = true;

        } else {
            // Invalid type
            revert("Invalid type");
        }

        emit MarketplaceLib.FinalizeListing(listingId);
    }

    /**
     * @dev See {IMarketplaceCore-getListing}.
     */
    function getListing(uint40 listingId) external view override returns(Listing memory listing) {
        MarketplaceLib.Listing storage internalListing = _getListing(listingId);
        listing.id = listingId;
        listing.seller = internalListing.seller;
        listing.finalized = MarketplaceLib.isFinalized(internalListing.flags);
        listing.totalSold = internalListing.totalSold;
        listing.marketplaceBPS = internalListing.marketplaceBPS;
        listing.referrerBPS = internalListing.referrerBPS;
        listing.details = internalListing.details;
        listing.token = internalListing.token;
        listing.receivers = internalListing.receivers;
        listing.fees = internalListing.fees;
        listing.bid = internalListing.bid;
        listing.offersAccepted = (internalListing.flags & MarketplaceLib.FLAG_MASK_ACCEPT_OFFERS) != 0;
    }

    /**
     * @dev See {IMarketplaceCore-getListingCurrentPrice}.
     */
    function getListingCurrentPrice(uint40 listingId) external view override returns(uint256) {
        MarketplaceLib.Listing storage listing = _getListing(listingId);
        return SettlementLib.computeListingPrice(listing);
    }

    /**
     * @dev See {IMarketplaceCore-getListingTotalPrice}.
     */
    function getListingTotalPrice(uint40 listingId, uint24 count) external view override returns(uint256) {
        MarketplaceLib.Listing storage listing = _getListing(listingId);
        return SettlementLib.computeTotalPrice(listing, count);
    }

    /**
     * @dev See {IMarketplaceCore-geListingDeliverFee}.
     */
    function getListingDeliverFee(uint40 listingId, uint256 price) external view override returns(uint256) {
        MarketplaceLib.Listing storage listing = _getListing(listingId);
        return SettlementLib.computeDeliverFee(listing, price);
    }

    /**
     * @dev See {IMarketplaceCore-getBids}.
     */
    function getBids(uint40 listingId) external view virtual override returns(MarketplaceLib.Bid[] memory bids) {
        MarketplaceLib.Listing storage listing = _getListing(listingId);
        if (MarketplaceLib.hasBid(listing.flags)) {
            bids = new MarketplaceLib.Bid[](1);
            bids[0] = listing.bid;
        }
    }

    /**
     * @dev See {IMarketplaceCore-getOffers}
     */
    function getOffers(uint40 listingId) external view override returns(Offer[] memory offers) {
        EnumerableSet.AddressSet storage offerAddresses = _listingOfferAddresses[listingId];
        uint256 offerCount = offerAddresses.length();
        offers = new Offer[](offerCount);
        for (uint i; i < offerCount;) {
            address offerer = offerAddresses.at(i);
            MarketplaceLib.Offer memory internalOffer = _listingOffers[listingId][offerer];
            offers[i].offerer = offerer;
            offers[i].amount = internalOffer.amount;
            offers[i].timestamp = internalOffer.timestamp;
            offers[i].accepted = internalOffer.accepted;
            unchecked { i++; }
        }
    }

    function _getListing(uint40 listingId) private view returns(MarketplaceLib.Listing storage) {
        require(listingId > 0 && listingId <= _listingCounter, "Invalid listing");
        return _listings[listingId];
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./IAdminControl.sol";

abstract contract AdminControlUpgradeable is OwnableUpgradeable, IAdminControl, ERC165 {
    using EnumerableSet for EnumerableSet.AddressSet;

    // Track registered admins
    EnumerableSet.AddressSet private _admins;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IAdminControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Only allows approved admins to call the specified function
     */
    modifier adminRequired() {
        require(owner() == msg.sender || _admins.contains(msg.sender), "AdminControl: Must be owner or admin");
        _;
    }   

    /**
     * @dev See {IAdminControl-getAdmins}.
     */
    function getAdmins() external view override returns (address[] memory admins) {
        admins = new address[](_admins.length());
        for (uint i = 0; i < _admins.length(); i++) {
            admins[i] = _admins.at(i);
        }
        return admins;
    }

    /**
     * @dev See {IAdminControl-approveAdmin}.
     */
    function approveAdmin(address admin) external override onlyOwner {
        if (!_admins.contains(admin)) {
            emit AdminApproved(admin, msg.sender);
            _admins.add(admin);
        }
    }

    /**
     * @dev See {IAdminControl-revokeAdmin}.
     */
    function revokeAdmin(address admin) external override onlyOwner {
        if (_admins.contains(admin)) {
            emit AdminRevoked(admin, msg.sender);
            _admins.remove(admin);
        }
    }

    /**
     * @dev See {IAdminControl-isAdmin}.
     */
    function isAdmin(address admin) public override view returns (bool) {
        return (owner() == admin || _admins.contains(admin));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./libs/MarketplaceLib.sol";

/**
 * Core Marketplace interface
 */     
interface IMarketplaceCore {

    event MarketplaceEnabled(address requestor, bool value);
    event MarketplaceFees(address requestor, uint16 feeBPS, uint16 referrerBPS);
    event MarketplaceSellerRegistry(address requestor, address registry);
    event MarketplaceWithdraw(address requestor, address erc20, uint256 amount, address receiver);
    event MarketplaceWithdrawEscrow(address requestor, address erc20, uint256 amount);
    event MarketplaceRoyaltyEngineUpdate(address royaltyEngineV1);

    /**
     * @dev Listing structure
     *
     * @param id              - id of listing
     * @param seller          - the selling party
     * @param finalized       - Whether or not this listing has completed accepting bids/purchases
     * @param totalSold       - total number of items sold.  This IS NOT the number of sales.  Number of sales is totalSold/details.totalPerSale.
     * @param marketplaceBPS  - Marketplace fee BPS
     * @param referrerBPS     - Referrer BPS
     * @param details         - ListingDetails.  Contains listing configuration
     * @param token           - TokenDetails.  Contains the details of token being sold
     * @param receivers       - Array of ListingReceiver structs.  If provided, will distribute sales proceeds to receivers accordingly.
     * @param fees            - DeliveryFees.  Contains the delivery fee configuration for the listing
     * @param bid             - Active bid.  Only valid for INDIVIDUAL_AUCTION (1 bid)
     */
    struct Listing {
        uint256 id;
        address payable seller;
        bool finalized;
        uint24 totalSold;
        uint16 marketplaceBPS;
        uint16 referrerBPS;
        MarketplaceLib.ListingDetails details;
        MarketplaceLib.TokenDetails token;
        MarketplaceLib.ListingReceiver[] receivers;
        MarketplaceLib.DeliveryFees fees;
        MarketplaceLib.Bid bid;
        bool offersAccepted;
    }

    /**
     * @dev Offer structure
     *
     * @param offerer     - The address that made the offer
     * @param amount      - The offer amount
     * @param timestamp   - The time the offer was made
     * @param accepted    - Whether or not the offer was accepted
     */
    struct Offer {
        address offerer;
        uint256 amount;
        uint48 timestamp;
        bool accepted;
    }

    /**
     * @dev Set marketplace fee
     */
    function setFees(uint16 marketplaceFeeBPS, uint16 marketplaceReferrerBPS) external;

    /**
     * @dev Set marketplace enabled
     */
    function setEnabled(bool enabled) external;

    /**
     * @dev Set marketplace seller registry
     */
    function setSellerRegistry(address registry) external;

    /**
     * @dev See RoyaltyEngineV1 location. Can only be set once
     */
    function setRoyaltyEngineV1(address royaltyEngineV1) external;

    /**
     * @dev Withdraw from treasury
     */
    function withdraw(uint256 amount, address payable receiver) external;

    /**
     * @dev Withdraw from treasury
     */
    function withdraw(address erc20, uint256 amount, address payable receiver) external;

    /**
     * @dev Withdraw from escrow
     */
    function withdrawEscrow(uint256 amount) external;

    /**
     * @dev Withdraw from escrow
     */
    function withdrawEscrow(address erc20, uint256 amount) external;

    /**
     * @dev Create listing
     */
    function createListing(MarketplaceLib.ListingDetails calldata listingDetails, MarketplaceLib.TokenDetails calldata tokenDetails, MarketplaceLib.DeliveryFees calldata deliveryFees, MarketplaceLib.ListingReceiver[] calldata listingReceivers, bool enableReferrer, bool acceptOffers, bytes calldata data) external returns (uint40);

    /**
     * @dev Modify listing
     */
    function modifyListing(uint40 listingId, uint256 initialAmount, uint48 startTime, uint48 endTime) external;

    /**
     * @dev Purchase a listed item
     */
    function purchase(uint40 listingId) external payable;
    function purchase(uint40 listingId, bytes calldata data) external payable;

    /**
     * @dev Purchase a listed item (with a referrer)
     */
    function purchase(address referrer, uint40 listingId) external payable;
    function purchase(address referrer, uint40 listingId, bytes calldata data) external payable;

    /**
     * @dev Purchase a listed item
     */
    function purchase(uint40 listingId, uint24 count) external payable;
    function purchase(uint40 listingId, uint24 count, bytes calldata data) external payable;

    /**
     * @dev Purchase a listed item (with a referrer)
     */
    function purchase(address referrer, uint40 listingId, uint24 count) external payable;
    function purchase(address referrer, uint40 listingId, uint24 count, bytes calldata data) external payable;

    /**
     * @dev Bid on a listed item
     */
    function bid(uint40 listingId, bool increase) external payable;
    function bid(uint40 listingId, bool increase, bytes calldata data) external payable;

    /**
     * @dev Bid on a listed item (with a referrer)
     */
    function bid(address payable referrer, uint40 listingId, bool increase) external payable;
    function bid(address payable referrer, uint40 listingId, bool increase, bytes calldata data) external payable;

    /**
     * @dev Bid on a listed item
     */
    function bid(uint40 listingId, uint256 bidAmount, bool increase) external;
    function bid(uint40 listingId, uint256 bidAmount, bool increase, bytes calldata data) external;

    /**
     * @dev Bid on a listed item (with a referrer)
     */
    function bid(address payable referrer, uint40 listingId, uint256 bidAmount, bool increase) external;
    function bid(address payable referrer, uint40 listingId, uint256 bidAmount, bool increase, bytes calldata data) external;

    /**
     * @dev Make offer on a listed item
     */
    function offer(uint40 listingId, bool increase) external payable;
    function offer(uint40 listingId, bool increase, bytes calldata data) external payable;

    /**
     * @dev Make offer on a listed item (with a referrer)
     */
    function offer(address payable referrer, uint40 listingId, bool increase) external payable;
    function offer(address payable referrer, uint40 listingId, bool increase, bytes calldata data) external payable;

    /**
     * @dev Make offer on a listed item
     */
    function offer(uint40 listingId, uint256 offerAmount, bool increase) external;
    function offer(uint40 listingId, uint256 offerAmount, bool increase, bytes calldata data) external;

    /**
     * @dev Make offer on a listed item (with a referrer)
     */
    function offer(address payable referrer, uint40 listingId, uint256 offerAmount, bool increase) external;
    function offer(address payable referrer, uint40 listingId, uint256 offerAmount, bool increase, bytes calldata data) external;

    /**
     * @dev Rescind an offer on a listed item
     */
    function rescind(uint40 listingId) external;
    function rescind(uint40[] calldata listingIds) external;
    function rescind(uint40 listingId, address[] calldata offerAddresses) external;

    /**
     * @dev Accept offer(s) on a listed item
     */
    function accept(uint40 listingId, address[] calldata addresses, uint256[] calldata amounts, uint256 maxAmount) external;

    /**
     * @dev Collect proceeds of sale.  Only valid for non-lazy auctions where the asset
     * is in escrow
     */
    function collect(uint40 listingId) external;

    /**
     * @dev Finalize a listed item (post-purchase)
     */
    function finalize(uint40 listingId) external payable;
    
    /**
     * @dev Cancel listing
     */
    function cancel(uint40 listingId, uint16 holdbackBPS) external;
    
    /**
     * @dev Get listing details
     */
    function getListing(uint40 listingId) external view returns(Listing memory);

    /**
     * @dev Get the listing's current price
     */
    function getListingCurrentPrice(uint40 listingId) external view returns(uint256);

    /**
     * @dev Get the listing's deliver fee
     */
    function getListingDeliverFee(uint40 listingId, uint256 price) external view returns(uint256);

    /**
     * @dev Get the total listing price for multiple items
     */
    function getListingTotalPrice(uint40 listingId, uint24 count) external view returns(uint256);

    /**
     * @dev Returns bids of a listing. No ordering guarantees
     */
    function getBids(uint40 listingId) external view returns(MarketplaceLib.Bid[] memory);

    /**
     * @dev Returns offers of a listing. No ordering guarantees
     */
    function getOffers(uint40 listingId) external view returns(Offer[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IMarketplaceSellerRegistry is IERC165 {

    // Events
    event SellerAdded(address requestor, address seller);
    event SellerRemoved(address requestor, address seller);

    /**
     *  @dev Check if seller is authorized
     *
     *  @param seller         Address of seller
     *  @param data           Additional data needed to verify
     */
    function isAuthorized(address seller, bytes calldata data) external view returns(bool);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "@manifoldxyz/libraries-solidity/contracts/access/IAdminControl.sol";

import "../IIdentityVerifier.sol";
import "../ILazyDelivery.sol";
import "../IPriceEngine.sol";

import "./TokenLib.sol";

/**
 * Interface for Ownable contracts
 */
interface IOwnable {
    function owner() external view returns(address);
}

/**
 * @dev Marketplace libraries
 */
library MarketplaceLib {
    using AddressUpgradeable for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Events
    event CreateListing(uint40 indexed listingId, uint16 marketplaceBPS, uint16 referrerBPS, uint8 listingType, uint24 totalAvailable, uint24 totalPerSale, uint48 startTime, uint48 endTime, uint256 initialAmount, uint16 extensionInterval, uint16 minIncrementBPS, address erc20, address identityVerifier);
    event CreateListingTokenDetails(uint40 indexed listingId, uint256 id, address address_, uint8 spec, bool lazy);
    event CreateListingFees(uint40 indexed listingId, uint16 deliverBPS, uint240 deliverFixed);

    event PurchaseEvent(uint40 indexed listingId, address referrer, address buyer, uint24 count, uint256 amount);
    event BidEvent(uint40 indexed listingId, address referrer, address bidder, uint256 amount);
    event OfferEvent(uint40 indexed listingId, address referrer, address oferrer, uint256 amount);
    event RescindOfferEvent(uint40 indexed listingId, address oferrer, uint256 amount);
    event AcceptOfferEvent(uint40 indexed listingId, address oferrer, uint256 amount);
    event ModifyListing(uint40 indexed listingId, uint256 initialAmount, uint48 startTime, uint48 endTime);
    event CancelListing(uint40 indexed listingId, address requestor, uint16 holdbackBPS);
    event FinalizeListing(uint40 indexed listingId);

    // Listing types
    enum ListingType {
        INVALID,
        INDIVIDUAL_AUCTION,
        FIXED_PRICE,
        DYNAMIC_PRICE,
        OFFERS_ONLY
    }

    /**
     * @dev Listing structure
     *
     * @param seller          - the selling party
     * @param flags           - bit flag (hasBid, finalized, tokenCreator).  See FLAG_MASK_*
     * @param totalSold       - total number of items sold.  This IS NOT the number of sales.  Number of sales is totalSold/details.totalPerSale.
     * @param marketplaceBPS  - Marketplace fee BPS
     * @param referrerBPS     - Fee BPS for referrer if there is one
     * @param details         - ListingDetails.  Contains listing configuration
     * @param token           - TokenDetails.  Contains the details of token being sold
     * @param receivers       - Array of ListingReceiver structs.  If provided, will distribute sales proceeds to receivers accordingly.
     * @param bid             - Active bid.  Only valid for INDIVIDUAL_AUCTION (1 bid)
     * @param fees            - DeliveryFees.  Contains the delivery fee configuration for the listing
     */
    struct Listing {
        address payable seller;
        uint8 flags;
        uint24 totalSold;
        uint16 marketplaceBPS;
        uint16 referrerBPS;
        ListingDetails details;
        TokenDetails token;
        ListingReceiver[] receivers;
        Bid bid;
        DeliveryFees fees;
    }

    uint8 internal constant FLAG_MASK_HAS_BID = 0x1;
    uint8 internal constant FLAG_MASK_FINALIZED = 0x2;
    uint8 internal constant FLAG_MASK_TOKEN_CREATOR = 0x4;
    uint8 internal constant FLAG_MASK_ACCEPT_OFFERS = 0x8;

    /**
     * @dev Listing details structure
     *
     * @param initialAmount     - The initial amount of the listing. For auctions, it represents the reserve price.  For DYNAMIC_PRICE listings, it must be 0.
     * @param type_             - Listing type
     * @param totalAvailable    - Total number of tokens available.  Must be divisible by totalPerSale. For INDIVIDUAL_AUCTION, totalAvailable must equal totalPerSale
     * @param totalPerSale      - Number of tokens the buyer will get per purchase.  Must be 1 if it is a lazy token
     * @param extensionInterval - Only valid for *_AUCTION types. Indicates how long an auction will extend if a bid is made within the last <extensionInterval> seconds of the auction.
     * @param minIncrementBPS   - Only valid for *_AUCTION types. Indicates the minimum bid increase required
     * @param erc20             - If not 0x0, it indicates the erc20 token accepted for this sale
     * @param identityVerifier  - If not 0x0, it indicates the buyers should be verified before any bid or purchase
     * @param startTime         - The start time of the sale.  If set to 0, startTime will be set to the first bid/purchase.
     * @param endTime           - The end time of the sale.  If startTime is 0, represents the duration of the listing upon first bid/purchase.
     */
    struct ListingDetails {
        uint256 initialAmount;
        ListingType type_;
        uint24 totalAvailable;
        uint24 totalPerSale;
        uint16 extensionInterval;
        uint16 minIncrementBPS;
        address erc20;
        address identityVerifier;
        uint48 startTime;
        uint48 endTime;
    }

    /**
     * @dev Token detail structure
     *
     * @param address_  - The contract address of the token
     * @param id        - The token id (or for a lazy asset, the asset id)
     * @param spec      - The spec of the token.  If it's a lazy token, it must be blank.
     * @param lazy      - True if token is to be lazy minted, false otherwise.  If lazy, the contract address must support ILazyDelivery
     */
    struct TokenDetails {
        uint256 id;
        address address_;
        TokenLib.Spec spec;
        bool lazy;
    }

    /**
     * @dev Fee configuration for listing
     *
     * @param deliverBPS         - Additional fee needed to deliver the token (BPS)
     * @param deliverFixed       - Additional fee needed to deliver the token (fixed)
     */
    struct DeliveryFees {
        uint16 deliverBPS;
        uint240 deliverFixed;
    }

    /**
     * Listing receiver.  The array of listing receivers must add up to 10000 BPS if provided.
     */
    struct ListingReceiver {
        address payable receiver;
        uint16 receiverBPS;
    }

    /**
     * Represents an active bid
     *
     * @param amount       - The bid amount
     * @param bidder       - The bidder
     * @param delivered    - Whether or not the token has been delivered.
     * @param settled      - Whether or not the seller has been paid
     * @param refunded     - Whether or not the bid has been refunded
     * @param timestamp    - Timestamp of bid
     * @param referrer     - The referrer
     */
    struct Bid {
        uint256 amount;
        address payable bidder;
        bool delivered;
        bool settled;
        bool refunded;
        uint48 timestamp;
        address payable referrer;
    }

    /**
     * Represents an active offer
     *
     * @param amount        - The offer amount
     * @param timestamp     - Timestamp of offer
     * @param accepted      - Whether or not the offer was accepted (seller was paid)
     * @param referrer      - The referrer
     * @param erc20         - Currently unused.
     *                        Offers can only be made on the listing currency
     */
    struct Offer {
        uint200 amount;
        uint48 timestamp;
        bool accepted;
        address payable referrer;
        address erc20;
    }

    /**
     * Construct a marketplace listing
     */
    function constructListing(address seller, uint40 listingId, Listing storage listing, ListingDetails calldata listingDetails, TokenDetails calldata tokenDetails, DeliveryFees calldata deliveryFees, ListingReceiver[] calldata listingReceivers, bool acceptOffers, bool intake) public {
        require(tokenDetails.address_.isContract(), "Token address must be a contract");
        require(listingDetails.endTime > listingDetails.startTime, "End time must be after start time");
        require(listingDetails.startTime == 0 || listingDetails.startTime > block.timestamp, "Start and end time cannot occur in the past");
        require(listingDetails.totalAvailable % listingDetails.totalPerSale == 0, "Invalid token config");
        require(!acceptOffers || listingDetails.type_ == ListingType.INDIVIDUAL_AUCTION, "Type cannot accept offers");
        
        if (listingDetails.identityVerifier != address(0)) {
            require(ERC165Checker.supportsInterface(listingDetails.identityVerifier, type(IIdentityVerifier).interfaceId), "Misconfigured verifier");
        }
        
        if (listingReceivers.length > 0) {
            uint256 totalBPS;
            for (uint i; i < listingReceivers.length;) {
                listing.receivers.push(listingReceivers[i]);
                totalBPS += listingReceivers[i].receiverBPS;
                unchecked { ++i; }
            }
            require(totalBPS == 10000, "Invalid receiver config");
        }

        if (listingDetails.type_ == ListingType.INDIVIDUAL_AUCTION) {
            require(listingDetails.totalAvailable == listingDetails.totalPerSale, "Invalid token config");
        } else if (listingDetails.type_ == ListingType.DYNAMIC_PRICE) {
            require(tokenDetails.lazy && listingDetails.initialAmount == 0, "Invalid listing config");
            require(ERC165Checker.supportsInterface(tokenDetails.address_, type(IPriceEngine).interfaceId), "Lazy delivered dynamic price items requires token address to implement IPriceEngine");
        } else if (listingDetails.type_ == ListingType.OFFERS_ONLY) {
            require(listingDetails.initialAmount == 0 && listingDetails.startTime > block.timestamp, "Invalid listing config");
        }

        // Purchase types        
        if (isPurchase(listingDetails.type_) || isOffer(listingDetails.type_)) {
            require(deliveryFees.deliverBPS == 0 && deliveryFees.deliverFixed == 0 && listingDetails.extensionInterval == 0 && listingDetails.minIncrementBPS == 0, "Invalid listing config");
        }

        if (tokenDetails.lazy) {
            require(listingDetails.totalPerSale == 1, "Invalid token config");
            require(ERC165Checker.supportsInterface(tokenDetails.address_, type(ILazyDelivery).interfaceId), "Lazy delivery requires token address to implement ILazyDelivery");
        } else {
            require(listingDetails.type_ == ListingType.INDIVIDUAL_AUCTION || listingDetails.type_ == ListingType.FIXED_PRICE, "Invalid type");
            if (intake) {
                _intakeToken(tokenDetails.spec, tokenDetails.address_, tokenDetails.id, listingDetails.totalAvailable, seller);
            }
        }

        // Set Listing Data
        listing.seller = payable(seller);
        listing.details = listingDetails;
        listing.token = tokenDetails;
        listing.fees = deliveryFees;

        // Token ownership check
        if (ERC165Checker.supportsInterface(tokenDetails.address_, type(IAdminControl).interfaceId)
                && IAdminControl(tokenDetails.address_).isAdmin(seller)) {
            listing.flags |= FLAG_MASK_TOKEN_CREATOR;
        } else {
            try IOwnable(tokenDetails.address_).owner() returns (address owner) {
                if (owner == seller) listing.flags |= FLAG_MASK_TOKEN_CREATOR;
            } catch {}
        }
        
        if (acceptOffers) {
            listing.flags |= FLAG_MASK_ACCEPT_OFFERS;
        }
        
        _emitCreateListing(listingId, listing);

    }

    function _emitCreateListing(uint40 listingId, Listing storage listing) private {
        emit CreateListing(listingId, listing.marketplaceBPS, listing.referrerBPS, uint8(listing.details.type_), listing.details.totalAvailable, listing.details.totalPerSale, listing.details.startTime, listing.details.endTime, listing.details.initialAmount, listing.details.extensionInterval, listing.details.minIncrementBPS, listing.details.erc20, listing.details.identityVerifier);
        emit CreateListingTokenDetails(listingId, listing.token.id, listing.token.address_, uint8(listing.token.spec), listing.token.lazy);
        if (listing.fees.deliverBPS > 0 || listing.fees.deliverFixed > 0) {
            emit CreateListingFees(listingId, listing.fees.deliverBPS, listing.fees.deliverFixed);
        }
    }

    function _intakeToken(TokenLib.Spec tokenSpec, address tokenAddress, uint256 tokenId, uint256 tokensToTransfer, address from) private {
        if (tokenSpec == TokenLib.Spec.ERC721) {
            require(tokensToTransfer == 1, "ERC721 invalid number of tokens to transfer");
            TokenLib._erc721Transfer(tokenAddress, tokenId, from, address(this));
        } else if (tokenSpec == TokenLib.Spec.ERC1155) {
            TokenLib._erc1155Transfer(tokenAddress, tokenId, tokensToTransfer, from, address(this));
        } else {
            revert("Unsupported token spec");
        }
    }

    function isAuction(ListingType type_) internal pure returns (bool) {
        return (type_ == ListingType.INDIVIDUAL_AUCTION);
    }

    function isPurchase(ListingType type_) internal pure returns (bool) {
        return (type_ == ListingType.FIXED_PRICE || type_ == ListingType.DYNAMIC_PRICE);
    }

    function isOffer(ListingType type_) internal pure returns (bool) {
        return (type_ == ListingType.OFFERS_ONLY);
    }

    function canOffer(ListingType type_, uint8 listingFlags) internal pure returns (bool) {
        // Can only make an offer if:
        // 1. Listing is an OFFERS_ONLY type
        // 2. Listing is an INDIVIDUAL_AUCTION that has offers enabled and no bids
        return (isOffer(type_) ||
            (
                isAuction(type_) &&
                (listingFlags & FLAG_MASK_ACCEPT_OFFERS) != 0 &&
                !hasBid(listingFlags)
            ));
    }

    function hasBid(uint8 listingFlags) internal pure returns (bool) {
        return listingFlags & FLAG_MASK_HAS_BID != 0;
    }

    function isFinalized(uint8 listingFlags) internal pure returns (bool) {
        return listingFlags & FLAG_MASK_FINALIZED != 0;
    }

    function sellerIsTokenCreator(uint8 listingFlags) internal pure returns (bool) {
        return listingFlags & FLAG_MASK_TOKEN_CREATOR != 0;
    }

    function modifyListing(uint40 listingId, Listing storage listing, uint256 initialAmount, uint48 startTime, uint48 endTime) public {
        require(listing.seller == msg.sender, "Permission denied");
        require(endTime > startTime, "End time must be after start time");
        require(startTime == 0 || (startTime == listing.details.startTime && endTime > block.timestamp) || startTime > block.timestamp, "Start and end time cannot occur in the past");
        require(!isFinalized(listing.flags) && (
                (!isAuction(listing.details.type_) && listing.totalSold == 0) ||
                (isAuction(listing.details.type_) && listing.bid.amount == 0)
            ), "Cannot modify listing that has already started or completed");
        require(listing.details.type_ != ListingType.DYNAMIC_PRICE || initialAmount == 0, "Invalid listing config");
        listing.details.initialAmount = initialAmount;
        listing.details.startTime = startTime;
        listing.details.endTime = endTime;

        emit ModifyListing(listingId, initialAmount, startTime, endTime);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@manifoldxyz/royalty-registry-solidity/contracts/IRoyaltyEngineV1.sol";

import "../IIdentityVerifier.sol";
import "../ILazyDelivery.sol";
import "../IPriceEngine.sol";

import "./MarketplaceLib.sol";
import "./TokenLib.sol";

/**
 * @dev Marketplace settlement logic
 */
library SettlementLib {
    using EnumerableSet for EnumerableSet.AddressSet;

    event Escrow(address indexed receiver, address erc20, uint256 amount);

    /**
     * Purchase logic
     */
    function performPurchase(address royaltyEngineV1, address payable referrer, uint40 listingId, MarketplaceLib.Listing storage listing, uint24 count, mapping(address => uint256) storage feesCollected, bytes memory data) public {
        require(MarketplaceLib.isPurchase(listing.details.type_), "Not available to purchase");
        require(listing.details.startTime <= block.timestamp, "Listing has not started");
        require(listing.details.endTime > block.timestamp || listing.details.startTime == 0, "Listing is expired");

        uint24 initialTotalSold = listing.totalSold;
        listing.totalSold += count*listing.details.totalPerSale;
        require(listing.totalSold <= listing.details.totalAvailable, "Not enough left");

        // If startTime is 0, start on first purchase
        if (listing.details.startTime == 0) {
            listing.details.startTime = uint48(block.timestamp);
            listing.details.endTime += uint48(block.timestamp);
        }

        uint256 totalPrice = _computeTotalPrice(listing, initialTotalSold, count);
        if (listing.details.erc20 == address(0)) {
          if (listing.details.type_ == MarketplaceLib.ListingType.DYNAMIC_PRICE) {
              // For dynamic price auctions, price may have changed so allow for a mismatch of funds sent
              receiveTokens(listing, msg.sender, totalPrice, true, false);
          } else {
              receiveTokens(listing, msg.sender, totalPrice, false, true);
          }
        } else {
          require(msg.value == 0, "Invalid amount");
        }
        
        // Identity verifier check
        if (listing.details.identityVerifier != address(0)) {
            require(IIdentityVerifier(listing.details.identityVerifier).verify(listingId, msg.sender, listing.token.address_, listing.token.id, count, totalPrice, listing.details.erc20, data), "Permission denied");
        }

        if (listing.token.lazy) {
            // Lazy delivered
            deliverTokenLazy(listingId, listing, msg.sender, count, totalPrice, 0);
        } else {
            // Single item
            deliverToken(listing, msg.sender, count, totalPrice, false);
        }

        // Automatically finalize listing if all sold
        if (listing.details.totalAvailable == listing.totalSold) {
            listing.flags |= MarketplaceLib.FLAG_MASK_FINALIZED;
        }

        // Pay seller
        if (listing.details.erc20 == address(0)) {
          _paySeller(royaltyEngineV1, listing, address(this), totalPrice, referrer, feesCollected);
        } else {
          _paySeller(royaltyEngineV1, listing, msg.sender, totalPrice, referrer, feesCollected);
        }
        
        emit MarketplaceLib.PurchaseEvent(listingId, referrer, msg.sender, count, totalPrice);
    }

    /**
     * Bid logic
     */
    function _preBidCheck(uint40 listingId, MarketplaceLib.Listing storage listing, uint256 bidAmount, bytes memory data) private {
        require(MarketplaceLib.isAuction(listing.details.type_), "Not available to bid");
        require(listing.details.startTime <= block.timestamp, "Listing has not started");
        require(listing.details.endTime > block.timestamp || listing.details.startTime == 0, "Listing is expired");

        // If startTime is 0, start on first purchase
        if (listing.details.startTime == 0) {
            listing.details.startTime = uint48(block.timestamp);
            listing.details.endTime += uint48(block.timestamp);
        }

        // Identity verifier check
        if (listing.details.identityVerifier != address(0)) {
            require(IIdentityVerifier(listing.details.identityVerifier).verify(listingId, msg.sender, listing.token.address_, listing.token.id, 1, bidAmount, listing.details.erc20, data), "Permission denied");
        }
    }

    function _postBidExtension(MarketplaceLib.Listing storage listing) private {
        if (listing.details.extensionInterval > 0 && listing.details.endTime <= (block.timestamp + listing.details.extensionInterval)) {
             // Extend auction time if necessary
             listing.details.endTime = uint48(block.timestamp) + listing.details.extensionInterval;
        }    
    }

    function performBid(uint40 listingId, MarketplaceLib.Listing storage listing, uint256 bidAmount, address payable referrer, bool increase, mapping(address => mapping(address => uint256)) storage escrow, bytes memory data) public {
        // Basic auction
        _preBidCheck(listingId, listing, bidAmount, data);

        address payable bidder = payable(msg.sender);
        MarketplaceLib.Bid storage currentBid = listing.bid;
        if (MarketplaceLib.hasBid(listing.flags)) {
            if (currentBid.bidder == bidder) {
                // Bidder is the current high bidder
                require(bidAmount > 0 && increase, "Existing bid");
                receiveTokens(listing, bidder, bidAmount, false, true);
                bidAmount += currentBid.amount;
            } else {
                // Bidder is not the current high bidder
                // Check minimum bid requirements
                require(bidAmount >= computeMinBid(listing.details.initialAmount, currentBid.amount, listing.details.minIncrementBPS), "Minimum bid not met");
                receiveTokens(listing, bidder, bidAmount, false, true);
                // Refund bid amount
                refundTokens(listing.details.erc20, currentBid.bidder, currentBid.amount, escrow);
            }
        } else {
            // Check minimum bid requirements
            require(bidAmount >= listing.details.initialAmount, "Invalid bid amount");
            // Set has bid flag first to prevent re-entrancy
            listing.flags |= MarketplaceLib.FLAG_MASK_HAS_BID;
            receiveTokens(listing, bidder, bidAmount, false, true);
        }
        // Update referrer if necessary
        if (currentBid.referrer != referrer && listing.referrerBPS > 0) currentBid.referrer = referrer;
        // Update bidder if necessary
        if (currentBid.bidder != bidder) currentBid.bidder = bidder;
        // Update amount
        currentBid.amount = bidAmount;
        emit MarketplaceLib.BidEvent(listingId, referrer, bidder, bidAmount);

        _postBidExtension(listing);
    }

    /**
     * Offer logic
     */
    function makeOffer(uint40 listingId, MarketplaceLib.Listing storage listing, uint256 offerAmount, address payable referrer, mapping (address => MarketplaceLib.Offer) storage offers, EnumerableSet.AddressSet storage offerAddresses, bool increase, bytes memory data) public {
        require(MarketplaceLib.canOffer(listing.details.type_, listing.flags), "Cannot make offer");
        require(offerAmount <= 0xffffffffffffffffffffffffffffffffffffffffffffffffff);
        require(listing.details.startTime <= block.timestamp, "Listing has not started");
        require(listing.details.endTime > block.timestamp || listing.details.startTime == 0, "Listing is expired");
        // Identity verifier check
        if (listing.details.identityVerifier != address(0)) {
            require(IIdentityVerifier(listing.details.identityVerifier).verify(listingId, msg.sender, listing.token.address_, listing.token.id, 1, offerAmount, listing.details.erc20, data), "Permission denied");
        }

        receiveTokens(listing, payable(msg.sender), offerAmount, false, true);
        MarketplaceLib.Offer storage currentOffer = offers[msg.sender];
        currentOffer.timestamp = uint48(block.timestamp);
        if (offerAddresses.contains(msg.sender)) {
            // Has existing offer, increase offer
            require(increase, "Existing offer");
            currentOffer.amount += uint200(offerAmount);
        } else {
            offerAddresses.add(msg.sender);
            currentOffer.amount = uint200(offerAmount);
            currentOffer.referrer = referrer;
        }
        emit MarketplaceLib.OfferEvent(listingId, referrer, msg.sender, currentOffer.amount);
    }

    function rescindOffer(uint40 listingId, MarketplaceLib.Listing storage listing, address offerAddress, mapping (address => MarketplaceLib.Offer) storage offers, EnumerableSet.AddressSet storage offerAddresses) public {
        require(offerAddresses.contains(offerAddress), "No offers found");
        MarketplaceLib.Offer storage currentOffer = offers[offerAddress];
        require(!currentOffer.accepted, "Offer already accepted");
        uint256 offerAmount = currentOffer.amount;

        // Remove offers first to prevent re-entrancy
        offerAddresses.remove(offerAddress);
        delete offers[offerAddress];

        refundTokens(listing.details.erc20, payable(offerAddress), offerAmount);

        emit MarketplaceLib.RescindOfferEvent(listingId, offerAddress, offerAmount);
    }

    /**
     * Deliver tokens
     */
    function deliverToken(MarketplaceLib.Listing storage listing, address to, uint24 count, uint256 payableAmount, bool reverse) public {
        // Check listing deliver fees if applicable
        if (payableAmount > 0 && (listing.fees.deliverBPS > 0 || listing.fees.deliverFixed > 0)) {
            uint256 deliveryFee = computeDeliverFee(listing, payableAmount);
            receiveTokens(listing, msg.sender, deliveryFee, false, true);
            // Pay out
            distributeProceeds(listing, address(this), deliveryFee);
        }
        
        if (listing.token.spec == TokenLib.Spec.ERC721) {
            require(count == 1, "Invalid amount");
            TokenLib._erc721Transfer(listing.token.address_, listing.token.id, address(this), to);
        } else if (listing.token.spec == TokenLib.Spec.ERC1155) {
            if (!reverse) {
                TokenLib._erc1155Transfer(listing.token.address_, listing.token.id, listing.details.totalPerSale*count, address(this), to);
            } else if (listing.details.totalAvailable > listing.totalSold) {
                require(count == 1, "Invalid amount");
                TokenLib._erc1155Transfer(listing.token.address_, listing.token.id, listing.details.totalAvailable-listing.totalSold, address(this), to);
            }
        } else {
            revert("Unsupported token spec");
        }
    }

    /**
     * Deliver lazy tokens
     */
    function deliverTokenLazy(uint40 listingId, MarketplaceLib.Listing storage listing, address to, uint24 count, uint256 payableAmount, uint256 index) public {
        // Check listing deliver fees if applicable
        if (payableAmount > 0 && (listing.fees.deliverBPS > 0 || listing.fees.deliverFixed > 0)) {
            // Receive tokens for fees
            uint256 deliveryFee = computeDeliverFee(listing, payableAmount);
            receiveTokens(listing, msg.sender, deliveryFee, false, true);
            // Pay out
            distributeProceeds(listing, address(this), deliveryFee);
        }

        // Call deliver (which can mint)
        ILazyDelivery(listing.token.address_).deliver(listingId, to, listing.token.id, count, payableAmount, listing.details.erc20, index);
    }


    /**
     * Distribute proceeds
     */
    function distributeProceeds(MarketplaceLib.Listing storage listing, address source, uint256 amount) public {
        if (listing.receivers.length > 0) {
            uint256 totalSent;
            uint256 receiverIndex;
            for (receiverIndex; receiverIndex < listing.receivers.length-1;) {
                uint256 receiverAmount = amount*listing.receivers[receiverIndex].receiverBPS/10000;
                sendTokens(listing.details.erc20, source, listing.receivers[receiverIndex].receiver, receiverAmount);
                totalSent += receiverAmount;
                unchecked { ++receiverIndex; }
            }
            require(totalSent < amount, "Settlement error");
            sendTokens(listing.details.erc20, source, listing.receivers[receiverIndex].receiver, amount-totalSent);
        } else {
            sendTokens(listing.details.erc20, source, listing.seller, amount);
        }
    }

    /**
     * Receive tokens.  Returns amount received.
     */
    function receiveTokens(MarketplaceLib.Listing storage listing, address source, uint256 amount, bool refundExcess, bool strict) public {
        if (source == address(this)) return;

        if (listing.details.erc20 == address(0)) {
            if (strict) {
                require(msg.value == amount, msg.value < amount ? "Insufficient funds" : "Invalid amount");
            } else {
                if (msg.value < amount) {
                   revert("Insufficient funds");
                } else if (msg.value > amount && refundExcess) {
                    // Refund excess
                   (bool success, ) = payable(source).call{value:msg.value-amount}("");
                   require(success, "Token send failure");
                }
            }
        } else {
            require(msg.value == 0, "Invalid amount");
            require(IERC20(listing.details.erc20).transferFrom(source, address(this), amount), "Insufficient funds");
        }
    }

    /**
     * Send proceeds to receiver
     */
    function sendTokens(address erc20, address source, address payable to, uint256 amount) public {
        require(source != to, "Invalid send request");

        if (erc20 == address(0)) {
            (bool success,) = to.call{value:amount}("");
            require(success, "Token send failure");
        } else {
            if (source == address(this)) {
                require(IERC20(erc20).transfer(to, amount), "Insufficient funds");
            } else {
                require(IERC20(erc20).transferFrom(source, to, amount), "Insufficient funds");
            }
        }
    }

    /**
     * Refund tokens
     */
    function refundTokens(address erc20, address payable to, uint256 amount, mapping(address => mapping(address => uint256)) storage escrow) public {
        if (erc20 == address(0)) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = to.call{value:amount, gas:20000}("");
            if (!success) {
                escrow[to][erc20] += amount;
                emit Escrow(to, erc20, amount);
            }
        } else {
            try IERC20(erc20).transfer(to, amount) {
            } catch {
                escrow[to][erc20] += amount;
                emit Escrow(to, erc20, amount);
            }
        }
    }

    function refundTokens(address erc20, address payable to, uint256 amount) public {
        if (erc20 == address(0)) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = to.call{value:amount}("");
            require(success);
        } else {
            IERC20(erc20).transfer(to, amount);
        }
    }

    /**
     * Compute deliver fee
     */
    function computeDeliverFee(MarketplaceLib.Listing memory listing, uint256 price) public pure returns(uint256) {
        return price*listing.fees.deliverBPS/10000 + listing.fees.deliverFixed;
    }

    /**
     * Compute current listing price
     */
    function computeListingPrice(MarketplaceLib.Listing storage listing) public view returns(uint256 currentPrice) {
        require(listing.details.endTime > block.timestamp || listing.details.startTime == 0 || !MarketplaceLib.isFinalized(listing.flags), "Listing is expired");
        currentPrice = listing.details.initialAmount;
        if (listing.details.type_ == MarketplaceLib.ListingType.DYNAMIC_PRICE) {
            currentPrice = IPriceEngine(listing.token.address_).price(listing.token.id, listing.totalSold, 1);
        } else {
            if (MarketplaceLib.hasBid(listing.flags)) {
                if (listing.details.type_ == MarketplaceLib.ListingType.INDIVIDUAL_AUCTION) {
                    currentPrice = computeMinBid(listing.details.initialAmount, listing.bid.amount, listing.details.minIncrementBPS);
                }
            }
        }
        return currentPrice;
    }

    /**
     * Compute total price for a <COUNT> of items to buy
     */
    function computeTotalPrice(MarketplaceLib.Listing storage listing, uint24 count) public view returns(uint256) {
        require(listing.details.endTime > block.timestamp || listing.details.startTime == 0 || !MarketplaceLib.isFinalized(listing.flags), "Listing is expired");
        return _computeTotalPrice(listing, listing.totalSold, count);
    }

    function _computeTotalPrice(MarketplaceLib.Listing storage listing, uint24 totalSold, uint24 count) private view returns(uint256) {
        if (listing.details.type_ != MarketplaceLib.ListingType.DYNAMIC_PRICE) {
            return listing.details.initialAmount*count;
        } else {
            return IPriceEngine(listing.token.address_).price(listing.token.id, totalSold, count);
        }
    }

    /**
     * Get the min bid
     */
    function computeMinBid(uint256 baseAmount, uint256 currentAmount, uint16 minIncrementBPS) pure public returns (uint256) {
        if (currentAmount == 0) {
            return baseAmount;
        }
        if (minIncrementBPS == 0) {
           return currentAmount+1;
        }
        uint256 incrementAmount = currentAmount*minIncrementBPS/10000;
        if (incrementAmount == 0) incrementAmount = 1;
        return currentAmount + incrementAmount;
    }

    /**
     * Helper to settle bid, which pays seller
     */
    function settleBid(address royaltyEngineV1, MarketplaceLib.Bid storage bid, MarketplaceLib.Listing storage listing, mapping(address => uint256) storage feesCollected) public {
        settleBid(royaltyEngineV1, bid, listing, 0, feesCollected);
    }

    function settleBid(address royaltyEngineV1, MarketplaceLib.Bid storage bid, MarketplaceLib.Listing storage listing, uint256 refundAmount, mapping(address => uint256) storage feesCollected) public {
        require(!bid.refunded, "Bid has been refunded");

        if (!bid.settled) {
            // Set to settled first to prevent re-entrancy
            bid.settled = true;
            _paySeller(royaltyEngineV1, listing, address(this), bid.amount-refundAmount, bid.referrer, feesCollected);
        }
    }

    /**
     * Refund bid
     */
    function refundBid(MarketplaceLib.Bid storage bid, MarketplaceLib.Listing storage listing, uint256 holdbackBPS, mapping(address => mapping(address => uint256)) storage escrow) public {
        require(!bid.settled, "Cannot refund, already settled");
        if (!bid.refunded) {
            // Set to refunded first to prevent re-entrancy
            bid.refunded = true;
            _refundBid(bid.bidder, bid.amount, listing, holdbackBPS, escrow);
        }
    }
    function _refundBid(address payable bidder, uint256 amount, MarketplaceLib.Listing storage listing, uint256 holdbackBPS, mapping(address => mapping(address => uint256)) storage escrow) private {
        uint256 refundAmount = amount;

        // Refund amount (less holdback)
        if (holdbackBPS > 0) {
            uint256 holdbackAmount = refundAmount*holdbackBPS/10000;
            refundAmount -= holdbackAmount;
            // Distribute holdback
            distributeProceeds(listing, address(this), holdbackAmount);
        }
        // Refund bidder
        refundTokens(listing.details.erc20, bidder, refundAmount, escrow);
    }

    /**
     * Helper to settle offer, which pays seller
     */
    function settleOffer(address royaltyEngineV1, uint40 listingId, MarketplaceLib.Listing storage listing, MarketplaceLib.Offer storage offer, address payable offerAddress, mapping(address => uint256) storage feesCollected, uint256 maxAmount, mapping(address => mapping(address => uint256)) storage escrow) public {
        require(!offer.accepted, "Already settled");

        // Set to accepted first to prevent re-entrancy
        offer.accepted = true;
        uint256 offerAmount = offer.amount;
        if (maxAmount > 0 && maxAmount < offerAmount) {
            // Refund the difference
            refundTokens(listing.details.erc20, offerAddress, offerAmount-maxAmount, escrow);
            // Set offerAmount to the max amount
            offerAmount = maxAmount;
        }
        _paySeller(royaltyEngineV1, listing, address(this), offerAmount, offer.referrer, feesCollected);
        emit MarketplaceLib.AcceptOfferEvent(listingId, msg.sender, offerAmount);
    }

    /**
     * Helper to pay seller given amount
     */
    function _paySeller(address royaltyEngineV1, MarketplaceLib.Listing storage listing, address source, uint256 amount, address payable referrer, mapping(address => uint256) storage feesCollected) private {
        uint256 sellerAmount = amount;
        if (listing.marketplaceBPS > 0) {
            uint256 marketplaceAmount = amount*listing.marketplaceBPS/10000;
            sellerAmount -= marketplaceAmount;
            receiveTokens(listing, source, marketplaceAmount, false, false);
            feesCollected[listing.details.erc20] += marketplaceAmount;
        }
        if (listing.referrerBPS > 0 && referrer != address(0)) {
            uint256 referrerAmount = amount*listing.referrerBPS/10000;
            sellerAmount -= referrerAmount;
            sendTokens(listing.details.erc20, source, referrer, referrerAmount);
        }

        if (!MarketplaceLib.sellerIsTokenCreator(listing.flags) && !listing.token.lazy) {
            // Handle royalties if not listed by token creator and not a lazy mint (lazy mints don't have royalties)
            try IRoyaltyEngineV1(royaltyEngineV1).getRoyalty(listing.token.address_, listing.token.id, amount) returns (address payable[] memory recipients, uint256[] memory amounts) {
                // Only pay royalties if properly configured
                if (recipients.length > 1 || (recipients.length == 1 && recipients[0] != listing.seller && recipients[0] != address(0))) {
                    for (uint i; i < recipients.length;) {
                        if (recipients[i] != address(0) && amounts[i] > 0) {
                            sellerAmount -= amounts[i];
                            sendTokens(listing.details.erc20, source, recipients[i], amounts[i]);
                        }
                        unchecked { ++i; }
                    }
                }
            } catch {}
        }
        distributeProceeds(listing, source, sellerAmount);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * @dev Token specs and functions
 */
library TokenLib {
    // Spec types
    enum Spec {
        NONE,
        ERC721,
        ERC1155
    }

    function _erc721Transfer(address tokenAddress, uint256 tokenId, address from, address to) internal {
        // Transfer token
        IERC721(tokenAddress).transferFrom(from, to, tokenId);
    }

    function _erc1155Transfer(address tokenAddress, uint256 tokenId, uint256 value, address from, address to) internal {
        // Transfer token
        IERC1155(tokenAddress).safeTransferFrom(from, to, tokenId, value, "");
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IIdentityVerifier is IERC165 {

    /**
     *  @dev Verify that the buyer can purchase/bid
     *
     *  @param listingId      The listingId associated with this verification
     *  @param identity       The identity to verify
     *  @param tokenAddress   The tokenAddress associated with this verification
     *  @param tokenId        The tokenId associated with this verification
     *  @param requestCount   The number of items being requested to purchase/bid
     *  @param requestAmount  The amount being requested
     *  @param requestERC20   The erc20 token address of the amount (0x0 if ETH)
     *  @param data           Additional data needed to verify
     *
     */
    function verify(uint40 listingId, address identity, address tokenAddress, uint256 tokenId, uint24 requestCount, uint256 requestAmount, address requestERC20, bytes calldata data) external returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface ILazyDelivery is IERC165 {

    /**
     *  @dev Deliver an asset and deliver to the specified party
     *  When implementing this interface, please ensure you restrict access.
     *  If using LazyDeliver.sol, you can use authorizedDelivererRequired modifier to restrict access. 
     *  Delivery can be for an existing asset or newly minted assets.
     * 
     *  @param listingId      The listingId associated with this delivery.  Useful for permissioning.
     *  @param to             The address to deliver the asset to
     *  @param assetId        The assetId to deliver
     *  @param payableCount   The number of assets to deliver
     *  @param payableAmount  The amount seller will receive upon delivery of asset
     *  @param payableERC20   The erc20 token address of the amount (0x0 if ETH)
     *  @param index          (Optional): Index value for certain sales methods
     *
     *  Suggestion: If determining a refund amount based on total sales data, do not enable this function
     *              until the sales data is finalized and recorded in contract
     *
     *  Exploit Prevention for dynamic/random assignment
     *  1. Ensure attributes are not assigned until AFTER underlying mint if using _safeMint.
     *     This is to ensure a receiver cannot check attribute values on receive and revert transaction.
     *     However, even if this is the case, the recipient can wrap its mint in a contract that checks 
     *     post mint completion and reverts if unsuccessful.
     *  2. Ensure that "to" is not a contract address. This prevents a contract from doing the lazy 
     *     mint, which could exploit random assignment by reverting if they do not receive the desired
     *     item post mint.
     */
    function deliver(uint40 listingId, address to, uint256 assetId, uint24 payableCount, uint256 payableAmount, address payableERC20, uint256 index) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IPriceEngine is IERC165 {

    /**
     *  @dev Determine price of an asset given the number
     *  already minted.
     */
    function price(uint256 assetId, uint256 alreadyMinted, uint24 count) view external returns (uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Interface for admin control
 */
interface IAdminControl is IERC165 {

    event AdminApproved(address indexed account, address indexed sender);
    event AdminRevoked(address indexed account, address indexed sender);

    /**
     * @dev gets address of all admins
     */
    function getAdmins() external view returns (address[] memory);

    /**
     * @dev add an admin.  Can only be called by contract owner.
     */
    function approveAdmin(address admin) external;

    /**
     * @dev remove an admin.  Can only be called by contract owner.
     */
    function revokeAdmin(address admin) external;

    /**
     * @dev checks whether or not given address is an admin
     * Returns True if they are
     */
    function isAdmin(address admin) external view returns (bool);

}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Lookup engine interface
 */
interface IRoyaltyEngineV1 is IERC165 {

    /**
     * Get the royalty for a given token (address, id) and value amount.  Does not cache the bps/amounts.  Caches the spec for a given token address
     * 
     * @param tokenAddress - The address of the token
     * @param tokenId      - The id of the token
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyalty(address tokenAddress, uint256 tokenId, uint256 value) external returns(address payable[] memory recipients, uint256[] memory amounts);

    /**
     * View only version of getRoyalty
     * 
     * @param tokenAddress - The address of the token
     * @param tokenId      - The id of the token
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyaltyView(address tokenAddress, uint256 tokenId, uint256 value) external view returns(address payable[] memory recipients, uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}