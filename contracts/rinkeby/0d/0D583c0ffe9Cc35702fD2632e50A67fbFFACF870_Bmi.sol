/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Bmi{

    string timeStamp;
    string bmi;

    function save(string memory tsp,string memory value) public {
        timeStamp= tsp;
        bmi= value;
    }

    function load() public view returns(string memory,string memory){
        return (timeStamp,bmi);
    }

}