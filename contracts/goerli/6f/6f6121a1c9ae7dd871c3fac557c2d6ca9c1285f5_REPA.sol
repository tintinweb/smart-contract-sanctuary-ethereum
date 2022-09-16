/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract REPA {
    mapping(string => string) public subscriptions;

    function set(string memory _id, string memory _data) public {
        // string to bytes
        bytes memory tempTest = bytes(subscriptions[_id]);

        //require that the string is not empty
        require(tempTest.length == 0, "Subscription already exists");

        //set the value
        subscriptions[_id] = _data;
    }
}