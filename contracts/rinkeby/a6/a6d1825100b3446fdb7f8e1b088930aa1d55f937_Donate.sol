/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract Donate {

    address immutable i_owner;

    constructor() {
        i_owner = msg.sender;
    }

    receive() external payable {
        donate();
    }

    fallback() external payable {
        donate();
    }

    function donate() public payable {
        require(msg.value > 0, "Donate something!");
    }

    function withdraw() public {
        require(msg.sender == i_owner, "You're not the owner!");
        require(address(this).balance > 0, "No funds in contract!");
        payable(address(i_owner)).transfer(address(this).balance);
    }
    
}