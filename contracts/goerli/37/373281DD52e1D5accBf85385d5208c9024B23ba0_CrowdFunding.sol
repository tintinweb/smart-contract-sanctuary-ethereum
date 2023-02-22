// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/*//////////////////////////////////////////////////////////////   
                        Errors
 //////////////////////////////////////////////////////////////*/
error createCampaign_InvalidDeadline();
error donateToCampaigns_DonationFailed();

contract CrowdFunding {

/*//////////////////////////////////////////////////////////////   
                        Variables
 //////////////////////////////////////////////////////////////*/
    // Campaign "Object"
    struct Campaign {
        address owner; 
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donators; //- find better alternative than array
        uint256[] donations; //- find better alternative than array
    }

    // Mapping of ID # to Campaign
    mapping(uint256 => Campaign) public campaigns; //- find better alternative than array ??

    // Number Of Campaigns 
    uint256 public numOfCampaigns = 0;

    //- Change to external ?
    function createCampaign(address _owner, string memory _title, string memory _description, uint256 _target, uint256 _deadline, string memory _image) public returns (uint256){
        Campaign storage campaign  = campaigns[numOfCampaigns];

        if(block.timestamp > campaign.deadline) { revert createCampaign_InvalidDeadline();}  //- Why isnt this first?

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;

        //Increament number of Campaigns
        numOfCampaigns++;

        // ID # of newly created campaign
        return numOfCampaigns - 1;

    }

    //- Change to external ?
    function donateToCampaigns(uint256 _id) public payable {
        uint256 amount = msg.value;

        Campaign storage campaign = campaigns[_id];

        campaign.donators.push(payable(msg.sender));
        campaign.donations.push(amount);

        //Send Donation to campaign Owner
        (bool sent,) = payable(campaign.owner).call{value: amount}("");

        // Makes sure Donation went thru
        if(!sent) {revert donateToCampaigns_DonationFailed();}

        // Update collect amount
        if(sent) {
            campaign.amountCollected = campaign.amountCollected + amount;
        }

    }

    //- Probably going to DELETE
    function getDonators(uint256 _id) view public returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    //- NO NO NO too much gas usage
    //- Events maybe the solution
    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numOfCampaigns);

        uint i;
        for(i = 0; i < numOfCampaigns;) {
            Campaign storage item = campaigns[i];
            allCampaigns[i] = item;
            i++;
        }

        return allCampaigns;
    }
}