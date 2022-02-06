/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

pragma solidity ^0.8.0;

interface I3SwapFactory {
  function createTriad(
    address token0,
    address token1,
    address token2
  ) external returns (address triad);

  function getTriads(
    address token0,
    address token1,
    address token2
  ) external returns (address triad);

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;

  function allTriadsLength() external view returns (uint);

  function allTriads(uint) external view returns (address triad);
}

library TransferHelper {
  function _safeTransferFrom(
    address token_,
    address sender,
    address recipient,
    uint value
  ) internal {
    (bool success, bytes memory data) = token_.call(
      abi.encodeWithSelector(
        bytes4(keccak256(bytes('transferFrom(address,address,uint256)'))),
        sender,
        recipient,
        value
      )
    );
    require(success && (data.length == 0 || abi.decode(data, (bool))));
  }

  function _safeTransfer(
    address token_,
    address to_,
    uint value
  ) internal returns (bool) {
    (bool success, bytes memory data) = token_.call(
      abi.encodeWithSelector(bytes4(keccak256(bytes('transfer(address,uint256)'))), to_, value)
    );
    require(success && (data.length == 0 || abi.decode(data, (bool))));
    return true;
  }

  function _safeTransferETH(address to_, uint value) internal {
    (bool success, ) = to_.call{value: value}(new bytes(0));
    require(success, 'eth transfer failed');
  }
}

interface I3SwapRouter1 {
  struct Tokens {
    address tokenA;
    address tokenB;
    address tokenC;
  }

  struct TokenAmounts {
    uint amountA;
    uint amountB;
    uint amountC;
  }

  function factory() external view returns (address);

  function WETH() external view returns (address);

  function addLiquidity(
    Tokens memory tokensForLiquidity,
    TokenAmounts memory amountsDesired,
    TokenAmounts memory amountsMin,
    address to,
    uint deadline
  )
    external
    returns (
      uint amountA,
      uint amountB,
      uint amountC,
      uint liquidity
    );

  function addLiquidityETH(
    Tokens memory tokensForLiquidity,
    TokenAmounts memory amountsDesired,
    TokenAmounts memory amountsMin,
    address to,
    uint deadline
  )
    external
    payable
    returns (
      uint amountToken1,
      uint amountToken2,
      uint amountETH,
      uint liquidity
    );

  function removeLiquidity(
    Tokens memory tokensForLiquidity,
    uint liquidity,
    TokenAmounts memory amountsMin,
    address to,
    uint deadline
  )
    external
    returns (
      uint amountA,
      uint amountB,
      uint amountC
    );

  function removeLiquidityETH(
    Tokens memory tokensForLiquidity,
    uint liquidity,
    TokenAmounts memory amountsMin,
    address to,
    uint deadline
  )
    external
    returns (
      uint amountToken1,
      uint amountToken2,
      uint amountETH
    );

