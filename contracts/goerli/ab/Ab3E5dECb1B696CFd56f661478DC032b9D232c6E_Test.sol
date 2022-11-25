pragma solidity ^0.4.21;


contract Test {

  /**
   * @dev called to check that can do batch transfer or not
   */
  function get() public view returns (uint256){
    return block.timestamp;
  }

}