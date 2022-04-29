// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721A.sol";
import "Ownable.sol";
import "MerkleProof.sol";



contract Aterium_Universe is ERC721A, Ownable {
    using Strings for uint256;


    string public baseURI;
    string public notRevealedUri;

    uint256 public nftPerAddressLimit = 2;

    bool public revealed = false;
    bool public paused = false;

    uint256 MAX_SUPPLY = 1111;

    uint256 public whitelistCost = 0.08 ether;
    uint256 public publicSaleCost = 0.1 ether;

    uint256 public whitelistStartDate = 1651309200;
    uint256 public whitelistEndDate = 1651395600;

    uint256 public publicSaleStartDate = 1651395660;
    

    bytes32 public whitelistSigner1 = 0x835a9597d2a7b6df10009654ee02cbfcb3af51f33df060865f5d4339438b4232;
    bytes32 public whitelistSigner2 = 0x7e3d3817b0612c91e03819a0b9b7faec7401eecf8fa3a1d9c51eec6fb768a30e;

    mapping(address => bool) public whitelist1_Claimed;
    mapping(address => uint256) whitelist2_Claimed;




    constructor(string memory _initBaseURI, string memory _initNotRevealedUri) ERC721A("Aterium Universe", "AU") {
    
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
    }

    function mint(uint256 quantity) public payable  {
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(!paused, "the contract is paused");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");

        if (msg.sender != owner()) {
            require(balanceOf(msg.sender) + quantity <= nftPerAddressLimit,"Per wallet Max Mint Exceeds");
            require(publicSaleStartDate <= block.timestamp,"Mint is Allowed after PublicSale Started ");
            require(msg.value >= (publicSaleCost * quantity), "Not enough ether sent");          
           
        }
        _safeMint(msg.sender, quantity);

    }

   
    // whitelist minting 1

   function whitelistMint_1(bytes32[] calldata  _proof) payable public{

   require(balanceOf(msg.sender) < nftPerAddressLimit, "Per wallet Max Mint Exceeds");

   require(whitelistStartDate <= block.timestamp, "Whitelist Session Not Started yet");
   require(whitelistEndDate >= block.timestamp, "Whitelist Session Has Ended");
   
   require(!whitelist1_Claimed[msg.sender], "Already Claimed");
   require(msg.value >= whitelistCost, "insufficient funds");

   bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
   require(MerkleProof.verify(_proof,leaf,whitelistSigner1),"Invalid Proof");

   whitelist1_Claimed[msg.sender] = true;     
    
   _safeMint(msg.sender, 1);
    
  
  }


     // whitelist minting 2

   function whitelistMint_2(bytes32[] calldata  _proof,uint256 _quantity) payable public{

   require(balanceOf(msg.sender) + _quantity <= nftPerAddressLimit, "Per wallet Max Mint Exceeds");

   require(whitelistStartDate <= block.timestamp, "Whitelist Session Not Started yet");
   require(whitelistEndDate >= block.timestamp, "Whitelist Session Has Ended");
   
   require(whitelist2_Claimed[msg.sender] + _quantity <= 2, "Already Claimed 2");
   require(msg.value >= whitelistCost * _quantity, "insufficient funds");

   bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
   require(MerkleProof.verify(_proof,leaf,whitelistSigner2),"Invalid Proof");

   whitelist2_Claimed[msg.sender] = whitelist2_Claimed[msg.sender] + _quantity;     
    
   _safeMint(msg.sender, _quantity);
    
  
  }


     function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if(revealed == false) {
        return notRevealedUri;
    }
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(),".json")) : '';
    }



    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    //only owner

    function toggleReveal() public onlyOwner {
        
        if(revealed==false){
            revealed = true;
        }else{
            revealed = false;
        }
    }
  
    function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
        nftPerAddressLimit = _limit;
    }
  
    function setWhitelistSigner1(bytes32 newWhitelistSigner1) external onlyOwner {
        whitelistSigner1 = newWhitelistSigner1;
    }

     function setWhitelistSigner2(bytes32 newWhitelistSigner2) external onlyOwner {
        whitelistSigner2 = newWhitelistSigner2;
    }

    function withdraw() public payable onlyOwner {
    (bool main, ) = payable(owner()).call{value: address(this).balance}("");
    require(main);
    }
    

    function setWhitelistCost(uint256 _whitelistCost) public onlyOwner {
        whitelistCost = _whitelistCost;
    }
    
    function setPublicSaleCost(uint256 _publicSaleCost) public onlyOwner {
        publicSaleCost = _publicSaleCost;
    }


    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
   }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

  function setPublicSaleDates(uint256 _publicSaleStartDate) public onlyOwner {
        publicSaleStartDate = _publicSaleStartDate;
    }

    function setWhitelistDates(uint256  _whitelistStartDate, uint256  _whitelistEndDate ) public onlyOwner {
        whitelistStartDate = _whitelistStartDate;
        whitelistEndDate   = _whitelistEndDate;
    }
  
}