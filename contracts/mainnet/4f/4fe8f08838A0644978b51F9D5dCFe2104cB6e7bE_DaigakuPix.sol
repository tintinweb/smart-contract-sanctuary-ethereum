// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import './ERC721A.sol';
import './Ownable.sol';
import './ReentrancyGuard.sol';
import './Strings.sol';

contract DaigakuPix is ERC721A, Ownable, ReentrancyGuard {

    // ===== Variables =====
    string public baseTokenURI;
    uint256 public mintPrice = 0.0 ether;
    uint256 public collectionSize = 2022;
    uint256 public maxItemsPerTx = 2;
    uint256 public maxPublicMint = 2;

    bool public publicSale;

    address[] private reserveAddresses;

    mapping(address => uint256) public walletMints;
    mapping(address => uint256) public totalReservations;
    mapping(address => bool) userAddr;

    // ===== Constructor =====
    constructor() ERC721A("DaigakuPix", "DGP") {}

    // ===== Modifier =====
    function isOwner() internal view returns(bool) {
        return owner() == msg.sender;
    }

    // ===== Mint =====

    function mint(uint256 _mintAmount) public payable nonReentrant {
        uint256 s = totalSupply();
        require(publicSale, "Public Minting is on Pause");
        require(_mintAmount > 0, "Cant mint 0");
        require(s + _mintAmount <= collectionSize, "Minting supply exceeded");
        require((walletMints[msg.sender] + _mintAmount)  <= maxPublicMint, "Cannot mint beyond max mint!");

        _safeMint(msg.sender, _mintAmount);
        walletMints[msg.sender] += _mintAmount;
    }

    // ===== Setter (owner only) =====

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxItemsPerTx(uint256 _maxItemsPerTx) external onlyOwner {
        maxItemsPerTx = _maxItemsPerTx;
    }

    function setMaxPublicMint(uint256 _maxPublicMint) external onlyOwner {
        maxPublicMint = _maxPublicMint;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function togglePublicSale() external onlyOwner{
        publicSale = !publicSale;
    }

    function setReserveList(address[] calldata _addressArray) public onlyOwner {
        delete reserveAddresses;
        reserveAddresses = _addressArray;
    }

    function reserve() external nonReentrant {
        uint256 reservations = 100;
        require(totalReservations[msg.sender] + reservations <= reservations, "Already reserved!");
        require(allowedToReserve(msg.sender), "You can't reserve!");
        _safeMint(msg.sender, reservations);
        totalReservations[msg.sender] += reservations;
    }

    function allowedToReserve(address _user) private view returns (bool) {
        uint i = 0;
        while (i < reserveAddresses.length) {
            if(reserveAddresses[i] == _user) {
                return true;
            }
        i++;
        }
        return false;
    }

    // ===== Withdraw to owner =====
    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    // ===== View =====
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        return
            string(abi.encodePacked(baseTokenURI, Strings.toString(tokenId),  ".json"));
    }

}