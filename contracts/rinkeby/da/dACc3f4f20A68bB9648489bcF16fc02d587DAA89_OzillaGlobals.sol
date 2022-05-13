//SPDX-License-Identifier: ISC
pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

// Libraries
import "./synthetix/SafeDecimalMath.sol";

// Inherited
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Interfaces
import "./interfaces/IExchanger.sol";
import "./interfaces/ILendingPool.sol";
import "./interfaces/ISwapRouter.sol";
import "./interfaces/IExchangeRates.sol";
import "./interfaces/ILiquidityPool.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./test-helpers/ITestOracle.sol";

/**
 * @title OzillaGlobals
 * @author Ozilla
 * @dev Manages variables across all OptionMarkets, along with managing access to Synthetix.
 * Groups access to variables needed during a trade to reduce the gas costs associated with repetitive
 * inter-contract calls.
 * The OptionMarket contract address is used as the key to access the variables for the market.
 */
contract OzillaGlobals is IOzillaGlobals, Ownable  {
  using SafeDecimalMath for uint;

  ISwapRouter public override swapRouter;
  IUniswapV2Pair public override uniswapV2Pair;
  IExchanger public override exchanger;
  IExchangeRates public override exchangeRates;
  ILendingPool public override lendingPool;
  AggregatorV3Interface internal priceFeed;
  IMockPricer public testOracle;

  /// @dev Pause the whole system. Note; this will not pause settling previously expired options.
  bool public override isPaused = false;

  /// @dev Don't sell options this close to expiry
  mapping(address => uint) public override tradingCutoff;

  // Variables related to calculating premium/fees
  mapping(address => uint) public override optionPriceFeeCoefficient;
  mapping(address => uint) public override spotPriceFeeCoefficient;
  mapping(address => uint) public override vegaFeeCoefficient;
  mapping(address => uint) public override vegaNormFactor;
  mapping(address => uint) public override standardSize;
  mapping(address => uint) public override skewAdjustmentFactor;
  mapping(address => int) public override rateAndCarry;
  mapping(address => int) public override minDelta;
  mapping(address => uint) public override volatilityCutoff;
  mapping(address => address) public override quoteMessage;
  mapping(address => address) public override baseMessage;

  constructor(AggregatorV3Interface _priceFeed) Ownable() {
    priceFeed = _priceFeed;
  }

  /**
   * @dev Set the globals that apply to all OptionMarkets.
   * @param _swapRouter The address of Uniswap.
   * @param _lendingPool The address of AAVE's LendingPool.
   */
  function setGlobals(ISwapRouter _swapRouter, ILendingPool _lendingPool, IUniswapV2Pair _uniswapV2Pair) external override onlyOwner {
    swapRouter = _swapRouter;
    uniswapV2Pair = _uniswapV2Pair;
    lendingPool = _lendingPool;
    emit GlobalsSet(_swapRouter, _lendingPool);
  }

  /**
   * @dev Set the globals for a specific OptionMarket.
   *
   * @param _contractAddress The address of the OptionMarket.
   * @param _tradingCutoff The time to stop trading.
   * @param pricingGlobals The PricingGlobals.
   * @param _quoteAddress The address of the quoteAsset.
   * @param _baseAddress The address of the baseAsset.
   */
  function setGlobalsForContract(
    address _contractAddress,
    uint _tradingCutoff,
    PricingGlobals memory pricingGlobals,
    address _quoteAddress,
    address _baseAddress
  ) external override onlyOwner {
    setTradingCutoff(_contractAddress, _tradingCutoff);
    setOptionPriceFeeCoefficient(_contractAddress, pricingGlobals.optionPriceFeeCoefficient);
    setSpotPriceFeeCoefficient(_contractAddress, pricingGlobals.spotPriceFeeCoefficient);
    setVegaFeeCoefficient(_contractAddress, pricingGlobals.vegaFeeCoefficient);
    setVegaNormFactor(_contractAddress, pricingGlobals.vegaNormFactor);
    setStandardSize(_contractAddress, pricingGlobals.standardSize);
    setSkewAdjustmentFactor(_contractAddress, pricingGlobals.skewAdjustmentFactor);
    setRateAndCarry(_contractAddress, pricingGlobals.rateAndCarry);
    setMinDelta(_contractAddress, pricingGlobals.minDelta);
    setVolatilityCutoff(_contractAddress, pricingGlobals.volatilityCutoff);
    setQuoteMessage(_contractAddress, _quoteAddress);
    setBaseMessage(_contractAddress, _baseAddress);
  }

  /**
   * @dev Pauses the contract.
   *
   * @param _isPaused Whether getting globals will revert or not.
   */
  function setPaused(bool _isPaused) external override onlyOwner {
    isPaused = _isPaused;

    emit Paused(isPaused);
  }

  /**
   * @dev Set the time when the OptionMarket will cease trading before expiry.
   *
   * @param _contractAddress The address of the OptionMarket.
   * @param _tradingCutoff The time to stop trading.
   */
  function setTradingCutoff(address _contractAddress, uint _tradingCutoff) public override onlyOwner {
    require(_tradingCutoff >= 6 hours && _tradingCutoff <= 14 days, "tradingCutoff value out of range");
    tradingCutoff[_contractAddress] = _tradingCutoff;
    emit TradingCutoffSet(_contractAddress, _tradingCutoff);
  }

  /**
   * @notice Set the option price fee coefficient for the OptionMarket.

   * @param _contractAddress The address of the OptionMarket.
   * @param _optionPriceFeeCoefficient The option price fee coefficient.
   */
  function setOptionPriceFeeCoefficient(address _contractAddress, uint _optionPriceFeeCoefficient)
    public
    override
    onlyOwner
  {
    require(_optionPriceFeeCoefficient <= 5e17, "optionPriceFeeCoefficient value out of range");
    optionPriceFeeCoefficient[_contractAddress] = _optionPriceFeeCoefficient;
    emit OptionPriceFeeCoefficientSet(_contractAddress, _optionPriceFeeCoefficient);
  }

  /**
   * @notice Set the spot price fee coefficient for the OptionMarket.
   *
   * @param _contractAddress The address of the OptionMarket.
   * @param _spotPriceFeeCoefficient The spot price fee coefficient.
   */
  function setSpotPriceFeeCoefficient(address _contractAddress, uint _spotPriceFeeCoefficient)
    public
    override
    onlyOwner
  {
    require(_spotPriceFeeCoefficient <= 1e17, "optionPriceFeeCoefficient value out of range");
    spotPriceFeeCoefficient[_contractAddress] = _spotPriceFeeCoefficient;
    emit SpotPriceFeeCoefficientSet(_contractAddress, _spotPriceFeeCoefficient);
  }

  /**
   * @notice Set the vega fee coefficient for the OptionMarket.
   *
   * @param _contractAddress The address of the OptionMarket.
   * @param _vegaFeeCoefficient The vega fee coefficient.
   */
  function setVegaFeeCoefficient(address _contractAddress, uint _vegaFeeCoefficient) public override onlyOwner {
    require(_vegaFeeCoefficient <= 100000e18, "optionPriceFeeCoefficient value out of range");
    vegaFeeCoefficient[_contractAddress] = _vegaFeeCoefficient;
    emit VegaFeeCoefficientSet(_contractAddress, _vegaFeeCoefficient);
  }

  /**
   * @notice Set the vega normalisation factor for the OptionMarket.
   *
   * @param _contractAddress The address of the OptionMarket.
   * @param _vegaNormFactor The vega normalisation factor.
   */
  function setVegaNormFactor(address _contractAddress, uint _vegaNormFactor) public override onlyOwner {
    require(_vegaNormFactor <= 10e18, "optionPriceFeeCoefficient value out of range");
    vegaNormFactor[_contractAddress] = _vegaNormFactor;
    emit VegaNormFactorSet(_contractAddress, _vegaNormFactor);
  }

  /**
   * @notice Set the standard size for the OptionMarket.
   *
   * @param _contractAddress The address of the OptionMarket.
   * @param _standardSize The size of an average trade.
   */
  function setStandardSize(address _contractAddress, uint _standardSize) public override onlyOwner {
    require(_standardSize >= 1e15 && _standardSize <= 100000e18, "standardSize value out of range");
    standardSize[_contractAddress] = _standardSize;
    emit StandardSizeSet(_contractAddress, _standardSize);
  }

  /**
   * @notice Set the skew adjustment factor for the OptionMarket.
   *
   * @param _contractAddress The address of the OptionMarket.
   * @param _skewAdjustmentFactor The skew adjustment factor.
   */
  function setSkewAdjustmentFactor(address _contractAddress, uint _skewAdjustmentFactor) public override onlyOwner {
    require(_skewAdjustmentFactor <= 10e18, "skewAdjustmentFactor value out of range");
    skewAdjustmentFactor[_contractAddress] = _skewAdjustmentFactor;
    emit SkewAdjustmentFactorSet(_contractAddress, _skewAdjustmentFactor);
  }

  /**
   * @notice Set the rate for the OptionMarket.
   *
   * @param _contractAddress The address of the OptionMarket.
   * @param _rateAndCarry The rate.
   */
  function setRateAndCarry(address _contractAddress, int _rateAndCarry) public override onlyOwner {
    require(_rateAndCarry <= 3e18 && _rateAndCarry >= -3e18, "rateAndCarry value out of range");
    rateAndCarry[_contractAddress] = _rateAndCarry;
    emit RateAndCarrySet(_contractAddress, _rateAndCarry);
  }

  /**
   * @notice Set the minimum Delta that the OptionMarket will trade.
   *
   * @param _contractAddress The address of the OptionMarket.
   * @param _minDelta The minimum delta value.
   */
  function setMinDelta(address _contractAddress, int _minDelta) public override onlyOwner {
    require(_minDelta >= 0 && _minDelta <= 2e17, "minDelta value out of range");
    minDelta[_contractAddress] = _minDelta;
    emit MinDeltaSet(_contractAddress, _minDelta);
  }

  /**
   * @notice Set the minimum volatility option that the OptionMarket will trade.
   *
   * @param _contractAddress The address of the OptionMarket.
   * @param _volatilityCutoff The minimum volatility value.
   */
  function setVolatilityCutoff(address _contractAddress, uint _volatilityCutoff) public override onlyOwner {
    require(_volatilityCutoff <= 2e18, "volatilityCutoff value out of range");
    volatilityCutoff[_contractAddress] = _volatilityCutoff;
    emit VolatilityCutoffSet(_contractAddress, _volatilityCutoff);
  }

  /**
   * @notice Set the quoteMessage of the OptionMarket.
   *
   * @param _contractAddress The address of the OptionMarket.
   * @param _quoteAddress The message of the quoteAsset.
   */
  function setQuoteMessage(address _contractAddress, address _quoteAddress) public override onlyOwner {
    quoteMessage[_contractAddress] = _quoteAddress;
    emit QuoteMessageSet(_contractAddress, _quoteAddress);
  }

  /**
   * @notice Set the baseMessage of the OptionMarket.
   *
   * @param _contractAddress The address of the OptionMarket.
   * @param _baseAddress The key of the baseAsset.
   */
  function setBaseMessage(address _contractAddress, address _baseAddress) public override onlyOwner {
    baseMessage[_contractAddress] = _baseAddress;
    emit BaseMessageSet(_contractAddress, _baseAddress);
  }

  // Getters

  /**
   * @notice Returns the price of the baseAsset.
   *
   * @param _contractAddress The address of the OptionMarket.
   */
  function getSpotPriceForMarket(address _contractAddress) external view override returns (uint) {
    return getSpotPrice(baseMessage[_contractAddress]);
  }

  /**
   * @notice Gets spot price of an asset.
   * @dev All rates are denominated in terms of sUSD,
   * so the price of sUSD is always $1.00, and is never stale.
   *
   * @param to The key of the synthetic asset.
   */
  function getSpotPrice(address to) public view override returns(uint256 price){
    (
    uint80 roundId,
    int256 answer,
    ,
    ,
    ) = priceFeed.latestRoundData();
    require(answer > 0,"price get error");
    // _roundId = roundId;
    price = uint256(answer);
    return price;
    // return 2628000000000000000000;
  }

  /**
   * @notice Returns a PricingGlobals struct for a given market address.
   *
   * @param _contractAddress The address of the OptionMarket.
   */
  function getPricingGlobals(address _contractAddress)
    external
    view
    override
    notPaused
    returns (PricingGlobals memory)
  {
    return
      PricingGlobals({
        optionPriceFeeCoefficient: optionPriceFeeCoefficient[_contractAddress],
        spotPriceFeeCoefficient: spotPriceFeeCoefficient[_contractAddress],
        vegaFeeCoefficient: vegaFeeCoefficient[_contractAddress],
        vegaNormFactor: vegaNormFactor[_contractAddress],
        standardSize: standardSize[_contractAddress],
        skewAdjustmentFactor: skewAdjustmentFactor[_contractAddress],
        rateAndCarry: rateAndCarry[_contractAddress],
        minDelta: minDelta[_contractAddress],
        volatilityCutoff: volatilityCutoff[_contractAddress],
        spotPrice: getSpotPrice(baseMessage[_contractAddress])
      });
  }

  /**
   * @notice Returns the GreekCacheGlobals.
   *
   * @param _contractAddress The address of the OptionMarket.
   */
  function getGreekCacheGlobals(address _contractAddress)
    external
    view
    override
    notPaused
    returns (GreekCacheGlobals memory)
  {
    return
      GreekCacheGlobals({
        rateAndCarry: rateAndCarry[_contractAddress],
        spotPrice: getSpotPrice(baseMessage[_contractAddress])
      });
  }

  /**
   * @notice Returns the ExchangeGlobals.
   * @param _contractAddress The address of the OptionMarket.
   */
  function getExchangeGlobals(address _contractAddress)
    public
    view
    override
    notPaused
    returns (ExchangeGlobals memory exchangeGlobals)
  {
    exchangeGlobals = ExchangeGlobals({
      spotPrice: 0,
      quoteAddress: quoteMessage[_contractAddress],
      baseAddress: baseMessage[_contractAddress],
      swapRouter: swapRouter,
      uniswapV2Pair: uniswapV2Pair,
      lendingPool: lendingPool
    });

    exchangeGlobals.spotPrice = getSpotPrice(exchangeGlobals.baseAddress);

    // if (exchangeType == ExchangeType.BASE_QUOTE || exchangeType == ExchangeType.ALL) {
    //   exchangeGlobals.baseQuoteFeeRate = exchanger.feeRateForExchange(
    //     exchangeGlobals.baseAddress,
    //     exchangeGlobals.quoteAddress
    //   );
    // }

    // if (exchangeType == ExchangeType.QUOTE_BASE || exchangeType == ExchangeType.ALL) {
    //   exchangeGlobals.quoteBaseFeeRate = exchanger.feeRateForExchange(
    //     exchangeGlobals.quoteAddress,
    //     exchangeGlobals.baseAddress
    //   );
    // }
  }

  /**
   * @dev Returns the globals needed to perform a trade.
   * The purpose of this function is to provide all the necessary variables in 1 call. Note that GreekCacheGlobals are a
   * subset of PricingGlobals, so we generate that struct when OptionMarketPricer calls OptionGreekCache.
   *
   * @param _contractAddress The address of the OptionMarket.
   */
  function getGlobalsForOptionTrade(address _contractAddress)
    external
    view
    override
    notPaused
    returns (
      PricingGlobals memory pricingGlobals,
      ExchangeGlobals memory exchangeGlobals,
      uint tradeCutoff
    )
  {
    // exchangeGlobals aren't necessary apart from long calls, but since they are the most expensive transaction
    // we add this overhead to other types of calls, to save gas on long calls.
    exchangeGlobals = getExchangeGlobals(_contractAddress);
    pricingGlobals = PricingGlobals({
      optionPriceFeeCoefficient: optionPriceFeeCoefficient[_contractAddress],
      spotPriceFeeCoefficient: spotPriceFeeCoefficient[_contractAddress],
      vegaFeeCoefficient: vegaFeeCoefficient[_contractAddress],
      vegaNormFactor: vegaNormFactor[_contractAddress],
      standardSize: standardSize[_contractAddress],
      skewAdjustmentFactor: skewAdjustmentFactor[_contractAddress],
      rateAndCarry: rateAndCarry[_contractAddress],
      minDelta: minDelta[_contractAddress],
      volatilityCutoff: volatilityCutoff[_contractAddress],
      spotPrice: exchangeGlobals.spotPrice
    });
    tradeCutoff = tradingCutoff[_contractAddress];
  }

  modifier notPaused {
    require(!isPaused, "contracts are paused");
    _;
  }

  /** Emitted when globals are set.
   */
  event GlobalsSet(ISwapRouter _swapRouter, ILendingPool _lendingPool);
  /**
   * @dev Emitted when paused.
   */
  event Paused(bool isPaused);
  /**
   * @dev Emitted when trading cut-off is set.
   */
  event TradingCutoffSet(address indexed _contractAddress, uint _tradingCutoff);
  /**
   * @dev Emitted when option price fee coefficient is set.
   */
  event OptionPriceFeeCoefficientSet(address indexed _contractAddress, uint _optionPriceFeeCoefficient);
  /**
   * @dev Emitted when spot price fee coefficient is set.
   */
  event SpotPriceFeeCoefficientSet(address indexed _contractAddress, uint _spotPriceFeeCoefficient);
  /**
   * @dev Emitted when vega fee coefficient is set.
   */
  event VegaFeeCoefficientSet(address indexed _contractAddress, uint _vegaFeeCoefficient);
  /**
   * @dev Emitted when standard size is set.
   */
  event StandardSizeSet(address indexed _contractAddress, uint _standardSize);
  /**
   * @dev Emitted when skew ddjustment factor is set.
   */
  event SkewAdjustmentFactorSet(address indexed _contractAddress, uint _skewAdjustmentFactor);
  /**
   * @dev Emitted when vegaNorm factor is set.
   */
  event VegaNormFactorSet(address indexed _contractAddress, uint _vegaNormFactor);
  /**
   * @dev Emitted when rate and carry is set.
   */
  event RateAndCarrySet(address indexed _contractAddress, int _rateAndCarry);
  /**
   * @dev Emitted when min delta is set.
   */
  event MinDeltaSet(address indexed _contractAddress, int _minDelta);
  /**
   * @dev Emitted when volatility cutoff is set.
   */
  event VolatilityCutoffSet(address indexed _contractAddress, uint _volatilityCutoff);
  /**
   * @dev Emitted when quote key is set.
   */
  event QuoteMessageSet(address indexed _contractAddress, address _quoteAddress);
  /**
   * @dev Emitted when base key is set.
   */
  event BaseMessageSet(address indexed _contractAddress, address _baseAddress);
}

