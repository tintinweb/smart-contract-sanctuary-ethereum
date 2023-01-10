/**
 *Submitted for verification at Etherscan.io on 2023-01-09
*/

// SPDX-License-Identifier: MIT

//One day, while browsing the internet, Chad came across a new crypto token called Chad. 

//CHAD! 
//FREAKING CHAD!

//TELEGRAM: https://t.me/chadstoken
//TAXES: ZERO (sell 0 / buy 0)
//TEAM TOKENS: 2.5% chadDev, 2.5% chadMarketer

//He was immediately intrigued by the name, as it was the same as his own. 
//But what caught his attention was that this token had ZERO tax (0/0) on all buys and sells.

//...break...

//*Bites into his cheeseburger before reading the rest of the story.*

//...back to the story...

//Chad knew that this was a rare opportunity. He had always been interested in investing in cryptocurrency, but the high taxes had always deterred him. 
//He also didn't want to shill anything or spend hours in a chat room -- aint no body got time for dat -- amaright? 
//A chat may be okay lol. 
//Now, with the Chad token, he could invest as much as he wanted without worrying about additional costs.
//Excited by the prospect, Chad bought as many Chad Tokens as possible. 
//He didn't want to be just another Chad, he wanted to be a Mega CHAD, or shall I dare to say... A GIGA CHAD. 
//He spent the next few weeks carefully tracking the market and watching the value of his investment grow.
//As word of the Chad token spread, more people started to notice. 
//They were drawn in by the promise of zero taxes and the potential for big returns. 
//Soon, the Chad token was one of the most popular cryptocurrencies on the market.
//Chad was thrilled with his success. He had taken a risk by investing in a new and unknown token, but it had paid off significantly. 
//And as the value of the Chad token continued to rise, he knew he had made the right decision.
//Thanks to the Chad token, Chad had finally found a way to make his fortune in cryptocurrency. 
//And he was confident that with its zero tax policy, it would continue to be a lucrative investment for anyone who chose to buy in.
//This is Chad Token. 
//You Are Chad.

pragma solidity ^0.4.23;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

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

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

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

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
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

}

contract CHAD is StandardToken {

  string public constant name = "CHAD";
  string public constant symbol = "CHAD";
  uint8 public constant decimals = 18;

  uint256 public constant INITIAL_SUPPLY = 1000000000 * (10 ** uint256(decimals));

  constructor() public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
  }

}


//Now sit back and enjoy that cheesburger,CHAD!