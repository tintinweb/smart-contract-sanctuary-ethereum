// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721A.sol";
import "Ownable.sol";
import "MerkleProof.sol";

contract NFT is ERC721A, Ownable {
    using Strings for uint256;

    string public baseURI;

    string public notRevealedUri;

    uint256 public onlyLeft;

    uint256 public MAX_SUPPLY = 8634;

    bool public revealed = false;

    uint256 public whitelistCost1 = 0.0045 ether; 
    uint256 public whitelistCost2 = 0.0090 ether; 

    uint256 public publicSaleCost = 0.0135 ether; 

    uint256 public publicMintLimit_pw = 30;
    uint256 public whitelistLimit_pw1 = 2;
    uint256 public whitelistLimit_pw2 = 2;

    bytes32 public whitelistSigner;

    mapping(address => uint256) public whitelist1_claimed;
    mapping(address => uint256) public whitelist2_claimed;
    mapping(address => uint256) public publicmint_claimed;

    bool public whitelist_status = true;
    bool public public_mint_status = true;

    constructor(bytes32 _initWLsigner, string memory _initBaseURI, string memory _initNotRevealedUri) ERC721A("NFT", "NFT") {
    
    setWhitelistSigner(_initWLsigner);
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

   
    // whitelist minting 

    function whitelistMint(bytes32[] calldata  _proof, uint256 quantity) payable public{

        require(whitelist_status, "Whitelist Mint Not Allowed");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_proof,leaf,whitelistSigner),"Invalid Proof");  
        require(totalSupply() < 2634, "Presale Sessions are over");  

        if(totalSupply() >= 0 && totalSupply() < 634){
               onlyLeft = 634 - totalSupply();
               require(onlyLeft >= quantity); 
               require(whitelist1_claimed[msg.sender] + quantity <= whitelistLimit_pw1);
               require(quantity * whitelistCost1 <= msg.value);
               _safeMint(msg.sender, quantity);

                if(isFreeMint(quantity)){
                (bool free5050_w1, ) = payable(msg.sender).call{value: whitelistCost1 * quantity}("");
                require(free5050_w1);
                }

               whitelist1_claimed[msg.sender] =  whitelist1_claimed[msg.sender] + quantity;
        }

        if(totalSupply() >= 634 && totalSupply() < 2634){
               onlyLeft = 2634 - totalSupply();
               require(onlyLeft >= quantity); 
               require(whitelist2_claimed[msg.sender] + quantity <= whitelistLimit_pw2);
               require(quantity * whitelistCost2 <= msg.value);
               _safeMint(msg.sender, quantity);

        if(isFreeMint(quantity)){
                (bool free5050_w2, ) = payable(msg.sender).call{value: whitelistCost2 * quantity}("");
                require(free5050_w2);
        }

            whitelist2_claimed[msg.sender] =  whitelist2_claimed[msg.sender] + quantity; 
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

     function setStatus_whitelist() public onlyOwner {
        if(whitelist_status == true){

            whitelist_status = false;
           

        } else {

        whitelist_status = true;

         }

    }      
    
  
    function setWhitelistSigner(bytes32 newWhitelistSigner) public onlyOwner {
        whitelistSigner = newWhitelistSigner;
    }

   
    function withdraw() public payable onlyOwner {
    (bool main, ) = payable(owner()).call{value: address(this).balance}("");
    require(main);
    }
    

    function setWhitelistCost1(uint256 _whitelistCost1) public onlyOwner {
        whitelistCost1 = _whitelistCost1;
    }

    function setWhitelistCost2(uint256 _whitelistCost2) public onlyOwner {
        whitelistCost2 = _whitelistCost2;
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

    function setwhitelistLimit_pw1(uint256 _whitelistLimit_pw1) public onlyOwner {
        whitelistLimit_pw1 = _whitelistLimit_pw1;
    }

     function setwhitelistLimit_pw2(uint256 _whitelistLimit_pw2) public onlyOwner {
        whitelistLimit_pw2 = _whitelistLimit_pw2;
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