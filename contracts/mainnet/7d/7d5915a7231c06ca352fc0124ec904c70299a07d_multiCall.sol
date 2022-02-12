/**
 *Submitted for verification at Etherscan.io on 2022-02-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IAirdrop {
    function transfer(address recipient, uint256 amount) external;
    function claim() external;
}

contract multiCall {
    function call(uint256 times) public {
        for(uint i=0;i<times;++i){
            new claimer();
        }
    }
}
contract claimer{
    constructor(){
        IAirdrop airdrop = IAirdrop(0x1c7E83f8C581a967940DBfa7984744646AE46b29);
        airdrop.claim();
        airdrop.transfer(address(tx.origin), 151200000000000000000000000);
        selfdestruct(payable(address(msg.sender)));
    }
}