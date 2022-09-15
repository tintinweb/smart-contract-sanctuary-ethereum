// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interface/NiftySouq-IMarketplaceManager.sol";
import "./interface/NiftySouq-IERC721.sol";
import "./interface/NiftySouq-IERC1155.sol";
import "./interface/NiftySouq-IFixedPrice.sol";
import "./interface/NiftySouq-IAuction.sol";
import "./interface/IERC20.sol";

enum OfferState {
    OPEN,
    CANCELLED,
    ENDED
}

enum OfferType {
    SALE,
    AUCTION
}

struct MintData {
    address tokenAddress;
    string uri;
    address[] creators;
    uint256[] royalties;
    address[] investors;
    uint256[] revenues;
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
}

struct LazyMintAuctionData {
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

struct Offer {
    uint256 tokenId;
    OfferType offerType;
    OfferState status;
    ContractType contractType;
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

contract NiftySouqMarketplaceV2 is Initializable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    address private _admin;

    NiftySouqIMarketplaceManager private _niftySouqMarketplaceManager;
    NiftySouqIERC721V2 private _niftySouqErc721;
    NiftySouqIERC1155V2 private _niftySouqErc1155;
    NiftySouqIFixedPrice private _niftySouqFixedPrice;
    NiftySouqIAuction private _niftySouqAuction;

    Counters.Counter private _offerId;
    mapping(uint256 => Offer) private _offers;

    event Mint(
        uint256 tokenId,
        address contractAddress,
        bool isERC1155,
        address owner,
        uint256 quantity
    );

    event FixedPriceSale(
        uint256 offerId,
        uint256 tokenId,
        address contractAddress,
        bool isERC1155,
        address owner,
        uint256 quantity,
        uint256 price
    );
    event UpdateSalePrice(uint256 offerId, uint256 price);
    event CancelSale(uint256 offerId);
    event MakeOffer(
        uint256 offerId,
        uint256 oferIdx,
        address offeredBy,
        uint256 quantity,
        uint256 offerPrice
    );
    event CancelOffer(uint256 offerId, uint256 offerIdx);

    event Purchase(
        uint256 offerId,
        address buyer,
        address currency,
        uint256 quantity,
        bool isSaleCompleted
    );
    
    event AcceptOffer(
        uint256 offerId,
        uint256 offerIdx,
        address buyer,
        address currency,
        uint256 quantity,
        bool isSaleCompleted
    );

    event CreateAuction(
        uint256 offerId,
        uint256 tokenId,
        address contractAddress,
        address owner,
        uint256 startTime,
        uint256 duration,
        uint256 startBidPrice,
        uint256 reservePrice
    );
    event CancelAuction(uint256 offerId);
    event EndAuction(
        uint256 offerId,
        uint256 BidIdx,
        address buyer,
        address currency,
        uint256 price
    );
    event PlaceBid(
        uint256 offerId,
        uint256 BidIdx,
        address bidder,
        uint256 bidAmount
    );
    event PlaceHigherBid(
        uint256 offerId,
        uint256 BidIdx,
        address bidder,
        uint256 bidAmount
    );
    event CancelBid(uint256 offerId, uint256 bidIdx);

    event PayoutTransfer(
        address indexed withdrawer,
        uint256 indexed amount,
        address indexed currency
    );
    event RefundTransfer(address indexed withdrawer, uint256 indexed amount);

    modifier isNiftyAdmin() {
        require(
            (_admin == msg.sender) ||
                (_niftySouqMarketplaceManager.isAdmin(msg.sender)),
            "NiftyMarketplace: unauthorized."
        );
        _;
    }

    function initialize() public initializer {
        _admin = msg.sender;
    }

    function setContractAddresses(
        address marketplaceManager_,
        address erc721_,
        address erc1155_,
        address fixedPrice_,
        address auction_
    ) public isNiftyAdmin {
        if (marketplaceManager_ != address(0))
            _niftySouqMarketplaceManager = NiftySouqIMarketplaceManager(
                marketplaceManager_
            );
        if (erc721_ != address(0))
            _niftySouqErc721 = NiftySouqIERC721V2(erc721_);
        if (erc1155_ != address(0))
            _niftySouqErc1155 = NiftySouqIERC1155V2(erc1155_);
        if (fixedPrice_ != address(0))
            _niftySouqFixedPrice = NiftySouqIFixedPrice(fixedPrice_);
        if (auction_ != address(0))
            _niftySouqAuction = NiftySouqIAuction(auction_);
    }

