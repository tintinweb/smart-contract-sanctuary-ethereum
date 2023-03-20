/**
 *Submitted for verification at Etherscan.io on 2023-03-20
*/

/**
 *Submitted for verification at snowtrace.io on 2022-05-20
*/

// Dependency file: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/Context.sol";

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


// Dependency file: @openzeppelin/contracts/utils/math/SafeMath.sol

// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

// pragma solidity ^0.8.0;

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


// Dependency file: contracts/interfaces/IJoeFactory.sol

// pragma solidity ^0.8.13;

interface IJoeFactory {
  function createPair(address tokenA, address tokenB) external returns (address pair);
}


// Dependency file: contracts/interfaces/IJoePair.sol

// pragma solidity ^0.8.13;

interface IJoePair {
  function sync() external;
}


// Dependency file: contracts/interfaces/IUniswapV2Router.sol

// pragma solidity ^0.8.13;

interface IUniswapV2Router {
  function factory() external pure returns (address);

  function WETH() external pure returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
}


// Root file: contracts/Stash.sol

pragma solidity ^0.8.13;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// import "contracts/interfaces/IJoeFactory.sol";
// import "contracts/interfaces/IJoePair.sol";
// import "contracts/interfaces/IUniswapV2Router.sol";

/**
 * @title STASH ERC20 token
 * @dev This is part of an implementation of the Stash protocol.
 *      STASH is a normal ERC20 token, but its supply can be adjusted by splitting and
 *      combining tokens proportionally across all wallets.
 *
 *      Stash balances are internally represented with a hidden denomination, 'gons'.
 *      We support splitting the currency in expansion and combining the currency on contraction by
 *      changing the exchange rate between the hidden 'gons' and the public 'fragments'.
 */
