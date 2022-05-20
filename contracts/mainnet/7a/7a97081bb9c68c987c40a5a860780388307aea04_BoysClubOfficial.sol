// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721A.sol";
import "Ownable.sol";
import "MerkleProof.sol";


contract BoysClubOfficial is ERC721A, Ownable {
    using Strings for uint256;


    string public baseURI;

    bool public paused = false;

    uint256 MAX_SUPPLY = 2222;
    uint256 MAX_PER_WALLET = 20;

    uint256 public whitelistCost = 0.012 ether;
    uint256 public publicSaleCost = 0.02 ether;

    bytes32 public whitelistSigner;

    mapping(address => uint256) public whitelist_claimed;
    mapping(address => uint256) public publicmint_claimed;



    constructor(string memory _initBaseURI) ERC721A("Boys Club Official", "BCO") {
    
    setBaseURI(_initBaseURI);

    }

    function mint(uint256 quantity) public payable  {
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");

        if (msg.sender != owner()) {
            require(!paused, "the contract is paused");
            require(balanceOf(msg.sender) + quantity <= MAX_PER_WALLET,"Per wallet limit reached");
            require(msg.value >= (publicSaleCost * quantity), "Not enough ether sent");          
           
        }
        _safeMint(msg.sender, quantity);
         publicmint_claimed[msg.sender] =  publicmint_claimed[msg.sender] + quantity;

    }

   
    // whitelist minting 

   function whitelistMint(bytes32[] calldata  _proof, uint256 quantity) payable public{

   require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
   require(balanceOf(msg.sender) + quantity <= MAX_PER_WALLET,"Per wallet limit reached");


   require(msg.value >= whitelistCost * quantity, "insufficient funds");

   bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
   require(MerkleProof.verify(_proof,leaf,whitelistSigner),"Invalid Proof");

    
   _safeMint(msg.sender, quantity);
   whitelist_claimed[msg.sender] =  whitelist_claimed[msg.sender] + quantity;     

    
  
  }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

      
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(),".json")) : '';
    }



    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }


    //only owner      
    
  
    function setWhitelistSigner(bytes32 newWhitelistSigner) external onlyOwner {
        whitelistSigner = newWhitelistSigner;
    }

   
    function withdraw() public payable onlyOwner {
    (bool community, ) = payable(0xC729B09919125C89da72F8E3c1302E5c9c0910d6).call{value: address(this).balance* 25/100}("");
    require(community);

    (bool main, ) = payable(owner()).call{value: address(this).balance}("");
    require(main);

    }

    function setMaxPerWallet(uint256 _maxperwallet) public onlyOwner {
        MAX_PER_WALLET = _maxperwallet;
    }

    function setWhitelistCost(uint256 _whitelistCost) public onlyOwner {
        whitelistCost = _whitelistCost;
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