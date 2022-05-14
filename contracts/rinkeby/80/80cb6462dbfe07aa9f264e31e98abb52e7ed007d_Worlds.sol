//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Token {
    string public assetUrl;

    constructor(string memory _assetUrl) {
        assetUrl = _assetUrl;
    }
}

contract World {
    Token[] public tokens;

    string private worldName;
    address private owner;

    constructor(address _owner, string memory _worldName) {
        owner = _owner;
        worldName = _worldName;
    }

    function addToken(Token token) public {
        tokens.push(token);
    }
}

contract Worlds {
    mapping(address => World[]) private worlds;

    address private owner;

    bool private inited;

    function init(address _owner) public {
        require(!inited);
        owner = _owner;
        inited = true;
    }

    function createWorld(string memory worldName) public {
        worlds[msg.sender].push(new World(msg.sender, worldName));
    }
}