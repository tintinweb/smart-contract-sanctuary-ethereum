// SPDX-License-Identifier: MIT
//pragma
pragma solidity ^0.8.0;

/**@title THe contract add two Numbers
 *@author Mustakim Nagori
 *@notice This simple contract will add two Numbers and purpose behind is to understand the stuff
 *@dev this implement two functions get and sum
 */
// contract
contract add {
    uint256 num1;
    uint256 num2;

    // public function
    ///@dev this setNum function will set the value 
    function setNum(uint256 x, uint256 y) public {
        num1 = x;
        num2 = y;
    }

    ///@dev this sum function will add num1 & num2
    ///@return , the sum of two number
    function sum() public view returns (uint256) {
        return num1 + num2;
    }
}