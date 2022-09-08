/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

pragma solidity ^0.8.7;
 
contract KeepDeep {
    
  mapping (address => bytes) private Notes;

  function set(bytes calldata data) external
  {
    Notes[msg.sender] = data;
  }

  function get() external view returns (bytes memory)
  {
    return Notes[msg.sender];
  }

}