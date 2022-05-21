// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

struct TokenMetadata {
        string name;
        string description;
        string image;
        uint256 value;
}

contract TokenCollection {
    address private _owner; 

    mapping(uint => TokenMetadata) private tokens;
    uint private _tokensCount;

    constructor() {
        _tokensCount = 0;
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(
            msg.sender == _owner,
            "Cant add"
        );
        _;
    }

    function tokensCount() public view returns(uint) {
        return _tokensCount;
    }

    function addToken(string memory name_, string memory description_, string memory image_, uint256 value_) public onlyOwner {
        tokens[_tokensCount] = TokenMetadata(name_, description_, image_, value_);
        _tokensCount++;
    }

    function getTokenMetadata(uint tokenID) public view returns(TokenMetadata memory) {
        return tokens[tokenID];
    }
}