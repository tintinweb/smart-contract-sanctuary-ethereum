/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract indexedTest{
    event ind(uint256 indexed num);
    event WInd(uint256 num);

    function WithIndexed(uint256 a) public returns(uint256){        
        emit ind(a);
        return a;
    }

    function WithoutIndexed(uint256 a) public returns(uint256){        
        emit WInd(a);
        return a;
    }
}