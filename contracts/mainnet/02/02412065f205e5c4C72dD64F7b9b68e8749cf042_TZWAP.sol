// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
*                                                                                  
..................................................................            
.                                                                .            
.  ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::  .            
.  ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::  .            
.  ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::  .            
.  ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::  .            
.  ::::::::::::::::::::--:.......:-==--:...::==::::::::::::::::  .            
.  ::::::::::::::::::--.    .:::.:--+=::::::--::-::::::::::::::  .            
.  :::::::::::::::::+:    ::.    .:--+=-===:..:--=-::::::::::::  .            
.  :::::::::::::::--     ..     .:-----=--. .:-=-:---::::::::::  .            
.  ::::::::::::::-.      .-::::.:+=====-=::---===--.:-:::::::::  .            
.  :::::::::::::-.   ...:...::::==+===::+=:-:::===:-=-==-::::::  .            
.  ::::::::::::=:.  :..:    ...---=-:::--=-:-=--::..:---+-:::::  .            
.  :::::::::::=:.. .::---...#+*@%%@-...:-==--=+*@@#-.:-=+::::::  .            
.  ::::::::::--..........::-%%#@=.%#    --=--:@[email protected]#.+.   +::::::  .            
.  ::::::::::=..........:--:.-=*#%@=   ..=-=:[email protected]#%@%%:.:-=::::::  .            
.  :::::::::-+=--:...:-:....-=========--:-=+**+:....::=-:::::::  .            
.  ::::::::--+==-:::-:..:::::------::--:..:::.-:.  ::::=-::::::  .            
.  ::::::::= ---. .:::..::::::--:-==--:::--:... ..     :+=:::::  .            
.  :::::::-: .:-:.:=++=-:::::::--=---------:.. ... .:--:*#-::::  .            
.  ::::::-=..  ::..-----=-::::---:--=---==--:..:. :---=*#=:::::  .            
.  :::::-: -   ....::.   .:::::=*####*****++====--++*##%-::::::  .            
.  ::::-.   :::....:.     .::::::+######################+::::::  .            
.  :::-.    .------:::::::::======+####################+:::::::  .            
.  ::-#=.     --++=-:=:::::-======++++*****+++++++=--:=::::::::  .            
.  ::#@@@%+:  ::  .-==-----*====::--:::-::   .:.:...:-=::::::::  .            
.  :[email protected]@@@@@@@#-   --:...--++=-+....:..-*=-....:-::::-%@%+::::::  .            
.  :%@@@@@@@@@:::...:-=+-:. .--::-::..:+=:.  :==-.:: @@@@@*-:::  .            
.  [email protected]@@@@@@@@+. .:..---:...:=:*@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@+::  .            
.  %@@@@@@@@@:..  .::::--:..:%@@@@@@@@@@@@@@@@@@@@@@#@@@@@@@@#-  .            
.  @@@@@@@@%-      .:::.:=#@=:%@@@#-.  -=:-=+*%@@@@@@@@@@@@@@@@  .            
.  @@@@@@@@@..        :#@@@@@%-:[email protected]@.   ..  =-+%@@@@@@@@@@@@@@@@. .            
.  @@@@@@@@@%:...     :@@@@@@@@@@@@@=  :.:%@@@@@@@@@@@@@@@@@@@@. .            
.  @@@@@@@@@@@%+-:-*#@@@@@@@@@@@@@@#-  .. [email protected]@@@@@@@@@@@@@@@@@@@. .            
.  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%. :. #@@@@@@@@@@@@@@@@@@@@. .            
.                                                                .            
..................................................................            

            ████████╗███████╗██╗    ██╗ █████╗ ██████╗ 
            ╚══██╔══╝╚══███╔╝██║    ██║██╔══██╗██╔══██╗
              ██║     ███╔╝ ██║ █╗ ██║███████║██████╔╝
              ██║    ███╔╝  ██║███╗██║██╔══██║██╔═══╝ 
              ██║   ███████╗╚███╔███╔╝██║  ██║██║     
              ╚═╝   ╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝     
                                                      
                TZWAP: On-chain TWAP Service
*/
import {Pausable} from '@openzeppelin/contracts/security/Pausable.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {I1inchAggregationRouterV4} from './interfaces/I1inchAggregationRouterV4.sol';
import {IChainlinkOracle} from './interfaces/IChainlinkOracle.sol';
import {ICustomPriceOracle} from './interfaces/ICustomPriceOracle.sol';
import {IWETH9} from './interfaces/IWETH9.sol';
import {IERC20} from'./interfaces/IERC20.sol';
import {ISafeERC20} from './interfaces/ISafeERC20.sol';


