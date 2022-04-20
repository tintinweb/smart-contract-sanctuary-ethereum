// contracts/infoGeeexchangeComIliDalsheBlock.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./Ownable.sol";

contract infoGeeexchangeComIliDalsheBlock is ERC721URIStorage, Ownable {
    uint256 public constant MAX_NFT_SUPPLY = 10000;
    uint256 public _counter;

    constructor() ERC721("infoGeeexchangeComIliDalsheBlock", "IGCIDB") {}
    function mint(address to) public onlyOwner returns (uint256){
        require(to != address(0), "ERC721: query for the zero address");
        require(_counter+1 <= MAX_NFT_SUPPLY, "The minting of coins is completed.");
        _safeMint(to, _counter);
        _counter += 1;
        return _counter;
    }
    
    

}