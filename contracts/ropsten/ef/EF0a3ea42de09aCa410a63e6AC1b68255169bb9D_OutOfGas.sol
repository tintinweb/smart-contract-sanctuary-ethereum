//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
contract OutOfGas{
 
    mapping(address => uint) private _balances;
 
    constructor() {
        _balances[msg.sender] = 10000;
    }
 
    function get() external view returns(uint){
        return _balances[msg.sender];
    }
 
    function del() external {
        _balances[msg.sender] = 0; //Out of gas
    }
}