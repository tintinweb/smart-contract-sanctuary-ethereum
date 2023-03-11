/**
 *Submitted for verification at Etherscan.io on 2023-03-11
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

contract Token {

    mapping (address => uint) public balances;

    constructor () {
        balances[0x9dC8812Cda50C7a00cacEa3dabf65739e6f30329] = 100;
    }

    function transfer(address target, uint amount ) public {
        require(balances[msg.sender] >= amount, "NOn hai abbastazna token");
        balances[msg.sender] = balances[msg.sender] - amount;
        balances[target] = balances[target] + amount;
    }
 


}