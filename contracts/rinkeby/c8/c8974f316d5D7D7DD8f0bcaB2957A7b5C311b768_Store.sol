//SPDX-License-Identifier: MIT;
pragma solidity ^0.8.0;

contract Store {

    address storedUsers;

    function storedTransactions(address users) public payable {
        storedUsers = users;
    }

    function get() public view returns(address) {
        return storedUsers;
    }
}