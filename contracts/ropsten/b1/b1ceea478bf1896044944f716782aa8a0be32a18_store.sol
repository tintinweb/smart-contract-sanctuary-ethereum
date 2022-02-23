/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract store{
    uint256 public data;

    function StoreData(uint256 _data) public {
        data = _data;
    }
}