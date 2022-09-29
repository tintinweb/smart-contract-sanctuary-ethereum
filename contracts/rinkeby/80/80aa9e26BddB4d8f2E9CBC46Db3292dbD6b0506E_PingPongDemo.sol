/**
 *Submitted for verification at Etherscan.io on 2022-09-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

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

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

/**
 * @title The OwnerIsCreator contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract OwnerIsCreator is ConfirmedOwner {
  constructor() ConfirmedOwner(msg.sender) {}
}

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

interface CCIPRouterInterface {
  struct Message {
    address receiver;
    bytes data;
    IERC20[] tokens;
    uint256[] amounts;
    uint256 gasLimit;
  }

  function ccipSend(uint256 destinationChainId, Message memory message) external returns (uint64);
}

interface CCIPReceiverInterface {
  struct ReceivedMessage {
    uint256 sourceChainId;
    bytes sender;
    bytes data;
    IERC20[] tokens;
    uint256[] amounts;
  }

  function ccipReceive(ReceivedMessage memory message) external;
}

contract PingPongDemo is CCIPReceiverInterface, OwnerIsCreator {
  event Ping(uint256 pingPongCount);
  event Pong(uint256 pingPongCount);

  CCIPRouterInterface internal s_receivingRouter;
  CCIPRouterInterface internal s_sendingRouter;

  // The chain ID of the counterpart ping pong contract
  uint256 public s_counterpartChainId;
  // The contract address of the counterpart ping pong contract
  address public s_counterpartAddress;

  // Pause ping-ponging
  bool public s_isPaused;

  constructor(CCIPRouterInterface receivingRouter, CCIPRouterInterface sendingRouter) {
    s_receivingRouter = receivingRouter;
    s_sendingRouter = sendingRouter;
    s_isPaused = false;
  }

  function setCounterpart(uint256 counterpartChainId, address counterpartAddress) external onlyOwner {
    s_counterpartChainId = counterpartChainId;
    s_counterpartAddress = counterpartAddress;
  }

  function startPingPong() external onlyOwner {
    s_isPaused = false;
    _respond(1);
  }

  function _respond(uint256 pingPongCount) private {
    if (pingPongCount & 1 == 1) {
      emit Ping(pingPongCount);
    } else {
      emit Pong(pingPongCount);
    }

    bytes memory data = abi.encode(pingPongCount);
    CCIPRouterInterface.Message memory message = CCIPRouterInterface.Message({
      receiver: s_counterpartAddress,
      data: data,
      tokens: new IERC20[](0),
      amounts: new uint256[](0),
      gasLimit: 200_000
    });
    s_sendingRouter.ccipSend(s_counterpartChainId, message);
  }

  function ccipReceive(ReceivedMessage memory message) external override onlyRouter {
    uint256 pingPongCount = abi.decode(message.data, (uint256));
    if (!s_isPaused) {
      _respond(pingPongCount + 1);
    }
  }

  /////////////////////////////////////////////////////////////////////
  // Plumbing
  /////////////////////////////////////////////////////////////////////

  function setRouters(CCIPRouterInterface receivingRouter, CCIPRouterInterface sendingRouter) external onlyOwner {
    s_receivingRouter = receivingRouter;
    s_sendingRouter = sendingRouter;
  }

  function getRouters() external view returns (CCIPRouterInterface, CCIPRouterInterface) {
    return (s_receivingRouter, s_sendingRouter);
  }

  function getSubscriptionManager() external view returns (address) {
    return owner();
  }

  function setPaused(bool isPaused) external onlyOwner {
    s_isPaused = isPaused;
  }

  error InvalidRouter(address router);

  /**
   * @dev only calls from the set router are accepted.
   */
  modifier onlyRouter() {
    if (msg.sender != address(s_receivingRouter)) revert InvalidRouter(msg.sender);
    _;
  }
}