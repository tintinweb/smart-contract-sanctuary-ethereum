// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./TokenWhitelist.sol";
import "./types/FlyweightTypes.sol";
import {FlyweightEvents} from "./libraries/FlyweightEvents.sol";

/**
 * @title Flyweight
 * Holds/manages order data
 */
contract Flyweight {
  /// @dev These are public to maximise contract transparency with users
  address public immutable uniswapRouterAddress;
  address public immutable oracleNodeAddress;
  TokenWhitelist public immutable tokenWhitelist;
  uint public ordersCount;
  mapping(uint => Order) public orders;
  mapping(address => uint[]) public orderIdsByAddress;
  mapping(string => string) public prices;
  mapping(uint => bytes32) public depositTxns;

  constructor(
    address _uniswapRouterAddress,
    address _oracleNodeAddress,
    string[] memory tokenSymbols,
    address[] memory tokenAddresses
  ) {
    uniswapRouterAddress = _uniswapRouterAddress;
    oracleNodeAddress = _oracleNodeAddress;
    ordersCount = 0;
    tokenWhitelist = new TokenWhitelist(
      _uniswapRouterAddress,
      tokenSymbols,
      tokenAddresses
    );

    for (uint i = 0; i < tokenSymbols.length; i++) {
      /// @dev Approvals to automatically send erc20's upon swap execution, back to order owner address
      IERC20(tokenAddresses[i]).approve(uniswapRouterAddress, type(uint).max);
    }
  }

  /**
   * @dev Whitelisted token symbols are stored immutably in contract state during contract creation
   * @return Token symbols supported on the Flyweight platform
   */
  function getWhitelistedSymbols() external view returns (string[] memory) {
    return tokenWhitelist.getSymbols();
  }

  /// @return address(0) if the token is not supported on the Flyweight platform
  function tryGetTokenAddress(
    string calldata symbol
  ) external view returns (address) {
    return tokenWhitelist.addresses(symbol);
  }

  /**
   * Adds a new order to the contract storage
   * @param tokenIn The token to swap from. This will be the token the EOA has to deposit into the contract
   * @param tokenOut The token to swap to. This will be the token sent to the order owner's address after swap execution
   */
  function addNewOrder(
    string calldata tokenIn,
    string calldata tokenOut,
    string calldata tokenInTriggerPrice,
    OrderTriggerDirection direction,
    uint tokenInAmount
  ) external onlyEoa returns (uint) {
    // Only allow 1 pending order per user
    uint[] storage orderIds = orderIdsByAddress[msg.sender];
    if (orderIds.length > 0) {
      uint lastOrderId = orderIds[orderIds.length - 1];
      require(orders[lastOrderId].orderState != OrderState.PENDING_DEPOSIT);
    }

    uint id = ordersCount;
    orders[id] = Order({
      id: id,
      owner: msg.sender,
      orderState: OrderState.PENDING_DEPOSIT,
      tokenIn: tokenIn,
      tokenOut: tokenOut,
      tokenInTriggerPrice: tokenInTriggerPrice,
      direction: direction,
      tokenInAmount: tokenInAmount,
      blockNumber: block.number
    });

    orderIdsByAddress[msg.sender].push(id);
    ordersCount++;
    return id;
  }

  /**
   * Updates latest token prices (retrieved via the Flyweight oracle) & then proceeds to execute swaps for triggered orders
   * @param newPriceItems Latest token prices
   * @param newTriggeredOrderIds Latest order id's to trigger
   */
  function storePricesAndProcessTriggeredOrderIds(
    NewPriceItem[] calldata newPriceItems,
    uint[] calldata newTriggeredOrderIds
  ) external onlyEoa onlyValidOracle {
    // Update prices
    for (uint i = 0; i < newPriceItems.length; i++) {
      NewPriceItem memory item = newPriceItems[i];
      string memory oldPrice = prices[item.symbol];
      prices[item.symbol] = item.price;

      emit FlyweightEvents.PriceUpdated({
        timestamp: block.timestamp,
        symbol: item.symbol,
        oldPrice: oldPrice,
        newPrice: item.price
      });
    }

    // Trigger orders
    for (uint i = 0; i < newTriggeredOrderIds.length; i++) {
      uint orderId = newTriggeredOrderIds[i];
      emit FlyweightEvents.OrderTriggered({orderId: orderId});

      executeOrderId(orderId);
      emit FlyweightEvents.OrderExecuted({orderId: orderId});
    }
  }

  /// Executes the swap for an order & sends the resulting tokens to the order owner's address
  function executeOrderId(uint orderId) private {
    Order storage order = orders[orderId];
    assert(order.orderState == OrderState.UNTRIGGERED);

    address tokenInAddress = tokenWhitelist.addresses(order.tokenIn);
    address tokenOutAddress = tokenWhitelist.addresses(order.tokenOut);
    uint balance = IERC20(tokenInAddress).balanceOf(address(this));
    require(balance >= order.tokenInAmount);

    address[2] memory path = [tokenInAddress, tokenOutAddress];
    uint tokenOutMinQuote = 0; // todo: front-end feature request - add UI slider bar to allow user to set preferred slippage

    ISwapRouter swapRouter = ISwapRouter(uniswapRouterAddress);
    ISwapRouter.ExactInputSingleParams memory swapParams = ISwapRouter
      .ExactInputSingleParams({
        tokenIn: path[0],
        tokenOut: path[1],
        /**
         * "fee" is the uniswap LP pool "fee tier", not the "swap fee".
         * The swap fees are paid from the Flyweight treasury, not the user/EOA.
         * Flyweight does not take "cuts" from swaps and passes the savings onto the users.
         */
        fee: 3000,
        recipient: order.owner,
        deadline: block.timestamp,
        amountIn: order.tokenInAmount,
        amountOutMinimum: tokenOutMinQuote,
        sqrtPriceLimitX96: 0
      });

    swapRouter.exactInputSingle(swapParams);
    order.orderState = OrderState.EXECUTED;
  }

  function getOrdersByAddress(
    address addr
  ) external view returns (Order[] memory) {
    uint[] storage orderIds = orderIdsByAddress[addr];
    Order[] memory ordersForAddress = new Order[](orderIds.length);
    for (uint i = 0; i < orderIds.length; i++) {
      uint orderId = orderIds[i];
      ordersForAddress[i] = orders[orderId];
    }

    return ordersForAddress;
  }

  function cancelOrder(uint orderId) external onlyEoa {
    emit FlyweightEvents.OrderCancelRequested({
      orderId: orderId,
      sender: msg.sender
    });

    Order storage order = orders[orderId];
    assert(msg.sender == order.owner);
    require(
      order.orderState == OrderState.PENDING_DEPOSIT ||
        order.orderState == OrderState.UNTRIGGERED
    );

    /// @dev Only refund deposit if user sent it to the contract
    if (order.orderState == OrderState.UNTRIGGERED) {
      address tokenInAddress = tokenWhitelist.addresses(order.tokenIn);
      IERC20(tokenInAddress).transfer(order.owner, order.tokenInAmount);
    }

    order.orderState = OrderState.CANCELLED;
    emit FlyweightEvents.OrderCancelled({
      orderId: order.id,
      tokenInAmount: order.tokenInAmount,
      tokenIn: order.tokenIn,
      owner: order.owner,
      blockNumber: block.number,
      blockTimestamp: block.timestamp
    });
  }

  /// Stores data that links on-chain transactions to Flyweight order deposits
  function storeDepositTransactionsAndUpdateOrderStates(
    NewDepositTx[] calldata txns
  ) external onlyEoa onlyValidOracle {
    for (uint i = 0; i < txns.length; i++) {
      NewDepositTx calldata newDepositTx = txns[i];
      depositTxns[newDepositTx.orderId] = newDepositTx.txHash;

      Order storage order = orders[newDepositTx.orderId];
      if (order.orderState == OrderState.PENDING_DEPOSIT) {
        orders[newDepositTx.orderId].orderState = OrderState.UNTRIGGERED;
      }
    }
  }

  function getPendingDepositOrders() external view returns (Order[] memory) {
    Order[] memory pendingDepositOrders = new Order[](ordersCount);
    uint pendingDepositOrdersCount = 0;
    for (uint i = 0; i < ordersCount; i++) {
      if (orders[i].orderState == OrderState.PENDING_DEPOSIT) {
        pendingDepositOrders[pendingDepositOrdersCount] = orders[i];
        pendingDepositOrdersCount++;
      }
    }

    return pendingDepositOrders;
  }

  modifier onlyValidOracle() {
    assert(msg.sender == oracleNodeAddress);
    _;
  }

  modifier onlyEoa() {
    assert(msg.sender == tx.origin);
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title FlyweightEvents
library FlyweightEvents {
  /**
   * Records token prices that are updated in the contract
   * @dev Prices obtained from Flyweight oracle
   */
  event PriceUpdated(
    uint timestamp,
    string symbol,
    string oldPrice,
    string newPrice
  );

  /**
   * Records when an order is triggered.
   * @dev This event happens after the Flyweight oracle calculating that an order's swap should be executed, & before the actual on-chain swap occurring.
   */
  event OrderTriggered(uint orderId);

  /**
   * Records when an order is executed.
   * @dev This event happens after the on-chain swap is executed.
   */
  event OrderExecuted(uint orderId);

  /**
   * Records when an order cancelled is requested.
   * @dev This event happens after the EOA calls the cancel contract method, & before the order state is updated in the contract data.
   */
  event OrderCancelRequested(uint orderId, address sender);

  /**
   * Records when an order is cancelled.
   * @dev This event happens after the data is updated in the smart contract.
   */
  event OrderCancelled(
    uint orderId,
    uint tokenInAmount,
    string tokenIn,
    address owner,
    uint blockNumber,
    uint blockTimestamp
  );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title TokenWhitelist
 * Holds token addresses swappable on the Flyweight platform. These addresses are only set during contract creation and are never changed
 * @dev The decision to only support a limited set of "trusted" ERC20's is an intentional product decision. E.g.: if a flyweight order were to swap a coin called SuperMoonDoggyDegenCoin, there is no guarantee on slippage for coins with no uniswap liquidity. Only coins with decent uniswap liquidity should be permitted for best user experience with Flyweight.
 */
contract TokenWhitelist {
  /// @dev These are public to maximise contract transparency with users
  string[] public symbols;
  mapping(string => address) public addresses;

  constructor(
    address uniswapRouterAddress,
    string[] memory _symbols,
    address[] memory _addresses
  ) {
    assert(uniswapRouterAddress != address(0));
    assert(_symbols.length == _addresses.length);

    /// Set symbols
    symbols = _symbols;

    /// Set addresses
    for (uint i = 0; i < _symbols.length; i++) {
      string memory symbol = _symbols[i];
      address addr = _addresses[i];
      addresses[symbol] = addr;
    }
  }

  function getSymbols() public view returns (string[] memory) {
    return symbols;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Represents the various states during an order's lifecycle.
 * @dev Untriggered = EOA has deposited erc20 into the flyweight contract & is ready to swap
 * @dev Pending deposit = EOA has created the order without a deposit yet.
 * @dev Executed = Swap has executed and resulting erc20 has been sent to order owner
 * @dev Cancelled = EOA has cancelled the order and the deposited erc20 (if any) has been returned to them
 */
enum OrderState {
  UNTRIGGERED,
  PENDING_DEPOSIT,
  EXECUTED,
  CANCELLED
}

/// Price direction for an orders' trigger condition
enum OrderTriggerDirection {
  BELOW,
  EQUAL,
  ABOVE
}

/// An EOA order
struct Order {
  uint id;
  address owner;
  OrderState orderState;
  string tokenIn;
  string tokenOut;
  string tokenInTriggerPrice;
  OrderTriggerDirection direction;
  uint tokenInAmount;
  uint blockNumber;
}

/// Represents a token price fetched from the Flyweight oracle
struct NewPriceItem {
  string symbol;
  string price;
}

/**
 * Represents an EOA order deposit
 * @dev This is an on-chain erc20 transaction from the EOA to the Flyweight smart contract
 */
struct NewDepositTx {
  uint orderId;
  bytes32 txHash;
}