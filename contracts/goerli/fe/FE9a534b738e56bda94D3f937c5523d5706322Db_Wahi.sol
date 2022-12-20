// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Wahi {
    event NewOffer(uint listingId, uint amount, string wahiUserId);
    event NewInsertListing(
        uint initialPrice,
        LISTING_STATUS status,
        string mlsId
    );
    uint public unlockTime;
    address payable public owner;

    constructor(uint _unlockTime) payable {
        require(
            block.timestamp < _unlockTime,
            "Unlock time should be in the future"
        );

        unlockTime = _unlockTime;
        owner = payable(msg.sender);
    }

    uint listingCounter = 0;
    uint offerCounter = 0;

    enum LISTING_STATUS {
        ACTIVE,
        SOLD,
        TERMINATED
    }

    struct Listing {
        uint initialPrice;
        address payable realtor;
        uint id;
        LISTING_STATUS status;
        uint acceptedOffer;
        string mlsId;
    }

    struct Offer {
        address payable buyer;
        uint listingId;
        string wahiUserId;
        uint amount;
        uint id;
        uint occupationDate;
        bool inspection;
        bool legalTerms;
        bool preApprobation;
        bool otherCondition;
    }

    mapping(uint => address) public listingToOwner;
    mapping(uint => address) public offerToOwner;

    mapping(address => uint) ownerListingCount;
    mapping(address => uint) ownerOfferCount;

    Listing[] public listingsArray;
    Offer[] public offersArray;


    function getAllListings() public view returns (Listing[] memory) {
        return listingsArray;
    }

    function getAllOffers() public view returns (Offer[] memory) {
        return offersArray;
    }

    function getListingsCount() public view returns (uint) {
        return listingCounter;
    }

    function getOffersCount() public view returns (uint) {
        return offerCounter;
    }

    function createOffer(
        uint _listingId,
        string memory _wahiUserId,
        uint _amount,
        uint _occupationDate,
        bool _inspection,
        bool _legalTerms,
        bool _preApprobation,
        bool _otherCondition
    ) public {
        require(_amount > 0, "Initial Price should be greater than zero");

        Offer memory tempOffer = Offer(
            payable(msg.sender),
            _listingId,
            _wahiUserId,
            _amount,
            offerCounter, //id in blockchain
            _occupationDate,
            _inspection,
            _legalTerms,
            _preApprobation,
            _otherCondition
        );
        offerToOwner[offerCounter] = msg.sender;
        ownerOfferCount[msg.sender]++;
        offersArray.push(tempOffer);
        offerCounter++;

        emit NewOffer(_listingId, _amount, _wahiUserId);
    }

    function createListing(uint _initialPrice, string memory _mlsId) public {
        require(_initialPrice > 0, "Initial Price should be greater than zero");

        Listing memory tempListing = Listing(
            _initialPrice,
            payable(msg.sender),
            listingCounter, //id in blockchain
            LISTING_STATUS.ACTIVE,
            0,
            _mlsId
        );

        listingToOwner[listingCounter] = msg.sender;
        ownerListingCount[msg.sender]++;
        listingsArray.push(tempListing);
        listingCounter++;

        emit NewInsertListing(_initialPrice, LISTING_STATUS.ACTIVE, _mlsId);
    }

    function getUserListingsIds(address _owner)
        public
        view
        returns (uint[] memory)
    {
        uint[] memory result = new uint[](ownerListingCount[_owner]);
        uint counter = 0;

        for (uint i = 0; i < listingsArray.length; i++) {
            if (listingToOwner[i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }

        return result;
    }

    function getUserOffersIds(address _owner)
        public
        view
        returns (uint[] memory)
    {
        uint[] memory result = new uint[](ownerOfferCount[_owner]);
        uint counter = 0;

        for (uint i = 0; i < offersArray.length; i++) {
            if (offerToOwner[i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }

        return result;
    }

    function getOffersIdsFromListing(uint lid)
        public
        view
        returns (uint[] memory)
    {
        uint counter = 0;
         uint counterPlus = 0;


        require(
            offersArray.length != 0,
            "No offers sorry"
        );

        for (uint i = 0; i < offersArray.length; i++) {
            if (offersArray[i].listingId == lid) {
                counter++;
            }
        }

        uint[] memory result = new uint[](counter);

        for (uint i = 0; i < offersArray.length; i++) {
            if (offersArray[i].listingId == lid) {
                result[counterPlus] = offersArray[i].id;
                counterPlus++;
            }
        }

        return result;
    }

    function soldListing(uint _listingId, uint _acceptedOffer) public {
        Listing storage listingFound = listingsArray[_listingId];


        listingFound.acceptedOffer = _acceptedOffer;
        listingFound.status = LISTING_STATUS.SOLD;
    }

    function terminatedListing(uint _listingId)
        public
    {
        Listing storage listingFound = listingsArray[_listingId];

        listingFound.status = LISTING_STATUS.TERMINATED;
    }
}