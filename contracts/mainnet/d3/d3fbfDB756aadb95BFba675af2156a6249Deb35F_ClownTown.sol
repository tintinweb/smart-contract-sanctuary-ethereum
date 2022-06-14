// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";

contract ClownTown is ERC721A, Ownable {

    uint256 public price = 0.004 ether;
    uint256 public maxTotalSupply = 5000;
    uint256 public saleStartTime = 1655213400;
    string private baseURI;
    mapping(address => bool) public freeClownsClaimed;

    constructor() ERC721A("ClownTown", "CLOWN") {
        saleStartTime = block.timestamp;
    }

    modifier mintableSupply(uint256 _quantity) {
        require(
            _quantity > 0,
            "You need to mint at least 1 NFT."
        );
        require(
            totalSupply() + _quantity <= maxTotalSupply,
            "Over maximum supply."
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

    function mintClowns(uint256 _quantity)
        external
        payable
        saleActive
        mintableSupply(_quantity) 
    {
        uint256 curr_value;
        if(freeClownsClaimed[msg.sender]) {
            curr_value = _quantity * price;
        } else {
            curr_value = (_quantity - 1) * price;
            freeClownsClaimed[msg.sender] = true;
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

    function setMaxSupply(uint256 newSupply) external onlyOwner {
        require(newSupply < maxTotalSupply);
        maxTotalSupply = newSupply;
    }


    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}