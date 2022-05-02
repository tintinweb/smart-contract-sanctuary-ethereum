// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Dao {
    mapping(address => bool) public members;

    constructor() {
        members[msg.sender] = true;
    }

    function addMember(address _newMember) external onlyMembers returns (bool) {
        members[_newMember] = true;
        return true;
    }

    receive() external payable {}

    modifier onlyMembers() {
        require(
            members[msg.sender] == true,
            "Only members can call this function"
        );
        _;
    }
}