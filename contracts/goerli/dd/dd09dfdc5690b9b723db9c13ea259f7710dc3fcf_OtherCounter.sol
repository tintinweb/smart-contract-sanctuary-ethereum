// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Counter {
    uint256 public number;

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Counter} from "./Counter.sol";

contract OtherCounter {
    uint256 public number;
    address public constant CounterAddress = 0x694886Fa8d41c138AdBfb98AdFD4450383a173dd;
    
    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }

    function incrementOther() public {
        Counter(CounterAddress).increment();
    }

    function setNumberOther(uint256 newNumber) public {
        Counter(CounterAddress).setNumber(newNumber);
    }

    function getNumberOther() public view returns (uint256) {
        return Counter(CounterAddress).number();
    }
}