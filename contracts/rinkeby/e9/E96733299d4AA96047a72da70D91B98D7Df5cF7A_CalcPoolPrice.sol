// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "../SafeMath.sol";
import "../UniswapV2PriceOracle.sol";
import "../Interfaces/IPriceFeeds.sol";
import "../UniswapV3PriceOracle.sol";

contract CalcPoolPrice {
    uint224 constant Q112 = 2**112;

    using FixedPoint for *;
    using SafeMath for uint;

    PriceOracle public priceOracle;

    constructor(address priceOracle_) {
        priceOracle = PriceOracle(priceOracle_);
    }

    function isContract(address account) public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function checkFunctionStaticCall(
        address target
    ) public view returns (bool) {
        require(isContract(target), "Address: static call to non-contract");

        bytes4 FUNC_SELECTOR = bytes4(keccak256("getReserves()"));
        bytes memory data = abi.encodeWithSelector(FUNC_SELECTOR);

        (bool success, ) = target.staticcall(data);
        return success;
    }

    function getPoolPriceAverage(address pair_, address asset) public view returns (FixedPoint.uq112x112 memory) {
        if (checkFunctionStaticCall(pair_)) {
            IUniswapV2Pair pair = IUniswapV2Pair(pair_);
            (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();

            FixedPoint.uq112x112 memory priceAverage;

            if (asset == pair.token0()) {
                priceAverage = FixedPoint.uq112x112(uqdiv(encode(reserve1), reserve0));
            } else {
                priceAverage = FixedPoint.uq112x112(uqdiv(encode(reserve0), reserve1));
            }

            return priceAverage;
        } else {
            address oracle = priceOracle.assetOracle(asset);
            uint price = UniswapV3PriceOracle(oracle).getAveragePrice(asset);

            return FixedPoint.uq112x112(uint224(price));
        }
    }

    function check1(address asset) public view returns (address) {
        return priceOracle.assetOracle(asset);
    }

    function check2(address oracle, address asset) public view returns (uint) {
        return UniswapV3PriceOracle(oracle).getAveragePrice(asset);
    }


    function getPoolETHAmount(address asset, uint amountIn) public view returns (uint) {
        address oracle = priceOracle.assetOracle(asset);
        address pair = UniswapV2PriceOracle(oracle).assetPair(asset);

        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();

        uint power;

        FixedPoint.uq112x112 memory priceAverage = getPoolPriceAverage(pair, asset);
        uint result = priceAverage.mul(amountIn).decode144();

        if (token0 == UniswapV2PriceOracle(oracle).WETHToken() || token1 == UniswapV2PriceOracle(oracle).WETHToken()) {
            // asset and weth pool
            return result;
        } else {
            // asset and stable coin pool
            if (token0 == asset) {
                power = EIP20Interface(token1).decimals();
                return result.mul(calcPoolCourseInETH(token1)).div(10**power);
            } else {
                power = EIP20Interface(token0).decimals();
                return result.mul(calcPoolCourseInETH(token0)).div(10**power);
            }
        }
    }

    function calcPoolCourseInETH(address asset) public view returns (uint) {
        if (asset == Registry(priceOracle.registry()).pETH()) {
            // ether always worth 1
            return 1e18;
        }

        uint power = EIP20Interface(asset).decimals();
        uint amountIn = 10**power;

        return getPoolETHAmount(asset, amountIn);
    }

    function getPoolCourseInETH(address asset) public view returns (uint) {
        if (asset == Registry(priceOracle.registry()).pETH()) {
            // ether always worth 1
            return 1e18;
        }

        return calcPoolCourseInETH(asset);
    }

    function getPoolPriceInUSD(address asset) public view returns (uint) {
        uint ETHUSDPrice = uint(AggregatorInterface(priceOracle.ETHUSDPriceFeed()).latestAnswer());
        uint AssetETHCourse = getPoolCourseInETH(asset);

        // div 1e8 is chainlink precision for ETH
        return ETHUSDPrice.mul(AssetETHCourse).div(1e8);
    }

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal view returns (uint224 z) {
        z = uint224(y) * uint224(Q112); // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./PriceOracle.sol";
import "./ErrorReporter.sol";
import "./PTokenInterfaces.sol";
import "./SafeMath.sol";
import "./UniswapV2PriceOracleStorage.sol";
import "./EIP20Interface.sol";
import "./Controller.sol";
import "./PTokenFactory.sol";

contract UniswapV2PriceOracle is UniswapCommon, UniswapV2PriceOracleStorageV1 {
    using FixedPoint for *;
    using SafeMath for uint;

    event AssetPairUpdated(address asset, address pair);

    constructor() {}

    function initialize(
        address poolFactory_,
        address WETHToken_
    )
        public
    {
        require(
            WETHToken == address(0)
            , "Oracle: may only be initialized once"
        );

        WETHToken = WETHToken_;

        require(
            poolFactory_ != address(0)
            , 'Oracle: invalid address for factory'
        );

        Q112 = 2**112;
        period = 10 minutes;

        poolFactories.push(poolFactory_);

        emit PoolAdded(0, poolFactory_);
    }

    function getCourseInETH(address asset) public view override returns (uint) {
        if (asset == Registry(registry).pETH()) {
            // ether always worth 1
            return 1e18;
        }

        return averagePrices[asset];
    }

    function update(address asset) public override returns (uint) {
        uint112 reserve0;
        uint112 reserve1;
        uint32 blockTimeStamp;
        address pair;

        if (!isNewAsset(asset)) {
            pair = assetPair[asset];

            address token0 = IUniswapV2Pair(pair).token0();
            address token1 = IUniswapV2Pair(pair).token1();

            (, reserve1, ) = getReservesFromPair(asset);
            uint result = uint(reserve1);

            if (token0 != WETHToken && token1 != WETHToken) {
                uint power;

                // asset and stable coin pool
                if (token0 == asset) {
                    power = EIP20Interface(token1).decimals();
                    result = uint(reserve1).mul(getCourseInETH(token1)).div(10**power);
                } else {
                    power = EIP20Interface(token0).decimals();
                    result = uint(reserve1).mul(getCourseInETH(token0)).div(10**power);
                }
            }

            if (result < minReserveLiquidity) {
                cumulativePrices[assetPair[asset]][asset].priceAverage._x = 0;
                cumulativePrices[assetPair[asset]][asset].priceCumulativePrevious = 0;
                cumulativePrices[assetPair[asset]][asset].blockTimeStampPrevious = 0;
                assetPair[asset] = address(0);
            }
        }

        if (isNewAsset(asset)) {
            if (assetPair[asset] == address(0)) {
                // first update from factory or other users
                (pair, ) = searchPair(asset);
            } else {
                // after updatePair function
                pair = assetPair[asset];
            }

            if (pair != address(0)) {
                assetPair[asset] = pair;

                (reserve0, reserve1, blockTimeStamp) = getReservesFromPair(asset);

                if (reserve1 < minReserveLiquidity) {
                    return fail(Error.UPDATE_PRICE, FailureInfo.NO_RESERVES);
                }

                cumulativePrices[pair][asset].priceAverage = FixedPoint.uq112x112(uqdiv(encode(reserve1), reserve0));
            } else {
                return fail(Error.UPDATE_PRICE, FailureInfo.NO_PAIR);
            }
        } else {
            // second and next updates
            if (!isPeriodElapsed(asset)) {
                return fail(Error.UPDATE_PRICE, FailureInfo.PERIOD_NOT_ELAPSED);
            }

            (, , blockTimeStamp) = getReservesFromPair(asset);
            pair = assetPair[asset];

            uint32 timeElapsed = blockTimeStamp - cumulativePrices[pair][asset].blockTimeStampPrevious;

            // overflow is desired, casting never truncates
            // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
            if (asset == IUniswapV2Pair(pair).token0()) {
                cumulativePrices[pair][asset].priceAverage = FixedPoint.uq112x112(uint224((IUniswapV2Pair(pair).price0CumulativeLast() - cumulativePrices[pair][asset].priceCumulativePrevious) / timeElapsed));
            } else {
                cumulativePrices[pair][asset].priceAverage = FixedPoint.uq112x112(uint224((IUniswapV2Pair(pair).price1CumulativeLast() - cumulativePrices[pair][asset].priceCumulativePrevious) / timeElapsed));
            }
        }

        cumulativePrices[pair][asset].blockTimeStampPrevious = blockTimeStamp;

        // update data
        if (asset == IUniswapV2Pair(pair).token0()) {
            cumulativePrices[pair][asset].priceCumulativePrevious = IUniswapV2Pair(pair).price0CumulativeLast();
        } else {
            cumulativePrices[pair][asset].priceCumulativePrevious = IUniswapV2Pair(pair).price1CumulativeLast();
        }

        averagePrices[asset] = calcCourseInETH(asset);

        return uint(Error.NO_ERROR);
    }

    function checkAndUpdateAllNewAssets() public {
        PTokenFactory factory = PTokenFactory(Registry(registry).factory());
        Controller controller = Controller(factory.controller());

        address[] memory allMarkets = Controller(controller).getAllMarkets();

        updateNewAssets(allMarkets);
    }

    function updateNewAssets(address[] memory pTokens) public {
        address asset;

        for(uint i = 0; i < pTokens.length; i++) {
            if (pTokens[i] == Registry(registry).pETH()) {
                continue;
            }

            asset = PErc20Interface(pTokens[i]).underlying();

            if (isNewAsset(asset)) {
                update(asset);
            }
        }
    }

    function isNewAsset(address asset) public view returns (bool) {
        return bool(cumulativePrices[assetPair[asset]][asset].blockTimeStampPrevious == 0);
    }

    function getPoolPair(address asset, uint poolId) public view returns (address) {
        IUniswapV2Factory factory = IUniswapV2Factory(poolFactories[poolId]);

        return factory.getPair(WETHToken, asset);
    }

    function getPoolPairWithStableCoin(address asset, uint poolId, uint stableCoinId) public view returns (address) {
        IUniswapV2Factory factory = IUniswapV2Factory(poolFactories[poolId]);

        return factory.getPair(stableCoins[stableCoinId], asset);
    }

    function getReservesFromPair(address asset) public view returns (uint112, uint112, uint32) {
        uint112 assetReserve;
        uint112 ethOrCoinReserves;
        uint32 blockTimeStamp;

        IUniswapV2Pair pair = IUniswapV2Pair(assetPair[asset]);

        address token0 = pair.token0();

        if (token0 == asset) {
            (assetReserve, ethOrCoinReserves, blockTimeStamp) = pair.getReserves();
        } else {
            (ethOrCoinReserves, assetReserve, blockTimeStamp) = pair.getReserves();
        }

        return (assetReserve, ethOrCoinReserves, blockTimeStamp);
    }

    function isPeriodElapsed(address asset) public view returns (bool) {
        IUniswapV2Pair pair = IUniswapV2Pair(assetPair[asset]);

        ( , , uint32 blockTimeStamp) = pair.getReserves();

        uint timeElapsed = uint(blockTimeStamp).sub(uint(cumulativePrices[assetPair[asset]][asset].blockTimeStampPrevious));

        return bool(timeElapsed > period);
    }

    function calcCourseInETH(address asset) public view returns (uint) {
        if (asset == Registry(registry).pETH()) {
            // ether always worth 1
            return 1e18;
        }

        uint power = EIP20Interface(asset).decimals();
        uint amountIn = 10**power;

        return getETHAmount(asset, amountIn);
    }

    function getETHAmount(address asset, uint amountIn) public view returns (uint) {
        address pair = assetPair[asset];

        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();

        uint power;
        uint result = cumulativePrices[pair][asset].priceAverage.mul(amountIn).decode144();

        if (token0 == WETHToken || token1 == WETHToken) {
            // asset and weth pool
            return result;
        } else {
            // asset and stable coin pool
            if (token0 == asset) {
                power = EIP20Interface(token1).decimals();
                return result.mul(getCourseInETH(token1)).div(10**power);
            } else {
                power = EIP20Interface(token0).decimals();
                return result.mul(getCourseInETH(token0)).div(10**power);
            }
        }
    }

    function searchPair(address asset) public view override returns (address, uint112) {
        address pair;
        uint112 maxReserves;

        IUniswapV2Pair tempPair;
        uint112 ETHReserves;

        uint112 stableCoinReserve;
        uint power;
        address token0;
        address token1;

        for (uint i = 0; i < poolFactories.length; i++) {
            tempPair = IUniswapV2Pair(getPoolPair(asset, i));

            if (address(tempPair) != address(0)) {
                if (tempPair.token0() == asset) {
                    (, ETHReserves, ) = tempPair.getReserves();
                } else {
                    (ETHReserves, , ) = tempPair.getReserves();
                }

                if (ETHReserves > maxReserves) {
                    maxReserves = ETHReserves;
                    pair = address(tempPair);
                }
            }

            for (uint j = 0; j < stableCoins.length; j++) {
                tempPair = IUniswapV2Pair(getPoolPairWithStableCoin(asset, i, j));

                if (address(tempPair) != address(0)) {
                    stableCoinReserve;
                    power;

                    token0 = tempPair.token0();
                    token1 = tempPair.token1();

                    if (token0 == asset) {
                        (, stableCoinReserve,) = tempPair.getReserves();
                        power = EIP20Interface(token1).decimals();
                        ETHReserves = uint112(getCourseInETH(token1) * stableCoinReserve / (10**power));
                    } else {
                        (stableCoinReserve, , ) = tempPair.getReserves();
                        power = EIP20Interface(token0).decimals();
                        ETHReserves = uint112(getCourseInETH(token0) * stableCoinReserve / (10**power));
                    }

                    if (ETHReserves > maxReserves) {
                        maxReserves = ETHReserves;
                        pair = address(tempPair);
                    }
                }
            }
        }

        return (pair, maxReserves);
    }

    function reSearchPair(address asset) public returns (uint) {
        address oldPair = assetPair[asset];
        (address newPair,) = searchPair(asset);

        if (newPair != address(0) && newPair != oldPair) {
            cumulativePrices[oldPair][asset].priceAverage._x = 0;
            cumulativePrices[oldPair][asset].priceCumulativePrevious = 0;
            cumulativePrices[oldPair][asset].blockTimeStampPrevious = 0;

            assetPair[asset] = newPair;

            emit AssetPairUpdated(asset, newPair);
        }

        return update(asset);
    }

    function _updateAssetPair(address asset, address pair) public returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.UPDATE_DATA);
        }

        require(
            asset != address(0)
            && pair != address(0)
            , 'Oracle: invalid address for asset or pair'
        );

        cumulativePrices[assetPair[asset]][asset].priceAverage._x = 0;
        cumulativePrices[assetPair[asset]][asset].priceCumulativePrevious = 0;
        cumulativePrices[assetPair[asset]][asset].blockTimeStampPrevious = 0;

        assetPair[asset] = pair;

        emit AssetPairUpdated(asset, pair);

        return update(asset);
    }

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal view returns (uint224 z) {
        z = uint224(y) * uint224(Q112); // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

library SafeCast {
    /// @notice Cast a uint256 to a uint128, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint128
    function toUint128(uint256 y) internal pure returns (uint128 z) {
        require((z = uint128(y)) == y);
    }

    /// @notice Cast a uint256 to a uint32, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint32
    function toUint32(uint256 y) internal pure returns (uint32 z) {
        require((z = uint32(y)) == y);
    }
}

interface AggregatorInterface {
    function latestAnswer() external view returns (int256);
}

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint _x;
    }

    uint8 private constant RESOLUTION = 112;

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint y) internal pure returns (uq144x112 memory) {
        uint z;
        require(y == 0 || (z = uint(self._x) * y) / y == uint(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
        return uq144x112(z);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import './Interfaces/uniswapV3/OracleLibrary.sol';
import './Interfaces/uniswapV3/PoolAddress.sol';
import './Interfaces/uniswapV3/IUniswapV3Factory.sol';
import './Interfaces/uniswapV3/LiquidityAmounts.sol';

import "./PriceOracle.sol";
import "./ErrorReporter.sol";
import "./PTokenInterfaces.sol";
import "./SafeMath.sol";
import "./UniswapV3PriceOracleStorage.sol";
import "./EIP20Interface.sol";
import "./Controller.sol";
import "./PTokenFactory.sol";

contract UniswapV3PriceOracle is UniswapCommon, UniswapV3PriceOracleStorageV1 {
    using SafeMath for uint;

    event AssetPairUpdated(address asset, address pair);

    constructor() {}

    function initialize(
        address poolFactory_,
        address WETHToken_
    )
        public
    {
        require(
            WETHToken == address(0)
            , "Oracle: may only be initialized once"
        );

        WETHToken = WETHToken_;

        require(
            poolFactory_ != address(0)
            , 'Oracle: invalid address for factory'
        );

        poolFactories.push(poolFactory_);

        feeArray.push(100);
        feeArray.push(500);
        feeArray.push(3000);
        feeArray.push(10000);

        period = 10 minutes;

        emit PoolAdded(0, poolFactory_);
    }

    function update(address asset) public override returns (uint) {
        uint reserves;
        address pair;

        if (assetPair[asset] != address(0)) {
            reserves = calcVirtualReserves(assetPair[asset], asset);
            if (reserves < minReserveLiquidity) {
                assetPair[asset] = address(0);
            }
        }

        if (assetPair[asset] == address(0)) {
            (pair, reserves) = searchPair(asset);

            if (pair == address(0)) {
                return fail(Error.UPDATE_PRICE, FailureInfo.NO_PAIR);
            }

            if (reserves > minReserveLiquidity) {
                assetPair[asset] = pair;
            } else {
                return fail(Error.UPDATE_PRICE, FailureInfo.NO_RESERVES);
            }
        }

        return uint(Error.NO_ERROR);
    }

    function getCourseInETH(address asset) public view override returns (uint) {
        if (asset == Registry(registry).pETH()) {
            // ether always worth 1
            return 1e18;
        }

        return getAveragePrice(asset);
    }

    function getAveragePrice(address asset) public view returns (uint) {
        uint assetAmount = (10 ** EIP20Interface(asset).decimals()).mul(100);

        uint price = assetToEth(asset, assetAmount);
        return price.div(100);
    }

    function assetToEth(address asset, uint256 amountIn) public view returns (uint ethAmountOut) {
        address pool;

        if (assetPair[asset] == address(0)) {
            // first update from factory or other users
            (pool,) = searchPair(asset);
        } else {
            pool = assetPair[asset];
        }

        address token0 = IUniswapV3PoolImmutables(pool).token0();
        address token1 = IUniswapV3PoolImmutables(pool).token1();

        if (token0 == WETHToken || token1 == WETHToken) {
            // asset and weth pool
            return fetchTwap(asset, amountIn, WETHToken, pool);
        } else {
            uint power;
            // asset and stable coin pool
            if (token0 == asset) {
                power = EIP20Interface(token1).decimals();
                return fetchTwap(asset, amountIn, token1, pool).mul(getCourseInETH(token1)).div(10**power);
            } else {
                power = EIP20Interface(token0).decimals();
                return fetchTwap(asset, amountIn, token0, pool).mul(getCourseInETH(token0)).div(10**power);
            }
        }
    }

    function fetchTwap(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        address pool
    ) public view returns (uint256 amountOut) {
        (int24 twapTick, ) = OracleLibrary.consult(pool, uint32(period));

        return OracleLibrary.getQuoteAtTick(twapTick, SafeCast.toUint128(amountIn), tokenIn, tokenOut);
    }

    function getMaxLiquidityPool(address tokenA, address tokenB) public view returns (address, uint) {
        address maxLiquidityPool;
        uint maxHarmonicMeanLiquidity;

        for(uint i = 0; i < poolFactories.length; i++) {
            for(uint j = 0; j < feeArray.length; j++) {
                address pool = IUniswapV3Factory(poolFactories[i]).getPool(tokenA, tokenB, feeArray[j]);

                if (pool != address(0)) {
                    (, uint128 poolHarmonicMeanLiquidity) = OracleLibrary.consult(pool, uint32(period));

                    if (poolHarmonicMeanLiquidity > maxHarmonicMeanLiquidity) {
                        maxHarmonicMeanLiquidity = poolHarmonicMeanLiquidity;
                        maxLiquidityPool = pool;
                    }
                }
            }
        }

        return (maxLiquidityPool, maxHarmonicMeanLiquidity);
    }

    function calcVirtualReserves(address pair, address asset) public view returns (uint) {
        if (pair == address(0)) {
            return 0;
        }

        uint virtualReserves;

        uint128 liquidity = IUniswapV3PoolState(pair).liquidity();
        (, int24 tick,,,,,) = IUniswapV3PoolState(pair).slot0();
        int24 tickSpacing = IUniswapV3PoolImmutables(pair).tickSpacing();

        int24 tickLow = tick / tickSpacing * tickSpacing;
        int24 tickHigh = tickLow + tickSpacing;

        uint160 sqrtPriceAX96 = TickMath.getSqrtRatioAtTick(tickLow);
        uint160 sqrtPriceBX96 = TickMath.getSqrtRatioAtTick(tickHigh);

        if (IUniswapV3PoolImmutables(pair).token0() == asset) {
            virtualReserves = LiquidityAmounts.getAmount0ForLiquidity(sqrtPriceAX96, sqrtPriceBX96, liquidity);
        } else {
            virtualReserves = LiquidityAmounts.getAmount1ForLiquidity(sqrtPriceAX96, sqrtPriceBX96, liquidity);
        }

        return virtualReserves;
    }

    function searchPair(address asset) public view override returns (address, uint112) {
        (address pair, ) = getMaxLiquidityPool(asset, WETHToken);
        uint virtualETHReserves;

        if (pair != address(0)) {
            virtualETHReserves = calcVirtualReserves(pair, asset);
        }

        address stablePair;
        uint maxStableCoinReserves;

        address tempPair;
        uint stableCoinReserves;

        for (uint i = 0; i < stableCoins.length; i++) {
            (tempPair, ) = getMaxLiquidityPool(asset, stableCoins[i]);

            if (tempPair != address(0)) {
                stableCoinReserves = calcVirtualReserves(tempPair, asset);

                if (stableCoinReserves > maxStableCoinReserves) {
                    maxStableCoinReserves = stableCoinReserves;
                    stablePair = tempPair;
                }
            }
        }

        if (stablePair != address(0)) {
            uint power;
            uint calcETHReserves;

            address token0 = IUniswapV3PoolImmutables(stablePair).token0();
            address token1 = IUniswapV3PoolImmutables(stablePair).token1();

            if (token0 == asset) {
                power = EIP20Interface(token1).decimals();
                calcETHReserves = getCourseInETH(token1).mul(maxStableCoinReserves).div(10**power);
            } else {
                power = EIP20Interface(token0).decimals();
                calcETHReserves = getCourseInETH(token0).mul(maxStableCoinReserves).div(10**power);
            }

            if (calcETHReserves > virtualETHReserves) {
                pair = stablePair;
                virtualETHReserves = calcETHReserves;
            }
        }

        return (pair, uint112(virtualETHReserves));
    }

    function reSearchPair(address asset) public returns (uint) {
        address oldPair = assetPair[asset];
        (address newPair,) = searchPair(asset);

        if (newPair != address(0) && newPair != oldPair) {
            assetPair[asset] = newPair;

            emit AssetPairUpdated(asset, newPair);
        }

        return uint(Error.NO_ERROR);
    }

    function _updateAssetPair(address asset, address pair) public returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.UPDATE_DATA);
        }

        require(
            pair != address(0)
            && asset != address(0)
            , 'Oracle: invalid address for asset or pair'
        );

        assetPair[asset] = pair;

        emit AssetPairUpdated(asset, pair);

        return update(asset);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./PriceOracle.sol";
import './RegistryInterface.sol';
import "./ErrorReporter.sol";
import "./Interfaces/IPriceFeeds.sol";
import "./PTokenInterfaces.sol";
import "./EIP20Interface.sol";
import "./SafeMath.sol";
import "./UniswapCommon.sol";
import "./PriceOracleProxy.sol";

abstract contract PriceOracleCore {
    /**
      * @notice Get the underlying price of a pToken asset
      * @param pToken The pToken to get the underlying price of
      * @return The underlying asset price mantissa (scaled by 1e18).
      *  Zero means the price is unavailable.
      */
    function getUnderlyingPrice(address pToken) external view virtual returns (uint);

    function updateUnderlyingPrice(address pToken) external virtual returns (uint);
}

contract PriceOracle is PriceOracleProxyStorage, PriceOracleCore, OracleErrorReporter {
    using SafeMath for uint;

    address public ETHUSDPriceFeed;

    address[] public priceOracles;

    mapping(address => address) public assetOracle;

    event OracleAdded(uint oracleId, address oracle);
    event OracleRemoved(uint oracleId, address oracle);
    event OracleUpdated(uint oracleId, address oracle);

    event PriceUpdated(address oracle, address asset, uint price);
    event AssetOracleUpdated(address oracle, address asset);

    function initialize(
        address ETHUSDPriceFeed_
    ) public {
        require(
            ETHUSDPriceFeed == address(0),
            "Oracle: may only be initialized once"
        );

        require(
            ETHUSDPriceFeed_ != address(0),
            "Oracle: address is not correct"
        );

        ETHUSDPriceFeed = ETHUSDPriceFeed_;
    }

    function updateUnderlyingPrice(address pToken) external override returns (uint) {
        if (pToken == RegistryInterface(registry).pETH()) {
            return uint(Error.NO_ERROR);
        }

        address asset = PErc20Interface(pToken).underlying();

        return update(asset);
    }

    function update(address asset) public returns (uint) {
        address oracle = assetOracle[asset];

        if (oracle == address(0)) {
            (oracle,,) = searchPair(asset);
        }

        if (oracle != address(0)) {
            if (assetOracle[asset] == address(0)) {
                assetOracle[asset] = oracle;
            }

            uint result = UniswapCommon(oracle).update(asset);

            if (result == uint(Error.NO_ERROR)) {
                emit AssetOracleUpdated(oracle, asset);
                emit PriceUpdated(oracle, asset, UniswapCommon(oracle).getCourseInETH(asset));
            }

            return result;
        }

        return fail(Error.UPDATE_PRICE, FailureInfo.NO_PAIR);
    }

    function reSearchPair(address asset) public returns (uint) {
        (address oracle,,) = searchPair(asset);

        if (oracle != address(0) && oracle != assetOracle[asset]) {
            assetOracle[asset] = oracle;
        }

        return update(asset);
    }

    function getPriceInUSD(address asset) public view virtual returns (uint) {
        uint ETHUSDPrice = uint(AggregatorInterface(ETHUSDPriceFeed).latestAnswer());
        uint AssetETHCourse = getPriceInETH(asset);

        // div 1e8 is chainlink precision for ETH
        return ETHUSDPrice.mul(AssetETHCourse).div(1e8);
    }

    function getPriceInETH(address asset) public view returns(uint) {
        if (asset == RegistryInterface(registry).pETH()) {
            // ether always worth 1
            return 1e18;
        }

        address oracle = assetOracle[asset];
        if (oracle == address(0)) {
            return 0;
        }

        return UniswapCommon(oracle).getCourseInETH(asset);
    }

    function getUnderlyingPrice(address pToken) public view override virtual returns (uint) {
        if (pToken == RegistryInterface(registry).pETH()) {
            return getPriceInUSD(pToken);
        }

        address asset = PErc20Interface(pToken).underlying();
        uint price = getPriceInUSD(asset);
        uint decimals = EIP20Interface(asset).decimals();

        return price.mul(10 ** (36 - decimals)).div(1e18);
    }

    function searchPair(address asset) public view returns (address, address, uint112) {
        address pair;
        uint112 liquidity;
        address maxLiquidityPair;
        uint112 maxLiquidity;
        address oracle;

        for(uint i = 0; i < priceOracles.length; i++) {
            (pair, liquidity) = UniswapCommon(priceOracles[i]).searchPair(asset);

            if (pair != address(0) && liquidity > maxLiquidity) {
                maxLiquidityPair = pair;
                maxLiquidity = liquidity;
                oracle = priceOracles[i];
            }
        }

        return (oracle, maxLiquidityPair, maxLiquidity);
    }

    function getMyAdmin() public view returns (address) {
        return RegistryInterface(registry).admin();
    }

    function _addOracle(address oracle_) public returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ADD_ORACLE);
        }

        require(
            oracle_ != address(0)
            , 'PriceOracle: invalid address for oracle'
        );

        for (uint i = 0; i < priceOracles.length; i++) {
            if (priceOracles[i] == oracle_) {
                return fail(Error.ORACLE_EXIST, FailureInfo.ADD_ORACLE);
            }
        }

        priceOracles.push(oracle_);

        emit OracleAdded(priceOracles.length - 1, oracle_);

        return uint(Error.NO_ERROR);
    }

    function _removeOracle(uint oracleId) public returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.UPDATE_DATA);
        }

        require(
            priceOracles.length > oracleId
            , 'PriceOracle: oracleId is not correct'
        );

        uint lastId = priceOracles.length - 1;

        address lastOracle = priceOracles[lastId];
        priceOracles.pop();
        emit OracleRemoved(oracleId, lastOracle);

        if (lastId != oracleId) {
            priceOracles[oracleId] = lastOracle;
            emit OracleUpdated(oracleId, lastOracle);
        }

        return uint(Error.NO_ERROR);
    }

    function _updateOracle(uint oracleId, address oracle_) public returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.UPDATE_DATA);
        }

        require(
            oracle_ != address(0)
            , 'PriceOracle: invalid address for oracle_'
        );

        for (uint i = 0; i < priceOracles.length; i++) {
            if (priceOracles[i] == oracle_) {
                return fail(Error.ORACLE_EXIST, FailureInfo.ADD_ORACLE);
            }
        }

        priceOracles[oracleId] = oracle_;

        emit OracleUpdated(oracleId, oracle_);

        return uint(Error.NO_ERROR);
    }

    function _updateAssetOracle(address oracle, address asset) public returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.UPDATE_DATA);
        }

        require(
            oracle != address(0)
            && asset != address(0)
            , 'Oracle: invalid address oracle or asset'
        );

        assetOracle[asset] = oracle;

        return update(asset);
    }

    function getAllPriceOracles() public view returns (address[] memory) {
        return priceOracles;
    }

    function getPriceOraclesLength() public view returns (uint) {
        return priceOracles.length;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

contract ControllerErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        CONTROLLER_MISMATCH,
        INSUFFICIENT_SHORTFALL,
        INSUFFICIENT_LIQUIDITY,
        INVALID_CLOSE_FACTOR,
        INVALID_COLLATERAL_FACTOR,
        INVALID_LIQUIDATION_INCENTIVE,
        MARKET_NOT_LISTED,
        MARKET_ALREADY_LISTED,
        MATH_ERROR,
        NONZERO_BORROW_BALANCE,
        PRICE_ERROR,
        REJECTION,
        GUARDIAN_REJECTION,
        SNAPSHOT_ERROR,
        TOO_MANY_ASSETS,
        TOO_MUCH_REPAY
    }

    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK,
        EXIT_MARKET_BALANCE_OWED,
        EXIT_MARKET_REJECTION,
        SET_CLOSE_FACTOR_OWNER_CHECK,
        SET_CLOSE_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_OWNER_CHECK,
        SET_COLLATERAL_FACTOR_NO_EXISTS,
        SET_COLLATERAL_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_WITHOUT_PRICE,
        SET_LIQUIDATION_INCENTIVE_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_VALIDATION,
        SET_MAX_ASSETS_OWNER_CHECK,
        SET_GUARDIAN_OWNER_CHECK,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_PENDING_IMPLEMENTATION_OWNER_CHECK,
        SUPPORT_MARKET_EXISTS,
        SUPPORT_MARKET_OWNER_CHECK,
        SET_FEE_FACTOR,
        SET_MAX_FEE_FACTOR,
        SET_BORROW_DELAY_OWNER_CHECK
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }

    /**
      * @dev use this when reporting an opaque error from an upgradeable collaborator contract
      */
    function failOpaque(Error err, FailureInfo info, uint opaqueError) internal returns (uint) {
        emit Failure(uint(err), uint(info), opaqueError);

        return uint(err);
    }
}

