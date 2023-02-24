/**
 *Submitted for verification at Etherscan.io on 2023-02-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract PersonalInfo {
    string private lastName;
    string private firstName;
    address private ethereumAddress;
    
    function setLastName(string memory _lastName) public {
        lastName = _lastName;
    }
    
    function setFirstName(string memory _firstName) public {
        firstName = _firstName;
    }
    
    function setEthereumAddress(address _ethereumAddress) public {
        ethereumAddress = _ethereumAddress;
    }
    
    function getLastName() public view returns (string memory) {
        return lastName;
    }
    
    function getFirstName() public view returns (string memory) {
        return firstName;
    }
    
    function getEthereumAddress() public view returns (address) {
        return ethereumAddress;
    }
}