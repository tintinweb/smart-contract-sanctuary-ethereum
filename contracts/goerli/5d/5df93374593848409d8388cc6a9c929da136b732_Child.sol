/**
 *Submitted for verification at Etherscan.io on 2022-01-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


contract Child {
    uint256 a;
    uint256 b;
    address c;
    event Params(string caller, uint256 a, uint256 b, address c);

    constructor(uint256 _a, uint256 _b, address _c) {
        a = _a;
        b = _b;
        c = _c;
    }

    function delegateParent(address parent) public payable{
        emit Params("delegateParent", a, b, c);
        parent.delegatecall(abi.encodeWithSignature("call()"));
    }
}