/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
}

contract UtilityContract {

    struct BalanceOutput {
        IERC20 token;
        uint256 balance;
    }

    constructor() {}

    function getBalances(address walletAddress, IERC20[] calldata tokenAddresses) public view 
    returns (BalanceOutput[] memory) {

         BalanceOutput[] memory BalanceOutputArray = new BalanceOutput[](tokenAddresses.length);

        for (uint i = 0; i < tokenAddresses.length ; i ++) {
            IERC20 curToken = tokenAddresses[i];
            uint256 tokenBalance = curToken.balanceOf(walletAddress);
            BalanceOutput memory output = BalanceOutput(tokenAddresses[i],tokenBalance);
            BalanceOutputArray[i] = output;
        }

        return BalanceOutputArray;
    }
}