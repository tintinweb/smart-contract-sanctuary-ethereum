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

pragma solidity 0.8.16;

interface IPolicy {
    function compute(uint256 amount, uint32 lockedAt, uint32 duration, uint256 startingBalance) external returns(uint256 balance);
    function isExclusive() external returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface ITokenLocker {
    struct Lock {
        uint192 amount;
        uint32 lockedAt;
        uint32 lockDuration;
    }

    // State changing methods
    function depositByMonths(uint192 _amount, uint256 _months, address _receiver) external;
    function boostToMax() external;
    function increaseAmount(uint192 _amount) external;
    function increaseByMonths(uint256 _months) external;

    // View methods
    function getLock(address _depositor) external returns (Lock memory);
    function lockOf(address account) external view returns (uint192, uint32, uint32);
    function minLockAmount() external returns (uint256);
    function maxLockDuration() external returns (uint32);
    function getLockMultiplier(uint32 _duration) external view returns (uint256);
    function getSecondsMonths() external view returns (uint256);
    function previewDepositByMonths(uint192 _amount, uint256 _months, address _receiver)
        external
        view
        returns (uint256);
}

pragma solidity 0.8.16;
import "./policies/DecayPolicy.sol";

/// @notice Simple oracle calculating the mothly decay for veAUXO locks
/// @dev The queue is processed in descending order, meaning the last index will be withdrawn from first.
contract SimpleDecayOracle is DecayPolicy {
    constructor(address _locker) DecayPolicy(_locker) {}
    function balanceOf(address _staker) external view returns(uint256) {
        (uint256 amount, uint32 lockedAt, uint32 duration) = locker.lockOf(_staker);
        return compute(amount, lockedAt, duration, 0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@interfaces/IPolicy.sol";
import "@interfaces/ITokenLocker.sol";
import {IERC20} from "@oz/token/ERC20/IERC20.sol";

contract DecayPolicy is IPolicy {
    ITokenLocker public immutable locker;
    uint256 public immutable AVG_SECONDS_MONTH;
    bool public exclusive = false;

    /// @notice API version.
    string public constant VERSION = "0.1";

    constructor(address _locker)  {
        locker = ITokenLocker(_locker);
        AVG_SECONDS_MONTH = locker.getSecondsMonths();
    }

    function isExclusive() external returns(bool) {
        return exclusive;
    }

    function getDecayMultiplier(uint256 amount, uint32 lockedAt, uint32 lockDuration) public view returns(uint256){
        // If Lock is already expired return 0
        uint32 remainingmonths = uint32(18);
        uint32 duration = uint32(remainingmonths * AVG_SECONDS_MONTH);
        uint256 decayedMonthMultiplier = locker.getLockMultiplier( duration );
        return decayedMonthMultiplier;
    }

    function compute(uint256 amount, uint32 lockedAt, uint32 duration, uint256 balance) public view returns(uint256) {
        uint256 dm = getDecayMultiplier(amount, lockedAt, duration);
        return (amount * dm) / 1e18;
    }

}