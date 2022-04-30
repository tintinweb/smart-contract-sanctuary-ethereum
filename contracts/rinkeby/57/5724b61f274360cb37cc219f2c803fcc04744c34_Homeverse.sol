/**
 *Submitted for verification at Etherscan.io on 2022-04-30
*/

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

contract Homeverse {

    address payable _owner;

    constructor() public {
        _owner = payable(msg.sender);
    }

    function getAccessOfCourse () public payable {
        require(msg.value == 1.4 ether, "Needs 1.4 ether to purchase course");
        _owner.transfer(msg.value);
    }

    function getAccessOfMovie () public payable {
        require(msg.value == 0.0025 ether, "Needs 0.0025 ether to purchase movie");
        _owner.transfer(msg.value);
    }
}