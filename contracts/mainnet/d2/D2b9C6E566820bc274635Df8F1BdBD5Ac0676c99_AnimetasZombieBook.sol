pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721AOwnersExplicit.sol";


interface Animetas {
    function balanceOf(address owner) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract AnimetasZombieBook is ERC721AOwnersExplicit, Ownable, ReentrancyGuard {
    uint256 collectionSize;
    uint256 maxBatchSize;
    uint256 price;
    uint256 animetasPrice;
    bool isLocked;
    bool mintLive;
    string varBaseURI_;
    address payee;
    address animetas;

    modifier onlyUnlocked() {
        require(!isLocked, "Error: collection already locked");
        _;
    }

    constructor(uint256 collectionSize_, uint256 maxBatchSize_, uint256 price_, uint256 animetasPrice_,
        string memory baseURI_, address animetas_) ERC721A("The First Link", "TFLA") Ownable() ReentrancyGuard() {
        collectionSize = collectionSize_;
        maxBatchSize = maxBatchSize_;
        price = price_;
        animetasPrice = animetasPrice_;
        isLocked = false;
        mintLive = false;
        varBaseURI_ = baseURI_;
        payee = msg.sender;
        animetas = animetas_;
    }

    function publicSaleMint(uint256 quantity)
    external
    payable
    nonReentrant
    {
        require(mintLive, "sale has not begun yet");
        require(totalSupply() + quantity <= collectionSize, "reached max supply");
        require(quantity <= maxBatchSize, "can not mint this many");
        bool hasAnimetas = Animetas(animetas).balanceOf(msg.sender) > 0;
        require(msg.value >= (hasAnimetas ? animetasPrice : price) * quantity, "Need to send more ETH.");

        _safeMint(msg.sender, quantity);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return varBaseURI_;
    }

    function availableTokens() public view returns (uint256) {
        return collectionSize - totalSupply();
    }

    function isMintLive() public view returns (bool) {
        return mintLive;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner onlyUnlocked {
        varBaseURI_ = baseURI_;
    }

    function setCollectionSize(uint256 collectionSize_) external onlyOwner onlyUnlocked {
        collectionSize = collectionSize_;
    }

    function setBatchSize(uint256 batchSize_) external onlyOwner onlyUnlocked {
        maxBatchSize = batchSize_;
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function setAnimetasPrice(uint256 price_) external onlyOwner {
        animetasPrice = price_;
    }

    function setMintStatus(bool status) external onlyOwner {
        mintLive = status;
    }

    function lock() external onlyOwner {
        isLocked = true;
    }

    function setPayee(address payee_) external onlyOwner {
        payee = payee_;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success,) = payable(payee).call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}