    //Mint
    function mintNft(MintData memory mintData_)
        public
        returns (
            uint256 tokenId_,
            bool erc1155_,
            address tokenAddress_
        )
    {
        require(mintData_.quantity > 0, "quantity should be grater than 0");

        (
            ContractType contractType,
            bool isERC1155,
            address tokenAddress
        ) = _niftySouqMarketplaceManager.getContractDetails(
                mintData_.tokenAddress,
                mintData_.quantity
            );
        erc1155_ = isERC1155;
        tokenAddress_ = tokenAddress;
        if (isERC1155 && contractType == ContractType.NIFTY_V2) {
            NiftySouqIERC1155V2.MintData
                memory mintData1155_ = NiftySouqIERC1155V2.MintData(
                    mintData_.uri,
                    msg.sender,
                    mintData_.creators,
                    mintData_.royalties,
                    mintData_.investors,
                    mintData_.revenues,
                    mintData_.quantity
                );
            tokenId_ = NiftySouqIERC1155V2(tokenAddress).mint(mintData1155_);
        } else if (
            !isERC1155 &&
            (contractType == ContractType.NIFTY_V2 ||
                contractType == ContractType.COLLECTOR)
        ) {
            NiftySouqIERC721V2.MintData memory mintData721_ = NiftySouqIERC721V2
                .MintData(
                    mintData_.uri,
                    msg.sender,
                    mintData_.creators,
                    mintData_.royalties,
                    mintData_.investors,
                    mintData_.revenues,
                    true
                );
            tokenId_ = NiftySouqIERC721V2(tokenAddress).mint(mintData721_);
            erc1155_ = false;
        }
        emit Mint(
            tokenId_,
            tokenAddress,
            erc1155_,
            msg.sender,
            mintData_.quantity
        );
    }

    //Sell
    function sellNft(
        uint256 tokenId_,
        address tokenAddress_,
        uint256 price_,
        uint256 quantity_,
        bool isBargainable_
    ) public returns (uint256 offerId_) {
        _offerId.increment();
        offerId_ = _offerId.current();
        (
            ContractType contractType,
            bool isERC1155,
            bool isOwner,
            uint256 quantity
        ) = _niftySouqMarketplaceManager.isOwnerOfNFT(
                msg.sender,
                tokenId_,
                tokenAddress_
            );
        require(isOwner, "seller not owner");
        require(quantity >= quantity_, "insufficient token balance");
        _offers[offerId_] = Offer(
            tokenId_,
            OfferType.SALE,
            OfferState.OPEN,
            contractType
        );

        NiftySouqIFixedPrice.SellData memory sellData = NiftySouqIFixedPrice
            .SellData(
                offerId_,
                tokenId_,
                tokenAddress_,
                isERC1155,
                isERC1155 ? quantity_ : 1,
                price_,
                msg.sender,
                isBargainable_
            );
        NiftySouqIFixedPrice(_niftySouqFixedPrice).sell(sellData);
        emit FixedPriceSale(
            offerId_,
            tokenId_,
            tokenAddress_,
            isERC1155,
            msg.sender,
            isERC1155 ? quantity_ : 1,
            price_
        );
    }

    //Mint & Sell
    function mintSellNft(
        MintData calldata mintData_,
        uint256 price_,
        bool isBargainable_
    ) public returns (uint256 tokenId_, uint256 offerId_) {
        (uint256 tokenId, , address tokenAddress) = mintNft(mintData_);
        tokenId_ = tokenId;

        offerId_ = sellNft(
            tokenId,
            tokenAddress,
            price_,
            mintData_.quantity,
            isBargainable_
        );
    }

    function lazyMintSellNft(
        uint256 purchaseQuantity,
        NiftySouqIMarketplaceManager.LazyMintSellData calldata lazyMintSellData_
    ) external payable returns (uint256 offerId_, uint256 tokenId_) {
        require(
            lazyMintSellData_.seller != msg.sender,
            "Nifty1155: seller and buyer is same"
        );

        address signer = _niftySouqMarketplaceManager.verifyFixedPriceLazyMint(
            lazyMintSellData_
        );
        require(
            lazyMintSellData_.seller == signer,
            "Nifty721: signature not verified"
        );

        (offerId_, tokenId_) = _lazyMint(purchaseQuantity, lazyMintSellData_);
    }

