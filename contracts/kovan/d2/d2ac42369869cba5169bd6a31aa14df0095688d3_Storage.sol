/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Storage {

    uint256 number;
    event Stored(uint256 number,address sender);

    function store(uint256 num) public {
        number = num;
        emit Stored(num,msg.sender);
    }

    function retrieve() public view returns (uint256){
        return number;
    }
}