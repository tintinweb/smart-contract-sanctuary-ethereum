// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ICollectionNFT.sol";
import "./interfaces/IStanNFT.sol";
import "./interfaces/IStanToken.sol";
import "./library/AuctionLibrary.sol";

contract Auction {
    using AuctionLibrary for AuctionLibrary.Offer;

    mapping(address => uint256) public stanFund;
    mapping(bytes => AuctionLibrary.autionStruct) private auctionIdToAuction;
    mapping(bytes => AuctionLibrary.Listing) public Listings;
    mapping(bytes => AuctionLibrary.Offer) public Offers;
    mapping(address => bool) private whiteList;

    address public tokenStanAddress;
    address public stanWalletAddress;
    address private owner;
    AuctionLibrary.feeSystem public feeSystem;
    bytes constant NULL = "";
    uint256 constant withdrawPercentage = 80;

    IStanToken public tokenStan;
    IStanNFT public stanNFT;
    ICollectionNFT private collectionNFT;

    event STAN_EVENT(
        bytes requestId,
        AuctionLibrary.FunctionName nameFunction,
        bool platForm,
        uint256 tokenId
    );

    constructor(
        address _tokenStan,
        address _stanNFT,
        address _collectionNFT,
        address _stanWalletAddress
    ) {
        owner = msg.sender;
        tokenStan = IStanToken(_tokenStan);
        stanNFT = IStanNFT(_stanNFT);
        collectionNFT = ICollectionNFT(_collectionNFT);
        stanWalletAddress = _stanWalletAddress;
        whiteList[owner] = true;
    }

    modifier checkNFTOwnerShip(uint256 _tokenId) {
        stanNFT.isApprovedOrOwner(_tokenId);
        _;
    }

    modifier checkValidAmout(uint256 _amount) {
        if (_amount <= 0) revert InvalidAmount();
        _;
    }

    modifier checkStateOfAution(bytes memory _auctionId) {
        if (
            auctionIdToAuction[_auctionId].state !=
            AuctionLibrary.StateOfAution.ACTIVE
        ) revert InvalidState();
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert InvalidOwner();
        _;
    }

    modifier onlyOwnerNFT(uint256 _tokenId) {
        if (
            msg.sender != stanNFT.ownerOf(_tokenId) &&
            msg.sender != stanNFT.getOwnerOfNFTMobile(_tokenId)
        ) revert InvalidOwnerNFT();
        _;
    }

    function setTokenStan(address _tokenStan) external onlyOwner {
        tokenStan = IStanToken(_tokenStan);
    }

    function setWhileList(address _user) external onlyOwner {
        whiteList[_user] = true;
    }

    function setStateAuction(
        bytes memory _auctionId,
        AuctionLibrary.StateOfAution _state
    ) external onlyOwner {
        if (
            auctionIdToAuction[_auctionId].state ==
            AuctionLibrary.StateOfAution.DONE
        ) revert InvalidState();
        auctionIdToAuction[_auctionId].state = _state;
    }

    function setStanNFT(address _stanNFT) external onlyOwner {
        stanNFT = IStanNFT(_stanNFT);
    }

    function setStanAddress(address _stanAddress) external onlyOwner {
        stanWalletAddress = _stanAddress;
    }

    function setCollectionNFTAddress(address _collectionNFTAddress)
        external
        onlyOwner
    {
        collectionNFT = ICollectionNFT(_collectionNFTAddress);
    }

    function setFeeSystem(uint256 _stanFee, uint256 _serviceFee)
        external
        onlyOwner
    {
        AuctionLibrary.feeSystem memory FeeSystem = AuctionLibrary.feeSystem(
            _stanFee,
            _serviceFee
        );
        feeSystem = FeeSystem;
    }

    function getInforListing(bytes memory _listing)
        public
        view
        returns (
            bytes memory,
            address,
            address,
            uint256,
            uint256,
            bytes memory,
            uint256
        )
    {
        AuctionLibrary.Listing memory listing = Listings[_listing];

        return (
            listing.ListingID,
            listing.Owner,
            listing.ownerOfNFT,
            listing.ExpirationTime,
            listing.Amount,
            listing.AuctionId,
            listing.tokenId
        );
    }

    function getInforOffer(
        bytes memory _indexId,
        bytes memory _subOfferId,
        bool _isAuction
    )
        public
        view
        returns (
            uint256,
            address,
            address,
            uint256,
            uint256,
            bytes memory,
            AuctionLibrary.StateOfOffer
        )
    {
        AuctionLibrary.Offer storage _offerInstance = _isAuction
            ? auctionIdToAuction[_indexId].offers
            : Offers[_indexId];
        AuctionLibrary.subOffer memory subOfferInstance = _offerInstance
            .subOffers[_subOfferId];

        return (
            _offerInstance.tokenId,
            subOfferInstance.owner,
            subOfferInstance.maker,
            subOfferInstance.amount,
            subOfferInstance.expirationTime,
            _offerInstance.nftID,
            subOfferInstance.state
        );
    }

    function getInforAuction(bytes memory _autionId)
        public
        view
        returns (
            bytes memory,
            uint256,
            AuctionLibrary.StateOfAution,
            address,
            address,
            bytes[] memory,
            AuctionLibrary.Type
        )
    {
        AuctionLibrary.autionStruct storage _auction = auctionIdToAuction[
            _autionId
        ];

        return (
            _auction.autionId,
            _auction.tokenId,
            _auction.state,
            _auction.owner,
            _auction.winner,
            _auction.offerIds,
            _auction._type
        );
    }

    function distributeToken(
        uint256 _amount,
        address _buyer,
        address _seller,
        address creator,
        uint256 fee,
        uint256 ratioCreator,
        uint256 ratioStan,
        bool _isWeb,
        AuctionLibrary.Method _method
    ) private {
        uint256 creatorAmount = (_amount * ratioCreator) / 100;
        uint256 creatorStan = (_amount * ratioStan) / 100;
        uint256 remainAmount = _isWeb
            ? _amount - creatorAmount - creatorStan - fee
            : _amount;

        if (_method == AuctionLibrary.Method.BUY) {
            tokenStan.purchase(_buyer, stanWalletAddress, _amount);
            tokenStan.purchase(stanWalletAddress, creator, creatorAmount);
            tokenStan.purchase(stanWalletAddress, _seller, remainAmount);
        } else {
            stanFund[_buyer] = _method == AuctionLibrary.Method.AUCTION
                ? stanFund[_buyer]
                : stanFund[_buyer] - _amount;
            stanFund[creator] += creatorAmount;
            stanFund[_seller] += remainAmount;
        }
    }

    // Stan transfer fee to receivers
    function purchaseProcessing(
        address _seller,
        address _buyer,
        uint256 _amount,
        uint256 _fee,
        uint256 _tokenId,
        AuctionLibrary.Method _method,
        bool _isWeb
    ) private {
        (
            uint256 ratioCreator,
            uint256 ratioStan,
            address creator,
            ,
            ,

        ) = collectionNFT.getInfoCollection(
                collectionNFT.getTokenIdToCollectionId(_tokenId),
                _tokenId,
                _seller
            );
        uint256 fee = (_amount * _fee) / 100;
        require(
            (_method == AuctionLibrary.Method.BUY &&
                tokenStan.balanceOf(_buyer) > 0) ||
                stanFund[_buyer] >= (_amount + fee),
            "The balance of buyer is not enought to buy nft"
        );

        distributeToken(
            _amount,
            _buyer,
            _seller,
            creator,
            fee,
            ratioCreator,
            ratioStan,
            _isWeb,
            _method
        );
    }

    function saveOffer(
        AuctionLibrary.paramOffer memory _params,
        AuctionLibrary.Offer storage _offerInstance
    ) private {
        _offerInstance.tokenId = _params.tokenId;
        _offerInstance.nftID = _params.indexId.length == 0
            ? NULL
            : _params.indexId;
        _offerInstance.subOffers[_params.subOfferId].subOfferId = _params
            .subOfferId;
        _offerInstance.subOffers[_params.subOfferId].owner = _params.owner;
        _offerInstance.subOffers[_params.subOfferId].maker = _params.maker;
        _offerInstance.subOffers[_params.subOfferId].amount = _params.amount;
        _offerInstance.subOffers[_params.subOfferId].expirationTime = _params
            .expiTime;
        _offerInstance.subOffers[_params.subOfferId].state = AuctionLibrary
            .StateOfOffer
            .ACTIVE;
    }

    function backFeeToUserFund(bytes memory _auctionId) private {
        AuctionLibrary.Offer storage _offerInstance = auctionIdToAuction[
            _auctionId
        ].offers;

        uint256 length = auctionIdToAuction[_auctionId].offerIds.length;

        for (uint256 i = 0; i < length; ) {
            if (
                _offerInstance
                    .subOffers[auctionIdToAuction[_auctionId].offerIds[i]]
                    .state == AuctionLibrary.StateOfOffer.CANCELLED
            ) {
                address maker = _offerInstance
                    .subOffers[auctionIdToAuction[_auctionId].offerIds[i]]
                    .maker;
                stanFund[maker] += auctionIdToAuction[_auctionId]
                    .userToBidnumber[maker];
            }
            unchecked {
                ++i;
            }
        }
    }

    function processCancelListing(bytes memory _listingId) private {
        if (
            Listings[_listingId].state == AuctionLibrary.StateOfListing.INACTIVE
        ) revert AlreadyInActive();
        if (Listings[_listingId].Owner != msg.sender) revert InvalidOwner();

        (, address _owner, , , , , uint256 _tokenId) = getInforListing(
            _listingId
        );
        Listings[_listingId].state = AuctionLibrary.StateOfListing.INACTIVE;
        stanNFT.updateOwnerNFTAndTransferNFT(
            address(stanNFT),
            _owner,
            _tokenId
        );
    }

    function processEvent(
        uint256 _tokenId,
        bytes memory _requestId,
        AuctionLibrary.FunctionName _nameFunct,
        bool platform
    ) private {
        emit STAN_EVENT(_requestId, _nameFunct, platform, _tokenId);
    }

    function changeStateOffers(bytes memory _auctionId, address _exceptionist)
        private
    {
        bytes[] memory offerIds = auctionIdToAuction[_auctionId].offerIds;
        AuctionLibrary.Offer storage offerInstance = auctionIdToAuction[
            _auctionId
        ].offers;

        for (uint256 i = 0; i < offerIds.length; ) {
            address user = offerInstance.subOffers[offerIds[i]].maker;
            if (user != _exceptionist) {
                offerInstance.subOffers[offerIds[i]].state = AuctionLibrary
                    .StateOfOffer
                    .CANCELLED;
            }
            unchecked {
                ++i;
            }
        }
    }

    function listingNFTFixedPrice(
        bytes memory _requestId,
        bytes memory _listingId,
        uint256 _amount,
        uint256 _tokenId,
        uint256 _expirationTime,
        bool _isWeb
    ) external onlyOwnerNFT(_tokenId) {
        AuctionLibrary.Listing memory newInstance = AuctionLibrary.Listing(
            _listingId,
            msg.sender,
            address(stanNFT),
            _expirationTime,
            _amount,
            _tokenId,
            NULL,
            AuctionLibrary.StateOfListing.ACTIVE,
            false
        );
        Listings[_listingId] = newInstance;
        stanNFT.setPriceNFT(_tokenId, _amount);
        stanNFT.updateTokenToListing(_listingId, _tokenId);
        stanNFT.updateOwnerNFTAndTransferNFT(
            msg.sender,
            address(stanNFT),
            _tokenId
        );

        processEvent(
            _tokenId,
            _requestId,
            AuctionLibrary.FunctionName.LIST_FIXED_PRICE,
            _isWeb
        );
    }

    function listingNFTAuction(
        bytes memory _requestId,
        bytes memory _auctionId,
        uint256 _amount,
        uint256 _tokenId,
        uint256 _expirationTime,
        bool _isWeb
    ) external onlyOwnerNFT(_tokenId) {
        if (stanFund[msg.sender] < feeSystem.stanFee && !whiteList[msg.sender])
            revert InvalidBalance();
        AuctionLibrary.Listing memory newInstance = AuctionLibrary.Listing(
            _auctionId,
            msg.sender,
            address(stanNFT),
            _expirationTime,
            _amount,
            _tokenId,
            _auctionId,
            AuctionLibrary.StateOfListing.ACTIVE,
            true
        );
        Listings[_auctionId] = newInstance;

        auctionIdToAuction[_auctionId].autionId = _auctionId;
        auctionIdToAuction[_auctionId].tokenId = _tokenId;
        auctionIdToAuction[_auctionId].state = AuctionLibrary
            .StateOfAution
            .ACTIVE;
        auctionIdToAuction[_auctionId].owner = msg.sender;
        Listings[_auctionId].state = AuctionLibrary.StateOfListing.ACTIVE;
        if (!whiteList[msg.sender] || _isWeb)
            stanFund[msg.sender] -= feeSystem.stanFee;

        stanNFT.updateOwnerNFTAndTransferNFT(
            msg.sender,
            address(stanNFT),
            _tokenId
        );

        processEvent(
            _tokenId,
            _requestId,
            AuctionLibrary.FunctionName.LIST_AUCTION,
            _isWeb
        );
    }

    function buyFixPrice(
        bytes memory _requestId,
        address _seller,
        uint256 _tokenId,
        bool _isWeb
    ) external {
        bytes memory _listingId = stanNFT.getTokenToListing(_tokenId);
        if (Listings[_listingId].isAuction) revert NFTAreOnAuction();
        if (Listings[_listingId].state != AuctionLibrary.StateOfListing.ACTIVE)
            revert InvalidState();
        address _buyer = msg.sender;
        uint256 priceOfNFT = stanNFT.getPriceNFT(_tokenId);

        if (priceOfNFT != 0 && tokenStan.balanceOf(_buyer) < priceOfNFT)
            revert InvalidBalance();

        Listings[_listingId].ownerOfNFT = _buyer;
        Listings[_listingId].state = AuctionLibrary.StateOfListing.INACTIVE;

        if (_isWeb && !whiteList[_buyer])
            purchaseProcessing(
                _seller,
                _buyer,
                priceOfNFT,
                0,
                _tokenId,
                AuctionLibrary.Method.BUY,
                _isWeb
            );

        stanNFT.updateOwnerNFTAndTransferNFT(
            address(stanNFT),
            _buyer,
            _tokenId
        );

        processEvent(
            _tokenId,
            _requestId,
            AuctionLibrary.FunctionName.BUY_NFT,
            _isWeb
        );
    }

    function cancelListingFixedPrice(
        bytes memory _requestId,
        bytes memory _listingId,
        bool _isWeb
    ) external {
        processCancelListing(_listingId);

        uint256 tokenId = Listings[_listingId].tokenId;

        processEvent(
            tokenId,
            _requestId,
            AuctionLibrary.FunctionName.CANCEL_LISTING_FIX_PRICE,
            _isWeb
        );
    }

    function cancelListingAuction(
        bytes memory _requestId,
        bytes memory _listingId,
        bool _isWeb
    ) external {
        if (stanFund[msg.sender] < feeSystem.stanFee && !whiteList[msg.sender])
            revert InvalidBalance();

        processCancelListing(_listingId);

        changeStateOffers(Listings[_listingId].AuctionId, address(0));
        if (!whiteList[msg.sender] || _isWeb) {
            backFeeToUserFund(Listings[_listingId].AuctionId);
            stanFund[msg.sender] -= feeSystem.stanFee;
        }
        uint256 tokenId = Listings[_listingId].tokenId;

        processEvent(
            tokenId,
            _requestId,
            AuctionLibrary.FunctionName.CANCEL_LISTING_AUCTION,
            _isWeb
        );
    }

    function makeOfferFixedPrice(
        bytes memory _requestId,
        bytes memory _subOfferId,
        bytes memory _nftID,
        uint256 _tokenId,
        uint256 _expirationTime,
        uint256 _amount,
        bool _isWeb
    ) external checkValidAmout(_amount) {
        address _maker = msg.sender;
        if (stanFund[_maker] < _amount && !whiteList[msg.sender])
            revert InvalidBalance();
        if (_expirationTime <= block.timestamp) revert InvalidTimestamp();

        address ownerOfNFT = stanNFT.ownerOf(_tokenId);

        AuctionLibrary.paramOffer memory params = AuctionLibrary.paramOffer(
            _subOfferId,
            _nftID,
            _tokenId,
            ownerOfNFT,
            _maker,
            _expirationTime,
            _amount,
            false
        );
        saveOffer(params, Offers[_nftID]);

        processEvent(
            _tokenId,
            _requestId,
            AuctionLibrary.FunctionName.MAKE_OFFER_WITH_NFT,
            _isWeb
        );
    }

    function reOffer(
        bytes memory _requestId,
        bytes memory _auctionId,
        bytes memory _subOfferId,
        uint256 _amount,
        bool _isWeb
    ) external checkValidAmout(_amount) {
        (
            uint256 tokenId,
            ,
            address maker,
            uint256 currentOfferAmount,
            ,
            ,
            AuctionLibrary.StateOfOffer state
        ) = getInforOffer(_auctionId, _subOfferId, true);

        if (
            (currentOfferAmount >= _amount ||
                state != AuctionLibrary.StateOfOffer.ACTIVE) &&
            !whiteList[msg.sender]
        ) revert ReOfferFailed();

        auctionIdToAuction[_auctionId]
            .offers
            .subOffers[_subOfferId]
            .amount = _amount;
        if (!whiteList[msg.sender] || _isWeb)
            stanFund[maker] -= (_amount - currentOfferAmount);
        auctionIdToAuction[_auctionId].userToBidnumber[maker] = _amount;

        processEvent(
            tokenId,
            _requestId,
            AuctionLibrary.FunctionName.RE_OFFER,
            _isWeb
        );
    }

    function placeBidAuction(
        bytes memory _requestId,
        bytes memory _subOfferId,
        bytes memory _auctionId,
        uint256 _expirationTime,
        uint256 _amount,
        bool _isWeb
    ) external checkValidAmout(_amount) checkStateOfAution(_auctionId) {
        if (
            stanFund[msg.sender] < (_amount + feeSystem.stanFee) &&
            !whiteList[msg.sender]
        ) revert InvalidBalance();
        (
            ,
            address _owner,
            ,
            uint256 ExpirationTime,
            uint256 Amount,
            ,
            uint256 _tokenId
        ) = getInforListing(_auctionId);

        if (ExpirationTime < _expirationTime) revert InvalidTimestamp();
        if (Amount > _amount && !whiteList[msg.sender]) revert InvalidOffer();
        if (!whiteList[msg.sender] || _isWeb)
            stanFund[msg.sender] -= (_amount + feeSystem.stanFee);

        AuctionLibrary.paramOffer memory params = AuctionLibrary.paramOffer(
            _subOfferId,
            NULL,
            _tokenId,
            _owner,
            msg.sender,
            _expirationTime,
            _amount,
            true
        );

        saveOffer(params, auctionIdToAuction[_auctionId].offers);
        auctionIdToAuction[_auctionId].offerIds.push(_subOfferId);
        auctionIdToAuction[_auctionId].userToBidnumber[msg.sender] = _amount;
        auctionIdToAuction[_auctionId].offerIdToIndex[_subOfferId] =
            auctionIdToAuction[_auctionId].offerIds.length -
            1;

        processEvent(
            params.tokenId,
            _requestId,
            AuctionLibrary.FunctionName.MAKE_OFFER_WITH_AUCTION,
            _isWeb
        );
    }

    function acceptOfferPvP(
        bytes memory _requestId,
        bytes memory _nftId,
        bytes memory _subOfferId,
        bool _isWeb
    ) external {
        (
            uint256 tokenId,
            ,
            address maker,
            uint256 amount,
            uint256 expirationTime,
            ,
            AuctionLibrary.StateOfOffer state
        ) = getInforOffer(_nftId, _subOfferId, false);

        address ownerOfNFT = stanNFT.ownerOf(tokenId);

        if (msg.sender != ownerOfNFT && ownerOfNFT != address(stanNFT))
            revert InvalidOwner();
        if (state != AuctionLibrary.StateOfOffer.ACTIVE) revert InvalidState();
        if (block.timestamp >= expirationTime) revert InvalidTimestamp();

        Offers[_nftId].subOffers[_subOfferId].state = AuctionLibrary
            .StateOfOffer
            .DONE;

        if (!whiteList[msg.sender] || _isWeb)
            purchaseProcessing(
                ownerOfNFT,
                maker,
                amount,
                0,
                tokenId,
                AuctionLibrary.Method.OTHER,
                _isWeb
            );

        stanNFT.updateOwnerNFTAndTransferNFT(ownerOfNFT, maker, tokenId);

        processEvent(
            tokenId,
            _requestId,
            AuctionLibrary.FunctionName.ACCEPT_OFFER_WITH_NFT,
            _isWeb
        );
    }

    function acceptOfferAuction(
        bytes memory _requestId,
        bytes memory _auctionId,
        bytes memory _subOfferId,
        bool _isWeb
    ) external {
        (
            uint256 tokenId,
            address OwnerOfOffer,
            address maker,
            uint256 amount,
            uint256 expirationTime,
            ,
            AuctionLibrary.StateOfOffer state
        ) = getInforOffer(_auctionId, _subOfferId, true);

        address ownerOfNFT = stanNFT.ownerOf(tokenId);
        if (ownerOfNFT != address(stanNFT)) revert InvalidOwner();
        if (
            state != AuctionLibrary.StateOfOffer.ACTIVE ||
            Listings[_auctionId].state != AuctionLibrary.StateOfListing.ACTIVE
        ) revert InvalidState();
        if (block.timestamp >= expirationTime) revert InvalidTimestamp();

        auctionIdToAuction[_auctionId].state = AuctionLibrary
            .StateOfAution
            .DONE;

        auctionIdToAuction[_auctionId]
            .offers
            .subOffers[_subOfferId]
            .state = AuctionLibrary.StateOfOffer.DONE;

        if (!whiteList[msg.sender] || _isWeb)
            purchaseProcessing(
                OwnerOfOffer,
                maker,
                amount,
                0,
                tokenId,
                AuctionLibrary.Method.AUCTION,
                _isWeb
            );
        stanNFT.updateOwnerNFTAndTransferNFT(ownerOfNFT, maker, tokenId);

        processEvent(
            tokenId,
            _requestId,
            AuctionLibrary.FunctionName.ACCEPT_OFFER_WITH_AUCTION,
            _isWeb
        );
    }

    function cancelOfferPvP(
        bytes memory _requestId,
        bytes memory _nftId,
        bytes memory _subOfferId,
        bool _isWeb
    ) external {
        address maker = Offers[_nftId].subOffers[_subOfferId].maker;
        uint256 tokenId = Offers[_nftId].tokenId;

        if (msg.sender != maker) revert InvalidOwner();
        Offers[_nftId].processCancel(_subOfferId);

        processEvent(
            tokenId,
            _requestId,
            AuctionLibrary.FunctionName.CANCEL_OFFER_WITH_NFT,
            _isWeb
        );
    }

    function cancelOfferAuction(
        bytes memory _requestId,
        bytes memory _auctionId,
        bytes memory _subOfferId,
        bool _isWeb
    ) external {
        address maker = auctionIdToAuction[_auctionId]
            .offers
            .subOffers[_subOfferId]
            .maker;
        uint256 tokenId = auctionIdToAuction[_auctionId].offers.tokenId;

        if (msg.sender != maker) revert InvalidOwner();
        if (auctionIdToAuction[_auctionId].offerIds.length == 0)
            revert InvalidOfferAmount();
        auctionIdToAuction[_auctionId].offers.processCancel(_subOfferId);
        if (!whiteList[msg.sender] || _isWeb)
            stanFund[msg.sender] += auctionIdToAuction[_auctionId]
                .offers
                .subOffers[_subOfferId]
                .amount;
        auctionIdToAuction[_auctionId].userToBidnumber[maker] = 0;

        processEvent(
            tokenId,
            _requestId,
            AuctionLibrary.FunctionName.CANCEL_OFFER_WITH_AUCTION,
            _isWeb
        );
    }

    function expiredOffer(
        bytes memory _requestId,
        bytes memory _indexId,
        bytes[] calldata subOffersIdParam,
        bool _isWeb
    ) external onlyOwner {
        (, , , , , bytes memory _auctionId, uint256 _tokenId) = getInforListing(
            _indexId
        );

        AuctionLibrary.Offer storage offerInstance = _auctionId.length != 0
            ? auctionIdToAuction[_indexId].offers
            : Offers[_indexId];

        for (uint256 i = 0; i < subOffersIdParam.length; ) {
            offerInstance.subOffers[subOffersIdParam[i]].state = AuctionLibrary
                .StateOfOffer
                .CANCELLED;
            unchecked {
                ++i;
            }
        }

        if (_auctionId.length != 0 && (!whiteList[msg.sender] || _isWeb))
            backFeeToUserFund(_indexId);

        processEvent(
            _tokenId,
            _requestId,
            AuctionLibrary.FunctionName.EXPIRED_FIX_PRICE,
            _isWeb
        );
    }

    function expiredListing(
        bytes memory _requestId,
        bytes[] memory listingIds,
        bool _isAuction,
        bool _isWeb
    ) external onlyOwner {
        for (uint256 i = 0; i < listingIds.length; ) {
            Listings[listingIds[i]].state = AuctionLibrary
                .StateOfListing
                .EXPIRED;
            stanNFT.updateOwnerNFTAndTransferNFT(
                address(stanNFT),
                Listings[listingIds[i]].Owner,
                Listings[listingIds[i]].tokenId
            );

            unchecked {
                ++i;
            }
        }

        if (_isAuction) {
            for (uint256 i = 0; i < listingIds.length; ) {
                auctionIdToAuction[listingIds[i]].state = AuctionLibrary
                    .StateOfAution
                    .EXPIRED;

                unchecked {
                    ++i;
                }
            }
        }

        processEvent(
            0,
            _requestId,
            AuctionLibrary.FunctionName.EXPIRED_LISTING,
            _isWeb
        );
    }

    function transferNFTPvP(
        bytes memory _requestId,
        address _receiver,
        uint256 _tokenId,
        bool _isWeb
    ) external {
        if (stanFund[msg.sender] < feeSystem.stanFee && !whiteList[msg.sender])
            revert FeeExceedBalance();
        if (
            stanNFT.ownerOf(_tokenId) != msg.sender ||
            Listings[stanNFT.getTokenToListing(_tokenId)].state !=
            AuctionLibrary.StateOfListing.INACTIVE
        ) revert CannotTransferNFT();

        if (!whiteList[msg.sender] || _isWeb)
            stanFund[msg.sender] -= feeSystem.stanFee;
        stanNFT.updateOwnerNFTAndTransferNFT(msg.sender, _receiver, _tokenId);

        processEvent(
            _tokenId,
            _requestId,
            AuctionLibrary.FunctionName.TRANSFER_NFT_PVP,
            _isWeb
        );
    }

    function deposit(
        bytes memory _requestId,
        uint256 _amount,
        bool _isWeb
    ) external checkValidAmout(_amount) {
        stanFund[msg.sender] += _amount;
        tokenStan.purchase(msg.sender, address(this), _amount);

        processEvent(
            0,
            _requestId,
            AuctionLibrary.FunctionName.DEPOSIT,
            _isWeb
        );
    }

    function withdraw(
        bytes memory _requestId,
        uint256 _amount,
        bool _isWeb
    ) external {
        if (stanFund[msg.sender] == 0 || _amount > stanFund[msg.sender])
            revert InvalidBalance();

        stanFund[msg.sender] -= _amount;
        tokenStan.purchase(address(this), msg.sender, _amount);

        processEvent(
            0,
            _requestId,
            AuctionLibrary.FunctionName.WITHDRAW,
            _isWeb
        );
    }

    function withdrawByStan(
        bytes memory _requestId,
        uint256 _amount,
        bool _isWeb
    ) external onlyOwner {
        uint256 totalStanToken = tokenStan.balanceOf(address(this));
        if (_amount > (withdrawPercentage * totalStanToken) / 100)
            revert InvalidAmount();

        tokenStan.purchase(address(this), msg.sender, _amount);

        processEvent(
            0,
            _requestId,
            AuctionLibrary.FunctionName.WITHDRAW_BY_STAN,
            _isWeb
        );
    }

    function claimNFT(
        bytes memory _requestId,
        uint256 _tokenId,
        bool _isWeb
    ) external onlyOwnerNFT(_tokenId) {
        stanNFT.processNFTClaiming(
            address(stanNFT),
            msg.sender,
            _tokenId,
            true
        );

        processEvent(
            _tokenId,
            _requestId,
            AuctionLibrary.FunctionName.CLAIM_NFT,
            _isWeb
        );
    }

    function depositNFT(
        bytes memory _requestId,
        uint256 _tokenId,
        bool _isWeb
    ) external onlyOwnerNFT(_tokenId) {
        stanNFT.processNFTClaiming(
            msg.sender,
            address(stanNFT),
            _tokenId,
            false
        );

        processEvent(
            _tokenId,
            _requestId,
            AuctionLibrary.FunctionName.DEPOSIT_NFT,
            _isWeb
        );
    }

    function findTheBestFitWinner(bytes memory _auctionId)
        private
        view
        returns (uint256)
    {
        uint256 max;
        uint256 winnerIndex;

        for (
            uint256 i = 0;
            i < auctionIdToAuction[_auctionId].offerIds.length;

        ) {
            uint256 _amount = auctionIdToAuction[_auctionId]
                .offers
                .subOffers[auctionIdToAuction[_auctionId].offerIds[i]]
                .amount;
            if (_amount > max) {
                max = _amount;
                winnerIndex = i;
            }
            unchecked {
                ++i;
            }
        }

        return winnerIndex;
    }

    function processFinishAuction(
        bytes memory _auctionId,
        bytes memory _winnerSubOfferId,
        bool _isWeb
    ) private returns (uint256) {
        (
            uint256 tokenId,
            address ownerOfOffer,
            address maker,
            uint256 _amount,
            ,
            ,
            AuctionLibrary.StateOfOffer state
        ) = getInforOffer(_auctionId, _winnerSubOfferId, true);

        if (state != AuctionLibrary.StateOfOffer.ACTIVE) revert InvalidState();

        address ownerNFT = stanNFT.ownerOf(tokenId);

        if (!whiteList[msg.sender] || _isWeb)
            purchaseProcessing(
                ownerOfOffer,
                maker,
                _amount,
                feeSystem.serviceFee,
                tokenId,
                AuctionLibrary.Method.AUCTION,
                _isWeb
            );

        stanNFT.updateOwnerNFTAndTransferNFT(ownerNFT, maker, tokenId);
        return tokenId;
    }

    function finishAuction(
        bytes memory _requestId,
        bytes memory _auctionId,
        bool _isWeb
    )
        external
        onlyOwner
        checkNFTOwnerShip(auctionIdToAuction[_auctionId].tokenId)
        checkStateOfAution(_auctionId)
    {
        if (Listings[_auctionId].state != AuctionLibrary.StateOfListing.ACTIVE)
            revert InvalidState();

        uint256 winnerIndex = findTheBestFitWinner(_auctionId);

        bytes memory winnerSubOfferId = auctionIdToAuction[_auctionId].offerIds[
            winnerIndex
        ];
        address winner = auctionIdToAuction[_auctionId]
            .offers
            .subOffers[winnerSubOfferId]
            .maker;

        if (auctionIdToAuction[_auctionId].userToBidnumber[winner] == 0)
            revert InvalidWinner();

        auctionIdToAuction[_auctionId].winner = winner;
        auctionIdToAuction[_auctionId].state = AuctionLibrary
            .StateOfAution
            .DONE;
        Listings[_auctionId].state = AuctionLibrary.StateOfListing.INACTIVE;

        changeStateOffers(_auctionId, winner);
        if (!whiteList[msg.sender] || _isWeb) backFeeToUserFund(_auctionId);
        uint256 tokenId = processFinishAuction(
            _auctionId,
            winnerSubOfferId,
            _isWeb
        );

        processEvent(
            tokenId,
            _requestId,
            AuctionLibrary.FunctionName.FINISH_AUCTION,
            _isWeb
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../library/AuctionLibrary.sol";

interface ICollectionNFT {
    event STAN_EVENT(
        bytes requestId,
        string nameFunction,
        bool platForm,
        uint256 tokenId
    );

    function getTokenIdToCollectionId(uint256 _tokenId)
        external
        view
        returns (bytes memory);

    function setInforCollection(
        uint256 _ratioCreator,
        uint256 _ratioStan,
        uint160 _maxColletionNumber
    ) external;

    function createCollection(
        bytes memory _requestId,
        bytes memory _collectionId,
        bool _isWeb
    ) external;

   function createCollectionByStan(
        bytes memory _requestId,
        address _to,
        bytes memory _collectionId,
        bool _isWeb
    ) external;

    function addNFTtoCollection(
        bytes memory _requestId,
        bytes memory _idCollection,
        uint256 _tokenId,
        address _creator,
        bool _isWeb
    ) external;

    function updateOwnerNFT(
        bytes memory _requestId,
        bytes memory _idCollection,
        address _from,
        address _to,
        bool _isWeb
    ) external;

    function getInfoCollection(
        bytes memory _idCollection,
        uint256 _nft,
        address _currentOwnerNFT
    )
        external
        view
        returns (
            uint256 ratioCreator,
            uint256 ratioStan,
            address creator,
            address owner,
            uint256 nft,
            address currentOwnerNFT
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../library/AuctionLibrary.sol";

interface IStanNFT {
    event STAN_EVENT(
        bytes requestId,
        string nameFunction,
        bool platForm,
        uint256 tokenId
    );

    function createNFT(
        bytes memory _requestId,
        bytes memory _idCollection,
        string memory _tokenURI,
        bool _isWeb
    ) external returns (uint256);

    function createNFTByStan(
        bytes memory _requestId,
        bytes memory _idCollection,
        string memory _tokenURI,
        address _to,
        bool _isWeb
    ) external returns (uint256);

    function isApprovedOrOwner(uint256 _tokenId) external view;

    function updateTokenToListing(bytes memory _listing, uint256 _tokenId)
        external;

    function getTokenToListing(uint256 _tokenId)
        external
        view
        returns (bytes memory);

    function deleteTokenToListing(uint256 _tokenId) external;

    function getListingResult(uint256 _tokenId) external view returns (bool);

    function setPriceNFT(uint256 _tokenId, uint256 _amount) external;

    function getPriceNFT(uint256 _tokenId) external view returns (uint256);

    function updateOwnerNFTAndTransferNFT(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function ownerOf(uint256 _tokenId) external view returns (address);

    function processNFTClaiming(
        address _from,
        address _to,
        uint256 _tokenId,
        bool _isClaim
    ) external;

    function getOwnerOfNFTMobile(uint256 _tokenId)
        external
        view
        returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStanToken {
    function purchase(
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "../interfaces/ICollectionNFT.sol";

error InvalidAmount();
error InvalidState();
error InvalidOwner();
error InvalidOwnerNFT();
error InvalidBalance();
error FeeExceedBalance();
error NFTAreOnAuction();
error InvalidTimestamp();
error InvalidOfferAmount();
error InvalidWinner();
error InvalidOffer();
error ReOfferFailed();
error CannotTransferNFT();
error AlreadyInActive();

library AuctionLibrary {
    using Counters for Counters.Counter;

    enum FunctionName {
        LIST_FIXED_PRICE,
        LIST_AUCTION,
        BUY_NFT,
        CANCEL_LISTING_FIX_PRICE,
        CANCEL_LISTING_AUCTION,
        MAKE_OFFER_WITH_NFT,
        RE_OFFER,
        MAKE_OFFER_WITH_AUCTION,
        ACCEPT_OFFER_WITH_NFT,
        ACCEPT_OFFER_WITH_AUCTION,
        CANCEL_OFFER_WITH_NFT,
        CANCEL_OFFER_WITH_AUCTION,
        EXPIRED_FIX_PRICE,
        EXPIRED_LISTING,
        TRANSFER_NFT_PVP,
        DEPOSIT,
        WITHDRAW,
        WITHDRAW_BY_STAN,
        CLAIM_NFT,
        DEPOSIT_NFT,
        FINISH_AUCTION
    }

    struct autionStruct {
        bytes autionId;
        uint256 tokenId;
        StateOfAution state;
        address owner;
        address winner;
        bytes[] offerIds;
        Type _type;
        Offer offers;
        mapping(bytes => uint256) offerIdToIndex;
        mapping(address => uint256) userToBidnumber;
    }

    struct feeSystem {
        uint256 stanFee;
        uint256 serviceFee;
    }

    struct inforCollection {
        uint256 ratioCreator;
        uint256 ratioStan;
        uint160 maxColletionNumber;
    }

    struct Offer {
        uint256 tokenId;
        mapping(bytes => subOffer) subOffers;
        bytes nftID;
    }

    struct subOffer {
        bytes subOfferId;
        address owner;
        address maker;
        uint256 amount;
        uint256 expirationTime;
        StateOfOffer state;
    }

    struct Listing {
        bytes ListingID;
        address Owner;
        address ownerOfNFT;
        uint256 ExpirationTime;
        uint256 Amount;
        uint256 tokenId;
        bytes AuctionId;
        StateOfListing state;
        bool isAuction;
    }

    struct stateCollection {
        bytes id;
        Counters.Counter currentNumber;
        uint256 maxNumber;
        uint256 ratioCreator;
        uint256 ratioStan;
        address owner;
        mapping(uint256 => uint256) NFT;
        mapping(address => address) currentOwnerNFT;
        mapping(uint256 => address) creator;
    }

    struct participant {
        address user;
        uint256 index;
    }

    struct paramOffer {
        bytes subOfferId;
        bytes indexId;
        uint256 tokenId;
        address owner;
        address maker;
        uint256 expiTime;
        uint256 amount;
        bool isAuction;
    }

    enum StateOfListing {
        INACTIVE,
        ACTIVE,
        EXPIRED
    }

    enum Method {
        BUY,
        AUCTION,
        OTHER
    }

    enum Type {
        POINT,
        CRYPTO
    }

    enum StateOfOffer {
        INACTIVE,
        ACTIVE,
        EXPIRED,
        DONE,
        CANCELLED
    }

    enum StateOfAution {
        ACTIVE,
        DONE,
        CANCEL,
        EXPIRED
    }

    function processCancel(
        AuctionLibrary.Offer storage _offerInstance,
        bytes memory _subOfferId
    ) internal {
        AuctionLibrary.StateOfOffer stateOfOffer = _offerInstance
            .subOffers[_subOfferId]
            .state;
        if (
            stateOfOffer == AuctionLibrary.StateOfOffer.CANCELLED ||
            stateOfOffer == AuctionLibrary.StateOfOffer.INACTIVE
        ) revert AlreadyInActive();
        _offerInstance.subOffers[_subOfferId].state = AuctionLibrary
            .StateOfOffer
            .INACTIVE;
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