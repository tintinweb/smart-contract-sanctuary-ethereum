// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

// import "forge-std/Test.sol";
import {ICounter} from "src/interface/ICounter.sol";

contract Counter is ICounter {
    uint256 public number;
    bool public hogwild = false;

    function myFunction() external override {
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface ICounter {
    function myFunction() external;
}