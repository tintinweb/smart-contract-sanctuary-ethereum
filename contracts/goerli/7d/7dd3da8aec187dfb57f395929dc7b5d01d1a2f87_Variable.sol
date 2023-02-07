/**
 *Submitted for verification at Etherscan.io on 2023-02-07
*/

//SPDX-License-Identifier:MIT

pragma solidity 0.8.17;

contract Variable {
    uint256 number;

    function add(uint256 num) public {
        number = number + num;
    }

    function reduce(uint256 num) public {
        number = number - num;
    }

    function set (uint256 num) public {
        number = num;
    } 

    function retrieve() public view returns (uint256){
        return number; 
    }

}