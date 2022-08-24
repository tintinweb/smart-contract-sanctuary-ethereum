// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract InfAAAATest1 is ERC721A, Ownable {

    //metadatas
    string public baseURI = "https://server.wagmi-studio.com/metadata/test/infTest/";

    constructor()
    ERC721A("Inf AAAA TEST 1", "INFAAA")
        {
        }


    function mint(address targetAddress, uint256 quantity) external onlyOwner {
        _mint(targetAddress, quantity);
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function tokenURI(uint256 tokenId) public view override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        // Concatenate the baseURI and the tokenId as the tokenId should
        // just be appended at the end to access the token metadata
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }


}