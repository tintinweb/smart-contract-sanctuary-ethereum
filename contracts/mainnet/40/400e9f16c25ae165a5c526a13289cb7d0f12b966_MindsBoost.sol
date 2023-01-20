/**
 *Submitted for verification at Etherscan.io on 2023-01-20
*/

// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

pragma solidity ^0.4.24;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: zeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: zeppelin-solidity/contracts/token/ERC20/BasicToken.sol

pragma solidity ^0.4.24;


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.4.24;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: zeppelin-solidity/contracts/token/ERC20/StandardToken.sol

pragma solidity ^0.4.24;


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.4.24;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: zeppelin-solidity/contracts/token/ERC20/MintableToken.sol

pragma solidity ^0.4.24;


/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address _to,
    uint256 _amount
  )
    hasMintPermission
    canMint
    public
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

// File: contracts/MindsToken.sol

pragma solidity ^0.4.24;

contract MindsToken is MintableToken {

    string public constant name = "Minds";
    string public constant symbol = "MINDS";
    uint8 public constant decimals = 18;

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        //call the spender function
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        require(_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        return true;
    }

}

// File: contracts/MindsBoostStorage.sol

pragma solidity ^0.4.24;


contract MindsBoostStorage is Ownable {

  struct Boost {
    address sender;
    address receiver;
    uint value;
    uint256 checksum;
    bool locked; //if the user has already interacted with
  }

  // Mapping of boosts by guid
  mapping(uint256 => Boost) public boosts;

  // Allowed contracts
  mapping(address => bool) public contracts;

  /**
   * Save the boost to the storage
   * @param guid The guid of the boost
   * @param sender The sender of the boost
   * @param receiver The receiver of the boost
   * @param value The value of the boost
   * @param locked If the boost is locked or not
   * @return bool
   */
  function upsert(uint256 guid, address sender, address receiver, uint value, uint256 checksum, bool locked) public returns (bool) {

    //only allow if transaction from an approved contract
    require(contracts[msg.sender]);

    Boost memory _boost = Boost(
      sender,
      receiver,
      value,
      checksum,
      locked
    );

    boosts[guid] = _boost;
    return true;
  }

  /**
   * Modify the allowed contracts that can write to this contract
   * @param addr The address of the contract
   * @param allowed True/False
   */
  function modifyContracts(address addr, bool allowed) public onlyOwner {
    contracts[addr] = allowed;
  }

}

// File: contracts/MindsBoost.sol

pragma solidity ^0.4.24;


contract MindsBoost {

  struct Boost {
    address sender;
    address receiver;
    uint value;
    uint256 checksum;
    bool locked; //if the user has already interacted with
  }

  MindsToken public token;
  MindsBoostStorage public s;

  /**
   * event for boost being created
   * @param guid - the guid of the boost
   */
  event BoostSent(uint256 guid);

  /**
   * event for boost being accepted
   * @param guid - the guid of the boost
   */
  event BoostAccepted(uint256 guid);

  /**
   * event for boost being rejected
   * @param guid - the guid of the boost
   */
  event BoostRejected(uint256 guid);

  /**
   * event for boost being revoked
   * @param guid - the guid of the boost
   */
  event BoostRevoked(uint256 guid);

  constructor(address _storage, address _token) public {
    s = MindsBoostStorage(_storage);
    token = MindsToken(_token);
  }

  function canIBoost() public view returns (bool) {
    uint balance = token.balanceOf(msg.sender);
    uint allowed = token.allowance(msg.sender, address(this));

    if (allowed > 0 && balance > 0) {
      return true;
    }

    return false;
  }

  function receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData) public returns (bool) {

    require(msg.sender == address(token));

    uint256 _guid = 0;
    address _receiver = 0x0;
    uint256 _checksum = 0;

    assembly {
      // Load the raw bytes into the respective variables to avoid any sort of costly
      // conversion.
      _checksum := mload(add(_extraData, 0x60))
      _guid := mload(add(_extraData, 0x40))
      _receiver := mload(add(_extraData, 0x20))
    }

    require(_receiver != 0x0);

    return boostFrom(_from, _guid, _receiver, _value, _checksum);
  }

  function boost(uint256 guid, address receiver, uint amount, uint256 checksum) public returns (bool) {
    return boostFrom(msg.sender, guid, receiver, amount, checksum);
  }

  function boostFrom(address sender, uint256 guid, address receiver, uint amount, uint256 checksum) private returns (bool) {

    //make sure our boost is for over 0
    require(amount > 0);

    Boost memory _boost;

    //get the boost
    (_boost.sender, _boost.receiver, _boost.value, _boost.checksum, _boost.locked) = s.boosts(guid);

    //must not exists
    require(_boost.sender == 0);
    require(_boost.receiver == 0);

    //spend tokens and store here
    token.transferFrom(sender, address(this), amount);

    //allow this contract to spend those tokens later
    token.increaseApproval(address(this), amount);

    //store boost
    s.upsert(guid, sender, receiver, amount, checksum, false);

    //send event
    emit BoostSent(guid);
    return true;
  }

  function accept(uint256 guid) public {

    Boost memory _boost;

    //get the boost
    (_boost.sender, _boost.receiver, _boost.value, _boost.checksum, _boost.locked) = s.boosts(guid);

    //do not do anything if we've aleady started accepting/rejecting
    require(_boost.locked == false);

    //check the receiver is the person accepting
    require(_boost.receiver == msg.sender);
    
    //lock
    s.upsert(guid, _boost.sender, _boost.receiver, _boost.value,  _boost.checksum, true);

    //send tokens to the receiver
    token.transferFrom(address(this), _boost.receiver, _boost.value);

    //send event
    emit BoostAccepted(guid);
  }

  function reject(uint256 guid) public {
    Boost memory _boost;

    //get the boost
    (_boost.sender, _boost.receiver, _boost.value, _boost.checksum, _boost.locked) = s.boosts(guid);

    //do not do anything if we've aleady started accepting/rejecting
    require(_boost.locked == false);

    //check the receiver is the person accepting
    require(_boost.receiver == msg.sender);
    
    //lock
    s.upsert(guid, _boost.sender, _boost.receiver, _boost.value, _boost.checksum, true);

    //send tokens back to sender
    token.transferFrom(address(this), _boost.sender, _boost.value);

    //send event
    emit BoostRejected(guid);
  }

  function revoke(uint256 guid) public {
    Boost memory _boost;

    //get the boost
    (_boost.sender, _boost.receiver, _boost.value, _boost.checksum, _boost.locked) = s.boosts(guid);

    //do not do anything if we've aleady started accepting/rejecting
    require(_boost.locked == false);

    //check the receiver is the person accepting
    require(_boost.sender == msg.sender);
    
    //lock
    s.upsert(guid, _boost.sender, _boost.receiver, _boost.value, _boost.checksum, true);

    //send tokens back to sender
    token.transferFrom(address(this), _boost.sender, _boost.value);

    //send event
    emit BoostRevoked(guid);
  }

}