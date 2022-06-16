//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";

 
contract AminNFTcreat is ERC721URIStorage,Ownable{
    
    using Counters for Counters.Counter;
    
    Counters.Counter private _TokenID;

    constructor(string memory name_, string memory symbol_) ERC721(name_,symbol_) {}

    function mint(string memory _tokenURI) public onlyOwner returns(uint256){
        uint256 tokenid =_TokenID.current();
        _TokenID.increment();
        _safeMint(_msgSender(),tokenid);
        _setTokenURI(tokenid,_tokenURI);

        return tokenid;
    }
}