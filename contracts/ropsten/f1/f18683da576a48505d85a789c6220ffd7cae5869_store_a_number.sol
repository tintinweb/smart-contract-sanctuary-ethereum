/**
 *Submitted for verification at Etherscan.io on 2022-02-28
*/

pragma solidity >=0.6.0 <0.9.0;

contract store_a_number{

    //this will store initialized to 0
    uint256 public CLNumber;

    function store(uint256 _CLNumber) public{
        CLNumber = _CLNumber;
    }

    //https://docs.soliditylang.org/en/v0.8.11/contracts.html
}