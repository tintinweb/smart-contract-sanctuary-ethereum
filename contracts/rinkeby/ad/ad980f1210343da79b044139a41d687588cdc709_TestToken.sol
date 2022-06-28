// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract TestToken is ERC721A, Ownable {

    using Strings for uint256;

    uint256 public constant TOTAL_SUPPLY = 5555;
    uint256 public constant MAX_MINT_AMOUNT = 4;
    uint256 public constant PRICE = 0.00 ether;
    
    string private _baseTokenURI;

    mapping(address => uint) public amountMintedAddress;
   
    constructor(
        string memory _initBaseURI
    ) ERC721A("Test Token", "TT") { //Replace with name and symbol
        _baseTokenURI = _initBaseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function mint(uint256 amount) public payable {
        require(amount<= MAX_MINT_AMOUNT, "Max mint per transaction exceeded");
        require(amountMintedAddress[_msgSender()] < MAX_MINT_AMOUNT, "Max mint per wallet exceeded");
        require(totalSupply() + amount <= TOTAL_SUPPLY, "Sold out");
        require(msg.value >= amount * PRICE, "Not enough ETH");
        amountMintedAddress[_msgSender()] += amount;
        _safeMint(msg.sender, amount);                
        
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(_exists(tokenId), "NFT does not exist");
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }

    function withdrawEther() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}