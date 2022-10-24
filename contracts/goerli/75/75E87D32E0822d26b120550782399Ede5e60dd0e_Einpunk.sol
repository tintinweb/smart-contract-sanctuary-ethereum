// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8; // Hello World I'm Einpunk

// EVM, Ethereum Virtual Machine
// Avalanche, Fantom, Polygon

contract Einpunk {
    // This gets initialized to zero
    // <- This means that this section is to comment!
    uint256 public stakedToken;

    mapping(string => uint256) public nameToStakedToken;

    struct FarmToken {
        uint256 stakedToken;
        string name;
    }

    // uint256[] public stakedTokenAmount;
    FarmToken[] public farmToken;

    function store(uint256 _stakedToken) public {
        stakedToken = _stakedToken;
        retreive();
    }

    // view, pure
    function retreive() public view returns (uint256) {
        return stakedToken;
    }

    function stakeFarmToken(string memory _name, uint256 _stakedToken) public {
        farmToken.push(FarmToken(_stakedToken, _name));
        nameToStakedToken[_name] = _stakedToken;
    }
}