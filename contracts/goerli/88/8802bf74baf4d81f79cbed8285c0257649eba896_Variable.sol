/**
 *Submitted for verification at Etherscan.io on 2023-02-07
*/

//SPDX-License-Identifier:MIT
// File: contracts/3-2_regalia.sol

pragma solidity 0.8.17;

contract Variable {
    uint256 number;

    function add(uint256 num) public {
        number = number + num;
    }

    function reduce(uint256 num) public {
        number = number - num;
    }

    function retrieve() public view returns (uint256){
        return number; 
    }

}
// File: contracts/3-1_main.sol

contract newVariable is Variable {
    function set (uint256 num) public {
        number = num;
    } 
}