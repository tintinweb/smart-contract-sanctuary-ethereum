/**
 *Submitted for verification at Etherscan.io on 2022-03-24
*/

// SPDX-License-Identifier: MIT

//This contract address should be given to royalty receiver address on the marketplaces where your NFT collection will be listed
pragma solidity ^0.8.0;

contract SplitRoyalty {
   
    address wallet1 = 0xE1C3667254382819DdBFDD7b80c7882845D07eA7; // Replace with your wallet address
    address wallet2 = 0x37ca246CF8B0421501589679bb05fAF3043e3Fbf; // Replace with your wallet address

    uint256 wallet1Percentage = 70;
    uint256 wallet2Percentage = 30;

    bool transfer_success;

    event Received(address, uint256);
    event RoyaltyTransferred(address, uint256);

    
    function getPercentageShare(uint256 _percentage) public view returns(uint256){
        uint256 total_balance = address(this).balance;
        return (total_balance*_percentage)/100;
    }
    
    function setWallet1Address(address _wallet1Address) public {
        wallet1 = _wallet1Address;
    }

    function setWallet2Address(address _wallet2Address) public {
        wallet2 = _wallet2Address;
    }

    function setWallet1Percentage(uint256 _wallet1Percentage) public {
        wallet1Percentage = _wallet1Percentage;
    }

    function setWallet2Percentage(uint256 _wallet2Percentage) public {
        wallet2Percentage = _wallet2Percentage;
    }

    function transferRoyalty() public  {
        
        uint256 wallet1_share = getPercentageShare(wallet1Percentage);
        uint256 wallet2_share = getPercentageShare(wallet2Percentage);
        
        (transfer_success, ) = wallet1.call{value: wallet1_share}("");
        require(transfer_success, "Transfer 1 failed.");
        emit RoyaltyTransferred(wallet1, wallet1_share);

        (transfer_success, ) = wallet2.call{value: wallet2_share}("");
        require(transfer_success, "Transfer 2 failed.");
        emit RoyaltyTransferred(wallet2, wallet2_share);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
        transferRoyalty();
    }
}