// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract MarketplaceV3 is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    /**
     * Variables
     */

    /// @notice Types of offer
    enum Types {
        regular,
        auction,
        offer
    }

    /// @notice Bid object
    struct Bid {
        address payable buyer;
        uint256 amount;
        bool isWinner;
        bool isChargedBack;
    }

    /// @notice Lot object
    struct Lot {
        address nft;
        address payable seller;
        uint256 tokenId;
        Types offerType;
        uint256 price;
        uint256 stopPrice;
        uint256 reservePrice;
        uint256 auctionStart;
        uint256 auctionEnd;
        bool isSold;
        bool isCanceled;
    }

    /// @notice Royalty object
    struct Royalty {
        uint256 percent;
        address receiver;
    }

    /// @dev This multiplier allows us to use the fractional part for the commission
    uint256 private constant FEES_MULTIPLIER = 10000;

    /// @notice Marketplace fee
    /// @dev 1 == 0.01%
    uint256 public serviceFee;

    /// @notice Maximal user royalty percent
    uint256 public maxRoyaltyPercent;

    /// @notice Address that will receive marketplace fees
    address payable public feesCollector;

    /// @notice ARA ERC20 token address
    address public ara;

    /// @notice RAD Pandas NFT address
    address public rad;

    /// @notice Users who are not allowed to the marketplace
    mapping(address => bool) public banList;

    /// @dev All lots IDs of the seller
    mapping(address => uint256[]) private lotsOfSeller;

    /// @notice All bids of lot
    mapping(uint256 => Bid[]) public bidsOfLot;

    /// @notice Sellers royalties
    mapping(address => mapping(uint256 => Royalty)) public royalties;

    /// @notice Array of lots
    Lot[] public lots;

    // V3

    uint256 public araAmount;

    /**
     * Events
     */

    /// @notice When service fee changed
    event ServiceFeeChanged(uint256 newFee);

    /// @notice When maximal royalty percent changed
    event MaxRoyaltyChanged(uint256 oldMaxRoyaltyPercent, uint256 newMaxRoyaltyPercent);

    /// @notice When user gets ban or unban status
    event UserBanStatusChanged(address indexed user, bool isBanned);

    /// @notice When address of ARA token changed
    event ARAAddressChanged(address indexed oldAddress, address indexed newAddress);

    /// @notice When amount of ARA token changed
    event ARAAmountChanged(uint256 oldAmount, uint256 newAmount);

    /// @notice When address of RAD Pandas token changed
    event RADAddressChanged(address indexed oldAddress, address indexed newAddress);

    /// @notice When new regular lot created
    event RegularLotCreated(uint256 indexed lotId, address indexed seller);

    /// @notice When new auction lot created
    event AuctionLotCreated(uint256 indexed lotId, address indexed seller);

    /// @notice When existing auction lot renewed
    event AuctionLotRenewed(uint256 indexed lotId, address indexed seller);

    /// @notice When new offer lot created
    event OfferLotCreated(uint256 indexed lotId, address indexed seller);

    /// @notice When lot removed
    event TokenRemovedFromSale(uint256 indexed lotId, bool indexed removedBySeller);

    /// @notice When lot sold
    event Sold(uint256 indexed lotId, address indexed buyer, uint256 price, uint256 fee, uint256 royalty);

    /// @notice When something was wrong with transaction
    event FailedTx(uint256 indexed lotId, uint256 bidId, address indexed recipient, uint256 amount);

    /// @notice When recover ethers after FailedTx event
    event EthersRecovered(uint256 amount);

    /// @notice When recovering NFT
    event NFTRecovered(address nft, uint256 tokenId);

    /// @notice When royalty set
    event RoyaltySet(address indexed nft, uint256 indexed tokenId, address receiver, uint256 percent);

    /// @notice When price offer created
    event NewOffer(address indexed buyer, uint256 price, uint256 indexed lotId);

    /// @notice When offer accepted by the seller
    event OfferAccepted(uint256 indexed lotId);

    /**
     * Modifiers
     */

    /**
     * @notice Checks that the user is not banned
     */
    modifier notBanned() {
        require(!banList[msg.sender], "you are banned");
        _;
    }

    /**
     * @notice Checks that the lot has not been sold or canceled
     * @param lotId - ID of the lot
     */
    modifier lotIsActive(uint256 lotId) {
        Lot memory lot = lots[lotId];
        require(!lot.isSold, "lot already sold");
        require(!lot.isCanceled, "lot canceled");
        _;
    }

    /**
     * Getters
     */

    /**
     * @notice Get filtered lots
     * @param from - Minimal lotId
     * @param to - Get to lot Id. 0 ar any value greater than lots.length will set "to" to lots.length
     * @param getActive - Is get active lots?
     * @param getSold - Is get sold lots?
     * @param getCanceled - Is get canceled lots?
     * @return _filteredLots - Array of filtered lots
     */
    function getLots(
        uint256 from,
        uint256 to,
        bool getActive,
        bool getSold,
        bool getCanceled
    ) external view returns (Lot[] memory _filteredLots) {
        require(from < lots.length, "value is bigger than lots count");
        if (to == 0 || to >= lots.length) to = lots.length - 1;
        Lot[] memory _tempLots = new Lot[](lots.length);
        uint256 _count = 0;
        for (uint256 i = from; i <= to; i++) {
            if (
                (getActive && (!lots[i].isSold && !lots[i].isCanceled)) ||
                (getSold && lots[i].isSold) ||
                (getCanceled && lots[i].isCanceled)
            ) {
                _tempLots[_count] = lots[i];
                _count++;
            }
        }
        _filteredLots = new Lot[](_count);
        for (uint256 i = 0; i < _count; i++) {
            _filteredLots[i] = _tempLots[i];
        }
    }

    /**
     * @notice Get all lots of the seller
     * @param seller - Address of seller
     * @return array of lot IDs
     */
    function getLotsOfSeller(address seller) external view returns (uint256[] memory) {
        return lotsOfSeller[seller];
    }

    /**
     * @notice Get all bids of the lot
     * @param lotId - ID of lot
     * @return array of lot IDs
     */
    function getBidsOfLot(uint256 lotId) external view returns (Bid[] memory) {
        return bidsOfLot[lotId];
    }

    /**
     * @notice Get lot by ERC721 address and token ID
     * @param nft - Address of ERC721 token
     * @param tokenId - ID of the token
     * @return _isFound - Is found or not
     * @return _lotId - ID of the lot
     */
    function getLotId(address nft, uint256 tokenId) external view returns (bool _isFound, uint256 _lotId) {
        require(nft != address(0), "zero_addr");
        _isFound = false;
        _lotId = 0;
        for (uint256 i; i < lots.length; i++) {
            Lot memory _lot = lots[i];
            if (_lot.nft == nft && _lot.tokenId == tokenId && !_lot.isCanceled && !_lot.isSold) {
                _isFound = true;
                _lotId = i;
                break;
            }
        }
    }

    /**
     * @notice Get bids of the user by lot Id
     * @param bidder - User's address
     * @param lotId - ID of lot
     * @return _bid - Return bid
     */
    function getBidsOf(address bidder, uint256 lotId) external view returns (Bid memory _bid) {
        for (uint256 i = 0; i < bidsOfLot[lotId].length; i++) {
            _bid = bidsOfLot[lotId][i];
            if (_bid.buyer == bidder && !_bid.isChargedBack) {
                return _bid;
            }
        }
        revert("bid not found");
    }

    /**
     * Setters
     */

    /**
     * @notice Change marketplace fee
     * @param newServiceFee - New fee amount
     */
    function setServiceFee(uint256 newServiceFee) external onlyOwner {
        require(serviceFee != newServiceFee, "same amount");
        serviceFee = newServiceFee;
        emit ServiceFeeChanged(newServiceFee);
    }

    /**
     * @notice Change user's ban status
     * @param user - Address of account
     * @param isBanned - Status of account
     */
    function setBanStatus(address user, bool isBanned) external onlyOwner {
        require(banList[user] != isBanned, "address already have this status");
        banList[user] = isBanned;
        emit UserBanStatusChanged(user, isBanned);
    }

    /**
     * @notice Change ARA token address
     * @param _ara - New address of the ARA ERC20 token
     */
    function setARAAddress(address _ara) external onlyOwner {
        require(_ara != address(0), "zero address");
        require(_ara != ara, "same address");
        address _oldARA = ara;
        ara = _ara;
        emit ARAAddressChanged(_oldARA, ara);
    }

    /**
     * @notice Set ARA amount for a 0 fee
     * @param _araAmount - New address of the ARA ERC20 token
     */
    function setARAAmount(uint256 _araAmount) external onlyOwner {
        require(_araAmount != araAmount, "same amount");
        uint256 _oldAmount = araAmount;
        araAmount = _araAmount;
        emit ARAAmountChanged(_oldAmount, araAmount);
    }

    /**
     * @notice Change RAD Pandas token address
     * @param _rad - New address of the RAD NFT
     */
    function setRADAddress(address _rad) external onlyOwner {
        require(_rad != address(0), "zero address");
        require(_rad != rad, "same address");
        address _oldRAD = rad;
        rad = _rad;
        emit RADAddressChanged(_oldRAD, _rad);
    }

    /**
     * @notice Set maximal royalty percent
     * @param _newMaxRoyaltyPercent - New maximal royalty percent
     */
    function setMaxRoyalty(uint256 _newMaxRoyaltyPercent) external onlyOwner {
        require(maxRoyaltyPercent != _newMaxRoyaltyPercent, "same amount");
        uint256 _oldMaxRoyaltyPercent = maxRoyaltyPercent;
        maxRoyaltyPercent = _newMaxRoyaltyPercent;
        emit MaxRoyaltyChanged(_oldMaxRoyaltyPercent, _newMaxRoyaltyPercent);
    }

    /**
     * @notice Set royalty
     * @dev Can be set only ones
     * @param nftToken - Address of NFT token
     * @param tokenId - ID of NFT token
     * @param royaltyPercent - Royalty (1% == 100)
     */
    function setRoyalty(
        address nftToken,
        uint256 tokenId,
        uint256 royaltyPercent
    ) external {
        require(royaltyPercent <= maxRoyaltyPercent, "% is bigger than maxRoyaltyPercent");
        Royalty storage _royalty = royalties[nftToken][tokenId];
        require(_royalty.percent == 0, "Royalty % already set");
        require(_royalty.receiver == address(0), "Royalty address already set");
        address _tokenOwner = IERC721Upgradeable(nftToken).ownerOf(tokenId);
        require(msg.sender == _tokenOwner, "not owner");
        _royalty.percent = royaltyPercent;
        _royalty.receiver = msg.sender;
        emit RoyaltySet(nftToken, tokenId, msg.sender, royaltyPercent);
    }

    /**
     * Marketplace logic
     */

    /**
     * @notice Regular offer (not auction)
     * @param nft - Address of NFT contract
     * @param tokenId - ID of token to sale
     * @param price - Token price
     * @return _lotId - Lot ID
     */
    function makeRegularOffer(
        address nft,
        uint256 tokenId,
        uint256 price
    ) external notBanned returns (uint256 _lotId) {
        require(nft != address(0), "zero address for NFT");
        require(price > 0, "price should be greater than 0");
        IERC721Upgradeable(nft).safeTransferFrom(msg.sender, address(this), tokenId);
        Lot memory newLot = Lot(nft, payable(msg.sender), tokenId, Types.regular, price, 0, 0, 0, 0, false, false);
        lots.push(newLot);
        _lotId = lots.length - 1;
        lotsOfSeller[msg.sender].push(_lotId);
        emit RegularLotCreated(_lotId, msg.sender);
    }

    /**
     * @notice Regular offer (not auction)
     * @param nft - Address of NFT contract
     * @param tokenId - ID of token to sale
     * @param price - Token price
     * @param stopPrice - Price to stop auction and sale immediately
     * @param reservePrice - Minimal token price that should to be reached
     * @param auctionStart - Auction starts at
     * @param auctionEnd - Auction finish at
     * @return _lotId - Lot ID
     */
    function makeAuctionOffer(
        address nft,
        uint256 tokenId,
        uint256 price,
        uint256 stopPrice,
        uint256 reservePrice,
        uint256 auctionStart,
        uint256 auctionEnd
    ) external notBanned returns (uint256 _lotId) {
        require(nft != address(0), "zero address");
        require(auctionStart > 0, "auction start time should be greater than 0");
        require(auctionEnd > auctionStart, "auction end time should be greater than auction start time");
        require(price > 0, "price should be greater than 0");
        if (stopPrice > 0) {
            require(stopPrice > price, "stop price should be greater than price");
        }
        if (reservePrice > 0) {
            require(reservePrice > price, "reserve price should be greater than price");
        }
        IERC721Upgradeable(nft).safeTransferFrom(msg.sender, address(this), tokenId);
        Lot memory newLot = Lot(
            nft,
            payable(msg.sender),
            tokenId,
            Types.auction,
            price,
            stopPrice,
            reservePrice,
            auctionStart,
            auctionEnd,
            false,
            false
        );
        lots.push(newLot);
        _lotId = lots.length - 1;
        lotsOfSeller[msg.sender].push(_lotId);
        emit AuctionLotCreated(_lotId, msg.sender);
    }

    /**
     * @notice Add token to receive price offers
     * @param nft - Address of NFT contract
     * @param tokenId - ID of token to sale
     * @return _lotId - Lot ID
     */
    function addTokenForOffers(address nft, uint256 tokenId) external notBanned returns (uint256 _lotId) {
        require(nft != address(0), "zero address for NFT");
        IERC721Upgradeable(nft).safeTransferFrom(msg.sender, address(this), tokenId);
        Lot memory newLot = Lot(nft, payable(msg.sender), tokenId, Types.offer, 0, 0, 0, 0, 0, false, false);
        lots.push(newLot);
        _lotId = lots.length - 1;
        lotsOfSeller[msg.sender].push(_lotId);
        emit OfferLotCreated(_lotId, msg.sender);
    }

    /**
     * @notice Remove lot from sale and return users funds
     * @dev Only lot owner or contract owner can do this
     * @param lotId - ID of the lot
     */
    function removeLot(uint256 lotId) external lotIsActive(lotId) nonReentrant {
        Lot storage lot = lots[lotId];
        require(msg.sender == lot.seller || msg.sender == owner(), "only owner or seller can remove");
        lot.isCanceled = true;
        if (lot.offerType != Types.regular) {
            // send funds to bidders
            Bid[] storage bids = bidsOfLot[lotId];
            for (uint256 i = 0; i < bids.length; i++) {
                Bid storage _bid = bids[i];
                if (!_bid.isChargedBack && !_bid.isWinner) {
                    _bid.isChargedBack = true;
                    (bool sent, ) = _bid.buyer.call{value: _bid.amount}("");
                    require(sent, "something went wrong");
                }
            }
        }
        // send NFT back to the seller
        IERC721Upgradeable(lot.nft).safeTransferFrom(address(this), lot.seller, lot.tokenId);
        emit TokenRemovedFromSale(lotId, msg.sender == lot.seller);
    }

    /**
     * @notice Update price for a regular offer
     * @param lotId - ID of the lot
     * @param newPrice - New price of the lot
     */
    function changeRegularOfferPrice(uint256 lotId, uint256 newPrice) external lotIsActive(lotId) {
        Lot storage _lot = lots[lotId];
        require(msg.sender == _lot.seller, "not seller");
        require(_lot.offerType == Types.regular, "only regular offer");
        require(_lot.price != newPrice, "same");
        _lot.price = newPrice;
    }

    /**
     * @notice Make offer to lot
     * @param lotId - ID of the lot
     */
    function makeOffer(uint256 lotId) external payable notBanned lotIsActive(lotId) nonReentrant {
        Lot storage lot = lots[lotId];
        require(lot.offerType == Types.offer, "only offer lot type");
        Bid[] storage _bids = bidsOfLot[lotId];
        if (_bids.length > 0) {
            (bool _hasActiveBid, uint256 _activeBidId) = _getLastActiveBid(lotId);
            if (_hasActiveBid) {
                Bid storage _lastBid = _bids[_activeBidId];
                require(msg.value > _lastBid.amount);
                _lastBid.isChargedBack = true;
                (bool isTransfered, ) = _lastBid.buyer.call{value: _lastBid.amount}("");
                require(isTransfered, "payment error");
            }
        }
        Bid memory _newBid = Bid(payable(msg.sender), msg.value, false, false);
        (bool isOk, ) = payable(address(this)).call{value: msg.value}("");
        require(isOk, "payment error");
        _bids.push(_newBid);
        emit NewOffer(msg.sender, msg.value, lotId);
    }

    /**
     * @notice Make offer to lot
     * @param lotId - ID of the lot
     */
    function acceptOffer(uint256 lotId) external payable notBanned lotIsActive(lotId) nonReentrant {
        Lot storage lot = lots[lotId];
        require(lot.seller == msg.sender, "seller only");
        require(lot.offerType == Types.offer, "only offer lot type");
        Bid[] storage _bids = bidsOfLot[lotId];
        require(_bids.length > 0, "no bids");
        (bool _hasActiveBid, uint256 _activeBidId) = _getLastActiveBid(lotId);
        require(_hasActiveBid, "no active bids");
        Bid storage _winner = _bids[_activeBidId];
        _winner.isWinner = true;
        _buy(lot, _winner.amount, lotId, _winner.buyer);
        emit OfferAccepted(lotId);
    }

    /**
     * @notice Buy regular lot (not auction)
     * @param lotId - ID of the lot
     */
    function buy(uint256 lotId) external payable notBanned lotIsActive(lotId) nonReentrant {
        Lot storage lot = lots[lotId];
        require(lot.offerType == Types.regular, "only regular lot type");
        require(msg.value == lot.price, "wrong ether amount");
        _buy(lot, lot.price, lotId, msg.sender);
    }

    /**
     * @notice Make auction bid
     * @param lotId - ID of the lot
     */
    function bid(uint256 lotId) external payable notBanned lotIsActive(lotId) nonReentrant {
        Lot storage lot = lots[lotId];
        require(lot.offerType == Types.auction, "only auction lot type");
        require(lot.auctionStart <= block.timestamp, "auction is not started yet");
        require(lot.auctionEnd >= block.timestamp, "auction already finished");
        Bid[] storage bids = bidsOfLot[lotId];
        uint256 bidAmount = msg.value;
        for (uint256 i = 0; i < bids.length; i++) {
            if (bids[i].buyer == msg.sender && !bids[i].isChargedBack) {
                bidAmount += bids[i].amount;
            }
        }
        if (lot.stopPrice != 0) {
            require(bidAmount <= lot.stopPrice, "amount should be less or equal to stop price");
        }
        require(bidAmount >= lot.price, "amount should be great or equal to lot price");
        if (bids.length > 0) {
            require(bids[bids.length - 1].amount < bidAmount, "bid should be greater than last");
        }
        // Pay
        (bool fundsInMarketplace, ) = payable(address(this)).call{value: msg.value}("");
        require(fundsInMarketplace, "payment error (bidder)");
        Bid memory newBid = Bid(payable(msg.sender), bidAmount, false, false);
        // Do not send funds to previous bids, because this amount in last bid
        for (uint256 i = 0; i < bids.length; i++) {
            if (bids[i].buyer == msg.sender && !bids[i].isChargedBack) {
                bids[i].isChargedBack = true;
            }
        }
        bids.push(newBid);
        // finalize when target price reached
        if (lot.stopPrice != 0 && bidAmount == lot.stopPrice) {
            lot.auctionEnd = block.timestamp - 1;
            _finalize(lotId);
        }
    }

    /**
     * @notice Finalize auction (external function)
     * @param lotId - ID of the lot
     */
    function finalize(uint256 lotId) external notBanned lotIsActive(lotId) nonReentrant {
        _finalize(lotId);
    }

    /**
     * @notice Renew auction
     * @param lotId - ID of the lot
     * @param price - Token price
     * @param stopPrice - Price to stop auction and sale immediately
     * @param auctionStart - Auction starts at
     * @param auctionEnd - Auction finish at
     */
    function renew(
        uint256 lotId,
        uint256 price,
        uint256 stopPrice,
        uint256 reservePrice,
        uint256 auctionStart,
        uint256 auctionEnd
    ) external lotIsActive(lotId) notBanned {
        require(price > 0, "price should be greater than 0");
        if (stopPrice > 0) {
            require(stopPrice > price, "stop price should be greater than price");
        }
        if (reservePrice > 0) {
            require(reservePrice > price, "reserve price should be greater than price");
        }
        Lot storage _lot = lots[lotId];
        require(msg.sender == _lot.seller, "restricted");
        require(_lot.auctionEnd < block.timestamp, "not ended");
        require(auctionStart > _lot.auctionEnd, "auction start time should be greater than previous auctionEnd");
        require(auctionEnd > auctionStart, "auction end time should be greater than auction start time");
        Bid[] storage _bids = bidsOfLot[lotId];
        require(_bids.length == 0, "have bids");
        _lot.auctionStart = auctionStart;
        _lot.auctionEnd = auctionEnd;
        _lot.price = price;
        _lot.stopPrice = stopPrice;
        _lot.reservePrice = reservePrice;
        emit AuctionLotRenewed(lotId, _lot.seller);
    }

    /**
     * Private functions
     */

    /**
     * @dev Get last offer bid
     * @param _lotId - ID of the lot
     * @return _isOk - Bid found
     * @return _bidId - Id of the lot bid
     */
    function _getLastActiveBid(uint256 _lotId) internal view returns (bool _isOk, uint256 _bidId) {
        _isOk = false;
        _bidId = 0;
        Bid[] memory _bids = bidsOfLot[_lotId];
        if (_bids.length > 0) {
            for (uint256 _i = _bids.length - 1; _i >= 0; _i--) {
                if (!_bids[_i].isChargedBack) {
                    _isOk = true;
                    _bidId = _i;
                    break;
                }
            }
        }
    }

    /**
     * @dev Send funds and token
     * @param lot - Lot to buy
     * @param price - Lot price
     * @param lotId - ID of the lot
     */
    function _buy(
        Lot storage lot,
        uint256 price,
        uint256 lotId,
        address buyer
    ) internal {
        uint256 _fee = (price * serviceFee) / FEES_MULTIPLIER;
        uint256 _royaltyPercent = 0;
        bool _payRoyalty = IERC20Upgradeable(ara).balanceOf(lot.seller) < araAmount;
        if (_payRoyalty) {
            _payRoyalty = IERC721Upgradeable(rad).balanceOf(lot.seller) < 1;
        }
        if (_payRoyalty) {
            Royalty memory _royalty = royalties[lot.nft][lot.tokenId];
            if (_royalty.percent > 0) {
                _royaltyPercent = (price * _royalty.percent) / FEES_MULTIPLIER;
                (bool payedRoyalty, ) = payable(_royalty.receiver).call{value: _royaltyPercent}("");
                require(payedRoyalty, "payment error (royalty)");
            }
        }
        (bool payedToSeller, ) = lot.seller.call{value: price - _fee - _royaltyPercent}("");
        require(payedToSeller, "payment error (seller)");
        (bool payedToFeesCollector, ) = feesCollector.call{value: _fee}("");
        require(payedToFeesCollector, "payment error (fees collector)");
        lot.isSold = true;
        IERC721Upgradeable(lot.nft).safeTransferFrom(address(this), buyer, lot.tokenId);
        emit Sold(lotId, msg.sender, price, _fee, _royaltyPercent);
    }

    /**
     * @dev Handle winner bid
     * @param bids - Bids of lot
     * @param lot - Current lot
     * @param lotId - ID of the lot
     * @param winnerId - Winner bid ID
     */
    function _bidWins(Bid[] storage bids, Lot storage lot, uint256 lotId, uint256 winnerId) internal {
        bids[winnerId].isWinner = true;
        _buy(lot, bids[winnerId].amount, lotId, bids[winnerId].buyer);
    }

    /**
     * @dev Handle non winning lot
     * @param lot - Current lot
     */
    function _cancelLot(Lot storage lot) internal {
        lot.isCanceled = true;
        IERC721Upgradeable(lot.nft).safeTransferFrom(address(this), lot.seller, lot.tokenId);
    }

    /**
     * @dev Finalize auction (internal function)
     * @param lotId - ID of the lot
     */
    function _finalize(uint256 lotId) internal {
        Lot storage lot = lots[lotId];
        require(lot.auctionEnd < block.timestamp, "auction is not finished yet");
        Bid[] storage bids = bidsOfLot[lotId];
        if (bids.length > 0) {
            uint256 winnerId;
            if (bids.length == 1) {
                winnerId = 0;
            } else {
                winnerId = bids.length - 1;
                // Return funds to losers
                for (uint256 i = 0; i < bids.length - 1; i++) {
                    Bid storage _bid = bids[i];
                    if (!_bid.isChargedBack) {
                        _bid.isChargedBack = true;
                        (bool success, ) = _bid.buyer.call{value: _bid.amount}("");
                        if (!success) {
                            emit FailedTx(lotId, i, _bid.buyer, _bid.amount);
                        }
                    }
                }
            }
            if (lot.reservePrice > 0) {
                if (lot.reservePrice <= bids[winnerId].amount) {
                    _bidWins(bids, lot, lotId, winnerId);
                } else {
                    _cancelLot(lot);
                    Bid storage _bid = bids[winnerId];
                    _bid.isChargedBack = true;
                    (bool success, ) = _bid.buyer.call{value: _bid.amount}("");
                    require(success, "tx failed");
                }
            } else {
                _bidWins(bids, lot, lotId, winnerId);
            }
        } else {
            _cancelLot(lot);
        }
    }

    /**
     * Other
     */

    /// @notice Acts like constructor() for upgradeable contracts
    function initialize(address _ara, address _rad) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        feesCollector = payable(msg.sender);
        serviceFee = 0;
        maxRoyaltyPercent = 1000; // 10%
        araAmount = 50000e18;
        ara = _ara;
        rad = _rad;
    }

    /**
     * @notice In case if user send his NFT token directly to this contract
     * @param _nft - NFT address
     * @param _tokenId - ID of token
     */
    function recoverNFT(address _nft, uint256 _tokenId) external onlyOwner {
        IERC721Upgradeable(_nft).safeTransferFrom(address(this), msg.sender, _tokenId);
        emit NFTRecovered(_nft, _tokenId);
    }

    /// @notice To make ERC721 safeTransferFrom works
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    /// @notice Allow this contract to receive ether
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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