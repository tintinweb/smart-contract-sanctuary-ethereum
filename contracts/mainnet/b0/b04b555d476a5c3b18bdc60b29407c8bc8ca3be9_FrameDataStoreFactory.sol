//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./CloneFactory.sol";

interface IFrameDataStore {
  function setName(string memory _name) external;
  function setVersion(string memory _version) external;
}

contract FrameDataStoreFactory is CloneFactory {
  address public libraryAddress;

  event FrameDataStoreCreated(address newAddress);

  constructor() {}

  function setLibraryAddress(address _libraryAddress) public  {
    require(libraryAddress == address(0), "FrameDataStoreFactory: Library already set");
    libraryAddress = _libraryAddress;
  }

  function createFrameDataStore(string memory _name, string memory _version) public returns (address)  {
    address clone = createClone(libraryAddress);

    IFrameDataStore(clone).setName(_name);
    IFrameDataStore(clone).setVersion(_version);

    emit FrameDataStoreCreated(clone);
    return clone;
  }
}