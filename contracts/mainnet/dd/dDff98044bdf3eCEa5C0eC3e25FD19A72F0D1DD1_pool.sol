/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Restakes Risk Pool Contract
// https://www.restakes.io

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

// Stake with caution, there is no withdrawal function outside of the claim function.
// Paused staking does not affect claiming rewards.

// Visit the Restakes Github for more information and resources.

contract pool {
    address public tokenAddress; // ERC20 being staked.
    address public treasuryAddress = 0xEe1232171De1A21A54F3581D1fC7F3CC7692aafF; // Treasury.
    address public splitAddress = 0x000000000000000000000000000000000000dEaD; // Burn.
    address public owner; // Contract owner (initialized in constructor as deployer).
    uint256 public rewardPercentage; // Reward generated per hour (as a percentage of staker.amount).
    uint256 public maxStakeAmount; // Maximum amount stakable.
    address public support1 = 0x184644bA0f5A38e45196CC4aBdab051381b96F01;
    address public support2 = 0x0F4AEA1865BEf07c405319C87Bf91F800d6DfEbc;
    bool public stakingPaused = false;

    event TokensStaked(address indexed staker, uint256 _amount, uint256 time);
    event Loss(address indexed staker, uint256 reward, uint256 currentRiskChance, uint256 burnAmount);
    event Win(address indexed staker, uint256 reward, uint256 currentRiskChance);

    struct Staker {
        uint256 amount;
        uint256 time;
        uint256 wins;
        uint256 losses;
    }

    mapping(address => Staker) public stakers;

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
        rewardPercentage = 100; // 100 / 2000
        maxStakeAmount = 10000000000000; // Maximum ammount stakeable
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    modifier notPaused() {
        require(!stakingPaused, "The game is currently paused, you cannot play at this time.");
        _;
    }

    // User stakes an amount of tokens, contract stores current time.
    function stakeTokens(uint256 _amount) public notPaused { 
        Staker storage staker = stakers[msg.sender];
        require(_amount > 0, "Amount cannot be zero");
        require(staker.time == 0, "Complete your current staking cycle first.");
        require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), _amount), "Token transfer failed");
        require(_amount <= maxStakeAmount, "Exceeded maximum stake amount");
        
        staker.amount += _amount;
        if (staker.time == 0) {
            staker.time = block.timestamp; // Set the start time.
        }

        uint256 stakerTime = staker.time;
        emit TokensStaked(msg.sender, _amount, stakerTime);
    }

    // Users claim their rewards to see if they've won or lost.
    function claimReward() public { 
        Staker memory staker = stakers[msg.sender];
        require(staker.amount > 0, "No tokens staked");
        // require(block.timestamp >= staker.time + 1 hours, "You need to stake your tokens for a minimum of 1 hour(s), try again soon.");

        uint256 elapsedTime = (block.timestamp - staker.time);
        uint256 reward = staker.amount + (staker.amount * elapsedTime * rewardPercentage) / (1000 * 3600);

        uint256 currentRiskChance = getCurrentRiskChance(msg.sender);

        if (random() <= currentRiskChance) {
            uint256 burnAmount = staker.amount / 5;
            uint256 trueBurnAmount = burnAmount / 2;
            uint256 treasuryAmount = burnAmount / 2;

            IERC20(tokenAddress).transfer(splitAddress, trueBurnAmount);
            IERC20(tokenAddress).transfer(treasuryAddress, treasuryAmount);
            stakers[msg.sender].amount = 0;
            stakers[msg.sender].time = 0;
            stakers[msg.sender].losses += 1;

            emit Loss(msg.sender, reward, currentRiskChance, burnAmount);
        } else {
            uint256 splitAmount = reward / 20;
            uint256 stakerAmount = reward - splitAmount;

            IERC20(tokenAddress).transfer(treasuryAddress, splitAmount);
            IERC20(tokenAddress).transfer(msg.sender, stakerAmount);
            stakers[msg.sender].amount = 0;
            stakers[msg.sender].time = 0;
            stakers[msg.sender].wins += 1;

            emit Win(msg.sender, reward, currentRiskChance);
        }
    }

    // Get the total risk percentage for a staker's active stake.
    function getCurrentRiskChance(address _staker) public view returns (uint256) {
        Staker memory staker = stakers[_staker];
        require(staker.amount > 0, "No tokens staked");

        uint256 elapsedTime = (block.timestamp - staker.time); // Calculate elapsed time in hours
        uint256 reward = (staker.amount * elapsedTime * rewardPercentage) / (1000 * 3600); // Calculate reward

        uint256 ratio = (reward * 100) / staker.amount; // Calculate the ratio of reward to the staked amount
        uint256 currentChance;

        // The risk scales depending on the ratio of the reward to the staked amount
        if (ratio <= 100) { // Reward is equal or less than staked amount
            currentChance = ratio * 5;
        } else if (ratio <= 200) { // Reward is between 101% and 200% of the staked amount
            currentChance = 510 + ((ratio - 100) * 2);
        } else if (ratio <= 300) { // Reward is between 201% and 300% of the staked amount
            currentChance = 660 + ((ratio - 200) * 2);
        } else if (ratio <= 400) { // Reward is between 301% and 400% of the staked amount
            currentChance = 750 + ((ratio - 300) * 2);
        } else if (ratio <= 500) { // Reward is between 501% and 600% of the staked amount
            currentChance = 800 + ((ratio - 400) * 3);
        } else if (ratio <= 600) { // Reward is between 601% and 700% of the staked amount
            currentChance = 920 + ((ratio - 500) * 3);
        } else { // For higher ratios, set the risk to the maximum
            currentChance = 1000;
        }

        return currentChance;
    }

    function random() private view returns (uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp + block.difficulty +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
            block.gaslimit +
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
            block.number
        )));
        return (seed - ((seed / 1000) * 1000));
    }

    function getFullRewardAmount(address _staker) public view returns (uint256) { // Read reward of staker.
        Staker memory staker = stakers[_staker];
        require(staker.amount > 0, "No tokens staked");

        uint256 elapsedTime = (block.timestamp - staker.time); // Calculate elapsed time in hours
        uint256 reward = staker.amount + (staker.amount * elapsedTime * rewardPercentage) / (1000 * 3600);
        return reward;
    }

    function getGeneratedRewardAmount(address _staker) public view returns (uint256) { // Read reward of staker.
        Staker memory staker = stakers[_staker];
        require(staker.amount > 0, "No tokens staked");

        uint256 elapsedTime = (block.timestamp - staker.time); // Calculate elapsed time in hours
        uint256 reward = (staker.amount * elapsedTime * rewardPercentage) / (1000 * 3600);
        return reward;
    }

    // Update the reward percentage.
    function updateRewardPercentage(uint256 _newPercentage) external onlyOwner { 
        rewardPercentage = _newPercentage;
    }

    // Update maximum staked amount
    function updateMaxStakeAmount(uint256 _newMaxStakeAmount) external onlyOwner {
        maxStakeAmount = _newMaxStakeAmount;
    }

    function updateTreasuryAddress(address _treasuryAddress) external onlyOwner {
        treasuryAddress = _treasuryAddress;
    }

    function updateSplitAddress(address _splitAddress) external onlyOwner { // Update the split address.
        splitAddress = _splitAddress;
    }

    function releaseValve() public onlyOwner { // Remove tokens.
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        require(balance > 0, "Contract has no balance");
        IERC20(tokenAddress).transfer(owner, balance);
    }

    // Support Team: Clear a staker and refund their original stake.
    function supportTool(address _staker) public {
        require(msg.sender == support1 || msg.sender == support2, "Only admins can call this function");
        
        Staker storage staker = stakers[_staker];
        require(staker.amount > 0, "No tokens staked");

        // Refund the staker directly, reset their stake data.
        IERC20(tokenAddress).transfer(_staker, staker.amount);
        staker.amount = 0;
        staker.time = 0;
    }

    // Pause staking to make pool contract upgrades seamless. Doesn't affect claiming.
    function pausePool() external onlyOwner {
        stakingPaused = true;
    }
    
    // Resume staking, probably never needed but precautionary include.
    function resumePool() external onlyOwner {
        stakingPaused = false;
    }
}