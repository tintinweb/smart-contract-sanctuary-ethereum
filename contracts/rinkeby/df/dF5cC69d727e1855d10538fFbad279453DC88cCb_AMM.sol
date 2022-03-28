pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AMM{
  using SafeMath for uint256;

  uint256 public reserve0;
  uint256 public reserve1;
  address public token0;
  address public token1;
  
  enum SwapType{
    NORMAL,
    LEVERAGE,
    LOCKEDTOKEN
  }

  struct Leverage{
    uint256 amount;
    uint8   position;
    uint256 remainAmount;
  }

  mapping(address => mapping(address => Leverage)) public leverages;
  uint8 constant MAX_POSITION = 10;
  uint8 constant LEVERAGE_FEE = 10; //10 / 1000 = 1%

  mapping(address => mapping(address => uint256)) public lockedAmount;

  address public treasury;

  event SwapNormal(address tokenOut, uint256 amountOut);
  event SwapLeverage(address tokenOut, uint256 amountOut);
  event SwapLockedToken(address tokenOut, uint256 amountOut);

  constructor(address _token0, address _token1, address _treasury) public {
    token0 = _token0;
    token1 = _token1;

    treasury = _treasury;
  }
  function getBalance(address wallet, address token) public view returns(uint256){
    return IERC20(token).balanceOf(wallet);
  }

  function addLiquidity(uint256 amount0, uint256 amount1) external {
    IERC20(token0).transferFrom(msg.sender, address(this), amount0);
    IERC20(token1).transferFrom(msg.sender, address(this), amount1);

    reserve0 = amount0;
    reserve1 = amount1;
  }

  function getReserve() external view returns (uint256, uint256){
    return (reserve0, reserve1);
  }

  function getTokenAddress() external view returns (address, address){
    return (token0, token1);
  }

  function getLeverageInfo(address wallet, address token) view public returns (uint256, uint8, uint256){
    Leverage memory leverage = leverages[wallet][token];
    return (leverage.amount, leverage.position, leverage.remainAmount);
  }

  function simulateSwap(address token, uint256 amountIn) view public returns (uint256){
    require(token == token0 || token == token1, "invalid token address");
    require(amountIn > 0 , "Invalid token amount");

    if(token == token0){
      require(reserve0 >= amountIn, "Invalid token amount");
      return reserve1.sub(reserve0.mul(reserve1).div(reserve0.add(amountIn)));
    }
    else {
      require(reserve1 >= amountIn, "Invalid token amount");
      return reserve0.sub(reserve0.mul(reserve1).div(reserve1.add(amountIn)));
    }
  }

  function _swap(address token, uint256 amountIn, uint256 amountOut, SwapType _type) internal {
    address _token_out;
    address _token_in = token;
    if(_token_in == token0){
      require(amountOut < reserve1, "Insufficient balance");

      reserve0 = reserve0.add(amountIn);
      reserve1 = reserve1.sub(amountOut);

      _token_out = token1;
    }
    else{
      require(amountOut < reserve0, "Insufficient balance");

      reserve0 = reserve0.sub(amountOut);
      reserve1 = reserve1.add(amountIn);

      _token_out = token0;
    }

    if(_type == SwapType.NORMAL){
      IERC20(_token_out).transfer(msg.sender, amountOut);
      emit SwapNormal(_token_out, amountOut);
    } else {
      Leverage storage outTokenLeverage = leverages[msg.sender][_token_out];

      if(outTokenLeverage.position > 0){
        outTokenLeverage.remainAmount = outTokenLeverage.remainAmount.add(amountOut);
        emit SwapLeverage(_token_out, amountOut);
      }
      else{
        lockedAmount[msg.sender][_token_out] += amountOut;
        emit SwapLockedToken(_token_out, amountOut);
      }
    }
  }

  function swap(address token, uint256 amountIn) external {
    uint256 _amountIn = amountIn; //gas saving
    address _token = token;    
    require(_amountIn > 0, "Amount should greater than 0");

    IERC20(_token).transferFrom(msg.sender, address(this), _amountIn);
    uint256 amountOut = simulateSwap(_token, _amountIn);
    _swap(_token, _amountIn, amountOut, SwapType.NORMAL);
  }

  function swapLeverage(address token, uint256 amountIn) external {
    uint256 _amountIn = amountIn; //gas saving
    address _token = token;
    require(amountIn > 0, "Amount should greater than 0");

    Leverage storage leverage = leverages[msg.sender][_token];
    require(leverage.remainAmount >= _amountIn, "Invalid amount or position");
    leverage.remainAmount = leverage.remainAmount.sub(_amountIn);
    uint256 amountOut = simulateSwap(_token, _amountIn);
    _swap(_token, _amountIn, amountOut, SwapType.LEVERAGE);
  }

  function swapLockedToken(address token, uint256 amountIn) external {
    uint256 _amountIn = amountIn; //gas saving
    address _token = token;
    require(_amountIn > 0, "Amount should greater than 0");
    require(lockedAmount[msg.sender][_token] >= _amountIn, "Insufficient locked balance");

    uint256 amountOut = simulateSwap(_token, _amountIn);
    lockedAmount[msg.sender][_token] = lockedAmount[msg.sender][_token].sub(_amountIn);
    _swap(_token, _amountIn, amountOut, SwapType.LOCKEDTOKEN);
  }

  function getMsgSender() public view returns(address){
    return msg.sender;
  }

  function getLockedAmount(address wallet, address token) public view returns(uint256){
    return lockedAmount[wallet][token];
  }

  function deposit(address token, uint256 amount) external returns (uint256){
    address _token = token; //gas saving
    require(_token == token0 || token == token1, "invalid token address");

    uint256 _amount = amount; //gas saving;
    require(_amount > 0 , "Invalid token amount");

    IERC20(_token).transferFrom(msg.sender, address(this), _amount);

    Leverage storage leverage = leverages[msg.sender][_token];
    leverage.amount = leverage.amount.add(_amount);
    leverage.remainAmount = leverage.remainAmount.add(_amount.mul(leverage.position));
    return amount;
  }

  function openPosition(address token, uint8 position) public {
    address _token = token; //gas saving
    require(_token == token0 || token == token1, "invalid token address");

    Leverage storage leverage = leverages[msg.sender][_token];
    uint8 _position = position; //gas saving
    
    require(_position > 0, "Position should be greater than 0");
    require(leverage.position + _position <= MAX_POSITION, "Exceed position");

    leverage.remainAmount = leverage.remainAmount.add(leverage.amount.mul(position));
    if(leverage.position == 0 && lockedAmount[msg.sender][_token] > 0){
      leverage.amount = leverage.amount.add(lockedAmount[msg.sender][_token]);
      lockedAmount[msg.sender][_token] = 0;
    }
    leverage.position += _position;
  }

  function getRemaingValue(address token) view public returns (uint256){
    address _token = token; //gas saving
    require(_token == token0 || token == token1, "invalid token address");
    Leverage storage leverage = leverages[msg.sender][_token];
    if(leverage.amount > 0){
      return (MAX_POSITION - leverage.position) * leverage.amount;
    }
    return 0;
  }

  function self_getRemaingValue(address token) view public returns (uint256){
    address _token = token; //gas saving
    require(_token == token0 || token == token1, "invalid token address");
    Leverage memory leverage = leverages[msg.sender][_token];
    return leverage.remainAmount;
  }
  
  function Withdraw(address token, uint256 amount) external {
    address _token = token; //gas saving
    require(_token == token0 || token == token1, "invalid token address");

    uint256 _amount = amount; //gas saving;
    require(_amount > 0 , "Invalid token amount");

    Leverage storage leverage = leverages[msg.sender][_token];
    uint256 value = _amount.mul(leverage.position-1);
    uint256 fee = value.mul(LEVERAGE_FEE);

    require(leverage.remainAmount >= (value + fee + _amount), "Can't withdraw");
    leverage.remainAmount  = leverage.remainAmount.sub(value);
    IERC20(token).transfer(msg.sender, _amount);
    IERC20(token).transfer(treasury, fee);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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