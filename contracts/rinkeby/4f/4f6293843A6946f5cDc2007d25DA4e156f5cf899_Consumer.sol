// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import './IOracle.sol';

contract Consumer {
  IOracle public oracle;

  constructor(address _oracle) {
    oracle = IOracle(_oracle);
  }

  function getTellorCurrentValue(bytes32 key) 
  external
   view
   returns(
    bool result,
    uint timestamp,
    uint data
   ){
    //bytes32 key = keccak256(abi.encodePacked('BTC/USD'));

    (bool _result, uint _data, uint _timestamp) = oracle.getData(key);
    require(_result == true, 'could not get price');
    require(_timestamp >= block.timestamp - 5 minutes, 'price too old'); 
    //so something with price;
    return(_result, _timestamp, _data);

  }
}

pragma solidity ^0.7.3;

interface IOracle {
  function updateReporter(address reporter, bool isReporter) external;
  function updateData(bytes32 key, uint payload) external;
  function getData(bytes32 key) 
    external 
    view 
    returns(bool result, uint date, uint payload);
}