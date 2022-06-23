// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

// external imports
import {ReentrancyGuard} from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {IERC165} from '@openzeppelin/contracts/interfaces/IERC165.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

// internal imports
import {OrderTypes} from '../libs/OrderTypes.sol';
import {IComplication} from '../interfaces/IComplication.sol';
import {SignatureChecker} from '../libs/SignatureChecker.sol';

/**
@title InfinityExchange
@author nneverlander. Twitter @nneverlander
@notice The main NFT exchange contract that holds state and does asset transfers
@dev This contract can be extended via 'complications' - strategies that let the exchange execute various types of orders
      like dutch auctions, reverse dutch auctions, floor price orders, private sales, etc.

NFTNFTNFT...........................................NFTNFTNFT
NFTNFT                                                 NFTNFT
NFT                                                       NFT
.                                                           .
.                                                           .
.                                                           .
.                                                           .
.               NFTNFTNFT            NFTNFTNFT              .
.            NFTNFTNFTNFTNFT      NFTNFTNFTNFTNFT           .
.           NFTNFTNFTNFTNFTNFT   NFTNFTNFTNFTNFTNFT         .
.         NFTNFTNFTNFTNFTNFTNFTNFTNFTNFTNFTNFTNFTNFT        .
.         NFTNFTNFTNFTNFTNFTNFTNFTNFTNFTNFTNFTNFTNFT        .
.         NFTNFTNFTNFTNFTNFTNFTNFTNFTNFTNFTNFTNFTNFT        .
.          NFTNFTNFTNFTNFTNFTN   NFTNFTNFTNFTNFTNFT         .
.            NFTNFTNFTNFTNFT      NFTNFTNFTNFTNFT           .
.               NFTNFTNFT            NFTNFTNFT              .
.                                                           .
.                                                           .
.                                                           .
.                                                           .
NFT                                                       NFT
NFTNFT                                                 NFTNFT
NFTNFTNFT...........................................NFTNFTNFT 

*/
contract InfinityExchange is ReentrancyGuard {
  using EnumerableSet for EnumerableSet.AddressSet;

  /// @dev WETH address of a chain; set at deploy time to the WETH address of the chain that this contract is deployed to
  address public immutable WETH;
  /// @dev Address of the Infinity Exchange admin contract
  address public immutable EXCHANGE_ADMIN;
  /// @dev Used in order signing with EIP-712
  bytes32 public immutable DOMAIN_SEPARATOR;
  /// @dev This is the address that is used to send auto sniped orders for execution on chain
  address public matchExecutor;
  /// @dev Gas cost for auto sniped orders are paid by the buyers and refunded to this contract in the form of WETH
  uint32 public wethTransferGasUnits = 5e4;
  /// @notice Exchange fee in basis points (250 bps = 2.5%)
  uint32 public protocolFeeBps = 250;

  /// @dev Used in division
  uint256 constant PRECISION = 1e4; // precision for division; similar to bps

  // keccak256('Order(bool isSellOrder,address signer,uint256[] constraints,OrderItem[] nfts,address[] execParams,bytes extraParams)OrderItem(address collection,TokenInfo[] tokens)TokenInfo(uint256 tokenId,uint256 numTokens)')
  bytes32 public constant ORDER_HASH = 0x7bcfb5a29031e6b8d34ca1a14dd0a1f5cb11b20f755bb2a31ee3c4b143477e4a;

  // keccak256('OrderItem(address collection,TokenInfo[] tokens)TokenInfo(uint256 tokenId,uint256 numTokens)')
  bytes32 public constant ORDER_ITEM_HASH = 0xf73f37e9f570369ceaab59cef16249ae1c0ad1afd592d656afac0be6f63b87e0;

  // keccak256('TokenInfo(uint256 tokenId,uint256 numTokens)')
  bytes32 public constant TOKEN_INFO_HASH = 0x88f0bd19d14f8b5d22c0605a15d9fffc285ebc8c86fb21139456d305982906f1;

  /**
   @dev All orders should have a nonce >= to this value. 
        Any orders with nonce value less than this are non-executable. 
        Used for cancelling all outstanding orders.
  */
  mapping(address => uint256) public userMinOrderNonce;

  /// @dev This records already executed or cancelled orders to prevent replay attacks.
  mapping(address => mapping(uint256 => bool)) public isUserOrderNonceExecutedOrCancelled;

  /// @dev Storage variable that keeps track of valid complications (order execution strategies)
  EnumerableSet.AddressSet private _complications;
  /// @dev Storage variable that keeps track of valid currencies (tokens)
  EnumerableSet.AddressSet private _currencies;

  event CancelAllOrders(address indexed user, uint256 newMinNonce);
  event CancelMultipleOrders(address indexed user, uint256[] orderNonces);

  event MatchOrderFulfilled(
    bytes32 sellOrderHash,
    bytes32 buyOrderHash,
    address indexed seller,
    address indexed buyer,
    address complication, // address of the complication that defines the execution
    address indexed currency, // token address of the transacting currency
    uint256 amount // amount spent on the order
  );

  event TakeOrderFulfilled(
    bytes32 orderHash,
    address indexed seller,
    address indexed buyer,
    address complication, // address of the complication that defines the execution
    address indexed currency, // token address of the transacting currency
    uint256 amount // amount spent on the order
  );

  /**
    @param _weth address of a chain; set at deploy time to the WETH address of the chain that this contract is deployed to
    @param _matchExecutor address of the match executor used by match* functions to auto execute orders 
    @param _exchangeAdmin address of the exchange admin contract
   */
  constructor(
    address _weth,
    address _matchExecutor,
    address _exchangeAdmin
  ) {
    // Calculate the domain separator
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
        keccak256('InfinityExchange'),
        keccak256(bytes('1')), // for versionId = 1
        block.chainid,
        address(this)
      )
    );
    WETH = _weth;
    matchExecutor = _matchExecutor;
    EXCHANGE_ADMIN = _exchangeAdmin;
    // add default currencies ETH and WETH
    _currencies.add(address(0));
    _currencies.add(WETH);
  }

  // =================================================== USER FUNCTIONS =======================================================

  /**
   @notice Matches orders one to one where each order has 1 NFT. Example: Match 1 specific NFT buy with one specific NFT sell.
   @dev Can execute orders in batches for gas efficiency. Can only be called by the match executor. Refunds gas cost incurred by the
        match executor to this contract. Checks whether the given complication can execute the match.
   @param makerOrders1 Maker order 1
   @param makerOrders2 Maker order 2
  */
  function matchOneToOneOrders(
    OrderTypes.MakerOrder[] calldata makerOrders1,
    OrderTypes.MakerOrder[] calldata makerOrders2
  ) external nonReentrant {
    uint256 startGas = gasleft();
    uint256 numMakerOrders = makerOrders1.length;
    require(msg.sender == matchExecutor, 'OME');
    require(numMakerOrders == makerOrders2.length, 'mismatched lengths');

    // the below 3 variables are copied locally once to save on gas
    // an SLOAD costs minimum 100 gas where an MLOAD only costs minimum 3 gas
    // since these values won't change during function execution, we can save on gas by copying them to memory once
    // instead of SLOADing once for each loop iteration
    uint32 _protocolFeeBps = protocolFeeBps;
    uint32 _wethTransferGasUnits = wethTransferGasUnits;
    address weth = WETH;
    uint256 sharedCost = (startGas - gasleft()) / numMakerOrders;
    for (uint256 i; i < numMakerOrders; ) {
      uint256 startGasPerOrder = gasleft() + sharedCost;
      (bool canExec, uint256 execPrice) = IComplication(makerOrders1[i].execParams[0]).canExecMatchOneToOne(
        makerOrders1[i],
        makerOrders2[i]
      );
      require(canExec, 'cannot execute');
      _matchOneToOneOrders(
        makerOrders1[i],
        makerOrders2[i],
        startGasPerOrder,
        execPrice,
        _protocolFeeBps,
        _wethTransferGasUnits,
        weth
      );
      unchecked {
        ++i;
      }
    }
  }

  /**
   @notice Matches one order to many orders. Example: A buy order with 5 specific NFTs with 5 sell orders with those specific NFTs.
   @dev Can only be called by the match executor. Refunds gas cost incurred by the
        match executor to this contract. Checks whether the given complication can execute the match.
   @param makerOrder The one order to match
   @param manyMakerOrders Array of multiple orders to match the one order against
  */
  function matchOneToManyOrders(
    OrderTypes.MakerOrder calldata makerOrder,
    OrderTypes.MakerOrder[] calldata manyMakerOrders
  ) external nonReentrant {
    uint256 startGas = gasleft();
    require(msg.sender == matchExecutor, 'OME');
    require(
      IComplication(makerOrder.execParams[0]).canExecMatchOneToMany(makerOrder, manyMakerOrders),
      'cannot execute'
    );
    bytes32 makerOrderHash = _hash(makerOrder);
    require(isOrderValid(makerOrder, makerOrderHash), 'invalid maker order');
    uint256 ordersLength = manyMakerOrders.length;
    // the below 3 variables are copied locally once to save on gas
    // an SLOAD costs minimum 100 gas where an MLOAD only costs minimum 3 gas
    // since these values won't change during function execution, we can save on gas by copying them to memory once
    // instead of SLOADing once for each loop iteration
    uint32 _protocolFeeBps = protocolFeeBps;
    uint32 _wethTransferGasUnits = wethTransferGasUnits;
    address weth = WETH;
    if (makerOrder.isSellOrder) {
      // 20000 for the SSTORE op that updates maker nonce status from zero to a non zero status
      uint256 sharedCost = (startGas + 20000 - gasleft()) / ordersLength;
      for (uint256 i; i < ordersLength; ) {
        uint256 startGasPerOrder = gasleft() + sharedCost;
        _matchOneMakerSellToManyMakerBuys(
          makerOrderHash,
          makerOrder,
          manyMakerOrders[i],
          startGasPerOrder,
          _protocolFeeBps,
          _wethTransferGasUnits,
          weth
        );
        unchecked {
          ++i;
        }
      }
      isUserOrderNonceExecutedOrCancelled[makerOrder.signer][makerOrder.constraints[5]] = true;
    } else {
      uint256 protocolFee;
      for (uint256 i; i < ordersLength; ) {
        protocolFee =
          protocolFee +
          _matchOneMakerBuyToManyMakerSells(makerOrderHash, manyMakerOrders[i], makerOrder, _protocolFeeBps);
        unchecked {
          ++i;
        }
      }
      isUserOrderNonceExecutedOrCancelled[makerOrder.signer][makerOrder.constraints[5]] = true;
      uint256 gasCost = (startGas - gasleft() + _wethTransferGasUnits) * tx.gasprice;
      // if the execution currency is weth, we can send the protocol fee and gas cost in one transfer to save gas
      // else we need to send the protocol fee separately in the execution currency
      // since the buyer is common across many sell orders, this part can be executed outside the above for loop
      // in contrast to the case where if the one order is a sell order, we need to do this in each for loop
      if (makerOrder.execParams[1] == weth) {
        IERC20(weth).transferFrom(makerOrder.signer, address(this), protocolFee + gasCost);
      } else {
        IERC20(makerOrder.execParams[1]).transferFrom(makerOrder.signer, address(this), protocolFee);
        IERC20(weth).transferFrom(makerOrder.signer, address(this), gasCost);
      }
    }
  }

  /**
   @notice Matches orders one to one where no specific NFTs are specified. 
          Example: A collection wide buy order with any 2 NFTs with a sell order that has any 2 NFTs from that collection.
   @dev Can only be called by the match executor. Refunds gas cost incurred by the
        match executor to this contract. Checks whether the given complication can execute the match.
        The constructs param specifies the actual NFTs that will be executed since buys and sells need not specify actual NFTs - only 
        a higher level intent.
   @param sells User signed sell orders
   @param buys User signed buy orders
   @param constructs Intersection of the NFTs in the sells and buys. Constructed by an off chain matching engine.
  */
  function matchOrders(
    OrderTypes.MakerOrder[] calldata sells,
    OrderTypes.MakerOrder[] calldata buys,
    OrderTypes.OrderItem[][] calldata constructs
  ) external nonReentrant {
    uint256 startGas = gasleft();
    uint256 numSells = sells.length;
    require(msg.sender == matchExecutor, 'OME');
    require(numSells == buys.length, 'mismatched lengths');
    require(numSells == constructs.length, 'mismatched lengths');
    // the below 3 variables are copied locally once to save on gas
    // an SLOAD costs minimum 100 gas where an MLOAD only costs minimum 3 gas
    // since these values won't change during function execution, we can save on gas by copying them to memory once
    // instead of SLOADing once for each loop iteration
    uint32 _protocolFeeBps = protocolFeeBps;
    uint32 _wethTransferGasUnits = wethTransferGasUnits;
    address weth = WETH;
    uint256 sharedCost = (startGas - gasleft()) / numSells;
    for (uint256 i; i < numSells; ) {
      uint256 startGasPerOrder = gasleft() + sharedCost;
      (bool executionValid, uint256 execPrice) = IComplication(sells[i].execParams[0]).canExecMatchOrder(
        sells[i],
        buys[i],
        constructs[i]
      );
      require(executionValid, 'cannot execute');
      _matchOrders(
        sells[i],
        buys[i],
        constructs[i],
        startGasPerOrder,
        execPrice,
        _protocolFeeBps,
        _wethTransferGasUnits,
        weth
      );
      unchecked {
        ++i;
      }
    }
  }

  /**
   @notice Batch buys or sells orders with specific `1` NFTs. Transaction initiated by an end user.
   @param makerOrders The orders to fulfill
  */
  function takeMultipleOneOrders(OrderTypes.MakerOrder[] calldata makerOrders) external payable nonReentrant {
    uint256 totalPrice;
    address currency = makerOrders[0].execParams[1];
    if (currency != address(0)) {
      require(msg.value == 0, 'msg has value');
    }
    bool isMakerSeller = makerOrders[0].isSellOrder;
    if (!isMakerSeller) {
      require(currency != address(0), 'offers only in ERC20');
    }
    for (uint256 i; i < makerOrders.length; ) {
      bytes32 makerOrderHash = _hash(makerOrders[i]);
      require(isOrderValid(makerOrders[i], makerOrderHash), 'invalid maker order');
      require(IComplication(makerOrders[i].execParams[0]).canExecTakeOneOrder(makerOrders[i]), 'cannot execute');
      require(currency == makerOrders[i].execParams[1], 'cannot mix currencies');
      require(isMakerSeller == makerOrders[i].isSellOrder, 'cannot mix order sides');
      require(msg.sender != makerOrders[i].signer, 'no dogfooding');
      uint256 execPrice = _getCurrentPrice(makerOrders[i]);
      totalPrice = totalPrice + execPrice;
      _execTakeOneOrder(makerOrderHash, makerOrders[i], isMakerSeller, execPrice);
      unchecked {
        ++i;
      }
    }
    // check to ensure that for ETH orders, enough ETH is sent
    // for non ETH orders, IERC20 transferFrom will throw error if insufficient amount is sent
    if (isMakerSeller && currency == address(0)) {
      require(msg.value >= totalPrice, 'invalid total price');
      if (msg.value > totalPrice) {
        (bool sent, ) = msg.sender.call{value: msg.value - totalPrice}('');
        require(sent, 'failed');
      }
    }
  }

  /**
   @notice Batch buys or sells orders where maker orders can have unspecified NFTs. Transaction initiated by an end user.
   @param makerOrders The orders to fulfill
   @param takerNfts The specific NFTs that the taker is willing to take that intersect with the higher order intent of the maker
   Example: If a makerOrder is 'buy any one of these 2 specific NFTs', then the takerNfts would be 'this one specific NFT'.
  */
  function takeOrders(OrderTypes.MakerOrder[] calldata makerOrders, OrderTypes.OrderItem[][] calldata takerNfts)
    external
    payable
    nonReentrant
  {
    require(makerOrders.length == takerNfts.length, 'mismatched lengths');
    uint256 totalPrice;
    address currency = makerOrders[0].execParams[1];
    if (currency != address(0)) {
      require(msg.value == 0, 'msg has value');
    }
    bool isMakerSeller = makerOrders[0].isSellOrder;
    if (!isMakerSeller) {
      require(currency != address(0), 'offers only in ERC20');
    }
    for (uint256 i; i < makerOrders.length; ) {
      require(currency == makerOrders[i].execParams[1], 'cannot mix currencies');
      require(isMakerSeller == makerOrders[i].isSellOrder, 'cannot mix order sides');
      require(msg.sender != makerOrders[i].signer, 'no dogfooding');
      uint256 execPrice = _getCurrentPrice(makerOrders[i]);
      totalPrice = totalPrice + execPrice;
      _takeOrders(makerOrders[i], takerNfts[i], execPrice);
      unchecked {
        ++i;
      }
    }
    // check to ensure that for ETH orders, enough ETH is sent
    // for non ETH orders, IERC20 transferFrom will throw error if insufficient amount is sent
    if (isMakerSeller && currency == address(0)) {
      require(msg.value >= totalPrice, 'invalid total price');
      if (msg.value > totalPrice) {
        (bool sent, ) = msg.sender.call{value: msg.value - totalPrice}('');
        require(sent, 'failed');
      }
    }
  }

  /**
   @notice Helper function (non exchange related) to send multiple NFTs in one go
   @param to The orders to fulfill
   @param items The specific NFTs to transfer
  */
  function transferMultipleNFTs(address to, OrderTypes.OrderItem[] calldata items) external nonReentrant {
    require(to != address(0), 'invalid address');
    _transferMultipleNFTs(msg.sender, to, items);
  }

  /**
   * @notice Cancel all pending orders
   * @param minNonce minimum user nonce
   */
  function cancelAllOrders(uint256 minNonce) external {
    require(minNonce > userMinOrderNonce[msg.sender], 'nonce too low');
    require(minNonce < userMinOrderNonce[msg.sender] + 1e6, 'too many');
    userMinOrderNonce[msg.sender] = minNonce;
    emit CancelAllOrders(msg.sender, minNonce);
  }

  /**
   * @notice Cancel multiple orders
   * @param orderNonces array of order nonces
   */
  function cancelMultipleOrders(uint256[] calldata orderNonces) external {
    require(orderNonces.length != 0, 'cannot be empty');
    for (uint256 i; i < orderNonces.length; ) {
      require(orderNonces[i] >= userMinOrderNonce[msg.sender], 'nonce too low');
      require(!isUserOrderNonceExecutedOrCancelled[msg.sender][orderNonces[i]], 'nonce already exec or cancelled');
      isUserOrderNonceExecutedOrCancelled[msg.sender][orderNonces[i]] = true;
      unchecked {
        ++i;
      }
    }
    emit CancelMultipleOrders(msg.sender, orderNonces);
  }

  /// @dev used for withdrawing exchange fees paid to the contract in tokens
  function withdrawTokens(address currency, uint256 amount) external {
    IERC20(currency).transfer(EXCHANGE_ADMIN, amount);
  }

  receive() external payable {}

  /// @dev used for withdrawing exchange fees paid to the contract in ETH
  function withdrawETH() external {
    (bool sent, ) = EXCHANGE_ADMIN.call{value: address(this).balance}('');
    require(sent, 'failed');
  }

  // ====================================================== VIEW FUNCTIONS ======================================================

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
   * @param orderHash hash of the order
   * @param sell the sell order
   * @param buy the buy order
   * @return whether orders are valid
   */
  function verifyMatchOneToManyOrders(
    bytes32 orderHash,
    bool verifySellOrder,
    OrderTypes.MakerOrder calldata sell,
    OrderTypes.MakerOrder calldata buy
  ) public view returns (bool) {
    bool currenciesMatch = sell.execParams[1] == buy.execParams[1] ||
      (sell.execParams[1] == address(0) && buy.execParams[1] == WETH);
    bool _orderValid;
    if (verifySellOrder) {
      _orderValid = isOrderValid(sell, orderHash);
    } else {
      _orderValid = isOrderValid(buy, orderHash);
    }
    return (sell.isSellOrder &&
      !buy.isSellOrder &&
      sell.execParams[0] == buy.execParams[0] &&
      sell.signer != buy.signer &&
      currenciesMatch &&
      _orderValid);
  }

  /**
   * @notice Checks whether orders are valid
   * @dev Checks whether currencies match, sides match, complications match and if each order is valid (see isOrderValid)
          Also checks if the given complication can execute this order
   * @param sellOrderHash hash of the sell order
   * @param buyOrderHash hash of the buy order
   * @param sell the sell order
   * @param buy the buy order
   * @return whether orders are valid and the execution price
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
   * @dev checks whether order nonce was cancelled or already executed, 
          if signature is valid and if the complication and currency are valid
   * @param order the order
   * @param orderHash computed hash of the order
   */
  function isOrderValid(OrderTypes.MakerOrder calldata order, bytes32 orderHash) public view returns (bool) {
    bool orderExpired = isUserOrderNonceExecutedOrCancelled[order.signer][order.constraints[5]] ||
      order.constraints[5] < userMinOrderNonce[order.signer];
    // Verify the validity of the signature
    (bytes32 r, bytes32 s, uint8 v) = abi.decode(order.sig, (bytes32, bytes32, uint8));
    bool sigValid = SignatureChecker.verify(orderHash, order.signer, r, s, v, DOMAIN_SEPARATOR);
    return (!orderExpired &&
      sigValid &&
      _complications.contains(order.execParams[0]) &&
      _currencies.contains(order.execParams[1]));
  }

  /// @notice returns the number of complications supported by the exchange
  function numComplications() external view returns (uint256) {
    return _complications.length();
  }

  /// @notice returns the complication at the given index
  function getComplicationAt(uint256 index) external view returns (address) {
    return _complications.at(index);
  }

  /// @notice returns whether a given complication is valid
  function isValidComplication(address complication) external view returns (bool) {
    return _complications.contains(complication);
  }

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

  // ====================================================== INTERNAL FUNCTIONS ================================================

  /**
   * @notice Internal helper function to match orders one to one
   * @param makerOrder1 first order
   * @param makerOrder2 second maker order
   * @param startGasPerOrder start gas when this order started execution
   * @param execPrice execution price
   * @param _protocolFeeBps exchange fee
   * @param _wethTransferGasUnits gas units that a WETH transfer will use
   * @param weth WETH address
   */
  function _matchOneToOneOrders(
    OrderTypes.MakerOrder calldata makerOrder1,
    OrderTypes.MakerOrder calldata makerOrder2,
    uint256 startGasPerOrder,
    uint256 execPrice,
    uint32 _protocolFeeBps,
    uint32 _wethTransferGasUnits,
    address weth
  ) internal {
    OrderTypes.MakerOrder calldata sell;
    OrderTypes.MakerOrder calldata buy;
    if (makerOrder1.isSellOrder) {
      sell = makerOrder1;
      buy = makerOrder2;
    } else {
      sell = makerOrder2;
      buy = makerOrder1;
    }
    bytes32 sellOrderHash = _hash(sell);
    bytes32 buyOrderHash = _hash(buy);
    require(verifyMatchOneToOneOrders(sellOrderHash, buyOrderHash, sell, buy), 'order not verified');
    _execMatchOneToOneOrders(
      sellOrderHash,
      buyOrderHash,
      sell,
      buy,
      startGasPerOrder,
      execPrice,
      _protocolFeeBps,
      _wethTransferGasUnits,
      weth
    );
  }

  /**
   * @notice Internal helper function to match one maker sell order to many maker buys
   * @param sellOrderHash sell order hash
   * @param sell the sell order
   * @param buy the buy order
   * @param startGasPerOrder start gas when this order started execution
   * @param _protocolFeeBps exchange fee
   * @param _wethTransferGasUnits gas units that a WETH transfer will use
   * @param weth WETH address
   */
  function _matchOneMakerSellToManyMakerBuys(
    bytes32 sellOrderHash,
    OrderTypes.MakerOrder calldata sell,
    OrderTypes.MakerOrder calldata buy,
    uint256 startGasPerOrder,
    uint32 _protocolFeeBps,
    uint32 _wethTransferGasUnits,
    address weth
  ) internal {
    bytes32 buyOrderHash = _hash(buy);
    require(verifyMatchOneToManyOrders(buyOrderHash, false, sell, buy), 'order not verified');
    _execMatchOneMakerSellToManyMakerBuys(
      sellOrderHash,
      buyOrderHash,
      sell,
      buy,
      startGasPerOrder,
      _getCurrentPrice(buy),
      _protocolFeeBps,
      _wethTransferGasUnits,
      weth
    );
  }

  /**
   * @notice Internal helper function to match one maker buy order to many maker sells
   * @param buyOrderHash buy order hash
   * @param sell the sell order
   * @param buy the buy order
   * @param _protocolFeeBps exchange fee
   */
  function _matchOneMakerBuyToManyMakerSells(
    bytes32 buyOrderHash,
    OrderTypes.MakerOrder calldata sell,
    OrderTypes.MakerOrder calldata buy,
    uint32 _protocolFeeBps
  ) internal returns (uint256) {
    bytes32 sellOrderHash = _hash(sell);
    require(verifyMatchOneToManyOrders(sellOrderHash, true, sell, buy), 'order not verified');
    return
      _execMatchOneMakerBuyToManyMakerSells(
        sellOrderHash,
        buyOrderHash,
        sell,
        buy,
        _getCurrentPrice(sell),
        _protocolFeeBps
      );
  }

  /**
   * @notice Internal helper function to match orders specified via a higher order intent
   * @param sell the sell order
   * @param buy the buy order
   * @param constructedNfts the nfts constructed by an off chain matching that are guaranteed to intersect
            with the user specified signed intents (orders)
   * @param startGasPerOrder start gas when this order started execution
   * @param _protocolFeeBps exchange fee
   * @param _wethTransferGasUnits gas units that a WETH transfer will use
   * @param weth WETH address
   */
  function _matchOrders(
    OrderTypes.MakerOrder calldata sell,
    OrderTypes.MakerOrder calldata buy,
    OrderTypes.OrderItem[] calldata constructedNfts,
    uint256 startGasPerOrder,
    uint256 execPrice,
    uint32 _protocolFeeBps,
    uint32 _wethTransferGasUnits,
    address weth
  ) internal {
    bytes32 sellOrderHash = _hash(sell);
    bytes32 buyOrderHash = _hash(buy);
    require(verifyMatchOrders(sellOrderHash, buyOrderHash, sell, buy), 'order not verified');
    _execMatchOrders(
      sellOrderHash,
      buyOrderHash,
      sell,
      buy,
      constructedNfts,
      startGasPerOrder,
      execPrice,
      _protocolFeeBps,
      _wethTransferGasUnits,
      weth
    );
  }

  /**
   * @notice Internal helper function that executes contract state changes and does asset transfers for match one to one orders
   * @dev Updates order nonce states, does asset transfers and emits events. Also refunds gas expenditure to the contract
   * @param sellOrderHash sell order hash
   * @param buyOrderHash buy order hash
   * @param sell the sell order
   * @param buy the buy order
   * @param startGasPerOrder start gas when this order started execution
   * @param execPrice execution price
   * @param _protocolFeeBps exchange fee
   * @param _wethTransferGasUnits gas units that a WETH transfer will use
   * @param weth WETH address
   */
  function _execMatchOneToOneOrders(
    bytes32 sellOrderHash,
    bytes32 buyOrderHash,
    OrderTypes.MakerOrder calldata sell,
    OrderTypes.MakerOrder calldata buy,
    uint256 startGasPerOrder,
    uint256 execPrice,
    uint32 _protocolFeeBps,
    uint32 _wethTransferGasUnits,
    address weth
  ) internal {
    isUserOrderNonceExecutedOrCancelled[sell.signer][sell.constraints[5]] = true;
    isUserOrderNonceExecutedOrCancelled[buy.signer][buy.constraints[5]] = true;
    uint256 protocolFee = (_protocolFeeBps * execPrice) / PRECISION;
    uint256 remainingAmount = execPrice - protocolFee;
    _transferMultipleNFTs(sell.signer, buy.signer, sell.nfts);
    // transfer final amount (post-fees) to seller
    IERC20(buy.execParams[1]).transferFrom(buy.signer, sell.signer, remainingAmount);
    _emitMatchEvent(
      sellOrderHash,
      buyOrderHash,
      sell.signer,
      buy.signer,
      buy.execParams[0],
      buy.execParams[1],
      execPrice
    );
    uint256 gasCost = (startGasPerOrder - gasleft() + _wethTransferGasUnits) * tx.gasprice;
    // if the execution currency is weth, we can send the protocol fee and gas cost in one transfer to save gas
    // else we need to send the protocol fee separately in the execution currency
    if (buy.execParams[1] == weth) {
      IERC20(weth).transferFrom(buy.signer, address(this), protocolFee + gasCost);
    } else {
      IERC20(buy.execParams[1]).transferFrom(buy.signer, address(this), protocolFee);
      IERC20(weth).transferFrom(buy.signer, address(this), gasCost);
    }
  }

  /**
   * @notice Internal helper function that executes contract state changes and does asset transfers for match one sell to many buy orders
   * @dev Updates order nonce states, does asset transfers and emits events. Also refunds gas expenditure to the contract
   * @param sellOrderHash sell order hash
   * @param buyOrderHash buy order hash
   * @param sell the sell order
   * @param buy the buy order
   * @param startGasPerOrder start gas when this order started execution
   * @param execPrice execution price
   * @param _protocolFeeBps exchange fee
   * @param _wethTransferGasUnits gas units that a WETH transfer will use
   * @param weth WETH address
   */
  function _execMatchOneMakerSellToManyMakerBuys(
    bytes32 sellOrderHash,
    bytes32 buyOrderHash,
    OrderTypes.MakerOrder calldata sell,
    OrderTypes.MakerOrder calldata buy,
    uint256 startGasPerOrder,
    uint256 execPrice,
    uint32 _protocolFeeBps,
    uint32 _wethTransferGasUnits,
    address weth
  ) internal {
    isUserOrderNonceExecutedOrCancelled[buy.signer][buy.constraints[5]] = true;
    uint256 protocolFee = (_protocolFeeBps * execPrice) / PRECISION;
    uint256 remainingAmount = execPrice - protocolFee;
    _execMatchOneToManyOrders(sell.signer, buy.signer, buy.nfts, buy.execParams[1], remainingAmount);
    _emitMatchEvent(
      sellOrderHash,
      buyOrderHash,
      sell.signer,
      buy.signer,
      buy.execParams[0],
      buy.execParams[1],
      execPrice
    );
    uint256 gasCost = (startGasPerOrder - gasleft() + _wethTransferGasUnits) * tx.gasprice;
    // if the execution currency is weth, we can send the protocol fee and gas cost in one transfer to save gas
    // else we need to send the protocol fee separately in the execution currency
    if (buy.execParams[1] == weth) {
      IERC20(weth).transferFrom(buy.signer, address(this), protocolFee + gasCost);
    } else {
      IERC20(buy.execParams[1]).transferFrom(buy.signer, address(this), protocolFee);
      IERC20(weth).transferFrom(buy.signer, address(this), gasCost);
    }
  }

  /**
   * @notice Internal helper function that executes contract state changes and does asset transfers for match one buy to many sell orders
   * @dev Updates order nonce states, does asset transfers and emits events. Gas expenditure refund is done in the caller
          since it does not need to be done in a loop
   * @param sellOrderHash sell order hash
   * @param buyOrderHash buy order hash
   * @param sell the sell order
   * @param buy the buy order
   * @param execPrice execution price
   * @param _protocolFeeBps exchange fee
   * @return the protocolFee so that the buyer can pay the protocol fee and gas cost in one go
   */
  function _execMatchOneMakerBuyToManyMakerSells(
    bytes32 sellOrderHash,
    bytes32 buyOrderHash,
    OrderTypes.MakerOrder calldata sell,
    OrderTypes.MakerOrder calldata buy,
    uint256 execPrice,
    uint32 _protocolFeeBps
  ) internal returns (uint256) {
    isUserOrderNonceExecutedOrCancelled[sell.signer][sell.constraints[5]] = true;
    uint256 protocolFee = (_protocolFeeBps * execPrice) / PRECISION;
    uint256 remainingAmount = execPrice - protocolFee;
    _execMatchOneToManyOrders(sell.signer, buy.signer, sell.nfts, buy.execParams[1], remainingAmount);
    _emitMatchEvent(
      sellOrderHash,
      buyOrderHash,
      sell.signer,
      buy.signer,
      buy.execParams[0],
      buy.execParams[1],
      execPrice
    );
    return protocolFee;
  }

  /// @dev this helper purely exists to help reduce contract size a bit and avoid any stack too deep errors
  function _execMatchOneToManyOrders(
    address seller,
    address buyer,
    OrderTypes.OrderItem[] calldata constructedNfts,
    address currency,
    uint256 amount
  ) internal {
    _transferMultipleNFTs(seller, buyer, constructedNfts);
    // transfer final amount (post-fees) to seller
    IERC20(currency).transferFrom(buyer, seller, amount);
  }

  /**
   * @notice Internal helper function that executes contract state changes and does asset transfers for match orders
   * @dev Updates order nonce states, does asset transfers, emits events and does gas refunds
   * @param sellOrderHash sell order hash
   * @param buyOrderHash buy order hash
   * @param sell the sell order
   * @param buy the buy order
   * @param constructedNfts the constructed nfts
   * @param startGasPerOrder gas when this order started execution
   * @param execPrice execution price
   * @param _protocolFeeBps exchange fee
   * @param _wethTransferGasUnits gas units that a WETH transfer will use
   * @param weth WETH address
   */
  function _execMatchOrders(
    bytes32 sellOrderHash,
    bytes32 buyOrderHash,
    OrderTypes.MakerOrder calldata sell,
    OrderTypes.MakerOrder calldata buy,
    OrderTypes.OrderItem[] calldata constructedNfts,
    uint256 startGasPerOrder,
    uint256 execPrice,
    uint32 _protocolFeeBps,
    uint32 _wethTransferGasUnits,
    address weth
  ) internal {
    uint256 protocolFee = (_protocolFeeBps * execPrice) / PRECISION;
    uint256 remainingAmount = execPrice - protocolFee;
    _execMatchOrder(
      sell.signer,
      buy.signer,
      sell.constraints[5],
      buy.constraints[5],
      constructedNfts,
      buy.execParams[1],
      remainingAmount
    );
    _emitMatchEvent(
      sellOrderHash,
      buyOrderHash,
      sell.signer,
      buy.signer,
      buy.execParams[0],
      buy.execParams[1],
      execPrice
    );
    uint256 gasCost = (startGasPerOrder - gasleft() + _wethTransferGasUnits) * tx.gasprice;
    // if the execution currency is weth, we can send the protocol fee and gas cost in one transfer to save gas
    // else we need to send the protocol fee separately in the execution currency
    if (buy.execParams[1] == weth) {
      IERC20(weth).transferFrom(buy.signer, address(this), protocolFee + gasCost);
    } else {
      IERC20(buy.execParams[1]).transferFrom(buy.signer, address(this), protocolFee);
      IERC20(weth).transferFrom(buy.signer, address(this), gasCost);
    }
  }

  /// @dev this helper purely exists to help reduce contract size a bit and avoid any stack too deep errors
  function _execMatchOrder(
    address seller,
    address buyer,
    uint256 sellNonce,
    uint256 buyNonce,
    OrderTypes.OrderItem[] calldata constructedNfts,
    address currency,
    uint256 amount
  ) internal {
    // Update order execution status to true (prevents replay)
    isUserOrderNonceExecutedOrCancelled[seller][sellNonce] = true;
    isUserOrderNonceExecutedOrCancelled[buyer][buyNonce] = true;
    _transferMultipleNFTs(seller, buyer, constructedNfts);
    // transfer final amount (post-fees) to seller
    IERC20(currency).transferFrom(buyer, seller, amount);
  }

  function _emitMatchEvent(
    bytes32 sellOrderHash,
    bytes32 buyOrderHash,
    address seller,
    address buyer,
    address complication,
    address currency,
    uint256 amount
  ) internal {
    emit MatchOrderFulfilled(sellOrderHash, buyOrderHash, seller, buyer, complication, currency, amount);
  }

  /**
   * @notice Internal helper function to take orders
   * @dev verifies whether order can be executed
   * @param makerOrder the maker order
   * @param takerItems nfts to be transferred
   * @param execPrice execution price
   */
  function _takeOrders(
    OrderTypes.MakerOrder calldata makerOrder,
    OrderTypes.OrderItem[] calldata takerItems,
    uint256 execPrice
  ) internal {
    bytes32 makerOrderHash = _hash(makerOrder);
    bool makerOrderValid = isOrderValid(makerOrder, makerOrderHash);
    bool executionValid = IComplication(makerOrder.execParams[0]).canExecTakeOrder(makerOrder, takerItems);
    require(makerOrderValid, 'order not verified');
    require(executionValid, 'cannot execute');
    _execTakeOrders(makerOrderHash, makerOrder, takerItems, makerOrder.isSellOrder, execPrice);
  }

  /**
   * @notice Internal helper function that executes contract state changes and does asset transfers 
              for take orders specifying a higher order intent
   * @dev Updates order nonce state, does asset transfers and emits events
   * @param makerOrderHash maker order hash
   * @param makerOrder the maker order
   * @param takerItems nfts to be transferred
   * @param isMakerSeller is the maker order a sell order
   * @param execPrice execution price
   */
  function _execTakeOrders(
    bytes32 makerOrderHash,
    OrderTypes.MakerOrder calldata makerOrder,
    OrderTypes.OrderItem[] calldata takerItems,
    bool isMakerSeller,
    uint256 execPrice
  ) internal {
    isUserOrderNonceExecutedOrCancelled[makerOrder.signer][makerOrder.constraints[5]] = true;
    if (isMakerSeller) {
      _transferNFTsAndFees(makerOrder.signer, msg.sender, takerItems, execPrice, makerOrder.execParams[1]);
      _emitTakerEvent(makerOrderHash, makerOrder.signer, msg.sender, makerOrder, execPrice);
    } else {
      _transferNFTsAndFees(msg.sender, makerOrder.signer, takerItems, execPrice, makerOrder.execParams[1]);
      _emitTakerEvent(makerOrderHash, msg.sender, makerOrder.signer, makerOrder, execPrice);
    }
  }

  /**
   * @notice Internal helper function that executes contract state changes and does asset transfers 
              for simple take orders
   * @dev Updates order nonce state, does asset transfers and emits events
   * @param makerOrderHash maker order hash
   * @param makerOrder the maker order
   * @param isMakerSeller is the maker order a sell order
   * @param execPrice execution price
   */
  function _execTakeOneOrder(
    bytes32 makerOrderHash,
    OrderTypes.MakerOrder calldata makerOrder,
    bool isMakerSeller,
    uint256 execPrice
  ) internal {
    isUserOrderNonceExecutedOrCancelled[makerOrder.signer][makerOrder.constraints[5]] = true;
    if (isMakerSeller) {
      _transferNFTsAndFees(makerOrder.signer, msg.sender, makerOrder.nfts, execPrice, makerOrder.execParams[1]);
      _emitTakerEvent(makerOrderHash, makerOrder.signer, msg.sender, makerOrder, execPrice);
    } else {
      _transferNFTsAndFees(msg.sender, makerOrder.signer, makerOrder.nfts, execPrice, makerOrder.execParams[1]);
      _emitTakerEvent(makerOrderHash, msg.sender, makerOrder.signer, makerOrder, execPrice);
    }
  }

  function _emitTakerEvent(
    bytes32 orderHash,
    address seller,
    address buyer,
    OrderTypes.MakerOrder calldata order,
    uint256 amount
  ) internal {
    emit TakeOrderFulfilled(orderHash, seller, buyer, order.execParams[0], order.execParams[1], amount);
  }

  /**
   * @notice Transfers NFTs and fees
   * @param seller the seller
   * @param buyer the buyer
   * @param nfts nfts to transfer
   * @param amount amount to transfer
   * @param currency currency of the transfer
   */
  function _transferNFTsAndFees(
    address seller,
    address buyer,
    OrderTypes.OrderItem[] calldata nfts,
    uint256 amount,
    address currency
  ) internal {
    // transfer NFTs
    _transferMultipleNFTs(seller, buyer, nfts);
    // transfer fees
    _transferFees(seller, buyer, amount, currency);
  }

  /**
   * @notice Transfers multiple NFTs in a loop
   * @param from the from address
   * @param to the to address
   * @param nfts nfts to transfer
   */
  function _transferMultipleNFTs(
    address from,
    address to,
    OrderTypes.OrderItem[] calldata nfts
  ) internal {
    for (uint256 i; i < nfts.length; ) {
      _transferNFTs(from, to, nfts[i]);
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @notice Transfer NFTs
   * @dev Only supports ERC721, no ERC1155 or NFTs that conform to both ERC721 and ERC1155
   * @param from address of the sender
   * @param to address of the recipient
   * @param item item to transfer
   */
  function _transferNFTs(
    address from,
    address to,
    OrderTypes.OrderItem calldata item
  ) internal {
    require(
      IERC165(item.collection).supportsInterface(0x80ac58cd) && !IERC165(item.collection).supportsInterface(0xd9b67a26),
      'only erc721'
    );
    _transferERC721s(from, to, item);
  }

  /**
   * @notice Transfer ERC721s
   * @param from address of the sender
   * @param to address of the recipient
   * @param item item to transfer
   */
  function _transferERC721s(
    address from,
    address to,
    OrderTypes.OrderItem calldata item
  ) internal {
    for (uint256 i; i < item.tokens.length; ) {
      IERC721(item.collection).transferFrom(from, to, item.tokens[i].tokenId);
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @notice Transfer fees. Fees are always transferred from buyer to the seller and the exchange although seller is 
            the one that actually 'pays' the fees
   * @dev if the currency ETH, no additional transfer is needed to pay exchange fees since the functions that receive ETH are 'payable'
   * @param seller the seller
   * @param buyer the buyer
   * @param amount amount to transfer
   * @param currency currency of the transfer
   */
  function _transferFees(
    address seller,
    address buyer,
    uint256 amount,
    address currency
  ) internal {
    // protocol fee
    uint256 protocolFee = (protocolFeeBps * amount) / PRECISION;
    uint256 remainingAmount = amount - protocolFee;
    // ETH
    if (currency == address(0)) {
      // transfer amount to seller
      (bool sent, ) = seller.call{value: remainingAmount}('');
      require(sent, 'failed to send ether to seller');
    } else {
      // transfer final amount (post-fees) to seller
      IERC20(currency).transferFrom(buyer, seller, remainingAmount);
      // send fee to protocol
      IERC20(currency).transferFrom(buyer, address(this), protocolFee);
    }
  }

  // =================================================== UTILS ==================================================================

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

  // ====================================================== ADMIN FUNCTIONS ======================================================

  function _onlyAdmin() internal view {
    require(msg.sender == EXCHANGE_ADMIN);
  }

  /// @dev adds a new transaction currency to the exchange
  function addCurrency(address _currency) external {
    _onlyAdmin();
    _currencies.add(_currency);
  }

  /// @dev adds a new complication to the exchange
  function addComplication(address _complication) external {
    _onlyAdmin();
    _complications.add(_complication);
  }

  /// @dev removes a transaction currency from the exchange
  function removeCurrency(address _currency) external {
    _onlyAdmin();
    _currencies.remove(_currency);
  }

  /// @dev removes a complication from the exchange
  function removeComplication(address _complication) external {
    _onlyAdmin();
    _complications.remove(_complication);
  }

  /// @dev updates auto snipe executor
  function updateMatchExecutor(address _matchExecutor) external {
    _onlyAdmin();
    matchExecutor = _matchExecutor;
  }

  /// @dev updates the gas units required for WETH transfers
  function updateWethTransferGasUnits(uint32 _newWethTransferGasUnits) external {
    _onlyAdmin();
    wethTransferGasUnits = _newWethTransferGasUnits;
  }

  /// @dev updates exchange fees
  function updateProtocolFee(uint32 _newProtocolFeeBps) external {
    _onlyAdmin();
    protocolFeeBps = _newProtocolFeeBps;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
    returns (bool, uint256);

  function canExecMatchOneToMany(
    OrderTypes.MakerOrder calldata makerOrder,
    OrderTypes.MakerOrder[] calldata manyMakerOrders
  ) external view returns (bool);

  function canExecMatchOrder(
    OrderTypes.MakerOrder calldata sell,
    OrderTypes.MakerOrder calldata buy,
    OrderTypes.OrderItem[] calldata constructedNfts
  ) external view returns (bool, uint256);

  function canExecTakeOneOrder(OrderTypes.MakerOrder calldata makerOrder) external view returns (bool);

  function canExecTakeOrder(OrderTypes.MakerOrder calldata makerOrder, OrderTypes.OrderItem[] calldata takerItems)
    external
    view
    returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {Address} from '@openzeppelin/contracts/utils/Address.sol';
import {IERC1271} from '@openzeppelin/contracts/interfaces/IERC1271.sol';

/**
 * @title SignatureChecker
 * @notice This library allows verification of signatures for both EOAs and contracts.
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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