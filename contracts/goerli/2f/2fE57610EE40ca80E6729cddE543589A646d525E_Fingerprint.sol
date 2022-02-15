/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract Fingerprint {
    function fingerprint() public view returns (address,address,uint,uint,uint,bytes32,uint) {
        return (
            msg.sender, 
            tx.origin,
            tx.gasprice, 
            gasleft(),
            block.number, 
            blockhash(block.number - 1),
            block.timestamp);
    }
}