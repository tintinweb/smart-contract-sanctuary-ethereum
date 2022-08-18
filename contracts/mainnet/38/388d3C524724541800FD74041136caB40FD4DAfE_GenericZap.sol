pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

import "./ZapBase.sol";
import "./libs/Swap.sol";
import "./interfaces/IBalancerVault.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/ICurvePool.sol";
import "./interfaces/ICurveFactory.sol";


contract GenericZap is ZapBase {

  IUniswapV2Router public immutable uniswapV2Router;
  ICurveFactory private immutable curveFactory = ICurveFactory(0xB9fC157394Af804a3578134A6585C0dc9cc990d4);
  IBalancerVault private immutable balancerVault = IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

  struct ZapLiquidityRequest {
    uint248 firstSwapMinAmountOut;
    bool useAltFunction;
    uint248 poolSwapMinAmountOut;
    bool isOneSidedLiquidityAddition;
    address otherToken;
    bool shouldTransferResidual;
    uint256 minLiquidityOut;
    uint256 uniAmountAMin;
    uint256 uniAmountBMin;
    bytes poolSwapData;
  }

  event ZappedIn(address indexed sender, address fromToken, uint256 fromAmount, address toToken, uint256 amountOut);
  event ZappedLPUniV2(address indexed recipient, address token0, address token1, uint256 amountA, uint256 amountB);
  event TokenRecovered(address token, address to, uint256 amount);
  event ZappedLPCurve(address indexed recipient, address fromToken, uint256 liquidity, uint256[] amounts);
  event ZappedLiquidityBalancerPool(address indexed recipient, address fromToken, uint256 fromAmount, uint256[] maxAmountsIn);

  constructor (
    address _router
  ) {
    uniswapV2Router = IUniswapV2Router(_router);
  }

  /**
   * @notice recover token or ETH
   * @param _token token to recover
   * @param _to receiver of recovered token
   * @param _amount amount to recover
   */
  function recoverToken(address _token, address _to, uint256 _amount) external onlyOwner {
    require(_to != address(0), "Invalid receiver");
    if (_token == address(0)) {
      // this is effectively how OpenZeppelin transfers eth
      require(address(this).balance >= _amount, "Address: insufficient balance");
      (bool success,) = _to.call{value: _amount}(""); 
      require(success, "Address: unable to send value");
    } else {
      _transferToken(IERC20(_token), _to, _amount);
    }
    
    emit TokenRecovered(_token, _to, _amount);
  }

  /**
   * @notice This function zaps ETH or an ERC20 token to another ERC20 token
   * @param _fromToken The token used for entry (address(0) if ether)
   * @param _fromAmount The amount of fromToken to zap
   * @param _toToken Exit token
   * @param _amountOutMin The minimum acceptable quantity of exit ERC20 token to receive
   * @param _swapTarget Execution target for the swap
   * @param _swapData DEX data
   * @return amountOut Amount of exit tokens received
   */
  function zapIn(
    address _fromToken,
    uint256 _fromAmount,
    address _toToken,
    uint256 _amountOutMin,
    address _swapTarget,
    bytes memory _swapData
  ) external payable returns (uint256) {
    return zapInFor(_fromToken, _fromAmount, _toToken, _amountOutMin, msg.sender, _swapTarget, _swapData);
  }

  /**
   * @notice This function zaps ETH or an ERC20 token into a balancer liquidity pool (one-sided or two-sided)
   * @param _fromToken The token used for entry (address(0) if ether)
   * @param _fromAmount The amount of fromToken to zap
   * @param _poolId Target balancer pool id
   * @param _swapTarget Execution target for the zap swap
   * @param _swapData DEX data
   * @param _zapLiqRequest Params for liquidity pool exchange
   * @param _request Params for liquidity addition in balancer pool
   */
  function zapLiquidityBalancerPool(
    address _fromToken,
    uint256 _fromAmount,
    bytes32 _poolId,
    address _swapTarget,
    bytes memory _swapData,
    ZapLiquidityRequest memory _zapLiqRequest,
    IBalancerVault.JoinPoolRequest memory _request
  ) external payable {
    zapLiquidityBalancerPoolFor(_fromToken, _fromAmount, _poolId, msg.sender, _swapTarget, _swapData, _zapLiqRequest, _request);
  }

  /**
   * @notice This function zaps ETH or an ERC20 token into a curve liquidity pool (one-sided or two-sided)
   * @param _fromToken The token used for entry (address(0) if ether)
   * @param _fromAmount The amount of fromToken to zap
   * @param _pool Target curve pool
   * @param _swapTarget Execution target for the zap swap
   * @param _swapData DEX data
   * @param _zapLiqRequest Params for liquidity pool exchange
   */
  function zapLiquidityCurvePool(
    address _fromToken,
    uint256 _fromAmount,
    address _pool,
    address _swapTarget,
    bytes memory _swapData,
    ZapLiquidityRequest memory _zapLiqRequest
  ) external payable {
    zapLiquidityCurvePoolFor(_fromToken, _fromAmount, _pool, msg.sender, _swapTarget, _swapData, _zapLiqRequest);
  }

  /**
   * @notice This function zaps ETH or an ERC20 token into adding liquidity into a uniswap v2 liquidity pool
   * @param _fromToken The token used for entry (address(0) if ether)
   * @param _fromAmount The amount of fromToken to zap
   * @param _pair Target uniswap v2 pair
   * @param _swapTarget Execution target for the zap swap
   * @param _swapData DEX data
   * @param _zapLiqRequest Params for liquidity pool exchange
   */
  function zapLiquidityUniV2(
    address _fromToken,
    uint256 _fromAmount,
    address _pair,
    address _swapTarget,
    bytes memory _swapData,
    ZapLiquidityRequest memory _zapLiqRequest
  ) external payable {
    zapLiquidityUniV2For(_fromToken, _fromAmount, _pair, msg.sender, _swapTarget, _swapData, _zapLiqRequest);
  }

  /**
   * @dev Helper function to calculate swap in amount of a token before adding liquidit to uniswap v2 pair
   * @param _token Token to swap in
   * @param _pair Uniswap V2 Pair token
   * @param _amount Amount of token
   * @return uint256 Amount to swap
   */
  function getAmountToSwap(
    address _token,
    address _pair,
    uint256 _amount
  ) external view returns (uint256) {
    return Swap.getAmountToSwap(_token, _pair, _amount);
  }

  /**
   * @dev Helper function to calculate swap in amount of a token before adding liquidit to uniswap v2 pair.
   * Alternative version
   * @param _reserveIn Pair reserve of incoming token
   * @param _userIn Amount of token
   */
  function getSwapInAmount(
    uint256 _reserveIn,
    uint256 _userIn
  ) external pure returns (uint256) {
    return Swap.calculateSwapInAmount(_reserveIn, _userIn);
  }

  /**
   * @notice This function zaps ETH or an ERC20 token to another ERC20 token
   * @param fromToken The token used for entry (address(0) if ether)
   * @param fromAmount The amount of fromToken to zap
   * @param toToken Exit token
   * @param amountOutMin The minimum acceptable quantity of exit ERC20 token to receive
   * @param recipient Recipient of exit tokens
   * @param swapTarget Execution target for the swap
   * @param swapData DEX data
   * @return amountOut Amount of exit tokens received
   */
  function zapInFor(
    address fromToken,
    uint256 fromAmount,
    address toToken,
    uint256 amountOutMin,
    address recipient,
    address swapTarget,
    bytes memory swapData
  ) public payable whenNotPaused returns (uint256 amountOut) {
    require(approvedTargets[fromToken][swapTarget] == true, "GenericZaps: Unsupported token/target");

    _pullTokens(fromToken, fromAmount);

    amountOut = Swap.fillQuote(
      fromToken,
      fromAmount,
      toToken,
      swapTarget,
      swapData
    );
    require(amountOut >= amountOutMin, "GenericZaps: Not enough tokens out");
    
    emit ZappedIn(msg.sender, fromToken, fromAmount, toToken, amountOut);

    // transfer token to recipient
    SafeERC20.safeTransfer(
      IERC20(toToken),
      recipient,
      amountOut
    );
  }

  /**
   * @notice This function zaps ETH or an ERC20 token into a balancer liquidity pool (one-sided or two-sided)
   * @param _fromToken The token used for entry (address(0) if ether)
   * @param _fromAmount The amount of fromToken to zap
   * @param _poolId Target balancer pool id
   * @param _recipient Recipient of LP tokens
   * @param _swapTarget Execution target for the zap swap
   * @param _swapData DEX data
   * @param _zapLiqRequest Params for liquidity pool exchange
   * @param _request Params for liquidity addition in balancer pool
   */
  function zapLiquidityBalancerPoolFor(
    address _fromToken,
    uint256 _fromAmount,
    bytes32 _poolId,
    address _recipient,
    address _swapTarget,
    bytes memory _swapData,
    ZapLiquidityRequest memory _zapLiqRequest,
    IBalancerVault.JoinPoolRequest memory _request
  ) public payable whenNotPaused {
    require(approvedTargets[_fromToken][_swapTarget] == true, "GenericZaps: Unsupported token/target");

    _pullTokens(_fromToken, _fromAmount);

    uint256 tokenBoughtIndex;
    uint256 amountBought;
    (address[] memory poolTokens,,) = balancerVault.getPoolTokens(_poolId);
    bool fromTokenIsPoolAsset = false;
    uint i = 0;
    for (; i<poolTokens.length;) {
      if (_fromToken == poolTokens[i]) {
        fromTokenIsPoolAsset = true;
        tokenBoughtIndex = i;
        break;
      }
      unchecked { i++; }
    }
    // fill order and execute swap
    if (!fromTokenIsPoolAsset) {
      (tokenBoughtIndex, amountBought) = _fillQuotePool(
        _fromToken,
        _fromAmount,
        poolTokens,
        _swapTarget,
        _swapData
      );
      require(amountBought >= _zapLiqRequest.firstSwapMinAmountOut, "Insufficient tokens out");
    }

    // swap token into 2 parts. use data from func call args, if not one-sided liquidity addition
    if (!_zapLiqRequest.isOneSidedLiquidityAddition) {
      uint256 toSwap;
      unchecked {
        toSwap = amountBought / 2;
        amountBought -= toSwap;
      }
      // use vault as target
      SafeERC20.safeIncreaseAllowance(IERC20(poolTokens[tokenBoughtIndex]), address(balancerVault), toSwap);
      Executable.execute(address(balancerVault), 0, _zapLiqRequest.poolSwapData);
      // ensure min amounts out swapped for other token
      require(_zapLiqRequest.poolSwapMinAmountOut <= IERC20(_zapLiqRequest.otherToken).balanceOf(address(this)),
        "Insufficient swap output for other token");
    }

    // approve tokens iteratively, ensuring contract has right balance each time
    for (i=0; i<poolTokens.length;) {
      if (_request.maxAmountsIn[i] > 0) {
        require(IERC20(poolTokens[i]).balanceOf(address(this)) >= _request.maxAmountsIn[i], 
          "Insufficient asset tokens");
        SafeERC20.safeIncreaseAllowance(IERC20(poolTokens[i]), address(balancerVault), _request.maxAmountsIn[i]);
      }
      unchecked { i++; }
    }
    // address(this) cos zaps sending the tokens
    balancerVault.joinPool(_poolId, address(this), _recipient, _request);

    emit ZappedLiquidityBalancerPool(_recipient, _fromToken, _fromAmount, _request.maxAmountsIn);
  }

  /**
   * @notice This function zaps ETH or an ERC20 token into a curve liquidity pool (one-sided or two-sided)
   * @param _fromToken The token used for entry (address(0) if ether)
   * @param _fromAmount The amount of fromToken to zap
   * @param _pool Target curve pool
   * @param _recipient Recipient of LP tokens
   * @param _swapTarget Execution target for the zap swap
   * @param _swapData DEX data
   * @param _zapLiqRequest Params for liquidity pool exchange
   */
  function zapLiquidityCurvePoolFor(
    address _fromToken,
    uint256 _fromAmount,
    address _pool,
    address _recipient,
    address _swapTarget,
    bytes memory _swapData,
    ZapLiquidityRequest memory _zapLiqRequest
  ) public payable whenNotPaused {

    require(approvedTargets[_fromToken][_swapTarget] == true, "GenericZaps: Unsupported token/target");

    // pull tokens
    _pullTokens(_fromToken, _fromAmount);
    uint256 nCoins;
    if (_zapLiqRequest.useAltFunction) {
      (nCoins,) = curveFactory.get_meta_n_coins(_pool);
    } else {
      nCoins = curveFactory.get_n_coins(_pool);
    }
    address[] memory coins = new address[](nCoins);
    uint256 fromTokenIndex = nCoins; // set wrong index as initial
    uint256 otherTokenIndex = nCoins;
    uint256 i;
    for (i=0; i<nCoins;) {
      coins[i] = ICurvePool(_pool).coins(i);
      if (_fromToken == coins[i]) {
        fromTokenIndex = i;
      } else if (coins[i] == _zapLiqRequest.otherToken) {
        otherTokenIndex = i;
      }
      unchecked { ++i; }
    }
    require(fromTokenIndex != otherTokenIndex && otherTokenIndex != nCoins, "Invalid token indices");
    // fromtoken not a pool coin
    if (fromTokenIndex == nCoins) {
      // reuse fromTokenIndex as coin bought index and fromAmount as amount bought
      (fromTokenIndex, _fromAmount) = 
        _fillQuotePool(
          _fromToken, 
          _fromAmount,
          coins,
          _swapTarget,
          _swapData
        );
        require(_fromAmount >= _zapLiqRequest.firstSwapMinAmountOut, "FillQuote: Insufficient tokens out");
    }
    // to populate coin amounts for liquidity addition
    uint256[] memory coinAmounts = new uint256[](nCoins);
    // if one-sided liquidity addition
    if (_zapLiqRequest.isOneSidedLiquidityAddition) {
      coinAmounts[fromTokenIndex] = _fromAmount;
      require(approvedTargets[coins[fromTokenIndex]][_pool] == true, "Pool not approved");
      SafeERC20.safeIncreaseAllowance(IERC20(coins[fromTokenIndex]), _pool, _fromAmount);
    } else {
      // swap coins
      // add coins in equal parts. assumes two coins
      uint256 amountToSwap;
      unchecked {
        amountToSwap = _fromAmount / 2;
        _fromAmount -= amountToSwap;
      }
      require(approvedTargets[coins[fromTokenIndex]][_pool] == true, "Pool not approved");
      SafeERC20.safeIncreaseAllowance(IERC20(coins[fromTokenIndex]), _pool, amountToSwap);
      uint256 otherTokenBalanceBefore = IERC20(coins[otherTokenIndex]).balanceOf(address(this));
      bytes memory result = Executable.execute(_pool, 0, _zapLiqRequest.poolSwapData);
      // reuse amountToSwap variable for amountReceived
      amountToSwap = abi.decode(result, (uint256));
      require(_zapLiqRequest.poolSwapMinAmountOut <= amountToSwap, 
        "Insufficient swap output for other token");
      require(IERC20(coins[otherTokenIndex]).balanceOf(address(this)) - otherTokenBalanceBefore <= amountToSwap, 
        "Insufficient tokens");
      
      // reinit variable to avoid stack too deep
      uint256 fromAmount = _fromAmount;
      address pool = _pool;
      SafeERC20.safeIncreaseAllowance(IERC20(coins[fromTokenIndex]), pool, fromAmount);
      SafeERC20.safeIncreaseAllowance(IERC20(coins[otherTokenIndex]), pool, amountToSwap);

      coinAmounts[fromTokenIndex] = fromAmount;
      coinAmounts[otherTokenIndex] = amountToSwap;
    }

    uint256 liquidity = _addLiquidityCurvePool(
      _pool,
      _recipient,
      _zapLiqRequest.minLiquidityOut,
      _zapLiqRequest.useAltFunction,
      coinAmounts
    );
    
    emit ZappedLPCurve(_recipient, _fromToken, liquidity, coinAmounts);
  }

  /**
   * @notice This function zaps ETH or an ERC20 token into adding liquidity into a uniswap v2 liquidity pool
   * @param _fromToken The token used for entry (address(0) if ether)
   * @param _fromAmount The amount of fromToken to zap
   * @param _pair Target uniswap v2 pair
   * @param _for Recipient of LP tokens
   * @param _swapTarget Execution target for the zap swap
   * @param _swapData DEX data
   * @param _zapLiqRequest Params for liquidity pool exchange
   */
  function zapLiquidityUniV2For(
    address _fromToken,
    uint256 _fromAmount,
    address _pair,
    address _for,
    address _swapTarget,
    bytes memory _swapData,
    ZapLiquidityRequest memory _zapLiqRequest
  ) public payable whenNotPaused {
    require(approvedTargets[_fromToken][_swapTarget] == true, "GenericZaps: Unsupported token/target");

    // pull tokens
    _pullTokens(_fromToken, _fromAmount);

    address intermediateToken;
    uint256 intermediateAmount;
    (address token0, address token1) = Swap.getPairTokens(_pair);

    if (_fromToken != token0 && _fromToken != token1) {
      // swap to intermediate
      intermediateToken = _zapLiqRequest.otherToken == token0 ? token1 : token0;
      intermediateAmount = Swap.fillQuote(
        _fromToken,
        _fromAmount,
        intermediateToken,
        _swapTarget,
        _swapData
      );
      require(intermediateAmount >= _zapLiqRequest.firstSwapMinAmountOut, "Not enough tokens out");
    } else {
      intermediateToken = _fromToken;
      intermediateAmount = _fromAmount;
    }
    
    (uint256 amountA, uint256 amountB) = _swapTokens(_pair, intermediateToken, intermediateAmount, _zapLiqRequest.poolSwapMinAmountOut);

    SafeERC20.safeIncreaseAllowance(IERC20(token1), address(uniswapV2Router), amountB);
    SafeERC20.safeIncreaseAllowance(IERC20(token0), address(uniswapV2Router), amountA);

    _addLiquidityUniV2(_pair, _for, amountA, amountB, _zapLiqRequest.uniAmountAMin, _zapLiqRequest.uniAmountBMin, _zapLiqRequest.shouldTransferResidual);
  }

  /**
   * @dev Get minimum amounts fo token0 and token1 to tolerate when adding liquidity to uniswap v2 pair
   * @param amountADesired Input desired amount of token0
   * @param amountBDesired Input desired amount of token1
   * @param pair Target uniswap v2 pair
   * @return amountA Minimum amount of token0 to use when adding liquidity
   * @return amountB Minimum amount of token1 to use when adding liquidity
   */
  function addLiquidityGetMinAmounts(
    uint amountADesired,
    uint amountBDesired,
    IUniswapV2Pair pair
  ) public view returns (uint amountA, uint amountB) {
    (uint reserveA, uint reserveB,) = pair.getReserves();
    if (reserveA == 0 && reserveB == 0) {
      (amountA, amountB) = (amountADesired, amountBDesired);
    } else {
      uint amountBOptimal = Swap.quote(amountADesired, reserveA, reserveB);
      if (amountBOptimal <= amountBDesired) {
          //require(amountBOptimal >= amountBMin, 'TempleStableAMMRouter: INSUFFICIENT_STABLE');
          (amountA, amountB) = (amountADesired, amountBOptimal);
      } else {
          uint amountAOptimal = Swap.quote(amountBDesired, reserveB, reserveA);
          assert(amountAOptimal <= amountADesired);
          //require(amountAOptimal >= amountAMin, 'TempleStableAMMRouter: INSUFFICIENT_TEMPLE');
          (amountA, amountB) = (amountAOptimal, amountBDesired);
      }
    }
  }

  function _addLiquidityCurvePool(
    address _pool,
    address _recipient,
    uint256 _minLiquidityOut,
    bool _useAltFunction,
    uint256[] memory _amounts
  ) internal returns (uint256 liquidity) {
    bool success;
    bytes memory data;
    if (_useAltFunction) {
      //liquidity = ICurvePool(_pool).add_liquidity(_amounts, _minLiquidityOut, false, _recipient);
      data = abi.encodeWithSelector(0x0b4c7e4d, _amounts, _minLiquidityOut, false, _recipient);
      // reuse data
      (success, data) = _pool.call{value:0}(data);
    } else {
      //liquidity = ICurvePool(_pool).add_liquidity(_amounts, _minLiquidityOut, _recipient);
      data = abi.encodeWithSelector(0xad6d8c4a, _amounts, _minLiquidityOut, _recipient);
      // reuse data
      (success, data) = _pool.call{value:0}(data);
    }
    require(success, "Failed adding liquidity");
    liquidity = abi.decode(data, (uint256));
  }

  function _addLiquidityUniV2(
    address _pair,
    address _recipient,
    uint256 _amountA,
    uint256 _amountB,
    uint256 _amountAMin,
    uint256 _amountBMin,
    bool _shouldTransferResidual
  ) internal {
    address tokenA = IUniswapV2Pair(_pair).token0();
    address tokenB = IUniswapV2Pair(_pair).token1();
    // avoid stack too deep
    {
      // reuse vars. _amountAMin and _amountBMin below are actually amountA and amountB added to liquidity after external call
      (_amountAMin, _amountBMin,) = uniswapV2Router.addLiquidity(
        tokenA,
        tokenB,
        _amountA,
        _amountB,
        _amountAMin,
        _amountBMin,
        _recipient,
        DEADLINE
      );

      emit ZappedLPUniV2(_recipient, tokenA, tokenB, _amountAMin, _amountBMin);

      // transfer residual
      if (_shouldTransferResidual) {
        _transferResidual(_recipient, tokenA, tokenB, _amountA, _amountB, _amountAMin, _amountBMin);
      }
    }    
  }

  function _transferResidual(
    address _recipient,
    address _tokenA,
    address _tokenB,
    uint256 _amountA,
    uint256 _amountB,
    uint256 _amountAActual,
    uint256 _amountBActual
  ) internal {
    if (_amountA > _amountAActual) {
      _transferToken(IERC20(_tokenA), _recipient, _amountA - _amountAActual);
    }

    if (_amountB > _amountBActual) {
      _transferToken(IERC20(_tokenB), _recipient, _amountB - _amountBActual);
    }
  }

  function _swapTokens(
    address _pair,
    address _fromToken,
    uint256 _fromAmount,
    uint256 _amountOutMin
  ) internal returns (uint256 amountA, uint256 amountB) {
    IUniswapV2Pair pair = IUniswapV2Pair(_pair);
    address token0 = pair.token0();
    address token1 = pair.token1();

    (uint256 res0, uint256 res1,) = pair.getReserves();
    if (_fromToken == token0) {
      uint256 amountToSwap = Swap.calculateSwapInAmount(res0, _fromAmount);
      //if no reserve or a new pair is created
      if (amountToSwap == 0) amountToSwap = _fromAmount / 2;

      amountB = _swapErc20ToErc20(
        _fromToken,
        token1,
        amountToSwap,
        _amountOutMin
      );
      amountA = _fromAmount - amountToSwap;
    } else {
      uint256 amountToSwap = Swap.calculateSwapInAmount(res1, _fromAmount);
      //if no reserve or a new pair is created
      if (amountToSwap == 0) amountToSwap = _fromAmount / 2;

      amountA = _swapErc20ToErc20(
        _fromToken,
        token0,
        amountToSwap,
        _amountOutMin
      );
      amountB = _fromAmount - amountToSwap;
    }
  }

  function _fillQuotePool(
    address _fromToken, 
    uint256 _fromAmount,
    address[] memory _coins,
    address _swapTarget,
    bytes memory _swapData
  ) internal returns (uint256, uint256){
    uint256 valueToSend;
    if (_fromToken == address(0)) {
      require(
          _fromAmount > 0 && msg.value == _fromAmount,
          "Invalid _amount: Input ETH mismatch"
      );
      valueToSend = _fromAmount;
    } else {
      SafeERC20.safeIncreaseAllowance(IERC20(_fromToken), _swapTarget, _fromAmount);
    }
    uint256 nCoins = _coins.length;
    uint256[] memory balancesBefore = new uint256[](nCoins);
    uint256 i = 0;
    for (; i<nCoins;) {
      balancesBefore[i] = IERC20(_coins[i]).balanceOf(address(this));
      unchecked { i++; }
    }

    Executable.execute(_swapTarget, valueToSend, _swapData);

    uint256 tokenBoughtIndex = nCoins;
    uint256 bal;
    // reuse vars
    for (i=0; i<nCoins;) {
      bal = IERC20(_coins[i]).balanceOf(address(this));
      if (bal > balancesBefore[i]) {
        tokenBoughtIndex = i;
        break;
      }
      unchecked { i++; }
    }
    require(tokenBoughtIndex != nCoins, "Invalid swap");

    return (tokenBoughtIndex, bal - balancesBefore[tokenBoughtIndex]);
  }

  /**
    @notice This function is used to swap ERC20 <> ERC20
    @param _fromToken The token address to swap from.
    @param _toToken The token address to swap to. 
    @param _amountIn The amount of tokens to swap
    @param _amountOutMin Minimum amount of tokens out
    @return tokenBought The amount of tokens bought
    */
  function _swapErc20ToErc20(
    address _fromToken,
    address _toToken,
    uint256 _amountIn,
    uint256 _amountOutMin
  ) internal returns (uint256 tokenBought) {
    if (_fromToken == _toToken) {
        return _amountIn;
    }

    SafeERC20.safeIncreaseAllowance(IERC20(_fromToken), address(uniswapV2Router), _amountIn);

    IUniswapV2Factory uniV2Factory = IUniswapV2Factory(
      uniswapV2Router.factory()
    );
    address pair = uniV2Factory.getPair(
      _fromToken,
      _toToken
    );
    require(pair != address(0), "No Swap Available");
    address[] memory path = new address[](2);
    path[0] = _fromToken;
    path[1] = _toToken;

    tokenBought = uniswapV2Router
      .swapExactTokensForTokens(
          _amountIn,
          _amountOutMin,
          path,
          address(this),
          DEADLINE
      )[path.length - 1];

    require(tokenBought >= _amountOutMin, "Error Swapping Tokens 2");
  }
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IWeth.sol";

abstract contract ZapBase is Ownable {
  using SafeERC20 for IERC20;

  bool public paused;
  address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  uint256 internal constant DEADLINE = 0xf000000000000000000000000000000000000000000000000000000000000000;

  // fromToken => swapTarget (per curve, univ2 and balancer) approval status
  mapping(address => mapping(address => bool)) public approvedTargets;

  event SetContractState(bool paused);

  receive() external payable {
    require(msg.sender != tx.origin, "ZapBase: Do not send ETH directly");
  }

  /**
    @notice Adds or removes an approved swapTarget
    * swapTargets should be Zaps and must not be tokens!
    @param _tokens An array of tokens
    @param _targets An array of addresses of approved swapTargets
    @param _isApproved An array of booleans if target is approved or not
    */
  function setApprovedTargets(
    address[] calldata _tokens,
    address[] calldata _targets,
    bool[] calldata _isApproved
  ) external onlyOwner {
    uint256 _length = _isApproved.length;
    require(_targets.length == _length && _tokens.length == _length, "ZapBase: Invalid Input length");

    for (uint256 i = 0; i < _length; i++) {
      approvedTargets[_tokens[i]][_targets[i]] = _isApproved[i];
    }
  }

  /**
    @notice Toggles the contract's active state
     */
  function toggleContractActive() external onlyOwner {
    paused = !paused;

    emit SetContractState(paused);
  }

  function _transferToken(IERC20 _token, address _to, uint256 _amount) internal {
    uint256 balance = _token.balanceOf(address(this));
    require(_amount <= balance, "ZapBase: not enough tokens");
    SafeERC20.safeTransfer(_token, _to, _amount);
  }

  /**
   * @notice Transfers tokens from msg.sender to this contract
   * @notice If native token, use msg.value
   * @notice For use with Zap Ins
   * @param token The ERC20 token to transfer to this contract (0 address if ETH)
   * @return Quantity of tokens transferred to this contract
     */
  function _pullTokens(
    address token,
    uint256 amount
  ) internal returns (uint256) {
    if (token == address(0)) {
      require(msg.value > 0, "ZapBase: No ETH sent");
      return msg.value;
    }

    require(amount > 0, "ZapBase: Invalid token amount");
    require(msg.value == 0, "ZapBase: ETH sent with token");

    SafeERC20.safeTransferFrom(
      IERC20(token),
      msg.sender,
      address(this),
      amount
    );

    return amount;
  }

  function _depositEth(
    uint256 _amount
  ) internal {
    require(
      _amount > 0 && msg.value == _amount,
      "ZapBase: Input ETH mismatch"
    );
    IWETH(WETH).deposit{value: _amount}();
  }

  // circuit breaker modifiers
  modifier whenNotPaused() {
    require(!paused, "ZapBase: Paused");
    _;
  }
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IWeth.sol";
import "./Executable.sol";
import "./EthConstants.sol";


/// @notice An inlined library for liquidity pool related helper functions.
library Swap {
  
  // @dev calling function should ensure targets are approved 
  function fillQuote(
    address _fromToken,
    uint256 _fromAmount,
    address _toToken,
    address _swapTarget,
    bytes memory _swapData
  ) internal returns (uint256) {
    if (_swapTarget == EthConstants.WETH) {
      require(_fromToken == EthConstants.WETH, "Swap: Invalid from token and WETH target");
      require(
        _fromAmount > 0 && msg.value == _fromAmount,
        "Swap: Input ETH mismatch"
      );
      IWETH(EthConstants.WETH).deposit{value: _fromAmount}();
      return _fromAmount;
    }

    uint256 amountBought;
    uint256 valueToSend;
    if (_fromToken == address(0)) {
      require(
        _fromAmount > 0 && msg.value == _fromAmount,
        "Swap: Input ETH mismatch"
      );
      valueToSend = _fromAmount;
    } else {
      SafeERC20.safeIncreaseAllowance(IERC20(_fromToken), _swapTarget, _fromAmount);
    }

    // to calculate amount received
    uint256 initialBalance = IERC20(_toToken).balanceOf(address(this));

    // we don't need the returndata here
    Executable.execute(_swapTarget, valueToSend, _swapData);
    unchecked {
      amountBought = IERC20(_toToken).balanceOf(address(this)) - initialBalance;
    }

    return amountBought;
  }

  function getAmountToSwap(
    address _token,
    address _pair,
    uint256 _amount
  ) internal view returns (uint256) {
    address token0 = IUniswapV2Pair(_pair).token0();
    (uint112 reserveA, uint112 reserveB,) = IUniswapV2Pair(_pair).getReserves();
    uint256 reserveIn = token0 == _token ? reserveA : reserveB;
    uint256 amountToSwap = calculateSwapInAmount(reserveIn, _amount);
    return amountToSwap;
  }

  function calculateSwapInAmount(
    uint256 reserveIn,
    uint256 userIn
  ) internal pure returns (uint256) {
    return
        (sqrt(
            reserveIn * ((userIn * 3988000) + (reserveIn * 3988009))
        ) - (reserveIn * 1997)) / 1994;
  }

  // borrowed from Uniswap V2 Core Math library https://github.com/Uniswap/v2-core/blob/master/contracts/libraries/Math.sol
  // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
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

  /** 
    * given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    *
    * Direct copy of UniswapV2Library.quote(amountA, reserveA, reserveB) - can't use as directly as it's built off a different version of solidity
    */
  function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
    require(reserveA > 0 && reserveB > 0, "Swap: Insufficient liquidity");
    amountB = (amountA * reserveB) / reserveA;
  }

  function getPairTokens(
    address _pairAddress
  ) internal view returns (address token0, address token1) {
    IUniswapV2Pair pair = IUniswapV2Pair(_pairAddress);
    token0 = pair.token0();
    token1 = pair.token1();
  }

}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBalancerVault {
  struct JoinPoolRequest {
    IERC20[] assets;
    uint256[] maxAmountsIn;
    bytes userData;
    bool fromInternalBalance;
  }

  struct SingleSwap {
    bytes32 poolId;
    SwapKind kind;
    IERC20 assetIn;
    IERC20 assetOut;
    uint256 amount;
    bytes userData;
  }

  struct BatchSwapStep {
    bytes32 poolId;
    uint256 assetInIndex;
    uint256 assetOutIndex;
    uint256 amount;
    bytes userData;
  }

  struct FundManagement {
    address sender;
    bool fromInternalBalance;
    address payable recipient;
    bool toInternalBalance;
  }

  enum SwapKind { GIVEN_IN, GIVEN_OUT }

  function swap(
      SingleSwap memory singleSwap,
      FundManagement memory funds,
      uint256 limit,
      uint256 deadline
  ) external payable returns (uint256 amountCalculated);

  function joinPool(
      bytes32 poolId,
      address sender,
      address recipient,
      JoinPoolRequest memory request
  ) external payable;

  function getPoolTokens(
    bytes32 poolId
  ) external view
    returns (
      address[] memory tokens,
      uint256[] memory balances,
      uint256 lastChangeBlock
  );

  function queryBatchSwap(
    SwapKind kind,
    BatchSwapStep[] memory swaps,
    IERC20[] memory assets,
    FundManagement memory funds
  ) external view returns (int256[] memory);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

interface IUniswapV2Router {
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

  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function factory() external view returns (address);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

interface ICurvePool {
    function coins(uint256 j) external view returns (address);
    function calc_token_amount(uint256[] calldata _amounts, bool _is_deposit) external view returns (uint256);
    function add_liquidity(uint256[] calldata _amounts, uint256 _min_mint_amount, address destination) external returns (uint256);
    function add_liquidity(uint256[] calldata _amounts, uint256 _min_mint_amount, bool use_ether, address destination) external returns (uint256);
    function get_dy(uint256 _from, uint256 _to, uint256 _from_amount) external view returns (uint256);
    function remove_liquidity(uint256 _amount, uint256[2] calldata _min_amounts) external returns (uint256[2] memory);
    function fee() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external returns (uint256);
    function remove_liquidity_imbalance(uint256[2] memory amounts, uint256 _max_burn_amount, address _receiver) external returns (uint256);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

interface ICurveFactory {
  function get_n_coins(address pool) external view returns (uint256);
  function get_meta_n_coins(address pool) external view returns (uint256, uint256);
}

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

interface IWETH {
  function deposit() external payable;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

interface IUniswapV2Pair {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function getReserves() external view returns (uint112, uint112, uint32);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

/// @notice An inlined library function to add a generic execute() function to contracts.
/// @dev As this is a powerful function, care and consideration needs to be taken when 
///      adding into contracts, and on who can call.
library Executable {

    /// @notice Call a function on another contract, where the msg.sender will be this contract
    /// @param _to The address of the contract to call
    /// @param _value Any eth to send
    /// @param _data The encoded function selector and args.
    /// @dev If the underlying function reverts, this willl revert where the underlying revert message will bubble up.
    function execute(
        address _to,
        uint256 _value,
        bytes memory _data
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = _to.call{value: _value}(_data);
        
        if (success) {
            return returndata;
        } else if (returndata.length > 0) {
            // Look for revert reason and bubble it up if present
            // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol#L232
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert("Execute: Unknown failure");
        }
    }
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

library EthConstants {
  address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
}