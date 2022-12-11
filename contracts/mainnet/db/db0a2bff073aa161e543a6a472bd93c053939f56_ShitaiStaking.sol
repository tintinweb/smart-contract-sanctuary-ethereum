/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external;

    function transfer(address to, uint256 value) external;

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external;
}

/// @title Shitai Staking Contract
/// @author Shitai
/// @notice The contract is used to manage staking Shitai tokens.
contract ShitaiStaking {
    using SafeMath for uint256;
    IERC20 public ShitaiToken;
    address public owner;
    uint256 public constant PERCENT_DENOMINATOR = 100000;
    uint256 public constant YEAR = 360 * 1 days; // 30 days for 1 Month
    uint256 public constant DAY = 1 days;

    uint256 public totalStakedToken;
    uint256 public totalUnstakedToken;
    uint256 public totalClaimedRewardToken;
    uint256 public totalStakers;

    uint256[3] public durations = [30 days, 60 days, 90 days]; // lock durations
    uint256[3] public apyBonus = [60000, 90000, 120000];
    uint256[3] public totalStakedPerPlan;
    uint256[3] public totalStakersPerPlan;
    modifier onlyOwner() {
        require(msg.sender == owner, " Not an owner");
        _;
    }

    struct Stake {
        uint256 plan;
        bool unstaked;
        uint256 amount;
        uint256 reward;
        uint256 stakeTime;
        uint256 unlockTime;
        uint256 rewardPerDay;
        uint256 rewardPerWeek;
        uint256 rewardPerSecond;
    }

    struct User {
        uint256 totalStakedTokens;
        uint256 totalUnstakedTokens;
        uint256 totalClaimedRewardTokens;
        uint256 stakeCount;
        mapping(uint256 => Stake) stakingInfo;
    }

    mapping(address => User) public userInfo;
    mapping(address => mapping(uint256 => uint256)) public userStakedPerPlan;

    event STAKE(address Staker, uint256 amount);
    event UNSTAKE(address Staker, uint256 amount, uint256 planID);

    constructor(address _owner, address _TOKEN) {
        owner = _owner;
        ShitaiToken = IERC20(_TOKEN);
    }

    // ========================== Public Functions ==========================

    /// @notice Stake amount in specific plan
    /// @param amount Amount which need to be staked
    /// @param planIndex plan index in which need to staked.
    function stake(uint256 amount, uint256 planIndex) public {
        require(planIndex < durations.length, "Invalid plan");
        require(amount > 0, "Invalid amount");

        if (userInfo[msg.sender].stakeCount == 0) {
            totalStakers++;
        }
        ShitaiToken.transferFrom(msg.sender, address(this), amount);

        uint256 index = ++userInfo[msg.sender].stakeCount;
        Stake storage userStakeInfo = userInfo[msg.sender].stakingInfo[index];

        // update stake record by plan
        userStakeInfo.amount = amount;
        userStakeInfo.stakeTime = block.timestamp;
        userStakeInfo.unlockTime = block.timestamp.add(durations[planIndex]);

        userStakeInfo.reward = (
            amount.mul(apyBonus[planIndex]).div(PERCENT_DENOMINATOR)
        ).div(YEAR.div(durations[planIndex]));
        userStakeInfo.rewardPerSecond = userStakeInfo.reward.div(
            durations[planIndex]
        );
        userStakeInfo.rewardPerDay = userStakeInfo.reward.mul(DAY).div(
            durations[planIndex]
        );
        userStakeInfo.plan = planIndex;

        // per plan info
        userStakedPerPlan[msg.sender][planIndex] = userStakedPerPlan[
            msg.sender
        ][planIndex].add(amount);
        userInfo[msg.sender].totalStakedTokens = userInfo[msg.sender]
            .totalStakedTokens
            .add(amount);

        // Total record
        totalStakedToken = totalStakedToken.add(amount);
        totalStakedPerPlan[planIndex] = totalStakedPerPlan[planIndex].add(
            amount
        );
        totalStakersPerPlan[planIndex]++;

        emit STAKE(msg.sender, amount);
    }

    /// @notice Unstake from specific staked plan
    /// @param index Index id in which need to be unstaked.
    function withdraw(uint256 index) public {
        Stake storage userStakeInfo = userInfo[msg.sender].stakingInfo[index];

        require(!userStakeInfo.unstaked, "already unstaked");
        require(
            index > 0 && index <= userInfo[msg.sender].stakeCount,
            "Invalid index"
        );

        userStakeInfo.unstaked = true;

        uint256 remaingReward = calculateRemainingReward(msg.sender, index);
        ShitaiToken.transfer(msg.sender, userStakeInfo.amount);
        ShitaiToken.transferFrom(owner, msg.sender, remaingReward);

        userInfo[msg.sender].totalUnstakedTokens = userInfo[msg.sender]
            .totalUnstakedTokens
            .add(userStakeInfo.amount);
        userInfo[msg.sender].totalClaimedRewardTokens = userInfo[msg.sender]
            .totalClaimedRewardTokens
            .add(remaingReward);

        userStakedPerPlan[msg.sender][userStakeInfo.plan] = userStakedPerPlan[
            msg.sender
        ][userStakeInfo.plan].sub(userStakeInfo.amount, "Unstake: underflow");
        totalStakedPerPlan[userStakeInfo.plan] = totalStakedPerPlan[
            userStakeInfo.plan
        ].sub(userStakeInfo.amount, "Unstake: underflow");

        totalClaimedRewardToken = totalClaimedRewardToken.add(remaingReward);
        totalUnstakedToken = totalUnstakedToken.add(remaingReward);
        totalStakersPerPlan[userStakeInfo.plan]--;

        emit UNSTAKE(msg.sender, userStakeInfo.amount, index);
    }

    // ========================== View Functions ==========================

    function calculateRemainingReward(address _usr, uint256 index)
        public
        view
        returns (uint256 reward)
    {
        Stake storage userStakeInfo = userInfo[_usr].stakingInfo[index];

        if (block.timestamp < userStakeInfo.unlockTime) {
            uint256 lockHalfTS = userStakeInfo.stakeTime.add(
                durations[userStakeInfo.plan].div(2)
            );

            uint256 rewardDurationInDays = block.timestamp > lockHalfTS
                ? block.timestamp.sub(lockHalfTS).div(DAY)
                : 0;

            reward = userStakeInfo.rewardPerDay.mul(rewardDurationInDays);
        } else {
            reward = userStakeInfo.reward;
        }
    }

    function realtimeReward(address user) public view returns (uint256 ret) {
        User storage _user = userInfo[user];
        for (uint256 i = 1; i <= _user.stakeCount; i++) {
            if (!_user.stakingInfo[i].unstaked) {
                uint256 duration = block.timestamp -
                    _user.stakingInfo[i].stakeTime;
                uint256 currentReward = duration.mul(
                    _user.stakingInfo[i].rewardPerSecond
                );
                if (currentReward < _user.stakingInfo[i].reward) {
                    ret += currentReward;
                } else {
                    ret += _user.stakingInfo[i].reward;
                }
            }
        }
    }

    function getUserInfo(address _usr, uint256 index)
        public
        view
        returns (uint256[6] memory arrData, bool unstaked)
    {
        arrData = [
            userInfo[_usr].stakingInfo[index].plan,
            userInfo[_usr].stakingInfo[index].amount,
            userInfo[_usr].stakingInfo[index].reward,
            userInfo[_usr].stakingInfo[index].rewardPerWeek,
            userInfo[_usr].stakingInfo[index].stakeTime,
            userInfo[_usr].stakingInfo[index].unlockTime
        ];

        return (arrData, userInfo[_usr].stakingInfo[index].unstaked);
    }

    // ========================== Owner's Functions ==========================
    function setStakeDuration(uint256[3] memory _durations) external onlyOwner {
        durations = _durations;
    }

    // transfer ownership
    function changeOwner(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function setStakeBonus(uint256[3] memory _bonuses) external onlyOwner {
        apyBonus = _bonuses;
    }

    function setToken(IERC20 _token) external onlyOwner {
        ShitaiToken = _token;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}