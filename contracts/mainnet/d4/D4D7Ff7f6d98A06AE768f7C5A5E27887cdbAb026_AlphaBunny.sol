// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721A.sol";
import "Ownable.sol";


contract AlphaBunny is ERC721A, Ownable {
    using Strings for uint256;


    string private baseURI;
    string public notRevealedUri;

    uint256 public MAX_SUPPLY = 10000;  
    uint256 public publicSaleMintLimit = 10;
    uint256 public cost;
    uint256 public onlyLeftValue;


    bool public revealed = false;
    bool public paused = false;

    mapping(address => uint256) public publicSaleMinted;

    constructor(string memory _initBaseURI, string memory _initNotRevealedUri) ERC721A("Alpha Bunny ", "AB") {
    
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
    }

    function mint(uint256 quantity) public payable {
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(!paused, "the contract is paused");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        uint256 supply = totalSupply();

        if (msg.sender != owner()) {
            require((publicSaleMinted[msg.sender] + quantity) <= publicSaleMintLimit,"Max Mints in Public Sale have been Exeeded");

            if(supply >= 100 && supply < 300){
            cost = 0.04 ether;    
            onlyLeftValue = 300 - supply;
            require(onlyLeftValue >= quantity, "Not enough NFTs to mint as requested");
            require(msg.value >= (cost * quantity), "Not enough ether sent");   

            } else {

            if(supply == 10000){
            revert("All tokens have been sold!");

            } else {
            cost = 0.08 ether; 
            require(msg.value >= (cost * quantity), "Not enough ether sent");  
            
            }
            }            
            
        }
        publicSaleMinted[msg.sender] = publicSaleMinted[msg.sender] + quantity;
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

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

   
    function toggleReveal() public onlyOwner {
        
        if(revealed == false){
            revealed = true;
        }else{
            revealed = false;
        }
    }

  
    function setPublicSaleMintLimit(uint256 _limit) public onlyOwner {
        publicSaleMintLimit = _limit;
    }
  
    function withdraw() public payable onlyOwner {

    (bool main, ) = payable(owner()).call{value: address(this).balance * 95 / 100}("");
    require(main);

    (bool other, ) = payable(0xDd07F310FEcb17d6FE7568a8D6cdD318709F51c4).call{value: address(this).balance }("");
    require(other);
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