contract TokenErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        BAD_INPUT,
        CONTROLLER_REJECTION,
        INVALID_ACCOUNT_PAIR,
        INVALID_CLOSE_AMOUNT_REQUESTED,
        MATH_ERROR,
        MARKET_NOT_FRESH,
        TOKEN_INSUFFICIENT_CASH
    }

    /*
     * Note: FailureInfo (but not Error) is kept in alphabetical order
     *       This is because FailureInfo grows significantly faster, and
     *       the order of Error has some meaning, while the order of FailureInfo
     *       is entirely arbitrary.
     */
    enum FailureInfo {
        ACCRUE_INTEREST_ACCUMULATED_INTEREST_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_BORROW_INDEX_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_TOTAL_BORROWS_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_TOTAL_RESERVES_CALCULATION_FAILED,
        ACCRUE_INTEREST_SIMPLE_INTEREST_FACTOR_CALCULATION_FAILED,
        BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        BORROW_ACCRUE_INTEREST_FAILED,
        BORROW_CASH_NOT_AVAILABLE,
        BORROW_FRESHNESS_CHECK,
        BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
        BORROW_CONTROLLER_REJECTION,
        LIQUIDATE_ACCRUE_BORROW_INTEREST_FAILED,
        LIQUIDATE_ACCRUE_COLLATERAL_INTEREST_FAILED,
        LIQUIDATE_COLLATERAL_FRESHNESS_CHECK,
        LIQUIDATE_CONTROLLER_REJECTION,
        LIQUIDATE_CONTROLLER_CALCULATE_AMOUNT_SEIZE_FAILED,
        LIQUIDATE_CLOSE_AMOUNT_IS_UINT_MAX,
        LIQUIDATE_CLOSE_AMOUNT_IS_ZERO,
        LIQUIDATE_FRESHNESS_CHECK,
        LIQUIDATE_LIQUIDATOR_IS_BORROWER,
        LIQUIDATE_REPAY_BORROW_FRESH_FAILED,
        LIQUIDATE_SEIZE_BALANCE_INCREMENT_FAILED,
        LIQUIDATE_SEIZE_BALANCE_DECREMENT_FAILED,
        LIQUIDATE_SEIZE_CONTROLLER_REJECTION,
        LIQUIDATE_SEIZE_LIQUIDATOR_IS_BORROWER,
        LIQUIDATE_SEIZE_TOO_MUCH,
        MINT_ACCRUE_INTEREST_FAILED,
        MINT_CONTROLLER_REJECTION,
        MINT_EXCHANGE_CALCULATION_FAILED,
        MINT_EXCHANGE_RATE_READ_FAILED,
        MINT_FRESHNESS_CHECK,
        MINT_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
        MINT_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        REDEEM_ACCRUE_INTEREST_FAILED,
        REDEEM_CONTROLLER_REJECTION,
        REDEEM_EXCHANGE_TOKENS_CALCULATION_FAILED,
        REDEEM_EXCHANGE_AMOUNT_CALCULATION_FAILED,
        REDEEM_EXCHANGE_RATE_READ_FAILED,
        REDEEM_FRESHNESS_CHECK,
        REDEEM_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
        REDEEM_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        REDEEM_TRANSFER_OUT_NOT_POSSIBLE,
        REDUCE_RESERVES_ACCRUE_INTEREST_FAILED,
        REDUCE_RESERVES_ADMIN_CHECK,
        REDUCE_RESERVES_CASH_NOT_AVAILABLE,
        REDUCE_RESERVES_FRESH_CHECK,
        REDUCE_RESERVES_VALIDATION,
        REPAY_BEHALF_ACCRUE_INTEREST_FAILED,
        REPAY_BORROW_ACCRUE_INTEREST_FAILED,
        REPAY_BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_CONTROLLER_REJECTION,
        REPAY_BORROW_FRESHNESS_CHECK,
        REPAY_BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        SET_CONTROLLER_OWNER_CHECK,
        SET_INTEREST_RATE_MODEL_ACCRUE_INTEREST_FAILED,
        SET_INTEREST_RATE_MODEL_FRESH_CHECK,
        SET_INTEREST_RATE_MODEL_OWNER_CHECK,
        SET_RESERVE_FACTOR_ACCRUE_INTEREST_FAILED,
        SET_RESERVE_FACTOR_ADMIN_CHECK,
        SET_RESERVE_FACTOR_FRESH_CHECK,
        SET_RESERVE_FACTOR_BOUNDS_CHECK,
        TRANSFER_CONTROLLER_REJECTION,
        TRANSFER_NOT_ALLOWED,
        TRANSFER_NOT_ENOUGH,
        TRANSFER_TOO_MUCH,
        ADD_RESERVES_ACCRUE_INTEREST_FAILED,
        ADD_RESERVES_FRESH_CHECK,
        SET_NEW_IMPLEMENTATION
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }

    /**
      * @dev use this when reporting an opaque error from an upgradeable collaborator contract
      */
    function failOpaque(Error err, FailureInfo info, uint opaqueError) internal returns (uint) {
        emit Failure(uint(err), uint(info), opaqueError);

        return uint(err);
    }
}

contract OracleErrorReporter {
    enum Error {
        NO_ERROR,
        POOL_OR_COIN_EXIST,
        ORACLE_EXIST,
        UNAUTHORIZED,
        UPDATE_PRICE
    }

    enum FailureInfo {
        ADD_ORACLE,
        ADD_POOL_OR_COIN,
        NO_PAIR,
        NO_RESERVES,
        PERIOD_NOT_ELAPSED,
        SET_NEW_IMPLEMENTATION,
        UPDATE_DATA
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }
}

