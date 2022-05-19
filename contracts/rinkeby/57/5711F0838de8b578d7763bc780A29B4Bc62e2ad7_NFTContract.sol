/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Strings.sol";
import "./Shareholders.sol";
import "./ERC721A.sol";
import "./MerkleProof.sol";



contract NFTContract is ERC721A, Shareholders {
    using Strings for uint;
    string public _baseTokenURI;
    uint public maxPerPresale = 5;
    uint public maxPerMint = 5;
    uint public maxPerWallet = 25;
    uint public cost = 0.0777 ether; //0.05
    uint public presaleCost = 0.069 ether; //0.05
    uint public maxSupply = 9999;  //10000
    bool public revealed = false;
    bool public presaleOnly = true;
    bytes32 public merkleRoot;

    mapping(address => uint) public addressMintedBalance;

  constructor(
      string memory name_,
      string memory symbol_,
      string memory baseUri_
      ) ERC721A(name_, symbol_)payable{
          _baseTokenURI = baseUri_;
  }

    /*Payment Splitter
        Demarco 442
        Charity 150
        Treasury 200
        Trust Me Vodka 163
        Co-Labs: 45
        Total: 1000
    */


  function publicMint(uint256 quantity) external payable
    {
        require(presaleOnly == false);
        require(quantity <= maxPerMint, "You can't mint this many at once.");
        require(addressMintedBalance[msg.sender] + quantity <= maxPerWallet, "You minted as many as you can already.");
        require(msg.value >= cost * quantity, "Insufficient Funds.");
        require(tx.origin == msg.sender, "No contracts!");
        _mint(msg.sender, quantity,"",true);
        addressMintedBalance[msg.sender] += quantity;
    }

    function preSaleMint(uint256 quantity, bytes32[] calldata proof) external payable
    {
        require(addressMintedBalance[msg.sender] + quantity <= maxPerPresale, "You minted as many as you can already.");
        require(msg.value >= cost * quantity, "Insufficient Funds.");
        require(tx.origin == msg.sender, "No contracts!");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid Merkle Tree proof supplied");

        _mint(msg.sender, quantity,"",true);
        addressMintedBalance[msg.sender] += quantity;    
    }

    

    

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }    

    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
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

    function setMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        merkleRoot = _newMerkleRoot;
    }

    function setPresaleOnly(bool _state) external onlyOwner {
        presaleOnly = _state;
    }

    function reveal(bool _state, string memory baseURI) external onlyOwner {
        revealed = _state;
        _baseTokenURI = baseURI;
    }

}