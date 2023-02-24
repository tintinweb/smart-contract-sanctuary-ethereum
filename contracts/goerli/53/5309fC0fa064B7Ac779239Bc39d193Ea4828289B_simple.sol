/**
 *Submitted for verification at Etherscan.io on 2023-02-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract simple {

    function test() public payable {

    }
   
    function withdraw() public {
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }

}