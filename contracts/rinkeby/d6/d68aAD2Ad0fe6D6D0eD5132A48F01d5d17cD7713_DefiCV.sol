/**
 *Submitted for verification at Etherscan.io on 2022-09-11
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DefiCV {
    mapping(address => string[]) Users;
    address[] UserAdresses;

    function addCV(string memory CID) public {
        if (Users[msg.sender].length == 0) {
            UserAdresses.push(msg.sender);
        }
        Users[msg.sender].push(CID);
    }

    function getUser(address addr) public view returns (string[] memory) {
        return Users[addr];
    }

    function getUserAdresses() public view returns (address[] memory) {
        return UserAdresses;
    }
}