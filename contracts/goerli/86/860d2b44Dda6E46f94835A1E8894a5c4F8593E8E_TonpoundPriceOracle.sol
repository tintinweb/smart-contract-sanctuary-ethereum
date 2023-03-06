// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Compound
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract ExponentialNoError {
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
     * @dev Truncates the given exp to a whole number value.
     *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
     */
    function truncate(Exp memory exp) pure internal returns (uint) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / expScale;
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mul_ScalarTruncate(Exp memory a, uint scalar) pure internal returns (uint) {
        Exp memory product = mul_(a, scalar);
        return truncate(product);
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mul_ScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) pure internal returns (uint) {
        Exp memory product = mul_(a, scalar);
        return add_(truncate(product), addend);
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
        return a + b;
    }

    function sub_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(uint a, uint b) pure internal returns (uint) {
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
        return a * b;
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
        return a / b;
    }

    function fraction(uint a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a, doubleScale), b)});
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "./UniswapConfig.sol";
import "../ExponentialNoError.sol";
import "./interfaces/IPriceOracle.sol";
import "./interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";



contract TonpoundPriceOracle is ExponentialNoError, UniswapConfig, Ownable {
    
    struct PriceData {
        uint248 price;
        bool failoverActive;
    }

    /// @notice ChainLink Feed address by underlying address
    mapping(address => address) public chainLinkFeeds;

    /// @notice ChainLink Feed decimals by underlying address
    mapping(address => uint8) public chainLinkFeedDecimals;

    /// @notice assets decimals by underlying address 
    mapping(address => uint8) public assetsDecimals;

    /// @notice The number of wei in 1 ETH
    uint256 public constant ETH_BASE_UNIT = 1e18;

    /// @notice A common scaling factor to maintain precision
    uint256 public constant EXP_SCALE = 1e18;

    bytes32 internal constant ETH_HASH = keccak256("ETH");

    /// @notice chainlink price feed ETH / USD
    AggregatorV3Interface public immutable baseAssetFeed;

    /// @notice denominator to scale price from chainlink price feed
    uint8 internal immutable baseAssetFeedDenominator;

    /// @notice The time interval to search for TWAPs when calling the Uniswap V3 observe function
    uint32 public immutable anchorPeriod;

    /// @notice The event emitted when the stored price is updated
    event PriceUpdated(bytes32 indexed symbolHash, uint256 price);

    /// @notice The event emitted when failover is activated
    event FailoverActivated(bytes32 indexed symbolHash);

    /// @notice The event emitted when failover is deactivated
    event FailoverDeactivated(bytes32 indexed symbolHash);

    /// @notice The event emitted when new PriceFeed added (updated)
    event NewFeedForAsset(address indexed asset, address oldFeed, address newFeed);


    /**
     * @notice Construct a Uniswap anchored view for a set of token configurations
     * @dev Note that to avoid immature TWAPs, the system must run for at least a single anchorPeriod before using.
     *      NOTE: Reported prices are set to 1 during construction. We assume that this contract will not be voted in by
     *      governance until prices have been updated through `validate` for each TokenConfig.
     * @param anchorPeriod_ The minimum amount of time required for the old Uniswap price accumulator to be replaced
     */
    constructor(
        uint32 anchorPeriod_,
        address baseUnderlying,
        AggregatorV3Interface baseAssetFeed_
    ) {
        require(anchorPeriod_ > 0, "period");
        anchorPeriod = anchorPeriod_;

        require(baseUnderlying != address(0), "underlying");
        // no need to check baseAssetFeed_ against address(0)
        baseAssetFeed = baseAssetFeed_;
        uint8 priceFeedDecimals_ = baseAssetFeed_.decimals();
        baseAssetFeedDenominator = priceFeedDecimals_ - 6;
        _setPriceFeedForUnderlyingInternal(baseUnderlying, address(baseAssetFeed_), priceFeedDecimals_);
    }

    /// @notice Get the underlying price of a cToken asset
    /// @param cToken The cToken to get the underlying price of
    /// @return The underlying asset price mantissa (scaled by 1e(36 - assetDecimals)).
    ///         Zero means the price is unavailable.
    function getUnderlyingPrice(ICToken cToken) public view returns (uint) {
        address asset = cToken.underlying();
        if (hasFeedForAsset(asset)) {
            return _getOraclePriceForAssetInternal(asset);
        } else if (hasTwapForAsset(asset)) {
            return _fetchTwapPriceForAssetInternal(address(cToken));
        } else {
            return 0;
        }
    }

    /// @notice Sets config to fetch underlying price
    /// @param cToken The address of the Compound Token
    /// @param uniswapMarket The address of the V3 pool being used as the anchor for this market
    function setTokenConfig(address cToken, address uniswapMarket) external onlyOwner {
        _setTokenConfig(cToken, uniswapMarket);
    }

    /// @notice Fetch the underlying price of a cToken from TWAP, in the format expected by the Comptroller.
    /// @dev Implements the PriceOracle interface for Compound v2.
    /// @param cToken The cToken address for price retrieval
    /// @return Price denominated in USD for the given cToken address, in the format expected by the Comptroller.
    ///         (scaled by 1e(36 - assetDecimals))
    function _fetchTwapPriceForAssetInternal(address cToken)
        internal
        view
        returns (uint256)
    {
        TokenConfig memory config = getTokenConfigByCToken(cToken);
        uint256 anchorPrice = calculateAnchorPriceFromEthPrice(config);
        require(anchorPrice < 2**248, "Anchor too big");
        // Comptroller needs prices in the format: ${raw price} * 1e36 / baseUnit
        // The baseUnit of an asset is the amount of the smallest denomination of that asset per whole.
        // For example, the baseUnit of ETH is 1e18.
        // Since the prices in this view have 6 decimals, we must scale them by 1e(36 - 6)/baseUnit
        return FullMath.mulDiv(1e30, anchorPrice, config.baseUnit);
    }

    /// @notice Calculate the anchor price by fetching price data from the TWAP
    /// @param config TokenConfig
    /// @return anchorPrice uint
    function calculateAnchorPriceFromEthPrice(TokenConfig memory config)
        internal
        view
        returns (uint256 anchorPrice)
    {
        uint256 ethPrice = fetchEthPrice();
        if (config.symbolHash == ETH_HASH) {
            anchorPrice = ethPrice;
        } else {
            anchorPrice = fetchAnchorPrice(config, ethPrice);
        }
    }

    /// @dev Fetches the latest TWATP from the UniV3 pool oracle, over the last anchor period.
    ///      Note that the TWATP (time-weighted average tick-price) is not equivalent to the TWAP,
    ///      as ticks are logarithmic. The TWATP returned by this function will usually
    ///      be lower than the TWAP.
    function getUniswapTwap(TokenConfig memory config)
        internal
        view
        returns (uint256)
    {
        uint32 anchorPeriod_ = anchorPeriod;
        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = anchorPeriod_;
        (int56[] memory tickCumulatives, ) = IUniswapV3Pool(
            config.uniswapMarket
        ).observe(secondsAgos);

        int56 anchorPeriod__ = int56(uint56(anchorPeriod_));
        int56 timeWeightedAverageTickS56 = (tickCumulatives[1] -
            tickCumulatives[0]) / anchorPeriod__;
        require(
            timeWeightedAverageTickS56 >= TickMath.MIN_TICK &&
                timeWeightedAverageTickS56 <= TickMath.MAX_TICK,
            "TWAP not in range"
        );
        require(
            timeWeightedAverageTickS56 < type(int24).max,
            "timeWeightedAverageTick > max"
        );
        int24 timeWeightedAverageTick = int24(timeWeightedAverageTickS56);
        if (config.isUniswapReversed) {
            // If the reverse price is desired, inverse the tick
            // price = 1.0001^{tick}
            // (price)^{-1} = (1.0001^{tick})^{-1}
            // \frac{1}{price} = 1.0001^{-tick}
            timeWeightedAverageTick = -timeWeightedAverageTick;
        }
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(
            timeWeightedAverageTick
        );
        // Squaring the result also squares the Q96 scalar (2**96),
        // so after this mulDiv, the resulting TWAP is still in Q96 fixed precision.
        uint256 twapX96 = FullMath.mulDiv(
            sqrtPriceX96,
            sqrtPriceX96,
            FixedPoint96.Q96
        );

        // Scale up to a common precision (EXP_SCALE), then down-scale from Q96.
        return FullMath.mulDiv(EXP_SCALE, twapX96, FixedPoint96.Q96);
    }

    /// @dev Fetches the current eth/usd price from price feed, with 6 decimals of precision.
    function fetchEthPrice() internal view returns (uint256) {
        return uint256(getChainLinkPrice(baseAssetFeed)) / baseAssetFeedDenominator;
    }

    /// @dev Fetches the current token/usd price from Uniswap, with 6 decimals of precision.
    /// @param conversionFactor 1e18 if seeking the ETH price, and a 6 decimal ETH-USDC price in the case of other assets
    function fetchAnchorPrice(
        TokenConfig memory config,
        uint256 conversionFactor
    ) internal view virtual returns (uint256) {
        // `getUniswapTwap(config)`
        //      -> TWAP between the baseUnits of Uniswap pair (scaled to 1e18)
        // `twap * config.baseUnit`
        //      -> price of 1 token relative to `baseUnit` of the other token (scaled to 1e18)
        uint256 twap = getUniswapTwap(config);

        // `unscaledPriceMantissa * config.baseUnit / EXP_SCALE`
        //      -> price of 1 token relative to baseUnit of the other token (scaled to 1)
        uint256 unscaledPriceMantissa = twap * conversionFactor;

        // Adjust twap according to the units of the non-ETH asset
        // 1. In the case of ETH, we would have to scale by 1e6 / USDC_UNITS, but since baseUnit2 is 1e6 (USDC), it cancels
        // 2. In the case of non-ETH tokens
        //  a. `getUniswapTwap(config)` handles "reversed" token pairs, so `twap` will always be Token/ETH TWAP.
        //  b. conversionFactor = ETH price * 1e6
        //      unscaledPriceMantissa = twap{token/ETH} * EXP_SCALE * conversionFactor
        //      so ->
        //      anchorPrice = (twap * tokenBaseUnit / ETH_BASE_UNIT) * ETH_price * 1e6
        //                  = twap * conversionFactor * tokenBaseUnit / ETH_BASE_UNIT
        //                  = unscaledPriceMantissa / EXP_SCALE * tokenBaseUnit / ETH_BASE_UNIT
        uint256 anchorPrice = (unscaledPriceMantissa * config.baseUnit) /
            ETH_BASE_UNIT /
            EXP_SCALE;

        return anchorPrice;
    }

    function hasTwapForAsset(address cToken) internal view returns (bool) {
        return cTokenConfig[cToken].underlying != address(0);
    }

    function hasFeedForAsset(address asset) public view returns (bool) {
        return chainLinkFeeds[asset] != address(0);
    }

    /* ChainLink Oracles */

    function _setPriceFeedForUnderlying(address _underlying, address _chainlinkFeed, uint8 _priceFeedDecimals) onlyOwner external {
        _setPriceFeedForUnderlyingInternal(_underlying, _chainlinkFeed, _priceFeedDecimals);
    }

    function _setPriceFeedsForUnderlyings(address[] calldata _underlyings, address[] calldata _chainlinkFeeds, uint8[] calldata _priceFeedsDecimals) onlyOwner external {
        require(_underlyings.length == _chainlinkFeeds.length, "invalid lengths");
        require(_underlyings.length == _priceFeedsDecimals.length, "invalid lengths");

        for (uint i = 0; i < _underlyings.length; i++) {
            _setPriceFeedForUnderlyingInternal(_underlyings[i], _chainlinkFeeds[i], _priceFeedsDecimals[i]);
        }
    }

    function _setPriceFeedForUnderlyingInternal(address underlying, address chainlinkFeed, uint8 priceFeedDecimals) internal {
        address existingFeed = chainLinkFeeds[underlying];
        // require(existingFeed == address(0), "Cannot reassign feed");

        uint8 decimalsForAsset;

        if (underlying == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
            decimalsForAsset = 18;
        } else {
            decimalsForAsset = IERC20(underlying).decimals();
        }

        // Update if the feed is different
        if (existingFeed != chainlinkFeed) {
            chainLinkFeeds[underlying] = chainlinkFeed;
            chainLinkFeedDecimals[underlying] = priceFeedDecimals;
            assetsDecimals[underlying] = decimalsForAsset;
            emit NewFeedForAsset(underlying, existingFeed, chainlinkFeed);
        }
    }

    /**
      * @notice Get the underlying price of a cToken asset
      * @param asset The asset (Erc20 or native)
      * @return The asset price mantissa (scaled by 1e(36 - assetDecimals)).
      *  Zero means the price is unavailable.
      */
    function _getOraclePriceForAssetInternal(address asset) internal view returns (uint) {
        uint8 feedDecimals = chainLinkFeedDecimals[asset];
        uint8 assetDecimals = assetsDecimals[asset];
        address feed = chainLinkFeeds[asset];
        int feedPriceRaw = getChainLinkPrice(AggregatorV3Interface(feed));
        uint feedPrice = uint(feedPriceRaw);

        // Safety
        require(feedPriceRaw == int(feedPrice), "Price Conversion error");

        // Needs to be scaled to e36 and then divided by the asset's decimals
        if (feedDecimals == 8) {
            return (1e28 * feedPrice) / (10 ** assetDecimals);
        } else if (feedDecimals == 18) {
            return (1e18 * feedPrice) / (10 ** assetDecimals);
        } else {
            return 0;
        }
    }

    function getChainLinkPrice(AggregatorV3Interface priceFeed) internal view returns (int) {
        (
        uint80 roundID,
        int price,
        uint startedAt,
        uint timeStamp,
        uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }

    /// @notice         Evaluates input amount according to stored price, accrues interest
    /// @param cToken   Market to evaluate
    /// @param amount   Amount of tokens to evaluate according to 'reverse' order
    /// @param reverse  Order of evaluation
    /// @return         Depending on 'reverse' order:
    ///                     false - return USD amount equal to 'amount' of 'cToken' in wei
    ///                     true - return cTokens equal to 'amount' of USD represented in wei
    ///                            e.g. 123e18 = 123.00$
    function getEvaluation(ICToken cToken, uint256 amount, bool reverse) external returns (uint256) {
        Exp memory exchangeRate = Exp({mantissa: cToken.exchangeRateCurrent()});
        uint256 oraclePriceMantissa = getUnderlyingPrice(cToken);        
        require(oraclePriceMantissa != 0, "invalid price");
        Exp memory oraclePrice = Exp({mantissa: oraclePriceMantissa});

        if (reverse) {
            // input: 'amount' in USD scaled in 1e18, i.e. 19.54$ = 19540000000000000000
            // tokenAmount = amountUSD / oraclePrice 
            // cTokenAmount = tokenAmount / exchangeRate
            uint256 tokenAmount = div_(amount, oraclePrice);
            uint256 cTokenAmount =  div_(tokenAmount, exchangeRate);
            return cTokenAmount; 
        }
        // underlyingAmount = exchangeRate * cTokenAmount
        // underlyingAmountUSD = underlyingAmount * oraclePrice
        uint256 underlyingAmount = mul_ScalarTruncate(exchangeRate, amount);
        uint256 underlyingAmountUSD = mul_ScalarTruncate(oraclePrice, underlyingAmount);
        return underlyingAmountUSD;
    }


    /// @notice         Evaluates input amount according to stored price, doesn't accrue interest
    /// @param cToken   Market to evaluate
    /// @param amount   Amount of tokens to evaluate according to 'reverse' order
    /// @param reverse  Order of evaluation
    /// @return         Depending on 'reverse' order:
    ///                     false - return USD amount equal to 'amount' of 'cToken' in wei
    ///                     true - return cTokens equal to 'amount' of USD represented in wei
    ///                            e.g. 123e18 = 123.00$
    function getEvaluationStored(ICToken cToken, uint256 amount, bool reverse) external view returns (uint256) {
        Exp memory exchangeRate = Exp({mantissa: cToken.exchangeRateStored()});
        // uint256 underlyingDecimals = IERC20(cToken.underlying()).decimals();
        uint256 oraclePriceMantissa = getUnderlyingPrice(cToken);
        require(oraclePriceMantissa != 0, "invalid price");
        Exp memory oraclePrice = Exp({mantissa: oraclePriceMantissa});

        if (reverse) {
            // input: 'amount' in USD scaled in 1e18, i.e. 19.54$ = 19540000000000000000
            // tokenAmount = amountUSD / oraclePrice 
            // cTokenAmount = tokenAmount / exchangeRate
            uint256 tokenAmount = div_(amount, oraclePrice);
            uint256 cTokenAmount =  div_(tokenAmount, exchangeRate);
            return cTokenAmount; 
        }
        // underlyingAmount = exchangeRate * cTokenAmount
        // underlyingAmountUSD = underlyingAmount * oraclePrice
        uint256 underlyingAmount = mul_ScalarTruncate(exchangeRate, amount);
        uint256 underlyingAmountUSD = mul_ScalarTruncate(oraclePrice, underlyingAmount);
        return underlyingAmountUSD;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "./interfaces/IPriceOracle.sol";
import "./UniswapLib.sol";


contract UniswapConfig {

    /// @dev Describe how the USD price should be determined for an asset.
    struct TokenConfig {
        // The address of the Compound Token
        address cToken;
        // The address of the underlying market token. For this `LINK` market configuration, this would be the address of the `LINK` token.
        address underlying;
        // The bytes32 hash of the underlying symbol.
        bytes32 symbolHash;
        // The number of smallest units of measurement in a single whole unit.
        uint256 baseUnit;
        // The address of the pool being used as the anchor for this market.
        address uniswapMarket;
        // True if the pair on Uniswap is defined as ETH / X
        bool isUniswapReversed;
    }

    /// @notice cToken configs
    mapping(address => TokenConfig) public cTokenConfig;
    
    /// @notice cToken address by underlying's symbol hash
    mapping(bytes32 => address) internal cTokenBySymbolHash;

    /// @notice cToken address by underlying address
    mapping(address => address) internal cTokenByUnderlying;

    event ConfigUpdate(address indexed cToken, address uniswapMarket);

    /**
     * @notice Sets config to fetch underlying price
     * @param cToken The address of the Compound Token
     * @param uniswapMarket The address of the V3 pool being used as the anchor for this market
     */
    function _setTokenConfig(
        address cToken,
        address uniswapMarket
        ) internal {

        require(ICToken(cToken).isCToken(), "invalid cToken");
        address underlying = ICToken(cToken).underlying();

        require(uniswapMarket != address(0), "No market");
        // require(
        //     IUniswapV3Pool(uniswapMarket).token0() == underlying || 
        //     IUniswapV3Pool(uniswapMarket).token1() == underlying,
        //     "invalid market"
        //     );

        bytes32 symbolHash = keccak256(bytes(IERC20(underlying).symbol()));
        uint256 baseUnit = 10 ** IERC20(underlying).decimals();
        // bool isUniswapReversed = IUniswapV3Pool(uniswapMarket).token0() == underlying ?
        //     false : true;
        bool isUniswapReversed = false;

        cTokenConfig[cToken] = TokenConfig({
            cToken: address(cToken),
            underlying: underlying,
            symbolHash: symbolHash,
            baseUnit: baseUnit,
            uniswapMarket: uniswapMarket,
            isUniswapReversed: isUniswapReversed
        });

        cTokenBySymbolHash[symbolHash] = cToken;
        cTokenByUnderlying[underlying] = cToken;
        
        emit ConfigUpdate(cToken, uniswapMarket);
    }

    /**
     * @notice Get the config for symbol
     * @param symbol The symbol of the config to get
     * @return The config object
     */
    function getTokenConfigBySymbol(string calldata symbol)
        public
        view
        returns (TokenConfig memory)
    {
        TokenConfig memory config = cTokenConfig[cTokenBySymbolHash[keccak256(bytes(symbol))]];
        return config;
    }

    /**
     * @notice Get the config for the symbolHash
     * @param symbolHash The keccack256 of the symbol of the config to get
     * @return The config object
     */
    function getTokenConfigBySymbolHash(bytes32 symbolHash)
        public
        view
        returns (TokenConfig memory)
    {
        TokenConfig memory config = cTokenConfig[cTokenBySymbolHash[symbolHash]];
        return config;
    }

    /**
     * @notice Get the config for the cToken
     * @param cToken The address of the cToken of the config to get
     * @return The config object
     */
    function getTokenConfigByCToken(address cToken)
        public
        view
        returns (TokenConfig memory)
    {
        TokenConfig memory config = cTokenConfig[cToken];
        return config;
    }

    /**
     * @notice Get the config for an underlying asset
     * @dev The underlying address of ETH is the zero address
     * @param underlying The address of the underlying asset of the config to get
     * @return The config object
     */
    function getTokenConfigByUnderlying(address underlying)
        public
        view
        returns (TokenConfig memory)
    {
        TokenConfig memory config = cTokenConfig[cTokenByUnderlying[underlying]];
        return config;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.8.7;

// From: https://github.com/Uniswap/uniswap-v3-core

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

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
        uint256 twos = denominator & (~denominator + 1);
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
}

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MIN_TICK = -887272;
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO =
        1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick)
        internal
        pure
        returns (uint160 sqrtPriceX96)
    {
        uint256 absTick = tick < 0
            ? uint256(-int256(tick))
            : uint256(int256(tick));
        require(absTick <= uint256(uint24(MAX_TICK)), "T");

        uint256 ratio = absTick & 0x1 != 0
            ? 0xfffcb933bd6fad37aa2d162d1a594001
            : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0)
            ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0)
            ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0)
            ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0)
            ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0)
            ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0)
            ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0)
            ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0)
            ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0)
            ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0)
            ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0)
            ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0)
            ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0)
            ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0)
            ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0)
            ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0)
            ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0)
            ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0)
            ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0)
            ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160(
            (ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1)
        );
    }
}

