// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Dopp{

    struct Campaign {
        uint id;
        string image;
        string name;
        string description;
        uint amountReceived;
        uint totalAmount;
        address payable author;
    }

    mapping(uint => Campaign) campaigns;
    uint256 public campaignCount =  0;

    function getAllCampaigns() view public returns(Campaign[] memory){
        Campaign[] memory _campaigns;
        
        for (uint i = 0; i <= campaignCount; i++) {
            _campaigns[i] = campaigns[i];
        }

        return _campaigns;
        
    }

    event CampaignCreated(
        uint256 id,
        string image,
        string name,
        string description,
        uint256 totalAmount,
        address author
    );

    event FundsDonated(
        uint id,
        string name,
        string description,
        uint amount,
        address investor
    );

    function createCampaign(string memory _name, string memory _description, string memory _image, uint _totalAmount ) public {
        require(bytes(_image).length > 0, "Send Nudes!");
        require(bytes(_description).length > 0, "Describe bitch!!");
        require(bytes(_name).length > 0, "Name is Required!");
        require(_totalAmount > 0, "Ask money");

        campaigns[campaignCount] = Campaign(campaignCount, _image, _name, _description, 0, _totalAmount, payable(msg.sender));

        campaignCount++;

        emit CampaignCreated(
            campaignCount,
            _image,
            _name,
            _description,
            _totalAmount,
            msg.sender
        );
    }

    function donateFunds(uint _id) public payable {
        require(msg.value > 0, "Send some money bitch!");
        campaigns[_id].amountReceived += msg.value;

        emit FundsDonated(
            _id,
            campaigns[_id].name,
            campaigns[_id].description,
            msg.value,
            msg.sender
        );
    }

}