// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Base64.sol";

contract DATest is ERC721 {

    constructor() ERC721("Test", "Testing") {
    }

    function safeMint() external {
        _safeMint(msg.sender, 0);
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        return string(
            abi.encodePacked('data:application/json;base64,',
            Base64.encode(bytes('{"name":"a name","description":"a desc", "attributes": [{"trait_type": "Base", "value": "Starfish"}]}'))
        )
        );
    }
}