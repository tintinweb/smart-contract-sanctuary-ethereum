// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";


//d8888b. d8888b.  .d88b.  db   dD d88888b d8b   db      db   d8b   db d888888b d88888D  .d8b.  d8888b. d8888b. .d8888. 
//88  `8D 88  `8D .8P  Y8. 88 ,8P' 88'     888o  88      88   I8I   88   `88'   YP  d8' d8' `8b 88  `8D 88  `8D 88'  YP 
//88oooY' 88oobY' 88    88 88,8P   88ooooo 88V8o 88      88   I8I   88    88       d8'  88ooo88 88oobY' 88   88 `8bo.   
//88~~~b. 88`8b   88    88 88`8b   88~~~~~ 88 V8o88      Y8   I8I   88    88      d8'   88~~~88 88`8b   88   88   `Y8b. 
//88   8D 88 `88. `8b  d8' 88 `88. 88.     88  V888      `8b d8'8b d8'   .88.    d8' db 88   88 88 `88. 88  .8D db   8D 
//Y8888P' 88   YD  `Y88P'  YP   YD Y88888P VP   V8P       `8b8' `8d8'  Y888888P d88888P YP   YP 88   YD Y8888D' `8888Y' 

contract BrokenWizards is ERC721A, Ownable {
    uint256 public maxSupply = 2345;
    uint256 public maxPerWallet = 6;
    uint256 public maxPerTx = 2;
    uint256 public _price = 0 ether;

    bool public activated;
    string public unrevealedTokenURI =
        "https://gateway.pinata.cloud/ipfs/QmeqVPPzuhYtGHwEPTCExy7fH45nm3z13kv1bTPZCRcAvs";
    string public baseURI = "";

    mapping(uint256 => string) private _tokenURIs;

    address private _ownerWallet = 0xE146f738515E11F9D3F86f48051B5626bA6Bb7F1;

    constructor( ) ERC721A("brokenwizardswtf", "BROKENWIZARD") {
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