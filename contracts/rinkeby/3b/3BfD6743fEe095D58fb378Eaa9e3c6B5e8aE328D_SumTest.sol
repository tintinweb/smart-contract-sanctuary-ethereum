/**
 *Submitted for verification at Etherscan.io on 2022-05-14
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract SumTest {
    mapping (address => uint) balances;
    constructor() {
        balances[address(this)] = 100;
    }
    
    function magicalSum() public view returns(uint){
        return balances[address(this)];
    }

    function addBalance(uint _extra) public {
        balances[address(this)] = balances[address(this)] + _extra;
    }

    function substractBalance(uint _get) public payable {
        require(msg.value >= 1 ether * _get, "You are so poor to buy it, sorry.");
        require(_get <= balances[address(this)], "No sum for you, sorry.");
        balances[address(this)] = balances[address(this)] - _get;
        balances[msg.sender] = balances[msg.sender] + _get;
    }
}