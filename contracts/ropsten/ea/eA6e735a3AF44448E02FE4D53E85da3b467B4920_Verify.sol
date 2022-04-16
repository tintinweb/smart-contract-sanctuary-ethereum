/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

pragma solidity ^0.8.13;

contract Verify {
    bool public verified = true;
    uint public id;

    function counter() external {
        id += 1;
    }
}