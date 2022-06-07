// SPDX-License-Identifier: MIT

/*

This Contract was ceated & edited according to the requirements of the "CryptoPunks" by AppslkOfficial


                           _ _     ____   __  __ _      _       _ 
     /\                   | | |   / __ \ / _|/ _(_)    (_)     | |
    /  \   _ __  _ __  ___| | | _| |  | | |_| |_ _  ___ _  __ _| |
   / /\ \ | '_ \| '_ \/ __| | |/ / |  | |  _|  _| |/ __| |/ _` | |
  / ____ \| |_) | |_) \__ \ |   <| |__| | | | | | | (__| | (_| | | 
 /_/    \_\ .__/| .__/|___/_|_|\_\\____/|_| |_| |_|\___|_|\__,_|_|
          | |   | |                                               
          |_|   |_|                                               

- https://bit.ly/3Q5kPbJ
*/

pragma solidity ^0.8.4;

import "ERC721A.sol";
import "Ownable.sol";

contract CryptoPunks is ERC721A, Ownable {
    using Strings for uint256;


    string public baseURI;

    bool public paused = false;

    uint256 MAX_SUPPLY = 9999;

    uint256 public publicSaleCost = 0.005 ether;

    uint256 public publicSaleLimit  = 6999;    
    uint256 public freeMintLimit  = 3000;

    uint256 public overallPublicSaleMints;
    uint256 public overallFreeMints;

    mapping(address => uint256) public freemint_claimed;
    mapping(address => uint256) public publicmint_claimed;

    bool public public_mint_status = false;
    bool public free_mint_status = false;



    constructor(string memory _initBaseURI) ERC721A("Crypto Punks", "CP") {
    
    setBaseURI(_initBaseURI);
    }

    function mint(uint256 quantity) public payable  {
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        require(overallPublicSaleMints + quantity <= publicSaleLimit, "Overall public minting limit reached" );

        if (msg.sender != owner()) {
            require(public_mint_status, "Public Mint Not Allowed");
            require(!paused, "The contract is paused");
            require(msg.value >= (publicSaleCost * quantity), "Not enough ether sent");          
           
        }
        _safeMint(msg.sender, quantity);
         publicmint_claimed[msg.sender] =  publicmint_claimed[msg.sender] + quantity;
         overallPublicSaleMints = overallPublicSaleMints + quantity;

    }

  
     // Free Mint

   function freemint() payable public{
   require(overallFreeMints + 1 <= freeMintLimit, "Overall free minting limit reached" );

   require(free_mint_status, "Free Mint Not Allowed");

   require(totalSupply() + 1 <= MAX_SUPPLY, "Not enough tokens left");
   require(freemint_claimed[msg.sender] < 1, "Free Mint Already Claimed");
  
    _safeMint(msg.sender, 1);
    freemint_claimed[msg.sender] = freemint_claimed[msg.sender] + 1;
    overallFreeMints = overallFreeMints + 1;
  }


     function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

          return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(),".json")) : '';
    }



    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    //only owner    
    function setStatus_freemint() public onlyOwner {
        if(free_mint_status == true){

            free_mint_status = false;

        } else {

        free_mint_status = true;

        public_mint_status = false;
        }
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