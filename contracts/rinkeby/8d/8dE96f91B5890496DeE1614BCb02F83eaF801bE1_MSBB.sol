// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract MSBB is ERC721, Ownable {
    using Strings for uint256;

    uint256 public constant NFT_MAX = 3500;
    uint256 public NFT_PRICE = 0.03 ether;
    uint256 public constant NFTS_PER_MINT = 10;
    string private _tokenBaseURI = "https://gateway.pinata.cloud/ipfs/QmUtLgPqxxj7HNiTHZS9XG2dhcLUn4i8hu5mbUk94EPLcA/";
    uint256 public totalSupply;

    constructor() ERC721("Ms. Bigfoot Baddie", "MSBB") {}

    function mint(
        uint256 tokenQuantity
    ) external payable {
        require(totalSupply < NFT_MAX, "OUT_OF_STOCK");
        require(totalSupply + tokenQuantity <= NFT_MAX, "EXCEED_STOCK");
        require(NFT_PRICE * tokenQuantity <= msg.value, "INSUFFICIENT_ETH");
        require(tokenQuantity <= NFTS_PER_MINT, "EXCEED_NFTS_PER_MINT");

        for (uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(msg.sender, totalSupply + i + 1);
        }

        totalSupply += tokenQuantity;
    }

    function withdraw(address wallet) external onlyOwner {
        uint256 currentBalance = address(this).balance;
        payable(wallet).transfer(currentBalance);
    }

    function setNFTPrice(uint256 price) external onlyOwner {
        NFT_PRICE = price;
    }

    function setTokenBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    function tokenBaseURI() public view returns (string memory) {
        return _tokenBaseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");
        
        return
            string(
                abi.encodePacked(_tokenBaseURI, tokenId.toString(), ".json")
            );
    }
}