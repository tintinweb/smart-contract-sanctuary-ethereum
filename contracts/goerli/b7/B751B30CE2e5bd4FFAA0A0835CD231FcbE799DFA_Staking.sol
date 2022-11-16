// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Arrays.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@dlsl/dev-modules/utils/Globals.sol";
import "@dlsl/dev-modules/libs/math/DSMath.sol";

import "./IStaking.sol";

contract Staking is Ownable, IStaking {
    using Arrays for uint256[];
    using SafeERC20 for IERC20;
    using DSMath for uint128;

    address public token;
    uint256 public aggregateStakedAmount;

    Intervals private _intervals;
    mapping(address => Stake) public accountToStake;

    constructor(address token_) {
        require(token_ != address(0), "SC: invalid token");

        token = token_;
    }

    function setOverAmountPercent(uint128 overAmountPercent_) external onlyOwner {
        _intervals.overAmountPercent = overAmountPercent_;

        emit OverAmountPercentChanged(overAmountPercent_);
    }

    function addIntervals(uint256[] calldata amounts_, uint128[] calldata percents_)
        external
        onlyOwner
    {
        require(amounts_.length > 0, "SC: invalid length");

        uint256 intervalsLength_ = _intervals.amounts.length;
        if (intervalsLength_ != 0) {
            require(
                amounts_[0] > _intervals.amounts[intervalsLength_ - 1],
                "SC: invalid initial amount"
            );
        }

        for (uint256 i = 0; i < amounts_.length; i++) {
            if (i != 0) {
                require(amounts_[i] > amounts_[i - 1], "SC: invalid amount (1)");
            } else {
                require(amounts_[i] > 0, "SC: invalid amount (2)");
            }

            _intervals.amounts.push(amounts_[i]);
            _intervals.percents.push(percents_[i]);
        }

        emit IntervalsAdded(amounts_, percents_);
    }

    function editIntervals(
        uint256[] calldata indexes_,
        uint256[] calldata amounts_,
        uint128[] calldata percents_
    ) external onlyOwner {
        uint256 intervalsLength_ = _intervals.amounts.length;
        require(intervalsLength_ > 0, "SC: intervals isn't added");

        for (uint256 i = 0; i < indexes_.length; i++) {
            uint256 index_ = indexes_[i];
            if (0 < index_ && index_ < intervalsLength_ - 1) {
                require(
                    _intervals.amounts[index_ - 1] < amounts_[i] &&
                        amounts_[i] < _intervals.amounts[index_ + 1],
                    "SC: invalid amount (1)"
                );
            } else if (0 == index_ && intervalsLength_ > 1) {
                require(amounts_[i] < _intervals.amounts[index_ + 1], "SC: invalid amount (2)");
            } else if (index_ == intervalsLength_ - 1 && intervalsLength_ > 1) {
                require(_intervals.amounts[index_ - 1] < amounts_[i], "SC: invalid amount (3)");
            } else if (0 == index_) {
                require(amounts_[i] > 0, "SC: invalid amount (4)");
            } else {
                revert("SC: invalid index");
            }

            _intervals.amounts[index_] = amounts_[i];
            _intervals.percents[index_] = percents_[i];
        }

        emit IntervalsEdited(indexes_, amounts_, percents_);
    }

    function removeIntervals(uint256 count_) external onlyOwner {
        uint256 intervalsLength_ = _intervals.amounts.length;

        if (count_ >= intervalsLength_) {
            delete _intervals.amounts;
            delete _intervals.percents;

            emit IntervalsDeleted(intervalsLength_);

            return;
        }

        for (uint256 i = 0; i < count_; i++) {
            _intervals.amounts.pop();
            _intervals.percents.pop();
        }

        emit IntervalsDeleted(count_);
    }

    function stake(uint256 amount_) external {
        require(amount_ > 0, "SC: invalid amount");

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount_);

        Stake memory stake_ = accountToStake[msg.sender];

        uint256 newAmount_ = stake_.amount + amount_;

        stake_.pendingRewards = _getPotentialRewards(stake_, uint32(block.timestamp));
        stake_.lastUpdate = uint32(block.timestamp);
        stake_.amount = newAmount_;
        stake_.percent = getPotentialPercent(newAmount_);

        accountToStake[msg.sender] = stake_;
        aggregateStakedAmount += amount_;

        emit Staked(msg.sender, amount_);
    }

    function claim() external {
        Stake memory stake_ = accountToStake[msg.sender];

        uint256 amount_ = _getPotentialRewards(stake_, uint32(block.timestamp));
        require(amount_ > 0, "SC: nothing to claim");

        stake_.pendingRewards = 0;
        stake_.lastUpdate = uint32(block.timestamp);
        stake_.percent = getPotentialPercent(stake_.amount);

        accountToStake[msg.sender] = stake_;

        IERC20(token).safeTransfer(msg.sender, amount_);

        emit Claimed(msg.sender, amount_, msg.sender);
    }

    function withdraw(uint256 amount_) external {
        require(amount_ > 0, "SC: invalid amount");

        Stake memory stake_ = accountToStake[msg.sender];
        require(stake_.amount > 0, "SC: nothing to withdraw");

        uint256 potentialRewards_ = _getPotentialRewards(stake_, uint32(block.timestamp));

        if (potentialRewards_ >= amount_) {
            stake_.pendingRewards = potentialRewards_ - amount_;
        } else {
            uint256 amountDecrease_ = amount_ - potentialRewards_;
            if (amountDecrease_ > stake_.amount) {
                amountDecrease_ = stake_.amount;
                amount_ = stake_.amount + potentialRewards_;
            }

            stake_.pendingRewards = 0;
            stake_.amount -= amountDecrease_;

            aggregateStakedAmount -= amountDecrease_;
        }

        stake_.lastUpdate = uint32(block.timestamp);
        stake_.percent = getPotentialPercent(stake_.amount);

        accountToStake[msg.sender] = stake_;

        IERC20(token).safeTransfer(msg.sender, amount_);

        emit Withdrawn(msg.sender, amount_);
    }

    function supplyRewardPool(uint256 amount_) external {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount_);
    }

    function getIntervals()
        external
        view
        returns (
            uint256[] memory,
            uint128[] memory,
            uint256
        )
    {
        return (_intervals.amounts, _intervals.percents, _intervals.overAmountPercent);
    }

    function getPotentialPercent(uint256 amount_) public view returns (uint128) {
        uint256 index_ = _intervals.amounts.findUpperBound(amount_);
        if (index_ == _intervals.amounts.length) {
            return _intervals.overAmountPercent;
        }

        return _intervals.percents[index_];
    }

    function getPotentialRewards(address account_, uint32 timestamp_)
        external
        view
        returns (uint256)
    {
        return _getPotentialRewards(accountToStake[account_], timestamp_);
    }

    function _getPotentialRewards(Stake memory stake_, uint32 timestamp_)
        private
        pure
        returns (uint256)
    {
        if (timestamp_ <= stake_.lastUpdate) return 0;

        uint256 potentialRewards_ = (stake_.amount *
            stake_.percent.rpow(timestamp_ - stake_.lastUpdate, PRECISION)) /
            PRECISION -
            stake_.amount;

        return potentialRewards_ + stake_.pendingRewards;
    }

    function transferStuckERC20(
        address token_,
        address to_,
        uint256 amount_
    ) external onlyOwner {
        require(token_ != token, "SC: invalid token address");

        return IERC20(token_).safeTransfer(to_, amount_);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IStaking {
    event OverAmountPercentChanged(uint128 overAmountPercent);
    event IntervalsAdded(uint256[] amounts, uint128[] percents);
    event IntervalsEdited(uint256[] indexes, uint256[] amounts, uint128[] percents);
    event IntervalsDeleted(uint256 count);
    event Staked(address indexed account, uint256 amount);
    event Claimed(address indexed account, uint256 amount, address indexed sender);
    event Withdrawn(address indexed account, uint256 amount);

    /**
     * @param amounts Tokens amount
     * @param percents Percents per second, 1.1^(1÷31536000)×10^25=10000000030222659800973876 (10%)
     * @param overAmountPercent Percent per second for amount that higher than last `amounts` value
     * @dev Example: [0,100] = 10%, (100,200] = 20%, (200, infinity) = 30%.
     */
    struct Intervals {
        uint256[] amounts; // [100 USDT, 200 USDT]
        uint128[] percents; // [10%, 20%]
        uint128 overAmountPercent; // 30%
    }

    /**
     * @param amounts Staked amount
     * @param pendingRewards Pending rewards, setted to non zero value after `stake` or `withdraw`
     * @param percent Second percent, reward will be calculated by this value
     * @param lastUpdate Unix timestamp, seconds
     */
    struct Stake {
        uint256 amount;
        uint256 pendingRewards;
        uint128 percent;
        uint32 lastUpdate;
    }

    /**
     * @notice Set percent for amount that higher than last `amounts` value
     * @param overAmountPercent_ New percent per second
     */
    function setOverAmountPercent(uint128 overAmountPercent_) external;

    /**
     * @notice Append new amounts and percents to `intervals`
     * @param amounts_ Token amount for interval
     * @param percents_ Percents per second
     */
    function addIntervals(uint256[] calldata amounts_, uint128[] calldata percents_) external;

    /**
     * @notice Edit existed amounts and percents in `intervals`
     * @param indexes_ Array indexes to edit
     * @param amounts_ Token amount for interval
     * @param percents_ Percents per second
     */
    function editIntervals(
        uint256[] calldata indexes_,
        uint256[] calldata amounts_,
        uint128[] calldata percents_
    ) external;

    /**
     * @notice Remove last elements in `intervals`
     * @param count_ Amount to remove
     */
    function removeIntervals(uint256 count_) external;

    /**
     * @notice Stake tokens
     * @param amount_ Token amount
     */
    function stake(uint256 amount_) external;

    /**
     * @notice Claim tokens from `msg.sender`
     */
    function claim() external;

    /**
     * @notice Withdraw tokens
     * @param amount_ Token amount
     */
    function withdraw(uint256 amount_) external;

    /**
     * @notice Transfer `amount_` of `token` from `msg.sender` to this contract
     * @param amount_ Token amount
     */
    function supplyRewardPool(uint256 amount_) external;

    /**
     * @notice `intervals` info
     */
    function getIntervals()
        external
        view
        returns (
            uint256[] memory,
            uint128[] memory,
            uint256
        );

    /**
     * @param amount_ Token amount
     * @return uint128 Persent per second for selected `amount_`
     */
    function getPotentialPercent(uint256 amount_) external view returns (uint128);

    /**
     * @param account_ User address
     * @param timestamp_ Unix timestamp, seconds
     * @return uint256 User reward at selected `timestamp_`
     */
    function getPotentialRewards(address account_, uint32 timestamp_)
        external
        view
        returns (uint256);

    /**
     * @notice Transfer any amount of ERC20 tokens from current contract to `to_`, except `token`
     * @param token_ ERC20 address
     * @param to_ Recipient address
     * @param amount_ Token amount
     */
    function transferStuckERC20(
        address token_,
        address to_,
        uint256 amount_
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/Arrays.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

uint256 constant PRECISION = 10**25;
uint256 constant DECIMAL = 10**18;
uint256 constant PERCENTAGE_100 = 10**27;

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: ALGPL-3.0-or-later-or-later
// from https://github.com/makerdao/dss/blob/master/src/jug.sol
pragma solidity ^0.8.0;

library DSMath {
    /**
     * @dev github.com/makerdao/dss implementation of exponentiation by squaring
     * @dev nth power of x where x is decimal number with b precision
     */
    function rpow(
        uint256 x,
        uint256 n,
        uint256 b
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    z := b
                }
                default {
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    z := b
                }
                default {
                    z := x
                }
                let half := div(b, 2) // for rounding.
                for {
                    n := div(n, 2)
                } n {
                    n := div(n, 2)
                } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) {
                        revert(0, 0)
                    }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }
                    x := div(xxRound, b)
                    if mod(n, 2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
                            revert(0, 0)
                        }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }
                        z := div(zxRound, b)
                    }
                }
            }
        }
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