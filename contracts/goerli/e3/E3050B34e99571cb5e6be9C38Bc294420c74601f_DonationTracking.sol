// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract DonationTracking{

    struct DonationEvent{
        address owner;
        string ownerName;  
        string title;
        string description;
        uint256 targetAmount;
        uint256 deadline; 
        uint256 totalDonations;
        string image;
        address[] donors;
        uint256[] donations; 
    }

    mapping(uint256 => DonationEvent) public donationEvents;

    uint256 public numberOfDonationEvents = 0;

    //function for creating a donationEvent
    function createDonationEvent(address _owner, string memory _ownerName, string memory _title, string memory _description, uint256 _targetAmount, uint256 _deadline, string memory _image) public returns (uint256) {
        DonationEvent storage donationEvent = donationEvents[numberOfDonationEvents];
        
        //for checking the requirements of the function
        require(donationEvent.deadline < block.timestamp, "The deadline should be a date in the future");
        require(donationEvent.owner != address(0), "Owner address cannot be zero");
        require(donationEvent.targetAmount > 0, "Target amount must be greater than zero");
       
        donationEvent.owner = _owner;
        donationEvent.ownerName = _ownerName;
        donationEvent.title = _title;
        donationEvent.description = _description;
        donationEvent.targetAmount = _targetAmount;
        donationEvent.deadline = _deadline;
        donationEvent.image = _image;

        numberOfDonationEvents++;

        // substract 1 because numberOfDonationEvents is incremented after the creation of the donationEvent for the next donationEvent
        // so the id of the donationEvent is numberOfDonationEvents-1 for the current donationEvent
        return numberOfDonationEvents-1;
    }

    //function for donating to a donationEvent (making a donation)
    function donateToDonationEvent(uint256 _donationEventId) public payable {
        require(msg.value > 0, "Donation amount must be greater than zero");

        uint256 amount = msg.value;

        DonationEvent storage donationEvent = donationEvents[_donationEventId];

        require(donationEvent.owner != address(0), "DonationEvent does not exist");
        require(donationEvent.deadline > block.timestamp, "DonationEvent deadline has passed");

        donationEvent.donors.push(msg.sender);
        donationEvent.donations.push(amount);

        (bool sent,)= payable(donationEvent.owner).call{value: amount}("");

        if(sent){
            donationEvent.totalDonations += amount;
        }

    }

    //function for getting the donors and donations of a donationEvent
    function getDonors(uint256 _donationEventId) view public returns (address[] memory, uint256[]memory) {
        return (donationEvents[_donationEventId].donors, donationEvents[_donationEventId].donations);
    }

    //function for getting all the donationEvents
    function getDonationEvents() public view returns (DonationEvent[] memory) {
        DonationEvent[] memory allDonationEvents = new DonationEvent[](numberOfDonationEvents);

        for(uint i = 0; i < numberOfDonationEvents; i++){
            DonationEvent storage item = donationEvents[i];
            allDonationEvents[i] = item;
        }

        return allDonationEvents;
    }

}