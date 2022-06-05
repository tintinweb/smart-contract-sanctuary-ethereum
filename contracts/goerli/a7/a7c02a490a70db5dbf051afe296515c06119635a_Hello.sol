// SPDX-License-Identifier: UNLICENSED
    pragma solidity =0.8.10;
    import {Unique} from "./unique.sol";
    library F {
        function f() public pure returns (uint256) {
            return 1;
        }
    }
    library C {
        function c() public pure returns (uint256) {
            return 2;
        }
    }
    interface HEVM {
        function startBroadcast() external;
    }

    contract Hello is Unique {
        function world() public {
            F.f();
            C.c();
        }
    }
    contract ScriptVerify {
        function run() public {
            address vm = address(bytes20(uint160(uint256(keccak256('hevm cheat code')))));
            HEVM(vm).startBroadcast();
            new Hello();
        }
    }

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.0;

contract Unique {
    uint public _timestamp = 1654436429016;
}