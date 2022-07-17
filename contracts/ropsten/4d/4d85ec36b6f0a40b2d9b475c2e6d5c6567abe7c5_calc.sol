/**
 *Submitted for verification at Etherscan.io on 2022-07-17
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.8.0;

contract calc {
    int private result;

    function add(int a, int b) public returns(int) {
        result = a + b;
        return result;
    }

    function getResult() public view returns (int) {
        return result;
    }


}