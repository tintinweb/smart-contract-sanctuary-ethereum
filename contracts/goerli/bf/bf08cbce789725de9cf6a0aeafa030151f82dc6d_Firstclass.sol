/**
 *Submitted for verification at Etherscan.io on 2022-12-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Firstclass{
    string count = "MongHee ";
    function my_function() public view returns(string memory){ // view 는 read contract로 빠짐 지우면 write로 바뀜
       return count;
    }
}