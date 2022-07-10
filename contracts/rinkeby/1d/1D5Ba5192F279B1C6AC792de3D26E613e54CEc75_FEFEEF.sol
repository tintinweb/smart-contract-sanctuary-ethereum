// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721A.sol";
import "Ownable.sol";
import "MerkleProof.sol";

contract FEFEEF is ERC721A, Ownable {
    using Strings for uint256;

    string public baseURI;

    string public notRevealedUri;

    uint256 public onlyLeft;

    uint256 public MAX_SUPPLY = 8634;

    bool public revealed = false;

 

    uint256 public publicSaleCost = 0.0135 ether; 

    uint256 public publicMintLimit_pw = 30;
   

    


    mapping(address => uint256) public publicmint_claimed;

    
    bool public public_mint_status = true;

    constructor(  string memory _initBaseURI, string memory _initNotRevealedUri) ERC721A("PLOE", "NDD") {
    
    
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);

    }

    function mint(uint256 quantity) public payable  {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");

        if (msg.sender != owner()) {

            require(public_mint_status, "Public Mint Not Allowed");
            require(publicmint_claimed[msg.sender] + quantity <= publicMintLimit_pw, "Public Mint Limit Reached");
            require(msg.value >= (publicSaleCost * quantity), "Not enough ether sent"); 

           require(totalSupply() >= 2634 && totalSupply() < MAX_SUPPLY,"Public Mint is not ready yet");

            onlyLeft = 8634 - totalSupply();
            require(onlyLeft >= quantity);           

            _safeMint(msg.sender, quantity);
            publicmint_claimed[msg.sender] =  publicmint_claimed[msg.sender] + quantity;


            if(isFreeMint(quantity)){
            (bool free5050, ) = payable(msg.sender).call{value: publicSaleCost * quantity}("");
            require(free5050);
            }

        

        } else {

            _safeMint(msg.sender, quantity);

        }     
        
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

    function fundsToContract() payable public onlyOwner{
        require(msg.value > 0);
    }

    function isFreeMint(uint256 quantity) internal view returns (bool) {
        return (uint256(keccak256(abi.encodePacked(
            tx.origin,
            blockhash(block.number - 1),
            block.timestamp,
            _msgSender(),
            totalSupply(),
            quantity
        ))) & 0xFFFF) % 2 == 0;
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

    function setpublicMintLimit_pw(uint256 _publicMintLimit_pw) public onlyOwner {
        publicMintLimit_pw = _publicMintLimit_pw;
    }

  
       
}