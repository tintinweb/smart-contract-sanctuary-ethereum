/**
 *Submitted for verification at Etherscan.io on 2022-04-10
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.0;



// File: c4.sol

contract Beg {
    mapping(address => uint) public book;
    address payable owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier only {
        require(msg.sender == owner);
        _;
    }

    function donate() payable public {
        book[msg.sender] += msg.value / (10 ** 16);
    }

    function withdraw() payable public only {
        owner.transfer(address(this).balance);
    }
}