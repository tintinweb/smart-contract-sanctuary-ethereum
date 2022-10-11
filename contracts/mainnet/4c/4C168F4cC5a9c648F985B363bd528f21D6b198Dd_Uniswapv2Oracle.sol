// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {PriceLibrary as Prices} from "../libs/PriceLibrary.sol";
import "../libs/FixedPoint.sol";
import "../recipe/UniswapV2Library.sol";
import "../interfaces/IUsdcOracle.sol";

contract Uniswapv2Oracle is IUsdcOracle, AccessControl {
    /* ==========  Libraries  ========== */

    using Prices for address;
    using Prices for Prices.PriceObservation;
    using Prices for Prices.TwoWayAveragePrice;
    using FixedPoint for FixedPoint.uq112x112;
    using FixedPoint for FixedPoint.uq144x112;

    /* ==========  Constants  ========== */

    // Period over which prices are observed, each period should have 1 price observation.
    // Minimum time elapsed between price observations
    uint32 public immutable MINIMUM_OBSERVATION_DELAY;

    address public immutable USDC; // 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public immutable WETH; // 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public immutable uniswapFactory; // 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    uint32 public immutable maxObservationAge;

    /* ==========  Storage  ========== */

    uint32 public observationPeriod;
    // Price observations for tokens indexed by time period.
    mapping(address => mapping(uint256 => Prices.PriceObservation)) internal priceObservations;

    /* ==========  Events  ========== */

    event PriceUpdated(
        address indexed token,
        uint224 tokenPriceCumulativeLast,
        uint224 ethPriceCumulativeLast
    );

    /* ==========  Constructor  ========== */

    constructor(address _uniswapFactory, uint32 _initialObservationPeriod, address _usdc, address _weth) {
        require(_uniswapFactory != address(0), "ERR_UNISWAPV2_FACTORY_INIT");
        require(_weth!= address(0), "ERR_WETH_INIT");
        uniswapFactory = _uniswapFactory;
        USDC = _usdc;
        WETH = _weth;
        observationPeriod = _initialObservationPeriod;
        MINIMUM_OBSERVATION_DELAY = _initialObservationPeriod / 2;
        maxObservationAge = _initialObservationPeriod * 2;
    }

    /* ==========  External Functions  ========== */

    function getLastPriceObservation(address token)
        external
        view
        returns (Prices.PriceObservation memory)
    {
        Prices.PriceObservation memory current = Prices.observeTwoWayPrice(
            uniswapFactory,
            token,
            WETH
        );
        Prices.PriceObservation memory previous = _getLatestUsableObservation(
            token,
            current.timestamp
        );
        return previous;
    }

    /**
     * @dev Gets the price observation at `observationIndex` for `token`.
     *
     * Note: This does not assert that there is an observation for that index,
     * this should be verified by the recipient.
     */
    function getPriceObservation(address token, uint256 observationIndex)
        external
        view
        returns (Prices.PriceObservation memory)
    {
        return priceObservations[token][observationIndex];
    }

    function canUpdatePrice(address token) external view returns (bool) {
        Prices.PriceObservation memory newObservation = Prices
            .observeTwoWayPrice(uniswapFactory, token, WETH);
        // We use the observation's timestamp rather than `now` because the
        // UniSwap pair may not have updated the price this block.
        uint256 observationIndex = observationIndexOf(newObservation.timestamp);
        // If this period already has an observation, return false.
        if (priceObservations[token][observationIndex].timestamp != 0)
            return false;
        // An observation can be made if the last update was at least half a period ago.
        uint32 timeElapsed = newObservation.timestamp -
            priceObservations[token][observationIndex - 1].timestamp;
        return timeElapsed >= MINIMUM_OBSERVATION_DELAY;
    }

    /**
     * @dev Returns the TwoWayAveragePrice structs representing the average price of
     * weth in terms of each token in `tokens` and the average price of each token
     * in terms of weth.
     *
     * Note: Requires that the token has a price observation between 0.5
     * and 2 periods old.
     */
    function computeTwoWayAveragePrices(address[] memory tokens)
        external
        view
        returns (Prices.TwoWayAveragePrice[] memory averagePrices, uint256 earliestTimestamp)
    {
        uint256 len = tokens.length;
        averagePrices = new Prices.TwoWayAveragePrice[](len);
        uint256 timestamp;
        for (uint256 i = 0; i < len; i++) {
            (averagePrices[i], timestamp) = computeTwoWayAveragePrice(tokens[i]);
            if (timestamp < earliestTimestamp) {
                earliestTimestamp = timestamp;
            }
        }
    }

    function canUpdateTokenPrices() external pure override returns (bool) {
        return true;
    }

    /**
     * @dev Updates the prices of multiple tokens.
     *
     * @return updates Array of boolean values indicating which tokens
     * successfully updated their prices.
     */
    function updateTokenPrices(address[] memory tokens)
        external
        returns (bool[] memory updates)
    {
        updateWethPrice();
        updates = new bool[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            updates[i] = updatePrice(tokens[i]);
        }
    }

    function tokenETHValue(address tokenIn, uint256 amount)
        external
        view
        returns (uint256, uint256)
    {
        if (tokenIn == WETH) {
            return (amount, block.timestamp);
        }

        return computeAverageAmountIn(tokenIn, amount);
    }

    /**
     * @dev Returns the UQ112x112 structs representing the average price of
     * weth in terms of each token in `tokens`.
     */
    function computeAverageEthPrices(address[] memory tokens)
        external
        view
        returns (FixedPoint.uq112x112[] memory averagePrices, uint256 earliestTimestamp)
    {
        uint256 len = tokens.length;
        averagePrices = new FixedPoint.uq112x112[](len);
        uint256 timestamp;
        for (uint256 i = 0; i < len; i++) {
            (averagePrices[i], timestamp) = computeAverageEthPrice(tokens[i]);
            if (timestamp < earliestTimestamp) {
                earliestTimestamp = timestamp;
            }
        }
    }

    /* ==========  Public  Functions  ========== */

    /*
     * @dev Updates the latest price observation for a token if allowable.
     *
     * Note: The price can only be updated once per period, and price
     * observations must be made at least half a period apart.
     *
     * @param token Token to update the price of
     * @return didUpdate Whether the token price was updated.
     */
    // update weth price in usdc
    function updateWethPrice() public returns (bool) {
        Prices.PriceObservation memory newObservation = Prices
            .observeTwoWayPrice(uniswapFactory, WETH, USDC);
        // We use the observation's timestamp rather than `now` because the
        // UniSwap pair may not have updated the price this block.
        uint256 observationIndex = observationIndexOf(newObservation.timestamp);

        Prices.PriceObservation storage current = priceObservations[WETH][
            observationIndex
        ];
        if (current.timestamp != 0) {
            // If an observation has already been made for this period, do not update.
            return false;
        }

        Prices.PriceObservation memory previous = priceObservations[WETH][
            observationIndex - 1
        ];
        uint256 timeElapsed = newObservation.timestamp - previous.timestamp;
        if (timeElapsed < MINIMUM_OBSERVATION_DELAY) {
            // If less than half a period has passed since the previous observation, do not update.
            return false;
        }
        priceObservations[WETH][observationIndex] = newObservation;
        emit PriceUpdated(
            WETH,
            newObservation.priceCumulativeLast,
            newObservation.ethPriceCumulativeLast
        );
        return true;
    }

    function updatePrice(address token) public returns (bool) {
        if (token == WETH) return true;

        Prices.PriceObservation memory newObservation = Prices
            .observeTwoWayPrice(uniswapFactory, token, WETH);
        // We use the observation's timestamp rather than `now` because the
        // UniSwap pair may not have updated the price this block.
        uint256 observationIndex = observationIndexOf(newObservation.timestamp);

        Prices.PriceObservation storage current = priceObservations[token][
            observationIndex
        ];
        if (current.timestamp != 0) {
            // If an observation has already been made for this period, do not update.
            return false;
        }

        Prices.PriceObservation memory previous = priceObservations[token][
            observationIndex - 1
        ];
        uint256 timeElapsed = newObservation.timestamp - previous.timestamp;
        if (timeElapsed < MINIMUM_OBSERVATION_DELAY) {
            // If less than half a period has passed since the previous observation, do not update.
            return false;
        }
        priceObservations[token][observationIndex] = newObservation;

        emit PriceUpdated(
            token,
            newObservation.priceCumulativeLast,
            newObservation.ethPriceCumulativeLast
        );
        return true;
    }

    /**
     * @dev Gets the observation index for `timestamp`
     */
    function observationIndexOf(uint256 timestamp)
        public
        view
        returns (uint256)
    {
        return timestamp / observationPeriod;
    }

    /**
     * @dev Computes the average value in weth of `amountIn` of `token`.
     */
    function computeAverageAmountOut(
        address token,
        address referenceToken,
        uint256 amountIn
    ) public view returns (uint144 amountOut, uint256 timestamp) {
        require(token != USDC, "ERR_INVALID_TOKEN");
        if (token == WETH) {
            require(referenceToken == USDC, "INCORRECT_REFERENCET");
        } else {
            require(referenceToken == WETH, "INCORRECT_REFERENCET");
        }
        FixedPoint.uq112x112 memory priceAverage;
        (priceAverage, timestamp) = computeAverageTokenPrice(token, referenceToken);
        return (priceAverage.mul(amountIn).decode144(), timestamp);
    }

    /**
     * @dev Computes the average value in `token` of `amountOut` of weth.
     */
    function computeAverageAmountIn(address token, uint256 amountOut)
        public
        view
        returns (uint144 amountIn, uint256 timestamp)
    {
        FixedPoint.uq112x112 memory priceAverage;
        (priceAverage,timestamp) = computeAverageEthPrice(token);
        return (priceAverage.mul(amountOut).decode144(), timestamp);
    }

    function tokenUsdcValue(address tokenIn, uint256 amount)
        public
        view
        override
        returns (uint256, uint256)
    {
        if (tokenIn == USDC) {
            return (amount, block.timestamp);
        }
        return getPrice(tokenIn, USDC, amount);
    }

    function getPrice(address base, address quote)
        external
        view
        override
        returns (uint256, uint256)
    {
        uint8 decimals = IERC20Metadata(base).decimals();
        uint256 amount = 10 ** decimals;
        return getPrice(base, quote, amount);
    }

    function getPrice(address base, address quote, uint256 amount)
        public
        view
        returns (uint256, uint256)
    {
        if (base == WETH) {
            return computeAverageAmountOut(base, quote, amount);
        }
        // tokenWETHValue is number of eth we will get for _amount amount of _tokenIn.
        (uint256 tokenWETHValue, uint256 timestamp1) = computeAverageAmountOut(
            base,
            WETH,
            amount
        );

        //  WETHUsdValue is numver of usdc for tokenWETHValue amount of WETH.
        (uint256 WETHquoteValue, uint256 timestamp2) = computeAverageAmountOut(
            WETH,
            quote,
            tokenWETHValue
        );
        uint256 earliestTimestamp = (timestamp1 < timestamp2) ? timestamp1 : timestamp2;
        return (WETHquoteValue, earliestTimestamp);
    }

    /**
     * @dev Returns the UQ112x112 struct representing the average price of
     * `token` in terms of usdc.
     *
     * Note: Requires that the token has a price observation between 0.5
     * and 2 periods old.
     */
    function computeAverageTokenPrice(address token, address referenceToken)
        public
        view
        returns (FixedPoint.uq112x112 memory priceAverage, uint256 timestamp)
    {
        require(token != USDC, "ERR_INVALID_TOKEN");
        if (token == WETH) {
            require(referenceToken == USDC, "INCORRECT_REFERENCET");
        } else {
            require(referenceToken == WETH, "INCORRECT_REFERENCET");
        }
        // Get the current cumulative price
        Prices.PriceObservation memory current = Prices.observeTwoWayPrice(
            uniswapFactory,
            token,
            referenceToken
        );
        // Get the latest usable price
        Prices.PriceObservation memory previous = _getLatestUsableObservation(
            token,
            current.timestamp
        );

        return (previous.computeAverageTokenPrice(current), previous.timestamp);
    }

    /**
     * @dev Returns the UQ112x112 struct representing the average price of
     * weth in terms of `token`.
     *
     * Note: Requires that the token has a price observation between 0.5
     * and 2 periods old.
     */
    function computeAverageEthPrice(address token)
        public
        view
        returns (FixedPoint.uq112x112 memory priceAverage, uint256 timestamp)
    {
        // Get the current cumulative price
        Prices.PriceObservation memory current = Prices.observeTwoWayPrice(
            uniswapFactory,
            token,
            WETH
        );
        // Get the latest usable price
        Prices.PriceObservation memory previous = _getLatestUsableObservation(
            token,
            current.timestamp
        );

        return (previous.computeAverageEthPrice(current), previous.timestamp);
    }

    /**
     * @dev Returns the TwoWayAveragePrice struct representing the average price of
     * weth in terms of `token` and the average price of `token` in terms of weth.
     *
     * Note: Requires that the token has a price observation between 0.5
     * and 2 periods old.
     */
    function computeTwoWayAveragePrice(address token)
        public
        view
        returns (Prices.TwoWayAveragePrice memory, uint256 timestamp)
    {
        // Get the current cumulative price
        Prices.PriceObservation memory current = Prices.observeTwoWayPrice(
            uniswapFactory,
            token,
            WETH
        );
        // Get the latest usable price
        Prices.PriceObservation memory previous = _getLatestUsableObservation(
            token,
            current.timestamp
        );

        return (previous.computeTwoWayAveragePrice(current), previous.timestamp);
    }

    /* ==========  Internal Observation Functions  ========== */

    /**
     * @dev Gets the latest price observation which is at least half a period older
     * than `timestamp` and at most 2 periods older.
     *
     * @param token Token to get the latest price for
     * @param timestamp Reference timestamp for comparison
     */
    function _getLatestUsableObservation(address token, uint32 timestamp)
        internal
        view
        returns (Prices.PriceObservation memory observation)
    {
        uint256 observationIndex = observationIndexOf(timestamp);
        uint256 periodTimeElapsed = timestamp % observationPeriod;
        // uint256 maxAge = maxObservationAge;
        // Before looking at the current observation period, check if it is possible
        // for an observation in the current period to be more than half a period old.
        if (periodTimeElapsed >= MINIMUM_OBSERVATION_DELAY) {
            observation = priceObservations[token][observationIndex];
            if (
                observation.timestamp != 0 &&
                timestamp - observation.timestamp >= MINIMUM_OBSERVATION_DELAY
            ) {
                return observation;
            }
        }

        // Check the observation for the previous period
        observation = priceObservations[token][--observationIndex];
        uint256 timeElapsed = timestamp - observation.timestamp;
        bool usable = observation.timestamp != 0 &&
            timeElapsed >= MINIMUM_OBSERVATION_DELAY;
        while (!usable) {
            observation = priceObservations[token][--observationIndex];
            uint256 obsTime = observation.timestamp;
            timeElapsed =
                timestamp -
                (obsTime == 0 ? observationPeriod * observationIndex : obsTime);
            usable =
                observation.timestamp != 0 &&
                timeElapsed >= MINIMUM_OBSERVATION_DELAY;
            require(
                timeElapsed <= maxObservationAge,
                "ERR_USABLE_PRICE_NOT_FOUND"
            );
        }
        return observation;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/************************************************************************************************
From https://github.com/Uniswap/uniswap-lib/blob/master/contracts/libraries/FixedPoint.sol
Copied from the github repository at commit hash 9642a0705fdaf36b477354a4167a8cd765250860.
Modifications:
- Removed `sqrt` function
Subject to the GPL-3.0 license
*************************************************************************************************/

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint256 _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint256 private constant Q112 = uint256(1) << RESOLUTION;
    uint256 private constant Q224 = Q112 << RESOLUTION;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x)
        internal
        pure
        returns (uq112x112 memory)
    {
        require(x != 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint256 y)
        internal
        pure
        returns (uq144x112 memory)
    {
        uint256 z;
        require(
            y == 0 || (z = uint256(self._x) * y) / y == uint256(self._x),
            "FixedPoint: MULTIPLICATION_OVERFLOW"
        );
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator)
        internal
        pure
        returns (uq112x112 memory)
    {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // take the reciprocal of a UQ112x112
    function reciprocal(uq112x112 memory self)
        internal
        pure
        returns (uq112x112 memory)
    {
        require(self._x != 0, "FixedPoint: ZERO_RECIPROCAL");
        return uq112x112(uint224(Q224 / self._x));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/* ==========  Internal Libraries  ========== */
import "./FixedPoint.sol";
import "./UniswapV2OracleLibrary.sol";
import "../recipe/UniswapV2Library.sol";

library PriceLibrary {
    using FixedPoint for FixedPoint.uq112x112;
    using FixedPoint for FixedPoint.uq144x112;

    /* ========= Structs ========= */

    struct PriceObservation {
        uint32 timestamp;
        uint224 priceCumulativeLast;
        uint224 ethPriceCumulativeLast;
    }

    /**
     * @dev Average prices for a token in terms of weth and weth in terms of the token.
     *
     * Note: The average weth price is not equivalent to the reciprocal of the average
     * token price. See the UniSwap whitepaper for more info.
     */
    struct TwoWayAveragePrice {
        uint224 priceAverage;
        uint224 ethPriceAverage;
    }

    /* ========= View Functions ========= */

    function pairInitialized(
        address uniswapFactory,
        address token,
        address weth
    ) internal view returns (bool) {
        address pair = UniswapV2Library.pairFor(uniswapFactory, token, weth);
        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pair)
            .getReserves();
        return reserve0 != 0 && reserve1 != 0;
    }

    function observePrice(
        address uniswapFactory,
        address tokenIn,
        address quoteToken
    )
        internal
        view
        returns (
            uint32, /* timestamp */
            uint224 /* priceCumulativeLast */
        )
    {
        (address token0, address token1) = UniswapV2Library.sortTokens(
            tokenIn,
            quoteToken
        );
        address pair = UniswapV2Library.calculatePair(
            uniswapFactory,
            token0,
            token1
        );
        if (token0 == tokenIn) {
            (
                uint256 price0Cumulative,
                uint32 blockTimestamp
            ) = UniswapV2OracleLibrary.currentCumulativePrice0(pair);
            return (blockTimestamp, uint224(price0Cumulative));
        } else {
            (
                uint256 price1Cumulative,
                uint32 blockTimestamp
            ) = UniswapV2OracleLibrary.currentCumulativePrice1(pair);
            return (blockTimestamp, uint224(price1Cumulative));
        }
    }

    /**
     * @dev Query the current cumulative price of a token in terms of usdc
     * and the current cumulative price of usdc in terms of the token.
     */
    function observeTwoWayPrice(
        address uniswapFactory,
        address token,
        address usdc
    ) internal view returns (PriceObservation memory) {
        (address token0, address token1) = UniswapV2Library.sortTokens(
            token,
            usdc
        );
        address pair = UniswapV2Library.calculatePair(
            uniswapFactory,
            token0,
            token1
        );
        // Get the sorted token prices
        require(pair != address(0), "pair doesn't exist");

        (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 blockTimestamp
        ) = UniswapV2OracleLibrary.currentCumulativePrices(pair);
        // Check which token is weth and which is the token,
        // then build the price observation.
        if (token0 == token) {
            return
                PriceObservation({
                    timestamp: blockTimestamp,
                    priceCumulativeLast: uint224(price0Cumulative),
                    ethPriceCumulativeLast: uint224(price1Cumulative)
                });
        } else {
            return
                PriceObservation({
                    timestamp: blockTimestamp,
                    priceCumulativeLast: uint224(price1Cumulative),
                    ethPriceCumulativeLast: uint224(price0Cumulative)
                });
        }
    }

    /* ========= Utility Functions ========= */

    /**
     * @dev Computes the average price of a token in terms of weth
     * and the average price of weth in terms of a token using two
     * price observations.
     */
    function computeTwoWayAveragePrice(
        PriceObservation memory observation1,
        PriceObservation memory observation2
    ) internal pure returns (TwoWayAveragePrice memory) {
        uint32 timeElapsed = uint32(
            observation2.timestamp - observation1.timestamp
        );
        FixedPoint.uq112x112 memory priceAverage = UniswapV2OracleLibrary
            .computeAveragePrice(
                observation1.priceCumulativeLast,
                observation2.priceCumulativeLast,
                timeElapsed
            );
        FixedPoint.uq112x112 memory ethPriceAverage = UniswapV2OracleLibrary
            .computeAveragePrice(
                observation1.ethPriceCumulativeLast,
                observation2.ethPriceCumulativeLast,
                timeElapsed
            );
        return
            TwoWayAveragePrice({
                priceAverage: priceAverage._x,
                ethPriceAverage: ethPriceAverage._x
            });
    }

    function computeAveragePrice(
        uint32 timestampStart,
        uint224 priceCumulativeStart,
        uint32 timestampEnd,
        uint224 priceCumulativeEnd
    ) internal pure returns (FixedPoint.uq112x112 memory) {
        return
            UniswapV2OracleLibrary.computeAveragePrice(
                priceCumulativeStart,
                priceCumulativeEnd,
                uint32(timestampEnd - timestampStart)
            );
    }

    /**
     * @dev Computes the average price of the token the price observations
     * are for in terms of weth.
     */
    function computeAverageTokenPrice(
        PriceObservation memory observation1,
        PriceObservation memory observation2
    ) internal pure returns (FixedPoint.uq112x112 memory) {
        return
            UniswapV2OracleLibrary.computeAveragePrice(
                observation1.priceCumulativeLast,
                observation2.priceCumulativeLast,
                uint32(observation2.timestamp - observation1.timestamp)
            );
    }

    /**
     * @dev Computes the average price of weth in terms of the token
     * the price observations are for.
     */
    function computeAverageEthPrice(
        PriceObservation memory observation1,
        PriceObservation memory observation2
    ) internal pure returns (FixedPoint.uq112x112 memory) {
        return
            UniswapV2OracleLibrary.computeAveragePrice(
                observation1.ethPriceCumulativeLast,
                observation2.ethPriceCumulativeLast,
                uint32(observation2.timestamp - observation1.timestamp)
            );
    }

    /**
     * @dev Compute the average value in weth of `tokenAmount` of the
     * token that the average price values are for.
     */
    function computeAverageEthForTokens(
        TwoWayAveragePrice memory prices,
        uint256 tokenAmount
    ) internal pure returns (uint144) {
        return
            FixedPoint
                .uq112x112(prices.priceAverage)
                .mul(tokenAmount)
                .decode144();
    }

    /**
     * @dev Compute the average value of `wethAmount` weth in terms of
     * the token that the average price values are for.
     */
    function computeAverageTokensForEth(
        TwoWayAveragePrice memory prices,
        uint256 wethAmount
    ) internal pure returns (uint144) {
        return
            FixedPoint
                .uq112x112(prices.ethPriceAverage)
                .mul(wethAmount)
                .decode144();
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "../interfaces/IUniswapV2Pair.sol";

library UniswapV2Library {
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
                        )
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(
            pairFor(factory, tokenA, tokenB)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        amountB = (amountA * reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn * (997);
        uint256 numerator = amountInWithFee * (reserveOut);
        uint256 denominator = reserveIn * (1000) + (amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn * (amountOut) * (1000);
        uint256 denominator = (reserveOut - amountOut) * (997);
        amountIn = (numerator / denominator) + (1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i],
                path[i + 1]
            );
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i - 1],
                path[i]
            );
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }

    function calculatePair(
        address factory,
        address token0,
        address token1
    ) internal pure returns (address pair) {
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
                        )
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

interface IUsdcOracle {
    function tokenUsdcValue(address token, uint256 amount) external view 
        returns (uint256 usdcValue, uint256 oldestObservation);
    function getPrice(address base, address quote) external view 
        returns (uint256 value, uint256 oldestObservation);
    function canUpdateTokenPrices() external pure 
        returns (bool);
    function updateTokenPrices(address[] memory tokens) external 
        returns (bool[] memory updates);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/* ==========  Internal Interfaces  ========== */
import "../interfaces/IUniswapV2Pair.sol";

/* ==========  Internal Libraries  ========== */
import "./FixedPoint.sol";

/************************************************************************************************
Originally from https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/libraries/UniswapV2OracleLibrary.sol
This source code has been modified from the original, which was copied from the github repository
at commit hash 6d03bede0a97c72323fa1c379ed3fdf7231d0b26.
Subject to the GPL-3.0 license
*************************************************************************************************/

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2**32);
    }

    // produces the cumulative prices using counterfactuals to save gas and avoid a call to sync.
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
        require(
            reserve0 != 0 && reserve1 != 0,
            "UniswapV2OracleLibrary::currentCumulativePrices: Pair has no reserves."
        );
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += (uint256(
                FixedPoint.fraction(reserve1, reserve0)._x
            ) * timeElapsed);
            // counterfactual
            price1Cumulative += (uint256(
                FixedPoint.fraction(reserve0, reserve1)._x
            ) * timeElapsed);
        }
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    // only gets the first price
    function currentCumulativePrice0(address pair)
        internal
        view
        returns (uint256 price0Cumulative, uint32 blockTimestamp)
    {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        ) = IUniswapV2Pair(pair).getReserves();
        require(
            reserve0 != 0 && reserve1 != 0,
            "UniswapV2OracleLibrary::currentCumulativePrice0: Pair has no reserves."
        );
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += (uint256(
                FixedPoint.fraction(reserve1, reserve0)._x
            ) * timeElapsed);
        }
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    // only gets the second price
    function currentCumulativePrice1(address pair)
        internal
        view
        returns (uint256 price1Cumulative, uint32 blockTimestamp)
    {
        blockTimestamp = currentBlockTimestamp();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        ) = IUniswapV2Pair(pair).getReserves();
        require(
            reserve0 != 0 && reserve1 != 0,
            "UniswapV2OracleLibrary::currentCumulativePrice1: Pair has no reserves."
        );
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price1Cumulative += (uint256(
                FixedPoint.fraction(reserve0, reserve1)._x
            ) * timeElapsed);
        }
    }

    function computeAveragePrice(
        uint224 priceCumulativeStart,
        uint224 priceCumulativeEnd,
        uint32 timeElapsed
    ) internal pure returns (FixedPoint.uq112x112 memory priceAverage) {
        // overflow is desired.
        priceAverage = FixedPoint.uq112x112(
            uint224((priceCumulativeEnd - priceCumulativeStart) / timeElapsed)
        );
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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