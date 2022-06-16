// SPDX-License-Identifier: MIT

import "./Context.sol";
import "./Ownable.sol";
import './ERC721A.sol';


pragma solidity ^0.8.7;

contract GoldBarz is Ownable, ERC721A {
    uint256 public maxSupply                    = 10000;
    uint256 public maxFreeSupply                = 1000;

    uint256 public maxPerAddressDuringMint      = 25;
    uint256 public maxPerAddressDuringFreeMint  = 3;
    
    uint256 public price                        = 0.05 ether;
    bool    public saleIsActive                 = false;

    string private _baseTokenURI;

    mapping(address => uint256) public freeMintedAmount;
    mapping(address => uint256) public mintedAmount;

    constructor() ERC721A("Gold Barz", "GLDBRZ") {
        
    }

    modifier mintCompliance() {
        require(saleIsActive, "Sale is not active yet.");
        require(tx.origin == msg.sender, "Caller cannot be a contract.");
        _;
    }

    function mint(uint256 _quantity) external payable mintCompliance() {
        require(
            msg.value >= price * _quantity,
            "Insufficient Fund."
        );
        require(
            maxSupply >= totalSupply() + _quantity,
            "Exceeds max supply."
        );
        uint256 _mintedAmount = mintedAmount[msg.sender];
        require(
            _mintedAmount + _quantity <= maxPerAddressDuringMint,
            "Exceeds max mints per address!"
        );

        mintedAmount[msg.sender] = _mintedAmount + _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function freeMint(uint256 _quantity) external mintCompliance() {
        require(
            maxFreeSupply >= totalSupply() + _quantity,
            "Exceeds max free supply."
        );
        uint256 _freeMintedAmount = freeMintedAmount[msg.sender];
        require(
            _freeMintedAmount + _quantity <= maxPerAddressDuringFreeMint,
            "Exceeds max free mints per address!"
        );
        freeMintedAmount[msg.sender] = _freeMintedAmount + _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function flipSale() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function burnSupply(uint256 _amount) public onlyOwner {
        require(
            maxSupply - _amount >= totalSupply(), 
            "Supply cannot fall below minted tokens."
        );
        maxSupply -= _amount;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

      function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
              string memory baseURI = _baseURI();
              return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId),".json")) : '';

    }

    function withdraw() external payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
  }
 
}