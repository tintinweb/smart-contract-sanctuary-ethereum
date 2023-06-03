// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract DepositWithdraw {
    address payable public owner;
    uint256 public constant PRESALE_HARD_CAP = 100 ether;
    uint256 public constant MAX_INDIVIDUAL_CONTRIBUTION = 1 ether;

    constructor() {
        owner = payable(msg.sender);
    }

    function contributeWhitelist(bytes32[] calldata proof) external payable {
        require(msg.value > 0, "E1");
    }

    function getTotalContribution() external view returns (uint256) {
        return address(this).balance;
    }

    function withdraw(uint256 amount) external {
        require(msg.sender == owner, "Only the owner can withdraw");
        require(amount <= address(this).balance, "Insufficient balance");

        owner.transfer(amount);
    }

    function withdrawAll() external {
        require(msg.sender == owner, "Only the owner can withdraw");
        require(address(this).balance > 0, "No balance to withdraw");

        owner.transfer(address(this).balance);
    }
}