contract FactoryErrorReporter {
    enum Error {
        NO_ERROR,
        INVALID_POOL,
        MARKET_NOT_LISTED,
        UNAUTHORIZED
    }

    enum FailureInfo {
        CREATE_PETH_POOL,
        CREATE_PPIE_POOL,
        DEFICIENCY_LIQUIDITY_IN_POOL_OR_PAIR_IS_NOT_EXIST,
        SET_MIN_LIQUIDITY_OWNER_CHECK,
        SET_NEW_CONTROLLER,
        SET_NEW_DECIMALS,
        SET_NEW_EXCHANGE_RATE,
        SET_NEW_INTEREST_RATE_MODEL,
        SET_NEW_RESERVE_FACTOR,
        SUPPORT_MARKET_BAD_RESULT,
        ADD_UNDERLYING_TO_BLACKLIST,
        REMOVE_UNDERLYING_FROM_BLACKLIST,
        UNDERLYING_IN_BLACKLIST
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }
}

contract RegistryErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED
    }

    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        SET_NEW_IMPLEMENTATION,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_NEW_FACTORY,
        SET_NEW_ORACLE
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./ControllerInterface.sol";
import "./InterestRateModel.sol";
import "./ProxyWithRegistry.sol";

contract PTokenStorage is ProxyWithRegistryStorage {
    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;

    /**
     * @notice EIP-20 token name for this token
     */
    string public name;

    /**
     * @notice EIP-20 token symbol for this token
     */
    string public symbol;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public decimals;

    /**
     * @dev Maximum borrow rate that can ever be applied (.0005% / block)
     */

    uint internal constant borrowRateMaxMantissa = 0.0005e16;

    /**
     * @dev Maximum fraction of interest that can be set aside for reserves
     */
    uint internal constant reserveFactorMaxMantissa = 1e18;

    /**
     * @notice Contract which oversees inter-pToken operations
     */
    ControllerInterface public controller;

    /**
     * @notice Model which tells what the current interest rate should be
     */
    InterestRateModel public interestRateModel;

    /**
     * @dev Initial exchange rate used when minting the first PTokens (used when totalSupply = 0)
     */
    uint internal initialExchangeRateMantissa;

    /**
     * @notice Fraction of interest currently set aside for reserves
     */
    uint public reserveFactorMantissa;

    /**
     * @notice Block number that interest was last accrued at
     */
    uint public accrualBlockNumber;

    /**
     * @notice Accumulator of the total earned interest rate since the opening of the market
     */
    uint public borrowIndex;

    /**
     * @notice Total amount of outstanding borrows of the underlying in this market
     */
    uint public totalBorrows;

    /**
     * @notice Total amount of reserves of the underlying held in this market
     */
    uint public totalReserves;

    /**
     * @notice Total number of tokens in circulation
     */
    uint public totalSupply;

    /**
     * @dev Official record of token balances for each account
     */
    mapping (address => uint) internal accountTokens;

    /**
     * @dev Approved token transfer amounts on behalf of others
     */
    mapping (address => mapping (address => uint)) internal transferAllowances;

    /**
     * @notice Container for borrow balance information
     * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @member interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint principal;
        uint interestIndex;
    }

    /**
     * @dev Mapping of account addresses to outstanding borrow balances
     */
    mapping(address => BorrowSnapshot) internal accountBorrows;
}

abstract contract PTokenInterface is PTokenStorage {
    /**
     * @notice Indicator that this is a PToken contract (for inspection)
     */
    bool public constant isPToken = true;


    /*** Market Events ***/

    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(uint cashPrior, uint interestAccumulated, uint borrowIndex, uint totalBorrows, uint totalReserves);

    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(address minter, uint mintAmount, uint mintTokens);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint redeemAmount, uint redeemTokens);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, uint borrowAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(address payer, address borrower, uint repayAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(address liquidator, address borrower, uint repayAmount, address pTokenCollateral, uint seizeTokens);


    /*** Admin Events ***/

    /**
     * @notice Event emitted when controller is changed
     */
    event NewController(ControllerInterface oldController, ControllerInterface newController);

    /**
     * @notice Event emitted when interestRateModel is changed
     */
    event NewMarketInterestRateModel(InterestRateModel oldInterestRateModel, InterestRateModel newInterestRateModel);

    /**
     * @notice Event emitted when the reserve factor is changed
     */
    event NewReserveFactor(uint oldReserveFactorMantissa, uint newReserveFactorMantissa);

    /**
     * @notice Event emitted when the reserves are added
     */
    event ReservesAdded(address benefactor, uint addAmount, uint newTotalReserves);

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(address admin, uint reduceAmount, uint newTotalReserves);

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(address indexed owner, address indexed spender, uint amount);

    /*** User Interface ***/

    function transfer(address dst, uint amount) external virtual returns (bool);
    function transferFrom(address src, address dst, uint amount) external virtual returns (bool);
    function approve(address spender, uint amount) external virtual returns (bool);
    function allowance(address owner, address spender) external view virtual returns (uint);
    function balanceOf(address owner) external view virtual returns (uint);
    function balanceOfUnderlying(address owner) external virtual returns (uint);
    function getAccountSnapshot(address account) external view virtual returns (uint, uint, uint, uint);
    function borrowRatePerBlock() external view virtual returns (uint);
    function supplyRatePerBlock() external view virtual returns (uint);
    function totalBorrowsCurrent() external virtual returns (uint);
    function borrowBalanceCurrent(address account) external virtual returns (uint);
    function borrowBalanceStored(address account) public view virtual returns (uint);
    function exchangeRateCurrent() public virtual returns (uint);
    function exchangeRateStored() public view virtual returns (uint);
    function getCash() external view virtual returns (uint);
    function accrueInterest() public virtual returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) external virtual returns (uint);

    /*** Admin Functions ***/

    function _setController(ControllerInterface newController) public virtual returns (uint);
    function _setReserveFactor(uint newReserveFactorMantissa) external virtual returns (uint);
    function _reduceReserves(uint reduceAmount) external virtual returns (uint);
    function _setInterestRateModel(InterestRateModel newInterestRateModel) public virtual returns (uint);
}

contract PErc20Storage {
    /**
     * @notice Underlying asset for this PToken
     */
    address public underlying;
}

abstract contract PErc20Interface is PErc20Storage {

    /*** User Interface ***/

    function mint(uint mintAmount) external virtual returns (uint);
    function redeem(uint redeemTokens) external virtual returns (uint);
    function redeemUnderlying(uint redeemAmount) external virtual returns (uint);
    function borrow(uint borrowAmount) external virtual returns (uint);
    function repayBorrow(uint repayAmount) external virtual returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external virtual returns (uint);
    function liquidateBorrow(address borrower, uint repayAmount, PTokenInterface pTokenCollateral) external virtual returns (uint);

    /*** Admin Functions ***/

    function _addReserves(uint addAmount) external virtual returns (uint);
}

contract PEer20ExtStorage {
    /**
     * @notice start borrow timestamp
     */
    uint public startBorrowTimestamp;
}

abstract contract PErc20ExtInterface is PEer20ExtStorage {

}


contract PPIEStorage {
    /// @notice A record of each accounts delegate
    mapping (address => address) public delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;
}

abstract contract PPIEInterface is PPIEStorage {
    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    function delegate(address delegatee) external virtual;
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) external virtual;
    function getCurrentVotes(address account) external view virtual returns (uint96);
    function getPriorVotes(address account, uint blockNumber) external view virtual returns (uint96);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import './Registry.sol';
import "./Interfaces/IPriceFeeds.sol";

