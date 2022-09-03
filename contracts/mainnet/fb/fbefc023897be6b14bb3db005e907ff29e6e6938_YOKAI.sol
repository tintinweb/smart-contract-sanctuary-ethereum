// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10 <0.9.0;

import './ERC721A.sol';
import './Ownable.sol';


    // 0.033eth  and ERC721A contract (low GAS Fee)
    // 4444 Supply and 3 NFT per wallte & per tx

contract YOKAI is ERC721A, Ownable {
    constructor() ERC721A("Yokai Labs v1", "YOKAI") {
        WLmint(1);
    }

    string _baseTokenURI;
    mapping(address => uint256) _minted;
    uint public constant RESERVED = 44;
    uint public Lab_Minted = 0;

    function WLmint(uint256 quantity) public payable {
        require(totalSupply() + quantity <= 4444 - RESERVED -Lab_Minted, "All YOKAI NFT minted");
        require(quantity <= 3, "Cant mint more than 3 YOKAI NFT in one tx");
        require(_minted[msg.sender] < 3, "Cant mint more than 3 YOKAI NFT per wallet");
        _minted[msg.sender] += quantity;
        _mint(msg.sender, quantity);
    }

    function mintReserved(address toaddress, uint256 quantity) external onlyOwner 
    {
        require(Lab_Minted + quantity <= RESERVED, "Cant mint more than _RESERVED");
        Lab_Minted = Lab_Minted + quantity;
        _mint(toaddress, quantity);

    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

 
}