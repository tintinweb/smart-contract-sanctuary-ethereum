// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "./abstract/ContractMetadata.sol";
import "./TokenCollection.sol";

contract sContract {
    address private collectionAddr;

    constructor() {
        collectionAddr = address(0xd1060E984e6c2037ebab85817f598fB9a5FaB7C1);
    }

    function getValue(uint tokenID) public view returns(uint) {
        TokenCollection collection = TokenCollection(collectionAddr);
        TokenMetadata memory tokenMetadata = collection.getTokenMetadata(tokenID);

        return tokenMetadata.value;
    }

    function mint(uint tokenTypeID) public payable {
        TokenCollection collection = TokenCollection(collectionAddr);
        TokenMetadata memory tokenMetadata = collection.getTokenMetadata(tokenTypeID);

        require(msg.value == tokenMetadata.value);

        
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

abstract contract ContractMetadata {
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view returns(string memory) {
        return _name;
    }

    function symbol() public view returns(string memory) {
        return _symbol;
    }

    function contractAddr() public view returns(address) {
        return address(this);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

struct TokenMetadata {
        string name;
        string description;
        string image;
        uint value;
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

    function addToken(string memory name_, string memory description_, string memory image_, uint value_) public onlyOwner {
        tokens[_tokensCount] = TokenMetadata(name_, description_, image_, value_ * 1 ether);
        _tokensCount++;
    }

    function getTokenMetadata(uint tokenID) public view returns(TokenMetadata memory) {
        return tokens[tokenID];
    }
}