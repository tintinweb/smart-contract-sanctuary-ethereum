/**
 *Submitted for verification at Etherscan.io on 2022-02-08
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
contract TestMint {
    mapping (address => uint256) public numClaimed;
    uint256 public maxTokensPerUser = 5;

    event Minted(address, uint256);
    function mint(uint numberOfTokens) external {
        require(numClaimed[msg.sender] <= maxTokensPerUser, "already maxed");
        require(numClaimed[msg.sender]+numberOfTokens <= maxTokensPerUser+1, "mint more than max");
        numClaimed[msg.sender] += numberOfTokens;
        emit Minted(msg.sender, numberOfTokens);
    }

    function resetNumClaimed() external {
        numClaimed[msg.sender] = 0;
    }

    function setMaxTokens(uint256 num) external {
        maxTokensPerUser = num;
    }

    function selfDestruct() external {
        selfdestruct(payable(msg.sender));
    }
}