//SPDX-License-Identifier: MIT
//
//Copyright (c) 2019 Synthetix
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.

pragma solidity ^0.8.0;

// Libraries
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// https://docs.synthetix.io/contracts/source/libraries/SafeDecimalMath/
library SafeDecimalMath {
  using SafeMath for uint;

  /* Number of decimal places in the representations. */
  uint8 public constant decimals = 18;
  uint8 public constant highPrecisionDecimals = 27;

  /* The number representing 1.0. */
  uint public constant UNIT = 10**uint(decimals);

  /* The number representing 1.0 for higher fidelity numbers. */
  uint public constant PRECISE_UNIT = 10**uint(highPrecisionDecimals);
  uint private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = 10**uint(highPrecisionDecimals - decimals);

  /**
   * @return Provides an interface to UNIT.
   */
  function unit() external pure returns (uint) {
    return UNIT;
  }

  /**
   * @return Provides an interface to PRECISE_UNIT.
   */
  function preciseUnit() external pure returns (uint) {
    return PRECISE_UNIT;
  }

  /**
   * @return The result of multiplying x and y, interpreting the operands as fixed-point
   * decimals.
   *
   * @dev A unit factor is divided out after the product of x and y is evaluated,
   * so that product must be less than 2**256. As this is an integer division,
   * the internal division always rounds down. This helps save on gas. Rounding
   * is more expensive on gas.
   */
  function multiplyDecimal(uint x, uint y) internal pure returns (uint) {
    /* Divide by UNIT to remove the extra factor introduced by the product. */
    return x.mul(y) / UNIT;
  }

  /**
   * @return The result of safely multiplying x and y, interpreting the operands
   * as fixed-point decimals of the specified precision unit.
   *
   * @dev The operands should be in the form of a the specified unit factor which will be
   * divided out after the product of x and y is evaluated, so that product must be
   * less than 2**256.
   *
   * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
   * Rounding is useful when you need to retain fidelity for small decimal numbers
   * (eg. small fractions or percentages).
   */
  function _multiplyDecimalRound(
    uint x,
    uint y,
    uint precisionUnit
  ) private pure returns (uint) {
    /* Divide by UNIT to remove the extra factor introduced by the product. */
    uint quotientTimesTen = x.mul(y) / (precisionUnit / 10);

    if (quotientTimesTen % 10 >= 5) {
      quotientTimesTen += 10;
    }

    return quotientTimesTen / 10;
  }

  /**
   * @return The result of safely multiplying x and y, interpreting the operands
   * as fixed-point decimals of a precise unit.
   *
   * @dev The operands should be in the precise unit factor which will be
   * divided out after the product of x and y is evaluated, so that product must be
   * less than 2**256.
   *
   * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
   * Rounding is useful when you need to retain fidelity for small decimal numbers
   * (eg. small fractions or percentages).
   */
  function multiplyDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
    return _multiplyDecimalRound(x, y, PRECISE_UNIT);
  }

  /**
   * @return The result of safely multiplying x and y, interpreting the operands
   * as fixed-point decimals of a standard unit.
   *
   * @dev The operands should be in the standard unit factor which will be
   * divided out after the product of x and y is evaluated, so that product must be
   * less than 2**256.
   *
   * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
   * Rounding is useful when you need to retain fidelity for small decimal numbers
   * (eg. small fractions or percentages).
   */
  function multiplyDecimalRound(uint x, uint y) internal pure returns (uint) {
    return _multiplyDecimalRound(x, y, UNIT);
  }

  /**
   * @return The result of safely dividing x and y. The return value is a high
   * precision decimal.
   *
   * @dev y is divided after the product of x and the standard precision unit
   * is evaluated, so the product of x and UNIT must be less than 2**256. As
   * this is an integer division, the result is always rounded down.
   * This helps save on gas. Rounding is more expensive on gas.
   */
  function divideDecimal(uint x, uint y) internal pure returns (uint) {
    /* Reintroduce the UNIT factor that will be divided out by y. */
    return x.mul(UNIT).div(y);
  }

  /**
   * @return The result of safely dividing x and y. The return value is as a rounded
   * decimal in the precision unit specified in the parameter.
   *
   * @dev y is divided after the product of x and the specified precision unit
   * is evaluated, so the product of x and the specified precision unit must
   * be less than 2**256. The result is rounded to the nearest increment.
   */
  function _divideDecimalRound(
    uint x,
    uint y,
    uint precisionUnit
  ) private pure returns (uint) {
    uint resultTimesTen = x.mul(precisionUnit * 10).div(y);

    if (resultTimesTen % 10 >= 5) {
      resultTimesTen += 10;
    }

    return resultTimesTen / 10;
  }

  /**
   * @return The result of safely dividing x and y. The return value is as a rounded
   * standard precision decimal.
   *
   * @dev y is divided after the product of x and the standard precision unit
   * is evaluated, so the product of x and the standard precision unit must
   * be less than 2**256. The result is rounded to the nearest increment.
   */
  function divideDecimalRound(uint x, uint y) internal pure returns (uint) {
    return _divideDecimalRound(x, y, UNIT);
  }

  /**
   * @return The result of safely dividing x and y. The return value is as a rounded
   * high precision decimal.
   *
   * @dev y is divided after the product of x and the high precision unit
   * is evaluated, so the product of x and the high precision unit must
   * be less than 2**256. The result is rounded to the nearest increment.
   */
  function divideDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
    return _divideDecimalRound(x, y, PRECISE_UNIT);
  }

  /**
   * @dev Convert a standard decimal representation to a high precision one.
   */
  function decimalToPreciseDecimal(uint i) internal pure returns (uint) {
    return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
  }

  /**
   * @dev Convert a high precision decimal to a standard decimal representation.
   */
  function preciseDecimalToDecimal(uint i) internal pure returns (uint) {
    uint quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

    if (quotientTimesTen % 10 >= 5) {
      quotientTimesTen += 10;
    }

    return quotientTimesTen / 10;
  }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

