// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";

contract Real100K is ERC721A, Ownable {

    uint256 public price = 0.01 ether;
    uint256 public maxMintPerWallet = 50;
    uint256 public freeMintAmount = 1000;
    uint256 public maxTotalSupply = 4444;
    uint256 public saleStartTime;
    string private baseURI;

    constructor() ERC721A("$100K PFP", "$100KPFP") {
        saleStartTime = block.timestamp;
    }

    modifier mintableSupply(uint256 _quantity) {
        require(
            totalSupply() + _quantity <= maxTotalSupply,
            "Over maximum supply."
        );
        _;
    }

    modifier maxPerWalletLimits(uint256 _quantity, uint256 _limits) {
        require(
            _quantity > 0 &&  _quantity <= _limits,
            "Over maximum limit."
        );
        _;
    }


    modifier saleActive() {
        require(
            saleStartTime <= block.timestamp,
            "Not start yet."
        );
        _;
    }

    function mint100k(uint256 _quantity)
        external
        payable
        saleActive
        maxPerWalletLimits(_quantity,maxMintPerWallet)
        mintableSupply(_quantity) 
    {
        uint256 curr_value;
        if(totalSupply() + _quantity <= freeMintAmount){
        curr_value = 0;
        }
        if(totalSupply() < freeMintAmount && (totalSupply() + _quantity > freeMintAmount)) {
        curr_value = (totalSupply() + _quantity - freeMintAmount) * price;
        }
        if(totalSupply() >= freeMintAmount) {
        curr_value = _quantity * price;
        }
        require(msg.value >= curr_value, "Insufficent funds.");
        
        _safeMint(msg.sender, _quantity);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }


    function setMintPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setSaleTime(uint256 _time) external onlyOwner {
        saleStartTime = _time;
    }


    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}