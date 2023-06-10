/**
 *Submitted for verification at Etherscan.io on 2023-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract StoreOfValue {
    uint public value;
    address public owner;

    constructor() payable {
        owner = 0x06f4DB783097c632B888669032B2905F70e08105;
        value = 0;
    }

    function getValue() public view returns (uint) {
        return value;
    }

    function increment() public {
        value += 1;
    }

    function setOwner(address newOwner) external {
        require(msg.sender == owner, "Only the current owner can set a new owner");
        owner = newOwner;
    }

    function withdraw() public {
        require(msg.sender == owner, "Only the owner can withdraw");
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable {}
    fallback() external payable {}
}