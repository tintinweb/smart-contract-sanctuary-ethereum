/**
 *Submitted for verification at Etherscan.io on 2022-08-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Test {
    constructor(){
    }

    function getBalance(address[] memory adList)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        uint256[] memory balanceList = new uint256[](adList.length);


        for(uint256 i=0; i < adList.length;i++ ) {
            uint256 balance = address(adList[i]).balance;
            balanceList[i] = balance;
        }

        return balanceList;
    }

}