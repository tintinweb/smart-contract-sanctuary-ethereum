//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract Counter {

    address public immutable owner ;
    uint256 public counter;
    mapping(address => bool) whitelist;

    event Increment(address indexed _address);

    constructor() {
        owner = msg.sender;
    }

    function setWhitelist(address _address) external {
        require(msg.sender == owner, "You are not owner.");
        whitelist[_address] = true;
    }

    function increment() external {
        require(msg.sender == owner || whitelist[msg.sender], "You are not permitted.");
        counter++;
        emit Increment(msg.sender);
    }


}