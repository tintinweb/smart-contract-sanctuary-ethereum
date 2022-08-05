/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

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

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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

// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity ^0.8.15;

interface IParrotRewards {
    function claimReward() external;
    function depositRewards() external payable;
    function getLockedShares(address wallet) external view returns (uint256);
    function lock(uint256 amount) external;
    function unlock(uint256 amount) external;
}

pragma solidity ^0.8.15;

contract ParrotRewards is IParrotRewards, Ownable {
    address public shareholderToken;

    uint256 private constant ONE_DAY = 60 * 60 * 24;
    uint256 public timeLock = 30 days;
    uint256 public totalLockedUsers;
    uint256 public totalSharesDeposited;
    uint256 public totalRewards;
    uint256 public totalDistributed;
    uint256 public rewardsPerShare;
    uint256 private constant ACC_FACTOR = 10**36;

    int256 private constant OFFSET19700101 = 2440588;

    uint8 public minDayOfMonthCanLock = 1;
    uint8 public maxDayOfMonthCanLock = 5;

    struct Reward {
        uint256 totalExcluded;
        uint256 totalRealised;
        uint256 lastClaim;
    }

    struct Share {
        uint256 amount;
        uint256 lockedTime;
    }

    // amount of shares a user has
    mapping(address => Share) public shares;
    // reward information per user
    mapping(address => Reward) public rewards;

    event ClaimReward(address wallet);
    event DistributeReward(address indexed wallet, address payable receiver);
    event DepositRewards(address indexed wallet, uint256 amountETH);

    constructor(address _shareholderToken) {
        shareholderToken = _shareholderToken;
    }

    function lock(uint256 _amount) external {
        uint256 _currentDayOfMonth = _dayOfMonth(block.timestamp);
        require(
            _currentDayOfMonth >= minDayOfMonthCanLock &&
            _currentDayOfMonth <= maxDayOfMonthCanLock,
            "outside of allowed lock window"
        );
        address shareholder = msg.sender;
        IERC20 tokenContract = IERC20(shareholderToken);
        _amount = _amount == 0 ? tokenContract.balanceOf(shareholder) : _amount;
        tokenContract.transferFrom(shareholder, address(this), _amount);
        _addShares(shareholder, _amount);
    }

    function unlock(uint256 _amount) external {
        address shareholder = msg.sender;
        require(
            block.timestamp >= shares[shareholder].lockedTime + timeLock,
            "must wait the time lock before unstaking"
        );
        _amount = _amount == 0 ? shares[shareholder].amount : _amount;
        require(_amount > 0, "need tokens to unlock");
        require(
            _amount <= shares[shareholder].amount,
            "cannot unlock more than you have locked"
        );
        IERC20(shareholderToken).transfer(shareholder, _amount);
        _removeShares(shareholder, _amount);
    }

    function _addShares(address shareholder, uint256 amount) internal {
        _distributeReward(shareholder);

        uint256 sharesBefore = shares[shareholder].amount;
        totalSharesDeposited += amount;
        shares[shareholder].amount += amount;
        shares[shareholder].lockedTime = block.timestamp;
        if (sharesBefore == 0 && shares[shareholder].amount > 0) {
            totalLockedUsers++;
        }
        rewards[shareholder].totalExcluded = getCumulativeRewards(
            shares[shareholder].amount
        );
    }

    function _removeShares(address shareholder, uint256 amount) internal {
        amount = amount == 0 ? shares[shareholder].amount : amount;
        require(
            shares[shareholder].amount > 0 && amount <= shares[shareholder].amount,
            "you can only unlock if you have some lockd"
        );
        _distributeReward(shareholder);

        totalSharesDeposited -= amount;
        shares[shareholder].amount -= amount;
        if (shares[shareholder].amount == 0) {
            totalLockedUsers--;
        }
        rewards[shareholder].totalExcluded = getCumulativeRewards(
            shares[shareholder].amount
        );
  }

    function depositRewards() public payable override {
        _depositRewards(msg.value);
    }

    function _depositRewards(uint256 _amount) internal {
        require(_amount > 0, "must provide ETH to deposit");
        require(totalSharesDeposited > 0, "must be shares deposited");

        totalRewards += _amount;
        rewardsPerShare += (ACC_FACTOR * _amount) / totalSharesDeposited;
        emit DepositRewards(msg.sender, _amount);
    }

    function _distributeReward(address shareholder) internal {
        if (shares[shareholder].amount == 0) {
            return;
        }

        uint256 amount = getUnpaid(shareholder);

        rewards[shareholder].totalRealised += amount;
        rewards[shareholder].totalExcluded = getCumulativeRewards(
            shares[shareholder].amount
        );
        rewards[shareholder].lastClaim = block.timestamp;

        if (amount > 0) {
            bool success;
            address payable receiver = payable(shareholder);
            totalDistributed += amount;
            uint256 balanceBefore = address(this).balance;
            (success,) = receiver.call{ value: amount }('');
            require(address(this).balance >= balanceBefore - amount);
            emit DistributeReward(shareholder, receiver);
        }
    }

    function _dayOfMonth(uint256 _timestamp) internal pure returns (uint256) {
        (, , uint256 day) = _daysToDate(_timestamp / ONE_DAY);
        return day;
    }

    // date conversion algorithm from http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    function _daysToDate(uint256 _days) internal pure returns (uint256, uint256, uint256) {
        int256 __days = int256(_days);

        int256 L = __days + 68569 + OFFSET19700101;
        int256 N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int256 _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int256 _month = (80 * L) / 2447;
        int256 _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        return (uint256(_year), uint256(_month), uint256(_day));
    }

    function claimReward() external override {
        _distributeReward(msg.sender);
        emit ClaimReward(msg.sender);
    }

    // returns the unpaid rewards
    function getUnpaid(address shareholder) public view returns (uint256) {
        if (shares[shareholder].amount == 0) {
            return 0;
        }

        uint256 earnedRewards = getCumulativeRewards(shares[shareholder].amount);
        uint256 rewardsExcluded = rewards[shareholder].totalExcluded;
        if (earnedRewards <= rewardsExcluded) {
            return 0;
        }

        return earnedRewards - rewardsExcluded;
    }

    function getCumulativeRewards(uint256 share) internal view returns (uint256) {
        return (share * rewardsPerShare) / ACC_FACTOR;
    }

    function getLockedShares(address user) external view override returns (uint256) {
        return shares[user].amount;
    }

    function setMinDayOfMonthCanLock(uint8 _day) external onlyOwner {
        require(_day <= maxDayOfMonthCanLock, "can set min day above max day");
        minDayOfMonthCanLock = _day;
    }

    function setMaxDayOfMonthCanLock(uint8 _day) external onlyOwner {
        require(_day >= minDayOfMonthCanLock, "can set max day below min day");
        maxDayOfMonthCanLock = _day;
    }

    function setTimeLock(uint256 numSec) external onlyOwner {
        require(numSec <= 365 days, "must be less than a year");
        timeLock = numSec;
    }

    function withdrawStuckETH() external onlyOwner {
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

    receive() external payable {
        _depositRewards(msg.value);
    }
}

