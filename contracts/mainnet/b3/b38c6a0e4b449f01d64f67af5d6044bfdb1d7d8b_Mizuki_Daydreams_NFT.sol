// SPDX-License-Identifier: MIT 
// @author: @MizukiReloadedTeam
pragma solidity ^0.8.4;

import './ERC721A.sol';
import './ERC721AQueryable.sol';
import './Ownable.sol';

contract Mizuki_Daydreams_NFT is ERC721A, ERC721AQueryable, Ownable {
    constructor() ERC721A("Mizuki Daydreams", "MIZUKI") {}

    uint256 public constant maxMizukiTokens = 888;
    bool public mintEnabled = false;
    bool public teamMintComplete = false;

    string public baseTokenURI = "https://api.mintmizuki.xyz/metadata/";

    function flipSale() public onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function mint(uint amount) external {
        require(mintEnabled == true, "Mint is not open yet");
        require(_numberMinted(msg.sender) + amount <= 2, "Max 2 per wallet");
        require(_totalMinted() + amount <= maxMizukiTokens, "Mizuki's have all been claimed!");
        _mint(msg.sender, amount);
    }

    function teamMint() external onlyOwner {
        require(teamMintComplete == false, "Team mint already complete!");
        teamMintComplete = true;
        _mint(msg.sender, 14);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }


}