//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

///@title ETHPool Challenge
///@author Damilola Edwards
///@notice ETHPool provides a service where people can deposit ETH and they will receive weekly rewards

contract ETHPool {
    ///@notice Address of Deployer & Team account used for making reward deposits
    address public Team;

    ///@notice Total amount of rewards added to the pool throughout the lifetime of the contract
    uint256 public rewardPool;

    ///@notice Total staked amount in the contract as at the last time when reward was added by team
    uint256 public poolShare;

    ///@notice Total balance of ETH currently held in the contract
    uint256 public ETHBalance;

    ///@notice maps user's addresses to thier current balances
    mapping(address => uint256) public balances;

    ///@notice Total reward pool value as at the last time when the user made a deposit
    mapping(address => uint256) public lastEntryPoint;

    event Deposit(
        address indexed sender,
        uint256 amount,
        uint256 restakedAmount
    );

    event Withdrawal(
        address indexed sender,
        uint256 balanceWithdrawn,
        uint256 rewardEarned
    );

    event RewardDeposited(uint256 amount);

    constructor() {
        Team = msg.sender;
    }

    function deposit() public payable {
        if (balances[msg.sender] == 0) {
            lastEntryPoint[msg.sender] = rewardPool;
        }
        //new staking amount = new deposit amount + previous rewards (if any)
        uint256 restakedAmount = msg.value + earnedRewards();
        balances[msg.sender] += restakedAmount;
        ETHBalance += restakedAmount;

        lastEntryPoint[msg.sender] = rewardPool; //updates user's lastEntry point to current reward pool value

        emit Deposit(msg.sender, msg.value, restakedAmount);
    }

    ///@notice The withdraw function transfers all deposited amount + rewards => resets user's balances to zero
    function withdraw() external {
        require(balances[msg.sender] > 0, "Empty wallet balance");
        uint256 reward = earnedRewards();
        uint256 totalAccrued = balances[msg.sender] + reward;
        ETHBalance -= balances[msg.sender];
        balances[msg.sender] = 0;
        (bool sent, ) = msg.sender.call{value: totalAccrued}("");
        require(sent, "Failed to send Ether");

        emit Withdrawal(msg.sender, balances[msg.sender], reward);
    }

    function depositReward() external payable {
        require(msg.sender == Team, "Only team can deposit rewards");
        rewardPool += msg.value;
        poolShare = ETHBalance;

        emit RewardDeposited(msg.value);
    }

    function earnedRewards() internal view returns (uint256) {
        if (balances[msg.sender] == 0) {
            return 0;
        }
        uint256 amount = rewardPool - lastEntryPoint[msg.sender]; //Total rewards accrued since the user's last deposit

        return (balances[msg.sender] * amount) / poolShare; //earned rewards
    }

    receive() external payable {
        deposit();
    }
}