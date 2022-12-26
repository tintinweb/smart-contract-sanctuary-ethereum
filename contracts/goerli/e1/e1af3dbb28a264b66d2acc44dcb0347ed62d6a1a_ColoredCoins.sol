/**
 *Submitted for verification at Etherscan.io on 2022-12-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ColoredCoins {

    struct ColoredWallet {
        uint256 numberOfRedCoins;
        uint256 numberOfBlueCoins;
        bool claimed;
    }

    mapping (address => ColoredWallet) public coloredWalletMapping;

    modifier notClaimedYet {
        require(!coloredWalletMapping[msg.sender].claimed, "User has claimed already");
        _;
    }

    modifier hasDestinationClaimed(address destination) {
        require(coloredWalletMapping[destination].claimed, "Destination is not claimed yet");
        _;
    }


    modifier sourceAndDestinationAreNotSame(address destination) {
        require(destination!= msg.sender, "Destination and source are same");
        _;
    }

    modifier hasEnoughBlueCoin(uint256 amount) {
        require(coloredWalletMapping[msg.sender].numberOfBlueCoins > amount, "User doesnt have enough blue coins");
        _;
    }

    function claim() public notClaimedYet {
        ColoredWallet memory coloredWallet  = ColoredWallet(0,100,true);
        coloredWalletMapping[msg.sender] = coloredWallet;
    }

    function swapBlueToRed(uint256 amount) public  hasEnoughBlueCoin(amount) {
        ColoredWallet memory coloredWallet =  coloredWalletMapping[msg.sender];
        coloredWallet.numberOfBlueCoins = coloredWallet.numberOfBlueCoins- amount;
        coloredWallet.numberOfRedCoins = coloredWallet.numberOfRedCoins +  amount * 2;
        coloredWalletMapping[msg.sender] = coloredWallet;
    }


    function transfer(uint256 amount, address destination) public  hasEnoughBlueCoin(amount) hasDestinationClaimed(destination)  sourceAndDestinationAreNotSame(destination)  {
        ColoredWallet memory sourceColoredWallet =  coloredWalletMapping[msg.sender];
        ColoredWallet memory destinationColoredWallet =  coloredWalletMapping[destination];

        sourceColoredWallet.numberOfBlueCoins = sourceColoredWallet.numberOfBlueCoins- amount;
        coloredWalletMapping[msg.sender] = sourceColoredWallet;

        destinationColoredWallet.numberOfBlueCoins = destinationColoredWallet.numberOfBlueCoins + amount;
        coloredWalletMapping[destination] = destinationColoredWallet;
    }
}