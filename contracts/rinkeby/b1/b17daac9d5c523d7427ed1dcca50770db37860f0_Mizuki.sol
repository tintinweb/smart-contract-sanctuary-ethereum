// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./ERC721AQueryable.sol";

contract Mizuki is ERC721A, ERC721AQueryable, Ownable {

    uint256 public constant maxMizukiTokens = 888;
    bool public mintEnabled = false;
    bool public teamMintComplete = false;

    string public baseTokenURI = "https://tsuki-endpoint.herokuapp.com/metadata/";

    constructor() ERC721A("Mizuki", "MIZUKI") {}

    function flipMint() public onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function mint() external {
        require(mintEnabled == true, "Mint is not open yet");
        require(_numberMinted(msg.sender) == 0, "Max 1 per wallet");
        require(_totalMinted() + 1 <= maxMizukiTokens, "All Mizuki's have been claimed!");
        _mint(msg.sender, 1);
    }

    function teamMint() external onlyOwner {
        require(teamMintComplete == false, "Team mint already complete!");
        teamMintComplete = true;
        _mint(msg.sender, 7);
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