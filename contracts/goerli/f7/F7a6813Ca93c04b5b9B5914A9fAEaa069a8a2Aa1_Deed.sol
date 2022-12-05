// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Deed {
    address public lawyer;
    address payable public beneficiary;
    uint256 public earliest;

    constructor(address payable _beneficiary, uint256 _fromNow) payable {
        beneficiary = _beneficiary;
        earliest = block.timestamp + _fromNow;
        lawyer = msg.sender;
    }

    function withdraw() public {
        require(msg.sender == lawyer, "only lawyer can withdraw");
        require(
            block.timestamp >= earliest,
            "can not withdraw before earliest"
        );
        beneficiary.transfer(address(this).balance);
    }
}