/**
 *Submitted for verification at Etherscan.io on 2022-05-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Storage {
    uint256 public data;

    function getData() public view returns (uint256) {
        return data;
    }

    function setData(uint256 _data) external {
      data = _data;
    } 
}