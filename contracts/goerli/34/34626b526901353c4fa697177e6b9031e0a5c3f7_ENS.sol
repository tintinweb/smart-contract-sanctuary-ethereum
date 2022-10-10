/**
 *Submitted for verification at Etherscan.io on 2022-10-09
*/

pragma solidity ^0.8.13;

contract ENS {
    error ENS__Unauthorised();
    error ENS__AlreadyRegistered();

    event NameRegistered(string indexed name, address indexed owner);
    event NameUpdated(string indexed updatedName, address indexed updatedOwner);

    mapping(string => address) public nameToAddress;

    function register(string memory name) public payable {
        if (nameToAddress[name] != address(0)) revert ENS__AlreadyRegistered();
        nameToAddress[name] = msg.sender;
    }

    function update(string memory name, address addr) public payable {
        if (msg.sender != nameToAddress[name]) revert ENS__Unauthorised();
        nameToAddress[name] = addr;
    }
}