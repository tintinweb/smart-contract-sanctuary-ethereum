// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Recover {
    address public admin; // contract admin

    modifier onlyAdmin {
        require(msg.sender == admin, "No");
        _;
    }

    receive() external payable {}

    constructor() {
        admin = msg.sender;
    }

    function recover(address to) external onlyAdmin {
        payable(to).transfer(address(this).balance);
    }
}