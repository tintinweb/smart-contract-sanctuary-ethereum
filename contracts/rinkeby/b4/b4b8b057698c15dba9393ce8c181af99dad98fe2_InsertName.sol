// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol"; 

//import "erc721a/contracts/ERC721A.sol";
//import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract InsertName is ERC721A, Ownable{
    using Strings for uint256;

    uint256 MAX_SUPPLY = 5555;
    uint256 MAX_MINTS_PUBLIC = 4;
    uint256 MAX_MINTS_WHITELIST = 2;
    uint256 MAX_MINTS_TEAM = 1;
    uint256 public mintRate_Public = 0.069 ether;
    uint256 public mintRate_WhiteList = 0.069 ether;
    uint256 public mintRate_Team = 0.01 ether;

    bool public isPublicSale = false; 
    bool public isWhiteListSale = false;
    bool public isTeamSale = false;
    bool public isRevealed = false; 
    bool public paused = true;

    string public baseURI = "https://gateway.pinata.cloud/ipfs/QmPuaAPTm2LAiaCjjk3DUU9sNannKXPw2zPf9ZuhhmFVAW";  //change
    string public unrevealedBaseURI = ""; // change

    bytes32 public whitelistMerkleRoot;
    mapping(address => bool) public teamAddresses;


    constructor() ERC721A("NFTContractName", "NFTSymbol"){
        addTeamAddress(0x7C9Ada7B2605b91796A121156Fe03f71E7596ebB);
    }

    modifier callerIsUser(){
        require(tx.origin == _msgSender(), "Only users can interact with this contract!");
        _;
    }

    modifier onlyTeam(){
        require(msg.sender == owner() || teamAddresses[msg.sender], "Caller is not owner or dev!");
        _;
    }

    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

    function publicMint(uint256 quantity) external payable callerIsUser{
        require(!paused);
        require(isPublicSale);
        require(quantity + _numberMinted(_msgSender()) <= MAX_MINTS_PUBLIC, "Exceeded max mints");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough Tokens");
        require(msg.value >= (mintRate_Public * quantity), "Not enough ether sent");
        _safeMint(_msgSender(), quantity);
    }

    function whiteListMint(uint256 quantity, bytes32[] calldata merkleProof) external payable callerIsUser 
    isValidMerkleProof(merkleProof, whitelistMerkleRoot)
    {
        require(!paused);
        require(isWhiteListSale);

        //require(whiteListAddresses[_msgSender()], "You are not whitelisted!");
        require(quantity + _numberMinted(_msgSender()) <= MAX_MINTS_WHITELIST, "Exceeded max mints");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough Tokens");
        require(msg.value >= (mintRate_WhiteList * quantity), "Not enough ether sent");
        _safeMint(_msgSender(), quantity);
    }

    function teamMint(uint256 quantity) external payable{
        require(!paused);
        require(isTeamSale);
        
        require(teamAddresses[_msgSender()], "You are not on the team!");
        require(quantity + _numberMinted(_msgSender()) <= MAX_MINTS_TEAM, "Exceeded max mints");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough Tokens");
        require(msg.value >= (mintRate_Team * quantity), "Not enough ether sent");
        _safeMint(_msgSender(), quantity);
    }

    function withdraw() external onlyTeam{
        uint256 devPay = (address(this).balance * 5) /100; // 5%
        address devAddress = 0x7C9Ada7B2605b91796A121156Fe03f71E7596ebB;

        uint256 managerPay = (address(this).balance * 10) /100;
        address managerAddress;

        // in second brackets minus all pays
        uint256 ownerPay = (address(this).balance * (100 - devPay))/ 100; 
        
        payable(owner()).transfer(ownerPay);
        payable(devAddress).transfer(devPay);
        payable(managerAddress).transfer(managerPay);
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
    
    function addTeamAddress(address teamAddress) public onlyOwner{
        teamAddresses[teamAddress] = true;
    }

    function removeTeamAddress(address existingAddress) public onlyOwner{
        require(teamAddresses[existingAddress], "Not an existing address");
        teamAddresses[existingAddress] = false;
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
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

    function burnToken(uint256 tokenId) public{
        _burn(tokenId);
    }
}