// https://docs.synthetix.io/contracts/source/interfaces/iexchanger
interface IExchanger {
  function feeRateForExchange(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey)
    external
    view
    returns (uint exchangeFeeRate);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

interface ILendingPool {
    /**
     * @dev Emitted on deposit()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the deposit
   * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
   * @param amount The amount deposited
   * @param referral The referral code used
   **/
    event Deposit(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referral
    );

    /**
     * @dev Emitted on withdraw()
   * @param reserve The address of the underlyng asset being withdrawn
   * @param user The address initiating the withdrawal, owner of aTokens
   * @param to Address that will receive the underlying
   * @param amount The amount to be withdrawn
   **/
    event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

    /**
     * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
   * @param reserve The address of the underlying asset being borrowed
   * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
   * initiator of the transaction on flashLoan()
   * @param onBehalfOf The address that will be getting the debt
   * @param amount The amount borrowed out
   * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
   * @param borrowRate The numeric rate at which the user has borrowed
   * @param referral The referral code used
   **/
    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 borrowRateMode,
        uint256 borrowRate,
        uint16 indexed referral
    );

    /**
     * @dev Emitted on repay()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The beneficiary of the repayment, getting his debt reduced
   * @param repayer The address of the user initiating the repay(), providing the funds
   * @param amount The amount repaid
   **/
    event Repay(
        address indexed reserve,
        address indexed user,
        address indexed repayer,
        uint256 amount
    );

