/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

pragma solidity ^0.4.24;

contract MyToken {

    mapping(address => uint256) balances;
    
    constructor() {
        balances[msg.sender] = 10;
    }
    
    function transfer(address _to,uint256 _value) public{
        require(balances[msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]);
        
        balances[msg.sender] -= _value;
        balances[_to] += _value;
    }
    
    
}