/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MyContract {
    uint data;

    function setData(uint _data) external {
        data = _data;
    }

    function getData() external view returns(uint) {
        return data; 
    }
}