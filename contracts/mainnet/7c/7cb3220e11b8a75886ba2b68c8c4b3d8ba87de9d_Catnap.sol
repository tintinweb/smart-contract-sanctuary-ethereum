// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ERC2981.sol";
import "./Base64.sol";

contract Catnap is ERC721, Ownable, ERC2981 {
    using Strings for uint256;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    mapping(uint256 => string) private names;
    mapping(uint256 => string) private images;

    constructor() ERC721("Islands of the Mind - Catnap", "CATNAP") {
        _setDefaultRoyalty(msg.sender, 500);
    }

    function safeMint(string memory name, string memory image) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        names[tokenId] = name;
        images[tokenId] = image;

        _safeMint(msg.sender, tokenId);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId));
        return buildMetadata(_tokenId);
    }

    function buildMetadata(uint256 _tokenId)
        private
        view
        returns (string memory)
    {
        string memory name = names[_tokenId];
        string memory image = images[_tokenId];
        string memory description= "Figure featured in 'Islands of the Mind - Catnap' by Hyunjeong Lim";
        string memory url = string(
            abi.encodePacked(
                "https://nft.hyunjeonglim.com/catnap/",
                _tokenId.toString()
            )
        );

        return string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"', name, '",',
                                '"description":"', description, '",',
                                '"external_url":"', url, '",',
                                '"image":"', image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}