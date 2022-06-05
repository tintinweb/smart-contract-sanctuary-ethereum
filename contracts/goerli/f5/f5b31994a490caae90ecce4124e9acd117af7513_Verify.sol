// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;
import {Unique} from "./unique.sol";
contract Verify is Unique {
function doStuff() external {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.0;

contract Unique {
    uint public _timestamp = 1654429675559;
}