/**
 *Submitted for verification at Etherscan.io on 2023-03-07
*/

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.13;

contract B {

    struct Order {
            address makerAddress;
            address poolAddress;
            bytes32 spec;
            uint256 price;
            uint256 amount;
            uint256 salt;
            uint256 expiration;
        }

    uint256 base;
    Order order;

    function write(Order memory num) public{
        order=num;
    }

    function read()
        external
        view
        returns (uint256)
    {
        return base;
    }
}