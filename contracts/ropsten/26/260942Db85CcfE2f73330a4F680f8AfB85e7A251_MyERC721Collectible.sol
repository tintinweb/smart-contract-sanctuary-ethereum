// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./ERC721Full.sol";

contract MyERC721Collectible is ERC721 {
    string[] public arts;
    mapping(string => bool) public artExists;

    constructor() ERC721("MyERC721Collectible", "MCO") {
    }

    function mint(string calldata _artName) external returns (uint) {
        require(!artExists[_artName], "Art already exists");
        arts.push(_artName);
        uint artId = arts.length - 1;
        _mint(msg.sender, artId);
        artExists[_artName] = true;
        return artId;
    }

    function burn(uint _artId) external returns (bool) {
        address artOwner = ERC721.ownerOf(_artId);
        if (msg.sender != artOwner) {
            bool approvedForAll = ERC721.isApprovedForAll(artOwner, msg.sender);
            require(msg.sender == ERC721.getApproved(_artId) || approvedForAll, "user isn't approved");
        }
        string memory artName = arts[_artId];
        delete arts[_artId];
        artExists[artName] = false;
        _burn(_artId);
        return true;
    }
}