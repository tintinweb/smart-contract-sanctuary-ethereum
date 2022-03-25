/**
 *Submitted for verification at Etherscan.io on 2022-03-25
*/

pragma solidity ^0.8.0;

contract Testfn {
    uint256 public supplies = 10000;
    function totalSupply() public view returns (uint256) {
        return supplies;
    }
}