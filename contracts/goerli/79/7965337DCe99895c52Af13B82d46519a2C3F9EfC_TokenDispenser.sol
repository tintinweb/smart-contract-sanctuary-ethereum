// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenDispenser is Ownable {
    error InvalidToken();
    error InvalidReceiver();
    error InvalidMontlyMax();
    error MonthlyClaimTooHigh();
    error NoTokensLeftToDistribute();
    error PaymentFailed();
    error InvalidClaimCaller();

    uint256 public constant ONE_YEAR = 365 days;
    uint256 public constant ONE_MONTH = ONE_YEAR / 12;
    IERC20 public immutable token;
    uint256 public immutable monthlyMin;
    uint256 public immutable monthlyMax;
    uint256 public immutable start;
    uint256 public lastClaimedPeriodStartTime;
    address public receiver;
    uint256 public claimedThisMonth;

    /// @notice Emitted when the receiver claims
    event Claimed(uint256 amount);

    /// @notice Emmited when the owner changes the receiver
    event ReceiverChanged(address oldReceiver, address newReceiver);

    /// @notice Contructor of the contract, initialize the contract state
    /// @param token_ Address of the token to distribute
    /// @param monthlyMin_ Minimum amount of tokens to distribute each month
    /// @param monthlyMax_ Maximum amount of tokens to distribute each month
    /// @param receiver_ Address of the receiver of the tokens that can claim
    constructor(IERC20 token_, uint256 monthlyMin_, uint256 monthlyMax_, address receiver_) {
        if (address(token_) == address(0)) revert InvalidToken();
        if (monthlyMax_ == 0) revert InvalidMontlyMax();
        if (receiver_ == address(0)) revert InvalidReceiver();

        token = token_;
        monthlyMin = monthlyMin_;
        monthlyMax = monthlyMax_;
        receiver = receiver_;
        start = block.timestamp;
        lastClaimedPeriodStartTime = block.timestamp;
    }

    /// @notice Allows the owner to change the receiver address
    /// @dev The new address can not be zero
    /// @param receiver_ Address of the new receiver
    function changeReceiver(address receiver_) external onlyOwner {
        if (receiver_ == address(0)) revert InvalidReceiver();
        address oldReceiver = receiver;
        receiver = receiver_;
        emit ReceiverChanged(oldReceiver, receiver_);
    }

    /// @notice Allows the receiver to claim and receive the corresponding amount of tokens for the month
    /// @dev The caller needs to be the receiver
    /// @dev If the monthlyMin amount of tokens is reached, the contract will transfer the leftover tokens
    /// @param amount_ Amount of tokens to claim, recommended to first call calculateMaxTokensThisMonth()
    function claim(uint256 amount_) external {
        if (msg.sender != receiver) revert InvalidClaimCaller();

        (uint256 maxTokens, bool isNewMonth) = calculateMaxTokensThisMonth();
        if (maxTokens == 0) revert NoTokensLeftToDistribute();
        if (maxTokens < amount_) revert MonthlyClaimTooHigh();

        if (isNewMonth) {
            (, , uint256 newPeriodStartTime) = getTimes();
            lastClaimedPeriodStartTime = newPeriodStartTime;
            claimedThisMonth = amount_;
        }

        emit Claimed(amount_);
        if (!token.transfer(msg.sender, amount_)) revert PaymentFailed();
    }

    /// @notice Makes it easy for users to see the balance of the contract
    function getContractBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /// @notice Gets information about the times of the contract like current year, month, newPeriodStartTime
    /// @return currentYear Current year, starts at 1, and increases every 365 days since the start of the contract
    /// @return currentMonth Current month, starts at 1, and increases every 365 days/12 since the start of the contract
    /// @return newPeriodStartTime Time in seconds when the newest active period starts
    function getTimes()
        public
        view
        returns (uint256 currentYear, uint256 currentMonth, uint256 newPeriodStartTime)
    {
        uint256 elapsedTime = block.timestamp - start;
        currentYear = (elapsedTime / ONE_YEAR) + 1;
        currentMonth = (elapsedTime / ONE_MONTH) + 1;
        newPeriodStartTime = start + (currentMonth * ONE_MONTH);
    }

    /// @notice Shows the max amount claimabled this month considering prevoous claims during the same month
    /// @dev The function will resturn the leftovers if the monthlyMin is reached
    /// @return maxTokens Maximum claimable amount
    /// @return isNewMonth Returns true if the receiver has not claimed in the current month
    function calculateMaxTokensThisMonth()
        public
        view
        returns (uint256 maxTokens, bool isNewMonth)
    {
        uint256 amount = _getClaimableAmount();

        assert(monthlyMax >= amount);
        if (amount <= monthlyMin) amount = token.balanceOf(address(this));

        (, , uint256 newPeriodStartTime) = getTimes();
        isNewMonth = newPeriodStartTime > lastClaimedPeriodStartTime;
        if (isNewMonth) maxTokens = amount;
        else maxTokens = amount - claimedThisMonth;
    }

    /// @dev Applies the formula to calculate the percentage from the max monthly amount according to the current month
    /// @return Max claimable amount of the month ignoring any already claimed tokens
    function _getClaimableAmount() private view returns (uint256) {
        (uint256 currentYear, , ) = getTimes();
        if (currentYear < 5) {
            uint256 percentage = currentYear == 1
                ? 10
                : (currentYear == 2 ? 25 : (currentYear == 3 ? 50 : 100));
            return (monthlyMax * percentage) / 100;
        }
        bool modulo4IsZero = ((100 * currentYear) / 4) % 100 == 0;
        uint256 exponential = modulo4IsZero ? (currentYear / 4 - 1) : (currentYear / 4);
        return monthlyMax / 2 ** exponential;
    }
}