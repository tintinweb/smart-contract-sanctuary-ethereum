// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../IOracleRelay.sol";

interface IBalancerFeed {
  enum Variable {
    PAIR_PRICE,
    BPT_PRICE,
    INVARIANT
  }

  struct OracleAverageQuery {
    Variable variable;
    uint256 secs;
    uint256 ago;
  }

  //this returns the deviation from the true peg
  function getTimeWeightedAverage(OracleAverageQuery[] memory queries) external view returns (uint256[] memory);
}

interface IRateProvider {
  //this returns the true peg
  function getRate() external view returns (uint256);
}

/*****************************************
 *
 * This relay gets a USD price for a wrapped wrapped asset from a balancer MetaStablePool
 * 
 */

contract BalancerPeggedAssetRelay is IOracleRelay {
  uint256 public immutable _multiply;
  uint256 public immutable _divide;
  uint256 public immutable _secs;

  IBalancerFeed private immutable _priceFeed;
  IRateProvider private immutable _rateProvider;
  IOracleRelay public immutable _underlyingOracle;

  /**
  * @param lookback - How many seconds to look back when generating TWAP
  * @param pool_address - Balancer MetaStablePool address
  * @param rateProvider - Provides the rate for the peg, typically can be found at @param pool_address.getRateProviders()
  */
  constructor(
    uint32 lookback,
    address pool_address,
    address rateProvider,
    address underlyingRelay,
    uint256 mul,
    uint256 div
  ) {
    _priceFeed = IBalancerFeed(pool_address);
    _rateProvider = IRateProvider(rateProvider);
    _underlyingOracle = IOracleRelay(underlyingRelay);//0x22B01826063564CBe01Ef47B96d623b739F82Bf2

    _multiply = mul;
    _divide = div;
    _secs = lookback;
  }

  function currentValue() external view override returns (uint256) {
    uint256 peg = _rateProvider.getRate();
    uint256 deviation = getDeviation();

    uint256 priceInunderlying = (deviation * peg) / 1e18;
    uint256 underlyingPrice = _underlyingOracle.currentValue();

    ///@notice switch to this to invert the price if needed, such that
    // priceInunderlying == wrapped assets per 1 underlying
    // return divide(underlyingPrice, priceInunderlying, 18);

    ///underlyingPrice == underlying per 1 wrapped asset
    return (underlyingPrice * priceInunderlying) / 1e18;
  }

  function getDeviation() private view returns (uint256) {
    IBalancerFeed.OracleAverageQuery[] memory inputs = new IBalancerFeed.OracleAverageQuery[](1);

    inputs[0] = IBalancerFeed.OracleAverageQuery({
      variable: IBalancerFeed.Variable.PAIR_PRICE,
      secs: _secs,
      ago: 0
    });

    uint256 result = _priceFeed.getTimeWeightedAverage(inputs)[0];
    return result;
  }

  /**
   * // this is only needed to invert the price
  function divide(
    uint256 numerator,
    uint256 denominator,
    uint256 factor
  ) internal pure returns (uint256) {
    uint256 q = (numerator / denominator) * 10**factor;
    uint256 r = ((numerator * 10**factor) / denominator) % 10**factor;

    return q + r;
  }
   */
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @title OracleRelay Interface
/// @notice Interface for interacting with OracleRelay
interface IOracleRelay {
  // returns  price with 18 decimals
  function currentValue() external view returns (uint256);
}