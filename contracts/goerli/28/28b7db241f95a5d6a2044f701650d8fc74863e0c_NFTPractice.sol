// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "./console.sol";

import "./ERC721Enumerable.sol";
import "./Ownable.sol";


contract NFTPractice is ERC721Enumerable, Ownable{
    string private currentBaseURI;
    uint256 public constant mintPrice = 0.001 ether;
    uint256 public constant maxSupply = 5;
    uint256 public nftPerAddressLimit = 1;
    constructor() ERC721("NFTPractice","NFT"){}
    

    function mint(uint256 quantity) public payable{
        require(totalSupply()+quantity<maxSupply,"Collection sold out");
        require(msg.value>=mintPrice*quantity,"Insufficient Balance");
        for(uint256 i=0; i<quantity; ++i){
          uint256 tokenId = totalSupply();
          _safeMint(msg.sender,tokenId);
        }
    }

    function _baseURI() internal view virtual override returns(string memory){
          return currentBaseURI;
    }

    function _setBaseURI(string memory baseURI_) public onlyOwner{
          currentBaseURI=baseURI_;
    }

    function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
        nftPerAddressLimit = _limit;
    }
    function withdraw() public onlyOwner{
        uint256 balance = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value:balance}("");
        require(success,"With Failed");
    }
}