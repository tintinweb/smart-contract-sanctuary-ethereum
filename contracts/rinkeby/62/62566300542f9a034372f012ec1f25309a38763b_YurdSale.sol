/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Strings.sol";
import "./Shareholders.sol";
import "./ERC721A.sol";




contract YurdSale is ERC721A, Shareholders {
    using Strings for uint;
    IERC721A public hoboTown = ERC721A(0x4e3706AA5853C92b91f08711E30e0993ead6DEC5); //mainnet address 0x6e0418050387C6C3d4Cd206d8b89788BBd432525
    string public _baseTokenURI;
    uint public maxPerMint = 5;
    uint public maxPerWallet = 25;
    uint public cost = .025 ether;
    uint public maxSupply = 2500;
    bool public paused = false;
    bool public revealed = false;
    bool public freeClaimPeriod = true;


    mapping(address => uint) public addressMintedBalance;
    mapping(address => bool) public freeMintClaimed;

  constructor(
    ) ERC721A("Yurd Sale", "YS")payable{
        _mint(msg.sender, 50);
    }

    
    modifier mintCompliance(uint256 quantity) {
        uint howManyHobos = hoboTown.balanceOf(msg.sender);
        require(paused == false, "Contract is paused");
        require(_totalMinted() + quantity <= maxSupply, "Collection is capped at 2,500");
        require(tx.origin == msg.sender, "No contracts!");
        require(quantity <= maxPerMint, "You can't mint this many at once.");
        require(addressMintedBalance[msg.sender] + quantity <= maxPerWallet, "You minted as many as you can already.");
        if (howManyHobos < 5) {
            require(msg.value >= cost * quantity, "Insufficient Funds.");
        } else if (howManyHobos > 4 && freeMintClaimed[msg.sender] == true) {
            require(msg.value >= cost * quantity, "Insufficient Funds.");
        } else {
            require(freeMintClaimed[msg.sender] == false, "You already claimed your free mint.");
            require(freeClaimPeriod == true, "Free claim period is over.");
            require(msg.value >= (cost * (quantity - 1)), "Insufficient Funds.");
            freeMintClaimed[msg.sender] = true;
        }
        _;
    }



  function mint(uint256 quantity) mintCompliance(quantity) external payable
    {
        _mint(msg.sender, quantity);
        addressMintedBalance[msg.sender] += quantity;
    }

    function ownerMint(uint256 quantity) external onlyOwner
    {
        require(_totalMinted() + quantity <= maxSupply, "Collection is capped at 9,999");
        _mint(msg.sender, quantity);
    }


    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }    

    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
        string memory currentBaseURI = _baseURI();
        if(revealed == true) {
            return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
            : "";
        } else {
            return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI))
            : "";
        } 
    }

    
    function setPause(bool _state) external onlyOwner {
        paused = _state;
    }


    function reveal(bool _state, string memory baseURI) external onlyOwner {
        revealed = _state;
        _baseTokenURI = baseURI;
    }

    function setFreeClaimPeriod(bool _state) external onlyOwner {
        freeClaimPeriod = _state;
    }

}