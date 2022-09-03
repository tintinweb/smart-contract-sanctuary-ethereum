// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract StakingRewards {
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardsToken;

    address public owner;

    // Reward to be paid out per year
    uint public rewardRate;
    // User address => rewardsPaid
    mapping(address => uint) public rewardsPaid;
    // User address => rewardsAccumulated
    mapping(address => uint) public rewardsAccumulated;
    // User address => block number of last applicable transaction
    mapping(address => uint) private latestAction;
    // User address => staked amount
    mapping(address => uint) public balanceOf;
    // Seconds per year (365*24*60*60)
    uint private secondsPerYear;
    // Total staked
    uint public totalSupply;
    

    constructor(address _stakingToken, address _rewardToken) {
        owner = msg.sender;
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardToken);
        secondsPerYear = 365 * 24 * 60 * 60;
        rewardRate = 52; // about the rate to get 1 token per minute at 1,000,000 staked
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not authorized");
        _;
    }
    
    modifier updateReward() {
        // skip first time
        if (latestAction[msg.sender] > 0) {
            uint accumulated = balanceOf[msg.sender] * rewardRate * (block.timestamp - latestAction[msg.sender]) / 100 / secondsPerYear;
            rewardsAccumulated[msg.sender] += accumulated;
        }
        
        latestAction[msg.sender] = block.timestamp;
        _;
    }

    function stake(uint _amount) external updateReward {
        require(_amount > 0, "amount = 0");
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;
    }

    function withdraw(uint _amount) external updateReward {
        require(_amount > 0, "amount = 0");
        require(_amount < balanceOf[msg.sender], "insufficient balance");
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        stakingToken.transfer(msg.sender, _amount);
    }

    function earned() public view returns (uint) {
        return (balanceOf[msg.sender] * rewardRate * (block.timestamp - latestAction[msg.sender]) / 100 / secondsPerYear) + rewardsAccumulated[msg.sender];
    }

    function claimReward() external updateReward {
        uint reward = rewardsAccumulated[msg.sender];
        if (reward > 0) {
            rewardsAccumulated[msg.sender] = 0;
            rewardsPaid[msg.sender] += reward;
            rewardsToken.transfer(msg.sender, reward);
        }
    }

    function setRewardsRate(uint _newRate) external onlyOwner {
        // send as a whold number. Ex: send 32% as 32
        rewardRate = _newRate;
    }

}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}