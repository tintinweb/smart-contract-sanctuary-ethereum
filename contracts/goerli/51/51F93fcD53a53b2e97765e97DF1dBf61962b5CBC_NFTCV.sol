/**
 *Submitted for verification at Etherscan.io on 2023-03-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//@custom:dev-run-script "scripts/run.js"
contract NFTCV {

    string private _name; // Token name
    string private _symbol; // Token symbol
    string private _baseURI; // Uniform Resource Identifier (URI) from IPFS 

    uint256 private _MAX_SUPPLY; // Max supply of nfts for this collection
    uint256 private _PRICE; // Price of one nft
    uint256 private _MAX_PER_MINT; // Max nft allowed per mint

    address public _owner = msg.sender; // Whom created the contract
    uint256 public totalMinted = 0; // Initialize minted nfts counter

    mapping(uint256 => address) private _nftOwners; // Mapping from token ID to owner address
    mapping(address => bool) private _hasMinted; // Mapping to keep track of whether an address has already minted an NFT

    event Mint(address indexed from, address indexed to, uint256 indexed nftID);

    constructor(string memory name_, string memory symbol_, string memory baseURI_, uint256 maxSupply_, uint256 price_, uint256 maxPerMint_) {
        _name = name_;
        _symbol = symbol_;
        _baseURI = baseURI_;
        _MAX_SUPPLY = maxSupply_;
        _PRICE = price_;
        _MAX_PER_MINT = maxPerMint_;
    }

    modifier onlyOwner() { 
        require(_owner == msg.sender, "You try to steal my funds :-)");
         _;
        }

    function name() public view returns (string memory) { return _name; } // Returns the token collection name
    function symbol() public view returns (string memory) { return _symbol; } // Returns the token collection symbol
    function baseURI() public view returns (string memory) { return _baseURI; } // Returns the address of the NFT
    function maxSupply() public view returns (uint256) { return _MAX_SUPPLY; } // Returns the max supply of nfts
    function price() public view returns (uint256) { return _PRICE; } // Returns the price to mint an nft
    function maxPerMint() public view returns (uint256) { return _MAX_PER_MINT; } // Returns the max nft allowed per mint
    
    function ownerOf(uint256 _nftID) public view returns (address) {
        require(totalMinted > 0, "No CV minted for now, please mint the first one or wait for someone else");
        return _nftOwners[_nftID]; } // Returns nfts owners

    function mintNFT() public payable {
        require(!_hasMinted[msg.sender], "Sorry, you can only obtain one CV."); // The caller can't mint more than 1 NFT
        require((totalMinted + 1) <= _MAX_SUPPLY, "Not enough CV let in the collection!"); // Are there enough NFTs left in the collection for the caller to mint the requested amount?
        require(msg.value == _PRICE, "Please provide the correct amount of Ether."); // Has the caller sent enough ether to mint the NFT?
        _mintSingleNFT(); // Call the mint function
        
    }

    function _mintSingleNFT() private {
        totalMinted += 1; // Increase by 1 of number of nft minted (no nftID = 0, starts wit nftID =1)
        uint256 nftID = totalMinted; // ID of the new token minted = total of nft minted including this new one
        _hasMinted[msg.sender] = true; // Set the flag to indicate that the caller has minted 1 NFT
        _nftOwners[nftID] = msg.sender; // Mint the new NFT and assign ownership to the caller

        emit Mint(address(0), msg.sender, nftID);
    }

    function withdraw() public payable onlyOwner{
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");
        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }
}