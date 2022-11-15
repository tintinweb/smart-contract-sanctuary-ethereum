// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;


contract PollideTest {
    string public tester = "tom";


    function getTester() public view returns (string memory) {
        return tester;
    }
}