//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract blockFundContract {

    constructor() {
        campaignCounter = 0;
    }

    uint256 campaignCounter;

    struct campaignStruct {
        uint256 id;
        string campaignName;
        uint256 target;
        uint256 balance;
        address creator;
    }

    campaignStruct[] public donationCampaigns;

    function createNewCampaign(string memory _campaignName, uint256 _target) public {
        donationCampaigns.push(campaignStruct({
            id: campaignCounter + 1,
            campaignName: _campaignName,
            target: _target,
            balance: 0,
            creator: msg.sender
        }));
    }

    function fundCampaign(uint256 _id, uint256 _amount) public payable {
        for (uint256 i = 0; i < donationCampaigns.length; i++) {
            if (donationCampaigns[i].id == _id) {
                require(donationCampaigns[i].target > donationCampaigns[i].balance + _amount, "You are donating too much over the target");
                donationCampaigns[i].balance += _amount;
            }
        }
    }

    function isCampaignCreator(uint256 _id) public view returns (bool) {
        for (uint256 i = 0; i < donationCampaigns.length; i++) {
            if (donationCampaigns[i].id == _id) {
                if (donationCampaigns[i].creator == msg.sender) {
                    return true;
                }
                return false;
            }
        }
    }

    function withdrawFromCampaign(uint256 _id) public payable {
        require(isCampaignCreator(_id), "You are not the campaign creator");
        for (uint256 i = 0; i < donationCampaigns.length; i++) {
            if (donationCampaigns[i].id == _id) {
                payable(msg.sender).transfer(donationCampaigns[i].balance);
            }
        }
    }
}