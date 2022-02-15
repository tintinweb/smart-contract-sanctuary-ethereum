//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./RopstenCurvePrice.sol";
import "./RopstenUniswapPrice.sol";

contract RopstenBeanstalkPrice is RopstenUniswapPrice, RopstenCurvePrice {

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

import {P} from "./P.sol";

contract RopstenCurvePrice {

    function getCurve() public pure returns (P.Pool memory pool) {
        pool.balances = [uint256(0),uint256(0)];
        pool.price = 1e6;
        pool.liquidity = 0;
        pool.deltaB = 0;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./P.sol";

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract RopstenUniswapPrice {

    using SafeMath for uint256;

    address private constant USDC_ETH_ADDRESS = 0x681A4164703351d6AceBA9D7038b573b444d3353;
    address private constant ETH_BEAN_ADDRESS = 0x298c5f1f902c5bDc2936eb44b3E0E8675F40B8db;
    address[2] private TOKENS = [0xDC59ac4FeFa32293A95889Dc396682858d52e5Db, 0xc778417E063141139Fce010982780140Aa0cD5Ab];

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