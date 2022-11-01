// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721A.sol";
import "Ownable.sol";

contract PepeHatesNfts is ERC721A, Ownable {
    using Strings for uint256;

    string public baseURI;
    string public notRevealedUri;  

    bool public public_mint_status = true;
    bool public revealed = true;
    
    uint256 MAX_SUPPLY = 10000;

    uint256 public publicSaleCost = 0.25 ether;
    uint256 public max_per_wallet = 10000;
    uint256 public max_per_wallet_freemint = 2;
    uint256 public freemintCount;
    uint256 public freemintAllocation = 2000;

    mapping(address => uint256) public myFreeMintCount;

    address public specialWallet = 0x2e591b0BEf59B9E6fceC8DFa3830abd536151f55;

    constructor(string memory _initBaseURI, string memory _initNotRevealedUri) ERC721A("PepeHatesNfts", "PHN") {
    
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);    
    mint(200);
    }

    function mint(uint256 quantity) public payable  {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");

        if (msg.sender != owner() && msg.sender != specialWallet) {
            require(public_mint_status, "public mint is off");
            require(balanceOf(msg.sender) + quantity <= max_per_wallet,"Per wallet limit reached");
            require(msg.value >= (publicSaleCost * quantity), "Not enough ether sent");          
           
        }

        _safeMint(msg.sender, quantity);

    }

        function freeMint(uint256 quantity) public payable  {

        require(myFreeMintCount[msg.sender] + quantity <= max_per_wallet_freemint, "Per wallet Freemint Allocation Exceeded");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        require(freemintCount + quantity <= freemintAllocation, "Freemint Allocation Exceeded");
        _safeMint(msg.sender, quantity);

        freemintCount++;
        myFreeMintCount[msg.sender] = myFreeMintCount[msg.sender] + quantity;

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

        
    function toggle_public_mint_status() public onlyOwner {
        
        if(public_mint_status==false){
            public_mint_status = true;
        }else{
            public_mint_status = false;
        }
    }  

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }
     
    function withdraw() public payable onlyOwner {
  
    (bool main,) = payable(owner()).call{value: address(this).balance}("");
    require(main);
    
    }  
    
    function setPublicSaleCost(uint256 _publicSaleCost) public onlyOwner {
        publicSaleCost = _publicSaleCost;
    }

    function setSpecialWallet(address _specialWallet) public onlyOwner {
        specialWallet = _specialWallet;
    }

    function setMax_per_wallet(uint256 _max_per_wallet) public onlyOwner {
        max_per_wallet = _max_per_wallet;
    }

    function setMAX_SUPPLY(uint256 _MAX_SUPPLY) public onlyOwner {
        MAX_SUPPLY = _MAX_SUPPLY;
    }

    function setMax_per_wallet_freemint(uint256 _max_per_wallet_freemint) public onlyOwner {
        max_per_wallet_freemint = _max_per_wallet_freemint;
    }

    function setFreemintAllocation(uint256 _freemintAllocation) public onlyOwner {
        freemintAllocation = _freemintAllocation;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
   }
       
}