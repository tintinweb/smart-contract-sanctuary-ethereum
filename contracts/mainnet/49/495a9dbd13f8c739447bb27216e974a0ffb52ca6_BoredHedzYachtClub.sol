// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract BoredHedzYachtClub is ERC721A, Ownable {
    uint256 public price;
    uint256 public maxMintPerTx;
    uint256 public immutable collectionSize;
    string public baseUri;
    bool public open = false;
    uint256 public maxFree;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _price,
        uint256 _maxMintPerTx,
        uint256 _collectionSize,
        uint256 _maxFree
    ) ERC721A(_name, _symbol) {
        price = _price;
        maxMintPerTx = _maxMintPerTx;
        collectionSize = _collectionSize;
        maxFree = _maxFree;
    }

    // Events
    event PriceChanged(uint256 newPrice);
    event MaxMintPerTxChanged(uint256 newMaxMintPerTx);

    modifier mintCompliance(uint256 _quantity) {
        unchecked {
            require(tx.origin == msg.sender, "Sender is smart contract");
            require(open, "Minting has not started yet");
            require(_quantity <= maxMintPerTx, "Quantity is too large");
            require(_quantity != 0, "Must mint at least 1 token");
        }
        _;
    }

    function getRequiredValue(uint256 _quantity) public view returns (uint256) {
        uint256 requiredValue = _quantity * price;
        uint256 userMinted = _numberMinted(msg.sender);

        if (userMinted == 0) {
            requiredValue = _quantity <= maxFree
                ? 0
                : requiredValue - (price * maxFree);
        }

        return requiredValue;
    }

    // Minting
    function mint(uint256 _quantity)
        external
        payable
        mintCompliance(_quantity)
    {
        uint256 requiredValue = getRequiredValue(_quantity);
        require(msg.value >= requiredValue, "Sent Ether is too low");
        if (_totalMinted() + _quantity <= collectionSize) {
            _safeMint(msg.sender, _quantity);
        }
    }

    // TokenURIs
    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    // Utils
    function setPrice(uint256 _newPrice) external onlyOwner {
        require(price != _newPrice, "Already set to this value");
        price = _newPrice;

        emit PriceChanged(_newPrice);
    }

    function setMaxMintPerTx(uint256 _newMaxMintPerTx) external onlyOwner {
        require(maxMintPerTx != _newMaxMintPerTx, "Already set to this value");
        maxMintPerTx = _newMaxMintPerTx;

        emit MaxMintPerTxChanged(_newMaxMintPerTx);
    }

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseUri = _newBaseURI;
    }

    function setOpen(bool _value) external onlyOwner {
        open = _value;
    }

    function setMaxFree(uint256 _newMaxFree) external onlyOwner {
        require(maxFree != _newMaxFree, "Already set to this value");
        maxFree = _newMaxFree;
    }

    function allowlistMint(uint256 _quantity) external onlyOwner {
        require(
            _totalMinted() + _quantity <= collectionSize,
            "Collection is full"
        );
        _safeMint(msg.sender, _quantity);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    // ERC721A overrides
    // ERC721A starts counting tokenIds from 0, this contract starts from 1
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    // ERC721A has no file extensions for its tokenURIs
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json"))
                : "";
    }
}