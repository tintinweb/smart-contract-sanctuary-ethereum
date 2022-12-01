/**
 *Submitted for verification at Etherscan.io on 2022-12-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BatchSend {
    address public admin;

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin {
        require(msg.sender == admin, "only admin");
        _;
    }

    function batchSend(address payable[] calldata receivers, uint amount) public payable onlyAdmin {
        require(amount > 0, "invalid amount");
        for (uint i=0; i<receivers.length; i++) {
            receivers[i].transfer(amount);
        }
        if (address(this).balance > 0) {
            payable(msg.sender).transfer(address(this).balance);
        }
    }
}