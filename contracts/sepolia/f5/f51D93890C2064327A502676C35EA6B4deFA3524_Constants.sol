// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

contract Constants {
  address public priceConversionAddr;
  address public userRegistryAddr;
  address public handlerAddr;
  address public postRegistryAddr;
  address public tokenAddr;
  address payable public timeLockAddr;
  address payable public governorAddr;
  address public variablesAddr;

  uint256 public constant MIN_DELAY = 60; //3600
  uint256 public constant VOTING_PERIOD = 120; // 50400;
  uint256 public constant VOTING_DELAY = 1;
  uint256 public constant QUORUM_PERCENTAGE = 4;


  function setPriceConversion(address _addr) external {
    priceConversionAddr = _addr;
  }
  
  function setUserRegistry(address _addr) external {
    userRegistryAddr = _addr;
  }
  
  function setPostRegistry(address _addr) external {
    postRegistryAddr = _addr;
  }
  
  function setHandler(address _addr) external {
    handlerAddr = _addr;
  }
  
  function setGovernanceToken(address _addr) external {
    tokenAddr = _addr;
  }

  function setTimeLock(address payable _addr) external {
    timeLockAddr = _addr;
  }

  function setGovernor(address payable _addr) external {
    governorAddr = _addr;
  }

  function setVariables(address _addr) external {
    variablesAddr = _addr;
  }

  function getPriceConversion() public view returns (address) {
    return priceConversionAddr;
  }
  
  function getUserRegistry() public view returns (address) {
    return userRegistryAddr;
  }
  
  function getPostRegistry() public view returns (address) {
    return postRegistryAddr;
  }
  
  function getHandler() public view returns (address) {
    return handlerAddr;
  }
  
  function getGovernanceToken() public view returns (address) {
    return tokenAddr;
  }
  
  function getGovernor() public view returns (address) {
    return governorAddr;
  }
  
  function getTimeLock() public view returns (address) {
    return timeLockAddr;
  }
  
  function getVariables() public view returns (address) {
    return variablesAddr;
  }
}