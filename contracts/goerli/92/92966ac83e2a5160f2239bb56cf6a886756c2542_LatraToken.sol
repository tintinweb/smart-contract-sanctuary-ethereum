/**
 *Submitted for verification at Etherscan.io on 2022-02-06
*/

/**
 *Submitted for verification at Etherscan.io on 2019-09-10
*/

pragma solidity >= 0.4.5<0.60;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error.
 */
library SafeMath {
  /**
  * @dev Multiplies two unsigned integers, reverts on overflow.
  * @notice source:
  * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero,
    // but the benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }

  /**
   * @dev Integer division of two unsigned integers truncating the quotient,
   * reverts on division by zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
   * @dev Subtracts two unsigned integers, reverts on overflow
   * (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;
    return c;
  }

  /**
   * @dev Adds two unsigned integers, reverts on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }

  /**
   * @dev Divides two unsigned integers and returns the remainder
   *(unsigned integer modulo), reverts when dividing by zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

/*
ERC-20 token
EIP-1132 locking functions
Burn function
*/
contract LatraToken {

  using SafeMath for uint;

  string public name = 'Latra Token';
  string public symbol = 'LTA';
  string public standard = 'Latra Token v1.0';
  uint256 public totalSupply;
  uint8 public decimals;

  // @dev Records data of all the tokens transferred
  // @param _from Address that sends tokens
  // @param _to Address that receives tokens
  // @param _value the amount that _spender can spend on behalf of _owner
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 _value
  );

  // @dev Records data of an Approval to spend the tokens on behalf of
  // @param _owner address that approves to pay on its behalf
  // @param _spender address to whom the approval is issued
  // @param _value the amount that _spender can spend on behalf of _owner

  event Approval(
    address indexed _owner,
    address indexed _spender,
    uint256 _value
  );

  //@dev Records the burn of tokens from a specific address
  // @param _from address that burns the tokens from its balance
  // @param _value the number of tokens that are being burned
  event Burn(
    address indexed _from,
    uint256 _value
  );

  //@dev Records data of all the tokens locked
  //@param _of address that has tokens locked
  //@param _reason the reason explaining why these tokens are locked
  //@param _amount the number of tokens being locked
  //@param _validity time in seconds tokens will be locked for
  event Locked(
    address indexed _of,
    bytes32 indexed _reason,
    uint256 _amount,
    uint256 _validity
  );

  //@dev Records data of all the tokens unlocked
  //@param _of address for whom the tokens are unlocked
  //@param _reason the reason explaining why these tokens were locked
  //@param _amount the number of tokens being unlocked
  event Unlocked(
    address indexed _of,
    bytes32 indexed _reason,
    uint256 _amount
  );

  //@dev mapping array for keeping the balances of all the accounts
  mapping(address => uint256) public balanceOf;

  //@dev amping array that keeps the allowance that is still allowed to withdraw from _owner
  mapping(address => mapping(address => uint256)) public allowance;
  //@notice account A approved account B to send C tokens (amount C is actually left )

  //@dev reasons why tokens have been locked
  mapping(address => bytes32[]) public lockReason;

  //@dev holds number & validity of tokens locked for a given reason for a specified address
  //@notice tokens locked for A account with B reason and C data: structure {ammount, valididty, claimed}
  mapping(address => mapping(bytes32 => lockToken)) public locked;

  // @dev locked token structure
  // @param amount - the amount of tokens lockedToken
  // @param validity - timestamp until when the tokes are locked
  // @param claimed - where the locked tokens already claimed
  // (unlocked and transferred to the address)
  struct lockToken {
    uint256 amount;
    uint256 validity;
    bool claimed;
  }

  constructor(uint256 _intialSupply, uint8 _intialDecimals)
    public
  {
    balanceOf[msg.sender] = _intialSupply;
    totalSupply = _intialSupply;
    decimals = _intialDecimals;
  }


  // @dev Transfers tokens from sender account to
  // @param _from Address that sends tokens
  // @param _to Address that receives tokens
  // @param _value the amount that _spender can spend on behalf of _owner
  function transfer(address _to, uint256 _value)
    public
    returns(bool success)
  {
    require(balanceOf[msg.sender] >= _value);
    balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
    balanceOf[_to] = balanceOf[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  // @dev Allows _spender to withdraw from [msg.sender] account multiple times,
  // up to the _value amount.
  // @param _spender address to whom the approval is issued
  // @param _value the amount that _spender can spend on behalf of _owner
  // @notice If this function is called again it overwrites the current allowance
  // with _value.
  function approve(address _spender, uint256 _value)
    public
    returns(bool success)
  {
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  // @dev Transfers tokens on behalf of _form account to _to account. [msg.sender]
  // should have an allowance from _from account to transfer the number of tokens.
  // @param _from address tokens are transferred from
  // @param _to address tokens are transferred to
  // @parram _value the number of tokens transferred
  // @notice _from account should have enough tokens and allowance should be equal
  // or greater than the amount transferred
  function transferFrom(address _from, address _to, uint256 _value)
    public
    returns(bool success)
  {
    require(balanceOf[_from] >= _value);
    require(allowance[_from][msg.sender] >= _value);
    balanceOf[_from] = balanceOf[_from].sub(_value);
    balanceOf[_to] = balanceOf[_to].add(_value);
    allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  // @notice Functions used for locking the tokens go next
  // @dev Locks a specified amount of tokens against an [msg.sender] address,
  // for a specified reason and time
  // @param _reason The reason to lock tokens
  // @param _amount Number of tokens to be locked
  // @param _time Lock time in seconds
  function lock(bytes32 _reason, uint256 _amount, uint256 _time)
  public
  returns (bool)
  {
    uint256 validUntil = now.add(_time);
    require(tokensLocked(msg.sender, _reason) == 0, 'Tokens already locked');
    // If tokens are already locked, then functions extendLock or
    // increaseLockAmount should be used to make any changes
    require(_amount != 0, 'Amount can not be 0');
    if (locked[msg.sender][_reason].amount == 0)
      lockReason[msg.sender].push(_reason);
    transfer(address(this), _amount);
    locked[msg.sender][_reason] = lockToken(_amount, validUntil, false);
    emit Locked(msg.sender, _reason, _amount, validUntil);
    return true;
  }

  // @dev Transfers from [msg.sender] account and locks against specified address
  // a specified amount of tokens, for a specified reason and time
  // @param _to Address against which tokens have to be locked (to which address
  // should be transferred after unlocking and claiming)
  // @param _reason The reason to lock tokens
  // @param _amount Number of tokens to be transferred and locked
  // @param _time Lock time in seconds
  function transferWithLock(
    address _to,
    bytes32 _reason,
    uint256 _amount,
    uint256 _time
  )
    public
    returns (bool)
  {
    uint256 validUntil = now.add(_time);
    require(tokensLocked(_to, _reason) == 0, 'Tokens already locked');
    require(_amount != 0, 'Amount can not be 0');
    if (locked[_to][_reason].amount == 0)
      lockReason[_to].push(_reason);
    transfer(address(this), _amount);
    locked[_to][_reason] = lockToken(_amount, validUntil, false);
    emit Locked(_to, _reason, _amount, validUntil);
    return true;
  }

  // @notice Functions used for increasing the number or time of locked tokens go next
  // @dev Extends the time of lock for tokens already locked for a specific reason
  // @param _reason The reason tokens are locked for.
  // @param _time Desirable lock extension time in seconds
  function extendLock(bytes32 _reason, uint256 _time)
    public
    returns (bool)
  {
    require(tokensLocked(msg.sender, _reason) > 0, 'There are no tokens locked for specified reason');
    locked[msg.sender][_reason].validity = locked[msg.sender][_reason].validity.add(_time);
    emit Locked(msg.sender, _reason, locked[msg.sender][_reason].amount, locked[msg.sender][_reason].validity);
    return true;
  }

  // @dev Increase number of tokens already locked for a specified reason
  // @param _reason The reason tokens are locked for.
  // @param _amount Number of tokens to be increased
  function increaseLockAmount(bytes32 _reason, uint256 _amount) public returns (bool)
  {
    require(tokensLocked(msg.sender, _reason) > 0, 'There are no tokens locked for specified reason');
    transfer(address(this), _amount);
    locked[msg.sender][_reason].amount = locked[msg.sender][_reason].amount.add(_amount);
    emit Locked(msg.sender, _reason, locked[msg.sender][_reason].amount, locked[msg.sender][_reason].validity);
    return true;
  }

  // @notice Function used for unlocking tokens goes next
  // @dev Unlocks the unlockable tokens of a specified address
  // @param _of Address of user, claiming back unlockable tokens
  function unlock(address _of) public returns (uint256 unlockableTokens) {
    uint256 lockedTokens;
    for (uint256 i = 0; i < lockReason[_of].length; i++) {
      lockedTokens = tokensUnlockable(_of, lockReason[_of][i]);
      if (lockedTokens > 0) {
        unlockableTokens = unlockableTokens.add(lockedTokens);
        locked[_of][lockReason[_of][i]].claimed = true;
        emit Unlocked(_of, lockReason[_of][i], lockedTokens);
      }
    }
    if (unlockableTokens > 0)
      this.transfer(_of, unlockableTokens);
  }

  // @dev Burns the tokens form the [msg.sender] account and reduces the TotalSupply
  // @parram _value the number of tokens to be burned
  function burn(uint256 _value) public returns (bool success)
  {
    require(balanceOf[msg.sender] >= _value);
    require(_value >= 0);
    balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
    totalSupply = totalSupply.sub(_value);
    emit Burn(msg.sender, _value);
    return true;
  }

  //@notice The end of standard ERC-20 functions
  //@noitce Further goes additional function from ERC1132 and burn function
  //@dev Returns tokens locked for a specified address for a specified reason
  //@param _of the address being checked
  //@param _reason the reason balance of locked tokens is checked for (how many tokens are locked for a specified reason)
  //@noitce this function shows the number of unclaimed tokens for the _of address at the moment. It shows as locked as well as unlockable but not yet claimed tokens
  function tokensLocked(address _of, bytes32 _reason)
    public
    view
    returns (uint256 amount)
  {
    if (!locked[_of][_reason].claimed)
    amount = locked[_of][_reason].amount;
  }

  // @dev Returns tokens locked for a specified address for a specified reason at a specific time
  // @param _of the address being checked
  // @param _reason the reason balance of locked tokens is checked for (how many tokens will be locked for a specified reason)
  // @param _time the future timestamp balance of locked tokens is checked for (how many tokens will be locked for a specified reason at a specified timestamp)
  // @noitce this function shows the number of unclaimed tokens for the _of address at the moment in future defined in a _time parameter. It shows only locked tokens.
  // The difference with tokensLocked is because of tokensLocked shows the amount at the current moment and calculates both locked and unlockable but not yet claimed tokes at the moment.
  // In the future, we cannot predict the behavior of the user and can show only locked ones.
  function tokensLockedAtTime(address _of, bytes32 _reason, uint256 _time)
    public
    view
    returns (uint256 amount)
  {
    if (locked[_of][_reason].validity > _time)
    amount = locked[_of][_reason].amount;
  }

  // @dev Returns total number of tokens held by an address (locked + unlockable but not yet claimed + transferable)
  // @param _of The address to query the total balance of
  function totalBalanceOf(address _of)
    public
    view
    returns (uint256 amount)
  {
    amount = balanceOf[_of];
    for (uint256 i = 0; i < lockReason[_of].length; i++) {
      amount = amount.add(tokensLocked(_of, lockReason[_of][i]));
    }
  }

  // @dev Returns the amount of unlockable tokens for a specified address for a specified reason
  // @param _of The address being checked
  // @param _reason The reason number of unlockable tokens is checked for
  // @notice How many tokens are unlockable for a specified reason for a specified address
  function tokensUnlockable(address _of, bytes32 _reason)
    public
    view
    returns (uint256 amount)
  {
    if (locked[_of][_reason].validity <= now && !locked[_of][_reason].claimed){
      amount = locked[_of][_reason].amount;
    }
  }

  // @dev Returns the total amount of all unlockable tokens for a specified address.
  // @param _of The address to query the unlockable token count of
  function getUnlockableTokens(address _of)
    public
    view
    returns (uint256 unlockableTokens)
  {
    for (uint256 i = 0; i < lockReason[_of].length; i++) {
      unlockableTokens = unlockableTokens.add(tokensUnlockable(_of, lockReason[_of][i]));
    }
  }
}