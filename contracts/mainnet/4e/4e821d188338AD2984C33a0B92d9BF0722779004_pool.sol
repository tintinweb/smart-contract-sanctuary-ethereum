/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

// Hats off to Synthetix for their staking contract.
// There's not much left of her here now, but she still hums quietly under the hood.
// https://app.aggressive.wtf

// Stake with caution, there are no withdrawal functions.
// This is an active-risk contract, staked tokens accrue a dynamic risk of loss.
// Paused staking does not affect claiming rewards.

contract pool {
    address public tokenAddress; // ERC20 being staked.
    uint256 public rewardChance; // Risk.
    address public treasuryAddress = 0x6de77170E1F71B80642D55c29f595aC37b91eBf6; // Treasury.
    address public burnAddress = 0x000000000000000000000000000000000000dEaD; // Burn.
    uint256 public rewardPercentage; // Reward generated per hour (as a percentage of staker.amount).
    uint256 public riskModifier; // Additional risk generated per hour (as a flat percentage).
    address public owner; // Contract owner (initialized in constructor as deployer).
    bool public stakingPaused = false; // Pauses the ability to stake, claiming cannot be paused.

    struct Staker {
        uint256 amount;
        uint256 time;
        uint256 wins;
        uint256 losses;
    }

    mapping(address => Staker) public stakers;
    mapping(address => bool) public admins;


    constructor(address _tokenAddress, uint256 _rewardChance) {
        tokenAddress = _tokenAddress;
        rewardChance = _rewardChance;
        rewardPercentage = 35;
        riskModifier = 6;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    modifier notPaused() {
        require(!stakingPaused, "The game is currently paused, you can not play at this time.");
        _;
    }

    modifier onlyAdmin() {
    require(admins[msg.sender], "Only admins can call this function");
    _;
    }

    function stakeTokens(uint256 _amount) public notPaused { // Users stake an amount of tokens.
        Staker storage staker = stakers[msg.sender];
        require(_amount > 0, "Amount cannot be zero");
        require(staker.time == 0, "Complete your current staking cycle first.");
        require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), _amount), "Token transfer failed");
        
        staker.amount += _amount;
        if (staker.time == 0) {
            staker.time = block.timestamp; // Set the start time if it's not already set
        }

        uint256 stakerTime = staker.time;
        emit TokensStaked(msg.sender, _amount, stakerTime);
    }

    event TokensStaked(address indexed staker, uint256 _amount, uint256 time);

    function claimReward() public { // Users claim their rewards to see if they've won or lost.
        Staker memory staker = stakers[msg.sender];
        require(staker.amount > 0, "No tokens staked");
        require(block.timestamp >= staker.time + 0.25 hours, "You need to stake your tokens for a minimum of 15 minutes, try again soon.");

        uint256 elapsedTime = (block.timestamp - staker.time); // Calculate elapsed time in seconds

        uint256 reward = staker.amount + (staker.amount * elapsedTime * rewardPercentage) / (1000 * 900);

        uint256 additionalModifier = (staker.amount * elapsedTime * riskModifier) / (1000 * 3600);
        additionalModifier = additionalModifier / 1000000000000000; // Divide the number for 18 decimals
        
        uint256 trueRewardChance = rewardChance + additionalModifier;

        if (trueRewardChance > 0 && block.timestamp % 10000 < trueRewardChance) { // updated for 18 decimals

            // Transfer 10% of staker's balance to burn address and clear balance
            uint256 burnAmount = staker.amount / 5;
            uint256 trueBurnAmount = burnAmount / 2;
            uint256 treasuryAmount = burnAmount / 2;
            if (burnAmount > 0) {
                IERC20(tokenAddress).transfer(burnAddress, trueBurnAmount);
                IERC20(tokenAddress).transfer(treasuryAddress, treasuryAmount);
            }

            // Clear stakers balance
            stakers[msg.sender].amount = 0;
            stakers[msg.sender].time = 0;
            stakers[msg.sender].losses += 1;
            emit Loss(msg.sender, reward, trueRewardChance, burnAmount);
        } else {

            // Transfer 10% of reward balance to burn address and the rest to the staker
            uint256 splitAmount = reward / 10;
            uint256 stakerAmount = reward - splitAmount;
            
            if (splitAmount > 0) {
                IERC20(tokenAddress).transfer(burnAddress, splitAmount);
            }
            if (stakerAmount > 0) {
                IERC20(tokenAddress).transfer(msg.sender, stakerAmount);
            }

            // Clear stakers balance
            if (staker.amount > 0) {
                stakers[msg.sender].amount = 0;
            }
            if (staker.time > 0) {
                stakers[msg.sender].time = 0;
            }
            stakers[msg.sender].wins += 1;
            emit Win(msg.sender, reward, trueRewardChance);
        }
    }

    event Loss(address indexed staker, uint256 reward, uint256 rewardChance, uint256 burnAmount);
    event Win(address indexed staker, uint256 reward, uint256 rewardChance);

    function updateTreasuryAddress(address _treasuryAddress) external onlyOwner { // Update the split address.
        treasuryAddress = _treasuryAddress;
    }

    function releaseValve() public onlyOwner { // Remove tokens.
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        require(balance > 0, "Contract has no balance");
        IERC20(tokenAddress).transfer(owner, balance);
    }

    function getCurrentRewardAmount(address _staker) public view returns (uint256) { // Read reward of staker.
        Staker memory staker = stakers[_staker];
        require(staker.amount > 0, "No tokens staked");

        uint256 elapsedTime = (block.timestamp - staker.time); // Calculate elapsed time in hours
        uint256 reward = staker.amount + (staker.amount * elapsedTime * rewardPercentage) / (1000 * 900);
        return reward;
    }

    function getCurrentRewardChance(address _staker) public view returns (uint256) { // Read risk of staker.
        Staker memory staker = stakers[_staker];
        require(staker.amount > 0, "No tokens staked");

        uint256 elapsedTime = (block.timestamp - staker.time); // Calculate time staker has staked

        uint256 additionalModifier = (staker.amount * elapsedTime * riskModifier) / (1000 * 3600);
        additionalModifier = additionalModifier / 1000000000000000; // Calc good number
        uint256 currentChance = rewardChance + additionalModifier;
        return currentChance;
    }

    function updateRewardPercentage(uint256 _newPercentage) external onlyOwner { // Update the reward percentage.
        rewardPercentage = _newPercentage;
    }

    function updateRiskModifier(uint256 _newRiskModifier) external onlyOwner { // Update risk modifier.
        riskModifier = _newRiskModifier;
    }

    function getStakerWins(address _staker) public view returns (uint256 wins) { // Read wins of staker.
        Staker memory staker = stakers[_staker];
        wins = staker.wins;
    }

    function getStakerLosses(address _staker) public view returns (uint256 losses) { // Read losses of staker.
        Staker memory staker = stakers[_staker];
        losses = staker.losses;
    }

    function supportTool(address _staker) external onlyAdmin {
        Staker storage staker = stakers[_staker];
        require(staker.amount > 0, "No tokens staked");

        // Transfer the staker's amount back to their wallet
        IERC20(tokenAddress).transfer(_staker, staker.amount);

        // Reset the staker's struct
        staker.amount = 0;
        staker.time = 0;
    }

    function addAdmin(address _admin) external onlyOwner {
        admins[_admin] = true;
    }

    function removeAdmin(address _admin) external onlyOwner {
        admins[_admin] = false;
    }

    function pauseGame() external onlyOwner {
        stakingPaused = true;
    }
    
    function resumeGame() external onlyOwner {
        stakingPaused = false;
    }
}