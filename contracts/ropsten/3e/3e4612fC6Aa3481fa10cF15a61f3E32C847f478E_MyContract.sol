pragma solidity ^0.5.0;


// Generic contract that is used to demonstrate domain registration during migration
contract MyContract {
    uint256 private storedValue = 0;

    function getValue() public view returns (uint256) {
        return storedValue;
    }

    function setValue(uint256 _newValue) public {
        storedValue = _newValue;
    }
}