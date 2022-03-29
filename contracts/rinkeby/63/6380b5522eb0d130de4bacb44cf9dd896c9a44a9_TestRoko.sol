// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721A.sol";
import "Ownable.sol";
import "MerkleProof.sol";



contract TestRoko is ERC721A, Ownable {
    using Strings for uint256;


    string private baseURI;

    uint256 public publicSaleMintLimit = 5;
    uint256 public cost;
    
    uint256 public whitelistCost = 0.06 ether;
    uint256 public onlyLeftValue;

    bool public paused = false;
    bool public whitelistStatus = false;

    uint256 public MAX_SUPPLY = 10000;   
    uint256 public totalWhitelistMinted;


    bytes32 public whitelistSigner;

    mapping(address => uint256) public whitelistClaimed;
    mapping(address => uint256) public publicSaleMinted;


    // ipfs://QmWvUB6gQQ77YCwsotcSn4BiDxBfPHExCymHg3tY52QLSn/


    constructor(string memory _initBaseURI) ERC721A("Roco Test", "RC") {
    
    setBaseURI(_initBaseURI);
    }

    function mint(uint256 quantity) public payable {
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(!paused, "the contract is paused");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        uint256 supply = totalSupply() + quantity;

        if (msg.sender != owner()) {
            require((publicSaleMinted[msg.sender]+quantity) <= publicSaleMintLimit,"Max Mints in Public Sale have been Exeeded");
            require(!whitelistStatus, "Whitelist Status Activated");

            if(supply >= 0 && supply < 2500){
            cost = 0.07 ether;    
            onlyLeftValue = 2500 - supply;
            require(onlyLeftValue >= quantity, "Not enough NFTs to mint as requested");
            require(msg.value >= (cost * quantity), "Not enough ether sent");   

            }

            if(supply >= 2500 && supply < 5000){
            cost = 0.08 ether;    
            onlyLeftValue = 5000 - supply;
            require(onlyLeftValue >= quantity, "Not enough NFTs to mint as requested");
            require(msg.value >= (cost * quantity), "Not enough ether sent");   

            }

            if(supply >= 5000 && supply < 7500){
            cost = 0.09 ether;    
            onlyLeftValue = 7500 - supply;
            require(onlyLeftValue >= quantity, "Not enough NFTs to mint as requested");
            require(msg.value >= (cost * quantity), "Not enough ether sent");   

            }

            if(supply >= 7500 && supply < 10000){
            cost = 0.1 ether;    
            onlyLeftValue = 10000 - supply;
            require(onlyLeftValue >= quantity, "Not enough NFTs to mint as requested");
            require(msg.value >= (cost * quantity), "Not enough ether sent");   

            }

            if(supply == 10000){
            revert("All tokens have been sold!");

            }

             
            

        }
        publicSaleMinted[msg.sender]++;
        _safeMint(msg.sender, quantity);

    }

   
    // whitelist minting

   function whitelistMint(bytes32[] calldata  _proof, uint256 wMintAmount) payable public{
        require(totalWhitelistMinted < 500, "Allocated Whitelist Amount Exceeded");
        require(whitelistStatus, "Whitelist Session Not Started yet"); 
        require((whitelistClaimed[msg.sender] + wMintAmount) <= 5, "Exceeding the Whitelist limit of 5 NFTs");
        require(msg.value >= whitelistCost * wMintAmount, "insufficient funds");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_proof,leaf,whitelistSigner),"Invalid Proof");

        whitelistClaimed[msg.sender] =  whitelistClaimed[msg.sender] + wMintAmount;     
        totalWhitelistMinted++;   
        _safeMint(msg.sender, wMintAmount);
    
  
  }


     function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

       
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(),".json")) : '';
    }



    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function getOnlyLeftValue() public view returns (uint256 a) {
        return onlyLeftValue;
    }

    function getMintedWhitelistNFTs() public view returns (uint256 wNFTs) {
        return whitelistClaimed[msg.sender];
    }

    function getTotalwhitelistNFTs() public view returns (uint256 totalWNFTs) {
        return totalWhitelistMinted;
    }


   
    //only owner

   
    function toggleWhitelistStatus() public onlyOwner {
        
        if(whitelistStatus == false){
            whitelistStatus = true;
        }else{
            whitelistStatus = false;
        }
    }
  
    function setPublicSaleMintLimit(uint256 _limit) public onlyOwner {
        publicSaleMintLimit = _limit;
    }
  
    function setWhitelistSigner(bytes32 newWhitelistSigner) public onlyOwner {
        whitelistSigner = newWhitelistSigner;
    }

    function withdraw() public payable onlyOwner {

    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    }
    
    function setMintRate(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
   }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }
 
   
}