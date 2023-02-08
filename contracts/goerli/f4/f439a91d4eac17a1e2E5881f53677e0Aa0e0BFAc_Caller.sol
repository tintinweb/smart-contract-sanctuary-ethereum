// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract Caller {

    address public proxy;

    constructor(address _proxy){
        proxy = _proxy;
    }

    function increment() external returns(uint256){
        (,bytes memory data) = proxy.call(abi.encodeWithSignature("increment()"));
        return abi.decode(data,(uint));
    }
}