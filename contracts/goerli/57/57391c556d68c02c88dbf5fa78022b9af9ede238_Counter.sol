// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// library F {
//     function f() public pure returns (uint) {
//         return 1;
//     }
// }

contract Counter {
    uint256 public number;

    // constructor() {
    //     F.f();
    // }

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }
}