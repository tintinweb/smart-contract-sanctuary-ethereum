/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Pool1 {
    using SafeMath for uint256;

    address internal owner;

    modifier onlyOwner() {
        require(isOwner(msg.sender), "Call not allowed."); _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function getRewardsEarned(address staker) public view returns (uint256) {
        return stakersRewards[staker] + (balance[staker] * rewardsPerBUBLSPerBlock * (block.number - lastUpdate[staker])) / 1e18;
    }

    function getLastUpdate(address staker) public view returns (uint256) {
        return lastUpdate[staker];
    }

    function getStakerBalance(address staker) public view returns (uint256) {
        return balance[staker];
    }

    function receiveEther() external payable {
        ethBalances[msg.sender] += msg.value;
    }

    address public penaltyWallet = (0xC432AA589e8592702cED4A3BF5C692F27b26A6EB);

function emergencyWithdraw() public {
    require(balance[msg.sender] > 0, "You do not have any staked tokens to withdraw!");

    uint256 _lastUpdate = lastUpdate[msg.sender];
    lastUpdate[msg.sender] = block.number;
    stakersRewards[msg.sender] += (balance[msg.sender] * rewardsPerBUBLSPerBlock * (block.number - _lastUpdate)) / 1e18;

    uint256 penaltyAmount = balance[msg.sender] / 2;
    uint256 withdrawalAmount = balance[msg.sender] - penaltyAmount;

    balance[msg.sender] = 0;
    totalLocked -= withdrawalAmount;

    if (balance[msg.sender] == 0) {
        removeStaker(msg.sender);
    }

    // Transfer the withdrawalAmount to the user
    BUBLS.transfer(msg.sender, withdrawalAmount);

    // Transfer the penaltyAmount to the penaltyWallet
    BUBLS.transfer(penaltyWallet, penaltyAmount);
}

    function withdrawETH(uint256 amount) external onlyOwner{
        payable(msg.sender).transfer(amount);
    }

	IERC20 BUBLS = IERC20(0x60801215f63a3CF80114a97F67B6FA259b21aD3D); //Main Net

    uint256 public maximumLocked = 9999999999999999999999 * 1e18;
	uint256 public totalLocked;
    uint256 public rewardsPerBUBLSPerBlock;
    uint256 public stackingStartTime;
    uint256 public launchTime;

 	mapping (address => uint256) stakersRewards;
	mapping (address => uint256) lastUpdate;
	mapping (address => uint256) balance;
    mapping (address => uint256) public ethBalances;

	address[] stakers;
    mapping (address => uint256) stakerIndexes;

    constructor() {
        owner = msg.sender;
        launchTime = block.timestamp;
    }

    function stake(uint256 amount) public {
		require(amount > 0 && totalLocked + amount <= maximumLocked, "The maximum amount of BUBLSs has been staked in this pool.");
		BUBLS.transferFrom(msg.sender, address(this), amount);

		totalLocked += amount;

		uint256 _lastUpdate = lastUpdate[msg.sender];
		lastUpdate[msg.sender] = block.number;

		if (balance[msg.sender] > 0) {
			stakersRewards[msg.sender] += (balance[msg.sender] * rewardsPerBUBLSPerBlock * (block.number - _lastUpdate)) / 1e18;
		} else {
            stackingStartTime = block.timestamp;
			addStaker(msg.sender);
		}

		balance[msg.sender] += amount;

        if (block.timestamp > launchTime + 24 hours) {
            rewardsPerBUBLSPerBlock = rewardsPerBUBLSPerBlock.div(2);
        } 
    }

    function withdraw(uint256 amount) public {
        require(block.timestamp >= stackingStartTime + 1 days, "You can only withdraw after 1 (day test) month of stacking.");
		require(amount > 0 && amount <= balance[msg.sender], "You cannot withdraw more than what you have!");
		uint256 _lastUpdate = lastUpdate[msg.sender];
		lastUpdate[msg.sender] = block.number;
		stakersRewards[msg.sender] += (balance[msg.sender] * rewardsPerBUBLSPerBlock * (block.number - _lastUpdate)) / 1e18;
		balance[msg.sender] -= amount;

		if (balance[msg.sender] == 0) {
			removeStaker(msg.sender);
		}

		BUBLS.transfer(msg.sender, amount);

        totalLocked -= amount;
    }

    function claim() public {
        uint256 _lastUpdate = lastUpdate[msg.sender];
        lastUpdate[msg.sender] = block.number;
        stakersRewards[msg.sender] += (balance[msg.sender] * rewardsPerBUBLSPerBlock * (block.number - _lastUpdate)) / 1e18;
        require(stakersRewards[msg.sender] > 0, "No rewards to claim!");
        uint256 rewards = stakersRewards[msg.sender];
        stakersRewards[msg.sender] = 0;

      
        require(address(this).balance >= rewards, "Not enough Ether to pay out rewards!");

       
        payable(msg.sender).transfer(rewards);
    }

    
	function modifyRewards(uint256 amount) public onlyOwner {

		for (uint256 i = 0; i < stakers.length; i++) {
			uint256 _lastUpdate = lastUpdate[stakers[i]];
			lastUpdate[stakers[i]] = block.number;
			stakersRewards[stakers[i]] += (balance[stakers[i]] * rewardsPerBUBLSPerBlock * (block.number - _lastUpdate)) / 1e18;
		}

		rewardsPerBUBLSPerBlock = amount;

	}

	function addStaker(address staker) internal {
        stakerIndexes[staker] = stakers.length;
        stakers.push(staker);
    }

    function removeStaker(address staker) internal {
        stakers[stakerIndexes[staker]] = stakers[stakers.length-1];
        stakerIndexes[stakers[stakers.length-1]] = stakerIndexes[staker];
        stakers.pop();
    }

}

contract Pool2 {
    using SafeMath for uint256;

    address internal owner;

    modifier onlyOwner() {
        require(isOwner(msg.sender), "Call not allowed."); _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function getRewardsEarned(address staker) public view returns (uint256) {
        return stakersRewards[staker] + (balance[staker] * rewardsPerBUBLSPerBlock * (block.number - lastUpdate[staker])) / 1e18;
    }

    function getLastUpdate(address staker) public view returns (uint256) {
        return lastUpdate[staker];
    }

    function getStakerBalance(address staker) public view returns (uint256) {
        return balance[staker];
    }
    function receiveEther() external payable {
        ethBalances[msg.sender] += msg.value;
    }

	IERC20 BUBLS = IERC20(0x60801215f63a3CF80114a97F67B6FA259b21aD3D); //Main Net

    uint256 public maximumLocked = 9999999999999999999999 * 1e18;
	uint256 public totalLocked;
    uint256 public rewardsPerBUBLSPerBlock;
    uint256 public stackingStartTime;
    uint256 public launchTime;

 	mapping (address => uint256) stakersRewards;
	mapping (address => uint256) lastUpdate;
	mapping (address => uint256) balance;
    mapping (address => uint256) public ethBalances;

	address[] stakers;
    mapping (address => uint256) stakerIndexes;

    constructor() {
        owner = msg.sender;
        launchTime = block.timestamp;
    }

    function stake(uint256 amount) public {
		require(amount > 0 && totalLocked + amount <= maximumLocked, "The maximum amount of BUBLSs has been staked in this pool.");
		BUBLS.transferFrom(msg.sender, address(this), amount);

		totalLocked += amount;

		uint256 _lastUpdate = lastUpdate[msg.sender];
		lastUpdate[msg.sender] = block.number;

		if (balance[msg.sender] > 0) {
			stakersRewards[msg.sender] += (balance[msg.sender] * rewardsPerBUBLSPerBlock * (block.number - _lastUpdate)) / 1e18;
		} else {
            stackingStartTime = block.timestamp;
			addStaker(msg.sender);
		}

		balance[msg.sender] += amount;

        if (block.timestamp > launchTime + 24 hours) {
            rewardsPerBUBLSPerBlock = rewardsPerBUBLSPerBlock.div(2);
        } 
    }

    function withdraw(uint256 amount) public {
        require(block.timestamp >= stackingStartTime + 90 days, "You can only withdraw after 3 month of stacking.");
		require(amount > 0 && amount <= balance[msg.sender], "You cannot withdraw more than what you have!");
		uint256 _lastUpdate = lastUpdate[msg.sender];
		lastUpdate[msg.sender] = block.number;
		stakersRewards[msg.sender] += (balance[msg.sender] * rewardsPerBUBLSPerBlock * (block.number - _lastUpdate)) / 1e18;
		balance[msg.sender] -= amount;

		if (balance[msg.sender] == 0) {
			removeStaker(msg.sender);
		}

		BUBLS.transfer(msg.sender, amount);

        totalLocked -= amount;
    }

    function claim() public {
        uint256 _lastUpdate = lastUpdate[msg.sender];
        lastUpdate[msg.sender] = block.number;
        stakersRewards[msg.sender] += (balance[msg.sender] * rewardsPerBUBLSPerBlock * (block.number - _lastUpdate)) / 1e18;
        require(stakersRewards[msg.sender] > 0, "No rewards to claim!");
        uint256 rewards = stakersRewards[msg.sender];
        stakersRewards[msg.sender] = 0;

      
        require(address(this).balance >= rewards, "Not enough Ether to pay out rewards!");

       
        payable(msg.sender).transfer(rewards);
    }

    
	function modifyRewards(uint256 amount) public onlyOwner {

		for (uint256 i = 0; i < stakers.length; i++) {
			uint256 _lastUpdate = lastUpdate[stakers[i]];
			lastUpdate[stakers[i]] = block.number;
			stakersRewards[stakers[i]] += (balance[stakers[i]] * rewardsPerBUBLSPerBlock * (block.number - _lastUpdate)) / 1e18;
		}

		rewardsPerBUBLSPerBlock = amount;

	}

	function addStaker(address staker) internal {
        stakerIndexes[staker] = stakers.length;
        stakers.push(staker);
    }

    function removeStaker(address staker) internal {
        stakers[stakerIndexes[staker]] = stakers[stakers.length-1];
        stakerIndexes[stakers[stakers.length-1]] = stakerIndexes[staker];
        stakers.pop();
    }

}

contract Pool3 {
    using SafeMath for uint256;

    address internal owner;

    modifier onlyOwner() {
        require(isOwner(msg.sender), "Call not allowed."); _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function getRewardsEarned(address staker) public view returns (uint256) {
        return stakersRewards[staker] + (balance[staker] * rewardsPerBUBLSPerBlock * (block.number - lastUpdate[staker])) / 1e18;
    }

    function getLastUpdate(address staker) public view returns (uint256) {
        return lastUpdate[staker];
    }

    function getStakerBalance(address staker) public view returns (uint256) {
        return balance[staker];
    }
    function receiveEther() external payable {
        ethBalances[msg.sender] += msg.value;
    }


	IERC20 BUBLS = IERC20(0x60801215f63a3CF80114a97F67B6FA259b21aD3D); //Main Net

    uint256 public maximumLocked = 9999999999999999999999 * 1e18;
	uint256 public totalLocked;
    uint256 public rewardsPerBUBLSPerBlock;
    uint256 public stackingStartTime;
    uint256 public launchTime;

 	mapping (address => uint256) stakersRewards;
	mapping (address => uint256) lastUpdate;
	mapping (address => uint256) balance;
    mapping (address => uint256) public ethBalances;

	address[] stakers;
    mapping (address => uint256) stakerIndexes;

    constructor() {
        owner = msg.sender;
        launchTime = block.timestamp;
    }

    function stake(uint256 amount) public {
		require(amount > 0 && totalLocked + amount <= maximumLocked, "The maximum amount of BUBLSs has been staked in this pool.");
		BUBLS.transferFrom(msg.sender, address(this), amount);

		totalLocked += amount;

		uint256 _lastUpdate = lastUpdate[msg.sender];
		lastUpdate[msg.sender] = block.number;

		if (balance[msg.sender] > 0) {
			stakersRewards[msg.sender] += (balance[msg.sender] * rewardsPerBUBLSPerBlock * (block.number - _lastUpdate)) / 1e18;
		} else {
            stackingStartTime = block.timestamp;
			addStaker(msg.sender);
		}

		balance[msg.sender] += amount;

        if (block.timestamp > launchTime + 24 hours) {
            rewardsPerBUBLSPerBlock = rewardsPerBUBLSPerBlock.div(2);
        } 
    }

    function withdraw(uint256 amount) public {
        require(block.timestamp >= stackingStartTime + 180 days, "You can only withdraw after 6 month of stacking.");
		require(amount > 0 && amount <= balance[msg.sender], "You cannot withdraw more than what you have!");
		uint256 _lastUpdate = lastUpdate[msg.sender];
		lastUpdate[msg.sender] = block.number;
		stakersRewards[msg.sender] += (balance[msg.sender] * rewardsPerBUBLSPerBlock * (block.number - _lastUpdate)) / 1e18;
		balance[msg.sender] -= amount;

		if (balance[msg.sender] == 0) {
			removeStaker(msg.sender);
		}

		BUBLS.transfer(msg.sender, amount);

        totalLocked -= amount;
    }

    function claim() public {
        uint256 _lastUpdate = lastUpdate[msg.sender];
        lastUpdate[msg.sender] = block.number;
        stakersRewards[msg.sender] += (balance[msg.sender] * rewardsPerBUBLSPerBlock * (block.number - _lastUpdate)) / 1e18;
        require(stakersRewards[msg.sender] > 0, "No rewards to claim!");
        uint256 rewards = stakersRewards[msg.sender];
        stakersRewards[msg.sender] = 0;

      
        require(address(this).balance >= rewards, "Not enough Ether to pay out rewards!");

       
        payable(msg.sender).transfer(rewards);
    }

    
	function modifyRewards(uint256 amount) public onlyOwner {

		for (uint256 i = 0; i < stakers.length; i++) {
			uint256 _lastUpdate = lastUpdate[stakers[i]];
			lastUpdate[stakers[i]] = block.number;
			stakersRewards[stakers[i]] += (balance[stakers[i]] * rewardsPerBUBLSPerBlock * (block.number - _lastUpdate)) / 1e18;
		}

		rewardsPerBUBLSPerBlock = amount;

	}

	function addStaker(address staker) internal {
        stakerIndexes[staker] = stakers.length;
        stakers.push(staker);
    }

    function removeStaker(address staker) internal {
        stakers[stakerIndexes[staker]] = stakers[stakers.length-1];
        stakerIndexes[stakers[stakers.length-1]] = stakerIndexes[staker];
        stakers.pop();
    }

}

contract Pool4 {
    using SafeMath for uint256;

    address internal owner;

    modifier onlyOwner() {
        require(isOwner(msg.sender), "Call not allowed."); _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function getRewardsEarned(address staker) public view returns (uint256) {
        return stakersRewards[staker] + (balance[staker] * rewardsPerBUBLSPerBlock * (block.number - lastUpdate[staker])) / 1e18;
    }

    function getLastUpdate(address staker) public view returns (uint256) {
        return lastUpdate[staker];
    }

    function getStakerBalance(address staker) public view returns (uint256) {
        return balance[staker];
    }
    function receiveEther() external payable {
        ethBalances[msg.sender] += msg.value;
    }

	IERC20 BUBLS = IERC20(0x60801215f63a3CF80114a97F67B6FA259b21aD3D); //Main Net

    uint256 public maximumLocked = 9999999999999999999999 * 1e18;
	uint256 public totalLocked;
    uint256 public rewardsPerBUBLSPerBlock;
    uint256 public stackingStartTime;
    uint256 public launchTime;

 	mapping (address => uint256) stakersRewards;
	mapping (address => uint256) lastUpdate;
	mapping (address => uint256) balance;
    mapping (address => uint256) public ethBalances;
    
	address[] stakers;
    mapping (address => uint256) stakerIndexes;

    constructor() {
        owner = msg.sender;
        launchTime = block.timestamp;
    }

    function stake(uint256 amount) public {
		require(amount > 0 && totalLocked + amount <= maximumLocked, "The maximum amount of BUBLSs has been staked in this pool.");
		BUBLS.transferFrom(msg.sender, address(this), amount);

		totalLocked += amount;

		uint256 _lastUpdate = lastUpdate[msg.sender];
		lastUpdate[msg.sender] = block.number;

		if (balance[msg.sender] > 0) {
			stakersRewards[msg.sender] += (balance[msg.sender] * rewardsPerBUBLSPerBlock * (block.number - _lastUpdate)) / 1e18;
		} else {
            stackingStartTime = block.timestamp;
			addStaker(msg.sender);
		}

		balance[msg.sender] += amount;

        if (block.timestamp > launchTime + 24 hours) {
            rewardsPerBUBLSPerBlock = rewardsPerBUBLSPerBlock.div(2);
        } 
    }

    function withdraw(uint256 amount) public {
        require(block.timestamp >= stackingStartTime + 365 days, "You can only withdraw after 1 year of stacking.");
		require(amount > 0 && amount <= balance[msg.sender], "You cannot withdraw more than what you have!");
		uint256 _lastUpdate = lastUpdate[msg.sender];
		lastUpdate[msg.sender] = block.number;
		stakersRewards[msg.sender] += (balance[msg.sender] * rewardsPerBUBLSPerBlock * (block.number - _lastUpdate)) / 1e18;
		balance[msg.sender] -= amount;

		if (balance[msg.sender] == 0) {
			removeStaker(msg.sender);
		}

		BUBLS.transfer(msg.sender, amount);

        totalLocked -= amount;
    }

    function claim() public {
        uint256 _lastUpdate = lastUpdate[msg.sender];
        lastUpdate[msg.sender] = block.number;
        stakersRewards[msg.sender] += (balance[msg.sender] * rewardsPerBUBLSPerBlock * (block.number - _lastUpdate)) / 1e18;
        require(stakersRewards[msg.sender] > 0, "No rewards to claim!");
        uint256 rewards = stakersRewards[msg.sender];
        stakersRewards[msg.sender] = 0;

      
        require(address(this).balance >= rewards, "Not enough Ether to pay out rewards!");

       
        payable(msg.sender).transfer(rewards);
    }

    
	function modifyRewards(uint256 amount) public onlyOwner {

		for (uint256 i = 0; i < stakers.length; i++) {
			uint256 _lastUpdate = lastUpdate[stakers[i]];
			lastUpdate[stakers[i]] = block.number;
			stakersRewards[stakers[i]] += (balance[stakers[i]] * rewardsPerBUBLSPerBlock * (block.number - _lastUpdate)) / 1e18;
		}

		rewardsPerBUBLSPerBlock = amount;

	}

	function addStaker(address staker) internal {
        stakerIndexes[staker] = stakers.length;
        stakers.push(staker);
    }

    function removeStaker(address staker) internal {
        stakers[stakerIndexes[staker]] = stakers[stakers.length-1];
        stakerIndexes[stakers[stakers.length-1]] = stakerIndexes[staker];
        stakers.pop();
    }

}