// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

library L {
    function concatenation(string calldata strL, string calldata strR) external pure returns (string memory) {
        return string(abi.encodePacked(strL, strR));
    }
}

/*
contract C {
    string public a = "HELLO";

    event Log(address target);

    function foo(string memory input) public {
        a = L.concatenation(a, input);
        emit Log(address(L));
    }
}
*/