// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract CallMeCutiePie is ERC721A, Ownable, ReentrancyGuard {

    // ===== Variables =====
    string public baseTokenURI;
    uint256 public mintPrice = 0.0 ether;
    uint256 public collectionSize = 3333;
    uint256 public reservedSize = 240;
    uint256 public maxItemsPerWallet = 3;
    uint256 public maxItemsPerTx = 2;
    uint256 public maxBatchSize = 120;


    // ===== Constructor =====
    constructor() ERC721A("CallMeCutiePie", "CTP") {}

    // ===== Modifier =====
    function _onlySender() private view {
        require(msg.sender == tx.origin);
    }

    modifier onlySender {
        _onlySender();
        _;
    }

    // ===== Dev mint =====
    function devMint(uint256 amount) external onlySender onlyOwner {
        require(amount <= reservedSize, "Minting amount exceeds reserved size");
        require((totalSupply() + amount) <= collectionSize, "Sold out!");
        require(
            amount % maxBatchSize == 0,
            "Can only mint a multiple of the maxBatchSize"
        );
        uint256 numChunks = amount / maxBatchSize;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, maxBatchSize);
        }
    }

    // ===== Public mint =====
     function mint(uint256 _mintAmount) public payable nonReentrant {
        uint256 s = totalSupply();
        require(_mintAmount > 0, "Cant mint 0");
        require(_mintAmount <= maxItemsPerWallet, "Cant mint more then maxmint" );
        require(s + _mintAmount <= collectionSize, "Cant go over supply");
        _safeMint(msg.sender, _mintAmount);
        delete s;
    }


    // ===== Setter (owner only) =====
    function setReservedSize(uint256 _reservedSize) external onlyOwner {
        reservedSize = _reservedSize;
    }

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

    // ===== Withdraw to owner =====
    function withdrawAll() external onlyOwner onlySender nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to send ether");
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

    function walletOfOwner(address address_) public virtual view returns (uint256[] memory) {
        uint256 _balance = balanceOf(address_);
        uint256[] memory _tokens = new uint256[] (_balance);
        uint256 _index;
        uint256 _loopThrough = totalSupply();
        for (uint256 i = 0; i < _loopThrough; i++) {
            bool _exists = _exists(i);
            if (_exists) {
                if (ownerOf(i) == address_) { _tokens[_index] = i; _index++; }
            }
            else if (!_exists && _tokens[_balance - 1] == 0) { _loopThrough++; }
        }
        return _tokens;
    }
}