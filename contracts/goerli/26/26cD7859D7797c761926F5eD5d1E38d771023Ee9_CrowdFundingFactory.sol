// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;



contract CrowdFundingFactory {
    address payable[] public deployedCampaigns;

    function createCampaign(address _owner, string memory _title, string memory _description, uint256 _target, uint256 _deadline, string memory _image) public returns (address) {
        address newCampaign = address( new CrowdFunding(_owner, _title, _description, _target, _deadline, _image));
        deployedCampaigns.push(payable(newCampaign));
        return (newCampaign);
    }

    function getDeployedCampaigns() public view returns (address payable[] memory) {
        return deployedCampaigns;
    }
}

contract CrowdFunding {
    address public owner;
    string public title;
    string public description;
    uint256 public target;
    uint256 public deadline;
    uint256 public amountCollected;
    string public image;
    address[] public donators;
    uint256[] public donations;

    constructor(address _owner, string memory _title, string memory _description, uint256 _target, uint256 _deadline, string memory _image) {
        require(_deadline > block.timestamp, "The deadline should be a date in the future.");

        owner = _owner;
        title = _title;
        description = _description;
        target = _target;
        deadline = _deadline;
        amountCollected = 0;
        image = _image;
    }

    function donate() public payable {
        uint256 amount = msg.value;

        donators.push(msg.sender);
        donations.push(amount);

        (bool sent,) = payable(owner).call{value: amount}("");

        if(sent) {
            amountCollected = amountCollected + amount;
        }
    }

    function getDonatorAddresses() public view returns (address[] memory) {
        return donators;
    }

    function getDonations() public view returns (uint256[] memory) {
        return donations;
    }

}