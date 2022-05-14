// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @author Sfy Mantissa
/// @title  A simple ERC-20-compliant token I made to better understand the
///         ERC-20 standard.
contract YetAnotherCoin is Ownable {

  mapping(address => uint256) private balances;
  mapping(address => mapping(address => uint256)) private allowances;
  
  string private _name;
  string private _symbol;
  uint8 private _decimals;
  uint256 private _totalSupply;

  /// @notice Gets triggered upon any action where tokens are moved
  ///         between accounts: transfer(), transferFrom(), mint(), burn().
  event Transfer(
    address indexed seller,
    address indexed buyer,
    uint256 amount
  );

  /// @notice Gets triggeted upon a successful approve() call.
  event Approval(
    address indexed owner,
    address indexed delegate,
    uint256 amount
  );

  /// @notice `_name` is the token's human-readable name string.
  ///         `_symbol` is the three character string used to represent the token.
  ///         `_decimals` is used to tell the precision of token quantity to the end-user.
  ///         `_totalSupply` is used to tell the total initial supply of tokens.
  /// @dev    Upon deployment owner gets the entire supply. `_totalSupply` can be manipulated
  ///         with mint() and burn() functions.
  constructor() {
    _name = "YetAnotherCoin";
    _symbol = "YAC";
    _decimals = 5;  
    _totalSupply = 100000;
    balances[msg.sender] = _totalSupply;
  }

  /// @notice Allows to transfer a specified `amount` of tokens between
  ///         the caller and the `buyer`
  /// @param  buyer Address of the recepient.
  /// @param  amount Number of tokens to be transferred.
  /// @return Flag to tell whether the call succeeded.
  function transfer(address buyer, uint256 amount) 
    public
    returns (bool)
  {
    require(buyer != address(0), "Buyer must have a non-zero address!");
    require(
      balances[msg.sender] >= amount,
      "Transfer amount must not exceed balance!"
    );

    balances[msg.sender] -= amount;
    balances[buyer] += amount;

    emit Transfer(msg.sender, buyer, amount);
    return true;
  }

  /// @notice Allows to transfer a specified `amount` of tokens on behalf
  ///         of `seller` by the delegate.
  /// @dev    Delegate must have enough allowance.
  /// @param  seller Address of the wallet to withdraw tokens from.
  /// @param  buyer Address of the recepient.
  /// @param  amount Number of tokens to be transferred.
  /// @return Flag to tell whether the call succeeded.
  function transferFrom(address seller, address buyer, uint256 amount)
    public
    returns (bool)
  {
    require(seller != address(0), "Seller must have a non-zero address!");
    require(buyer != address(0), "Buyer must have a non-zero address!");

    require(
      balances[seller] >= amount,
      "Seller does not have the specified amount!"
    );

    require(
      allowances[seller][msg.sender] >= amount,
      "Delegate does not have enough allowance!"
    );

    balances[seller] -= amount;
    allowances[seller][msg.sender] -= amount;
    balances[buyer] += amount;

    emit Transfer(seller, buyer, amount);
    return true;
  }

  /// @notice Allows the caller to delegate spending the specified `amount`
  ///         of tokens from caller's wallet by the `delegate`.
  /// @param  delegate Address of the delegate.
  /// @param  amount Number of tokens to be allowed for transfer.
  /// @return Flag to tell whether the call succeeded.
  function approve(address delegate, uint256 amount)
    public
    returns (bool)
  {
    require(delegate != address(0), "Delegate must have a non-zero address!");

    allowances[msg.sender][delegate] = amount;

    emit Approval(msg.sender, delegate, amount);
    return true;
  }

  /// @notice Allows the caller to give the specified `amount` of tokens
  ///         to the `account` and increase `_totalSupply` by the `amount`.
  /// @dev    Can only be called by the owner.
  /// @param  account Address of the recepient.
  /// @param  amount Number of tokens to be transferred.
  function mint(address account, uint256 amount)
    public
    onlyOwner
  {
    require(account != address(0), "Receiving account must have a non-zero address!");

    _totalSupply += amount;
    balances[account] += amount;

    emit Transfer(address(0), account, amount);
  }

  /// @notice Allows the caller to burn the specified `amount` of tokens
  ///         from the `account` and decrease the `_totalSupply by the `amount`.
  /// @dev    Can only be called by the owner.
  /// @param  account Address of the burned account.
  /// @param  amount Number of tokens to be burned.
  function burn(address account, uint256 amount)
    public
    onlyOwner
  {
    require(account != address(0), "Burner account must have a non-zero address!");
    require(balances[account] >= amount, "Burn amount must not exceed balance!");

    balances[account] -= amount;
    _totalSupply -= amount;

    emit Transfer(account, address(0), amount);
  }

  /// @notice Allows the caller to get token's `_name`.
  /// @return Token's name.
  function name()
    public
    view
    returns (string memory)
  {
    return _name;
  }

  /// @notice Allows the caller to get token's `_symbol`.
  /// @return Token's symbol.
  function symbol()
    public
    view
    returns (string memory)
  {
    return _symbol;
  }

  /// @notice Allows the caller to get token's `_decimals`.
  /// @return Token's decimals.
  function decimals()
    public
    view
    returns (uint8)
  {
    return _decimals;
  }

  /// @notice Allows the caller to get token's `_totalSupply`.
  /// @return Token's total supply.
  function totalSupply()
    public
    view
    returns (uint256)
  {
    return _totalSupply;
  }

  /// @notice Allows the caller to get token balance of the `account`.
  /// @param  account The address for which the balance is fetched.
  /// @return Token balance of the `account`.
  function balanceOf(address account)
    public
    view
    returns (uint256)
  {
    return balances[account];
  }

  /// @notice Allows the caller to get the allowance provided by the
  ///         `account` to `delegate`
  /// @return The amount of allowance.
  function allowance(address account, address delegate)
    public
    view
    returns (uint256)
  {
    return allowances[account][delegate];
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