contract UniswapV2PriceOracleStorageV1 {
    uint public Q112;

    struct PoolCumulativePrice {
        FixedPoint.uq112x112 priceAverage;
        uint priceCumulativePrevious;
        uint32 blockTimeStampPrevious;
    }

    // asset => assetPair => data from pool
    mapping(address => mapping (address => PoolCumulativePrice)) public cumulativePrices;
    mapping(address => uint) public averagePrices;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

/**
 * @title ERC 20 Token Standard Interface
 *  https://eips.ethereum.org/EIPS/eip-20
 */
interface EIP20Interface {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    /**
      * @notice Get the total number of tokens in circulation
      * @return The supply of tokens
      */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return Whether or not the transfer succeeded
      */
    function transfer(address dst, uint256 amount) external returns (bool);

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return Whether or not the transfer succeeded
      */
    function transferFrom(address src, address dst, uint256 amount) external returns (bool);

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved (-1 means infinite)
      * @return Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return The number of tokens allowed to be spent (-1 means infinite)
      */
    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./ErrorReporter.sol";
import "./Exponential.sol";
import "./PriceOracle.sol";
import "./ControllerInterface.sol";
import "./ControllerStorage.sol";
import "./PTokenInterfaces.sol";
import "./PTokenFactory.sol";
import "./EIP20Interface.sol";
import "./Unitroller.sol";

/**
 * @title DeFiPie's Controller Contract
 * @author DeFiPie
 */
contract Controller is ControllerStorage, ControllerInterface, ControllerErrorReporter, Exponential {
    /// @notice Emitted when an admin supports a market
    event MarketListed(address pToken);

    /// @notice Emitted when an account enters a market
    event MarketEntered(address pToken, address account);

    /// @notice Emitted when an account exits a market
    event MarketExited(address pToken, address account);

    /// @notice Emitted when close factor is changed by admin
    event NewCloseFactor(uint oldCloseFactorMantissa, uint newCloseFactorMantissa);

    /// @notice Emitted when a collateral factor is changed by admin
    event NewCollateralFactor(address pToken, uint oldCollateralFactorMantissa, uint newCollateralFactorMantissa);

    /// @notice Event emitted when the fee factor max is changed
    event NewFeeFactorMaxMantissa(uint oldFeeFactorMaxMantissa, uint newFeeFactorMaxMantissa);

    /// @notice Event emitted when the fee factor is changed
    event NewFeeFactor(address pToken, uint oldFeeFactorMantissa, uint newFeeFactorMantissa);

    /// @notice Event emitted when the borrow delay is changed
    event NewBorrowDelay(uint oldBorrowDelay, uint newBorrowDelay);

    /// @notice Emitted when liquidation incentive is changed by admin
    event NewLiquidationIncentive(uint oldLiquidationIncentiveMantissa, uint newLiquidationIncentiveMantissa);

    /// @notice Emitted when maxAssets is changed by admin
    event NewMaxAssets(uint oldMaxAssets, uint newMaxAssets);

    /// @notice Emitted when price oracle is changed
    event NewPriceOracle(PriceOracle oldPriceOracle, PriceOracle newPriceOracle);

    /// @notice Emitted when pause guardian is changed
    event NewPauseGuardian(address oldPauseGuardian, address newPauseGuardian);

    /// @notice Emitted when pause guardian is changed
    event NewLiquidateGuardian(address oldLiquidateGuardian, address newLiquidateGuardian);

    /// @notice Emitted when an action is paused globally
    event ActionPaused(string action, bool pauseState);

    /// @notice Emitted when an action is paused on a market
    event ActionPaused(address pToken, string action, bool pauseState);

    /// @notice Emitted when a new PIE speed is calculated for a market
    event PieSpeedUpdated(address indexed pToken, uint newSpeed);

    /// @notice Emitted when PIE is distributed to a supplier
    event DistributedSupplierPie(address indexed pToken, address indexed supplier, uint pieDelta, uint pieSupplyIndex);

    /// @notice Emitted when PIE is distributed to a borrower
    event DistributedBorrowerPie(address indexed pToken, address indexed borrower, uint pieDelta, uint pieBorrowIndex);

    /// @notice The threshold above which the flywheel transfers PIE, in wei
    uint public constant pieClaimThreshold = 0.001e18;

    /// @notice The initial PIE index for a market
    uint224 public constant pieInitialIndex = 1e36;

    // closeFactorMantissa must be strictly greater than this value
    uint internal constant closeFactorMinMantissa = 0.05e18; // 0.05

    // closeFactorMantissa must not exceed this value
    uint internal constant closeFactorMaxMantissa = 0.9e18; // 0.9

    // No collateralFactorMantissa may exceed this value
    uint internal constant collateralFactorMaxMantissa = 0.9e18; // 0.9

    // liquidationIncentiveMantissa must be no less than this value
    uint internal constant liquidationIncentiveMinMantissa = 1.0e18; // 1.0

    // liquidationIncentiveMantissa must be no greater than this value
    uint internal constant liquidationIncentiveMaxMantissa = 1.5e18; // 1.5

    constructor() {}

    /*** Assets You Are In ***/

    /**
     * @notice Returns the assets an account has entered
     * @param account The address of the account to pull assets for
     * @return A dynamic list with the assets the account has entered
     */
    function getAssetsIn(address account) external view returns (address[] memory) {
        address[] memory assetsIn = accountAssets[account];

        return assetsIn;
    }

    /**
     * @notice Returns whether the given account is entered in the given asset
     * @param account The address of the account to check
     * @param pToken The pToken to check
     * @return True if the account is in the asset, otherwise false.
     */
    function checkMembership(address account, address pToken) external view returns (bool) {
        return markets[pToken].accountMembership[account];
    }

    /**
     * @notice Add assets to be included in account liquidity calculation
     * @param pTokens The list of addresses of the pToken markets to be enabled
     * @return Success indicator for whether each corresponding market was entered
     */
    function enterMarkets(address[] memory pTokens) public override returns (uint[] memory) {
        uint len = pTokens.length;

        uint[] memory results = new uint[](len);
        for (uint i = 0; i < len; i++) {
            address pToken = pTokens[i];

            results[i] = uint(addToMarketInternal(pToken, msg.sender));
        }

        return results;
    }

    /**
     * @notice Add the market to the borrower's "assets in" for liquidity calculations
     * @param pToken The market to enter
     * @param borrower The address of the account to modify
     * @return Success indicator for whether the market was entered
     */
    function addToMarketInternal(address pToken, address borrower) internal returns (Error) {
        Market storage marketToJoin = markets[pToken];

        if (!marketToJoin.isListed) {
            // market is not listed, cannot join
            return Error.MARKET_NOT_LISTED;
        }

        if (marketToJoin.accountMembership[borrower] == true) {
            // already joined
            return Error.NO_ERROR;
        }

        if (accountAssets[borrower].length >= maxAssets)  {
            // no space, cannot join
            return Error.TOO_MANY_ASSETS;
        }

        // survived the gauntlet, add to list
        // NOTE: we store these somewhat redundantly as a significant optimization
        //  this avoids having to iterate through the list for the most common use cases
        //  that is, only when we need to perform liquidity checks
        //  and not whenever we want to check if an account is in a particular market
        marketToJoin.accountMembership[borrower] = true;
        accountAssets[borrower].push(pToken);

        emit MarketEntered(pToken, borrower);

        return Error.NO_ERROR;
    }

    /**
     * @notice Removes asset from sender's account liquidity calculation
     * @dev Sender must not have an outstanding borrow balance in the asset,
     *  or be providing neccessary collateral for an outstanding borrow.
     * @param pTokenAddress The address of the asset to be removed
     * @return Whether or not the account successfully exited the market
     */
    function exitMarket(address pTokenAddress) external override returns (uint) {
        address pToken = pTokenAddress;
        /* Get sender tokensHeld and amountOwed underlying from the pToken */
        (uint oErr, uint tokensHeld, uint amountOwed, ) = PTokenInterface(pToken).getAccountSnapshot(msg.sender);
        require(oErr == 0, "exitMarket: getAccountSnapshot failed"); // semi-opaque error code

        /* Fail if the sender has a borrow balance */
        if (amountOwed != 0) {
            return fail(Error.NONZERO_BORROW_BALANCE, FailureInfo.EXIT_MARKET_BALANCE_OWED);
        }

        /* Fail if the sender is not permitted to redeem all of their tokens */
        uint allowed = redeemAllowedInternal(pTokenAddress, msg.sender, tokensHeld);
        if (allowed != 0) {
            return failOpaque(Error.REJECTION, FailureInfo.EXIT_MARKET_REJECTION, allowed);
        }

        Market storage marketToExit = markets[pToken];

        /* Return true if the sender is not already ‘in’ the market */
        if (!marketToExit.accountMembership[msg.sender]) {
            return uint(Error.NO_ERROR);
        }

        /* Set pToken account membership to false */
        delete marketToExit.accountMembership[msg.sender];

        /* Delete pToken from the account’s list of assets */
        // load into memory for faster iteration
        address[] memory userAssetList = accountAssets[msg.sender];
        uint len = userAssetList.length;
        uint assetIndex = len;
        for (uint i = 0; i < len; i++) {
            if (userAssetList[i] == pToken) {
                assetIndex = i;
                break;
            }
        }

        // We *must* have found the asset in the list or our redundant data structure is broken
        assert(assetIndex < len);

        // copy last item in list to location of item to be removed, reduce length by 1
        address[] storage storedList = accountAssets[msg.sender];
        storedList[assetIndex] = storedList[storedList.length - 1];
        storedList.pop(); //storedList.length--;

        emit MarketExited(pToken, msg.sender);

        return uint(Error.NO_ERROR);
    }

    /*** Policy Hooks ***/

    /**
     * @notice Checks if the account should be allowed to mint tokens in the given market
     * @param pToken The market to verify the mint against
     * @param minter The account which would get the minted tokens
     * @param mintAmount The amount of underlying being supplied to the market in exchange for tokens
     * @return 0 if the mint is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function mintAllowed(address pToken, address minter, uint mintAmount) external override returns (uint) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!mintGuardianPaused[pToken], "mint is paused");

        // Shh - currently unused
        minter;
        mintAmount;

        if (!markets[pToken].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        // Keep the flywheel moving
        updatePieSupplyIndex(pToken);
        distributeSupplierPie(pToken, minter, false);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Checks if the account should be allowed to redeem tokens in the given market
     * @param pToken The market to verify the redeem against
     * @param redeemer The account which would redeem the tokens
     * @param redeemTokens The number of pTokens to exchange for the underlying asset in the market
     * @return 0 if the redeem is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function redeemAllowed(address pToken, address redeemer, uint redeemTokens) external override returns (uint) {
        uint allowed = redeemAllowedInternal(pToken, redeemer, redeemTokens);
        if (allowed != uint(Error.NO_ERROR)) {
            return allowed;
        }

        // Keep the flywheel moving
        updatePieSupplyIndex(pToken);
        distributeSupplierPie(pToken, redeemer, false);

        return uint(Error.NO_ERROR);
    }

    function redeemAllowedInternal(address pToken, address redeemer, uint redeemTokens) internal view returns (uint) {
        if (!markets[pToken].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        /* If the redeemer is not 'in' the market, then we can bypass the liquidity check */
        if (!markets[pToken].accountMembership[redeemer]) {
            return uint(Error.NO_ERROR);
        }

        /* Otherwise, perform a hypothetical liquidity check to guard against shortfall */
        (Error err, , uint shortfall) = getHypotheticalAccountLiquidityInternal(redeemer, pToken, redeemTokens, 0);
        if (err != Error.NO_ERROR) {
            return uint(err);
        }
        if (shortfall > 0) {
            return uint(Error.INSUFFICIENT_LIQUIDITY);
        }

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Validates redeem and reverts on rejection. May emit logs.
     * @param pToken Asset being redeemed
     * @param redeemer The address redeeming the tokens
     * @param redeemAmount The amount of the underlying asset being redeemed
     * @param redeemTokens The number of tokens being redeemed
     */
    function redeemVerify(address pToken, address redeemer, uint redeemAmount, uint redeemTokens) external override {
        // Shh - currently unused
        pToken;
        redeemer;

        // Require tokens is zero or amount is also zero
        if (redeemTokens == 0 && redeemAmount > 0) {
            revert("redeemTokens zero");
        }
    }

    /**
     * @notice Checks if the account should be allowed to borrow the underlying asset of the given market
     * @param pToken The market to verify the borrow against
     * @param borrower The account which would borrow the asset
     * @param borrowAmount The amount of underlying the account would borrow
     * @return 0 if the borrow is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function borrowAllowed(address pToken, address borrower, uint borrowAmount) external override returns (uint) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!borrowGuardianPaused[pToken], "borrow is paused");

        if (!markets[pToken].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        Error err;

        if (!markets[pToken].accountMembership[borrower]) {
            // only pTokens may call borrowAllowed if borrower not in market
            require(msg.sender == pToken, "sender must be pToken");

            // attempt to add borrower to the market
            err = addToMarketInternal(msg.sender, borrower);
            if (err != Error.NO_ERROR) {
                return uint(err);
            }

            // it should be impossible to break the important invariant
            assert(markets[pToken].accountMembership[borrower]);
        }

        if (getOracle().getUnderlyingPrice(pToken) == 0) {
            return uint(Error.PRICE_ERROR);
        }

        uint shortfall;

        (err, , shortfall) = getHypotheticalAccountLiquidityInternal(borrower, pToken, 0, borrowAmount);
        if (err != Error.NO_ERROR) {
            return uint(err);
        }
        if (shortfall > 0) {
            return uint(Error.INSUFFICIENT_LIQUIDITY);
        }

        // Keep the flywheel moving
        Exp memory borrowIndex = Exp({mantissa: PTokenInterface(pToken).borrowIndex()});
        updatePieBorrowIndex(pToken, borrowIndex);
        distributeBorrowerPie(pToken, borrower, borrowIndex, false);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Checks if the account should be allowed to repay a borrow in the given market
     * @param pToken The market to verify the repay against
     * @param payer The account which would repay the asset
     * @param borrower The account which would borrowed the asset
     * @param repayAmount The amount of the underlying asset the account would repay
     * @return 0 if the repay is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function repayBorrowAllowed(
        address pToken,
        address payer,
        address borrower,
        uint repayAmount
    ) external override returns (uint) {
        // Shh - currently unused
        payer;
        borrower;
        repayAmount;

        if (!markets[pToken].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        // Keep the flywheel moving
        Exp memory borrowIndex = Exp({mantissa: PTokenInterface(pToken).borrowIndex()});
        updatePieBorrowIndex(pToken, borrowIndex);
        distributeBorrowerPie(pToken, borrower, borrowIndex, false);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Checks if the liquidation should be allowed to occur
     * @param pTokenBorrowed Asset which was borrowed by the borrower
     * @param pTokenCollateral Asset which was used as collateral and will be seized
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param repayAmount The amount of underlying being repaid
     */
    function liquidateBorrowAllowed(
        address pTokenBorrowed,
        address pTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount
    ) external override returns (uint) {
        if (!markets[pTokenBorrowed].isListed || !markets[pTokenCollateral].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        /* The borrower must have shortfall(sumCollateral < sumBorrowPlusEffects) in order to be liquidatable */
        (Error err, uint sumCollateral, uint sumBorrowPlusEffects, uint sumDeposit) = calcHypotheticalAccountLiquidityInternal(borrower, address(0), 0, 0);
        if (err != Error.NO_ERROR) {
            return uint(err);
        }
        if (sumCollateral >= sumBorrowPlusEffects) {
            return uint(Error.INSUFFICIENT_SHORTFALL);
        }

        /* The liquidator may not repay more than what is allowed by the closeFactor */
        uint borrowBalance = PTokenInterface(pTokenBorrowed).borrowBalanceStored(borrower);
        (MathError mathErr, uint maxClose) = mulScalarTruncate(Exp({mantissa: closeFactorMantissa}), borrowBalance);
        if (mathErr != MathError.NO_ERROR) {
            return uint(Error.MATH_ERROR);
        }
        if (repayAmount > maxClose) {
            return uint(Error.TOO_MUCH_REPAY);
        }

        // res = sumBorrowPlusEffects * liquidationIncentiveMantissa / 1e18
        uint result = div_(mul_(sumBorrowPlusEffects, liquidationIncentiveMantissa), 1e18);
        if (result > sumDeposit
            && liquidator != liquidateGuardian
        ) {
            return uint(Error.GUARDIAN_REJECTION);
        }

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Checks if the seizing of assets should be allowed to occur
     * @param pTokenCollateral Asset which was used as collateral and will be seized
     * @param pTokenBorrowed Asset which was borrowed by the borrower
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param seizeTokens The number of collateral tokens to seize
     */
    function seizeAllowed(
        address pTokenCollateral,
        address pTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens
    ) external override returns (uint) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!seizeGuardianPaused, "seize is paused");

        // Shh - currently unused
        seizeTokens;

        if (!markets[pTokenCollateral].isListed || !markets[pTokenBorrowed].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        if (PTokenInterface(pTokenCollateral).controller() != PTokenInterface(pTokenBorrowed).controller()) {
            return uint(Error.CONTROLLER_MISMATCH);
        }

        // Keep the flywheel moving
        updatePieSupplyIndex(pTokenCollateral);
        distributeSupplierPie(pTokenCollateral, borrower, false);
        distributeSupplierPie(pTokenCollateral, liquidator, false);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Checks if the account should be allowed to transfer tokens in the given market
     * @param pToken The market to verify the transfer against
     * @param src The account which sources the tokens
     * @param dst The account which receives the tokens
     * @param transferTokens The number of pTokens to transfer
     * @return 0 if the transfer is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function transferAllowed(
        address pToken,
        address src,
        address dst,
        uint transferTokens
    ) external override returns (uint) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!transferGuardianPaused, "transfer is paused");

        // Currently the only consideration is whether or not
        //  the src is allowed to redeem this many tokens
        uint allowed = redeemAllowedInternal(pToken, src, transferTokens);
        if (allowed != uint(Error.NO_ERROR)) {
            return allowed;
        }

        // Keep the flywheel moving
        updatePieSupplyIndex(pToken);
        distributeSupplierPie(pToken, src, false);
        distributeSupplierPie(pToken, dst, false);

        return uint(Error.NO_ERROR);
    }

    /*** Liquidity/Liquidation Calculations ***/

    /**
     * @dev Local vars for avoiding stack-depth limits in calculating account liquidity.
     *  Note that `pTokenBalance` is the number of pTokens the account owns in the market,
     *  whereas `borrowBalance` is the amount of underlying that the account has borrowed.
     */
    struct AccountLiquidityLocalVars {
        uint sumCollateral;
        uint sumBorrowPlusEffects;
        uint pTokenBalance;
        uint borrowBalance;
        uint exchangeRateMantissa;
        uint oraclePriceMantissa;
        uint sumDeposit;
        Exp collateralFactor;
        Exp exchangeRate;
        Exp oraclePrice;
        Exp tokensToDenom;
    }

    /**
     * @notice Determine the current account liquidity wrt collateral requirements
     * @return (possible error code (semi-opaque),
                account liquidity in excess of collateral requirements,
     *          account shortfall below collateral requirements)
     */
    function getAccountLiquidity(address account) public view returns (uint, uint, uint) {
        (Error err, uint liquidity, uint shortfall) = getHypotheticalAccountLiquidityInternal(account, address(0), 0, 0);

        return (uint(err), liquidity, shortfall);
    }

    /**
     * @notice Determine the current account liquidity wrt collateral requirements
     * @return (possible error code,
                account liquidity in excess of collateral requirements,
     *          account shortfall below collateral requirements)
     */
    function getAccountLiquidityInternal(address account) internal view returns (Error, uint, uint) {
        return getHypotheticalAccountLiquidityInternal(account, address(0), 0, 0);
    }

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param pTokenModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemTokens The number of tokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @return (possible error code (semi-opaque),
                hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
    function getHypotheticalAccountLiquidity(
        address account,
        address pTokenModify,
        uint redeemTokens,
        uint borrowAmount
    ) public view virtual returns (uint, uint, uint) {
        (Error err, uint liquidity, uint shortfall) = getHypotheticalAccountLiquidityInternal(account, pTokenModify, redeemTokens, borrowAmount);
        return (uint(err), liquidity, shortfall);
    }

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param pTokenModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemTokens The number of tokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @dev Note that we calculate the exchangeRateStored for each collateral pToken using stored data,
     *  without calculating accumulated interest.
     * @return (possible error code,
                hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
    function getHypotheticalAccountLiquidityInternal(
        address account,
        address pTokenModify,
        uint redeemTokens,
        uint borrowAmount
    ) internal view returns (Error, uint, uint) {

        (Error err, uint sumCollateral, uint sumBorrowPlusEffects, ) = calcHypotheticalAccountLiquidityInternal(account, pTokenModify, redeemTokens, borrowAmount);
        if (err != Error.NO_ERROR) {
            return (err, sumCollateral, sumBorrowPlusEffects);
        }

        // These are safe, as the underflow condition is checked first
        if (sumCollateral > sumBorrowPlusEffects) {
            return (Error.NO_ERROR, sumCollateral - sumBorrowPlusEffects, 0);
        } else {
            return (Error.NO_ERROR, 0, sumBorrowPlusEffects - sumCollateral);
        }
    }

    function calcHypotheticalAccountLiquidityInternal(
        address account,
        address pTokenModify,
        uint redeemTokens,
        uint borrowAmount
    ) internal view returns (Error, uint, uint, uint) {

        AccountLiquidityLocalVars memory vars; // Holds all our calculation results
        uint oErr;
        MathError mErr;

        // For each asset the account is in
        address[] memory assets = accountAssets[account];
        for (uint i = 0; i < assets.length; i++) {
            address asset = assets[i];

            // Read the balances and exchange rate from the pToken
            (oErr, vars.pTokenBalance, vars.borrowBalance, vars.exchangeRateMantissa) = PTokenInterface(asset).getAccountSnapshot(account);
            if (oErr != 0) { // semi-opaque error code, we assume NO_ERROR == 0 is invariant between upgrades
                return (Error.SNAPSHOT_ERROR, 0, 0, 0);
            }
            vars.collateralFactor = Exp({mantissa: markets[address(asset)].collateralFactorMantissa});
            vars.exchangeRate = Exp({mantissa: vars.exchangeRateMantissa});

            // Get the normalized price of the asset
            vars.oraclePriceMantissa = getOracle().getUnderlyingPrice(asset);
            if (vars.oraclePriceMantissa == 0) {
                return (Error.PRICE_ERROR, 0, 0, 0);
            }

            vars.oraclePrice = Exp({mantissa: vars.oraclePriceMantissa});

            // Pre-compute a conversion factor from tokens -> ether (normalized price value)
            (mErr, vars.tokensToDenom) = mulExp(vars.exchangeRate, vars.oraclePrice);
            if (mErr != MathError.NO_ERROR) {
                return (Error.MATH_ERROR, 0, 0, 0);
            }

            (mErr, vars.sumDeposit) = mulScalarTruncateAddUInt(vars.tokensToDenom, vars.pTokenBalance, vars.sumDeposit);
            if (mErr != MathError.NO_ERROR) {
                return (Error.MATH_ERROR, 0, 0, 0);
            }

            (mErr, vars.tokensToDenom) = mulExp(vars.collateralFactor, vars.tokensToDenom);
            if (mErr != MathError.NO_ERROR) {
                return (Error.MATH_ERROR, 0, 0, 0);
            }

            // sumCollateral += tokensToDenom * pTokenBalance
            (mErr, vars.sumCollateral) = mulScalarTruncateAddUInt(vars.tokensToDenom, vars.pTokenBalance, vars.sumCollateral);
            if (mErr != MathError.NO_ERROR) {
                return (Error.MATH_ERROR, 0, 0, 0);
            }

            // for feeToken
            if (asset != registry.pETH()
                && asset != registry.pPIE()
                && feeFactorMantissa[asset] > 0
            ) {
                // vars.oraclePriceMantissa * (1e18 + feeFactorMantissa[asset] * 3) / 1e18
                vars.oraclePrice = Exp({mantissa: div_(mul_(vars.oraclePriceMantissa, (add_(1e18, mul_(feeFactorMantissa[asset], 3)))), 1e18)});
            }

            // sumBorrowPlusEffects += oraclePrice * borrowBalance
            (mErr, vars.sumBorrowPlusEffects) = mulScalarTruncateAddUInt(vars.oraclePrice, vars.borrowBalance, vars.sumBorrowPlusEffects);
            if (mErr != MathError.NO_ERROR) {
                return (Error.MATH_ERROR, 0, 0, 0);
            }

            // Calculate effects of interacting with pTokenModify
            if (asset == pTokenModify) {
                // redeem effect
                // sumBorrowPlusEffects += tokensToDenom * redeemTokens
                (mErr, vars.sumBorrowPlusEffects) = mulScalarTruncateAddUInt(vars.tokensToDenom, redeemTokens, vars.sumBorrowPlusEffects);
                if (mErr != MathError.NO_ERROR) {
                    return (Error.MATH_ERROR, 0, 0, 0);
                }

                // borrow effect
                // sumBorrowPlusEffects += oraclePrice * borrowAmount
                (mErr, vars.sumBorrowPlusEffects) = mulScalarTruncateAddUInt(vars.oraclePrice, borrowAmount, vars.sumBorrowPlusEffects);
                if (mErr != MathError.NO_ERROR) {
                    return (Error.MATH_ERROR, 0, 0, 0);
                }
            }
        }

        return (Error.NO_ERROR, vars.sumCollateral, vars.sumBorrowPlusEffects, vars.sumDeposit);
    }

    /**
     * @notice Calculate number of tokens of collateral asset to seize given an underlying amount
     * @dev Used in liquidation (called in pToken.liquidateBorrowFresh)
     * @param pTokenBorrowed The address of the borrowed pToken
     * @param pTokenCollateral The address of the collateral pToken
     * @param actualRepayAmount The amount of pTokenBorrowed underlying to convert into pTokenCollateral tokens
     * @return (errorCode, number of pTokenCollateral tokens to be seized in a liquidation)
     */
    function liquidateCalculateSeizeTokens(
        address pTokenBorrowed,
        address pTokenCollateral,
        uint actualRepayAmount
    ) external view override returns (uint, uint) {
        /* Read oracle prices for borrowed and collateral markets */
        uint priceBorrowedMantissa = getOracle().getUnderlyingPrice(pTokenBorrowed);
        uint priceCollateralMantissa = getOracle().getUnderlyingPrice(pTokenCollateral);
        if (priceBorrowedMantissa == 0 || priceCollateralMantissa == 0) {
            return (uint(Error.PRICE_ERROR), 0);
        }

        /*
         * Get the exchange rate and calculate the number of collateral tokens to seize:
         *  seizeAmount = actualRepayAmount * liquidationIncentive * priceBorrowed / priceCollateral
         *  seizeTokens = seizeAmount / exchangeRate
         *   = actualRepayAmount * (liquidationIncentive * priceBorrowed) / (priceCollateral * exchangeRate)
         */
        uint seizeTokens;
        Exp memory numerator;
        Exp memory denominator;
        Exp memory ratio;
        MathError mathErr;

        (mathErr, numerator) = mulExp(liquidationIncentiveMantissa, priceBorrowedMantissa);
        if (mathErr != MathError.NO_ERROR) {
            return (uint(Error.MATH_ERROR), 0);
        }

        // uint exchangeRateMantissa = PTokenInterface(pTokenCollateral).exchangeRateStored(); // Note: reverts on error
        (mathErr, denominator) = mulExp(priceCollateralMantissa, PTokenInterface(pTokenCollateral).exchangeRateStored());
        if (mathErr != MathError.NO_ERROR) {
            return (uint(Error.MATH_ERROR), 0);
        }

        (mathErr, ratio) = divExp(numerator, denominator);
        if (mathErr != MathError.NO_ERROR) {
            return (uint(Error.MATH_ERROR), 0);
        }

        (mathErr, seizeTokens) = mulScalarTruncate(ratio, actualRepayAmount);
        if (mathErr != MathError.NO_ERROR) {
            return (uint(Error.MATH_ERROR), 0);
        }

        uint feeFactor = feeFactorMantissa[pTokenBorrowed];
        if (feeFactor > 0) {
            // seizeTokens * 1e36 / ((1e18 - feeFactorMantissa[pTokenBorrowed]) ** 2)
            uint res = sub_(1e18, feeFactor);
            seizeTokens = div_(mul_(seizeTokens, 1e36), mul_(res, res));
        }

        return (uint(Error.NO_ERROR), seizeTokens);
    }

    /*** Admin Functions ***/

    /**
      * @notice Sets a PIE address for the controller
      * @return uint 0=success
      */
    function _setPieAddress(address pieAddress_) public returns (uint) {
        require(msg.sender == getAdmin() && pieAddress == address(0), "pie address may only be initialized once");

        pieAddress = pieAddress_;

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets the closeFactor used when liquidating borrows
      * @dev Admin function to set closeFactor
      * @param newCloseFactorMantissa New close factor, scaled by 1e18
      * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
      */
    function _setCloseFactor(uint newCloseFactorMantissa) external returns (uint) {
        // Check caller is admin
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_CLOSE_FACTOR_OWNER_CHECK);
        }

        Exp memory newCloseFactorExp = Exp({mantissa: newCloseFactorMantissa});
        Exp memory lowLimit = Exp({mantissa: closeFactorMinMantissa});
        if (lessThanOrEqualExp(newCloseFactorExp, lowLimit)) {
            return fail(Error.INVALID_CLOSE_FACTOR, FailureInfo.SET_CLOSE_FACTOR_VALIDATION);
        }

        Exp memory highLimit = Exp({mantissa: closeFactorMaxMantissa});
        if (lessThanExp(highLimit, newCloseFactorExp)) {
            return fail(Error.INVALID_CLOSE_FACTOR, FailureInfo.SET_CLOSE_FACTOR_VALIDATION);
        }

        uint oldCloseFactorMantissa = closeFactorMantissa;
        closeFactorMantissa = newCloseFactorMantissa;
        emit NewCloseFactor(oldCloseFactorMantissa, closeFactorMantissa);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets the collateralFactor for a market
      * @dev Admin function to set per-market collateralFactor
      * @param pToken The market to set the factor on
      * @param newCollateralFactorMantissa The new collateral factor, scaled by 1e18
      * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
      */
    function _setCollateralFactor(address pToken, uint newCollateralFactorMantissa) external returns (uint) {
        // Check caller is admin
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_COLLATERAL_FACTOR_OWNER_CHECK);
        }

        // Verify market is listed
        Market storage market = markets[pToken];
        if (!market.isListed) {
            return fail(Error.MARKET_NOT_LISTED, FailureInfo.SET_COLLATERAL_FACTOR_NO_EXISTS);
        }

        Exp memory newCollateralFactorExp = Exp({mantissa: newCollateralFactorMantissa});

        // Check collateral factor <= 0.9
        Exp memory highLimit = Exp({mantissa: collateralFactorMaxMantissa});
        if (lessThanExp(highLimit, newCollateralFactorExp)) {
            return fail(Error.INVALID_COLLATERAL_FACTOR, FailureInfo.SET_COLLATERAL_FACTOR_VALIDATION);
        }

        getOracle().updateUnderlyingPrice(pToken);
        // If collateral factor != 0, fail if price == 0
        if (newCollateralFactorMantissa != 0 && getOracle().getUnderlyingPrice(pToken) == 0) {
            return fail(Error.PRICE_ERROR, FailureInfo.SET_COLLATERAL_FACTOR_WITHOUT_PRICE);
        }

        // Set market's collateral factor to new collateral factor, remember old value
        uint oldCollateralFactorMantissa = market.collateralFactorMantissa;
        market.collateralFactorMantissa = newCollateralFactorMantissa;

        // Emit event with asset, old collateral factor, and new collateral factor
        emit NewCollateralFactor(pToken, oldCollateralFactorMantissa, newCollateralFactorMantissa);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets the max fee factor for a markets
      * @dev Admin function to set max fee factor
      * @param newFeeFactorMaxMantissa The new max fee factor, scaled by 1e18
      * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
      */
    function _setFeeFactorMaxMantissa(uint newFeeFactorMaxMantissa) external returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_MAX_FEE_FACTOR);
        }

        uint oldFeeFactorMaxMantissa = feeFactorMaxMantissa;
        feeFactorMaxMantissa = newFeeFactorMaxMantissa;

        emit NewFeeFactorMaxMantissa(oldFeeFactorMaxMantissa, newFeeFactorMaxMantissa);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets the feeFactor for a market
      * @dev Admin function to set per-market fee factor (also market can set fee factor after calc)
      * @param pToken The market to set the factor on
      * @param newFeeFactorMantissa The new fee factor, scaled by 1e18
      * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
      */
    function _setFeeFactor(address pToken, uint newFeeFactorMantissa) public override returns (uint) {
        if (msg.sender != getAdmin() && !markets[msg.sender].isListed) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_FEE_FACTOR);
        }

        require(newFeeFactorMantissa <= feeFactorMaxMantissa, 'SET_FEE_FACTOR_FAILED');
        require(markets[pToken].isListed, 'market is not listed');

        uint oldFeeFactorMantissa = feeFactorMantissa[pToken];
        feeFactorMantissa[pToken] = newFeeFactorMantissa;

        emit NewFeeFactor(pToken, oldFeeFactorMantissa, newFeeFactorMantissa);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets the feeFactors for a markets
      * @dev Admin function to set per-market fee factors (also market can set fee factor after calc)
      * @param pTokens Markets to set the factor on
      * @param newFeeFactors The new fee factors for markets, scaled by 1e18
      * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
      */
    function _setFeeFactors(address[] calldata pTokens, uint[] calldata newFeeFactors) external returns (uint) {
        require(pTokens.length != 0 && newFeeFactors.length == pTokens.length, "invalid input");

        uint result;
        for(uint i = 0; i < pTokens.length; i++ ) {
            result = _setFeeFactor(pTokens[i], newFeeFactors[i]);

            if (result != uint(Error.NO_ERROR)) {
                return fail(Error.REJECTION, FailureInfo.SET_FEE_FACTOR);
            }
        }

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets maxAssets which controls how many markets can be entered
      * @dev Admin function to set maxAssets
      * @param newMaxAssets New max assets
      * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
      */
    function _setMaxAssets(uint newMaxAssets) external returns (uint) {
        // Check caller is admin
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_MAX_ASSETS_OWNER_CHECK);
        }

        uint oldMaxAssets = maxAssets;
        maxAssets = newMaxAssets;
        emit NewMaxAssets(oldMaxAssets, newMaxAssets);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets liquidationIncentive
      * @dev Admin function to set liquidationIncentive
      * @param newLiquidationIncentiveMantissa New liquidationIncentive scaled by 1e18
      * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
      */
    function _setLiquidationIncentive(uint newLiquidationIncentiveMantissa) external returns (uint) {
        // Check caller is admin
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_LIQUIDATION_INCENTIVE_OWNER_CHECK);
        }

        // Check de-scaled min <= newLiquidationIncentive <= max
        Exp memory newLiquidationIncentive = Exp({mantissa: newLiquidationIncentiveMantissa});
        Exp memory minLiquidationIncentive = Exp({mantissa: liquidationIncentiveMinMantissa});
        if (lessThanExp(newLiquidationIncentive, minLiquidationIncentive)) {
            return fail(Error.INVALID_LIQUIDATION_INCENTIVE, FailureInfo.SET_LIQUIDATION_INCENTIVE_VALIDATION);
        }

        Exp memory maxLiquidationIncentive = Exp({mantissa: liquidationIncentiveMaxMantissa});
        if (lessThanExp(maxLiquidationIncentive, newLiquidationIncentive)) {
            return fail(Error.INVALID_LIQUIDATION_INCENTIVE, FailureInfo.SET_LIQUIDATION_INCENTIVE_VALIDATION);
        }

        // Save current value for use in log
        uint oldLiquidationIncentiveMantissa = liquidationIncentiveMantissa;

        // Set liquidation incentive to new incentive
        liquidationIncentiveMantissa = newLiquidationIncentiveMantissa;

        // Emit event with old incentive, new incentive
        emit NewLiquidationIncentive(oldLiquidationIncentiveMantissa, newLiquidationIncentiveMantissa);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Add the market to the markets mapping and set it as listed
      * @dev Admin function to set isListed and add support for the market
      * @param pToken The address of the market (token) to list
      * @return uint 0=success, otherwise a failure. (See enum Error for details)
      */
    function _supportMarket(address pToken) external returns (uint) {
        if (msg.sender != getAdmin() && msg.sender != registry.factory()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SUPPORT_MARKET_OWNER_CHECK);
        }

        if (markets[pToken].isListed) {
            return fail(Error.MARKET_ALREADY_LISTED, FailureInfo.SUPPORT_MARKET_EXISTS);
        }

        PTokenInterface(pToken).isPToken(); // Sanity check to make sure its really a PToken

        _addMarketInternal(pToken);

        Market storage newMarket = markets[pToken];
        newMarket.isListed = true;

        emit MarketListed(pToken);

        return uint(Error.NO_ERROR);
    }

    function _addMarketInternal(address pToken) internal {
        require(markets[pToken].isListed == false, "market already added");
        allMarkets.push(pToken);
    }

    /**
     * @notice Admin function to change the Pause Guardian
     * @param newPauseGuardian The address of the new Pause Guardian
     * @return uint 0=success, otherwise a failure. (See enum Error for details)
     */
    function _setPauseGuardian(address newPauseGuardian) public returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_GUARDIAN_OWNER_CHECK);
        }

        // Save current value for inclusion in log
        address oldPauseGuardian = pauseGuardian;

        // Store pauseGuardian with value newPauseGuardian
        pauseGuardian = newPauseGuardian;

        // Emit NewPauseGuardian(OldPauseGuardian, NewPauseGuardian)
        emit NewPauseGuardian(oldPauseGuardian, pauseGuardian);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Admin function to change the Liquidate Guardian
     * @param newLiquidateGuardian The address of the new Liquidate Guardian
     * @return uint 0=success, otherwise a failure. (See enum Error for details)
     */
    function _setLiquidateGuardian(address newLiquidateGuardian) public returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_GUARDIAN_OWNER_CHECK);
        }

        // Save current value for inclusion in log
        address oldLiquidateGuardian = liquidateGuardian;

        // Store pauseGuardian with value newLiquidateGuardian
        liquidateGuardian = newLiquidateGuardian;

        // Emit newLiquidateGuardian(OldPauseGuardian, NewLiquidateGuardian)
        emit NewLiquidateGuardian(oldLiquidateGuardian, liquidateGuardian);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Admin function to change the mint status for market
     * @param pToken The address of the market
     * @param state The flag of the mint status for market
     * @return uint 0=success, otherwise a failure. (See enum Error for details)
     */
    function _setMintPaused(address pToken, bool state) public returns (bool) {
        require(markets[pToken].isListed, "cannot pause a market that is not listed");
        require(msg.sender == pauseGuardian || msg.sender == getAdmin(), "only pause guardian and admin can pause");
        require(msg.sender == getAdmin() || state == true, "only admin can unpause");

        mintGuardianPaused[pToken] = state;

        emit ActionPaused(pToken, "Mint", state);

        return state;
    }

    /**
     * @notice Admin function to change the borrow status for market
     * @param pToken The address of the market
     * @param state The flag of the borrow status for market
     * @return uint 0=success, otherwise a failure. (See enum Error for details)
     */
    function _setBorrowPaused(address pToken, bool state) public returns (bool) {
        require(markets[pToken].isListed, "cannot pause a market that is not listed");
        require(msg.sender == pauseGuardian || msg.sender == getAdmin(), "only pause guardian and admin can pause");
        require(msg.sender == getAdmin() || state == true, "only admin can unpause");

        borrowGuardianPaused[pToken] = state;

        emit ActionPaused(pToken, "Borrow", state);

        return state;
    }

    /**
     * @notice Admin function to change the Borrow Delay
     * @param newBorrowDelay The value of the new Borrow Delay in seconds
     * @return uint 0=success, otherwise a failure. (See enum Error for details)
     */
    function _setBorrowDelay(uint newBorrowDelay) public returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_BORROW_DELAY_OWNER_CHECK);
        }

        // Save current value for inclusion in log
        uint oldBorrowDelay = borrowDelay;

        // Store dorrowDelay with value newBorrowDelay
        borrowDelay = newBorrowDelay;

        // Emit newBorrowDelay(OldBorrowDelay, NewBorrowDelay)
        emit NewBorrowDelay(oldBorrowDelay, borrowDelay);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Admin function to change the transfer status for markets
     * @param state The flag of the transfer status
     * @return uint 0=success, otherwise a failure. (See enum Error for details)
     */
    function _setTransferPaused(bool state) public returns (bool) {
        require(msg.sender == pauseGuardian || msg.sender == getAdmin(), "only pause guardian and admin can pause");
        require(msg.sender == getAdmin() || state == true, "only admin can unpause");

        transferGuardianPaused = state;

        emit ActionPaused("Transfer", state);

        return state;
    }

    /**
     * @notice Admin function to change the seize status for markets
     * @param state The flag of the transfer status
     * @return uint 0=success, otherwise a failure. (See enum Error for details)
     */
    function _setSeizePaused(bool state) public returns (bool) {
        require(msg.sender == pauseGuardian || msg.sender == getAdmin(), "only pause guardian and admin can pause");
        require(msg.sender == getAdmin() || state == true, "only admin can unpause");

        seizeGuardianPaused = state;

        emit ActionPaused("Seize", state);

        return state;
    }

    function _become(address payable unitroller) public {
        require(msg.sender == Unitroller(unitroller).getAdmin(), "only unitroller admin can change brains");
        require(Unitroller(unitroller)._acceptImplementation() == 0, "change not authorized");
    }

    /*** Pie Distribution ***/

    /**
     * @notice Set PIE speed for a single market
     * @param pToken The market whose PIE speed to update
     * @param pieSpeed New PIE speed for market
     */
    function setPieSpeedInternal(address pToken, uint pieSpeed) internal {
        uint currentPieSpeed = pieSpeeds[pToken];
        if (currentPieSpeed != 0) {
            // note that PIE speed could be set to 0 to halt liquidity rewards for a market
            Exp memory borrowIndex = Exp({mantissa: PTokenInterface(pToken).borrowIndex()});
            updatePieSupplyIndex(pToken);
            updatePieBorrowIndex(pToken, borrowIndex);
        } else if (pieSpeed != 0) {
            // Add the PIE market
            Market storage market = markets[pToken];
            require(market.isListed == true, "pie market is not listed");

            if (pieSupplyState[pToken].index == 0) {
                pieSupplyState[pToken] = PieMarketState({
                    index: pieInitialIndex,
                    block: safe32(getBlockNumber(), "block number exceeds 32 bits")
                });
            } else {
                pieSupplyState[pToken].block = safe32(getBlockNumber(), "block number exceeds 32 bits");
            }

            if (pieBorrowState[pToken].index == 0) {
                pieBorrowState[pToken] = PieMarketState({
                    index: pieInitialIndex,
                    block: safe32(getBlockNumber(), "block number exceeds 32 bits")
                });
            } else {
                pieBorrowState[pToken].block = safe32(getBlockNumber(), "block number exceeds 32 bits");
            }
        }

        if (currentPieSpeed != pieSpeed) {
            pieSpeeds[pToken] = pieSpeed;
            emit PieSpeedUpdated(pToken, pieSpeed);
        }
    }

    /**
     * @notice Accrue PIE to the market by updating the supply index
     * @param pToken The market whose supply index to update
     */
    function updatePieSupplyIndex(address pToken) internal {
        PieMarketState storage supplyState = pieSupplyState[pToken];
        uint supplySpeed = pieSpeeds[pToken];
        uint blockNumber = getBlockNumber();
        uint deltaBlocks = sub_(blockNumber, uint(supplyState.block));
        if (deltaBlocks > 0 && supplySpeed > 0) {
            uint supplyTokens = PTokenInterface(pToken).totalSupply();
            uint pieAccrued = mul_(deltaBlocks, supplySpeed);
            Double memory ratio = supplyTokens > 0 ? fraction(pieAccrued, supplyTokens) : Double({mantissa: 0});
            Double memory index = add_(Double({mantissa: supplyState.index}), ratio);
            pieSupplyState[pToken] = PieMarketState({
                index: safe224(index.mantissa, "new index exceeds 224 bits"),
                block: safe32(blockNumber, "block number exceeds 32 bits")
            });
        }
    }

    /**
     * @notice Accrue PIE to the market by updating the borrow index
     * @param pToken The market whose borrow index to update
     */
    function updatePieBorrowIndex(address pToken, Exp memory marketBorrowIndex) internal {
        PieMarketState storage borrowState = pieBorrowState[pToken];
        uint borrowSpeed = pieSpeeds[pToken];
        uint blockNumber = getBlockNumber();
        uint deltaBlocks = sub_(blockNumber, uint(borrowState.block));
        if (deltaBlocks > 0 && borrowSpeed > 0) {
            uint borrowAmount = div_(PTokenInterface(pToken).totalBorrows(), marketBorrowIndex);
            uint pieAccrued = mul_(deltaBlocks, borrowSpeed);
            Double memory ratio = borrowAmount > 0 ? fraction(pieAccrued, borrowAmount) : Double({mantissa: 0});
            Double memory index = add_(Double({mantissa: borrowState.index}), ratio);
            pieBorrowState[pToken] = PieMarketState({
                index: safe224(index.mantissa, "new index exceeds 224 bits"),
                block: safe32(blockNumber, "block number exceeds 32 bits")
            });
        }
    }

    /**
     * @notice Calculate PIE accrued by a supplier and possibly transfer it to them
     * @param pToken The market in which the supplier is interacting
     * @param supplier The address of the supplier to distribute PIE to
     */
    function distributeSupplierPie(address pToken, address supplier, bool distributeAll) internal {
        PieMarketState storage supplyState = pieSupplyState[pToken];
        Double memory supplyIndex = Double({mantissa: supplyState.index});
        Double memory supplierIndex = Double({mantissa: pieSupplierIndex[pToken][supplier]});
        pieSupplierIndex[pToken][supplier] = supplyIndex.mantissa;

        if (supplierIndex.mantissa == 0 && supplyIndex.mantissa > 0) {
            supplierIndex.mantissa = pieInitialIndex;
        }

        Double memory deltaIndex = sub_(supplyIndex, supplierIndex);
        uint supplierTokens = PTokenInterface(pToken).balanceOf(supplier);
        uint supplierDelta = mul_(supplierTokens, deltaIndex);
        uint supplierAccrued = add_(pieAccrued[supplier], supplierDelta);
        pieAccrued[supplier] = transferPie(supplier, supplierAccrued, distributeAll ? 0 : pieClaimThreshold);
        emit DistributedSupplierPie(pToken, supplier, supplierDelta, supplyIndex.mantissa);
    }

    /**
     * @notice Calculate PIE accrued by a borrower and possibly transfer it to them
     * @dev Borrowers will not begin to accrue until after the first interaction with the protocol.
     * @param pToken The market in which the borrower is interacting
     * @param borrower The address of the borrower to distribute PIE to
     */
    function distributeBorrowerPie(
        address pToken,
        address borrower,
        Exp memory marketBorrowIndex,
        bool distributeAll
    ) internal {
        PieMarketState storage borrowState = pieBorrowState[pToken];
        Double memory borrowIndex = Double({mantissa: borrowState.index});
        Double memory borrowerIndex = Double({mantissa: pieBorrowerIndex[pToken][borrower]});
        pieBorrowerIndex[pToken][borrower] = borrowIndex.mantissa;

        if (borrowerIndex.mantissa > 0) {
            Double memory deltaIndex = sub_(borrowIndex, borrowerIndex);
            uint borrowerAmount = div_(PTokenInterface(pToken).borrowBalanceStored(borrower), marketBorrowIndex);
            uint borrowerDelta = mul_(borrowerAmount, deltaIndex);
            uint borrowerAccrued = add_(pieAccrued[borrower], borrowerDelta);
            pieAccrued[borrower] = transferPie(borrower, borrowerAccrued, distributeAll ? 0 : pieClaimThreshold);
            emit DistributedBorrowerPie(pToken, borrower, borrowerDelta, borrowIndex.mantissa);
        }
    }

    /**
     * @notice Claim all the pie accrued by holder in all markets
     * @param holder The address to claim PIE for
     */
    function claimPie(address holder) public {
        claimPie(holder, allMarkets);
    }

    /**
     * @notice Claim all the pie accrued by holder in the specified markets
     * @param holder The address to claim PIE for
     * @param pTokens The list of markets to claim PIE in
     */
    function claimPie(address holder, address[] memory pTokens) public {
        address[] memory holders = new address[](1);
        holders[0] = holder;
        claimPie(holders, pTokens, true, true);
    }

    /**
     * @notice Claim all pie accrued by the holders
     * @param holders The addresses to claim PIE for
     * @param pTokens The list of markets to claim PIE in
     * @param borrowers Whether or not to claim PIE earned by borrowing
     * @param suppliers Whether or not to claim PIE earned by supplying
     */
    function claimPie(address[] memory holders, address[] memory pTokens, bool borrowers, bool suppliers) public {
        for (uint i = 0; i < pTokens.length; i++) {
            address pToken = pTokens[i];
            require(markets[pToken].isListed, "market must be listed");
            if (borrowers == true) {
                Exp memory borrowIndex = Exp({mantissa: PTokenInterface(pToken).borrowIndex()});
                updatePieBorrowIndex(pToken, borrowIndex);
                for (uint j = 0; j < holders.length; j++) {
                    distributeBorrowerPie(pToken, holders[j], borrowIndex, true);
                }
            }
            if (suppliers == true) {
                updatePieSupplyIndex(pToken);
                for (uint j = 0; j < holders.length; j++) {
                    distributeSupplierPie(pToken, holders[j], true);
                }
            }
        }
    }

    /**
     * @notice Transfer PIE to the user
     * @dev Note: If there is not enough PIE, we do not perform the transfer all.
     * @param user The address of the user to transfer PIE to
     * @param userAccrued The amount of PIE to (possibly) transfer
     * @return The userAccrued of PIE which was NOT transferred to the user
     */
    function transferPie(address user, uint userAccrued, uint threshold) internal returns (uint) {
        if (userAccrued >= threshold && userAccrued > 0) {
            address pie = getPieAddress();
            uint pieRemaining = EIP20Interface(pie).balanceOf(address(this));
            if (userAccrued <= pieRemaining) {
                EIP20Interface(pie).transfer(user, userAccrued);
                return 0;
            }
        }
        return userAccrued;
    }

    /*** Pie Distribution Admin ***/

    /**
    * @notice Set PIE speed for a single market
    * @param pToken The market whose PIE speed to update
    * @param pieSpeed New PIE speed for market
    */
    function _setPieSpeed(address pToken, uint pieSpeed) public {
        require(msg.sender == getAdmin(), "only admin can set pie speed");
        setPieSpeedInternal(pToken, pieSpeed);
    }

    /**
     * @notice Return all of the markets
     * @dev The automatic getter may be used to access an individual market.
     * @return The list of market addresses
     */
    function getAllMarkets() public view returns (address[] memory) {
        return allMarkets;
    }

    /**
     * @notice Return the number of current block
     * @return The block number
     */
    function getBlockNumber() public view virtual returns (uint) {
        return block.number;
    }

    /**
     * @notice Return the address of the PIE token
     * @return The address of PIE
     */
    function getPieAddress() public view virtual returns (address) {
        return pieAddress;
    }

    /**
     * @notice Return the address of the oracle
     * @return The interface (address) of oracle
     */
    function getOracle() public view override returns (PriceOracle) {
        return PriceOracle(registry.oracle());
    }

    /**
     * @notice Return the address of the admin
     * @return The address of admin
     */
    function getAdmin() public view virtual returns (address payable) {
        return registry.admin();
    }

    /**
     * @notice Return the fee factor of the pToken
     * @param pToken PToken address
     * @return The address of admin
     */
    function getFeeFactorMantissa(address pToken) public view override returns (uint) {
        return feeFactorMantissa[pToken];
    }

    /**
     * @notice Return the borrow delay for markets
     * @return The borrow delay
     */
    function getBorrowDelay() public view override returns (uint) {
        return borrowDelay;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import './PErc20Delegator.sol';
import './RegistryInterface.sol';
import './EIP20Interface.sol';
import "./Interfaces/IPriceFeeds.sol";
import "./ErrorReporter.sol";
import "./SafeMath.sol";
import "./PEtherDelegator.sol";
import "./PPIEDelegator.sol";
import "./Controller.sol";
import "./PriceOracle.sol";
import "./PTokenInterfaces.sol";

contract PTokenFactory is FactoryErrorReporter {
    using SafeMath for uint;

    uint public minUniswapLiquidity;

    // decimals for pToken
    uint8 public decimals = 8;

    // default parameters for pToken
    address public controller;
    address public interestRateModel;
    uint256 public initialExchangeRateMantissa;
    uint256 public initialReserveFactorMantissa;

    mapping (address => bool) public isUnderlyingBlackListed;

    /**
     * Fired on creation new pToken proxy
     * @param newPToken Address of new PToken proxy contract
     * @param startBorrowTimestamp Timestamp for borrow start
     */
    event PTokenCreated(address newPToken, uint startBorrowTimestamp);

    event AddedBlackList(address _underlying);
    event RemovedBlackList(address _underlying);

    RegistryInterface public registry;

    constructor(
        RegistryInterface registry_,
        uint minUniswapLiquidity_,
        address _controller,
        address _interestRateModel,
        uint256 _initialExchangeRateMantissa,
        uint256 _initialReserveFactorMantissa
    ) {
        registry = registry_;
        minUniswapLiquidity = minUniswapLiquidity_;
        controller = _controller;
        interestRateModel = _interestRateModel;
        initialExchangeRateMantissa = _initialExchangeRateMantissa;
        initialReserveFactorMantissa = _initialReserveFactorMantissa;
    }

    /**
     * Creates new pToken proxy contract and adds pToken to the controller
     * @param underlying_ The address of the underlying asset
     */
    function createPToken(address underlying_) external returns (uint) {
        if (getBlackListStatus(underlying_)) {
            return fail(Error.INVALID_POOL, FailureInfo.UNDERLYING_IN_BLACKLIST);
        }

        if (!checkPair(underlying_)) {
            return fail(Error.INVALID_POOL, FailureInfo.DEFICIENCY_LIQUIDITY_IN_POOL_OR_PAIR_IS_NOT_EXIST);
        }

        (string memory name, string memory symbol) = _createPTokenNameAndSymbol(underlying_);

        uint power = EIP20Interface(underlying_).decimals();
        uint exchangeRateMantissa = calcExchangeRate(power);

        PErc20Delegator newPToken = new PErc20Delegator(underlying_, controller, interestRateModel, exchangeRateMantissa, initialReserveFactorMantissa, name, symbol, decimals, address(registry));

        uint256 result = Controller(controller)._supportMarket(address(newPToken));
        if (result != 0) {
            return fail(Error.MARKET_NOT_LISTED, FailureInfo.SUPPORT_MARKET_BAD_RESULT);
        }

        registry.addPToken(underlying_, address(newPToken));

        uint startBorrowTimestamp = PErc20ExtInterface(address(newPToken)).startBorrowTimestamp();
        emit PTokenCreated(address(newPToken), startBorrowTimestamp);

        getOracle().update(underlying_);

        return uint(Error.NO_ERROR);
    }

    function _createPETH(address pETHImplementation_, string memory symbol_) external virtual returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.CREATE_PETH_POOL);
        }

        string memory name = string(abi.encodePacked("DeFiPie ", symbol_));
        string memory symbol = string(abi.encodePacked("p", symbol_));

        uint power = 18;
        uint exchangeRateMantissa = calcExchangeRate(power);

        PETHDelegator newPETH = new PETHDelegator(pETHImplementation_, controller, interestRateModel, exchangeRateMantissa, initialReserveFactorMantissa, name, symbol, decimals, address(registry));

        uint256 result = Controller(controller)._supportMarket(address(newPETH));
        if (result != 0) {
            return fail(Error.MARKET_NOT_LISTED, FailureInfo.SUPPORT_MARKET_BAD_RESULT);
        }

        registry.addPETH(address(newPETH));

        emit PTokenCreated(address(newPETH), block.timestamp);

        return uint(Error.NO_ERROR);
    }

    function _createPPIE(address underlying_, address pPIEImplementation_) external virtual returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.CREATE_PPIE_POOL);
        }

        string memory name = "DeFiPie PIE";
        string memory symbol = "pPIE";

        uint power = EIP20Interface(underlying_).decimals();
        uint exchangeRateMantissa = calcExchangeRate(power);

        PPIEDelegator newPPIE = new PPIEDelegator(underlying_, pPIEImplementation_, controller, interestRateModel, exchangeRateMantissa, initialReserveFactorMantissa, name, symbol, decimals, address(registry));

        uint256 result = Controller(controller)._supportMarket(address(newPPIE));
        if (result != 0) {
            return fail(Error.MARKET_NOT_LISTED, FailureInfo.SUPPORT_MARKET_BAD_RESULT);
        }

        registry.addPPIE(address(newPPIE));

        emit PTokenCreated(address(newPPIE), block.timestamp);

        getOracle().update(underlying_);

        return uint(Error.NO_ERROR);
    }

    function checkPair(address asset) public view returns (bool) {
        (, address pair, uint112 ethEquivalentReserves) = getOracle().searchPair(asset);

        return bool(pair != address(0) && ethEquivalentReserves >= minUniswapLiquidity);
    }

    function _setMinUniswapLiquidity(uint minUniswapLiquidity_) public returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_MIN_LIQUIDITY_OWNER_CHECK);
        }

        minUniswapLiquidity = minUniswapLiquidity_;

        return uint(Error.NO_ERROR);
    }

    /**
     *  Sets address of actual controller contract
     *  @return uint 0 = success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setController(address newController) external returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_CONTROLLER);
        }
        controller = newController;

        return(uint(Error.NO_ERROR));
    }

    /**
     *  Sets address of actual interestRateModel contract
     *  @return uint 0 = success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setInterestRateModel(address newInterestRateModel) external returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_INTEREST_RATE_MODEL);
        }

        interestRateModel = newInterestRateModel;

        return(uint(Error.NO_ERROR));
    }

    /**
     *  Sets initial exchange rate
     *  @return uint 0 = success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setInitialExchangeRateMantissa(uint _initialExchangeRateMantissa) external returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_EXCHANGE_RATE);
        }

        initialExchangeRateMantissa = _initialExchangeRateMantissa;

        return(uint(Error.NO_ERROR));
    }

    function _setInitialReserveFactorMantissa(uint _initialReserveFactorMantissa) external returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_RESERVE_FACTOR);
        }

        initialReserveFactorMantissa = _initialReserveFactorMantissa;

        return(uint(Error.NO_ERROR));
    }

    function _setPTokenDecimals(uint _decimals) external returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_DECIMALS);
        }

        decimals = uint8(_decimals);

        return(uint(Error.NO_ERROR));
    }

    function _addBlackList(address _underlying) public returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ADD_UNDERLYING_TO_BLACKLIST);
        }

        isUnderlyingBlackListed[_underlying] = true;

        emit AddedBlackList(_underlying);

        return(uint(Error.NO_ERROR));
    }

    function _removeBlackList(address _underlying) public returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.REMOVE_UNDERLYING_FROM_BLACKLIST);
        }

        isUnderlyingBlackListed[_underlying] = false;

        emit RemovedBlackList(_underlying);

        return(uint(Error.NO_ERROR));
    }

    function getBlackListStatus(address _underlying) public view returns (bool) {
        return isUnderlyingBlackListed[_underlying];
    }

    function getAdmin() public view returns(address payable) {
        return registry.admin();
    }

    function getOracle() public view returns (PriceOracle) {
        return PriceOracle(registry.oracle());
    }

    function _createPTokenNameAndSymbol(address underlying_) internal view returns (string memory, string memory) {
        string memory name = string(abi.encodePacked("DeFiPie ", EIP20Interface(underlying_).name()));
        string memory symbol = string(abi.encodePacked("p", EIP20Interface(underlying_).symbol()));
        return (name, symbol);
    }

    function calcExchangeRate(uint power) internal view returns (uint) {
        uint factor;

        if (decimals >= power) {
            factor = 10**(decimals - power);
            return initialExchangeRateMantissa.div(factor);
        } else {
            factor = 10**(power - decimals);
            return initialExchangeRateMantissa.mul(factor);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface RegistryInterface {

    /**
     *  Returns admin address for pToken contracts
     *  @return admin address
     */
    function admin() external view returns (address payable);

    /**
     *  Returns pToken factory address of protocol
     *  @return factory address
     */
    function factory() external view returns (address);

    /**
     *  Returns oracle address for protocol
     *  @return oracle address
     */
    function oracle() external view returns (address);

    /**
     *  Returns address of actual pToken implementation contract
     *  @return Address of contract
     */
    function pTokenImplementation() external view returns (address);

    /**
     *  Returns address of actual pPIE token
     *  @return Address of contract
     */
    function pPIE() external view returns (address);

    /**
     *  Returns address of actual pETH token
     *  @return Address of contract
     */
    function pETH() external view returns (address);

    function addPToken(address underlying, address pToken) external returns(uint);
    function addPETH(address pETH_) external returns(uint);
    function addPPIE(address pPIE_) external returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./ErrorReporter.sol";
