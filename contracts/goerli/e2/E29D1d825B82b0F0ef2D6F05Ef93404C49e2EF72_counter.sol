/**
 *Submitted for verification at Etherscan.io on 2023-02-22
*/

pragma solidity ^0.8.9;

contract counter {
    uint public count = 0;

    function incrementCount() public {
        count++;
    }
    function getCount() public view returns (uint) {
        return count;
    }
}