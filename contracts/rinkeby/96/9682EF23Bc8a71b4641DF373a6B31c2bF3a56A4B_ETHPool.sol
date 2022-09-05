/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ETHPool {
    using SafeMath for uint256;

    mapping(address => bool) public isTeamMember;

    mapping(address => Stake) internal stakes;

    uint256 public stakeCount;

    struct Stake {
        address user;
        uint256 amount;
        uint256 createdAt;
        bool isValid;
        uint256 withdrawalAt;
        uint256 updatedAt;
        uint256 reward;
        uint256 id;
        uint256 lastDepositAt;
    }

    address[] internal stakeholders;

    Stake[] public pool;

    uint256 public rewardBalance; // total reward left unclaimed

    mapping(address => uint256) public _balances; // track stake of an addrrss

    uint256 public _totalStakesInPool; // total stakes in the pool

    uint256 public nextRewardTimeStamp = block.timestamp;

    modifier _onlyTeam() {
        require(isTeamMember[msg.sender], "You must be a team member");
        _;
    }

    event Staked(uint256 amount, address address_);
    event RewardDeposited(uint256 amount, address teamMember);
    event Withdrawal(uint256 amount, address address_);

    constructor() {
        isTeamMember[msg.sender] = true;
    }

    receive() external payable {
        uint256 amount = msg.value;
        rewardBalance += amount;
    }

    function addTeamMember(address _address) external _onlyTeam returns (bool) {
        require(_address == address(_address), "Invalid address");
        isTeamMember[_address] = true;
        return true;
    }

    function removeTeamMember(address _address) external _onlyTeam returns (bool) {
        require(_address == address(_address), "Invalid address");
        isTeamMember[_address] = false;
        return true;
    }

    function pullFunds(uint256 amount, uint256 fundType) external payable _onlyTeam returns (bool) {
        require(amount > 0 wei, "Send a valid amount to deposit");
        require(address(this).balance >= amount, "Insufficient funds");

        if (fundType == 1) {
            // upddate stake balance;

            // prevent underflow
            require(_totalStakesInPool >= _totalStakesInPool - amount, "_totalStakesInPool Underflow");

            _totalStakesInPool -= amount;
        } else {
            require(rewardBalance >= rewardBalance.sub(amount), "rewardBalance Underflow");

            // update reward balance;
            rewardBalance -= amount;
        }

        (bool sent, ) = payable(msg.sender).call{ value: amount }("");
        return sent;
    }

    function depositReward() external payable _onlyTeam {
        require(msg.value > 0 wei, "Insufficient stake amount");

        require(block.timestamp >= nextRewardTimeStamp, "Wrong time to desposit reward");

        rewardBalance = rewardBalance.add(msg.value);
        // loop through all valid stakers and add bonus;

        for (uint256 index = 0; index < stakeholders.length; index++) {
            address userAddress = stakeholders[index];
            Stake storage currentStake = stakes[userAddress];

            if (currentStake.isValid) {
                // calculate percentage of stake in pool;

                uint256 reward;

                if (currentStake.amount % _totalStakesInPool > 0) {
                    uint256 percentage = (currentStake.amount * 100) / _totalStakesInPool;

                    if (percentage % 100 == 0) {
                        reward = (percentage / 100) * rewardBalance;
                    } else {
                        reward = (percentage * rewardBalance) / 100;
                    }
                } else {
                    uint256 percentage = (currentStake.amount / _totalStakesInPool).mul(100);
                    if (percentage % 100 > 0) {
                        reward = (percentage * rewardBalance) / 100;
                    } else {
                        reward = percentage.div(100).mul(rewardBalance);
                    }
                }

                currentStake.reward = reward;
                currentStake.updatedAt = block.timestamp;
            }
        }
        nextRewardTimeStamp = block.timestamp + 7 days;

        emit RewardDeposited(msg.value, msg.sender);
    }

    function withdrawStake(uint256 amount) external payable returns (bool) {
        require(amount > 0 wei, "Send a valid amount to deposit");

        Stake storage currentStake = stakes[msg.sender];

        if (currentStake.isValid) {
            uint256 reward = _calculateReward(currentStake.amount);
            uint256 totalFunds = reward + amount;
            uint256 maxFundsWithdrawable = reward + currentStake.amount;

            // check if address is trying to drain the pool
            require(totalFunds <= maxFundsWithdrawable, "Trying to drain the pool?");

            require(amount <= currentStake.amount, "Withdraw amount Underflow");

            // check if balance of contract has enough funds to release

            (bool sent, ) = payable(msg.sender).call{ value: totalFunds }("");
            require(sent, "Failed to send Ether");

            currentStake.reward = currentStake.reward - reward;
            currentStake.amount = currentStake.amount - amount;
            currentStake.isValid = currentStake.amount > 0;

            _balances[msg.sender] = currentStake.amount;
            rewardBalance = rewardBalance - reward;
            _totalStakesInPool = _totalStakesInPool - amount;

            if (currentStake.amount == 0) removeStakeholder(msg.sender);

            emit Withdrawal(amount, msg.sender);
            return true;
        } else {
            revert("No valid stake");
        }
    }

    function stakeEth() external payable {
        uint256 amount = msg.value;

        require(amount > 0 wei, "Send a valid amount to deposit");

        uint256 currentTimestamp = block.timestamp;

        Stake storage currentStake = stakes[msg.sender];

        if (currentStake.isValid) {
            // add more to the existing stake;
            _balances[msg.sender] = _balances[msg.sender].add(amount);
            _totalStakesInPool = _totalStakesInPool.add(amount);

            currentStake.amount = currentStake.amount.add(amount);
            currentStake.updatedAt = currentTimestamp;
            currentStake.lastDepositAt = block.timestamp;
            stakeCount++;
            emit Staked(amount, msg.sender);
        } else {
            _balances[msg.sender] = _balances[msg.sender].add(amount);
            _totalStakesInPool = _totalStakesInPool.add(amount);

            addStakeholder(msg.sender);
            currentStake.lastDepositAt = block.timestamp;
            uint256 id = stakeCount.add(1);
            currentStake.amount = amount;
            currentStake.createdAt = currentTimestamp;
            currentStake.isValid = true;
            currentStake.reward = 0;
            currentStake.user = msg.sender;
            currentStake.id = id;
            stakeCount = id;

            emit Staked(amount, msg.sender);
        }
    }

    function getReward(address _address) public view returns (uint256) {
        require(_address == address(_address), "Invalid address");

        Stake storage currentStake = stakes[_address];

        require(currentStake.isValid, "No valid stake for address");
        for (uint256 s = 0; s < stakeholders.length; s += 1) {
            if (_address == stakeholders[s]) {
                return _calculateReward(stakes[stakeholders[s]].amount);
            }
        }
        return 0;
    }

    function _calculateReward(uint256 stake) public view returns (uint256) {
        uint256 rewardPercent = stake.mul(100).div(_totalStakesInPool);
        uint256 reward = rewardPercent.mul(rewardBalance).div(100);
        return reward;
    }

    function rewardOf(address _stakeholder) public view returns (uint256) {
        Stake memory stake = stakes[_stakeholder];
        return stake.reward;
    }

    function getStake(address _address)
        public
        view
        returns (
            uint256,
            uint256,
            bool,
            uint256
        )
    {
        require(_address == address(_address), "Invalid address");

        Stake storage currentStake = stakes[_address];

        require(currentStake.isValid, "No valid stake for address");
        return (currentStake.reward, currentStake.amount, currentStake.isValid, currentStake.updatedAt);
    }

    function addStakeholder(address _stakeholder) internal {
        (bool _isStakeholder, ) = isStakeholder(_stakeholder);
        if (!_isStakeholder) stakeholders.push(_stakeholder);
    }

    function removeStakeholder(address _stakeholder) internal {
        (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
        if (_isStakeholder) {
            stakeholders[s] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
            Stake storage stake = stakes[_stakeholder];
            stake.isValid = false;
        }
    }

    function isStakeholder(address _address) public view returns (bool, uint256) {
        for (uint256 s = 0; s < stakeholders.length; s += 1) {
            if (_address == stakeholders[s]) return (true, s);
        }
        return (false, 0);
    }
}