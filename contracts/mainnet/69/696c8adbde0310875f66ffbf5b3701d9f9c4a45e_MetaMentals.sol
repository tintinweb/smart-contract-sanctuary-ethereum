// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract MetaMentals is ERC721A, Ownable {

    constructor(string memory baseURI) ERC721A("FLYINFRIENDS", "FLYINFRIENDS") {
        setBaseURI(baseURI);
    }

    uint256 public constant MAX_SUPPLY = 6500;

    uint256 private mintCount = 0;

    uint256 public price = 470000000000000;

    string private baseTokenURI;
      
    bool public saleOpen = false;

    event Minted(uint256 totalMinted);
      
    function totalSupply() public view override returns (uint256) {
        return mintCount;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function changePrice(uint256 _newPrice) external onlyOwner {
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

        if (msg.sender != owner()) {
            require(saleOpen, "Sale is not open yet");
            require(
                _count <= 20,
                "Maximum 20 NFTs can be minted per transaction"
            );
            require(
                msg.value >= price * _count,
                "Ether sent with this transaction is not correct"
            );
        }
        mintCount += _count;      
        _safeMint(_to, _count);
        emit Minted(_count);       
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
}