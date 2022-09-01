// SPDX-License-Identifier : MIT
pragma solidity ^0.8.0;

contract HelpingHands {
    uint256 listingNonce = 0;

    // structs
    struct ListingData {
        uint256 listingId;
        address needer;
        uint256 amountNeeded;
        string description;
        string contactInfo;
        uint256 amountCollected;
        uint256 upvoteCount;
        uint256 downvoteCount;
    }

    struct HonestyVotes {
        uint256 listingId;
        address voter;
        bool upvote;
        string voteComment;
    }

    // maps
    mapping(uint256 => ListingData) public idToListingData;
    mapping(uint256 => mapping(address => HonestyVotes))
        public idToHonestyVotes;

    // private functions to write on blockchain
    function upvote(uint256 listingId, string memory voteComment) private {
        HonestyVotes memory HV = HonestyVotes(
            listingId,
            msg.sender,
            true,
            voteComment
        );
        idToHonestyVotes[listingId][msg.sender] = HV;
    }

    function downvote(uint256 listingId, string memory voteComment) private {
        HonestyVotes memory HV = HonestyVotes(
            listingId,
            msg.sender,
            false,
            voteComment
        );
        idToHonestyVotes[listingId][msg.sender] = HV;
    }

    // view functions
    function getListingAt(uint256 listingId)
        public
        view
        returns (ListingData memory)
    {
        return idToListingData[listingId];
    }

    function getListingCount() public view returns (uint256) {
        return listingNonce;
    }

    function getVote(uint256 listingId, address voter)
        public
        view
        returns (HonestyVotes memory)
    {
        return idToHonestyVotes[listingId][voter];
    }

    // Modifiers

    modifier onlyNeeder(uint256 listingId) {
        require(
            idToListingData[listingId].needer == msg.sender,
            "Only needer can edit contact info!!"
        );
        _;
    }

    // public function
    function listNeeder(
        address needer,
        uint256 amountNeeded,
        string memory description,
        string memory contactInfo
    ) public {
        ListingData memory LD = ListingData(
            listingNonce,
            needer,
            amountNeeded,
            description,
            contactInfo,
            0,
            0,
            0
        );
        idToListingData[listingNonce] = LD;
        listingNonce += 1;
    }

    function editContactInfo(uint256 listingId, string memory contactInfo)
        public
        onlyNeeder(listingId)
    {
        idToListingData[listingId].contactInfo = contactInfo;
    }

    function voteListing(
        uint256 listingId,
        bool vote,
        string memory voteComment
    ) public {
        require(
            idToListingData[listingId].needer != msg.sender,
            "You cannot vote yourself!!"
        );
        require(
            idToHonestyVotes[listingId][msg.sender].voter != address(0x0),
            "Already Voted!!"
        );
        if (vote) {
            upvote(listingId, voteComment);
        } else {
            downvote(listingId, voteComment);
        }
    }

    //payable public function
    function donate(uint256 listingId, uint256 amount) public payable {
        require(
            idToListingData[listingId].amountCollected <
                idToListingData[listingId].amountNeeded,
            "Required amount reached!!"
        );
        require(listingId >= 0 && listingId < listingNonce, "Invalid Id!!");
        payable(address(this)).transfer(amount);
        idToListingData[listingId].amountCollected += amount;
    }

    function withdraw(uint256 listingId) public payable onlyNeeder(listingId) {
        require(
            idToListingData[listingId].amountCollected >=
                idToListingData[listingId].amountNeeded
        );
        require(listingId >= 0 && listingId < listingNonce, "Invalid Id!!");
        payable(msg.sender).transfer(
            idToListingData[listingId].amountCollected
        );
    }
}