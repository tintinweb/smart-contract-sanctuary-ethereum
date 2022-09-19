/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract ValueTest {
    uint256 public _number = 1;
    uint256 public _number1 = _number +1;
    uint256 public number = 1;

    function Addpure(uint256 _number2) external pure returns(uint256 new_number){
        new_number = _number2 + 1;
    }

    function Addview() external view returns(uint256 new_number){
        new_number = number + 1;
    }
}