    function _lazyMint(
        uint256 purchaseQuantity,
        NiftySouqIMarketplaceManager.LazyMintSellData calldata lazyMintSellData_
    ) private returns (uint256 offerId_, uint256 tokenId_) {
        (
            ContractType contractType,
            bool isERC1155,
            address tokenAddress
        ) = _niftySouqMarketplaceManager.getContractDetails(
                lazyMintSellData_.tokenAddress,
                lazyMintSellData_.quantity
            );

        if (isERC1155 && contractType == ContractType.NIFTY_V2) {
            NiftySouqIERC1155V2.LazyMintData
                memory lazyMintData_ = NiftySouqIERC1155V2.LazyMintData(
                    lazyMintSellData_.uri,
                    lazyMintSellData_.seller,
                    msg.sender,
                    lazyMintSellData_.creators,
                    lazyMintSellData_.royalties,
                    lazyMintSellData_.investors,
                    lazyMintSellData_.revenues,
                    lazyMintSellData_.quantity,
                    purchaseQuantity
                );
            tokenId_ = NiftySouqIERC1155V2(_niftySouqErc1155).lazyMint(
                lazyMintData_
            );
        } else if (
            !isERC1155 &&
            (contractType == ContractType.NIFTY_V2 ||
                contractType == ContractType.COLLECTOR)
        ) {
            MintData memory mintData = MintData(
                tokenAddress,
                lazyMintSellData_.uri,
                lazyMintSellData_.creators,
                lazyMintSellData_.royalties,
                lazyMintSellData_.investors,
                lazyMintSellData_.revenues,
                lazyMintSellData_.quantity
            );

            (
                uint256 tokenId__,
                bool isERC1155__,
                address tokenAddress__
            ) = mintNft(mintData);
            tokenId_ = tokenId__;
            isERC1155 = isERC1155__;
            tokenAddress = tokenAddress__;
        }
        _offerId.increment();
        offerId_ = _offerId.current();

        NiftySouqIFixedPrice.LazyMintData
            memory lazyMintData = NiftySouqIFixedPrice.LazyMintData(
                offerId_,
                tokenId_,
                tokenAddress,
                isERC1155,
                lazyMintSellData_.quantity,
                lazyMintSellData_.minPrice,
                lazyMintSellData_.seller,
                purchaseQuantity,
                msg.sender,
                purchaseQuantity,
                lazyMintSellData_.investors,
                lazyMintSellData_.revenues
            );
        (
            address[] memory recipientAddresses,
            uint256[] memory paymentAmount
        ) = NiftySouqIFixedPrice(_niftySouqFixedPrice).lazyMint(lazyMintData);

        _payout(Payout(address(0), recipientAddresses, paymentAmount));

        _offers[offerId_] = Offer(
            tokenId_,
            OfferType.SALE,
            OfferState.ENDED,
            ContractType.NIFTY_V2
        );
    }

    //Update Price
    function updateSalePrice(uint256 offerId_, uint256 updatedPrice_) public {
        require(offerId_ <= _offerId.current(), "offer id doesnt exist");
        require(
            _offers[offerId_].offerType == OfferType.SALE,
            "offer id is not sale"
        );
        require(
            _offers[offerId_].status == OfferState.OPEN,
            "offer is not active"
        );
        NiftySouqIFixedPrice(_niftySouqFixedPrice).updateSalePrice(
            offerId_,
            updatedPrice_,
            msg.sender
        );
        emit UpdateSalePrice(offerId_, updatedPrice_);
    }

    //Cancel Sale
    function cancelSale(uint256 offerId_) public {
        require(offerId_ <= _offerId.current(), "offer id doesnt exist");
        require(
            _offers[offerId_].offerType == OfferType.SALE,
            "offer id is not sale"
        );
        require(
            _offers[offerId_].status == OfferState.OPEN,
            "offer is not active"
        );
        _offers[offerId_].status = OfferState.CANCELLED;
        emit CancelSale(offerId_);

    }

    // //Make offer for sale
    // function makeOffer(
    //     uint256 offerId_,
    //     uint256 quantity,
    //     uint256 offerPrice
    // ) public {
    //     require(offerId_ <= _offerId.current(), "offer id doesnt exist");
    //     require(
    //         _offers[offerId_].offerType == OfferType.SALE,
    //         "offer id is not sale"
    //     );
    //     require(
    //         _offers[offerId_].status == OfferState.OPEN,
    //         "offer is not active"
    //     );
    //     uint256 offerIdx = NiftySouqIFixedPrice(_niftySouqFixedPrice).makeOffer(
    //         offerId_,
    //         msg.sender,
    //         quantity,
    //         offerPrice
    //     );
    //     emit MakeOffer(offerId_, offerIdx, msg.sender, quantity, offerPrice);
    // }

