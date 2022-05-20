//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import './interfaces/IERC20.sol';

contract MyStaking {
    address owner; // owner of contract
    uint freezeTime; // the time after which the user can withdraw lp tokens
    uint rewardsPercent; // percent of rewards, depending on the number of lp tokens
    IERC20 lpToken; // lp token
    IERC20 rewardsToken; // rewards token
    uint  rewardsFrequency; // how often are rewards generated

    struct Stake {
        uint amount; // amount of new stake
        uint timestamp; // when stake was proceeded
    }

    struct User {
        uint lpBalance; // needs to count rewards
        uint rewardsBalance; // balance of rewards tokens of user
        uint lastRewardsTime; // needs to recount rewardsBalance if lpBalance changes
        Stake [] stakes; // needs to know, how many lp tokens user can withdraw at the moment
    }

    mapping (address => User) users; // information about users

    event StakeEv(
        address user,
        uint amount
    );

    event ClaimEv(
        address user,
        uint amount
    );

    event UnstakeEv(
        address user,
        uint amount,
        uint remains
    );

    constructor (uint _freezeTime, uint _rewardsPercent, uint _rewardsFrequency, address _lpToken, address _rewardsToken) {
        lpToken = IERC20(_lpToken);
        rewardsToken = IERC20(_rewardsToken);
        owner = msg.sender;
        freezeTime = _freezeTime;
        rewardsPercent = _rewardsPercent;
        rewardsFrequency = _rewardsFrequency;
    }

    modifier requireOwner {
        require(msg.sender == owner, "Not an owner");
        _;
    }

    modifier countRewards {
        if (users[msg.sender].lastRewardsTime != 0) {
            uint rewardsPerCycle = users[msg.sender].lpBalance * rewardsPercent / 100;
            uint numberOfCycles = (block.timestamp - users[msg.sender].lastRewardsTime) / rewardsFrequency; 

            users[msg.sender].rewardsBalance += (rewardsPerCycle * numberOfCycles);
        }

        users[msg.sender].lastRewardsTime = block.timestamp;
        _;
    }

    // sends tokens to contract for staking
    function stake (uint _amount) external countRewards {
        require(_amount > 0, "You can't send 0 tokens");
        // adding info about this stake
        users[msg.sender].stakes.push(Stake(_amount, block.timestamp));

        // before it user should approve tokens to contract
        lpToken.transferFrom(msg.sender, address(this), _amount);
        users[msg.sender].lpBalance += _amount;
        
        emit StakeEv(msg.sender, _amount);
    }
   
    // sends reward tokens to user
    function claim () external countRewards {
        require(users[msg.sender].rewardsBalance > 0, "You haven't got reward tokens");
        rewardsToken.transfer(msg.sender, users[msg.sender].rewardsBalance);

        emit ClaimEv(msg.sender, users[msg.sender].rewardsBalance);
        users[msg.sender].rewardsBalance = 0;
    }

    // withdraw lp tokens
    function unstake () external countRewards {
        require(users[msg.sender].lpBalance > 0, "Nothing to unstake");
        uint availableBalance;
        
        // for sorting array
        uint lastUnusedElement;
        uint elementsUsed;


        // collects stakes, that has been staked more than freeze time ago and sorts array
        for (uint i=0; i<users[msg.sender].stakes.length; ++i) {
            if (block.timestamp - users[msg.sender].stakes[i].timestamp > freezeTime) {
                availableBalance += users[msg.sender].stakes[i].amount;
                users[msg.sender].stakes[i].amount = 0;
                
                elementsUsed++;
            }
            else {
                users[msg.sender].stakes[lastUnusedElement] = users[msg.sender].stakes[i];
                lastUnusedElement++;
            }
            // now unused elements in the left side of array
        }

        for (uint i = 0; i<elementsUsed; i++) {
            users[msg.sender].stakes.pop();
        }

        require(availableBalance > 0, "You can't unstake lp tokens right now");

        lpToken.transfer(msg.sender, availableBalance);
        users[msg.sender].lpBalance -= availableBalance;

        emit UnstakeEv(
            msg.sender,
            availableBalance,
            users[msg.sender].lpBalance
        );
    }

    // changes settings only by owner
    function changeSettings (uint _freezeTime, uint _rewardsPercent, uint _rewardsFrequency) external requireOwner {
        freezeTime = _freezeTime;
        rewardsPercent = _rewardsPercent;
        rewardsFrequency = _rewardsFrequency;
    }

    // info about this staking contract
    function stakingInfo () external view returns (uint, uint, uint) {
        return (freezeTime, rewardsPercent, rewardsFrequency);
    }

    // info about user
    function userInfo (address user) external view returns (uint, uint) {
        return (users[user].lpBalance, users[user].rewardsBalance);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);

    function approve(address _spender, uint256 _value) external returns (bool);

    function allowance(address _owner, address _spender) external view returns (uint256);


    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}