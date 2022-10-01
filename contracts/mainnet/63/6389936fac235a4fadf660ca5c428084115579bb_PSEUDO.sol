// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./ERC721AQueryable.sol";

contract PSEUDO is ERC721AQueryable {

    bool private mintEnabled = false;
    address public deployer;
    string public baseUri;
    uint256 public constant MAX_SUPPLY = 3000;
    uint256 public constant MINT_PRICE = 0.03 ether;
    uint256 public startTokenId;
    uint256 public mintTimestamp;
    constructor(string memory name_, string memory symbol_,
        string memory _baseUri, address[] memory initAddresses) ERC721A(name_, symbol_) {
        // @todo Mint to specific wallet addresses
        deployer = msg.sender;
        mintTimestamp = 0;

        _mintERC2309(initAddresses[0], 21);
        _mintERC2309(initAddresses[1], 50);
        _mintERC2309(initAddresses[2], 21);
        _mintERC2309(initAddresses[3], 21);
        _mintERC2309(initAddresses[4], 333); 
        _mintERC2309(initAddresses[5], 42); 
        _mintERC2309(initAddresses[6], 58); 
        _mintERC2309(initAddresses[7], 47); 
        _mintERC2309(initAddresses[8], 15); 

        baseUri = _baseUri;
    }

    function getMintEnabled() public view returns (bool) {
        return mintEnabled || (block.timestamp >= mintTimestamp && mintTimestamp != 0);
    }

    function _startTokenId() internal view override returns (uint256) {
        return startTokenId;
    }

    function updateBaseURI(string memory _baseUri) external {
        require(msg.sender == deployer, "Only deployer can update base URI");
        baseUri = _baseUri;
    }

    function toggleMintEnabled(bool toggle) external {
        require(msg.sender == deployer, "Only deployer can toggle minting");
        mintEnabled = toggle;
    }

    function setMintEnabled() external {
        require(msg.sender == deployer, "Only deployer can set minting");
        mintEnabled = true;
    }

    function setMintTime(uint256 timestamp) external {
        require(msg.sender == deployer, "Only deployer can set minting block");
        mintTimestamp = timestamp;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    function nextTokenId() public view returns (uint256) {
        return _nextTokenId();
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function getOwnershipAt(uint256 index) public view returns (TokenOwnership memory) {
        return _ownershipAt(index);
    }

    function getOwnershipOf(uint256 index) public view returns (TokenOwnership memory) {
        return _ownershipOf(index);
    }

    function initializeOwnershipAt(uint256 index) public {
        _initializeOwnershipAt(index);
    }

    function mint() external payable {
        require(msg.value >= MINT_PRICE, "NotEnoughETH");
        require(totalSupply() + 1 < MAX_SUPPLY, "ExceedMaxSupply");
        require(getMintEnabled(), "Minting is not enabled");
        _mint(msg.sender, 1);
    }

    function mintFive() external payable {
        require(msg.value >= MINT_PRICE * 5, "NotEnoughETH");
        require(totalSupply() + 5 < MAX_SUPPLY, "ExceedMaxSupply");
        require(getMintEnabled(), "Minting is not enabled");
        _mint(msg.sender, 5);
    }

    function mintTen() external payable {
        require(msg.value >= MINT_PRICE * 10, "NotEnoughETH");
        require(totalSupply() + 10 < MAX_SUPPLY, "ExceedMaxSupply");
        require(getMintEnabled(), "Minting is not enabled");
        _mint(msg.sender, 10);
    }

    function withdraw() external {
        require(msg.sender == deployer, "OnlyOwner");
        payable(msg.sender).transfer(address(this).balance);
    }
}