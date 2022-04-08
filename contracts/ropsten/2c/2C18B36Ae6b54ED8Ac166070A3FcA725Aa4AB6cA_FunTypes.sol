/**
 *Submitted for verification at Etherscan.io on 2022-04-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;


contract FunTypes {
    uint256 _tokenId;
    bool  _publicMint = false;  // Did public mint start? Default is set to false.      
    int  _tokensPerWalletLimit = 4; // set limit for the number of tokens a wallet can have couldn't do '<='
    uint8   _totalHoldingWallets;  // number of wallets holding the token 
    int _totalTokens = 10000; // total number of tokens available
    //_ownerRatio = (10 / _totalT23okens); // get and owners ratio 

    int _addition = (1 + 2);
    int _division = (2/2);

    address _projectAddress = address(this); // holds the address of the contract
    //address payable _buyerAddress = 0x123456; // address buyer ??
 
    uint _walletCollection;
    //address _allowList = _walletCollection[][5]; // collect a list of wallets for allowlist??


    // Arrarys
    uint[5] originAllowWallet; // array that holds 5 wallets from Origins
    uint[3] openEnroll; // open enrollemnt from 3 outside locations 
    uint[] _storage; // an array that holds multiple values 
    uint[] _bites; // holds a particular set of bytes, but i dont know what that is

    // Data Locations


    // Mapping Types
    uint KeyType;
    uint ValueType;
    uint balance;
    // mapping(KeyType => ValueType) funding;
    // mapping(address => balance) public _walletBalance; //tells the balance of a wallet

    // Operators

    uint8 y;
    uint16 z;
    uint32 x = y + z;


}

contract Sample {
    uint numAccess;  
}


// 6. Compile funTypes
// 7. Solidity Doc > Types 
// 8. Incorporate every possible type into the smart contract