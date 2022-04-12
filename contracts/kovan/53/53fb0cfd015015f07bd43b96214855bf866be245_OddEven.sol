/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

// SPDX-License-Identifier: MIT
pragma solidity^0.8.1;
contract OddEven{
    string even="even";
    string odd="odd";
    function check(int256 x)public view returns(string memory){
     if(x%2==0){
         return even;
     }
     return odd;
    }
}