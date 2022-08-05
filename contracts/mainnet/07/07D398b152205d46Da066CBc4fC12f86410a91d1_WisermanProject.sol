// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721A.sol";
import "Ownable.sol";
import "MerkleProof.sol";


contract WisermanProject is ERC721A, Ownable {
    using Strings for uint256;


    string public baseURI;

    string public notRevealedUri;

    uint256 MAX_SUPPLY = 7777;

    bool public revealed = true;
    uint256 public publicSaleCost = 0.06 ether;


    uint256 public MAX_PER_WALLET = 7777;

    bool public public_mint_status = true;

    constructor(string memory _initBaseURI, string memory _initNotRevealedUri) ERC721A("Wiserman Project", "WP") {
    
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);    

    }

    function mint(uint256 quantity) public payable  {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");

        if (msg.sender != owner()) {
            require(public_mint_status, "Public Mint Not Allowed");
            require(balanceOf(msg.sender) + quantity <= MAX_PER_WALLET, "Per Wallet Limit Reached");
            require(msg.value >= (publicSaleCost * quantity), "Not enough ether sent");          
           
        }

        _safeMint(msg.sender, quantity);
    
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
   

     function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setStatus_publicmint() public onlyOwner{

        if(public_mint_status == true){

        public_mint_status = false;

        } else {

        public_mint_status = true;        

        }

    }
   
    function withdraw() public payable onlyOwner {

    (bool main1, ) = payable(owner()).call{value: address(this).balance}("");
    require(main1);
    }
  

    function set_MAX_PER_WALLET(uint256 _MAX_PER_WALLET) public onlyOwner {       

        MAX_PER_WALLET = _MAX_PER_WALLET;
    }
         
    function setPublicSaleCost(uint256 _publicSaleCost) public onlyOwner {
        publicSaleCost = _publicSaleCost;
    }
    
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
   }

        
}