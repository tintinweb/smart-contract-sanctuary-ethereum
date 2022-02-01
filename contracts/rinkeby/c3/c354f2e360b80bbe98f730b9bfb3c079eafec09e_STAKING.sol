// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./coinsupply.sol";

contract STAKING is CoinSupply {
 
    uint256 public StakeTime;
    uint private  interestPerSecond;
    IERC20 private stakingToken;
    uint256 private interest;

    mapping(address => uint256) _balances;

    mapping(address => uint256) _stakeMoney;
    mapping(address => uint256)  _rewardYearly;

    constructor(address _stakingToken) {
        stakingToken = IERC20(_stakingToken);
    }
// stake
    function stake(uint256 amount) public {
        require(amount > 0, "amount cant be null");
        require(msg.sender != address(0), "address cant be zero address ");
        _totalSupply += amount;
        StakeTime = block.timestamp;

        _stakeMoney[msg.sender] = amount;
        CoinSupply.transferStake(msg.sender, address(this), amount);
        emit staked(_totalSupply, StakeTime, amount);
    }
//    reward per second
    function rewardGeneratePerSecond(uint256 _interest) public {
        uint256 secInYear = 12 * 30 * 24 * 60 * 60;
        uint256 totalRewardGenerateadyearly = (((_interest *
            _stakeMoney[msg.sender]) * 12) / 100);
             _rewardYearly[msg.sender] = totalRewardGenerateadyearly;
       
        interestPerSecond = totalRewardGenerateadyearly / secInYear;
       
        emit rewardGeneratePerSec(
            secInYear,
            totalRewardGenerateadyearly,
            interestPerSecond
        );
    }

   // time and claimable amount
function rewardGenerateTime() public view returns(uint , uint){
    uint generatedTime = block.timestamp - StakeTime ;
    uint claimableAmount = generatedTime * interestPerSecond; 
    return (generatedTime , claimableAmount);
}


function yearlyReward(address account) public view returns (uint256) {
        return _rewardYearly[account];
    }


    function stakemoney(address account) public view returns (uint256) {
        return _stakeMoney[account];
    }

    event staked(uint256 _totalSupply, uint256 StakeTime, uint256 amount);
    event rewardGeneratePerSec(
        uint256 secInYear,
        uint256 totalRewardGeneratedyearly,
        uint256 interestPerSecond
    );
}