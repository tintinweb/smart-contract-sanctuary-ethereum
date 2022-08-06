// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10 <0.9.0;

import './ERC721A.sol';
import "./Ownable.sol";

contract ooobirds is ERC721A, Ownable {
    constructor() ERC721A("ooobirds", "ooobirds") {
        mint(1);
    }

    string _baseTokenURI;
    mapping(address => uint256) _minted;

    // its free
    function mint(uint256 quantity) public {
        require(totalSupply() + quantity <= 10000, "All ooobirds minted");
        require(quantity <= 10, "Cant mint more than 10 ooobirds in one tx");
        require(_minted[msg.sender] < 10, "Cant mint more than 10 ooobirds per wallet");
        _minted[msg.sender] += quantity;
        _mint(msg.sender, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }
}