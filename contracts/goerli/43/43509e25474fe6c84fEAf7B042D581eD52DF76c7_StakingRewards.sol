pragma solidity ^0.5.16;

import "./Math.sol";
import "./SafeMath.sol";
//import "./ERC20Detailed.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

// Inheritance
import "./IStakingRewards.sol";
import "./IUniswapV2ERC20.sol";
import "./RewardsDistributionRecipient.sol";

contract StakingRewards is IStakingRewards, RewardsDistributionRecipient, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IERC20 public rewardsToken;
    IERC20 public stakingToken;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration = 60 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    
    address [] public validStakers;
    mapping(address => uint256) private _stakeTimeStamp;
    mapping(address => uint) private _indexOfAccounts; // for valid stakers

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken
    ) public {
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        rewardsDistribution = _rewardsDistribution;
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
            );
    }

    function earned(address account) public view returns (uint256) {
        // earned = stake balance * (rewardPertoken - userRewardPerTokenPaid) / 1e18 + rewards
        // rewardPertoken = rewardPerTokenStored + ( (lastTimeRewardApplicable - lastUpdateTime) * rewardRate  * 1e18 / totalSupply) 
        // userRewardPerTokenPaid = rewardPerTokenStored
        // lastTimeRewardApplicable = min(block.timestamp, periodFinish)

        // updateRewards = update reward = earned 
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stakeWithPermit(uint256 amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);

        // permit
        IUniswapV2ERC20(address(stakingToken)).permit(msg.sender, address(this), amount, deadline, v, r, s);

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function stake(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);

        _entryStake(msg.sender);

        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
               
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
        
        _leaveStake(msg.sender);
        
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() external {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    // https://ethereum.stackexchange.com/questions/1527/how-to-delete-an-element-at-a-certain-index-in-an-array
    // https://ethereum.stackexchange.com/questions/35790/efficient-approach-to-delete-element-from-array-in-solidity 
    function _removeValidStaker(uint index) private {
        require(index < validStakers.length, "valid staker index not valid.");
        validStakers[index] = validStakers[validStakers.length - 1];
        _indexOfAccounts[validStakers[index]] = index;
        validStakers.pop();
    }

    function _entryStake(address account) private {
        if (_balances[account] == 0) {
            validStakers.push(account);
            _indexOfAccounts[account] = validStakers.length - 1;
            _stakeTimeStamp[account] = block.timestamp;
        }
    }

    function _leaveStake(address account) private {
        if (_balances[account] == 0) {
            uint index = _indexOfAccounts[account];
            _removeValidStaker(index);
            _stakeTimeStamp[account] = 0;
        }
    }

    /// refers to IStakingRewards interface
    /// param duration: seconds of a period of time
    function getAccountsByStakingDuration(uint256 duration) external view returns (address [] memory, uint) {
        require(validStakers.length > 0, "valid stakers array has no one");
        uint256 currentTimeStamp = block.timestamp;
        uint count = 0;
        address[] memory _addresses = new address[](validStakers.length);
        for(uint i = 0; i < validStakers.length; i++) {
            address currentAccount = validStakers[i];
            uint256 stakeTimeStamp = _stakeTimeStamp[currentAccount];
            if( stakeTimeStamp > 0) {
                require(currentTimeStamp >=  stakeTimeStamp, "current block timestamp must greater than stake timestamp");
                uint256 currentDuration = currentTimeStamp - stakeTimeStamp;
                if (currentDuration >= duration) {
                    _addresses[count] = currentAccount;
                    count++;
                }
            }
        }

        address[] memory _results = new address[](count);
        for(uint i = 0; i < _results.length; i++) {
            _results[i] = _addresses[i];
        }
        
        return (_results, count);
    }


    function getValidStakersWithWeight() external view returns (address [] memory, uint256 [] memory, uint256 [] memory, uint) {
        require(validStakers.length > 0, "valid stakers array has no one");
        uint256 currentTimeStamp = block.timestamp;
        require(currentTimeStamp < periodFinish, "current Time Stamp must in valid reward time range");
        uint count = 0;
        address[] memory _addresses = new address[](validStakers.length);
        uint256[] memory _balancesWeight = new uint256[](validStakers.length);
        uint256[] memory _timeDurationWeight = new uint256[](validStakers.length);
        for (uint i = 0; i < validStakers.length; i++) {
            address currentAccount = validStakers[i];
            uint256 stakeTimeStamp = _stakeTimeStamp[currentAccount];
            if (currentTimeStamp > stakeTimeStamp) {
                uint256 balance = _balances[currentAccount];
                // https://ethereum.stackexchange.com/questions/55701/how-to-do-solidity-percentage-calculation
                uint256 balanceWeight = balance.mul(1e18).div(_totalSupply);
                uint256 timeDuration = currentTimeStamp - stakeTimeStamp;
                uint256 timeDurationWeight = timeDuration.mul(1e18).div(rewardsDuration);

               _addresses[count] = currentAccount;
               _balancesWeight[count] = balanceWeight;
               _timeDurationWeight[count] = timeDurationWeight;
               count++;

            }
        }

        address[] memory addresses_result = new address[](count);
        uint256[] memory balance_weight_result = new uint256[](count);
        uint256[] memory timeduration_weight_result = new uint256[](count);
        for(uint i = 0; i < count; i++) {
            addresses_result[i] = _addresses[i];
            balance_weight_result[i] = _balancesWeight[i];
            timeduration_weight_result[i] = _timeDurationWeight[i];
        }

        return (addresses_result, balance_weight_result, timeduration_weight_result, count);
    }

    function getWeight(address account) external view returns (uint256, uint256) {
        require(account != address(0), "address must not zero address");
        if(_balances[account] == 0) {
            return (0, 0);
        }

        uint256 currentTimeStamp = block.timestamp;
        require(currentTimeStamp < periodFinish, "current Time Stamp must in valid reward time range");
        uint256 stakeTimeStamp = _stakeTimeStamp[account];
        if (currentTimeStamp > stakeTimeStamp) {
            uint256 balance = _balances[account];
            // https://ethereum.stackexchange.com/questions/55701/how-to-do-solidity-percentage-calculation
            uint256 balanceWeight = balance.mul(1e18).div(_totalSupply);
            uint256 timeDuration = currentTimeStamp - stakeTimeStamp;
            uint256 timeDurationWeight = timeDuration.mul(1e18).div(rewardsDuration);
            return (balanceWeight, timeDurationWeight);
        } else {
            return (0, 0);
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */
    // ony rewardsDistribution call this method
    function notifyRewardAmount(uint256 reward) external onlyRewardsDistribution updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = rewardsToken.balanceOf(address(this));
        require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    // Almost same as notifyRewardAmount
    function notifyRewardAmount2(uint256 _rewardDuration, uint256 _rewardAmount) external onlyRewardsDistribution updateReward(address(0)) {
        rewardsDuration = _rewardDuration;
        uint256 reward = _rewardAmount;

        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = rewardsToken.balanceOf(address(this));
        require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
}