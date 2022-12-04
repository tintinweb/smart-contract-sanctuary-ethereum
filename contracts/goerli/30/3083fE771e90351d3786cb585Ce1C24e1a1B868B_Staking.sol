/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

// SPDX-License-Identifier: GPL-3.0
 
pragma solidity 0.8.15;
interface IERC20 {
    function mint(address, uint) external;
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

contract Staking{
    address public owner;
    address public LPTokenAdress;
    address public rewardTokenAddress;
    IERC20 public LPToken;
    IERC20 public rewardToken;
    uint256 public freezingTime;
    uint256 public percents;
    struct StakeStruct{
        uint256 tokenValue; // количество застейканых токенов
        uint256 timeStamp; // время создания стейка
        uint256 rewardPaid; // сумма уже выплаченной награды
    }
    mapping(address => StakeStruct) public stakes;
    event Stake(address from, uint256 timeStamp, uint256 value);
    event Claim(address to, uint256 value);
    event Unstake(address to, uint256 value);

    constructor(address _LPTokenAddress, address _rewardTokenAddress, uint256 _freezingTime, uint256 _percents){
        LPTokenAdress = _LPTokenAddress;
        LPToken = IERC20(_LPTokenAddress);
        rewardTokenAddress = _rewardTokenAddress;
        rewardToken = IERC20(_rewardTokenAddress);
        freezingTime = _freezingTime;
        percents = _percents;
    }

    function stake(uint256 value) external{
        require(stakes[msg.sender].tokenValue == 0, "You already have a stake");
        LPToken.transferFrom(msg.sender, address(this), value);
        emit Stake(msg.sender, block.timestamp, value);
    }

    function claim() external {
        require(stakes[msg.sender].tokenValue > 0, "Stake: You don't have a stake");
        require(stakes[msg.sender].timeStamp > freezingTime, "Stake: freezing time has not yet passed");
        uint256 reward = stakes[msg.sender].tokenValue - stakes[msg.sender].rewardPaid;
        require(reward > 0, "Stake: you have no reward available for withdrawal");
        rewardToken.mint(msg.sender, reward);
        stakes[msg.sender].rewardPaid += reward;
        emit Claim(msg.sender, reward);
    }

    function unstake() external {
        require(stakes[msg.sender].tokenValue > 0, "Stake: You don't have a stake");
        require(stakes[msg.sender].timeStamp > freezingTime, "Stake: freezing time has not yet passed");
        LPToken.transfer(msg.sender, stakes[msg.sender].tokenValue);
        emit Unstake(msg.sender, stakes[msg.sender].tokenValue);
        stakes[msg.sender].tokenValue = 0;
    }
}