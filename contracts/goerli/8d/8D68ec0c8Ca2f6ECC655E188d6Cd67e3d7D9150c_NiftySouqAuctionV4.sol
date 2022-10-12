// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;
pragma abicoder v2;

import "./interface/NiftySouq-IMarketplaceManager.sol";
import "./interface/NiftySouq-IMarketplace.sol";
import "./interface/NiftySouq-IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

struct Bid {
    address bidder;
    uint256 price;
    uint256 bidAt;
    bool canceled;
}

struct Auction {
    uint256 tokenId;
    address tokenContract;
    uint256 startTime;
    uint256 endTime;
    address seller;
    uint256 startBidPrice;
    uint256 reservePrice;
    uint256 highestBidIdx;
    uint256 selectedBid;
    Bid[] bids;
}

struct CreateAuction {
    uint256 offerId;
    uint256 tokenId;
    address tokenContract;
    uint256 startTime;
    uint256 duration;
    address seller;
    uint256 startBidPrice;
    uint256 reservePrice;
}

struct CreateAuctionData {
    uint256 tokenId;
    address tokenContract;
    uint256 duration;
    uint256 startBidPrice;
    uint256 reservePrice;
}

struct MintAndCreateAuctionData {
    address tokenAddress;
    string uri;
    address[] creators;
    uint256[] royalties;
    address[] investors;
    uint256[] revenues;
    uint256 duration;
    uint256 startBidPrice;
    uint256 reservePrice;
}

struct Payout {
    address currency;
    address[] refundAddresses;
    uint256[] refundAmounts;
}

