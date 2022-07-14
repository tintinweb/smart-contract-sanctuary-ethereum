// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721A.sol";
import "Ownable.sol";
import "MerkleProof.sol";

contract NFT is ERC721A, Ownable {
    using Strings for uint256;

    string public baseURI;
    uint256 public MAX_SUPPLY = 50;

    uint256 public publicSaleCost = 0.03 ether;
    uint256 public publicMintLimit_pw = 50;

    bool public public_mint_status = true;
   
    string public shortName;
    string public projectName;

    address public owner1;
    address public owner2;
    address public owner3;



    constructor(string memory _initBaseURI, string memory _projectName, string memory _symbol) ERC721A(projectName,shortName) {
    
    setBaseURI(_initBaseURI);
    projectName = _projectName;
    shortName = _symbol;

    }

    function mint(uint256 quantity) public payable  {

        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");

        if (msg.sender != owner()) {

            require(public_mint_status, "Public Mint Not Allowed");
            require(msg.value >= (publicSaleCost * quantity), "Not enough ether sent"); 
            require(balanceOf(msg.sender) + quantity <= publicMintLimit_pw, "Limit Per Wallet Reached");         
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

    function setStatus_publicmint() public onlyOwner {
        if(public_mint_status == true){

            public_mint_status = false;

        } else {

        public_mint_status = true;
      
        }

    }   
   
    function withdraw() public payable onlyOwner {

    (bool main1, ) = payable(owner1).call{value: address(this).balance/3}("");
    require(main1);

    (bool main2, ) = payable(owner2).call{value: address(this).balance/2}("");
    require(main2);

    (bool main3, ) = payable(owner3).call{value: address(this).balance}("");
    require(main3);
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

    function setOwner1(address _owner1) public onlyOwner {
        owner1 = _owner1;
    }

    function setOwner2(address _owner2) public onlyOwner {
        owner2 = _owner2;
    }

    function setOwner3(address _owner3) public onlyOwner {
        owner3 = _owner3;
    }

    function setMAX_SUPPLY(uint256 _MAX_SUPPLY) public onlyOwner {
        MAX_SUPPLY = _MAX_SUPPLY;
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