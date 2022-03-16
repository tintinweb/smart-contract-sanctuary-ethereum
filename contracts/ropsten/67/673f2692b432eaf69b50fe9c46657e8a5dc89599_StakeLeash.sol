//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StakeLeash {
    uint256 public constant STAKE_MIN = 1 * 10**18;
    uint256 public constant STAKE_MAX = 1000 * 10**18;
    uint256 public constant DAYS_MIN = 1;
    uint256 public constant DAYS_MAX = 100;

    IERC20 public immutable LEASH;

    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 duration;
    }

    mapping(address => Stake) private _stakeOf;

    constructor(address _leash) {
        LEASH = IERC20(_leash);
    }

    function stakeOf(address user)
        public
        view
        returns (
            uint256 amount,
            uint256 startTime,
            uint256 duration
        )
    {
        return (
            _stakeOf[user].amount,
            _stakeOf[user].startTime,
            _stakeOf[user].duration
        );
    }

    function weightOf(address user) public view returns (uint256) {
        return _stakeOf[user].amount * _stakeOf[user].duration;
    }

    function extraStakeNeeded(address user, uint256 targetWeight)
        external
        view
        returns (uint256)
    {
        uint256 currentWeight = weightOf(user);

        if (currentWeight >= targetWeight) {
            return 0;
        }

        return (targetWeight - currentWeight) / _stakeOf[user].duration;
    }

    function extraDurationNeeded(address user, uint256 targetWeight)
        external
        view
        returns (uint256)
    {
        uint256 currentWeight = weightOf(user);

        if (currentWeight >= targetWeight) {
            return 0;
        }

        return (targetWeight - currentWeight) / _stakeOf[user].amount;
    }

    function stake(uint256 amount, uint256 numDaysToAdd) external {
        Stake storage s = _stakeOf[msg.sender];

        s.amount += amount;
        require(
            STAKE_MIN <= s.amount && s.amount <= STAKE_MAX,
            "LEASH amount outside of limits"
        );

        if (s.duration == 0) {
            // no existing lock
            s.startTime = block.timestamp;
        }

        if (numDaysToAdd > 0) {
            s.duration += numDaysToAdd * 1 days;
        }

        uint256 duration = s.duration / 1 days;

        require(
            DAYS_MIN <= duration && duration <= DAYS_MAX,
            "Duration outside of limits"
        );

        LEASH.transferFrom(msg.sender, address(this), amount);
    }

    function unstake() external {
        Stake storage s = _stakeOf[msg.sender];

        uint256 amount = s.amount;
        uint256 startTime = s.startTime;
        uint256 duration = s.duration;

        require(amount > 0, "No LEASH staked");
        require(startTime + duration <= block.timestamp, "Not unlocked yet");

        delete _stakeOf[msg.sender];

        LEASH.transfer(msg.sender, amount);
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