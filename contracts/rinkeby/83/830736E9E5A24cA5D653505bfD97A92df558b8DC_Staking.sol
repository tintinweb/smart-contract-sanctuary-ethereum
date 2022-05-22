//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC20Token {
    function balanceOf(address owner) external view returns(uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
}


contract Staking {
    address public owner;
    address private lpTokenAddress;
    address private rewardTokenAddress;
    uint public lpCourse;
    
    struct Staked {
        uint256 amount;
        uint256 reward;
        uint256 timeStamp;
    }
    mapping(address => Staked) private stakeholders;

    constructor(address _lpTokenAddress, address _rewardTokenAddress) {
        owner = msg.sender;
        lpTokenAddress = _lpTokenAddress;
        rewardTokenAddress = _rewardTokenAddress;
        lpCourse = 2000;
    }

    function stake(uint256 amount) public {
        require(stakeholders[msg.sender].amount == 0, "Already staked");
        require(ERC20Token(lpTokenAddress).allowance(msg.sender, address(this)) >= amount, "No enough allowance");
        ERC20Token(lpTokenAddress).transferFrom(msg.sender, address(this), amount);
        stakeholders[msg.sender].amount = amount;
        stakeholders[msg.sender].timeStamp = block.timestamp;
    }

    function claim() public {
        require(stakeholders[msg.sender].reward != 0, "Zero reward");
        ERC20Token(rewardTokenAddress).transfer(msg.sender, stakeholders[msg.sender].reward);
        stakeholders[msg.sender].reward = 0;
    }

    function unstake(uint256 amount) public {
        require(stakeholders[msg.sender].amount != 0, "Zero balance staked");
        require(stakeholders[msg.sender].amount >= amount, "Not enough balance staked");
        ERC20Token(lpTokenAddress).transfer(msg.sender, amount);
        stakeholders[msg.sender].amount -= amount;
    }

    function checkReward() public {
        require(block.timestamp - stakeholders[msg.sender].timeStamp > 600, "Time not passed");
        stakeholders[msg.sender].reward = stakeholders[msg.sender].amount * 20 / 100 * lpCourse;
    }
}