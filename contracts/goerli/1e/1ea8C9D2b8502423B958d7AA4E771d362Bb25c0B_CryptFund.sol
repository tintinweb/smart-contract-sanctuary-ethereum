/**
 *Submitted for verification at Etherscan.io on 2022-10-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

error NotTheCampaignOwner();
error CreateCampaignFirst();

contract CryptFund {

    address private immutable i_owner;
    uint private constant MINIMUM_DONATION = 0.01 ether;
    uint public count = 0;
    uint public ActiveCampaignsCount = 0;


    struct Contribution {
        uint campaignId;
        address payable contributorAddress;
        uint256 donatedAmount;
        uint timestamp;
    }
    

    // Campaign data structure
    struct Campaign {
        uint campaignId;
        address payable campaignowner;
        string name;
        string description;
        uint256 targetAmount;
        uint startAt;
        uint endAt;
        uint noOfContributors;
        uint contributedAmount;
        bool claimed;
    }

    // List of all active campaigns
    Campaign[] private allCampaigns;

    // Mapping of all discontinued campaigns
    mapping(address => Campaign[]) private discontinuedCampaigns;
    mapping(uint => Campaign) private activeCampaigns;

    // Mapping of all conntributors
    mapping(address => Contribution[]) private contributorAddressToContributions;

    mapping(address => uint) private addressToId;
    mapping(address => bool) private haveActiveCampaign;


    constructor() {
        i_owner = msg.sender;
    }


    function createCampaign( string memory _name, string memory _desc, uint256 _target, uint _startAt, uint _endAt ) external {
        require(haveActiveCampaign[msg.sender] == false); // one person can create only one campaign
        require(_startAt >= block.timestamp, "start at < now");
        require(_endAt >= _startAt, "end at < start at");
        require(_endAt <= block.timestamp + 60 days, "end at > max duration");

        count += 1;
        ActiveCampaignsCount += 1;

        activeCampaigns[count] = 
            Campaign({
                campaignId: count,
                campaignowner: payable(msg.sender),
                name: _name,
                description: _desc,
                targetAmount: _target,
                startAt: _startAt,
                endAt: _endAt,
                noOfContributors: 0,
                contributedAmount: 0,
                claimed: false
            });

        allCampaigns.push(
            Campaign({
                campaignId: count,
                campaignowner: payable(msg.sender),
                name: _name,
                description: _desc,
                targetAmount: _target,
                startAt: _startAt,
                endAt: _endAt,
                noOfContributors: 0,
                contributedAmount: 0,
                claimed: false
            })
        );


        
        addressToId[msg.sender] = count;
        haveActiveCampaign[msg.sender] = true;
    }

    function discontinueCampaign() external {

        require(haveActiveCampaign[msg.sender], "First create a campaign");
        require(msg.sender == allCampaigns[addressToId[msg.sender]].campaignowner, "Not Campaign owner");
        require(block.timestamp <= allCampaigns[addressToId[msg.sender]].startAt, "Campaign has already started");
        require(block.timestamp >= allCampaigns[addressToId[msg.sender]].endAt, "Campaign has already ended");


        discontinuedCampaigns[msg.sender].push(activeCampaigns[addressToId[msg.sender]]);
        delete activeCampaigns[addressToId[msg.sender]];
        haveActiveCampaign[msg.sender] = false;

        ActiveCampaignsCount = ActiveCampaignsCount - 1;
    }

    function contributeToCampaign(uint _id) external payable {
    
        require(activeCampaigns[_id].campaignowner != address(0) ," Invalid Campaign");
        require(block.timestamp >= allCampaigns[_id].startAt, "Campaign has not started yet");
        require(block.timestamp <= allCampaigns[_id].endAt, "Campaign has ended");
        require(msg.value >= MINIMUM_DONATION, 'Contribution amount is too low !');


        activeCampaigns[_id].contributedAmount += msg.value;

        contributorAddressToContributions[msg.sender].push(
            Contribution({
                campaignId: _id,
                contributorAddress: payable(msg.sender),
                donatedAmount: msg.value,
                timestamp: block.timestamp
            })
        );
    }

    function withdrawAmount() external {

        require(haveActiveCampaign[msg.sender], "First create a campaign");
        require(msg.sender == allCampaigns[addressToId[msg.sender]].campaignowner , "Not Campaign owner");
        require(block.timestamp >= allCampaigns[addressToId[msg.sender]].endAt, "Campaign has not ended");
        require(allCampaigns[addressToId[msg.sender]].contributedAmount >= allCampaigns[addressToId[msg.sender]].targetAmount, "Contribution amount is too low !");
        require(!allCampaigns[addressToId[msg.sender]].claimed, "Already claimed");


        address payable onr = allCampaigns[addressToId[msg.sender]].campaignowner;
        onr.transfer(allCampaigns[addressToId[msg.sender]].contributedAmount);

        allCampaigns[addressToId[msg.sender]].claimed = true;
    }

    




    // getter Functions
    function getAllCampaigns() external view returns (Campaign[] memory) {
        return allCampaigns;
    }

    function getMyActiveCampaign() external view returns (Campaign memory) {
        require(!(haveActiveCampaign[msg.sender]), "No active campaigns found");
        return activeCampaigns[addressToId[msg.sender]];
    }

    function getMyDiscontinuedCampaigns() external view returns (Campaign[] memory) {
        return discontinuedCampaigns[msg.sender];
    }

    function getMyContributions() external view returns (Contribution[] memory) {
        return contributorAddressToContributions[msg.sender];
    }

    function getMinimumDonation() external pure returns (uint) {
        return MINIMUM_DONATION;
    }

    function getContractBalance() public view returns(uint256){
        return address(this).balance;
    }

    function getNumberOfCampaignsCreated() external view returns (uint) {
        return allCampaigns.length;
    }

    function getNumberOfActiveCampaigns() external view returns (uint) {
        return ActiveCampaignsCount;
    }
}