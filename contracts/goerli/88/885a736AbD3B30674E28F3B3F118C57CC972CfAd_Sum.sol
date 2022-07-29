/**
 *Submitted for verification at Etherscan.io on 2022-07-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract Sum {

    uint public Number;

    function ShowNumber() external view returns (uint){
        return Number;
    }

    function IncreaseNumber(uint Val) public {
        Number = Number + Val;
    }
    
    function DecreaseNumber(uint Val) public {
        Number = Number - Val;
    }

}