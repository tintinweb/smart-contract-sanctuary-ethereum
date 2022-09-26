/**
 *Submitted for verification at Etherscan.io on 2022-09-26
*/

// File: contracts/utils/Context.sol


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

// File: contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

// File: contracts/ERC20.sol



pragma solidity >=0.8.14;

interface ERC20 {
  function totalSupply() external returns (uint256);

  function balanceOf(address tokenOwner) external returns (uint256 balance);

  function allowance(address tokenOwner, address spender)
    external
    returns (uint256 remaining);

  function transfer(address to, uint256 tokens) external returns (bool success);

  function approve(address spender, uint256 tokens)
    external
    returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 tokens
  ) external returns (bool success);

  event Transfer(address indexed from, address indexed to, uint256 tokens);
  event Approval(
    address indexed tokenOwner,
    address indexed spender,
    uint256 tokens
  );
}

// File: contracts/Owner.sol


pragma solidity >=0.8.14;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Owner {
  address private owner;

  // event for EVM logging
  event OwnerSet(address indexed oldOwner, address indexed newOwner);

  // modifier to check if caller is owner
  modifier isOwner() {
    // If the first argument of 'require' evaluates to 'false', execution terminates and all
    // changes to the state and to Ether balances are reverted.
    // This used to consume all gas in old EVM versions, but not anymore.
    // It is often a good idea to use 'require' to check if functions are called correctly.
    // As a second argument, you can also provide an explanation about what went wrong.
    require(msg.sender == owner, "Caller is not owner");
    _;
  }

  /**
   * @dev Set contract deployer as owner
   */
  constructor() {
    owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
    emit OwnerSet(address(0), owner);
  }

  /**
   * @dev Change owner
   * @param newOwner address of new owner
   */
  function changeOwner(address newOwner) public isOwner {
    emit OwnerSet(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Return owner address
   * @return address of owner
   */
  function getOwner() external view returns (address) {
    return owner;
  }
}

// File: contracts/FixedSwapLiquidityPool.sol


pragma solidity >=0.8.14;




contract FixedSwapLiquidityPool is Owner, Pausable {
  enum Status {
    SUBMITTED,
    COMPLETED,
    CANCELLED
  }

  struct Order {
    address user;
    uint256 txIndex;
    uint256 fromChainId;
    address fromToken;
    uint256 fromAmount;
    address recipient;
    uint256 toChainId;
    address toToken;
    uint256 toAmount;
    uint256 exchangeRate;
    uint256 createdAt;
    string depositTxHash;
    string withdrawTxHash;
    string refundTxHash;
    Status status;
  }

  event CashEvent(
    address user,
    uint256 txIndex,
    uint256 fromChainId,
    address fromToken,
    uint256 fromAmount,
    address recipient,
    uint256 toChainId,
    address toToken
  );

  address owner;
  string constant NULL_TX = "0x0";
  uint256 constant NULL_AMOUNT = 0;
  address constant NATIVE = address(0x0);
  mapping(address => Order[]) booking;

  function pause() public isOwner {
    _pause();
  }

  function unpause() public isOwner {
    _unpause();
  }

  function cash(
    uint256 fromAmount,
    address fromToken,
    address recipient,
    uint256 toChainId,
    address toToken
  ) public whenNotPaused returns (Order memory) {
    require(fromAmount > 0, "You need to sell at least some tokens");

    address user = msg.sender;
    uint256 allowance = ERC20(fromToken).allowance(user, address(this));

    require(allowance >= fromAmount, "Check the token allowance");
    ERC20(fromToken).transferFrom(user, address(this), fromAmount);

    uint256 txIndex = booking[user].length;
    uint256 fromChainId;

    assembly {
      fromChainId := chainid()
    }

    booking[user].push(
      Order(
        user,
        txIndex,
        fromChainId,
        fromToken,
        fromAmount,
        recipient,
        toChainId,
        toToken,
        NULL_AMOUNT, // toAmount
        NULL_AMOUNT, // exchangeRate
        block.timestamp, // createdAt
        NULL_TX, // depositTxHash
        NULL_TX, // withdrawTxHash
        NULL_TX, // refundTxHash
        Status.SUBMITTED
      )
    );

    emit CashEvent(
      user,
      txIndex,
      fromChainId,
      fromToken,
      fromAmount,
      recipient,
      toChainId,
      toToken
    );

    return booking[user][txIndex];
  }

  function withdraw(
    address payable recipient,
    address token,
    uint256 amount
  ) public isOwner {
    if (token == NATIVE) {
      recipient.transfer(amount);
    } else {
      ERC20(token).transfer(recipient, amount);
    }
  }

  function listUserOrders(address user) public view returns (Order[] memory) {
    return booking[user];
  }

  function readUserOrder(address user, uint256 txIndex)
    public
    view
    returns (Order memory)
  {
    return booking[user][txIndex];
  }

  function completeOrder(
    address user,
    uint256 txIndex,
    uint256 toAmount,
    uint256 exchangeRate,
    string memory depositTxHash,
    string memory withdrawTxHash
  ) public payable isOwner returns (Order memory) {
    booking[user][txIndex].toAmount = toAmount;
    booking[user][txIndex].exchangeRate = exchangeRate;
    booking[user][txIndex].depositTxHash = depositTxHash;
    booking[user][txIndex].withdrawTxHash = withdrawTxHash;
    booking[user][txIndex].status = Status.COMPLETED;
    return booking[user][txIndex];
  }

  function cancelOrder(
    address user,
    uint256 txIndex,
    uint256 toAmount,
    uint256 exchangeRate,
    string memory depositTxHash,
    string memory refundTxHash
  ) public payable isOwner returns (Order memory) {
    booking[user][txIndex].toAmount = toAmount;
    booking[user][txIndex].exchangeRate = exchangeRate;
    booking[user][txIndex].depositTxHash = depositTxHash;
    booking[user][txIndex].refundTxHash = refundTxHash;
    booking[user][txIndex].status = Status.CANCELLED;
    return booking[user][txIndex];
  }

  function transfer(
    address payable recipient,
    address token,
    uint256 amount
  ) public isOwner {
    if (token == NATIVE) {
      payable(recipient).transfer(amount);
    } else {
      ERC20(token).transfer(recipient, amount);
    }
  }

  receive() external payable whenNotPaused {
    // Receive Native Token (Coin)
  }
}