/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

pragma solidity ^0.8.11;

contract Storage 
{
    uint256 number;
    function store (uint _num) public {
        number = _num;
    }
    function retrieve() public view returns (uint256) {
        return number;
    }
}