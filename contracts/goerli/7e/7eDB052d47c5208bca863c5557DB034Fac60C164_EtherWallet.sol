//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract EtherWallet {
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    receive() external payable {}

    function withdraw(uint256 _amount) public {
        require(msg.sender == owner, "only owner can withdraw money");
        owner.transfer(_amount);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}