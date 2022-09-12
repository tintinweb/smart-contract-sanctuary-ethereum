// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

// import "forge-std/Test.sol";
import {ICounter} from "./interface/ICounter.sol";
import {OtherContract} from "../script/folder/OtherContract.sol";

contract Counter is ICounter {
    uint256 public number;
    bool public hogwild = false;

    function myFunction() external override {
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface ICounter {
    function myFunction() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

contract OtherContract {}