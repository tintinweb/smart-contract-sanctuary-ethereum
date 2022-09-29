// SPDX-License-Identifier: MIT

pragma solidity 0.7.3;

import "./ITellorCaller.sol";
import "./IOracle.sol";
/*
* This contract has a single external function that calls Tellor: getTellorCurrentValue(). 
* Use oracle old mastr depreciated
*
* The function is called by the Liquity contract PriceFeed.sol. If any of its inner calls to Tellor revert, 
* this function will revert, and PriceFeed will catch the failure and handle it accordingly.
*
* The function comes from Tellor's own wrapper contract, 'UsingTellor.sol':
* https://github.com/tellor-io/usingtellor/blob/master/contracts/UsingTellor.sol
*
*/
contract TellorCaller is ITellorCaller {
  IOracle public oracle;

  constructor(address _oracle) public {
    oracle = IOracle(_oracle);
  }

  function getTellorCurrentValue() 
  external
  override
   view
   returns(
    bool result,
    uint timestamp,
    uint data
   ){
    bytes32 key = 0xfe189873dc68fa446c034dcb44e22b6da34aaadc48bccb2551badb856acc3c83;
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

// SPDX-License-Identifier: MIT

pragma solidity 0.7.3;

interface ITellorCaller {
    function getTellorCurrentValue() external view returns (bool, uint256, uint256);
}