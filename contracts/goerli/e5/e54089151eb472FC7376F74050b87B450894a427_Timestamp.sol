/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

pragma solidity ^0.8.7;

contract Timestamp {

    uint public timestamp;

    function saveTimestamp() public {
        timestamp = block.timestamp;
    }

}