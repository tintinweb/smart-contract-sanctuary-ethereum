/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.4.24;
// Math operations with safety checks
contract SafeMath {
  function safeMathMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
        return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function safeMathDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  function safeMathSub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }

  function safeMathAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }
}

contract SanYashToken is SafeMath{
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;

    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // Public event on the blockchain to notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Notifies clients about the burnt amount
    event Burn(address indexed from, uint256 value);
    
    // Notifies clients about the amount frozen 
    event Freeze(address indexed from, uint256 value);
    
    // Notifies clients about the amount unfrozen 
    event Unfreeze(address indexed from, uint256 value);

    constructor(uint256 initialSupply,string memory tokenName,uint8 decimalUnits,string memory tokenSymbol )  public {
        balanceOf[msg.sender] = initialSupply;  // Gives the creator all initial tokens            
        totalSupply = initialSupply;                    // Update total supply    
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               
        decimals = decimalUnits;                            
        owner = msg.sender;
    }

    modifier validAddress {
        assert(address(0x0) != msg.sender);
        _;
    }

    // Send coins
    function transfer(address _to, uint256 _value) public validAddress returns (bool success) {
        require(_value > 0);
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);        
        balanceOf[msg.sender] = SafeMath.safeMathSub(balanceOf[msg.sender], _value);
        balanceOf[_to] = SafeMath.safeMathAdd(balanceOf[_to], _value);
        emit Transfer(msg.sender, _to, _value);                   
        return true;
    }

    // Allow other contract to spend some tokens in your behalf 
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        require(_value > 0);
        allowance[msg.sender][_spender] = _value;
        return true;
    }
       

    // A contract attempts to get the coins
    function transferFrom(address _from, address _to, uint256 _value) public validAddress returns (bool success) {
        require(_value > 0); 
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        require(allowance[_from][msg.sender] >= _value);
        balanceOf[_from] = SafeMath.safeMathSub(balanceOf[_from], _value);                           
        balanceOf[_to] = SafeMath.safeMathAdd(balanceOf[_to], _value);                             
        allowance[_from][msg.sender] = SafeMath.safeMathSub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(_value > 0);
        balanceOf[msg.sender] = SafeMath.safeMathSub(balanceOf[msg.sender], _value);
        totalSupply = SafeMath.safeMathSub(totalSupply,_value);                     
        emit Burn(msg.sender, _value);
        return true;
    }
    
    function freeze(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(_value > 0);
        balanceOf[msg.sender] = SafeMath.safeMathSub(balanceOf[msg.sender], _value);                      
        freezeOf[msg.sender] = SafeMath.safeMathAdd(freezeOf[msg.sender], _value);                        
        emit Freeze(msg.sender, _value);
        return true;
    }
    
    function unfreeze(uint256 _value) public returns (bool success) {
        require(freezeOf[msg.sender] >= _value);
        require(_value > 0);
        freezeOf[msg.sender] = SafeMath.safeMathSub(freezeOf[msg.sender], _value);                      
        balanceOf[msg.sender] = SafeMath.safeMathAdd(balanceOf[msg.sender], _value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }    
}