/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: Uphold LTD

pragma solidity ^0.8.7;

contract SendToAddress{

    // 0.001 eth
    uint amount = 0.001 ether;

    function send(address payable to) public payable {
        uint256 remaining = address(this).balance;

        if (remaining > amount) {
            to.transfer(amount);
        } else {
            to.transfer(remaining);
        }
    }

    receive() payable external {}
}