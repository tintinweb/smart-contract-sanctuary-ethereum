/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

// Sources flattened with hardhat v2.9.1 https://hardhat.org

// File contracts/facets/ClaimUpdateFacet.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

contract ClaimUpdateFacet {
    event Claim(address indexed from, uint256 amount);
    event ClaimAll(address indexed from);

    /** 
    @notice Claim a specific amount of staked tokens of the sender
    (if amount is superior to number of tokens staked by the account, the amount of tokens staked will be released instead).
    @param amount The amount of token claimed.
     */
    function claim(uint256 amount) external payable {
        require(msg.value >= 0.0015 ether, "Not enough eth for transaction.");
        emit Claim(msg.sender, amount);
    }

    /// @notice Claim all staked tokens of the sender.
    function claimAll() external payable {
        require(msg.value >= 0.0015 ether, "Not enough eth for transaction.");
        emit ClaimAll(msg.sender);
    }
}