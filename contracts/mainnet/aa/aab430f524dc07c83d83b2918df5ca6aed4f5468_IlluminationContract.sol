// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract IlluminationContract is Ownable, ERC721A, ReentrancyGuard {
    uint256 private constant _PUBLIC_PRICE = 0.05 ether;
    uint256 private constant MAX_BATCH_SIZE = 20;
    uint256 private _MAX_MINT = 5555;
    address private _TEAM = 0x4Dcdbd3F4e5D559D78000a11d18805eAd8B337ef;

    uint256 public constant publicStart = 1650486000; //4:20pm ET 2022-04-20
    uint256 public paused; // default is 0 which means not paused

    // ends with a slash for easier formatting
    string private _baseTokenURI = "https://penguin-labs-web3.github.io/illumination-nyc/passes/";

    constructor() ERC721A("Illumination Light Art Festival", "Illumination Member", MAX_BATCH_SIZE, _MAX_MINT) {
    }

    modifier mintGuard(uint256 tokenCount) {
        // easy checks
        require(paused == 0, "Sale is not available");
        require(tokenCount > 0 && tokenCount <= MAX_BATCH_SIZE, "Purchase must be for 1-20 tokens");
        require(msg.sender == tx.origin, "No buying on behalf of others");
        require(_PUBLIC_PRICE * tokenCount <= msg.value, "Insufficient Funds");

        // math-y checks
        // tokens start a 0, with 0 being a fake one, so allow (limit+1) mints
        // to allow [0, limit] inclusive for limit worth of real tokens
        require(totalSupply() + tokenCount <= _MAX_MINT+1, "Not enough supply remaining");
        _;
    }

    function mint(uint256 amount) external payable mintGuard(amount) {
        require(block.timestamp > publicStart, "Sale not live");
        _safeMint(msg.sender, amount);
    }

    // Mints a value-less token 0 that will be discarded so that listing on opensea can occur
    // before the mint is live
    function mintZeroForOpenSea() external onlyOwner {
        // this can only be done once
        require(totalSupply() == 0);
        _safeMint(msg.sender, 1);
    }

    function pause() external onlyOwner {
        paused = 1;
    }

    function unpause() external onlyOwner {
        paused = 0;
    }


    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function cashout() external onlyOwner {
        payable(_TEAM).transfer(address(this).balance);
    }

    function setCashout(address addr) external onlyOwner returns(address) {
        _TEAM = addr;
        return addr;
    }

}