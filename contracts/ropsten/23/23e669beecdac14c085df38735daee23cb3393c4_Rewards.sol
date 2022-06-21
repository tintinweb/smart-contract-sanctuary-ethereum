/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
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
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
library SafeMathInt {
  int256 private constant MIN_INT256 = int256(1) << 255;
  int256 private constant MAX_INT256 = ~(int256(1) << 255);

  function mul(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a * b;
    require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
    require((b == 0) || (c / b == a));
    return c;
  }

  function div(int256 a, int256 b) internal pure returns (int256) {
    require(b != -1 || a != MIN_INT256);
    return a / b;
  }

  function sub(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a - b;
    require((b >= 0 && c <= a) || (b < 0 && c > a));
    return c;
  }

  function add(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a + b;
    require((b >= 0 && c >= a) || (b < 0 && c < a));
    return c;
  }

  function abs(int256 a) internal pure returns (int256) {
    require(a != MIN_INT256);
    return a < 0 ? -a : a;
  }

  function toUint256Safe(int256 a) internal pure returns (uint256) {
    require(a >= 0);
    return uint256(a);
  }
}
library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}
interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}
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

contract Tracker is Ownable {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

  uint256 public totalBalance;
  uint256 public totalDistributed;
  uint256 internal magnifiedBalance;
  uint256 internal MAGNIFIER;

  mapping(address => uint256) public balanceOf;
  mapping(address => int256) internal magnifiedCorrections;
  mapping(address => uint256) internal withdrawnRewards;

  event FundsDeposited(address indexed from, uint amount);
  event FundsWithdrawn(address indexed account, uint amount);

  constructor() { }
  function __Tracker_init()  public onlyOwner  {
      MAGNIFIER = 2**128;
  }

  receive() external payable {
    require(msg.value > 0, "No funds sent");
    require(totalBalance > 0, "No balances tracked");

    distributeFunds(msg.value);
    emit FundsDeposited(msg.sender, msg.value);
  }

  function getAccumulated(address account) public view returns(uint256) {
    return magnifiedBalance.mul(balanceOf[account]).toInt256Safe().add(magnifiedCorrections[account]).toUint256Safe() / MAGNIFIER;
  }

  function getPending(address account) public view returns(uint256) {
    return getAccumulated(account).sub(withdrawnRewards[account]);
  }

  function getWithdrawn(address account) external view returns(uint256) {
    return withdrawnRewards[account];
  }

  function putBalance(address account, uint256 newBalance) public virtual onlyOwner {
    updateBalance(account, newBalance);
  }

  function withdrawFunds(address payable account) public virtual {
    uint256 amount = processWithdraw(account);
    if (amount > 0) emit FundsWithdrawn(account, amount);
  }

  // PRIVATE

  function decreaseBalance(address account, uint256 amount) internal {
    magnifiedCorrections[account] = magnifiedCorrections[account].add((magnifiedBalance.mul(amount)).toInt256Safe());
  }

  function distributeFunds(uint256 amount) internal virtual {
    if (totalBalance > 0 && amount > 0) {
      magnifiedBalance = magnifiedBalance.add((amount).mul(MAGNIFIER) / totalBalance);
      totalDistributed = totalDistributed.add(amount);
    }
  }

  function increaseBalance(address account, uint256 amount) internal {
    magnifiedCorrections[account] = magnifiedCorrections[account].sub((magnifiedBalance.mul(amount)).toInt256Safe());
  }

  function processWithdraw(address payable account) internal returns (uint256) {
    uint256 amount = getPending(account);
    if (amount <= 0) return 0;
    withdrawnRewards[account] = withdrawnRewards[account].add(amount);

    if (sendReward(account, amount)) return amount;

    withdrawnRewards[account] = withdrawnRewards[account].sub(amount);
    return 0;
  }

  function sendReward(address payable account, uint256 amount) internal virtual returns (bool) {
    (bool success,) = account.call{value: amount, gas: 3000}("");
    return success;
  }

  function updateBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = balanceOf[account];
    balanceOf[account] = newBalance;
    if (newBalance > currentBalance) {
      uint256 increaseAmount = newBalance.sub(currentBalance);
      increaseBalance(account, increaseAmount);
      totalBalance += increaseAmount;
    } else if(newBalance < currentBalance) {
      uint256 reduceAmount = currentBalance.sub(newBalance);
      decreaseBalance(account, reduceAmount);
      totalBalance -= reduceAmount;
    }
  }
}
contract Rewards is Tracker {
  using SafeMath for uint256;
  using SafeMathInt for int256;

  IUniswapV2Router02 public  uniswapV2Router;
  address payable public variegate;

  struct Holder {
    uint256 index;
    uint256 balance;
    uint32 percent;
    uint32 added;
    uint32 excluded;
    uint32 bought;
    uint32 sold;
    uint32 claimed;
  }

  uint256 public holders;
  uint256 public currentHolder;
  mapping (uint256 => address) public holderAt;
  mapping (address => Holder) public holder;

  struct Token {
    address token;
    uint256 index;
    uint256 added;     // date added
    uint256 claims;   // # of claims processed
    uint256 balance; // total tokens distributed
    uint256 amount; // total BNB of tokens distributed
  }

  uint256 public tokens = 0;
  mapping (uint256 => address) public tokenAt;
  mapping (address => Token) public token;

  uint256 public MAX_SLOTS;
  uint256 public slots ;
  uint256 public offset ;
  mapping (uint256 => address) public tokenInSlot;

  uint256 public minimumBalance;
  uint256 public waitingPeriod;
  bool public isStakingOn;
  uint256 public totalTracked;

  event ClaimsProcessed(uint256 iterations, uint256 claims, uint256 lastRecord, uint256 gasUsed);
  event ExcludedChanged(address indexed account, bool excluded);
  event MinimumBalanceChanged(uint256 from, uint256 to);
  event StakingChanged(bool from, bool to);
  event WaitingPeriodChanged(uint256 from, uint256 to);
  event TokenAdded(address indexed token, string name);
  event TokenDeleted(address indexed token, string name);
  event SlotSet(uint256 slot, address indexed token, string name);

 // constructor() {};
    function __Rewards_init()  public onlyOwner  {
    __Tracker_init();

    MAX_SLOTS = 10;
    slots = 0;
    offset = 0;

    minimumBalance = 500_000 ether;
    waitingPeriod = 6 hours;
    isStakingOn = true;

    address ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    // address ROUTER_PCSV2_TESTNET = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    // address ROUTER_FAKEPCS_TESTNET = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    IUniswapV2Router02 router = IUniswapV2Router02(ROUTER);
    uniswapV2Router = router;
    holder[owner()].excluded = stamp();
  }

  function addToken(address key) external onlyOwner {
    require(isContract(key), "Not a contract");
    require(token[key].added==0, "Token exists");

    token[key].token = key;
    token[key].added = stamp();
    tokens++;
    tokenAt[tokens] = key;
    token[key].index = tokens;
    emit TokenAdded(key, IERC20Metadata(key).name());
  }

  function currentSlot() public view returns (uint256) {
    if (slots==0) return 0;
    uint256 since = block.timestamp / (24 * 60 * 60) + offset;
    return (since % slots) + 1;
  }

  function deleteSlot(uint256 slot) external onlyOwner {
    require(slot>0 && slot <= slots, "Value invalid");

    for (uint256 idx=slot; idx<slots; idx++) {
      tokenInSlot[idx] = tokenInSlot[idx+1];
    }
    delete tokenInSlot[slots];
    slots--;
  }

  function deleteToken(address remove) external onlyOwner { // REMOVES TRACKING DATA
    require(token[remove].added > 0, "Token not found");

    token[tokenAt[tokens]].index = token[remove].index; // LAST TOKEN TAKES THIS ONES PLACE
    tokenAt[token[remove].index] = tokenAt[tokens]; // LAST TOKEN TAKES THIS ONES PLACE
    delete tokenAt[tokens];
    delete token[remove];
    tokens--;
    emit TokenDeleted(remove, IERC20Metadata(remove).name());
  }

  function getReport() external view returns (uint256 holderCount, bool stakingOn, uint256 totalTokensTracked, uint256 totalTokensStaked, uint256 totalRewardsPaid, uint256 requiredBalance, uint256 waitPeriodSeconds) {
    holderCount = holders;
    stakingOn = isStakingOn;
    totalTokensTracked = totalTracked;
    totalTokensStaked = totalBalance;
    totalRewardsPaid = totalDistributed;
    requiredBalance = minimumBalance;
    waitPeriodSeconds = waitingPeriod;
  }

  function getReportAccount(address key) public view returns (address account, uint256 index, uint256 balance, uint256 stakedPercent, uint256 stakedTokens, uint256 rewardsEarned, uint256 rewardsClaimed, uint256 claimHours) {
    require(holder[key].added > 0, "Value invalid");

    account = key;
    index = holder[account].index;
    balance = holder[account].balance;
    stakedPercent = holder[account].percent;
    stakedTokens = balanceOf[account];
    rewardsEarned = getAccumulated(account);
    rewardsClaimed = withdrawnRewards[account];
    claimHours = ageInHours(holder[account].claimed);
  }

  function getReportAccountAt(uint256 indexOf) public view returns (address account, uint256 index, uint256 balance, uint256 stakedPercent, uint256 stakedTokens, uint256 rewardsEarned, uint256 rewardsClaimed, uint256 claimHours) {
    require(indexOf > 0 && indexOf <= holders, "Value invalid");

    return getReportAccount(holderAt[indexOf]);
  }

  function getReportToken(address key) public view returns (string memory name, string memory symbol, address tokenAddress, uint256 claims, uint256 balance, uint256 amount) {
    require(token[key].added > 0, "Token not found");

    IERC20Metadata reward = IERC20Metadata(key);
    name = reward.name();
    symbol = reward.symbol();
    tokenAddress = key;
    claims = token[key].claims;
    balance = token[key].balance;
    amount = token[key].amount;
  }

  function getReportTokenInSlot(uint256 slot) external view returns (string memory name, string memory symbol, address tokenAddress, uint256 claims, uint256 balance, uint256 amount) {
    require(slots > 0 && slot>=0 && slot <= slots, "Value invalid");

    if (slot==0) slot = currentSlot();

    return getReportToken(tokenInSlot[slot]);
  }

  function getTokens() external view returns (string[] memory) {
    string[] memory data = new string[](tokens);
    for (uint256 idx=1; idx<=slots; idx++) {
      data[idx-1] = IERC20Metadata(tokenInSlot[idx]).name();
    }
    return data;
  }

  function processClaims(uint256 gas) external {
    if (holders==0) return;

    uint256 gasUsed = 0;
    uint256 gasLeft = gasleft();
    uint256 iterations = 0;
    uint256 claims = 0;

    while (gasUsed < gas && iterations < holders) {
      bool worthy = (address(this).balance > (1 ether / 10)); // ENOUGH FUNDS TO WARRANT PUSHING?
      // IF WORTHY 1 LOOP COST MAX ~65_000 GAS, UNWORTHY MAX ~8_500 GAS
      if (gasLeft < (worthy ? 65_000 : 8_500)) break; // EXIT IF NOT ENOUGH TO PROCESS THIS ITERATION TO AVOID OOG ERROR

      currentHolder = (currentHolder % holders) + 1;
      address account = holderAt[currentHolder];
      updatedWeightedBalance(account);
      if (worthy && pushFunds(account)) claims++;
      iterations++;
      uint256 newGasLeft = gasleft();
      if (gasLeft > newGasLeft) gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
      gasLeft = newGasLeft;
    }

    emit ClaimsProcessed(iterations, claims, currentHolder, gasUsed);
  }

  function setExcluded(address account, bool setting) external onlyOwner {
    require(setting && holder[account].excluded==0 || !setting && holder[account].excluded!=0, "Value unchanged");

    holder[account].excluded = setting ? 0 : stamp();
    setBalance(account, holder[account].balance);
    emit ExcludedChanged(account, true);
  }

  function setCurrentSlot(uint256 slot) external onlyOwner {
    require(slot>0 && slot <= slots, "Value invalid");
    offset = 0;
    offset = (slots + slot - currentSlot()) % 7;
  }

  function setMinimumBalance(uint256 newBalance) external onlyOwner {
    require(newBalance >= 100_000 && newBalance <= 500_000, "Value invalid");
    newBalance = (newBalance * 1 ether);
    require(newBalance != minimumBalance, "Value unchanged");
    require(minimumBalance > newBalance, "Value cannot increase");

    emit MinimumBalanceChanged(minimumBalance, newBalance);
    minimumBalance = newBalance;
  }

  function setSlot(uint256 slot, address key) public onlyOwner {
    require(slot>=0 && slot <= slots, "Value invalid");
    require(slot>0 || slots < MAX_SLOTS, "All slots filled");
    require(token[key].added>0, "Token not found");

    if (slot==0) {
      slots++;
      slot = slots;
    }
    tokenInSlot[slot] = key;
    emit SlotSet(slot, key, IERC20Metadata(key).name());
  }

  function setSlots(address[] memory keys) external onlyOwner {
    require(keys.length > 0 && keys.length < MAX_SLOTS, "Too many values");
    for (uint256 idx=0; idx<keys.length; idx++) require(token[keys[idx]].added>0, "Token not found");

    for (uint256 idx=1; idx<=slots; idx++) delete tokenInSlot[idx];
    slots = 0;
    for (uint256 idx=0; idx<keys.length; idx++) setSlot(0, keys[idx]);
  }

  function setStaking(bool setting) external onlyOwner {
    require(isStakingOn!=setting, "Value unchanged");

    isStakingOn = setting;
    emit StakingChanged(!setting, setting);
  }

  function setWaitingPeriod(uint256 inSeconds) external onlyOwner {
    require(inSeconds != waitingPeriod, "Value unchanged");
    require(inSeconds >= 1 hours && inSeconds <= 1 days, "Value invalid");

    emit WaitingPeriodChanged(waitingPeriod, inSeconds);
    waitingPeriod = inSeconds;
  }

  function trackBuy(address account, uint256 newBalance) public onlyOwner {
    if (holder[account].added==0) holder[account].added = stamp();
    holder[account].bought = stamp();
    setBalance(account, newBalance);
  }

  function trackSell(address account, uint256 newBalance) public onlyOwner {
    holder[account].sold = stamp();
    setBalance(account, newBalance);
  }
  function trackAction(address from, uint256 fromBalance, address to, uint256 toBalance) external onlyOwner {
    if ( from != address(0))
      trackSell(from, fromBalance);
    if ( to != address(0))
    trackBuy(to, toBalance);
  }
  function withdrawFunds(address payable account) public override { // EMITS EVENT
    require(getPending(account) > 0, "No funds");
    require(canClaim(holder[account].claimed), "Wait time active");

    updatedWeightedBalance(account);
    holder[account].claimed = stamp();
    super.withdrawFunds(account);
  }

  // PRIVATE

  function _transferOwnership(address newOwner) internal override {
    super._transferOwnership(newOwner);
    if (isContract(newOwner)) variegate = payable(newOwner);
  }

  function ageInDays(uint32 stamped) private view returns (uint32) {
    return ageInHours(stamped) / 24;
  }

  function ageInHours(uint32 stamped) private view returns (uint32) {
    return stamped==0 ? 0 : (stamp() - stamped) / 1 hours;
  }

  function canClaim(uint48 lastClaimTime) private view returns (bool) {
    if (lastClaimTime > block.timestamp) return false;
    return block.timestamp.sub(lastClaimTime) >= waitingPeriod;
  }

  function holderSet(address account, uint256 val) private {
    if (holder[account].index==0) {
      holders++;
      holderAt[holders] = account;
      holder[account].index = holders;
    }
    holder[account].balance = val;
  }

  function holderRemove(address account) private {
    if (holder[account].index==0) return;

    // COPY LAST ROW INTO SLOT BEING DELETED
    holder[holderAt[holders]].index = holder[account].index;
    holderAt[holder[account].index] = holderAt[holders];

    delete holderAt[holders];
    holders--;
    holder[account].index = 0;
  }

  function isContract(address key) private view returns (bool) {
    return key.code.length > 0;
  }

  function setBalance(address account, uint256 newBalance) private {
    if (newBalance < minimumBalance || holder[account].excluded!=0) { // BELOW MIN OR EXCLUDED
      totalTracked -= holder[account].balance;
      updateBalance(account, 0);
      holderRemove(account); // REMOVE FROM ARRAY TO THIN STORAGE
      return;
    }

    if (newBalance > holder[account].balance) {
      totalTracked += newBalance.sub(holder[account].balance);
    } else if(newBalance < holder[account].balance) {
      totalTracked -= holder[account].balance.sub(newBalance);
    }

    holderSet(account, newBalance);
    putWeighted(account);

    if (getPending(account) <= 0) return; // NOTHING PENDING WE ARE DONE HERE
    // PUSH FUNDS TO ACCOUNT W/EVENT AND UPDATE CLAIMED STAMP
    holder[account].claimed = stamp();
    super.withdrawFunds(payable(account));
  }

  function stakePercent(address account) internal view returns (uint32) {
    if (!isStakingOn) return 100;
    uint32 stamped = holder[account].sold;
    if (stamped==0) stamped = holder[account].added;
    uint32 age = ageInDays(stamped);
    return (age > 50) ? 100 : 50 + age;
  }

  function stamp() private view returns (uint32) {
    return uint32(block.timestamp); // - 1231006505 seconds past BTC epoch
  }

  function pushFunds(address account) internal returns (bool) {
    if (!canClaim(holder[account].claimed) || getPending(account)==0) return false;

    super.withdrawFunds(payable(account));

    holder[account].claimed = stamp();
    return true;
  }

  function putWeighted(address account) private {
    holder[account].percent = stakePercent(account);
    updateBalance(account, weightedBalance(account));
  }

  function sendReward(address payable account, uint256 amount) internal override returns (bool) {
    if (currentSlot()==0) return super.sendReward(account, amount);

    address tkn = tokenInSlot[currentSlot()];
    IERC20 rewards = IERC20(tkn);
    uint256 before = rewards.balanceOf(account);
    address[] memory path = new address[](2);
    path[0] = uniswapV2Router.WETH();
    path[1] = tkn;

    try uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount} (0, path, address(account), block.timestamp){
      token[tkn].balance += rewards.balanceOf(account).sub(before);
      token[tkn].amount += amount;
      token[tkn].claims++;
    } catch {
      return false;
    }
    return true;
  }

  function weightedBalance(address account) internal view returns (uint256) {
    uint256 balance = holder[account].balance;
    if (!isStakingOn || balance==0 || holder[account].percent > 99) return balance;
    return balance.mul(holder[account].percent).div(100);
  }

  function updatedWeightedBalance(address account) internal {
    if (holder[account].percent==stakePercent(account)) return; // NO CHANGE
    putWeighted(account); // REWEIGHT TOKENS
  }
}