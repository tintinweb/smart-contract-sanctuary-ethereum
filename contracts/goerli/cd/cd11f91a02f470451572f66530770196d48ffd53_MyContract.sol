/**
 *Submitted for verification at Etherscan.io on 2023-01-22
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract MyContract{

    address public mediator;

    constructor(address _mediator){
        mediator = _mediator;
    }

    function add(uint256 x,uint256 y) external{

        mediator.call(
      abi.encodeWithSelector(
        bytes4(keccak256("add(uint256,uint256)")),
        x,
        y
      )
    );
  }
}