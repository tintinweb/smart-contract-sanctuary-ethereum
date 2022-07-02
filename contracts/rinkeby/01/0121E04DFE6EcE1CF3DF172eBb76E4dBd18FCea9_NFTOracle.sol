// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

import {INFTOracle} from '../interfaces/INFTOracle.sol';
import {Ownable} from '../dependencies/openzeppelin/contracts/Ownable.sol';

/**
 * @title NFTOracle
 * @author Vinci
 **/
contract NFTOracle is INFTOracle, Ownable {

  // batch update
  struct Input {
    uint64[4] prices;
    address[4] addresses;
    uint64 id;
  }

  // asset address
  struct Location {
    uint64 id;
    uint64 index;
  }
  mapping (address => Location) internal locations;
  address[] internal addressList;
  uint64 internal locationId;
  uint64 internal locationIndex;

  // price
  struct Price {
    uint64 v1;
    uint64 v2;
    uint64 v3;
    uint64 v4;
  }
  mapping (uint256 => Price) internal prices;

  /// @notice Constructor
  /// @param assets The addresses of the assets
  constructor(address[] memory assets) public {
    _addAssets(assets);
  }

  function _addAssets(address[] memory addresses) internal {
    uint64 id = locationId;
    uint64 index = locationIndex;
    for (uint256 i = 0; i < addresses.length; i++) {
      address _asset = addresses[i];
      Location memory cacheLocation = locations[_asset];
      if (cacheLocation.id == 0) {
        if (index >= 4) {
          index = 0;
          id++;
        }
        index++;
        addressList.push(_asset);
        cacheLocation.id = id + 1;
        cacheLocation.index = index;
        locations[_asset] = cacheLocation;
        emit AddAsset(_asset, id + 1, index);
      }
    }
    locationId = id;
    locationIndex = index;
  }

  function getAddressList() external view returns(address[] memory) {
    return addressList;
  }

  function getLocation(address _asset) external view returns (uint64, uint64) {
    Location memory cacheLocation = locations[_asset];
    return (cacheLocation.id, cacheLocation.index);
  }

  function _setAssetPrice(address _asset, uint64 _price) internal {
    Location memory location = locations[_asset];
    Price storage price = prices[location.id];
    if (location.index == 1) {
      price.v1 = _price;
    } else if (location.index == 2) {
      price.v2 = _price;
    } else if (location.index == 3) {
      price.v3 = _price;
    } else if (location.index == 4) {
      price.v4 = _price;
    }
  }

  function _setAllPrice(uint256 _id, uint64[4] memory _prices) internal {
    Price storage price = prices[_id];
    price.v1 = _prices[0];
    price.v2 = _prices[1];
    price.v3 = _prices[2];
    price.v4 = _prices[3];
  }

  function addAssets(address[] memory _assets) external onlyOwner {
    _addAssets(_assets);
  }

  function batchSetAssetPrice(Input[] calldata input) external onlyOwner {
    for (uint256 i = 0; i < input.length; i++) {
      Input memory cacheInput = input[i];
      uint64[4] memory _prices = cacheInput.prices;
      _setAllPrice(cacheInput.id, _prices);
      emit BatchSetAssetData(cacheInput.addresses, _prices, block.timestamp);
    }
  }

  // set in GWei
  function setAssetPriceInGwei(address _asset, uint64 _price) external onlyOwner {
    _setAssetPrice(_asset, _price);
    emit SetAssetData(_asset, _price, block.timestamp);
  }

  // return in Wei
  function getAssetPrice(address _asset) public view virtual returns (uint256) {
    Location memory location = locations[_asset];
    Price storage price = prices[location.id];
    uint256 _price;
    if (location.index == 1) {
      _price = price.v1;
    } else if (location.index == 2) {
      _price = price.v2;
    } else if (location.index == 3) {
      _price = price.v3;
    } else if (location.index == 4) {
      _price = price.v4;
    }
    return _price * 1e9;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

/************
@title INFTOracle interface
@notice Interface for the NFT price oracle.*/
interface INFTOracle {

  event OracleUpdaterChange(address newOracleUpdater);
  event SetAssetData(address indexed asset, uint64 price, uint256 timestamp);
  event BatchSetAssetData(address[4] addresses,  uint64[4] prices, uint256 timestamp);
  event AddAsset(address indexed asset, uint64 id, uint64 index);

  /***********
    @dev returns the nft asset price in wei
     */
  function getAssetPrice(address asset) external view returns (uint256);

  /***********
    @dev returns the addresses of the assets
  */
  function getAddressList() external view returns(address[] memory);

  /***********
    @dev returns the location of the asset
  */
  function getLocation(address _asset) external view returns (uint64, uint64);
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