/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

/*
https://t.me/finnishspitzETH
https://t.me/finnishspitzETH
https://t.me/finnishspitzETH
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;
contract FinnishFritz {

    uint256 number;
    function store(uint256 num) public {
        number = num;
    }
    function retrieve() public view returns (uint256){
        return number;
    }
}