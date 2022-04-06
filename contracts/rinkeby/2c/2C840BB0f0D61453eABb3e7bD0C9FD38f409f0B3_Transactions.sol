// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title Transactions
/// @author cristianrisueo
/// @notice Makes a transaction from one account to another
contract Transactions {
    /// @notice Triggers a event with the transaction details after publishing the transaction
    /// @param sender The address of the sender
    /// @param receiver The address of the receiver
    /// @param amount The amount of token sent
    /// @param message The message sent with the transaction
    /// @param timestamp The timestamp of the transaction
    /// @param keyword The keyword used to trigger the event
    event Transfer(address sender, address receiver, uint amount, string message, uint256 timestamp, string keyword);

    /// @notice Just emits a event with the transaction details
    /// @param receiver The address of the receiver
    /// @param amount The amount of token sent
    /// @param message The message sent with the transaction
    /// @param keyword The keyword used to trigger the event
    function publishTransaction(address payable receiver, uint amount, string memory message, string memory keyword) public {
        emit Transfer(msg.sender, receiver, amount, message, block.timestamp, keyword); 
    }
}