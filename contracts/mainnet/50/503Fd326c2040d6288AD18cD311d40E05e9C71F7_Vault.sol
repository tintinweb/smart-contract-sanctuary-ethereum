/**
 *Submitted for verification at Etherscan.io on 2023-01-17
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.16;
pragma abicoder v2;


// Интерфейсы
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
interface INonfungiblePositionManager{
    
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    function mint(MintParams calldata params) external payable returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    function increaseLiquidity(IncreaseLiquidityParams calldata params) external payable returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    function decreaseLiquidity(DecreaseLiquidityParams calldata params) external payable returns (uint256 amount0, uint256 amount1);
}
interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}
interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}
interface IUniswapV3PoolState {
    function slot0() external view returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );
}


// Либы
library ABDKMathQuad {
  /*
   * 0.
   */
  bytes16 private constant POSITIVE_ZERO = 0x00000000000000000000000000000000;

  /*
   * -0.
   */
  bytes16 private constant NEGATIVE_ZERO = 0x80000000000000000000000000000000;

  /*
   * +Infinity.
   */
  bytes16 private constant POSITIVE_INFINITY = 0x7FFF0000000000000000000000000000;

  /*
   * -Infinity.
   */
  bytes16 private constant NEGATIVE_INFINITY = 0xFFFF0000000000000000000000000000;

  /*
   * Canonical NaN value.
   */
  bytes16 private constant NaN = 0x7FFF8000000000000000000000000000;

  /**
   * Convert signed 256-bit integer number into quadruple precision number.
   *
   * @param x signed 256-bit integer number
   * @return quadruple precision number
   */
  function fromInt (int256 x) internal pure returns (bytes16) {
    unchecked {
      if (x == 0) return bytes16 (0);
      else {
        // We rely on overflow behavior here
        uint256 result = uint256 (x > 0 ? x : -x);

        uint256 msb = mostSignificantBit (result);
        if (msb < 112) result <<= 112 - msb;
        else if (msb > 112) result >>= msb - 112;

        result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16383 + msb << 112;
        if (x < 0) result |= 0x80000000000000000000000000000000;

        return bytes16 (uint128 (result));
      }
    }
  }

  /**
   * Convert quadruple precision number into signed 256-bit integer number
   * rounding towards zero.  Revert on overflow.
   *
   * @param x quadruple precision number
   * @return signed 256-bit integer number
   */
  function toInt (bytes16 x) internal pure returns (int256) {
    unchecked {
      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

      require (exponent <= 16638); // Overflow
      if (exponent < 16383) return 0; // Underflow

      uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
        0x10000000000000000000000000000;

      if (exponent < 16495) result >>= 16495 - exponent;
      else if (exponent > 16495) result <<= exponent - 16495;

      if (uint128 (x) >= 0x80000000000000000000000000000000) { // Negative
        require (result <= 0x8000000000000000000000000000000000000000000000000000000000000000);
        return -int256 (result); // We rely on overflow behavior here
      } else {
        require (result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int256 (result);
      }
    }
  }

  /**
   * Convert unsigned 256-bit integer number into quadruple precision number.
   *
   * @param x unsigned 256-bit integer number
   * @return quadruple precision number
   */
  function fromUInt (uint256 x) internal pure returns (bytes16) {
    unchecked {
      if (x == 0) return bytes16 (0);
      else {
        uint256 result = x;

        uint256 msb = mostSignificantBit (result);
        if (msb < 112) result <<= 112 - msb;
        else if (msb > 112) result >>= msb - 112;

        result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16383 + msb << 112;

        return bytes16 (uint128 (result));
      }
    }
  }

  /**
   * Convert quadruple precision number into unsigned 256-bit integer number
   * rounding towards zero.  Revert on underflow.  Note, that negative floating
   * point numbers in range (-1.0 .. 0.0) may be converted to unsigned integer
   * without error, because they are rounded to zero.
   *
   * @param x quadruple precision number
   * @return unsigned 256-bit integer number
   */
  function toUInt (bytes16 x) internal pure returns (uint256) {
    unchecked {
      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

      if (exponent < 16383) return 0; // Underflow

      require (uint128 (x) < 0x80000000000000000000000000000000); // Negative

      require (exponent <= 16638); // Overflow
      uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
        0x10000000000000000000000000000;

      if (exponent < 16495) result >>= 16495 - exponent;
      else if (exponent > 16495) result <<= exponent - 16495;

      return result;
    }
  }

  /**
   * Calculate x / y.  Special values behave in the following way:
   *
   * NaN / x = NaN for any x.
   * x / NaN = NaN for any x.
   * Infinity / x = Infinity for any finite non-negative x.
   * Infinity / x = -Infinity for any finite negative x including -0.
   * -Infinity / x = -Infinity for any finite non-negative x.
   * -Infinity / x = Infinity for any finite negative x including -0.
   * x / Infinity = 0 for any finite non-negative x.
   * x / -Infinity = -0 for any finite non-negative x.
   * x / Infinity = -0 for any finite non-negative x including -0.
   * x / -Infinity = 0 for any finite non-negative x including -0.
   * 
   * Infinity / Infinity = NaN.
   * Infinity / -Infinity = -NaN.
   * -Infinity / Infinity = -NaN.
   * -Infinity / -Infinity = NaN.
   *
   * Division by zero behaves in the following way:
   *
   * x / 0 = Infinity for any finite positive x.
   * x / -0 = -Infinity for any finite positive x.
   * x / 0 = -Infinity for any finite negative x.
   * x / -0 = Infinity for any finite negative x.
   * 0 / 0 = NaN.
   * 0 / -0 = NaN.
   * -0 / 0 = NaN.
   * -0 / -0 = NaN.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function div (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    unchecked {
      uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
      uint256 yExponent = uint128 (y) >> 112 & 0x7FFF;

      if (xExponent == 0x7FFF) {
        if (yExponent == 0x7FFF) return NaN;
        else return x ^ y & 0x80000000000000000000000000000000;
      } else if (yExponent == 0x7FFF) {
        if (y & 0x0000FFFFFFFFFFFFFFFFFFFFFFFFFFFF != 0) return NaN;
        else return POSITIVE_ZERO | (x ^ y) & 0x80000000000000000000000000000000;
      } else if (y & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) {
        if (x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
        else return POSITIVE_INFINITY | (x ^ y) & 0x80000000000000000000000000000000;
      } else {
        uint256 ySignifier = uint128 (y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (yExponent == 0) yExponent = 1;
        else ySignifier |= 0x10000000000000000000000000000;

        uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (xExponent == 0) {
          if (xSignifier != 0) {
            uint shift = 226 - mostSignificantBit (xSignifier);

            xSignifier <<= shift;

            xExponent = 1;
            yExponent += shift - 114;
          }
        }
        else {
          xSignifier = (xSignifier | 0x10000000000000000000000000000) << 114;
        }

        xSignifier = xSignifier / ySignifier;
        if (xSignifier == 0)
          return (x ^ y) & 0x80000000000000000000000000000000 > 0 ?
              NEGATIVE_ZERO : POSITIVE_ZERO;

        assert (xSignifier >= 0x1000000000000000000000000000);

        uint256 msb =
          xSignifier >= 0x80000000000000000000000000000 ? mostSignificantBit (xSignifier) :
          xSignifier >= 0x40000000000000000000000000000 ? 114 :
          xSignifier >= 0x20000000000000000000000000000 ? 113 : 112;

        if (xExponent + msb > yExponent + 16497) { // Overflow
          xExponent = 0x7FFF;
          xSignifier = 0;
        } else if (xExponent + msb + 16380  < yExponent) { // Underflow
          xExponent = 0;
          xSignifier = 0;
        } else if (xExponent + msb + 16268  < yExponent) { // Subnormal
          if (xExponent + 16380 > yExponent)
            xSignifier <<= xExponent + 16380 - yExponent;
          else if (xExponent + 16380 < yExponent)
            xSignifier >>= yExponent - xExponent - 16380;

          xExponent = 0;
        } else { // Normal
          if (msb > 112)
            xSignifier >>= msb - 112;

          xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

          xExponent = xExponent + msb + 16269 - yExponent;
        }

        return bytes16 (uint128 (uint128 ((x ^ y) & 0x80000000000000000000000000000000) |
            xExponent << 112 | xSignifier));
      }
    }
  }

  /**
   * Calculate binary logarithm of x.  Return NaN on negative x excluding -0.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function log_2 (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      if (uint128 (x) > 0x80000000000000000000000000000000) return NaN;
      else if (x == 0x3FFF0000000000000000000000000000) return POSITIVE_ZERO; 
      else {
        uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
        if (xExponent == 0x7FFF) return x;
        else {
          uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          if (xExponent == 0) xExponent = 1;
          else xSignifier |= 0x10000000000000000000000000000;

          if (xSignifier == 0) return NEGATIVE_INFINITY;

          bool resultNegative;
          uint256 resultExponent = 16495;
          uint256 resultSignifier;

          if (xExponent >= 0x3FFF) {
            resultNegative = false;
            resultSignifier = xExponent - 0x3FFF;
            xSignifier <<= 15;
          } else {
            resultNegative = true;
            if (xSignifier >= 0x10000000000000000000000000000) {
              resultSignifier = 0x3FFE - xExponent;
              xSignifier <<= 15;
            } else {
              uint256 msb = mostSignificantBit (xSignifier);
              resultSignifier = 16493 - msb;
              xSignifier <<= 127 - msb;
            }
          }

          if (xSignifier == 0x80000000000000000000000000000000) {
            if (resultNegative) resultSignifier += 1;
            uint256 shift = 112 - mostSignificantBit (resultSignifier);
            resultSignifier <<= shift;
            resultExponent -= shift;
          } else {
            uint256 bb = resultNegative ? 1 : 0;
            while (resultSignifier < 0x10000000000000000000000000000) {
              resultSignifier <<= 1;
              resultExponent -= 1;
  
              xSignifier *= xSignifier;
              uint256 b = xSignifier >> 255;
              resultSignifier += b ^ bb;
              xSignifier >>= 127 + b;
            }
          }

          return bytes16 (uint128 ((resultNegative ? 0x80000000000000000000000000000000 : 0) |
              resultExponent << 112 | resultSignifier & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF));
        }
      }
    }
  }


  /**
   * Get index of the most significant non-zero bit in binary representation of
   * x.  Reverts if x is zero.
   *
   * @return index of the most significant non-zero bit in binary representation
   *         of x
   */
  function mostSignificantBit (uint256 x) private pure returns (uint256) {
    unchecked {
      require (x > 0);

      uint256 result = 0;

      if (x >= 0x100000000000000000000000000000000) { x >>= 128; result += 128; }
      if (x >= 0x10000000000000000) { x >>= 64; result += 64; }
      if (x >= 0x100000000) { x >>= 32; result += 32; }
      if (x >= 0x10000) { x >>= 16; result += 16; }
      if (x >= 0x100) { x >>= 8; result += 8; }
      if (x >= 0x10) { x >>= 4; result += 4; }
      if (x >= 0x4) { x >>= 2; result += 2; }
      if (x >= 0x2) result += 1; // No need to shift x anymore

      return result;
    }
  }
}
library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }
}


