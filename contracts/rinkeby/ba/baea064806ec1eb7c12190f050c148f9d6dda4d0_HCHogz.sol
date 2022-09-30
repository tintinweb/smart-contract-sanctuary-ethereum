/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/* 

Developed by Co-Labs. Hire us www.co-labs.studio
*/

import "./Strings.sol";
import "./Shareholders.sol";
import "./ERC721A.sol";
import "./MerkleProof.sol";


contract HCHogz is ERC721A, Shareholders {
    using Strings for uint;
    string public _baseTokenURI;
    uint public maxPerWallet = 16;
    uint public maxPerWalletPresale = 16;
    uint public baseCost = 0.01 ether;
    uint public multiplier = 0.01 ether;
    uint public increment = 10;
    uint public presaleCost = 0.35 ether;
    uint public presaleSupply = 2750;
    uint public presaleUsed = 0;
    uint public maxSupply = 9666;
    bool public revealed = false;
    bool public presaleOnly = true;
    bool public paused = true;
    bytes32 public merkleRoot;
    mapping(address => uint) public addressMintedBalance;
  constructor(
        string memory name_, //Hostile Crypto Hogz
        string memory symbol_, //HC Hogz
        string memory baseUri_
    ) ERC721A(name_, symbol_)payable{
        _baseTokenURI = baseUri_;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }


    modifier mintCompliance(uint256 quantity) {
        require(paused == false, "Contract is paused.");
        require(addressMintedBalance[msg.sender] + quantity <= maxPerWallet, "You can't mint this many.");
        require(_totalMinted() + quantity <= maxSupply, "Cannot exceed max supply");
        require(tx.origin == msg.sender, "No contracts!");
        _;
    }

    function publicMint(uint256 quantity) mintCompliance(quantity) external payable
    {
        require(presaleOnly == false, "Presale Only");
        uint256 price = getPrice(quantity);
        require(msg.value >= price, "Amount of Ether sent too small");
        _mint(msg.sender, quantity);
        addressMintedBalance[msg.sender] += quantity;
    }

    function preSaleMint(uint256 quantity, bytes32[] calldata proof) mintCompliance(quantity) external payable
    {
        require(presaleOnly == true, "Presale has ended.");
        require(addressMintedBalance[msg.sender] + quantity <= maxPerWalletPresale, "You can't mint this many during presale.");
        require(msg.value >= presaleCost * quantity, "Amount of Ether sent too small");
        require(quantity <= presaleSupply - presaleUsed, "Cannot exceed presaleSupply");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid Merkle Tree proof supplied");
        _mint(msg.sender, quantity);
        addressMintedBalance[msg.sender] += quantity;
        presaleUsed += quantity;
    }

    function ownerMint(uint256 quantity) external payable onlyOwner
    {
        require(_totalMinted() + quantity <= maxSupply, "Cannot exceed max supply");
        _mint(msg.sender, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) 
    {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner 
    {
        _baseTokenURI = baseURI;
    }

    function exists(uint256 tokenId) public view returns (bool) 
    {
        return _exists(tokenId);
    }

    function tokenURI(uint tokenId) public view virtual override returns (string memory) 
    {
    string memory currentBaseURI = _baseURI();
    if(revealed == true) {
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
        : "";
    } else {
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI))
        : "";
    }
    
    }

    function setMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner 
    {
    merkleRoot = _newMerkleRoot;
    }

    function setPresaleOnly(bool _state) external onlyOwner 
    {
    presaleOnly = _state;//set to false for main mint
    }

    function reveal(bool _state, string memory baseURI) external onlyOwner 
    {
    revealed = _state;
    _baseTokenURI = baseURI;
    }

    function pause(bool _state) external onlyOwner 
    {
    paused = _state;
    }

    function changeSaleDetails(uint _baseCost, uint _multiplier, uint _presaleCost, uint _maxPerWallet, uint _maxPerWalletPresale) external onlyOwner {
        baseCost = _baseCost;
        multiplier = _multiplier;
        presaleCost = _presaleCost;
        maxPerWallet = _maxPerWallet;
        maxPerWalletPresale = _maxPerWalletPresale;
    }

    function getPrice(uint quantity) public view returns (uint256) {
        uint256 premium = ((_totalMinted()-presaleUsed)/increment)*multiplier;
        uint256 finalCost = (baseCost + premium)*quantity;
        return finalCost;
    }
    
}