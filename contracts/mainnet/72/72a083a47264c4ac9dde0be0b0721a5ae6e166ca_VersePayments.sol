pragma solidity 0.8.13;
// SPDX-License-Identifier: MIT

import "./Ownable.sol";

/**
 * @title Verse payments capturer
 * @author Verse
 * @notice This contract allows to capture ETH payments from private wallets that will be picked up by Verse platform.
 */
interface IVersePayments {
    /**
     * @dev Payment event is emitted when user pays to the contract, where `metadata` is used to identify the payment.
     */
    event Payment(string metadata, uint256 amount, address indexed buyer);

    /**
     * @dev Refund event is emited during refund, where `metadata` is used to identify the payment.
     */
    event Refund(string metadata);

    /**
     * @notice Pay method collects user payment for the item, where `metadata` is used to identify the payment and emits {Payment} event.
     */
    function pay(string calldata metadata) external payable;

    /**
     * @dev Refund method transfers user ETH and emits {Refund} event.
     */
    function refund(
        string calldata metadata,
        uint256 amount,
        address buyer
    ) external;

    /**
     * @dev Withdraw method transfers all collected ETH to the treasury wallet.
     */
    function withdraw() external;
}

/**
 * @title Verse payments capturer
 * @author Verse
 * @notice This contract allows to capture ETH payments from private wallets that will be picked up by Verse platform.
 */
contract VersePayments is Ownable, IVersePayments {
    address treasury;

    constructor(address treasury_) {
        treasury = treasury_;
    }

    /**
     * @notice Pay method collects user payment for the item, where `metadata` is used to identify the payment and emits {Payment} event.
     */
    function pay(string calldata metadata) public payable {
        emit Payment(metadata, msg.value, msg.sender);
    }

    /**
     * @dev Refund method transfers user ETH and emits {Refund} event.
     */
    function refund(
        string calldata metadata,
        uint256 amount,
        address buyer
    ) public onlyOwner {
        (bool sent, ) = buyer.call{value: amount}("");
        require(sent, "Failed to send Ether");
        emit Refund(metadata);
    }

    /**
     * @dev Withdraw method transfers all collected ETH to the treasury wallet.
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool sent, ) = treasury.call{value: balance}("");
        require(sent, "Failed to send Ether");
    }
}