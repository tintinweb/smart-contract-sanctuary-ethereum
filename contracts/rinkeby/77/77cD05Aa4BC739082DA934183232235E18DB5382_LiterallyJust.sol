// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract LiterallyJust {
    uint256 public collectionSize;
    uint256 public maxFree;
    uint256 public maxBatchSize;
    uint256 public maxPerAddress;
    uint256 public amountForDevs;
    uint256 public mintPrice;

    string public contractMetadataURI;
    string public baseURI;

    bool public publicSaleActive = false;

    mapping(address => uint256) private _mintedFree;
    uint256 private _mintedByDevs = 0;

    constructor(
        uint256 _collectionSize,
        uint256 _maxFree,
        uint256 _maxBatchSize,
        uint256 _maxPerAddress,
        uint256 _amountForDevs,
        uint256 _mintPrice,
        string memory _contractMetadataURI,
        string memory _newBaseURI
    ) {
        collectionSize = _collectionSize;
        maxFree = _maxFree;
        maxBatchSize = _maxBatchSize;
        maxPerAddress = _maxPerAddress;
        amountForDevs = _amountForDevs;
        mintPrice = _mintPrice;
        contractMetadataURI = _contractMetadataURI;
        baseURI = _newBaseURI;
    }

    // PUBLIC READ

    function contractURI() public view returns (string memory) {
        return contractMetadataURI;
    }

    function numberMinted(address _owner) public view returns (uint256) {
        return 0;
    }

    function numberMintedFree(address _owner) public view returns (uint256) {
        return 0;
    }

    // PUBLIC WRITE

    function mint(uint256 _amount) external payable mintAllowed(_amount) {
        
    }

    function setPublicSaleActive(bool _publicSaleActive) external {
        publicSaleActive = _publicSaleActive;
    }

    function withdraw() external {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // MODIFIERS

    modifier mintAllowed(uint256 _amount) {
        require(publicSaleActive, "Public sale is not active");
        require(tx.origin == msg.sender, "Caller is a contract");
        // require(totalSupply() + _amount <= collectionSize - amountForDevs, "Quantity exceeds remaining mints");
        _;
    }

    // INTERNAL

    // function _startTokenId() internal view virtual override returns (uint256) {
    //     return 1;
    // }

    // function _baseURI() internal view override returns (string memory) {
    //     return baseURI;
    // }
}