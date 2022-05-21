// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract EthPool {
    uint256 public totalStaked;
    uint256 public sharedRewards;
    mapping(address => uint256) public stake;
    mapping(address => uint256) public initialReward;

    address public owner;

    uint256 constant PPB = 10**9;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Invalid Owner Account.");
        _;
    }

    function depositToPool() public payable {
        uint256 deposited = stake[msg.sender];
        uint256 reward = rewardOfAccount();
        stake[msg.sender] = reward + deposited + msg.value;
        initialReward[msg.sender] = sharedRewards;
        totalStaked = totalStaked + reward + msg.value;
    }

    function depositRewards() public payable onlyOwner {
        if (totalStaked > 0) {
            uint256 value = msg.value;
            uint256 value2 = (value * PPB) / totalStaked;
            sharedRewards = sharedRewards + value2;
        } else {
            revert();
        }
    }

    function rewardOfAccount() public view returns (uint256) {
        uint256 deposited = stake[msg.sender];
        uint256 p = sharedRewards - initialReward[msg.sender];
        uint256 reward = ((deposited) / PPB) * p;
        return reward;
    }

    function totalOfAccount() public view returns (uint256) {
        uint256 deposited = stake[msg.sender];
        uint256 reward = rewardOfAccount();
        return deposited + reward;
    }

    function withdraw() public payable {
        uint256 deposited = stake[msg.sender];
        uint256 p = (sharedRewards - initialReward[msg.sender]);
        uint256 reward = ((deposited) / PPB) * p;
        totalStaked = totalStaked - deposited;
        stake[msg.sender] = 0;
        payable(msg.sender).transfer(deposited + reward);
    }
}