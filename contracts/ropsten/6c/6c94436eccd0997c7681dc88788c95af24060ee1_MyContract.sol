/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

contract MyContract {
    mapping(address => uint) public balance;

    constructor() {
        balance[msg.sender] = 100;
    }

    function transfer(address to, uint amount) public {
        balance[msg.sender] -= amount;
        balance[to] += amount;
    }

    function someCrypticFunctionName(address _addr) public view returns(uint) {
        return balance[_addr];
    }
    receive() external payable{}
}