import "./RegistryInterface.sol";
import "./PTokenInterfaces.sol";

contract UniswapProxyStorage {
    address public implementation;
    address public registry;
}

contract UniswapCommonStorage {
    address public WETHToken;
    uint public period;

    // asset => pair with reserves
    mapping(address => address) public assetPair;

    address[] public poolFactories;
    address[] public stableCoins;

    uint public minReserveLiquidity;
}

abstract contract UniswapCommon is UniswapProxyStorage, UniswapCommonStorage, OracleErrorReporter  {
    event PoolAdded(uint id, address poolFactory);
    event PoolRemoved(uint id, address poolFactory);
    event PoolUpdated(uint id, address poolFactory);

    event StableCoinAdded(uint id, address coin);
    event StableCoinRemoved(uint id, address coin);
    event StableCoinUpdated(uint id, address coin);

    event PriceUpdated(address asset, uint price); // price in eth

    function getCourseInETH(address asset) public view virtual returns (uint);

    function update(address asset) public virtual returns(uint);

    function searchPair(address asset) public view virtual returns (address, uint112);

    function getMyAdmin() public view returns (address) {
        return RegistryInterface(registry).admin();
    }

    function _setNewWETHAddress(address WETHToken_) external returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.UPDATE_DATA);
        }

        WETHToken = WETHToken_;

        return uint(Error.NO_ERROR);
    }

    function _setNewRegistry(address registry_) external returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.UPDATE_DATA);
        }

        registry = registry_;

        return uint(Error.NO_ERROR);
    }

    function _setPeriod(uint period_) public returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.UPDATE_DATA);
        }

        period = period_;

        return uint(Error.NO_ERROR);
    }

    function _setMinReserveLiquidity(uint minReserveLiquidity_) public returns (uint) {
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.UPDATE_DATA);
        }

        minReserveLiquidity = minReserveLiquidity_;

        return uint(Error.NO_ERROR);
    }

    function _addPool(address poolFactory_) public returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ADD_POOL_OR_COIN);
        }

        require(
            poolFactory_ != address(0)
        , 'Oracle: invalid address for factory'
        );

        for (uint i = 0; i < poolFactories.length; i++) {
            if (poolFactories[i] == poolFactory_) {
                return fail(Error.POOL_OR_COIN_EXIST, FailureInfo.ADD_POOL_OR_COIN);
            }
        }

        poolFactories.push(poolFactory_);
        uint poolId = poolFactories.length - 1;

        emit PoolAdded(poolId, poolFactory_);

        return uint(Error.NO_ERROR);
    }

    function _removePool(uint poolId) public returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.UPDATE_DATA);
        }

        require(
            poolFactories.length > 1
        , 'Oracle: must have one pool'
        );

        uint lastId = poolFactories.length - 1;

        address factory = poolFactories[lastId];
        poolFactories.pop();
        emit PoolRemoved(lastId, factory);

        if (lastId != poolId) {
            poolFactories[poolId] = factory;
            emit PoolUpdated(poolId, factory);
        }

        return uint(Error.NO_ERROR);
    }

    function _updatePool(uint poolId, address poolFactory_) public returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.UPDATE_DATA);
        }

        require(
            poolFactory_ != address(0)
            , 'Oracle: invalid address for factory'
        );

        for (uint i = 0; i < poolFactories.length; i++) {
            if (poolFactories[i] == poolFactory_) {
                return fail(Error.POOL_OR_COIN_EXIST, FailureInfo.UPDATE_DATA);
            }
        }

        poolFactories[poolId] = poolFactory_;

        emit PoolUpdated(poolId, poolFactory_);

        return uint(Error.NO_ERROR);
    }

    function _addStableCoin(address stableCoin_) public returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ADD_POOL_OR_COIN);
        }

        require(
            stableCoin_ != address(0)
            , 'Oracle: invalid address for stable coin'
        );

        for (uint i = 0; i < stableCoins.length; i++) {
            if (stableCoins[i] == stableCoin_) {
                return fail(Error.POOL_OR_COIN_EXIST, FailureInfo.ADD_POOL_OR_COIN);
            }
        }

        stableCoins.push(stableCoin_);

        emit StableCoinAdded(stableCoins.length - 1, stableCoin_);

        return uint(Error.NO_ERROR);
    }

    function _removeStableCoin(uint coinId) public returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.UPDATE_DATA);
        }

        require(
            stableCoins.length > coinId
        , 'Oracle: stable coins are empty'
        );


        uint lastId = stableCoins.length - 1;

        address stableCoin = stableCoins[lastId];
        stableCoins.pop();
        emit StableCoinRemoved(lastId, stableCoin);

        if (lastId != coinId) {
            stableCoins[coinId] = stableCoin;
            emit StableCoinUpdated(coinId, stableCoin);
        }

        return uint(Error.NO_ERROR);
    }

    function _updateStableCoin(uint coinId, address stableCoin_) public returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.UPDATE_DATA);
        }

        require(
            stableCoin_ != address(0)
        , 'Oracle: invalid address for stable coin'
        );

        for (uint i = 0; i < stableCoins.length; i++) {
            if (stableCoins[i] == stableCoin_) {
                return fail(Error.POOL_OR_COIN_EXIST, FailureInfo.UPDATE_DATA);
            }
        }

        stableCoins[coinId] = stableCoin_;

        emit StableCoinUpdated(coinId, stableCoin_);

        return uint(Error.NO_ERROR);
    }

    function getAllPoolFactories() public view returns (address[] memory) {
        return poolFactories;
    }

    function getAllStableCoins() public view returns (address[] memory) {
        return stableCoins;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./ErrorReporter.sol";
import "./RegistryInterface.sol";
import "./PriceOracle.sol";

contract PriceOracleProxyStorage {
    address public implementation;
    address public registry;
}

contract PriceOracleProxy is PriceOracleProxyStorage, OracleErrorReporter {

    /**
      * @notice Emitted when implementation is changed
      */
    event NewImplementation(address oldImplementation, address newImplementation);

    constructor(
        address implementation_,
        address registry_,
        address ethPriceFeed_
    ) {
        implementation = implementation_;
        registry = registry_;

        delegateTo(implementation, abi.encodeWithSignature("initialize(address)", ethPriceFeed_));
    }

    function _setOracleImplementation(address newImplementation) external returns(uint256) {
        if (msg.sender != RegistryInterface(registry).admin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_IMPLEMENTATION);
        }

        address oldImplementation = implementation;
        implementation = newImplementation;

        emit NewImplementation(oldImplementation, implementation);

        return(uint(Error.NO_ERROR));
    }

    /**
     * @notice Internal method to delegate execution to another contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param callee The contract to delegatecall
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateTo(address callee, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        return returnData;
    }

    function delegateAndReturn() private returns (bytes memory) {
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())

            switch success
            case 0 { revert(free_mem_ptr, returndatasize()) }
            default { return(free_mem_ptr, returndatasize()) }
        }
    }

    /**
     * @notice Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     */
    fallback() external {
        // delegate all other functions to current implementation
        delegateAndReturn();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./PriceOracle.sol";

abstract contract ControllerInterface {
    /// @notice Indicator that this is a Controller contract (for inspection)
    bool public constant isController = true;

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata pTokens) external virtual returns (uint[] memory);
    function exitMarket(address pToken) external virtual returns (uint);

    /*** Policy Hooks ***/

    function mintAllowed(address pToken, address minter, uint mintAmount) external virtual returns (uint);
    function redeemAllowed(address pToken, address redeemer, uint redeemTokens) external virtual returns (uint);
    function redeemVerify(address pToken, address redeemer, uint redeemAmount, uint redeemTokens) external virtual;
    function borrowAllowed(address pToken, address borrower, uint borrowAmount) external virtual returns (uint);

    function repayBorrowAllowed(
        address pToken,
        address payer,
        address borrower,
        uint repayAmount) external virtual returns (uint);

    function liquidateBorrowAllowed(
        address pTokenBorrowed,
        address pTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external virtual returns (uint);

    function seizeAllowed(
        address pTokenCollateral,
        address pTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external virtual returns (uint);

    function transferAllowed(address pToken, address src, address dst, uint transferTokens) external virtual returns (uint);

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address pTokenBorrowed,
        address pTokenCollateral,
        uint repayAmount) external view virtual returns (uint, uint);

    function getOracle() external view virtual returns (PriceOracle);
    function _setFeeFactor(address pToken, uint newFeeFactorMantissa) external virtual returns (uint);
    function getFeeFactorMantissa(address pToken) public view virtual returns (uint);
    function getBorrowDelay() public view virtual returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

/**
  * @title DeFiPie's InterestRateModel Interface
  * @author DeFiPie
  */
abstract contract InterestRateModel {
    /// @notice Indicator that this is an InterestRateModel contract (for inspection)
    bool public constant isInterestRateModel = true;

    /**
      * @notice Calculates the current borrow interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @return The borrow rate per block (as a percentage, and scaled by 1e18)
      */
    function getBorrowRate(uint cash, uint borrows, uint reserves) external view virtual returns (uint);

    /**
      * @notice Calculates the current supply interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @param reserveFactorMantissa The current reserve factor the market has
      * @return The supply rate per block (as a percentage, and scaled by 1e18)
      */
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) external view virtual returns (uint);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./RegistryInterface.sol";

contract ProxyWithRegistryStorage {

    /**
     * @notice Address of the registry contract
     */
    address public registry;
}

abstract contract ProxyWithRegistryInterface is ProxyWithRegistryStorage {
    function _setRegistry(address _registry) internal virtual;
    function _pTokenImplementation() internal view virtual returns (address);
}

contract ProxyWithRegistry is ProxyWithRegistryInterface {
    /**
     *  Returns actual address of the implementation contract from current registry
     *  @return registry Address of the registry
     */
    function _pTokenImplementation() internal view override returns (address) {
        return RegistryInterface(registry).pTokenImplementation();
    }

    function _setRegistry(address _registry) internal override {
        registry = _registry;
    }
}

contract ImplementationStorage {

    address public implementation;

    function _setImplementationInternal(address implementation_) internal {
        implementation = implementation_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./PTokenInterfaces.sol";
import './RegistryStorage.sol';
import "./ErrorReporter.sol";
import "./Controller.sol";
import "./PTokenFactory.sol";

contract Registry is RegistryStorage, RegistryErrorReporter {

    address public factory;
    address public pTokenImplementation;
    address public oracle;

    mapping (address => address) public pTokens;
    address public pETH;
    address public pPIE;

    /*** Admin Events ***/

    /**
     * @notice Event emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Event emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    /**
      * @notice Emitted when PTokenImplementation is changed
      */
    event NewPTokenImplementation(address oldImplementation, address newImplementation);

    /**
      * @notice Emitted when Factory address is changed
      */
    event NewFactory(address oldFactory, address newFactory);

    /**
      * @notice Emitted when Oracle address is changed
      */
    event NewOracle(address oldOracle, address newOracle);

    /**
      * @notice Emitted when admin remove pToken
      */
    event RemovePToken(address pToken);

    constructor() {}

    function initialize(address _pTokenImplementation) public {
        require(pTokenImplementation == address(0), "Registry may only be initialized once");

        pTokenImplementation = _pTokenImplementation;
    }

    /**
     *  Sets address of actual pToken implementation contract
     *  @return uint 0 = success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setPTokenImplementation(address newImplementation) external returns (uint) {
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_IMPLEMENTATION);
        }

        address oldImplementation = pTokenImplementation;
        pTokenImplementation = newImplementation;

        emit NewPTokenImplementation(oldImplementation, pTokenImplementation);

        return(uint(Error.NO_ERROR));
    }

    function _setFactoryContract(address _factory) external returns (uint) {
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_FACTORY);
        }

        address oldFactory = factory;
        factory = _factory;

        emit NewFactory(oldFactory, factory);

        return uint(Error.NO_ERROR);
    }

    function _setOracle(address _oracle) public returns (uint) {
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_ORACLE);
        }

        address oldOracle = oracle;
        oracle = _oracle;

        emit NewOracle(oldOracle, oracle);

        return uint(Error.NO_ERROR);
    }

    function addPToken(address underlying, address pToken) public returns (uint) {
        require(msg.sender == admin || msg.sender == factory, "Only admin or factory can add PTokens");

        PTokenInterface(pToken).isPToken(); // Sanity check to make sure its really a PToken

        require(pTokens[underlying] == address(0), "Token already added");
        pTokens[underlying] = pToken;

        return uint(Error.NO_ERROR);
    }

    function addPETH(address pETH_) public returns (uint) {
        require(msg.sender == admin || msg.sender == factory, "Only admin or factory can add PETH");

        PTokenInterface(pETH_).isPToken(); // Sanity check to make sure its really a PToken

        require(pETH == address(0), "ETH already added");
        pETH = pETH_;

        return uint(Error.NO_ERROR);
    }

    function addPPIE(address pPIE_) public returns (uint) {
        require(msg.sender == admin || msg.sender == factory, "Only admin or factory can add PPIE");

        PTokenInterface(pPIE_).isPToken(); // Sanity check to make sure its really a PToken

        require(pPIE == address(0), "PIE already added");
        pPIE = pPIE_;

        address underlying = PErc20Storage(pPIE).underlying();
        pTokens[underlying] = pPIE;

        return uint(Error.NO_ERROR);
    }

    function _removePToken(address pToken) public returns (uint) {
        require(msg.sender == admin, "Only admin can remove PTokens");

        PTokenInterface(pToken).isPToken(); // Sanity check to make sure its really a PToken

        address underlying = PErc20Storage(pToken).underlying();
        require(pTokens[underlying] != address(0), "Token not added");
        delete pTokens[underlying];

        emit RemovePToken(pToken);

        return uint(Error.NO_ERROR);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

contract RegistryStorage {
    address public implementation;
    address public admin;
    address public pendingAdmin;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./CarefulMath.sol";

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author DeFiPie
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract Exponential is CarefulMath {
    uint constant expScale = 1e18;
    uint constant doubleScale = 1e36;
    uint constant halfExpScale = expScale/2;
    uint constant mantissaOne = expScale;

    struct Exp {
        uint mantissa;
    }

    struct Double {
        uint mantissa;
    }

    /**
     * @dev Creates an exponential from numerator and denominator values.
     *      Note: Returns an error if (`num` * 10e18) > MAX_INT,
     *            or if `denom` is zero.
     */
    function getExp(uint num, uint denom) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint scaledNumerator) = mulUInt(num, expScale);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        (MathError err1, uint rational) = divUInt(scaledNumerator, denom);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: rational}));
    }

    /**
     * @dev Adds two exponentials, returning a new exponential.
     */
    function addExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        (MathError error, uint result) = addUInt(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

    /**
     * @dev Subtracts two exponentials, returning a new exponential.
     */
    function subExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        (MathError error, uint result) = subUInt(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

    /**
     * @dev Multiply an Exp by a scalar, returning a new Exp.
     */
    function mulScalar(Exp memory a, uint scalar) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint scaledMantissa) = mulUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: scaledMantissa}));
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mulScalarTruncate(Exp memory a, uint scalar) pure internal returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(product));
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mulScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) pure internal returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return addUInt(truncate(product), addend);
    }

    /**
     * @dev Divide an Exp by a scalar, returning a new Exp.
     */
    function divScalar(Exp memory a, uint scalar) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint descaledMantissa) = divUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: descaledMantissa}));
    }

    /**
     * @dev Divide a scalar by an Exp, returning a new Exp.
     */
    function divScalarByExp(uint scalar, Exp memory divisor) pure internal returns (MathError, Exp memory) {
        /*
          We are doing this as:
          getExp(mulUInt(expScale, scalar), divisor.mantissa)

          How it works:
          Exp = a / b;
          Scalar = s;
          `s / (a / b)` = `b * s / a` and since for an Exp `a = mantissa, b = expScale`
        */
        (MathError err0, uint numerator) = mulUInt(expScale, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }
        return getExp(numerator, divisor.mantissa);
    }

    /**
     * @dev Divide a scalar by an Exp, then truncate to return an unsigned integer.
     */
    function divScalarByExpTruncate(uint scalar, Exp memory divisor) pure internal returns (MathError, uint) {
        (MathError err, Exp memory fraction_) = divScalarByExp(scalar, divisor);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(fraction_));
    }

    /**
     * @dev Multiplies two exponentials, returning a new exponential.
     */
    function mulExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {

        (MathError err0, uint doubleScaledProduct) = mulUInt(a.mantissa, b.mantissa);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        // We add half the scale before dividing so that we get rounding instead of truncation.
        //  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
        // Without this change, a result like 6.6...e-19 will be truncated to 0 instead of being rounded to 1e-18.
        (MathError err1, uint doubleScaledProductWithHalfScale) = addUInt(halfExpScale, doubleScaledProduct);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        (MathError err2, uint product) = divUInt(doubleScaledProductWithHalfScale, expScale);
        // The only error `div` can return is MathError.DIVISION_BY_ZERO but we control `expScale` and it is not zero.
        assert(err2 == MathError.NO_ERROR);

        return (MathError.NO_ERROR, Exp({mantissa: product}));
    }

    /**
     * @dev Multiplies two exponentials given their mantissas, returning a new exponential.
     */
    function mulExp(uint a, uint b) pure internal returns (MathError, Exp memory) {
        return mulExp(Exp({mantissa: a}), Exp({mantissa: b}));
    }

    /**
     * @dev Multiplies three exponentials, returning a new exponential.
     */
    function mulExp3(Exp memory a, Exp memory b, Exp memory c) pure internal returns (MathError, Exp memory) {
        (MathError err, Exp memory ab) = mulExp(a, b);
        if (err != MathError.NO_ERROR) {
            return (err, ab);
        }
        return mulExp(ab, c);
    }

    /**
     * @dev Divides two exponentials, returning a new exponential.
     *     (a/scale) / (b/scale) = (a/scale) * (scale/b) = a/b,
     *  which we can scale as an Exp by calling getExp(a.mantissa, b.mantissa)
     */
    function divExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        return getExp(a.mantissa, b.mantissa);
    }

    /**
     * @dev Truncates the given exp to a whole number value.
     *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
     */
    function truncate(Exp memory exp) pure internal returns (uint) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / expScale;
    }

    /**
     * @dev Checks if first Exp is less than second Exp.
     */
    function lessThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa < right.mantissa;
    }

    /**
     * @dev Checks if left Exp <= right Exp.
     */
    function lessThanOrEqualExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa <= right.mantissa;
    }

    /**
     * @dev Checks if left Exp > right Exp.
     */
    function greaterThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa > right.mantissa;
    }

    /**
     * @dev returns true if Exp is exactly zero
     */
    function isZeroExp(Exp memory value) pure internal returns (bool) {
        return value.mantissa == 0;
    }

    function safe224(uint n, string memory errorMessage) pure internal returns (uint224) {
        require(n < 2**224, errorMessage);
        return uint224(n);
    }

    function safe32(uint n, string memory errorMessage) pure internal returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function add_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(uint a, uint b) pure internal returns (uint) {
        return add_(a, b, "addition overflow");
    }

    function add_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(uint a, uint b) pure internal returns (uint) {
        return sub_(a, b, "subtraction underflow");
    }

    function sub_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function mul_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b.mantissa) / expScale});
    }

    function mul_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Exp memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / expScale;
    }

    function mul_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b.mantissa) / doubleScale});
    }

    function mul_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Double memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / doubleScale;
    }

    function mul_(uint a, uint b) pure internal returns (uint) {
        return mul_(a, b, "multiplication overflow");
    }

    function mul_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, errorMessage);
        return c;
    }

    function div_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(mul_(a.mantissa, expScale), b.mantissa)});
    }

    function div_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Exp memory b) pure internal returns (uint) {
        return div_(mul_(a, expScale), b.mantissa);
    }

    function div_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a.mantissa, doubleScale), b.mantissa)});
    }

    function div_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Double memory b) pure internal returns (uint) {
        return div_(mul_(a, doubleScale), b.mantissa);
    }

    function div_(uint a, uint b) pure internal returns (uint) {
        return div_(a, b, "divide by zero");
    }

    function div_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function fraction(uint a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a, doubleScale), b)});
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./PriceOracle.sol";
import './RegistryInterface.sol';

