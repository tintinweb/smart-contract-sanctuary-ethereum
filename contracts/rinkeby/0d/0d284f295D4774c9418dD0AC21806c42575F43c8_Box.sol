// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
 
contract Box {
    uint256 private value;
    mapping(address=>uint256) public theMap;
 
    // Emitted when the stored value changes
    event ValueChanged(uint256 _value);
    event MappingAdded(address _address, uint _value);
 
    // Stores a new value in the contract
    function store(uint256 _value) public {
        value = _value;
        theMap[msg.sender] = _value;
        emit ValueChanged(_value);
        emit MappingAdded(msg.sender, _value);
    }
 
    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return value;
    }
}