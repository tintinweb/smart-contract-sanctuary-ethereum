// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./Strings.sol";

contract MOUSAI is ERC721A, Ownable, Pausable, ReentrancyGuard {
    using Strings for uint256;

    struct SalePlan {
        uint256 price;
        uint256 amount;
        uint256 mintedAmount;
    }

    uint256 private maxSupply = 10000;
    uint8 private maxAmount = 10;

    string private metadataUri;

    bool private isMinting = false;
    bool private isRevealed = false;
    bool private isPublic = false;

    mapping(address => mapping(uint8 => uint8)) public allowedAmounts;
    mapping(address => uint8) public publicMintedAmounts;

    uint8 private saleCount = 0;
    SalePlan public salePlan;

    constructor(
    ) ERC721A("MOUSAI", "MOUSAI") {
        salePlan.price = 50000000000000000; //0.05 ETH
        salePlan.amount = 500;
        salePlan.mintedAmount = 0;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(metadataUri, Strings.toString(_tokenId)));
    }

    function mint(uint8 amount) external payable nonReentrant whenNotPaused isNotContract {

        //phase is on check
        require(isMinting, "Minting is off");

        //value == price check
        uint256 _price = salePlan.price * amount;
        require(msg.value == _price, "Invalid ETH balance");

        //allowed amount check
        require(amount <= allowedAmounts[msg.sender][saleCount], "No allowed amount");

        //amount check
        require(salePlan.mintedAmount + amount <= salePlan.amount, "Exceeding sale amount");
        require(_totalMinted() + amount <= maxSupply, "Exceeding max supply amount");

        allowedAmounts[msg.sender][saleCount] -= amount;
        salePlan.mintedAmount += amount;

        if(salePlan.mintedAmount == salePlan.amount) isMinting = false;

        _mint(msg.sender, amount);
        emit Minted(msg.sender, amount);
    }
    //team mint amount ; no mint phase check, only total amount check

    function mintForTeamReserve(uint8 amount) external onlyOwner {
        require(_totalMinted() + amount <= maxSupply, "Exceeding max supply amount");
        _mint(msg.sender, amount);
        emit Minted(msg.sender, amount);
    }

    function publicMint(uint8 amount) external payable nonReentrant whenNotPaused isNotContract {
        require(isMinting, "Minting is off");
        require(isPublic, "Minting is not public");

        uint256 _price = salePlan.price * amount;
        require(msg.value == _price, "Invalid ETH balance");

        require(amount <= maxAmount - publicMintedAmounts[msg.sender], "No public allowed amount");

        require(salePlan.mintedAmount + amount <= salePlan.amount, "Exceeding sale amount");
        require(_totalMinted() + amount <= maxSupply, "Exceeding max supply amount"); 

        publicMintedAmounts[msg.sender] += amount;
        salePlan.mintedAmount += amount;

        if(salePlan.mintedAmount == salePlan.amount) isMinting = false;

        _mint(msg.sender, amount);
        emit Minted(msg.sender, amount);
    }

    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
        emit Burn(tokenId);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) {
            revert("Ether transfer failed");
        }
    }

    function setMetadataUri(string calldata _metadataUri) external onlyOwner {
        metadataUri = _metadataUri;
    }

    function setIsReveal(bool _isReveal) external onlyOwner {
        isRevealed = _isReveal;
    }

    function setIsPublic(bool _isPublic) external onlyOwner {
        isPublic = _isPublic;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        require(_totalMinted() <= _maxSupply, "Less than total minted amount");
        maxSupply = _maxSupply;
    }

    function setMaxAmount(uint8 _maxAmount) external onlyOwner {
        maxAmount = _maxAmount;
    }

    function setMintRound(uint256 price, uint8 amount) external onlyOwner {
        require(!isMinting, "Minting is now live");
        require(_totalMinted() + amount <= maxSupply, "Exceeding max supply");
        salePlan.price = price;
        salePlan.amount = amount;
        salePlan.mintedAmount = 0;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function mintStop() external onlyOwner {
        require(isMinting, "Minting is off");
        isMinting = false;
    }

    function mintStart() external onlyOwner {
        require(!isMinting, "Minting is on");
        isMinting = true;
    }

    function setAllowedAmounts(uint8 _saleCount, address[] calldata _addresses, uint8[] calldata _amounts) external onlyOwner {
        require(_addresses.length == _amounts.length, "Length is different");

        saleCount = _saleCount;

        for(uint8 i = 0; i < _addresses.length; i++) {
            allowedAmounts[_addresses[i]][saleCount] = _amounts[i];
        }
    }
    
    function getAllowedAmounts(address _address) public view returns (uint8) {
        require(_address != address(0), "address can't be 0");
        return allowedAmounts[_address][saleCount];
    }

    function mintedAmount() public view returns (uint256) {
        return _totalMinted();
    }

    function isSoldOut() public view returns (bool) {
        return _totalMinted() == maxSupply;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A) returns (bool) {
        return ERC721A.supportsInterface(interfaceId);
    }

    modifier isNotContract() {
        require(msg.sender == tx.origin, "Sender is not EOA");
        _;
    }

    event Minted(address indexed receiver, uint256 quantity);
    event Burn(uint256 tokenId);

}