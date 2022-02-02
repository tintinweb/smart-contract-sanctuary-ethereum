// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

contract FunTypes {
    uint256 tokenId;
    bool _publicMintLive = false; //is public mint active
    int _mintSupply = 1000; //fixed supply is 1000
    uint _amountOfTokensToMint; //how many tokens do you want to mint
    uint _mintPricePerToken; //price of 1 token to mint
    uint _totalCostToMint = _amountOfTokensToMint * _mintPricePerToken; //Operator: total cost to mint
    address _ownerAddress = 0xc9dD58f732f8a4bBa37b8160f74066226779ae4d; //contract owner address
    

    struct UserMinting { //structure for user mint details
        address useraddress;
        uint amountMinting;
        uint mintPriceTotal; 
    }
   

    uint[3] array;   // array of 3 uints

   mapping (address => uint) public balances;
    
}