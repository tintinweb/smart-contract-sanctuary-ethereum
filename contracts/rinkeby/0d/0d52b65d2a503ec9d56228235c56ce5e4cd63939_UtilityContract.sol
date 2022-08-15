/**
 *Submitted for verification at Etherscan.io on 2022-08-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract UtilityContract {

    IERC20 public currentToken;

    event Balance(uint256 amount);
    struct Output {
        IERC20 token;
        uint balance;
    }
    constructor() {
    }

    function getBalances(address walletAddress, IERC20[] calldata tokenAddresses ) 
    public
    returns (Output[] memory) {

         Output[] memory outputArray = new Output[](tokenAddresses.length);
        for (uint i = 0; i < tokenAddresses.length ; i ++) {
            currentToken = tokenAddresses[i];
            uint256 walletBalance = currentToken.balanceOf(walletAddress);
            Output memory o = Output(tokenAddresses[i],walletBalance);
            outputArray[i] = o;
        }
        return outputArray;

    }
}