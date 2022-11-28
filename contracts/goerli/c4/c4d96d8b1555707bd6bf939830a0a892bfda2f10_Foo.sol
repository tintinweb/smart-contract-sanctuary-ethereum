/**
 *Submitted for verification at Etherscan.io on 2022-11-28
*/

pragma solidity ^0.5.0;

contract Foo {
    uint256 x;

    function addOne() public {
        x = x + 1;
    }

    function getX() view public returns (uint256) {
        return x;
    }
}