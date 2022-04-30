/**
 *Submitted for verification at Etherscan.io on 2022-04-30
*/

/*
https://steemit.com/kr/@kblock/64-upgradable-smart-contract
*/

pragma solidity ^0.4.24;


library SafeMath {


  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;
  
  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  }

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20 {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  mapping (address => mapping (address => uint256)) internal allowed;

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }


  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to == address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
}

contract MyToken is StandardToken {

  string public name;
  string public symbol;
  uint8 public decimals;

  /**
   * @dev Constructor that gives msg.sender all of existing tokens.
   */
  constructor(string _name, string _symbol, uint8 _decimals, uint256 _initial_supply) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    
    totalSupply_ = _initial_supply;
    balances[msg.sender] = _initial_supply;
    emit Transfer(0x0, msg.sender, _initial_supply);
  }
}

contract UpgradableToken is MyToken, Ownable {
  StandardToken public functionBase;
  
  constructor()
    MyToken("Upgradable Token", "UGT", 18, 10e28) public
  {
    functionBase = new StandardToken();
  }
  
  function setFunctionBase(address _base) onlyOwner public {
    require(_base != address(0) && functionBase != _base);
    functionBase = StandardToken(_base);
  }
  
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(address(functionBase).delegatecall(0xa9059cbb, _to, _value));
    return true;
  }
}





contract StandardToken2 is ERC20 {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
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
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
}