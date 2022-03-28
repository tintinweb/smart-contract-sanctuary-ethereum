/**
 *Submitted for verification at Etherscan.io on 2022-03-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IETH {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);


    function transfer(address recipient, uint256 amount) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);


    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface INFTDatabase {
    function mint(address to, string memory _tokenURI) external returns (uint256);

    function burn(uint256 tokenId) external returns (uint256);

    function totalSupply() external view returns (uint256);
}


contract MintNFT {
    address private devWallet = 0xeec3257A121CB432Ae261e8c5836705169657D21;
    INFTDatabase private database = INFTDatabase(0xDcE4D07A194eaF005ec8251CE6CfE7bCa314fdBa);
    IETH private eth = IETH(0xc778417E063141139Fce010982780140Aa0cD5Ab);


    string[] nftPresaleIds = ["10001", "10002", "10003", "20001", "20002", "20003", "30001", "30002", "30003", "60001", "60002"];
    uint[] nftPresalePrices = [0.1 ether, 0.1 ether, 0.1 ether, 0.1 ether, 0.1 ether, 0.1 ether, 0.1 ether, 0.1 ether, 0.1 ether, 0.2 ether, 0.2 ether];

    function IdIsExistOnPresale(string memory _idNft) public view returns (bool){
        for (uint i = 0; i < nftPresaleIds.length; i++) {
            if (keccak256(abi.encodePacked(nftPresaleIds[i])) == keccak256(abi.encodePacked(_idNft))) {
                return true;
            }
        }
        return false;
    }

    function GetPriceOfNft(string memory _nftId) public view returns (uint){
        for (uint i = 0; i < nftPresaleIds.length; i++) {
            if (keccak256(abi.encodePacked(nftPresaleIds[i])) == keccak256(abi.encodePacked(_nftId))) {
                return nftPresalePrices[i];
            }
        }
        return 0.1 ether;
    }

    function BuyPresaleNftWithId(string memory _nftId) external returns (uint256){
        require(database.totalSupply() < 5000, "NFTs on this presale is maximum !");
        require(IdIsExistOnPresale(_nftId), "Id of this key does not exist in this presale !");

        uint price = GetPriceOfNft(_nftId);
        require(eth.balanceOf(msg.sender) >= price, "sufficient amount !");

        eth.transferFrom(msg.sender, devWallet, price);

        return database.mint(msg.sender, _nftId);
    }
}