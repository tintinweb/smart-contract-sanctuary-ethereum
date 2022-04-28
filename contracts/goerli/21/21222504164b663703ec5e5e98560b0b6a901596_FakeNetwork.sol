/**
 *Submitted for verification at Etherscan.io on 2022-04-28
*/

pragma solidity 0.8.13;

// Faking https://github.com/bancorprotocol/contracts-v3/blob/dev/contracts/network/BancorNetwork.sol

interface Token {}

contract FakeNetwork {
  mapping(Token => address) private _collectionByPool;

  function setCollectionForPool(Token pool, address collection) public {
    _collectionByPool[pool] = collection;
  }

  function collectionByPool(Token pool) public view returns (address) {
    return _collectionByPool[pool];
  }
}