// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "IExtraReward.sol";
import "IERC20.sol";
import "SafeERC20.sol";
import "Math.sol";
import "IGauge.sol";
import "BaseGauge.sol";

import "IVotingEscrow.sol";

/** @title  Gauge stake vault token get YFI rewards
    @notice Deposit your vault token (one gauge per vault).
    YFI are paid based on the number of vault tokens, the veYFI balance, and the duration of the lock.
    @dev this contract is used behind multiple delegate proxies.
 */

contract Gauge is BaseGauge, IGauge {
    using SafeERC20 for IERC20;

    struct Balance {
        uint256 realBalance;
        uint256 boostedBalance;
        uint256 lastDeposit;
        uint256 integrateCheckpointOf;
    }

    struct Appoved {
        bool deposit;
        bool claim;
        bool lock;
    }

    uint256 public boostingFactor = 100;
    uint256 private constant BOOST_DENOMINATOR = 1000;

    IERC20 public stakingToken;
    //// @notice veYFI
    address public veToken;
    //// @notice the veYFI YFI reward pool, penalty are sent to this contract.
    address public veYfiRewardPool;
    //// @notice a copy of the veYFI max lock duration
    uint256 public constant MAX_LOCK = 4 * 365 * 86400;
    uint256 public constant PRECISON_FACTOR = 10**6;
    //// @notice Penalty does not apply for locks expiring after 3y11m

    //// @notice rewardManager is in charge of adding/removing additional rewards
    address public rewardManager;

    /**
    @notice penalty queued to be transferred later to veYfiRewardPool using `transferQueuedPenalty`
    @dev rewards are queued when an account `_updateReward`.
    */
    uint256 public queuedVeYfiRewards;
    uint256 private _totalSupply;
    mapping(address => Balance) private _balances;
    mapping(address => mapping(address => Appoved)) public approvedTo;

    //// @notice list of extraRewards pool.
    address[] public extraRewards;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event AddedExtraReward(address indexed reward);
    event DeletedExtraRewards(address[] rewards);
    event RemovedExtraReward(address indexed reward);
    event UpdatedRewardManager(address indexed rewardManager);
    event UpdatedVeToken(address indexed ve);
    event TransferedQueuedPenalty(uint256 transfered);
    event UpdatedBoostingFactor(uint256 boostingFactor);

    event Initialized(
        address indexed stakingToken,
        address indexed rewardToken,
        address indexed owner,
        address rewardManager,
        address ve,
        address veYfiRewardPool
    );

    /** @notice initialize the contract
     *  @dev Initialize called after contract is cloned.
     *  @param _stakingToken The vault token to stake
     *  @param _rewardToken the reward token YFI
     *  @param _owner owner address
     *  @param _rewardManager reward manager address
     *  @param _ve veYFI address
     *  @param _veYfiRewardPool veYfiRewardPool address
     */
    function initialize(
        address _stakingToken,
        address _rewardToken,
        address _owner,
        address _rewardManager,
        address _ve,
        address _veYfiRewardPool
    ) external initializer {
        require(
            address(_stakingToken) != address(0x0),
            "_stakingToken 0x0 address"
        );
        require(address(_ve) != address(0x0), "_ve 0x0 address");
        require(
            address(_veYfiRewardPool) != address(0x0),
            "_veYfiRewardPool 0x0 address"
        );

        require(_rewardManager != address(0), "_rewardManager 0x0 address");

        __initialize(_rewardToken, _owner);
        stakingToken = IERC20(_stakingToken);
        veToken = _ve;
        rewardManager = _rewardManager;
        veYfiRewardPool = _veYfiRewardPool;

        emit Initialized(
            _stakingToken,
            _rewardToken,
            _owner,
            _rewardManager,
            _ve,
            _veYfiRewardPool
        );
        boostingFactor = 100;
    }

    /**
    @notice Set the veYFI token address.
    @param _veToken the new address of the veYFI token
    */
    function setVe(address _veToken) external onlyOwner {
        require(address(_veToken) != address(0x0), "_veToken 0x0 address");
        veToken = _veToken;
        emit UpdatedVeToken(_veToken);
    }

    /**
    @notice Set the boosting factor.
    @dev the boosting factor is used to calculate your boosting balance using the curve boosting formula adjusted with the boostingFactor
    @param _boostingFactor the value should be between 20 and 500
    */
    function setBoostingFactor(uint256 _boostingFactor) external onlyOwner {
        require(_boostingFactor <= BOOST_DENOMINATOR / 2, "value too high");
        require(_boostingFactor >= BOOST_DENOMINATOR / 50, "value too low");

        boostingFactor = _boostingFactor;
        emit UpdatedBoostingFactor(_boostingFactor);
    }

    /** @return total of the staked vault token
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /** @param _account to look balance for
     *  @return amount of staked token for an account
     */
    function balanceOf(address _account)
        external
        view
        override
        returns (uint256)
    {
        return _balances[_account].realBalance;
    }

    /** @param _account to look balance for
     *  @return amount of staked token for an account
     */
    function snapshotBalanceOf(address _account)
        external
        view
        returns (uint256)
    {
        return _balances[_account].boostedBalance;
    }

    /** @param _account integrateCheckpointOf
     *  @return block number
     */
    function integrateCheckpointOf(address _account)
        external
        view
        returns (uint256)
    {
        return _balances[_account].integrateCheckpointOf;
    }

    /** @return the number of extra rewards pool
     */
    function extraRewardsLength() external view returns (uint256) {
        return extraRewards.length;
    }

    /** @notice add extra rewards to the gauge
     *  @dev can only be done by rewardManager
     *  @param _extraReward the ExtraReward contract address
     *  @return true
     */
    function addExtraReward(address _extraReward) external returns (bool) {
        require(msg.sender == rewardManager, "!authorized");
        require(_extraReward != address(0), "!reward setting");
        for (uint256 i = 0; i < extraRewards.length; ++i) {
            require(extraRewards[i] != _extraReward, "exists");
        }
        emit AddedExtraReward(_extraReward);
        extraRewards.push(_extraReward);
        return true;
    }

    /** @notice remove extra rewards from the gauge
     *  @dev can only be done by rewardManager
     *  @param _extraReward the ExtraReward contract address
     */
    function removeExtraReward(address _extraReward) external returns (bool) {
        require(msg.sender == rewardManager, "!authorized");
        uint256 index = type(uint256).max;
        uint256 length = extraRewards.length;
        for (uint256 i = 0; i < length; ++i) {
            if (extraRewards[i] == _extraReward) {
                index = i;
                break;
            }
        }
        require(index != type(uint256).max, "extra reward not found");
        emit RemovedExtraReward(_extraReward);
        extraRewards[index] = extraRewards[extraRewards.length - 1];
        extraRewards.pop();
        return true;
    }

    /** @notice remove extra rewards
     *  @dev can only be done by rewardManager
     */
    function clearExtraRewards() external {
        require(msg.sender == rewardManager, "!authorized");
        emit DeletedExtraRewards(extraRewards);
        delete extraRewards;
    }

    function _updateReward(address _account) internal override {
        rewardPerTokenStored = _rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (_account != address(0)) {
            if (_balances[_account].boostedBalance != 0) {
                uint256 newEarning = _newEarning(_account);
                uint256 maxEarning = _maxEarning(_account);

                rewards[_account] += newEarning;
                queuedVeYfiRewards += (maxEarning - newEarning);
            }
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
            emit UpdatedRewards(
                _account,
                rewardPerTokenStored,
                lastUpdateTime,
                rewards[_account],
                userRewardPerTokenPaid[_account]
            );
        }
    }

    function _rewardPerToken() internal view override returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            (((lastTimeRewardApplicable() - lastUpdateTime) *
                rewardRate *
                PRECISION_FACTOR) / totalSupply());
    }

    /** @notice earnings for an account
     *  @dev earnings are based on lock duration and boost
     *  @return amount of tokens earned
     */
    function earned(address _account)
        external
        view
        override(BaseGauge, IBaseGauge)
        returns (uint256)
    {
        uint256 newEarning = _newEarning(_account);

        return newEarning + rewards[_account];
    }

    function _newEarning(address _account)
        internal
        view
        override
        returns (uint256)
    {
        return
            (_balances[_account].boostedBalance *
                (_rewardPerToken() - userRewardPerTokenPaid[_account])) /
            PRECISION_FACTOR;
    }

    function _maxEarning(address _account) internal view returns (uint256) {
        return
            (_balances[_account].realBalance *
                (_rewardPerToken() - userRewardPerTokenPaid[_account])) /
            PRECISION_FACTOR;
    }

    /** @notice boosted balance of based on veYFI balance
     *  @return boosted balance
     */
    function boostedBalanceOf(address _account)
        external
        view
        returns (uint256)
    {
        return _boostedBalanceOf(_account);
    }

    function _boostedBalanceOf(address _account)
        internal
        view
        returns (uint256)
    {
        return _boostedBalanceOf(_account, _balances[_account].realBalance);
    }

    function _boostedBalanceOf(address _account, uint256 _realBalance)
        internal
        view
        returns (uint256)
    {
        uint256 veTotalSupply = IVotingEscrow(veToken).totalSupply();
        if (veTotalSupply == 0) {
            return _realBalance;
        }
        return
            Math.min(
                ((_realBalance * boostingFactor) +
                    (((_totalSupply *
                        IVotingEscrow(veToken).balanceOf(_account)) /
                        veTotalSupply) *
                        (BOOST_DENOMINATOR - boostingFactor))) /
                    BOOST_DENOMINATOR,
                _realBalance
            );
    }

    /** @notice deposit vault tokens into the gauge
     * @dev a user without a veYFI should not lock.
     * @dev This call updates claimable rewards
     * @param _amount of vault token
     * @return true
     */
    function deposit(uint256 _amount) external returns (bool) {
        _deposit(msg.sender, _amount);
        return true;
    }

    /** @notice deposit vault tokens into the gauge
     *   @dev a user without a veYFI should not lock.
     *   @dev will deposit the min between user balance and user approval
     *   @dev This call updates claimable rewards
     *   @return true
     */
    function deposit() external returns (bool) {
        uint256 balance = Math.min(
            stakingToken.balanceOf(msg.sender),
            stakingToken.allowance(msg.sender, address(this))
        );
        _deposit(msg.sender, balance);
        return true;
    }

    /** @notice deposit vault tokens into the gauge for a user
     *   @dev vault token is taken from msg.sender
     *   @dev This call update  `_for` claimable rewards
     *   @param _for the account to deposit to
     *    @param _amount to deposit
     *    @return true
     */
    function depositFor(address _for, uint256 _amount) external returns (bool) {
        _deposit(_for, _amount);
        return true;
    }

    function _deposit(address _for, uint256 _amount)
        internal
        updateReward(_for)
    {
        require(_amount != 0, "RewardPool : Cannot deposit 0");
        if (_for != msg.sender) {
            require(approvedTo[msg.sender][_for].deposit, "not allowed");
        }

        //also deposit to linked rewards
        uint256 length = extraRewards.length;
        for (uint256 i = 0; i < length; ++i) {
            IExtraReward(extraRewards[i]).rewardCheckpoint(_for);
        }

        //give to _for
        Balance storage balance = _balances[_for];
        balance.lastDeposit = block.number;

        _totalSupply += _amount;
        uint256 newBalance = balance.realBalance + _amount;
        balance.realBalance = newBalance;
        balance.boostedBalance = _boostedBalanceOf(_for, newBalance);
        balance.integrateCheckpointOf = block.number;

        //take away from sender
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Staked(_for, _amount);
    }

    /** @notice allow an address to deposit on your behalf
     *  @param _addr address to change approval for
     *  @param _canDeposit can deposit
     *  @param _canClaim can deposit
     *  @return true
     */
    function setApprovals(
        address _addr,
        bool _canDeposit,
        bool _canClaim,
        bool _canLock
    ) external returns (bool) {
        approvedTo[_addr][msg.sender].deposit = _canDeposit;
        approvedTo[_addr][msg.sender].claim = _canClaim;
        approvedTo[_addr][msg.sender].lock = _canLock;

        return true;
    }

    /** @notice withdraw vault token from the gauge
     * @dev This call updates claimable rewards
     *  @param _amount amount to withdraw
     *   @param _claim claim veYFI and additional reward
     *   @param _lock should the claimed rewards be locked in veYFI for the user
     *   @return true
     */
    function withdraw(
        uint256 _amount,
        bool _claim,
        bool _lock
    ) public updateReward(msg.sender) returns (bool) {
        require(_amount != 0, "RewardPool : Cannot withdraw 0");
        Balance storage balance = _balances[msg.sender];
        require(
            balance.lastDeposit < block.number,
            "no withdraw on the deposit block"
        );

        //also withdraw from linked rewards
        uint256 length = extraRewards.length;
        for (uint256 i = 0; i < length; ++i) {
            IExtraReward(extraRewards[i]).rewardCheckpoint(msg.sender);
        }

        _totalSupply -= _amount;
        uint256 newBalance = balance.realBalance - _amount;
        balance.realBalance = newBalance;
        balance.boostedBalance = _boostedBalanceOf(msg.sender, newBalance);
        balance.integrateCheckpointOf = block.number;

        if (_claim) {
            _getReward(msg.sender, _lock, true);
        }

        stakingToken.safeTransfer(msg.sender, _amount);
        emit Withdrawn(msg.sender, _amount);

        return true;
    }

    /** @notice withdraw all vault tokens from gauge
     *   @dev This call updates claimable rewards
     *   @param _claim claim veYFI and additional reward
     *   @param _lock should the claimed rewards be locked in veYFI for the user
     *   @return true
     */
    function withdraw(bool _claim, bool _lock) external returns (bool) {
        withdraw(_balances[msg.sender].realBalance, _claim, _lock);
        return true;
    }

    /** @notice withdraw all vault token from gauge
     *  @dev This call update claimable rewards
     *  @param _claim claim veYFI and additional reward
     *  @return true
     */
    function withdraw(bool _claim) external returns (bool) {
        withdraw(_balances[msg.sender].realBalance, _claim, false);
        return true;
    }

    /** @notice withdraw all vault token from gauge
        @dev This call update claimable rewards
        @return true
    */
    function withdraw() external returns (bool) {
        withdraw(_balances[msg.sender].realBalance, false, false);
        return true;
    }

    /**
     * @notice
     *  Get rewards
     * @param _lock should the yfi be locked in veYFI
     * @param _claimExtras claim extra rewards
     * @return true
     */
    function getReward(bool _lock, bool _claimExtras)
        external
        updateReward(msg.sender)
        returns (bool)
    {
        _balances[msg.sender].boostedBalance = _boostedBalanceOf(msg.sender);
        _getReward(msg.sender, _lock, _claimExtras);
        return true;
    }

    /**
     * @notice
     *  Get rewards and claim extra rewards
     *  @param _lock should the yfi be locked in veYFI
     *  @return true
     */
    function getReward(bool _lock)
        external
        updateReward(msg.sender)
        returns (bool)
    {
        _getReward(msg.sender, _lock, true);
        return true;
    }

    /**
     * @notice
     *  Get rewards and claim extra rewards, do not lock YFI earned
     *  @return true
     */
    function getReward() external updateReward(msg.sender) returns (bool) {
        _getReward(msg.sender, false, true);
        return true;
    }

    /**
     * @notice
     *  Get rewards for an account
     * @dev rewards are transferred to _account
     * @param _account to claim rewards for
     * @param _claimExtras claim extra rewards
     * @return true
     */
    function getRewardFor(
        address _account,
        bool _lock,
        bool _claimExtras
    ) external updateReward(_account) returns (bool) {
        if (_account != msg.sender) {
            require(
                approvedTo[msg.sender][_account].claim,
                "not allowed to claim"
            );
            require(
                _lock == false || approvedTo[msg.sender][_account].lock,
                "not allowed to lock"
            );
        }

        _getReward(_account, _lock, _claimExtras);

        return true;
    }

    function _getReward(
        address _account,
        bool _lock,
        bool _claimExtras
    ) internal {
        _balances[_account].boostedBalance = _boostedBalanceOf(_account);
        _balances[_account].integrateCheckpointOf = block.number;

        uint256 reward = rewards[_account];
        if (reward != 0) {
            rewards[_account] = 0;
            if (_lock) {
                rewardToken.approve(address(veToken), reward);
                IVotingEscrow(veToken).deposit_for(_account, reward);
            } else {
                rewardToken.safeTransfer(_account, reward);
            }

            emit RewardPaid(_account, reward);
        }
        //also get rewards from linked rewards
        if (_claimExtras) {
            uint256 length = extraRewards.length;
            for (uint256 i = 0; i < length; ++i) {
                IExtraReward(extraRewards[i]).getRewardFor(_account);
            }
        }
    }

    /**
     * @notice
     * Transfer penalty to the veYFIRewardContract
     * @dev Penalty are queued in this contract.
     * @return true
     */
    function transferVeYfiRewards() external returns (bool) {
        uint256 toTransfer = queuedVeYfiRewards;
        queuedVeYfiRewards = 0;

        IERC20(rewardToken).approve(veYfiRewardPool, toTransfer);
        BaseGauge(veYfiRewardPool).queueNewRewards(toTransfer);
        emit TransferedQueuedPenalty(toTransfer);
        return true;
    }

    /**
     * @notice
     * set reward manager
     * @dev Can be called by rewardManager or owner
     * @param _rewardManager new reward manager
     * @return true
     */
    function setRewardManager(address _rewardManager) external returns (bool) {
        require(
            msg.sender == rewardManager || msg.sender == owner(),
            "!authorized"
        );

        require(_rewardManager != address(0), "_rewardManager 0x0 address");
        rewardManager = _rewardManager;
        emit UpdatedRewardManager(rewardManager);
        return true;
    }

    function _notProtectedTokens(address _token)
        internal
        view
        override
        returns (bool)
    {
        return
            _token != address(rewardToken) && _token != address(stakingToken);
    }

    /**
    @notice Kick `addr` for abusing their boost
    @param _account Address to kick
    */
    function kick(address _account) external updateReward(_account) {
        Balance storage balance = _balances[_account];

        require(
            balance.boostedBalance >
                (balance.realBalance * boostingFactor) / BOOST_DENOMINATOR,
            "min boosted balance"
        );

        balance.boostedBalance = _boostedBalanceOf(
            _account,
            balance.realBalance
        );
        balance.integrateCheckpointOf = block.number;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "IERC20.sol";
import "IBaseGauge.sol";

interface IExtraReward is IBaseGauge {
    function initialize(
        address _gauge,
        address _reward,
        address _owner
    ) external;

    function rewardCheckpoint(address _account) external returns (bool);

    function getRewardFor(address _account) external returns (bool);

    function getReward() external returns (bool);
}

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
pragma solidity 0.8.13;
import "IERC20.sol";

interface IBaseGauge {
    function queueNewRewards(uint256 _amount) external returns (bool);

    function rewardToken() external view returns (IERC20);

    function earned(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "IBaseGauge.sol";

interface IGauge is IBaseGauge {
    function initialize(
        address _stakingToken,
        address _rewardToken,
        address _owner,
        address _rewardManager,
        address _ve,
        address _veYfiRewardPool
    ) external;

    function totalSupply() external view returns (uint256);

    function balanceOf(address _account) external view returns (uint256);

    function boostedBalanceOf(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "IERC20.sol";
import "Math.sol";
import "SafeERC20.sol";
import "Ownable.sol";
import "Initializable.sol";
import "IBaseGauge.sol";

abstract contract BaseGauge is IBaseGauge, Ownable, Initializable {
    IERC20 public override rewardToken;
    //// @notice rewards are distributed over `duration` seconds when queued.
    uint256 public duration;
    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    /**
    @notice that are queued to be distributed on a `queueNewRewards` call
    @dev rewards are queued when an account `_updateReward`.
    */
    uint256 public queuedRewards;
    uint256 public currentRewards;
    uint256 public historicalRewards;
    uint256 public constant PRECISION_FACTOR = 1e18;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardsAdded(
        uint256 currentRewards,
        uint256 lastUpdateTime,
        uint256 periodFinish,
        uint256 rewardRate,
        uint256 historicalRewards
    );

    event RewardsQueued(address indexed from, uint256 amount);

    event RewardPaid(address indexed user, uint256 reward);
    event UpdatedRewards(
        address indexed account,
        uint256 rewardPerTokenStored,
        uint256 lastUpdateTime,
        uint256 rewards,
        uint256 userRewardPerTokenPaid
    );
    event Sweep(address indexed token, uint256 amount);

    event DurationUpdated(
        uint256 duration,
        uint256 rewardRate,
        uint256 periodFinish
    );

    function _newEarning(address) internal view virtual returns (uint256);

    function _updateReward(address) internal virtual;

    function _rewardPerToken() internal view virtual returns (uint256);

    modifier updateReward(address account) {
        _updateReward(account);
        _;
    }

    function __initialize(address _rewardToken, address _owner) internal {
        require(
            address(_rewardToken) != address(0x0),
            "_rewardToken 0x0 address"
        );
        require(_owner != address(0), "_owner 0x0 address");
        rewardToken = IERC20(_rewardToken);
        duration = 14 days;
        _transferOwnership(_owner);
    }

    /**
    @notice set the duration of the reward distribution.
    @param _newDuration duration in seconds. 
     */
    function setDuration(uint256 _newDuration)
        external
        onlyOwner
        updateReward(address(0))
    {
        require(_newDuration != 0, "duration should be greater than zero");
        if (block.timestamp < periodFinish) {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = leftover / _newDuration;
            periodFinish = block.timestamp + _newDuration;
        }
        duration = _newDuration;
        emit DurationUpdated(_newDuration, rewardRate, periodFinish);
    }

    /**
     *  @return timestamp until rewards are distributed
     */
    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    /** @notice reward per token deposited
     *  @dev gives the total amount of rewards distributed since the inception of the pool.
     *  @return rewardPerToken
     */
    function rewardPerToken() external view returns (uint256) {
        return _rewardPerToken();
    }

    function _notProtectedTokens(address _token)
        internal
        view
        virtual
        returns (bool)
    {
        return _token != address(rewardToken);
    }

    /** @notice sweep tokens that are airdropped/transferred into the gauge.
     *  @dev sweep can only be done on non-protected tokens.
     *  @return _token to sweep
     */
    function sweep(address _token) external onlyOwner returns (bool) {
        require(_notProtectedTokens(_token), "protected token");
        uint256 amount = IERC20(_token).balanceOf(address(this));

        SafeERC20.safeTransfer(IERC20(_token), owner(), amount);
        emit Sweep(_token, amount);
        return true;
    }

    /** @notice earnings for an account
     *  @dev earnings are based on lock duration and boost
     *  @return amount of tokens earned
     */
    function earned(address _account) external view virtual returns (uint256) {
        return _newEarning(_account);
    }

    /**
     * @notice
     * Add new rewards to be distributed over a week
     * @dev Trigger reward rate recalculation using `_amount` and queue rewards
     * @param _amount token to add to rewards
     * @return true
     */
    function queueNewRewards(uint256 _amount) external override returns (bool) {
        require(_amount != 0, "==0");
        SafeERC20.safeTransferFrom(
            IERC20(rewardToken),
            msg.sender,
            address(this),
            _amount
        );
        emit RewardsQueued(msg.sender, _amount);
        _amount = _amount + queuedRewards;

        if (block.timestamp >= periodFinish) {
            _notifyRewardAmount(_amount);
            queuedRewards = 0;
            return true;
        }
        uint256 elapsedSinceBeginingOfPeriod = block.timestamp -
            (periodFinish - duration);
        uint256 distributedSoFar = elapsedSinceBeginingOfPeriod * rewardRate;
        // we only restart a new period if _amount is 120% of distributedSoFar.

        if ((distributedSoFar * 12) / 10 < _amount) {
            _notifyRewardAmount(_amount);
            queuedRewards = 0;
        } else {
            queuedRewards = _amount;
        }
        return true;
    }

    function _notifyRewardAmount(uint256 _reward)
        internal
        updateReward(address(0))
    {
        historicalRewards = historicalRewards + _reward;

        if (block.timestamp >= periodFinish) {
            rewardRate = _reward / duration;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            _reward = _reward + leftover;
            rewardRate = _reward / duration;
        }
        currentRewards = _reward;
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + duration;
        emit RewardsAdded(
            currentRewards,
            lastUpdateTime,
            periodFinish,
            rewardRate,
            historicalRewards
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "IERC20.sol";

interface IVotingEscrow is IERC20 {
    struct LockedBalance {
        int128 amount;
        uint256 end;
    }

    function totalSupply() external view returns (uint256);

    function locked__end(address) external view returns (uint256);

    function locked(address) external view returns (LockedBalance memory);

    function deposit_for(address, uint256) external;

    function migration() external view returns (bool);

    function user_point_epoch(address) external view returns (uint256);

    function user_point_history__ts(address, uint256)
        external
        view
        returns (uint256);
}