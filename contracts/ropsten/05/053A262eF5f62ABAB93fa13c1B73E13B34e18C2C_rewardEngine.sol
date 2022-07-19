/**
 *Submitted for verification at Etherscan.io on 2022-07-19
*/

// File: leeDAO/rewardEngine.sol

/* SPDX-License-Identifier: UNLICENSED */

pragma solidity ^0.8.0;

interface IBOBtoken {
    function mintBOB(address to, uint amount) external;

    function burnDRNK(address to, uint amount) external;
}

interface IJULtoken {
    function mintJUL(address to, uint amount) external;

    function burnJUL(uint amount) external;
}

contract rewardEngine {

    uint REALrate = 100;
    uint GOLDrate = 300;
    uint PROrate = 500;
    uint PURErate = 1000;

    uint REALid = 1;
    uint GOLDid = 2;
    uint PROid = 3;
    uint PUREid = 4;

    function walletToBOB(uint _walletType, uint _numOfWalletsSold, address _BOBaddress) public {
        require(_walletType == REALid || _walletType == GOLDid || _walletType == PROid || _walletType == PUREid, "Invalid Ballet Wallet Type");

        if (_walletType == REALid) {
            uint _amountOfBOB = (REALrate * _numOfWalletsSold);
            IBOBtoken(_BOBaddress).mintBOB(msg.sender, _amountOfBOB);
        } else if (_walletType == GOLDid) {
            uint _amountOfBOB = (GOLDrate * _numOfWalletsSold);
            IBOBtoken(_BOBaddress).mintBOB(msg.sender, _amountOfBOB);
        } else if (_walletType == PROid) {
            uint _amountOfBOB = (PROrate * _numOfWalletsSold);
            IBOBtoken(_BOBaddress).mintBOB(msg.sender, _amountOfBOB);
        } else {
            uint _amountOfBOB = (PURErate * _numOfWalletsSold);
            IBOBtoken(_BOBaddress).mintBOB(msg.sender, _amountOfBOB);
        }
        
    }

    function BOBtoJUL(uint _amountInBOB, address _BOBaddress, address _JULaddress) public {
        uint amountInJUL = _amountInBOB / 2;

        IBOBtoken(_BOBaddress).burnDRNK(msg.sender, _amountInBOB);

        IJULtoken(_JULaddress).mintJUL(msg.sender, amountInJUL);
    }

}