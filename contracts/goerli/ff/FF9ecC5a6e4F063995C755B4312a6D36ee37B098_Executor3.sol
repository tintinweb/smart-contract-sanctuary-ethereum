// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Executor3 {
    uint256 public count;
    address public proxy;

    // constructor(uint256 _count) Executor2(_count) {
    //     // count = _count;
    // }

    modifier onlyProxy() {
        require(msg.sender == proxy, "caller is not the proxy");
        _;
    }

    function increment() public onlyProxy {
        count++;
    }

    function decrease(uint number) public onlyProxy {
        count -= number;
    }
}