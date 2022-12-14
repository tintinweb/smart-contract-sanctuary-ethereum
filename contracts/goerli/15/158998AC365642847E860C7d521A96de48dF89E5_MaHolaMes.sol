// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract MaHolaMes {
    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 objectif;
        uint256 terme;
        uint256 amountCollected;
        string image;
        address[] donateurs;
        uint256[] dons;
    }
    mapping(uint256 => Campaign) public campaigns;

    uint256 public numberOfCampaigns = 0;

    function createCampaign(
        address _owner,
        string memory _title,
        string memory _description,
        uint256 _objectif,
        uint256 _terme,
        string memory _image
    ) public returns (uint) {
        Campaign storage campaign = campaigns[numberOfCampaigns];

        require(
            campaign.terme < block.timestamp,
            "choisir une autre date future"
        );

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.objectif = _objectif;
        campaign.terme = _terme;
        campaign.amountCollected = 0;
        campaign.image = _image;

        numberOfCampaigns++;

        // index de la demande la plus récente
        return numberOfCampaigns - 1;
    }

    function donateToCampaign(uint256 _id) public payable {
        uint256 amount = msg.value;

        Campaign storage campaign = campaigns[_id];

        campaign.donateurs.push(msg.sender);
        campaign.dons.push(amount);

        (bool sent, ) = payable(campaign.owner).call{value: amount}("");

        if (sent) {
            campaign.amountCollected = campaign.amountCollected + amount;
        }
    }

    function getDonateurs(
        uint256 _id
    ) public view returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].donateurs, campaigns[_id].dons);
    }

    function getCampaigns() public view returns (Campaign[] memory) {
        //empty array of structs [{}, {}, ...]
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for (uint i = 0; i < numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i];

            allCampaigns[i] = item;
        }
        return allCampaigns;
    }
}