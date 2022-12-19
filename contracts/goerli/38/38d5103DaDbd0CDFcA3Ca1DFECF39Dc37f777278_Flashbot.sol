/**
 *Submitted for verification at Etherscan.io on 2022-12-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Flashbot {

    uint256 number;
    uint256 calling;
  
    function store(uint256 num) public {
        calling = num;
        require(number != num, "value already store");
        number = num;
    }

    function retrieve() public view returns (uint256){
        return number;
    }
}