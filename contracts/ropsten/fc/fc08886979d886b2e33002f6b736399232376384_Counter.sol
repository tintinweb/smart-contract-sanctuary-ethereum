/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

pragma solidity 0.8.7;

contract Counter {
    uint256 public value;
    function increment(uint256 amount) public {
        value += amount;
    }
}