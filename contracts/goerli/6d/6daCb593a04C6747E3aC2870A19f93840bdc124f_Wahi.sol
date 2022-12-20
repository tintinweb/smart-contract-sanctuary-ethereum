// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Wahi {
    event NewOffer(uint256 listingId, uint256 amount, string wahiUserId);
    event NewInsertListing(
        uint256 initialPrice,
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

    uint256 listingCounter = 0;
    uint256 offerCounter = 0;

    enum LISTING_STATUS {
        ACTIVE,
        SOLD,
        TERMINATED
    }

    struct Listing {
        uint256 initialPrice;
        address payable realtor;
        uint256 id;
        LISTING_STATUS status;
        uint256 acceptedOffer;
        string mlsId;
    }

    struct Offer {
        address payable buyer;
        uint256 listingId;
        string wahiUserId;
        uint256 amount;
        uint256 id;
        uint256 occupationDate;
        bool inspection;
        bool legalTerms;
        bool preApprobation;
        bool otherCondition;
    }

    mapping(uint256 => address) public listingToOwner;
    mapping(uint256 => address) public offerToOwner;

    mapping(address => uint256) ownerListingCount;
    mapping(address => uint256) ownerOfferCount;

    Listing[] public listingsArray;
    Offer[] public offersArray;

function stringsEquals(string memory s1, string memory s2) private pure returns (bool) {
    bytes memory b1 = bytes(s1);
    bytes memory b2 = bytes(s2);
    uint256 l1 = b1.length;
    if (l1 != b2.length) return false;
    for (uint256 i=0; i<l1; i++) {
        if (b1[i] != b2[i]) return false;
    }
    return true;
}

    function getAllListings() public view returns (Listing[] memory) {
        return listingsArray;
    }

    function getAllOffers() public view returns (Offer[] memory) {
        return offersArray;
    }

    function getListingsCount() public view returns (uint256) {
        return listingCounter;
    }

    function getOffersCount() public view returns (uint256) {
        return offerCounter;
    }

    function createOffer(
        uint256 _listingId,
        string memory _wahiUserId,
        uint256 _amount,
        uint256 _occupationDate,
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
        offersArray.push(tempOffer);
        offerToOwner[offerCounter] = msg.sender;
        ownerOfferCount[msg.sender]++;
        offerCounter++;

        emit NewOffer(_listingId, _amount, _wahiUserId);
    }

    function createListing(uint256 _initialPrice, string memory _mlsId) public {
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
        returns (uint256[] memory)
    {
        uint256[] memory result = new uint256[](ownerListingCount[_owner]);
        uint256 counter = 0;

        for (uint256 i = 0; i < listingsArray.length; i++) {
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
        returns (uint256[] memory)
    {
        uint256[] memory result = new uint256[](ownerOfferCount[_owner]);
        uint256 counter = 0;

        for (uint256 i = 0; i < offersArray.length; i++) {
            if (offerToOwner[i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }

        return result;
    }

    function getOffersIdsFromListing(uint256 lid)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory result;
        uint256 counter = 0;

        for (uint256 i = 0; i < offersArray.length; i++) {
            if (offersArray[i].listingId == lid) {
                result[counter] = offersArray[i].id;
                counter++;
            }
        }

        return result;
    }

    function soldListing(uint256 _listingId, uint256 _acceptedOffer) public {
        Listing storage listingFound = listingsArray[_listingId];

        require(listingFound.status == LISTING_STATUS.SOLD, "Already SOLD");
        require(
            listingFound.status == LISTING_STATUS.TERMINATED,
            "Cannot sold because listing is TERMINATED"
        );

        listingFound.acceptedOffer = _acceptedOffer;
        listingFound.status = LISTING_STATUS.SOLD;
    }

    function terminatedListing(uint256 _listingId, uint256 acceptedOffer)
        public
    {
        Listing storage listingFound = listingsArray[_listingId];

        require(
            listingFound.status == LISTING_STATUS.TERMINATED,
            "Already TERMINATED"
        );
        require(
            listingFound.status == LISTING_STATUS.SOLD,
            "Cannot TERMINATED because it's already SOLD"
        );

        listingFound.status = LISTING_STATUS.TERMINATED;
    }
}