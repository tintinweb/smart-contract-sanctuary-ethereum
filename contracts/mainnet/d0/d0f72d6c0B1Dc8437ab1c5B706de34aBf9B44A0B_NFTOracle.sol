// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

import {INFTOracle} from '../interfaces/INFTOracle.sol';
import {Ownable} from '../dependencies/openzeppelin/contracts/Ownable.sol';
import {Pausable} from '../dependencies/openzeppelin/contracts/Pausable.sol';

/**
 * @title NFTOracle
 * @author Vinci
 **/
contract NFTOracle is INFTOracle, Ownable, Pausable {

  // asset address
  mapping (address => uint256) private _addressIndexes;
  mapping (address => bool) private _emergencyAdmin;
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
  uint256 public constant MAX_PRICE_DEVIATION = 15 * 1e16;  // 15%
  uint32 public constant MIN_UPDATE_TIME = 30 * 60; // 30 min

  event SetAssetData(uint32[7] prices);
  event ChangeOperator(address indexed oldOperator, address indexed newOperator);
  event SetEmergencyAdmin(address indexed admin, bool enabled);

  /// @notice Constructor
  /// @param assets The addresses of the assets
  constructor(address[] memory assets) {
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

  function isEmergencyAdmin(address admin) external view returns (bool) {
    return _emergencyAdmin[admin];
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

  function setPause(bool val) external {
    require(_emergencyAdmin[_msgSender()], "NFTOracle: caller is not the emergencyAdmin");
    if (val) {
      _pause();
    } else {
      _unpause();
    }
  }

  function setOperator(address newOperator) external onlyOwner {
    require(newOperator != address(0), 'NFTOracle: invalid operator');
    address oldOperator = _operator;
    _operator = newOperator;
    emit ChangeOperator(oldOperator, newOperator);
  }

  function setEmergencyAdmin(address admin, bool enabled) external onlyOwner {
    require(admin != address(0), 'NFTOracle: invalid admin');
    _emergencyAdmin[admin] = enabled;
    emit SetEmergencyAdmin(admin, enabled);
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
    } else {
      return 0;
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
    uint256 currentPrice
  ) private pure returns (uint256) {

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

    if (percentDeviation > MAX_PRICE_DEVIATION) {
      return latestPrice;
    }
    return currentPrice;
  }

  // set with 1e4
  function batchSetAssetPrice(uint256[7] memory prices) external whenNotPaused {
    require(_operator == _msgSender(), "NFTOracle: caller is not the operator");
    Price storage cachePrice = _price;
    uint32 currentTimestamp = uint32(block.timestamp);
    if ((currentTimestamp - cachePrice.ts) >= MIN_UPDATE_TIME) {
      uint32[7] memory newPrices = [
        uint32(getNewPrice(cachePrice.v1, prices[0])),
        uint32(getNewPrice(cachePrice.v2, prices[1])),
        uint32(getNewPrice(cachePrice.v3, prices[2])),
        uint32(getNewPrice(cachePrice.v4, prices[3])),
        uint32(getNewPrice(cachePrice.v5, prices[4])),
        uint32(getNewPrice(cachePrice.v6, prices[5])),
        uint32(getNewPrice(cachePrice.v7, prices[6]))
      ];

      cachePrice.v1 = newPrices[0];
      cachePrice.v2 = newPrices[1];
      cachePrice.v3 = newPrices[2];
      cachePrice.v4 = newPrices[3];
      cachePrice.v5 = newPrices[4];
      cachePrice.v6 = newPrices[5];
      cachePrice.v7 = newPrices[6];
      cachePrice.ts = currentTimestamp;

      emit SetAssetData(newPrices);
    }
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
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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