/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract Domain {
    address owner;
    constructor(){
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    mapping(address => string) domains;
    event SetDomain(address indexed _address, string indexed _domain);

    function getDomain() public view returns (string memory _domain) {
        _domain = domains[msg.sender];
    }
    function setDomain(string memory _domain,address _address) payable public onlyOwner {
        domains[_address] = _domain;
        emit SetDomain(_address, _domain);
    }
}