    /**
     * @dev Emitted on swapBorrowRateMode()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user swapping his rate mode
   * @param rateMode The rate mode that the user wants to swap to
   **/
    event Swap(address indexed reserve, address indexed user, uint256 rateMode);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
    event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
    event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on rebalanceStableBorrowRate()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user for which the rebalance has been executed
   **/
    event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on flashLoan()
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param asset The address of the asset being flash borrowed
   * @param amount The amount flash borrowed
   * @param premium The fee flash borrowed
   * @param referralCode The referral code used
   **/
    event FlashLoan(
        address indexed target,
        address indexed initiator,
        address indexed asset,
        uint256 amount,
        uint256 premium,
        uint16 referralCode
    );

    /**
     * @dev Emitted when the pause is triggered.
   */
    event Paused();

    /**
     * @dev Emitted when the pause is lifted.
   */
    event Unpaused();

    /**
     * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
   * LendingPoolCollateral manager using a DELEGATECALL
   * This allows to have the events in the generated ABI for LendingPool.
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
   * @param liquidator The address of the liquidator
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveAToken
    );

    /**
     * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
   * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
   * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
   * gets added to the LendingPool ABI
   * @param reserve The address of the underlying asset of the reserve
   * @param liquidityRate The new liquidity rate
   * @param stableBorrowRate The new stable borrow rate
   * @param variableBorrowRate The new variable borrow rate
   * @param liquidityIndex The new liquidity index
   * @param variableBorrowIndex The new variable borrow index
   **/
    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 stableBorrowRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );

    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   **/
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @return The final amount repaid
   **/
    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external returns (uint256);

    /**
     * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
   * @param asset The address of the underlying asset borrowed
   * @param rateMode The rate mode that the user wants to swap to
   **/
    function swapBorrowRateMode(address asset, uint256 rateMode) external;

    /**
     * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
   * - Users can be rebalanced if the following conditions are satisfied:
   *     1. Usage ratio is above 95%
   *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
   *        borrowed at a stable rate and depositors are not earning enough
   * @param asset The address of the underlying asset borrowed
   * @param user The address of the user to be rebalanced
   **/
    function rebalanceStableBorrowRate(address asset, address user) external;

    /**
     * @dev Allows depositors to enable/disable a specific deposited asset as collateral
   * @param asset The address of the underlying asset deposited
   * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
   **/
    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

    /**
     * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;

    /**
     * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
   * For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
   * @param assets The addresses of the assets being flash-borrowed
   * @param amounts The amounts amounts being flash-borrowed
   * @param modes Types of the debt to open if the flash loan is not returned:
   *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
   *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @dev Returns the user account data across all the reserves
   * @param user The address of the user
   * @return totalCollateralETH the total collateral in ETH of the user
   * @return totalDebtETH the total debt in ETH of the user
   * @return availableBorrowsETH the borrowing power left of the user
   * @return currentLiquidationThreshold the liquidation threshold of the user
   * @return ltv the loan to value of the user
   * @return healthFactor the current health factor of the user
   **/
    function getUserAccountData(address user)
    external
    view
    returns (
        uint256 totalCollateralETH,
        uint256 totalDebtETH,
        uint256 availableBorrowsETH,
        uint256 currentLiquidationThreshold,
        uint256 ltv,
        uint256 healthFactor
    );

    function initReserve(
        address reserve,
        address aTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external;

    function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress)
    external;

    function setConfiguration(address reserve, uint256 configuration) external;

    /**
     * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
    function getReserveNormalizedIncome(address asset) external view returns (uint256);

    /**
     * @dev Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
    function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromAfter,
        uint256 balanceToBefore
    ) external;

    function getReservesList() external view returns (address[] memory);

    function setPause(bool val) external;

    function paused() external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter {
  struct ExactInputParams {
    bytes path;
    address recipient;
    uint deadline;
    uint amountIn;
    uint amountOutMinimum;
  }

  /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
  /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
  /// @return amountOut The amount of the received token
  function exactInput(ExactInputParams calldata params) external payable returns (uint amountOut);
}

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

// https://docs.synthetix.io/contracts/source/interfaces/iexchangerates
interface IExchangeRates {
  function rateAndInvalid(bytes32 currencyKey) external view returns (uint rate, bool isInvalid);
}

//SPDX-License-Identifier: ISC
pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

import "./IOzillaGlobals.sol";

interface ILiquidityPool {
  struct Collateral {
    uint quote;
    uint base;
  }

  /// @dev These are all in quoteAsset amounts.
  struct Liquidity {
    uint freeCollatLiquidity;
    uint usedCollatLiquidity;
    uint freeDeltaLiquidity;
    uint usedDeltaLiquidity;
  }

  enum Error {
    QuoteTransferFailed,
    AlreadySignalledWithdrawal,
    SignallingBetweenRounds,
    UnSignalMustSignalFirst,
    UnSignalAlreadyBurnable,
    WithdrawNotBurnable,
    EndRoundWithLiveBoards,
    EndRoundAlreadyEnded,
    EndRoundMustExchangeBase,
    EndRoundMustHedgeDelta,
    StartRoundMustEndRound,
    ReceivedZeroFromBaseQuoteExchange,
    ReceivedZeroFromQuoteBaseExchange,
    LockingMoreQuoteThanIsFree,
    LockingMoreBaseThanCanBeExchanged,
    FreeingMoreBaseThanLocked,
    SendPremiumNotEnoughCollateral,
    OnlyPoolHedger,
    OnlyOptionMarket,
    OnlyShortCollateral,
    ReentrancyDetected,
    Last
  }

  function lockedCollateral() external view returns (uint, uint);

  function queuedQuoteFunds() external view returns (uint);

  function expiryToTokenValue(uint) external view returns (uint);

  function deposit(address beneficiary, uint amount) external returns (uint);

  function signalWithdrawal(uint certificateId) external;

  function unSignalWithdrawal(uint certificateId) external;

  function withdraw(address beneficiary, uint certificateId) external returns (uint value);

//  function tokenPriceQuote() external view returns (uint);

  function endRound() external;

  function startRound(uint lastMaxExpiryTimestamp, uint newMaxExpiryTimestamp) external;

  function exchangeBase() external;

  function lockQuote(uint amount, uint freeCollatLiq) external;

  function lockBase(
    uint amount,
    IOzillaGlobals.ExchangeGlobals memory exchangeGlobals,
    Liquidity memory liquidity
  ) external;

  function freeQuoteCollateral(uint amount) external;

  function freeBase(uint amountBase) external;

  function sendPremium(
    address recipient,
    uint amount,
    uint freeCollatLiq
  ) external;

  function boardLiquidation(
    uint amountQuoteFreed,
    uint amountQuoteReserved,
    uint amountBaseFreed
  ) external;

  function sendReservedQuote(address user, uint amount) external;

  function getTotalPoolValueQuote(uint basePrice, uint usedDeltaLiquidity) external view returns (uint);

  function getLiquidity(uint basePrice) external view returns (Liquidity memory);

  function transferQuoteToHedge(IOzillaGlobals.ExchangeGlobals memory exchangeGlobals, uint amount)
    external
    returns (uint);

  function transferBaseToHedge(uint amount)
  external
  returns (uint);
}

/**
 *Submitted for verification at Etherscan.io on 2020-05-05
*/

