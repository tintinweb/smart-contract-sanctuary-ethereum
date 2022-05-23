//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.8.0;

import "./testA.sol";

contract testB {
    testA public _testA;
    constructor(address aAddress) {
        _testA = testA(aAddress);
    }

    function test() public {
        //bytes4 methodId = bytes4(keccak256(bytes('fun(address)')));
        //(bool success, ) = address(_testA).delegatecall(abi.encode(methodId, address(this)));
        //(bool success, ) = address(_testA).call(abi.encode(methodId, address(this)));
        //require(success, "MOTORN:fun error");
        _testA.fun(msg.sender, address(this));
    }
}