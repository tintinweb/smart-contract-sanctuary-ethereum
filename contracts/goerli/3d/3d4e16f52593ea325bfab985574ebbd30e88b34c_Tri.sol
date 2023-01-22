/**
 *Submitted for verification at Etherscan.io on 2023-01-22
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract Tri{

    address public dva;

    constructor(address _dva){
        dva = _dva;
    }

    function addEden() external{
        uint256 x = 2;
        uint256 y = 5;

        dva.call(
      abi.encodeWithSelector(
        bytes4(keccak256("add(uint256,uint256)")),
        x,
        y
      )
    );
  }
}