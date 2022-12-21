/**
 *Submitted for verification at Etherscan.io on 2022-12-21
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.0 <0.9.0;

contract Storage {

    uint256 public number;
    event ret(address indexed user, uint256 num);

    function store(uint256 num) public {
        number = num;
    }


    function retrieve() public returns (uint256){
        emit ret(msg.sender,number);
        return number;
    }
}