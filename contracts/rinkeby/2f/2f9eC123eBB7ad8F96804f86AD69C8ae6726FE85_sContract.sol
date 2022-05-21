// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "./abstract/ContractMetadata.sol";
import "./TokenCollection.sol";

contract sContract {
    address private collectionAddr;

    constructor() {
        collectionAddr = address(0xF0331fbe82eDB140BA71Df1AAF5240aB1D646b3e);
    }

    function getValue(uint tokenID) public view returns(uint256) {
        TokenCollection collection = TokenCollection(collectionAddr);
        TokenMetadata memory tokenMetadata = collection.getTokenMetadata(tokenID);

        return tokenMetadata.value;
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
        uint256 value;
}

contract TokenCollection {
    mapping(uint => TokenMetadata) private tokens;
    uint private _tokensCount;

    constructor() {
        _tokensCount = 0;
    }

    function tokensCount() public view returns(uint) {
        return _tokensCount;
    }

    function addToken(string memory name_, string memory description_, string memory image_, uint256 value_) public {
        tokens[_tokensCount] = TokenMetadata(name_, description_, image_, value_);
        _tokensCount++;
    }

    function getTokenMetadata(uint tokenID) public view returns(TokenMetadata memory) {
        return tokens[tokenID];
    }
}