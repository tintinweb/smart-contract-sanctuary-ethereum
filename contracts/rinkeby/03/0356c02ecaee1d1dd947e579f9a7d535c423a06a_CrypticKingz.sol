// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";

contract CrypticKingz is ERC721A, Ownable{
    using Strings for uint256;

    uint256 MAX_SUPPLY = 5555;
    uint256 MAX_MINTS_PUBLIC = 4;
    uint256 MAX_MINTS_WHITELIST = 2;
    uint256 MAX_MINTS_TEAM = 100;
    uint256 public mintRate_Public = 0.069 ether;
    uint256 public mintRate_WhiteList = 0.069 ether;
    uint256 public mintRate_Team = 0.01 ether;
    address constant developerAddress = 0x7C9Ada7B2605b91796A121156Fe03f71E7596ebB; 
    uint256 constant developerRate = 5; //5 percent

    bool public isPublicSale = false; 
    bool public isWhiteListSale = false;
    bool public isTeamSale = false;
    bool public isRevealed = false; 
    bool public paused = true;

    string public baseURI = "https://gateway.pinata.cloud/ipfs/QmPuaAPTm2LAiaCjjk3DUU9sNannKXPw2zPf9ZuhhmFVAW";  //change
    string public unrevealedBaseURI = ""; // change

    mapping(address => bool) public whiteListAddresses;
    mapping(address => bool) public teamAddresses;


    constructor() ERC721A("NFTContractName", "NFTSymbol"){}

    function publicMint(uint256 quantity) external payable{
        require(!paused);
        require(isPublicSale);
        require(quantity + _numberMinted(msg.sender) <= MAX_MINTS_PUBLIC, "Exceeded max mints");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough Tokens");
        require(msg.value >= (mintRate_Public * quantity), "Not enough ether sent");
        _safeMint(msg.sender, quantity);
    }

    function whiteListMint(uint256 quantity) external payable{
        require(!paused);
        require(isWhiteListSale);

        require(whiteListAddresses[msg.sender], "You are not whitelisted!");
        require(quantity + _numberMinted(msg.sender) <= MAX_MINTS_WHITELIST, "Exceeded max mints");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough Tokens");
        require(msg.value >= (mintRate_WhiteList * quantity), "Not enough ether sent");
        _safeMint(msg.sender, quantity);
    }

    function teamMint(uint256 quantity) external payable{
        require(!paused);
        require(isTeamSale);
        
        require(teamAddresses[msg.sender], "You are not on the team!");
        require(quantity + _numberMinted(msg.sender) <= MAX_MINTS_TEAM, "Exceeded max mints");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough Tokens");
        require(msg.value >= (mintRate_Team * quantity), "Not enough ether sent");
        _safeMint(msg.sender, quantity);
    }

    function withdraw() external payable onlyOwner{
        uint256 devPay = address(this).balance * developerRate/100;
        uint256 ownerPay = address(this).balance * (100 - developerRate)/100;
        
        payable(owner()).transfer(ownerPay);
        payable(developerAddress).transfer(devPay);
    }

    function _baseURI() internal view virtual override returns(string memory){
        return baseURI;
    }

    function setBaseURI(string memory newURI) public onlyOwner{
        baseURI = newURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns(string memory){
        require(_exists(tokenId), "Non-existant token URI Query");
        uint256 trueId = tokenId + 1;

        if(!isRevealed){
            return unrevealedBaseURI;
        }

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, trueId.toString(), ".json")) : "";
    }

    // mint price has to be 100x what you want to set it as
    function setPublicMint(uint256 _maxMint, uint256 _mintPrice ) public onlyOwner{
        MAX_MINTS_PUBLIC = _maxMint;
        mintRate_Public = (_mintPrice / 100);
    }

    // mint price has to be 100x what you want to set it as
    function setWhiteListMint(uint256 _maxMint, uint256 _mintPrice) public onlyOwner{
        MAX_MINTS_WHITELIST = _maxMint;
        mintRate_WhiteList = (_mintPrice / 100);
    }

    // mint price has to be 100x what you want to set it as
    function setTeamMint(uint256 _maxMint, uint256 _mintPrice) public onlyOwner{
        MAX_MINTS_TEAM = _maxMint;
        mintRate_Team = (_mintPrice / 100);
    }

    function addWhiteListAddress(address newAddress) public onlyOwner{
        whiteListAddresses[newAddress] = true;
    }
    
    function addTeamAddress(address teamAddress) public onlyOwner{
        teamAddresses[teamAddress] = true;
    }

    function removeWhiteListAddress(address existingAddress) public onlyOwner{
        require(whiteListAddresses[existingAddress], "Not an existing address");
        whiteListAddresses[existingAddress] = false;
    }

    function removeTeamAddress(address existingAddress) public onlyOwner{
        require(teamAddresses[existingAddress], "Not an existing address");
        teamAddresses[existingAddress] = false;
    }

    function reveal(bool shouldReveal) public onlyOwner{
        isRevealed = shouldReveal;
    }
    
    function pause(bool shouldPause) public onlyOwner{
        paused = shouldPause;
    }

    function setPublicSale(bool shouldStartPublicSale) public onlyOwner{
        isPublicSale = shouldStartPublicSale;
    }

    function setWhiteListSale(bool shouldStartWhiteListSale) public onlyOwner{
        isWhiteListSale = shouldStartWhiteListSale;
    }

    function setTeamSale(bool shouldStartTeamSale) public onlyOwner{
        isTeamSale = shouldStartTeamSale;
    }
}