// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./IERC721A.sol";
import "./Ownable.sol";

//Fuck it, let's go bowling.

contract DegenPins is IERC721A, Ownable, ERC721A {
    uint256 public maxSupply = 10000; 
    uint256 public paidPrice = 0.0069420 ether; 
    uint256 public constant maxPerWallet = 25;
    uint256 public constant maxPerTx = 10;
    string public baseURI;
    bool public saleStarted;

    IERC721A public pivotalPinsToken;
    IERC721A public kbaToken;
    IERC721A public mirrorToken;

    // Some beneficiary degens.
    address constant public pivotalPinsAddress = 0xe209829e376D56F49bD9aFCf1704b08E790c6318;
    address constant public kbaAddress = 0x45359616610A584CC39AecdcBb2A457976780023;
    address constant public mirrorAddress = 0xb08A61d96108136439180Ad3F3e340A24e448f6B;

    // For checking how many you grabbed.
    mapping(address => uint) internal hasMinted;

    constructor() ERC721A('Degen Pins', 'DegenPins') {
        pivotalPinsToken = IERC721A(pivotalPinsAddress);
        kbaToken = IERC721A(kbaAddress);
        mirrorToken = IERC721A(mirrorAddress);
        _safeMint(msg.sender, 50);
    }

    modifier whenSaleStarted() {
        require(saleStarted, "Public sale has not started");
        _;
    }

    //Got any of these?

    function ownsPivotalPin(address tokenholder) public view returns (bool) {
        if(pivotalPinsToken.balanceOf(tokenholder) > 0) return true;
        return false;
    }
    function ownsKBA(address tokenholder) public view returns (bool) {
        if(kbaToken.balanceOf(tokenholder) > 0) return true;
        return false;
    }
    function ownsMirror(address tokenholder) public view returns (bool) {
        if(mirrorToken.balanceOf(tokenholder) > 0) return true;
        return false;
    }

    //One free, unless...
    function mintFree(uint256 _mintAmount) public payable whenSaleStarted {
        uint freeAllowance = 1;
        if(ownsPivotalPin(msg.sender)) {
            freeAllowance = 10;
        } else if(ownsKBA(msg.sender)) {
            freeAllowance = 3;
        } else if(ownsMirror(msg.sender)) {
            freeAllowance = 3;
        }       
        require(tx.origin == _msgSender(), "Only EOA");
        require(_mintAmount > 0, "Must mint at least one Degen Pin");
        require(totalSupply() + _mintAmount <= maxSupply, "Exceeds max supply fellow degen.");
        require(_mintAmount <= freeAllowance, "You can only have so many free pins, degen.");
        require(hasMinted[msg.sender] + _mintAmount <= freeAllowance, "You already grabbed your free pins, bud.");
        hasMinted[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    //0.0069420 if you're a certain type of degen.
    function mint(uint256 amountOfPins) external payable whenSaleStarted {
        require(tx.origin == _msgSender(), "Only EOA");
        require(totalSupply() + amountOfPins <= maxSupply, "Exceeds max supply fellow degen.");
        require(hasMinted[msg.sender] + amountOfPins <= maxPerWallet, "Purchase exceeds max allowed per address");
        require(amountOfPins > 0, "Must mint at least one Degen Pin");
        require(amountOfPins <= maxPerTx, "Amount over max per transaction.");
        require(paidPrice * amountOfPins <= msg.value, "ETH amount is incorrect");
        hasMinted[msg.sender] += amountOfPins;
        _safeMint(msg.sender, amountOfPins);
    }

    function claimReserved(address recipient, uint256 amountOfPins) external onlyOwner {
        require(recipient != address(0), "Cannot add null address");
        _safeMint(msg.sender, amountOfPins);
    }

    function toggleSaleStarted() external onlyOwner {
        saleStarted = !saleStarted;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }
    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}