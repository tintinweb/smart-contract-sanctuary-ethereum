/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

contract Homeverse {

    address payable _owner;

    constructor() public {
        _owner = payable(msg.sender);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getAccessOfCourse () public payable {
        require(msg.value == 0.014 ether, "Needs 1.4 ether to purchase course");
        _owner.transfer(msg.value);
    }
}