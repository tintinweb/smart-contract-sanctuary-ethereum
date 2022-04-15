// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./base64.sol";
import "./ERC721.sol";
import "./Ownable.sol";

contract Contract is ERC721, Ownable {
    using Strings for uint256;
    mapping(uint256 => string) private _tokenURIs;
    uint256 tokenCounter = 0;

    constructor() ERC721("Flammable Punks V2", "FLAMS") {}

    function mintPunks(string memory name, string memory description) public {
        address rescuer = msg.sender;
        _safeMint(rescuer, tokenCounter);
        _setTokenURI(
            tokenCounter,
            string(
                abi.encodePacked(
                    "name: {",
                    name,
                    "}, description: {",
                    description,
                    "} , attributes: []}"
                )
            )
        );
        tokenCounter = tokenCounter + 1;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory _tokenURI = _tokenURIs[tokenId];

        return _tokenURI;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }
}