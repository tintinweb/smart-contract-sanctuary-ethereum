/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

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

contract MelviIncFarmingLP {
    IERC20 public MelviToken;
    IERC20 public LPToken;

    uint public rewardRate = 100;
    uint public lastUpdateTime;
    uint public rewardPerTokenStored;

    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public rewards;

    uint private _totalSupply;
    mapping(address => uint) private _balances;

    constructor(address _LPToken, address _MelviToken) {
        LPToken = IERC20(_LPToken);
        MelviToken = IERC20(_MelviToken);
    }

    function rewardPerToken() public view returns (uint) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
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
        LPToken.transferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(uint _amount) external updateReward(msg.sender) {
        _totalSupply -= _amount;
        _balances[msg.sender] -= _amount;
        LPToken.transfer(msg.sender, _amount);
    }

    function getReward() external updateReward(msg.sender) {
        uint reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        MelviToken.transfer(msg.sender, reward);
    }
}