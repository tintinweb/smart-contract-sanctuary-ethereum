/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

// SPDX-License-Identifier: None
pragma solidity ^0.8.7;

contract BubblehouseETHReciever {
    address public owner;
    address payable constant public beneficiary = payable(0xa500c2ab319C54ef4d3266508f9f215f72fD6a3a);

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