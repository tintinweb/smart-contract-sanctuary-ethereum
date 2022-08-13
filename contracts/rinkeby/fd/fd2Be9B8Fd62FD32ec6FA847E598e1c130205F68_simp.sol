// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

contract simp {
    mapping(address=>uint) balances;

    function cme() public {
        balances[msg.sender] += 1;
    }

    function getBalance() public view returns (uint) {
        return balances[msg.sender];
    }

}