// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CryptoMyName {
    mapping(address => string) private userNames;
    mapping(string => address) private addresses;

    function registerUser(string memory _userName) public {
        require(checkNewUserName(_userName), "this name is already registered");
        require(checkNewAddress(msg.sender), "this address already has name");

        userNames[msg.sender] = _userName;
        addresses[_userName] = msg.sender;
    }

    function checkNewAddress(address _address) public view returns (bool) {
        return keccak256(abi.encodePacked(userNames[_address])) == keccak256(abi.encodePacked(""));
    }

    function checkNewUserName(string memory _userName) public view returns (bool) {
        return addresses[_userName] == address(0x0);
    }

    function getAddress(string memory _userName) public view returns (address) {
        return addresses[_userName];
    }

    function getUserName(address _address) public view returns (string memory) {
        return userNames[_address];
    }
}