contract UnitrollerAdminStorage {
    /**
    * @notice Administrator for this contract in registry
    */
    RegistryInterface public registry;

    /**
    * @notice Active brains of Unitroller
    */
    address public controllerImplementation;

    /**
    * @notice Pending brains of Unitroller
    */
    address public pendingControllerImplementation;
}

contract ControllerStorage is UnitrollerAdminStorage {
    /**
     * @notice Oracle which gives the price of any given asset
     */
    PriceOracle public oracle;

    /**
     * @notice Multiplier used to calculate the maximum repayAmount when liquidating a borrow
     */
    uint public closeFactorMantissa;

    /**
     * @notice Multiplier representing the discount on collateral that a liquidator receives
     */
    uint public liquidationIncentiveMantissa;

    /**
     * @notice Max number of assets a single account can participate in (borrow or use as collateral)
     */
    uint public maxAssets;

    /**
     * @notice Per-account mapping of "assets you are in", capped by maxAssets
     */
    mapping(address => address[]) public accountAssets;

    /// @notice isListed Whether or not this market is listed
    /**
     * @notice collateralFactorMantissa Multiplier representing the most one can borrow against their collateral in this market.
     *  For instance, 0.9 to allow borrowing 90% of collateral value.
     *  Must be between 0 and 1, and stored as a mantissa.
     */
    /// @notice accountMembership Per-market mapping of "accounts in this asset"
    /// @notice isPied Whether or not this market receives PIE
    struct Market {
        bool isListed;
        uint collateralFactorMantissa;
        mapping(address => bool) accountMembership;
        bool isPied;
    }

    /**
     * @notice Official mapping of pTokens -> Market metadata
     * @dev Used e.g. to determine if a market is supported
     */
    mapping(address => Market) public markets;

    /**
     * @notice The Pause Guardian can pause certain actions as a safety mechanism.
     *  Actions which allow users to remove their own assets cannot be paused.
     *  Liquidation / seizing / transfer can only be paused globally, not by market.
     */
    address public pauseGuardian;
    bool public _mintGuardianPaused;
    bool public _borrowGuardianPaused;
    bool public transferGuardianPaused;
    bool public seizeGuardianPaused;
    mapping(address => bool) public mintGuardianPaused;
    mapping(address => bool) public borrowGuardianPaused;

    /// @notice index The market's last updated pieBorrowIndex or pieSupplyIndex
    /// @notice block The block number the index was last updated at
    struct PieMarketState {
        uint224 index;
        uint32 block;
    }

    /// @notice A list of all markets
    address[] public allMarkets;

    /// @notice The rate at which the flywheel distributes PIE, per block
    uint public pieRate;

    /// @notice Address of the PIE token
    address public pieAddress;

    // @notice Address of the factory
    address public factory;

    /// @notice The portion of pieRate that each market currently receives
    mapping(address => uint) public pieSpeeds;

    /// @notice The PIE market supply state for each market
    mapping(address => PieMarketState) public pieSupplyState;

    /// @notice The PIE market borrow state for each market
    mapping(address => PieMarketState) public pieBorrowState;

    /// @notice The PIE borrow index for each market for each supplier as of the last time they accrued PIE
    mapping(address => mapping(address => uint)) public pieSupplierIndex;

    /// @notice The PIE borrow index for each market for each borrower as of the last time they accrued PIE
    mapping(address => mapping(address => uint)) public pieBorrowerIndex;

    /// @notice The PIE accrued but not yet transferred to each user
    mapping(address => uint) public pieAccrued;

    /// @notice Only the Liquidate guardian can liquidate loans with collateral below the loan amount
    address public liquidateGuardian;

    /// @notice Multiplier representing the bonus on collateral that a liquidator receives for fee tokens
    mapping(address => uint) public feeFactorMantissa;

    // Max value of fee factor can be set for fee factor
    uint public feeFactorMaxMantissa;

    // Value of borrow delay for markets
    uint public borrowDelay;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./ErrorReporter.sol";
import "./ControllerStorage.sol";

/**
 * @title ControllerCore
 * @dev Storage for the controller is at this address, while execution is delegated to the `controllerImplementation`.
 * PTokens should reference this contract as their controller.
 */
contract Unitroller is UnitrollerAdminStorage, ControllerErrorReporter {

    /**
      * @notice Emitted when pendingControllerImplementation is changed
      */
    event NewPendingImplementation(address oldPendingImplementation, address newPendingImplementation);

    /**
      * @notice Emitted when pendingControllerImplementation is accepted, which means controller implementation is updated
      */
    event NewImplementation(address oldImplementation, address newImplementation);

    constructor(address registry_) {
        registry = RegistryInterface(registry_);
    }

    /*** Admin Functions ***/
    function _setPendingImplementation(address newPendingImplementation) public returns (uint) {

        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PENDING_IMPLEMENTATION_OWNER_CHECK);
        }

        address oldPendingImplementation = pendingControllerImplementation;

        pendingControllerImplementation = newPendingImplementation;

        emit NewPendingImplementation(oldPendingImplementation, pendingControllerImplementation);

        return uint(Error.NO_ERROR);
    }

    /**
    * @notice Accepts new implementation of controller. msg.sender must be pendingImplementation
    * @dev Admin function for new implementation to accept it's role as implementation
    * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
    */
    function _acceptImplementation() public returns (uint) {
        // Check caller is pendingImplementation and pendingImplementation ≠ address(0)
        if (msg.sender != pendingControllerImplementation || pendingControllerImplementation == address(0)) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK);
        }

        // Save current values for inclusion in log
        address oldImplementation = controllerImplementation;
        address oldPendingImplementation = pendingControllerImplementation;

        controllerImplementation = pendingControllerImplementation;

        pendingControllerImplementation = address(0);

        emit NewImplementation(oldImplementation, controllerImplementation);
        emit NewPendingImplementation(oldPendingImplementation, pendingControllerImplementation);

        return uint(Error.NO_ERROR);
    }

    function getAdmin() public view returns(address payable) {
        return registry.admin();
    }

    /**
     * @dev Delegates execution to an implementation contract.
     * It returns to the external caller whatever the implementation returns
     * or forwards reverts.
     */
    fallback() payable external {
        // delegate all other functions to current implementation
        (bool success, ) = controllerImplementation.delegatecall(msg.data);

        assembly {
        let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())

            switch success
            case 0 { revert(free_mem_ptr, returndatasize()) }
            default { return(free_mem_ptr, returndatasize()) }
        }
    }

    receive() payable external {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

/**
  * @title Careful Math
  * @author DeFiPie
  * @notice Derived from OpenZeppelin's SafeMath library
  *         https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
  */
contract CarefulMath {

    /**
     * @dev Possible error codes that we can return
     */
    enum MathError {
        NO_ERROR,
        DIVISION_BY_ZERO,
        INTEGER_OVERFLOW,
        INTEGER_UNDERFLOW
    }

    /**
    * @dev Multiplies two numbers, returns an error on overflow.
    */
    function mulUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (a == 0) {
            return (MathError.NO_ERROR, 0);
        }

        uint c = a * b;

        if (c / a != b) {
            return (MathError.INTEGER_OVERFLOW, 0);
        } else {
            return (MathError.NO_ERROR, c);
        }
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function divUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b == 0) {
            return (MathError.DIVISION_BY_ZERO, 0);
        }

        return (MathError.NO_ERROR, a / b);
    }

    /**
    * @dev Subtracts two numbers, returns an error on overflow (i.e. if subtrahend is greater than minuend).
    */
    function subUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b <= a) {
            return (MathError.NO_ERROR, a - b);
        } else {
            return (MathError.INTEGER_UNDERFLOW, 0);
        }
    }

    /**
    * @dev Adds two numbers, returns an error on overflow.
    */
    function addUInt(uint a, uint b) internal pure returns (MathError, uint) {
        uint c = a + b;

        if (c >= a) {
            return (MathError.NO_ERROR, c);
        } else {
            return (MathError.INTEGER_OVERFLOW, 0);
        }
    }

    /**
    * @dev add a and b and then subtract c
    */
    function addThenSubUInt(uint a, uint b, uint c) internal pure returns (MathError, uint) {
        (MathError err0, uint sum) = addUInt(a, b);

        if (err0 != MathError.NO_ERROR) {
            return (err0, 0);
        }

        return subUInt(sum, c);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./ProxyWithRegistry.sol";
import "./RegistryInterface.sol";

/**
 * @title DeFiPie's PErc20Delegator Contract
 * @notice PTokens which wrap an EIP-20 underlying and delegate to an implementation
 * @author DeFiPie
 */
contract PErc20Delegator is ProxyWithRegistry {

    /**
     * @notice Construct a new money market
     * @param underlying_ The address of the underlying asset
     * @param controller_ The address of the Controller
     * @param interestRateModel_ The address of the interest rate model
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param initialReserveFactorMantissa_ The initial reserve factor, scaled by 1e18
     * @param name_ ERC-20 name of this token
     * @param symbol_ ERC-20 symbol of this token
     * @param decimals_ ERC-20 decimal precision of this token
     * @param registry_ The address of the registry contract
     */
    constructor(
        address underlying_,
        address controller_,
        address interestRateModel_,
        uint initialExchangeRateMantissa_,
        uint initialReserveFactorMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address registry_
    ) {
        // Set registry
        _setRegistry(registry_);

        // First delegate gets to initialize the delegator (i.e. storage contract)
        delegateTo(_pTokenImplementation(), abi.encodeWithSignature("initialize(address,address,address,address,uint256,uint256,string,string,uint8)",
                                                            underlying_,
                                                            registry_,
                                                            controller_,
                                                            interestRateModel_,
                                                            initialExchangeRateMantissa_,
                                                            initialReserveFactorMantissa_,
                                                            name_,
                                                            symbol_,
                                                            decimals_));
    }

    /**
     * @notice Internal method to delegate execution to another contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param callee The contract to delegatecall
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateTo(address callee, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        return returnData;
    }

    function delegateAndReturn() internal returns (bytes memory) {
        (bool success, ) = _pTokenImplementation().delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())

            switch success
            case 0 { revert(free_mem_ptr, returndatasize()) }
            default { return(free_mem_ptr, returndatasize()) }
        }
    }

    /**
     * @notice Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     */
    fallback() external {
        // delegate all other functions to current implementation
        delegateAndReturn();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./ProxyWithRegistry.sol";
import "./RegistryInterface.sol";
import "./ErrorReporter.sol";

/**
 * @title DeFiPie's PETHDelegator Contract
 * @notice PETH which wrap a delegate to an implementation
 * @author DeFiPie
 */
contract PETHDelegator is ImplementationStorage, ProxyWithRegistry, TokenErrorReporter {

    /**
      * @notice Emitted when implementation is changed
      */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Construct a new money market
     * @param pETHImplementation_ The address of the PEthImplementation
     * @param controller_ The address of the Controller
     * @param interestRateModel_ The address of the interest rate model
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param initialReserveFactorMantissa_ The initial reserve factor, scaled by 1e18
     * @param name_ ERC-20 name of this token
     * @param symbol_ ERC-20 symbol of this token
     * @param decimals_ ERC-20 decimal precision of this token
     * @param registry_ The address of the registry contract
     */
    constructor(
        address pETHImplementation_,
        address controller_,
        address interestRateModel_,
        uint initialExchangeRateMantissa_,
        uint initialReserveFactorMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address registry_
    ) {
        // Set registry
        _setRegistry(registry_);
        _setImplementationInternal(pETHImplementation_);

        // First delegate gets to initialize the delegator (i.e. storage contract)
        delegateTo(implementation, abi.encodeWithSignature("initialize(address,address,address,uint256,uint256,string,string,uint8)",
                                                            registry_,
                                                            controller_,
                                                            interestRateModel_,
                                                            initialExchangeRateMantissa_,
                                                            initialReserveFactorMantissa_,
                                                            name_,
                                                            symbol_,
                                                            decimals_));
    }

    /**
     * @notice Internal method to delegate execution to another contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param callee The contract to delegatecall
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateTo(address callee, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        return returnData;
    }

    function delegateAndReturn() private returns (bytes memory) {
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())

            switch success
            case 0 { revert(free_mem_ptr, returndatasize()) }
            default { return(free_mem_ptr, returndatasize()) }
        }
    }

    /**
     * @notice Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     */
    fallback() external payable {
        // delegate all other functions to current implementation
        delegateAndReturn();
    }

    receive() external payable {
        // delegate all other functions to current implementation
        delegateAndReturn();
    }

    function _setImplementation(address newImplementation) external returns(uint) {
        if (msg.sender != RegistryInterface(registry).admin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_IMPLEMENTATION);
        }

        address oldImplementation = implementation;
        _setImplementationInternal(newImplementation);

        emit NewImplementation(oldImplementation, implementation);

        return(uint(Error.NO_ERROR));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./ProxyWithRegistry.sol";
import "./RegistryInterface.sol";
import "./ErrorReporter.sol";

/**
 * @title DeFiPie's PPIEDelegator Contract
 * @notice PPIE which wrap an EIP-20 underlying and delegate to an implementation
 * @author DeFiPie
 */
contract PPIEDelegator is ImplementationStorage, ProxyWithRegistry, TokenErrorReporter {

    /**
      * @notice Emitted when implementation is changed
      */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Construct a new money market
     * @param underlying_ The address of the underlying asset
     * @param pPIEImplementation_ The address of the PPIEImplementation
     * @param controller_ The address of the Controller
     * @param interestRateModel_ The address of the interest rate model
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param initialReserveFactorMantissa_ The initial reserve factor, scaled by 1e18
     * @param name_ ERC-20 name of this token
     * @param symbol_ ERC-20 symbol of this token
     * @param decimals_ ERC-20 decimal precision of this token
     * @param registry_ The address of the registry contract
     */
    constructor(
        address underlying_,
        address pPIEImplementation_,
        address controller_,
        address interestRateModel_,
        uint initialExchangeRateMantissa_,
        uint initialReserveFactorMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address registry_
    ) {
        // Set registry
        _setRegistry(registry_);
        _setImplementationInternal(pPIEImplementation_);

        // First delegate gets to initialize the delegator (i.e. storage contract)
        delegateTo(implementation, abi.encodeWithSignature("initialize(address,address,address,address,uint256,uint256,string,string,uint8)",
                                                        underlying_,
                                                        registry_,
                                                        controller_,
                                                        interestRateModel_,
                                                        initialExchangeRateMantissa_,
                                                        initialReserveFactorMantissa_,
                                                        name_,
                                                        symbol_,
                                                        decimals_));
    }

    /**
     * @notice Internal method to delegate execution to another contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param callee The contract to delegatecall
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateTo(address callee, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        return returnData;
    }

    function delegateAndReturn() internal returns (bytes memory) {
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())

            switch success
            case 0 { revert(free_mem_ptr, returndatasize()) }
            default { return(free_mem_ptr, returndatasize()) }
        }
    }

    /**
     * @notice Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     */
    fallback() external {
        // delegate all other functions to current implementation
        delegateAndReturn();
    }

    function _setImplementation(address newImplementation) external returns (uint) {
        if (msg.sender != RegistryInterface(registry).admin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_IMPLEMENTATION);
        }

        address oldImplementation = implementation;
        _setImplementationInternal(newImplementation);

        emit NewImplementation(oldImplementation, implementation);

        return(uint(Error.NO_ERROR));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

import './FullMath.sol';
import './TickMath.sol';
import './IUniswapV3Pool.sol';

/// @title Oracle library
/// @notice Provides functions to integrate with V3 pool oracle
library OracleLibrary {
    /// @notice Calculates time-weighted means of tick and liquidity for a given Uniswap V3 pool
    /// @param pool Address of the pool that we want to observe
    /// @param secondsAgo Number of seconds in the past from which to calculate the time-weighted means
    /// @return arithmeticMeanTick The arithmetic mean tick from (block.timestamp - secondsAgo) to block.timestamp
    /// @return harmonicMeanLiquidity The harmonic mean liquidity from (block.timestamp - secondsAgo) to block.timestamp
    function consult(address pool, uint32 secondsAgo)
        internal
        view
        returns (int24 arithmeticMeanTick, uint128 harmonicMeanLiquidity)
    {
        require(secondsAgo != 0, 'BP');

        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = secondsAgo;
        secondsAgos[1] = 0;

        (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s) =
        IUniswapV3Pool(pool).observe(secondsAgos);

        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
        uint160 secondsPerLiquidityCumulativesDelta =
        secondsPerLiquidityCumulativeX128s[1] - secondsPerLiquidityCumulativeX128s[0];

        arithmeticMeanTick = int24(tickCumulativesDelta / secondsAgo);
        // Always round to negative infinity
        if (tickCumulativesDelta < 0 && (tickCumulativesDelta % secondsAgo != 0)) arithmeticMeanTick--;

        // We are multiplying here instead of shifting to ensure that harmonicMeanLiquidity doesn't overflow uint128
        uint192 secondsAgoX160 = uint192(secondsAgo) * type(uint160).max;
        harmonicMeanLiquidity = uint128(secondsAgoX160 / (uint192(secondsPerLiquidityCumulativesDelta) << 32));
    }

    /// @notice Given a tick and a token amount, calculates the amount of token received in exchange
    /// @param tick Tick value used to calculate the quote
    /// @param baseAmount Amount of token to be converted
    /// @param baseToken Address of an ERC20 token contract used as the baseAmount denomination
    /// @param quoteToken Address of an ERC20 token contract used as the quoteAmount denomination
    /// @return quoteAmount Amount of quoteToken received for baseAmount of baseToken
    function getQuoteAtTick(
        int24 tick,
        uint128 baseAmount,
        address baseToken,
        address quoteToken
    ) internal pure returns (uint256 quoteAmount) {
        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);

        // Calculate quoteAmount with better precision if it doesn't overflow when multiplied by itself
        if (sqrtRatioX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
            quoteAmount = baseToken < quoteToken
            ? FullMath.mulDiv(ratioX192, baseAmount, 1 << 192)
            : FullMath.mulDiv(1 << 192, baseAmount, ratioX192);
        } else {
            uint256 ratioX128 = FullMath.mulDiv(sqrtRatioX96, sqrtRatioX96, 1 << 64);
            quoteAmount = baseToken < quoteToken
            ? FullMath.mulDiv(ratioX128, baseAmount, 1 << 128)
            : FullMath.mulDiv(1 << 128, baseAmount, ratioX128);
        }
    }

    /// @notice Given a pool, it returns the number of seconds ago of the oldest stored observation
    /// @param pool Address of Uniswap V3 pool that we want to observe
    /// @return secondsAgo The number of seconds ago of the oldest observation stored for the pool
    function getOldestObservationSecondsAgo(address pool) internal view returns (uint32 secondsAgo) {
        (, , uint16 observationIndex, uint16 observationCardinality, , , ) = IUniswapV3Pool(pool).slot0();
        require(observationCardinality > 0, 'NI');

        (uint32 observationTimestamp, , , bool initialized) =
        IUniswapV3Pool(pool).observations((observationIndex + 1) % observationCardinality);

        // The next index might not be initialized if the cardinality is in the process of increasing
        // In this case the oldest observation is always in index 0
        if (!initialized) {
            (observationTimestamp, , , ) = IUniswapV3Pool(pool).observations(0);
        }

        secondsAgo = uint32(block.timestamp) - observationTimestamp;
    }

    /// @notice Given a pool, it returns the tick value as of the start of the current block
    /// @param pool Address of Uniswap V3 pool
    /// @return The tick that the pool was in at the start of the current block
    function getBlockStartingTickAndLiquidity(address pool) internal view returns (int24, uint128) {
        (, int24 tick, uint16 observationIndex, uint16 observationCardinality, , , ) = IUniswapV3Pool(pool).slot0();

        // 2 observations are needed to reliably calculate the block starting tick
        require(observationCardinality > 1, 'NEO');

        // If the latest observation occurred in the past, then no tick-changing trades have happened in this block
        // therefore the tick in `slot0` is the same as at the beginning of the current block.
        // We don't need to check if this observation is initialized - it is guaranteed to be.
        (uint32 observationTimestamp, int56 tickCumulative, uint160 secondsPerLiquidityCumulativeX128, ) =
        IUniswapV3Pool(pool).observations(observationIndex);
        if (observationTimestamp != uint32(block.timestamp)) {
            return (tick, IUniswapV3Pool(pool).liquidity());
        }

        uint256 prevIndex = (uint256(observationIndex) + observationCardinality - 1) % observationCardinality;
        (
        uint32 prevObservationTimestamp,
        int56 prevTickCumulative,
        uint160 prevSecondsPerLiquidityCumulativeX128,
        bool prevInitialized
        ) = IUniswapV3Pool(pool).observations(prevIndex);

        require(prevInitialized, 'ONI');

        uint32 delta = observationTimestamp - prevObservationTimestamp;
        tick = int24((tickCumulative - prevTickCumulative) / delta);
        uint128 liquidity =
        uint128(
            (uint192(delta) * type(uint160).max) /
            (uint192(secondsPerLiquidityCumulativeX128 - prevSecondsPerLiquidityCumulativeX128) << 32)
        );
        return (tick, liquidity);
    }

    /// @notice Information for calculating a weighted arithmetic mean tick
    struct WeightedTickData {
        int24 tick;
        uint128 weight;
    }

    /// @notice Given an array of ticks and weights, calculates the weighted arithmetic mean tick
    /// @param weightedTickData An array of ticks and weights
    /// @return weightedArithmeticMeanTick The weighted arithmetic mean tick
    /// @dev Each entry of `weightedTickData` should represents ticks from pools with the same underlying pool tokens. If they do not,
    /// extreme care must be taken to ensure that ticks are comparable (including decimal differences).
    /// @dev Note that the weighted arithmetic mean tick corresponds to the weighted geometric mean price.
    function getWeightedArithmeticMeanTick(WeightedTickData[] memory weightedTickData)
        internal
        pure
        returns (int24 weightedArithmeticMeanTick)
    {
        // Accumulates the sum of products between each tick and its weight
        int256 numerator;

        // Accumulates the sum of the weights
        uint256 denominator;

        // Products fit in 152 bits, so it would take an array of length ~2**104 to overflow this logic
        for (uint256 i; i < weightedTickData.length; i++) {
            numerator += weightedTickData[i].tick * int256(weightedTickData[i].weight);
            denominator += weightedTickData[i].weight;
        }

        weightedArithmeticMeanTick = int24(numerator / int256(denominator));
        // Always round to negative infinity
        if (numerator < 0 && (numerator % int256(denominator) != 0)) weightedArithmeticMeanTick--;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(abi.encode(key.token0, key.token1, key.fee)),
                        POOL_INIT_CODE_HASH
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

import './FullMath.sol';

library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
    /// @notice Downcasts uint256 to uint128
    /// @param x The uint258 to be downcasted
    /// @return y The passed value, downcasted to uint128
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        return toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount of token0 being sent in
    /// @param amount1 The amount of token1 being sent in
    /// @return liquidity The maximum amount of liquidity received
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
        FullMath.mulDiv(
            uint256(liquidity) << FixedPoint96.RESOLUTION,
            sqrtRatioBX96 - sqrtRatioAX96,
            sqrtRatioBX96
        ) / sqrtRatioAX96;
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount of token1
    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
    }

    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
        } else {
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import './Registry.sol';
import "./Interfaces/IPriceFeeds.sol";

contract UniswapV3PriceOracleStorageV1 {
    uint24[] public feeArray;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = -denominator & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(MAX_TICK), 'T');

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

/// @title pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

/// @title pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
    external
    view
    returns (
        uint160 sqrtPriceX96,
        int24 tick,
        uint16 observationIndex,
        uint16 observationCardinality,
        uint16 observationCardinalityNext,
        uint8 feeProtocol,
        bool unlocked
    );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
    external
    view
    returns (
        uint128 liquidityGross,
        int128 liquidityNet,
        uint256 feeGrowthOutside0X128,
        uint256 feeGrowthOutside1X128,
        int56 tickCumulativeOutside,
        uint160 secondsPerLiquidityOutsideX128,
        uint32 secondsOutside,
        bool initialized
    );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
    external
    view
    returns (
        uint128 _liquidity,
        uint256 feeGrowthInside0LastX128,
        uint256 feeGrowthInside1LastX128,
        uint128 tokensOwed0,
        uint128 tokensOwed1
    );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
    external
    view
    returns (
        uint32 blockTimestamp,
        int56 tickCumulative,
        uint160 secondsPerLiquidityCumulativeX128,
        bool initialized
    );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

/// @title pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
    external
    view
    returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
    external
    view
    returns (
        int56 tickCumulativeInside,
        uint160 secondsPerLiquidityInsideX128,
        uint32 secondsInside
    );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}