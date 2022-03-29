/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract VanquishBot {
    address payable public owner;
    uint fee = 50000000000000000;

    event subscribed(string userId);

    constructor() {
        owner = payable(msg.sender);
    }

    receive() external payable {
    }

    function updateFee(uint256 newFee) public {
        require(msg.sender == owner, "caller is not owner!");
        fee = newFee;
    }

    function paySubscriptionFee(string memory userId) external payable {
        require(msg.value >= fee,"insufficient ethers paid!");
        emit subscribed(userId);
    }

    function withdraw(uint _amount) external {
        require(msg.sender == owner, "caller is not owner!");
        payable(msg.sender).transfer(_amount);
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }

    function sendEthToWallets(address payable[] memory _wallets) public payable {
        uint256 perWallet = msg.value/_wallets.length;
        for (uint32 i=0; i<_wallets.length; i++) {
            _wallets[i].call{value: perWallet}("");
        }
    }
}