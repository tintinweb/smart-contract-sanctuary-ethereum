// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import './CounterStorage.sol';

contract CounterFacet {
    using CounterStorage for CounterStorage.Data;

    function set(uint256 value) external {
        CounterStorage.data().counter = value;
        CounterStorage.data().lastCaller = msg.sender;
    }

    function add(uint256 value) external {
       CounterStorage.data().counter += value;
       CounterStorage.data().lastCaller = msg.sender;
    }

    function getValue() external view returns(uint256){
        return CounterStorage.data().counter;
    }

    function getLastCaller() external view returns(address){
        return CounterStorage.data().lastCaller;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

library CounterStorage {
  bytes32 internal constant STORAGE_SLOT = keccak256('diamond.storage.counter');
  
  struct Data {
    uint256 counter;
    address lastCaller;
  } 

  function data() internal pure returns(Data storage d) {
    bytes32 slot = STORAGE_SLOT;
    assembly {d.slot := slot}
  }
}