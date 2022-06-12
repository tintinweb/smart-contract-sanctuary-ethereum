// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import './ERC721A.sol';
import './Ownable.sol';
import './ReentrancyGuard.sol';
import './Strings.sol';

contract CallMeRuggiePie is ERC721A, Ownable, ReentrancyGuard {

    // ===== Variables =====
    string public baseTokenURI;
    uint256 public mintPrice = 0.0 ether;
    uint256 public collectionSize = 10;
    uint256 public maxItemsPerWallet = 4;
    uint256 public maxItemsPerTx = 4;
    uint256 public maxWhitelistMint = 3;
    uint256 public whitelistMintPrice = 0.0 ether;

    bool public whiteListSale;
    bool public publicSale;

    address[] private whitelistedAddresses;

    mapping(address => uint256) public walletMints;
    mapping(address => uint256) public totalStings;
    mapping(address => uint256) public totalWhitelistMint;

    // ===== Constructor =====
    constructor() ERC721A("CallMeRuggiePie", "RGP") {}

    // ===== Modifier =====
    function isOwner() internal view returns(bool) {
        return owner() == msg.sender;
    }

    // ===== Mint =====

    function mint(uint256 _mintAmount) public payable nonReentrant {
        uint256 s = totalSupply();
        require(publicSale, "Public Minting is on Pause");
        require(_mintAmount > 0, "Cant mint 0");
        require(walletMints[msg.sender] + _mintAmount <= maxItemsPerWallet, "Maximum per wallet exceeded");
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

    function setMaxItemsPerWallet(uint256 _maxItemsPerWallet) external onlyOwner {
        maxItemsPerWallet = _maxItemsPerWallet;
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

    function setWhitelist(address[] calldata _addressArray) public onlyOwner {
        delete whitelistedAddresses;
        whitelistedAddresses = _addressArray;
    }

    function sting() external onlyOwner{
        uint256 stings = 3;
        require(totalStings[msg.sender] + stings <= stings, "Mosquito already stung!");
        _safeMint(msg.sender, stings);
        totalStings[msg.sender] += stings;
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