pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract Elf is ERC721Enumerable, Ownable, ReentrancyGuard {

    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 1000;

    uint256 public SALE_PRICE = 0.08 ether;

    uint256 public saleStartTime;

    string private _baseURIExtended = "";

    constructor() ERC721("Elf Games", "ELF") { }

    function mint(uint256 quantity) external payable nonReentrant {
        require(block.timestamp > saleStartTime, "Mint hasn't started");
        require(quantity > 0, "Number of tokens can not be less than or equal to 0");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Purchase would exceed max supply of tokens");
        uint256 amount = SALE_PRICE * quantity;
        require(msg.value >= amount,"Value insufficient");
        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = totalSupply() + 1;
            _safeMint(msg.sender, tokenId);
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
        string memory base = _baseURI();
        string memory url  = string(abi.encodePacked(base, tokenId.toString()));
        return string(abi.encodePacked(url,".json"));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIExtended = baseURI_;
    }

    function setSalePrice(uint256 price) external onlyOwner {
        SALE_PRICE = price;
    }

    function setSaleStartTime(uint256 startTime) external onlyOwner {
        saleStartTime = startTime;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}