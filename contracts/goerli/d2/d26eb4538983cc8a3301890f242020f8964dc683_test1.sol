/**
 *Submitted for verification at Etherscan.io on 2022-12-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProxy {
    function execute(address,bytes memory) external;
}

contract test1 {
    function call(address proxy, address target) external returns (bool) {
        bytes memory data = encode(target);
        IProxy proxy = IProxy(proxy);
        proxy.execute(target, data);
        return true;
    }

    function encode(address target) internal returns (bytes memory) {
        return abi.encodeWithSignature("setNum(uint)", 111);
    }
}