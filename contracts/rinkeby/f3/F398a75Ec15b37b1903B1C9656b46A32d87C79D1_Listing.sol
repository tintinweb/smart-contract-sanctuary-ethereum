// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./interfaces/IStanNFT.sol";
import "./library/AuctionLibrary.sol";

contract Listing {
    mapping(bytes => AuctionLibrary.Listing) public Listings;
    IStanNFT public stanNFT;
    address private owner;
    bytes constant NULL = "";
    address public auctionAddress;

    modifier onlyOwner() {
        if (msg.sender != owner) revert InvalidOwner();
        _;
    }

    modifier onlyAuction() {
        if (auctionAddress != msg.sender) revert InvalidOwner();
        _;
    }

    constructor(address _stanNFT) {
        owner = msg.sender;
        stanNFT = IStanNFT(_stanNFT);
    }

    function setAuction(address _auction) external onlyOwner {
        if (_auction == address(0)) revert InvalidAddress();
        auctionAddress = _auction;
    }

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
            listing.tokenId,
            listing.isAuction,
            listing.state,
            listing.nftId
        );
    }

    function processCancelListing(bytes calldata _listingId, bool _isWeb)
        private
    {
        if (
            Listings[_listingId].state == AuctionLibrary.StateOfListing.INACTIVE
        ) revert AlreadyInActive();

        Listings[_listingId].state = AuctionLibrary.StateOfListing.INACTIVE;
        if (_isWeb)
            stanNFT.updateOwnerNFTAndTransferNFT(
                address(stanNFT),
                Listings[_listingId].Owner,
                Listings[_listingId].tokenId
            );
    }

    function listingNFTFixedPrice(
        bytes memory _listingId,
        uint256 _amount,
        uint256 _tokenId,
        address _sender,
        uint256 _expirationTime,
        bytes memory _nftId,
        bool _isWeb
    ) external onlyAuction {
        AuctionLibrary.Listing memory newInstance = AuctionLibrary.Listing(
            _listingId,
            _sender,
            address(stanNFT),
            false,
            _expirationTime,
            _amount,
            _tokenId,
            AuctionLibrary.StateOfListing.ACTIVE,
            NULL,
            _nftId
        );
        Listings[_listingId] = newInstance;
        stanNFT.setPriceNFT(_tokenId, _amount);
        stanNFT.updateTokenToListing(_listingId, _tokenId);
        if (_isWeb)
            stanNFT.updateOwnerNFTAndTransferNFT(
                _sender,
                address(stanNFT),
                _tokenId
            );
    }

    function listingNFTAuction(
        bytes memory _auctionId,
        uint256 _amount,
        uint256 _tokenId,
        address _sender,
        uint256 _expirationTime,
        bytes memory _nftId,
        bool _isWeb
    ) external onlyAuction returns (address) {
        AuctionLibrary.Listing memory newInstance = AuctionLibrary.Listing(
            _auctionId,
            _sender,
            address(stanNFT),
            true,
            _expirationTime,
            _amount,
            _tokenId,
            AuctionLibrary.StateOfListing.ACTIVE,
            _auctionId,
            _nftId
        );
        Listings[_auctionId] = newInstance;
        Listings[_auctionId].state = AuctionLibrary.StateOfListing.ACTIVE;

        if (_isWeb)
            stanNFT.updateOwnerNFTAndTransferNFT(
                _sender,
                address(stanNFT),
                _tokenId
            );

        return _sender;
    }

    function cancelListingFixedPrice(bytes calldata _listingId, bool _isWeb)
        external
        onlyAuction
        returns (uint256)
    {
        processCancelListing(_listingId, _isWeb);

        uint256 tokenId = Listings[_listingId].tokenId;
        return tokenId;
    }

    function cancelListingAuction(bytes calldata _listingId, bool _isWeb)
        external
        onlyAuction
    {
        processCancelListing(_listingId, _isWeb);
    }

    function updateListing(
        bytes calldata _listingId,
        AuctionLibrary.paramListing memory params
    ) external onlyAuction {
        Listings[_listingId].ownerOfNFT = params.ownerOfNFT;
        Listings[_listingId].state = params.state;
    }

    function expiredListing(bytes[] calldata listingIds, bool _isWeb)
        external
        onlyAuction
    {
        for (uint256 i = 0; i < listingIds.length; ) {
            Listings[listingIds[i]].state = AuctionLibrary
                .StateOfListing
                .EXPIRED;

            unchecked {
                ++i;
            }
        }
        if (_isWeb)
            for (uint256 i = 0; i < listingIds.length; ) {
                stanNFT.updateOwnerNFTAndTransferNFT(
                    address(stanNFT),
                    Listings[listingIds[i]].Owner,
                    Listings[listingIds[i]].tokenId
                );

                unchecked {
                    ++i;
                }
            }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

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
pragma solidity 0.8.4;

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
error InvalidAddress();

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

    struct userFund {
        address maker;
        uint256 bidnumber;
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
        uint256 max = 0;
        uint256 winnerIndex = 0;

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
pragma solidity 0.8.4;

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