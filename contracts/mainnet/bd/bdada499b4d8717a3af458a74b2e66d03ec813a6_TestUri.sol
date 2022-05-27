/**
 *Submitted for verification at Etherscan.io on 2022-05-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

error NotOwner();

contract TestUri{
    address public immutable owner;
    string public baseURI;

    constructor(string memory _baseURI) {
        owner = msg.sender;
        baseURI = _baseURI;
    }

    function setBaseURI(string calldata newURI) public onlyOwner {
        baseURI = newURI;
    }

    modifier onlyOwner {
        if (msg.sender != owner) revert NotOwner();
        _;
    }
}