/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

pragma solidity ^0.8.4;

contract Storeage{
    uint256 number;

    function store(uint256 num) public{
        number = num;
    }

    function retrieve() public view returns (uint256){
        return number;
    }


}