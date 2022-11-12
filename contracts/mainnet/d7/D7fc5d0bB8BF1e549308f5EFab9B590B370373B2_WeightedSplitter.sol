/**
 *Submitted for verification at Etherscan.io on 2022-11-12
*/

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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


// File @openzeppelin/contracts/security/[email protected]

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// File contracts/WeightedSplitter.sol

pragma solidity ^0.8.0;

contract WeightedSplitter is Ownable, ReentrancyGuard {
  // Address changes will be executable 2 weeks after being submitted
  uint256 constant WALLET_TIMELOCK = 2 weeks;

  // Total weight of all the payees set up in this splitter
  uint256 public totalWeight;

  // Amount already withdrawn by token and by payee
  mapping(address => mapping(uint256 => uint256)) payeeWithdrawnAmount;
  // Total amount withdrawn by token
  mapping(address => uint256) totalWithdrawnAmount;
  // Weught by payee
  mapping(uint256 => uint256) payeeWeight;
  // Mapping from addresses to payee ID
  mapping(address => uint256) addressToPayee;

  // Amount of payees
  uint256 public payeeCount;

  // Struct used to register a payee address change request
  struct PayeeChange {
    // New payee address
    address newPayee;
    // Time from which change can be executed
    uint96 executionTime;
  }

  // Mapping of pending payee changes
  mapping(address => PayeeChange) public pendingPayeeChanges;

  // Emitted when a payee address change request is submitted
  event PayeeChangeSubmitted(
    uint256 indexed payeeId,
    address indexed oldAccount,
    address indexed newAccount
  );
  // Emitted when a payee address change request is executed
  event PayeeChangeExecuted(
    uint256 indexed payeeId,
    address indexed oldAccount,
    address indexed newAccount
  );

  constructor(
    address payable[] memory _addresses,
    uint256[] memory _weights
  ) {
    require(_addresses.length == _weights.length, "invalid arguments");
    for (uint256 i = 0; i < _addresses.length; i++) {
      uint256 id = i + 1;
      addressToPayee[_addresses[i]] = id;
      payeeWeight[id] = _weights[i];
      totalWeight += _weights[i];
    }
    payeeCount = _addresses.length;
  }

  /**
   * @dev Submits a new payee change request. Owner only
   */
  function submitPayeeChange(
    address _oldAccount,
    address _newAccount
  ) external onlyOwner {
    uint256 _payeeId = addressToPayee[_oldAccount];
    require(_payeeId  != 0, "payee does not exist");

    uint256 _newPayeeId = addressToPayee[_newAccount];
    require(_newPayeeId == 0, "new account already is payee");

    pendingPayeeChanges[_oldAccount] = PayeeChange(
      _newAccount,
      uint96(block.timestamp + WALLET_TIMELOCK)
    );

    emit PayeeChangeSubmitted(
      _payeeId,
      _oldAccount,
      _newAccount
    );
  }

  /**
   * @dev Executes a payee change request. Owner only.
   * Can only be done after waiting WALLET_TIMELOCK.
   */
  function executePayeeChange(
    address _oldAccount
  ) external onlyOwner {
    uint256 _payeeId = addressToPayee[_oldAccount];
    require(_payeeId  != 0, "payee does not exist");

    PayeeChange storage payeeChange = pendingPayeeChanges[_oldAccount];

    uint256 _newPayeeId = addressToPayee[payeeChange.newPayee];
    require(_newPayeeId == 0, "new account already is payee");
    
    require(payeeChange.newPayee != address(0), "no pending request for that payee");
    require(payeeChange.executionTime < block.timestamp, "request still timelocked");
    
    addressToPayee[_oldAccount] = 0;
    addressToPayee[payeeChange.newPayee] = _payeeId;

    emit PayeeChangeExecuted(
      _payeeId,
      _oldAccount,
      payeeChange.newPayee
    );

    payeeChange.executionTime = 0;
    payeeChange.newPayee = address(0);
  }

  /**
   * @dev returns the weight for the given account, if it is a payee.
   * Else reverts.
   */
  function getPayeeWeight(address _account) external view returns (uint256) {
    uint256 _payeeId = addressToPayee[_account];
    require(_payeeId  != 0, "payee does not exist");
    return payeeWeight[_payeeId];
  }

  /**
   * @dev returns the payee ID associated with the given account, if any.
   * Else reverts.
   */
  function getPayeeId(address _account) external view returns (uint256) {
    uint256 _payeeId = addressToPayee[_account];
    require(_payeeId  != 0, "payee does not exist");
    return _payeeId;
  }

  /**
   * @dev Returns the total amount of the specified token
   * withdrawn by specific account, if payee.
   * Note: when a payee address is changed, the total amount is attributed to
   * the new account.
   */
  function getWithdrawnAmount(
    address _account,
    address _token
  ) public view returns(uint256) {
    uint256 _payeeId = addressToPayee[_account];
    require(_payeeId != 0, "payee does not exist");
    return payeeWithdrawnAmount[_token][_payeeId];
  }

  /**
   * @dev Returns the balance of the given token for the given account.
   * address(0) is ETH.
   */
  function getBalance(address _account, address _token) public view returns(uint256) {
    uint256 _payeeId = addressToPayee[_account];
    require(_payeeId  != 0, "payee does not exist");
    uint256 _contractBalance;
    if (_token == address(0)) {
      _contractBalance = address(this).balance;
    } else {
      _contractBalance = IERC20(_token).balanceOf(address(this));
    }
    uint256 _contractBalanceIncWithdrawn = (
      _contractBalance + totalWithdrawnAmount[_token]
    );
    uint256 _accountBalanceIncWithdrawn = (
      _contractBalanceIncWithdrawn * payeeWeight[_payeeId] / totalWeight
    );

    return _accountBalanceIncWithdrawn - payeeWithdrawnAmount[_token][_payeeId];
  }

  /**
   * @dev Returns the ETH balance. Convenience method.
   */
  function getEthBalance(address _account) external view returns(uint256) {
    return getBalance(_account, address(0));
  }

  /**
   * @dev Withdraws the available balance of the given token for the given
   * account, to that account. Only owner, or payee.
   */
  function withdrawFor(address _account, address _token) public nonReentrant {
    require(
      _msgSender() == owner() || _msgSender() == _account,
      "unauthorized"
    );

    uint256 _payeeId = addressToPayee[_account];
    require(_payeeId != 0, "payee does not exist");

    uint256 balance = getBalance(_account, _token);
    require(balance > 0, 'balance is 0');

    payeeWithdrawnAmount[_token][_payeeId] += balance;
    totalWithdrawnAmount[_token] += balance;

    if (_token == address(0)) {
      (bool success, ) = _account.call{value: balance}("");
      require(success, "withdrawal failed");
    } else {
      IERC20(_token).transfer(_account, balance);
    }
  }

  /**
   * @dev Withdraws the available balance of ETH for the given
   * account, to that account. Only owner, or payee. Convenience method.
   */
  function withdrawEthFor(address _account) public {
    withdrawFor(_account, address(0));
  }

  /**
   * @dev Withdraws the available balance of the given token for the sender.
   * Payee only. Convenience method.
   */
  function withdraw(address _token) public {
    withdrawFor(_msgSender(), _token);
  }

  /**
   * @dev Withdraws the available balance of ETH for the sender.
   * Payee only. Convenience method.
   */
  function withdrawEth() public {
    withdrawFor(_msgSender(), address(0));
  }

  // Make this contract capable of receiving ETH
  receive() external payable {}
}