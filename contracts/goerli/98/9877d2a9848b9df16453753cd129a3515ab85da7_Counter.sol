/**
 *Submitted for verification at Etherscan.io on 2023-01-15
*/

pragma solidity 0.8.0;

contract Counter {
    uint256 public count;

    function increaseCount() public {
        count = ++count;
    }

    function decreaseCount() public {
        count = --count;
    }
}