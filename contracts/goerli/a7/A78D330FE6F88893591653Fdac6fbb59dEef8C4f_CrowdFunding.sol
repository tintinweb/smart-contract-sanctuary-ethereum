// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {
    struct Campaign {
        address payable patient;
        string patientImage;
        string hospitalNoteByDoctor;
        bool isVerified;
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

    uint256 public numberOfCampaigns = 0;

    function checkEligibility(string memory _patientImage, string memory _hospitalNoteByDoctor) public pure returns(bool) {
        // Check if patient image and hospital note are valid
        if (bytes(_patientImage).length == 0 || bytes(_hospitalNoteByDoctor).length == 0) {
            return false;
        }

        // If all checks pass, return true
        return true;
    }

    function createCampaign(address _patient, string memory _patientImage, string memory _hospitalNoteByDoctor, string memory _title, string memory _description, uint256 _target, uint256 _deadline) public returns (uint256) {
        require(checkEligibility(_patientImage, _hospitalNoteByDoctor), "Patient is not eligible to create campaign");
        require(_deadline > block.timestamp, "The deadline should be a date in the future.");

        Campaign storage campaign = campaigns[numberOfCampaigns];
        campaign.patient = payable(_patient);
        campaign.patientImage = _patientImage;
        campaign.hospitalNoteByDoctor = _hospitalNoteByDoctor;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;

        numberOfCampaigns++;

        return numberOfCampaigns - 1;
    }

    function donateToCampaign(uint256 _id) public payable {
        Campaign storage campaign = campaigns[_id];

        campaign.donators.push(msg.sender);
        campaign.donations.push(msg.value);

        (bool sent,) = payable(campaign.patient).call{value: msg.value}("");
        if(sent) {
            campaign.amountCollected += msg.value;
        }
    }

    function getDonators(uint256 _id) view public returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for(uint i = 0; i < numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i];

            allCampaigns[i] = item;
        }

        return allCampaigns;
    }

    function withdrawFunds(uint256 _id) public {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp >= campaign.deadline, "The deadline has not been reached yet.");

        // Check that the patient is the one calling this function
        require(msg.sender == campaign.patient, "Only the patient can withdraw the funds.");

        uint256 amountToWithdraw = campaign.amountCollected;
        campaign.amountCollected = 0;

        (bool sent,) = payable(campaign.patient).call{value: amountToWithdraw}("");
        require(sent, "Failed to send funds to the patient.");
    }
}