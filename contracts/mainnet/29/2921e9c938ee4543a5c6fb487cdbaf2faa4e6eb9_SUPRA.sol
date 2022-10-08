// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./IERC721A.sol";
import "./Ownable.sol";
import "./ERC721AQueryable.sol";
import "./IERC721AQueryable.sol";
import "./ERC721ABurnable.sol";
import "./IERC721ABurnable.sol";

contract SUPRA is IERC721A, Ownable, ERC721A {
    uint256 public maxSupply = 5000; 
    uint256 public paidPrice = 0.05 ether; 
    string public baseURI;
    bool public saleStarted;

    constructor() ERC721A('Supra3.0', 'SUPRA') {
    }

//Gamarjoba!

    modifier whenSaleStarted() {
        require(saleStarted, "Public sale has not started");
        _;
    }

    function mint(uint256 amountOfTokens) external payable whenSaleStarted {
        require(totalSupply() + amountOfTokens <= maxSupply, "Exceeds max supply.");
        require(amountOfTokens > 0, "Must mint at least one.");
        require(paidPrice * amountOfTokens <= msg.value, "ETH amount is incorrect");
        _safeMint(msg.sender, amountOfTokens);
    }

    function airdrop(address recipient, uint256 amountOfTokens) external onlyOwner {
        require(recipient != address(0), "Cannot add null address");
        _safeMint(recipient, amountOfTokens);
    }

    function toggleSaleStarted() external onlyOwner {
        saleStarted = !saleStarted;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function changeSupply(uint256 newMax) external onlyOwner {
        maxSupply = newMax;
    }

    function updatePrice(uint256 newPriceInWEI) external onlyOwner {
        paidPrice = newPriceInWEI;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }
    function withdrawrouted() external onlyOwner {
        uint256 sendAmount = address(this).balance;
        address supra1 = payable(0x394EE2F4fbA198aA953Ffd8861fBD2dEe1BA830E);
        address supra2 = payable(0x45d3590e45A4c491F0163567c260c9Aa100D5E6c);
        address supra3 = payable(0x7Fe06D2c4D5E42d8506fDA55085e782F12805b3e);
        address supra4 = payable(0x2b5920C422E9Be335d2d8c375700Cbc6D525E243);
        address supra5 = payable(0xB8f5D071714a15e99b2fcfCb49666e27073E7c85);

        bool success;
        (success, ) = supra1.call{value: ((sendAmount * 43)/100)}("");
        require(success, "Transaction Unsuccessful");

        (success, ) = supra2.call{value: ((sendAmount * 15)/100)}("");
        require(success, "Transaction Unsuccessful");

        (success, ) = supra3.call{value: ((sendAmount * 14)/100)}("");
        require(success, "Transaction Unsuccessful");

        (success, ) = supra4.call{value: ((sendAmount * 14)/100)}("");
        require(success, "Transaction Unsuccessful");        

        (success, ) = supra5.call{value: ((sendAmount * 14)/100)}("");
        require(success, "Transaction Unsuccessful");
     }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}