pragma solidity ^0.7.0;

contract AddressBook {
  // The address to store
  address public storedAddress;

  // Set the address
  function setAddress(address _address) public {
    storedAddress = _address;
  }
}