/**
 *Submitted for verification at Etherscan.io on 2022-08-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


contract MyToken  {
    bytes[] public data;
    constructor(bytes[] memory _data) {
        data = _data;
    }

    function setdata(bytes[] memory _data) public  {
        data = _data;
    }




}