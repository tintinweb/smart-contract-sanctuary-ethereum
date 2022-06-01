pragma solidity ^0.8.1;

struct TokenTypeData {
    bytes10 name;
    string image;
    uint256 value;
}

contract TokenDataDetails {
    TokenTypeData[] private _tokenTypes;
    

    constructor() {
        //_tokenTypes = new TokenTypeData[](1);
        _tokenTypes.push(TokenTypeData("tt","i",2));
    }

    function GetTokenTypes() public view returns(TokenTypeData[] memory) {
        return _tokenTypes;
    }
}