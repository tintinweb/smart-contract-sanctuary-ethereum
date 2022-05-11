// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721A.sol";
import "Ownable.sol";



contract RogueCroc is ERC721A, Ownable {
    using Strings for uint256;


    string public baseURI;

    uint256 public nftPerTxnLimit = 20;

    bool public paused = false;
    bool public freemint = true;


    uint256 MAX_SUPPLY = 5555;

     uint256 public cost = 0.06 ether;


    constructor(string memory _initBaseURI) ERC721A("Rogue Croc Animated", "RCA") {
    
    setBaseURI(_initBaseURI);
    }

    function mint(uint256 quantity) public payable  {
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(!paused, "the contract is paused");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");


        if(msg.sender != owner()){

        require(quantity <= nftPerTxnLimit, "Your minting limit reached");

        if(freemint){

        _safeMint(msg.sender, quantity);

        } else {


                require(msg.value >= cost * quantity);

                 _safeMint(msg.sender, quantity);

                }
        } else {
            
            _safeMint(msg.sender, quantity);

        }
       
        


    }
  


     function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(),".json")) : '';
    }



    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    //only owner

     
    function setNftPerTxnLimit(uint256 _limit) public onlyOwner {
        nftPerTxnLimit = _limit;
    }
  
  

    function withdraw() public payable onlyOwner {
    (bool main, ) = payable(owner()).call{value: address(this).balance}("");
    require(main);
    }
    

   
    function setPublicSaleCost(uint256 _publicSaleCost) public onlyOwner {
        cost = _publicSaleCost;
    }


    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
   }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

      function freeMintState(bool _state) public onlyOwner {
        freemint = _state;
    }

   
  
  
}