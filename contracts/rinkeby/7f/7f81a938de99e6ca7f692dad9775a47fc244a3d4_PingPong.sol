// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../interfaces/applications/Any2EVMMessageReceiverInterface.sol";
import "../interfaces/onRamp/EVM2AnySubscriptionOnRampRouterInterface.sol";

contract PingPong is Any2EVMMessageReceiverInterface, OwnerIsCreator {
  error InvalidDeliverer(address deliverer);
  event Ping(uint256 pingPongs);
  event Pong(uint256 pingPongs);

  Any2EVMOffRampRouterInterface internal s_receivingRouter;
  EVM2AnySubscriptionOnRampRouterInterface internal s_sendingRouter;

  // The chain ID of the counterpart ping pong application
  uint256 public s_pongChainId;
  // The contract address of the counterpart ping pong application
  address public s_pongAddress;

  // Indicates whether receiving a ping pong request should send one back
  bool public s_isPaused;

  constructor(Any2EVMOffRampRouterInterface receivingRouter, EVM2AnySubscriptionOnRampRouterInterface sendingRouter) {
    s_receivingRouter = receivingRouter;
    s_sendingRouter = sendingRouter;
    s_isPaused = false;
  }

  function setCounterPart(uint256 pongChainId, address pongAddress) public onlyOwner {
    s_pongChainId = pongChainId;
    s_pongAddress = pongAddress;
  }

  function startPingPong() public onlyOwner {
    s_isPaused = false;
    returnMessage(1);
  }

  function returnMessage(uint256 pingPongNumber) private {
    bytes memory data = abi.encode(pingPongNumber);
    CCIP.EVM2AnySubscriptionMessage memory message = CCIP.EVM2AnySubscriptionMessage({
      receiver: s_pongAddress,
      data: data,
      tokens: new IERC20[](0),
      amounts: new uint256[](0),
      gasLimit: 2e5
    });
    s_sendingRouter.ccipSend(s_pongChainId, message);
    emit Ping(pingPongNumber);
  }

  /**
   * @notice Called by the OffRamp, this function receives a message and forwards
   * the tokens sent with it to the designated EOA
   * @param message CCIP Message
   */
  function ccipReceive(CCIP.Any2EVMMessage memory message) external override onlyRouter {
    uint256 pingPongNumber = abi.decode(message.data, (uint256));
    emit Pong(pingPongNumber);
    if (!s_isPaused) {
      returnMessage(pingPongNumber + 1);
    }
  }

  function setRouters(
    Any2EVMOffRampRouterInterface receivingRouter,
    EVM2AnySubscriptionOnRampRouterInterface sendingRouter
  ) public {
    s_receivingRouter = receivingRouter;
    s_sendingRouter = sendingRouter;
  }

  function getRouters() public view returns (Any2EVMOffRampRouterInterface, EVM2AnySubscriptionOnRampRouterInterface) {
    return (s_receivingRouter, s_sendingRouter);
  }

  function getSubscriptionManager() external view returns (address) {
    return owner();
  }

  function setPaused(bool isPaused) external {
    s_isPaused = isPaused;
  }

  /**
   * @dev only calls from the set router are accepted.
   */
  modifier onlyRouter() {
    if (msg.sender != address(s_receivingRouter)) revert InvalidDeliverer(msg.sender);
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../models/Models.sol";
import "../subscription/SubscriptionManagerInterface.sol";

interface Any2EVMMessageReceiverInterface is SubscriptionManagerInterface {
  function ccipReceive(CCIP.Any2EVMMessage calldata message) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../models/Models.sol";
import "./BaseOnRampRouterInterface.sol";
import "./EVM2EVMSubscriptionOnRampInterface.sol";

interface EVM2AnySubscriptionOnRampRouterInterface is BaseOnRampRouterInterface {
  error OnRampAlreadySet(uint256 chainId, EVM2EVMSubscriptionOnRampInterface onRamp);
  error FundingTooLow(address sender);
  error OnlyCallableByFeeAdmin();

  event OnRampSet(uint256 indexed chainId, EVM2EVMSubscriptionOnRampInterface indexed onRamp);
  event FeeSet(uint96);
  event SubscriptionFunded(address indexed sender, uint256 amount);
  event SubscriptionUnfunded(address indexed sender, uint256 amount);

  struct RouterConfig {
    uint96 fee;
    IERC20 feeToken;
    address feeAdmin;
  }

  function ccipSend(uint256 destinationChainId, CCIP.EVM2AnySubscriptionMessage memory message)
    external
    returns (uint64);

  function setOnRamp(uint256 chainId, EVM2EVMSubscriptionOnRampInterface onRamp) external;

  function getOnRamp(uint256 chainId) external view returns (EVM2EVMSubscriptionOnRampInterface);

  function setFee(uint96 newFee) external;

  function getFee() external returns (uint96);

  function fundSubscription(uint256 amount) external;

  function unfundSubscription(uint256 amount) external;

  function getBalance(address sender) external returns (uint256 balance);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../vendor/IERC20.sol";
import "../pools/TokenPool.sol";

library CCIP {
  bytes32 public constant LEAF_DOMAIN_SEPARATOR = 0x0000000000000000000000000000000000000000000000000000000000000000;
  bytes32 public constant INTERNAL_DOMAIN_SEPARATOR =
    0x0000000000000000000000000000000000000000000000000000000000000001;

  struct Any2EVMMessageFromSender {
    uint256 sourceChainId;
    bytes sender;
    address receiver;
    bytes data;
    IERC20[] destTokens;
    PoolInterface[] destPools;
    uint256[] amounts;
    uint256 gasLimit;
  }

  struct Any2EVMMessage {
    uint256 sourceChainId;
    bytes sender;
    bytes data;
    IERC20[] destTokens;
    uint256[] amounts;
  }

  function _toAny2EVMMessage(CCIP.Any2EVMMessageFromSender memory original)
    internal
    pure
    returns (CCIP.Any2EVMMessage memory message)
  {
    message = CCIP.Any2EVMMessage({
      sourceChainId: original.sourceChainId,
      sender: abi.encode(original.sender),
      data: original.data,
      destTokens: original.destTokens,
      amounts: original.amounts
    });
  }

  struct Interval {
    uint64 min;
    uint64 max;
  }

  struct RelayReport {
    address[] onRamps;
    Interval[] intervals;
    bytes32[] merkleRoots;
    bytes32 rootOfRoots;
  }

  struct ExecutionReport {
    uint64[] sequenceNumbers;
    address[] tokenPerFeeCoinAddresses;
    uint256[] tokenPerFeeCoin;
    bytes[] encodedMessages;
    bytes32[] innerProofs;
    uint256 innerProofFlagBits;
    bytes32[] outerProofs;
    uint256 outerProofFlagBits;
  }

  enum MessageExecutionState {
    UNTOUCHED,
    IN_PROGRESS,
    SUCCESS,
    FAILURE
  }

  struct ExecutionResult {
    uint64 sequenceNumber;
    MessageExecutionState state;
  }

  struct EVM2AnyTollMessage {
    address receiver;
    bytes data;
    IERC20[] tokens;
    uint256[] amounts;
    IERC20 feeToken;
    uint256 feeTokenAmount;
    uint256 gasLimit;
  }

  struct EVM2EVMTollMessage {
    uint256 sourceChainId;
    uint64 sequenceNumber;
    address sender;
    address receiver;
    bytes data;
    IERC20[] tokens;
    uint256[] amounts;
    IERC20 feeToken;
    uint256 feeTokenAmount;
    uint256 gasLimit;
  }

  function addToTokensAmounts(
    IERC20[] memory tokens,
    uint256[] memory amounts,
    IERC20 token,
    uint256 amount
  ) internal pure returns (IERC20[] memory, uint256[] memory) {
    for (uint256 i = 0; i < tokens.length; ++i) {
      if (tokens[i] == token) {
        amounts[i] += amount;
        return (tokens, amounts);
      }
    }
    IERC20[] memory newTokens = new IERC20[](tokens.length + 1);
    uint256[] memory newAmounts = new uint256[](amounts.length + 1);
    for (uint256 i = 0; i < tokens.length; ++i) {
      newTokens[i] = tokens[i];
      newAmounts[i] = amounts[i];
    }
    newTokens[tokens.length] = token;
    newAmounts[amounts.length] = amount;
    return (newTokens, newAmounts);
  }

  bytes32 internal constant EVM_2_EVM_TOLL_MESSAGE_HASH = keccak256("EVM2EVMTollMessagePlus");

  function _hash(CCIP.EVM2EVMTollMessage memory original, bytes32 metadataHash) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encode(
          LEAF_DOMAIN_SEPARATOR,
          metadataHash,
          original.sequenceNumber,
          original.sender,
          original.receiver,
          keccak256(original.data),
          keccak256(abi.encode(original.tokens)),
          keccak256(abi.encode(original.amounts)),
          original.gasLimit,
          original.feeToken,
          original.feeTokenAmount
        )
      );
  }

  struct EVM2AnySubscriptionMessage {
    address receiver;
    bytes data;
    IERC20[] tokens;
    uint256[] amounts;
    uint256 gasLimit;
  }

  struct EVM2EVMSubscriptionMessage {
    uint256 sourceChainId;
    uint64 sequenceNumber;
    address sender;
    address receiver;
    uint64 nonce;
    bytes data;
    IERC20[] tokens;
    uint256[] amounts;
    uint256 gasLimit;
  }

  bytes32 internal constant EVM_2_EVM_SUBSCRIPTION_MESSAGE_HASH = keccak256("EVM2EVMSubscriptionMessagePlus");

  function _hash(CCIP.EVM2EVMSubscriptionMessage memory original, bytes32 metadataHash)
    internal
    pure
    returns (bytes32)
  {
    return
      keccak256(
        abi.encode(
          LEAF_DOMAIN_SEPARATOR,
          metadataHash,
          original.sequenceNumber,
          original.sender,
          original.receiver,
          keccak256(original.data),
          keccak256(abi.encode(original.tokens)),
          keccak256(abi.encode(original.amounts)),
          original.gasLimit,
          original.nonce
        )
      );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface SubscriptionManagerInterface {
  function getSubscriptionManager() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface BaseOnRampRouterInterface {
  error UnsupportedDestinationChain(uint256 destinationChainId);

  function isChainSupported(uint256 chainId) external view returns (bool supported);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../models/Models.sol";
import "./BaseOnRampInterface.sol";

interface EVM2EVMSubscriptionOnRampInterface is BaseOnRampInterface {
  event CCIPSendRequested(CCIP.EVM2EVMSubscriptionMessage message);

  function forwardFromRouter(CCIP.EVM2AnySubscriptionMessage memory message, address originalSender)
    external
    returns (uint64);
}

// SPDX-License-Identifier: MIT

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
pragma solidity 0.8.15;

import "../../vendor/SafeERC20.sol";
import "../../vendor/Pausable.sol";
import "../access/OwnerIsCreator.sol";
import "../onRamp/BaseOnRamp.sol";
import "../interfaces/onRamp/BaseOnRampInterface.sol";
import "../interfaces/offRamp/BaseOffRampInterface.sol";

/**
 * @notice Base abstract class with common functions for all token pools
 */
abstract contract TokenPool is PoolInterface, OwnerIsCreator, Pausable {
  IERC20 internal immutable i_token;
  mapping(BaseOnRampInterface => bool) internal s_onRamps;
  mapping(BaseOffRampInterface => bool) internal s_offRamps;

  constructor(IERC20 token) {
    i_token = token;
  }

  /**
   * @notice Pause the pool
   * @dev Only callable by the owner
   */
  function pause() external override onlyOwner {
    _pause();
  }

  /**
   * @notice Unpause the pool
   * @dev Only callable by the owner
   */
  function unpause() external override onlyOwner {
    _unpause();
  }

  /**
   * @notice Set an onRamp's permissions
   * @dev Only callable by the owner
   * @param onRamp The onRamp
   * @param permission Whether or not the onRamp has onRamp permissions on this contract
   */
  function setOnRamp(BaseOnRampInterface onRamp, bool permission) public onlyOwner {
    s_onRamps[onRamp] = permission;
  }

  /**
   * @notice Set an offRamp's permissions
   * @dev Only callable by the owner
   * @param offRamp The offRamp
   * @param permission Whether or not the offRamp has offRamp permissions on this contract
   */
  function setOffRamp(BaseOffRampInterface offRamp, bool permission) public onlyOwner {
    s_offRamps[offRamp] = permission;
  }

  /**
   * @notice Checks whether something is a permissioned onRamp on this contract
   * @return boolean
   */
  function isOnRamp(BaseOnRampInterface onRamp) public view returns (bool) {
    return s_onRamps[onRamp];
  }

  /**
   * @notice Checks whether something is a permissioned offRamp on this contract
   * @return boolean
   */
  function isOffRamp(BaseOffRampInterface offRamp) public view returns (bool) {
    return s_offRamps[offRamp];
  }

  /**
   * @notice Gets the underlying token
   * @return token
   */
  function getToken() public view override returns (IERC20 token) {
    return i_token;
  }

  /**
   * @notice Checks whether the msg.sender is either the owner, or a permissioned onRamp on this contract
   * @dev Reverts with a PermissionsError if check fails
   */
  function _validateOwnerOrOnRamp() internal view {
    if (msg.sender != owner() && !isOnRamp(BaseOnRampInterface(msg.sender))) revert PermissionsError();
  }

  /**
   * @notice Checks whether the msg.sender is either the owner, or a permissioned offRamp on this contract
   * @dev Reverts with a PermissionsError if check fails
   */
  function _validateOwnerOrOffRamp() internal view {
    if (msg.sender != owner() && !isOffRamp(BaseOffRampInterface(msg.sender))) revert PermissionsError();
  }

  /**
   * @notice Check permissions and limits of a lock or burn
   */
  modifier assertLockOrBurn() {
    _validateOwnerOrOnRamp();
    _;
  }

  /**
   * @notice Check permissions and limits of a lock or burn
   */
  modifier assertMintOrRelease() {
    _validateOwnerOrOffRamp();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../access/AllowListInterface.sol";
import "../pools/PoolInterface.sol";

interface BaseOnRampInterface is AllowListInterface {
  error MessageTooLarge(uint256 maxSize, uint256 actualSize);
  error UnsupportedNumberOfTokens();
  error UnsupportedToken(IERC20 token);
  error MustBeCalledByRouter();
  error RouterMustSetOriginalSender();
  error RouterNotSet();
  event RouterSet(address router);
  event OnRampConfigSet(OnRampConfig config);

  struct OnRampConfig {
    // Fee for sending message taken in this contract
    uint64 relayingFeeJuels;
    // maximum payload data size
    uint64 maxDataSize;
    // Maximum number of distinct ERC20 tokens that can be sent in a message
    uint64 maxTokensLength;
  }

  /**
   * @notice Get the pool for a specific token
   * @param token token to get the pool for
   * @return pool PoolInterface
   */
  function getTokenPool(IERC20 token) external returns (PoolInterface);

  /**
   * @notice Gets the next sequence number to be used in the onRamp
   * @return the next sequence number to be used
   */
  function getExpectedNextSequenceNumber() external view returns (uint64);

  /**
   * @notice Sets the router to the given router
   * @param router The new router
   */
  function setRouter(address router) external;

  /**
   * @notice Gets the configured router
   * @return The set router
   */
  function getRouter() external view returns (address);

  /**
   * @notice Sets the onRamp config to the given OnRampConfig object
   * @param config The new OnRampConfig
   */
  function setConfig(OnRampConfig calldata config) external;

  /**
   * @notice Gets the current onRamp configuration
   * @return config The current configuration
   */
  function getConfig() external view returns (OnRampConfig memory config);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Address.sol";

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
pragma solidity 0.8.15;

import "../../ConfirmedOwner.sol";

/**
 * @title The OwnerIsCreator contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract OwnerIsCreator is ConfirmedOwner {
  constructor() ConfirmedOwner(msg.sender) {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../pools/TokenPoolRegistry.sol";
import "../health/HealthChecker.sol";
import "../pools/PoolCollector.sol";
import "../access/AllowList.sol";
import "../rateLimiter/AggregateRateLimiter.sol";

contract BaseOnRamp is
  BaseOnRampInterface,
  HealthChecker,
  TokenPoolRegistry,
  PoolCollector,
  AllowList,
  AggregateRateLimiter
{
  // Chain ID of the source chain (where this contract is deployed)
  uint256 public immutable i_chainId;
  // Chain ID of the destination chain (where this contract sends messages)
  uint256 public immutable i_destinationChainId;

  // The last used sequence number. This is zero in the case where no
  // messages has been sent yet. 0 is not a valid sequence number for any
  // real transaction.
  uint64 internal s_sequenceNumber;

  // The current configuration of the onRamp.
  OnRampConfig s_config;
  // The router that is allowed to interact with this onRamp.
  address internal s_router;

  constructor(
    uint256 chainId,
    uint256 destinationChainId,
    IERC20[] memory tokens,
    PoolInterface[] memory pools,
    address[] memory allowlist,
    AFNInterface afn,
    OnRampConfig memory config,
    RateLimiterConfig memory rateLimiterConfig,
    address tokenLimitsAdmin,
    address router
  )
    HealthChecker(afn)
    TokenPoolRegistry(tokens, pools)
    AllowList(allowlist)
    AggregateRateLimiter(rateLimiterConfig, tokenLimitsAdmin)
  {
    // TokenPoolRegistry does a check on tokens.length != pools.length
    i_chainId = chainId;
    i_destinationChainId = destinationChainId;
    s_config = config;
    s_router = router;
    s_sequenceNumber = 0;
  }

  /// @inheritdoc BaseOnRampInterface
  function getTokenPool(IERC20 token) external view override returns (PoolInterface) {
    return getPool(token);
  }

  /// @inheritdoc BaseOnRampInterface
  function getExpectedNextSequenceNumber() external view returns (uint64) {
    return s_sequenceNumber + 1;
  }

  /// @inheritdoc BaseOnRampInterface
  function setRouter(address router) public onlyOwner {
    s_router = router;
    emit RouterSet(router);
  }

  /// @inheritdoc BaseOnRampInterface
  function getRouter() external view returns (address router) {
    return s_router;
  }

  /// @inheritdoc BaseOnRampInterface
  function setConfig(OnRampConfig calldata config) external onlyOwner {
    s_config = config;
    emit OnRampConfigSet(config);
  }

  /// @inheritdoc BaseOnRampInterface
  function getConfig() external view returns (OnRampConfig memory config) {
    return s_config;
  }

  /**
   * @notice Handles common checks and token locking for forwardFromRouter calls.
   * @dev this function is generic over message types, thereby reducing code duplication.
   * @param dataLength The length of the data field of the message
   * @param tokens The tokens to be sent. They will be locked into pools by this function.
   * @param amounts The amounts corresponding to the tokens.
   * @param originalSender The original sender of the message on the router.
   */
  function handleForwardFromRouter(
    uint256 dataLength,
    IERC20[] memory tokens,
    uint256[] memory amounts,
    address originalSender
  ) internal {
    if (s_router == address(0)) revert RouterNotSet();
    if (originalSender == address(0)) revert RouterMustSetOriginalSender();
    // Check that payload is formed correctly
    if (dataLength > uint256(s_config.maxDataSize)) revert MessageTooLarge(uint256(s_config.maxDataSize), dataLength);
    uint256 tokenLength = tokens.length;
    if (tokenLength > uint256(s_config.maxTokensLength) || tokenLength != amounts.length)
      revert UnsupportedNumberOfTokens();

    if (s_allowlistEnabled && !s_allowed[originalSender]) revert SenderNotAllowed(originalSender);

    _removeTokens(tokens, amounts);

    // Lock all tokens in their corresponding pools
    for (uint256 i = 0; i < tokenLength; ++i) {
      IERC20 token = tokens[i];
      PoolInterface pool = getPool(token);
      if (address(pool) == address(0)) revert UnsupportedToken(token);
      pool.lockOrBurn(amounts[i]);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Any2EVMOffRampRouterInterface.sol";
import "../BlobVerifierInterface.sol";
import "../../../vendor/IERC20.sol";

interface BaseOffRampInterface {
  error ZeroAddressNotAllowed();
  error AlreadyExecuted(uint64 sequenceNumber);
  error ExecutionError(bytes error);
  error InvalidSourceChain(uint256 sourceChainId);
  error NoMessagesToExecute();
  error ManualExecutionNotYetEnabled();
  error MessageTooLarge(uint256 maxSize, uint256 actualSize);
  error RouterNotSet();
  error RootNotRelayed();
  error UnsupportedNumberOfTokens(uint64 sequenceNumber);
  error TokenAndAmountMisMatch();
  error UnsupportedToken(IERC20 token);
  error CanOnlySelfCall();
  error ReceiverError();
  error MissingFeeCoinPrice(address feeCoin);
  error InsufficientFeeAmount(uint256 sequenceNumber, uint256 expectedFeeTokens, uint256 feeTokenAmount);
  error IncorrectNonce(uint64 nonce);

  event ExecutionStateChanged(uint64 indexed sequenceNumber, CCIP.MessageExecutionState state);
  event OffRampRouterSet(address indexed router);
  event OffRampConfigSet(OffRampConfig config);

  struct OffRampConfig {
    // On ramp address on the source chain
    address onRampAddress;
    // The waiting time before manual execution is enabled
    uint32 permissionLessExecutionThresholdSeconds;
    // execution delay in seconds
    uint64 executionDelaySeconds;
    // maximum payload data size
    uint64 maxDataSize;
    // Maximum number of distinct ERC20 tokens that can be sent in a message
    uint64 maxTokensLength;
  }

  /**
   * @notice setRouter sets a new router
   * @param router the new Router
   * @dev only the owner should be able to call this function
   */
  function setRouter(Any2EVMOffRampRouterInterface router) external;

  /**
   * @notice get the current router
   * @return Any2EVMOffRampRouterInterface
   */
  function getRouter() external view returns (Any2EVMOffRampRouterInterface);

  /**
   * @notice Execute a series of one or more messages using a merkle proof
   * @param report ExecutionReport
   * @param manualExecution Whether or not it is manual or DON execution
   */
  function execute(CCIP.ExecutionReport memory report, bool manualExecution) external;

  /**
   * @notice Returns the current execution state of a message based on its
   *          sequenceNumber.
   */
  function getExecutionState(uint64 sequenceNumber) external view returns (CCIP.MessageExecutionState);

  /**
   * @notice Returns the current blob verifier.
   */
  function getBlobVerifier() external view returns (BlobVerifierInterface);

  /**
   * @notice Updates the blobVerifier.
   * @param blobVerifier The new blobVerifier
   */
  function setBlobVerifier(BlobVerifierInterface blobVerifier) external;

  /**
   * @notice Returns the current config.
   */
  function getConfig() external view returns (OffRampConfig memory);

  /**
   * @notice Sets a new config.
   */
  function setConfig(OffRampConfig memory config) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AllowListInterface {
  error SenderNotAllowed(address sender);

  event AllowListSet(address[] allowlist);
  event AllowListEnabledSet(bool enabled);

  /**
   * @notice Enables or disabled the allowList functionality.
   * @param enabled Signals whether the allowlist should be enabled.
   */
  function setAllowlistEnabled(bool enabled) external;

  /**
   * @notice Gets whether the allowList functionality is enabled.
   * @return true is enabled, false if not.
   */
  function getAllowlistEnabled() external view returns (bool);

  /**
   * @notice Sets the allowed addresses.
   * @param allowlist The new allowed addresses.
   */
  function setAllowlist(address[] calldata allowlist) external;

  /**
   * @notice Gets the allowed addresses.
   * @return The allowed addresses.
   */
  function getAllowlist() external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../vendor/IERC20.sol";

// Shared public interface for multiple pool types.
// Each pool type handles a different child token model (lock/unlock, mint/burn.)
interface PoolInterface {
  error ExceedsTokenLimit(uint256 currentLimit, uint256 requested);
  error PermissionsError();

  event Locked(address indexed sender, uint256 amount);
  event Burned(address indexed sender, uint256 amount);
  event Released(address indexed sender, address indexed recipient, uint256 amount);
  event Minted(address indexed sender, address indexed recipient, uint256 amount);

  /**
   * @notice Lock or burn the token in the pool
   * @param amount Amount to lock or burn
   */
  function lockOrBurn(uint256 amount) external;

  /**
   * @notice Release or mint tokens fromm the pool to the recipient
   * @param recipient Recipient address
   * @param amount Amount to release or mint
   */
  function releaseOrMint(address recipient, uint256 amount) external;

  function getToken() external view returns (IERC20 pool);

  function pause() external;

  function unpause() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../interfaces/pools/PoolInterface.sol";
import "../access/OwnerIsCreator.sol";

contract TokenPoolRegistry is OwnerIsCreator {
  error InvalidTokenPoolConfig();
  error PoolAlreadyAdded();
  error NoPools();
  error PoolDoesNotExist();
  error TokenPoolMismatch();

  event PoolAdded(IERC20 token, PoolInterface pool);
  event PoolRemoved(IERC20 token, PoolInterface pool);

  struct PoolConfig {
    PoolInterface pool;
    uint96 listIndex;
  }

  // token => token pool
  mapping(IERC20 => PoolConfig) private s_pools;
  // List of tokens
  IERC20[] private s_tokenList;

  /**
   * @notice The `tokens` and `pools` passed to this constructor depend on which chain this contract
   * is being deployed to. Mappings of source token => destination pool is maintained on the destination
   * chain. Therefore, when being deployed as an inheriting OffRamp, `tokens` should represent source chain tokens,
   * `pools` destinations chain pools. When being deployed as an inheriting OnRamp, `tokens` and `pools`
   * should both be source chain.
   */
  constructor(IERC20[] memory tokens, PoolInterface[] memory pools) {
    if (tokens.length != pools.length) revert InvalidTokenPoolConfig();

    // Set new tokens and pools
    s_tokenList = tokens;
    for (uint256 i = 0; i < tokens.length; ++i) {
      PoolInterface pool = pools[i];
      s_pools[tokens[i]] = PoolConfig({pool: pool, listIndex: uint96(i)});
    }
  }

  function addPool(IERC20 token, PoolInterface pool) public onlyOwner {
    if (address(token) == address(0) || address(pool) == address(0)) revert InvalidTokenPoolConfig();
    PoolConfig memory config = s_pools[token];
    // Check if the pool is already set
    if (address(config.pool) != address(0)) revert PoolAlreadyAdded();

    // Set the s_pools with new config values
    config.pool = pool;
    config.listIndex = uint96(s_tokenList.length);
    s_pools[token] = config;

    // Add to the s_tokenList
    s_tokenList.push(token);

    emit PoolAdded(token, pool);
  }

  function removePool(IERC20 token, PoolInterface pool) public onlyOwner {
    // Check that there are any pools to remove
    uint256 listLength = s_tokenList.length;
    if (listLength == 0) revert NoPools();

    PoolConfig memory oldConfig = s_pools[token];
    // Check if the pool exists
    if (address(oldConfig.pool) == address(0)) revert PoolDoesNotExist();
    // Sanity check
    if (address(oldConfig.pool) != address(pool)) revert TokenPoolMismatch();

    // In the list, swap the pool token in question with the last item,
    // Update the index of the item swapped, then pop from the list to remove.

    IERC20 lastItem = s_tokenList[listLength - 1];
    // Perform swap
    s_tokenList[listLength - 1] = s_tokenList[oldConfig.listIndex];
    s_tokenList[oldConfig.listIndex] = lastItem;
    // Update listIndex on moved item
    s_pools[lastItem].listIndex = oldConfig.listIndex;
    // Pop, and delete from mapping
    s_tokenList.pop();
    delete s_pools[token];

    emit PoolRemoved(token, pool);
  }

  /**
   * @notice Get a token pool by its token
   * @param sourceToken token
   * @return Token Pool
   */
  function getPool(IERC20 sourceToken) public view returns (PoolInterface) {
    return s_pools[sourceToken].pool;
  }

  /**
   * @notice Get all configured source tokens
   * @return Array of configured source tokens
   */
  function getPoolTokens() public view returns (IERC20[] memory) {
    return s_tokenList;
  }

  /**
   * @notice Get the destination token from the pool based on a given source token.
   * @param sourceToken The source token
   * @return the destination token
   */
  function getDestinationToken(IERC20 sourceToken) public view returns (IERC20) {
    PoolInterface pool = s_pools[sourceToken].pool;
    if (address(pool) == address(0)) revert PoolDoesNotExist();
    return s_pools[sourceToken].pool.getToken();
  }

  /**
   * @notice Get all configured destination tokens
   * @return tokens Array of configured destination tokens
   */
  function getDestinationTokens() external view returns (IERC20[] memory tokens) {
    tokens = new IERC20[](s_tokenList.length);
    for (uint256 i = 0; i < s_tokenList.length; ++i) {
      tokens[i] = getDestinationToken(s_tokenList[i]);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../../vendor/Pausable.sol";
import "../interfaces/health/AFNInterface.sol";
import "../access/OwnerIsCreator.sol";

contract HealthChecker is Pausable, OwnerIsCreator {
  // AFN contract to check health of the system
  AFNInterface private s_afn;

  error BadAFNSignal();
  error BadHealthConfig();

  event AFNSet(AFNInterface oldAFN, AFNInterface newAFN);

  /**
   * @param afn The AFN contract to check health
   */
  constructor(AFNInterface afn) {
    if (address(afn) == address(0)) revert BadHealthConfig();
    s_afn = afn;
  }

  /**
   * @notice Pause the contract
   * @dev only callable by the owner
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @notice Unpause the contract
   * @dev only callable by the owner
   */
  function unpause() external onlyOwner {
    _unpause();
  }

  /**
   * @notice Change the afn contract to track
   * @dev only callable by the owner
   * @param afn new AFN contract
   */
  function setAFN(AFNInterface afn) external onlyOwner {
    if (address(afn) == address(0)) revert BadHealthConfig();
    AFNInterface old = s_afn;
    s_afn = afn;
    emit AFNSet(old, afn);
  }

  /**
   * @notice Get the current AFN contract
   * @return Current AFN
   */
  function getAFN() external view returns (AFNInterface) {
    return s_afn;
  }

  /**
   * @notice Support querying whether health checker is healthy.
   */
  function isAFNHealthy() external view returns (bool) {
    return !s_afn.badSignalReceived();
  }

  /**
   * @notice Ensure that the AFN has not emitted a bad signal, and that the latest heartbeat is not stale.
   */
  modifier whenHealthy() {
    if (s_afn.badSignalReceived()) revert BadAFNSignal();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../interfaces/onRamp/EVM2EVMTollOnRampInterface.sol";
import "../../vendor/SafeERC20.sol";
import "../access/OwnerIsCreator.sol";

contract PoolCollector is OwnerIsCreator {
  using SafeERC20 for IERC20;

  event FeeCharged(address from, address to, uint256 fee);
  event FeesWithdrawn(IERC20 feeToken, address recipient, uint256 amount);

  error FeeTokenAmountTooLow();

  /**
   * @notice Collect the fee
   * @param onRamp OnRamp to get the fee and pools from
   * @param feeToken the feeToken to be collected
   * @param feeTokenAmount the amount of feeToken that is available
   */
  function _chargeFee(
    EVM2EVMTollOnRampInterface onRamp,
    IERC20 feeToken,
    uint256 feeTokenAmount
  ) internal returns (uint256 fee) {
    // Ensure fee token is valid.
    PoolInterface feeTokenPool = onRamp.getTokenPool(feeToken);
    if (address(feeTokenPool) == address(0)) revert BaseOnRampInterface.UnsupportedToken(feeToken);
    fee = onRamp.getRequiredFee(feeToken);
    address sender = msg.sender;
    if (fee > 0) {
      if (fee > feeTokenAmount) {
        revert FeeTokenAmountTooLow();
      }
      feeTokenAmount -= fee;
      feeToken.safeTransferFrom(sender, address(this), fee);
    }
    if (feeTokenAmount > 0) {
      // Send the fee token to the pool
      feeToken.safeTransferFrom(sender, address(feeTokenPool), feeTokenAmount);
    }
    emit FeeCharged(sender, address(this), fee);
  }

  /**
   * @notice Collect tokens and send them to the pools
   * @param onRamp OnRamp to get the fee and pools from
   * @param tokens the tokens to be collected
   * @param amounts the amounts of the tokens to be collected

   */
  function _collectTokens(
    BaseOnRampInterface onRamp,
    IERC20[] memory tokens,
    uint256[] memory amounts
  ) internal {
    // Send the tokens to the pools
    for (uint256 i = 0; i < tokens.length; ++i) {
      IERC20 token = tokens[i];
      PoolInterface pool = onRamp.getTokenPool(token);
      if (address(pool) == address(0)) revert BaseOnRampInterface.UnsupportedToken(token);
      token.safeTransferFrom(msg.sender, address(pool), amounts[i]);
    }
  }

  /**
   * @notice Withdraw the fee tokens accumulated in this contract
   * @dev only callable by owner
   */
  function withdrawAccumulatedFees(
    IERC20 feeToken,
    address recipient,
    uint256 amount
  ) external onlyOwner {
    feeToken.safeTransfer(recipient, amount);
    emit FeesWithdrawn(feeToken, recipient, amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../interfaces/access/AllowListInterface.sol";
import "../access/OwnerIsCreator.sol";

contract AllowList is AllowListInterface, OwnerIsCreator {
  // Whether the allowlist is enabled
  bool internal s_allowlistEnabled;
  // List of allowed addresses
  address[] internal s_allowList;
  // Addresses that are allowed to send messages
  mapping(address => bool) internal s_allowed;

  constructor(address[] memory allowlist) {
    if (allowlist.length > 0) {
      s_allowlistEnabled = true;
      s_allowList = allowlist;
    }
    for (uint256 i = 0; i < allowlist.length; ++i) {
      s_allowed[allowlist[i]] = true;
    }
  }

  /// @inheritdoc AllowListInterface
  function setAllowlistEnabled(bool enabled) external onlyOwner {
    s_allowlistEnabled = enabled;
    emit AllowListEnabledSet(enabled);
  }

  /// @inheritdoc AllowListInterface
  function getAllowlistEnabled() external view returns (bool) {
    return s_allowlistEnabled;
  }

  /// @inheritdoc AllowListInterface
  function setAllowlist(address[] calldata allowlist) external onlyOwner {
    // Remove existing allowlist
    address[] memory existingList = s_allowList;
    for (uint256 i = 0; i < existingList.length; ++i) {
      s_allowed[existingList[i]] = false;
    }

    // Set the new allowlist
    s_allowList = allowlist;
    for (uint256 i = 0; i < allowlist.length; ++i) {
      s_allowed[allowlist[i]] = true;
    }
    emit AllowListSet(allowlist);
  }

  /// @inheritdoc AllowListInterface
  function getAllowlist() external view returns (address[] memory) {
    return s_allowList;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../interfaces/rateLimiter/AggregateRateLimiterInterface.sol";
import "../access/OwnerIsCreator.sol";
import "../../vendor/IERC20.sol";

contract AggregateRateLimiter is AggregateRateLimiterInterface, OwnerIsCreator {
  // The address of the token limit admin that has the same permissions as
  // the owner.
  address private s_tokenLimitAdmin;

  // A mapping of token => tokenPrice
  mapping(IERC20 => uint256) private s_priceByToken;
  // The tokens that have a set price
  IERC20[] private s_allowedTokens;

  // The token bucket object that contains the bucket state.
  TokenBucket private s_tokenBucket;

  /**
   * @param config The RateLimiterConfig containing the capacity and refill rate of the bucket
   * @param tokenLimitsAdmin The address that is allowed to change prices and the bucket
   *      configuration settings.
   */
  constructor(RateLimiterConfig memory config, address tokenLimitsAdmin) {
    s_tokenLimitAdmin = tokenLimitsAdmin;
    s_tokenBucket = TokenBucket({
      rate: config.rate,
      capacity: config.capacity,
      tokens: config.capacity,
      lastUpdated: block.timestamp
    });
  }

  /// @inheritdoc AggregateRateLimiterInterface
  function getTokenLimitAdmin() public view returns (address) {
    return s_tokenLimitAdmin;
  }

  /// @inheritdoc AggregateRateLimiterInterface
  function setTokenLimitAdmin(address newAdmin) public onlyOwner {
    s_tokenLimitAdmin = newAdmin;
  }

  /// @inheritdoc AggregateRateLimiterInterface
  function calculateCurrentTokenBucketState() public view returns (TokenBucket memory) {
    TokenBucket memory bucket = s_tokenBucket;

    // We update the bucket to reflect the status at the exact time of the
    // call. This means to might need to refill a part of the bucket based
    // on the time that has passed since the last update.
    uint256 timeNow = block.timestamp;
    uint256 difference = timeNow - bucket.lastUpdated;

    // Overflow doesn't happen here because bucket.rate is <= type(uint208).max
    // leaving 48 bits for the time difference. 2 ** 48 seconds = 9e6 years.
    bucket.tokens = min(bucket.capacity, bucket.tokens + difference * bucket.rate);
    bucket.lastUpdated = timeNow;
    return bucket;
  }

  /// @inheritdoc AggregateRateLimiterInterface
  function setRateLimiterConfig(RateLimiterConfig memory config) public requireAdminOrOwner {
    // We only allow a refill rate of uint208 so we don't have to deal with any
    // overflows for the next ~9 million years. Any sensible rate is way below this value.
    if (config.rate >= type(uint208).max) {
      revert RefillRateTooHigh();
    }
    // First update the bucket to make sure the proper rate is used for all the time
    // up until the config change.
    update(s_tokenBucket);

    s_tokenBucket.capacity = config.capacity;
    s_tokenBucket.rate = config.rate;
    s_tokenBucket.tokens = min(config.capacity, s_tokenBucket.tokens);

    emit ConfigChanged(config.capacity, config.rate);
  }

  function getPricesForTokens(IERC20[] memory tokens) public view returns (uint256[] memory prices) {
    uint256 numberOfTokens = tokens.length;
    prices = new uint256[](numberOfTokens);

    for (uint256 i = 0; i < numberOfTokens; ++i) {
      prices[i] = s_priceByToken[tokens[i]];
    }

    return prices;
  }

  /// @inheritdoc AggregateRateLimiterInterface
  function setPrices(IERC20[] memory tokens, uint256[] memory prices) public requireAdminOrOwner {
    uint256 newTokenLength = tokens.length;
    if (newTokenLength != prices.length) {
      revert TokensAndPriceLengthMismatch();
    }

    // Remove all old entries
    uint256 setTokensLength = s_allowedTokens.length;
    for (uint256 i = 0; i < setTokensLength; ++i) {
      delete s_priceByToken[s_allowedTokens[i]];
    }

    for (uint256 i = 0; i < newTokenLength; ++i) {
      IERC20 token = tokens[i];
      if (token == IERC20(address(0))) {
        revert AddressCannotBeZero();
      }
      s_priceByToken[token] = prices[i];
      emit TokenPriceChanged(address(token), prices[i]);
    }

    s_allowedTokens = tokens;
  }

  /**
   * @notice _removeTokens removes the given token values from the pool, lowering the
              value allowed to be transferred for subsequent calls. It will use the
              s_priceByToken mapping to determine value in a standardised unit.
   * @param tokens The tokens that are send across the bridge. All of the tokens need
   *          to have a corresponding price set in s_priceByToken.
   * @param amounts The number of tokens sent across the bridge.
   * @dev Reverts when a token price is not found or when the tx value exceeds the
   *          amount allowed in the bucket.
   * @dev Will only remove and therefore emit removal of value if the value is > 0.
   */
  function _removeTokens(IERC20[] memory tokens, uint256[] memory amounts) internal {
    uint256 value = 0;
    for (uint256 i = 0; i < tokens.length; ++i) {
      uint256 pricePerToken = s_priceByToken[tokens[i]];
      if (pricePerToken == 0) {
        revert PriceNotFoundForToken(address(tokens[i]));
      }
      value += pricePerToken * amounts[i];
    }

    // If there is no value to remove skip this step to reduce gas usage
    if (value > 0) {
      // Refill the bucket if possible
      update(s_tokenBucket);
      if (s_tokenBucket.tokens < value) {
        revert ValueExceedsAllowedThreshold();
      }

      s_tokenBucket.tokens -= value;
      emit TokensRemovedFromBucket(value);
    }
  }

  function update(TokenBucket storage bucket) internal {
    uint256 timeNow = block.timestamp;

    // Return if there's nothing to update
    if (bucket.tokens == bucket.capacity || bucket.lastUpdated == timeNow) return;
    // Revert if the tokens in the bucket exceed its capacity
    if (bucket.tokens > bucket.capacity) revert BucketOverfilled();
    uint256 difference = timeNow - bucket.lastUpdated;
    bucket.tokens = min(bucket.capacity, bucket.tokens + difference * bucket.rate);
    bucket.lastUpdated = timeNow;
  }

  /**
   * @notice Return the smallest of two integers
   * @param a first int
   * @param b second int
   * @return smallest
   */
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  /**
   * @notice a modifier that allows the owner or the s_tokenLimitAdmin call the functions
   *          it is applied to.
   */
  modifier requireAdminOrOwner() {
    if (msg.sender != owner() && msg.sender != s_tokenLimitAdmin) {
      revert OnlyCallableByAdminOrOwner();
    }
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseOffRampInterface.sol";
import "../../models/Models.sol";

interface Any2EVMOffRampRouterInterface {
  error NoOffRampsConfigured();
  error MustCallFromOffRamp(address sender);
  error SenderNotAllowed(address sender);
  error InvalidAddress();
  error OffRampNotAllowed(BaseOffRampInterface offRamp);
  error AlreadyConfigured(BaseOffRampInterface offRamp);

  event OffRampAdded(BaseOffRampInterface indexed offRamp);
  event OffRampRemoved(BaseOffRampInterface indexed offRamp);

  struct OffRampDetails {
    uint96 listIndex;
    bool allowed;
  }

  function addOffRamp(BaseOffRampInterface offRamp) external;

  function removeOffRamp(BaseOffRampInterface offRamp) external;

  function getOffRamps() external view returns (BaseOffRampInterface[] memory offRamps);

  function isOffRamp(BaseOffRampInterface offRamp) external view returns (bool allowed);

  function routeMessage(CCIP.Any2EVMMessageFromSender calldata message) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../models/Models.sol";

interface BlobVerifierInterface {
  error UnsupportedOnRamp(address onRamp);
  error InvalidInterval(CCIP.Interval interval, address onRamp);
  error InvalidRelayReport(CCIP.RelayReport report);
  error InvalidConfiguration();

  event ReportAccepted(CCIP.RelayReport report);
  event BlobVerifierConfigSet(BlobVerifierConfig config);

  struct BlobVerifierConfig {
    address[] onRamps;
    uint64[] minSeqNrByOnRamp;
  }

  /**
   * @notice Gets the current configuration.
   * @return the currently configured BlobVerifierConfig.
   */
  function getConfig() external view returns (BlobVerifierConfig memory);

  /**
   * @notice Sets the new BlobVerifierConfig and updates the s_expectedNextMinByOnRamp
   *      mapping. It will first blank the entire mapping and then input the new values.
   *      This means that any onRamp previously set but not included in the new config
   *      will be unsupported afterwards.
   * @param config The new configuration.
   */
  function setConfig(BlobVerifierConfig calldata config) external;

  /**
   * @notice Returns the next expected sequence number for a given onRamp.
   * @param onRamp The onRamp for which to get the next sequence number.
   * @return the next expected sequenceNumber for the given onRamp.
   */
  function getExpectedNextSequenceNumber(address onRamp) external view returns (uint64);

  /**
   * @notice Returns timestamp of when root was accepted or -1 if verification fails.
   * @dev This method uses a merkle tree within a merkle tree, with the hashedLeaves,
   *        innerProofs and innerProofFlagBits being used to get the root of the inner
   *        tree. This root is then used as the singular leaf of the outer tree.
   */
  function verify(
    bytes32[] calldata hashedLeaves,
    bytes32[] calldata innerProofs,
    uint256 innerProofFlagBits,
    bytes32[] calldata outerProofs,
    uint256 outerProofFlagBits
  ) external returns (uint256 timestamp);

  /**
   * @notice Generates a Merkle Root based on the given leaves, proofs and proofFlagBits.
   *          This method can proof multiple leaves at the same time.
   * @param leaves The leaf hashes of the merkle tree.
   * @param proofs The hashes to be used instead of a leaf hash when the proofFlagBits
   *          indicates a proof should be used.
   * @param proofFlagBits A single uint256 of which each bit indicates whether a leaf or
   *          a proof needs to be used in a hash operation.
   * @dev the maximum number of hash operations it set to 256. Any input that would require
   *          more than 256 hashes to get to a root will revert.
   * @dev For given input `leaves` = [a,b,c] `proofs` = [D] and `proofFlagBits` = 5
   *     totalHashes = 3 + 1 - 1 = 3
   *  ** round 1 **
   *     proofFlagBits = (5 >> 0) & 1 = true
   *     hashes[0] = hashPair(a, b)
   *     (leafPos, hashPos, proofPos) = (2, 0, 0);
   *
   *  ** round 2 **
   *     proofFlagBits = (5 >> 1) & 1 = false
   *     hashes[1] = hashPair(D, c)
   *     (leafPos, hashPos, proofPos) = (3, 0, 1);
   *
   *  ** round 3 **
   *     proofFlagBits = (5 >> 2) & 1 = true
   *     hashes[2] = hashPair(hashed[0], hashes[1])
   *     (leafPos, hashPos, proofPos) = (3, 2, 1);
   *
   *     i = 3 and no longer < totalHashes. The algorithm is done
   *     return hashes[totalHashes - 1] = hashes[2]; the last hash we computed.
   */
  function merkleRoot(
    bytes32[] memory leaves,
    bytes32[] memory proofs,
    uint256 proofFlagBits
  ) external pure returns (bytes32);

  /**
   * @notice Returns the timestamp of a potentially previously relayed merkle root. If
   *          the root was never relayed 0 will be returned.
   * @param root The merkle root to check the relay status for.
   * @return the timestamp of the relayed root or zero in the case that it was never
   *          relayed.
   */
  function getMerkleRoot(bytes32 root) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AFNInterface {
  event RootBlessed(bytes32 indexed root, uint256 votes);
  event VoteToBless(address indexed voter, bytes32 indexed root, uint256 weight);
  event VoteBad(address indexed voter, uint256 weight);
  event AFNBadSignal(uint256 timestamp);
  event RecoveredFromBadSignal();
  event AFNConfigSet(address[] parties, uint256[] weights, uint256 goodQuorum, uint256 badQuorum);

  error InvalidVoter(address voter);
  error AlreadyVoted();
  error InvalidConfig();
  error InvalidWeight();
  error MustRecoverFromBadSignal();
  error RecoveryNotNecessary();

  /**
   * @notice Check if a bad signal has been received
   * @return bool badSignal
   */
  function badSignalReceived() external view returns (bool);

  /**
   * @notice Vote to bless a set of roots with Origin
   * @param rootsWithOrigin - array of roots
   */
  function voteToBlessRoots(bytes32[] calldata rootsWithOrigin) external;

  /**
   * @notice Get thresholds for blessing and bad signal
   * @return blessing threshold for blessing
   * @return badSignal threshold for bad signal
   */
  function getWeightThresholds() external returns (uint256 blessing, uint256 badSignal);

  /**
   * @notice Check if a participant has voted to bless a root
   * @param participant address
   * @param root bytes32
   * @return bool has voted to bless
   */
  function hasVotedToBlessRoot(address participant, bytes32 root) external view returns (bool);

  /**
   * @notice Get all configured participants
   * @return participants address array
   */
  function getParticipants() external returns (address[] memory);

  /**
   * @notice Get the weight of a participant
   * @param participant address
   * @return weight uint256
   */
  function getWeightByParticipant(address participant) external view returns (uint256);

  /**
   * @notice Get the config version
   * @return version uint256
   */
  function getConfigVersion() external view returns (uint256);

  /**
   * @notice Get participants who have voted bad, and the total number of bad votes
   * @return voters address array
   * @return votes total number of bad votes
   */
  function getBadVotersAndVotes() external view returns (address[] memory voters, uint256 votes);

  /**
   * @notice Get the number of votes to bless a particular root
   * @param root bytes32
   * @return votes number of votes
   */
  function getVotesToBlessRoot(bytes32 root) external view returns (uint256);

  /**
   * @notice Check if a participant has voted bad
   * @param participant address
   * @return hasVotedBad bool
   */
  function hasVotedBad(address participant) external view returns (bool);

  /**
   * @notice Vote bad
   */
  function voteBad() external;

  /**
   * @notice Check if a root is blessed
   * @param root bytes32
   * @return isBlessed bool
   */
  function isBlessed(bytes32 root) external returns (bool);

  /**
   * @notice Recover from a bad signal
   */
  function recoverFromBadSignal() external;

  /**
   * @notice Set config storage vars
   * @dev only callable by the owner
   * @param participants participants allowed to vote
   * @param weights weights of each participant's vote
   * @param weightThresholdForBlessing threshold to emit a blessing
   * @param weightThresholdForBadSignal threashold to emit a bad signal
   */
  function setAFNConfig(
    address[] memory participants,
    uint256[] memory weights,
    uint256 weightThresholdForBlessing,
    uint256 weightThresholdForBadSignal
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../models/Models.sol";
import "./BaseOnRampInterface.sol";

interface EVM2EVMTollOnRampInterface is BaseOnRampInterface {
  error InvalidFeeConfig();

  event CCIPSendRequested(CCIP.EVM2EVMTollMessage message);

  /**
   * @notice Send a message to the remote chain
   * @dev approve() must have already been called on the token using the this ramp address as the spender.
   * @dev if the contract is paused, this function will revert.
   * @param message Message struct to send
   * @param originalSender The original initiator of the CCIP request
   */
  function forwardFromRouter(CCIP.EVM2AnyTollMessage memory message, address originalSender) external returns (uint64);

  struct FeeConfig {
    // Fees per fee token
    uint256[] fees;
    // Supported fee tokens
    IERC20[] feeTokens;
  }

  /**
   * @notice Set the required fee by fee token.
   * @param feeConfig fees by token.
   */
  function setFeeConfig(FeeConfig calldata feeConfig) external;

  /**
   * @notice Get the required fee for a specific fee token
   * @param feeToken token to get the fee for
   * @return fee uint256
   */
  function getRequiredFee(IERC20 feeToken) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../vendor/IERC20.sol";

interface AggregateRateLimiterInterface {
  error OnlyCallableByAdminOrOwner();
  error TokensAndPriceLengthMismatch();
  error ValueExceedsAllowedThreshold();
  error PriceNotFoundForToken(address token);
  error AddressCannotBeZero();
  error BucketOverfilled();
  error RefillRateTooHigh();

  event ConfigChanged(uint256 capacity, uint256 rate);
  event TokensRemovedFromBucket(uint256 tokens);
  event TokenPriceChanged(address token, uint256 newPrice);

  struct TokenBucket {
    uint256 rate;
    uint256 capacity;
    uint256 tokens;
    uint256 lastUpdated;
  }

  struct RateLimiterConfig {
    uint256 rate;
    uint256 capacity;
  }

  /**
   * @notice Gets the token limit admin address
   */
  function getTokenLimitAdmin() external view returns (address);

  /**
   * @notice Sets the token limit admin address
   * @param newAdmin the address of the new admin.
   */
  function setTokenLimitAdmin(address newAdmin) external;

  /**
   * @notice Gets the token bucket with it's values for the block it was
   *          requested at.
   * @return The token bucket.
   */
  function calculateCurrentTokenBucketState() external view returns (TokenBucket memory);

  /**
   * @notice Sets the rate limited config.
   * @param config The new rate limiter config.
   * @dev should only be callable by the owner or token limit admin.
   * @dev the max rate is uint208.max
   */
  function setRateLimiterConfig(RateLimiterConfig memory config) external;

  /**
   * @notice Gets the set prices for the given IERC20s.
   * @param tokens The tokens to get the price of.
   * @return prices The current prices of the token.
   */
  function getPricesForTokens(IERC20[] memory tokens) external view returns (uint256[] memory prices);

  /**
   * @notice Sets the prices of the given IERC20 tokens to the given prices.
   * @param tokens The tokens for which the price will be set.
   * @param prices The new prices of the given tokens.
   * @dev if any previous prices were set for a number of given tokens, these
   *        will be overwritten. Previously set prices for tokens that are
   *        not present in subsequent setPrices calls will *not* be reset
   *        to zero but will be left unchanged.
   * @dev should only be callable by the owner or token limit admin.
   */
  function setPrices(IERC20[] memory tokens, uint256[] memory prices) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}