// File: contracts/interfaces/IUniswapV2Pair.sol

pragma solidity >=0.8.0;

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

//SPDX-License-Identifier: ISC
pragma solidity ^0.8.0;

interface IMockPricer {
    function setPrice(uint256 _price) external;

    function getPrice() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

//SPDX-License-Identifier: ISC
pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

import "./ICollateralShort.sol";
import "./IExchangeRates.sol";
import "./IExchanger.sol";
import "./IUniswapV2Pair.sol";
import "./ILendingPool.sol";
import "./ISwapRouter.sol";

interface IOzillaGlobals {
  enum ExchangeType {BASE_QUOTE, QUOTE_BASE, ALL}

  /**
   * @dev Structs to help reduce the number of calls between other contracts and this one
   * Grouped in usage for a particular contract/use case
   */
  struct ExchangeGlobals {
    uint spotPrice;
    address quoteAddress;
    address baseAddress;
    ISwapRouter swapRouter;
    IUniswapV2Pair uniswapV2Pair;
    ILendingPool lendingPool;
  }

  struct GreekCacheGlobals {
    int rateAndCarry;
    uint spotPrice;
  }

  struct PricingGlobals {
    uint optionPriceFeeCoefficient;
    uint spotPriceFeeCoefficient;
    uint vegaFeeCoefficient;
    uint vegaNormFactor;
    uint standardSize;
    uint skewAdjustmentFactor;
    int rateAndCarry;
    int minDelta;
    uint volatilityCutoff;
    uint spotPrice;
  }

