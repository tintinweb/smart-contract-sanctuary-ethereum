/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;


    contract Test {
        uint public balance;
        address public owner;

        constructor () public {
            owner = msg.sender;
        }

        function deposit () public payable {
            require(msg.value != 0, "Send more than 0");
            balance += msg.value;
        }

        function selfDestruct(address payable recipient) public {
            selfdestruct(recipient);
        }

        
    }