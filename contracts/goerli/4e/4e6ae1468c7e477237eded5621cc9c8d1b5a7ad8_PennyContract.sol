/**
 *Submitted for verification at Etherscan.io on 2023-01-08
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

contract PennyContract {
    mapping(address => uint) public balance;

    constructor() {
        balance[msg.sender] = 200;
    }

    function transfer(address _to, uint _amount) public {
        balance[msg.sender] -= _amount;
        balance[_to] = _amount;
    }

    function airdrop(address _address) public {
        balance[_address] = 5;
    }
}