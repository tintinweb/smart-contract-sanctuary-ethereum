// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract HealthInsure{

    address private owner;
    mapping (address => bool) private authorized;

    struct User {
        bool isUidGenerated;
        string name;
        uint amountInsured;
    }

    mapping (address => User) public userMapping;
    mapping (address => bool) public doctorMapping;
    
    constructor() {
        owner = msg.sender;
        authorized[msg.sender] = true;
    }

    modifier onlyAuthorized() {
        require(authorized[msg.sender], "Not authorized");
        _;
    }

    function setDoctor(address _address) public onlyAuthorized {
        require(!doctorMapping[_address], "Doctor already authorized");
        doctorMapping[_address] = true; 
    }

    function setUser(string memory _name, uint _amountInsured) public onlyAuthorized returns (address) {
        bytes32 hash = sha256(abi.encodePacked(_name));
        address uniqueId = address(uint160(uint256(hash)));
        
        userMapping[uniqueId].name = _name;
        userMapping[uniqueId].amountInsured = _amountInsured;
        return uniqueId;
    }

    function useInsurance(address _uniqueId, uint _amountUsed) public onlyAuthorized returns (string memory) {
        require(doctorMapping[msg.sender], "Only doctor can use the insurance");
        require(userMapping[_uniqueId].amountInsured >= _amountUsed, "Insufficient insurance amount");

        userMapping[_uniqueId].amountInsured -= _amountUsed;
        return "Insurance has been successfully used.";
    }

    function authorize(address _address) public onlyAuthorized {
        authorized[_address] = true;
    }

    function revokeAuthorization(address _address) public onlyAuthorized {
        authorized[_address] = false;
    }
}