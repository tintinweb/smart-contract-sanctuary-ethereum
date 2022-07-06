/**
 *Submitted for verification at Etherscan.io on 2022-07-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

//not great error handling 
error InvalidName();

contract FundRaising {

    event CampaignStart(uint id, address indexed creator, string name, uint targetAmount);
    event DonationMade(uint id, address indexed contributor, uint amount);
    event DonationCanceled(uint id, address indexed contributor);
    event RefundDonation(uint id, address indexed contributor);
    event CampaignFinished(uint id, address indexed creator, uint targetAmount);  

    modifier ValidID(uint index){
        require(index >= 0 && index <= id);
        _;
    }

    struct Campaign {
        address creator;
        string name; 
        string description;
        uint targetAmount;
        uint currentAmount;
        uint endTime;        
        bool active;
    }

    uint id;
    mapping(uint => Campaign) public campaigns;
    mapping(uint => mapping(address => uint)) public donations;

    function startCampaign(string calldata _name, string calldata _description, uint _targetAmount, uint _duration) external {
        if (bytes(_name).length <= 0)
            revert InvalidName(); 
        require(_targetAmount > 0, "Invalid target amount");
        require(_duration > 0, "Invalid duration");

        campaigns[id] = Campaign({
            creator: msg.sender,
            name: _name,
            description: _description,
            targetAmount: _targetAmount,
            currentAmount: 0,
            endTime: block.timestamp + _duration,
            active: true
        });
        id++;

        emit CampaignStart(id, msg.sender, _name, _targetAmount);
    }

    function donate(uint campaignIndex) external payable ValidID(campaignIndex){
        Campaign storage temp = campaigns[campaignIndex];
        require(msg.sender != temp.creator, "Creator can't donate");
        require(temp.active == true, "Campaign is not active");
        require(msg.value > 0 && msg.value <= (temp.targetAmount-temp.currentAmount), "Invalid amount to donate");
        require(temp.endTime > block.timestamp, "Campaign finished");
        donations[campaignIndex][msg.sender] += msg.value;
        temp.currentAmount += msg.value;

        emit DonationMade(campaignIndex, msg.sender, msg.value);
    }

    function cancelDonation(uint campaignIndex) external ValidID(campaignIndex){     
        Campaign storage temp = campaigns[campaignIndex];
        require(temp.endTime >= block.timestamp, "Campaign is not active");
        require(donations[campaignIndex][msg.sender] > 0, "Not donor yet");  
        require(temp.active == true, "Campaign finished");
        temp.currentAmount -= donations[campaignIndex][msg.sender];       
        payable(msg.sender).transfer(donations[campaignIndex][msg.sender]);
        donations[campaignIndex][msg.sender] = 0;  

        emit DonationCanceled(campaignIndex, msg.sender);
    }

    function finishCampaign(uint campaignIndex) external ValidID(campaignIndex){
        Campaign storage temp = campaigns[campaignIndex];
        require(temp.endTime <= block.timestamp, "Not enough time passed"); 
        require(temp.creator == msg.sender, "Not creator");
        require(temp.active == true, "Not active");
        require(temp.targetAmount == temp.currentAmount,"Not enough funds");
        payable(msg.sender).transfer(temp.targetAmount);
        temp.active = false;

        emit CampaignFinished(campaignIndex, msg.sender, temp.targetAmount); 
    }

    function refundDonation(uint campaignIndex) external ValidID(campaignIndex) {
        Campaign memory temp = campaigns[campaignIndex];
        require(temp.endTime < block.timestamp,"Not enough time passed");
        require(donations[campaignIndex][msg.sender] > 0,"Not donor yet");  
        require(temp.active == false, "Not finished");
        require(msg.sender != temp.creator, "Creator can't refund");
        payable(msg.sender).transfer(donations[campaignIndex][msg.sender]);
        donations[campaignIndex][msg.sender] = 0;  

        emit RefundDonation(campaignIndex, msg.sender);        
    }

}