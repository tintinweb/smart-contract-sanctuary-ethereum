// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721A.sol";
import "Ownable.sol";
import "MerkleProof.sol";

contract Hoz4CryptoBroz is ERC721A, Ownable {
    using Strings for uint256;

    string public baseURI;

    string public notRevealedUri;

    uint256 public MAX_SUPPLY = 10000;

    bool public revealed = true;

    uint256 public whitelistCost = 0 ether;
    uint256 public publicSaleCost = 0.055 ether;

    uint256 public publicMintLimit_pw = 9000;
    uint256 public whitelistLimit_pw = 2;

    uint256 public whitelistLimit = 1000;
    uint256 public freeMintLimit = 1000;
    uint256 public publicSaleLimit = 9000;

    uint256 public freeMintCount;
    uint256 public whitelistCount;
    uint256 public publicMintCount;

    bytes32 public whitelistSigner;

    mapping(address => uint256) public whitelist_claimed;
    mapping(address => uint256) public publicmint_claimed;

    uint256 public startDate = 1658160000;

    bool public whitelist_status = true;
    bool public public_mint_status = true;

    constructor(string memory _initBaseURI, string memory _initNotRevealedUri) ERC721A("Hoz4CryptoBroz", "H4CB") {
    
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
    }

    function mint(uint256 quantity) public payable  {

        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");

        if (msg.sender != owner()) {
      
            require(startDate <= block.timestamp, "Minting Not Yet Started");
            require(public_mint_status, "Public Mint Not Allowed");
            require(publicmint_claimed[msg.sender] + quantity <= publicMintLimit_pw, "Public Mint Limit Reached");
            require(publicMintCount + quantity <= publicSaleLimit, "Public Mint Limit Exceeded");

                if(publicmint_claimed[msg.sender] > 0){
                    
                  require(msg.value >= (publicSaleCost * quantity), "Not enough ether sent");     

                } else if(freeMintCount < freeMintLimit){                  

                    require(msg.value >= (publicSaleCost * (quantity-1)), "Not enough ether sent"); 
                    freeMintCount = freeMintCount + 1;

                  } else{

                    require(msg.value >= (publicSaleCost * quantity), "Not enough ether sent");     

                  }                 

                }

            _safeMint(msg.sender, quantity);
            publicmint_claimed[msg.sender] =  publicmint_claimed[msg.sender] + quantity;
            publicMintCount =  publicMintCount + quantity;

        }
         
   

   
    // whitelist minting 

   function whitelistMint(bytes32[] calldata  _proof, uint256 quantity) payable public{

        require(startDate <= block.timestamp, "Minting Not Yet Started");

        require(whitelist_status, "Whitelist Mint Not Allowed");

        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");

        require(whitelist_claimed[msg.sender] + quantity <= whitelistLimit_pw, "Limit Exceed");
        require(msg.value >= whitelistCost * quantity, "insufficient funds");
        require(whitelistCount + quantity <= whitelistLimit, "Whitelist Limit Exceeded");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_proof,leaf,whitelistSigner),"Invalid Proof");
    
        _safeMint(msg.sender, quantity);
        whitelist_claimed[msg.sender] =  whitelist_claimed[msg.sender] + quantity;   
        whitelistCount = whitelistCount + quantity;    
  
  }


     // Free Mint

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
        
        if(revealed == false){
            revealed = true;
        }else{
            revealed = false;
        }
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setStatus_publicmint() public onlyOwner {
        if(public_mint_status == true){

            public_mint_status = false;

        } else {

        public_mint_status = true;
      
        }

    }

     function setStatus_whitelist() public onlyOwner {
        if(whitelist_status == true){

            whitelist_status = false;
           

        } else {

        whitelist_status = true;

         }

    }      
    
  
    function setWhitelistSigner(bytes32 newWhitelistSigner) public onlyOwner {
        whitelistSigner = newWhitelistSigner;
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

    function setpublicMintLimit_pw(uint256 _publicMintLimit_pw) public onlyOwner {
        publicMintLimit_pw = _publicMintLimit_pw;
    }

    function setwhitelistLimit_pw(uint256 _whitelistLimit_pw) public onlyOwner {
        whitelistLimit_pw = _whitelistLimit_pw;
    }

    function setwhitelistLimit(uint256 _whitelistLimit) public onlyOwner {
        whitelistLimit = _whitelistLimit;
    }

    function setfreeMintLimit(uint256 _freeMintLimit) public onlyOwner {
        freeMintLimit = _freeMintLimit;
    }

    function setpublicSaleLimit(uint256 _publicSaleLimit) public onlyOwner {
        publicSaleLimit = _publicSaleLimit;
    }

    function setStartDate(uint256 _startDate) public onlyOwner {
        startDate = _startDate;
    }
       
}


/*

                           _ _     ____   __  __ _      _       _ 
     /\                   | | |   / __ \ / _|/ _(_)    (_)     | |
    /  \   _ __  _ __  ___| | | _| |  | | |_| |_ _  ___ _  __ _| |
   / /\ \ | '_ \| '_ \/ __| | |/ / |  | |  _|  _| |/ __| |/ _` | |
  / ____ \| |_) | |_) \__ \ |   <| |__| | | | | | | (__| | (_| | | 
 /_/    \_\ .__/| .__/|___/_|_|\_\\____/|_| |_| |_|\___|_|\__,_|_|
          | |   | |                                               
          |_|   |_|                                               


               https://www.fiverr.com/appslkofficial


*/