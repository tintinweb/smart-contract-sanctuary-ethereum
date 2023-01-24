/**
 *Submitted for verification at Etherscan.io on 2023-01-24
*/

// File: @openzeppelin/contracts/utils/math/Math.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// File: zapper.sol


pragma solidity 0.8.17;


interface IBaseV1Factory {
    function pairCodeHash() external pure returns (bytes32);
    function getPair(address tokenA, address token, bool stable) external view returns (address);
    function createPair(address tokenA, address tokenB, bool stable) external returns (address pair);
}

interface IBaseV1Pair {
    function burn(address to) external returns (uint amount0, uint amount1);
    function mint(address to) external returns (uint liquidity);
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function swap(uint256 amount0Out,uint256 amount1Out,address to,bytes memory data) external;
    function feeRatio() external view returns (uint);
    function metadata() external view returns (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0, address t1);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
    function balanceOf(address) external view returns (uint);
}

interface ILpDepositor {
    function deposit(address pool, uint256 amount, address[] calldata rewardTokens) external;
    function tokenForPool(address pool) external view returns (IERC20);
}

contract zapper {
    IBaseV1Factory public immutable factory;
    ILpDepositor public immutable lpDepositor;

    uint internal constant MINIMUM_LIQUIDITY = 10**3;
    bytes32 immutable pairCodeHash;
    address immutable owner;
    mapping (address => IERC20) public depositTokenForPair;
    address[] empty;

    constructor(IBaseV1Factory _factory, ILpDepositor _lpDepositor) {
        factory = _factory;
        pairCodeHash = IBaseV1Factory(_factory).pairCodeHash();
        lpDepositor = _lpDepositor;
        owner = msg.sender;
    }


    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'BaseV1Router: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'BaseV1Router: ZERO_ADDRESS');
    }
    
    // @notice calculates the CREATE2 address for a pair without making any external calls
    function PairFor(address tokenA, address tokenB, bool stable) external view returns (address pair) {
        return _pairFor(tokenA,tokenB,stable);
    }

    function _pairFor(address tokenA, address tokenB, bool stable) internal view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
            hex'ff',
            factory,
            keccak256(abi.encodePacked(token0, token1, stable)),
            pairCodeHash // init code hash
        )))));
    }

    // @notice given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quoteLiquidity(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'BaseV1Router: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'BaseV1Router: INSUFFICIENT_LIQUIDITY');
        amountB = amountA * reserveB / reserveA;
    }

    // @notice fetches and sorts the reserves for a pair
    function getReserves(address tokenA, address tokenB, bool stable) external view returns (uint reserveA, uint reserveB){
        (,,reserveA, reserveB) = getMetadata(tokenA, tokenB, stable);
    }

    function getMetadata(address tokenA, address tokenB, bool stable) internal view returns 
    (uint decimalsA, uint decimalsB,uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint decimals0, 
        uint decimals1,
        uint reserve0, 
        uint reserve1,,,) = IBaseV1Pair(_pairFor(tokenA, tokenB, stable)).metadata();
        (decimalsA, decimalsB, reserveA, reserveB) = 
        tokenA == token0 ? (decimals0, decimals1,reserve0, reserve1) : (decimals1, decimals0, reserve1, reserve0);
    }

    function quoteAddLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint amountADesired,
        uint amountBDesired
    ) public view returns (uint amountA, uint amountB, uint liquidity) {
        address _pair = _pairFor(tokenA, tokenB, stable);
        (uint reserveA, uint reserveB) = (0,0);
        uint _totalSupply = 0;
        if (_pair != address(0)) {
            _totalSupply = IERC20(_pair).totalSupply();
            (,, reserveA, reserveB) = getMetadata(tokenA, tokenB, stable);
        }
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
            liquidity = Math.sqrt(amountA * amountB) - MINIMUM_LIQUIDITY;
        } else {

            uint amountBOptimal = quoteLiquidity(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                (amountA, amountB) = (amountADesired, amountBOptimal);
                liquidity = Math.min(amountA * _totalSupply / reserveA, amountB * _totalSupply / reserveB);
            } else {
                uint amountAOptimal = quoteLiquidity(amountBDesired, reserveB, reserveA);
                (amountA, amountB) = (amountAOptimal, amountBDesired);
                liquidity = Math.min(amountA * _totalSupply / reserveA, amountB * _totalSupply / reserveB);
            }
        }
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
        require(amountADesired >= amountAMin);
        require(amountBDesired >= amountBMin);
        address _pair = factory.getPair(tokenA, tokenB, stable);
        if (_pair == address(0)) {
            _pair = factory.createPair(tokenA, tokenB, stable);
        }
        (,,uint reserveA, uint reserveB) = getMetadata(tokenA, tokenB, stable);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = quoteLiquidity(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'BaseV1Router: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = quoteLiquidity(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'BaseV1Router: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function _getDepositToken(address pair) internal returns (IERC20) {
        IERC20 token = depositTokenForPair[pair];
        if (address(token) == address(0)) {
            IERC20(pair).approve(address(lpDepositor), type(uint).max);
            token = lpDepositor.tokenForPool(pair);
            depositTokenForPair[pair] = token;
        }
        return token;
    }

    // @notice returns amounts of the tokens that will be deposited and the lp minted.
    function quoteZapIn( address tokenA, address tokenB, uint amountA, bool stable
    ) external view returns (uint, uint, uint liquidity) {
        (uint decimals0,uint decimals1,uint reserve0,uint reserve1) = getMetadata(tokenA,tokenB,stable);
        uint fee = IBaseV1Pair(_pairFor(tokenA, tokenB, stable)).feeRatio() * 10**6;
        uint swapAmount = _calcSwap(amountA, stable, reserve0, reserve1, fee, decimals0, decimals1);
        fee = 10**6 - (fee  / 10**6);
        uint amountB = getAmountOut(swapAmount * fee, stable, reserve0, reserve1, decimals0, decimals1);
        
        amountA -= swapAmount;
       return quoteAddLiquidity(tokenA, tokenB, stable, amountA, amountB);
    }

    function zapIn(address tokenA, address tokenB, uint amountA, bool stable, uint minLpOut) external {
        
        address pair = _pairFor(tokenA, tokenB, stable);
        IERC20(tokenA).transferFrom(msg.sender,address(this),amountA);
        (uint amountB, uint swapAmount) = _swap(tokenA, tokenB, pair, amountA, stable);
        uint liquidity;

        if (!stable){
            IERC20(tokenA).transfer(pair, amountA - swapAmount);
            IERC20(tokenB).transfer(pair, amountB);
            liquidity = IBaseV1Pair(pair).mint(address(this));
        } else{
            (amountA, amountB) = _addLiquidity(tokenA, tokenB, stable, amountA - swapAmount, amountB, 0, 0);
            IERC20(tokenA).transfer(pair,amountA);
            IERC20(tokenB).transfer(pair,amountB);
            liquidity = IBaseV1Pair(pair).mint(address(this));
        }
        // stakes in farm and transfers receipt token to user.
        IERC20 lp = _getDepositToken(pair);
        lpDepositor.deposit(pair, liquidity, empty);
        lp.transfer(msg.sender, liquidity);

        if (liquidity < minLpOut) {
            revert("Oof");
        }
    }
    
    function calcSwap(uint amountA, address tokenA, address tokenB, bool stable) external view returns (uint swapAmount) {
        (uint decimals0,uint decimals1,uint reserve0,uint reserve1) = getMetadata(tokenA,tokenB,stable);
        uint fee = IBaseV1Pair(_pairFor(tokenA, tokenB, stable)).feeRatio() * 10**6;
        swapAmount = _calcSwap(amountA, stable, reserve0, reserve1, fee, decimals0, decimals1);

    }

    function _calcSwap(
        uint amountA, 
        bool stable,
        uint reserve0,
        uint reserve1,
        uint fee,
        uint decimals0,
        uint decimals1) internal pure returns (uint amount){
        
        if (!stable){
            // (sqrt(((2 - f)r)^2 + 4(1 - f)ar) - (2 - f)r) / (2(1 - f))
            uint x = (2*10**6) - fee / 10**6;
            uint y = (4 * (10**6 - (fee / 10**6)) * 10**6);
            uint z = 2 * (10**6 - (fee / 10**6));
            return (Math.sqrt(reserve0 * (x * x * reserve0 + amountA * y)) - reserve0 * x) / z;
        } else{
            // Credit to Tarot for this formula.
            uint a = amountA * 10**18 / decimals0;
            uint x = reserve0 * 10**18 / decimals0;
            uint y = reserve1 * 10**18 / decimals1;
            uint x2 = x * x / 10**18;
            uint y2 = y * y / 10**18;
            uint p = y * (((x2 * 3) + y2) * 10**18 / ((y2 * 3) + x2)) / x;
            uint num = a * y;
            uint den = (a + x) * p / 10**18 + y;

            return num / den * decimals0 / 10**18;
        }
       
    }

    function _swap(
        address tokenA, 
        address tokenB, 
        address pair, 
        uint amountA, 
        bool stable) internal returns(uint, uint){
        uint fee = IBaseV1Pair(pair).feeRatio() * 10**6;
        (uint decimals0,uint decimals1,uint reserve0,uint reserve1) = getMetadata(tokenA,tokenB,stable);
        uint swapAmount = _calcSwap(amountA, stable, reserve0, reserve1,fee, decimals0, decimals1);
        fee = 10**6 - (fee  / 10**6);
         if (!stable){
            uint amountOut = getAmountOut(swapAmount * fee, stable, reserve0, reserve1, decimals0,decimals1);
            IERC20(tokenA).transfer(pair, swapAmount);
            if (tokenA < tokenB){
                IBaseV1Pair(pair).swap(0,amountOut,address(this),"");
            }else{
                IBaseV1Pair(pair).swap(amountOut,0,address(this),"");
            }
            return (amountOut, swapAmount);
        } else {
            uint amountOut = getAmountOut(swapAmount * fee, stable, reserve0, reserve1, decimals0,decimals1);
            IERC20(tokenA).transfer(pair, swapAmount);
            if (tokenA < tokenB){
                IBaseV1Pair(pair).swap(0,amountOut,address(this),"");
            }else{
                IBaseV1Pair(pair).swap(amountOut,0,address(this),"");
            }
            return (amountOut, swapAmount);
        }
    }

    function getAmountOut(
        uint amountA, 
        bool stable, 
        uint reserve0, 
        uint reserve1, 
        uint decimals0, 
        uint decimals1) internal pure returns (uint) {
        
        uint amountB;
        if (!stable) {
            amountB = (amountA * reserve1) / (reserve0 * 10**6 + amountA);
        } else {
            amountA = amountA / 10**6;
            uint xy = _k(reserve0,reserve1,decimals0,decimals1);
            amountA = amountA * 10**18 / decimals0;
            uint y = (reserve1 * 10**18 / decimals1) - getY(amountA+(reserve0 * 10**18 / decimals0),xy,reserve1);
            amountB = y * decimals1 / 10**18;
        }
        return amountB;
    }
  
    // k = xy(x^2 + y^2)
    function _k(uint x, uint y,uint decimals0, uint decimals1) internal pure returns (uint) {
        uint _x = x * 10**18 / decimals0;
        uint _y = y * 10**18 / decimals1;
        uint _a = (_x * _y) / 10**18;
        uint _b = ((_x * _x) / 10**18 + (_y * _y) / 10**18);
        return _a * _b / 10**18; 
    }

    function getY(uint x0, uint xy, uint y) internal pure returns (uint) {
        for (uint i = 0; i < 255; ++i) {
            uint y_prev = y;
            uint k = _f(x0, y);
            if (k < xy) {
                uint dy = (xy - k)*10**18/_d(x0, y);
                y = y + dy;
            } else {
                uint dy = (k - xy)*10**18/_d(x0, y);
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

    function _f(uint x0, uint y) internal pure returns (uint) {
        return x0*(y*y/10**18*y/10**18)/10**18+(x0*x0/10**18*x0/10**18)*y/10**18;
    }
    function _d(uint x0, uint y) internal pure returns (uint) {
        return 3*x0*(y*y/10**18)/10**18+(x0*x0/10**18*x0/10**18);
    }
    
    // @notice To recover dust, or in case a brainlet sends tokens to the contract.
    function sweepToken(address token) external{
        require(msg.sender == owner);
        IERC20 _token = IERC20(token);
        _token.transfer(msg.sender,_token.balanceOf(address(this)));
    }
}