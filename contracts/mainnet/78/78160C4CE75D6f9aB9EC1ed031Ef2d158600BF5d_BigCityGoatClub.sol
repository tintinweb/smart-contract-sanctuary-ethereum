// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721A.sol";
import "Ownable.sol";


contract BigCityGoatClub is ERC721A, Ownable {
    using Strings for uint256;


    string private baseURI;

    uint256 public MAX_SUPPLY = 5800;  
    uint256 public Avl_Supply = 86;
    uint256 public cost = 0.05 ether;
    address public owner75 = 0x1d5e0BFE7E8a492E53F05bA78811e3d157613881;
    address public owner25 = 0x15F234b33DFC175d23AC2F4d0D636f0092AAfF60;

    bool public paused = false;


    constructor(string memory _initBaseURI) ERC721A("Big City Goat Club ", "BCGC") {
    
    setBaseURI(_initBaseURI);
  
    }

    function mint(uint256 quantity) public payable {
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(Avl_Supply <= MAX_SUPPLY);
        require(!paused, "the contract is paused");
        require(totalSupply() + quantity <= Avl_Supply, "Not enough tokens left");
        uint256 supply = totalSupply();

        if (msg.sender != owner()) {

            if(supply == Avl_Supply){
            revert("All tokens in the session have been sold!");

            } else {
            require(msg.value >= (cost * quantity), "Not enough ether sent");  
            
            }
                       
            
        }
        _safeMint(msg.sender, quantity);

        

    }

     function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(),".json")) : '';
    }



    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    //only owner

    function setAvl_supply(uint256 _avlSupply) public onlyOwner {
        Avl_Supply = _avlSupply;
    }


    function withdraw() public payable onlyOwner {


    (bool main, ) = payable(owner75).call{value: address(this).balance * 75/100}("");
    require(main);

    (bool minor, ) = payable(owner25).call{value: address(this).balance}("");
    require(minor);

    }   
    
    function setMintRate(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setOwners(address _owner75, address _owner25) public onlyOwner {
        owner75 = _owner75;
        owner25 = _owner25;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
   }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }
 
   
}