// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract CrowdFunding {
    struct Campaign{
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donators;
        uint256[] donations;
    }

    mapping(uint256 => Campaign) public campaigns;
    uint256 public numberofCampaings = 0;

    function createCampaign(address _owner, string memory _title, string memory _description, uint256 _target, uint256 _deadline, string memory _image) public returns(uint256){
        Campaign storage campaign = campaigns[numberofCampaings++];
        require(campaign.deadline < block.timestamp, "The deadline should be a date in the future");
        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;

        // numberofCampaings++;
        return numberofCampaings - 1;
    }

    function donateToCampaign(uint256 _id) public payable{
        uint256 amount = msg.value;
        require(amount > 0, "amount must be greater than zero");
        // Campaign storage campaign = campaigns[_id];
        // campaign.donators.push(msg.sender);
        // campaign.donations.push(amount);
        campaigns[_id].donators.push(msg.sender);
        campaigns[_id].donations.push(amount);
        (bool sent, ) = payable(campaigns[_id].owner).call{value: amount}("");
        if(sent){
            campaigns[_id].amountCollected += amount;
        }
    }

    function getDonators(uint256 _id) view public returns(address[] memory, uint256[] memory){
        return(campaigns[_id].donators, campaigns[_id].donations);
    }

    function getCampaigns() public view returns(Campaign[] memory){
        // we created allcampaings in the size of numberofCampaings
        Campaign[] memory allCampaings = new Campaign[](numberofCampaings);
        for(uint i = 0 ; i < numberofCampaings ; i++){
            allCampaings[i] = campaigns[i];
            // allCampaings[i] = item;
        }
        return allCampaings;
    }
}