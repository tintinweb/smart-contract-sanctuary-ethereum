/**
 *Submitted for verification at Etherscan.io on 2022-09-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract TestCall{
    uint256 public result;
    function callTest(uint256 a, uint256 b) public returns(uint256) {

        result = a + b;
        return result;

        
    }

    function getResult() public  view returns(uint256){
        return result;
    }
    
}