// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface Aggregator {
  function latestAnswer() external view returns (int);
}

struct OracleAsset {
  Aggregator aggregator;
  uint8 decimals;
}

interface IPriceFeedOracle {

  function ETH() external view returns (address);
  function assets(address) external view returns (Aggregator, uint8);

  function getAssetToEthRate(address asset) external view returns (uint);
  function getAssetForEth(address asset, uint ethIn) external view returns (uint);
  function getEthForAsset(address asset, uint amount) external view returns (uint);

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.18;

import "../../interfaces/IPriceFeedOracle.sol";


contract PriceFeedOracle is IPriceFeedOracle {

  mapping(address => OracleAsset) public assets;

  address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  constructor(
    address[] memory _assetAddresses,
    address[] memory _assetAggregators,
    uint8[] memory _assetDecimals
  ) {
    require(
      _assetAddresses.length == _assetAggregators.length && _assetAggregators.length == _assetDecimals.length,
      "PriceFeedOracle: different args length"
    );

    for (uint i = 0; i < _assetAddresses.length; i++) {
      assets[_assetAddresses[i]] = OracleAsset(Aggregator(_assetAggregators[i]), _assetDecimals[i]);
    }
  }

  /**
   * @dev Returns the amount of ether in wei that are equivalent to 1 unit (10 ** decimals) of asset
   * @param assetAddress address of asset
   * @return price in ether
   */
  function getAssetToEthRate(address assetAddress) public view returns (uint) {
    if (assetAddress == ETH) {
      return 1 ether;
    }

    OracleAsset memory asset = assets[assetAddress];
    return _getAssetToEthRate(asset.aggregator);
  }

  /**
   * @dev Returns the amount of currency that is equivalent to ethIn amount of ether.
   * @param assetAddress address of asset
   * @param ethIn amount of ether to be converted to the asset
   * @return asset amount
   */
  function getAssetForEth(address assetAddress, uint ethIn) external view returns (uint) {
    if (assetAddress == ETH) {
      return ethIn;
    }

    OracleAsset memory asset = assets[assetAddress];
    uint price = _getAssetToEthRate(asset.aggregator);

    return ethIn * (10**uint(asset.decimals)) / price;
  }

  /**
   * @dev Returns the amount of eth that is equivalent to a given asset and amount
   * @param assetAddress address of asset
   * @param amount amount of asset
   * @return amount of ether
   */
  function getEthForAsset(address assetAddress, uint amount) external view returns (uint) {
    if (assetAddress == ETH) {
      return amount;
    }

    OracleAsset memory asset = assets[assetAddress];
    uint price = _getAssetToEthRate(asset.aggregator);

    return amount * (price) / 10**uint(asset.decimals);
  }

  /**
   * @dev Returns the amount of ether in wei that are equivalent to 1 unit (10 ** decimals) of asset
   * @param aggregator The asset aggregator
   * @return price in ether
   */
  function _getAssetToEthRate(Aggregator aggregator) internal view returns (uint) {
    require(address(aggregator) != address(0), "PriceFeedOracle: Unknown asset");
    // TODO: consider checking the latest timestamp and revert if it's *very* old
    int rate = aggregator.latestAnswer();
    require(rate > 0, "PriceFeedOracle: Rate must be > 0");

    return uint(rate);
  }
}