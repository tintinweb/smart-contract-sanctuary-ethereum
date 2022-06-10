// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./utils/Interfaces.sol";
import "./utils/MathUtil.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Base Reward Pool contract
/// @dev Rewards contract for Prime Pools is based on the convex contract
contract BaseRewardPool {
    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    error Unauthorized();
    error InvalidAmount();

    uint256 public constant DURATION = 7 days;
    uint256 public constant NEW_REWARD_RATIO = 830;

    // Rewards token is Bal
    IERC20 public immutable rewardToken;
    IERC20 public immutable stakingToken;

    // Operator is Controller smart contract
    address public immutable operator;
    address public immutable rewardManager;

    uint256 public pid;
    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public queuedRewards;
    uint256 public currentRewards;
    uint256 public historicalRewards;
    uint256 private _totalSupply;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) private _balances;

    address[] public extraRewards;

    constructor(
        uint256 pid_,
        address stakingToken_,
        address rewardToken_,
        address operator_,
        address rewardManager_
    ) {
        pid = pid_;
        stakingToken = IERC20(stakingToken_);
        rewardToken = IERC20(rewardToken_);
        operator = operator_;
        rewardManager = rewardManager_;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    modifier onlyAddress(address authorizedAddress) {
        if (msg.sender != authorizedAddress) {
            revert Unauthorized();
        }
        _;
    }

    /// @notice Returns total supply
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /// @notice Get the specified address' balance
    /// @param account The address of the token holder
    /// @return The `account`'s balance
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /// @notice Returns number of extra rewards
    function extraRewardsLength() external view returns (uint256) {
        return extraRewards.length;
    }

    /// @notice Adds an extra reward
    /// @dev only `rewardManager` can add extra rewards
    /// @param _reward token address of the reward
    /// @return true on success
    function addExtraReward(address _reward)
        external
        onlyAddress(rewardManager)
        returns (bool)
    {
        require(_reward != address(0), "!reward setting");
        extraRewards.push(_reward);
        return true;
    }

    /// @notice Returns last time reward applicable
    /// @return The lower value of current block.timestamp or last time reward applicable
    function lastTimeRewardApplicable() public view returns (uint256) {
        // solhint-disable-next-line
        return MathUtil.min(block.timestamp, periodFinish);
    }

    /// @notice Returns rewards per token staked
    /// @return The rewards per token staked
    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            (((lastTimeRewardApplicable() - lastUpdateTime) *
                rewardRate *
                1e18) / totalSupply());
    }

    /// @notice Returns the `account`'s earned rewards
    /// @param account The address of the token holder
    /// @return The `account`'s earned rewards
    function earned(address account) public view returns (uint256) {
        return
            (balanceOf(account) *
                (rewardPerToken() - userRewardPerTokenPaid[account])) /
            1e18 +
            rewards[account];
    }

    /// @notice Stakes `amount` tokens
    /// @param _amount The amount of tokens user wants to stake
    /// @return true on success
    function stake(uint256 _amount)
        public
        updateReward(msg.sender)
        returns (bool)
    {
        if (_amount < 1) {
            revert InvalidAmount();
        }

        stakeToExtraRewards(msg.sender, _amount);

        _totalSupply = _totalSupply + (_amount);
        _balances[msg.sender] = _balances[msg.sender] + (_amount);

        stakingToken.transferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount);

        return true;
    }

    /// @notice Stakes all BAL tokens
    /// @return true on success
    function stakeAll() external returns (bool) {
        uint256 balance = stakingToken.balanceOf(msg.sender);
        stake(balance);
        return true;
    }

    /// @notice Stakes `amount` tokens for `_for`
    /// @param _for Who are we staking for
    /// @param _amount The amount of tokens user wants to stake
    function stakeFor(address _for, uint256 _amount)
        public
        updateReward(_for)
        returns (bool)
    {
        if (_amount < 1) {
            revert InvalidAmount();
        }

        stakeToExtraRewards(_for, _amount);

        _totalSupply = _totalSupply + (_amount);
        // update _for balances
        _balances[_for] = _balances[_for] + (_amount);

        // take away from sender
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        emit Staked(_for, _amount);

        return true;
    }

    /// @notice Unstakes `amount` tokens
    /// @param _amount The amount of tokens that the user wants to withdraw
    /// @param _claim Whether or not the user wants to claim their rewards
    function withdraw(uint256 _amount, bool _claim)
        public
        updateReward(msg.sender)
        returns (bool)
    {
        if (_amount < 1) {
            revert InvalidAmount();
        }

        // withdraw from linked rewards
        withdrawExtraRewards(msg.sender, _amount);

        _totalSupply = _totalSupply - (_amount);
        _balances[msg.sender] = _balances[msg.sender] - (_amount);

        // return staked tokens to sender
        stakingToken.transfer(msg.sender, _amount);
        emit Withdrawn(msg.sender, _amount);

        // claim staking rewards
        if (_claim) {
            getReward(msg.sender, true);
        }

        return true;
    }

    /// @notice Withdraw all tokens
    function withdrawAll(bool _claim) external {
        withdraw(_balances[msg.sender], _claim);
    }

    /// @notice Withdraw `amount` tokens and unwrap
    /// @param _amount The amount of tokens that the user wants to withdraw
    /// @param _claim Whether or not the user wants to claim their rewards
    function withdrawAndUnwrap(uint256 _amount, bool _claim)
        public
        updateReward(msg.sender)
        returns (bool)
    {
        if (_amount < 1) {
            revert InvalidAmount();
        }

        withdrawExtraRewards(msg.sender, _amount);

        _totalSupply = _totalSupply - (_amount);
        _balances[msg.sender] = _balances[msg.sender] - (_amount);

        // tell operator to withdraw from here directly to user
        IDeposit(operator).withdrawTo(pid, _amount, msg.sender);
        emit Withdrawn(msg.sender, _amount);

        //get rewards too
        if (_claim) {
            getReward(msg.sender, true);
        }
        return true;
    }

    /// @notice Withdraw all tokens and unwrap
    /// @param _claim Whether or not the user wants to claim their rewards
    function withdrawAllAndUnwrap(bool _claim) external {
        withdrawAndUnwrap(_balances[msg.sender], _claim);
    }

    /// @notice Claims Rewards for `_account`
    /// @param _account The account to claim rewards for
    /// @param _claimExtras Whether or not the user wants to claim extra rewards
    function getReward(address _account, bool _claimExtras)
        public
        updateReward(_account)
        returns (bool)
    {
        uint256 reward = earned(_account);
        if (reward > 0) {
            rewards[_account] = 0;
            rewardToken.transfer(_account, reward);
            IDeposit(operator).rewardClaimed(pid, _account, reward);
            emit RewardPaid(_account, reward);
        }

        // also get rewards from linked rewards
        if (_claimExtras) {
            address[] memory extraRewardsMemory = extraRewards;
            for (
                uint256 i = 0;
                i < extraRewardsMemory.length;
                i = unsafeInc(i)
            ) {
                IRewards(extraRewardsMemory[i]).getReward(_account);
            }
        }
        return true;
    }

    /// @notice Claims Reward for signer
    /// @return true on success
    function getReward() external returns (bool) {
        getReward(msg.sender, true);
        return true;
    }

    /// @notice Donates reward token to this contract
    /// @param _amount The amount of tokens to donate
    /// @return true on success
    function donate(uint256 _amount) external returns (bool) {
        IERC20(rewardToken).transferFrom(msg.sender, address(this), _amount);
        queuedRewards = queuedRewards + _amount;
        return true;
    }

    /// @notice Queue new rewards
    /// @dev Only the operator can queue new rewards
    /// @param _rewards The amount of tokens to queue
    /// @return true on success
    function queueNewRewards(uint256 _rewards)
        external
        onlyAddress(operator)
        returns (bool)
    {
        _rewards = _rewards + queuedRewards;

        // solhint-disable-next-line
        if (block.timestamp >= periodFinish) {
            notifyRewardAmount(_rewards);
            queuedRewards = 0;
            return true;
        }

        // solhint-disable-next-line
        uint256 elapsedTime = block.timestamp - (periodFinish - DURATION);
        uint256 currentAtNow = rewardRate * elapsedTime;
        uint256 queuedRatio = (currentAtNow * 1000) / _rewards;

        if (queuedRatio < NEW_REWARD_RATIO) {
            notifyRewardAmount(_rewards);
            queuedRewards = 0;
        } else {
            queuedRewards = _rewards;
        }
        return true;
    }

    /// @dev Gas optimization for loops that iterate over extra rewards
    /// We know that this can't overflow because we can't interate over big arrays
    function unsafeInc(uint256 x) internal pure returns (uint256) {
        unchecked {
            return x + 1;
        }
    }

    /// @dev Stakes `amount` tokens for address `for` to extra rewards tokens
    /// RewardManager `rewardManager` is responsible for adding reward tokens
    /// @param _for Who are we staking for
    /// @param _amount The amount of tokens user wants to stake
    function stakeToExtraRewards(address _for, uint256 _amount) internal {
        address[] memory extraRewardsMemory = extraRewards;
        for (uint256 i = 0; i < extraRewardsMemory.length; i = unsafeInc(i)) {
            IRewards(extraRewardsMemory[i]).stake(_for, _amount);
        }
    }

    /// @dev Stakes `amount` tokens for address `for` to extra rewards tokens
    /// RewardManager `rewardManager` is responsible for adding reward tokens
    /// @param _for Who are we staking for
    /// @param _amount The amount of tokens user wants to stake
    function withdrawExtraRewards(address _for, uint256 _amount) internal {
        address[] memory extraRewardsMemory = extraRewards;
        for (uint256 i = 0; i < extraRewardsMemory.length; i = unsafeInc(i)) {
            IRewards(extraRewardsMemory[i]).withdraw(_for, _amount);
        }
    }

    function notifyRewardAmount(uint256 reward)
        internal
        updateReward(address(0))
    {
        historicalRewards = historicalRewards + reward;
        // solhint-disable-next-line
        if (block.timestamp >= periodFinish) {
            rewardRate = reward / DURATION;
        } else {
            // solhint-disable-next-line
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            reward = reward + leftover;
            rewardRate = reward / DURATION;
        }
        currentRewards = reward;
        // solhint-disable-next-line
        lastUpdateTime = block.timestamp;
        // solhint-disable-next-line
        periodFinish = block.timestamp + DURATION;
        emit RewardAdded(reward);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBalGauge {
    function deposit(uint256) external;

    function balanceOf(address) external view returns (uint256);

    function withdraw(uint256) external;

    function claim_rewards() external;

    function reward_tokens(uint256) external view returns (address);

    function lp_token() external view returns (address);
}

interface IBalVoteEscrow {
    function create_lock(uint256, uint256) external;

    function increase_amount(uint256) external;

    function increase_unlock_time(uint256) external;

    function withdraw() external;

    function smart_wallet_checker() external view returns (address);

    function balanceOf(address, uint256) external view returns (uint256);

    function balanceOfAt(address, uint256) external view returns (uint256);
}

interface IWalletChecker {
    function check(address) external view returns (bool);
}

interface IVoting {
    function vote(
        uint256,
        bool,
        bool
    ) external; //voteId, support, executeIfDecided

    function vote_for_gauge_weights(address, uint256) external;
}

interface IMinter {
    function mint(address) external;
}

interface IVoterProxy {
    function deposit(address _token, address _gauge) external;

    function withdrawWethBal(
        address,
        address,
        uint256
    ) external returns (bool);

    function withdraw(IERC20 _asset) external returns (uint256 balance);

    function withdraw(
        address _token,
        address _gauge,
        uint256 _amount
    ) external;

    function withdrawAll(address _token, address _gauge) external;

    function createLock(uint256 _value, uint256 _unlockTime) external;

    function increaseAmount(uint256 _value) external;

    function increaseTime(uint256 _unlockTimestamp) external;

    function release() external;

    function claimBal(address _gauge) external returns (uint256);

    function claimRewards(address _gauge) external;

    function claimFees(address _distroContract, IERC20 _token)
        external
        returns (uint256);

    function setStashAccess(address _stash, bool _status) external;

    function vote(
        uint256 _voteId,
        address _votingAddress,
        bool _support
    ) external;

    function voteGaugeWeight(address _gauge, uint256 _weight) external;

    function balanceOfPool(address _gauge) external view returns (uint256);

    function operator() external view returns (address);

    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external returns (bool, bytes memory);
}

interface IRewards {
    function stake(address, uint256) external;

    function stakeFor(address, uint256) external;

    function withdraw(address, uint256) external;

    function exit(address) external;

    function getReward(address) external;

    function queueNewRewards(uint256) external;

    function notifyRewardAmount(uint256) external;

    function addExtraReward(address) external;

    function stakingToken() external view returns (address);

    function rewardToken() external view returns (address);

    function earned(address account) external view returns (uint256);
}

interface IStash {
    function stashRewards() external returns (bool);

    function processStash() external returns (bool);

    function claimRewards() external returns (bool);

    function initialize(
        uint256 _pid,
        address _operator,
        address _staker,
        address _gauge,
        address _rewardFactory
    ) external;
}

interface IFeeDistro {
    /**
     * @notice Claims all pending distributions of the provided token for a user.
     * @dev It's not necessary to explicitly checkpoint before calling this function, it will ensure the FeeDistributor
     * is up to date before calculating the amount of tokens to be claimed.
     * @param user - The user on behalf of which to claim.
     * @param token - The ERC20 token address to be claimed.
     * @return The amount of `token` sent to `user` as a result of claiming.
     */
    function claimToken(address user, IERC20 token) external returns (uint256);

    /**
     * @notice Claims a number of tokens on behalf of a user.
     * @dev A version of `claimToken` which supports claiming multiple `tokens` on behalf of `user`.
     * See `claimToken` for more details.
     * @param user - The user on behalf of which to claim.
     * @param tokens - An array of ERC20 token addresses to be claimed.
     * @return An array of the amounts of each token in `tokens` sent to `user` as a result of claiming.
     */
    function claimTokens(address user, IERC20[] calldata tokens)
        external
        returns (uint256[] memory);
}

interface ITokenMinter {
    function mint(address, uint256) external;

    function burn(address, uint256) external;
}

interface IDeposit {
    function isShutdown() external view returns (bool);

    function balanceOf(address _account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function poolInfo(uint256)
        external
        view
        returns (
            address,
            address,
            address,
            address,
            address,
            bool
        );

    function rewardClaimed(
        uint256,
        address,
        uint256
    ) external;

    function withdrawTo(
        uint256,
        uint256,
        address
    ) external;

    function claimRewards(uint256, address) external returns (bool);

    function rewardArbitrator() external returns (address);

    function setGaugeRedirect(uint256 _pid) external returns (bool);

    function owner() external returns (address);
}

interface ICrvDeposit {
    function deposit(uint256, bool) external;

    function lockIncentive() external view returns (uint256);
}

interface IRewardFactory {
    function setAccess(address, bool) external;

    function createBalRewards(uint256, address) external returns (address);

    function createTokenRewards(
        address,
        address,
        address
    ) external returns (address);

    function activeRewardCount(address) external view returns (uint256);

    function addActiveReward(address, uint256) external returns (bool);

    function removeActiveReward(address, uint256) external returns (bool);
}

interface IStashFactory {
    function createStash(
        uint256,
        address,
        address
    ) external returns (address);
}

interface ITokenFactory {
    function createDepositToken(address) external returns (address);
}

interface IPools {
    function addPool(address, address) external returns (bool);

    function forceAddPool(address, address) external returns (bool);

    function shutdownPool(uint256) external returns (bool);

    function poolInfo(uint256)
        external
        view
        returns (
            address,
            address,
            address,
            address,
            address,
            bool
        );

    function poolLength() external view returns (uint256);

    function gaugeMap(address) external view returns (bool);

    function setPoolManager(address _poolM) external;
}

interface IVestedEscrow {
    function fund(address[] calldata _recipient, uint256[] calldata _amount)
        external
        returns (bool);
}

interface GaugeController {
    function gauge_types(address _addr) external returns (int128);
}

interface LiquidityGauge {
    function integrate_fraction(address _address) external returns (uint256);

    function user_checkpoint(address _address) external returns (bool);
}

interface IProxyFactory {
    function clone(address _target) external returns (address);
}

interface IRewardHook {
    function onRewardClaim() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// copied from https://github.com/Uniswap/v2-core/blob/master/contracts/libraries/SafeMath.sol

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUtil {
    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /// @dev Gas optimization for loops that iterate over extra rewards
    /// We know that this can't overflow because we can't interate over big arrays
    function unsafeInc(uint256 x) internal pure returns (uint256) {
        unchecked {
            return x + 1;
        }
    }
}