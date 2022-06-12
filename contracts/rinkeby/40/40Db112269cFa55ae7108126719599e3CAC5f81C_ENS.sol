// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// Could not transfer ether
error WithdrawFailed();

contract ENS {
    address public owner;

    string[] names;
    mapping(address => bool) public allAddresses;
    mapping(address => string) public addressToName;
    mapping(string => address) public nameToAddress;

    constructor() {
        owner = msg.sender;
    }

    modifier notZeroAddress(address _address) {
        require(_address != address(0), "Zero Addresses are not allowed!");
        _;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Only callable by owner!");
        _;
    }

    function changeOwner(address _newOwner)
        external
        onlyOwner
        notZeroAddress(_newOwner)
    {
        require(msg.sender == owner, "You're not the current owner!");

        owner = _newOwner;
    }

    function add(string calldata _name, address _address)
        external
        payable
        notZeroAddress(_address)
    {
        require(!allAddresses[_address], "Address already exists!");
        require(nameToAddress[_name] != address(0), "Name already exists!");
        require(msg.value == 1e18, "Insufficient Amount!");

        names.push(_name);
        allAddresses[_address] = true;
        addressToName[_address] = _name;
        nameToAddress[_name] = _address;
    }

    function get(string calldata _name) external view returns (address) {
        require(nameToAddress[_name] != address(0), "Name does not exist!");

        return nameToAddress[_name];
    }

    function validate(string calldata _name) external view returns (bool) {
        if (nameToAddress[_name] != address(0)) return true;
        return false;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner).call{value: address(this).balance}(
            ""
        );

        if (!success) {
            revert WithdrawFailed();
        }
    }
}