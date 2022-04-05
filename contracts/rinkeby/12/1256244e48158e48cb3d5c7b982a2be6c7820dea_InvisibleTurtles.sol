// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract InvisibleTurtles is ERC721A, Ownable {
    using Strings for uint256;

    string public baseURI = "ipfs://QmaEXvNF9eXX7jt9zzZx2euxqbbWZ3Kcjt8BgKdctcx4Qu/";
    string public constant baseExtension = ".json";

    uint256 public constant MAX_TOKENS = 3333;
    uint256 public constant MAX_FREE_TOKENS = 833;
    uint256 public constant MAX_PER_TX = 20;
    uint256 public price = .01 ether;

    bool public saleActive = true;
    
    constructor() ERC721A("Invisible Turtles", "TURT") { }
    
    // Could change to payable
    function mint(uint256 amount) external payable {
        address caller = _msgSender();

        require(saleActive, "Sale not active");
        require(MAX_TOKENS >= totalSupply() + amount, "Cannot exceed max supply");
        require(caller == tx.origin, "No contracts lol");
        require(MAX_PER_TX >= amount, "Cannot exceed 20 per tx");

        if (MAX_FREE_TOKENS >= totalSupply()) {
            require(MAX_FREE_TOKENS >= totalSupply() + amount, "Cannot exceed free supply");
        }
        else {
            require(amount * price == msg.value, "Invalid amount paid");
        }
        _safeMint(caller, amount);
    }

    // Set base URI
    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }
    
    // Get token URI
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return bytes(baseURI).length > 0 ? string(
            abi.encodePacked(
              baseURI,
              Strings.toString(_tokenId),
              baseExtension
            )
        ) : "";
    }
    
    // Pause sale in case anything happens
    function flipSaleState() public onlyOwner {
        saleActive = !saleActive;
    }

    // Override default baseURI function to return new URI
    function _baseURI() internal view virtual override returns (string memory) { 
        return baseURI;
    }
    // Send given amount to given address
    function withdraw(address _to, uint256 _amount) public onlyOwner {
        require(_amount <= address(this).balance, "Not enough money in the balance"); // Check that it doesn't exceed max balance
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether"); // Check that it sent
    }
    
}