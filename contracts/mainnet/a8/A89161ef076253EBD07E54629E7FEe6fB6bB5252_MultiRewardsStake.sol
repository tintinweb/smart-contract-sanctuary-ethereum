// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./interfaces/IERC20.sol";
import "./libraries/Math.sol";
import "./libraries/SafeERC20.sol";

// solhint-disable not-rely-on-time
contract MultiRewardsStake {
    using SafeERC20 for IERC20;

    // Base staking info
    IERC20 public stakingToken;
    RewardData private _state;
    address private _owner;

    struct RewardData {
        uint8 mutex;
        uint64 periodFinish;
        uint64 rewardsDuration;
        uint64 lastUpdateTime;
    }

    // User reward info
    mapping(address => mapping(address => uint256))
        private _userRewardPerTokenPaid;
    mapping(address => mapping(address => uint256)) private _rewards;

    // Reward token data
    uint256 private _totalRewardTokens;
    mapping(uint256 => RewardToken) private _rewardTokens;
    mapping(address => uint256) private _rewardTokenToIndex;

    // User deposit data
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    // Store reward token data
    struct RewardToken {
        address token;
        uint256 rewardRate;
        uint256 rewardPerTokenStored;
    }

    constructor(
        address stakingToken_,
        address[] memory rewardTokens_,
        uint64 duration
    ) {
        _owner = msg.sender;
        stakingToken = IERC20(stakingToken_);
        _totalRewardTokens = rewardTokens_.length;

        for (uint256 i; i < rewardTokens_.length; ) {
            _rewardTokens[i + 1].token = rewardTokens_[i];
            _rewardTokenToIndex[rewardTokens_[i]] = i + 1;

            unchecked {
                ++i;
            }
        }

        _state.rewardsDuration = duration;
        _state.mutex = 1;
    }

    /* VIEWS */

    function owner() external view returns (address) {
        return _owner;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, _state.periodFinish);
    }

    function totalRewardTokens() external view returns (uint256) {
        return _totalRewardTokens;
    }

    // Get reward rate for all tokens
    function rewardPerToken() public view returns (uint256[] memory) {
        uint256 totalRewards = _totalRewardTokens;
        uint256[] memory tokens = new uint256[](totalRewards);

        if (_totalSupply == 0) {
            for (uint256 i = 0; i < totalRewards;) {
                tokens[i] = _rewardForToken(i + 1);
                unchecked { ++i; }
            }
        } else {
            for (uint256 i = 0; i < totalRewards;) {
                tokens[i] = _rewardForToken(i + 1);
                unchecked { ++i; }
            }
        }

        return tokens;
    }

    // Get reward rate for individual token
    function rewardForToken(address token) public view returns (uint256) {
        uint256 index = _rewardTokenToIndex[token];
        return _rewardForToken(index);
    }

    function _rewardForToken(uint256 index) private view returns (uint256) {
        RewardToken memory rewardToken = _rewardTokens[index];
        uint256 supply = _totalSupply;

        if (supply == 0) {
            return rewardToken.rewardPerTokenStored;
        } else {
            return rewardToken.rewardPerTokenStored +
                    (((lastTimeRewardApplicable() - _state.lastUpdateTime) *
                        rewardToken.rewardRate *
                        1e18) / supply);
        }
    }

    function getRewardTokens() public view returns (RewardToken[] memory) {
        uint256 totalTokens = _totalRewardTokens;
        RewardToken[] memory tokens = new RewardToken[](totalTokens);

        for (uint256 i = 0; i < totalTokens;) {
            tokens[i] = _rewardTokens[i + 1];
            unchecked { ++i; }
        }

        return tokens;
    }

    function earned(address account) public view returns (uint256[] memory) {
        uint256 totalTokens = _totalRewardTokens;
        uint256[] memory earnings = new uint256[](totalTokens);

        for (uint256 i = 0; i < totalTokens;) {
            earnings[i] = _earned(account, i + 1);
            unchecked { ++i; }
        }

        return earnings;
    }

    function _earned(address account, uint256 index) private view returns (uint256)
    {
        uint256 reward = _rewardForToken(index);
        address token = _rewardTokens[index].token;
        
        return _balances[account] * (reward - _userRewardPerTokenPaid[account][token]) / 1e18 + _rewards[account][token];
    }

    function getRewardForDuration() external view returns (uint256[] memory) {
        uint256 totalTokens = _totalRewardTokens;
        uint256[] memory currentRewards = new uint256[](totalTokens);

        for (uint256 i = 0; i < totalTokens;) {
            currentRewards[i] = _rewardTokens[i + 1].rewardRate * _state.rewardsDuration;
            unchecked { ++i; }
        }

        return currentRewards;
    }

    /* === MUTATIONS === */

    function stake(uint256 amount)
        external
        nonReentrant
        updateReward(msg.sender)
    {
        require(amount > 0, "Cannot stake 0");

        uint256 currentBalance = stakingToken.balanceOf(address(this));

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        uint256 newBalance = stakingToken.balanceOf(address(this));
        uint256 supplyDiff = newBalance - currentBalance;

        _totalSupply += supplyDiff;
        _balances[msg.sender] += supplyDiff;

        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount)
        public
        nonReentrant
        updateReward(msg.sender)
    {
        require(amount > 0, "Cannot withdraw 0");

        _totalSupply -= amount;
        _balances[msg.sender] -= amount;

        stakingToken.safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public nonReentrant {

        for (uint256 i = 0; i < _totalRewardTokens;) {
            _updateReward(msg.sender, i + 1);

            address token = _rewardTokens[i + 1].token;

            uint256 currentReward = _rewards[msg.sender][token];

            if (currentReward > 0) {
                _rewards[msg.sender][token] = 0;

                IERC20(token).safeTransfer(
                    msg.sender,
                    currentReward
                );

                emit RewardPaid(msg.sender, token, currentReward);
            }

            unchecked { ++i; }
        }

        _state.lastUpdateTime = uint64(lastTimeRewardApplicable());
    }

    function exit() external {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    /* === RESTRICTED FUNCTIONS === */

    function depositRewardTokens(uint256[] memory amount) external onlyOwner {
        require(amount.length == _totalRewardTokens, "Wrong amounts");

        for (uint256 i = 0; i < _totalRewardTokens;) {
            RewardToken storage rewardToken = _rewardTokens[i + 1];

            uint256 prevBalance = IERC20(rewardToken.token).balanceOf(
                address(this)
            );

            IERC20(rewardToken.token).safeTransferFrom(
                msg.sender,
                address(this),
                amount[i]
            );

            uint256 reward = IERC20(rewardToken.token).balanceOf(address(this)) - prevBalance;

            if (block.timestamp >= _state.periodFinish) {
                rewardToken.rewardRate = reward / _state.rewardsDuration;
            } else {
                uint256 remaining = _state.periodFinish - block.timestamp;
                uint256 leftover = remaining * rewardToken.rewardRate;
                rewardToken.rewardRate = (reward + leftover) / _state.rewardsDuration;
            }

            uint256 balance = IERC20(rewardToken.token).balanceOf(
                address(this)
            );

            require(
                rewardToken.rewardRate <= balance / _state.rewardsDuration,
                "Reward too high"
            );

            emit RewardAdded(reward);

            unchecked { ++i; }
        }

        _state.lastUpdateTime = uint64(block.timestamp);
        _state.periodFinish = uint64(block.timestamp + _state.rewardsDuration);
    }

    function notifyRewardAmount(uint256[] memory reward)
        public
        onlyOwner
    {
        require(reward.length == _totalRewardTokens, "Wrong reward amounts");
        for (uint256 i = 0; i < _totalRewardTokens;) {
            _updateReward(address(0), i + 1);
            RewardToken storage rewardToken = _rewardTokens[i + 1];
            if (block.timestamp >= _state.periodFinish) {
                rewardToken.rewardRate = reward[i] / _state.rewardsDuration;
            } else {
                uint256 remaining = _state.periodFinish - block.timestamp;
                uint256 leftover = remaining * rewardToken.rewardRate;
                rewardToken.rewardRate = (reward[i] + leftover) / _state.rewardsDuration;
            }

            uint256 balance = IERC20(rewardToken.token).balanceOf(address(this));

            require(
                rewardToken.rewardRate <= balance / _state.rewardsDuration,
                "Reward too high"
            );

            emit RewardAdded(reward[i]);

            unchecked { ++i; }
        }

        _state.lastUpdateTime = uint64(block.timestamp);
        _state.periodFinish = uint64(block.timestamp + _state.rewardsDuration);
    }

    function addRewardToken(address token) external onlyOwner {
        require(_totalRewardTokens < 6, "Too many tokens");
        require(
            IERC20(token).balanceOf(address(this)) > 0,
            "Must prefund contract"
        );

        uint256 newTotal = _totalRewardTokens + 1;

        // Increment total reward tokens
        _totalRewardTokens = newTotal;

        // Create new reward token record
        _rewardTokens[newTotal].token = token;

        _rewardTokenToIndex[token] = newTotal;

        uint256[] memory rewardAmounts = new uint256[](newTotal);
        uint256 rewardAmount = IERC20(token).balanceOf(address(this));

        if (token == address(stakingToken)) {
            rewardAmount -= _totalSupply;
        }

        rewardAmounts[newTotal - 1] = rewardAmount;

        notifyRewardAmount(rewardAmounts);
    }

    function removeRewardToken(address token)
        public
        onlyOwner
        updateReward(address(0))
    {
        require(_totalRewardTokens > 1, "Cannot have 0 reward tokens");
        // Get the index of token to remove
        uint256 indexToDelete = _rewardTokenToIndex[token];
        uint256 existingTotal = _totalRewardTokens;
        _totalRewardTokens -= 1;

        uint256 amount = IERC20(token).balanceOf(address(this));
        if (token == address(stakingToken)) {
            amount -= _totalSupply;
        }
        _withdrawTokens(token, amount);

        // Start at index of token to remove. Remove token and move all later indices lower.
        for (uint256 i = indexToDelete; i <= existingTotal;) {
            // Get token of one later index
            RewardToken storage rewardToken = _rewardTokens[i + 1];

            // Overwrite existing index with index + 1 record
            _rewardTokens[i] = rewardToken;

            // Set new index
            _rewardTokenToIndex[rewardToken.token] = i;

            // Delete original
            delete _rewardTokens[i + 1];

            unchecked { ++i; }
        }
    }

    function emergencyWithdrawal(address token)
        external
        onlyOwner
    {
        uint256 balance = IERC20(token).balanceOf(address(this));

        require(balance > 0, "Contract holds no tokens");

        uint256 index = _rewardTokenToIndex[token];

        if (_rewardTokenToIndex[token] != 0) {
            require(_state.periodFinish < block.timestamp, "Period still active");
            _rewardTokens[index].rewardRate = 0;
            _rewardTokens[index].rewardPerTokenStored = 0;
            if (token == address(stakingToken)) {
                _withdrawTokens(token, balance - _totalSupply);
            }  else {
                _withdrawTokens(token, balance);
            }
        } else {
            _withdrawTokens(token, balance);
        }
    }

    function _withdrawTokens(address token, uint256 amount) private
    {
        IERC20(token).safeTransfer(_owner, amount);
    }

    function _updateReward(address account, uint256 index) private
    {
        uint256 tokenReward = _rewardForToken(index);
        uint256 currentEarned = _earned(account, index);
        RewardToken storage rewardToken = _rewardTokens[index];
        rewardToken.rewardPerTokenStored = tokenReward;

        if (account != address(0)) {
            _rewards[account][rewardToken.token] = currentEarned;
            _userRewardPerTokenPaid[account][rewardToken.token] = tokenReward;            
        }

    }

    function transferOwnership(address newOwner) external onlyOwner
    {
        require(newOwner != address(0), "Owner cannot be zero addr");

        address oldOwner = _owner;
        _owner = newOwner;

        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /* === MODIFIERS === */

    modifier updateReward(address account) {
        for (uint256 i = 0; i < _totalRewardTokens;) {
            _updateReward(account, i + 1);
            unchecked { ++i; }
        }
        _state.lastUpdateTime = uint64(lastTimeRewardApplicable());
        _;
    }

    modifier nonReentrant() {
        require(_state.mutex == 1, "Nonreentrant");
        _state.mutex = 2;
        _;
        _state.mutex = 1;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not owner");
        _;
    }

    /* === EVENTS === */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, address indexed token, uint256 reward);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Returns the amount of decimals in the token
     */
    function decimals() external view returns (uint256);

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
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "./Address.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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