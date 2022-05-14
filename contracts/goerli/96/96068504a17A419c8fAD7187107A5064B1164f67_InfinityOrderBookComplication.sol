// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OrderTypes} from '../libs/OrderTypes.sol';
import {IComplication} from '../interfaces/IComplication.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

// import 'hardhat/console.sol'; // todo: remove this

/**
 * @title InfinityOrderBookComplication
 * @notice Complication to execute orderbook orders
 */
contract InfinityOrderBookComplication is IComplication, Ownable {
  using OrderTypes for OrderTypes.Order;
  using OrderTypes for OrderTypes.OrderItem;

  uint256 public immutable PROTOCOL_FEE;
  uint256 public ERROR_BOUND; // error bound for prices in wei; todo: check if this is reqd

  event NewErrorbound(uint256 errorBound);

  /**
   * @notice Constructor
   * @param _protocolFee protocol fee (200 --> 2%, 400 --> 4%)
   * @param _errorBound price error bound in wei
   */
  constructor(uint256 _protocolFee, uint256 _errorBound) {
    PROTOCOL_FEE = _protocolFee;
    ERROR_BOUND = _errorBound;
  }

  function canExecOrder(
    OrderTypes.Order calldata sell,
    OrderTypes.Order calldata buy,
    OrderTypes.Order calldata constructed
  ) external view returns (bool, uint256) {
    // console.log('running canExecOrder in InfinityOrderBookComplication');
    bool isTimeValid = _isTimeValid(sell, buy);
    (bool isAmountValid, uint256 execPrice) = _isAmountValid(sell, buy, constructed);
    bool numItemsValid = _areNumItemsValid(sell, buy, constructed);
    bool itemsIntersect = _checkItemsIntersect(sell, constructed) && _checkItemsIntersect(buy, constructed);
    // console.log('isTimeValid', isTimeValid);
    // console.log('isAmountValid', isAmountValid);
    // console.log('numItemsValid', numItemsValid);
    // console.log('itemsIntersect', itemsIntersect);
    return (isTimeValid && isAmountValid && numItemsValid && itemsIntersect, execPrice);
  }

  function canExecTakeOrder(OrderTypes.Order calldata makerOrder, OrderTypes.Order calldata takerOrder)
    external
    view
    returns (bool, uint256)
  {
    // console.log('running canExecTakeOrder in InfinityOrderBookComplication');
    // check timestamps
    (uint256 startTime, uint256 endTime) = (makerOrder.constraints[3], makerOrder.constraints[4]);
    bool isTimeValid = startTime <= block.timestamp && endTime >= block.timestamp;

    (uint256 currentMakerPrice, uint256 currentTakerPrice) = (
      _getCurrentPrice(makerOrder),
      _getCurrentPrice(takerOrder)
    );
    bool isAmountValid = _arePricesWithinErrorBound(currentMakerPrice, currentTakerPrice);
    bool numItemsValid = _areTakerNumItemsValid(makerOrder, takerOrder);
    bool itemsIntersect = _checkItemsIntersect(makerOrder, takerOrder);
    // console.log('isTimeValid', isTimeValid);
    // console.log('isAmountValid', isAmountValid);
    // console.log('numItemsValid', numItemsValid);
    // console.log('itemsIntersect', itemsIntersect);

    return (isTimeValid && isAmountValid && numItemsValid && itemsIntersect, currentTakerPrice);
  }

  /**
   * @notice Return protocol fee for this complication
   * @return protocol fee
   */
  function getProtocolFee() external view override returns (uint256) {
    return PROTOCOL_FEE;
  }

  function setErrorBound(uint256 _errorBound) external onlyOwner {
    ERROR_BOUND = _errorBound;
    emit NewErrorbound(_errorBound);
  }

  // ============================================== INTERNAL FUNCTIONS ===================================================

  function _isTimeValid(OrderTypes.Order calldata sell, OrderTypes.Order calldata buy) internal view returns (bool) {
    (uint256 sellStartTime, uint256 sellEndTime) = (sell.constraints[3], sell.constraints[4]);
    (uint256 buyStartTime, uint256 buyEndTime) = (buy.constraints[3], buy.constraints[4]);
    bool isSellTimeValid = sellStartTime <= block.timestamp && sellEndTime >= block.timestamp;
    bool isBuyTimeValid = buyStartTime <= block.timestamp && buyEndTime >= block.timestamp;
    // console.log('isSellTimeValid', isSellTimeValid);
    // console.log('isBuyTimeValid', isBuyTimeValid);
    return isSellTimeValid && isBuyTimeValid;
  }

  // todo: make this function public
  function _isAmountValid(
    OrderTypes.Order calldata sell,
    OrderTypes.Order calldata buy,
    OrderTypes.Order calldata constructed
  ) internal view returns (bool, uint256) {
    (uint256 currentSellPrice, uint256 currentBuyPrice, uint256 currentConstructedPrice) = (
      _getCurrentPrice(sell),
      _getCurrentPrice(buy),
      _getCurrentPrice(constructed)
    );
    return (
      currentBuyPrice >= currentSellPrice && currentConstructedPrice <= currentSellPrice,
      currentConstructedPrice
    );
  }

  function _areNumItemsValid(
    OrderTypes.Order calldata sell,
    OrderTypes.Order calldata buy,
    OrderTypes.Order calldata constructed
  ) internal pure returns (bool) {
    bool numItemsWithinBounds = constructed.constraints[0] >= buy.constraints[0] &&
      buy.constraints[0] <= sell.constraints[0];

    uint256 numConstructedItems = 0;
    for (uint256 i = 0; i < constructed.nfts.length; ) {
      unchecked {
        numConstructedItems += constructed.nfts[i].tokens.length;
        ++i;
      }
    }
    bool numConstructedItemsMatch = constructed.constraints[0] == numConstructedItems;
    // console.log('numItemsWithinBounds', numItemsWithinBounds);
    // console.log('numConstructedItemsMatch', numConstructedItemsMatch);
    return numItemsWithinBounds && numConstructedItemsMatch;
  }

  function _areTakerNumItemsValid(OrderTypes.Order calldata makerOrder, OrderTypes.Order calldata takerOrder)
    internal
    pure
    returns (bool)
  {
    bool numItemsEqual = makerOrder.constraints[0] == takerOrder.constraints[0];

    uint256 numTakerItems = 0;
    for (uint256 i = 0; i < takerOrder.nfts.length; ) {
      unchecked {
        numTakerItems += takerOrder.nfts[i].tokens.length;
        ++i;
      }
    }
    bool numTakerItemsMatch = takerOrder.constraints[0] == numTakerItems;
    // console.log('numItemsEqual', numItemsEqual);
    // console.log('numTakerItemsMatch', numTakerItemsMatch);
    return numItemsEqual && numTakerItemsMatch;
  }

  function _getCurrentPrice(OrderTypes.Order calldata order) internal view returns (uint256) {
    (uint256 startPrice, uint256 endPrice) = (order.constraints[1], order.constraints[2]);
    // console.log('startPrice', startPrice, 'endPrice', endPrice);
    (uint256 startTime, uint256 endTime) = (order.constraints[3], order.constraints[4]);
    // console.log('startTime', startTime, 'endTime', endTime);
    // console.log('block.timestamp', block.timestamp);
    uint256 duration = endTime - startTime;
    // console.log('duration', duration);
    uint256 priceDiff;
    if (startPrice > endPrice) {
      priceDiff = startPrice - endPrice;
    } else {
      priceDiff = endPrice - startPrice;
    }
    if (priceDiff == 0 || duration == 0) {
      return startPrice;
    }
    uint256 elapsedTime = block.timestamp - startTime;
    // console.log('elapsedTime', elapsedTime);
    uint256 PRECISION = 10**4; // precision for division; similar to bps
    uint256 portionBps = elapsedTime > duration ? 1 : ((elapsedTime * PRECISION) / duration);
    // console.log('portion', portionBps);
    priceDiff = (priceDiff * portionBps) / PRECISION;
    // console.log('priceDiff', priceDiff);
    uint256 currentPrice;
    if (startPrice > endPrice) {
      currentPrice = startPrice - priceDiff;
    } else {
      currentPrice = startPrice + priceDiff;
    }
    // console.log('current price', currentPrice);
    return currentPrice;
  }

  function _arePricesWithinErrorBound(uint256 price1, uint256 price2) internal view returns (bool) {
    // console.log('price1', price1, 'price2', price2);
    // console.log('ERROR_BOUND', ERROR_BOUND);
    if (price1 == price2) {
      return true;
    } else if (price1 > price2 && price1 - price2 <= ERROR_BOUND) {
      return true;
    } else if (price2 > price1 && price2 - price1 <= ERROR_BOUND) {
      return true;
    } else {
      return false;
    }
  }

  function _checkItemsIntersect(OrderTypes.Order calldata makerOrder, OrderTypes.Order calldata takerOrder)
    internal
    pure
    returns (bool)
  {
    // case where maker/taker didn't specify any items
    if (makerOrder.nfts.length == 0 || takerOrder.nfts.length == 0) {
      return true;
    }

    uint256 numCollsMatched = 0;
    // check if taker has all items in maker
    for (uint256 i = 0; i < takerOrder.nfts.length; ) {
      for (uint256 j = 0; j < makerOrder.nfts.length; ) {
        if (makerOrder.nfts[j].collection == takerOrder.nfts[i].collection) {
          // increment numCollsMatched
          unchecked {
            ++numCollsMatched;
          }
          // check if tokenIds intersect
          bool tokenIdsIntersect = _checkTokenIdsIntersect(makerOrder.nfts[j], takerOrder.nfts[i]);
          require(tokenIdsIntersect, 'taker cant have more tokenIds per coll than maker');
          // short circuit
          break;
        }
        unchecked {
          ++j;
        }
      }
      unchecked {
        ++i;
      }
    }
    // console.log('collections intersect', numCollsMatched == takerOrder.nfts.length);
    return numCollsMatched == takerOrder.nfts.length;
  }

  function _checkTokenIdsIntersect(OrderTypes.OrderItem calldata makerItem, OrderTypes.OrderItem calldata takerItem)
    internal
    pure
    returns (bool)
  {
    // case where maker/taker didn't specify any tokenIds for this collection
    if (makerItem.tokens.length == 0 || takerItem.tokens.length == 0) {
      return true;
    }
    uint256 numTokenIdsPerCollMatched = 0;
    for (uint256 k = 0; k < takerItem.tokens.length; ) {
      for (uint256 l = 0; l < makerItem.tokens.length; ) {
        if (
          makerItem.tokens[l].tokenId == takerItem.tokens[k].tokenId &&
          makerItem.tokens[l].numTokens == takerItem.tokens[k].numTokens
        ) {
          // increment numTokenIdsPerCollMatched
          unchecked {
            ++numTokenIdsPerCollMatched;
          }
          break;
        }
        unchecked {
          ++l;
        }
      }
      unchecked {
        ++k;
      }
    }
    // console.log('token ids per collection intersect', numTokenIdsPerCollMatched == takerItem.tokens.length);
    return numTokenIdsPerCollMatched == takerItem.tokens.length;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title OrderTypes
 */
library OrderTypes {
  struct TokenInfo {
    uint256 tokenId;
    uint256 numTokens;
  }

  struct OrderItem {
    address collection;
    TokenInfo[] tokens;
  }

  struct Order {
    // is order sell or buy
    bool isSellOrder;
    address signer;
    // total length: 7
    // in order:
    // numItems - min/max number of items in the order
    // start and end prices in wei
    // start and end times in block.timestamp
    // minBpsToSeller
    // nonce
    uint256[] constraints;
    // collections and tokenIds
    OrderItem[] nfts;
    // address of complication for trade execution (e.g. OrderBook), address of the currency (e.g., WETH)
    address[] execParams;
    // additional parameters like rarities, private sale buyer etc
    bytes extraParams;
    // uint8 v: parameter (27 or 28), bytes32 r, bytes32 s
    bytes sig;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OrderTypes} from '../libs/OrderTypes.sol';

interface IComplication {
  function canExecOrder(
    OrderTypes.Order calldata sell,
    OrderTypes.Order calldata buy,
    OrderTypes.Order calldata constructed
  ) external view returns (bool, uint256);

  function canExecTakeOrder(OrderTypes.Order calldata makerOrder, OrderTypes.Order calldata takerOrder)
    external
    view
    returns (bool, uint256);

  function getProtocolFee() external view returns (uint256);
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