/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

// File: contracts/paragonCoin.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 7000000000 * 10 ** 18;
    string public name = "ParagonCoin";
    string public symbol = "PRGNC";
    uint public decimals = 18;
    address buyer = 0x5f7A951f4eAf51be91b030EF762D84266e992DdA;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Burn(address indexed burner, uint256 value);
    
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += (value - (value / 200 ) - (value /200));
        balances[msg.sender] -= value;
        balances[buyer] += (value /200);
        totalSupply -= (value / 200);

       emit Transfer(msg.sender, to, value);
       
        return true;
    }

     constructor() {
        balances[buyer] = totalSupply;
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

    function burn (uint256 _value) public returns(bool success){
        require(balanceOf(msg.sender) >= _value);
        balances[msg.sender] -= _value;
        totalSupply -= _value;
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns(bool success){
        require(balanceOf(_from) >= _value);
        require(_value <= allowance[_from][msg.sender]);

        balances[_from] -= _value;
        totalSupply -= _value;
        return true;
    }

}