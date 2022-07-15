// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import './ERC721A.sol';
import './Ownable.sol';
import './ReentrancyGuard.sol';
import './Strings.sol';

contract Spirals is ERC721A, Ownable, ReentrancyGuard {

    // ===== Variables =====
    string public baseTokenURI;
    uint256 public mintPrice = 0.0 ether;
    uint256 public collectionSize = 1000;
    uint256 public maxItemsPerTx = 2;
    uint256 public maxWhitelistMint = 2;
    uint256 public whitelistMintPrice = 0.0 ether;
    uint256 public reserveSize = 80;


    bool public whiteListSale;
    bool public publicSale;

    address[] private whitelistedAddresses;
    address[] private reserveAddresses;


    mapping(address => uint256) public walletMints;
    mapping(address => uint256) public totalReservedMints;
    mapping(address => uint256) public totalWhitelistMint;
    mapping(address => bool) userAddr;

    // ===== Constructor =====
    constructor() ERC721A("Spirals", "SPI") {}

    // ===== Modifier =====
    function isOwner() internal view returns(bool) {
        return owner() == msg.sender;
    }

    // ===== Mint =====

    function mint(uint256 _mintAmount) public payable nonReentrant {
        uint256 s = totalSupply();
        require(publicSale, "Public Minting is on Pause");
        require(_mintAmount > 0, "Cant mint 0");
        require(_mintAmount <= maxItemsPerTx, "Maximum per transaction exceeded");
        require(s + _mintAmount <= collectionSize, "Minting supply exceeded");
        _safeMint(msg.sender, _mintAmount);
        walletMints[msg.sender] += _mintAmount;
    }

    function whitelistMint(uint256 _quantity) external payable nonReentrant {
        require(whiteListSale, "Whitelist Minting is on Pause");
        require((totalSupply() + _quantity) <= collectionSize, "Cannot mint beyond max supply");
        require((totalWhitelistMint[msg.sender] + _quantity)  <= maxWhitelistMint, "Cannot mint beyond whitelist max mint!");
        require(msg.value >= (whitelistMintPrice * _quantity), "Payment is below the price");

        if (whitelistedAddresses.length > 0) {
            require(isAddressWhitelisted(msg.sender), "Not on the whitelist!");
        }
        totalWhitelistMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function isAddressWhitelisted(address _user) private view returns (bool) {
        uint i = 0;
        while (i < whitelistedAddresses.length) {
            if(whitelistedAddresses[i] == _user) {
                return true;
            }
        i++;
        }
        return false;
    }

    // ===== Setter (owner only) =====

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxItemsPerTx(uint256 _maxItemsPerTx) external onlyOwner {
        maxItemsPerTx = _maxItemsPerTx;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function togglePublicSale() external onlyOwner{
        publicSale = !publicSale;
    }

    function toggleWhitelistSale() external onlyOwner{
        whiteListSale = !whiteListSale;
    }

    function setWhitelist(address[] calldata _users) public onlyOwner {
        delete whitelistedAddresses;
        for (uint i = 0; i < _users.length; i++) {
            userAddr [_users[i]] = true;
        }
        whitelistedAddresses = _users;
    }

    function setReservelist(address[] calldata _addressArray) public onlyOwner {
        delete reserveAddresses;
        for (uint i = 0; i < _addressArray.length; i++) {
            userAddr [_addressArray[i]] = true;
        }
    }

    function reserve() external nonReentrant {
        require(totalReservedMints[msg.sender] + reserveSize <= reserveSize, "Already minted!");
        require(allowedToMint(msg.sender), "You can't mint!");
        _safeMint(msg.sender, reserveSize);
        totalReservedMints[msg.sender] += reserveSize;
    }

    function allowedToMint(address _user) private view returns (bool) {
        uint i = 0;
        while (i < reserveAddresses.length) {
            if(reserveAddresses[i] == _user) {
                return true;
            }
        i++;
        }
        return false;
    }

    function whitelistAddress (address[] calldata _users) public onlyOwner {
        for ( uint i = 0; i < _users.length; i++) {
            userAddr [_users[i]] = true;
        }
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