/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;
contract TestEvents{
    uint256 public count;
    event Mint(string mess, address indexed user);
    event Increment(uint256 count, address indexed user);

    function test(string memory _message) external{
        count++;
        emit Mint(_message, msg.sender);
        emit Increment(count, msg.sender);
    }
}