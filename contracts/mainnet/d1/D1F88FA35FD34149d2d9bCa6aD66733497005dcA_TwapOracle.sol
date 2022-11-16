// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/ITwapOracle.sol";

import "./external/IUniswapV2Pair.sol";
import "./external/UniswapV2OracleLibrary.sol";

/// @title TwapOracle
/// @author Bluejay Core Team
/// @notice TwapOracle provides a Time-Weighted Average Price (TWAP) of a Uniswap V2 pool.
/// This is a fixed window oracle that recomputes the average price for the entire period once every period
/// https://github.com/Uniswap/v2-periphery/blob/master/contracts/examples/ExampleOracleSimple.sol
contract TwapOracle is ITwapOracle {
  /// @notice Minimum period which the oracle will compute the average price
  uint256 public immutable period;

  /// @notice Address of Uniswap V2 pool address which the average price will be computed for
  IUniswapV2Pair public immutable pair;

  /// @notice Cache of token0 on the Uniswap V2 pool
  address public immutable token0;

  /// @notice Cache of token1 on the Uniswap V2 pool
  address public immutable token1;

  /// @notice Last stored cumulative price of token 0
  uint256 public price0CumulativeLast;

  /// @notice Last stored cumulative price of token 1
  uint256 public price1CumulativeLast;

  /// @notice Timestamp where cumulative prices were last fetched
  uint32 public blockTimestampLast;

  /// @notice Average price of token 0, updated on `blockTimestampLast`
  uint224 public price0Average;

  /// @notice Average price of token 1, updated on `blockTimestampLast`
  uint224 public price1Average;

  /// @notice Constructor to initialize the contract
  /// @param poolAddress Address of Uniswap V2 pool address which the average price will be computed for
  /// @param _period Minimum period which the oracle will compute the average price
  constructor(address poolAddress, uint256 _period) {
    period = _period;
    IUniswapV2Pair _pair = IUniswapV2Pair(poolAddress);
    pair = _pair;
    token0 = _pair.token0();
    token1 = _pair.token1();
    price0CumulativeLast = _pair.price0CumulativeLast(); // fetch the current accumulated price value (1 / 0)
    price1CumulativeLast = _pair.price1CumulativeLast(); // fetch the current accumulated price value (0 / 1)
    uint112 reserve0;
    uint112 reserve1;
    (reserve0, reserve1, blockTimestampLast) = _pair.getReserves();
    require(reserve0 != 0 && reserve1 != 0, "No liquidity in pool"); // ensure that there's liquidity in the pair
  }

  // =============================== INTERNAL FUNCTIONS =================================

  /// @notice Decode a UQ112x112 into a uint112 by truncating after the radix point
  /// https://github.com/Uniswap/solidity-lib/blob/master/contracts/libraries/FixedPoint.sol
  function _decode144(uint256 num) internal pure returns (uint144) {
    return uint144(num >> 112);
  }

  // =============================== PUBLIC FUNCTIONS =================================

  /// @notice Update the average price of both tokens over the period elapsed
  /// @dev This function can only be called after the minimum period have passed since the last update
  function update() public override {
    (
      uint256 price0Cumulative,
      uint256 price1Cumulative,
      uint32 blockTimestamp
    ) = UniswapV2OracleLibrary.currentCumulativePrices(address(pair));
    uint32 timeElapsed = blockTimestamp - blockTimestampLast;

    require(timeElapsed >= period, "Period not elapsed");

    unchecked {
      price0Average = uint224(
        (price0Cumulative - price0CumulativeLast) / timeElapsed
      );
      price1Average = uint224(
        (price1Cumulative - price1CumulativeLast) / timeElapsed
      );
    }

    price0CumulativeLast = price0Cumulative;
    price1CumulativeLast = price1Cumulative;
    blockTimestampLast = blockTimestamp;
    emit UpdatedPrice(
      price0Average,
      price1Average,
      price0CumulativeLast,
      price1CumulativeLast
    );
  }

  /// @notice Non-reverting function to update the average prices
  function tryUpdate() public override {
    if (
      UniswapV2OracleLibrary.currentBlockTimestamp() - blockTimestampLast >=
      period
    ) {
      update();
    }
  }

  // =============================== STATIC CALL QUERY FUNCTIONS =================================

  /// @notice Non-reverting function to update the average prices and returning the prices
  /// @dev Use static call on this function to get the latest average price.
  /// Note that this will always return 0 before update has been called successfully for the first time.
  /// @param token Address of input token
  /// @param amountIn Amount of tokens input
  /// @return amountOut Amount of tokens output after the swap using the average price
  function updateAndConsult(address token, uint256 amountIn)
    public
    override
    returns (uint256 amountOut)
  {
    tryUpdate();
    return consult(token, amountIn);
  }

  // =============================== VIEW FUNCTIONS =================================

  /// @notice Get the swap output of the token using the average price
  /// @dev Note that this will always return 0 before update has been called successfully for the first time.
  /// @param token Address of input token
  /// @param amountIn Amount of tokens input
  /// @return amountOut Amount of tokens output after the swap using the average price
  function consult(address token, uint256 amountIn)
    public
    view
    override
    returns (uint256 amountOut)
  {
    if (token == token0) {
      amountOut = _decode144(price0Average * amountIn);
    } else {
      require(token == token1, "Invalid swap");
      amountOut = _decode144(price1Average * amountIn);
    }
    require(amountOut > 0, "Zero output");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITwapOracle {
  function update() external;

  function tryUpdate() external;

  function consult(address token, uint256 amountIn)
    external
    view
    returns (uint256 amountOut);

  function updateAndConsult(address token, uint256 amountIn)
    external
    returns (uint256 amountOut);

  event UpdatedPrice(
    uint256 price0Average,
    uint256 price1Average,
    uint256 price0CumulativeLast,
    uint256 price1CumulativeLast
  );
}

// SPDX-License-Identifier: GPL-3.0-or-later
// https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Pair.sol
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IUniswapV2Pair is IERC20 {
  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint256);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(
    address indexed sender,
    uint256 amount0,
    uint256 amount1,
    address indexed to
  );
  event Swap(
    address indexed sender,
    uint256 amount0In,
    uint256 amount1In,
    uint256 amount0Out,
    uint256 amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint256);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function price0CumulativeLast() external view returns (uint256);

  function price1CumulativeLast() external view returns (uint256);

  function kLast() external view returns (uint256);

  function mint(address to) external returns (uint256 liquidity);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// https://github.com/Uniswap/solidity-lib/blob/master/contracts/libraries/FixedPoint.sol
pragma solidity ^0.8.4;

import "./IUniswapV2Pair.sol";

// References
// https://github.com/fei-protocol/fei-protocol-core/blob/develop/contracts/external/UniswapV2OracleLibrary.sol
// https://github.com/Uniswap/solidity-lib/blob/master/contracts/libraries/FullMath.sol
// https://medium.com/coinmonks/math-in-solidity-part-3-percents-and-proportions-4db014e080b1

library FullMath {
  uint256 constant MAX_256 = type(uint256).max;

  function fullMul(uint256 x, uint256 y)
    internal
    pure
    returns (uint256 l, uint256 h)
  {
    uint256 mm = mulmod(x, y, MAX_256);
    l = x * y;
    h = mm - l;
    if (mm < l) h -= 1;
  }

  function fullDiv(
    uint256 l,
    uint256 h,
    uint256 d
  ) private pure returns (uint256) {
    uint256 pow2 = uint256(int256(d) & -int256(d));
    d /= pow2;
    l /= pow2;
    l += h * (uint256((-int256(pow2)) / int256(pow2 + 1)));
    uint256 r = 1;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    return l * r;
  }

  function mulDiv(
    uint256 x,
    uint256 y,
    uint256 d
  ) internal pure returns (uint256) {
    (uint256 l, uint256 h) = fullMul(x, y);

    uint256 mm = mulmod(x, y, d);
    if (mm > l) h -= 1;
    l -= mm;

    if (h == 0) return l / d;

    require(h < d, "FullMath: FULLDIV_OVERFLOW");
    return fullDiv(l, h, d);
  }
}

library FixedPoint {
  // range: [0, 2**112 - 1]
  // resolution: 1 / 2**112
  struct uq112x112 {
    uint224 _x;
  }

  uint8 public constant RESOLUTION = 112;
  uint256 public constant Q112 = 2**112;
  uint144 constant MAX_144 = type(uint144).max;
  uint224 constant MAX_224 = type(uint224).max;

  // returns a UQ112x112 which represents the ratio of the numerator to the denominator
  // can be lossy
  function fraction(uint256 numerator, uint256 denominator)
    internal
    pure
    returns (uq112x112 memory)
  {
    require(denominator > 0, "FixedPoint::fraction: division by zero");
    if (numerator == 0) return FixedPoint.uq112x112(0);

    if (numerator <= MAX_144) {
      uint256 result = (numerator << RESOLUTION) / denominator;
      require(result <= MAX_224, "FixedPoint::fraction: overflow");
      return uq112x112(uint224(result));
    } else {
      uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
      require(result <= MAX_224, "FixedPoint::fraction: overflow");
      return uq112x112(uint224(result));
    }
  }
}

library UniswapV2OracleLibrary {
  using FixedPoint for *;

  // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
  function currentBlockTimestamp() internal view returns (uint32) {
    return uint32(block.timestamp % 2**32);
  }

  // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
  function currentCumulativePrices(address pair)
    internal
    view
    returns (
      uint256 price0Cumulative,
      uint256 price1Cumulative,
      uint32 blockTimestamp
    )
  {
    blockTimestamp = currentBlockTimestamp();
    price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
    price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

    // if time has elapsed since the last update on the pair, mock the accumulated price values
    (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    ) = IUniswapV2Pair(pair).getReserves();
    if (blockTimestampLast != blockTimestamp) {
      unchecked {
        // subtraction overflow is desired
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;
        // addition overflow is desired
        price0Cumulative +=
          uint256(FixedPoint.fraction(reserve1, reserve0)._x) *
          timeElapsed;
        price1Cumulative +=
          uint256(FixedPoint.fraction(reserve0, reserve1)._x) *
          timeElapsed;
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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