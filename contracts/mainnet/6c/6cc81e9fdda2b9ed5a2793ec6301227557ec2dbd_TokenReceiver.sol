/**
 *Submitted for verification at Etherscan.io on 2022-12-19
*/

pragma solidity ^0.6.0;

// This is the contract's ABI (Application Binary Interface).
// It defines the functions and variables that can be called on the contract.
contract TokenReceiver {
    // This is an event that will be triggered when the contract receives a token.
    event TokenReceived(address sender, uint256 value);

    // This is the function that will be called when the contract receives a token.
    function receiveToken(uint256 value) public {
        // Trigger the TokenReceived event with the sender and value of the token.
        emit TokenReceived(msg.sender, value);
    }
}