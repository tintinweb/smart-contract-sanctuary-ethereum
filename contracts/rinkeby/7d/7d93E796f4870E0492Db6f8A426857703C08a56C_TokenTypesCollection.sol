// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "./TokenDetails.sol";

contract TokenTypesCollection {
    address private _owner; 

    

    mapping(uint256 => TokenDetails) private tokens;
    uint256 private _tokensCount;

    constructor() {
        _tokensCount = 0;
        _owner = msg.sender;
    }

   

    function tokensCount() public view returns(uint256) {
        return _tokensCount;
    }

    function addToken(string memory name_, string memory description_, string memory image_, uint value_) public {
        if(msg.sender!=_owner)
            revert("not auth");
        tokens[_tokensCount] = TokenDetails(name_, description_, image_, value_);
        _tokensCount++;
    }

    function getTokenDetails(uint256 tokenTypeId) public view returns(TokenDetails memory) {
        return tokens[tokenTypeId];
    }

    function getTokenMintValue(uint256 tokenTypeId) public view returns(uint) {
        return tokens[tokenTypeId].value;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

struct TokenDetails {
        string name;
        string description;
        string image;
        uint value;
}