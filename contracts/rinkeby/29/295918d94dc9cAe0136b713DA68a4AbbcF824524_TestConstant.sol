// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// This library has the state variables 'contractAddress' and 'name'
library TestConstant {

  // defining state variables
  struct ConstantStorage {
    address WETH_ADDRESS;
    address UNISWAP_ROUTER;
    // ... any number of other state variables
  }

  // return a struct storage pointer for accessing the state variables
  function constantStorage() 
    internal 
    pure 
    returns (ConstantStorage storage cs) 
  {
    bytes32 position = keccak256("constant.standard.constant.storage");
    assembly { cs.slot := position }
  }

  // set state variables
  function setStateVariables(
    address _wethAddress, 
    address _uniswapRouter
  ) 
    external 
  {
    ConstantStorage storage cs = constantStorage();
    cs.WETH_ADDRESS = _wethAddress;
    cs.UNISWAP_ROUTER = _uniswapRouter;
  }

  // get contractAddress state variable
  function getWethAddress() external view returns (address) {
    return constantStorage().WETH_ADDRESS;
  }

  // get name state variable
  function getUniswapRouter() external view returns (address) {
    return constantStorage().UNISWAP_ROUTER;
  }
}