// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";

contract BoredGoblinYachtClub is ERC721A, Ownable {
    uint256 public price = 0.005 ether;
    uint256 public maxMintPerWallet = 50;
    uint256 public maxFreeMintPerWallet = 5;
    uint256 public freeMintAmount = 500;
    uint256 public maxTotalSupply = 3000;
    uint256 public saleStartTime;
    string private baseURI;

    constructor() ERC721A("BoredGoblinYachtClub", "BGYC") {
        saleStartTime = block.timestamp;
    }

    modifier mintableSupply(uint256 _quantity) {
        require(
            totalSupply() + _quantity <= maxTotalSupply,
            "Over maximum supply."
        );
        _;
    }

    modifier saleActive() {
        require(saleStartTime <= block.timestamp, "Not start yet.");
        _;
    }

    function mintBGYC(uint256 _quantity)
        external
        payable
        saleActive
        mintableSupply(_quantity)
    {
        require(_quantity <= maxMintPerWallet, "Over maximum limit.");

        uint256 curr_value;
        if (totalSupply() + _quantity <= freeMintAmount) {
            require(
                _quantity <= maxFreeMintPerWallet,
                "Over max free mint limit."
            );
            curr_value = 0;
        }
        if (
            totalSupply() < freeMintAmount &&
            (totalSupply() + _quantity > freeMintAmount)
        ) {
            require(
                _numberMinted(msg.sender) + freeMintAmount - totalSupply() <=
                    maxFreeMintPerWallet,
                "Over max free mint limit."
            );
            curr_value = (totalSupply() + _quantity - freeMintAmount) * price;
        }
        if (totalSupply() >= freeMintAmount) {
            curr_value = _quantity * price;
        }
        require(msg.value >= curr_value, "Insufficent funds.");

        _safeMint(msg.sender, _quantity);
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setTime(uint256 _time) external onlyOwner {
        saleStartTime = _time;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}