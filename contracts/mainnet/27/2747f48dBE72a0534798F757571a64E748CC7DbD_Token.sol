// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

contract Token  {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 500000000 * 10 ** 18 ;
    string public name = "MARA TOKEN";
    string public symbol = "MARA";
    uint public decimals = 18;
    uint transferFeePercentage = 5;
    address feeAccount = 0xAD4ac1eEF544212c277C46264A9E951053b9A302;
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
  function transfer(address _to, uint256 _value) public returns (bool) {
     require(_value%100 == 0);
        uint fee = _value * transferFeePercentage/100; // for 5% fee
        require (balances[msg.sender] > _value) ; // Check if the sender has enough balance
        require (balances[_to] + _value > balances[_to]); // Check for overflows
        balances[msg.sender] -= _value; // Subtract from the sender
        balances[_to] += (_value-fee); // Add the same to the recipient
        balances[feeAccount] += fee;
        return true;
  }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
}