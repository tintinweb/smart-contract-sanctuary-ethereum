/**
 *Submitted for verification at Etherscan.io on 2023-03-15
*/

pragma solidity ^0.6.0;

// This contract keeps all Ether sent to it with no way
// to get it back.
//  This is example code. Do not use it in production.
contract Sink {
    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}