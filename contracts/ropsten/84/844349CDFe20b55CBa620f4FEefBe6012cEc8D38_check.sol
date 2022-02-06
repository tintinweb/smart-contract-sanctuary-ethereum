/**
 *Submitted for verification at Etherscan.io on 2022-02-06
*/

pragma solidity ^0.8.0;

contract check {
    function checkHash( ) public view returns (bytes32) {
        address user_ = msg.sender;
        bytes32 res = keccak256(abi.encodePacked(user_));
        return res;
    }
}