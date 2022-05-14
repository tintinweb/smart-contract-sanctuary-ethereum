// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OrderTypes} from '../libs/OrderTypes.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {ICurrencyRegistry} from '../interfaces/ICurrencyRegistry.sol';
import {IComplicationRegistry} from '../interfaces/IComplicationRegistry.sol';
import {IComplication} from '../interfaces/IComplication.sol';
import {IInfinityExchange} from '../interfaces/IInfinityExchange.sol';
import {IInfinityFeeTreasury} from '../interfaces/IInfinityFeeTreasury.sol';
import {IInfinityTradingRewards} from '../interfaces/IInfinityTradingRewards.sol';
import {SignatureChecker} from '../libs/SignatureChecker.sol';
import {IERC165} from '@openzeppelin/contracts/interfaces/IERC165.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC1155} from '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import {IERC20, SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

// import 'hardhat/console.sol'; // todo: remove this

/**
 * @title InfinityExchange

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
contract InfinityExchange is IInfinityExchange, ReentrancyGuard, Ownable {
  using OrderTypes for OrderTypes.Order;
  using OrderTypes for OrderTypes.OrderItem;
  using SafeERC20 for IERC20;

  address public immutable WETH;
  bytes32 public immutable DOMAIN_SEPARATOR;

  ICurrencyRegistry public currencyRegistry;
  IComplicationRegistry public complicationRegistry;
  IInfinityFeeTreasury public infinityFeeTreasury;
  IInfinityTradingRewards public infinityTradingRewards;

  mapping(address => uint256) public userMinOrderNonce;
  mapping(address => mapping(uint256 => bool)) public isUserOrderNonceExecutedOrCancelled;
  address public matchExecutor;

  event CancelAllOrders(address user, uint256 newMinNonce);
  event CancelMultipleOrders(address user, uint256[] orderNonces);
  event NewCurrencyRegistry(address currencyRegistry);
  event NewComplicationRegistry(address complicationRegistry);
  event NewInfinityFeeTreasury(address infinityFeeTreasury);
  event NewInfinityTradingRewards(address infinityTradingRewards);
  event NewMatchExecutor(address matchExecutor);

  event OrderFulfilled(
    bytes32 sellOrderHash, // hash of the sell order
    bytes32 buyOrderHash, // hash of the sell order
    address indexed seller,
    address indexed buyer,
    address indexed complication, // address of the complication that defines the execution
    address currency, // token address of the transacting currency
    OrderTypes.OrderItem[] nfts, // nfts sold; todo: check actual output
    uint256 amount // amount spent on the order
  );

  /**
   * @notice Constructor
   * @param _currencyRegistry currency manager address
   * @param _complicationRegistry execution manager address
   * @param _WETH wrapped ether address (for other chains, use wrapped native asset)
   * @param _matchExecutor executor address for matches
   */
  constructor(
    address _currencyRegistry,
    address _complicationRegistry,
    address _WETH,
    address _matchExecutor
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

    currencyRegistry = ICurrencyRegistry(_currencyRegistry);
    complicationRegistry = IComplicationRegistry(_complicationRegistry);
    WETH = _WETH;
    matchExecutor = _matchExecutor;
  }

  // =================================================== USER FUNCTIONS =======================================================

  /**
   * @notice Cancel all pending orders
   * @param minNonce minimum user nonce
   */
  function cancelAllOrders(uint256 minNonce) external {
    // console.log('user min order nonce', msg.sender, userMinOrderNonce[msg.sender]);
    // console.log('new min order nonce', msg.sender, minNonce);
    require(minNonce > userMinOrderNonce[msg.sender], 'nonce too low');
    require(minNonce < userMinOrderNonce[msg.sender] + 1000000, 'too many');
    userMinOrderNonce[msg.sender] = minNonce;
    emit CancelAllOrders(msg.sender, minNonce);
  }

  /**
   * @notice Cancel multiple orders
   * @param orderNonces array of order nonces
   */
  function cancelMultipleOrders(uint256[] calldata orderNonces) external {
    require(orderNonces.length > 0, 'cannot be empty');
    // console.log('user min order nonce', msg.sender, userMinOrderNonce[msg.sender]);
    for (uint256 i = 0; i < orderNonces.length; i++) {
      // console.log('order nonce', orderNonces[i]);
      require(orderNonces[i] > userMinOrderNonce[msg.sender], 'nonce too low');
      require(!isUserOrderNonceExecutedOrCancelled[msg.sender][orderNonces[i]], 'nonce already executed or cancelled');
      isUserOrderNonceExecutedOrCancelled[msg.sender][orderNonces[i]] = true;
    }
    emit CancelMultipleOrders(msg.sender, orderNonces);
  }

  function matchOrders(
    OrderTypes.Order[] calldata sells,
    OrderTypes.Order[] calldata buys,
    OrderTypes.Order[] calldata constructs,
    bool tradingRewards,
    bool feeDiscountEnabled
  ) external override nonReentrant {
    uint256 startGas = gasleft();
    // check pre-conditions
    require(sells.length == buys.length, 'mismatched lengths');
    require(sells.length == constructs.length, 'mismatched lengths');

    if (tradingRewards) {
      address[] memory sellers = new address[](sells.length);
      address[] memory buyers = new address[](sells.length);
      address[] memory currencies = new address[](sells.length);
      uint256[] memory amounts = new uint256[](sells.length);
      // execute orders one by one
      for (uint256 i = 0; i < sells.length; ) {
        (sellers[i], buyers[i], currencies[i], amounts[i]) = _matchOrders(
          sells[i],
          buys[i],
          constructs[i],
          feeDiscountEnabled
        );
        unchecked {
          ++i;
        }
      }
      infinityTradingRewards.updateRewards(sellers, buyers, currencies, amounts);
    } else {
      for (uint256 i = 0; i < sells.length; ) {
        _matchOrders(sells[i], buys[i], constructs[i], feeDiscountEnabled);
        unchecked {
          ++i;
        }
      }
    }
    // refund gas to match executor
    infinityFeeTreasury.refundMatchExecutionGasFee(startGas, sells, matchExecutor, WETH);
  }

  function takeOrders(
    OrderTypes.Order[] calldata makerOrders,
    OrderTypes.Order[] calldata takerOrders,
    bool tradingRewards,
    bool feeDiscountEnabled
  ) external payable override nonReentrant {
    // check pre-conditions
    require(makerOrders.length == takerOrders.length, 'mismatched lengths');

    if (tradingRewards) {
      // console.log('trading rewards enabled');
      address[] memory sellers = new address[](makerOrders.length);
      address[] memory buyers = new address[](makerOrders.length);
      address[] memory currencies = new address[](makerOrders.length);
      uint256[] memory amounts = new uint256[](makerOrders.length);
      // execute orders one by one
      for (uint256 i = 0; i < makerOrders.length; ) {
        (sellers[i], buyers[i], currencies[i], amounts[i]) = _takeOrders(
          makerOrders[i],
          takerOrders[i],
          feeDiscountEnabled
        );
        unchecked {
          ++i;
        }
      }
      infinityTradingRewards.updateRewards(sellers, buyers, currencies, amounts);
    } else {
      // console.log('no trading rewards');
      for (uint256 i = 0; i < makerOrders.length; ) {
        _takeOrders(makerOrders[i], takerOrders[i], feeDiscountEnabled);
        unchecked {
          ++i;
        }
      }
    }
  }

  function batchTransferNFTs(
    address from,
    address to,
    OrderTypes.OrderItem[] calldata items
  ) external nonReentrant {
    _batchTransferNFTs(from, to, items);
  }

  // ====================================================== VIEW FUNCTIONS ======================================================

  /**
   * @notice Check whether user order nonce is executed or cancelled
   * @param user address of user
   * @param nonce nonce of the order
   */
  function isNonceValid(address user, uint256 nonce) external view returns (bool) {
    return !isUserOrderNonceExecutedOrCancelled[user][nonce] && nonce > userMinOrderNonce[user];
  }

  function verifyOrderSig(OrderTypes.Order calldata order) external view returns (bool) {
    // Verify the validity of the signature
    // console.log('verifying order signature');
    (bytes32 r, bytes32 s, uint8 v) = abi.decode(order.sig, (bytes32, bytes32, uint8));
    // console.log('domain sep:');
    // console.logBytes32(DOMAIN_SEPARATOR);
    // console.log('signature:');
    // console.logBytes32(r);
    // console.logBytes32(s);
    // console.log(v);
    // console.log('signer', order.signer);
    return SignatureChecker.verify(_hash(order), order.signer, r, s, v, DOMAIN_SEPARATOR);
  }

  // ====================================================== INTERNAL FUNCTIONS ================================================

  function _matchOrders(
    OrderTypes.Order calldata sell,
    OrderTypes.Order calldata buy,
    OrderTypes.Order calldata constructed,
    bool feeDiscountEnabled
  )
    internal
    returns (
      address,
      address,
      address,
      uint256
    )
  {
    bytes32 sellOrderHash = _hash(sell);
    bytes32 buyOrderHash = _hash(buy);

    // if this order is not valid, just return and continue with other orders
    (bool orderVerified, uint256 execPrice) = _verifyOrders(sellOrderHash, buyOrderHash, sell, buy, constructed);
    if (!orderVerified) {
      // console.log('skipping invalid order');
      return (address(0), address(0), address(0), 0);
    }

    return _execMatchOrders(sellOrderHash, buyOrderHash, sell, buy, constructed, execPrice, feeDiscountEnabled);
  }

  function _execMatchOrders(
    bytes32 sellOrderHash,
    bytes32 buyOrderHash,
    OrderTypes.Order calldata sell,
    OrderTypes.Order calldata buy,
    OrderTypes.Order calldata constructed,
    uint256 execPrice,
    bool feeDiscountEnabled
  )
    internal
    returns (
      address,
      address,
      address,
      uint256
    )
  {
    // exec order
    return
      _execOrder(
        sellOrderHash,
        buyOrderHash,
        sell.signer,
        buy.signer,
        sell.constraints[6],
        buy.constraints[6],
        sell.constraints[5],
        constructed,
        execPrice,
        feeDiscountEnabled
      );
  }

  function _takeOrders(
    OrderTypes.Order calldata makerOrder,
    OrderTypes.Order calldata takerOrder,
    bool feeDiscountEnabled
  )
    internal
    returns (
      address,
      address,
      address,
      uint256
    )
  {
    // console.log('taking order');
    bytes32 makerOrderHash = _hash(makerOrder);
    bytes32 takerOrderHash = _hash(takerOrder);

    // if this order is not valid, just return and continue with other orders
    (bool orderVerified, uint256 execPrice) = _verifyTakeOrders(makerOrderHash, makerOrder, takerOrder);
    if (!orderVerified) {
      // console.log('skipping invalid order');
      return (address(0), address(0), address(0), 0);
    }

    // exec order
    return _exectakeOrders(makerOrderHash, takerOrderHash, makerOrder, takerOrder, execPrice, feeDiscountEnabled);
  }

  function _exectakeOrders(
    bytes32 makerOrderHash,
    bytes32 takerOrderHash,
    OrderTypes.Order calldata makerOrder,
    OrderTypes.Order calldata takerOrder,
    uint256 execPrice,
    bool feeDiscountEnabled
  )
    internal
    returns (
      address,
      address,
      address,
      uint256
    )
  {
    // exec order
    bool isTakerSell = takerOrder.isSellOrder;
    if (isTakerSell) {
      return _execTakerSellOrder(takerOrderHash, makerOrderHash, takerOrder, makerOrder, execPrice, feeDiscountEnabled);
    } else {
      return _execTakerBuyOrder(takerOrderHash, makerOrderHash, takerOrder, makerOrder, execPrice, feeDiscountEnabled);
    }
  }

  function _execTakerSellOrder(
    bytes32 takerOrderHash,
    bytes32 makerOrderHash,
    OrderTypes.Order calldata takerOrder,
    OrderTypes.Order calldata makerOrder,
    uint256 execPrice,
    bool feeDiscountEnabled
  )
    internal
    returns (
      address,
      address,
      address,
      uint256
    )
  {
    // console.log('executing taker sell order');
    return
      _execOrder(
        takerOrderHash,
        makerOrderHash,
        takerOrder.signer,
        makerOrder.signer,
        takerOrder.constraints[6],
        makerOrder.constraints[6],
        takerOrder.constraints[5],
        takerOrder,
        execPrice,
        feeDiscountEnabled
      );
  }

  function _execTakerBuyOrder(
    bytes32 takerOrderHash,
    bytes32 makerOrderHash,
    OrderTypes.Order calldata takerOrder,
    OrderTypes.Order calldata makerOrder,
    uint256 execPrice,
    bool feeDiscountEnabled
  )
    internal
    returns (
      address,
      address,
      address,
      uint256
    )
  {
    // console.log('executing taker buy order');
    return
      _execOrder(
        makerOrderHash,
        takerOrderHash,
        makerOrder.signer,
        takerOrder.signer,
        makerOrder.constraints[6],
        takerOrder.constraints[6],
        makerOrder.constraints[5],
        takerOrder,
        execPrice,
        feeDiscountEnabled
      );
  }

  function _verifyOrders(
    bytes32 sellOrderHash,
    bytes32 buyOrderHash,
    OrderTypes.Order calldata sell,
    OrderTypes.Order calldata buy,
    OrderTypes.Order calldata constructed
  ) internal view returns (bool, uint256) {
    // console.log('verifying match orders');
    bool sidesMatch = sell.isSellOrder && !buy.isSellOrder;
    bool complicationsMatch = sell.execParams[0] == buy.execParams[0];
    bool currenciesMatch = sell.execParams[1] == buy.execParams[1];
    bool sellOrderValid = _isOrderValid(sell, sellOrderHash);
    bool buyOrderValid = _isOrderValid(buy, buyOrderHash);
    (bool executionValid, uint256 execPrice) = IComplication(sell.execParams[0]).canExecOrder(sell, buy, constructed);
    // console.log('sidesMatch', sidesMatch);
    // console.log('complicationsMatch', complicationsMatch);
    // console.log('currenciesMatch', currenciesMatch);
    // console.log('sellOrderValid', sellOrderValid);
    // console.log('buyOrderValid', buyOrderValid);
    // console.log('executionValid', executionValid);
    return (
      sidesMatch && complicationsMatch && currenciesMatch && sellOrderValid && buyOrderValid && executionValid,
      execPrice
    );
  }

  function _verifyTakeOrders(
    bytes32 makerOrderHash,
    OrderTypes.Order calldata maker,
    OrderTypes.Order calldata taker
  ) internal view returns (bool, uint256) {
    // console.log('verifying take orders');
    bool msgSenderIsTaker = msg.sender == taker.signer;
    bool sidesMatch = (maker.isSellOrder && !taker.isSellOrder) || (!maker.isSellOrder && taker.isSellOrder);
    bool complicationsMatch = maker.execParams[0] == taker.execParams[0];
    bool currenciesMatch = maker.execParams[1] == taker.execParams[1];
    bool makerOrderValid = _isOrderValid(maker, makerOrderHash);
    (bool executionValid, uint256 execPrice) = IComplication(maker.execParams[0]).canExecTakeOrder(maker, taker);
    // console.log('msgSenderIsTaker', msgSenderIsTaker);
    // console.log('sidesMatch', sidesMatch);
    // console.log('complicationsMatch', complicationsMatch);
    // console.log('currenciesMatch', currenciesMatch);
    // console.log('makerOrderValid', makerOrderValid);
    // console.log('executionValid', executionValid);
    return (
      msgSenderIsTaker && sidesMatch && complicationsMatch && currenciesMatch && makerOrderValid && executionValid,
      execPrice
    );
  }

  /**
   * @notice Verifies the validity of the order
   * @param order the order
   * @param orderHash computed hash of the order
   */
  function _isOrderValid(OrderTypes.Order calldata order, bytes32 orderHash) internal view returns (bool) {
    return
      _orderValidity(
        order.signer,
        order.sig,
        orderHash,
        order.execParams[0],
        order.execParams[1],
        order.constraints[6]
      );
  }

  function _orderValidity(
    address signer,
    bytes calldata sig,
    bytes32 orderHash,
    address complication,
    address currency,
    uint256 nonce
  ) internal view returns (bool) {
    // console.log('checking order validity');
    bool orderExpired = isUserOrderNonceExecutedOrCancelled[signer][nonce] || nonce < userMinOrderNonce[signer];
    // console.log('order expired:', orderExpired);
    // Verify the validity of the signature
    (bytes32 r, bytes32 s, uint8 v) = abi.decode(sig, (bytes32, bytes32, uint8));
    bool sigValid = SignatureChecker.verify(orderHash, signer, r, s, v, DOMAIN_SEPARATOR);

    if (
      orderExpired ||
      !sigValid ||
      signer == address(0) ||
      !currencyRegistry.isCurrencyWhitelisted(currency) ||
      !complicationRegistry.isComplicationWhitelisted(complication)
    ) {
      return false;
    }
    return true;
  }

  function _execOrder(
    bytes32 sellOrderHash,
    bytes32 buyOrderHash,
    address seller,
    address buyer,
    uint256 sellNonce,
    uint256 buyNonce,
    uint256 minBpsToSeller,
    OrderTypes.Order calldata constructed,
    uint256 execPrice,
    bool feeDiscountEnabled
  )
    internal
    returns (
      address,
      address,
      address,
      uint256
    )
  {
    // console.log('executing order');
    // Update order execution status to true (prevents replay)
    isUserOrderNonceExecutedOrCancelled[seller][sellNonce] = true;
    isUserOrderNonceExecutedOrCancelled[buyer][buyNonce] = true;

    _transferNFTsAndFees(
      seller,
      buyer,
      constructed.nfts,
      execPrice,
      constructed.execParams[1],
      minBpsToSeller,
      constructed.execParams[0],
      feeDiscountEnabled
    );

    _emitEvent(sellOrderHash, buyOrderHash, seller, buyer, constructed, execPrice);

    return (seller, buyer, constructed.execParams[1], execPrice);
  }

  function _getCurrentPrice(OrderTypes.Order calldata order) internal view returns (uint256) {
    (uint256 startPrice, uint256 endPrice) = (order.constraints[1], order.constraints[2]);
    (uint256 startTime, uint256 endTime) = (order.constraints[3], order.constraints[4]);
    uint256 duration = endTime - startTime;
    uint256 priceDiff = startPrice - endPrice;
    if (priceDiff == 0 || duration == 0) {
      return startPrice;
    }
    uint256 elapsedTime = block.timestamp - startTime;
    uint256 portion = elapsedTime > duration ? 1 : elapsedTime / duration;
    priceDiff = priceDiff * portion;
    return startPrice - priceDiff;
  }

  function _emitEvent(
    bytes32 sellOrderHash,
    bytes32 buyOrderHash,
    address seller,
    address buyer,
    OrderTypes.Order calldata constructed,
    uint256 amount
  ) internal {
    emit OrderFulfilled(
      sellOrderHash,
      buyOrderHash,
      seller,
      buyer,
      constructed.execParams[0],
      constructed.execParams[1],
      constructed.nfts,
      amount
    );
  }

  function _transferNFTsAndFees(
    address seller,
    address buyer,
    OrderTypes.OrderItem[] calldata nfts,
    uint256 amount,
    address currency,
    uint256 minBpsToSeller,
    address complication,
    bool feeDiscountEnabled
  ) internal {
    // console.log('transfering nfts and fees');
    // transfer NFTs
    _batchTransferNFTs(seller, buyer, nfts);
    // transfer fees
    _transferFees(seller, buyer, nfts, amount, currency, minBpsToSeller, complication, feeDiscountEnabled);
  }

  function _batchTransferNFTs(
    address from,
    address to,
    OrderTypes.OrderItem[] calldata nfts
  ) internal {
    // console.log('batch transfering nfts');
    for (uint256 i = 0; i < nfts.length; ) {
      _transferNFTs(from, to, nfts[i]);
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @notice Transfer NFT
   * @param from address of the sender
   * @param to address of the recipient
   * @param item item to transfer
   */
  function _transferNFTs(
    address from,
    address to,
    OrderTypes.OrderItem calldata item
  ) internal {
    if (IERC165(item.collection).supportsInterface(0x80ac58cd)) {
      _transferERC721s(from, to, item);
    } else if (IERC165(item.collection).supportsInterface(0xd9b67a26)) {
      _transferERC1155s(from, to, item);
    }
  }

  function _transferERC721s(
    address from,
    address to,
    OrderTypes.OrderItem calldata item
  ) internal {
    for (uint256 i = 0; i < item.tokens.length; ) {
      // console.log('transfering erc721 from collection', item.collection, 'with tokenId', item.tokens[i].tokenId);
      // console.log('from address', from, 'to address', to);
      IERC721(item.collection).safeTransferFrom(from, to, item.tokens[i].tokenId);
      unchecked {
        ++i;
      }
    }
  }

  function _transferERC1155s(
    address from,
    address to,
    OrderTypes.OrderItem calldata item
  ) internal {
    for (uint256 i = 0; i < item.tokens.length; ) {
      // console.log('transfering erc1155 from collection', item.collection, 'with tokenId', item.tokens[i].tokenId);
      // console.log('num tokens', item.tokens[i].numTokens);
      // console.log('from address', from, 'to address', to);
      IERC1155(item.collection).safeTransferFrom(from, to, item.tokens[i].tokenId, item.tokens[i].numTokens, '');
      unchecked {
        ++i;
      }
    }
  }

  function _transferFees(
    address seller,
    address buyer,
    OrderTypes.OrderItem[] calldata nfts,
    uint256 amount,
    address currency,
    uint256 minBpsToSeller,
    address complication,
    bool feeDiscountEnabled
  ) internal {
    // console.log('transfering fees');
    infinityFeeTreasury.allocateFees{value: msg.value}(
      seller,
      buyer,
      nfts,
      amount,
      currency,
      minBpsToSeller,
      complication,
      feeDiscountEnabled
    );
  }

  function _hash(OrderTypes.Order calldata order) internal pure returns (bytes32) {
    // keccak256('Order(bool isSellOrder,address signer,uint256[] constraints,OrderItem[] nfts,address[] execParams,bytes extraParams)OrderItem(address collection,TokenInfo[] tokens)TokenInfo(uint256 tokenId,uint256 numTokens)')
    bytes32 ORDER_HASH = 0x7bcfb5a29031e6b8d34ca1a14dd0a1f5cb11b20f755bb2a31ee3c4b143477e4a;
    bytes32 orderHash = keccak256(
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
    // console.log('order hash:');
    // console.logBytes32(orderHash);
    return orderHash;
  }

  function _nftsHash(OrderTypes.OrderItem[] calldata nfts) internal pure returns (bytes32) {
    // keccak256('OrderItem(address collection,TokenInfo[] tokens)TokenInfo(uint256 tokenId,uint256 numTokens)')
    // console.log('calculating nfts hash');
    bytes32 ORDER_ITEM_HASH = 0xf73f37e9f570369ceaab59cef16249ae1c0ad1afd592d656afac0be6f63b87e0;
    bytes32[] memory hashes = new bytes32[](nfts.length);
    // console.log('nfts length', nfts.length);
    for (uint256 i = 0; i < nfts.length; ) {
      bytes32 hash = keccak256(abi.encode(ORDER_ITEM_HASH, nfts[i].collection, _tokensHash(nfts[i].tokens)));
      hashes[i] = hash;
      unchecked {
        ++i;
      }
    }
    bytes32 nftsHash = keccak256(abi.encodePacked(hashes));
    // console.log('nfts hash:');
    // console.logBytes32(nftsHash);
    return nftsHash;
  }

  function _tokensHash(OrderTypes.TokenInfo[] calldata tokens) internal pure returns (bytes32) {
    // keccak256('TokenInfo(uint256 tokenId,uint256 numTokens)')
    // console.log('calculating tokens hash');
    bytes32 TOKEN_INFO_HASH = 0x88f0bd19d14f8b5d22c0605a15d9fffc285ebc8c86fb21139456d305982906f1;
    bytes32[] memory hashes = new bytes32[](tokens.length);
    // console.log('tokens length:', tokens.length);
    for (uint256 i = 0; i < tokens.length; ) {
      bytes32 hash = keccak256(abi.encode(TOKEN_INFO_HASH, tokens[i].tokenId, tokens[i].numTokens));
      hashes[i] = hash;
      unchecked {
        ++i;
      }
    }
    bytes32 tokensHash = keccak256(abi.encodePacked(hashes));
    // console.log('tokens hash:');
    // console.logBytes32(tokensHash);
    return tokensHash;
  }

  // ====================================================== ADMIN FUNCTIONS ======================================================

  function rescueTokens(
    address destination,
    address currency,
    uint256 amount
  ) external onlyOwner {
    IERC20(currency).safeTransfer(destination, amount);
  }

  function rescueETH(address destination) external payable onlyOwner {
    (bool sent, ) = destination.call{value: msg.value}('');
    require(sent, 'failed');
  }

  /**
   * @notice Update currency manager
   * @param _currencyRegistry new currency manager address
   */
  function updateCurrencyRegistry(address _currencyRegistry) external onlyOwner {
    currencyRegistry = ICurrencyRegistry(_currencyRegistry);
    emit NewCurrencyRegistry(_currencyRegistry);
  }

  /**
   * @notice Update execution manager
   * @param _complicationRegistry new execution manager address
   */
  function updateComplicationRegistry(address _complicationRegistry) external onlyOwner {
    complicationRegistry = IComplicationRegistry(_complicationRegistry);
    emit NewComplicationRegistry(_complicationRegistry);
  }

  /**
   * @notice Update fee distributor
   * @param _infinityFeeTreasury new address
   */
  function updateInfinityFeeTreasury(address _infinityFeeTreasury) external onlyOwner {
    infinityFeeTreasury = IInfinityFeeTreasury(_infinityFeeTreasury);
    emit NewInfinityFeeTreasury(_infinityFeeTreasury);
  }

  function updateInfinityTradingRewards(address _infinityTradingRewards) external onlyOwner {
    infinityTradingRewards = IInfinityTradingRewards(_infinityTradingRewards);
    emit NewInfinityTradingRewards(_infinityTradingRewards);
  }

  function updateMatchExecutor(address _matchExecutor) external onlyOwner {
    matchExecutor = _matchExecutor;
    emit NewMatchExecutor(_matchExecutor);
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
pragma solidity ^0.8.0;

interface ICurrencyRegistry {
  function isCurrencyWhitelisted(address currency) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IComplicationRegistry {
  function isComplicationWhitelisted(address complication) external view returns (bool);
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
pragma solidity ^0.8.0;

import {OrderTypes} from '../libs/OrderTypes.sol';

interface IInfinityExchange {
  function takeOrders(
    OrderTypes.Order[] calldata makerOrders,
    OrderTypes.Order[] calldata takerOrders,
    bool tradingRewards,
    bool feeDiscountEnabled
  ) external payable;

  function matchOrders(
    OrderTypes.Order[] calldata sells,
    OrderTypes.Order[] calldata buys,
    OrderTypes.Order[] calldata constructs,
    bool tradingRewards,
    bool feeDiscountEnabled
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {OrderTypes} from '../libs/OrderTypes.sol';

interface IInfinityFeeTreasury {
  function getEffectiveFeeBps(address user) external view returns (uint16);

  function allocateFees(
    address seller,
    address buyer,
    OrderTypes.OrderItem[] calldata items,
    uint256 amount,
    address currency,
    uint256 minBpsToSeller,
    address execComplication,
    bool feeDiscountEnabled
  ) external payable;

  function refundMatchExecutionGasFee(
    uint256 startGas,
    OrderTypes.Order[] calldata sells,
    address matchExecutor,
    address weth
  ) external;

  function claimCreatorFees(address currency) external;

  function claimCuratorFees(
    address currency,
    uint256 cumulativeAmount,
    bytes32 expectedMerkleRoot,
    bytes32[] calldata merkleProof
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Duration} from '../interfaces/IStaker.sol';

interface IInfinityTradingRewards {
  function updateRewards(
    address[] calldata sellers,
    address[] calldata buyers,
    address[] calldata currencies,
    uint256[] calldata amounts
  ) external;

  function claimRewards(
    address destination,
    address currency,
    uint256 amount
  ) external;

  function stakeInfinityRewards(uint256 amount, Duration duration) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Address} from '@openzeppelin/contracts/utils/Address.sol';
import {IERC1271} from '@openzeppelin/contracts/interfaces/IERC1271.sol';

// import 'hardhat/console.sol'; // todo: remove this

/**
 * @title SignatureChecker
 * @notice This library allows verification of signatures for both EOAs and contracts.
 */
library SignatureChecker {
  /**
   * @notice Recovers the signer of a signature (for EOA)
   * @param hashed the hash containing the signed mesage
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
    // console.log('Recovered Signer:', signer);
    return signer;
  }

  /**
   * @notice Returns whether the signer matches the signed message
   * @param orderHash the hash containing the signed message
   * @param signer the signer address to confirm message validity
   * @param r parameter
   * @param s parameter
   * @param v parameter (27 or 28) this prevents malleability since the public key recovery equation has two possible solutions
   * @param domainSeparator paramer to prevent signature being executed in other chains and environments
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
    // console.log('digest:');
    // console.logBytes32(digest);
    if (Address.isContract(signer)) {
      // 0x1626ba7e is the interfaceId for signature contracts (see IERC1271)
      return IERC1271(signer).isValidSignature(digest, abi.encodePacked(r, s, v)) == 0x1626ba7e;
    } else {
      return recover(digest, r, s, v) == signer;
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
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
pragma solidity ^0.8.0;

import {OrderTypes} from '../libs/OrderTypes.sol';

enum Duration {
  NONE,
  THREE_MONTHS,
  SIX_MONTHS,
  TWELVE_MONTHS
}

enum StakeLevel {
  NONE,
  BRONZE,
  SILVER,
  GOLD,
  PLATINUM
}

interface IStaker {
  function stake(address user, uint256 amount, Duration duration) external;

  function changeDuration(uint256 amount, Duration oldDuration, Duration newDuration) external;

  function unstake(uint256 amount) external;

  function rageQuit() external;

  function getUserTotalStaked(address user) external view returns (uint256);

  function getUserTotalVested(address user) external view returns (uint256);

  function getRageQuitAmounts(address user) external view returns (uint256, uint256);

  function getUserStakePower(address user) external view returns (uint256);

  function getUserStakeLevel(address user) external view returns (StakeLevel);
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