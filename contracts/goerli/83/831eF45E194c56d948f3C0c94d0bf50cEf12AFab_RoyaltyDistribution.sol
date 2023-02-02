// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract RoyaltyDistribution {
    mapping (address => uint256) public membersPersentage;
    mapping (address => uint256) public membersEarned;
    address admin;
    uint256 persent;
    uint256 public budget;
    uint256 public costs;
    bool public unlock;

    modifier onlyAdmin() {
        require (msg.sender == admin, "You are not an admin");
        _;
    }

    modifier unlocked() {
        require (unlock, "Contract is locked");
        _;
    }

    modifier locked() {
        require (unlock == false, "Contract is unlocked");
        _;
    }

    constructor () {
        admin = msg.sender;
        persent = 100;
    }

    function addMember (address member, uint256 newPersent) public onlyAdmin locked{
        require (newPersent <= persent, "Choose a lower value");
        persent -= newPersent;
        persent += membersPersentage[member];
        membersPersentage[member] = newPersent;
    } 

    function setAdminPercent (uint256 newPersent) public onlyAdmin locked{
        require (newPersent <= persent, "Choose a lower value");
        persent -= newPersent;
        persent += membersPersentage[admin];
        membersPersentage[admin] = newPersent;
    } 

    function addCosts (uint256 newcost) public onlyAdmin locked{
        costs += newcost;
    }

    function subCosts (uint256 newcost) public onlyAdmin locked{
        require (costs > newcost, "Choose a lower value");
        costs -= newcost;
    }

    receive () external payable {
        if (msg.value >= costs) {
            budget = msg.value - costs;
            costs = 0;
        } else {
            costs -= msg.value;
        }
    }

    function Unlock () public onlyAdmin locked returns(uint256) {
        unlock = true;
        if (budget >= costs) {
            budget -= costs;
            costs = 0;
        } else {
            costs -= budget;
            budget = 0;
        }
        return costs;
    }

    function transfer () public payable unlocked {
        require (budget * membersPersentage[msg.sender] / 100 - membersEarned[msg.sender] > 0, "You have no money");
        payable(msg.sender).transfer(budget * membersPersentage[msg.sender] / 100 - membersEarned[msg.sender]);
    }
}