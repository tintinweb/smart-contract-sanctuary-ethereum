//  SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Airdropper {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    function withdrawEther() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether balance to withdraw.");
        payable(msg.sender).transfer(balance);
    }

    function withdrawToken(IERC20 token, uint256 amount) external onlyOwner {
        require(amount > 0, "Invalid token amount.");
        require(token.transfer(msg.sender, amount), "Token transfer failed.");
    }

    function _AirdropEther(address[] calldata recipients, uint256[] calldata values) external payable {
        require(recipients.length == values.length, "Array length mismatch.");

        for (uint256 i = 0; i < recipients.length; i++) {
            require(values[i] > 0, "Invalid ether value.");

            (bool success, ) = recipients[i].call{value: values[i]}("");
            require(success, "Ether transfer failed.");
        }

        uint256 contractBalance = address(this).balance;
        if (contractBalance > 0) {
            (bool success, ) = msg.sender.call{value: contractBalance}("");
            require(success, "Ether transfer failed.");
        }
    }

    function _AirdropToken(IERC20 token, address[] calldata recipients, uint256[] calldata values) external {
        require(recipients.length == values.length, "Array length mismatch.");

        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            require(values[i] > 0, "Invalid token value.");
            total += values[i];
        }

        require(token.transferFrom(msg.sender, address(this), total), "Token transfer failed.");

        for (uint256 i = 0; i < recipients.length; i++) {
            require(token.transfer(recipients[i], values[i]), "Token transfer failed.");
        }
    }

    function _AirdropTokenSimple(IERC20 token, address[] calldata recipients, uint256[] calldata values) external {
        require(recipients.length == values.length, "Array length mismatch.");

        for (uint256 i = 0; i < recipients.length; i++) {
            require(values[i] > 0, "Invalid token value.");
            require(token.transferFrom(msg.sender, recipients[i], values[i]), "Token transfer failed.");
        }
    }
}