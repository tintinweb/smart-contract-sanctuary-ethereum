/**
 *Submitted for verification at Etherscan.io on 2022-11-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IERC20Staking {
    
    function balanceOf(address _owner) external view returns (uint256 balance);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function transfer(address _to, uint256 _value) external returns (bool success);
}

interface IERC20Reward {
    function transfer(address _to, uint256 _value) external returns (bool success);
    function balanceOf(address _owner) external view returns (uint256 balance);
}

contract Stakes {
    event Stake(address indexed _owner, uint256 _value, uint256 _time);
    event UnStake(address indexed _owner, uint256 _value, uint256 _time);

    IERC20Staking immutable private stakingToken;
    IERC20Reward immutable private rewardToken;
    address immutable public owner;
    address immutable public wallet;
    uint256 constant public MIN_STAKE_VALUE = 200;
    struct Staking {
        bool isStaked;
        uint256 tokens;
        uint256 time;
        uint256 withdraws;
    }
    mapping (address => Staking) stakedBalances;

    constructor(address _stakingToken, address _rewardToken, address _wallet) {
        owner = msg.sender;
        stakingToken = IERC20Staking(_stakingToken);
        rewardToken = IERC20Reward(_rewardToken);
        wallet = _wallet;
    }

    function decimals() public pure  returns (uint256) {
        return 10**18;
    }

    function stake(uint256 _value, address _user) public {
        //require(msg.sender == address(marketplace));
        //check if staked already
        require(stakedBalances[_user].isStaked != true, "User can't restake untill unstake");
        //check for min stake && owner balance && marketplace allowance
        require(_value >= MIN_STAKE_VALUE, "Stake value less than min allowed");
        uint256 fee = (_value * 5) / 1000;
        // require(stakingToken.balanceOf(msg.sender) >= _value, "Not enough Funds!!");
        // require(stakingToken.allowance(msg.sender, address(this)) >= _value, "Not enough funds allowed to Maketplace!!");
        //transfer tokens to this marketplace address
        stakingToken.transferFrom(_user, address(this), _value);
        //transfer fee to wallet
        stakingToken.transfer(wallet, fee);
        stakedBalances[_user].isStaked = true;
        stakedBalances[_user].tokens = _value - fee;
        stakedBalances[_user].time = block.timestamp;

        emit Stake(_user, _value, block.timestamp);
    }

    function unStake(address _user) public{
        //require(msg.sender == address(marketplace));
        require(stakedBalances[_user].isStaked == true, "Tokens not staked!!");
        uint256 fees = (stakedBalances[_user].tokens * 15) / 100;
        //reentrancy protection
        uint256 remaining = stakedBalances[_user].tokens - fees;
        delete stakedBalances[_user];
        stakingToken.transfer(wallet, fees);
        stakingToken.transfer(_user, remaining);

        emit UnStake(_user, remaining, block.timestamp);
    }

    function calculateReward(address _user) public view returns (uint256){
        uint256 daysStaked = (block.timestamp - stakedBalances[_user].time) / 86400;
        uint256 withdraws = stakedBalances[_user].withdraws;

        return ((daysStaked - withdraws) * (stakedBalances[_user].tokens * 7) / 10000);
    }

    function withdrawReward(address _user) public {
        //require(msg.sender == address(marketplace));
        require(stakedBalances[_user].isStaked == true, "Tokens not staked!!");
        uint256 daysStaked = (block.timestamp - stakedBalances[_user].time) / 86400;
        uint256 withdraws = stakedBalances[_user].withdraws;
        //reward time completed && reward not already withdrawn
        require(daysStaked > 0 && withdraws < daysStaked, "Reward not available yet");
        stakedBalances[_user].withdraws += 1;
        rewardToken.transfer(_user, (daysStaked - withdraws) * (stakedBalances[_user].tokens * 7) / 10000);
    }
}