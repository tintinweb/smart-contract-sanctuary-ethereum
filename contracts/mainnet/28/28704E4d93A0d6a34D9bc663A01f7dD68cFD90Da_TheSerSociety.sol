// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "IERC721.sol";
import "ERC721A.sol";
import "Ownable.sol";
import "MerkleProof.sol";

contract TheSerSociety is ERC721A, Ownable {
    using Strings for uint256;

    string public baseURI;

    bool public paused = false;

    uint256 MAX_SUPPLY = 10000;

    string public notRevealedUri;
    
    bool public revealed = false;

    uint256 public whitelistCost = 0.01 ether;
    uint256 public publicSaleCost = 0.01 ether;
    uint256 public max_per_wallet = 2;
    uint256 public special_price = 0.01 ether;

    bytes32 public whitelistSigner;
    
    IERC721 public nft1;
    IERC721 public nft2;

     // Contract Addresses
    address _nft_Contract_1 = 0xbCe3781ae7Ca1a5e050Bd9C4c77369867eBc307e;
    address _nft_Contract_2 = 0xE6d48bF4ee912235398b96E16Db6F310c21e82CB;

    constructor(string memory _initBaseURI, string memory _initNotRevealedUri) ERC721A("The Ser Society", "SER") {
    
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);    
    nft1 = IERC721(_nft_Contract_1);
    nft2 = IERC721(_nft_Contract_2);

    }

    function mint(uint256 quantity) public payable  {

        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");

        if (msg.sender != owner()) {
            require(!paused, "the contract is paused");
            require(balanceOf(msg.sender) + quantity <= max_per_wallet, "Per wallet limit reached");

            if(nft1.balanceOf(msg.sender) > 0 || nft2.balanceOf(msg.sender) > 0){
                require(msg.value >= (special_price * quantity), "Not enough ether sent");          
            }else{
              require(msg.value >= (publicSaleCost * quantity), "Not enough ether sent");        

            }
           
        }
        _safeMint(msg.sender, quantity);
    }
   
    // whitelist minting 

   function whitelistMint(bytes32[] calldata _proof, uint256 quantity) payable public{

   require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
   require(balanceOf(msg.sender) + quantity <= max_per_wallet,"Per wallet limit reached");

   require(msg.value >= whitelistCost * quantity, "insufficient funds");
   require(!paused, "the contract is paused");

   bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
   require(MerkleProof.verify(_proof,leaf,whitelistSigner),"Invalid Proof");
    
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
  
    function setWhitelistSigner(bytes32 newWhitelistSigner) external onlyOwner {
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

    function setMax_per_wallet(uint256 _max_per_wallet) public onlyOwner {
        max_per_wallet = _max_per_wallet;
    }

    function setMAX_SUPPLY(uint256 _MAX_SUPPLY) public onlyOwner {
        MAX_SUPPLY = _MAX_SUPPLY;
    }

    function setSpecial_price(uint256 _special_price) public onlyOwner {
        special_price = _special_price;
    }

    function setNft_Contract_1(address __nft_Contract_1) public onlyOwner {
        nft1 = IERC721(__nft_Contract_1);
    }

    function setNft_Contract_2(address __nft_Contract_2) public onlyOwner {
        nft2 = IERC721(__nft_Contract_2);
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