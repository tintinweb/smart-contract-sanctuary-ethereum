// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../../lib/Math.sol";
import "../../lib/SafeERC20.sol";
import "../../interface/IERC20.sol";
import "../../interface/IWMATIC.sol";
import "../../interface/IPair.sol";
import "../../interface/IFactory.sol";

contract DystRouter01 {
  using SafeERC20 for IERC20;

  struct Route {
    address from;
    address to;
    bool stable;
  }

  address public immutable factory;
  IWMATIC public immutable wmatic;
  uint internal constant MINIMUM_LIQUIDITY = 10 ** 3;
  bytes32 immutable pairCodeHash;

  modifier ensure(uint deadline) {
    require(deadline >= block.timestamp, 'DystRouter: EXPIRED');
    _;
  }

  constructor(address _factory, address _wmatic) {
    factory = _factory;
    pairCodeHash = IFactory(_factory).pairCodeHash();
    wmatic = IWMATIC(_wmatic);
  }

  receive() external payable {
    // only accept ETH via fallback from the WETH contract
    require(msg.sender == address(wmatic), "DystRouter: NOT_WMATIC");
  }

  function sortTokens(address tokenA, address tokenB) external pure returns (address token0, address token1) {
    return _sortTokens(tokenA, tokenB);
  }

  function _sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
    require(tokenA != tokenB, 'DystRouter: IDENTICAL_ADDRESSES');
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), 'DystRouter: ZERO_ADDRESS');
  }

  function pairFor(address tokenA, address tokenB, bool stable) external view returns (address pair) {
    return _pairFor(tokenA, tokenB, stable);
  }

  /// @dev Calculates the CREATE2 address for a pair without making any external calls.
  function _pairFor(address tokenA, address tokenB, bool stable) internal view returns (address pair) {
    (address token0, address token1) = _sortTokens(tokenA, tokenB);
    pair = address(uint160(uint(keccak256(abi.encodePacked(
        hex'ff',
        factory,
        keccak256(abi.encodePacked(token0, token1, stable)),
        pairCodeHash // init code hash
      )))));
  }

  function quoteLiquidity(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB) {
    return _quoteLiquidity(amountA, reserveA, reserveB);
  }

  /// @dev Given some amount of an asset and pair reserves, returns an equivalent amount of the other asset.
  function _quoteLiquidity(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
    require(amountA > 0, 'DystRouter: INSUFFICIENT_AMOUNT');
    require(reserveA > 0 && reserveB > 0, 'DystRouter: INSUFFICIENT_LIQUIDITY');
    amountB = amountA * reserveB / reserveA;
  }

  function getReserves(address tokenA, address tokenB, bool stable) external view returns (uint reserveA, uint reserveB) {
    return _getReserves(tokenA, tokenB, stable);
  }

  /// @dev Fetches and sorts the reserves for a pair.
  function _getReserves(address tokenA, address tokenB, bool stable) internal view returns (uint reserveA, uint reserveB) {
    (address token0,) = _sortTokens(tokenA, tokenB);
    (uint reserve0, uint reserve1,) = IPair(_pairFor(tokenA, tokenB, stable)).getReserves();
    (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
  }

  /// @dev Performs chained getAmountOut calculations on any number of pairs.
  function getAmountOut(uint amountIn, address tokenIn, address tokenOut) external view returns (uint amount, bool stable) {
    address pair = _pairFor(tokenIn, tokenOut, true);
    uint amountStable;
    uint amountVolatile;
    if (IFactory(factory).isPair(pair)) {
      amountStable = IPair(pair).getAmountOut(amountIn, tokenIn);
    }
    pair = _pairFor(tokenIn, tokenOut, false);
    if (IFactory(factory).isPair(pair)) {
      amountVolatile = IPair(pair).getAmountOut(amountIn, tokenIn);
    }
    return amountStable > amountVolatile ? (amountStable, true) : (amountVolatile, false);
  }

  function getExactAmountOut(uint amountIn, address tokenIn, address tokenOut, bool stable) external view returns (uint) {
    address pair = _pairFor(tokenIn, tokenOut, stable);
    if (IFactory(factory).isPair(pair)) {
      return IPair(pair).getAmountOut(amountIn, tokenIn);
    }
    return 0;
  }

  /// @dev Performs chained getAmountOut calculations on any number of pairs.
  function getAmountsOut(uint amountIn, Route[] memory routes) external view returns (uint[] memory amounts) {
    return _getAmountsOut(amountIn, routes);
  }

  function _getAmountsOut(uint amountIn, Route[] memory routes) internal view returns (uint[] memory amounts) {
    require(routes.length >= 1, 'DystRouter: INVALID_PATH');
    amounts = new uint[](routes.length + 1);
    amounts[0] = amountIn;
    for (uint i = 0; i < routes.length; i++) {
      address pair = _pairFor(routes[i].from, routes[i].to, routes[i].stable);
      if (IFactory(factory).isPair(pair)) {
        amounts[i + 1] = IPair(pair).getAmountOut(amounts[i], routes[i].from);
      }
    }
  }

  function isPair(address pair) external view returns (bool) {
    return IFactory(factory).isPair(pair);
  }

  function quoteAddLiquidity(
    address tokenA,
    address tokenB,
    bool stable,
    uint amountADesired,
    uint amountBDesired
  ) external view returns (uint amountA, uint amountB, uint liquidity) {
    // create the pair if it doesn't exist yet
    address _pair = IFactory(factory).getPair(tokenA, tokenB, stable);
    (uint reserveA, uint reserveB) = (0, 0);
    uint _totalSupply = 0;
    if (_pair != address(0)) {
      _totalSupply = IERC20(_pair).totalSupply();
      (reserveA, reserveB) = _getReserves(tokenA, tokenB, stable);
    }
    if (reserveA == 0 && reserveB == 0) {
      (amountA, amountB) = (amountADesired, amountBDesired);
      liquidity = Math.sqrt(amountA * amountB) - MINIMUM_LIQUIDITY;
    } else {

      uint amountBOptimal = _quoteLiquidity(amountADesired, reserveA, reserveB);
      if (amountBOptimal <= amountBDesired) {
        (amountA, amountB) = (amountADesired, amountBOptimal);
        liquidity = Math.min(amountA * _totalSupply / reserveA, amountB * _totalSupply / reserveB);
      } else {
        uint amountAOptimal = _quoteLiquidity(amountBDesired, reserveB, reserveA);
        (amountA, amountB) = (amountAOptimal, amountBDesired);
        liquidity = Math.min(amountA * _totalSupply / reserveA, amountB * _totalSupply / reserveB);
      }
    }
  }

  function quoteRemoveLiquidity(
    address tokenA,
    address tokenB,
    bool stable,
    uint liquidity
  ) external view returns (uint amountA, uint amountB) {
    // create the pair if it doesn't exist yet
    address _pair = IFactory(factory).getPair(tokenA, tokenB, stable);

    if (_pair == address(0)) {
      return (0, 0);
    }

    (uint reserveA, uint reserveB) = _getReserves(tokenA, tokenB, stable);
    uint _totalSupply = IERC20(_pair).totalSupply();
    // using balances ensures pro-rata distribution
    amountA = liquidity * reserveA / _totalSupply;
    // using balances ensures pro-rata distribution
    amountB = liquidity * reserveB / _totalSupply;

  }

  function _addLiquidity(
    address tokenA,
    address tokenB,
    bool stable,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin
  ) internal returns (uint amountA, uint amountB) {
    require(amountADesired >= amountAMin, "DystRouter: DESIRED_A_AMOUNT");
    require(amountBDesired >= amountBMin, "DystRouter: DESIRED_B_AMOUNT");
    // create the pair if it doesn't exist yet
    address _pair = IFactory(factory).getPair(tokenA, tokenB, stable);
    if (_pair == address(0)) {
      _pair = IFactory(factory).createPair(tokenA, tokenB, stable);
    }
    (uint reserveA, uint reserveB) = _getReserves(tokenA, tokenB, stable);
    if (reserveA == 0 && reserveB == 0) {
      (amountA, amountB) = (amountADesired, amountBDesired);
    } else {
      uint amountBOptimal = _quoteLiquidity(amountADesired, reserveA, reserveB);
      if (amountBOptimal <= amountBDesired) {
        require(amountBOptimal >= amountBMin, 'DystRouter: INSUFFICIENT_B_AMOUNT');
        (amountA, amountB) = (amountADesired, amountBOptimal);
      } else {
        uint amountAOptimal = _quoteLiquidity(amountBDesired, reserveB, reserveA);
        assert(amountAOptimal <= amountADesired);
        require(amountAOptimal >= amountAMin, 'DystRouter: INSUFFICIENT_A_AMOUNT');
        (amountA, amountB) = (amountAOptimal, amountBDesired);
      }
    }
  }

  function addLiquidity(
    address tokenA,
    address tokenB,
    bool stable,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
    (amountA, amountB) = _addLiquidity(
      tokenA,
      tokenB,
      stable,
      amountADesired,
      amountBDesired,
      amountAMin,
      amountBMin
    );
    address pair = _pairFor(tokenA, tokenB, stable);
    SafeERC20.safeTransferFrom(IERC20(tokenA), msg.sender, pair, amountA);
    SafeERC20.safeTransferFrom(IERC20(tokenB), msg.sender, pair, amountB);
    liquidity = IPair(pair).mint(to);
  }

  function addLiquidityMATIC(
    address token,
    bool stable,
    uint amountTokenDesired,
    uint amountTokenMin,
    uint amountMATICMin,
    address to,
    uint deadline
  ) external payable ensure(deadline) returns (uint amountToken, uint amountMATIC, uint liquidity) {
    (amountToken, amountMATIC) = _addLiquidity(
      token,
      address(wmatic),
      stable,
      amountTokenDesired,
      msg.value,
      amountTokenMin,
      amountMATICMin
    );
    address pair = _pairFor(token, address(wmatic), stable);
    IERC20(token).safeTransferFrom(msg.sender, pair, amountToken);
    wmatic.deposit{value : amountMATIC}();
    assert(wmatic.transfer(pair, amountMATIC));
    liquidity = IPair(pair).mint(to);
    // refund dust eth, if any
    if (msg.value > amountMATIC) _safeTransferMATIC(msg.sender, msg.value - amountMATIC);
  }

  // **** REMOVE LIQUIDITY ****

  function removeLiquidity(
    address tokenA,
    address tokenB,
    bool stable,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB) {
    return _removeLiquidity(
      tokenA,
      tokenB,
      stable,
      liquidity,
      amountAMin,
      amountBMin,
      to,
      deadline
    );
  }

  function _removeLiquidity(
    address tokenA,
    address tokenB,
    bool stable,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) internal ensure(deadline) returns (uint amountA, uint amountB) {
    address pair = _pairFor(tokenA, tokenB, stable);
    IERC20(pair).safeTransferFrom(msg.sender, pair, liquidity);
    // send liquidity to pair
    (uint amount0, uint amount1) = IPair(pair).burn(to);
    (address token0,) = _sortTokens(tokenA, tokenB);
    (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
    require(amountA >= amountAMin, 'DystRouter: INSUFFICIENT_A_AMOUNT');
    require(amountB >= amountBMin, 'DystRouter: INSUFFICIENT_B_AMOUNT');
  }

  function removeLiquidityMATIC(
    address token,
    bool stable,
    uint liquidity,
    uint amountTokenMin,
    uint amountMATICMin,
    address to,
    uint deadline
  ) external returns (uint amountToken, uint amountMATIC) {
    return _removeLiquidityMATIC(
      token,
      stable,
      liquidity,
      amountTokenMin,
      amountMATICMin,
      to,
      deadline
    );
  }

  function _removeLiquidityMATIC(
    address token,
    bool stable,
    uint liquidity,
    uint amountTokenMin,
    uint amountMATICMin,
    address to,
    uint deadline
  ) internal ensure(deadline) returns (uint amountToken, uint amountMATIC) {
    (amountToken, amountMATIC) = _removeLiquidity(
      token,
      address(wmatic),
      stable,
      liquidity,
      amountTokenMin,
      amountMATICMin,
      address(this),
      deadline
    );
    IERC20(token).safeTransfer(to, amountToken);
    wmatic.withdraw(amountMATIC);
    _safeTransferMATIC(to, amountMATIC);
  }

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    bool stable,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountA, uint amountB) {
    address pair = _pairFor(tokenA, tokenB, stable);
    {
      uint value = approveMax ? type(uint).max : liquidity;
      IPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
    }

    (amountA, amountB) = _removeLiquidity(tokenA, tokenB, stable, liquidity, amountAMin, amountBMin, to, deadline);
  }

  function removeLiquidityMATICWithPermit(
    address token,
    bool stable,
    uint liquidity,
    uint amountTokenMin,
    uint amountMATICMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountToken, uint amountMATIC) {
    address pair = _pairFor(token, address(wmatic), stable);
    uint value = approveMax ? type(uint).max : liquidity;
    IPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
    (amountToken, amountMATIC) = _removeLiquidityMATIC(token, stable, liquidity, amountTokenMin, amountMATICMin, to, deadline);
  }

  function removeLiquidityMATICSupportingFeeOnTransferTokens(
    address token,
    bool stable,
    uint liquidity,
    uint amountTokenMin,
    uint amountFTMMin,
    address to,
    uint deadline
  ) external returns (uint amountToken, uint amountFTM) {
    return _removeLiquidityMATICSupportingFeeOnTransferTokens(
      token,
      stable,
      liquidity,
      amountTokenMin,
      amountFTMMin,
      to,
      deadline
    );
  }

  function _removeLiquidityMATICSupportingFeeOnTransferTokens(
    address token,
    bool stable,
    uint liquidity,
    uint amountTokenMin,
    uint amountFTMMin,
    address to,
    uint deadline
  ) internal ensure(deadline) returns (uint amountToken, uint amountFTM) {
    (amountToken, amountFTM) = _removeLiquidity(
      token,
      address(wmatic),
      stable,
      liquidity,
      amountTokenMin,
      amountFTMMin,
      address(this),
      deadline
    );
    IERC20(token).safeTransfer(to, IERC20(token).balanceOf(address(this)));
    wmatic.withdraw(amountFTM);
    _safeTransferMATIC(to, amountFTM);
  }

  function removeLiquidityMATICWithPermitSupportingFeeOnTransferTokens(
    address token,
    bool stable,
    uint liquidity,
    uint amountTokenMin,
    uint amountFTMMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountToken, uint amountFTM) {
    address pair = _pairFor(token, address(wmatic), stable);
    uint value = approveMax ? type(uint).max : liquidity;
    IPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
    (amountToken, amountFTM) = _removeLiquidityMATICSupportingFeeOnTransferTokens(
      token, stable, liquidity, amountTokenMin, amountFTMMin, to, deadline
    );
  }

  // **** SWAP ****
  // requires the initial amount to have already been sent to the first pair
  function _swap(uint[] memory amounts, Route[] memory routes, address _to) internal virtual {
    for (uint i = 0; i < routes.length; i++) {
      (address token0,) = _sortTokens(routes[i].from, routes[i].to);
      uint amountOut = amounts[i + 1];
      (uint amount0Out, uint amount1Out) = routes[i].from == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
      address to = i < routes.length - 1 ? _pairFor(routes[i + 1].from, routes[i + 1].to, routes[i + 1].stable) : _to;
      IPair(_pairFor(routes[i].from, routes[i].to, routes[i].stable)).swap(
        amount0Out, amount1Out, to, new bytes(0)
      );
    }
  }

  function _swapSupportingFeeOnTransferTokens(Route[] memory routes, address _to) internal virtual {
    for (uint i; i < routes.length; i++) {
      (address input, address output) = (routes[i].from, routes[i].to);
      (address token0,) = _sortTokens(input, output);
      IPair pair = IPair(_pairFor(routes[i].from, routes[i].to, routes[i].stable));
      uint amountInput;
      uint amountOutput;
      {// scope to avoid stack too deep errors
        (uint reserve0, uint reserve1,) = pair.getReserves();
        uint reserveInput = input == token0 ? reserve0 : reserve1;
        amountInput = IERC20(input).balanceOf(address(pair)) - reserveInput;
        //(amountOutput,) = getAmountOut(amountInput, input, output, stable);
        amountOutput = pair.getAmountOut(amountInput, input);
      }
      (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
      address to = i < routes.length - 1 ? _pairFor(routes[i + 1].from, routes[i + 1].to, routes[i + 1].stable) : _to;
      pair.swap(amount0Out, amount1Out, to, new bytes(0));
    }
  }

  function swapExactTokensForTokensSimple(
    uint amountIn,
    uint amountOutMin,
    address tokenFrom,
    address tokenTo,
    bool stable,
    address to,
    uint deadline
  ) external ensure(deadline) returns (uint[] memory amounts) {
    Route[] memory routes = new Route[](1);
    routes[0].from = tokenFrom;
    routes[0].to = tokenTo;
    routes[0].stable = stable;
    amounts = _getAmountsOut(amountIn, routes);
    require(amounts[amounts.length - 1] >= amountOutMin, 'DystRouter: INSUFFICIENT_OUTPUT_AMOUNT');
    IERC20(routes[0].from).safeTransferFrom(
      msg.sender, _pairFor(routes[0].from, routes[0].to, routes[0].stable), amounts[0]
    );
    _swap(amounts, routes, to);
  }

  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    Route[] calldata routes,
    address to,
    uint deadline
  ) external ensure(deadline) returns (uint[] memory amounts) {
    amounts = _getAmountsOut(amountIn, routes);
    require(amounts[amounts.length - 1] >= amountOutMin, 'DystRouter: INSUFFICIENT_OUTPUT_AMOUNT');
    IERC20(routes[0].from).safeTransferFrom(
      msg.sender, _pairFor(routes[0].from, routes[0].to, routes[0].stable), amounts[0]
    );
    _swap(amounts, routes, to);
  }

  function swapExactMATICForTokens(uint amountOutMin, Route[] calldata routes, address to, uint deadline)
  external
  payable
  ensure(deadline)
  returns (uint[] memory amounts)
  {
    require(routes[0].from == address(wmatic), 'DystRouter: INVALID_PATH');
    amounts = _getAmountsOut(msg.value, routes);
    require(amounts[amounts.length - 1] >= amountOutMin, 'DystRouter: INSUFFICIENT_OUTPUT_AMOUNT');
    wmatic.deposit{value : amounts[0]}();
    assert(wmatic.transfer(_pairFor(routes[0].from, routes[0].to, routes[0].stable), amounts[0]));
    _swap(amounts, routes, to);
  }

  function swapExactTokensForMATIC(uint amountIn, uint amountOutMin, Route[] calldata routes, address to, uint deadline)
  external
  ensure(deadline)
  returns (uint[] memory amounts)
  {
    require(routes[routes.length - 1].to == address(wmatic), 'DystRouter: INVALID_PATH');
    amounts = _getAmountsOut(amountIn, routes);
    require(amounts[amounts.length - 1] >= amountOutMin, 'DystRouter: INSUFFICIENT_OUTPUT_AMOUNT');
    IERC20(routes[0].from).safeTransferFrom(
      msg.sender, _pairFor(routes[0].from, routes[0].to, routes[0].stable), amounts[0]
    );
    _swap(amounts, routes, address(this));
    wmatic.withdraw(amounts[amounts.length - 1]);
    _safeTransferMATIC(to, amounts[amounts.length - 1]);
  }

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    Route[] calldata routes,
    address to,
    uint deadline
  ) external ensure(deadline) {
    IERC20(routes[0].from).safeTransferFrom(
      msg.sender,
      _pairFor(routes[0].from, routes[0].to, routes[0].stable),
      amountIn
    );
    uint balanceBefore = IERC20(routes[routes.length - 1].to).balanceOf(to);
    _swapSupportingFeeOnTransferTokens(routes, to);
    require(
      IERC20(routes[routes.length - 1].to).balanceOf(to) - balanceBefore >= amountOutMin,
      'DystRouter: INSUFFICIENT_OUTPUT_AMOUNT'
    );
  }

  function swapExactMATICForTokensSupportingFeeOnTransferTokens(
    uint amountOutMin,
    Route[] calldata routes,
    address to,
    uint deadline
  )
  external
  payable
  ensure(deadline)
  {
    require(routes[0].from == address(wmatic), 'DystRouter: INVALID_PATH');
    uint amountIn = msg.value;
    wmatic.deposit{value : amountIn}();
    assert(wmatic.transfer(_pairFor(routes[0].from, routes[0].to, routes[0].stable), amountIn));
    uint balanceBefore = IERC20(routes[routes.length - 1].to).balanceOf(to);
    _swapSupportingFeeOnTransferTokens(routes, to);
    require(
      IERC20(routes[routes.length - 1].to).balanceOf(to) - balanceBefore >= amountOutMin,
      'DystRouter: INSUFFICIENT_OUTPUT_AMOUNT'
    );
  }

  function swapExactTokensForMATICSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    Route[] calldata routes,
    address to,
    uint deadline
  )
  external
  ensure(deadline)
  {
    require(routes[routes.length - 1].to == address(wmatic), 'DystRouter: INVALID_PATH');
    IERC20(routes[0].from).safeTransferFrom(
      msg.sender, _pairFor(routes[0].from, routes[0].to, routes[0].stable), amountIn
    );
    _swapSupportingFeeOnTransferTokens(routes, address(this));
    uint amountOut = IERC20(address(wmatic)).balanceOf(address(this));
    require(amountOut >= amountOutMin, 'DystRouter: INSUFFICIENT_OUTPUT_AMOUNT');
    wmatic.withdraw(amountOut);
    _safeTransferMATIC(to, amountOut);
  }

  function UNSAFE_swapExactTokensForTokens(
    uint[] memory amounts,
    Route[] calldata routes,
    address to,
    uint deadline
  ) external ensure(deadline) returns (uint[] memory) {
    IERC20(routes[0].from).safeTransferFrom(msg.sender, _pairFor(routes[0].from, routes[0].to, routes[0].stable), amounts[0]);
    _swap(amounts, routes, to);
    return amounts;
  }

  function _safeTransferMATIC(address to, uint value) internal {
    (bool success,) = to.call{value : value}(new bytes(0));
    require(success, 'DystRouter: ETH_TRANSFER_FAILED');
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

library Math {

  function max(uint a, uint b) internal pure returns (uint) {
    return a >= b ? a : b;
  }

  function min(uint a, uint b) internal pure returns (uint) {
    return a < b ? a : b;
  }

  function positiveInt128(int128 value) internal pure returns (int128) {
    return value < 0 ? int128(0) : value;
  }

  function closeTo(uint a, uint b, uint target) internal pure returns (bool) {
    if (a > b) {
      if (a - b <= target) {
        return true;
      }
    } else {
      if (b - a <= target) {
        return true;
      }
    }
    return false;
  }

  function sqrt(uint y) internal pure returns (uint z) {
    if (y > 3) {
      z = y;
      uint x = y / 2 + 1;
      while (x < z) {
        z = x;
        x = (y / x + x) / 2;
      }
    } else if (y != 0) {
      z = 1;
    }
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.13;

import "../interface/IERC20.sol";
import "./Address.sol";

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
    uint value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint value
  ) internal {
    uint newAllowance = token.allowance(address(this), spender) + value;
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IWMATIC {
  function name() external view returns (string memory);

  function approve(address guy, uint256 wad) external returns (bool);

  function totalSupply() external view returns (uint256);

  function transferFrom(
    address src,
    address dst,
    uint256 wad
  ) external returns (bool);

  function withdraw(uint256 wad) external;

  function decimals() external view returns (uint8);

  function balanceOf(address) external view returns (uint256);

  function symbol() external view returns (string memory);

  function transfer(address dst, uint256 wad) external returns (bool);

  function deposit() external payable;

  function allowance(address, address) external view returns (uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IPair {

  // Structure to capture time period obervations every 30 minutes, used for local oracles
  struct Observation {
    uint timestamp;
    uint reserve0Cumulative;
    uint reserve1Cumulative;
  }

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

  function burn(address to) external returns (uint amount0, uint amount1);

  function mint(address to) external returns (uint liquidity);

  function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);

  function getAmountOut(uint, address) external view returns (uint);

  function claimFees() external returns (uint, uint);

  function tokens() external view returns (address, address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function stable() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IFactory {
  function treasury() external view returns (address);

  function isPair(address pair) external view returns (bool);

  function getInitializable() external view returns (address, address, bool);

  function isPaused() external view returns (bool);

  function pairCodeHash() external pure returns (bytes32);

  function getPair(address tokenA, address token, bool stable) external view returns (address);

  function createPair(address tokenA, address tokenB, bool stable) external returns (address pair);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.13;

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

  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), "Address: call to non-contract");
    (bool success, bytes memory returndata) = target.call(data);
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