interface IUniswapV3Pool {
    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

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
        returns (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulativeX128s
        );

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
}

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

interface IERC20 {

    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

	// getRoundData and latestRoundData should both raise "No data present"
	// if they do not have data to report, instead of returning unset values
	// which could be misinterpreted as actual reported values.
	function getRoundData(uint80 _roundId) external view 
		returns (
			uint80 roundId,
			int256 answer,
			uint256 startedAt,
			uint256 updatedAt,
			uint80 answeredInRound
		);

	function latestRoundData() external view
		returns (
			uint80 roundId,
			int256 answer,
			uint256 startedAt,
			uint256 updatedAt,
			uint80 answeredInRound
		);
}

interface AggregatorValidatorInterface {
	function validate(uint256 previousRoundId,
			int256 previousAnswer,
			uint256 currentRoundId,
			int256 currentAnswer) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ICToken {
    function underlying() external view returns (address);
    function exchangeRateCurrent() external returns (uint);
    function exchangeRateStored() external view returns (uint);
    function isCToken() external view returns (bool);
}

interface IPriceOracle {
    function isPriceOracle() external view returns (bool);
    function getAssetPrice(address asset) external view returns (uint);
    function getAssetPriceUpdateTimestamp(address asset) external view returns (uint);
    function getUnderlyingPrice(ICToken cToken) external view returns (uint);
    function getUnderlyingPriceUpdateTimestamp(address cToken) external view returns (uint);
}