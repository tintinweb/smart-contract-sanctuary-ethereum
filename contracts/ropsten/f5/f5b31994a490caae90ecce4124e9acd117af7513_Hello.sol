// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

interface HEVM {
    function startBroadcast() external;
}

contract Hello {
    function world() public {
    }
}
contract ScriptVerify {
    function run() public {
        address vm = address(bytes20(uint160(uint256(keccak256('hevm cheat code')))));
        HEVM(vm).startBroadcast();
        new Hello();
        new Hello();
    }
}