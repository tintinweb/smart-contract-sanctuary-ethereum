/**
 *Submitted for verification at Etherscan.io on 2023-01-22
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract Mediator{
    address public calculator;

    constructor(address _calculator){
        calculator = _calculator;
    }

    fallback() external{
    if (msg.data.length > 0) {
      calculator.call(msg.data);
    }
}
}