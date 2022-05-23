// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract BatchWithdraw {
    constructor() {}
    receive() external payable {}
    function withdraw(uint256 cnt) external {
        address payable target = payable(msg.sender);
        for (uint256 i = 0; i < cnt; i++) {
            (bool success, ) = target.call{value: 1e14}("");
            require(success, "failed transaction");
        }
    }

    function withdraw(address[] memory targets) external {
        for (uint256 i = 0; i < targets.length; i++) {
            address payable target = payable(targets[i]);
            (bool success, ) = target.call{value: 1e14}("");
            require(success, "failed transaction");
        }
    }


}