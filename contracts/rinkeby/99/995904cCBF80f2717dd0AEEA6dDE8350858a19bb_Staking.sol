// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "IERC20.sol";
import "SafeERC20.sol";
import "Ownable.sol";
import "IRewardManager.sol";
import "ReentrancyGuard.sol";

/**
 * @notice This contract DOES NOT support Fee-On-Transfer Tokens
 */
contract Staking is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Info of each user
    struct UserInfo {
        uint256 amount; // How many tokens the user has provided
        uint256 rewardDebt; // Reward debt. Same as Sushiswap
    }

    // Info of each pool
    struct PoolInfo {
        IERC20 stakingToken; // Address of token
        uint256 accRewardPerShare; // Accumulated THF token per share, times 1e12
        uint256 lastRewardBlock; // Last block number that THF token distribution occurs
        uint256 allocPoint; // How many allocation points assigned to this pool
        uint256 tokenBalance; // Total balance of this pool
    }

    // Info of each emission schedule
    struct EmissionPoint {
        uint128 startTimeOffset; // start time offset this reward rate is applied
        uint128 rewardsPerSecond; // rate applied to this emission schedule
    }

    bool public paused;

    // Reward manager to manage claimed amount
    // when user claim, pending reward will be vested to Reward Manager and locked there
    // user can withdraw 100% reward after locked period. ex: 12 weeks
    // user can only withdraw 50% reward before locked period. 50% remain will go to Reward Reserve
    address public rewardManager;

    // THF token created per interval for reward
    uint256 public rewardTokenPerInterval;

    // Total allocation points. Must be the sum of all allocation points in all pools
    uint256 public totalAllocPoint;

    // staking start time
    uint256 public startTime;

    uint256 private constant ACC_PRECISION = 1e12;

    // pool -> address -> user info
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Info of each pool
    PoolInfo[] public poolInfo;

    // Info of each emission schedule
    EmissionPoint[] public emissionSchedule;

    // events
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Claim(address indexed user, uint256[] indexed pids, uint256 amount);
    event LogPoolAddition(uint256 indexed pid, uint256 allocPoint, address indexed lpToken);
    event LogSetPool(uint256 indexed pid, uint256 allocPoint);
    event LogUpdatePool(uint256 indexed pid, uint256 lastRewardBlock, uint256 lpSupply, uint256 accRewardPerShare);
    event LogUpdateEmissionRate(address indexed user, uint256 rewardTokenPerInterval);

    event PauseContract(uint256 indexed timestamp);
    event UnpauseContract(uint256 indexed timestamp);
    event RewardManagerUpdated(address indexed rewardManager);
    event StartBlockUpdated(uint256 indexed startTime);

    /**
     * @dev The pause mechanism
     */
    modifier pausable() {
        require(!paused, "PAUSED");
        _;
    }

    /**
     * @dev Constructor
     * @param _rewardManager The address of reward manager contract
     * @param _startTime The timestamp at which staking will begin
     * @param _startTimeOffset Array of duration count from startTime when new staking rates will be applied.
     * @param _rewardsPerSecond Array of staking reward rates
     */
    constructor(
        address _rewardManager,
        uint256 _startTime,
        uint128[] memory _startTimeOffset,
        uint128[] memory _rewardsPerSecond
    ) {
        require(_rewardManager != address(0), "ADDRESS_0");
        require(_startTime > block.timestamp, "INVALID_START_TIME");

        rewardManager = _rewardManager;
        startTime = _startTime;

        require(_startTimeOffset.length == _rewardsPerSecond.length, "INVALID_SCHEDULE");

        unchecked {
            for (uint256 i = _startTimeOffset.length - 1; i + 1 != 0; i--) {
                emissionSchedule.push(
                    EmissionPoint({startTimeOffset : _startTimeOffset[i], rewardsPerSecond : _rewardsPerSecond[i]})
                );
            }
        }
    }

    /**
     * @dev Pause staking functions
     */
    function pause() external onlyOwner {
        paused = true;
        emit PauseContract(block.timestamp);
    }

    /**
     * @dev Unpause staking functions
     */
    function unpause() external onlyOwner {
        paused = false;
        emit UnpauseContract(block.timestamp);
    }

    function poolLength() external view returns (uint256 pools) {
        pools = poolInfo.length;
    }

    /// @notice Add a new LP to the pool. Can only be called by the owner.
    /// @param allocPoint AP of the new pool.
    /// @param _stakingToken Address of the LP ERC-20 token.
    function add(uint256 allocPoint, address _stakingToken) external onlyOwner {

        require(_stakingToken != address(0), "ADDRESS_0");

        // check if the _stakingToken already in another pool
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; pid++) {
            require(address(poolInfo[pid].stakingToken) != _stakingToken, "TOKEN_ALREADY_EXISTS");
        }

        uint256 lastRewardBlock = block.timestamp > startTime ? block.timestamp : startTime;

        // 2.1.1 -> pre-calculating pool info before update totalAllocPoint
        _updateEmissions();
        this.massUpdatePools();
        totalAllocPoint += allocPoint;

        poolInfo.push(
            PoolInfo({
        stakingToken : IERC20(_stakingToken),
        allocPoint : allocPoint,
        lastRewardBlock : lastRewardBlock,
        accRewardPerShare : 0,
        tokenBalance : 0
        })
        );
        emit LogPoolAddition(poolInfo.length - 1, allocPoint, _stakingToken);
    }

    /// @notice Update the given pool's allocation point.
    /// @dev Can only be called by the owner.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _allocPoint New AP of the pool.
    function set(
        uint256 _pid,
        uint256 _allocPoint
    ) external onlyOwner {

        require(_pid < poolInfo.length, "POOL_DOES_NOT_EXIST");

        this.massUpdatePools();

        totalAllocPoint = (totalAllocPoint - poolInfo[_pid].allocPoint) + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        emit LogSetPool(_pid, _allocPoint);
    }

    /// @notice Update RewardManager contract address.
    /// @param _rewardManager The address of the new RewardManager contract.
    function updateRewardManager(address _rewardManager) external onlyOwner {
        require(_rewardManager != address(0), "ADDRESS_ZERO");
        rewardManager = _rewardManager;
        emit RewardManagerUpdated(_rewardManager);
    }

    /// @notice View function to see pending  on frontend.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _user Address of user.
    /// @return pending reward for a given user.
    function pendingReward(uint256 _pid, address _user) external view returns (uint256 pending) {
        require(_pid < poolInfo.length, "POOL_DOES_NOT_EXIST");

        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];

        if (user.amount == 0) {
            return 0;
        }

        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 stakingSupply = pool.tokenBalance;

        if (block.timestamp > pool.lastRewardBlock && stakingSupply != 0) {
            uint256 duration = (block.timestamp - pool.lastRewardBlock);
            uint256 reward = (duration * rewardTokenPerInterval * pool.allocPoint) / totalAllocPoint;
            accRewardPerShare = accRewardPerShare + ((reward * ACC_PRECISION) / stakingSupply);
        }

        if (accRewardPerShare == 0) {
            return 0;
        }

        pending = ((user.amount * accRewardPerShare) / ACC_PRECISION) - user.rewardDebt;
    }

    /// @notice Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() external {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            this.updatePool(pid);
        }
    }

    /// @notice Update reward variables of the given pool.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @return pool Returns the pool that was updated.
    function updatePool(uint256 pid) external returns (PoolInfo memory pool) {
        pool = poolInfo[pid];
        if (block.timestamp > pool.lastRewardBlock) {
            uint256 stakingSupply = pool.tokenBalance;
            if (stakingSupply > 0) {
                uint256 duration = (block.timestamp - pool.lastRewardBlock);
                uint256 reward = (duration * rewardTokenPerInterval * pool.allocPoint) / totalAllocPoint;
                pool.accRewardPerShare = pool.accRewardPerShare + ((reward * ACC_PRECISION) / stakingSupply);
            }
            pool.lastRewardBlock = block.timestamp;
            poolInfo[pid] = pool;
            emit LogUpdatePool(pid, pool.lastRewardBlock, stakingSupply, pool.accRewardPerShare);
        }
    }

    /// @notice Deposit LP tokens for  allocation.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to deposit.
    function deposit(
        uint256 pid,
        uint256 amount
    ) external nonReentrant pausable {

        require(pid < poolInfo.length, "POOL_DOES_NOT_EXIST");

        _updateEmissions();
        PoolInfo memory pool = this.updatePool(pid);
        UserInfo storage user = userInfo[pid][msg.sender];

        // if user is having deposited amount in this pool
        // -> calculate pendingReward and send that amount to rewardManager
        // -> fresh calculation again with new amount
        if (user.amount > 0) {
            uint256 accumulatedReward = (user.amount * pool.accRewardPerShare) / ACC_PRECISION;
            uint256 _pendingReward = accumulatedReward - user.rewardDebt;

            uint256[] memory eventArray = new uint256[](1);
            eventArray[0] = pid;

            if (_pendingReward > 0) {
                bool success = IRewardManager(rewardManager).mint(msg.sender, _pendingReward, true);
                require(success, "TOKEN_MINT_FAILED");
                emit Claim(msg.sender, eventArray, _pendingReward);
            }
        }

        // transfer token from sender to this contract
        // 2.1.2 might cause re-entrance ERC 777 (token has callback hook) -> added nonReentrant modifier
        poolInfo[pid].stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        // increase user amount and re-calculate rewardDebt
        user.amount += amount;
        user.rewardDebt = (user.amount * pool.accRewardPerShare) / ACC_PRECISION;

        // increase pool balance
        poolInfo[pid].tokenBalance += amount;

        emit Deposit(msg.sender, pid, amount);
    }

    /// @notice Withdraw LP tokens.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to withdraw.
    function withdrawAndClaim(
        uint256 pid,
        uint256 amount
    ) external pausable {

        require(amount > 0, "INVALID_AMOUNT");

        require(pid < poolInfo.length, "POOL_DOES_NOT_EXIST");

        UserInfo storage user = userInfo[pid][msg.sender];
        require(user.amount >= amount, "NOT_ENOUGH_AMOUNT");

        _updateEmissions();
        PoolInfo memory pool = this.updatePool(pid);

        // calculate _pendingReward
        uint256 accumulatedReward = (user.amount * pool.accRewardPerShare) / ACC_PRECISION;
        uint256 _pendingReward = accumulatedReward - user.rewardDebt;

        // decrease user amount
        user.amount -= amount;
        // re-calculate rewardDebt
        user.rewardDebt = (user.amount * pool.accRewardPerShare) / ACC_PRECISION;

        // decrease pool balance
        poolInfo[pid].tokenBalance -= amount;

        uint256[] memory eventArray = new uint256[](1);
        eventArray[0] = pid;

        // send _pendingReward amount to rewardManager
        if (_pendingReward > 0) {
            bool success = IRewardManager(rewardManager).mint(msg.sender, _pendingReward, true);
            require(success, "TOKEN_MINT_FAILED");
            emit Claim(msg.sender, eventArray, _pendingReward);
        }

        // transfer token to sender
        pool.stakingToken.safeTransfer(msg.sender, amount);

        emit Withdraw(msg.sender, pid, amount);
    }

    /// @notice Claim reward of multiple pools
    /// @param pids The index of the pool. See `poolInfo`.
    function claim(uint256[] calldata pids) external pausable {
        _updateEmissions();
        uint256 _pendingReward;

        // loop thru all pools and calculate _pendingReward and rewardDebt for each pool
        for (uint256 i = 0; i < pids.length; i++) {

            require(pids[i] < poolInfo.length, "POOL_DOES_NOT_EXIST");

            PoolInfo memory pool = this.updatePool(pids[i]);
            UserInfo storage user = userInfo[pids[i]][msg.sender];

            if (user.amount > 0 && pool.accRewardPerShare > 0) {
                uint256 accumulatedReward = (user.amount * pool.accRewardPerShare) / ACC_PRECISION;
                _pendingReward = _pendingReward + accumulatedReward - user.rewardDebt;

                // update user rewardDebt for this pool
                user.rewardDebt = accumulatedReward;
            }
        }

        // send _pendingReward amount to rewardManager
        if (_pendingReward > 0) {
            bool success = IRewardManager(rewardManager).mint(msg.sender, _pendingReward, true);
            require(success, "TOKEN_MINT_FAILED");
            emit Claim(msg.sender, pids, _pendingReward);
        }
    }

    /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    /// @param pid The index of the pool. See `poolInfo`.
    function emergencyWithdraw(uint256 pid) external {

        require(pid < poolInfo.length, "POOL_DOES_NOT_EXIST");

        UserInfo storage user = userInfo[pid][msg.sender];
        require(user.amount > 0, "AMOUNT_ZERO");

        // re-assign user amount to use in stakingToken.safeTransfer
        uint256 userAmount = user.amount;

        // decrease pool balance
        poolInfo[pid].tokenBalance -= userAmount;

        // reset user values
        user.amount = 0;
        user.rewardDebt = 0;

        // transfer to sender
        poolInfo[pid].stakingToken.safeTransfer(msg.sender, userAmount);
        emit EmergencyWithdraw(msg.sender, pid, userAmount);
    }

    /// @notice Internal function to check if a new emission rate is to be used from the emission rate schedule.
    function _updateEmissions() internal {
        uint256 length = emissionSchedule.length;
        if (length > 0 && (block.timestamp > startTime)) {
            // get the most recent emissionSchedule
            EmissionPoint memory emission = emissionSchedule[length - 1];
            // if the time is passed for this emissionSchedule
            // -> update rewardTokenPerInterval with new rate from rewardTokenPerInterval
            if (block.timestamp - startTime > emission.startTimeOffset) {
                this.massUpdatePools();
                rewardTokenPerInterval = uint256(emission.rewardsPerSecond);
                emissionSchedule.pop();
            }
        }
    }

    /// @notice External function to check if a new emission rate is to be used from the emission rate schedule.
    function updateEmissions() external {
        _updateEmissions();
    }

    /// @notice Update the existing emission rate schedule.
    /// @param _startTimeOffset The time, in seconds, of when the rate of the same index will take place.
    /// @param _rewardsPerSecond The rate at which reward tokens are emitted.
    function updateEmissionSchedule(uint128[] memory _startTimeOffset, uint128[] memory _rewardsPerSecond)
    external
    onlyOwner
    {
        require(
            _startTimeOffset.length == _rewardsPerSecond.length && _startTimeOffset.length == emissionSchedule.length,
            "INVALID_SCHEDULE"
            );
            
    unchecked {
        for (uint256 i = _startTimeOffset.length - 1; i + 1 != 0; i--) {
            emissionSchedule[_startTimeOffset.length - i - 1] = EmissionPoint({
            startTimeOffset : _startTimeOffset[i],
            rewardsPerSecond : _rewardsPerSecond[i]
            });
        }
    }
    }

    /// @notice Returns the current emission schedule.
    function getScheduleLength() external view returns (uint256) {
        return emissionSchedule.length;
    }

    /// @notice Updates a new starttime for staking emissions to begin.
    /// @notice Only update before start of farm
    function updateStartBlock(uint256 _startTime) external onlyOwner {
        require(block.timestamp < startTime, "STAKING_HAS_BEGUN");
        startTime = _startTime;
        emit StartBlockUpdated(_startTime);
    }

    /// @notice Withdraws ERC20 tokens that have been sent directly to the contract.
    function flushLostToken(uint256 pid) external onlyOwner nonReentrant {

        require(pid < poolInfo.length, "POOL_DOES_NOT_EXIST");
        PoolInfo memory pool = poolInfo[pid];
        uint256 amount = poolInfo[pid].stakingToken.balanceOf(address(this)) - pool.tokenBalance;
        if (amount > 0) {
            poolInfo[pid].stakingToken.safeTransfer(msg.sender, amount);
        }
    }
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

pragma solidity ^0.8.9;

interface IRewardManager {
    function addMinter(address _minter) external;

    function removeMinter(address _minter) external;

    function setPenaltyRate(uint256 _penaltyRate) external;

    function setLockDuration(uint256 _durationInSeconds) external;

    function mint(
        address user,
        uint256 amount,
        bool withPenalty
    ) external returns (bool);

    function withdrawUnlocked() external;

    function withdrawAmount(uint256 amount) external;

    function withdrawAll() external;

    function totalBalance(address user) external view returns (uint256 amount);

    function unlockTime(address user) external view returns (uint256 timestamp);

    function unlockedBalance(address user) external view returns (uint256 amount);

    function lockedBalance(address user) external view returns (uint256 amount);

    function withdrawableBalance(address user) external view returns (uint256 amount, uint256 penalizedAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}