contract NiftySouqAuctionV4 is Initializable {
    using SafeMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public constant PERCENT_UNIT = 1e4;
    uint256 public bidIncreasePercentage;

    address private _marketplace;
    NiftySouqIMarketplaceManager private _marketplaceManager;

    mapping(uint256 => Auction) private _auction;

    uint256 public extendAuctionPeriod;

    event eCreateAuction(
        uint256 offerId,
        uint256 tokenId,
        address contractAddress,
        address owner,
        uint256 startTime,
        uint256 duration,
        uint256 startBidPrice,
        uint256 reservePrice
    );
    event eCancelAuction(uint256 offerId);
    event eEndAuction(
        uint256 offerId,
        uint256 BidIdx,
        address buyer,
        address currency,
        uint256 price
    );
    event ePlaceBid(
        uint256 offerId,
        uint256 BidIdx,
        address bidder,
        uint256 bidAmount
    );
    event ePlaceHigherBid(
        uint256 offerId,
        uint256 BidIdx,
        address bidder,
        uint256 bidAmount
    );
    event eCancelBid(uint256 offerId, uint256 bidIdx);

    event ePayoutTransfer(
        address indexed withdrawer,
        uint256 indexed amount,
        address indexed currency
    );
    modifier isNiftyMarketplace() {
        require(
            msg.sender == _marketplace,
            "Nifty721: unauthorized. not niftysouq marketplace"
        );
        _;
    }

    function initialize(
        address marketplace_,
        address marketplaceManager_,
        uint256 bidIncreasePercentage_
    ) public initializer {
        _marketplace = marketplace_;
        _marketplaceManager = NiftySouqIMarketplaceManager(marketplaceManager_);
        bidIncreasePercentage = bidIncreasePercentage_;
    }

    function setExtendAuctionPeriod(uint256 extendAuctionPeriod_) external {
        extendAuctionPeriod = extendAuctionPeriod_;
    }

    function _createAuction(CreateAuction memory createAuctionData_) internal {
        _auction[createAuctionData_.offerId].tokenId = createAuctionData_
            .tokenId;
        _auction[createAuctionData_.offerId].tokenContract = createAuctionData_
            .tokenContract;
        _auction[createAuctionData_.offerId].startTime = createAuctionData_
            .startTime;
        _auction[createAuctionData_.offerId].endTime = createAuctionData_
            .startTime
            .add(createAuctionData_.duration);
        _auction[createAuctionData_.offerId].seller = createAuctionData_.seller;
        _auction[createAuctionData_.offerId].startBidPrice = createAuctionData_
            .startBidPrice;
        _auction[createAuctionData_.offerId].reservePrice = createAuctionData_
            .reservePrice;
    }

    function _cancelAuction(uint256 offerId)
        internal
        returns (
            address[] memory refundAddresses_,
            uint256[] memory refundAmount_
        )
    {
        refundAddresses_ = new address[](_auction[offerId].bids.length);
        refundAmount_ = new uint256[](_auction[offerId].bids.length);
        uint256 j = 0;
        for (uint256 i = 0; i < _auction[offerId].bids.length; i++) {
            Bid storage bid = _auction[offerId].bids[i];
            if (!bid.canceled) {
                refundAddresses_[j] = bid.bidder;
                refundAmount_[j] = bid.price;
                j = j.add(1);
                _auction[offerId].bids[i].canceled = true;
            }
        }
    }

    function _placeBid(
        uint256 offerId,
        address bidder,
        uint256 bidPrice
    ) internal returns (uint256 bidIdx_) {
        require(_auction[offerId].seller != bidder, "seller can not bid");
        require(
            _auction[offerId].endTime > block.timestamp,
            "Auction duration completed"
        );
        uint256 highestBidPrice = _auction[offerId].startBidPrice;

        if (_auction[offerId].bids.length > 0) {
            Bid storage highestBid = _auction[offerId].bids[
                _auction[offerId].highestBidIdx
            ];
            require(highestBid.bidder != bidder, "already bid");

            highestBidPrice = highestBid
                .price
                .mul(PERCENT_UNIT + bidIncreasePercentage)
                .div(PERCENT_UNIT);

            require(highestBidPrice > highestBid.price, "not enough bid");
        }

        require(bidPrice >= highestBidPrice, "not enough bid");

        _auction[offerId].bids.push(
            Bid({
                bidder: bidder,
                price: bidPrice,
                bidAt: block.timestamp,
                canceled: false
            })
        );

        _auction[offerId].highestBidIdx = _auction[offerId].bids.length - 1;
        bidIdx_ = _auction[offerId].highestBidIdx;
    }

    function _placeHigherBid(
        uint256 offerId,
        address bidder,
        uint256 bidIdx,
        uint256 bidPrice
    ) internal returns (uint256 currentBidPrice_) {
        require(bidIdx < _auction[offerId].bids.length, "invalid bid");
        require(
            bidder == _auction[offerId].bids[bidIdx].bidder,
            "not the bidder"
        );
        require(
            _auction[offerId].endTime > block.timestamp,
            "Auction duration completed"
        );

        Bid storage bid = _auction[offerId].bids[bidIdx];
        Bid storage highestBid = _auction[offerId].bids[
            _auction[offerId].highestBidIdx
        ];

        uint256 requiredMinBidPrice = highestBid
            .price
            .mul(PERCENT_UNIT + bidIncreasePercentage)
            .div(PERCENT_UNIT);

        require(
            bidPrice.add(bid.price) > requiredMinBidPrice,
            "not enough bid"
        );

        _auction[offerId].bids[bidIdx].price = bidPrice.add(bid.price);

        _auction[offerId].highestBidIdx = bidIdx;
        currentBidPrice_ = _auction[offerId].bids[bidIdx].price;
    }

    function _cancelBid(
        uint256 offerId,
        address bidder,
        uint256 bidIdx
    )
        internal
        returns (
            address[] memory refundAddresses_,
            uint256[] memory refundAmount_
        )
    {
        require(bidIdx < _auction[offerId].bids.length, "invalid bid");
        require(
            bidder == _auction[offerId].bids[bidIdx].bidder,
            "not a bidder"
        );
        refundAddresses_ = new address[](1);
        refundAmount_ = new uint256[](1);
        _auction[offerId].bids[bidIdx].canceled = true;
        refundAddresses_[0] = _auction[offerId].bids[bidIdx].bidder;
        refundAmount_[0] = _auction[offerId].bids[bidIdx].price;

        // update highest bidder
        if (_auction[offerId].highestBidIdx == bidIdx) {
            uint256 idx = 0;
            for (uint256 i = 0; i < _auction[offerId].bids.length; i++) {
                if (
                    !_auction[offerId].bids[i].canceled &&
                    _auction[offerId].bids[i].price >
                    _auction[offerId].bids[uint256(idx)].price
                ) {
                    idx = i;
                }
            }
            _auction[offerId].highestBidIdx = idx;
        }
    }

    function _endAuction(
        uint256 offerId_,
        // address creator,
        uint256 bidIdx
    )
        internal
        returns (
            uint256 bidAmount_,
            address[] memory recipientAddresses_,
            uint256[] memory paymentAmount_
        )
    {
        // require(creator == _auction[offerId_].seller, "not seller");
        require(bidIdx < _auction[offerId_].bids.length, "invalid bid");
        require(
            _auction[offerId_].bids[bidIdx].canceled == false,
            "bid already canceled"
        );
        require(
            _auction[offerId_].endTime < block.timestamp,
            "Auction duration not completed"
        );
        if (
            _auction[offerId_].highestBidIdx == 0 &&
            _auction[offerId_].bids[0].canceled == false
        ) return (0, new address[](0), new uint256[](0));
        uint256 offerId = offerId_;
        uint256 j = 0;

        (
            address[] memory recipientAddresses,
            uint256[] memory paymentAmount,
            ,

        ) = _marketplaceManager.calculatePayout(
                CalculatePayout(
                    _auction[offerId_].tokenId,
                    _auction[offerId_].tokenContract,
                    _auction[offerId_].seller,
                    _auction[offerId].bids[bidIdx].price,
                    1
                )
            );
        recipientAddresses_ = new address[](
            (_auction[offerId].bids.length).add(recipientAddresses.length)
        );
        paymentAmount_ = new uint256[](
            (_auction[offerId].bids.length).add(paymentAmount.length)
        );

        for (uint256 i = 0; i < recipientAddresses.length; i++) {
            recipientAddresses_[j] = recipientAddresses[i];
            if (i == recipientAddresses.length.sub(1))
                paymentAmount_[j] = paymentAmount[i].sub(
                    paymentAmount[i.sub(1)]
                );
            else paymentAmount_[j] = paymentAmount[i];
            j = j.add(1);
        }

        // refund
        {
            for (uint256 i = 0; i < _auction[offerId].bids.length; i++) {
                Bid storage bid = _auction[offerId].bids[i];
                if (i != bidIdx && !bid.canceled) {
                    recipientAddresses_[j] = bid.bidder;
                    paymentAmount_[j] = bid.price;
                    j = j.add(1);
                    _auction[offerId].bids[i].canceled = true;
                }
            }
        }

        bidAmount_ = _auction[offerId_].bids[bidIdx].price;
    }

    function _endAuctionWithHighestBid(uint256 offerId_, address caller_)
        internal
        returns (
            uint256 bidIdx_,
            uint256 bidAmount_,
            address[] memory recipientAddresses_,
            uint256[] memory paymentAmount_
        )
    {
        bidIdx_ = _auction[offerId_].highestBidIdx;
        require(
            (caller_ == _auction[offerId_].seller) ||
                (_marketplaceManager.isAdmin(caller_)),
            "NiftyMarketplace: not seller or niftysouq admin."
        );
        (bidAmount_, recipientAddresses_, paymentAmount_) = _endAuction(
            offerId_,
            // creator_,
            bidIdx_
        );
    }

    function getAuctionDetails(uint256 offerId_)
        public
        view
        returns (Auction memory auction_)
    {
        auction_ = _auction[offerId_];
    }

    function _calculatePayout(
        uint256 price_,
        uint256 serviceFeePercent_,
        uint256[] memory payouts_
    )
        internal
        view
        virtual
        returns (
            uint256 serviceFee_,
            uint256[] memory payoutFees_,
            uint256 netFee_
        )
    {
        payoutFees_ = new uint256[](payouts_.length);
        uint256 payoutSum = 0;
        serviceFee_ = percent(price_, serviceFeePercent_);

        for (uint256 i = 0; i < payouts_.length; i++) {
            uint256 royalFee = percent(price_, payouts_[i]);
            payoutFees_[i] = royalFee;
            payoutSum = payoutSum.add(royalFee);
        }

        netFee_ = price_.sub(serviceFee_).sub(payoutSum);
    }

    function percent(uint256 value_, uint256 percentage_)
        public
        pure
        virtual
        returns (uint256)
    {
        uint256 result = value_.mul(percentage_).div(PERCENT_UNIT);
        return (result);
    }

    /*************************************************************************************************************************** */
    //Create Auction
    function createAuction(CreateAuctionData memory createAuctionData_)
        public
        returns (uint256 offerId_)
    {
        (
            ContractType contractType,
            bool isERC1155,
            bool isOwner,

        ) = _marketplaceManager.isOwnerOfNFT(
                msg.sender,
                createAuctionData_.tokenId,
                createAuctionData_.tokenContract
            );
        require(isOwner, "seller not owner");
        require(!isERC1155, "cannot auction erc1155 token");

        offerId_ = NiftySouqIMarketplace(_marketplace).createSale(
            createAuctionData_.tokenId,
            NiftySouqIMarketplace.ContractType(uint256(contractType)),
            NiftySouqIMarketplace.OfferType.AUCTION
        );

        CreateAuction memory auctionData = CreateAuction(
            offerId_,
            createAuctionData_.tokenId,
            createAuctionData_.tokenContract,
            block.timestamp,
            createAuctionData_.duration,
            msg.sender,
            createAuctionData_.startBidPrice,
            createAuctionData_.reservePrice
        );
        _createAuction(auctionData);
        emit eCreateAuction(
            offerId_,
            createAuctionData_.tokenId,
            createAuctionData_.tokenContract,
            msg.sender,
            block.timestamp,
            createAuctionData_.duration,
            createAuctionData_.startBidPrice,
            createAuctionData_.reservePrice
        );
    }

    //Mint and Auction
    function mintCreateAuctionNft(
        MintAndCreateAuctionData calldata mintNCreateAuction_
    ) public returns (uint256 offerId_, uint256 tokenId_) {
        (uint256 tokenId, , address tokenAddress) = NiftySouqIMarketplace(
            _marketplace
        ).mintNft(
                NiftySouqIMarketplace.MintData(
                    msg.sender,
                    mintNCreateAuction_.tokenAddress,
                    mintNCreateAuction_.uri,
                    mintNCreateAuction_.creators,
                    mintNCreateAuction_.royalties,
                    mintNCreateAuction_.investors,
                    mintNCreateAuction_.revenues,
                    1
                )
            );

        offerId_ = createAuction(
            CreateAuctionData(
                tokenId,
                tokenAddress,
                mintNCreateAuction_.duration,
                mintNCreateAuction_.startBidPrice,
                mintNCreateAuction_.reservePrice
            )
        );
        tokenId_ = tokenId;
    }

    // //End Auction
    // function endAuction(uint256 offerId_, uint256 bidIdx_) public {
    //     NiftySouqIMarketplace.Offer memory offer = NiftySouqIMarketplace(
    //         _marketplace
    //     ).getOfferStatus(offerId_);
    //     require(
    //         offer.offerType == NiftySouqIMarketplace.OfferType.AUCTION,
    //         "offer id is not auction"
    //     );
    //     require(
    //         offer.status == NiftySouqIMarketplace.OfferState.OPEN,
    //         "auction is not active"
    //     );
    //     (
    //         uint256 bidAmount,
    //         address[] memory refundAddresses,
    //         uint256[] memory refundAmount
    //     ) = _endAuction(offerId_,
    //     // msg.sender,
    //     bidIdx_);

    //     if (refundAddresses.length > 0) {
    //         Auction memory auctionDetails = getAuctionDetails(offerId_);
    //         NiftySouqIMarketplace(_marketplace).transferNFT(
    //             auctionDetails.seller,
    //             auctionDetails.bids[bidIdx_].bidder,
    //             auctionDetails.tokenId,
    //             auctionDetails.tokenContract,
    //             1
    //         );
    //         CryptoTokens memory wethDetails = _marketplaceManager
    //             .cryptoTokenList("WETH");
    //         _payout(
    //             Payout(wethDetails.tokenAddress, refundAddresses, refundAmount)
    //         );
    //     }
    //     NiftySouqIMarketplace(_marketplace).endSale(
    //         offerId_,
    //         NiftySouqIMarketplace.OfferState.ENDED
    //     );
    //     emit eEndAuction(offerId_, bidIdx_, msg.sender, address(0), bidAmount);
    // }

    //End Auction with highest bid
    function endAuction(uint256 offerId_) public {
        NiftySouqIMarketplace.Offer memory offer = NiftySouqIMarketplace(
            _marketplace
        ).getOfferStatus(offerId_);
        require(
            offer.offerType == NiftySouqIMarketplace.OfferType.AUCTION,
            "offer id is not auction"
        );
        require(
            offer.status == NiftySouqIMarketplace.OfferState.OPEN,
            "auction is not active"
        );
        (
            uint256 bidIdx,
            uint256 bidAmount,
            address[] memory refundAddresses,
            uint256[] memory refundAmount
        ) = _endAuctionWithHighestBid(offerId_, msg.sender);
        if (refundAddresses.length > 0) {
            Auction memory auctionDetails = getAuctionDetails(offerId_);
            NiftySouqIMarketplace(_marketplace).transferNFT(
                auctionDetails.seller,
                auctionDetails.bids[bidIdx].bidder,
                auctionDetails.tokenId,
                auctionDetails.tokenContract,
                1
            );
            CryptoTokens memory wethDetails = _marketplaceManager
                .cryptoTokenList("WETH");

            _payout(
                Payout(wethDetails.tokenAddress, refundAddresses, refundAmount)
            );
        }
        NiftySouqIMarketplace(_marketplace).endSale(
            offerId_,
            NiftySouqIMarketplace.OfferState.ENDED
        );
        emit eEndAuction(offerId_, bidIdx, msg.sender, address(0), bidAmount);
    }

    //extend Auction
    function extendAuction(uint256 offerId_, uint256 duration_) public {
        NiftySouqIMarketplace.Offer memory offer = NiftySouqIMarketplace(
            _marketplace
        ).getOfferStatus(offerId_);
        require(
            offer.offerType == NiftySouqIMarketplace.OfferType.AUCTION,
            "offer id is not auction"
        );
        require(
            offer.status == NiftySouqIMarketplace.OfferState.OPEN,
            "offer is not active"
        );

        require(
            _auction[offerId_].endTime > block.timestamp,
            "Auction duration completed"
        );

        require(
            _auction[offerId_].endTime.sub(extendAuctionPeriod) < block.timestamp,
            "Not in Extend Auction duration"
        );

        require(
            _auction[offerId_].reservePrice >
                _auction[offerId_].bids[_auction[offerId_].highestBidIdx].price,
            "Cannot extend auction. already highest bid grater than reserve price"
        );
        _auction[offerId_].endTime = _auction[offerId_].endTime.add(duration_);
    }

    //Cancel Auction
    function cancelAuction(uint256 offerId_) public {
        NiftySouqIMarketplace.Offer memory offer = NiftySouqIMarketplace(
            _marketplace
        ).getOfferStatus(offerId_);
        require(
            offer.offerType == NiftySouqIMarketplace.OfferType.AUCTION,
            "offer id is not auction"
        );
        require(
            offer.status == NiftySouqIMarketplace.OfferState.OPEN,
            "offer is not active"
        );
        (
            address[] memory refundAddresses,
            uint256[] memory refundAmount
        ) = _cancelAuction(offerId_);
        CryptoTokens memory wethDetails = _marketplaceManager.cryptoTokenList(
            "WETH"
        );

        _payout(
            Payout(wethDetails.tokenAddress, refundAddresses, refundAmount)
        );

        NiftySouqIMarketplace(_marketplace).endSale(
            offerId_,
            NiftySouqIMarketplace.OfferState.ENDED
        );
        emit eCancelAuction(offerId_);
    }

    //place bid function for lazy mint token
    function lazyMintAuctionNPlaceBid(
        LazyMintAuctionData calldata lazyMintAuctionData_,
        uint256 bidPrice
    )
        public
        returns (
            uint256 offerId_,
            uint256 tokenId_,
            uint256 bidIdx_
        )
    {
        address signer = _marketplaceManager.verifyAuctionLazyMint(
            lazyMintAuctionData_
        );
        require(
            lazyMintAuctionData_.seller == signer,
            "Nifty721: signature not verified"
        );
        (ContractType contractType_, bool isERC1155_, ) = _marketplaceManager
            .getContractDetails(lazyMintAuctionData_.tokenAddress, 1);

        require(!isERC1155_, "cannot auction erc1155 token");
        require(
            (contractType_ == ContractType.NIFTY_V2 ||
                contractType_ == ContractType.COLLECTOR) && !isERC1155_,
            "Not niftysouq contract"
        );
        //mint nft

        (uint256 tokenId, , address tokenAddress) = NiftySouqIMarketplace(
            _marketplace
        ).mintNft(
                NiftySouqIMarketplace.MintData(
                    lazyMintAuctionData_.seller,
                    lazyMintAuctionData_.tokenAddress,
                    lazyMintAuctionData_.uri,
                    lazyMintAuctionData_.creators,
                    lazyMintAuctionData_.royalties,
                    lazyMintAuctionData_.investors,
                    lazyMintAuctionData_.revenues,
                    1
                )
            );
        tokenId_ = tokenId;
        //create auction
        offerId_ = NiftySouqIMarketplace(_marketplace).createSale(
            tokenId_,
            NiftySouqIMarketplace.ContractType(uint256(contractType_)),
            NiftySouqIMarketplace.OfferType.AUCTION
        );

        CreateAuction memory auctionData = CreateAuction(
            offerId_,
            tokenId_,
            tokenAddress,
            lazyMintAuctionData_.startTime,
            lazyMintAuctionData_.duration,
            lazyMintAuctionData_.seller,
            lazyMintAuctionData_.startBidPrice,
            lazyMintAuctionData_.reservePrice
        );
        _createAuction(auctionData);

        //place bid
        bidIdx_ = placeBid(offerId_, bidPrice);
    }

    //Place Bid
    function placeBid(uint256 offerId_, uint256 bidPrice_)
        public
        returns (uint256 bidIdx_)
    {
        NiftySouqIMarketplace.Offer memory offer = NiftySouqIMarketplace(
            _marketplace
        ).getOfferStatus(offerId_);
        require(
            offer.offerType == NiftySouqIMarketplace.OfferType.AUCTION,
            "offer id is not auction"
        );
        require(
            offer.status == NiftySouqIMarketplace.OfferState.OPEN,
            "offer is not active"
        );
        CryptoTokens memory wethDetails = _marketplaceManager.cryptoTokenList(
            "WETH"
        );

        IERC20Upgradeable(wethDetails.tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            bidPrice_
        );

        bidIdx_ = _placeBid(offerId_, msg.sender, bidPrice_);
        emit ePlaceBid(offerId_, bidIdx_, msg.sender, bidPrice_);
    }

    //Place Higher Bid
    function placeHigherBid(
        uint256 offerId_,
        uint256 bidIdx_,
        uint256 bidPrice_
    ) public {
        NiftySouqIMarketplace.Offer memory offer = NiftySouqIMarketplace(
            _marketplace
        ).getOfferStatus(offerId_);
        require(
            offer.offerType == NiftySouqIMarketplace.OfferType.AUCTION,
            "offer id is not auction"
        );
        require(
            offer.status == NiftySouqIMarketplace.OfferState.OPEN,
            "offer is not active"
        );
        CryptoTokens memory wethDetails = _marketplaceManager.cryptoTokenList(
            "WETH"
        );

        IERC20Upgradeable(wethDetails.tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            bidPrice_
        );

        uint256 currentBidAmount = _placeHigherBid(
            offerId_,
            msg.sender,
            bidIdx_,
            bidPrice_
        );
        emit ePlaceHigherBid(offerId_, bidIdx_, msg.sender, currentBidAmount);
    }

    //Cancel Bid
    function cancelBid(uint256 offerId_, uint256 bidIdx_) public {
        NiftySouqIMarketplace.Offer memory offer = NiftySouqIMarketplace(
            _marketplace
        ).getOfferStatus(offerId_);
        require(
            offer.offerType == NiftySouqIMarketplace.OfferType.AUCTION,
            "offer id is not auction"
        );
        require(
            offer.status == NiftySouqIMarketplace.OfferState.OPEN,
            "offer is not active"
        );
        (
            address[] memory refundAddresses,
            uint256[] memory refundAmount
        ) = _cancelBid(offerId_, msg.sender, bidIdx_);
        CryptoTokens memory wethDetails = _marketplaceManager.cryptoTokenList(
            "WETH"
        );

        _payout(
            Payout(wethDetails.tokenAddress, refundAddresses, refundAmount)
        );
        emit eCancelBid(offerId_, bidIdx_);
    }

    function _payout(Payout memory payoutData_) private {
        for (uint256 i = 0; i < payoutData_.refundAddresses.length; i++) {
            if (payoutData_.refundAddresses[i] != address(0)) {
                if (address(0) == payoutData_.currency) {
                    payable(payoutData_.refundAddresses[i]).transfer(
                        payoutData_.refundAmounts[i]
                    );
                } else {
                    IERC20Upgradeable(payoutData_.currency).safeTransfer(
                        payoutData_.refundAddresses[i],
                        payoutData_.refundAmounts[i]
                    );
                }
                emit ePayoutTransfer(
                    payoutData_.refundAddresses[i],
                    payoutData_.refundAmounts[i],
                    payoutData_.currency
                );
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

enum ContractType {
    NIFTY_V1,
    NIFTY_V2,
    COLLECTOR,
    EXTERNAL,
    UNSUPPORTED
}
struct CalculatePayout {
    uint256 tokenId;
    address contractAddress;
    address seller;
    uint256 price;
    uint256 quantity;
}

struct LazyMintSellData {
    address tokenAddress;
    string uri;
    address seller;
    address[] creators;
    uint256[] royalties;
    address[] investors;
    uint256[] revenues;
    uint256 minPrice;
    uint256 quantity;
    bytes signature;
    string currency;
}

struct LazyMintAuctionData {
    address tokenAddress;
    string uri;
    address seller;
    address[] creators;
    uint256[] royalties;
    address[] investors;
    uint256[] revenues;
    uint256 startTime;
    uint256 duration;
    uint256 startBidPrice;
    uint256 reservePrice;
    bytes signature;
}

struct CryptoTokens {
    address tokenAddress;
    uint256 tokenValue;
    bool isEnabled;
}

interface NiftySouqIMarketplaceManager {
    function owner() external returns (address);

    function isAdmin(address caller_) external view returns (bool);

    function serviceFeeWallet() external returns (address);

    function serviceFeePercent() external returns (uint256);

    function cryptoTokenList(string memory)
        external
        returns (CryptoTokens memory);

    function verifyFixedPriceLazyMintV1(LazyMintSellData calldata lazyData_)
        external
        returns (address);

    function verifyFixedPriceLazyMintV2(LazyMintSellData calldata lazyData_)
        external
        returns (address);

    function verifyAuctionLazyMint(LazyMintAuctionData calldata lazyData_)
        external
        returns (address);

    function getContractDetails(address contractAddress_, uint256 quantity_)
        external
        returns (
            ContractType contractType_,
            bool isERC1155_,
            address tokenAddress_
        );

    function isOwnerOfNFT(
        address address_,
        uint256 tokenId_,
        address contractAddress_
    )
        external
        returns (
            ContractType contractType_,
            bool isERC1155_,
            bool isOwner_,
            uint256 quantity_
        );

    function calculatePayout(CalculatePayout memory calculatePayout_)
        external
        returns (
            address[] memory recepientAddresses_,
            uint256[] memory paymentAmount_,
            bool isTokenTransferable_,
            bool isOwner_
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface NiftySouqIERC721V2 {
    struct NftData {
        string uri;
        address[] creators;
        uint256[] royalties;
        address[] investors;
        uint256[] revenues;
        bool isFirstSale;
    }

    struct MintData {
        string uri;
        address minter;
        address[] creators;
        uint256[] royalties;
        address[] investors;
        uint256[] revenues;
        bool isFirstSale;
    }

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function getNftInfo(uint256 tokenId_)
        external
        view
        returns (NftData memory nfts_);

    function mint(MintData calldata mintData_)
        external
        returns (uint256 tokenId_);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferNft(
        address from_,
        address to_,
        uint256 tokenId_
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface NiftySouqIMarketplace {
    enum ContractType {
        NIFTY_V1,
        NIFTY_V2,
        COLLECTOR,
        EXTERNAL,
        UNSUPPORTED
    }

    enum OfferState {
        OPEN,
        CANCELLED,
        ENDED
    }

    enum OfferType {
        SALE,
        AUCTION
    }

    struct Offer {
        uint256 tokenId;
        OfferType offerType;
        OfferState status;
        ContractType contractType;
    }

    struct MintData {
        address minter;
        address tokenAddress;
        string uri;
        address[] creators;
        uint256[] royalties;
        address[] investors;
        uint256[] revenues;
        uint256 quantity;
    }

    struct Payout {
        address currency;
        address[] refundAddresses;
        uint256[] refundAmounts;
    }

    function mintNft(MintData memory mintData_)
        external
        returns (
            uint256 tokenId_,
            bool erc1155_,
            address tokenAddress_
        );

    function createSale(uint256 tokenId_, ContractType contractType_, OfferType offerType_)
        external
        returns (uint256 offerId_);

    function endSale(uint256 offerId_, OfferState offerState_) external;

    function payout(Payout memory payoutData_) external;

    function transferNFT(
        address from_,
        address to_,
        uint256 tokenId_,
        address tokenAddress_,
        uint256 quantity_
    ) external;

    function getOfferStatus(uint256 offerId_)
        external
        view
        returns (Offer memory offerDetails_);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}