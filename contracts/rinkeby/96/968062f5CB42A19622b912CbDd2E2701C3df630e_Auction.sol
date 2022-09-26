// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ICollectionNFT.sol";
import "./interfaces/IStanNFT.sol";
import "./interfaces/IStanToken.sol";
import "./interfaces/IListing.sol";
import "./interfaces/IOffer.sol";
import "./library/AuctionLibrary.sol";
import "hardhat/console.sol";

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
        bytes calldata _auctionId,
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

    function setFeeSystem(uint128 _stanFee, uint128 _serviceFee)
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
        AuctionLibrary.autionStruct
            storage auctionInstance = auctionIdToAuction[_indexId];
        AuctionLibrary.subOffer memory subOfferInstance = auctionInstance
            .offers
            .subOffers[_subOfferId];

        return (
            auctionInstance.offers.tokenId,
            auctionInstance.offers.owner,
            subOfferInstance.maker,
            subOfferInstance.amount,
            subOfferInstance.expirationTime,
            subOfferInstance.state
        );
    }

    function getInforAuction(bytes calldata _autionId)
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
        AuctionLibrary.Method _method
    ) private {
        uint256 creatorAmount = (_amount * ratioCreator) / 100;
        uint256 creatorStan = (_amount * ratioStan) / 100;
        uint256 remainAmount = _amount - creatorAmount - creatorStan - fee;

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
        AuctionLibrary.Method _method
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

    function processNFTOwner(
        address _sender,
        address _receiver,
        uint256 _tokenId,
        bytes memory _nftId,
        bool _isWeb
    ) private {
        _isWeb
            ? stanNFT.updateOwnerNFTAndTransferNFT(_sender, _receiver, _tokenId)
            : stanNFT.updateOwnerOfMobile(_nftId, _receiver);
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
        bytes calldata _requestId,
        bytes calldata _listingId,
        uint256 _amount,
        uint256 _tokenId,
        uint256 _expirationTime,
        address _maker,
        bytes calldata _nftId,
        bool _isWeb
    ) external onlyOwnerNFT(_tokenId) {
        listing.listingNFTFixedPrice(
            _listingId,
            _amount,
            _tokenId,
            getSender(_maker, msg.sender),
            _expirationTime,
            _nftId,
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
        uint256 _expirationTime,
        address _maker,
        bytes memory _nftId,
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
            _nftId,
            _isWeb
        );

        AuctionLibrary.autionStruct
            storage auctionInstance = auctionIdToAuction[_auctionId];

        auctionInstance.autionId = _auctionId;
        auctionInstance.tokenId = _tokenId;
        auctionInstance.state = AuctionLibrary.StateOfAution.ACTIVE;
        auctionInstance.owner = ownerOfListing;
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
        bytes memory _listingId,
        bool _isWeb
    ) external {
        (
            ,
            ,
            ,
            ,
            ,
            ,
            uint256 _tokenId,
            bool isAuction,
            AuctionLibrary.StateOfListing state,
            bytes memory _nftId
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
                AuctionLibrary.Method.BUY
            );

        processNFTOwner(address(stanNFT), _buyer, _tokenId, _nftId, _isWeb);

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
        uint256 tokenId = listing.cancelListingFixedPrice(_listingId, _isWeb);

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
        (
            ,
            address ownerOfListing,
            ,
            ,
            ,
            bytes memory auctionId,
            uint256 tokenId,
            ,
            ,

        ) = listing.getInforListing(_listingId);

        listing.cancelListingAuction(_listingId, _isWeb);

        if (
            stanFund[ownerOfListing] < feeSystem.stanFee &&
            !whiteList[msg.sender]
        ) revert InvalidBalance();

        changeStateOffers(auctionId, address(0));
        if (!whiteList[msg.sender] || _isWeb) {
            backFeeToUserFund(auctionId);
            stanFund[ownerOfListing] -= feeSystem.stanFee;
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
        uint256 _expirationTime,
        uint256 _amount,
        address _maker,
        bool _isWeb
    ) external {
        if (_amount <= 0) revert InvalidAmount();
        address maker = getSender(_maker, msg.sender);

        (bytes memory _listingId, address _owner, , , , , , , , ) = listing
            .getInforListing(stanNFT.getTokenToListing(_tokenId));

        if (stanFund[maker] < _amount && !whiteList[msg.sender])
            revert InvalidBalance();
        if (_expirationTime <= block.timestamp) revert InvalidTimestamp();

        address ownerOfNFT = _listingId.length != 0
            ? _owner
            : (
                stanNFT.getOwnerOfNFTMobile(_nftID) == address(0)
                    ? stanNFT.ownerOf(_tokenId)
                    : stanNFT.getOwnerOfNFTMobile(_nftID)
            );

        offer.makeOfferFixedPrice(
            ownerOfNFT,
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

        if ((currentAmount >= _amount)) revert ReOfferFailed();

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

        AuctionLibrary.autionStruct
            storage auctionInstance = auctionIdToAuction[_auctionId];

        auctionInstance.offers.saveOffer(params);
        auctionInstance.offerIds.push(_subOfferId);
        auctionInstance.userToBidnumber[maker] = _amount;
        auctionInstance.offerIdToIndex[_subOfferId] =
            auctionInstance.offerIds.length -
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
            address ownerOffer,
            address maker,
            uint256 amount,
            uint256 expirationTime,
            ,
            AuctionLibrary.StateOfOffer state
        ) = offer.getInforOffer(_nftId, _subOfferId);

        if (!whiteList[msg.sender] && msg.sender != ownerOffer)
            revert InvalidOwner();
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
                AuctionLibrary.Method.OTHER
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
        bytes memory _nftId,
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
            AuctionLibrary.StateOfListing stateOfListing,

        ) = listing.getInforListing(_auctionId);

        address ownerOfNFT = stanNFT.ownerOf(tokenId);
        if (ownerOfNFT != address(stanNFT)) revert InvalidOwner();
        if (
            state != AuctionLibrary.StateOfOffer.ACTIVE ||
            stateOfListing != AuctionLibrary.StateOfListing.ACTIVE
        ) revert InvalidState();
        if (block.timestamp >= expirationTime) revert InvalidTimestamp();

        AuctionLibrary.autionStruct
            storage auctionInstance = auctionIdToAuction[_auctionId];
        auctionInstance.state = AuctionLibrary.StateOfAution.DONE;
        auctionInstance.offers.subOffers[_subOfferId].state = AuctionLibrary
            .StateOfOffer
            .DONE;

        if (!whiteList[msg.sender] || _isWeb)
            purchaseProcessing(
                OwnerOfOffer,
                maker,
                amount,
                0,
                tokenId,
                AuctionLibrary.Method.AUCTION
            );

        processNFTOwner(ownerOfNFT, maker, tokenId, _nftId, _isWeb);
        if (_nftId.length > 0) offer.updateOwnerOfNFT(_nftId, maker);

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
        uint256 tokenId = offer.cancelOfferPvP(
            _nftId,
            _subOfferId,
            msg.sender,
            whiteList[msg.sender]
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
        bytes calldata _subOfferId,
        bool _isWeb
    ) external {
        AuctionLibrary.autionStruct
            storage auctionInstance = auctionIdToAuction[_auctionId];
        address maker = auctionInstance.offers.subOffers[_subOfferId].maker;
        if (!whiteList[msg.sender] && msg.sender != maker)
            revert InvalidOwner();

        uint256 tokenId = auctionInstance.offers.tokenId;

        if (auctionInstance.offerIds.length == 0) revert InvalidOfferAmount();
        auctionInstance.offers.processCancel(_subOfferId);
        if (!whiteList[msg.sender] || _isWeb)
            stanFund[maker] += auctionInstance
                .offers
                .subOffers[_subOfferId]
                .amount;
        auctionInstance.userToBidnumber[maker] = 0;

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
        (, , , , , bytes memory _auctionId, uint256 _tokenId, , , ) = listing
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
        bytes memory _nftId,
        bool _isWeb
    ) external {
        address maker = getSender(_maker, msg.sender);
        if (stanFund[maker] < feeSystem.stanFee && !whiteList[msg.sender])
            revert FeeExceedBalance();

        (, , , , , , , , AuctionLibrary.StateOfListing state, ) = listing
            .getInforListing(stanNFT.getTokenToListing(_tokenId));
        if (
            (maker != stanNFT.ownerOf(_tokenId) &&
                maker != stanNFT.getOwnerOfNFTMobile(_nftId)) ||
            state != AuctionLibrary.StateOfListing.INACTIVE
        ) revert CannotTransferNFT();

        if (!whiteList[msg.sender] || _isWeb)
            stanFund[maker] -= feeSystem.stanFee;

        processNFTOwner(maker, _receiver, _tokenId, _nftId, _isWeb);

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
        bytes calldata _nftId,
        bool _isWeb
    ) external {
        if (msg.sender != stanNFT.getOwnerOfNFTMobile(_nftId))
            revert InvalidOwnerNFT();
        uint256 tokenId = stanNFT.processNFTClaiming(
            address(stanNFT),
            msg.sender,
            _nftId,
            true
        );

        processEvent(
            tokenId,
            _requestId,
            AuctionLibrary.FunctionName.CLAIM_NFT,
            _isWeb
        );
    }

    function depositNFT(
        bytes memory _requestId,
        uint256 _tokenId,
        bytes calldata _nftId,
        bool _isWeb
    ) external {
        if (msg.sender != stanNFT.ownerOf(_tokenId)) revert InvalidOwnerNFT();
        uint256 tokenId = stanNFT.processNFTClaiming(
            msg.sender,
            address(stanNFT),
            _nftId,
            false
        );

        processEvent(
            tokenId,
            _requestId,
            AuctionLibrary.FunctionName.DEPOSIT_NFT,
            _isWeb
        );
    }

    function processFinishAuction(
        bytes memory _auctionId,
        bytes memory _winnerSubOfferId,
        bytes memory _nftId,
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
                AuctionLibrary.Method.AUCTION
            );

        processNFTOwner(ownerNFT, maker, tokenId, _nftId, _isWeb);
        return tokenId;
    }

    function finishAuction(
        bytes memory _requestId,
        bytes memory _auctionId,
        bytes memory _nftId,
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
            AuctionLibrary.StateOfListing state,

        ) = listing.getInforListing(_auctionId);
        if (state != AuctionLibrary.StateOfListing.ACTIVE)
            revert InvalidState();

        AuctionLibrary.autionStruct
            storage auctionInstance = auctionIdToAuction[_auctionId];

        uint256 winnerIndex = auctionInstance.findTheBestFitWinner();
        bytes memory winnerSubOfferId = auctionInstance.offerIds[winnerIndex];
        address winner = auctionInstance
            .offers
            .subOffers[winnerSubOfferId]
            .maker;

        if (auctionInstance.userToBidnumber[winner] == 0)
            revert InvalidWinner();

        auctionInstance.winner = winner;
        auctionInstance.state = AuctionLibrary.StateOfAution.DONE;

        listing.updateListing(
            _auctionId,
            AuctionLibrary.paramListing(
                ownerOfNFT,
                AuctionLibrary.StateOfListing.INACTIVE
            )
        );

        changeStateOffers(_auctionId, winner);
        if (_nftId.length > 0) offer.updateOwnerOfNFT(_nftId, winner);

        if (!whiteList[msg.sender] || _isWeb) backFeeToUserFund(_auctionId);
        uint256 tokenId = processFinishAuction(
            _auctionId,
            winnerSubOfferId,
            _nftId,
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
        bytes calldata _requestId,
        bytes calldata _collectionId,
        bool _isWeb
    ) external;

    function createCollectionByStan(
        bytes calldata _requestId,
        address _to,
        bytes calldata _collectionId,
        bool _isWeb
    ) external;

    function addNFTtoCollection(
        bytes calldata _requestId,
        bytes calldata _idCollection,
        uint256 _tokenId,
        address _creator,
        bool _isWeb
    ) external;

    function updateOwnerNFT(
        bytes calldata _idCollection,
        address _from,
        address _to
    ) external;

    function getInfoCollection(
        bytes calldata _idCollection,
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
        bytes calldata _requestId,
        bytes calldata _idCollection,
        string calldata _tokenURI,
        bool _isWeb
    ) external returns (uint256);

    function createNFTByStan(
        bytes calldata _requestId,
        bytes calldata _idCollection,
        string calldata _tokenURI,
        address _to,
        bytes calldata _nftID,
        bool _isWeb
    ) external returns (uint256);

    function isApprovedOrOwner(uint256 _tokenId) external view;

    function updateTokenToListing(bytes calldata _listing, uint256 _tokenId)
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
        bytes calldata _nftId,
        bool _isClaim
    ) external returns (uint256);

    function getOwnerOfNFTMobile(bytes calldata _nftId)
        external
        view
        returns (address);

    function updateOwnerOfMobile(bytes calldata _nftId, address _owner)
        external;
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
        bytes calldata _listingId,
        uint256 _amount,
        uint256 _tokenId,
        address _sender,
        uint256 _expirationTime,
        bytes calldata _nftId,
        bool _isWeb
    ) external;

    function listingNFTAuction(
        bytes calldata _auctionId,
        uint256 _amount,
        uint256 _tokenId,
        address _sender,
        uint256 _expirationTime,
        bytes calldata _nftId,
        bool _isWeb
    ) external returns (address);

    function cancelListingFixedPrice(bytes calldata _listingId, bool _isWeb)
        external
        returns (uint256);

    function cancelListingAuction(bytes calldata _listingId, bool _isWeb)
        external;

    function getInforListing(bytes calldata _listing)
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
            AuctionLibrary.StateOfListing,
            bytes memory
        );

    function expiredListing(bytes[] calldata listingIds, bool _isWeb) external;

    function updateListing(
        bytes calldata _listingId,
        AuctionLibrary.paramListing calldata params
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../library/AuctionLibrary.sol";

interface IOffer {
    function makeOfferFixedPrice(
        address _owner,
        address _maker,
        bytes calldata _subOfferId,
        bytes calldata _nftID,
        uint256 _tokenId,
        uint256 _expirationTime,
        uint256 _amount
    ) external;

    function acceptOfferPvP(
        bytes calldata _nftId,
        bytes calldata _subOfferId,
        bool _isWeb
    ) external;

    function cancelOfferPvP(
        bytes calldata _nftId,
        bytes calldata _subOfferId,
        address _sender,
        bool isWhiteList
    ) external returns (uint256);

    function getInforOffer(bytes calldata _indexId, bytes calldata _subOfferId)
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
        bytes calldata _indexId,
        bytes[] calldata subOffersIdParam
    ) external;

    function updateOwnerOfNFT(bytes calldata _indexId, address _user) external;

    function getInforOfferBasic(bytes calldata _indexId)
        external
        view
        returns (
            uint256,
            address,
            bytes memory
        );
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
        uint128 stanFee;
        uint128 serviceFee;
    }

    struct inforCollection {
        uint128 ratioCreator;
        uint128 ratioStan;
        uint128 maxColletionNumber;
    }

    struct Offer {
        uint256 tokenId;
        mapping(bytes => subOffer) subOffers;
        address owner;
        bytes nftID;
    }

    struct userMobile {
        address owner;
        uint256 tokenId;
    }

    struct subOffer {
        bytes subOfferId;
        address maker;
        uint256 amount;
        uint256 expirationTime;
        StateOfOffer state;
    }

    struct Listing {
        bytes ListingID;
        address Owner;
        address ownerOfNFT;
        bool isAuction;
        uint256 ExpirationTime;
        uint256 Amount;
        uint256 tokenId;
        StateOfListing state;
        bytes AuctionId;
        bytes nftId;
    }

    struct stateCollection {
        bytes id;
        uint128 currentNumber;
        uint128 maxNumber;
        uint128 ratioCreator;
        uint128 ratioStan;
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
        _offerInstance.owner = _params.owner;
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
        bytes calldata _subOfferId
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

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}