// SPDX-License-Identifier: MIT
// Author: https://twitter.com/cosmicmetanft
// ERC-721 Smart Contract for the Cosmic Meta War Chicks NFT Collection - https://cosmicmeta.io
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Ownable.sol";

contract CosmicMetaWarChicks is ERC721, ERC721Enumerable, Pausable, Ownable {
    using Strings for uint256;

    string public baseTokenURI;
    string public contractURI;
    uint256 public constant MAX_TOKENS = 2222; // 2222 War Chicks
    uint256 public maxMint = 10; // Max 10 War Chicks per transaction
    uint256 public price = 0.025 ether; // Each War Chicks cost 0.025 ETH to mint
    uint256 public preMintPrice = 0.01 ether; // Lower price for pre-sale
    bool public mainSale = false; // Main Sale is disabled by default
    mapping(address => bool) public presaleAccessList; // Whitelist for pre-sale

    constructor(string memory _baseTokenURI, string memory _contractURI) ERC721("Cosmic Meta War Chicks", "CMWC") {
        setBaseURI(_baseTokenURI);
        setContractURI(_contractURI);

        // The first 50 War Chicks are minted for the team, giveaways and our community
        mint(msg.sender, 50);
    }

    function preMint(address _to, uint256 _quantity) public payable {
        uint256 supply = totalSupply();

        require(hasPresaleAccess(_to), "You are not whitelisted for the War Chicks pre-sale!");
        require(!mainSale, "You can't pre-mint War Chicks at the moment!");
        require(_quantity > 0 && _quantity <= maxMint, "You can only mint 1 to 10 War Chicks!");
        require(msg.value >= preMintPrice * _quantity, "Ether sent is not correct!");
        require(supply + _quantity <= MAX_TOKENS, "Exceeds maximum supply!");

        for (uint256 i = 1; i <= _quantity; i++) {
          _safeMint(_to, supply + i);
        }
    }

    function mint(address _to, uint256 _quantity) public payable {
        uint256 supply = totalSupply();

        if (msg.sender != owner()) {
            require(mainSale, "The War Chicks main sale is not open!");
            require(_quantity > 0 && _quantity <= maxMint, "You can only mint 1 to 20 War Chicks!");
            require(msg.value >= price * _quantity, "Ether sent is not correct!");
        }

        require(supply + _quantity <= MAX_TOKENS, "Exceeds maximum supply!");

        for (uint256 i = 1; i <= _quantity; i++) {
          _safeMint(_to, supply + i);
        }
    }

    function gift(address[] calldata receivers) external onlyOwner {
        uint256 supply = totalSupply();

        require(supply + receivers.length <= MAX_TOKENS, "Exceeds maximum supply!");

        for (uint256 i = 1; i <= receivers.length; i++) {
            _safeMint(receivers[i-1], supply + i);
        }
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);

        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function setPresaleAccessList(address[] memory _addressList) public onlyOwner {
        for (uint256 i; i < _addressList.length; i++) {
            presaleAccessList[_addressList[i]] = true;
        }
    }

    function hasPresaleAccess(address wallet) public view returns (bool) {
        return presaleAccessList[wallet];
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    function setPrice(uint256 _price) public onlyOwner() {
        price = _price;
    }

    function setPreMintPrice(uint256 _price) public onlyOwner() {
        preMintPrice = _price;
    }

    function setMaxMint(uint256 _maxMint) public onlyOwner() {
        maxMint = _maxMint;
    }

    function updateMainSaleStatus(bool _mainSale) public onlyOwner {
        mainSale = _mainSale;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function start() public onlyOwner {
        _unpause();
    }

    function withdraw(uint256 _amount) public payable onlyOwner {
        require(payable(msg.sender).send(_amount));
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
}