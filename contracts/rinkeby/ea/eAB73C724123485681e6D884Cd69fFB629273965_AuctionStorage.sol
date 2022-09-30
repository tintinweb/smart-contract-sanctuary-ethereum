// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./interfaces/IOffer.sol";
import "./library/AuctionLibrary.sol";

contract AuctionStorage {
    using AuctionLibrary for AuctionLibrary.Offer;
    using AuctionLibrary for AuctionLibrary.autionStruct;

    mapping(bytes => AuctionLibrary.autionStruct) private auctionIdToAuction;
    address private owner;
    bytes constant NULL = "";
    address public auctionAddress;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert InvalidOwner();
        _;
    }

    modifier onlyAuction() {
        if (auctionAddress != msg.sender) revert InvalidOwner();
        _;
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

    function setAuction(address _auction) external onlyOwner {
        if (_auction == address(0)) revert InvalidAddress();
        auctionAddress = _auction;
    }

    function getInforAuction(bytes calldata _auctionId)
        external
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
            _auctionId
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

    function getInforSubOffer(
        bytes calldata _auctionId,
        bytes calldata _subOfferId
    )
        external
        view
        returns (
            address,
            uint256,
            uint256
        )
    {
        AuctionLibrary.autionStruct
            storage auctionInstance = auctionIdToAuction[_auctionId];
        return (
            auctionInstance.offers.subOffers[_subOfferId].maker,
            auctionInstance.offers.tokenId,
            auctionInstance.offers.subOffers[_subOfferId].amount
        );
    }

    function getInforOfferAuction(
        bytes memory _indexId,
        bytes memory _subOfferId
    )
        external
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

    function backFeeToUserFund(bytes memory _auctionId)
        external
        view
        onlyAuction
        returns (AuctionLibrary.userFund[] memory)
    {
        AuctionLibrary.Offer storage _offerInstance = auctionIdToAuction[
            _auctionId
        ].offers;

        uint256 length = auctionIdToAuction[_auctionId].offerIds.length;
        AuctionLibrary.userFund[]
            memory userFunds = new AuctionLibrary.userFund[](length);

        for (uint256 i = 0; i < length; ) {
            if (
                _offerInstance
                    .subOffers[auctionIdToAuction[_auctionId].offerIds[i]]
                    .state == AuctionLibrary.StateOfOffer.CANCELLED
            ) {
                address maker = _offerInstance
                    .subOffers[auctionIdToAuction[_auctionId].offerIds[i]]
                    .maker;
                AuctionLibrary.userFund memory instance = AuctionLibrary
                    .userFund(
                        maker,
                        auctionIdToAuction[_auctionId].userToBidnumber[maker]
                    );
                userFunds[i] = instance;
            }
            unchecked {
                ++i;
            }
        }

        return userFunds;
    }

    function changeStateOffers(bytes memory _auctionId, address _exceptionist)
        external
        onlyAuction
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

    function listingNFTAuction(
        bytes memory _auctionId,
        uint256 _tokenId,
        address _ownerOfListing
    ) external onlyAuction {
        AuctionLibrary.autionStruct
            storage auctionInstance = auctionIdToAuction[_auctionId];
        auctionInstance.autionId = _auctionId;
        auctionInstance.tokenId = _tokenId;
        auctionInstance.state = AuctionLibrary.StateOfAution.ACTIVE;
        auctionInstance.owner = _ownerOfListing;
    }

    function placeBidAuction(
        bytes memory _subOfferId,
        bytes memory _auctionId,
        AuctionLibrary.paramOffer memory _params,
        uint256 _amount,
        address maker
    ) external onlyAuction {
        AuctionLibrary.autionStruct
            storage auctionInstance = auctionIdToAuction[_auctionId];
        auctionInstance.offers.saveOffer(_params);
        auctionInstance.offerIds.push(_subOfferId);
        auctionInstance.userToBidnumber[maker] = _amount;
        auctionInstance.offerIdToIndex[_subOfferId] =
            auctionInstance.offerIds.length -
            1;
    }

    function acceptOfferAuction(
        bytes memory _auctionId,
        bytes memory _subOfferId
    ) external onlyAuction {
        AuctionLibrary.autionStruct
            storage auctionInstance = auctionIdToAuction[_auctionId];
        auctionInstance.state = AuctionLibrary.StateOfAution.DONE;
        auctionInstance.offers.subOffers[_subOfferId].state = AuctionLibrary
            .StateOfOffer
            .DONE;
    }

    function cancelOfferAuction(
        bytes memory _auctionId,
        bytes calldata _subOfferId
    ) external onlyAuction {
        AuctionLibrary.autionStruct
            storage auctionInstance = auctionIdToAuction[_auctionId];
        address maker = auctionInstance.offers.subOffers[_subOfferId].maker;

        if (auctionInstance.offerIds.length == 0) revert InvalidOfferAmount();
        auctionInstance.offers.processCancel(_subOfferId);
        auctionInstance.userToBidnumber[maker] = 0;
    }

    function expiredOffer(
        bytes memory _indexId,
        bytes[] calldata subOffersIdParam
    ) external onlyAuction {
        auctionIdToAuction[_indexId].offers.processChangeExpired(
            subOffersIdParam
        );
    }

    function expiredListing(bytes[] memory listingIds) external onlyAuction {
        for (uint256 i = 0; i < listingIds.length; ) {
            auctionIdToAuction[listingIds[i]].state = AuctionLibrary
                .StateOfAution
                .EXPIRED;

            unchecked {
                ++i;
            }
        }
    }

    function finishAuction(bytes memory _auctionId)
        external
        onlyAuction
        returns (address, bytes memory)
    {
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

        return (winner, winnerSubOfferId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

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