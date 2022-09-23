/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Withdraw {
    address public owner;
    constructor() {
        owner = msg.sender;
    }

    function withdrawEthers() public payable {
        require(msg.sender==owner, "Caller is not Owner");
        payable(owner).transfer(address(this).balance);
    }
}