    // //cancel offer for sale
    // function cancelOffer(uint256 offerId_, uint256 offerIdx_) public {
    //     require(offerId_ <= _offerId.current(), "offer id doesnt exist");
    //     require(
    //         _offers[offerId_].offerType == OfferType.SALE,
    //         "offer id is not sale"
    //     );
    //     (
    //         address[] memory refundAddresses,
    //         uint256[] memory refundAmount
    //     ) = NiftySouqIFixedPrice(_niftySouqFixedPrice).cancelOffer(
    //             offerId_,
    //             msg.sender,
    //             offerIdx_
    //         );

    //     _payout(Payout(address(0), refundAddresses, refundAmount));
    // }

    //Purchase
    function buyNft(uint256 offerId_, uint256 quantity_) public payable {
        require(offerId_ <= _offerId.current(), "offer id doesnt exist");
        require(
            _offers[offerId_].offerType == OfferType.SALE,
            "offer id is not sale"
        );
        require(
            _offers[offerId_].status == OfferState.OPEN,
            "offer is not active"
        );
        NiftySouqIFixedPrice.Payout memory payoutData = NiftySouqIFixedPrice(
            _niftySouqFixedPrice
        ).buyNft(
                NiftySouqIFixedPrice.BuyNFT(
                    offerId_,
                    msg.sender,
                    quantity_,
                    msg.value
                )
            );

        _payout(
            Payout(
                address(0),
                payoutData.refundAddresses,
                payoutData.refundAmount
            )
        );

        _transferNFT(
            payoutData.seller,
            payoutData.buyer,
            payoutData.tokenId,
            payoutData.tokenAddress,
            payoutData.quantity
        );

        if (payoutData.soldout) {
            _offers[offerId_].status = OfferState.ENDED;
            emit Purchase(offerId_, msg.sender, address(0), quantity_, true);
        } else {
            emit Purchase(offerId_, msg.sender, address(0), quantity_, false);
        }
    }

    // // Accept Offer
    // function acceptOffer(uint256 offerId_, uint256 offerIdx_) public payable {
    //     require(offerId_ <= _offerId.current(), "offer id doesnt exist");
    //     require(
    //         _offers[offerId_].offerType == OfferType.SALE,
    //         "offer id is not sale"
    //     );
    //     require(
    //         _offers[offerId_].status == OfferState.OPEN,
    //         "offer is not active"
    //     );
    //     NiftySouqIFixedPrice.Payout memory payoutData = NiftySouqIFixedPrice(
    //         _niftySouqFixedPrice
    //     ).acceptOffer(offerId_, msg.sender, offerIdx_);

    //     _payout(
    //         Payout(
    //             address(0),
    //             payoutData.refundAddresses,
    //             payoutData.refundAmount
    //         )
    //     );
    //     _transferNFT(
    //         payoutData.seller,
    //         payoutData.buyer,
    //         payoutData.tokenId,
    //         payoutData.tokenAddress,
    //         payoutData.quantity
    //     );

    //     if (payoutData.soldout) {
    //         _offers[offerId_].status = OfferState.ENDED;
    //         emit AcceptOffer(
    //             offerId_,
    //             offerIdx_,
    //             payoutData.buyer,
    //             address(0),
    //             payoutData.quantity,
    //             true
    //         );
    //     } else {
    //         emit AcceptOffer(
    //             offerId_,
    //             offerIdx_,
    //             payoutData.buyer,
    //             address(0),
    //             payoutData.quantity,
    //             false
    //         );
    //     }
    // }

