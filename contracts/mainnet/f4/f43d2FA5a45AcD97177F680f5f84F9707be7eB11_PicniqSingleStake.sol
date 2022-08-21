// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./libraries/Math.sol";
import "./utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// solhint-disable not-rely-on-time
contract PicniqSingleStake is Context {

    IERC20 internal immutable _token;

    RewardState private _state;

    uint256 private _totalSupply;
    mapping(address => uint256) private _userRewardPerTokenPaid;
    mapping(address => uint256) private _rewards;
    mapping(address => uint256) private _balances;

    struct RewardState {
        uint8 mutex;
        uint64 periodFinish;
        uint64 rewardsDuration;
        uint64 lastUpdateTime;
        uint160 distributor;
        uint256 rewardRate;
        uint256 rewardPerTokenStored;
    }

    constructor(
        address token,
        address distributor,
        uint64 duration
    ) {
        _state.mutex = 1;
        _state.rewardsDuration = duration;
        _token = IERC20(token);
        _state.distributor = uint160(distributor);
    }

    function rewardToken() external view returns (address) {
        return address(_token);
    }

    function stakingToken() external view returns (address) {
        return address(_token);
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

    function rewardPerToken() public view returns (uint256) {
        uint256 supply = _totalSupply;

        if (supply == 0) {
            return _state.rewardPerTokenStored;
        }

        return
            _state.rewardPerTokenStored +
            (((lastTimeRewardApplicable() - _state.lastUpdateTime) *
                _state.rewardRate *
                1e18) / supply);
    }

    function earned(address account) public view returns (uint256) {
        return
            (_balances[account] *
                (rewardPerToken() - _userRewardPerTokenPaid[account])) /
            1e18 +
            _rewards[account];
    }

    function getRewardForDuration() external view returns (uint256) {
        return _state.rewardRate * _state.rewardsDuration;
    }

    function stake(uint256 amount) external payable updateReward(_msgSender()) {
        require(amount > 0, "Must be greater than 0");

        address sender = _msgSender();

        _token.transferFrom(sender, address(this), amount);

        _totalSupply += amount;
        _balances[sender] += amount;
    }

    function withdraw(uint256 amount) external payable nonReentrant updateReward(_msgSender()) {
        require(amount > 0, "Must be greater than 0");

        address sender = _msgSender();

        _totalSupply -= amount;
        _balances[sender] -= amount;
        _token.transfer(sender, amount);

        emit Withdrawn(sender, amount);
    }

    function getReward() external payable nonReentrant updateReward(_msgSender()) {
        address sender = _msgSender();

        uint256 reward = _rewards[sender];

        if (reward > 0) {
            _rewards[sender] = 0;
            _token.transfer(sender, reward);

            emit RewardPaid(sender, reward);
        }
    }

    function exit() external payable nonReentrant {
        // Logic for updateReward is mixed in for efficiency
        _state.rewardPerTokenStored = rewardPerToken();
        _state.lastUpdateTime = uint64(lastTimeRewardApplicable());

        address sender = _msgSender();

        uint256 reward = earned(sender);
        _userRewardPerTokenPaid[sender] = _state.rewardPerTokenStored;

        uint256 balance = _balances[sender];
        _totalSupply -= balance;
        _balances[sender] = 0;
        _rewards[sender] = 0;

        _token.transfer(sender, balance + reward);

        emit Withdrawn(sender, balance);
        emit RewardPaid(sender, reward);
    }

    function notifyRewardAmount(uint256 reward)
        public
        payable
        onlyDistributor
        updateReward(address(0))
    {
        if (block.timestamp >= _state.periodFinish) {
            _state.rewardRate = reward / _state.rewardsDuration;
        } else {
            uint256 remaining = _state.periodFinish - block.timestamp;
            uint256 leftover = remaining * _state.rewardRate;
            _state.rewardRate =
                (_state.rewardRate + leftover) /
                _state.rewardsDuration;
        }

        uint256 balance = _token.balanceOf(
            address(this)
        ) - _totalSupply;

        require(
            _state.rewardRate <= balance / _state.rewardsDuration,
            "Reward too high"
        );

        _state.lastUpdateTime = uint64(block.timestamp);
        _state.periodFinish = uint64(block.timestamp + _state.rewardsDuration);

        emit RewardAdded(reward);
    }

    function _notifyRewardAmount(uint256 reward, address account) private {
        _updateReward(account);

        if (block.timestamp >= _state.periodFinish) {
            _state.rewardRate = reward / _state.rewardsDuration;
        } else {
            uint256 remaining = _state.periodFinish - block.timestamp;
            uint256 leftover = remaining * _state.rewardRate;
            _state.rewardRate =
                (_state.rewardRate + leftover) /
                _state.rewardsDuration;
        }

        uint256 balance = _token.balanceOf(
            address(this)
        ) - _totalSupply;

        require(
            _state.rewardRate <= balance / _state.rewardsDuration,
            "Reward too high"
        );

        _state.lastUpdateTime = uint64(block.timestamp);
        _state.periodFinish = uint64(block.timestamp + _state.rewardsDuration);

        emit RewardAdded(reward);
    }

    function _updateReward(address account) private {
        _state.rewardPerTokenStored = rewardPerToken();
        _state.lastUpdateTime = uint64(lastTimeRewardApplicable());

        if (account != address(0)) {
            _rewards[account] = earned(account);
            _userRewardPerTokenPaid[account] = _state.rewardPerTokenStored;
        }
    }

    function addRewardTokens(uint256 amount) external onlyDistributor
    {
        _token.transferFrom(_msgSender(), address(this), amount);
        notifyRewardAmount(amount);
    }

    function withdrawRewardTokens() external onlyDistributor
    {
        require(block.timestamp > _state.periodFinish, "Rewards still active");

        uint256 supply = _totalSupply;
        uint256 balance = _token.balanceOf(address(this));

        _token.transfer(address(_state.distributor), balance - supply);
        
        _notifyRewardAmount(0, address(0));
    }

    modifier updateReward(address account) {
        _updateReward(account);
        _;
    }

    modifier onlyDistributor() {
        require(
            _msgSender() == address(_state.distributor),
            "Must be distributor"
        );
        _;
    }

    modifier nonReentrant() {
        require(_state.mutex == 1, "Nonreentrant");
        _state.mutex = 2;
        _;
        _state.mutex = 1;
    }

    /* === EVENTS === */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}