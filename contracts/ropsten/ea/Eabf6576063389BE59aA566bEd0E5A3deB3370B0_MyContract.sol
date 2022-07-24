/**
 *Submitted for verification at Etherscan.io on 2022-07-23
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract MyContract {

    uint256 totalSupply = 10000000;

    mapping(address => uint256) balances;

    constructor() {
        balances[msg.sender] = totalSupply;
    }

    function send(address receiver, uint256 amount) public {
        balances[receiver] += amount;
        balances[msg.sender] -= amount;
    }

    function balanceOf(address wallet) public view returns(uint256) {
        return balances[wallet];
    }
}