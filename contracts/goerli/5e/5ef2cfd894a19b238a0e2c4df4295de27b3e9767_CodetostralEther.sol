/**
 *Submitted for verification at Etherscan.io on 2022-12-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
contract CodetostralEther {
    function buy() external payable {

    }

    function widthdraw() external {
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }
}