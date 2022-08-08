/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

// contracts/ERC20Batch.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;


interface BaseContract {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract ERC20Batch {
    constructor () public {}

    function batchTransfer2(BaseContract tokenContractAddr, address[] calldata to, uint256[] calldata amount, uint num) public {
        for(uint i=0;i<num;++i){
            require(tokenContractAddr.transferFrom(msg.sender, to[i], amount[i]),"transferFrom failed!");
        }
    }
}