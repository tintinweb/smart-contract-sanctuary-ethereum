// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./interfaces/IPriceConsumer.sol";

contract PriceConsumer is IPriceConsumer {
	/**
	 * Network: Rinkeby
	 * Aggregators: ETH/USD, BTC/USD, XAU/USD, XFT/USD
	 */

	enum Assets {
		XFT,
		USD,
		BTC,
		ETH,
		XAU
	}

	uint8 internal constant _decimalmax = 18;

	constructor() {}

	/**
	 * @dev Returns required input amount of the asset given an output amount of other asset.
	 * @param exchAggr aggregator of input asset.
	 * @param quoteAggr aggregator of output asset.
	 * @param exchAmount output amount.
	 * @return input amount and decimals.
	 */
	function exchangeAssets(
		uint8 exchAggr,
		uint8 quoteAggr,
		uint256 exchAmount
	) external view override returns (uint256, uint8) {
		require(exchAggr != quoteAggr, "Aggregator names are the same");
		(uint256 _quotePrice, uint8 _quoteDecimal) = getDerivedPrice(exchAggr, quoteAggr);

		return (uint256(exchAmount * _quotePrice) / (uint256(10**_quoteDecimal)), _quoteDecimal);
	}

	/**
	 * @dev Returns output amount of the asset given other asset.
 	 * @param baseAggr input asset agregator.
	 * @param quoteAggr output asset agregator.
	 * @return amount and decimals.
	 */
	function getDerivedPrice(uint8 baseAggr, uint8 quoteAggr)
		public
		view
		returns (uint256, uint8)
	{
		(int256 _basePrice, uint8 _baseDecimals) = getLatestPrice(baseAggr);
		(int256 _quotePrice, uint8 _quoteDecimals) = getLatestPrice(quoteAggr);

		(_basePrice, _baseDecimals) = _scalePrice(_basePrice, _baseDecimals, _decimalmax);
		(_quotePrice, _quoteDecimals) = _scalePrice(_quotePrice, _quoteDecimals, _decimalmax);

		return (
			uint256((_basePrice * (int256(10**uint256(_baseDecimals)))) / _quotePrice),
			_quoteDecimals
		);
	}

	/**
	 * @dev Returns the latest price.
	 * @param aggregator Token name by number in Assets enum.
	 * @return price and decimals
	 */
	function getLatestPrice(uint8 aggregator) public view returns (int256, uint8) {
		//aggregator need be capital letters
		if (aggregator == uint8(Assets.USD)) {
			return (int256(10**uint256(_decimalmax)), _decimalmax);
		}
		address _addrAggr = _getAddrAggregator(aggregator);
		require(_addrAggr != address(0), "Adress aggregator cannot be zero.");
		(, int256 _price, , , ) = AggregatorV3Interface(_addrAggr).latestRoundData();
		uint8 _decimals = AggregatorV3Interface(_addrAggr).decimals();
		return (_price, _decimals);
	}

	/**
	 * @dev Returns the aggregator address.
	 * @param _aggregator Token name by number in Assets enum.
	 * @return address.
	 */
	function _getAddrAggregator(uint8 _aggregator) internal pure returns (address) {
		address _addrAggregator;

		if (_aggregator == uint8(Assets.USD))
			_addrAggregator = 0xECe365B379E1dD183B20fc5f022230C044d51404;

		if (_aggregator == uint8(Assets.ETH))
			_addrAggregator = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;

		if (_aggregator == uint8(Assets.XAU))
			_addrAggregator = 0x81570059A0cb83888f1459Ec66Aad1Ac16730243;

		if (_aggregator == uint8(Assets.XFT))
			_addrAggregator = 0xab4a352ac35dFE83221220D967Db41ee61A0DeFa;

		return _addrAggregator;
	}

	/**
	 * @dev Convert the price to the set decimals.
	 * @param _price Token name by number in Assets enum.
	 * @param _priceDecimals Token name by number in Assets enum.
	 * @param _decimals Token name by number in Assets enum.
	 * @return price and decimals.
	 */
	function _scalePrice(
		int256 _price,
		uint8 _priceDecimals,
		uint8 _decimals
	) internal pure returns (int256, uint8) {
		if (_priceDecimals < _decimals) {
			return (_price * int256(10**uint256(_decimals - _priceDecimals)), _decimals);
		} else if (_priceDecimals > _decimals) {
			return (_price / int256(10**uint256(_priceDecimals - _decimals)), _priceDecimals);
		}
		return (_price, _priceDecimals);
	}

	/**
	 * @dev Function for check aggregators equality.
	 * @param _aggr Token name by number in Assets enum.
	 * @param _name Token name by number in Assets enum.
	 * @return result of the equality check.
	 */
	function _isEqualAggr(string memory _aggr, string memory _name) internal pure returns (bool) {
		bool _isEq = bytes(_aggr).length == bytes(_name).length;
		for (uint8 i = 0; i < bytes(_aggr).length; i++) {
			_isEq = _isEq && (bytes(_aggr)[i] == bytes(_name)[i]);
		}
		return _isEq;
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

pragma solidity =0.8.4;

interface IPriceConsumer {
	function exchangeAssets(
		uint8 exchAggr,
		uint8 quoteAggr,
		uint256 exchAmount
	) external view returns (uint256, uint8);
}