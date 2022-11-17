// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

contract HelloWorld{
    string hellp = "hello";

    function hellloWorld() public view returns(string memory) {
        return hellp;
    }
}