/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Strings.sol";
import "./Shareholders.sol";
import "./ERC721A.sol";
import "./MerkleProof.sol";



contract WEDRIPZ is ERC721A, Shareholders {
    using Strings for uint;
    string public _baseTokenURI;
    uint public maxPerPresale = 25;
    uint public maxPerMint = 15;
    uint public maxPerWallet = 75;
    uint public cost = 0.0777 ether;
    uint public presaleCost = 0.069 ether; 
    uint public maxSupply = 9999;
    bool public paused = true;
    bool public presaleOnly = true;
    bool public revealed = false;
    bytes32 public merkleRoot;

    mapping(address => uint) public addressMintedBalance;

  constructor(
    ) ERC721A("WEDRIPZ", "SV")payable{
        _mint(msg.sender, 30);
    }

    
    modifier mintCompliance(uint256 quantity) {
        require(paused == false, "Contract is paused");
        require(_totalMinted() + quantity <= maxSupply, "Collection is capped at 9,999");
        require(tx.origin == msg.sender, "No contracts!");
        require(quantity <= maxPerMint, "You can't mint this many at once.");
        require(addressMintedBalance[msg.sender] + quantity <= maxPerWallet, "You minted as many as you can already.");
        if (presaleOnly == true) {
            require(msg.value >= presaleCost * quantity, "Insufficient Funds.");
        } else {
            require(msg.value >= cost * quantity, "Insufficient Funds.");
        }
        _;
    }



  function mint(uint256 quantity) mintCompliance(quantity) external payable
    {
        _mint(msg.sender, quantity);
        addressMintedBalance[msg.sender] += quantity;
    }

    function driplist(uint256 quantity, bytes32[] calldata proof) mintCompliance(quantity) external payable
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid Merkle Tree proof supplied");
        _mint(msg.sender, quantity);
        addressMintedBalance[msg.sender] += quantity;    
    }

    function ownerMint(uint256 quantity) external onlyOwner
    {
        require(_totalMinted() + quantity <= maxSupply, "Collection is capped at 9,999");
        _mint(msg.sender, quantity);
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

    function setPause(bool _state) external onlyOwner {
        paused = _state;
    }

    function setPresaleOnly(bool _state) external onlyOwner {
        presaleOnly = _state;
    }

    function reveal(bool _state, string memory baseURI) external onlyOwner {
        revealed = _state;
        _baseTokenURI = baseURI;
    }

}