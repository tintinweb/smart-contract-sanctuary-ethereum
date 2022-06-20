// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";

import {Base64} from "./Base64.sol";

contract MXRT is ERC721, Ownable {
    constructor() ERC721("MXR Collectibles", "MXRT") {}

    function simplifiedFormatTokenURI(string memory imageURI, string memory _name, string memory _description)
    public
    pure
    returns (string memory)
    {
        string memory baseURL = "data:application/json;base64,";
        string memory json = string(
            abi.encodePacked(
                '{"name": "',_name,'", "description": "',_description,'", "image":"',
                imageURI,
                '"}'
            )
        );
        string memory jsonBase64Encoded = Base64.encode(bytes(json));
        return string(abi.encodePacked(baseURL, jsonBase64Encoded));
    }

    function mint(uint tokenId, string memory imageURI, string memory _name, string memory _description)
    public
    onlyOwner
    {
        string memory uri = simplifiedFormatTokenURI(imageURI, _name, _description);
        _mint(msg.sender, tokenId, uri);
    }

    function mintBatch(uint256[] memory ids, string[] memory imageURI, string[] memory _name, string[] memory _description)
    public
    onlyOwner
    {
        for (uint i = 0; i < ids.length ; i++) {
            string memory uri = simplifiedFormatTokenURI(imageURI[i], _name[i], _description[i]);
            _mint(msg.sender, ids[i], uri);
        }
    }
}