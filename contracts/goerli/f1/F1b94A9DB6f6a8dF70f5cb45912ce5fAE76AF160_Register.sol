// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Register {
    /* State variables */
    string private s_info;
    address[] private s_storedInfo;
    mapping(address => string) s_AddressToInfo;

    // Functions
    function setInfo(string memory info) public {
        s_info = info;
        s_storedInfo.push(msg.sender);
        s_AddressToInfo[msg.sender] = info;
    }

    function getInfo() public view returns (string memory) {
        return s_info;
    }
}