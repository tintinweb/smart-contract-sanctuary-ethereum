// SPDX-License-Identifier: MIT
// MOOOGGGHHHHH minhoutours wekm taᵥᵤ
/*

• ▌ ▄ ·. ▪   ▐ ▄       ▄▄▄▄▄ ▄▄▄· ▄• ▄▌▄▄▄  ▄• ▄▌.▄▄ · ▄▄▄▄▄      ▄▄▌ ▐ ▄▌ ▐ ▄ 
·██ ▐███▪██ •█▌▐█▪     •██  ▐█ ▀█ █▪██▌▀▄ █·█▪██▌▐█ ▀. •██  ▪     ██· █▌▐█•█▌▐█
▐█ ▌▐▌▐█·▐█·▐█▐▐▌ ▄█▀▄  ▐█.▪▄█▀▀█ █▌▐█▌▐▀▀▄ █▌▐█▌▄▀▀▀█▄ ▐█.▪ ▄█▀▄ ██▪▐█▐▐▌▐█▐▐▌
██ ██▌▐█▌▐█▌██▐█▌▐█▌.▐▌ ▐█▌·▐█ ▪▐▌▐█▄█▌▐█•█▌▐█▄█▌▐█▄▪▐█ ▐█▌·▐█▌.▐▌▐█▌██▐█▌██▐█▌
▀▀  █▪▀▀▀▀▀▀▀▀ █▪ ▀█▄▀▪ ▀▀▀  ▀  ▀  ▀▀▀ .▀  ▀ ▀▀▀  ▀▀▀▀  ▀▀▀  ▀█▄▀▪ ▀▀▀▀ ▀▪▀▀ █▪

*/

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ERC721A.sol";

contract MinotaurusTown is ERC721A, Ownable {
    uint256 public constant maxSupply = 4000;
    uint256 public mooExtrUTOPAy = 0.005 ether;
    uint256 public mouinuTOforTX = 11;
    string public baseURI = "ipfs://QmbteCRina9hqchg9iyNHKB79YLRgCkS5HYVv9zPJSW1ZU/";
    string public contractURI = "ipfs://QmZDLqj8iKLgovHoazNTPM6P8ByPYPZfcfcdfYRh76nkxC"; //opensea description
    bool public minotaurusFree = false;
    
    mapping(address => uint256) private _freeMintedCount;

    constructor() ERC721A("minotaurustown", "MTT") {}

    function getContractURI() public view returns (string memory) {
        return contractURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function lockIntuuuuumLabyrint() external onlyOwner {
        minotaurusFree = false;
    }

    function exitFuuuuumLabyrint() external onlyOwner {
        minotaurusFree = true;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function setBaseURI(string memory _updatedURI) public onlyOwner {
        baseURI = _updatedURI;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        mooExtrUTOPAy = _newCost;
    }

    function setContractURI(string memory _updatedURI) public onlyOwner {
        contractURI = _updatedURI;
    }

    modifier checks(uint256 _mintAmount) {
        require(minotaurusFree, "MOOOintingIS PAUSED");
        require(_mintAmount > 0);
        require(totalSupply() + _mintAmount <= maxSupply, "MOOEXceed Max suPPLY");
        require(_mintAmount < mouinuTOforTX, "MOOEXceed Max tX");


        uint256 payForCount = _mintAmount;
        uint256 freeMintCount = _freeMintedCount[msg.sender];

        if (freeMintCount < 1) {
            if (_mintAmount > 1) {
                payForCount = _mintAmount - 1;
            } else {
                payForCount = 0;
            }

            _freeMintedCount[msg.sender] = 1;
            }

        require(msg.value >= payForCount * mooExtrUTOPAy, "MOOsend ENOUGH ETH!");
        _;
    }

    function freeMintedCount(address owner) external view returns (uint256) {
        return _freeMintedCount[owner];
    }

    function moMint(uint256 _mintAmount) public payable checks(_mintAmount) {
        _safeMint(msg.sender, _mintAmount);
    }
    
    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

}