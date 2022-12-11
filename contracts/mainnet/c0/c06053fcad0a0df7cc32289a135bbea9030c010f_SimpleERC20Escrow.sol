/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @dev Caution: We assume all failed transfers cause reverts and ignore the returned bool.
interface IERC20 {
    function transfer(address,uint) external returns (bool);
    function transferFrom(address,address,uint) external returns (bool);
    function balanceOf(address) external view returns (uint);
}

/**
@title Simple ERC20 Escrow
@notice Collateral is stored in unique escrow contracts for every user and every market.
@dev Caution: This is a proxy implementation. Follow proxy pattern best practices
*/
contract SimpleERC20Escrow {
    address public market;
    IERC20 public token;
    
    /**
    @notice Initialize escrow with a token
    @dev Must be called right after proxy is created
    @param _token The IERC20 token to be stored in this specific escrow
    */
    function initialize(IERC20 _token, address) public {
        require(market == address(0), "ALREADY INITIALIZED");
        market = msg.sender;
        token = _token;
    }
    
    /**
    @notice Transfers the associated ERC20 token to a recipient.
    @param recipient The address to receive payment from the escrow
    @param amount The amount of ERC20 token to be transferred.
    */
    function pay(address recipient, uint amount) public {
        require(msg.sender == market, "ONLY MARKET");
        token.transfer(recipient, amount);
    }

    /**
    @notice Get the token balance of the escrow
    @return Uint representing the token balance of the escrow
    */
    function balance() public view returns (uint) {
        return token.balanceOf(address(this));
    }

    /**
    @notice Function called by market on deposit. Function is empty for this escrow.
    @dev This function should remain callable by anyone to handle direct inbound transfers.
    */
    function onDeposit() public {

    }
}