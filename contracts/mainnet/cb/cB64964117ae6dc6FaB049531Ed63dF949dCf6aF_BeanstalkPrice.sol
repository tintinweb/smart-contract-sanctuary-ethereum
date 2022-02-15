//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./CurvePrice.sol";
import "./UniswapPrice.sol";

contract BeanstalkPrice is UniswapPrice, CurvePrice {

    using SafeMath for uint256;

    struct Prices {
        uint256 price;
        uint256 liquidity;
        int deltaB;
        P.Pool[2] ps;
    }

    function price() external view returns (Prices memory p) {
        P.Pool memory c = getCurve();
        P.Pool memory u = getUniswap();
        p.ps = [c,u];
        p.price = (c.price*c.liquidity + u.price*u.liquidity) / (c.liquidity + u.liquidity);
        p.liquidity = c.liquidity + u.liquidity;
        p.deltaB = c.deltaB + u.deltaB;
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {P} from "./P.sol";

interface I3Curve {
    function get_virtual_price() external view returns (uint256);
}

interface IMeta3Curve {
    function A_precise() external view returns (uint256);
    function get_balances() external view returns (uint256[2] memory);
    function get_price_cumulative_last() external view returns (uint256[2] memory);
    function block_timestamp_last() external view returns (uint256);
    // function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
    function get_dy_underlying(int128 i, int128 j, uint256 dx, uint256[2] calldata _balances) external view returns (uint256);
    function get_dy(int128 i, int128 j, uint256 dx, uint256[2] calldata _balances) external view returns (uint256);
}

contract CurvePrice {

    using SafeMath for uint256;

    uint256 private constant A_PRECISION = 100;
    address private constant POOL = 0x3a70DfA7d2262988064A2D051dd47521E43c9BdD;
    address private constant CRV3_POOL = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    uint256 private constant N_COINS  = 2;
    uint256 private constant RATE_MULTIPLIER = 10 ** 30;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant i = 0;
    uint256 private constant j = 1;
    address[2] private tokens = [0xDC59ac4FeFa32293A95889Dc396682858d52e5Db, 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490];

    function getCurve() public view returns (P.Pool memory pool) {
        pool.pool = POOL;
        pool.tokens = tokens;
        uint256[2] memory balances = IMeta3Curve(POOL).get_balances();
        pool.balances = balances;
        uint256[2] memory rates = getRates();
        uint256[2] memory xp = getXP(balances, rates);
        uint256 a = IMeta3Curve(POOL).A_precise();
        uint256 D = getD(xp, a);

        pool.price = getCurvePrice(xp, rates, a, D);
        rates[0] = rates[0].mul(pool.price).div(1e6);
        pool.liquidity = getCurveUSDValue(balances, rates);
        pool.deltaB = getCurveDeltaB(balances[0], D);
    }

    function getCurveDeltaB(uint256 balance, uint256 D) private pure returns (int deltaB) {
        uint256 pegBeans = D / 2 / 1e12;
        deltaB = int256(pegBeans) - int256(balance);
    }
    
    function getCurvePrice(uint256[2] memory xp, uint256[2] memory rates, uint256 a, uint256 D) private pure returns (uint) {
        uint256 x = xp[i] + (1 * rates[i] / PRECISION);
        uint256 y = getY(x, xp, a, D);
        uint256 dy = xp[j] - y - 1;
        return dy / 1e6;
    }

    function getCurveUSDValue(uint256[2] memory balances, uint256[2] memory rates) private pure returns (uint) {
        uint256[2] memory value = getXP(balances, rates);
        return (value[0] + value[1]) / 1e12;
    }

    function getY(uint256 x, uint256[2] memory xp, uint256 a, uint256 D) private pure returns (uint256 y) {

        uint256 S_ = 0;
        uint256 _x = 0;
        uint256 y_prev = 0;
        uint256 c = D;
        uint256 Ann = a * N_COINS;

        for (uint256 _i = 0; _i < N_COINS; _i++) {
            if (_i == i) _x = x;
            else if (_i != j) _x = xp[_i];
            else continue;
            S_ += _x;
            c = c * D / (_x * N_COINS);
        }

        c = c * D * A_PRECISION / (Ann * N_COINS);
        uint256 b = S_ + D * A_PRECISION / Ann; // - D
        y = D;

        for (uint256 _i = 0; _i < 255; _i++) {
            y_prev = y;
            y = (y*y + c) / (2 * y + b - D);
            // Equality with the precision of 1
            if (y > y_prev && y - y_prev <= 1) return y;
            else if (y_prev - y <= 1) return y;
        }
        require(false, "Price: Convergence false");
    }



    function getD(uint256[2] memory xp, uint256 a) private pure returns (uint D) {
        
        /*  
        * D invariant calculation in non-overflowing integer operations
        * iteratively
        *
        * A * sum(x_i) * n**n + D = A * D * n**n + D**(n+1) / (n**n * prod(x_i))
        *
        * Converging solution:
        * D[j+1] = (A * n**n * sum(x_i) - D[j]**(n+1) / (n**n prod(x_i))) / (A * n**n - 1)
        */
        uint256 S;
        uint256 Dprev;
        for (uint _i = 0; _i < xp.length; _i++) {
            S += xp[_i];
        }
        if (S == 0) return 0;

        D = S;
        uint256 Ann = a * N_COINS;
        for (uint _i = 0; _i < 256; _i++) {
            uint256 D_P = D;
            for (uint _j = 0; _j < xp.length; _j++) {
                D_P = D_P * D / (xp[_j] * N_COINS);  // If division by 0, this will be borked: only withdrawal will work. And that is good
            }
            Dprev = D;
            D = (Ann * S / A_PRECISION + D_P * N_COINS) * D / ((Ann - A_PRECISION) * D / A_PRECISION + (N_COINS + 1) * D_P);
            // Equality with the precision of 1
            if (D > Dprev && D - Dprev <= 1) return D;
            else if (Dprev - D <= 1) return D;
        }
        // convergence typically occurs in 4 rounds or less, this should be unreachable!
        // if it does happen the pool is borked and LPs can withdraw via `remove_liquidity`
        require(false, "Price: Convergence false");
    }

    function getXP(uint256[2] memory balances, uint256[2] memory rates) private pure returns (uint256[2] memory xp) {
        xp[0] = balances[0].mul(rates[0]).div(PRECISION);
        xp[1] = balances[1].mul(rates[1]).div(PRECISION);
    }

    function getRates() private view returns (uint256[2] memory rates) {
        return [RATE_MULTIPLIER, I3Curve(CRV3_POOL).get_virtual_price()];
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./P.sol";

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract UniswapPrice {

    using SafeMath for uint256;

    address private constant USDC_ETH_ADDRESS = 0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc;
    address private constant ETH_BEAN_ADDRESS = 0x87898263B6C5BABe34b4ec53F22d98430b91e371;
    address[2] private TOKENS = [0xDC59ac4FeFa32293A95889Dc396682858d52e5Db, 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2];

    function getUniswap() public view returns (P.Pool memory pool) {
        pool.pool = ETH_BEAN_ADDRESS;
        pool.tokens = TOKENS;
        // Bean, Eth
        uint256[2] memory reserves = _reserves();
        pool.balances = reserves;
        // USDC, Eth
        uint256[2] memory pegReserves = _pegReserves();

        uint256[2] memory prices = getUniswapPrice(reserves, pegReserves);
        pool.price = prices[0];
        pool.liquidity = getUniswapUSDValue(reserves, prices);
        pool.deltaB = getUniswapDeltaB(reserves, pegReserves);
    }
    
    function getUniswapPrice(uint256[2] memory reserves, uint256[2] memory pegReserves) private pure returns (uint256[2] memory prices) {
        prices[1] = uint256(pegReserves[0]).mul(1e18).div(pegReserves[1]);
        prices[0] = reserves[1].mul(prices[1]).div(reserves[0]).div(1e12);
    }

    function getUniswapUSDValue(uint256[2] memory balances, uint256[2] memory rates) private pure returns (uint) {
        return (balances[0].mul(rates[0]) + balances[1].mul(rates[1]).div(1e12)).div(1e6);
    }

    function getUniswapDeltaB(uint256[2] memory reserves, uint256[2] memory pegReserves) private pure returns (int256) {
        uint256 newBeans = sqrt(reserves[1].mul(reserves[0]).mul(pegReserves[0]).div(pegReserves[1]));
        return int256(newBeans) - int256(reserves[0]);
    }

    function _reserves() private view returns (uint256[2] memory reserves) {
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(ETH_BEAN_ADDRESS).getReserves();
        reserves = [uint256(reserve1), uint256(reserve0)];
    }

    function _pegReserves() private view returns (uint256[2] memory reserves) {
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(USDC_ETH_ADDRESS).getReserves();
        reserves = [uint256(reserve0), uint256(reserve1)];
    }

    function sqrt(uint y) private pure returns (uint z) {
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract P {
    struct Pool {
        address pool;
        address[2] tokens;
        uint256[2] balances;
        uint256 price;
        uint256 liquidity;
        int256 deltaB;
    }

    struct Prices {
        address pool;
        address[] tokens;
        uint256 price;
        uint256 liquidity;
        int deltaB;
        P.Pool[2] ps;
    }
}