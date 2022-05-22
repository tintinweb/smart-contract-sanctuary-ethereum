// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.8;

/// @author Sfy Mantissa
/// @title  A simple ERC-20-compliant token I made to better understand the
///         ERC-20 standard.
interface IYetAnotherCoin {

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

  /// @notice Get token `balance` of the `account`.
  /// @param account Address of the account.
  function balanceOf(address account)
    external
    view
    returns (uint256);

  /// @notice Get the allowance provided by the account to delegate.
  /// @param account Address of the account.
  /// @param delegate Address of the delegate.
  function allowance(address account, address delegate)
    external
    view
    returns (uint256);

  /// @notice Get token's human-readable name.
  function name()
    external
    view
    returns (string memory);

  /// @notice Get token's acronym representation.
  function symbol()
    external
    view
    returns (string memory);

  /// @notice Get token's decimals for end-user representation.
  function decimals()
    external
    view
    returns (uint8);

  /// @notice Get token's total supply.
  function totalSupply()
    external
    view
    returns (uint256);

  /// @notice Allows to transfer a specified `amount` of tokens between
  ///         the caller and the `buyer`
  /// @param  buyer Address of the recepient.
  /// @param  amount Number of tokens to be transferred.
  /// @return Flag to tell whether the call succeeded.
  function transfer(address buyer, uint256 amount)
    external
    returns (bool);

  /// @notice Allows to transfer a specified `amount` of tokens on behalf
  ///         of `seller` by the delegate.
  /// @dev    Delegate must have enough allowance.
  /// @param  seller Address of the wallet to withdraw tokens from.
  /// @param  buyer Address of the recepient.
  /// @param  amount Number of tokens to be transferred.
  /// @return Flag to tell whether the call succeeded.
  function transferFrom(address seller, address buyer, uint256 amount)
    external
    returns (bool);

  /// @notice Allows the caller to delegate spending the specified `amount`
  ///         of tokens from caller's wallet by the `delegate`.
  /// @param  delegate Address of the delegate.
  /// @param  amount Number of tokens to be allowed for transfer.
  /// @return Flag to tell whether the call succeeded.
  function approve(address delegate, uint256 amount)
    external
    returns (bool);

  /// @notice Allows the caller to burn the specified `amount` of tokens
  ///         from the `account` and decrease the `totalSupply 
  ///         by the `amount`.
  /// @param  account Address of the burned account.
  /// @param  amount Number of tokens to be burned.
  function burn(address account, uint256 amount)
    external
    returns (bool);

  /// @notice Allows the caller to give the specified `amount` of tokens
  ///         to the `account` and increase `totalSupply` by the `amount`.
  /// @param  account Address of the recepient.
  /// @param  amount Number of tokens to be transferred.
  function mint(address account, uint256 amount)
    external
    returns (bool);

}

contract YetAnotherCoin is IYetAnotherCoin {

  mapping(address => uint256) public balanceOf;
  mapping(address => mapping(address => uint256)) public allowance;
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;

  constructor(
    string memory _name,
    string memory _symbol,
    uint8 _decimals,
    uint256 initialSupply
  )
  {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;  
    mint(msg.sender, initialSupply);
  }

  function transfer(address buyer, uint256 amount) 
    external
    returns (bool)
  {
    _transfer(msg.sender, buyer, amount);
    return true;
  }

  function transferFrom(address seller, address buyer, uint256 amount)
    external
    returns (bool)
  {
    _transfer(seller, buyer, amount);
    _spendAllowance(seller, msg.sender, amount);
    return true;
  }

  function approve(address delegate, uint256 amount)
    external
    returns (bool)
  {
    require(delegate != address(0), "Delegate must have a non-zero address!");

    allowance[msg.sender][delegate] = amount;

    emit Approval(msg.sender, delegate, amount);
    return true;
  }

  function burn(address account, uint256 amount)
    external
    returns (bool)
  {
    require(
      account != address(0),
      "Burner account must have a non-zero address!"
    );

    require(
      balanceOf[account] >= amount,
      "Burn amount must not exceed balance!"
    );
    
    unchecked {
      balanceOf[account] -= amount;
    }

    totalSupply -= amount;

    emit Transfer(account, address(0), amount);
    return true;
  }

  function mint(address account, uint256 amount)
    public
    returns (bool)
  {
    require(
      account != address(0),
      "Receiving account must have a non-zero address!"
    );

    totalSupply += amount;
    balanceOf[account] += amount;

    emit Transfer(address(0), account, amount);
    return true;
  }

  function _transfer(address seller, address buyer, uint256 amount)
    internal
  {
    require(seller != address(0), "Seller must have a non-zero address!");
    require(buyer != address(0), "Buyer must have a non-zero address!");
    require(
      balanceOf[seller] >= amount,
      "Seller does not have the specified amount!"
    );

    unchecked {
      balanceOf[msg.sender] -= amount;
    }

    balanceOf[buyer] += amount;

    emit Transfer(seller, buyer, amount);
  }

  function _spendAllowance(address seller, address delegate, uint256 amount)
    internal
  {
    require(
      allowance[seller][delegate] >= amount,
      "Delegate does not have enough allowance!"
    );

    unchecked {
      allowance[seller][delegate] -= amount;
    }
  }

}