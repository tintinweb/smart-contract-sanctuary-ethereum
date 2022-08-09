// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721A.sol";
import "Ownable.sol";


contract Moonwhalez is ERC721A, Ownable {
    using Strings for uint256;


    string public baseURI;

    bool public paused = false;

    uint256 MAX_SUPPLY = 10000;
    string public notRevealedUri;
    
    bool public revealed = true;

    uint256 public publicSaleCost = 0.0069 ether;

    uint256 public total_free_mint_claimed;
    uint256 public freemintLimit = 4200;

    uint256 public per_wallet_limit = 20;

    constructor(string memory _initBaseURI, string memory _initNotRevealedUri) ERC721A("Moonwhalez", "MW") {
    
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);    

    }

    function mint(uint256 quantity) public payable  {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");

        if (msg.sender != owner()) {
            require(!paused, "the contract is paused");
            require(balanceOf(msg.sender) + quantity <= per_wallet_limit);

            if(totalSupply() + quantity <= freemintLimit){
              total_free_mint_claimed = total_free_mint_claimed + quantity;
            }else{
            require(msg.value >= (publicSaleCost * quantity), "Not enough ether sent");          

            }
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
   
    function withdraw() public payable onlyOwner {

    (bool main1, ) = payable(owner()).call{value:address(this).balance}("");
    require(main1);

    }
    
    function setPublicSaleCost(uint256 _publicSaleCost) public onlyOwner {
        publicSaleCost = _publicSaleCost;
    }

    function setPer_wallet_limit(uint256 _per_wallet_limit) public onlyOwner {
        per_wallet_limit = _per_wallet_limit;
    }

    function setFreemintLimit(uint256 _freemintLimit) public onlyOwner {
        freemintLimit = _freemintLimit;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
   }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }
       
}