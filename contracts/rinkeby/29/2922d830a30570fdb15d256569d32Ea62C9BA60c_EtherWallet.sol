//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract EtherWallet {
    address payable public owner;
    uint8 public counter;

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    constructor() {
        owner = payable(msg.sender);
    }

    function withdraw(uint256 _amount) external {
        require(msg.sender == owner, "Only owner withdraws");
        payable(msg.sender).transfer(_amount);
    }

    function take() external payable {
        require(msg.value > 0, "Give eth");
        counter = counter;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}