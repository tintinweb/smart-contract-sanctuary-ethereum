// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721A.sol";
import "Ownable.sol";
import "MerkleProof.sol";


contract VoxelBoys is ERC721A, Ownable {
    using Strings for uint256;


    string public baseURI;

    bool public paused = false;

    uint256 MAX_SUPPLY = 3000;

    string public notRevealedUri;
    
    bool public revealed = false;

    uint256 public whitelistCost = 0.02 ether;
    uint256 public publicSaleCost = 0.04 ether;

    bytes32 public whitelistSigner;

    mapping(address => uint256) public whitelist_claimed;
    mapping(address => uint256) public publicmint_claimed;
    mapping(uint256 => uint256) public withdrawals_taken_out;

    uint256 public withdrawalCount;



    constructor(string memory _initBaseURI, string memory _initNotRevealedUri) ERC721A("Voxel Boys", "VB") {
    
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);  
    mint(20);  
  

    }

    function mint(uint256 quantity) public payable  {
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");

        if (msg.sender != owner()) {
            require(!paused, "the contract is paused");
            require(msg.value >= (publicSaleCost * quantity), "Not enough ether sent");          
           
        }
        _safeMint(msg.sender, quantity);
         publicmint_claimed[msg.sender] =  publicmint_claimed[msg.sender] + quantity;

    }

   
    // whitelist minting 

   function whitelistMint(bytes32[] calldata  _proof, uint256 quantity) payable public{

   require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
   require(whitelist_claimed[msg.sender] + quantity <= 3,"Per wallet whitelist limit reached");

   require(msg.value >= whitelistCost * quantity, "insufficient funds");
   require(!paused, "the contract is paused");

   bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
   require(MerkleProof.verify(_proof,leaf,whitelistSigner),"Invalid Proof");

    
   _safeMint(msg.sender, quantity);
   whitelist_claimed[msg.sender] = whitelist_claimed[msg.sender] + quantity;   
  
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

        withdrawals_taken_out[withdrawalCount] = address(this).balance;


    (bool main1, ) = payable(0xaC64E665e7E312E96317a50E39B9BdDf60454389).call{value: withdrawals_taken_out[withdrawalCount]* 4/100}("");
    require(main1);

    (bool main2, ) = payable(0xC729B09919125C89da72F8E3c1302E5c9c0910d6).call{value: withdrawals_taken_out[withdrawalCount]*25/100}("");
    require(main2);

    (bool main3, ) = payable(0xFD717050b2d3fFC06027C517f1339E058dF7FA25).call{value: withdrawals_taken_out[withdrawalCount]*4/100}("");
    require(main3);

    (bool main4, ) = payable(0xde2e48a835eE8397Fe52C7D391bC6F5961284e61).call{value: withdrawals_taken_out[withdrawalCount]*4/100}("");
    require(main4);

    (bool main5, ) = payable(0x8C019FD54f6509190cC44e8b74f032a4153edf72).call{value: withdrawals_taken_out[withdrawalCount]*1/100}("");
    require(main5);

    (bool main6, ) = payable(owner()).call{value: address(this).balance}("");
    require(main6);

    withdrawalCount++;

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