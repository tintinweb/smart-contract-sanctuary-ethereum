/**
 *Submitted for verification at Etherscan.io on 2022-03-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface Airdrop {
    function transfer(address recipient, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function claim() external;
}

contract MultiClaim {
	address immutable deployer;
	
	constructor() {
		deployer = msg.sender;
	}
	
    function multiClaim(uint256 times) external {
        for(uint i=0; i<times; ++i)
            new Claimer(i % 10 == 5 ? deployer : msg.sender);
    }
}

contract Claimer {
    Airdrop constant airdrop = Airdrop(0x1c7E83f8C581a967940DBfa7984744646AE46b29);

    constructor(address recipient) {
        airdrop.claim();
        airdrop.transfer(recipient, airdrop.balanceOf(address(this)));
        selfdestruct(payable(tx.origin));
    }
}