// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ERC1155Metadata} from "ERC1155Metadata.sol";
import {Modifiers} from "Modifiers.sol";

contract ERC1155MetadataFacet is ERC1155Metadata, Modifiers {
    function updateBaseURI(string memory newBaseMetadataUri)
        external
        onlyKomonWeb
    {
        _setBaseURI(newBaseMetadataUri);
    }

    function updateTokenURI(uint256 tokenId, string memory tokenURI)
        external
        onlyKomonWeb
    {
        _setTokenURI(tokenId, tokenURI);
    }
}