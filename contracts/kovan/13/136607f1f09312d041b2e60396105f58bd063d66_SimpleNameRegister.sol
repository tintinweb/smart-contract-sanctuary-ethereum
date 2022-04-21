// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract SimpleNameRegister {
    
    // map a string to an address to identify current owner
    mapping (string => address) public nameOwner;    

    // emit event when name is registered or relinquished
    event NameRegistered(address indexed owner, string indexed name);
    event NameRelinquished(address indexed owner, string indexed name);

    // register an available name
    function registerName(string memory _name) public {
        require(nameOwner[_name] == address(0), "The provided name has already been registered!");
        nameOwner[_name] = msg.sender;
        emit NameRegistered(msg.sender, _name);
    }

    //owner can relinquish a name that they own
    function relinquishName(string memory _name) public {
        require(nameOwner[_name] == msg.sender, "The provided name does not belong to you!");
        nameOwner[_name] = address(0);
        emit NameRelinquished(msg.sender, _name);
    }
}