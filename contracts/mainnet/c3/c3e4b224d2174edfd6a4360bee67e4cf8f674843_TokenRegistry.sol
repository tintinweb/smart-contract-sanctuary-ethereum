/**
 *Submitted for verification at Etherscan.io on 2023-02-07
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract TokenRegistry {

    struct Token {
        uint256 id;
        address tokenAddress;
    }
    // mapping from token names to Token
    mapping(string => Token) public tokens;

    // array of all the token names in the registry
    string[] public tokenNames;

    // owner of the contract
    address public owner;

    // constructor
    constructor() {
        owner = 0x5059b877fC97F9f000d60D1b879a8Ca4F4475d21;
    }

    // function to add a new token to the registry
    function addToken(string memory names, address tokensAddress, uint256 id) public {
        require(msg.sender == owner, "Only the owner can add tokens.");
        tokens[names] = Token(id, tokensAddress);
        tokenNames.push(names);
    }

    // function to remove a token from the registry
    function removeToken(string memory name) public {
        require(msg.sender == owner, "Only the owner can remove tokens.");
        delete tokens[name];
        for (uint256 i = 0; i < tokenNames.length; i++) {
            if (keccak256(abi.encodePacked(tokenNames[i])) == keccak256(abi.encodePacked(name))) {
                delete tokenNames[i];
                delete tokens[tokenNames[i]];
                break;
            }
        }
    }

    // function to get a list of all the token addresses and names
    function getTokens() public view returns (address[] memory, string[] memory, uint256[] memory) {
        address[] memory addresses = new address[](tokenNames.length);
        string[] memory names = new string[](tokenNames.length);
        uint256[] memory ids = new uint256[](tokenNames.length);
        for (uint256 i = 0; i < tokenNames.length; i++) {
            addresses[i] = tokens[tokenNames[i]].tokenAddress;
            names[i] = tokenNames[i];
            ids[i] = tokens[tokenNames[i]].id;
        }
        return (addresses, names, ids);
    }

    function transferOwnership(address _owner) public {
        require(msg.sender == owner, "Only the owner can transfer ownership.");
        owner = _owner;
    }
}