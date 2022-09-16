// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

/// @custom:security-contact [email protected]
contract MyNFT is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("World NFT-Hastur", "Hastur") {

    }

    function safeMint(address to,uint8 num) public onlyOwner {
        require(num<100000,"num maxed");
        for (uint8 i = 0; i < num; i++) { 
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(to, tokenId); 
        }
    }


    function _baseURI() internal pure override returns (string memory) {
        return "https://bafkreih4grzylajoentxrgmjh5zekhs7psy34ehn67wwyxn3r5qs736jai.ipfs.nftstorage.link";
    }




}