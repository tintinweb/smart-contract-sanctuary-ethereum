/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

contract TimeLockReward {
    bool private unlocked;
    modifier lock() {
        require(!unlocked, "TimeLockReward: Locked");
        unlocked = true;
        _;
        unlocked = false;
    }

    uint256 public totalReward;
    uint256 public rewardPerBlock;

    uint256 public startBlock;
    uint256 public endBlock;

    struct UserInfo {
        uint256 depositBlock;
        uint256 balance;
    }

    mapping(address => UserInfo) public userInfo;

    /// @dev Initializes contract.
    constructor() payable {
       totalReward += msg.value;
       startBlock = block.number;
       endBlock = startBlock + 100000;
       rewardPerBlock = totalReward / (endBlock - startBlock);
    }

    function deposit() external payable {
        require(msg.value > 0, "TimeLockReward: Deposit value must not be zero");
        require(block.number < endBlock, "TimeLockReward: Deposit time ended");
        userInfo[msg.sender].depositBlock = block.number;
        userInfo[msg.sender].balance += msg.value;
    }

    function totalDeposit() public view returns(uint256) {
        return address(this).balance - totalReward;
    }

    function calculateReward() public view returns(uint256) {
        uint256 distance; 
        if(block.number < endBlock) {
            distance = block.number - userInfo[msg.sender].depositBlock;
        } else {
            distance = endBlock - userInfo[msg.sender].depositBlock;
        } 
        
        return (rewardPerBlock * distance) * (userInfo[msg.sender].balance / totalDeposit()); 
    }

    function withdraw(uint256 _amount) external lock {
        require(userInfo[msg.sender].balance - _amount >= 0, "TimeLockReward: Insufficient funds");

        uint256 reward = calculateReward();
        totalReward -= reward;

        userInfo[msg.sender].balance -= _amount;
        
        (bool sent, ) = msg.sender.call{value: (_amount + reward)}("");
        require(sent, "TimeLockReward: Failed to send Ether");
    }
}