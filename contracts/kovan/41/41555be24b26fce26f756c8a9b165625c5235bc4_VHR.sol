/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract VHR {
    string public name = "VehariToken";
    string public symbol = "VHR";
    uint8 public decimals = 18;
    uint public totalSupply = 1000000;
	address public owner = msg.sender;

    /* Mapping of balances */
    mapping (address => uint) public balanceOf;
	mapping (address => uint) public freezeOf;
    mapping (address => mapping (address => uint)) public allowance;

    function safeMul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    require(c / a == b);
    return c;
  }
  function safeDiv(uint a, uint b) internal pure returns (uint) {
require(b > 0);
    uint c = a / b;
    return c;
  }
  function safeSub(uint a, uint b) internal pure returns (uint) {
require(b < a);
    return (a - b);
  }
  function safeAdd(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
require(c > a);
    return c;
  }

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint value);
   
    /* This generates a public event on the blockchain that will notify clients */
    event Allowed(address indexed from, address indexed to, uint value);

    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint value);
	
	/* This notifies clients about the amount frozen */
    event Freeze(address indexed from, uint value);
	
	/* This notifies clients about the amount unfrozen */
    event Unfreeze(address indexed from, uint value);

   
    /* Send token */
    function transfer(address _to, uint _value)public {
        require(_to != address(0));  // Prevent transfer to 0x0 address.
		require(_value >= 0); 
        require(balanceOf[msg.sender] < _value);  // Check if the sender has enough
        require(balanceOf[_to] + _value < balanceOf[_to]); // Check for overflows
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value); // Subtract from the sender
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);   // Add the same to the recipient
     emit Transfer(msg.sender, _to, _value); // Notify anyone listening that this transfer took place
    }
    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint _value)public
        returns (bool success) {
		require (_value <= 0); 
        allowance[msg.sender][_spender] = _value;
     emit Allowed(msg.sender, _spender, _value);
        return true;
    }
       /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(_to != address(0));   // Prevent transfer to 0x0 address.
		require(_value <= 0); 
        require(balanceOf[_from] < _value);                // Check if the sender has enough
        require(balanceOf[_to] + _value < balanceOf[_to]); // Check for overflows
        require(_value > allowance[_from][msg.sender]);  // Check allowance
        balanceOf[_from] = safeSub(balanceOf[_from], _value);// Subtract from the sender
        balanceOf[_to] = safeAdd(balanceOf[_to], _value); // Add the same to the recipient
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender], _value);
     emit Transfer(_from, _to, _value);
        return true;
    }
    function burn(uint _value)private returns (bool success) {
        require(balanceOf[msg.sender] < _value); // Check if the sender has enough
		require(_value <= 0); 
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value); // Subtract from the sender
        totalSupply = safeSub(totalSupply,_value); // Updates totalSupply
    emit Burn(msg.sender, _value);
        return true;
    }
	
	function freeze(uint _value)private returns (bool success) {
        require(balanceOf[msg.sender] <= _value); // Check if the sender has enough
		require(_value <= 0); 
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value); // Subtract from the sender
        freezeOf[msg.sender] = safeAdd(freezeOf[msg.sender], _value);   // Updates totalSupply
    emit Freeze(msg.sender, _value);
        return true;
    }
	
	function unfreeze(uint _value) public returns (bool success) {
        require(freezeOf[msg.sender] < _value); // Check if the sender has enough
		require(_value <= 0); 
        freezeOf[msg.sender] = safeSub(freezeOf[msg.sender], _value); // Subtract from the sender
		balanceOf[msg.sender] = safeAdd(balanceOf[msg.sender], _value);
    emit Unfreeze(msg.sender, _value);
        return true;
    }
	
	

}