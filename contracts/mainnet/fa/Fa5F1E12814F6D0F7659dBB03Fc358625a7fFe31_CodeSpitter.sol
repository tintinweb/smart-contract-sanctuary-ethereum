// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error NotOwner();

contract CodeSpitter {
    address private owner;
    uint256 private flag = 0;

    constructor() {
        owner = msg.sender;
    }

    function setFlag(uint256 _flag) external {
        if (owner != msg.sender) {
            revert NotOwner();
        }
        flag = _flag;
    }

    function getRuntimeBytecode() external view returns (bytes memory) {
        if (flag == 0) {
            return hex"3460125760026004350160005260206000f35b600080fd";
        } else {
            return hex"346013576024356004350160005260206000f35b600080fd";
        }
    }
}