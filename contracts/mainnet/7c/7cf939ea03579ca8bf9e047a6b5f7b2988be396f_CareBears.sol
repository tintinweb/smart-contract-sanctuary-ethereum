// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721F.sol";
import "./SafeMath.sol";

/**
 * @title Care Bears contract
 * @dev Extends ERC721F Non-Fungible Token Standard basic implementation.
 * Optimized to no longer use ERC721Enumerable , but still provide a totalSupply() and walletOfOwner(address _owner) implementation.
 * @author @rip0004
 * 
 */

contract CareBears is ERC721F {
    using SafeMath for uint256;
    using Strings for uint256;
    
    uint256 public tokenPrice = 0.01 ether;
    uint256 public MAX_TOKENS = 2222;
    
    bool public saleIsActive;

    event priceChange(address _by, uint256 price);
    
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721F(_name, _symbol) {
        setBaseTokenURI(_initBaseURI);
    }

    function mintOwner(address to,uint numberOfTokens) public onlyOwner {    
        uint supply = totalSupply();
        require(supply.add(numberOfTokens) <= MAX_TOKENS, "Reserve would exceed max supply of Tokens");
        for (uint i = 0; i < numberOfTokens; i++) {
            _safeMint(to, supply + i);
        }
    }

    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setPrice(uint256 price) external onlyOwner {
        tokenPrice = price;
    }

    function publicMint(uint256 numberOfTokens) external payable {
        uint256 supply = totalSupply();
        require(saleIsActive, "Sale NOT active yet");
        require(numberOfTokens < 11, "max of 10 NFTs per transaction");
        require(supply.add(numberOfTokens) <= MAX_TOKENS, "Purchase would exceed max supply of Tokens");
        if(supply.add(numberOfTokens) > 1600) {  require(tokenPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct"); }
        for(uint256 i; i < numberOfTokens; i++){
            _safeMint( msg.sender, supply + i );
        }
    }
    
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _withdraw(owner(), balance);
    }
    
    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Failed to widthdraw Ether");
    }

    // contract can recieve Ether
    fallback() external payable { }
    receive() external payable { }
}