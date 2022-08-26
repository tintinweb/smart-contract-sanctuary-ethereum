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

}