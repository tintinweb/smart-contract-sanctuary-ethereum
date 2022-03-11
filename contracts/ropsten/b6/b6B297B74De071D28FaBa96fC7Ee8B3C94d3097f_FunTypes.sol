/**
 *Submitted for verification at Etherscan.io on 2022-03-10
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

contract FunTypes {
    uint256 _tokenId; //token id
    bool _saleState = false; //sale state active yet
    int _totalSupply = 1000; //total supply of the collection
    address _owner = 0x3D88e71D6526e9e61c2D20aA8dcDaDDABe11ed5b; //address of owner that deployed contract
    bytes32 merkleRoot;
}