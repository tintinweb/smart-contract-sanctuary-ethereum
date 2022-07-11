// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Register {
    mapping(address => bool) private wallet;
    uint256 public s_count = 0;

    function register() public {
        require(!wallet[msg.sender], "Already registered.");
        wallet[msg.sender] = true;
        s_count = s_count + 1;
    }
}