  function swapRouter() external view returns (ISwapRouter);

  function uniswapV2Pair() external view returns (IUniswapV2Pair);

  function exchanger() external view returns (IExchanger);

  function exchangeRates() external view returns (IExchangeRates);

  function lendingPool() external view returns (ILendingPool);

  function isPaused() external view returns (bool);

  function tradingCutoff(address) external view returns (uint);

  function optionPriceFeeCoefficient(address) external view returns (uint);

  function spotPriceFeeCoefficient(address) external view returns (uint);

  function vegaFeeCoefficient(address) external view returns (uint);

  function vegaNormFactor(address) external view returns (uint);

  function standardSize(address) external view returns (uint);

  function skewAdjustmentFactor(address) external view returns (uint);

  function rateAndCarry(address) external view returns (int);

  function minDelta(address) external view returns (int);

  function volatilityCutoff(address) external view returns (uint);

  function quoteMessage(address) external view returns (address);

  function baseMessage(address) external view returns (address);

  function setGlobals(ISwapRouter _swapRouter, ILendingPool _lendingPool ,IUniswapV2Pair _uniswapV2Pair) external;

  function setGlobalsForContract(
    address _contractAddress,
    uint _tradingCutoff,
    PricingGlobals memory pricingGlobals,
    address _quoteAddress,
    address _baseAddress
  ) external;

