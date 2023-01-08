// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "../librairies/LibDiamond.sol";
contract Counter {
    // Function to get the current count
    function get() external view returns (uint256) {
        return LibCounterDiamond.diamondStorageCounter() ;
    }

    // Function to increment count by 1
    function inc() external {
        LibCounterDiamond.incrementCount(); 
    }

    // // Function to decrement count by 1
    // function dec() external {
    //     // This function will fail if count = 0
    //     count -= 1;
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;


library LibCounterDiamond {
    bytes32 constant DIAMOND_COUNTER_STORAGE_POSITION = keccak256("mydiamond.standard.diamond.counter");

    struct CounterStorage {
        uint256 count;
    }

    function diamondStorage() internal pure returns (CounterStorage storage counter) {
        bytes32 position = DIAMOND_COUNTER_STORAGE_POSITION;
        assembly {
            counter.slot := position
        }
    }
    function diamondStorageCounter() internal view  returns (uint256 _count) {       
        CounterStorage storage _counter = diamondStorage();
        _count = _counter.count;
    }
    function incrementCount() internal  {       
        CounterStorage storage _counter = diamondStorage();
        _counter.count ++ ;
    }
}