contract TZWAP is Ownable, Pausable {

  using ISafeERC20 for IERC20;

  I1inchAggregationRouterV4 public aggregationRouterV4;
  IWETH9 public weth;

  // Min TWAP interval in seconds
  uint public minInterval = 60;

  // Min number of intervals for a TWAP order
  uint public minNumOfIntervals = 3;

  // Precision for all % math
  uint public percentagePrecision =  10 ** 5;

  // Auto-incrementing of orders
  uint public orderCount;
  // TWAP orders mapped to auto-incrementing ID
  mapping (uint => TWAPOrder) public orders;
  // IDs of TWAP orders for a certain user address
  mapping (address => uint[]) public userOrders;
  // Fills for TWAP orders
  mapping (uint => Fill[]) public fills;
  // Token addresses mapped to oracles
  mapping (address => Oracle) public oracles;
  // Whitelisted addresses who can interact with fillOrder
  mapping (address => bool) public whitelist;

  // If true only whitelisted addresses can interact with fillOrder
  bool public isWhitelistActive;

  struct Oracle {
    // Address of oracle
    address oracleAddress;
    // Toggled to false if oracle is not chainlink
    bool isChainlink;
  }

  struct TWAPOrder {
    // Order creator
    address creator;
    // Token to swap from
    address srcToken;
    // Token to swap to
    address dstToken;
    // How often a swap should be made
    uint interval;
    // srcToken to swap per interval
    uint tickSize;
    // Total srcToken to swap
    uint total;
    // Min fees in % to be paid per swap interval
    uint minFees;
    // Max fees in % to be paid per swap interval
    uint maxFees;
    // Creation timestamp
    uint created;
    // Toggled to true when an order is killed
    bool killed;
  }
  
  struct Fill {
    // Address that called fill
    address filler;
    // Amount of ticks filled
    uint ticksFilled;
    // Amount of srcToken spent
    uint srcTokensSwapped;
    // Amount of dstToken received
    uint dstTokensReceived;
    // Fees collected
    uint fees;
    // Time of last fill
    uint timestamp;
  }

  // 1inch swaps structs

  struct swapParams {
    address caller;
    I1inchAggregationRouterV4.SwapDescription desc;
    bytes data;
  }

  struct unoswapParams {
    address srcToken;
    uint256 amount;
    uint256 minReturn;
    bytes32[] pools;
  }

  struct uniswapV3Params {
    uint256 amount;
    uint256 minReturn;
    uint256[] pools;
  }

  event LogNewOrder(uint id);
  event LogNewFill(uint id, uint fillIndex);
  event LogOrderKilled(uint id);

  constructor(
    address payable _aggregationRouterV4Address,
    address payable _wethAddress
  ) {
    aggregationRouterV4 = I1inchAggregationRouterV4(_aggregationRouterV4Address);
    weth = IWETH9(_wethAddress);
    isWhitelistActive = true;
  }

  receive() external payable {}

  /**
  * Creates a new TWAP order
  * @param order Order params
  * @return Whether order was created
  */
  function newOrder(
    TWAPOrder memory order
  )
  payable
  public
  whenNotPaused
  returns (bool) {
    require(order.srcToken != address(0), "Invalid srcToken address");
    require(order.dstToken != address(0), "Invalid dstToken address");
    require(order.interval >= minInterval, "Invalid interval");
    require(order.tickSize > 0, "Invalid tickSize");
    require(order.total > order.tickSize && order.total % order.tickSize == 0, "Invalid total");
    require(order.total / order.tickSize > minNumOfIntervals, "Number of intervals is too less");
    order.creator = msg.sender;
    order.created = block.timestamp;
    order.killed = false;

    if (order.srcToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
      require(msg.value == order.total, "Invalid msg value");
      weth.deposit{value: msg.value}();
      order.srcToken = address(weth);
    }
    else {
      require(IERC20(order.srcToken).transferFrom(msg.sender, address(this), order.total));
    }

    require(oracles[order.srcToken].oracleAddress != address(0) && oracles[order.dstToken].oracleAddress != address(0), "Oracle is missing");

    orders[orderCount++] = order;
    userOrders[msg.sender].push(orderCount - 1);
    emit LogNewOrder(orderCount - 1);

    return true;
  }

  /**
  * Fills an active order
  * @param id Order ID
  * @param swapType 0: swap() 1: unoswap() 2: uniswapV3SwapTo()
  * @param _swapParams Default 1inch swap
  * @param _unoswapParams 1inch swap through only sushi or uni v2
  * @param _uniswapV3Params 1inch swap through only uni v3
  * @return Whether order was filled
  */
  function fillOrder(
    uint id,
    uint swapType,
    swapParams calldata _swapParams,
    unoswapParams calldata _unoswapParams,
    uniswapV3Params calldata _uniswapV3Params
  )
  public
  whenNotPaused
  returns (uint) {
    if (isWhitelistActive)
      require(whitelist[msg.sender] == true, "Not whitelisted");

    require(orders[id].created != 0, "Invalid order");
    require(!orders[id].killed, "Order was killed");
    require(getSrcTokensSwappedForOrder(id) < orders[id].total, "Order is already filled");

    uint ticksToFill = getTicksToFill(id);

    require(ticksToFill > 0, "Interval must pass before next fill");

    fills[id].push(
      Fill({
        filler: msg.sender, 
        ticksFilled: ticksToFill, 
        srcTokensSwapped: 0, // Update after swap
        dstTokensReceived: 0, // Update after swap
        fees: 0, // Update after swap
        timestamp: block.timestamp
      })
    );

    uint preSwapSrcTokenBalance = IERC20(orders[id].srcToken).balanceOf(address(this));
    uint preSwapDstTokenBalance = IERC20(orders[id].dstToken).balanceOf(address(this));

    if (IERC20(orders[id].srcToken).allowance(address(this), address(aggregationRouterV4)) == 0)
      IERC20(orders[id].srcToken).safeIncreaseAllowance(address(aggregationRouterV4), 2**256 - 1);

    if (swapType == 0) aggregationRouterV4.swap(_swapParams.caller, _swapParams.desc, _swapParams.data);
    else if (swapType == 1) aggregationRouterV4.unoswap(_unoswapParams.srcToken, _unoswapParams.amount, _unoswapParams.minReturn, _unoswapParams.pools);
    else aggregationRouterV4.uniswapV3Swap(_uniswapV3Params.amount, _uniswapV3Params.minReturn, _uniswapV3Params.pools);

    uint256 srcTokensSwapped = preSwapSrcTokenBalance - IERC20(orders[id].srcToken).balanceOf(address(this));
    uint256 dstTokensReceived = IERC20(orders[id].dstToken).balanceOf(address(this)) - preSwapDstTokenBalance;

    _ensureSwapValidityAndUpdate(id, srcTokensSwapped, dstTokensReceived);

    require(srcTokensSwapped == ticksToFill * orders[id].tickSize, "Invalid amount");
    require(getSrcTokensSwappedForOrder(id) <= orders[id].total, "Overbought");

    _setFeesAndDistribute(id);

    emit LogNewFill(id, fills[id].length - 1);

    return fills[id][fills[id].length - 1].fees;
  }

  /**
  * Execute post-swap checks and updates
  */
  function _ensureSwapValidityAndUpdate(
    uint id,
    uint256 srcTokensSwapped,
    uint256 dstTokensReceived
  )
  internal {
    // Estimate amount to receive using oracles
    uint srcTokenPriceInUsd;
    uint dstTokenPriceInUsd;

    if (oracles[orders[id].srcToken].isChainlink)
      srcTokenPriceInUsd = uint(IChainlinkOracle(oracles[orders[id].srcToken].oracleAddress).latestAnswer());
    else
      srcTokenPriceInUsd = ICustomPriceOracle(oracles[orders[id].srcToken].oracleAddress).getPriceInUSD();

    if (oracles[orders[id].dstToken].isChainlink)
      dstTokenPriceInUsd = uint(IChainlinkOracle(oracles[orders[id].dstToken].oracleAddress).latestAnswer());
    else
      dstTokenPriceInUsd = ICustomPriceOracle(oracles[orders[id].dstToken].oracleAddress).getPriceInUSD();

    // 10% max slippage
    uint srcTokenDecimals = IERC20(orders[id].srcToken).decimals();
    uint dstTokenDecimals = IERC20(orders[id].dstToken).decimals();
    uint minDstTokenReceived = (900 * srcTokensSwapped * srcTokenPriceInUsd * (10 ** dstTokenDecimals)) / (1000 * dstTokenPriceInUsd * (10 ** srcTokenDecimals));

    require(dstTokensReceived > minDstTokenReceived, "Tokens received are not enough");

    fills[id][fills[id].length - 1].srcTokensSwapped = srcTokensSwapped;
    fills[id][fills[id].length - 1].dstTokensReceived = dstTokensReceived;
  }

  /**
  * Set fees and distribute
  */
  function _setFeesAndDistribute(
    uint id
  )
  internal {
    uint timeElapsed = getTimeElapsedSinceLastFill(id);

    uint timeElapsedSinceCallable;

    if (fills[id].length > 1)
      timeElapsedSinceCallable = timeElapsed - orders[id].interval;
    else
      timeElapsedSinceCallable = timeElapsed;

    uint minFeesAmount = (fills[id][fills[id].length - 1].dstTokensReceived / fills[id][fills[id].length - 1].ticksFilled) * orders[id].minFees / percentagePrecision;
    uint maxFeesAmount = (fills[id][fills[id].length - 1].dstTokensReceived / fills[id][fills[id].length - 1].ticksFilled) * orders[id].maxFees / percentagePrecision;

    fills[id][fills[id].length - 1].fees = Math.min(maxFeesAmount, minFeesAmount * ((1000 + timeElapsedSinceCallable / 6) / 1000));
    // minFees + 0.1% every 6 secs

    IERC20(orders[id].dstToken).safeTransfer(
      msg.sender,
      fills[id][fills[id].length - 1].fees
    );

    IERC20(orders[id].dstToken).safeTransfer(
      orders[id].creator,
      fills[id][fills[id].length - 1].dstTokensReceived - fills[id][fills[id].length - 1].fees
    );
  }


  /**
  * Kills an active order
  * @param id Order ID
  * @return Whether order was killed
  */
  function killOrder(
    uint id
  )
  public
  whenNotPaused
  returns (bool) {
    require(msg.sender == orders[id].creator, "Invalid sender");
    require(!orders[id].killed, "Order already killed");
    orders[id].killed = true;
    IERC20(orders[id].srcToken).safeTransfer(
      orders[id].creator, 
      orders[id].total - getSrcTokensSwappedForOrder(id)
    );
    emit LogOrderKilled(id);
    return true;
  }

  /**
  * Returns total DST tokens received for an order
  * @param id Order ID
  * @return Total DST tokens received for an order
  */
  function getDstTokensReceivedForOrder(uint id)
  public
  view
  returns (uint) {
    require(orders[id].created != 0, "Invalid order");
    uint dstTokensReceived = 0;
    for (uint i = 0; i < fills[id].length; i++) 
      dstTokensReceived += fills[id][i].dstTokensReceived;
    return dstTokensReceived;
  }

  /**
  * Returns seconds passed since last fill
  * @param id Order ID
  * @return number of seconds
  */
  function getTimeElapsedSinceLastFill(uint id)
  public
  view
  returns (uint) {
    uint timeElapsed;

    if (fills[id].length > 0) {
      timeElapsed = block.timestamp - fills[id][fills[id].length - 1].timestamp;
    } else
      timeElapsed = block.timestamp - orders[id].created;

    return timeElapsed;
  }

  /**
  * Returns total SRC tokens received for an order
  * @param id Order ID
  * @return Total SRC tokens received for an order
  */
  function getSrcTokensSwappedForOrder(uint id)
  public
  view
  returns (uint) {
    require(orders[id].created != 0, "Invalid order");
    uint srcTokensSwapped = 0;
    for (uint i = 0; i < fills[id].length; i++) 
      srcTokensSwapped += fills[id][i].srcTokensSwapped;
    return srcTokensSwapped;
  }

  /**
  * Returns total number of ticks filled of a certain order
  * @param id Order ID
  * @return number of ticks filled
  */
  function getTicksFilled(uint id)
  public
  view
  returns (uint) {
    require(orders[id].created != 0, "Invalid order");
    uint ticksFilled = 0;
    for (uint i = 0; i < fills[id].length; i++)
      ticksFilled += fills[id][i].ticksFilled;
    return ticksFilled;
  }

  /**
  * Get the number of ticks that is possible to fill
  * @param id Order ID
  * @return number of ticks that can be filled
  */
  function getTicksToFill(uint id)
  public view
  returns (uint) {
    uint timeElapsed = getTimeElapsedSinceLastFill(id);

    uint ticksToFill = timeElapsed / orders[id].interval;
    uint ticksFilled = getTicksFilled(id);
    uint maxTicksFillable = (orders[id].total / orders[id].tickSize) - ticksFilled;

    if (ticksToFill >= maxTicksFillable) return maxTicksFillable;
    else return ticksToFill;
  }

  /**
  * Get the required amount of token that is possible to swap
  * @param id Order ID
  * @return amount of srcToken that can be swapped
  */
  function getSrcTokensToSwap(uint id)
  public view
  returns (uint) {
    return getTicksToFill(id) * orders[id].tickSize;
  }

  /**
  * Returns whether an order is active
  * @param id Order ID
  * @return Whether order is active
  */
  function isOrderActive(uint id) 
  public
  view
  returns (bool) {
    return orders[id].created != 0 && 
      !orders[id].killed && 
      getSrcTokensSwappedForOrder(id) < orders[id].total;
  }

  function addOracle(address token, Oracle memory oracle)
  public
  onlyOwner
  {
    // This is required to make it impossible to exploit 1inch params even for contract owner
    require(oracles[token].oracleAddress == address(0), "Oracles cannot be updated");

    oracles[token] = oracle;
  }

  function toggleWhitelist(bool value)
  public
  onlyOwner
  {
    isWhitelistActive = value;
  }

  function addToWhitelist(address authorized)
  public
  onlyOwner
  {
    whitelist[authorized] = true;
  }

  function removeFromWhitelist(address authorized)
  public
  onlyOwner
  {
    whitelist[authorized] = false;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

interface I1inchAggregationRouterV4 {
  struct SwapDescription {
    address srcToken;
    address dstToken;
    address srcReceiver;
    address dstReceiver;
    uint256 amount;
    uint256 minReturnAmount;
    uint256 flags;
    bytes permit;
  }

  event OrderFilledRFQ(bytes32 orderHash,uint256 makingAmount) ;

  event OwnershipTransferred(address indexed previousOwner,address indexed newOwner) ;

  event Swapped(address sender,address srcToken,address dstToken,address dstReceiver,uint256 spentAmount,uint256 returnAmount) ;

  function DOMAIN_SEPARATOR() external view returns (bytes32) ;

  function LIMIT_ORDER_RFQ_TYPEHASH() external view returns (bytes32) ;

  function cancelOrderRFQ(uint256 orderInfo) external;

  function destroy() external;

  function fillOrderRFQ(LimitOrderProtocolRFQ.OrderRFQ memory order,bytes memory signature,uint256 makingAmount,uint256 takingAmount) external payable returns (uint256 , uint256) ;

  function fillOrderRFQTo(LimitOrderProtocolRFQ.OrderRFQ memory order,bytes memory signature,uint256 makingAmount,uint256 takingAmount,address target) external payable returns (uint256 , uint256) ;

  function fillOrderRFQToWithPermit(LimitOrderProtocolRFQ.OrderRFQ memory order,bytes memory signature,uint256 makingAmount,uint256 takingAmount,address target,bytes memory permit) external  returns (uint256 , uint256) ;

  function invalidatorForOrderRFQ(address maker,uint256 slot) external view returns (uint256) ;

  function owner() external view returns (address) ;

  function renounceOwnership() external;

  function rescueFunds(address token,uint256 amount) external;

  function swap(address caller,SwapDescription memory desc,bytes memory data) external payable returns (uint256 returnAmount, uint256 gasLeft);

  function transferOwnership(address newOwner) external;

  function uniswapV3Swap(uint256 amount,uint256 minReturn,uint256[] memory pools) external payable returns (uint256 returnAmount) ;

  function uniswapV3SwapCallback(int256 amount0Delta,int256 amount1Delta,bytes memory ) external;

  function uniswapV3SwapTo(address recipient,uint256 amount,uint256 minReturn,uint256[] memory pools) external payable returns (uint256 returnAmount) ;

  function uniswapV3SwapToWithPermit(address recipient,address srcToken,uint256 amount,uint256 minReturn,uint256[] memory pools,bytes memory permit) external  returns (uint256 returnAmount) ;

  function unoswap(address srcToken,uint256 amount,uint256 minReturn,bytes32[] memory pools) external payable returns (uint256 returnAmount) ;

  function unoswapWithPermit(address srcToken,uint256 amount,uint256 minReturn,bytes32[] memory pools,bytes memory permit) external  returns (uint256 returnAmount) ;

  receive () external payable;
}

interface LimitOrderProtocolRFQ {
  struct OrderRFQ {
    uint256 info;
    address makerAsset;
    address takerAsset;
    address maker;
    address allowedSender;
    uint256 makingAmount;
    uint256 takingAmount;
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.7.0 <0.9.0;

interface IChainlinkOracle {
    function latestAnswer() external view returns (int256);
}

// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.7.0 <0.9.0;

interface ICustomPriceOracle {
    function getPriceInUSD() external returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.7.0 <0.9.0;

interface IWETH9 {
    function deposit() external payable;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the decimals.
     */
    function decimals() external view returns (uint256);

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
// OpenZeppelin Contracts v4.4.1

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IAddress.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library ISafeERC20 {
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
// OpenZeppelin Contracts (last updated v4.5.0)

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