contract Vault is IERC721Receiver {
    // Служебные переменные и константы   
    address private constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant swap_router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address private constant nonfungible_position_manager = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    address private constant pool_005 = 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640;
    address private constant pool_03 = 0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8;
    bool private reentry_lock;

    // Параметры контракта
    mapping (address=>Position) private positions;
    mapping (uint256=>OutOfRangeData) private out_of_range_datas;
    uint256 public min_deposit_usdc;
    uint256 private lp_token_id;
    uint128 private total_liquidity;
    address payable private owner;
    uint256 public min_price;
    uint256 public max_price;
    int24 public tick_lower;
    int24 public tick_upper;
    uint8 public price_decimals;
    uint8 public percent_decimals;
    uint256 public max_capacity;
    uint256 public used_capacity;
    bool public is_in_range;
    uint256 public last_event_block_number;
    uint24[] public apr_value;
    uint256[] public apr_time;
        
    // Структура описывает позицию пользователя
    struct Position {
        address user;
        uint256 open_time;
        uint256 maturity_time;
        uint256 open_usdc_amount;
        uint256 close_usdc_amount;
        uint256 withdrawal_usdc_amount;
        uint256 open_price;
        uint256 close_price;
        uint256 min_price;
        uint256 max_price;
        uint256 lp_token_id;
        uint128 liquidity;
    }

    //Структура описывает данные при выходе из диапазона цен
    struct OutOfRangeData {
        uint256 close_price;
        uint256 close_time;
        uint256 close_slippage;
        uint256 total_used_capacity;
        uint256 close_usdc_amount;
    }
    
    constructor() {
        owner = payable(msg.sender);
        min_deposit_usdc = 100000000;
        min_price = 90000000000;
        max_price = 220000000000;
        tick_upper = 208290;
        tick_lower = 199350;
        price_decimals = 8;
        apr_value.push(10000);
        apr_time.push(block.timestamp);
        percent_decimals = 3;
        reentry_lock = false;
        max_capacity = 10000000000;
        is_in_range = true;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }
    modifier noReentry() {
        require(!reentry_lock, "Prevented by noReentry in ReentrancyGuard");
        reentry_lock = true;
        _;
        reentry_lock = false;
    }

    // События
    event NewPosition(address, uint256, uint256, uint256, uint256, uint256);
    event ClosePosition(address, uint256, uint256);
    event NewRange(uint256, uint256, uint256);

    // Функции для установки параметров стратегии
    function set_min_deposit_usdc(uint256 value) external onlyOwner{
        min_deposit_usdc = value;
    }

    function set_max_capacity(uint256 value) external onlyOwner{
        max_capacity = value;
    }

    function set_range(uint256 min_value, uint256 max_value) external onlyOwner {
        uint256 price_005 = get_uni3_oracle_price(pool_005); 
        require(price_005 > min_value && price_005 < max_value, "Incorrect range selected");

        min_price = min_value;
        max_price = max_value;
        tick_lower = price_to_tick(max_price) / 10 * 10;
        tick_upper = price_to_tick(min_price) / 10 * 10;

        // Контракт переходит в режим in_range
        is_in_range = true;

        last_event_block_number = block.number;
        emit NewRange(last_event_block_number, min_price, max_price);
    }

    function set_apr(uint24 value) external onlyOwner{
        apr_value.push(value);
        apr_time.push(block.timestamp);
    }
    

    // Вспомогательные функции
    function get_position(address user) external view returns(Position memory){
        return positions[user];
    }

    function estimate_profit(address user) external view returns(uint256){
        Position memory p = positions[user];
        require(p.user!=address(0), "There is no position for specified address");
        return calc_withdrawal_amount(p);
    }

    function price_to_tick(uint256 price) private pure returns(int24){
        return int24(ABDKMathQuad.toInt(
            ABDKMathQuad.div(
                ABDKMathQuad.log_2(ABDKMathQuad.div(ABDKMathQuad.fromUInt(1e12), ABDKMathQuad.div(ABDKMathQuad.fromUInt(price), ABDKMathQuad.fromUInt(1e8)))),
                ABDKMathQuad.log_2(ABDKMathQuad.div(ABDKMathQuad.fromUInt(10001), ABDKMathQuad.fromUInt(10000)))
            )
        ));
    }

    function sqrt(uint256 n) private pure returns (uint256) { unchecked {
        if (n > 0) {
            uint256 x = n / 2 + 1;
            uint256 y = (x + n / x) / 2;
            while (x > y) {
                x = y;
                y = (x + n / x) / 2;
            }
            return x;
        }
        return 0;
    }}

    function get_lp_proportion(uint256 deposit_y, uint256 deposit_price, uint256 current_price, uint256 minimal_price, uint256 maximal_price) private view returns(uint256, uint256){
        uint256 L = deposit_y * 1e18 / (deposit_price * (10**(24-price_decimals)) / sqrt(deposit_price * (10**(24-price_decimals))) - deposit_price * (10**(24-price_decimals))/sqrt(maximal_price * (10**(24-price_decimals))) +  sqrt(deposit_price * (10**(24-price_decimals))) -  sqrt(minimal_price * (10**(24-price_decimals))));
        uint256 x_virtual_upper = L * 1e18 / sqrt(maximal_price * (10**(24-price_decimals)));
        uint256 y_virtual_lower = L * sqrt(minimal_price * (10**(24-price_decimals))) / 1e18;
		uint256 x_max = L * 1e18 / sqrt(minimal_price * (10**(24-price_decimals))) - L * 1e18 / sqrt(maximal_price * (10**(24-price_decimals)));
        uint256 y_max = (sqrt(maximal_price * (10**(24-price_decimals)))-sqrt(minimal_price * (10**(24-price_decimals)))) * L / 1e18;
        
        uint256 x_now;
        uint256 y_now;
        if(current_price <= minimal_price){
            x_now = x_max;
            y_now = 0;
        }
        else if(current_price > maximal_price){
            x_now = 0;
            y_now = y_max;
        }
        else{
            x_now = L * 1e18 / sqrt(current_price * (10**(24-price_decimals))) - x_virtual_upper;
            y_now = L * sqrt(current_price * (10**(24-price_decimals))) / 1e18 - y_virtual_lower;
        }

        return (x_now, y_now);
    }
    
    function swap_to_weth(uint256 amountIn, uint256 amountOutMinimum) private returns (uint256 amountOut) {
        TransferHelper.safeApprove(USDC, swap_router, amountIn);
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: USDC,
                tokenOut: WETH,
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: 0
            });

        amountOut = ISwapRouter(swap_router).exactInputSingle(params);
    }

    function swap_to_usdc(uint256 amountIn, uint256 amountOutMinimum) private returns (uint256 amountOut) {
        TransferHelper.safeApprove(WETH, swap_router, amountIn);
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: WETH,
                tokenOut: USDC,
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: 0
            });

        amountOut = ISwapRouter(swap_router).exactInputSingle(params);
    }

    function create_liquidity_position(uint256 usdc_to_pool, uint256 weth_to_pool, uint24 slippage_percent) private returns(uint256, uint256, uint256, uint128) {
        TransferHelper.safeApprove(USDC, nonfungible_position_manager, usdc_to_pool);
        TransferHelper.safeApprove(WETH, nonfungible_position_manager, weth_to_pool);
        
        INonfungiblePositionManager.MintParams memory params =
            INonfungiblePositionManager.MintParams({
                token0: USDC,
                token1: WETH,
                fee: 500,
                tickLower: tick_lower,
                tickUpper: tick_upper,
                amount0Desired: usdc_to_pool,
                amount1Desired: weth_to_pool,
                amount0Min: slippage_percent!=0 ? usdc_to_pool-usdc_to_pool * slippage_percent / 100000 : 0,
                amount1Min: slippage_percent!=0 ? weth_to_pool-weth_to_pool * slippage_percent / 100000 : 0,
                recipient: address(this),
                deadline: block.timestamp
            });

        (uint256 token_id, uint128 liquidity, uint256 amount0, uint256 amount1) = INonfungiblePositionManager(nonfungible_position_manager).mint(params);

        if (amount0 < usdc_to_pool) {TransferHelper.safeApprove(USDC, nonfungible_position_manager, 0);}
        if (amount1 < weth_to_pool) {TransferHelper.safeApprove(WETH, nonfungible_position_manager, 0);}

        return (amount0, amount1, token_id, liquidity);  
    }

    function add_liquidity(uint256 token_id, uint256 usdc_to_pool, uint256 weth_to_pool, uint24 slippage_percent) private returns(uint256, uint256, uint128) {
        TransferHelper.safeApprove(USDC, nonfungible_position_manager, usdc_to_pool);
        TransferHelper.safeApprove(WETH, nonfungible_position_manager, weth_to_pool);
        
        INonfungiblePositionManager.IncreaseLiquidityParams memory params =
            INonfungiblePositionManager.IncreaseLiquidityParams({
                tokenId: token_id,
                amount0Desired: usdc_to_pool,
                amount1Desired: weth_to_pool,
                amount0Min: slippage_percent!=0 ? usdc_to_pool-usdc_to_pool * slippage_percent / 100000 : 0,
                amount1Min: slippage_percent!=0 ? weth_to_pool-weth_to_pool * slippage_percent / 100000 : 0,
                deadline: block.timestamp
            });

        (uint128 liquidity, uint256 amount0, uint256 amount1) = INonfungiblePositionManager(nonfungible_position_manager).increaseLiquidity(params);

        if (amount0 < usdc_to_pool) {TransferHelper.safeApprove(USDC, nonfungible_position_manager, 0);}
        if (amount1 < weth_to_pool) {TransferHelper.safeApprove(WETH, nonfungible_position_manager, 0);}

        return (amount0, amount1, liquidity);    
    }

    function collect_fees(uint256 token_id) private returns(uint256, uint256){
        INonfungiblePositionManager.CollectParams memory params =
            INonfungiblePositionManager.CollectParams({
                tokenId: token_id,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });
        
        (uint256 amount0, uint256 amount1) = INonfungiblePositionManager(nonfungible_position_manager).collect(params);
        return (amount0, amount1);
    }

    function remove_liquidity(uint256 token_id, uint128 liquidity) private returns(uint256, uint256){
        INonfungiblePositionManager.DecreaseLiquidityParams memory params =
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: token_id,
                liquidity: liquidity,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            });

        INonfungiblePositionManager(nonfungible_position_manager).decreaseLiquidity(params);
        (uint256 usdc_from_pool, uint256 weth_from_pool) = collect_fees(token_id);
        return (usdc_from_pool, weth_from_pool);
    }

    function mul_div(uint256 a, uint256 b, uint256 denominator) private pure returns (uint256 result) {
        uint256 prod0; 
        uint256 prod1; 
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        require(denominator > prod1);

        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        int256 denominator_int = int256(denominator);
        uint256 twos = uint256(-denominator_int & denominator_int);
        assembly {
            denominator := div(denominator, twos)
        }

        assembly {
            prod0 := div(prod0, twos)
        }

        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        uint256 inv = (3 * denominator) ^ 2;
        inv *= 2 - denominator * inv;
        inv *= 2 - denominator * inv;
        inv *= 2 - denominator * inv;
        inv *= 2 - denominator * inv;
        inv *= 2 - denominator * inv;
        inv *= 2 - denominator * inv;

        result = prod0 * inv;
        return result;
    }

    function get_uni3_oracle_price(address pool) private view returns (uint256 quoteAmount) {
        (uint160 sqrtRatioX96, , , , , ,) = IUniswapV3PoolState(pool).slot0();
        
        if (sqrtRatioX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
            quoteAmount = mul_div(1 << 192, 1e18, ratioX192) * 1e2;
        } else {
            uint256 ratioX128 = mul_div(sqrtRatioX96, sqrtRatioX96, 1 << 64);
            quoteAmount = mul_div(1 << 128, 1e18, ratioX128) * 1e2;
        }
    }

    function calc_withdrawal_amount(Position memory p) private view returns (uint256){
        uint256 withdrawal_amount = p.open_usdc_amount;
        uint index;
        for (uint i = apr_value.length-1; i>=0; i-=1) {
            if (p.open_time>=apr_time[i]) {
                index = i;
                break;
            }
        }

        uint256 current_time = p.open_time;
        uint256 apr_weighted;

        // Позиция была открыта раньше чем последнее изменение apr
        if (index < apr_value.length - 1) {
            for(uint i = index; i <= apr_value.length-2; i++) {
                apr_weighted = apr_value[i] * (apr_time[i+1] - current_time) * 1e20 / 31536000;
                withdrawal_amount += p.open_usdc_amount * apr_weighted / 100000 / 1e20;
                current_time = apr_time[i+1];
            }

            apr_weighted = apr_value[apr_value.length-1] * (block.timestamp - apr_time[apr_time.length-1]) * 1e20 / 31536000;
            withdrawal_amount += p.open_usdc_amount * apr_weighted / 100000 / 1e20;
        }

        // Позиция была открыта позже чем последнее изменение apr
        else{
            apr_weighted = apr_value[apr_value.length-1] * (block.timestamp - p.open_time) * 1e20 / 31536000;
            withdrawal_amount += p.open_usdc_amount * apr_weighted / 100000 / 1e20;
        }

        return withdrawal_amount;
    }
    
    
    // Основные функции
    function deposit(uint256 amount_usdc, uint24 slippage_percent) external noReentry returns(uint256, uint256, uint256){
        require(is_in_range, "Contract is out of range and is not available for new deposits now");
        require(used_capacity+amount_usdc <= max_capacity, "Contract is fully funded can't create deposit");
        require(amount_usdc > min_deposit_usdc, "USDC amount should be > min_deposit_usdc");
        require(positions[msg.sender].user==address(0), "A position for specified address is already exists, please deposit from another address");
        
        TransferHelper.safeTransferFrom(USDC, msg.sender, address(this), amount_usdc);

        // Определяем цену с ораклов Uniswap
        uint256 price_005 = get_uni3_oracle_price(pool_005); 
        uint256 price_03 = get_uni3_oracle_price(pool_03); 
        
        // Определяем пропорцию WETH и USDC
        (, uint256 usdc_to_pool) = get_lp_proportion(amount_usdc, price_005, price_005, min_price, max_price);
        
        // Учитываем слипедж
        uint256 weth_min;
        if(slippage_percent != 0){
            weth_min = (amount_usdc - usdc_to_pool) * 1e20 / price_03;
            weth_min -= weth_min * slippage_percent / 100000;
        }
        else { weth_min = 0; }
        
        // Меняем часть USDC чтобы получить требуемую пропорцию
        uint256 weth_to_pool = swap_to_weth(amount_usdc - usdc_to_pool, weth_min);
        
        // Создаем позицию ликвидности или добавляем ликвидность в пул
        uint256 usdc_in_pool;
        uint256 weth_in_pool;
        uint128 liquidity;
        if (total_liquidity == 0){
            uint256 token_id;
            (usdc_in_pool, weth_in_pool, token_id, liquidity) = create_liquidity_position(usdc_to_pool, weth_to_pool, slippage_percent);
            lp_token_id = token_id;
        }
        else{ (usdc_in_pool, weth_in_pool, liquidity) = add_liquidity(lp_token_id, usdc_to_pool, weth_to_pool, slippage_percent); }

        // Вычисляем остатки и отправляем их обратно пользователю
        uint256 usdc_rest;
        uint256 weth_rest;
        if (usdc_to_pool > usdc_in_pool) {
            usdc_rest = usdc_to_pool - usdc_in_pool;
            TransferHelper.safeTransfer(USDC, msg.sender, usdc_rest);
        }
        if (weth_to_pool > weth_in_pool) {
            weth_rest = weth_to_pool - weth_in_pool;
            TransferHelper.safeTransfer(WETH, msg.sender, weth_rest);
        }

        // Создаем позицию
        Position memory p = Position({
            user: msg.sender, 
            open_time: block.timestamp,
            maturity_time: 0,
            open_usdc_amount: usdc_in_pool+(weth_in_pool*price_005)/1e20, 
            close_usdc_amount: 0,
            withdrawal_usdc_amount: 0,
            open_price: price_005, 
            close_price: 0,
            min_price: min_price,
            max_price: max_price,
            lp_token_id: lp_token_id,
            liquidity: liquidity
        }); 
        positions[msg.sender] = p;

        // Обновляем данные по емкости контракта
        used_capacity += p.open_usdc_amount;
        total_liquidity += liquidity;

        // Обновляем номер блока последнего события
        last_event_block_number = block.number;

        // Эмитим событие
        emit NewPosition(p.user, last_event_block_number, p.open_usdc_amount, p.open_price, p.min_price, p.max_price);

        return (p.open_usdc_amount, usdc_rest, weth_rest);
    }

    function close_position(uint24 slippage_percent) external noReentry returns(int256, uint256){
        Position memory p = positions[msg.sender];
        require(p.user!=address(0), "There is no position for specified address");
        require(p.maturity_time==0, "Position is already closed");

        // Позиция закрывается внутри диапазона
        if (is_in_range) {
            // Определяем цену с оракла Uniswap
            uint256 price_005 = get_uni3_oracle_price(pool_005); 
            uint256 price_03 = get_uni3_oracle_price(pool_03);

            // Меняем LP токены обратно на андерлаеры
            (uint256 usdc_from_pool, uint256 weth_from_pool) = remove_liquidity(lp_token_id, p.liquidity);
            uint256 usdc_from_pool_zero_slippage;
            if (weth_from_pool > 0) {
                uint256 usdc_min;
                if ( slippage_percent != 0 ){
                    usdc_min = weth_from_pool * price_03 / 1e20;
                    usdc_from_pool_zero_slippage = usdc_from_pool + usdc_min * 100300 / 100000;
                    usdc_min -= usdc_min * slippage_percent / 100000;
                }
                else{
                    usdc_from_pool_zero_slippage = usdc_from_pool + weth_from_pool * price_03 / 1e20 * 100300 / 100000; 
                    usdc_min = 0; 
                }
                usdc_from_pool += swap_to_usdc(weth_from_pool, usdc_min);
            }

            // Вычисляем возникший слипедж
            uint256 usdc_slippage_value = usdc_from_pool_zero_slippage - usdc_from_pool;

            // Обновляем данные по емкости контракта
            used_capacity -= p.open_usdc_amount;
            total_liquidity -= p.liquidity;
            if (total_liquidity == 0) {lp_token_id = 0;}

            // Обновляем позицию пользователя, начисляем APR юзеру за вычетом slippage
            p.withdrawal_usdc_amount = calc_withdrawal_amount(p) - usdc_slippage_value;
            p.close_usdc_amount = usdc_from_pool;
            p.close_price = price_005;
            p.maturity_time = block.timestamp + 86400;
            p.liquidity = 0;
            positions[msg.sender] = p;

            // Обновляем номер блока последнего события 
            last_event_block_number = block.number;

            // Эмитим событие
            emit ClosePosition(p.user, last_event_block_number, price_005);
            
            return (int256(p.withdrawal_usdc_amount) - int256(p.open_usdc_amount), usdc_slippage_value);
        }

        // Позиция закрывается вне диапазона
        else {

            // Обновляем позицию пользователя, начисляем APR юзеру за вычетом slippage
            OutOfRangeData memory out_of_range_data = out_of_range_datas[p.lp_token_id];
            uint256 usdc_slippage_value = out_of_range_data.close_slippage * (p.open_usdc_amount * 100000 / out_of_range_data.total_used_capacity) / 100000;
            p.withdrawal_usdc_amount = calc_withdrawal_amount(p) - usdc_slippage_value; 
            p.close_usdc_amount = out_of_range_data.close_usdc_amount * (p.open_usdc_amount * 100000 / out_of_range_data.total_used_capacity) / 100000;
            p.close_price = out_of_range_data.close_price;
            p.maturity_time = out_of_range_data.close_time + 86400;
            p.liquidity = 0;
            positions[msg.sender] = p;

            return (int256(p.withdrawal_usdc_amount) - int256(p.open_usdc_amount), usdc_slippage_value);
        
        }
    }

    function withdraw() external noReentry returns(uint256){
        Position memory p = positions[msg.sender];
        require(p.user!=address(0), "There is no position for specified address");
        require(p.maturity_time!=0, "Position is not closed, please close position before withdrawal");
        require(block.timestamp > p.maturity_time, "Please wait for maturity time before withdrawal");

        // Определяем соотношение токенов для расчета IL
        (uint256 weth_portion, uint256 usdc_portion) = get_lp_proportion(p.open_usdc_amount, p.open_price, p.close_price, p.min_price, p.max_price);
        uint256 usdc_current = weth_portion * p.close_price / 1e20 + usdc_portion;

        // Вычисляем IL
        uint256 delta_usdc;
        if(usdc_current < p.open_usdc_amount){
            delta_usdc = p.open_usdc_amount - usdc_current;

            // IL!=0, цена пошла вниз, стратегия успешно захеджировалась, возвращаем юзеру его профит остальное забираем в виде профита фонда
            if (IERC20(USDC).balanceOf(owner)>=delta_usdc){
                TransferHelper.safeTransferFrom(USDC, owner, address(this), delta_usdc);

                // Очищаем данные о позиции юзера
                delete positions[msg.sender];

                // Вычисляем прибыль фонда
                uint256 revenue = p.close_usdc_amount + delta_usdc; 
                if (revenue > p.withdrawal_usdc_amount){ TransferHelper.safeTransfer(USDC, owner, revenue - p.withdrawal_usdc_amount); }

                // Отправляем юзеру тело депозита + проценты
                TransferHelper.safeTransfer(USDC, msg.sender, p.withdrawal_usdc_amount);

                return p.withdrawal_usdc_amount;
            }

            // IL!=0, цена пошла вниз, стратегия не захеджировалась, это аварийный кейс, выплачиваем юзеру то что осталось по его позиции
            else{
                // Очищаем данные о позиции юзера
                delete positions[msg.sender];

                // Отправляем только то, что осталось
                TransferHelper.safeTransfer(USDC, msg.sender, p.close_usdc_amount);

                return p.close_usdc_amount;
            }
        }

        // IL = 0, цена пошла вверх, возвращаем юзеру его профит остальное забираем в виде профита фонда
        else{
            // Очищаем данные о позиции юзера
            delete positions[msg.sender];

            // Вычисляем прибыль фонда
            uint256 revenue = p.close_usdc_amount + delta_usdc; 
            if (revenue > p.withdrawal_usdc_amount){ TransferHelper.safeTransfer(USDC, owner, revenue - p.withdrawal_usdc_amount); }

            // Отправляем юзеру тело депозита + проценты
            TransferHelper.safeTransfer(USDC, msg.sender, p.withdrawal_usdc_amount);

            return p.withdrawal_usdc_amount;
        }
    }

    function out_of_range_close_out(uint24 slippage_percent) external onlyOwner noReentry {
        // Определяем цену с оракла Uniswap
        uint256 price_005 = get_uni3_oracle_price(pool_005); 
        uint256 price_03 = get_uni3_oracle_price(pool_03);

        // Меняем LP токены обратно на андерлаеры
        (uint256 usdc_from_pool, uint256 weth_from_pool) = remove_liquidity(lp_token_id, total_liquidity);
        uint256 usdc_from_pool_zero_slippage;
        if (weth_from_pool > 0) {
            uint256 usdc_min;
            if ( slippage_percent != 0 ){
                usdc_min = weth_from_pool * price_03 / 1e20;
                usdc_from_pool_zero_slippage = usdc_from_pool + usdc_min * 100300 / 100000;
                usdc_min -= usdc_min * slippage_percent / 100000;
            }
            else{
                usdc_from_pool_zero_slippage = usdc_from_pool + weth_from_pool * price_03 / 1e20 * 100300 / 100000; 
                usdc_min = 0; 
            }
            usdc_from_pool += swap_to_usdc(weth_from_pool, usdc_min);
        }

        // Контракт переходит в режим out_of_range
        is_in_range = false;

        out_of_range_datas[lp_token_id] = OutOfRangeData({
            close_price: price_005,
            close_time: block.timestamp,
            close_slippage: usdc_from_pool_zero_slippage - usdc_from_pool,
            total_used_capacity: used_capacity,
            close_usdc_amount: usdc_from_pool
        });

        // Обновляем данные по емкости контракта
        used_capacity = 0;
        total_liquidity = 0;
        lp_token_id = 0;
    }
    

    // Реализация интерфейсов
    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}