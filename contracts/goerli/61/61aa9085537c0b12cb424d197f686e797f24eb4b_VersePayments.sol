pragma solidity 0.8.13;
// SPDX-License-Identifier: MIT

import "./Ownable.sol";

interface IVersePayments {
    event Payment(string metadata, uint256 amount, address indexed buyer);
    event Refund(string metadata);

    function pay(string calldata metadata) external payable;

    function refund(
        string calldata metadata,
        uint256 amount,
        address buyer
    ) external;

    function withdraw() external;
}

contract VersePayments is Ownable, IVersePayments {
    address treasury;

    constructor(address treasury_) {
        treasury = treasury_;
    }

    function pay(string calldata metadata) public payable {
        emit Payment(metadata, msg.value, msg.sender);
    }

    function refund(
        string calldata metadata,
        uint256 amount,
        address buyer
    ) public onlyOwner {
        (bool sent, ) = buyer.call{value: amount}("");
        require(sent, "Failed to send Ether");
        emit Refund(metadata);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool sent, ) = treasury.call{value: balance}("");
        require(sent, "Failed to send Ether");
    }
}