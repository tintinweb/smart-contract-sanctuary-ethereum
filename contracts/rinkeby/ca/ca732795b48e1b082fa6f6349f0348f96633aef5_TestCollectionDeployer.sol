/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

interface ERC721Deployer {
    function deploy721(string memory, string memory, uint256, address, string memory) external returns (address);
}

interface ERC1155Deployer {
    function deploy1155(uint256, address, uint256, string memory) external returns (address);
}

contract TestCollectionDeployer {
    address[] public deployed721Collections;
    address[] public deployed1155Collections;
    address erc721Deployer;
    address erc1155Deployer;

    constructor(address _erc721Deployer, address _erc1155Deployer) {
        erc721Deployer = _erc721Deployer;
        erc1155Deployer = _erc1155Deployer;
    }

    function deploy721(string memory collectionName, string memory ticker, uint256 size, address recipient, string memory customBaseURI) public returns (address) {
         address collection = ERC721Deployer(erc721Deployer).deploy721(collectionName, ticker, size, recipient, customBaseURI);
         deployed721Collections.push(collection);
         return collection;
    }

    function deploy1155(uint256 typeCount, address recipient, uint256 countPerType, string memory uri) public returns (address) {
         address collection = ERC1155Deployer(erc1155Deployer).deploy1155(typeCount, recipient, countPerType, uri);
         deployed1155Collections.push(collection);
         return collection;
    }
}