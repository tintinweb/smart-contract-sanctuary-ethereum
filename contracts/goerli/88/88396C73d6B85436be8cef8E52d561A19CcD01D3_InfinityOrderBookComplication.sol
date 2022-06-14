// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

import {OrderTypes} from '../libs/OrderTypes.sol';
import {IComplication} from '../interfaces/IComplication.sol';

/**
 * @title InfinityOrderBookComplication
 * @author nneverlander. Twitter @nneverlander
 * @notice Complication to execute orderbook orders
 */
contract InfinityOrderBookComplication is IComplication, Ownable {
  // ======================================================= EXTERNAL FUNCTIONS ==================================================

  /**
   * @notice Checks whether one to one matches can be executed
   * @dev This function is called by the main exchange to check whether one to one matches can be executed.
          It checks whether orders have the right constraints - i.e they have one NFT only, whether time is still valid,
          prices are valid and whether the nfts intersect
   * @param makerOrder1 first makerOrder
   * @param makerOrder2 second makerOrder
   * @return returns whether the order can be executed and the execution price
   */
  function canExecMatchOneToOne(OrderTypes.MakerOrder calldata makerOrder1, OrderTypes.MakerOrder calldata makerOrder2)
    external
    view
    override
    returns (bool, uint256)
  {
    bool numItemsValid = makerOrder2.constraints[0] == makerOrder1.constraints[0] &&
      makerOrder2.constraints[0] == 1 &&
      makerOrder2.nfts.length == 1 &&
      makerOrder2.nfts[0].tokens.length == 1 &&
      makerOrder1.nfts.length == 1 &&
      makerOrder1.nfts[0].tokens.length == 1;
    bool _isTimeValid = makerOrder2.constraints[3] <= block.timestamp &&
      makerOrder2.constraints[4] >= block.timestamp &&
      makerOrder1.constraints[3] <= block.timestamp &&
      makerOrder1.constraints[4] >= block.timestamp;
    bool _isPriceValid = false;
    uint256 makerOrder1Price = _getCurrentPrice(makerOrder1);
    uint256 makerOrder2Price = _getCurrentPrice(makerOrder2);
    uint256 execPrice;
    if (makerOrder1.isSellOrder) {
      _isPriceValid = makerOrder2Price >= makerOrder1Price;
      execPrice = makerOrder1Price;
    } else {
      _isPriceValid = makerOrder1Price >= makerOrder2Price;
      execPrice = makerOrder2Price;
    }
    return (
      numItemsValid && _isTimeValid && doItemsIntersect(makerOrder1.nfts, makerOrder2.nfts) && _isPriceValid,
      execPrice
    );
  }

  /**
   * @notice Checks whether one to matches matches can be executed
   * @dev This function is called by the main exchange to check whether one to many matches can be executed.
          It checks whether orders have the right constraints - i.e they have the right number of items, whether time is still valid,
          prices are valid and whether the nfts intersect
   * @param makerOrder the one makerOrder
   * @param manyMakerOrders many maker orders
   * @return returns whether the order can be executed
   */
  function canExecMatchOneToMany(
    OrderTypes.MakerOrder calldata makerOrder,
    OrderTypes.MakerOrder[] calldata manyMakerOrders
  ) external view override returns (bool) {
    uint256 numItems;
    bool isOrdersTimeValid = true;
    bool itemsIntersect = true;
    uint256 ordersLength = manyMakerOrders.length;
    for (uint256 i = 0; i < ordersLength; ) {
      if (!isOrdersTimeValid || !itemsIntersect) {
        return false; // short circuit
      }

      uint256 nftsLength = manyMakerOrders[i].nfts.length;
      for (uint256 j = 0; j < nftsLength; ) {
        numItems += manyMakerOrders[i].nfts[j].tokens.length;
        unchecked {
          ++j;
        }
      }

      isOrdersTimeValid =
        isOrdersTimeValid &&
        manyMakerOrders[i].constraints[3] <= block.timestamp &&
        manyMakerOrders[i].constraints[4] >= block.timestamp;

      itemsIntersect = itemsIntersect && doItemsIntersect(makerOrder.nfts, manyMakerOrders[i].nfts);

      unchecked {
        ++i;
      }
    }

    bool _isTimeValid = isOrdersTimeValid &&
      makerOrder.constraints[3] <= block.timestamp &&
      makerOrder.constraints[4] >= block.timestamp;

    uint256 currentMakerOrderPrice = _getCurrentPrice(makerOrder);
    uint256 sumCurrentOrderPrices = _sumCurrentPrices(manyMakerOrders);

    bool _isPriceValid = false;
    if (makerOrder.isSellOrder) {
      _isPriceValid = sumCurrentOrderPrices >= currentMakerOrderPrice;
    } else {
      _isPriceValid = sumCurrentOrderPrices <= currentMakerOrderPrice;
    }

    return (numItems == makerOrder.constraints[0]) && _isTimeValid && itemsIntersect && _isPriceValid;
  }

  /**
   * @notice Checks whether match orders with a higher order intent can be executed
   * @dev This function is called by the main exchange to check whether one to one matches can be executed.
          It checks whether orders have the right constraints - i.e they have the right number of items, whether time is still valid,
          prices are valid and whether the nfts intersect
   * @param sell sell order
   * @param buy buy order
   * @param constructedNfts - nfts constructed by the off chain matching engine
   * @return returns whether the order can be executed and the execution price
   */
  function canExecMatchOrder(
    OrderTypes.MakerOrder calldata sell,
    OrderTypes.MakerOrder calldata buy,
    OrderTypes.OrderItem[] calldata constructedNfts
  ) external view override returns (bool, uint256) {
    (bool _isPriceValid, uint256 execPrice) = isPriceValid(sell, buy);
    return (
      isTimeValid(sell, buy) &&
        _isPriceValid &&
        areNumItemsValid(sell, buy, constructedNfts) &&
        doItemsIntersect(sell.nfts, constructedNfts) &&
        doItemsIntersect(buy.nfts, constructedNfts) &&
        doItemsIntersect(sell.nfts, buy.nfts),
      execPrice
    );
  }

  /**
   * @notice Checks whether take orders with a higher order intent can be executed
   * @dev This function is called by the main exchange to check whether take orders with a higher order intent can be executed.
          It checks whether orders have the right constraints - i.e they have the right number of items, whether time is still valid
          and whether the nfts intersect
   * @param makerOrder the maker order
   * @param takerItems the taker items specified by the taker
   * @return returns whether order can be executed
   */
  function canExecTakeOrder(OrderTypes.MakerOrder calldata makerOrder, OrderTypes.OrderItem[] calldata takerItems)
    external
    view
    override
    returns (bool)
  {
    return (makerOrder.constraints[3] <= block.timestamp &&
      makerOrder.constraints[4] >= block.timestamp &&
      areTakerNumItemsValid(makerOrder, takerItems) &&
      doItemsIntersect(makerOrder.nfts, takerItems));
  }

  // ======================================================= PUBLIC FUNCTIONS ==================================================

  /// @dev checks whether the orders are active and not expired
  function isTimeValid(OrderTypes.MakerOrder calldata sell, OrderTypes.MakerOrder calldata buy)
    public
    view
    returns (bool)
  {
    return
      sell.constraints[3] <= block.timestamp &&
      sell.constraints[4] >= block.timestamp &&
      buy.constraints[3] <= block.timestamp &&
      buy.constraints[4] >= block.timestamp;
  }

  /// @dev checks whether the price is valid; a buy order should always have a higher price than a sell order
  function isPriceValid(OrderTypes.MakerOrder calldata sell, OrderTypes.MakerOrder calldata buy)
    public
    view
    returns (bool, uint256)
  {
    (uint256 currentSellPrice, uint256 currentBuyPrice) = (_getCurrentPrice(sell), _getCurrentPrice(buy));
    return (currentBuyPrice >= currentSellPrice, currentSellPrice);
  }

  /// @dev sanity check to make sure the constructed nfts conform to the user signed constraints
  function areNumItemsValid(
    OrderTypes.MakerOrder calldata sell,
    OrderTypes.MakerOrder calldata buy,
    OrderTypes.OrderItem[] calldata constructedNfts
  ) public pure returns (bool) {
    uint256 numConstructedItems = 0;
    uint256 nftsLength = constructedNfts.length;
    for (uint256 i = 0; i < nftsLength; ) {
      unchecked {
        numConstructedItems += constructedNfts[i].tokens.length;
        ++i;
      }
    }
    return numConstructedItems >= buy.constraints[0] && buy.constraints[0] <= sell.constraints[0];
  }

  /// @dev sanity check to make sure that a taker is specifying the right number of items
  function areTakerNumItemsValid(OrderTypes.MakerOrder calldata makerOrder, OrderTypes.OrderItem[] calldata takerItems)
    public
    pure
    returns (bool)
  {
    uint256 numTakerItems = 0;
    uint256 nftsLength = takerItems.length;
    for (uint256 i = 0; i < nftsLength; ) {
      unchecked {
        numTakerItems += takerItems[i].tokens.length;
        ++i;
      }
    }
    return makerOrder.constraints[0] == numTakerItems;
  }

  /**
   * @notice Checks whether nfts intersect
   * @dev This function checks whether there are intersecting nfts between two orders
   * @param order1Nfts nfts in the first order
   * @param order2Nfts nfts in the second order
   * @return returns whether items intersect
   */
  function doItemsIntersect(OrderTypes.OrderItem[] calldata order1Nfts, OrderTypes.OrderItem[] calldata order2Nfts)
    public
    pure
    returns (bool)
  {
    uint256 order1NftsLength = order1Nfts.length;
    uint256 order2NftsLength = order2Nfts.length;
    // case where maker/taker didn't specify any items
    if (order1NftsLength == 0 || order2NftsLength == 0) {
      return true;
    }

    uint256 numCollsMatched = 0;
    // check if taker has all items in maker
    for (uint256 i = 0; i < order2NftsLength; ) {
      for (uint256 j = 0; j < order1NftsLength; ) {
        if (order1Nfts[j].collection == order2Nfts[i].collection) {
          // increment numCollsMatched
          unchecked {
            ++numCollsMatched;
          }
          // check if tokenIds intersect
          bool tokenIdsIntersect = doTokenIdsIntersect(order1Nfts[j], order2Nfts[i]);
          require(tokenIdsIntersect, 'tokenIds dont intersect');
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

    return numCollsMatched == order2NftsLength;
  }

  /**
   * @notice Checks whether tokenIds intersect
   * @dev This function checks whether there are intersecting tokenIds between two order items
   * @param item1 first item
   * @param item2 second item
   * @return returns whether tokenIds intersect
   */
  function doTokenIdsIntersect(OrderTypes.OrderItem calldata item1, OrderTypes.OrderItem calldata item2)
    public
    pure
    returns (bool)
  {
    uint256 item1TokensLength = item1.tokens.length;
    uint256 item2TokensLength = item2.tokens.length;
    // case where maker/taker didn't specify any tokenIds for this collection
    if (item1TokensLength == 0 || item2TokensLength == 0) {
      return true;
    }
    uint256 numTokenIdsPerCollMatched = 0;
    for (uint256 k = 0; k < item2TokensLength; ) {
      for (uint256 l = 0; l < item1TokensLength; ) {
        if (
          item1.tokens[l].tokenId == item2.tokens[k].tokenId && item1.tokens[l].numTokens == item2.tokens[k].numTokens
        ) {
          // increment numTokenIdsPerCollMatched
          unchecked {
            ++numTokenIdsPerCollMatched;
          }
          // short circuit
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

    return numTokenIdsPerCollMatched == item2TokensLength;
  }

  // ======================================================= UTILS ============================================================

  /// @dev returns the sum of current order prices; used in match one to many orders
  function _sumCurrentPrices(OrderTypes.MakerOrder[] calldata orders) internal view returns (uint256) {
    uint256 sum = 0;
    uint256 ordersLength = orders.length;
    for (uint256 i = 0; i < ordersLength; ) {
      sum += _getCurrentPrice(orders[i]);
      unchecked {
        ++i;
      }
    }
    return sum;
  }

  /// @dev Gets current order price for orders that vary in price over time (dutch and reverse dutch auctions)
  function _getCurrentPrice(OrderTypes.MakerOrder calldata order) internal view returns (uint256) {
    (uint256 startPrice, uint256 endPrice) = (order.constraints[1], order.constraints[2]);
    uint256 duration = order.constraints[4] - order.constraints[3];
    uint256 priceDiff = startPrice > endPrice ? startPrice - endPrice : endPrice - startPrice;
    if (priceDiff == 0 || duration == 0) {
      return startPrice;
    }
    uint256 elapsedTime = block.timestamp - order.constraints[3];
    uint256 PRECISION = 10**4; // precision for division; similar to bps
    uint256 portionBps = elapsedTime > duration ? PRECISION : ((elapsedTime * PRECISION) / duration);
    priceDiff = (priceDiff * portionBps) / PRECISION;
    return startPrice > endPrice ? startPrice - priceDiff : startPrice + priceDiff;
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
pragma solidity 0.8.14;

/**
 * @title OrderTypes
 * @author nneverlander. Twitter @nneverlander
 * @notice This library contains the order types used by the main exchange and complications
 */
library OrderTypes {
  /// @dev the tokenId and numTokens (=1 for ERC721 and >=1 for ERC1155)
  struct TokenInfo {
    uint256 tokenId;
    uint256 numTokens;
  }

  /// @dev an order item is a collection address and tokens from that collection
  struct OrderItem {
    address collection;
    TokenInfo[] tokens;
  }

  struct MakerOrder {
    ///@dev is order sell or buy
    bool isSellOrder;
    ///@dev signer of the order (maker address)
    address signer;
    ///@dev Constraints array contains the order constraints. Total constraints: 6. In order:
    // numItems - min (for buy orders) / max (for sell orders) number of items in the order
    // start price in wei
    // end price in wei
    // start time in block.timestamp
    // end time in block.timestamp
    // nonce of the order
    uint256[] constraints;
    ///@dev nfts array contains order items where each item is a collection and its tokenIds
    OrderItem[] nfts;
    ///@dev address of complication for trade execution (e.g. InfinityOrderBookComplication), address of the currency (e.g., WETH)
    address[] execParams;
    ///@dev additional parameters like traits for trait orders, private sale buyer for OTC ordes etc
    bytes extraParams;
    ///@dev the order signature uint8 v: parameter (27 or 28), bytes32 r, bytes32 s
    bytes sig;
  }

  /// @dev taker order struct are simply a subset of maker order since they don't need the signature and constraints
  struct TakerOrder {
    bool isSellOrder;
    OrderItem[] nfts;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {OrderTypes} from '../libs/OrderTypes.sol';

/**
 * @title IComplication
 * @author nneverlander. Twitter @nneverlander
 * @notice Complication interface that must be implemented by all complications (execution strategies)
 */
interface IComplication {

  function canExecMatchOrder(
    OrderTypes.MakerOrder calldata sell,
    OrderTypes.MakerOrder calldata buy,
    OrderTypes.OrderItem[] calldata constructedNfts
  ) external view returns (bool, uint256);

  function canExecMatchOneToMany(
    OrderTypes.MakerOrder calldata makerOrder,
    OrderTypes.MakerOrder[] calldata manyMakerOrders
  ) external view returns (bool);

  function canExecMatchOneToOne(OrderTypes.MakerOrder calldata makerOrder1, OrderTypes.MakerOrder calldata makerOrder2)
    external
    view
    returns (bool, uint256);

  function canExecTakeOrder(OrderTypes.MakerOrder calldata makerOrder, OrderTypes.OrderItem[] calldata takerItems)
    external
    view
    returns (bool);
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