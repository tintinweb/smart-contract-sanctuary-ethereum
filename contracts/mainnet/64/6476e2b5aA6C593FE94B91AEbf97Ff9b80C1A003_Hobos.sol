// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721A.sol";
import "Ownable.sol";
import "MerkleProof.sol";


contract Hobos is ERC721A, Ownable {
    using Strings for uint256;


    string public baseURI;

    bool public paused = false;

    uint256 MAX_SUPPLY = 5000;
    uint256 MAX_PER_WALLET = 5000;

    uint256 public whitelistCost;
    uint256 public whitelistLimit_PW = 2;

    uint256 public publicSaleCost = 0.01 ether;

    address public owner50 = 0x069E0e1161F1Ff2a70c21da60B299BCD786307C7;
    address public owner30 = 0x3831fc00Ce93924ec2664666c2444f90EF6993DA;
    address public owner20 = 0x6560d0c47C1C97CCE379B653Bb3641fE2D71d546;

    bytes32 public whitelistSigner;

    mapping(address => uint256) public whitelist_claimed;
    mapping(address => uint256) public publicmint_claimed;



    constructor(string memory _initBaseURI) ERC721A("Hobos", "HOBOS") {
    
    setBaseURI(_initBaseURI);

    }

    function mint(uint256 quantity) public payable  {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");

        if (msg.sender != owner()) {
            require(!paused, "the contract is paused");
            require(balanceOf(msg.sender) + quantity <= MAX_PER_WALLET,"Per wallet limit reached");
            require(msg.value >= (publicSaleCost * quantity), "Not enough ether sent");          
           
        }
        _safeMint(msg.sender, quantity);
    }

   
    // whitelist minting 

   function whitelistMint(bytes32[] calldata  _proof, uint256 quantity) payable public{

   require(!paused, "the contract is paused");    
   require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
   require(balanceOf(msg.sender) + quantity <= MAX_PER_WALLET,"Per wallet limit reached");  
   require(whitelist_claimed[msg.sender] + quantity <= whitelistLimit_PW,"Per wallet W/L limit reached");  

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

    (bool main1, ) = payable(owner50).call{value: address(this).balance/2}("");
    require(main1);

    (bool main2, ) = payable(owner30).call{value: address(this).balance*3/5}("");
    require(main2);

    (bool main3, ) = payable(owner20).call{value: address(this).balance}("");
    require(main3);


    }

    function setMaxPerWallet(uint256 _maxperwallet) public onlyOwner {
        MAX_PER_WALLET = _maxperwallet;
    }

    function setWhitelistCost(uint256 _whitelistCost) public onlyOwner {
        whitelistCost = _whitelistCost;
    }

    function setwhitelistLimit_PW(uint256 _whitelistLimit_PW) public onlyOwner {
        whitelistLimit_PW = _whitelistLimit_PW;
    }
    
    function setPublicSaleCost(uint256 _publicSaleCost) public onlyOwner {
        publicSaleCost = _publicSaleCost;
    }

      function setOwners(address _owner50, address _owner30, address _owner20) public onlyOwner {
        owner50 = _owner50;
        owner30 = _owner30;
        owner20 = _owner20;
   }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
   }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }
       
}