contract Stash is IERC20, Ownable {
  using SafeMath for uint256;

  string private constant _name = "Stash";
  string private constant _symbol = "STASH";
  uint8 private constant _decimals = 5;

  uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 500 * 10**3 * 10**_decimals;
  uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);
  uint256 private constant MAX_SUPPLY = 500 * 10**7 * 10**_decimals;

  address constant DEAD = 0x000000000000000000000000000000000000dEaD;
  address constant ZERO = 0x0000000000000000000000000000000000000000;

  uint256 public constant ADD_LIQUIDITY_PERIOD = 2 days;
  uint256 public constant MAX_UINT256 = ~uint256(0);
  uint8 public constant RATE_DECIMALS = 7;
  uint256 public constant REBASE_PERIOD = 15 minutes;

  bool private inSwap = false;
  uint256 private _totalSupply;
  uint256 private _gonsPerFragment;
  mapping(address => bool) private _isFeeExempt;
  mapping(address => uint256) private _gonBalances;
  mapping(address => mapping(address => uint256)) private _allowedFragments;

  uint256 public basicRebaseRate = 2374;

  uint256 public liquidityFee = 40;
  uint256 public treasuryFee = 20;
  uint256 public stashInsuranceFundFee = 50;
  uint256 public sellFee = 30;
  uint256 public burnRate = 20;
  uint256 public totalFee = liquidityFee.add(treasuryFee).add(stashInsuranceFundFee).add(burnRate);
  uint256 public feeDenominator = 1000;

  bool public autoRebase;
  bool public autoAddLiquidity;
  bool public autoSwapback;

  uint256 public initRebaseStartTime;
  uint256 public lastRebasedTime;
  uint256 public lastAddLiquidityTime;

  address public autoLiquidityReceiver;
  address public treasuryReceiver;
  address public stashInsuranceFundReceiver;
  address public pair;
  IUniswapV2Router public router;
  mapping(address => bool) public blacklist;

  event LogRebase(uint256 indexed epoch, uint256 lastTotalSupply, uint256 currentTotalSupply);

  modifier validRecipient(address to) {
    require(to != address(0x0));
    _;
  }

  modifier swapping() {
    inSwap = true;
    _;
    inSwap = false;
  }

  constructor(
    address _UniswapV2Router,
    address _autoLiquidityReceiver,
    address _treasuryReceiver,
    address _stashInsuranceFundReceiver
  ) {
    router = IUniswapV2Router(_UniswapV2Router);
    pair = IJoeFactory(router.factory()).createPair(router.WETH(), address(this));

    autoLiquidityReceiver = _autoLiquidityReceiver;
    treasuryReceiver = _treasuryReceiver;
    stashInsuranceFundReceiver = _stashInsuranceFundReceiver;

    _allowedFragments[address(this)][address(router)] = MAX_UINT256;

    _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
    _gonBalances[treasuryReceiver] = TOTAL_GONS;
    _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
    _isFeeExempt[treasuryReceiver] = true;
    _isFeeExempt[address(this)] = true;

    emit Transfer(address(0x0), treasuryReceiver, _totalSupply);
  }

  /**
   * @dev Get current rebase rate of Stash tokens.
   * Rebase rate will reduce as time goes by
   */
  function getRebaseRate() public view returns (uint256 rebaseRate) {
    uint256 deltaTimeFromInit = block.timestamp - initRebaseStartTime;

    if (deltaTimeFromInit < (365 days)) {
      rebaseRate = basicRebaseRate;
    } else if (deltaTimeFromInit >= (365 days)) {
      rebaseRate = 211;
    } else if (deltaTimeFromInit >= ((15 * 365 days) / 10)) {
      rebaseRate = 14;
    } else if (deltaTimeFromInit >= (7 * 365 days)) {
      rebaseRate = 2;
    }
  }

  function setBasicRebaseRate(uint256 value) external onlyOwner {
    basicRebaseRate = value;
  }

  /**
   * @dev Notifies Stash contract about a new rebase cycle
   * After a rebase, the totalSupply should increase proportionally to the current rebase rate.
   */
  function rebase() internal {
    if (inSwap) return;
    uint256 deltaTime = block.timestamp - lastRebasedTime;
    uint256 times = deltaTime.div(REBASE_PERIOD);
    uint256 epoch = times.mul(15);
    uint256 rebaseRate = getRebaseRate();

    uint256 lastTotalSupply = _totalSupply;
    for (uint256 i = 0; i < times; i++) {
      _totalSupply = _totalSupply.mul((10**RATE_DECIMALS).add(rebaseRate)).div(10**RATE_DECIMALS);
    }

    _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
    lastRebasedTime = lastRebasedTime.add(times.mul(REBASE_PERIOD));

    IJoePair(pair).sync();

    emit LogRebase(epoch, lastTotalSupply, _totalSupply);
  }

  function transfer(address to, uint256 value) external override validRecipient(to) returns (bool) {
    _transferFrom(msg.sender, to, value);
    return true;
  }

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external override validRecipient(to) returns (bool) {
    uint256 currentAllowance = allowance(from, msg.sender);
    if (currentAllowance != MAX_UINT256) {
      _allowedFragments[from][msg.sender] = currentAllowance.sub(value, "ERC20: insufficient allowance");
    }
    _transferFrom(from, to, value);
    return true;
  }

  function _basicTransfer(
    address from,
    address to,
    uint256 amount
  ) internal returns (bool) {
    uint256 gonAmount = amount.mul(_gonsPerFragment);
    _gonBalances[from] = _gonBalances[from].sub(gonAmount, "ERC20: transfer amount exceeds balance");
    _gonBalances[to] = _gonBalances[to].add(gonAmount);
    return true;
  }

  function _transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) internal returns (bool) {
    require(!blacklist[sender] && !blacklist[recipient], "ADDRESS_IN_BLACKLIST");

    if (inSwap) {
      return _basicTransfer(sender, recipient, amount);
    }
    if (shouldRebase()) {
      rebase();
    }

    if (shouldAddLiquidity()) {
      addLiquidity();
    }

    if (shouldSwapBack()) {
      swapBack();
    }

    uint256 gonAmount = amount.mul(_gonsPerFragment);
    _gonBalances[sender] = _gonBalances[sender].sub(gonAmount, "ERC20: transfer amount exceeds balance");
    uint256 gonAmountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, recipient, gonAmount) : gonAmount;
    _gonBalances[recipient] = _gonBalances[recipient].add(gonAmountReceived);

    emit Transfer(sender, recipient, gonAmountReceived.div(_gonsPerFragment));
    return true;
  }

  function takeFee(
    address sender,
    address recipient,
    uint256 gonAmount
  ) internal returns (uint256) {
    uint256 _totalFee = totalFee;
    uint256 _treasuryFee = treasuryFee;

    if (recipient == pair) {
      _totalFee = totalFee.add(sellFee);
      _treasuryFee = treasuryFee.add(sellFee);
    }

    uint256 feeAmount = gonAmount.div(feeDenominator).mul(_totalFee);

    // burn tokens
    _gonBalances[DEAD] = _gonBalances[DEAD].add(gonAmount.div(feeDenominator).mul(burnRate));
    _gonBalances[address(this)] = _gonBalances[address(this)].add(gonAmount.div(feeDenominator).mul(_treasuryFee.add(stashInsuranceFundFee)));
    _gonBalances[autoLiquidityReceiver] = _gonBalances[autoLiquidityReceiver].add(gonAmount.div(feeDenominator).mul(liquidityFee));

    emit Transfer(sender, address(this), feeAmount.div(_gonsPerFragment));
    return gonAmount.sub(feeAmount);
  }

  function addLiquidity() internal swapping {
    uint256 autoLiquidityAmount = _gonBalances[autoLiquidityReceiver].div(_gonsPerFragment);
    _gonBalances[address(this)] = _gonBalances[address(this)].add(_gonBalances[autoLiquidityReceiver]);
    _gonBalances[autoLiquidityReceiver] = 0;
    uint256 amountToLiquify = autoLiquidityAmount.div(2);
    uint256 amountToSwap = autoLiquidityAmount.sub(amountToLiquify);

    if (amountToSwap == 0) {
      return;
    }
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = router.WETH();

    uint256 balanceBefore = address(this).balance;

    router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountToSwap, 0, path, address(this), block.timestamp);

    uint256 amountETHLiquidity = address(this).balance.sub(balanceBefore);

    if (amountToLiquify > 0 && amountETHLiquidity > 0) {
      router.addLiquidityETH{value: amountETHLiquidity}(address(this), amountToLiquify, 0, 0, autoLiquidityReceiver, block.timestamp);
    }
    lastAddLiquidityTime = block.timestamp;
  }

  function swapBack() internal swapping {
    uint256 amountToSwap = _gonBalances[address(this)].div(_gonsPerFragment);

    if (amountToSwap == 0) {
      return;
    }

    uint256 balanceBefore = address(this).balance;
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = router.WETH();

    router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountToSwap, 0, path, address(this), block.timestamp);

    uint256 amountETHToTreasuryAndSIF = address(this).balance.sub(balanceBefore);

    (bool success, ) = payable(treasuryReceiver).call{value: amountETHToTreasuryAndSIF.mul(treasuryFee).div(treasuryFee.add(stashInsuranceFundFee)), gas: 30000}("");
    (success, ) = payable(stashInsuranceFundReceiver).call{value: amountETHToTreasuryAndSIF.mul(stashInsuranceFundFee).div(treasuryFee.add(stashInsuranceFundFee)), gas: 30000}("");
  }

  function withdrawAllToTreasury() external swapping onlyOwner {
    uint256 amountToSwap = _gonBalances[address(this)].div(_gonsPerFragment);
    require(amountToSwap > 0, "NO_TOKENS_DEPOSITED");
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = router.WETH();
    router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountToSwap, 0, path, treasuryReceiver, block.timestamp);
  }

  function shouldTakeFee(address from, address to) internal view returns (bool) {
    if (_isFeeExempt[from] || _isFeeExempt[to]) {
      return false;
    }

    return (pair == from || pair == to);
  }

  function shouldRebase() internal view returns (bool) {
    return autoRebase && (_totalSupply < MAX_SUPPLY) && msg.sender != pair && !inSwap && block.timestamp >= (lastRebasedTime + REBASE_PERIOD);
  }

  function shouldAddLiquidity() internal view returns (bool) {
    return autoAddLiquidity && !inSwap && msg.sender != pair && block.timestamp >= (lastAddLiquidityTime + ADD_LIQUIDITY_PERIOD);
  }

  function shouldSwapBack() internal view returns (bool) {
    return autoSwapback && !inSwap && msg.sender != pair;
  }

  function setAutoRebase(bool _flag) external onlyOwner {
    if (_flag) {
      autoRebase = _flag;
      if (initRebaseStartTime == 0) {
        initRebaseStartTime = block.timestamp;
      }
      lastRebasedTime = block.timestamp;
    } else {
      autoRebase = _flag;
    }
  }

  function setAutoAddLiquidity(bool _flag) external onlyOwner {
    if (_flag) {
      autoAddLiquidity = _flag;
      lastAddLiquidityTime = block.timestamp;
    } else {
      autoAddLiquidity = _flag;
    }
  }

  function setAutoSwapback(bool flag) external onlyOwner {
    autoSwapback = flag;
  }

  function allowance(address owner_, address spender) public view override returns (uint256) {
    return _allowedFragments[owner_][spender];
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
    uint256 oldValue = _allowedFragments[msg.sender][spender];
    if (subtractedValue >= oldValue) {
      _allowedFragments[msg.sender][spender] = 0;
    } else {
      _allowedFragments[msg.sender][spender] = oldValue.sub(subtractedValue);
    }
    emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
    _allowedFragments[msg.sender][spender] = _allowedFragments[msg.sender][spender].add(addedValue);
    emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
    return true;
  }

  function approve(address spender, uint256 value) external override returns (bool) {
    _allowedFragments[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function checkFeeExempt(address _addr) external view returns (bool) {
    return _isFeeExempt[_addr];
  }

  function getCirculatingSupply() public view returns (uint256) {
    return (TOTAL_GONS.sub(_gonBalances[DEAD]).sub(_gonBalances[ZERO])).div(_gonsPerFragment);
  }

  function isNotInSwap() external view returns (bool) {
    return !inSwap;
  }

  function manualSync() external {
    IJoePair(pair).sync();
  }

  function setFeeReceivers(
    address _autoLiquidityReceiver,
    address _treasuryReceiver,
    address _stashInsuranceFundReceiver
  ) external onlyOwner {
    autoLiquidityReceiver = _autoLiquidityReceiver;
    treasuryReceiver = _treasuryReceiver;
    stashInsuranceFundReceiver = _stashInsuranceFundReceiver;
  }

  function setFees(
    uint256 _liquidityFee,
    uint256 _treasuryFee,
    uint256 _stashInsuranceFundFee,
    uint256 _sellFee,
    uint256 _burnRate,
    uint256 _feeDenominator
  ) external onlyOwner {
    liquidityFee = _liquidityFee;
    treasuryFee = _treasuryFee;
    stashInsuranceFundFee = _stashInsuranceFundFee;
    sellFee = _sellFee;
    burnRate = _burnRate;
    feeDenominator = _feeDenominator;
  }

  function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
    uint256 liquidityBalance = _gonBalances[pair].div(_gonsPerFragment);
    return accuracy.mul(liquidityBalance.mul(2)).div(getCirculatingSupply());
  }

  function setWhitelist(address _addr) external onlyOwner {
    _isFeeExempt[_addr] = true;
  }

  function setBotBlacklist(address _botAddress, bool _flag) external onlyOwner {
    require(isContract(_botAddress), "MUST_BE_A_CONTRACT_ADDRESS");
    blacklist[_botAddress] = _flag;
  }

  function setLP(address _address) external onlyOwner {
    pair = _address;
  }

  function totalSupply() external view override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address who) external view override returns (uint256) {
    return _gonBalances[who].div(_gonsPerFragment);
  }

  /**
   * @dev Returns the name of the token.
   */
  function name() public pure returns (string memory) {
    return _name;
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() public pure returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the number of decimals used to get its user representation.
   * For example, if `decimals` equals `2`, a balance of `505` tokens should
   * be displayed to a user as `5.05` (`505 / 10 ** 2`).
   *
   * Tokens usually opt for a value of 18, imitating the relationship between
   * Ether and Wei. This is the value {ERC20} uses, unless this function is
   * overridden;
   *
   * NOTE: This information is only used for _display_ purposes: it in
   * no way affects any of the arithmetic of the contract, including
   * {IERC20-balanceOf} and {IERC20-transfer}.
   */
  function decimals() public pure returns (uint8) {
    return _decimals;
  }

  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    assembly {
      size := extcodesize(addr)
    }
    return size > 0;
  }

  /**
   * @dev Function allows admin to withdraw ETH accidentally dropped to the contract.
   */
  function rescue() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  /**
   * @dev Function allows admin to withdraw tokens accidentally dropped to the contract.
   */
  function rescueToken(address tokenAddress, uint256 amount) external onlyOwner {
    require(IERC20(tokenAddress).transfer(msg.sender, amount), "RESCUE_TOKENS_FAILED");
  }

  receive() external payable {}
}