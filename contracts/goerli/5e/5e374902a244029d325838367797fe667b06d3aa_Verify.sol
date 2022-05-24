// SPDX-License-Identifier: UNLICENSED
    pragma solidity =0.8.10;
    import {Unique} from "./unique.sol";
    contract Verify is Unique {
        address _a;
        address _b;
        address _c;
        address _d;
        constructor(address a, address b, address c, address d)  {
            _a = a;
            _b = b;
            _c = c;
            _d = d;
        }
    }

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.0;

contract Unique {
    uint public _timestamp = 1653349345389;
}