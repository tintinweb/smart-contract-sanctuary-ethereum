/**
 *Submitted for verification at Etherscan.io on 2023-01-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract cellphone {

    function simple() public payable {

    }

    function withdraw() public {

        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);

    }

}