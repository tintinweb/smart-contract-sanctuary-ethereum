/**
 *Submitted for verification at Etherscan.io on 2022-09-02
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

struct PairData {
    uint256 amountIn;
    address tokenIn;
    uint256 _reserve0;
    uint256 _reserve1;
    address token0;
    uint256 decimals0;
    uint256 decimals1;
    bool stable;
}

struct ReserveData {
    uint256 reserve0;
    uint256 reserve1;
    bool isSet;
}

interface ISwapPair {
  function metadata()
    external
    view
    returns (
      uint256 dec0,
      uint256 dec1,
      uint256 r0,
      uint256 r1,
      bool st,
      address t0,
      address t1
    );

  function isPair(
    address pairAddress
  ) external view returns (bool);
}

interface IRouter {
  function pairFor(
    address tokenA,
    address tokenB,
    bool stable
  ) external view returns (address pair);
}

interface IFactory {
  function isPair(
    address pairAddress
  ) external view returns (bool);
}

contract ReservesMapping {
  mapping(address => ReserveData) public reservesLeft;

  function update(address _pairAddress,uint256 _reserve0, uint256 _reserve1) public {
    reservesLeft[_pairAddress] = ReserveData(_reserve0,_reserve1,true);
  }

  function getReserves(address _pairAddress) public view returns (ReserveData memory) {
    return reservesLeft[_pairAddress];
  }
}

contract RouterUtil {
  struct route {
    address from;
    address to;
    bool stable;
  }

  IRouter public immutable router;

  address public immutable factory;

  constructor(address _router,address _factory) {
    router = IRouter(_router);
    factory = _factory;
  }

  function _f(uint256 x0, uint256 y) internal pure returns (uint256) {
    return (x0 * ((((y * y) / 1e18) * y) / 1e18)) / 1e18 + (((((x0 * x0) / 1e18) * x0) / 1e18) * y) / 1e18;
  }

  function _d(uint256 x0, uint256 y) internal pure returns (uint256) {
    return (3 * x0 * ((y * y) / 1e18)) / 1e18 + ((((x0 * x0) / 1e18) * x0) / 1e18);
  }

  function _get_y(
    uint256 x0,
    uint256 xy,
    uint256 y
  ) internal pure returns (uint256) {
    for (uint256 i = 0; i < 255; i++) {
      uint256 y_prev = y;
      uint256 k = _f(x0, y);
      if (k < xy) {
        uint256 dy = ((xy - k) * 1e18) / _d(x0, y);
        y = y + dy;
      } else {
        uint256 dy = ((k - xy) * 1e18) / _d(x0, y);
        y = y - dy;
      }
      if (y > y_prev) {
        if (y - y_prev <= 1) {
          return y;
        }
      } else {
        if (y_prev - y <= 1) {
          return y;
        }
      }
    }
    return y;
  }

  function getTradeDiff(
    uint256 amountIn,
    address tokenIn,
    address tokenOut,
    bool stable
  ) external view returns (uint256 a, uint256 b) {
    (uint256 dec0, uint256 dec1, uint256 r0, uint256 r1, bool st, address t0, ) = ISwapPair(
      router.pairFor(tokenIn, tokenOut, stable)
    ).metadata();
    uint256 sample = tokenIn == t0 ? (r0 * dec1) / r1 : (r1 * dec0) / r0;
    a = (_getAmountOut(sample, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18) / sample;
    b = (_getAmountOut(amountIn, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18) / amountIn;
  }

  function getTradeDiff(
    uint256 amountIn,
    address tokenIn,
    address pair
  ) external view returns (uint256 a, uint256 b) {
    (uint256 dec0, uint256 dec1, uint256 r0, uint256 r1, bool st, address t0, ) = ISwapPair(pair).metadata();
    uint256 sample = tokenIn == t0 ? (r0 * dec1) / r1 : (r1 * dec0) / r0;
    a = (_getAmountOut(sample, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18) / sample;
    b = (_getAmountOut(amountIn, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18) / amountIn;
  }

  function getSample(
    address tokenIn,
    address tokenOut,
    bool stable
  ) external view returns (uint256) {
    (uint256 dec0, uint256 dec1, uint256 r0, uint256 r1, bool st, address t0, ) = ISwapPair(
      router.pairFor(tokenIn, tokenOut, stable)
    ).metadata();
    uint256 sample = tokenIn == t0 ? (r0 * dec1) / r1 : (r1 * dec0) / r0;
    return (_getAmountOut(sample, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18) / sample;
  }

  function getMinimumValue(
    address tokenIn,
    address tokenOut,
    bool stable
  )
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    (uint256 dec0, uint256 dec1, uint256 r0, uint256 r1, , address t0, ) = ISwapPair(
      router.pairFor(tokenIn, tokenOut, stable)
    ).metadata();
    uint256 sample = tokenIn == t0 ? (r0 * dec1) / r1 : (r1 * dec0) / r0;
    return (sample, r0, r1);
  }

  function getAmountOut(
    uint256 amountIn,
    address tokenIn,
    address tokenOut,
    bool stable
  ) external view returns (uint256) {
    (uint256 dec0, uint256 dec1, uint256 r0, uint256 r1, bool st, address t0, ) = ISwapPair(
      router.pairFor(tokenIn, tokenOut, stable)
    ).metadata();
    return (_getAmountOut(amountIn, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18) / amountIn;
  }

  function getRouteData(route[][] calldata routes, uint256[] calldata amountsIn) external returns (uint256[][] memory) {
    ReservesMapping localReserves = new ReservesMapping();
    uint256[][] memory amounts;
    for (uint256 index = 0; index < routes.length; index++) {
       amounts[index] = getAmountsOutWithReserveChange(amountsIn[index],routes[index],localReserves);
       if(amounts[index].length == 0){
         amounts = new uint256[][](0);
         return amounts;
       }
    }
    return amounts;
  }

  // performs chained getAmountOut calculations on any number of pairs, accounting for reserves changed
  function getAmountsOutWithReserveChange(uint256 amountIn, route[] memory routes,ReservesMapping localReserves)
    internal
    returns (uint256[] memory)
  {
    require(routes.length >= 1, "BaseV1Router: INVALID_PATH");
    uint256[] memory amounts = new uint256[](routes.length + 1);
    amounts[0] = amountIn;
    for (uint256 i = 0; i < routes.length; i++) {
      address pair = router.pairFor(routes[i].from, routes[i].to, routes[i].stable);
      if (IFactory(factory).isPair(pair)) {
        (uint256 dec0, uint256 dec1, uint256 r0, uint256 r1,, address t0, ) = ISwapPair(pair).metadata();
        ReserveData memory res = localReserves.getReserves(pair);
        if(res.isSet){
          r0 = res.reserve0;
          r1 = res.reserve1;
        }
        uint[2] memory newReserves;
        (amounts[i+1],newReserves) = _getAmountOutWithReserveChange(PairData(amounts[i],routes[i].from,r0,r1,t0,dec0,dec1,routes[i].stable));
        if(newReserves[0] < 10**3 || newReserves[1] < 10**3){
          return new uint256[](0);
        }
        localReserves.update(pair, newReserves[0], newReserves[1]);
      }
      else{
        return new uint256[](0);
      }
    }
    return amounts;
  }

  function _getAmountOutWithReserveChange(
    PairData memory pairData
  ) internal pure returns (uint256,uint256[2] memory) {
    uint256 amountOut;
    if (pairData.stable) {
      uint256 xy = _k(pairData._reserve0, pairData._reserve1, pairData.stable, pairData.decimals0, pairData.decimals1);
      (uint256 reserveA, uint256 reserveB) = pairData.tokenIn == pairData.token0
        ? ((pairData._reserve0 * 1e18) / pairData.decimals0, (pairData._reserve1 * 1e18) / pairData.decimals1)
        : ((pairData._reserve1 * 1e18) / pairData.decimals1, (pairData._reserve0 * 1e18) / pairData.decimals0);
      uint256 y = reserveB -
        _get_y(
          (pairData.tokenIn == pairData.token0 ? (pairData.amountIn * 1e18) / pairData.decimals0 : (pairData.amountIn * 1e18) / pairData.decimals1) + reserveA,
          xy,
          reserveB
        );
      amountOut = (y * (pairData.tokenIn == pairData.token0 ? pairData.decimals1 : pairData.decimals0)) / 1e18;
    } else {
      (uint256 reserveA, uint256 reserveB) = pairData.tokenIn == pairData.token0 ? (pairData._reserve0, pairData._reserve1) : (pairData._reserve1, pairData._reserve0);
      amountOut = (pairData.amountIn * reserveB) / (reserveA + pairData.amountIn);
    }
    uint256 reserve0Change = pairData.tokenIn == pairData.token0 ? pairData._reserve0 + pairData.amountIn : pairData._reserve0 - amountOut;
    uint256 reserve1Change = pairData.tokenIn == pairData.token0 ? pairData._reserve1 + pairData.amountIn : pairData._reserve1 - amountOut;
    return (amountOut, [reserve0Change, reserve1Change]);
  }

  function _getAmountOut(
    uint256 amountIn,
    address tokenIn,
    uint256 _reserve0,
    uint256 _reserve1,
    address token0,
    uint256 decimals0,
    uint256 decimals1,
    bool stable
  ) internal pure returns (uint256) {
    if (stable) {
      uint256 xy = _k(_reserve0, _reserve1, stable, decimals0, decimals1);
      _reserve0 = (_reserve0 * 1e18) / decimals0;
      _reserve1 = (_reserve1 * 1e18) / decimals1;
      (uint256 reserveA, uint256 reserveB) = tokenIn == token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
      amountIn = tokenIn == token0 ? (amountIn * 1e18) / decimals0 : (amountIn * 1e18) / decimals1;
      uint256 y = reserveB - _get_y(amountIn + reserveA, xy, reserveB);
      return (y * (tokenIn == token0 ? decimals1 : decimals0)) / 1e18;
    } else {
      (uint256 reserveA, uint256 reserveB) = tokenIn == token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
      return (amountIn * reserveB) / (reserveA + amountIn);
    }
  }

  function _k(
    uint256 x,
    uint256 y,
    bool stable,
    uint256 decimals0,
    uint256 decimals1
  ) internal pure returns (uint256) {
    if (stable) {
      uint256 _x = (x * 1e18) / decimals0;
      uint256 _y = (y * 1e18) / decimals1;
      uint256 _a = (_x * _y) / 1e18;
      uint256 _b = ((_x * _x) / 1e18 + (_y * _y) / 1e18);
      return (_a * _b) / 1e18; // x3y+y3x >= k
    } else {
      return x * y; // xy >= k
    }
  }
}