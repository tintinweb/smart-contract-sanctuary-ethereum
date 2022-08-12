//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./CloneFactory.sol";

interface FrameDataStore {
    function transferOwnership(address newOwner) external;
}

contract FrameDataStoreFactory is CloneFactory {
  address public libraryAddress;

  event FrameDataStoreCreated(address newAddress);

  constructor() {}

  function setLibraryAddress(address _libraryAddress) public  {
    require(libraryAddress == address(0), "Storage Factory: Library already set");
    libraryAddress = _libraryAddress;
  }

  function createFrameDataStore() public returns (address)  {
    address clone = createClone(libraryAddress);
    FrameDataStore(clone).transferOwnership(msg.sender);

    emit FrameDataStoreCreated(clone);
    return clone;
  }
}