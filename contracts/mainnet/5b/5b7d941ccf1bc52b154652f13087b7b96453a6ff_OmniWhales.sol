// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract OmniWhales is ERC721A, Ownable {
    using Strings for uint256;

    constructor() ERC721A("OmniWhales", "OmniWhales") {
    }

    uint256 public constant MAX_SUPPLY = 2000;
    
    uint256 private mintCount = 0;

    uint256 public freeMintAmount = 500;

    uint256 public price = 0.003 ether;

    string private baseTokenURI;

    string public unRevealedURI = "https://ipfs.io/ipfs/QmaBk4sdedvfDaRuivcuUsB3jpTb3eRH1878aevRB6CW3L";
      
    bool public saleOpen = true;

    bool public revealed = false;

    event Minted(uint256 totalMinted);
      
    function totalSupply() public view override returns (uint256) {
        return mintCount;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setUnRevealedURI(string memory uri) public onlyOwner {
        unRevealedURI = uri;
    }

    function setFreeAmount(uint256 amount) external onlyOwner {
        freeMintAmount = amount;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function flipSale() external onlyOwner {
        saleOpen = !saleOpen;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function mint(address _to, uint256 _count) external payable {
        uint256 supply = totalSupply();

        require(supply + _count <= MAX_SUPPLY, "Exceeds maximum supply");
        require(_count > 0, "Minimum 1 NFT has to be minted per transaction");

        if (msg.sender != owner() && (mintCount + _count) > freeMintAmount) {
            require(saleOpen, "Sale is not open yet");
            require(
                msg.value >= price * _count,
                "Ether sent with this transaction is not correct"
            );
        }

        if(msg.sender != owner()) {
            require(
                _count <= 20,
                "Maximum 20 NFTs can be minted per transaction"
            );
        }
        
        mintCount += _count;      
        _safeMint(_to, _count);
        emit Minted(_count);       
    }

    function setRevealed(bool _revealed) external onlyOwner {
        revealed = _revealed;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return revealed ? string(abi.encodePacked(baseTokenURI, tokenId.toString(), '.json')) : unRevealedURI;
    }
}