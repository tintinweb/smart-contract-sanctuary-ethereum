// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/LibAppStorage.sol";

contract StorageTest {
  AppStorage s;

  function myFacetFunction2() external {
    s.lastVar = s.firstVar + s.secondVar;
  }

  
  function readlastVar() external view returns(uint256) {
    return s.lastVar;
  }  
  function readlastVar2() external view returns(uint256) {
    AppStorage storage c = LibAppStorage.diamondStorage();
    return c.lastVar;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//LibAppStorage.sol

struct AppStorage {
  uint256 secondVar;
  uint256 firstVar;
  uint256 lastVar;
}

library LibAppStorage {

  function diamondStorage() 
    internal 
    pure 
    returns (AppStorage storage ds) {
      assembly {
        ds.slot := 0
      }
   }

  function myLibraryFunction() internal {
    AppStorage storage s = LibAppStorage.diamondStorage();
    s.lastVar = s.firstVar + s.secondVar;
  }

  function myLibraryFunction2(AppStorage storage s) internal {
    s.lastVar = s.firstVar + s.secondVar;
  }

  function retrieve() internal {
    AppStorage storage s = LibAppStorage.diamondStorage();
    s.lastVar = s.firstVar + s.secondVar;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// A contract that implements Diamond Storage.
library LibA {

  // This struct contains state variables we care about.
  struct DiamondStorage {
    address owner;
    bytes32 dataA;
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

  function setDataA(bytes32 _dataA) external {
    LibA.DiamondStorage storage ds = LibA.diamondStorage();
    require(ds.owner == msg.sender, "Must be owner.");
    ds.dataA = _dataA;
  }

  function setDataA2(bytes32 _dataA) external {
    LibA.DiamondStorage storage ds = LibA.diamondStorage();
    ds.dataA = _dataA;
  }

  function getDataA() external view returns (bytes32) {
    return LibA.diamondStorage().dataA;
  }
}