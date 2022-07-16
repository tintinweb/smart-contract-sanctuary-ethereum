// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";


//░██████╗░█████╗░██╗░░░██╗██████╗░██╗░██████╗░░█████╗░██████╗░██╗░░░░░██╗███╗░░██╗░██████╗
//██╔════╝██╔══██╗██║░░░██║██╔══██╗██║██╔════╝░██╔══██╗██╔══██╗██║░░░░░██║████╗░██║██╔════╝
//╚█████╗░███████║██║░░░██║██║░░██║██║██║░░██╗░██║░░██║██████╦╝██║░░░░░██║██╔██╗██║╚█████╗░
//░╚═══██╗██╔══██║██║░░░██║██║░░██║██║██║░░╚██╗██║░░██║██╔══██╗██║░░░░░██║██║╚████║░╚═══██╗
//██████╔╝██║░░██║╚██████╔╝██████╔╝██║╚██████╔╝╚█████╔╝██████╦╝███████╗██║██║░╚███║██████╔╝
//╚═════╝░╚═╝░░╚═╝░╚═════╝░╚═════╝░╚═╝░╚═════╝░░╚════╝░╚═════╝░╚══════╝╚═╝╚═╝░░╚══╝╚═════╝░

contract SAUDIGOBLINSWTF is ERC721A, Ownable {
    uint256 public maxSupply = 3333;
    uint256 public maxPerWallet = 6;
    uint256 public maxPerTx = 2;
    uint256 public _price = 0 ether;

    bool public activated;
    string public unrevealedTokenURI =
        "https://gateway.pinata.cloud/ipfs/QmTGCcqPbUGZDpazP5zcbPH3o3oCdSweiPJFCBEUmG8LTA";
    string public baseURI = "";

    mapping(uint256 => string) private _tokenURIs;

    address private _ownerWallet = 0x33B7c87bFF3f2f054563fAB767F24B84A4daF376;

    constructor( ) ERC721A("saudigoblinswtf", "SAUDIGOBLIN") {
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