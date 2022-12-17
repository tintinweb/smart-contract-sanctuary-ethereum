// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721Royalty.sol";
import "./Counters.sol";


contract Formule1 is ERC721Royalty,Ownable {
    address public minter;

    uint256 public totalSupply;

    uint256[] public tokenIdsToMint;

    string public baseURI;

    string public collectionURI;

    constructor()
    ERC721("F1 drivers NFT collection", "MFGP")
        {
        }

    function mint(address to,uint256 quantity) external {
        require(msg.sender==minter||msg.sender==owner(), "not allowed");
        for(uint256 i = 0; i < quantity; i++){
            uint256 tokenId = tokenIdsToMint[tokenIdsToMint.length-1];
            tokenIdsToMint.pop();
            _mint(to, tokenId);
            totalSupply++;
        }        
    }

    function addTokensToMint(uint256[] memory tokenIds) external {
        require(msg.sender==minter||msg.sender==owner(), "not allowed");
        for(uint256 i=0;i<tokenIds.length;i++){
            tokenIdsToMint.push(tokenIds[i]);
        }
    }

    //METADATA URI BUILDER

    function tokenURI(uint256 tokenId) public view override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        // Concatenate the baseURI and the tokenId as the tokenId should
        // just be appended at the end to access the token metadata
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setContractURI(string memory uri) external onlyOwner {
        collectionURI = uri;
    }

    function contractURI() public view returns (string memory) {
        return collectionURI;
    }


    function setMinter(address  _minter) external onlyOwner {
        minter = _minter;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
       _setDefaultRoyalty(receiver,feeNumerator);
    }

}