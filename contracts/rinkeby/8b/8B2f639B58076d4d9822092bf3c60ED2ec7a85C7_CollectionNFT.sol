// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IStanNFT.sol";
import "./library/AuctionLibrary.sol";

error AlreadyInUsed();
error OverMaxCollection();

contract CollectionNFT {
    IStanNFT public stanNFT;
    mapping(bytes => bool) public collectionId;
    mapping(uint256 => bytes) public tokenIdToCollectionId;
    mapping(bytes => AuctionLibrary.stateCollection) public _collectionNFT;
    AuctionLibrary.inforCollection public inforCollection;
    address public owner;

    modifier OnlyStanOrOwner() {
        if (owner != msg.sender && msg.sender != address(stanNFT))
            revert InvalidOwner();
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert InvalidOwner();
        _;
    }

    event STAN_EVENT(
        bytes requestId,
        AuctionLibrary.FunctionName nameFunction,
        bool platForm,
        uint256 tokenId
    );

    constructor(address _stanNFT) {
        owner = msg.sender;
        stanNFT = IStanNFT(_stanNFT);
    }

    function setStanNFT(address _stanNFT) external onlyOwner {
        stanNFT = IStanNFT(_stanNFT);
    }

    function setInforCollection(
        uint256 _ratioCreator,
        uint256 _ratioStan,
        uint160 _maxColletionNumber
    ) external onlyOwner {
        AuctionLibrary.inforCollection memory InforCollection = AuctionLibrary
            .inforCollection(_ratioCreator, _ratioStan, _maxColletionNumber);
        inforCollection = InforCollection;
    }

    function getTokenIdToCollectionId(uint256 _tokenId)
        external
        view
        returns (bytes memory)
    {
        return tokenIdToCollectionId[_tokenId];
    }

    function processCreatingCollection(
        bytes memory _requestId,
        address _owner,
        bytes memory _collectionId,
        bool _isWeb
    ) private {
        collectionId[_collectionId] = true;
        _collectionNFT[_collectionId].id = _collectionId;
        _collectionNFT[_collectionId].owner = _owner;
        _collectionNFT[_collectionId].maxNumber = inforCollection
            .maxColletionNumber;
        _collectionNFT[_collectionId].ratioCreator = inforCollection
            .ratioCreator;
        _collectionNFT[_collectionId].ratioStan = inforCollection.ratioStan;

        emit STAN_EVENT(
            _requestId,
            AuctionLibrary.FunctionName.CREATE_COLLECTION,
            _isWeb,
            0
        );
    }

    function createCollection(
        bytes memory _requestId,
        bytes memory _collectionId,
        bool _isWeb
    ) external {
        if (collectionId[_collectionId] == true) revert AlreadyInUsed();
        processCreatingCollection(
            _requestId,
            msg.sender,
            _collectionId,
            _isWeb
        );
    }

    function createCollectionByStan(
        bytes memory _requestId,
        address _to,
        bytes memory _collectionId,
        bool _isWeb
    ) external onlyOwner {
        if (collectionId[_collectionId] == true) revert AlreadyInUsed();
        processCreatingCollection(_requestId, _to, _collectionId, _isWeb);
    }

    function addNFTtoCollection(
        bytes memory _requestId,
        bytes memory _idCollection,
        uint256 _tokenId,
        address _creator,
        bool _isWeb
    ) external OnlyStanOrOwner {
        if (
            _collectionNFT[_idCollection].currentNumber >
            inforCollection.maxColletionNumber
        ) revert OverMaxCollection();

        _collectionNFT[_idCollection].NFT[_tokenId] = _tokenId;
        _collectionNFT[_idCollection].creator[_tokenId] = _creator;
        _collectionNFT[_idCollection].currentNumber += 1;
        tokenIdToCollectionId[_tokenId] = _idCollection;

        emit STAN_EVENT(
            _requestId,
            AuctionLibrary.FunctionName.CREATE_COLLECTION,
            _isWeb,
            0
        );
    }

    function updateOwnerNFT(
        bytes memory _idCollection,
        address _from,
        address _to
    ) external OnlyStanOrOwner {
        delete _collectionNFT[_idCollection].currentOwnerNFT[_from];
        _collectionNFT[_idCollection].currentOwnerNFT[_to] = _to;
    }

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
            address _owner,
            uint256 nft,
            address currentOwnerNFT
        )
    {
        return (
            _collectionNFT[_idCollection].ratioCreator,
            _collectionNFT[_idCollection].ratioStan,
            _collectionNFT[_idCollection].creator[_nft],
            _collectionNFT[_idCollection].owner,
            _collectionNFT[_idCollection].NFT[_nft],
            _collectionNFT[_idCollection].currentOwnerNFT[_currentOwnerNFT]
        );
    }
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