//SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "./Proxiable.sol";

contract MyContract2 is Proxiable {

    address public owner;
    uint public count;
    bool public initalized = false;

    function initialize() public {
        require(owner == address(0), "Already initalized");
        require(!initalized, "Already initalized");
        owner = msg.sender;
        initalized = true;
    }

    function increment() public {
        count++;
    }

    function decrement() public {
        count--;
    }

    function updateCode(address newCode) onlyOwner public {
        updateCodeAddress(newCode);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed to perform this action");
        _;
    }
}