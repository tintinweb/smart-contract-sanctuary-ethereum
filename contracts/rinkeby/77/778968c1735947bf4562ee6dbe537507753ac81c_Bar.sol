// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Bar {
    function bar() view public {
        require(msg.sender == tx.origin, "msg.sender != tx.origin");
    }
}

contract Foo {
    constructor(Bar bar) {
        // bar.bar();
        (bool success, ) = address(bar).call(abi.encodeWithSignature("bar()"));
        payable(address(bar)).transfer(1 ether);
    }
}