  function setPaused(bool _isPaused) external;

  function setTradingCutoff(address _contractAddress, uint _tradingCutoff) external;

  function setOptionPriceFeeCoefficient(address _contractAddress, uint _optionPriceFeeCoefficient) external;

  function setSpotPriceFeeCoefficient(address _contractAddress, uint _spotPriceFeeCoefficient) external;

  function setVegaFeeCoefficient(address _contractAddress, uint _vegaFeeCoefficient) external;

  function setVegaNormFactor(address _contractAddress, uint _vegaNormFactor) external;

  function setStandardSize(address _contractAddress, uint _standardSize) external;

  function setSkewAdjustmentFactor(address _contractAddress, uint _skewAdjustmentFactor) external;

  function setRateAndCarry(address _contractAddress, int _rateAndCarry) external;

  function setMinDelta(address _contractAddress, int _minDelta) external;

  function setVolatilityCutoff(address _contractAddress, uint _volatilityCutoff) external;

  function setQuoteMessage(address _contractAddress, address _quoteAddress) external;

  function setBaseMessage(address _contractAddress, address _baseAddress) external;

  function getSpotPriceForMarket(address _contractAddress) external view returns (uint);

  function getSpotPrice(address to) external view returns(uint256);

  function getPricingGlobals(address _contractAddress) external view returns (PricingGlobals memory);

