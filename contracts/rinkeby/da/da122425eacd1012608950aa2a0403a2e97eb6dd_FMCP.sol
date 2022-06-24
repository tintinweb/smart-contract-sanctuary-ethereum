// SPDX-License-Identifier: MIT


pragma solidity ^0.8.4;

import "ERC721A.sol";
import "Ownable.sol";
import "MerkleProof.sol";



contract FMCP is ERC721A, Ownable {
    using Strings for uint256;


    string public baseURI;
    string public extension;

    bool public paused = false;
    string public notRevealedUri;

    uint256 MAX_SUPPLY = 4000;

    bool public revealed = true;

    uint256 public publicSaleCost;

    mapping(address => uint256) public freemint_claimed;
    mapping(address => uint256) public publicmint_claimed;

    bool public public_mint_status = false;
    bool public free_mint_status = true;

    constructor(string memory _initBaseURI, string memory _initNotRevealedUri) ERC721A("Free Minters Community Pass", "FMCP") {
    
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
    mint(500);
    }

    function mint(uint256 quantity) public payable  {
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");

        if (msg.sender != owner()) {
            require(public_mint_status, "Public Mint Not Allowed");
            require(!paused, "The contract is paused");
            require(msg.value >= (publicSaleCost * quantity), "Not enough ether sent");          
           
        }
        _safeMint(msg.sender, quantity);
         publicmint_claimed[msg.sender] =  publicmint_claimed[msg.sender] + quantity;

    }

    

     // Free Mint

   function freemint() payable public{

   require(free_mint_status, "Free Mint Not Allowed");

   require(totalSupply() + 1 <= MAX_SUPPLY, "Not enough tokens left");
   require(freemint_claimed[msg.sender] < 1, "Free Mint Already Claimed");
  
    _safeMint(msg.sender, 1);
    freemint_claimed[msg.sender] = freemint_claimed[msg.sender] + 1;
   
  }


     function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if(revealed == false) {
        return notRevealedUri;
        }
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), extension)) : '';
    }



    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    //only owner    

      function toggleReveal() public onlyOwner {
        
        if(revealed == false){
            revealed = true;
        } else {
            revealed = false;
        }
    }

    function setStatus_freemint() public onlyOwner {

        if(free_mint_status == true){

        free_mint_status = false;

        } else {

        free_mint_status = true;

        public_mint_status = false;

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
        
        free_mint_status = false;

        }

    }

    function withdraw() public payable onlyOwner {
    (bool main, ) = payable(owner()).call{value: address(this).balance}("");
    require(main);
    }

    function setExtension(string memory _extension) public onlyOwner{
        extension = _extension;
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