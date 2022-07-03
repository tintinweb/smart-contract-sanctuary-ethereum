// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

// external imports
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {Pausable} from '@openzeppelin/contracts/security/Pausable.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {IERC165} from '@openzeppelin/contracts/interfaces/IERC165.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

// internal imports
import {OrderTypes} from '../libs/OrderTypes.sol';
import {IComplication} from '../interfaces/IComplication.sol';

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
contract InfinityExchange is ReentrancyGuard, Ownable, Pausable {
  /// @dev WETH address of a chain; set at deploy time to the WETH address of the chain that this contract is deployed to
  address public immutable WETH;
  /// @dev This is the address that is used to send auto sniped orders for execution on chain
  address public matchExecutor;
  /// @dev Gas cost for auto sniped orders are paid by the buyers and refunded to this contract in the form of WETH
  uint32 public wethTransferGasUnits = 5e4;
  /// @notice max weth transfer gas units
  uint32 public constant MAX_WETH_TRANSFER_GAS_UNITS = 2e5;
  /// @notice Exchange fee in basis points (250 bps = 2.5%)
  uint32 public protocolFeeBps = 250;
  /// @notice Max exchange fee in basis points (2000 bps = 20%)
  uint32 public constant MAX_PROTOCOL_FEE_BPS = 2000;

  /// @dev Used in division
  uint256 constant PRECISION = 1e4; // precision for division; similar to bps

  /**
   @dev All orders should have a nonce >= to this value. 
        Any orders with nonce value less than this are non-executable. 
        Used for cancelling all outstanding orders.
  */
  mapping(address => uint256) public userMinOrderNonce;

  /// @dev This records already executed or cancelled orders to prevent replay attacks.
  mapping(address => mapping(uint256 => bool)) public isUserOrderNonceExecutedOrCancelled;

  ///@notice admin events
  event ETHWithdrawn(address indexed destination, uint256 amount);
  event ERC20Withdrawn(address indexed destination, address indexed currency, uint256 amount);
  event MatchExecutorUpdated(address indexed matchExecutor);
  event WethTransferGasUnitsUpdated(uint32 wethTransferGasUnits);
  event ProtocolFeeUpdated(uint32 protocolFee);

  /// @notice user events
  event MatchOrderFulfilled(
    bytes32 sellOrderHash,
    bytes32 buyOrderHash,
    address indexed seller,
    address indexed buyer,
    address complication, // address of the complication that defines the execution
    address indexed currency, // token address of the transacting currency
    uint256 amount, // amount spent on the order
    OrderTypes.OrderItem[] nfts // items in the order
  );
  event TakeOrderFulfilled(
    bytes32 orderHash,
    address indexed seller,
    address indexed buyer,
    address complication, // address of the complication that defines the execution
    address indexed currency, // token address of the transacting currency
    uint256 amount, // amount spent on the order
    OrderTypes.OrderItem[] nfts // items in the order
  );
  event CancelAllOrders(address indexed user, uint256 newMinNonce);
  event CancelMultipleOrders(address indexed user, uint256[] orderNonces);

  /**
    @param _weth address of a chain; set at deploy time to the WETH address of the chain that this contract is deployed to
    @param _matchExecutor address of the match executor used by match* functions to auto execute orders 
   */
  constructor(address _weth, address _matchExecutor) {
    WETH = _weth;
    matchExecutor = _matchExecutor;
  }

  // =================================================== USER FUNCTIONS =======================================================

  /**
   @notice Matches orders one to one where each order has 1 NFT. Example: Match 1 specific NFT buy with one specific NFT sell.
   @dev Can execute orders in batches for gas efficiency. Can only be called by the match executor. Buyers refund gas cost incurred by the
        match executor to this contract. Checks whether the given complication can execute the match.
   @param makerOrders1 Maker order 1
   @param makerOrders2 Maker order 2
  */
  function matchOneToOneOrders(
    OrderTypes.MakerOrder[] calldata makerOrders1,
    OrderTypes.MakerOrder[] calldata makerOrders2
  ) external nonReentrant whenNotPaused {
    uint256 startGas = gasleft();
    uint256 numMakerOrders = makerOrders1.length;
    require(msg.sender == matchExecutor, 'only match executor');
    require(numMakerOrders == makerOrders2.length, 'mismatched lengths');

    // the below 3 variables are copied locally once to save on gas
    // an SLOAD costs minimum 100 gas where an MLOAD only costs minimum 3 gas
    // since these values won't change during function execution, we can save on gas by copying them locally once
    // instead of SLOADing once for each loop iteration
    uint32 _protocolFeeBps = protocolFeeBps;
    uint32 _wethTransferGasUnits = wethTransferGasUnits;
    address weth = WETH;
    uint256 sharedCost = (startGas - gasleft()) / numMakerOrders;
    for (uint256 i; i < numMakerOrders; ) {
      uint256 startGasPerOrder = gasleft() + sharedCost;
      _matchOneToOneOrders(
        makerOrders1[i],
        makerOrders2[i],
        startGasPerOrder,
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
   @dev Can only be called by the match executor. Buyers refund gas cost incurred by the
        match executor to this contract. Checks whether the given complication can execute the match.
   @param makerOrder The one order to match
   @param manyMakerOrders Array of multiple orders to match the one order against
  */
  function matchOneToManyOrders(
    OrderTypes.MakerOrder calldata makerOrder,
    OrderTypes.MakerOrder[] calldata manyMakerOrders
  ) external nonReentrant whenNotPaused {
    uint256 startGas = gasleft();
    require(msg.sender == matchExecutor, 'only match executor');

    (bool canExec, bytes32 makerOrderHash) = IComplication(makerOrder.execParams[0]).canExecMatchOneToMany(
      makerOrder,
      manyMakerOrders
    );
    require(canExec, 'cannot execute');

    bool makerOrderExpired = isUserOrderNonceExecutedOrCancelled[makerOrder.signer][makerOrder.constraints[5]] ||
      makerOrder.constraints[5] < userMinOrderNonce[makerOrder.signer];
    require(!makerOrderExpired, 'maker order expired');

    uint256 ordersLength = manyMakerOrders.length;
    // the below 3 variables are copied locally once to save on gas
    // an SLOAD costs minimum 100 gas where an MLOAD only costs minimum 3 gas
    // since these values won't change during function execution, we can save on gas by copying them locally once
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
      // check gas price constraint
      if (makerOrder.constraints[6] > 0) {
        require(tx.gasprice <= makerOrder.constraints[6], 'gas price too high');
      }
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
   @dev Can only be called by the match executor. Buyers refund gas cost incurred by the
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
  ) external nonReentrant whenNotPaused {
    uint256 startGas = gasleft();
    uint256 numSells = sells.length;
    require(msg.sender == matchExecutor, 'only match executor');
    require(numSells == buys.length, 'mismatched lengths');
    require(numSells == constructs.length, 'mismatched lengths');
    // the below 3 variables are copied locally once to save on gas
    // an SLOAD costs minimum 100 gas where an MLOAD only costs minimum 3 gas
    // since these values won't change during function execution, we can save on gas by copying them locally once
    // instead of SLOADing once for each loop iteration
    uint32 _protocolFeeBps = protocolFeeBps;
    uint32 _wethTransferGasUnits = wethTransferGasUnits;
    address weth = WETH;
    uint256 sharedCost = (startGas - gasleft()) / numSells;
    for (uint256 i; i < numSells; ) {
      uint256 startGasPerOrder = gasleft() + sharedCost;
      _matchOrders(sells[i], buys[i], constructs[i], startGasPerOrder, _protocolFeeBps, _wethTransferGasUnits, weth);
      unchecked {
        ++i;
      }
    }
  }

  /**
   @notice Batch buys or sells orders with specific `1` NFTs. Transaction initiated by an end user.
   @param makerOrders The orders to fulfill
  */
  function takeMultipleOneOrders(OrderTypes.MakerOrder[] calldata makerOrders)
    external
    payable
    nonReentrant
    whenNotPaused
  {
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

      bool orderExpired = isUserOrderNonceExecutedOrCancelled[makerOrders[i].signer][makerOrders[i].constraints[5]] ||
        makerOrders[i].constraints[5] < userMinOrderNonce[makerOrders[i].signer];
      require(!orderExpired, 'order expired');

      (bool canExec, bytes32 makerOrderHash) = IComplication(makerOrders[i].execParams[0]).canExecTakeOneOrder(
        makerOrders[i]
      );
      require(canExec, 'cannot execute');

      uint256 execPrice = _getCurrentPrice(makerOrders[i]);
      totalPrice = totalPrice + execPrice;
      _execTakeOneOrder(makerOrderHash, makerOrders[i], isMakerSeller, execPrice);
      unchecked {
        ++i;
      }
    }
    // check to ensure that for ETH orders, enough ETH is sent
    // for non ETH orders, IERC20 transferFrom will throw error if insufficient amount is sent
    if (currency == address(0)) {
      require(msg.value >= totalPrice, 'insufficient total price');
      if (msg.value > totalPrice) {
        (bool sent, ) = msg.sender.call{value: msg.value - totalPrice}('');
        require(sent, 'failed returning excess ETH');
      }
    }
  }

  /**
   @notice Batch buys or sells orders where maker orders can have unspecified NFTs. Transaction initiated by an end user.
   @param makerOrders The orders to fulfill
   @param takerNfts The specific NFTs that the taker is willing to take that intersect with the higher level intent of the maker
   Example: If a makerOrder is 'buy any one of these 2 specific NFTs', then the takerNfts would be 'this one specific NFT'.
  */
  function takeOrders(OrderTypes.MakerOrder[] calldata makerOrders, OrderTypes.OrderItem[][] calldata takerNfts)
    external
    payable
    nonReentrant
    whenNotPaused
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
    if (currency == address(0)) {
      require(msg.value >= totalPrice, 'insufficient total price');
      if (msg.value > totalPrice) {
        (bool sent, ) = msg.sender.call{value: msg.value - totalPrice}('');
        require(sent, 'failed returning excess ETH');
      }
    }
  }

  /**
   @notice Helper function (non exchange related) to send multiple NFTs in one go. Only ERC721
   @param to the receiver address
   @param items the specific NFTs to transfer
  */
  function transferMultipleNFTs(address to, OrderTypes.OrderItem[] calldata items) external nonReentrant whenNotPaused {
    require(to != address(0), 'invalid address');
    _transferMultipleNFTs(msg.sender, to, items);
  }

  /**
   * @notice Cancel all pending orders
   * @param minNonce minimum user nonce
   */
  function cancelAllOrders(uint256 minNonce) external {
    require(minNonce > userMinOrderNonce[msg.sender], 'nonce too low');
    require(minNonce < userMinOrderNonce[msg.sender] + 1e5, 'too many');
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

  // ====================================================== VIEW FUNCTIONS ======================================================

  /**
   * @notice Check whether user order nonce is executed or cancelled
   * @param user address of user
   * @param nonce nonce of the order
   * @return whether nonce is valid
   */
  function isNonceValid(address user, uint256 nonce) external view returns (bool) {
    return !isUserOrderNonceExecutedOrCancelled[user][nonce] && nonce >= userMinOrderNonce[user];
  }

  // ====================================================== INTERNAL FUNCTIONS ================================================

  /**
   * @notice Internal helper function to match orders one to one
   * @param makerOrder1 first order
   * @param makerOrder2 second maker order
   * @param startGasPerOrder start gas when this order started execution
   * @param _protocolFeeBps exchange fee
   * @param _wethTransferGasUnits gas units that a WETH transfer will use
   * @param weth WETH address
   */
  function _matchOneToOneOrders(
    OrderTypes.MakerOrder calldata makerOrder1,
    OrderTypes.MakerOrder calldata makerOrder2,
    uint256 startGasPerOrder,
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

    (bool canExec, bytes32 sellOrderHash, bytes32 buyOrderHash, uint256 execPrice) = IComplication(
      makerOrder1.execParams[0]
    ).canExecMatchOneToOne(sell, buy);

    require(canExec, 'cannot execute');

    bool sellOrderExpired = isUserOrderNonceExecutedOrCancelled[sell.signer][sell.constraints[5]] ||
      sell.constraints[5] < userMinOrderNonce[sell.signer];
    require(!sellOrderExpired, 'sell order expired');

    bool buyOrderExpired = isUserOrderNonceExecutedOrCancelled[buy.signer][buy.constraints[5]] ||
      buy.constraints[5] < userMinOrderNonce[buy.signer];
    require(!buyOrderExpired, 'buy order expired');

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
    (bool verified, bytes32 buyOrderHash) = IComplication(sell.execParams[0]).verifyMatchOneToManyOrders(
      false,
      sell,
      buy
    );
    require(verified, 'order not verified');

    bool buyOrderExpired = isUserOrderNonceExecutedOrCancelled[buy.signer][buy.constraints[5]] ||
      buy.constraints[5] < userMinOrderNonce[buy.signer];
    require(!buyOrderExpired, 'buy order expired');

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
    (bool verified, bytes32 sellOrderHash) = IComplication(sell.execParams[0]).verifyMatchOneToManyOrders(
      true,
      sell,
      buy
    );
    require(verified, 'order not verified');

    bool sellOrderExpired = isUserOrderNonceExecutedOrCancelled[sell.signer][sell.constraints[5]] ||
      sell.constraints[5] < userMinOrderNonce[sell.signer];
    require(!sellOrderExpired, 'sell order expired');

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
   * @notice Internal helper function to match orders specified via a higher level intent
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
    uint32 _protocolFeeBps,
    uint32 _wethTransferGasUnits,
    address weth
  ) internal {
    (bool executionValid, bytes32 sellOrderHash, bytes32 buyOrderHash, uint256 execPrice) = IComplication(
      sell.execParams[0]
    ).canExecMatchOrder(sell, buy, constructedNfts);
    require(executionValid, 'cannot execute');

    bool sellOrderExpired = isUserOrderNonceExecutedOrCancelled[sell.signer][sell.constraints[5]] ||
      sell.constraints[5] < userMinOrderNonce[sell.signer];
    require(!sellOrderExpired, 'sell order expired');

    bool buyOrderExpired = isUserOrderNonceExecutedOrCancelled[buy.signer][buy.constraints[5]] ||
      buy.constraints[5] < userMinOrderNonce[buy.signer];
    require(!buyOrderExpired, 'buy order expired');

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
    if (buy.constraints[6] > 0) {
      require(tx.gasprice <= buy.constraints[6], 'gas price too high');
    }
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
      execPrice,
      buy.nfts
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
    if (buy.constraints[6] > 0) {
      require(tx.gasprice <= buy.constraints[6], 'gas price too high');
    }
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
      execPrice,
      buy.nfts
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
      execPrice,
      sell.nfts
    );
    return protocolFee;
  }

  /// @dev This helper purely exists to help reduce contract size a bit and avoid any stack too deep errors
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
    // checks if maker specified a max gas price
    if (buy.constraints[6] > 0) {
      require(tx.gasprice <= buy.constraints[6], 'gas price too high');
    }
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
      execPrice,
      constructedNfts
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

  /// @dev This helper purely exists to help reduce contract size a bit and avoid any stack too deep errors
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

  /// @notice Internal helper function to emit match events
  function _emitMatchEvent(
    bytes32 sellOrderHash,
    bytes32 buyOrderHash,
    address seller,
    address buyer,
    address complication,
    address currency,
    uint256 amount,
    OrderTypes.OrderItem[] calldata nfts
  ) internal {
    emit MatchOrderFulfilled(sellOrderHash, buyOrderHash, seller, buyer, complication, currency, amount, nfts);
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
      _transferNFTsAndFees(makerOrder.signer, msg.sender, makerOrder.nfts, makerOrder.execParams[1], execPrice);
      _emitTakerEvent(makerOrderHash, makerOrder.signer, msg.sender, makerOrder, execPrice, makerOrder.nfts);
    } else {
      _transferNFTsAndFees(msg.sender, makerOrder.signer, makerOrder.nfts, makerOrder.execParams[1], execPrice);
      _emitTakerEvent(makerOrderHash, msg.sender, makerOrder.signer, makerOrder, execPrice, makerOrder.nfts);
    }
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
    bool orderExpired = isUserOrderNonceExecutedOrCancelled[makerOrder.signer][makerOrder.constraints[5]] ||
      makerOrder.constraints[5] < userMinOrderNonce[makerOrder.signer];
    require(!orderExpired, 'order expired');

    (bool executionValid, bytes32 makerOrderHash) = IComplication(makerOrder.execParams[0]).canExecTakeOrder(
      makerOrder,
      takerItems
    );
    require(executionValid, 'cannot execute');
    _execTakeOrders(makerOrderHash, makerOrder, takerItems, makerOrder.isSellOrder, execPrice);
  }

  /**
   * @notice Internal helper function that executes contract state changes and does asset transfers 
              for take orders specifying a higher level intent
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
      _transferNFTsAndFees(makerOrder.signer, msg.sender, takerItems, makerOrder.execParams[1], execPrice);
      _emitTakerEvent(makerOrderHash, makerOrder.signer, msg.sender, makerOrder, execPrice, takerItems);
    } else {
      _transferNFTsAndFees(msg.sender, makerOrder.signer, takerItems, makerOrder.execParams[1], execPrice);
      _emitTakerEvent(makerOrderHash, msg.sender, makerOrder.signer, makerOrder, execPrice, takerItems);
    }
  }

  /// @notice Internal helper function to emit events for take orders
  function _emitTakerEvent(
    bytes32 orderHash,
    address seller,
    address buyer,
    OrderTypes.MakerOrder calldata order,
    uint256 amount,
    OrderTypes.OrderItem[] calldata nfts
  ) internal {
    emit TakeOrderFulfilled(orderHash, seller, buyer, order.execParams[0], order.execParams[1], amount, nfts);
  }

  /**
   * @notice Transfers NFTs and fees
   * @param seller the seller
   * @param buyer the buyer
   * @param nfts nfts to transfer
   * @param currency currency of the transfer
   * @param amount amount to transfer
   */
  function _transferNFTsAndFees(
    address seller,
    address buyer,
    OrderTypes.OrderItem[] calldata nfts,
    address currency,
    uint256 amount
  ) internal {
    // transfer NFTs
    _transferMultipleNFTs(seller, buyer, nfts);
    // transfer fees
    _transferFees(seller, buyer, currency, amount);
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
   * @dev requires approvals to be set
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
   * @dev if the currency ETH, no additional transfer is needed to pay exchange fees since reqd functions are 'payable'
   * @param seller the seller
   * @param buyer the buyer
   * @param currency currency of the transfer
   * @param amount amount to transfer
   */
  function _transferFees(
    address seller,
    address buyer,
    address currency,
    uint256 amount
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

  // ====================================================== ADMIN FUNCTIONS ======================================================

  /// @dev Used for withdrawing exchange fees paid to the contract in ETH
  function withdrawETH(address destination) external onlyOwner {
    uint256 amount = address(this).balance;
    (bool sent, ) = destination.call{value: amount}('');
    require(sent, 'failed');
    emit ETHWithdrawn(destination, amount);
  }

  /// @dev Used for withdrawing exchange fees paid to the contract in ERC20 tokens
  function withdrawTokens(
    address destination,
    address currency,
    uint256 amount
  ) external onlyOwner {
    IERC20(currency).transfer(destination, amount);
    emit ERC20Withdrawn(destination, currency, amount);
  }

  /// @dev Updates auto snipe executor
  function updateMatchExecutor(address _matchExecutor) external onlyOwner {
    require(_matchExecutor != address(0), 'match executor cannot be 0');
    matchExecutor = _matchExecutor;
    emit MatchExecutorUpdated(_matchExecutor);
  }

  /// @dev Updates the gas units required for WETH transfers
  function updateWethTransferGas(uint32 _newWethTransferGasUnits) external onlyOwner {
    require(_newWethTransferGasUnits <= MAX_WETH_TRANSFER_GAS_UNITS);
    wethTransferGasUnits = _newWethTransferGasUnits;
    emit WethTransferGasUnitsUpdated(_newWethTransferGasUnits);
  }

  /// @dev Updates exchange fees
  function updateProtocolFee(uint32 _newProtocolFeeBps) external onlyOwner {
    require(_newProtocolFeeBps <= MAX_PROTOCOL_FEE_BPS, 'protocol fee too high');
    protocolFeeBps = _newProtocolFeeBps;
    emit ProtocolFeeUpdated(_newProtocolFeeBps);
  }

  /// @dev Function to pause the contract
  function pause() external onlyOwner {
    _pause();
  }

  /// @dev Function to unpause the contract
  function unpause() external onlyOwner {
    _unpause();
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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