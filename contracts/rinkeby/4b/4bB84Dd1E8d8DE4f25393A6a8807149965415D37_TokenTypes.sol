//SPDX-License-Identifier: UNLICENSED;
pragma solidity ^0.8.1;

contract TokenTypes {
    struct TokenDetails {
        string name;
        string image;
        uint value;
    }

    mapping(uint => TokenDetails) private _tokenType;
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

    function typesCount() public view IsPublished returns(uint) {
        return _tokenTypesCount;
    }

    function AddTokenType(string memory name, string memory image, uint value) public IsNotPublished {
        _tokenType[_tokenTypesCount] = TokenDetails(name, image, value);
        _tokenTypesCount++;
    }
}