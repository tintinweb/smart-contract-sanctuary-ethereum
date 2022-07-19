/**
 *Submitted for verification at Etherscan.io on 2022-07-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract crypto318 {

    
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;

    
    mapping(address => uint256) public balance;
    mapping(address => mapping(address => uint256)) public allowance;

    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        name = "sena vetus civitas";
        symbol = "svc";
        decimals = 18;
        totalSupply = 1000000000000000000000000; 
        balance[msg.sender] = totalSupply;
    }

   
    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(balance[msg.sender] >= _value);
        _transfer(msg.sender, _to, _value);
        return true;
    }

    
    function _transfer(address _from, address _to, uint256 _value) internal {
        
        require(_to != address(0));
        balance[_from] = balance[_from] - (_value);
        balance[_to] = balance[_to] + (_value);
        emit Transfer(_from, _to, _value);
    }


    function balanceOf(address tokenOwner) public view returns (uint balances) {
        return balance[tokenOwner];
    }

    
    function approve(address _spender, uint256 _value) external returns (bool) {
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

 
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_value <= balance[_from]);
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = allowance[_from][msg.sender] - (_value);
        _transfer(_from, _to, _value);
        return true;
    }

}