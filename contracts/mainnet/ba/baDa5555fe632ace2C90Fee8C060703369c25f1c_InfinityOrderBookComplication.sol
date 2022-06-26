// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

// external imports
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

// internal imports
import {SignatureChecker} from '../libs/SignatureChecker.sol';
import {OrderTypes} from '../libs/OrderTypes.sol';
import {IComplication} from '../interfaces/IComplication.sol';

/**
 * @title InfinityOrderBookComplication
 * @author nneverlander. Twitter @nneverlander
 * @notice Complication to execute orderbook orders
 */
contract InfinityOrderBookComplication is IComplication, Ownable {
  using EnumerableSet for EnumerableSet.AddressSet;
  uint256 public constant PRECISION = 1e4; // precision for division; similar to bps

  /// @dev WETH address of the chain being used
  address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  // keccak256('Order(bool isSellOrder,address signer,uint256[] constraints,OrderItem[] nfts,address[] execParams,bytes extraParams)OrderItem(address collection,TokenInfo[] tokens)TokenInfo(uint256 tokenId,uint256 numTokens)')
  bytes32 public constant ORDER_HASH = 0x7bcfb5a29031e6b8d34ca1a14dd0a1f5cb11b20f755bb2a31ee3c4b143477e4a;

  // keccak256('OrderItem(address collection,TokenInfo[] tokens)TokenInfo(uint256 tokenId,uint256 numTokens)')
  bytes32 public constant ORDER_ITEM_HASH = 0xf73f37e9f570369ceaab59cef16249ae1c0ad1afd592d656afac0be6f63b87e0;

  // keccak256('TokenInfo(uint256 tokenId,uint256 numTokens)')
  bytes32 public constant TOKEN_INFO_HASH = 0x88f0bd19d14f8b5d22c0605a15d9fffc285ebc8c86fb21139456d305982906f1;

  /// @dev Used in order signing with EIP-712
  bytes32 public immutable DOMAIN_SEPARATOR;

  /// @dev Storage variable that keeps track of valid currencies used for payment (tokens)
  EnumerableSet.AddressSet private _currencies;

  event CurrencyAdded(address currency);
  event CurrencyRemoved(address currency);

  constructor() {
    // Calculate the domain separator
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
        keccak256('InfinityComplication'),
        keccak256(bytes('1')), // for versionId = 1
        block.chainid,
        address(this)
      )
    );

    // add default currencies
    _currencies.add(WETH);
    _currencies.add(address(0)); // ETH
  }

  // ======================================================= EXTERNAL FUNCTIONS ==================================================

  /**
   * @notice Checks whether one to one matches can be executed
   * @dev This function is called by the main exchange to check whether one to one matches can be executed.
          It checks whether orders have the right constraints - i.e they have one specific NFT only, whether time is still valid,
          prices are valid and whether the nfts intersect.
   * @param makerOrder1 first makerOrder
   * @param makerOrder2 second makerOrder
   * @return returns whether the order can be executed, orderHashes and the execution price
   */
  function canExecMatchOneToOne(OrderTypes.MakerOrder calldata makerOrder1, OrderTypes.MakerOrder calldata makerOrder2)
    external
    view
    override
    returns (
      bool,
      bytes32,
      bytes32,
      uint256
    )
  {
    // check if the orders are valid
    bytes32 sellOrderHash = _hash(makerOrder1);
    bytes32 buyOrderHash = _hash(makerOrder2);
    require(verifyMatchOneToOneOrders(sellOrderHash, buyOrderHash, makerOrder1, makerOrder2), 'order not verified');

    // check constraints
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

    bool _isPriceValid;
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
      sellOrderHash,
      buyOrderHash,
      execPrice
    );
  }

  /**
   * @notice Checks whether one to many matches can be executed
   * @dev This function is called by the main exchange to check whether one to many matches can be executed.
          It checks whether orders have the right constraints - i.e they have the right number of items, whether time is still valid,
          prices are valid and whether the nfts intersect. All orders are expected to contain specific items.
   * @param makerOrder the one makerOrder
   * @param manyMakerOrders many maker orders
   * @return returns whether the order can be executed and orderHash of the one side order
   */
  function canExecMatchOneToMany(
    OrderTypes.MakerOrder calldata makerOrder,
    OrderTypes.MakerOrder[] calldata manyMakerOrders
  ) external view override returns (bool, bytes32) {
    // check if makerOrder is valid
    bytes32 makerOrderHash = _hash(makerOrder);
    require(isOrderValid(makerOrder, makerOrderHash), 'invalid maker order');

    // check the constraints of the 'one' maker order
    uint256 numNftsInOneOrder;
    for (uint256 i; i < makerOrder.nfts.length; ) {
      numNftsInOneOrder = numNftsInOneOrder + makerOrder.nfts[i].tokens.length;
      unchecked {
        ++i;
      }
    }

    // check the constraints of many maker orders
    uint256 totalNftsInManyOrders;
    bool numNftsPerManyOrderValid = true;
    bool isOrdersTimeValid = true;
    bool itemsIntersect = true;
    for (uint256 i; i < manyMakerOrders.length; ) {
      uint256 nftsLength = manyMakerOrders[i].nfts.length;
      uint256 numNftsPerOrder;
      for (uint256 j; j < nftsLength; ) {
        numNftsPerOrder = numNftsPerOrder + manyMakerOrders[i].nfts[j].tokens.length;
        unchecked {
          ++j;
        }
      }
      numNftsPerManyOrderValid = numNftsPerManyOrderValid && manyMakerOrders[i].constraints[0] == numNftsPerOrder;
      totalNftsInManyOrders = totalNftsInManyOrders + numNftsPerOrder;

      isOrdersTimeValid =
        isOrdersTimeValid &&
        manyMakerOrders[i].constraints[3] <= block.timestamp &&
        manyMakerOrders[i].constraints[4] >= block.timestamp;

      itemsIntersect = itemsIntersect && doItemsIntersect(makerOrder.nfts, manyMakerOrders[i].nfts);

      if (!numNftsPerManyOrderValid) {
        return (false, makerOrderHash); // short circuit
      }

      unchecked {
        ++i;
      }
    }

    bool _isTimeValid = isOrdersTimeValid &&
      makerOrder.constraints[3] <= block.timestamp &&
      makerOrder.constraints[4] >= block.timestamp;

    uint256 currentMakerOrderPrice = _getCurrentPrice(makerOrder);
    uint256 sumCurrentOrderPrices = _sumCurrentPrices(manyMakerOrders);

    bool _isPriceValid;
    if (makerOrder.isSellOrder) {
      _isPriceValid = sumCurrentOrderPrices >= currentMakerOrderPrice;
    } else {
      _isPriceValid = sumCurrentOrderPrices <= currentMakerOrderPrice;
    }

    return (
      numNftsInOneOrder == makerOrder.constraints[0] &&
        numNftsInOneOrder == totalNftsInManyOrders &&
        _isTimeValid &&
        itemsIntersect &&
        _isPriceValid,
      makerOrderHash
    );
  }

  /**
   * @notice Checks whether match orders with a higher level intent can be executed
   * @dev This function is called by the main exchange to check whether one to one matches can be executed.
          It checks whether orders have the right constraints - i.e they have the right number of items, whether time is still valid,
          prices are valid and whether the nfts intersect
   * @param sell sell order
   * @param buy buy order
   * @param constructedNfts - nfts constructed by the off chain matching engine
   * @return returns whether the order can be execute, orderHashes and the execution price
   */
  function canExecMatchOrder(
    OrderTypes.MakerOrder calldata sell,
    OrderTypes.MakerOrder calldata buy,
    OrderTypes.OrderItem[] calldata constructedNfts
  )
    external
    view
    override
    returns (
      bool,
      bytes32,
      bytes32,
      uint256
    )
  {
    // check if orders are valid
    bytes32 sellOrderHash = _hash(sell);
    bytes32 buyOrderHash = _hash(buy);
    require(verifyMatchOrders(sellOrderHash, buyOrderHash, sell, buy), 'order not verified');

    (bool _isPriceValid, uint256 execPrice) = isPriceValid(sell, buy);

    return (
      isTimeValid(sell, buy) &&
        _isPriceValid &&
        areNumMatchItemsValid(sell, buy, constructedNfts) &&
        doItemsIntersect(sell.nfts, constructedNfts) &&
        doItemsIntersect(buy.nfts, constructedNfts),
      sellOrderHash,
      buyOrderHash,
      execPrice
    );
  }

  /**
   * @notice Checks whether one to one taker orders can be executed
   * @dev This function is called by the main exchange to check whether one to one taker orders can be executed.
          It checks whether orders have the right constraints - i.e they have one NFT only and whether time is still valid
   * @param makerOrder the makerOrder
   * @return returns whether the order can be executed and makerOrderHash
   */
  function canExecTakeOneOrder(OrderTypes.MakerOrder calldata makerOrder)
    external
    view
    override
    returns (bool, bytes32)
  {
    // check if makerOrder is valid
    bytes32 makerOrderHash = _hash(makerOrder);
    require(isOrderValid(makerOrder, makerOrderHash), 'invalid maker order');

    bool numItemsValid = makerOrder.constraints[0] == 1 &&
      makerOrder.nfts.length == 1 &&
      makerOrder.nfts[0].tokens.length == 1;
    bool _isTimeValid = makerOrder.constraints[3] <= block.timestamp && makerOrder.constraints[4] >= block.timestamp;

    return (numItemsValid && _isTimeValid, makerOrderHash);
  }

  /**
   * @notice Checks whether take orders with a higher level intent can be executed
   * @dev This function is called by the main exchange to check whether take orders with a higher level intent can be executed.
          It checks whether orders have the right constraints - i.e they have the right number of items, whether time is still valid
          and whether the nfts intersect
   * @param makerOrder the maker order
   * @param takerItems the taker items specified by the taker
   * @return returns whether order can be executed and the makerOrderHash
   */
  function canExecTakeOrder(OrderTypes.MakerOrder calldata makerOrder, OrderTypes.OrderItem[] calldata takerItems)
    external
    view
    override
    returns (bool, bytes32)
  {
    // check if makerOrder is valid
    bytes32 makerOrderHash = _hash(makerOrder);
    require(isOrderValid(makerOrder, makerOrderHash), 'invalid maker order');

    return (
      makerOrder.constraints[3] <= block.timestamp &&
        makerOrder.constraints[4] >= block.timestamp &&
        areNumTakerItemsValid(makerOrder, takerItems) &&
        doItemsIntersect(makerOrder.nfts, takerItems),
      makerOrderHash
    );
  }

  // ======================================================= PUBLIC FUNCTIONS ==================================================

  /**
   * @notice Checks whether orders are valid
   * @dev Checks whether currencies match, sides match, complications match and if each order is valid (see isOrderValid)
   * @param sellOrderHash hash of the sell order
   * @param buyOrderHash hash of the buy order
   * @param sell the sell order
   * @param buy the buy order
   * @return whether orders are valid
   */
  function verifyMatchOneToOneOrders(
    bytes32 sellOrderHash,
    bytes32 buyOrderHash,
    OrderTypes.MakerOrder calldata sell,
    OrderTypes.MakerOrder calldata buy
  ) public view returns (bool) {
    bool currenciesMatch = sell.execParams[1] == buy.execParams[1] ||
      (sell.execParams[1] == address(0) && buy.execParams[1] == WETH);

    return (sell.isSellOrder &&
      !buy.isSellOrder &&
      sell.execParams[0] == buy.execParams[0] &&
      sell.signer != buy.signer &&
      currenciesMatch &&
      isOrderValid(sell, sellOrderHash) &&
      isOrderValid(buy, buyOrderHash));
  }

  /**
   * @notice Checks whether orders are valid
   * @dev Checks whether currencies match, sides match, complications match and if each order is valid (see isOrderValid)
   * @param sell the sell order
   * @param buy the buy order
   * @return whether orders are valid and orderHash
   */
  function verifyMatchOneToManyOrders(
    bool verifySellOrder,
    OrderTypes.MakerOrder calldata sell,
    OrderTypes.MakerOrder calldata buy
  ) public view override returns (bool, bytes32) {
    bool currenciesMatch = sell.execParams[1] == buy.execParams[1] ||
      (sell.execParams[1] == address(0) && buy.execParams[1] == WETH);

    bool _orderValid;
    bytes32 orderHash;

    if (verifySellOrder) {
      orderHash = _hash(sell);
      _orderValid = isOrderValid(sell, orderHash);
    } else {
      orderHash = _hash(buy);
      _orderValid = isOrderValid(buy, orderHash);
    }
    return (
      sell.isSellOrder &&
        !buy.isSellOrder &&
        sell.execParams[0] == buy.execParams[0] &&
        sell.signer != buy.signer &&
        currenciesMatch &&
        _orderValid,
      orderHash
    );
  }

  /**
   * @notice Checks whether orders are valid
   * @dev Checks whether currencies match, sides match, complications match and if each order is valid (see isOrderValid)
          Also checks if the given complication can execute this order
   * @param sellOrderHash hash of the sell order
   * @param buyOrderHash hash of the buy order
   * @param sell the sell order
   * @param buy the buy order
   * @return whether orders are valid
   */
  function verifyMatchOrders(
    bytes32 sellOrderHash,
    bytes32 buyOrderHash,
    OrderTypes.MakerOrder calldata sell,
    OrderTypes.MakerOrder calldata buy
  ) public view returns (bool) {
    bool currenciesMatch = sell.execParams[1] == buy.execParams[1] ||
      (sell.execParams[1] == address(0) && buy.execParams[1] == WETH);

    return (sell.isSellOrder &&
      !buy.isSellOrder &&
      sell.execParams[0] == buy.execParams[0] &&
      sell.signer != buy.signer &&
      currenciesMatch &&
      isOrderValid(sell, sellOrderHash) &&
      isOrderValid(buy, buyOrderHash));
  }

  /**
   * @notice Verifies the validity of the order
   * @dev checks if signature is valid and if the complication and currency are valid
   * @param order the order
   * @param orderHash computed hash of the order
   * @return whether the order is valid
   */
  function isOrderValid(OrderTypes.MakerOrder calldata order, bytes32 orderHash) public view returns (bool) {
    // Verify the validity of the signature
    (bytes32 r, bytes32 s, uint8 v) = abi.decode(order.sig, (bytes32, bytes32, uint8));
    bool sigValid = SignatureChecker.verify(orderHash, order.signer, r, s, v, DOMAIN_SEPARATOR);
    return (sigValid && order.execParams[0] == address(this) && _currencies.contains(order.execParams[1]));
  }

  /// @dev checks whether the orders are expired
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
  function areNumMatchItemsValid(
    OrderTypes.MakerOrder calldata sell,
    OrderTypes.MakerOrder calldata buy,
    OrderTypes.OrderItem[] calldata constructedNfts
  ) public pure returns (bool) {
    uint256 numConstructedItems;
    for (uint256 i; i < constructedNfts.length; ) {
      unchecked {
        numConstructedItems = numConstructedItems + constructedNfts[i].tokens.length;
        ++i;
      }
    }
    return numConstructedItems >= buy.constraints[0] && numConstructedItems <= sell.constraints[0];
  }

  /// @dev sanity check to make sure that a taker is specifying the right number of items
  function areNumTakerItemsValid(OrderTypes.MakerOrder calldata makerOrder, OrderTypes.OrderItem[] calldata takerItems)
    public
    pure
    returns (bool)
  {
    uint256 numTakerItems;
    for (uint256 i; i < takerItems.length; ) {
      unchecked {
        numTakerItems = numTakerItems + takerItems[i].tokens.length;
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

    uint256 numCollsMatched;
    unchecked {
      for (uint256 i; i < order2NftsLength; ) {
        for (uint256 j; j < order1NftsLength; ) {
          if (order1Nfts[j].collection == order2Nfts[i].collection) {
            // increment numCollsMatched
            ++numCollsMatched;
            // check if tokenIds intersect
            bool tokenIdsIntersect = doTokenIdsIntersect(order1Nfts[j], order2Nfts[i]);
            require(tokenIdsIntersect, 'tokenIds dont intersect');
            // short circuit
            break;
          }
          ++j;
        }
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
    uint256 numTokenIdsPerCollMatched;
    unchecked {
      for (uint256 k; k < item2TokensLength; ) {
        for (uint256 l; l < item1TokensLength; ) {
          if (item1.tokens[l].tokenId == item2.tokens[k].tokenId) {
            // increment numTokenIdsPerCollMatched
            ++numTokenIdsPerCollMatched;
            // short circuit
            break;
          }
          ++l;
        }
        ++k;
      }
    }

    return numTokenIdsPerCollMatched == item2TokensLength;
  }

  // ======================================================= UTILS ============================================================

  /// @dev hashes the given order with the help of _nftsHash and _tokensHash
  function _hash(OrderTypes.MakerOrder calldata order) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encode(
          ORDER_HASH,
          order.isSellOrder,
          order.signer,
          keccak256(abi.encodePacked(order.constraints)),
          _nftsHash(order.nfts),
          keccak256(abi.encodePacked(order.execParams)),
          keccak256(order.extraParams)
        )
      );
  }

  function _nftsHash(OrderTypes.OrderItem[] calldata nfts) internal pure returns (bytes32) {
    bytes32[] memory hashes = new bytes32[](nfts.length);
    for (uint256 i; i < nfts.length; ) {
      bytes32 hash = keccak256(abi.encode(ORDER_ITEM_HASH, nfts[i].collection, _tokensHash(nfts[i].tokens)));
      hashes[i] = hash;
      unchecked {
        ++i;
      }
    }
    bytes32 nftsHash = keccak256(abi.encodePacked(hashes));
    return nftsHash;
  }

  function _tokensHash(OrderTypes.TokenInfo[] calldata tokens) internal pure returns (bytes32) {
    bytes32[] memory hashes = new bytes32[](tokens.length);
    for (uint256 i; i < tokens.length; ) {
      bytes32 hash = keccak256(abi.encode(TOKEN_INFO_HASH, tokens[i].tokenId, tokens[i].numTokens));
      hashes[i] = hash;
      unchecked {
        ++i;
      }
    }
    bytes32 tokensHash = keccak256(abi.encodePacked(hashes));
    return tokensHash;
  }

  /// @dev returns the sum of current order prices; used in match one to many orders
  function _sumCurrentPrices(OrderTypes.MakerOrder[] calldata orders) internal view returns (uint256) {
    uint256 sum;
    uint256 ordersLength = orders.length;
    for (uint256 i; i < ordersLength; ) {
      sum = sum + _getCurrentPrice(orders[i]);
      unchecked {
        ++i;
      }
    }
    return sum;
  }

  /// @dev Gets current order price for orders that vary in price over time (dutch and reverse dutch auctions)
  function _getCurrentPrice(OrderTypes.MakerOrder calldata order) internal view returns (uint256) {
    (uint256 startPrice, uint256 endPrice) = (order.constraints[1], order.constraints[2]);
    if (startPrice == endPrice) {
      return startPrice;
    }

    uint256 duration = order.constraints[4] - order.constraints[3];
    if (duration == 0) {
      return startPrice;
    }

    uint256 elapsedTime = block.timestamp - order.constraints[3];
    unchecked {
      uint256 portionBps = elapsedTime > duration ? PRECISION : ((elapsedTime * PRECISION) / duration);
      if (startPrice > endPrice) {
        uint256 priceDiff = ((startPrice - endPrice) * portionBps) / PRECISION;
        return startPrice - priceDiff;
      } else {
        uint256 priceDiff = ((endPrice - startPrice) * portionBps) / PRECISION;
        return startPrice + priceDiff;
      }
    }
  }

  // ======================================================= OWNER FUNCTIONS ============================================================

  /// @dev adds a new transaction currency to the exchange
  function addCurrency(address _currency) external onlyOwner {
    _currencies.add(_currency);
    emit CurrencyAdded(_currency);
  }

  /// @dev removes a transaction currency from the exchange
  function removeCurrency(address _currency) external onlyOwner {
    _currencies.remove(_currency);
    emit CurrencyRemoved(_currency);
  }

  // ======================================================= VIEW FUNCTIONS ============================================================

  /// @notice returns the number of currencies supported by the exchange
  function numCurrencies() external view returns (uint256) {
    return _currencies.length();
  }

  /// @notice returns the currency at the given index
  function getCurrencyAt(uint256 index) external view returns (address) {
    return _currencies.at(index);
  }

  /// @notice returns whether a given currency is valid
  function isValidCurrency(address currency) external view returns (bool) {
    return _currencies.contains(currency);
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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {Address} from '@openzeppelin/contracts/utils/Address.sol';
import {IERC1271} from '@openzeppelin/contracts/interfaces/IERC1271.sol';

/**
 * @title SignatureChecker
 * @notice This library allows verification of signatures for both EOAs and contracts
 */
library SignatureChecker {
  /**
   * @notice Recovers the signer of a signature (for EOA)
   * @param hashed hash containing the signed message
   * @param r parameter
   * @param s parameter
   * @param v parameter (27 or 28). This prevents malleability since the public key recovery equation has two possible solutions.
   */
  function recover(
    bytes32 hashed,
    bytes32 r,
    bytes32 s,
    uint8 v
  ) internal pure returns (address) {
    // https://ethereum.stackexchange.com/questions/83174/is-it-best-practice-to-check-signature-malleability-in-ecrecover
    // https://crypto.iacr.org/2019/affevents/wac/medias/Heninger-BiasedNonceSense.pdf
    require(
      uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
      'Signature: Invalid s parameter'
    );

    require(v == 27 || v == 28, 'Signature: Invalid v parameter');

    // If the signature is valid (and not malleable), return the signer address
    address signer = ecrecover(hashed, v, r, s);
    require(signer != address(0), 'Signature: Invalid signer');

    return signer;
  }

  /**
   * @notice Returns whether the signer matches the signed message
   * @param orderHash the hash containing the signed message
   * @param signer the signer address to confirm message validity
   * @param r parameter
   * @param s parameter
   * @param v parameter (27 or 28) this prevents malleability since the public key recovery equation has two possible solutions
   * @param domainSeparator parameter to prevent signature being executed in other chains and environments
   * @return true --> if valid // false --> if invalid
   */
  function verify(
    bytes32 orderHash,
    address signer,
    bytes32 r,
    bytes32 s,
    uint8 v,
    bytes32 domainSeparator
  ) internal view returns (bool) {
    // \x19\x01 is the standardized encoding prefix
    // https://eips.ethereum.org/EIPS/eip-712#specification
    bytes32 digest = keccak256(abi.encodePacked('\x19\x01', domainSeparator, orderHash));

    if (Address.isContract(signer)) {
      // 0x1626ba7e is the interfaceId for signature contracts (see IERC1271)
      return IERC1271(signer).isValidSignature(digest, abi.encodePacked(r, s, v)) == 0x1626ba7e;
    } else {
      return recover(digest, r, s, v) == signer;
    }
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
  /// @dev the tokenId and numTokens (==1 for ERC721)
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
    ///@dev Constraints array contains the order constraints. Total constraints: 7. In order:
    // numItems - min (for buy orders) / max (for sell orders) number of items in the order
    // start price in wei
    // end price in wei
    // start time in block.timestamp
    // end time in block.timestamp
    // nonce of the order
    // max tx.gasprice in wei that a user is willing to pay for gas
    uint256[] constraints;
    ///@dev nfts array contains order items where each item is a collection and its tokenIds
    OrderItem[] nfts;
    ///@dev address of complication for trade execution (e.g. InfinityOrderBookComplication), address of the currency (e.g., WETH)
    address[] execParams;
    ///@dev additional parameters like traits for trait orders, private sale buyer for OTC orders etc
    bytes extraParams;
    ///@dev the order signature uint8 v: parameter (27 or 28), bytes32 r, bytes32 s
    bytes sig;
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
  function canExecMatchOneToOne(OrderTypes.MakerOrder calldata makerOrder1, OrderTypes.MakerOrder calldata makerOrder2)
    external
    view
    returns (
      bool,
      bytes32,
      bytes32,
      uint256
    );

  function canExecMatchOneToMany(
    OrderTypes.MakerOrder calldata makerOrder,
    OrderTypes.MakerOrder[] calldata manyMakerOrders
  ) external view returns (bool, bytes32);

  function canExecMatchOrder(
    OrderTypes.MakerOrder calldata sell,
    OrderTypes.MakerOrder calldata buy,
    OrderTypes.OrderItem[] calldata constructedNfts
  )
    external
    view
    returns (
      bool,
      bytes32,
      bytes32,
      uint256
    );

  function canExecTakeOneOrder(OrderTypes.MakerOrder calldata makerOrder) external view returns (bool, bytes32);

  function canExecTakeOrder(OrderTypes.MakerOrder calldata makerOrder, OrderTypes.OrderItem[] calldata takerItems)
    external
    view
    returns (bool, bytes32);

  function verifyMatchOneToManyOrders(
    bool verifySellOrder,
    OrderTypes.MakerOrder calldata sell,
    OrderTypes.MakerOrder calldata buy
  ) external view returns (bool, bytes32);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}