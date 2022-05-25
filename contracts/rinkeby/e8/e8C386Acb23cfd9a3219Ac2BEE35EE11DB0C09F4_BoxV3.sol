// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract BoxV3 {
    uint public val;

    //This func initializes only called once 
    // whne the first version of the contract is deployed(BOX)
    // we wont need this func anymore
    
    // function initialize(uint _val) external {
    //     val = _val;
    // }

    function dec() external {
        val -= 1;
    }
}