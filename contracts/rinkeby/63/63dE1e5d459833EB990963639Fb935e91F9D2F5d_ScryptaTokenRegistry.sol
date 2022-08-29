// SPDX-License-Identifier: Unlicense
 
pragma solidity ^0.8.0;
 
import "./Ownable.sol"; 
import "./ScryptaERC1155.sol";
import "./ScryptaERC20.sol";

contract ScryptaTokenRegistry is Ownable {

    ScryptaERC1155[] public collections;
    ScryptaERC20[] public coins;
 
    constructor(
        ScryptaERC1155[] memory _collections,
        ScryptaERC20[] memory _coins
    ) {
        collections = _collections;
        coins = _coins;
    }
 
    function createCollection(
        string memory name,
        string memory symbol,
        string memory uri
    ) public onlyOwner returns (uint256) {
        ScryptaERC1155 collection = new ScryptaERC1155(name, symbol, uri);
        collection.transferOwnership(_msgSender());
        collections.push(collection);
        return collections.length-1;
    }
 
    function createCoin(
        string memory name,
        string memory symbol
    ) public onlyOwner returns (uint256) {
        ScryptaERC20 coin = new ScryptaERC20(name, symbol);
        coin.transferOwnership(_msgSender());
        coins.push(coin);
        return coins.length-1;
    }
 
}