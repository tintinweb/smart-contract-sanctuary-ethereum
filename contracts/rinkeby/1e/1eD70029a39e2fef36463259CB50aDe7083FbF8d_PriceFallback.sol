// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "../interfaces/IPriceFeed.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @notice Dynamic error for price getters
/// @dev Emitted when address of token is not authorized
error TokenNotAuthorized(bytes32 symbol);

/// @notice Dynamic error for price getters
/// @dev Emitted when got old price data
error OldPriceData(bytes32 sumbol);

/// @title RedStone Oracle Fallback contract
/// @author Moola Markets
/// @notice Utility contract to get price from price feed
/// @custom:contract Ownable implementation of admin modifiers
contract PriceFallback is Ownable {
  /// @notice Price feed address
  IPriceFeed public feed;

  /// @notice Map that authorizes assets (address to hash-symbol)
  mapping(address => bytes32) public addressToSymbol;

  /// @notice Hash-symbol for CELO
  bytes32 public constant CELO = bytes32("CELO");

  /// @notice Timestmap of each price update lifecycle
  uint256 public timestampDelay = 1 minutes;

  /// @notice Event emitted after feed is reset
  /// @param previous Previous price feed
  /// @param feed New price feed
  event ResetPriceFeed(address previous, address feed);
  /// @notice Event emmited after asset is authorized
  /// @param symbol Hash-symbol of asset
  /// @param asset Address of asset
  event AddedAsset(bytes32 symbol, address asset);

  /// @notice Event emmited after asset is deauthorized
  /// @param symbol Hash-symbol of asset
  /// @param asset Address of asset
  event DeletedAsset(bytes32 symbol, address asset);

  /// @notice Ecent emitted after timestamp delay is being changed
  /// @param time New delay in seconds
  event TimestampDelayChanged(uint256 time);

  /// @notice Initialize fallback
  /// @param _feed Price feed address
  constructor(IPriceFeed _feed) {
    feed = _feed;
  }

  /// @notice Authorize new asset
  /// @param _asset Address of not authorized asset
  /// @param _symbol Hash of symbol of asset
  function addAsset(address _asset, bytes32 _symbol) external onlyOwner {
    require(
      addressToSymbol[_asset] == bytes32(0),
      "Asset is already authorized"
    );
    addressToSymbol[_asset] = _symbol;
    emit AddedAsset(_symbol, _asset);
  }

  /// @notice Deauthorize asset
  /// @param _asset Address of authorized asset
  function deleteAsset(address _asset) external onlyOwner {
    bytes32 symbol = addressToSymbol[_asset];
    if (symbol != bytes32(0)) {
      addressToSymbol[_asset] = bytes32(0);
      emit DeletedAsset(symbol, _asset);
      return;
    }
    revert TokenNotAuthorized(symbol);
  }

  /// @notice Set new feed
  /// @param _feed address of new feed
  /// @dev Feed must be compatible with IPriceFeed interface
  function resetPriceFeed(address _feed) external onlyOwner {
    require(_feed != address(0), "Null address provided");
    address previous = address(feed);
    feed = IPriceFeed(_feed);
    emit ResetPriceFeed(previous, _feed);
  }

  /// @notice Set new timestamp delay
  /// @param _seconds New timestamp in seconds
  function changeTimestampDelay(uint256 _seconds) external onlyOwner {
    timestampDelay = _seconds;
    emit TimestampDelayChanged(timestampDelay);
  }

  /// @notice Get current price of asset (in CELO)
  /// @param _asset Address of asset
  function getAssetPrice(address _asset) public view returns (uint256) {
    bytes32 symbol = addressToSymbol[_asset];
    if (symbol != bytes32(0)) {
      uint last = feed.lastPriceUpdate(symbol);
      require(last>0, "The price has never been set");
      if (block.timestamp < timestampDelay + last) {
        return (feed.getPrice(symbol) * 1e18) / feed.getPrice(CELO);
      }
      revert OldPriceData(symbol);
    }
    revert TokenNotAuthorized(symbol);
  }

  /// @notice Get current price of several assets (in CELO)
  /// @param _assets Addresses of assets
  function getAssetPriceExt(address[] memory _assets)
    external
    view
    returns (uint256[] memory)
  {
    uint256[] memory prices = new uint256[](_assets.length);
    for (uint256 i; i < _assets.length; i++) {
      prices[i] = getAssetPrice(_assets[i]);
    }
    return prices;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

interface IPriceFeed {
  function getPrice(bytes32 symbol) external view returns (uint256);

  function lastPriceUpdate(bytes32 symbol) external view returns (uint256);
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