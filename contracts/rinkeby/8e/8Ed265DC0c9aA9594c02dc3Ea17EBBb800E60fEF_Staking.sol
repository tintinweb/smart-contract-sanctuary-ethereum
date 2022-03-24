/**
 *Submitted for verification at Etherscan.io on 2022-03-24
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Staking {
    IERC20 public rewartToken;
    IERC20 public stakingToken;

    mapping(address => Staker) public stakers;
    struct Staker {
        uint256 stakeBalance;
        uint256 rewardBalance;
        uint256 lastStakeTimestamp;
        uint256 lastRewardUpdateTimestamp;
    }

    uint256 private _percent = 20;
    uint256 private _rewardSeconds = 600;
    uint256 private _freezeStakeSeconds = 1200;

    mapping(address => bool)  private _admins;

    constructor(address _stakingToken, address _rewardToken) {
        stakingToken = IERC20(_stakingToken);
        rewartToken = IERC20(_rewardToken);
        _admins[msg.sender] = true;
    }

    modifier onlyAdmin {
        require(_admins[msg.sender], "Only admin action");
        _;
    }

    function updatePercent(uint256 newPercent) public onlyAdmin {
        _percent = newPercent;
    }

    function updateRewardSeconds(uint256 _newRewardSeconds) public onlyAdmin {
        _rewardSeconds = _newRewardSeconds;
    }

    function updateFreezeStakeSeconds(uint256 _newFreezeStakeSeconds) public onlyAdmin {
        _freezeStakeSeconds = _newFreezeStakeSeconds;
    }

    function getPercent() public view onlyAdmin returns(uint256) {
        return _percent;
    }

    function getRewardSeconds() public view onlyAdmin returns(uint256) {
        return _rewardSeconds;
    }

    function getFreezeStakeSeconds() public view onlyAdmin returns(uint256) {
        return _freezeStakeSeconds;
    }

    function stake(uint256 _amount) external {
        Staker memory staker = stakers[msg.sender];

        staker.rewardBalance += calculateReward(staker);
        staker.lastRewardUpdateTimestamp = block.timestamp;
        staker.stakeBalance += _amount;
        staker.lastStakeTimestamp = block.timestamp;

        stakers[msg.sender] = staker;
        stakingToken.transferFrom(msg.sender, address(this), _amount);
    }
    
    function unstake() external {
        Staker memory staker = stakers[msg.sender];
 
        require(staker.lastStakeTimestamp != 0, "Never stake");
        require(staker.lastStakeTimestamp <= block.timestamp - _freezeStakeSeconds, "Freeze time don't pass");
        require(staker.stakeBalance != 0, "Zero balance");

        uint256 balance = staker.stakeBalance;
        staker.stakeBalance = 0;
        stakers[msg.sender] = staker;
        stakingToken.transfer(msg.sender, balance);
    }
 
    function claim() external {
        Staker memory staker = stakers[msg.sender];
        uint256 rewardBalance = staker.rewardBalance + calculateReward(staker);
        staker.rewardBalance = 0;
        staker.lastRewardUpdateTimestamp = block.timestamp;
        stakers[msg.sender] = staker;
 
        rewartToken.transfer(msg.sender, rewardBalance); 
    }

    function calculateReward(Staker memory _staker) internal view returns(uint256) {
        uint256 lastTimestamp = _staker.lastRewardUpdateTimestamp;
        if (lastTimestamp == 0) {
            return 0;
        }
        uint256 secondsPassFromLastStake = block.timestamp - lastTimestamp;
        uint256 times = secondsPassFromLastStake / _rewardSeconds;
        return times * calculatePercent(_staker.stakeBalance);
    }

    function calculatePercent(uint256 _amount) internal view returns(uint256) {
        uint256 amount = _amount * 1000;
        uint256 percentAmount = amount / 100 * _percent;
        return percentAmount / 1000;
    }
}