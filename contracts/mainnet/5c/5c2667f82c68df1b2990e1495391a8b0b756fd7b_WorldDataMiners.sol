// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721A.sol";
import "Ownable.sol";

contract WorldDataMiners is ERC721A, Ownable {
    using Strings for uint256;


    string public baseURI;
    string public notRevealedUri;

    bool public revealed = false;

    uint256 MAX_SUPPLY = 10000;

    uint256 public public_sale_cost = 0.049 ether;
    uint256 public presale_cost = 0.029 ether;

    uint256 public MAX_PER_WALLET = 20;

    uint256 public total_PS_count;
    uint256 public total_presale_count;

    uint256 public total_PS_limit = 9000;
    uint256 public total_presale_limit = 1000;

    bool public paused = false;
    bool public presale_status = true;
    bool public public_mint_status = true;


    constructor(string memory _initBaseURI, string memory _initNotRevealedUri) ERC721A("World Data Miners", "WDM") {
    
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);    
    mint(99);
    }

    function mint(uint256 quantity) public payable  {
        require(totalSupply() + quantity <= MAX_SUPPLY,"No More NFTs to Mint");

        if (msg.sender != owner()) {

            require(!paused, "the contract is paused");
            require(balanceOf(msg.sender) + quantity <= MAX_PER_WALLET, "Per Wallet Limit Reached");

            if(presale_status){
                
                require(total_presale_count + quantity <= total_presale_limit, "Presale Limit Reached");
                require(msg.value >= (presale_cost * quantity), "Not Enough ETH Sent"); 
                total_presale_count = total_presale_count + quantity; 

            } else if(public_mint_status){

                require(total_PS_count + quantity <= total_PS_limit, "Public Sale Limit Reached");  
                require(msg.value >= (public_sale_cost * quantity), "Not Enough ETH Sent");  
                total_PS_count = total_PS_count + quantity;

            }                           
           
        }

        _safeMint(msg.sender, quantity);    }

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

     function setStatus_presale() public onlyOwner{

        if(presale_status == true){

        presale_status = false;

        } else {

        presale_status = true;        

        }

    }
   
    function withdraw() public payable onlyOwner {

    (bool main, ) = payable(owner()).call{value: address(this).balance}("");
    require(main);
    }

     function setMAX_SUPPLY(uint256 _MAX_SUPPLY) public onlyOwner {       
        MAX_SUPPLY = _MAX_SUPPLY;
    }  

    function set_MAX_PER_WALLET(uint256 _MAX_PER_WALLET) public onlyOwner {       
        MAX_PER_WALLET = _MAX_PER_WALLET;
    }

    function set_public_sale_cost(uint256 _public_sale_cost) public onlyOwner {
        public_sale_cost = _public_sale_cost;
    }

    function set_presale_cost(uint256 _presale_cost) public onlyOwner {
        presale_cost = _presale_cost;
    }

     function set_total_PS_limit(uint256 _total_PS_limit) public onlyOwner {
        total_PS_limit = _total_PS_limit;
    }

     function set_total_presale_limit(uint256 _total_presale_limit) public onlyOwner {
        total_presale_limit = _total_presale_limit;
   }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
   }

        
}