  function swapExactTokensForTokens(
    uint amount0In,
    uint amount1In,
    uint amount2OutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function swapExactETHForTokens(
    uint amount1In,
    uint amount2OutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable returns (uint[] memory amounts);

  function swapExactTokensForETH(
    uint amount0In,
    uint amount1In,
    uint amount2OutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function quote(
    uint amountA,
    uint amountB,
    uint reserveA,
    uint reserveB,
    uint reserveC
  ) external pure returns (uint amountC);

  function getAmountOut(
    uint amountAIn,
    uint amountBIn,
    uint reserveAIn,
    uint reserveBIn,
    uint reserveOut
  ) external pure returns (uint amountOut);

  function getAmountIn(
    uint amountOut,
    uint reserveAIn,
    uint reserveBIn,
    uint reserveOut
  ) external pure returns (uint amountAIn, uint amountBIn);
}

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

interface I3SwapTriad {
  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function token2() external view returns (address);

  function mint(address to) external returns (uint liquidity);

  function swap(
    uint amountOout,
    uint amount1Out,
    uint amount2Out,
    address to
  ) external;

  function burn(address to)
    external
    returns (
      uint amount0,
      uint amount1,
      uint amount2
    );

  function initialize(
    address t0,
    address t1,
    address t2
  ) external;

  function MINIMUM_LIQUIDITY() external pure returns (uint);

  function getReserves()
    external
    view
    returns (
      uint112 _reserve0,
      uint112 _reserve1,
      uint112 _reserve2,
      uint32 _blockTimestampLast
    );
}

library L3SwapLibrary {
  using SafeMath for uint;

  function sortTokens(
    address tokenA,
    address tokenB,
    address tokenC
  )
    internal
    pure
    returns (
      address token0,
      address token1,
      address token2
    )
  {
    require(tokenA != tokenB && tokenB != tokenC && tokenA != tokenC, 'identical addresses');
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    (token1, token2) = token1 < tokenC ? (token1, tokenC) : (tokenC, token1);
    require(token0 != address(0), 'zero address');
  }

  function triadFor(
    address factory,
    address tokenA,
    address tokenB,
    address tokenC
  ) internal pure returns (address triad) {
    (address token0, address token1, address token2) = sortTokens(tokenA, tokenB, tokenC);
    triad = address(
      uint160(
        uint(
          keccak256(
            abi.encodePacked(
              hex'ff',
              factory,
              keccak256(abi.encodePacked(token0, token1, token2)),
              hex'2612d4eb9dab6652d72a6ec7022aef62794c5601c0fff785c015336a39ee9bde'
            )
          )
        )
      )
    );
  }

  function getReserves(
    address factory,
    address tokenA,
    address tokenB,
    address tokenC
  )
    internal
    view
    returns (
      uint reserveA,
      uint reserveB,
      uint reserveC
    )
  {
    (reserveA, reserveB, reserveC, ) = I3SwapTriad(triadFor(factory, tokenA, tokenB, tokenC)).getReserves();
  }

  function quote(
    uint amountA,
    uint amountB,
    uint reserveA,
    uint reserveB,
    uint reserveC
  ) internal pure returns (uint _amountC) {
    require(amountA > 0 && amountB > 0, 'insufficient amount');
    require(reserveA > 0 && reserveB > 0 && reserveC > 0, 'insufficient liquidity');
    _amountC = (amountA + amountB).mul(reserveC) / (reserveA + reserveB);
  }

  function getAmountOut(
    uint amountAIn,
    uint amountBIn,
    uint reserveAIn,
    uint reserveBIn,
    uint reserveOut
  ) internal pure returns (uint amountOut) {
    require(amountAIn > 0 && amountBIn > 0, 'insufficient input amount');
    require(reserveAIn > 0 && reserveBIn > 0 && reserveOut > 0, 'insufficient liquidity');
    uint amountInWithFee = (amountAIn + amountBIn).mul(997);
    uint numerator = amountInWithFee.mul(reserveOut);
    uint denominator = (reserveAIn + reserveBIn).mul(1000).add(amountInWithFee);
    amountOut = numerator / denominator;
  }

  function getAmountIn(
    uint amountOut,
    uint reserveAIn,
    uint reserveBIn,
    uint reserveOut
  ) internal pure returns (uint amountAIn, uint amountBIn) {
    require(amountOut > 0, 'insufficient output amount');
    require(reserveAIn > 0 && reserveBIn > 0 && reserveOut > 0, 'insufficient liquidity');
    uint numerator = (reserveAIn + reserveBIn).mul(amountOut).mul(1000);
    uint denominator = reserveOut.sub(amountOut).mul(997);
    uint val = (numerator / denominator).add(1);
    amountAIn = val.sub(reserveBIn);
    amountBIn = val.sub(reserveAIn);
  }

  function getAmountsOut(
    address factory,
    uint amountAIn,
    uint amountBIn,
    address[] calldata path
  ) internal view returns (uint[] memory amounts) {
    require(path.length >= 3, 'invalid path');
    amounts = new uint[](path.length);
    amounts[0] = amountAIn;
    amounts[1] = amountBIn;
    for (uint i; i < path.length - 2; i++) {
      (uint reserveAIn, uint reserveBIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1], path[i + 2]);
      amounts[i + 2] = getAmountOut(amounts[i], amounts[i + 1], reserveAIn, reserveBIn, reserveOut);
    }
  }

  function getAmountsIn(
    address factory,
    uint amountOut,
    address[] calldata path
  ) internal view returns (uint[] memory amounts) {
    require(path.length >= 3, 'invalid path');
    amounts = new uint[](path.length);
    amounts[amounts.length - 1] = amountOut;
    for (uint i = path.length - 2; i > 0; i--) {
      (uint reserveAIn, uint reserveBIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i], path[i + 1]);
      (amounts[i - 1], amounts[i]) = getAmountIn(amounts[i + 1], reserveAIn, reserveBIn, reserveOut);
    }
  }
}

interface IWETH {
  function deposit() external payable;