  function getGreekCacheGlobals(address _contractAddress) external view returns (GreekCacheGlobals memory);

  function getExchangeGlobals(address _contractAddress) external view returns (ExchangeGlobals memory exchangeGlobals);

  function getGlobalsForOptionTrade(address _contractAddress)
    external
    view
    returns (
      PricingGlobals memory pricingGlobals,
      ExchangeGlobals memory exchangeGlobals,
      uint tradeCutoff
    );
}

//SPDX-License-Identifier: ISC
pragma solidity >=0.8.0;
pragma experimental ABIEncoderV2;

interface ICollateralShort {
  struct Loan {
    // ID for the loan
    uint id;
    //  Account that created the loan
    address account;
    //  Amount of collateral deposited
    uint collateral;
    // The synth that was borrowed
    address currency;
    //  Amount of synths borrowed
    uint amount;
    // Indicates if the position was short sold
    bool short;
    // interest amounts accrued
    uint accruedInterest;
    // last interest index
    uint interestIndex;
    // time of last interaction.
    uint lastInteraction;
  }

  function loans(uint id)
    external
    returns (
      uint,
      address,
      uint,
      address,
      uint,
      bool,
      uint,
      uint,
      uint
    );

  function minCratio() external returns (uint);

  function minCollateral() external returns (uint);

  function issueFeeRate() external returns (uint);

  function open(
    uint collateral,
    uint amount,
    address currency
  ) external returns (uint id);

  function repay(
    address borrower,
    uint id,
    uint amount
  ) external returns (uint short, uint collateral);

  function repayWithCollateral(uint id, uint repayAmount) external returns (uint short, uint collateral);

  function draw(uint id, uint amount) external returns (uint short, uint collateral);

  // Same as before
  function deposit(
    address borrower,
    uint id,
    uint amount
  ) external returns (uint short, uint collateral);

  // Same as before
  function withdraw(uint id, uint amount) external returns (uint short, uint collateral);

  // function to return the loan details in one call, without needing to know about the collateralstate
  function getShortAndCollateral(address account, uint id) external view returns (uint short, uint collateral);
}