// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// best solution for no backend. Everything works, but it required the second
// sctruct that is there to show data from the first one and be iterable.

contract CrowdfundingCampaign {
    address payable public deployer;

    constructor() {
        deployer = payable(msg.sender);
    }

    struct Campaign {
        uint256 campaignID;
        address payable owner;
        string title;
        string description;
        string image;
        uint256 duration;
        uint256 raisingGoal; //you called it target
        uint256 deadline;
        uint256 amountCollected;
        mapping(address => uint256) donators;
    }

    mapping(uint256 => Campaign) public campaigns;

    event LogCampaign(
        uint256 campaignID,
        address payable owner,
        string title,
        string description,
        string image,
        uint256 duration,
        uint256 raisingGoal,
        uint256 deadline,
        uint256 amountCollected
    );

    uint256 public numberOfCampaigns = 0;

    function createCampaign(
        uint256 _duration,
        uint256 _raisingGoal,
        string memory _title,
        string memory _description,
        string memory _image
    ) public returns (uint256) {
        // Check for past campaigns that have passed deadline and have no donations
        for (uint256 i = 0; i < numberOfCampaigns; i++) {
            Campaign storage campaign = campaigns[i];
            if (
                block.timestamp > campaign.deadline &&
                campaign.amountCollected == 0
            ) {
                delete campaigns[i];
            } // delete old and empty campaignes
        }

        uint256 _campaignID = ++numberOfCampaigns; //assign campaignID
        uint256 _deadline = block.timestamp + _duration; //calculate deadline based on duration (better, than taking deadline directly, since it doesn't need checks for past time)

        campaigns[_campaignID].campaignID = _campaignID;
        campaigns[_campaignID].owner = payable(msg.sender);
        campaigns[_campaignID].title = _title;
        campaigns[_campaignID].description = _description;
        campaigns[_campaignID].image = _image;
        campaigns[_campaignID].duration = _duration;
        campaigns[_campaignID].raisingGoal = _raisingGoal;
        campaigns[_campaignID].deadline = _deadline;
        campaigns[_campaignID].amountCollected = 0;

        emit LogCampaign(
            campaigns[_campaignID].campaignID,
            campaigns[_campaignID].owner,
            campaigns[_campaignID].title,
            campaigns[_campaignID].description,
            campaigns[_campaignID].image,
            campaigns[_campaignID].duration,
            campaigns[_campaignID].raisingGoal,
            campaigns[_campaignID].deadline,
            campaigns[_campaignID].amountCollected
        );

        return numberOfCampaigns; // <-- get total amount of campaigns, so next one will have next ID.
    }

    // function to add ETH to a specific campaign, checked if it's still ongoing, stores donator and amount of ETH
    function donateToCampaign(uint256 _campaignID) public payable {
        Campaign storage campaign = campaigns[_campaignID];
        require(campaign.campaignID != 0, "Campaign does not exist.");
        require(
            block.timestamp < campaign.deadline,
            "Campaign deadline has passed."
        );
        campaign.amountCollected += msg.value; // <-- transfer msg.value here and add it to amountCollected
        campaign.donators[msg.sender] += msg.value; // <-- store msg.value here linked to a donator address, so we can use it for the refund function later
    }

    // function to return ETH to donator on calling it
    function refund(uint256 _campaignID) public {
        Campaign storage campaign = campaigns[_campaignID];
        require(campaign.campaignID != 0, "Campaign does not exist.");
        require(
            campaign.amountCollected < campaign.raisingGoal,
            "Campaign goal has been reached."
        );
        require(
            campaign.donators[msg.sender] > 0,
            "You have not contributed to this campaign."
        );
        // require(block.timestamp > campaign.deadline, "Campaign deadline has not passed."); // <-- optional function to refund only if campaign fails

        address payable sender = payable(msg.sender); // <-- assign sender value

        // Refund the caller's contribution
        uint256 amount = campaign.donators[msg.sender]; // <-- get the transfer value from mapping storage
        (bool sent, ) = sender.call{value: amount}(""); // <-- check if the transfer was successful, return 'sent' on success
        require(sent, "ETH Refund failed"); // <-- if no 'sent', return an error
        campaign.donators[msg.sender] = 0; // <-- set contribution to 0
        campaign.amountCollected -= amount; // <-- decrease campaigns 'amountCollected', delete campaign when all funds returned
        if (
            campaign.amountCollected == 0 && block.timestamp > campaign.deadline
        ) {
            delete campaigns[_campaignID];
        }
    }

    function withdrawFunds(uint256 _campaignID) public {
        // <-- only available for Campaign creator, if funds were fully raised

        Campaign storage campaign = campaigns[_campaignID];
        require(campaign.campaignID != 0, "Campaign does not exist.");
        require(
            campaign.amountCollected >= campaign.raisingGoal,
            "Campaign goal has not been reached."
        ); // <-- check fund goal
        require(
            msg.sender == campaign.owner,
            "Only the campaign creator can withdraw funds."
        ); // <-- check caller's adress, fail if not owner

        uint256 commission = (campaign.amountCollected * 5) / 100; // <-- calculate comission
        uint256 withdrawalAmount = campaign.amountCollected - commission; // <-- calculate withdrawalAmount
        (bool sent, ) = campaign.owner.call{value: withdrawalAmount}(""); // <-- withdraw funds only for called Campaign, returns 'sent' on success
        require(sent, "ETH Withdrawal failed"); // <-- if no 'sent', return an error

        (bool commissioned, ) = deployer.call{value: commission}(""); // <-- same but for comission
        require(commissioned, "Commission transfer failed");

        delete campaigns[_campaignID]; // <-- remove our withdrawn Campaign from our mapping storage
    }

    struct CampaignView {
        uint256 campaignID;
        address owner;
        uint256 duration;
        uint256 raisingGoal;
        uint256 deadline;
        uint256 amountCollected;
        string title;
        string description;
        string image;
    }

    //function to get all created campaigns via CampaignView. Doesn't give info about donators, that's why it works for iteration (no nested mapping)
    function getAllCampaigns() public view returns (CampaignView[] memory) {
        CampaignView[] memory result = new CampaignView[](numberOfCampaigns);
        uint256 i = 0;
        for (uint256 j = 0; j <= numberOfCampaigns; j++) {
            if (campaigns[j].campaignID != 0) {
                result[i].campaignID = campaigns[j].campaignID;
                result[i].owner = campaigns[j].owner;
                result[i].duration = campaigns[j].duration;
                result[i].raisingGoal = campaigns[j].raisingGoal;
                result[i].deadline = campaigns[j].deadline;
                result[i].amountCollected = campaigns[j].amountCollected;
                result[i].title = campaigns[j].title;
                result[i].description = campaigns[j].description;
                result[i].image = campaigns[j].image;
                i++;
            }
        }
        return result;
    }

    function getCurrentTime() public view returns (uint256) {
        // <-- function to get a current time, used that only for testing
        return block.timestamp;
    }
}