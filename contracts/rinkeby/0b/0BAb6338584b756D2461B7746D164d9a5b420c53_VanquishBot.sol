/**
 *Submitted for verification at Etherscan.io on 2022-04-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract VanquishBot {
    address payable public owner;
    address payable[] public shareHolders;

    uint fee = 50000000000000000;

    event subscribed(string userId);

    constructor() {
        owner = payable(msg.sender);
        shareHolders.push(payable(msg.sender));
        shareHolders.push(payable(0xEfbbF0E44314Aa73CCf4C52fe8df1BDcE96eB181));
        shareHolders.push(payable(0x54DfeaB519287296d7dD0f51AD8aA3F3e17916BC));
        shareHolders.push(payable(0xAae294756F17C0ef382a00b583D61d2852C1E9e2));
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
        for (uint i = 0; i < shareHolders.length; i++) {
            payable(shareHolders[i]).transfer(_amount/4);
        }
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