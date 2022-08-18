// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/**
    @title SimpleStorage
    @dev Store and retrieve value for every sender that executes a transaction
*/

contract SimpleStorage {
    mapping(address => uint256) users;

    /**
        @dev store num against the address that called the transaction
        @param _num value to store
    */
    function store(uint256 _num) public virtual {
        users[msg.sender] = _num;
    }

    /**
        @dev retrieve value against the input address
    */
    function retrieve() public view returns (uint256) {
        return users[msg.sender];
    }
}