  function withdraw(uint) external;
}

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
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

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
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
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

contract C3SwapRouter1 is I3SwapRouter1 {
  address public factory;
  address public WETH;

  modifier ensure(uint deadline) {
    require(deadline >= block.timestamp, 'expired');
    _;
  }

  constructor(address _factory, address _WETH) {
    factory = _factory;
    WETH = _WETH;
  }

  receive() external payable {
    assert(msg.sender == WETH);
  }

  function _addLiquidity(
    Tokens memory tokensForLiquidity,
    TokenAmounts memory amountsDesired,
    TokenAmounts memory amountsMin
  )
    private
    returns (
      uint amountA,
      uint amountB,
      uint amountC
    )
  {
    if (
      I3SwapFactory(factory).getTriads(
        tokensForLiquidity.tokenA,
        tokensForLiquidity.tokenB,
        tokensForLiquidity.tokenC
      ) == address(0)
    )
      I3SwapFactory(factory).createTriad(
        tokensForLiquidity.tokenA,
        tokensForLiquidity.tokenB,
        tokensForLiquidity.tokenC
      );

    (uint reserveA, uint reserveB, uint reserveC) = L3SwapLibrary.getReserves(
      factory,
      tokensForLiquidity.tokenA,
      tokensForLiquidity.tokenB,
      tokensForLiquidity.tokenC
    );

    if (reserveA == 0 && reserveB == 0 && reserveC == 0)
      (amountA, amountB, amountC) = (amountsDesired.amountA, amountsDesired.amountB, amountsDesired.amountC);
    else {
      uint amountCOptimal = L3SwapLibrary.quote(amountA, amountB, reserveA, reserveB, reserveC);
      uint amountBOptimal = L3SwapLibrary.quote(amountA, amountC, reserveA, reserveB, reserveC);
      if (amountCOptimal <= amountsDesired.amountC) {
        require(amountCOptimal >= amountsMin.amountC, 'insufficient_C_amount');
        (amountA, amountB, amountC) = (amountsDesired.amountA, amountsDesired.amountB, amountCOptimal);
      } else if (amountBOptimal <= amountsDesired.amountB) {
        require(amountBOptimal >= amountsMin.amountB, 'insufficient_B_amount');
        (amountA, amountB, amountC) = (amountsDesired.amountA, amountBOptimal, amountsDesired.amountC);
      } else {
        uint amountAOptimal = L3SwapLibrary.quote(amountB, amountC, reserveA, reserveB, reserveC);
        assert(amountAOptimal <= amountsDesired.amountA);
        require(amountAOptimal >= amountsMin.amountA, 'insufficient_A_amount');
        (amountA, amountB, amountC) = (amountAOptimal, amountsDesired.amountB, amountsDesired.amountC);
      }
    }
  }

  function addLiquidity(
    Tokens memory tokensForLiquidity,
    TokenAmounts memory amountsDesired,
    TokenAmounts memory amountsMin,
    address to,
    uint deadline
  )
    external
    override
    ensure(deadline)
    returns (
      uint amountA,
      uint amountB,
      uint amountC,
      uint liquidity
    )
  {
    (amountA, amountB, amountC) = _addLiquidity(tokensForLiquidity, amountsDesired, amountsMin);
    address triad = L3SwapLibrary.triadFor(
      factory,
      tokensForLiquidity.tokenA,
      tokensForLiquidity.tokenB,
      tokensForLiquidity.tokenC
    );
    TransferHelper._safeTransferFrom(tokensForLiquidity.tokenA, msg.sender, triad, amountA);
    TransferHelper._safeTransferFrom(tokensForLiquidity.tokenB, msg.sender, triad, amountB);
    TransferHelper._safeTransferFrom(tokensForLiquidity.tokenC, msg.sender, triad, amountC);
    liquidity = I3SwapTriad(triad).mint(to);
  }

  function addLiquidityETH(
    Tokens memory tokensLiquidity,
    TokenAmounts memory amountsDesired,
    TokenAmounts memory amountsMin,
    address to,
    uint deadline
  )
    external
    payable
    override
    ensure(deadline)
    returns (
      uint amountTokenA,
      uint amountTokenB,
      uint amountETH,
      uint liquidity
    )
  {
    Tokens memory _tokensLiquidity = tokensLiquidity;
    _tokensLiquidity.tokenC = WETH;
    TokenAmounts memory _tokenAmountsDesired = amountsDesired;
    _tokenAmountsDesired.amountC = msg.value;
    (amountTokenA, amountTokenB, amountETH) = _addLiquidity(_tokensLiquidity, _tokenAmountsDesired, amountsMin);
    address triad = L3SwapLibrary.triadFor(
      factory,
      _tokensLiquidity.tokenA,
      _tokensLiquidity.tokenB,
      _tokensLiquidity.tokenC
    );
    TransferHelper._safeTransferFrom(_tokensLiquidity.tokenA, msg.sender, triad, amountsDesired.amountA);
    TransferHelper._safeTransferFrom(_tokensLiquidity.tokenB, msg.sender, triad, amountsDesired.amountB);
    IWETH(WETH).deposit{value: amountETH}();
    assert(IERC20(WETH).transfer(triad, amountETH));
    liquidity = I3SwapTriad(triad).mint(to);
    if (msg.value > amountETH) {
      TransferHelper._safeTransferETH(msg.sender, msg.value - amountETH);
    }
  }

  function _initRemoveLiquidityAmountsBurn(
    Tokens memory tokensLiquidity,
    uint liquidity,
    address to,
    address sender
  )
    private
    returns (
      uint amount0,
      uint amount1,
      uint amount2
    )
  {
    address triad = L3SwapLibrary.triadFor(
      factory,
      tokensLiquidity.tokenA,
      tokensLiquidity.tokenB,
      tokensLiquidity.tokenC
    );
    IERC20(triad).transferFrom(sender, triad, liquidity);
    (amount0, amount1, amount2) = I3SwapTriad(triad).burn(to);
  }

  function _initRemoveLiquidityTokensSort(
    Tokens memory tokensLiquidity,
    uint amount0,
    uint amount1,
    uint amount2
  )
    private
    pure
    returns (
      uint amountA,
      uint amountB,
      uint amountC
    )
  {
    (address token0, address token1, address token2) = L3SwapLibrary.sortTokens(
      tokensLiquidity.tokenA,
      tokensLiquidity.tokenB,
      tokensLiquidity.tokenC
    );
    if (token0 < token1) {
      (amountA, amountB, amountC) = (amount0, amount1, amount2);
    } else if (token1 < token0) {
      (amountA, amountB, amountC) = (amount1, amount0, amount2);
    }

    if (token1 < token2) {
      (amountA, amountB, amountC) = (amountA, amountB, amountC);
    } else if (token2 < token1) {
      (amountA, amountB, amountC) = (amountA, amountC, amountB);
    }
  }

  function removeLiquidity(
    Tokens memory tokensLiquidity,
    uint liquidity,
    TokenAmounts memory amountsMin,
    address to,
    uint deadline
  )
    public
    override
    ensure(deadline)
    returns (
      uint amountA,
      uint amountB,
      uint amountC
    )
  {
    (uint amount0, uint amount1, uint amount2) = _initRemoveLiquidityAmountsBurn(
      tokensLiquidity,
      liquidity,
      to,
      msg.sender
    );
    (amountA, amountB, amountC) = _initRemoveLiquidityTokensSort(tokensLiquidity, amount0, amount1, amount2);
    require(amountA >= amountsMin.amountA, 'insufficient_A_amount');
    require(amountB >= amountsMin.amountB, 'insufficient_B_amount');
    require(amountC >= amountsMin.amountC, 'insufficient_C_amount');
  }

  function removeLiquidityETH(
    Tokens memory tokensLiquidity,
    uint liquidity,
    TokenAmounts memory amountsMin,
    address to,
    uint deadline
  )
    external
    override
    ensure(deadline)
    returns (
      uint amountToken1,
      uint amountToken2,
      uint amountETH
    )
  {
    Tokens memory _tokensLiquidity = tokensLiquidity;
    _tokensLiquidity.tokenC = WETH;
    (amountToken1, amountToken2, amountETH) = removeLiquidity(
      _tokensLiquidity,
      liquidity,
      amountsMin,
      address(this),
      deadline
    );
    TransferHelper._safeTransfer(_tokensLiquidity.tokenA, to, amountToken1);
    TransferHelper._safeTransfer(_tokensLiquidity.tokenB, to, amountToken2);
    IWETH(WETH).withdraw(amountETH);
    TransferHelper._safeTransferETH(to, amountETH);
  }

  function _initSwapSort(address[] memory path, uint index)
    private
    pure
    returns (
      address token0,
      address token1,
      address token2,
      address out
    )
  {
    (address input1, address input2, address output) = (path[index], path[index + 1], path[index + 2]);
    (token0, token1, token2) = L3SwapLibrary.sortTokens(input1, input2, output);
    out = output;
  }

  function _swap(
    uint[] memory amounts,
    address[] memory path,
    address _to
  ) private {
    for (uint i; i < path.length - 2; i++) {
      (address token0, address token1, address token2, address output) = _initSwapSort(path, i);
      uint amountOut = amounts[i + 2];
      (uint amount0Out, uint amount1Out, uint amount2Out) = token0 == output
        ? (amountOut, uint(0), uint(0))
        : token1 == output
        ? (uint(0), amountOut, uint(0))
        : (uint(0), uint(0), amountOut);
      address to = i < path.length - 3 ? L3SwapLibrary.triadFor(factory, output, path[i + 1], path[i + 2]) : _to;
      I3SwapTriad(L3SwapLibrary.triadFor(factory, token0, token1, token2)).swap(amount0Out, amount1Out, amount2Out, to);
    }
  }

  function swapExactTokensForTokens(
    uint amount0In,
    uint amount1In,
    uint amount2OutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external override ensure(deadline) returns (uint[] memory amounts) {
    amounts = L3SwapLibrary.getAmountsOut(factory, amount0In, amount1In, path);
    require(amounts[amounts.length - 1] >= amount2OutMin, 'insufficient_output_amount');
    TransferHelper._safeTransferFrom(
      path[0],
      msg.sender,
      L3SwapLibrary.triadFor(factory, path[0], path[1], path[2]),
      amounts[0]
    );
    TransferHelper._safeTransferFrom(
      path[1],
      msg.sender,
      L3SwapLibrary.triadFor(factory, path[0], path[1], path[2]),
      amounts[1]
    );
    _swap(amounts, path, to);
  }

  function swapExactETHForTokens(
    uint amount1In,
    uint amount2OutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable override ensure(deadline) returns (uint[] memory amounts) {
    require(path[0] == WETH, 'invalid_path_at_0');
    amounts = L3SwapLibrary.getAmountsOut(factory, msg.value, amount1In, path);
    require(amounts[amounts.length - 1] >= amount2OutMin, 'insufficient_output_amount');
    IWETH(WETH).deposit{value: amounts[0]}();
    assert(IERC20(WETH).transfer(L3SwapLibrary.triadFor(factory, path[0], path[1], path[2]), amounts[0]));
    TransferHelper._safeTransferFrom(
      path[1],
      msg.sender,
      L3SwapLibrary.triadFor(factory, path[0], path[1], path[2]),
      amounts[1]
    );
    _swap(amounts, path, to);
  }

  function swapExactTokensForETH(
    uint amount0In,
    uint amount1In,
    uint amount2OutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external override ensure(deadline) returns (uint[] memory amounts) {
    require(path[path.length - 1] == WETH, 'invalid_path');
    amounts = L3SwapLibrary.getAmountsOut(factory, amount0In, amount1In, path);
    require(amounts[amounts.length - 1] >= amount2OutMin, 'insufficient_output_amount');
    TransferHelper._safeTransferFrom(
      path[0],
      msg.sender,
      L3SwapLibrary.triadFor(factory, path[0], path[1], path[2]),
      amounts[0]
    );
    TransferHelper._safeTransferFrom(
      path[1],
      msg.sender,
      L3SwapLibrary.triadFor(factory, path[0], path[1], path[2]),
      amounts[1]
    );
    _swap(amounts, path, address(this));
    IWETH(WETH).withdraw(amounts[amounts.length - 1]);
    TransferHelper._safeTransferETH(to, amounts[amounts.length - 1]);
  }

  function quote(
    uint amountA,
    uint amountB,
    uint reserveA,
    uint reserveB,
    uint reserveC
  ) public pure override returns (uint amountC) {
    return L3SwapLibrary.quote(amountA, amountB, reserveA, reserveB, reserveC);
  }

  function getAmountOut(
    uint amountAIn,
    uint amountBIn,
    uint reserveAIn,
    uint reserveBIn,
    uint reserveOut
  ) public pure override returns (uint amountC) {
    return L3SwapLibrary.getAmountOut(amountAIn, amountBIn, reserveAIn, reserveBIn, reserveOut);
  }

  function getAmountIn(
    uint amountOut,
    uint reserveAIn,
    uint reserveBIn,
    uint reserveOut
  ) public pure override returns (uint amountAIn, uint amountBIn) {
    return L3SwapLibrary.getAmountIn(amountOut, reserveAIn, reserveBIn, reserveOut);
  }

  function getAmountsOut(
    uint amountAIn,
    uint amountBIn,
    address[] calldata path
  ) public view returns (uint[] memory amounts) {
    return L3SwapLibrary.getAmountsOut(factory, amountAIn, amountBIn, path);
  }

  function getAmountsIn(uint amountOut, address[] calldata path) public view returns (uint[] memory amounts) {
    return L3SwapLibrary.getAmountsIn(factory, amountOut, path);
  }

  function viewTriad(
    address tokenA,
    address tokenB,
    address tokenC
  ) external view returns (address) {
    return L3SwapLibrary.triadFor(factory, tokenA, tokenB, tokenC);
  }
}