//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract GreeterV2 {
    uint256 public constant VERSION = 2;

    address public owner;

    function init(address _owner) public {
        require(owner == address(0), "owner has setted");
        owner = _owner;
    }
}