// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

error CrypTip__ValueMustBeAboveZero();
error CrypTip__NoTips();

/// @title cryptip.me
/// @author web3slinger
/// @notice This contract is for creators and artists to accept support by receiving ether
contract CrypTip {
    /// @notice Mapping user address to proceeds
    mapping(address => uint256) private s_tips;

    /// @notice This event is emitted when the contract receives an ether
    /// @dev Using events to get the sender message and details using an indexing protocol
    /// @param receiver Receiver address
    /// @param sender Sender address
    /// @param amount The amount
    /// @param timestamp Transaction timestamp
    /// @param name Name of the sender
    /// @param message Message from the sender
    event Tip(
        address indexed receiver,
        address indexed sender,
        uint256 indexed amount,
        uint256 timestamp,
        string name,
        string message
    );

    /// @notice Sends ether to the contract
    /// @dev Using pull over push method
    /// @param receiver Receiver address
    /// @param name Name of the sender
    /// @param message Message from the sender
    function sendTip(
        address receiver,
        string memory name,
        string memory message
    ) public payable {
        if (msg.value <= 0) revert CrypTip__ValueMustBeAboveZero();

        // Could just send the money...
        // https://fravoll.github.io/solidity-patterns/pull_over_push.html
        s_tips[receiver] += msg.value;
        emit Tip(receiver, msg.sender, msg.value, block.timestamp, name, message);
    }

    /// @notice Transfers the amount that an address have
    function withdrawTips() external {
        uint256 proceeds = s_tips[msg.sender];
        if (proceeds <= 0) revert CrypTip__NoTips();

        s_tips[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: proceeds}("");
        require(success, "Transfer failed");
    }

    /// @return Tip balance of the address
    function getTipBalance(address _address) external view returns (uint256) {
        return s_tips[_address];
    }
}