pragma solidity ^0.8.15;

interface IUSDCReceiver {
    function initialize(address) external;
    function withdraw() external;
    function withdrawUnsupportedAsset(address, uint256) external;
}

pragma solidity ^0.8.15;

contract USDCReceiver is IUSDCReceiver, Ownable {

    address public usdc;
    address public token;

    constructor() Ownable() {
        token = msg.sender;
    }

    function initialize(address _usdc) public onlyOwner {
        require(usdc == address(0x0), "Already initialized");
        usdc = _usdc;
    }

    function withdraw() public {
        require(msg.sender == token, "Caller is not token");
        IERC20(usdc).transfer(token, IERC20(usdc).balanceOf(address(this)));
    }

    function withdrawUnsupportedAsset(address _token, uint256 _amount) public onlyOwner {
        if(_token == address(0x0))
            payable(owner()).transfer(_amount);
        else
            IERC20(_token).transfer(owner(), _amount);
    }
}

contract Parrot is Context, IERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 private _uniswapV2Router;

    ParrotRewards private _rewards;
    USDCReceiver private _receiver;

    mapping (address => uint) private _cooldown;

    mapping (address => uint256) private _rOwned;

    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcludedMaxTransactionAmount;
    mapping (address => bool) private _isBlacklisted;

    bool public tradingOpen;
    bool private swapping;
    bool private swapEnabled = false;
    bool public cooldownEnabled = false;
    bool public feesEnabled = true;

    string private constant _name = "Parrot";
    string private constant _symbol = "PRT";

    uint8 private constant _decimals = 18;

    uint256 private constant _tTotal = 1e9 * (10**_decimals);
    uint256 public maxBuyAmount = _tTotal;
    uint256 public maxSellAmount = _tTotal;
    uint256 public maxWalletAmount = _tTotal;
    uint256 public tradingActiveBlock = 0;
    uint256 private _blocksToBlacklist = 0;
    uint256 private _cooldownBlocks = 1;
    uint256 public constant FEE_DIVISOR = 1000;
    uint256 public buyLiquidityFee = 10;
    uint256 private _previousBuyLiquidityFee = buyLiquidityFee;
    uint256 public buyTreasuryFee = 70;
    uint256 private _previousBuyTreasuryFee = buyTreasuryFee;
    uint256 public buyDevelopmentFee = 20;
    uint256 private _previousBuyDevelopmentFee = buyDevelopmentFee;
    uint256 public sellLiquidityFee = 10;
    uint256 private _previousSellLiquidityFee = sellLiquidityFee;
    uint256 public sellTreasuryFee = 70;
    uint256 private _previousSellTreasuryFee = sellTreasuryFee;
    uint256 public sellDevelopmentFee = 20;
    uint256 private _previousSellDevelopmentFee = sellDevelopmentFee;
    uint256 private _tokensForLiquidity;
    uint256 private _tokensForTreasury;
    uint256 private _tokensForDevelopment;
    uint256 private _swapTokensAtAmount = 0;

    address payable public liquidityWallet;
    address payable public treasuryWallet;
    address payable public developmentWallet;
    address private _uniswapV2Pair;
    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    address private ZERO = 0x0000000000000000000000000000000000000000;
    address private USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);
    
    constructor (address liquidityWalletAddy, address treasuryWalletAddy, address developmentWalletAddy) {
        liquidityWallet = payable(liquidityWalletAddy);
        treasuryWallet = payable(treasuryWalletAddy);
        developmentWallet = payable(developmentWalletAddy);

        _rewards = new ParrotRewards(address(this));
        _rewards.transferOwnership(msg.sender);

        _receiver = new USDCReceiver();
        _receiver.initialize(USDC);
        _receiver.transferOwnership(msg.sender);

        _rOwned[_msgSender()] = _tTotal;

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[address(_receiver)] = true;
        _isExcludedFromFees[DEAD] = true;
        _isExcludedFromFees[liquidityWallet] = true;
        _isExcludedFromFees[treasuryWallet] = true;
        _isExcludedFromFees[developmentWallet] = true;

        _isExcludedMaxTransactionAmount[owner()] = true;
        _isExcludedMaxTransactionAmount[address(this)] = true;
        _isExcludedMaxTransactionAmount[address(_receiver)] = true;
        _isExcludedMaxTransactionAmount[DEAD] = true;
        _isExcludedMaxTransactionAmount[liquidityWallet] = true;
        _isExcludedMaxTransactionAmount[treasuryWallet] = true;
        _isExcludedMaxTransactionAmount[developmentWallet] = true;

        _rewards = new ParrotRewards(address(this));
        _rewards.transferOwnership(msg.sender);

        _receiver = new USDCReceiver();
        _receiver.initialize(USDC);
        _receiver.transferOwnership(msg.sender);

        emit Transfer(ZERO, _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _rOwned[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function setCooldownEnabled(bool onoff) external onlyOwner {
        cooldownEnabled = onoff;
    }

    function setSwapEnabled(bool onoff) external onlyOwner {
        swapEnabled = onoff;
    }

    function setFeesEnabled(bool onoff) external onlyOwner {
        feesEnabled = onoff;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != ZERO, "ERC20: approve from the zero address");
        require(spender != ZERO, "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != ZERO, "ERC20: transfer from the zero address");
        require(to != ZERO, "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        bool takeFee = true;
        bool shouldSwap = false;
        if (from != owner() && to != owner() && to != ZERO && to != DEAD && !swapping) {
            require(!_isBlacklisted[from] && !_isBlacklisted[to]);

            if(!tradingOpen) {
                require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not allowed yet.");
            }

            if (cooldownEnabled) {
                if (to != address(_uniswapV2Router) && to != address(_uniswapV2Pair)){
                    require(_cooldown[tx.origin] < block.number - _cooldownBlocks && _cooldown[to] < block.number - _cooldownBlocks, "Transfer delay enabled. Try again later.");
                    _cooldown[tx.origin] = block.number;
                    _cooldown[to] = block.number;
                }
            }

            if (from == _uniswapV2Pair && to != address(_uniswapV2Router) && !_isExcludedMaxTransactionAmount[to]) {
                require(amount <= maxBuyAmount, "Transfer amount exceeds the maxBuyAmount.");
                require(balanceOf(to) + amount <= maxWalletAmount, "Exceeds maximum wallet token amount.");
            }
            
            if (to == _uniswapV2Pair && from != address(_uniswapV2Router) && !_isExcludedMaxTransactionAmount[from]) {
                require(amount <= maxSellAmount, "Transfer amount exceeds the maxSellAmount.");
                shouldSwap = true;
            }
        }

        if(_isExcludedFromFees[from] || _isExcludedFromFees[to] || !feesEnabled) {
            takeFee = false;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = (contractTokenBalance > _swapTokensAtAmount) && shouldSwap;

        if (canSwap && swapEnabled && !swapping && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        _tokenTransfer(from, to, amount, takeFee, shouldSwap);
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = _tokensForLiquidity + _tokensForTreasury + _tokensForDevelopment;
        
        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}

        if(contractBalance > _swapTokensAtAmount * 5) {
            contractBalance = _swapTokensAtAmount * 5;
        }
        
        uint256 liquidityTokens = contractBalance * _tokensForLiquidity / totalTokensToSwap / 2;
        uint256 amountToSwapForUSDC = contractBalance.sub(liquidityTokens);
        
        uint256 initialUSDCBalance = IERC20(USDC).balanceOf(address(this));

        swapTokensForTokens(amountToSwapForUSDC);
        _receiver.withdraw();
        
        uint256 usdcBalance = IERC20(USDC).balanceOf(address(this)).sub(initialUSDCBalance);
        uint256 usdcForTreasury = usdcBalance.mul(_tokensForTreasury).div(totalTokensToSwap);
        uint256 usdcForDevelopment = usdcBalance.mul(_tokensForDevelopment).div(totalTokensToSwap);
        uint256 usdcForLiquidity = usdcBalance - usdcForTreasury - usdcForDevelopment;
        
        _tokensForLiquidity = 0;
        _tokensForTreasury = 0;
        _tokensForDevelopment = 0;
        
        if(liquidityTokens > 0 && usdcForLiquidity > 0){
            addLiquidity(liquidityTokens, usdcForLiquidity);
            emit SwapAndLiquify(amountToSwapForUSDC, usdcForLiquidity, _tokensForLiquidity);
        }
        
        IERC20(USDC).transfer(developmentWallet, usdcForDevelopment);
        IERC20(USDC).transfer(treasuryWallet, IERC20(USDC).balanceOf(address(this)));
    }

    function swapTokensForTokens(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDC;
        _approve(address(this), address(_uniswapV2Router), tokenAmount);
        _uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(_receiver),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 usdcAmount) private {
        _approve(address(this), address(_uniswapV2Router), tokenAmount);
        IERC20(USDC).approve(address(_uniswapV2Router), usdcAmount);
        _uniswapV2Router.addLiquidity(
            address(this),
            USDC,
            tokenAmount,
            usdcAmount,
            0,
            0,
            liquidityWallet,
            block.timestamp
        );
    }
        
    function sendUSDCToFee(uint256 amount) private {
        IERC20(USDC).transfer(treasuryWallet, amount.div(2));
        IERC20(USDC).transfer(developmentWallet, amount.div(2));
    }

    function rewardsContract() external view returns (address) {
        return address(_rewards);
    }

    function usdcReceiverContract() external view returns (address) {
        return address(_receiver);
    }

    function isBlacklisted(address wallet) external view returns (bool) {
        return _isBlacklisted[wallet];
    }
    
    function launch() external onlyOwner {
        require(!tradingOpen, "Trading is already open");
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _uniswapV2Router = uniswapV2Router;
        _approve(address(this), address(_uniswapV2Router), _tTotal);
        IERC20(USDC).approve(address(_uniswapV2Router), IERC20(USDC).balanceOf(address(this)));
        _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), USDC);
        _uniswapV2Router.addLiquidity(address(this), USDC, balanceOf(address(this)), IERC20(USDC).balanceOf(address(this)), 0, 0, owner(), block.timestamp);
        swapEnabled = true;
        _swapTokensAtAmount = 5e5 * (10**_decimals);
        tradingOpen = true;
        tradingActiveBlock = block.number;
        IERC20(_uniswapV2Pair).approve(address(_uniswapV2Router), type(uint).max);
    }

    function setMaxBuyAmount(uint256 maxBuy) external onlyOwner {
        require(maxBuy >= 1e5 * (10**_decimals), "Max buy amount cannot be lower than 0.01% total supply.");
        maxBuyAmount = maxBuy;
    }

    function setMaxSellAmount(uint256 maxSell) external onlyOwner {
        require(maxSell >= 1e5 * (10**_decimals), "Max sell amount cannot be lower than 0.01% total supply.");
        maxSellAmount = maxSell;
    }
    
    function setMaxWalletAmount(uint256 maxToken) external onlyOwner {
        require(maxToken >= 1e6 * (10**_decimals), "Max wallet amount cannot be lower than 0.1% total supply.");
        maxWalletAmount = maxToken;
    }
    
    function setSwapTokensAtAmount(uint256 swapAmount) external onlyOwner {
        require(swapAmount >= 1e4 * (10**_decimals), "Swap amount cannot be lower than 0.001% total supply.");
        require(swapAmount <= 5e6 * (10**_decimals), "Swap amount cannot be higher than 0.5% total supply.");
        _swapTokensAtAmount = swapAmount;
    }

    function setLiquidityWallet(address liquidityWalletAddy) external onlyOwner {
        require(liquidityWalletAddy != ZERO, "liquidityWallet address cannot be 0");
        _isExcludedFromFees[liquidityWallet] = false;
        _isExcludedMaxTransactionAmount[liquidityWallet] = false;
        liquidityWallet = payable(liquidityWalletAddy);
        _isExcludedFromFees[liquidityWallet] = true;
        _isExcludedMaxTransactionAmount[liquidityWallet] = true;
    }

    function setTreasuryWallet(address treasuryWalletAddy) external onlyOwner {
        require(treasuryWalletAddy != ZERO, "treasuryWallet address cannot be 0");
        _isExcludedFromFees[treasuryWallet] = false;
        _isExcludedMaxTransactionAmount[treasuryWallet] = false;
        treasuryWallet = payable(treasuryWalletAddy);
        _isExcludedFromFees[treasuryWallet] = true;
        _isExcludedMaxTransactionAmount[treasuryWallet] = true;
    }

    function setDevelopmentWallet(address developmentWalletAddy) external onlyOwner {
        require(developmentWalletAddy != ZERO, "developmentWallet address cannot be 0");
        _isExcludedFromFees[developmentWallet] = false;
        _isExcludedMaxTransactionAmount[developmentWallet] = false;
        developmentWallet = payable(developmentWalletAddy);
        _isExcludedFromFees[developmentWallet] = true;
        _isExcludedMaxTransactionAmount[developmentWallet] = true;
    }

    function setExcludedFromFees(address[] memory accounts, bool isEx) external onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = isEx;
        }
    }
    
    function setExcludeFromMaxTransaction(address[] memory accounts, bool isEx) external onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            _isExcludedMaxTransactionAmount[accounts[i]] = isEx;
        }
    }
    
    function setBlacklisted(address[] memory accounts, bool exempt) external onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            _isBlacklisted[accounts[i]] = exempt;
        }
    }

    function setBuyFee(uint256 newBuyLiquidityFee, uint256 newBuyTreasuryFee, uint256 newBuyDevelopmentFee) external onlyOwner {
        require(newBuyLiquidityFee + newBuyTreasuryFee + newBuyDevelopmentFee <= 200, "Must keep buy taxes below 20%");
        buyLiquidityFee = newBuyLiquidityFee;
        buyTreasuryFee = newBuyTreasuryFee;
        buyDevelopmentFee = newBuyDevelopmentFee;
    }

    function setSellFee(uint256 newSellLiquidityFee, uint256 newSellTreasuryFee, uint256 newSellDevelopmentFee) external onlyOwner {
        require(newSellLiquidityFee + newSellTreasuryFee + newSellDevelopmentFee <= 200, "Must keep sell taxes below 20%");
        sellLiquidityFee = newSellLiquidityFee;
        sellTreasuryFee = newSellTreasuryFee;
        sellDevelopmentFee = newSellDevelopmentFee;
    }

    function setBlocksToBlacklist(uint256 blocks) external onlyOwner {
        require(blocks < 10, "Must keep blacklist blocks below 10");
        _blocksToBlacklist = blocks;
    }

    function setCooldownBlocks(uint256 blocks) external onlyOwner {
        require(blocks < 10, "Must keep cooldown blocks below 10");
        _cooldownBlocks = blocks;
    }

    function removeAllFee() private {
        if(buyLiquidityFee == 0 && buyTreasuryFee == 0 && buyDevelopmentFee == 0 && sellLiquidityFee == 0 && sellTreasuryFee == 0 && sellDevelopmentFee == 0) return;
        
        _previousBuyLiquidityFee = buyLiquidityFee;
        _previousBuyTreasuryFee = buyTreasuryFee;
        _previousBuyDevelopmentFee = buyDevelopmentFee;
        _previousSellLiquidityFee = sellLiquidityFee;
        _previousSellTreasuryFee = sellTreasuryFee;
        _previousSellDevelopmentFee = sellDevelopmentFee;
        
        buyLiquidityFee = 0;
        buyTreasuryFee = 0;
        buyDevelopmentFee = 0;
        sellLiquidityFee = 0;
        sellTreasuryFee = 0;
        sellDevelopmentFee = 0;
    }
    
    function restoreAllFee() private {
        buyLiquidityFee = _previousBuyLiquidityFee;
        buyTreasuryFee = _previousBuyTreasuryFee;
        buyDevelopmentFee = _previousBuyDevelopmentFee;
        sellLiquidityFee = _previousSellLiquidityFee;
        sellTreasuryFee = _previousSellTreasuryFee;
        sellDevelopmentFee = _previousSellDevelopmentFee;
    }
        
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee, bool isSell) private {
        if(!takeFee) {
            removeAllFee();
        } else {
            amount = _takeFees(sender, amount, isSell);
        }

        _transferStandard(sender, recipient, amount);
        
        if(!takeFee) {
            restoreAllFee();
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        _rOwned[sender] = _rOwned[sender].sub(tAmount);
        _rOwned[recipient] = _rOwned[recipient].add(tAmount);
        emit Transfer(sender, recipient, tAmount);
    }

    function _takeFees(address sender, uint256 amount, bool isSell) private returns (uint256) {
        uint256 _totalFees;
        uint256 liqFee;
        uint256 trsryFee;
        uint256 devFee;
        if(tradingActiveBlock + _blocksToBlacklist >= block.number){
            _totalFees = 999;
            liqFee = 333;
            trsryFee = 333;
            devFee = 333;
        } else {
            _totalFees = _getTotalFees(isSell);
            if (isSell) {
                liqFee = sellLiquidityFee;
                trsryFee = sellTreasuryFee;
                devFee = sellDevelopmentFee;
            } else {
                liqFee = buyLiquidityFee;
                trsryFee = buyTreasuryFee;
                devFee = buyDevelopmentFee;
            }
        }

        uint256 fees = amount.mul(_totalFees).div(FEE_DIVISOR);
        _tokensForLiquidity += fees * liqFee / _totalFees;
        _tokensForTreasury += fees * trsryFee / _totalFees;
        _tokensForDevelopment += fees * devFee / _totalFees;
            
        if(fees > 0) {
            _transferStandard(sender, address(this), fees);
        }
            
        return amount -= fees;
    }

    function _getTotalFees(bool isSell) private view returns(uint256) {
        if (isSell) {
            return sellLiquidityFee + sellTreasuryFee + sellDevelopmentFee;
        }
        return buyLiquidityFee + buyTreasuryFee + buyDevelopmentFee;
    }

    receive() external payable {}
    fallback() external payable {}
    
    function unclog() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForTokens(contractBalance);
    }
    
    function distributeFees() external onlyOwner {
        _receiver.withdraw();
        uint256 contractUSDCBalance = IERC20(USDC).balanceOf(address(this));
        sendUSDCToFee(contractUSDCBalance);
    }

    function withdrawStuckETH() external onlyOwner {
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

    function withdrawStuckTokens(address tkn) external onlyOwner {
        require(tkn != address(this), "Cannot withdraw this token");
        require(IERC20(tkn).balanceOf(address(this)) > 0, "No tokens");
        uint amount = IERC20(tkn).balanceOf(address(this));
        IERC20(tkn).transfer(msg.sender, amount);
    }

}