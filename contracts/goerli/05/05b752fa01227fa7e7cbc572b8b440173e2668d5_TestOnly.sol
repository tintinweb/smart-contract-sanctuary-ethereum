/**
 *Submitted for verification at Etherscan.io on 2023-02-03
*/

pragma solidity ^0.8.0;

contract TestOnly {
    event user(address indexed, string indexed);

    function upsertUser(string calldata _data) public {
        emit user(msg.sender, _data);
    }
}