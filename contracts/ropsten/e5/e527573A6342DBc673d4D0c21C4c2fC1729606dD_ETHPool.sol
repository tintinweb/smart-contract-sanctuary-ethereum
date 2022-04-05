/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract ETHPool {
    // Used to calculate reward unit since "0 < `RewardUnit` < 1"
    uint public constant MULTIPLIER = 10 ** 18;

    // Represents the address of the team who can reward.
    address public team;

    // Represents how much Ether each user has deposited to the contract.
    mapping(address => uint) public depositByUser;

    // Represents amount of reward per Ether as of last user deposit.
    mapping(address => uint) public lastRewardUnit;

    // Represents how much reward has been calculated for user.
    // Because the unit of reward differs whenever deposit/withdraw happens.
    mapping(address => uint) public calculatedReward;

    // Represents how much Ether has been deposited to the contract by users.
    uint public totalDeposit;

    // Represents how much Ether has been rewarded to the contract by team.
    uint public totalReward;

    // Represents amount of reward per Ether(deposited).
    uint public currentRewardUnit;

    constructor() {
        // Set team to contract deployer by default.
        team = msg.sender;
    }

    // Check if address is not zero.
    modifier validAddress(address _addr) {
        require(_addr != address(0), "Not a valid address");
        _;
    }

    // Check if deposit/reward amount matches the value.
    modifier validAmount(uint _amount) {
        require(msg.value == _amount, "Not valid amount");
        _;
    }

    // Validate team transaction.
    modifier onlyTeam() {
        require(msg.sender == team, "Not team");
        _;
    }

    modifier onlyDepositedUser() {
        require(depositByUser[msg.sender] > 0, "User has no deposit");
        _;
    }

    function changeTeam(address _newTeam) public onlyTeam validAddress(_newTeam) {
        team = _newTeam;
    }

    function deposit(uint _amount) payable public validAmount(_amount) {
        // Calculate reward for the user so far.
        calculatedReward[msg.sender] = calculateReward(msg.sender);

        // Keep track of reward unit.
        lastRewardUnit[msg.sender] = currentRewardUnit;

        // Increase amount.
        depositByUser[msg.sender] += _amount;
        totalDeposit += _amount;
    }

    function withdraw() public onlyDepositedUser {
        uint rewardAmount = calculateReward(msg.sender);
        uint withdrawAmount = depositByUser[msg.sender] + rewardAmount;

        // Decrease amount.
        totalDeposit -= depositByUser[msg.sender];
        totalReward -= rewardAmount;

        // Initialize user records.
        depositByUser[msg.sender] = 0;
        calculatedReward[msg.sender] = 0;
        lastRewardUnit[msg.sender] = 0;

        // Send Ether to the user.
        address payable addrWithdraw = payable(msg.sender);
        addrWithdraw.transfer(withdrawAmount);
    }

    function reward(uint _amount) payable public onlyTeam validAmount(_amount) {
        require(totalDeposit > 0, "No deposit yet");

        totalReward += _amount;
        currentRewardUnit += _amount * MULTIPLIER / totalDeposit;
    }

    // Returns the total amount of deposit and reward.
    // Must be always same with the value from totalETH()
    function totalAmount() public view returns (uint) {
        return totalDeposit + totalReward;
    }

    // Returns the total amount of ETH held in the smart contract.
    // Must be always same with the value from totalAmount()
    function totalETH() public view returns (uint) {
        return address(this).balance;
    }

    function userDeposit() public view returns (uint) {
        return depositByUser[msg.sender];
    }

    function calculateReward(address _addr) private view returns (uint) {
        return calculatedReward[_addr] + depositByUser[_addr] * (currentRewardUnit - lastRewardUnit[_addr]) / MULTIPLIER;
    }
}