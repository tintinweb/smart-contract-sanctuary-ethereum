/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

// File: contracts/ETHPool.sol


pragma solidity ^0.8.13;

/**
 * ETHPool contract.
 * Users accrue reward per round.
 * Users balance does not carry forward to new rounds.
 *
 */
contract Contract {
    address public owner;
    uint256 counter;

    mapping(address => mapping(uint256 => uint256)) public balance;
    mapping(uint256 => uint256) totalBalance;
    mapping(uint256 => uint256) rewards;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function depositETH() public payable {
        balance[msg.sender][counter] += msg.value;
        totalBalance[counter] += msg.value;
    }

    function depositRewards() public payable onlyOwner {
        rewards[counter++] = msg.value;
    }

    function withdraw(uint256 _rewardRound) public {
        uint256 userBalance = balance[msg.sender][_rewardRound];
        require(userBalance != 0, "User has already withdrawn or never deposited");

        uint256 totalBalanceOfRound = totalBalance[_rewardRound];
        uint256 rewardsOfRound = rewards[_rewardRound];
        uint256 userRewards = (userBalance * rewardsOfRound) / totalBalanceOfRound;

        balance[msg.sender][_rewardRound] = 0;

        payable(msg.sender).send(userBalance + userRewards); // avoid reverting with transfer.
    }
}