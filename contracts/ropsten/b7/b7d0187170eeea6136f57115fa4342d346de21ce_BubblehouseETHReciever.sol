/**
 *Submitted for verification at Etherscan.io on 2022-06-07
*/

// SPDX-License-Identifier: None
pragma solidity ^0.8.7;

contract BubblehouseETHReciever {
    address public owner;
    address public beneficiary;

    constructor() {
        beneficiary = msg.sender;
        owner = msg.sender;
    }

    function setBeneficiary(address newBeneficiary) public {
        require(msg.sender == owner, "Access forbidden!");
        beneficiary = newBeneficiary;
    }

    fallback() external payable {
        if (msg.value > 0) {
            payable(beneficiary).transfer(msg.value);
        }
    }

    receive() external payable {
        if (msg.value > 0) {
            payable(beneficiary).transfer(msg.value);
        }
    }    
}