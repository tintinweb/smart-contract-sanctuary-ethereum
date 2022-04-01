/**
 *Submitted for verification at Etherscan.io on 2022-03-31
*/

//SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface Whitelist {
    function isWhitelisted(address account) external view returns (bool);
}

contract PHUNTOKEN_STAKING_UNISWAP_V2 is Ownable {
    IERC20 public rewardToken;
    IERC20 public stakedToken;
    Whitelist public whitelistContract;
    uint256 public totalSupply;
    uint256 public rewardRate;
    uint64 public periodFinish;
    uint64 public lastUpdateTime;
    uint128 public rewardPerTokenStored;
    uint8 public exitPercent;
    address private treasury;
    mapping (address => bool) public whitelist;
    mapping(address => uint256) private _balances;
    struct UserRewards {
        uint128 earnedToDate;
        uint128 userRewardPerTokenPaid;
        uint128 rewards;
    }
    mapping(address => UserRewards) public userRewards;
    string constant _transferErrorMessage = "staked token transfer failed";
    
    event RewardAdded(uint256 reward);
    event RewardPaid(address indexed user, uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event exitStaked(address indexed user);
    event enterStaked(address indexed user);

    constructor(IERC20 _rewardToken, IERC20 _stakedToken, Whitelist _whitelistAddress) {
        rewardToken = _rewardToken;
        stakedToken = _stakedToken;
        whitelistContract = _whitelistAddress;
    }

    modifier onlyWhitelist(address account) {
        require(isWhitelisted(account), "PHTK Staking: User is not whitelisted.");
        _;
    }

    modifier updateReward(address account) {
        uint128 _rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        rewardPerTokenStored = _rewardPerTokenStored;
        userRewards[account].rewards = earned(account);
        userRewards[account].userRewardPerTokenPaid = _rewardPerTokenStored;
        _;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint64) {
        uint64 blockTimestamp = uint64(block.timestamp);
        return blockTimestamp < periodFinish ? blockTimestamp : periodFinish;
    }

    function rewardPerToken() public view returns (uint128) {
        uint256 totalStakedSupply = totalSupply;
        if (totalStakedSupply == 0)
            return rewardPerTokenStored;
        unchecked {
            uint256 rewardDuration = lastTimeRewardApplicable() - lastUpdateTime;
            return uint128(rewardPerTokenStored + rewardDuration * rewardRate * 1e18 / totalStakedSupply);
        }
    }

    function earned(address account) public view returns (uint128) {
        unchecked { 
            return uint128(balanceOf(account) * (rewardPerToken() - userRewards[account].userRewardPerTokenPaid) /1e18 + userRewards[account].rewards);
        }
    }

    function stake(uint128 amount) external payable onlyWhitelist(msg.sender) {
        require(msg.value == 0, "PHTK Staking: Cannot stake any ETH");
        require(amount > 0, "PHTK Staking: Cannot stake 0 Tokens");
        if (_balances[msg.sender] == 0)
            emit enterStaked(msg.sender);
        require(stakedToken.transferFrom(msg.sender, address(this), amount), _transferErrorMessage);
        unchecked { 
            totalSupply += amount;
            _balances[msg.sender] += amount;
        }
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint128 amount) public updateReward(msg.sender) {
        require(amount > 0, "PHTK Staking: Cannot withdraw 0 LP Tokens");
        require(amount <= _balances[msg.sender], "PHTK Staking: Cannot withdraw more LP Tokens than user staking balance");
        unchecked {
            _balances[msg.sender] -= amount;
            totalSupply = totalSupply - amount;
        }
        require(stakedToken.transfer(msg.sender, amount), _transferErrorMessage);
        emit Withdrawn(msg.sender, amount);
        if(amount == _balances[msg.sender])
            emit exitStaked(msg.sender);
    }

    function exit() external {
        claimReward();
        withdraw(uint128(balanceOf(msg.sender)));
        emit exitStaked(msg.sender);
    }

    function claimReward() public updateReward(msg.sender) {
        uint256 reward = earned(msg.sender);
        uint256 tax = 0;
        if(rewardToken.balanceOf(address(this)) <= reward)
            reward = 0;
        if (reward > 0) {
            userRewards[msg.sender].rewards = 0;
            if(exitPercent != 0 && reward != 0){
                tax = reward * exitPercent / 100;
                require(rewardToken.transfer(treasury, tax), "PHTK Staking: Reward transfer failed");
                emit RewardPaid(treasury, tax);
            }
            require(rewardToken.transfer(msg.sender, reward - tax), "PHTK Staking: Reward transfer failed");
            userRewards[msg.sender].earnedToDate += uint128(reward - tax);
            emit RewardPaid(msg.sender, reward - tax);
        }
    }

    function setRewardParams(uint128 reward, uint64 duration) external onlyOwner {
        unchecked {
            require(reward > 0);
            rewardPerTokenStored = rewardPerToken();
            uint64 blockTimestamp = uint64(block.timestamp);
            uint256 maxRewardSupply = rewardToken.balanceOf(address(this));
            if(rewardToken == stakedToken)
                maxRewardSupply -= totalSupply;
            uint256 leftover = 0;
            if (blockTimestamp >= periodFinish) {
                rewardRate = reward/duration;
            } else {
                uint256 remaining = periodFinish-blockTimestamp;
                leftover = remaining*rewardRate;
                rewardRate = (reward+leftover)/duration;
            }
            require(reward+leftover <= maxRewardSupply, "PHTK Staking: Not enough tokens to supply Reward Pool");
            lastUpdateTime = blockTimestamp;
            periodFinish = blockTimestamp+duration;
            emit RewardAdded(reward);
        }
    }

    function withdrawReward() external onlyOwner {
        uint256 rewardSupply = rewardToken.balanceOf(address(this));
        //ensure funds staked by users can't be transferred out - this only transfers reward token back to contract owner
        if(rewardToken == stakedToken)
                rewardSupply -= totalSupply;
        require(rewardToken.transfer(msg.sender, rewardSupply));
        rewardRate = 0;
        periodFinish = uint64(block.timestamp);
    }
    
    function isWhitelisted(address account) public view returns (bool) {
       return whitelistContract.isWhitelisted(account);
    }

    function updateExitStake(uint8 _exitPercent) external onlyOwner() {
        require(_exitPercent <= 20, "PHTK Staking: Exit percent cannot be greater than 20%");
        exitPercent = _exitPercent;
    }

    function updateTreasury(address account) external onlyOwner() {
        treasury = account;
    }
}