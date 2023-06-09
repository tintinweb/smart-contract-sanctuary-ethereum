/**
 *Submitted for verification at Etherscan.io on 2023-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract IrishTraditionalNFT {
    string public constant TOKEN_NAME = "IrishTraditionalNFT";
    string public constant TOKEN_SYMBOL = "ITNFT";

    struct Token {
        string abc;
        address owner;
    }

    struct User {
        string username;
        bool exists;
    }

    uint256 private _tokenIdCounter;
    mapping(uint256 => Token) private _tokens;
    mapping(address => uint256[]) private _userTokens;
    mapping(address => User) private _users;

    constructor() {
        _tokenIdCounter = 0;
    }

    function TuneABC(string memory abc) public returns (uint256) {
        _tokenIdCounter++;
        uint256 newTokenId = _tokenIdCounter;

        // Check if the user exists
        if (!_users[msg.sender].exists) {
            revert("User does not exist. Please set a username first.");
        }

        _tokens[newTokenId] = Token(abc, msg.sender);
        _userTokens[msg.sender].push(newTokenId);

        return newTokenId;
    }

    function setUsername(string memory username) public {
        require(!_users[msg.sender].exists, "Username has already been set.");
        _users[msg.sender] = User(username, true);
    }

    function getUsername(address user) public view returns (string memory) {
        require(_users[user].exists, "User does not exist.");
        return _users[user].username;
    }

    function getTokenABC(uint256 tokenId) public view returns (string memory) {
        require(tokenId <= _tokenIdCounter, "Invalid token ID");
        return _tokens[tokenId].abc;
    }

    function getTokenOwner(uint256 tokenId) public view returns (address) {
        require(tokenId <= _tokenIdCounter, "Invalid token ID");
        return _tokens[tokenId].owner;
    }

    function getUserTokens(address user) public view returns (uint256[] memory) {
        return _userTokens[user];
    }

    function getTuneName(uint256 tokenId) public view returns (string memory) {
        require(tokenId <= _tokenIdCounter, "Invalid token ID");
        string memory abc = _tokens[tokenId].abc;
        string memory tuneName = parseTuneName(abc);
        return tuneName;
    }

    function parseTuneName(string memory abc) private pure returns (string memory) {
        bytes memory abcBytes = bytes(abc);
        uint256 start = findLineStart(abcBytes, 2);
        uint256 end = findLineEnd(abcBytes, start);
        string memory tuneName = substring(abc, start, end);
        return tuneName;
    }

    function findLineStart(bytes memory abcBytes, uint256 lineNumber) private pure returns (uint256) {
        uint256 lineCount = 0;
        uint256 pos = 0;
        while (lineCount < lineNumber && pos < abcBytes.length) {
            if (abcBytes[pos] == '\n') {
                lineCount++;
            }
            pos++;
        }
        return pos;
    }

    function findLineEnd(bytes memory abcBytes, uint256 startPos) private pure returns (uint256) {
        uint256 pos = startPos;
        while (pos < abcBytes.length && abcBytes[pos] != '\n') {
            pos++;
        }
        return pos;
    }

    function substring(string memory str, uint256 start, uint256 end) private pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        require(start >= 0 && start < strBytes.length, "Invalid start index");
        require(end >= start && end < strBytes.length, "Invalid end index");

        bytes memory result = new bytes(end - start);
        for (uint256 i = start; i < end; i++) {
            result[i - start] = strBytes[i];
        }
        return string(result);
    }
}