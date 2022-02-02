/**
 *Submitted for verification at Etherscan.io on 2022-02-02
*/

pragma solidity ^0.4.17;

contract Counter {
    uint256 count;  // persistent contract storage

    constructor(uint256 _count) public { 
        count = _count;
    }

    function increment() public {
        count += 1;
    }

    function getCount() public view returns (uint256) {
        return count;
    } 
}