/**
 *Submitted for verification at Etherscan.io on 2022-03-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract SafeCheckLibrary{
    function WalletCollectionContains(address[] memory wallets, address _addr) public view returns (bool isVerified){
       for (uint i=0; i<wallets.length; i++) {
           if(wallets[i] == _addr){
               return true;
           }
       }
    }

    function killMe() public {
        selfdestruct(payable(address(0)));
    }
}