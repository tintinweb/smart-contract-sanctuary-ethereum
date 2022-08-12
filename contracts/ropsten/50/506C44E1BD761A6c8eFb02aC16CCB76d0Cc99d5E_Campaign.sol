/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

// File: remix.sol

// SPDX-License_Identifier: MIT

pragma solidity >= 0.5.0 <= 0.9.0;

contract campaignRecord
{
    address[]public deployedCampaigns;

    event CampaignCreated (
        string title,
        uint requiredAmount,
        address indexed owner,
        address campaignAddress,
        string img,
        uint indexed timestamp,
        string indexed category
    );

    function createCampaign(
        string memory _title,
        uint _requiredAmount,
        string memory _img,
        string memory _story,
        string memory category
        )public
        {
            Campaign newcampaign = new Campaign
            (
                _title,
                _requiredAmount,
                _img,
                _story
             );

             deployedCampaigns.push(address(newcampaign));

             emit CampaignCreated(
                 _title,
                 _requiredAmount,
                 msg.sender,
                 address(newcampaign),
                 _img,
                 block.timestamp,
                 category
                 );
        }
}

contract Campaign
{
    string public title;
    uint256 public requiredAmount;
    string public image;
    string public story;
    address payable public owner;
    uint256 public receivedAmount;

    event donated(
        address indexed donar,
        uint indexed amount, 
        uint indexed timestamp
        );

    constructor(
        string memory _title,
        uint _requiredAmount,
        string memory _img,
        string memory _story
        )
    {
        title = _title;
        requiredAmount = _requiredAmount;
        image = _img;
        story=_story;
        owner= payable(msg.sender);
    }

    function donate()public payable
    {
        require(requiredAmount > receivedAmount, "Required Amount fullfilled");
        owner.transfer(msg.value);
        receivedAmount += msg.value;

        emit donated(msg.sender,msg.value,block.timestamp);
    }
}