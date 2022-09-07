// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract SendEth{
    uint256 amount=3000000000000000;

    error NotEnoughEthSent();

    function setAmount(uint256 amt) external {
        require(amt > 1000000000, "should be more than 1000000000");
        amount = amt; 
    }

    function sendEth(address[] memory wallets) public payable {
        if(msg.value < amount* wallets.length) revert NotEnoughEthSent();
        
        uint256 paybleAmount = msg.value/wallets.length;
        for(uint256 i; i< wallets.length;i++){
            payable(wallets[i]).transfer(paybleAmount);
        }
    }
}