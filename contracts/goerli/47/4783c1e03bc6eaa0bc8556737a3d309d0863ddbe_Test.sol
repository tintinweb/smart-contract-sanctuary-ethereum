// SPDX-License-Identifier: MIT

import "./ERC721A.sol";
import "./Ownable.sol";
import "./AggregatorV3Interface.sol";

pragma solidity ^0.8.4;

contract Test is Ownable, ERC721A {
    AggregatorV3Interface internal priceFeed;

    //price for public sale
    // $55
    uint256 public nftPriceInUsd = 55 * 1e18;
    string private baseTokenURI;

    constructor() ERC721A("Test", "Test") {
        priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
    }

    ///Allows any address to mint when the public sale is open
    function publicMint(uint256 _mintAmount) public payable {
        require(getConversionRate(msg.value) >= nftPriceInUsd * _mintAmount,"Insufficient funds!");

        _safeMint(msg.sender, _mintAmount);
    }

    function getLatestPrice() public view returns (uint256) {
        (,int price,,,) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function getConversionRate(uint256 ethAmount) public view returns (uint256){
        uint256 ethPrice = getLatestPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}