/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

pragma solidity ^0.8.0;

contract Trigger {
    event Triggered();

    function trigger() external {
        emit Triggered();
    }
}