    //Create Auction
    function createAuction(CreateAuctionData memory createAuctionData_)
        public
        returns (uint256 offerId_)
    {
        _offerId.increment();
        offerId_ = _offerId.current();
        (
            ContractType contractType,
            bool isERC1155,
            bool isOwner,

        ) = _niftySouqMarketplaceManager.isOwnerOfNFT(
                msg.sender,
                createAuctionData_.tokenId,
                createAuctionData_.tokenContract
            );
        require(isOwner, "seller not owner");
        require(!isERC1155, "cannot auction erc1155 token");

        _offers[offerId_] = Offer(
            createAuctionData_.tokenId,
            OfferType.AUCTION,
            OfferState.OPEN,
            contractType
        );

        NiftySouqIAuction.CreateAuction memory auctionData = NiftySouqIAuction
            .CreateAuction(
                offerId_,
                createAuctionData_.tokenId,
                createAuctionData_.tokenContract,
                block.timestamp,
                createAuctionData_.duration,
                msg.sender,
                createAuctionData_.startBidPrice,
                createAuctionData_.reservePrice
            );
        NiftySouqIAuction(_niftySouqAuction).createAuction(auctionData);
        emit CreateAuction(
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
        (uint256 tokenId, , address tokenAddress) = mintNft(
            MintData(
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

    //End Auction
    function endAuction(uint256 offerId_, uint256 bidIdx_) public {
        require(offerId_ <= _offerId.current(), "offer id doesnt exist");
        require(
            _offers[offerId_].offerType == OfferType.AUCTION,
            "offer id is not auction"
        );
        require(
            _offers[offerId_].status == OfferState.OPEN,
            "offer is not active"
        );
        (
            uint256 bidAmount,
            address[] memory refundAddresses,
            uint256[] memory refundAmount
        ) = NiftySouqIAuction(_niftySouqAuction).endAuction(
                offerId_,
                msg.sender,
                bidIdx_
            );

        NiftySouqIAuction.Auction memory auctionDetails = NiftySouqIAuction(
            _niftySouqAuction
        ).getAuctionDetails(offerId_);
        _transferNFT(
            auctionDetails.seller,
            auctionDetails.bids[bidIdx_].bidder,
            auctionDetails.tokenId,
            auctionDetails.tokenContract,
            1
        );
        NiftySouqIMarketplaceManager.CryptoTokens
            memory wethDetails = _niftySouqMarketplaceManager.cryptoTokenList(
                "weth"
            );
        _payout(
            Payout(wethDetails.tokenAddress, refundAddresses, refundAmount)
        );
        emit EndAuction(offerId_, bidIdx_, msg.sender, address(0), bidAmount);
    }

    //End Auction with highest bid
    function endAuctionHighestBid(uint256 offerId_) public {
        require(offerId_ <= _offerId.current(), "offer id doesnt exist");
        require(
            _offers[offerId_].offerType == OfferType.AUCTION,
            "offer id is not auction"
        );
        require(
            _offers[offerId_].status == OfferState.OPEN,
            "offer is not active"
        );
        (
            uint256 bidIdx,
            uint256 bidAmount,
            address[] memory refundAddresses,
            uint256[] memory refundAmount
        ) = NiftySouqIAuction(_niftySouqAuction).endAuctionWithHighestBid(
                offerId_,
                msg.sender
            );

        NiftySouqIAuction.Auction memory auctionDetails = NiftySouqIAuction(
            _niftySouqAuction
        ).getAuctionDetails(offerId_);
        _transferNFT(
            auctionDetails.seller,
            auctionDetails.bids[bidIdx].bidder,
            auctionDetails.tokenId,
            auctionDetails.tokenContract,
            1
        );
        NiftySouqIMarketplaceManager.CryptoTokens
            memory wethDetails = _niftySouqMarketplaceManager.cryptoTokenList(
                "weth"
            );

        _payout(
            Payout(wethDetails.tokenAddress, refundAddresses, refundAmount)
        );
        emit EndAuction(offerId_, bidIdx, msg.sender, address(0), bidAmount);
    }

    //Cancel Auction
    function cancelAuction(uint256 offerId_) public {
        require(offerId_ <= _offerId.current(), "offer id doesnt exist");
        require(
            _offers[offerId_].offerType == OfferType.AUCTION,
            "offer id is not auction"
        );
        require(
            _offers[offerId_].status == OfferState.OPEN,
            "offer is not active"
        );
        (
            address[] memory refundAddresses,
            uint256[] memory refundAmount
        ) = NiftySouqIAuction(_niftySouqAuction).cancelAuction(offerId_);
        NiftySouqIMarketplaceManager.CryptoTokens
            memory wethDetails = _niftySouqMarketplaceManager.cryptoTokenList(
                "weth"
            );

        _payout(
            Payout(wethDetails.tokenAddress, refundAddresses, refundAmount)
        );
        emit CancelAuction(offerId_);
    }

    //place bid function for lazy mint token
    function lazyMintAuctionNPlaceBid(
        NiftySouqIMarketplaceManager.LazyMintAuctionData
            calldata lazyMintAuctionData_,
        uint256 bidPrice
    )
        public
        returns (
            uint256 offerId_,
            uint256 tokenId_,
            uint256 bidIdx_
        )
    {
        address signer = _niftySouqMarketplaceManager.verifyAuctionLazyMint(
            lazyMintAuctionData_
        );
        require(
            lazyMintAuctionData_.seller == signer,
            "Nifty721: signature not verified"
        );
        address tokenAddress;
        if (lazyMintAuctionData_.tokenAddress == address(0))
            tokenAddress = address(_niftySouqErc721);
        else tokenAddress = lazyMintAuctionData_.tokenAddress;
        (
            ContractType contractType,
            bool isERC1155,
            bool isOwner,

        ) = _niftySouqMarketplaceManager.isOwnerOfNFT(
                msg.sender,
                tokenId_,
                tokenAddress
            );
        require(isOwner, "seller not owner");
        require(!isERC1155, "cannot auction erc1155 token");
        require(
            (contractType == ContractType.NIFTY_V2 ||
                contractType == ContractType.COLLECTOR) && !isERC1155,
            "Not niftysouq contract"
        );
        //mint nft
        NiftySouqIERC721V2.MintData memory mintData721_ = NiftySouqIERC721V2
            .MintData(
                lazyMintAuctionData_.uri,
                lazyMintAuctionData_.seller,
                lazyMintAuctionData_.creators,
                lazyMintAuctionData_.royalties,
                lazyMintAuctionData_.investors,
                lazyMintAuctionData_.revenues,
                false
            );
        tokenId_ = NiftySouqIERC721V2(tokenAddress).mint(mintData721_);

        //create auction
        _offerId.increment();
        offerId_ = _offerId.current();
        _offers[offerId_] = Offer(
            tokenId_,
            OfferType.AUCTION,
            OfferState.OPEN,
            contractType
        );

        NiftySouqIAuction.CreateAuction memory auctionData = NiftySouqIAuction
            .CreateAuction(
                offerId_,
                tokenId_,
                address(_niftySouqErc721),
                lazyMintAuctionData_.startTime,
                lazyMintAuctionData_.duration,
                lazyMintAuctionData_.seller,
                lazyMintAuctionData_.startBidPrice,
                lazyMintAuctionData_.reservePrice
            );
        NiftySouqIAuction(_niftySouqAuction).createAuction(auctionData);

        //place bid
        bidIdx_ = placeBid(offerId_, bidPrice);
    }

    //Place Bid
    function placeBid(uint256 offerId, uint256 bidPrice)
        public
        returns (uint256 bidIdx_)
    {
        require(offerId <= _offerId.current(), "offer id doesnt exist");
        require(
            _offers[offerId].offerType == OfferType.AUCTION,
            "offer id is not auction"
        );
        require(
            _offers[offerId].status == OfferState.OPEN,
            "offer is not active"
        );
        NiftySouqIMarketplaceManager.CryptoTokens
            memory wethDetails = _niftySouqMarketplaceManager.cryptoTokenList(
                "weth"
            );

        IERC20(wethDetails.tokenAddress).transferFrom(
            msg.sender,
            address(this),
            bidPrice
        );

        bidIdx_ = NiftySouqIAuction(_niftySouqAuction).placeBid(
            offerId,
            msg.sender,
            bidPrice
        );
        emit PlaceBid(offerId, bidIdx_, msg.sender, bidPrice);
    }

    //Place Higher Bid
    function placeHigherBid(
        uint256 offerId,
        uint256 bidIdx,
        uint256 bidPrice
    ) public {
        require(offerId <= _offerId.current(), "offer id doesnt exist");
        require(
            _offers[offerId].offerType == OfferType.AUCTION,
            "offer id is not auction"
        );
        require(
            _offers[offerId].status == OfferState.OPEN,
            "offer is not active"
        );
        NiftySouqIMarketplaceManager.CryptoTokens
            memory wethDetails = _niftySouqMarketplaceManager.cryptoTokenList(
                "weth"
            );

        IERC20(wethDetails.tokenAddress).transferFrom(
            msg.sender,
            address(this),
            bidPrice
        );

        uint256 currentBidAmount = NiftySouqIAuction(_niftySouqAuction)
            .placeHigherBid(offerId, msg.sender, bidIdx, bidPrice);
        emit PlaceHigherBid(offerId, bidIdx, msg.sender, currentBidAmount);
    }

    //Cancel Bid
    function cancelBid(uint256 offerId, uint256 bidIdx) public {
        require(offerId <= _offerId.current(), "offer id doesnt exist");
        require(
            _offers[offerId].offerType == OfferType.AUCTION,
            "offer id is not auction"
        );
        require(
            _offers[offerId].status == OfferState.OPEN,
            "offer is not active"
        );
        (
            address[] memory refundAddresses,
            uint256[] memory refundAmount
        ) = NiftySouqIAuction(_niftySouqAuction).cancelBid(
                offerId,
                msg.sender,
                bidIdx
            );
        NiftySouqIMarketplaceManager.CryptoTokens
            memory wethDetails = _niftySouqMarketplaceManager.cryptoTokenList(
                "weth"
            );

        _payout(
            Payout(wethDetails.tokenAddress, refundAddresses, refundAmount)
        );
        emit CancelBid(offerId, bidIdx);
    }

    //get offer details
    function getOfferStatus(uint256 offerId_)
        public
        view
        returns (Offer memory offerDetails_)
    {
        offerDetails_ = _offers[offerId_];
    }

    //get offer details
    function getFixedPriceStatus(uint256 offerId_)
        public
        view
        returns (NiftySouqIFixedPrice.Sale memory saleDetails_)
    {
        saleDetails_ = NiftySouqIFixedPrice(_niftySouqFixedPrice)
            .getSaleDetails(offerId_);
    }

    //get offer details
    function getAuctionStatus(uint256 offerId_)
        public
        view
        returns (NiftySouqIAuction.Auction memory auctionDetails_)
    {
        auctionDetails_ = NiftySouqIAuction(_niftySouqAuction)
            .getAuctionDetails(offerId_);
    }

    function _payout(Payout memory payoutData_) internal {
        for (uint256 i = 0; i < payoutData_.refundAddresses.length; i++) {
            if (payoutData_.refundAddresses[i] != address(0)) {
                if (address(0) == payoutData_.currency) {
                    payable(payoutData_.refundAddresses[i]).transfer(
                        payoutData_.refundAmounts[i]
                    );
                } else {
                    IERC20(payoutData_.currency).transfer(
                        payoutData_.refundAddresses[i],
                        payoutData_.refundAmounts[i]
                    );
                }
                emit PayoutTransfer(
                    payoutData_.refundAddresses[i],
                    payoutData_.refundAmounts[i],
                    payoutData_.currency
                );
            }
        }
    }

    function _transferNFT(
        address from_,
        address to_,
        uint256 tokenId_,
        address tokenAddress_,
        uint256 quantity_
    ) internal {
        (
            ContractType contractType,
            bool isERC1155,
            bool isOwner,
            uint256 quantity
        ) = _niftySouqMarketplaceManager.isOwnerOfNFT(
                from_,
                tokenId_,
                tokenAddress_
            );
        require(isOwner, "seller not owner");
        require(quantity >= quantity_, "insufficient token balance");
        if (
            (contractType == ContractType.NIFTY_V2 ||
                contractType == ContractType.COLLECTOR) && !isERC1155
        ) {
            NiftySouqIERC721V2(tokenAddress_).transferNft(from_, to_, tokenId_);
        } else if (contractType == ContractType.NIFTY_V2 && isERC1155) {
            NiftySouqIERC1155V2(tokenAddress_).transferNft(
                from_,
                to_,
                tokenId_,
                quantity_
            );
        } else if (contractType == ContractType.EXTERNAL && !isERC1155) {
            NiftySouqIERC721V2(tokenAddress_).transferFrom(
                from_,
                to_,
                tokenId_
            );
        } else if (contractType == ContractType.EXTERNAL && isERC1155) {
            NiftySouqIERC1155V2(tokenAddress_).safeTransferFrom(
                from_,
                to_,
                tokenId_,
                quantity_,
                ""
            );
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

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

interface NiftySouqIMarketplaceManager {
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

    function owner() external returns (address);

    function isAdmin(address caller_) external view returns (bool);

    function serviceFeeWallet() external returns (address);

    function serviceFeePercent() external returns (uint256);

    function cryptoTokenList(string memory)
        external
        returns (CryptoTokens memory);

    function verifyFixedPriceLazyMint(LazyMintSellData calldata lazyData_)
        external
        returns (address);

    function verifyAuctionLazyMint(LazyMintAuctionData calldata lazyData_)
        external
        returns (address);

    function getContractDetails(address contractAddress_, uint256 quantity_)
        external
        returns (ContractType contractType_, bool isERC1155_, address tokenAddress_);

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
pragma solidity ^0.8.4;

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
pragma solidity ^0.8.4;

interface NiftySouqIERC1155V2 {
    struct NftData {
        string uri;
        address[] creators;
        uint256[] royalties;
        address[] investors;
        uint256[] revenues;
        address minter;
        uint256 firstSaleQuantity;
    }

    struct MintData {
        string uri;
        address minter;
        address[] creators;
        uint256[] royalties;
        address[] investors;
        uint256[] revenues;
        uint256 quantity;
    }

    struct LazyMintData {
        string uri;
        address minter;
        address buyer;
        address[] creators;
        uint256[] royalties;
        address[] investors;
        uint256[] revenues;
        uint256 quantity;
        uint256 soldQuantity;
    }

    function getNftInfo(uint256 tokenId_)
        external
        view
        returns (NftData memory nfts_);

    function totalSupply(uint256 tokenId)
        external
        view
        returns (uint256 totalSupply_);

    function mint(MintData calldata mintData_)
        external
        returns (uint256 tokenId_);

    function lazyMint(LazyMintData calldata lazyMintData_)
        external
        returns (uint256 tokenId_);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function transferNft(
        address from_,
        address to_,
        uint256 tokenId_,
        uint256 quantity_
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface NiftySouqIFixedPrice {
    struct PurchaseOffer {
        address offeredBy;
        uint256 quantity;
        uint256 price;
        uint256 offeredAt;
        bool canceled;
    }

    struct Sale {
        uint256 tokenId;
        address tokenContract;
        bool isERC1155;
        uint256 quantity;
        uint256 price;
        address seller;
        uint256 createdAt;
        uint256 soldQuantity;
        address[] buyer;
        uint256[] purchaseQuantity;
        uint256[] soldAt;
        bool isBargainable;
        PurchaseOffer[] offers;
    }

    struct SellData {
        uint256 offerId;
        uint256 tokenId;
        address tokenContract;
        bool isERC1155;
        uint256 quantity;
        uint256 price;
        address seller;
        bool isBargainable;
    }

    struct LazyMintData {
        uint256 offerId;
        uint256 tokenId;
        address tokenContract;
        bool isERC1155;
        uint256 quantity;
        uint256 price;
        address seller;
        uint256 soldQuantity;
        address buyer;
        uint256 purchaseQuantity;
        address[] investors;
        uint256[] revenues;
    }

    struct BuyNFT {
        uint256 offerId;
        address buyer;
        uint256 quantity;
        uint256 payment;
    }

    struct Payout {
        address seller;
        address buyer;
        uint256 tokenId;
        address tokenAddress;
        uint256 quantity;
        address[] refundAddresses;
        uint256[] refundAmount;
        bool soldout;
    }

    function sell(SellData calldata sell_) external;

    function lazyMint(LazyMintData calldata lazyMintData_)
        external
        returns (
            address[] memory recipientAddresses_,
            uint256[] memory paymentAmount_
        );

    function updateSalePrice(uint256 offerId_, uint256 updatedPrice_, address seller_) external;

    function makeOffer(
        uint256 offerId_,
        address offeredBy,
        uint256 quantity,
        uint256 offerPrice
    ) external returns (uint256 offerIdx_);

    function cancelOffer(
        uint256 offerId,
        address offeredBy,
        uint256 offerIdx_
    )
        external
        returns (
            address[] memory refundAddresses_,
            uint256[] memory refundAmount_
        );

    function buyNft(BuyNFT calldata buyNft_)
        external
        returns (Payout memory payout_);

    function acceptOffer(
        uint256 offerId_,
        address seller_,
        uint256 offerIdx_
    ) external returns (Payout memory payout_);

    function getSaleDetails(uint256 offerId_)
        external
        view
        returns (Sale memory sale_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface NiftySouqIAuction {
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

    function createAuction(CreateAuction calldata createAuctionData_) external;

    function cancelAuction(uint256 offerId)
        external
        returns (
            address[] memory refundAddresses_,
            uint256[] memory refundAmount_
        );

    function placeBid(
        uint256 offerId,
        address bidder,
        uint256 bidPrice
    ) external returns (uint256 bidIdx_);

    function placeHigherBid(
        uint256 offerId,
        address bidder,
        uint256 bidIdx,
        uint256 bidPrice
    ) external returns (uint256 currentBidPrice_);

    function cancelBid(
        uint256 offerId,
        address bidder,
        uint256 bidIdx
    )
        external
        returns (
            address[] memory refundAddresses_,
            uint256[] memory refundAmount_
        );

    function endAuction(
        uint256 offerId_,
        address creator,
        uint256 bidIdx
    )
        external
        returns (
            uint256 bidAmount_,
            address[] memory recipientAddresses_,
            uint256[] memory paymentAmount_
        );

    function endAuctionWithHighestBid(uint256 offerId_, address creator_)
        external
        returns (
            uint256 bidIdx_,
            uint256 bidAmount_,
            address[] memory recipientAddresses_,
            uint256[] memory paymentAmount_
        );

    function getAuctionDetails(uint256 offerId_)
        external
        view
        returns (Auction memory auction_);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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