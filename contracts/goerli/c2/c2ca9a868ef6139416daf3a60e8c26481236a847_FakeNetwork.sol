/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

pragma solidity 0.8.13;

contract FakeNetwork {
  mapping(address => address) private _collectionByPool;

  function setCollectionForPool(address pool, address collection) public {
    _collectionByPool[pool] = collection;
  }

  function collectionByPool(address pool) public view returns (address) {
    return _collectionByPool[pool];
  }
}