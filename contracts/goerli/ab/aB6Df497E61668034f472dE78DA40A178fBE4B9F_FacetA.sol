// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// A contract that implements Diamond Storage.
library LibA {

  // This struct contains state variables we care about.
  struct DiamondStorage {
    address owner;
    string dataA;
    uint256 number;
  }

  // Returns the struct from a specified position in contract storage
  // ds is short for DiamondStorage
  function diamondStorage() internal pure returns(DiamondStorage storage ds) {
    // Specifies a random position in contract storage
    // This can be done with a keccak256 hash of a unique string as is
    // done here or other schemes can be used such as this: 
    // bytes32 storagePosition = keccak256(abi.encodePacked(ERC1155.interfaceId, ERC1155.name, address(this)));
    bytes32 storagePosition = keccak256("diamond.storage.LibA");
    // Set the position of our struct in contract storage
    assembly {ds.slot := storagePosition}
  }
}

// Our facet uses the Diamond Storage defined above.
contract FacetA {

  function setDataA(string memory _dataA) external {
    LibA.DiamondStorage storage ds = LibA.diamondStorage();
    require(ds.owner == msg.sender, "Must be owner.");
    ds.dataA = _dataA;
  }

  function setDataA2(string memory _dataA) external {
    LibA.DiamondStorage storage ds = LibA.diamondStorage();
    ds.dataA = _dataA;
  }


  function setNumber(uint256 _number) external {
    LibA.DiamondStorage storage ds = LibA.diamondStorage();
    require(ds.owner == msg.sender, "Must be owner.");
    ds.number = _number;
  }

  function setNumber2(uint256 _number) external {
    LibA.DiamondStorage storage ds = LibA.diamondStorage();
    ds.number = _number;
  }

  function getDataA() external view returns (string memory) {
    return LibA.diamondStorage().dataA;
  }

  function getNumber() external view returns (uint256) {
    return LibA.diamondStorage().number;
  }
}