// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract ExampleExternalContract {
    bool public completed;
    address public immutable i_owner;

    modifier onlyOwner() {
        require(msg.sender == i_owner, "Only Owner can run this method");
        _;
    }

    constructor() {
        i_owner = msg.sender;
    }

    function complete() public payable {
        completed = true;
    }

    function withdraw() external payable onlyOwner {
        require(address(this).balance > 0, "No balance found for this user");

        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) {
            revert("withdrawal failed");
        }
    }
}