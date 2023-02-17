/**
 *Submitted for verification at Etherscan.io on 2023-02-17
*/

// SPDX-License-Identifier: MIT

pragma solidity = 0.8.17;

contract Calc {
    int counter = 0;

    function increase() external returns(int){
        int tempCount = counter;
        tempCount += 1;
        counter = tempCount;
        return(counter);
    }

    function reset() external returns(int){
        int tempCount = counter;
        tempCount = 0;
        counter = tempCount;
        return(counter);
    }

    function decrease() external returns(int){
        int tempCount = counter;
        tempCount -= 1;
        counter = tempCount;
        return(counter);
    }
}