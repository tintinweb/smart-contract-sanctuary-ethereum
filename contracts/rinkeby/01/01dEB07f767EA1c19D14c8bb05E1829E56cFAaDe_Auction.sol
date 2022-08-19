// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ICollectionNFT.sol";
import "./interfaces/IStanNFT.sol";
import "./interfaces/IStanToken.sol";
import "./interfaces/IListing.sol";
import "./interfaces/IOffer.sol";
import "./library/AuctionLibrary.sol";

contract Auction {
    using AuctionLibrary for AuctionLibrary.Offer;
    using AuctionLibrary for AuctionLibrary.autionStruct;

    mapping(address => uint256) public stanFund;
    mapping(bytes => AuctionLibrary.autionStruct) private auctionIdToAuction;
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
    IListing private listing;
    IOffer private offer;

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
        address _stanWalletAddress,
        address _listingAddress,
        address _offerAddress
    ) {
        owner = msg.sender;
        tokenStan = IStanToken(_tokenStan);
        stanNFT = IStanNFT(_stanNFT);
        collectionNFT = ICollectionNFT(_collectionNFT);
        stanWalletAddress = _stanWalletAddress;
        whiteList[owner] = true;
        listing = IListing(_listingAddress);
        offer = IOffer(_offerAddress);
    }

    modifier checkNFTOwnerShip(uint256 _tokenId) {
        stanNFT.isApprovedOrOwner(_tokenId);
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
        if (msg.sender != stanNFT.ownerOf(_tokenId) && !whiteList[msg.sender])
            revert InvalidOwnerNFT();
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

    function getInforOfferAuction(
        bytes memory _indexId,
        bytes memory _subOfferId
    )
        public
        view
        returns (
            uint256,
            address,
            address,
            uint256,
            uint256,
            AuctionLibrary.StateOfOffer
        )
    {
        AuctionLibrary.subOffer memory subOfferInstance = auctionIdToAuction[
            _indexId
        ].offers.subOffers[_subOfferId];

        return (
            auctionIdToAuction[_indexId].offers.tokenId,
            subOfferInstance.owner,
            subOfferInstance.maker,
            subOfferInstance.amount,
            subOfferInstance.expirationTime,
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

    function getOwnerWebOrMobile(uint256 _tokenId, bool _isWeb)
        private
        view
        returns (address)
    {
        return _isWeb ? msg.sender : stanNFT.getOwnerOfNFTMobile(_tokenId);
    }

    function processNFTOwner(
        address _sender,
        address _receiver,
        uint256 _tokenId,
        bool _isWeb
    ) private {
        _isWeb
            ? stanNFT.updateOwnerNFTAndTransferNFT(_sender, _receiver, _tokenId)
            : stanNFT.updateOwnerOfMobile(_tokenId, _receiver);
    }

    function getSender(address _maker, address _msgSender)
        private
        view
        returns (address)
    {
        if (_maker != address(0) && !whiteList[_msgSender])
            revert InvalidOwner();

        return _maker != address(0) ? _maker : _msgSender;
    }

    function listingNFTFixedPrice(
        bytes memory _requestId,
        bytes memory _listingId,
        uint256 _amount,
        uint256 _tokenId,
        address _maker,
        uint256 _expirationTime,
        bool _isWeb
    ) external onlyOwnerNFT(_tokenId) {
        listing.listingNFTFixedPrice(
            _listingId,
            _amount,
            _tokenId,
            getSender(_maker, msg.sender),
            _expirationTime,
            _isWeb
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
        address _maker,
        uint256 _expirationTime,
        bool _isWeb
    ) external onlyOwnerNFT(_tokenId) {
        if (stanFund[msg.sender] < feeSystem.stanFee && !whiteList[msg.sender])
            revert InvalidBalance();

        address maker = getSender(_maker, msg.sender);
        address ownerOfListing = listing.listingNFTAuction(
            _auctionId,
            _amount,
            _tokenId,
            maker,
            _expirationTime,
            _isWeb
        );

        auctionIdToAuction[_auctionId].autionId = _auctionId;
        auctionIdToAuction[_auctionId].tokenId = _tokenId;
        auctionIdToAuction[_auctionId].state = AuctionLibrary
            .StateOfAution
            .ACTIVE;
        auctionIdToAuction[_auctionId].owner = ownerOfListing;
        if (!whiteList[msg.sender] || _isWeb)
            stanFund[maker] -= feeSystem.stanFee;

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
        address _maker,
        uint256 _tokenId,
        bool _isWeb
    ) external {
        bytes memory _listingId = stanNFT.getTokenToListing(_tokenId);

        (
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            bool isAuction,
            AuctionLibrary.StateOfListing state
        ) = listing.getInforListing(_listingId);

        if (isAuction) revert NFTAreOnAuction();
        if (state != AuctionLibrary.StateOfListing.ACTIVE)
            revert InvalidState();
        address _buyer = getSender(_maker, msg.sender);
        uint256 priceOfNFT = stanNFT.getPriceNFT(_tokenId);

        if (priceOfNFT != 0 && tokenStan.balanceOf(_buyer) < priceOfNFT)
            revert InvalidBalance();

        listing.updateListing(
            _listingId,
            AuctionLibrary.paramListing(
                _buyer,
                AuctionLibrary.StateOfListing.INACTIVE
            )
        );

        if (!whiteList[msg.sender] || _isWeb)
            purchaseProcessing(
                _seller,
                _buyer,
                priceOfNFT,
                0,
                _tokenId,
                AuctionLibrary.Method.BUY,
                _isWeb
            );

        processNFTOwner(address(stanNFT), _buyer, _tokenId, _isWeb);

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
        address _maker,
        bool _isWeb
    ) external {
        uint256 tokenId = listing.cancelListingFixedPrice(
            _listingId,
            getSender(_maker, msg.sender),
            _isWeb
        );

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
        address _maker,
        bool _isWeb
    ) external {
        address maker = getSender(_maker, msg.sender);
        if (stanFund[maker] < feeSystem.stanFee && !whiteList[msg.sender])
            revert InvalidBalance();

        listing.cancelListingAuction(_listingId, maker, _isWeb);
        (, , , , , bytes memory auctionId, uint256 tokenId, , ) = listing
            .getInforListing(_listingId);

        changeStateOffers(auctionId, address(0));
        if (!whiteList[msg.sender] || _isWeb) {
            backFeeToUserFund(auctionId);
            stanFund[maker] -= feeSystem.stanFee;
        }

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
        address _maker,
        uint256 _expirationTime,
        uint256 _amount,
        bool _isWeb
    ) external {
        if (_amount <= 0) revert InvalidAmount();
        address maker = getSender(_maker, msg.sender);

        if (stanFund[maker] < _amount && !whiteList[msg.sender])
            revert InvalidBalance();
        if (_expirationTime <= block.timestamp) revert InvalidTimestamp();

        offer.makeOfferFixedPrice(
            maker,
            _subOfferId,
            _nftID,
            _tokenId,
            _expirationTime,
            _amount
        );

        processEvent(
            _tokenId,
            _requestId,
            AuctionLibrary.FunctionName.MAKE_OFFER_WITH_NFT,
            _isWeb
        );
    }

    function reOffer(
        bytes memory _subOfferId,
        bytes memory _auctionId,
        uint256 _amount
    ) private view returns (uint256) {
        (
            ,
            address ownerOffer,
            ,
            uint256 currentAmount,
            ,
            AuctionLibrary.StateOfOffer state
        ) = getInforOfferAuction(_auctionId, _subOfferId);

        if (
            ownerOffer == address(0) &&
            state == AuctionLibrary.StateOfOffer.INACTIVE
        ) return _amount;

        if (
            (currentAmount >= _amount ||
                state != AuctionLibrary.StateOfOffer.ACTIVE) &&
            !whiteList[msg.sender]
        ) revert ReOfferFailed();

        return _amount - currentAmount;
    }

    function placeBidAuction(
        bytes memory _requestId,
        bytes memory _subOfferId,
        bytes memory _auctionId,
        uint256 _amount,
        address _maker,
        bool _isWeb
    ) external checkStateOfAution(_auctionId) {
        if (_amount <= 0) revert InvalidAmount();
        address maker = getSender(_maker, msg.sender);
        if (
            stanFund[maker] < (_amount + feeSystem.stanFee) && !whiteList[maker]
        ) revert InvalidBalance();
        (
            ,
            address _owner,
            ,
            uint256 ExpirationTime,
            uint256 Amount,
            ,
            uint256 _tokenId,
            ,

        ) = listing.getInforListing(_auctionId);

        if (ExpirationTime < block.timestamp) revert InvalidTimestamp();
        if (Amount > _amount && !whiteList[maker]) revert InvalidOffer();
        if (!whiteList[msg.sender] || _isWeb)
            stanFund[maker] -= (reOffer(_subOfferId, _auctionId, _amount) +
                feeSystem.stanFee);

        AuctionLibrary.paramOffer memory params = AuctionLibrary.paramOffer(
            _subOfferId,
            NULL,
            _tokenId,
            _owner,
            maker,
            0,
            _amount,
            true
        );

        auctionIdToAuction[_auctionId].offers.saveOffer(params);
        auctionIdToAuction[_auctionId].offerIds.push(_subOfferId);
        auctionIdToAuction[_auctionId].userToBidnumber[maker] = _amount;
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
        address _maker,
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
        ) = offer.getInforOffer(_nftId, _subOfferId);

        (bytes memory _listingId, , , , , , , , ) = listing.getInforListing(
            _nftId
        );

        address ownerOffer = _listingId.length == 0
            ? getSender(_maker, msg.sender)
            : address(stanNFT);
        if (
            ownerOffer != stanNFT.ownerOf(tokenId) &&
            ownerOffer != stanNFT.getOwnerOfNFTMobile(tokenId)
        ) revert InvalidOwner();
        if (state != AuctionLibrary.StateOfOffer.ACTIVE) revert InvalidState();
        if (block.timestamp >= expirationTime) revert InvalidTimestamp();
        offer.acceptOfferPvP(_nftId, _subOfferId, _isWeb);

        if (!whiteList[msg.sender] || _isWeb)
            purchaseProcessing(
                ownerOffer,
                maker,
                amount,
                0,
                tokenId,
                AuctionLibrary.Method.OTHER,
                _isWeb
            );

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
        address _maker,
        bool _isWeb
    ) external {
        (
            uint256 tokenId,
            address OwnerOfOffer,
            address maker,
            uint256 amount,
            ,
            AuctionLibrary.StateOfOffer state
        ) = getInforOfferAuction(_auctionId, _subOfferId);

        (
            ,
            ,
            ,
            uint256 expirationTime,
            ,
            ,
            ,
            ,
            AuctionLibrary.StateOfListing stateOfListing
        ) = listing.getInforListing(_auctionId);

        address ownerOfNFT = stanNFT.ownerOf(tokenId);
        if (
            !_isWeb &&
            getSender(_maker, msg.sender) !=
            stanNFT.getOwnerOfNFTMobile(tokenId)
        ) revert InvalidOwner();
        if (ownerOfNFT != address(stanNFT)) revert InvalidOwner();
        if (
            state != AuctionLibrary.StateOfOffer.ACTIVE ||
            stateOfListing != AuctionLibrary.StateOfListing.ACTIVE
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

        processNFTOwner(ownerOfNFT, maker, tokenId, _isWeb);

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
        address _maker,
        bool _isWeb
    ) external {
        uint256 tokenId = offer.cancelOfferPvP(
            _nftId,
            _subOfferId,
            getSender(_maker, msg.sender),
            _isWeb
        );

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
        address _maker,
        bool _isWeb
    ) external {
        address maker = auctionIdToAuction[_auctionId]
            .offers
            .subOffers[_subOfferId]
            .maker;
        uint256 tokenId = auctionIdToAuction[_auctionId].offers.tokenId;
        address makerGetted = getSender(_maker, msg.sender);

        if (!_isWeb && maker != makerGetted) revert InvalidOwner();
        if (makerGetted != maker) revert InvalidOwner();
        if (auctionIdToAuction[_auctionId].offerIds.length == 0)
            revert InvalidOfferAmount();
        auctionIdToAuction[_auctionId].offers.processCancel(_subOfferId);
        if (!whiteList[msg.sender] || _isWeb)
            stanFund[makerGetted] += auctionIdToAuction[_auctionId]
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
        (, , , , , bytes memory _auctionId, uint256 _tokenId, , ) = listing
            .getInforListing(_indexId);

        if (_auctionId.length != 0) {
            auctionIdToAuction[_indexId].offers.processChangeExpired(
                subOffersIdParam
            );
            if (!whiteList[msg.sender] || _isWeb) backFeeToUserFund(_indexId);
        } else {
            offer.expiredOffer(_indexId, subOffersIdParam);
        }

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
        listing.expiredListing(listingIds, _isWeb);

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
        address _maker,
        bool _isWeb
    ) external {
        address maker = getSender(_maker, msg.sender);
        if (stanFund[maker] < feeSystem.stanFee && !whiteList[msg.sender])
            revert FeeExceedBalance();

        (, , , , , , , , AuctionLibrary.StateOfListing state) = listing
            .getInforListing(stanNFT.getTokenToListing(_tokenId));
        if (
            (maker != stanNFT.ownerOf(_tokenId) &&
                maker != stanNFT.getOwnerOfNFTMobile(_tokenId)) ||
            state != AuctionLibrary.StateOfListing.INACTIVE
        ) revert CannotTransferNFT();

        if (!whiteList[msg.sender] || _isWeb)
            stanFund[maker] -= feeSystem.stanFee;

        processNFTOwner(maker, _receiver, _tokenId, _isWeb);

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
    ) external {
        if (_amount <= 0) revert InvalidAmount();
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
    ) external {
        if (msg.sender != stanNFT.getOwnerOfNFTMobile(_tokenId))
            revert InvalidOwnerNFT();
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
    ) external {
        if (msg.sender != stanNFT.ownerOf(_tokenId)) revert InvalidOwnerNFT();
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
            AuctionLibrary.StateOfOffer state
        ) = getInforOfferAuction(_auctionId, _winnerSubOfferId);

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

        processNFTOwner(ownerNFT, maker, tokenId, _isWeb);
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
        (
            ,
            ,
            address ownerOfNFT,
            ,
            ,
            ,
            ,
            ,
            AuctionLibrary.StateOfListing state
        ) = listing.getInforListing(_auctionId);
        if (state != AuctionLibrary.StateOfListing.ACTIVE)
            revert InvalidState();

        uint256 winnerIndex = auctionIdToAuction[_auctionId]
            .findTheBestFitWinner();

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

        listing.updateListing(
            _auctionId,
            AuctionLibrary.paramListing(
                ownerOfNFT,
                AuctionLibrary.StateOfListing.INACTIVE
            )
        );

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
        bytes memory _idCollection,
        address _from,
        address _to
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

    function updateOwnerOfMobile(uint256 _tokenId, address _owner) external;
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

import "../library/AuctionLibrary.sol";

interface IListing {
    function listingNFTFixedPrice(
        bytes memory _listingId,
        uint256 _amount,
        uint256 _tokenId,
        address _sender,
        uint256 _expirationTime,
        bool _isWeb
    ) external;

    function listingNFTAuction(
        bytes memory _auctionId,
        uint256 _amount,
        uint256 _tokenId,
        address _sender,
        uint256 _expirationTime,
        bool _isWeb
    ) external returns (address);

    function cancelListingFixedPrice(
        bytes memory _listingId,
        address _sender,
        bool _isWeb
    ) external returns (uint256);

    function cancelListingAuction(
        bytes memory _listingId,
        address _sender,
        bool _isWeb
    ) external;

    function getInforListing(bytes memory _listing)
        external
        view
        returns (
            bytes memory,
            address,
            address,
            uint256,
            uint256,
            bytes memory,
            uint256,
            bool,
            AuctionLibrary.StateOfListing
        );

    function expiredListing(bytes[] memory listingIds, bool _isWeb) external;

    function updateListing(
        bytes memory _listingId,
        AuctionLibrary.paramListing memory params
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../library/AuctionLibrary.sol";

interface IOffer {
    function makeOfferFixedPrice(
        address _maker,
        bytes memory _subOfferId,
        bytes memory _nftID,
        uint256 _tokenId,
        uint256 _expirationTime,
        uint256 _amount
    ) external;

    function acceptOfferPvP(
        bytes memory _nftId,
        bytes memory _subOfferId,
        bool _isWeb
    ) external;

    function cancelOfferPvP(
        bytes memory _nftId,
        bytes memory _subOfferId,
        address _sender,
        bool _isWeb
    ) external returns (uint256);

    function getInforOffer(bytes memory _indexId, bytes memory _subOfferId)
        external
        view
        returns (
            uint256,
            address,
            address,
            uint256,
            uint256,
            bytes memory,
            AuctionLibrary.StateOfOffer
        );

    function expiredOffer(
        bytes memory _indexId,
        bytes[] calldata subOffersIdParam
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ICollectionNFT.sol";
import "../interfaces/IStanNFT.sol";

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
        FINISH_AUCTION,
        CREATE_NFT_BY_STAN,
        CREATE_NFT,
        CREATE_COLLECTION,
        ADD_NFT_TO_COLLECTION
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
        uint256 currentNumber;
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

    struct paramListing {
        address ownerOfNFT;
        StateOfListing state;
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

    function saveOffer(Offer storage _offerInstance, paramOffer memory _params)
        internal
    {
        _offerInstance.tokenId = _params.tokenId;
        if (_params.indexId.length != 0) {
            _offerInstance.nftID = _params.indexId;
        }
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

    function processCancel(
        Offer storage _offerInstance,
        bytes memory _subOfferId
    ) internal {
        StateOfOffer stateOfOffer = _offerInstance.subOffers[_subOfferId].state;
        if (
            stateOfOffer == AuctionLibrary.StateOfOffer.CANCELLED ||
            stateOfOffer == AuctionLibrary.StateOfOffer.INACTIVE
        ) revert AlreadyInActive();
        _offerInstance.subOffers[_subOfferId].state = AuctionLibrary
            .StateOfOffer
            .INACTIVE;
    }

    function findTheBestFitWinner(autionStruct storage _auction)
        internal
        view
        returns (uint256)
    {
        uint256 max;
        uint256 winnerIndex;

        for (uint256 i = 0; i < _auction.offerIds.length; ) {
            uint256 _amount = _auction
                .offers
                .subOffers[_auction.offerIds[i]]
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

    function processChangeExpired(
        Offer storage _offerInstance,
        bytes[] calldata subOffersIdParam
    ) internal {
        for (uint256 i = 0; i < subOffersIdParam.length; ) {
            _offerInstance.subOffers[subOffersIdParam[i]].state = AuctionLibrary
                .StateOfOffer
                .CANCELLED;
            unchecked {
                ++i;
            }
        }
    }
}