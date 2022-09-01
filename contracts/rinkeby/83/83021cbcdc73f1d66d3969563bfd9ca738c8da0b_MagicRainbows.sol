/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Strings.sol";
import "./Shareholders.sol";
import "./ERC721A.sol";
import "./MerkleProof.sol";



contract MagicRainbows is ERC721A, Shareholders {
    using Strings for uint;
    string public _baseTokenURI;
    uint public maxPerWallet = 2;
    uint public maxPerWalletPresale = 2;
    uint public cost = 0.123 ether;
    uint public presaleCost = 0.123 ether;
    uint public maxSupply = 500;
    bool public presaleOnly = true;
    bool public paused = true;
    bytes32 public merkleRoot; 
    mapping(address => uint) public addressMintedBalance;
  constructor(
        
    ) ERC721A("Magic Rainbows", "RAINBOWS")payable{
       _mint(msg.sender, 10);
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
        require(msg.value >= cost * quantity, "Amount of Ether sent too small");
        _mint(msg.sender, quantity);
        addressMintedBalance[msg.sender] += quantity;

    }

    function preSaleMint(uint256 quantity, bytes32[] calldata proof) mintCompliance(quantity) external payable
    {
        require(presaleOnly == true, "Presale has ended.");
        require(addressMintedBalance[msg.sender] + quantity <= maxPerWalletPresale, "You can't mint this many during presale.");
        require(msg.value >= presaleCost * quantity, "Amount of Ether sent too small");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid Merkle Tree proof supplied");
        _mint(msg.sender, quantity);
        addressMintedBalance[msg.sender] += quantity;

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
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
        : "";
    }

    function setMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner 
    {
        merkleRoot = _newMerkleRoot;
    }

    function setPresaleOnly(bool _state) external onlyOwner 
    {
        presaleOnly = _state;
    }

    
    function pause(bool _state) external onlyOwner 
    {
        paused = _state;
    }

    function setPrice(uint _newPublicPrice, uint _newPresalePrice) external onlyOwner
    {
        cost = _newPublicPrice;
        presaleCost = _newPresalePrice;
    }

    function setMaxPerWallet(uint _newPublicMax, uint _newPresaleMax) external onlyOwner
    {
        maxPerWallet = _newPublicMax;
        maxPerWalletPresale = _newPresaleMax;
    }

    

}