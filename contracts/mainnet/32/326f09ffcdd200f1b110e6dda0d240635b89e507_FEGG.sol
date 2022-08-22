// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10 <0.9.0;

import './ERC721A.sol';
import './Ownable.sol';


    // its free Mint  and ERC721A contract (low GAS Fee)
    // 19270 Supply and 10 NFT per wallte & per tx
    // INSTANT REVEAL

    // Follow @NFT2Pixel 


contract FEGG is ERC721A, Ownable {
    constructor() ERC721A("Finiliar-egg", "FEGG") {
        mint(10);
    }

    string _baseTokenURI;
    mapping(address => uint256) _minted;
    uint public constant N2PLab_RESERVED = 1972;
    uint public N2PLab_Minted = 0;

    function mint(uint256 quantity) public {
        require(totalSupply() + quantity <= 19270 - N2PLab_RESERVED -N2PLab_Minted, "All Finiliar-egg minted");
        require(quantity <= 10, "Cant mint more than 10 Finiliar-egg in one tx");
        require(_minted[msg.sender] < 10, "Cant mint more than 10 Finiliar-egg per wallet");
        _minted[msg.sender] += quantity;
        _mint(msg.sender, quantity);
    }

    function mintReserved(address toaddress, uint256 quantity) external onlyOwner 
    {
        require(N2PLab_Minted + quantity <= N2PLab_RESERVED, "Cant mint more than _RESERVED");
        N2PLab_Minted = N2PLab_Minted + quantity;
        _mint(toaddress, quantity);

    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

 
}