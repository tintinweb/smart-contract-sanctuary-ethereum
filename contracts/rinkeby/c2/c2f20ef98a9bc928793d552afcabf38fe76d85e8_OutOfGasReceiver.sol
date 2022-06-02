/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IAuctionHouse {
	function createBid(uint256 auctionId, uint256 amount) external payable;
}

contract OutOfGasReceiver {
	function createBid(address target, uint256 auctionId) public payable {
		IAuctionHouse(target).createBid{value: msg.value}(auctionId, msg.value);
	}

	receive() external payable {
		uint256 i;
		while(gasleft() > 10) {
			i++;
		}
	}
}