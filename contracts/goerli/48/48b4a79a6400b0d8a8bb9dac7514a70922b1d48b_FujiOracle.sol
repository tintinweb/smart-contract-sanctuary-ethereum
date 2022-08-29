// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IAggregatorV3} from "./interfaces/chainlink/IAggregatorV3.sol";
import {IFujiOracle} from "./interfaces/IFujiOracle.sol";

/**
 * @dev Contract that returns and computes prices for the Fuji protocol
 */

contract FujiOracle is IFujiOracle, Ownable {
  // mapping from asset address to its price feed oracle in USD - decimals: 8
  mapping(address => address) public usdPriceFeeds;

  /**
   * @dev Initializes the contract setting '_priceFeeds' addresses for '_assets'
   */
  constructor(address[] memory _assets, address[] memory _priceFeeds) {
    require(_assets.length == _priceFeeds.length, "Invalid input!");
    for (uint256 i = 0; i < _assets.length; i++) {
      usdPriceFeeds[_assets[i]] = _priceFeeds[i];
    }
  }

  /**
   * @dev Sets '_priceFeed' address for a '_asset'.
   * Can only be called by the contract owner.
   * Emits a {AssetPriceFeedChanged} event.
   */
  function setPriceFeed(address _asset, address _priceFeed) public onlyOwner {
    require(_priceFeed != address(0), "Zero address!");
    usdPriceFeeds[_asset] = _priceFeed;
    emit AssetPriceFeedChanged(_asset, _priceFeed);
  }

  /**
   * @dev Calculates the exchange rate between two assets, with price oracle given in specified decimals.
   *      Format is: (_currencyAsset per unit of _commodityAsset Exchange Rate).
   * @param _currencyAsset: the currency asset, zero-address for USD.
   * @param _commodityAsset: the commodity asset, zero-address for USD.
   * @param _decimals: the decimals of the price output.
   * Returns the exchange rate of the given pair.
   */
  function getPriceOf(
    address _currencyAsset,
    address _commodityAsset,
    uint8 _decimals
  ) external view override returns (uint256 price) {
    price = 10**uint256(_decimals);

    if (_commodityAsset != address(0)) {
      price = price * _getUSDPrice(_commodityAsset);
    } else {
      price = price * (10**8);
    }

    if (_currencyAsset != address(0)) {
      price = price / _getUSDPrice(_currencyAsset);
    } else {
      price = price / (10**8);
    }
  }

  /**
   * @dev Calculates the USD price of asset.
   * @param _asset: the asset address.
   * Returns the USD price of the given asset
   */
  function _getUSDPrice(address _asset) internal view returns (uint256 price) {
    require(usdPriceFeeds[_asset] != address(0), "Missing price feed!");

    (, int256 latestPrice, , , ) = IAggregatorV3(usdPriceFeeds[_asset]).latestRoundData();

    price = uint256(latestPrice);
  }
}

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

interface IAggregatorV3 {
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

interface IFujiOracle {
  // FujiOracle Events

  /**
   * @dev Log a change in price feed address for asset address
   */
  event AssetPriceFeedChanged(address asset, address newPriceFeedAddress);

  function getPriceOf(
    address _collateralAsset,
    address _borrowAsset,
    uint8 _decimals
  ) external view returns (uint256);
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