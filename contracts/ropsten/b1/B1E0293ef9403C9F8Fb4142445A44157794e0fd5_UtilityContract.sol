// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface ERC20 {
    function balanceOf(address who) external view returns (uint256);
}

contract UtilityContract {

    struct ReturnBalance {
        address token;
        uint256 balance;
    }

    constructor() {}

    function getBalances(address walletAddr, address[] calldata tokenAddr) public view 
    returns (ReturnBalance[] memory) {

         ReturnBalance[] memory BalanceOutputArray = new ReturnBalance[](tokenAddr.length);

        for (uint i=0; i<tokenAddr.length ; i++) {
            // address curToken = ;
            uint256 tokenBalance = ERC20(tokenAddr[i]).balanceOf(walletAddr);
            // ReturnBalance memory output = ReturnBalance(tokenAddr[i],tokenBalance);
            // BalanceOutputArray[i] = output;
            BalanceOutputArray[i] = ReturnBalance(tokenAddr[i],tokenBalance);
        }

        return BalanceOutputArray;
    }
}