/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

pragma solidity ^0.8.0;

contract First_contract {
    uint256 public a = 0 ;
    function dodo() public returns(uint256){
        a += 1;
        return a;
    }
    function ad() public view returns(address){
        return address(this);
    }
}