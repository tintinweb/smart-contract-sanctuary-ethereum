// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

import {INFTOracle} from '../interfaces/INFTOracle.sol';
import {Ownable} from '../dependencies/openzeppelin/contracts/Ownable.sol';

/**
 * @title NFTOracle
 * @author Vinci
 **/
contract NFTOracle is INFTOracle, Ownable {

  // asset address
  mapping (address => uint256) private _addressIndexes;
  address[] private _addressList;
  address private _operator;

  // price
  struct Price {
    uint32 v1;
    uint32 v2;
    uint32 v3;
    uint32 v4;
    uint32 v5;
    uint32 v6;
    uint32 v7;
    uint32 ts;
  }
  Price private _price;
  uint256 private constant PRECISION = 1e18;
  uint256 public maxPriceDeviation = 15 * 1e16;  // 15%
  uint256 public minUpdateTime = 30 * 60; // 30 min

  event SetAssetData(Price record);
  event ChangeOperator(address indexed oldOperator, address indexed newOperator);

  /// @notice Constructor
  /// @param assets The addresses of the assets
  constructor(address[] memory assets) public {
    _operator = _msgSender();
    _addAssets(assets);
  }

  function _addAssets(address[] memory addresses) private {
    uint256 index = _addressList.length + 1;
    for (uint256 i = 0; i < addresses.length; i++) {
      address addr = addresses[i];
      if (_addressIndexes[addr] == 0) {
        _addressIndexes[addr] = index;
        _addressList.push(addr);
        index++;
      }
    }
  }

  function operator() external view returns (address) {
    return _operator;
  }

  function getAddressList() external view returns (address[] memory) {
    return _addressList;
  }

  function getIndex(address asset) external view returns (uint256) {
    return _addressIndexes[asset];
  }

  function addAssets(address[] memory assets) external onlyOwner {
    require(assets.length > 0);
    _addAssets(assets);
  }

  function setPriceDeviation(uint256 priceDeviation) external onlyOwner {
    maxPriceDeviation = priceDeviation;
  }

  function setOperator(address newOperator) external onlyOwner {
    address oldOperator = _operator;
    _operator = newOperator;
    emit ChangeOperator(oldOperator, newOperator);
  }

  function _getPriceByIndex(uint256 index) private view returns(uint256) {
    Price memory cachePrice = _price;
    if (index == 1) {
      return cachePrice.v1;
    } else if (index == 2) {
      return cachePrice.v2;
    } else if (index == 3) {
      return cachePrice.v3;
    } else if (index == 4) {
      return cachePrice.v4;
    } else if (index == 5) {
      return cachePrice.v5;
    } else if (index == 6) {
      return cachePrice.v6;
    } else if (index == 7) {
      return cachePrice.v7;
    }
  }

  function getLatestTimestamp() external view returns (uint256) {
    return uint256(_price.ts);
  }

  // return in Wei
  function getAssetPrice(address asset) external view returns (uint256) {
    uint256 price = _getPriceByIndex(_addressIndexes[asset]);
    return price * 1e14;
  }

  function getNewPrice(
    uint256 latestPrice,
    uint256 latestTimestamp,
    uint256 currentPrice
  ) private view returns (uint256) {

    if (latestPrice == 0) {
      return currentPrice;
    }

    if (currentPrice == 0 || currentPrice == latestPrice) {
      return latestPrice;
    }

    uint256 percentDeviation;
    if (latestPrice > currentPrice) {
      percentDeviation = ((latestPrice - currentPrice) * PRECISION) / latestPrice;
    } else {
      percentDeviation = ((currentPrice - latestPrice) * PRECISION) / latestPrice;
    }

    uint256 timeDeviation = block.timestamp - latestTimestamp;

    if (percentDeviation > maxPriceDeviation) {
      return latestPrice;
    } else if (timeDeviation < minUpdateTime) {
      return latestPrice;
    }
    return currentPrice;
  }

  function _setAssetPrice(uint256[7] memory prices) private {
    Price storage cachePrice = _price;
    uint256 latestTimestamp = cachePrice.ts;
    // checkprice
    cachePrice.v1 = uint32(getNewPrice(cachePrice.v1, latestTimestamp, prices[0]));
    cachePrice.v2 = uint32(getNewPrice(cachePrice.v2, latestTimestamp, prices[1]));
    cachePrice.v3 = uint32(getNewPrice(cachePrice.v3, latestTimestamp, prices[2]));
    cachePrice.v4 = uint32(getNewPrice(cachePrice.v4, latestTimestamp, prices[3]));
    cachePrice.v5 = uint32(getNewPrice(cachePrice.v5, latestTimestamp, prices[4]));
    cachePrice.v6 = uint32(getNewPrice(cachePrice.v6, latestTimestamp, prices[5]));
    cachePrice.v7 = uint32(getNewPrice(cachePrice.v7, latestTimestamp, prices[6]));
    cachePrice.ts = uint32(block.timestamp);

    emit SetAssetData(cachePrice);
  }

  // set with 1e4
  function batchSetAssetPrice(address[] memory assets, uint256[] memory prices) external {
    require(_operator == _msgSender(), "NFTOracle: caller is not the operator");
    require(assets.length > 0 && assets.length == prices.length);
    uint256[7] memory newPrices;
    for (uint256 i = 0; i < assets.length; i++) {
      uint256 index = _addressIndexes[assets[i]];
      newPrices[index - 1] = prices[i];
    }
    _setAssetPrice(newPrices);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

/************
@title INFTOracle interface
@notice Interface for the NFT price oracle.*/
interface INFTOracle {

  /***********
    @dev returns the nft asset price in wei
     */
  function getAssetPrice(address asset) external view returns (uint256);

  /***********
    @dev returns the addresses of the assets
  */
  function getAddressList() external view returns(address[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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