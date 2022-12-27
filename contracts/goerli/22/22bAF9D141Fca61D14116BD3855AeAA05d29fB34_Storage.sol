// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Storage {
    
    uint256 private x;
    function setValue(uint256 _x) public
    {
        x = _x;
    }
    
    function getValue() public view returns(uint)
    {
      return x;
    }
    
}