// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/// @title CrowdFunding Contract All the logic of the web3 crowdfunding software
/// @author Khushal Bhardwaj
/// @notice It has all the functionailty you need to run the 
contract CrowdFunding {
    struct Campaign {
		address owner;
		string title;
		string description;
		uint target;
		uint deadline;
		uint ammountCollected;
		string image;
		address[] donators;
		uint[] donations;
	}

	mapping (uint => Campaign) public campaigns;

	uint public numberOfCampaigns = 0;

	function createCampaign(address _owner, string memory _title, string memory _description, uint _target, uint _deadline, string memory _image) public returns(uint) {
		Campaign storage campaign = campaigns[numberOfCampaigns];
	
		require(campaign.deadline < block.timestamp, "The deadline should be a date in the feature");

		campaign.owner = _owner;
		campaign.title = _title;
		campaign.description = _description;
		campaign.target = _target;
		campaign.ammountCollected = 0;
		campaign.image = _image;

		numberOfCampaigns ++;

		return numberOfCampaigns - 1;
	}

	function donateToCampaign(uint _id) public payable {
		uint ammount = msg.value;
		Campaign storage campaign = campaigns[_id];

		campaign.donators.push(msg.sender);
		campaign.donations.push(ammount);

		(bool sent,) = payable(campaign.owner).call{value:ammount}("");
		if (sent) {
			campaign.ammountCollected = campaign.ammountCollected + ammount;
		}
	}

	// @param _id: the id of the campaing
	function getDonators(uint _id) public view returns (address[] memory, uint[] memory) {
		return (campaigns[_id].donators, campaigns[_id].donations); 
	}

	function getCampaigns() public view returns (Campaign[] memory) {
		Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);
		for (uint i = 0; i < numberOfCampaigns; i++) {
			Campaign storage campaign = campaigns[i];
			allCampaigns[i] = campaign;
		}

		return allCampaigns;
	}
}