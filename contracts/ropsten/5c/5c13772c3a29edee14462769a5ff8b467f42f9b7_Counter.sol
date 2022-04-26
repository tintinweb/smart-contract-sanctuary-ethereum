/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

pragma solidity ^0.4.24;

contract Counter {
    uint256 public count = 0;
    function increment() public {
        count += 1;
    }
    function getCount() public view returns (uint256) {
        return count;
    }
}