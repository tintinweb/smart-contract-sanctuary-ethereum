// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";


//8b    d8 888888 888888    db        .dP"Y8 88  88    db    88""Yb 888888 .dP"Y8 
//88b  d88 88__     88     dPYb       `Ybo." 88  88   dPYb   88__dP 88__   `Ybo." 
//88YbdP88 88""     88    dP__Yb      o.`Y8b 888888  dP__Yb  88"""  88""   o.`Y8b 
//88 YY 88 888888   88   dP""""Yb     8bodP' 88  88 dP""""Yb 88     888888 8bodP' 


contract MetaShapes is ERC721A, Ownable {
    uint256 public maxSupply = 3333;
    uint256 public maxPerWallet = 6;
    uint256 public maxPerTx = 2;
    uint256 public _price = 0 ether;

    bool public activated;
    string public unrevealedTokenURI =
        "https://gateway.pinata.cloud/ipfs/QmZkG52cs3d5pj7Cm3wT89qLXvhgEb12Sp238GhhPfhqzp";
    string public baseURI = "";

    mapping(uint256 => string) private _tokenURIs;

    address private _ownerWallet = 0xaB13095920904d6FA60E09eC25eE18C86BF10c8E;

    constructor( ) ERC721A("metashapeswtf", "METASHAPE") {
    }

    ////  OVERIDES
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json"))
                : unrevealedTokenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    ////  MINT
    function mint(uint256 numberOfTokens) external payable {
        require(activated, "Inactive");
        require(totalSupply() + numberOfTokens <= maxSupply, "All minted");
        require(numberOfTokens <= maxPerTx, "Too many for Tx");
        require(
            _numberMinted(msg.sender) + numberOfTokens <= maxPerWallet,
            "Too many for address"
        );
        _safeMint(msg.sender, numberOfTokens);
    }

    ////  SETTERS
    function setTokenURI(string calldata newURI) external onlyOwner {
        baseURI = newURI;
    }

    function setMaxPerTx(uint256 _maxPerTx) external onlyOwner {
        maxPerTx = _maxPerTx;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setIsActive(bool _isActive) external onlyOwner {
        activated = _isActive;
    }
}