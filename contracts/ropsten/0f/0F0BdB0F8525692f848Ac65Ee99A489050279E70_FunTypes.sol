/**
 *Submitted for verification at Etherscan.io on 2022-03-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

contract FunTypes {
    bool _saleActive = false; // states if the sale is active
    int _amountOwed = 1 ether; // amount owed by address
    uint256 _tokenId; // token ID 
    uint128 _maxPricePerItem = 1 ether; // price per token
    uint64 _quantity = 3; // amount of tokens bought or sold
    uint32 _publicSaleStartTime; 
    bytes32 _merkleRoot;
    string _Hello = "Greetings, Earthlings";
    address _ownerAdress = 0xD27171957005920e3596aD95c9151083952baDf2;
    mapping(address => uint256) allowlist;
    struct Lambo {
        string name;
        uint make;
        uint model;
        uint year;
        uint color;
        uint speed;
    Lambo[] lambos; 
    }
}