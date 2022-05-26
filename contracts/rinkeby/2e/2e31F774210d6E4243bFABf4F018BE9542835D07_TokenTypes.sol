pragma solidity ^0.8.1;

contract TokenTypes {
    struct TokenDetails {
        string name;
        string image;
        uint value;
    }

    mapping(uint => TokenDetails) private _tokenTypes;
    uint private _tokenTypesCount;
    bool private _published;

    constructor() {
        _tokenTypesCount = 0;
        _published = false;
    }

    modifier IsNotPublished() {
        require(!_published);
        _;
    }

    modifier IsPublished() {
        require(_published);
        _;
    }

    function publishStatus() public view returns(bool) {
        return _published;
    }

    function Publish() public IsNotPublished {
        _published = true;
    }

    function typesCount() public view IsPublished returns(uint) {
        return _tokenTypesCount;
    }

    function AddTokenType(string memory name, string memory image, uint value) public IsNotPublished {
        _tokenTypes[_tokenTypesCount] = TokenDetails(name, image, value);
        _tokenTypesCount++;
    }

    function GetTokenTypes(uint index) public view returns(TokenDetails memory) {
        require(index<_tokenTypesCount);
        return _tokenTypes[index];
    }
}