/**
 *Submitted for verification at Etherscan.io on 2022-07-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title RojaMe
/// @author LeProfCode
/// @notice This contract is for creators and artists to accept tips in BNB
contract RojaMeFunds {
    /// @notice Mapping user address to proceeds
    mapping(address => uint256) private _funds;

    /// @notice This event is emitted when the contract receives an ether
    /// @dev Using events to get the sender message and details using an indexing protocol
    /// @param receiver Receiver address
    /// @param sender Sender address
    /// @param amount The amount
    /// @param name Name of the sender
    /// @param message Message from the sender
    event Roja(
        address indexed receiver,
        address indexed sender,
        uint256 indexed amount,
        string name,
        string message
    );

    /// @notice Sends BNB to the contract
    /// @dev Using pull over push method
    /// @param receiver Receiver address
    /// @param name Name of the sender
    /// @param message Message from the sender
    function RojaMe(
        address receiver,
        string memory name,
        string memory message
    ) external payable {
        require(msg.value > 1, "Not enough BNB");

        // Could just send the money...
        // https://fravoll.github.io/solidity-patterns/pull_over_push.html
        _funds[receiver] += msg.value;
        emit Roja(receiver, msg.sender, msg.value, name, message);
    }

    /// @notice Transfers the amount that an address have
    function withdrawRoja() external {
        uint256 proceeds = _funds[msg.sender];
        require (proceeds > 0, "Not enough Roja");

        _funds[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: proceeds}("");
        require(success, "Transfer failed");
    }

    /// @return Roja balance of the address
    function getRojaBalance(address walletAddress) external view returns (uint256) {
        return _funds[walletAddress];
    }
}