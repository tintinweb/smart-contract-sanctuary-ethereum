// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./ERC721.sol";

contract JimmyNFT is ERC721 {

    using Strings for uint256;

    string public defaultCoverURI;
    
    constructor() ERC721("JimmyNFT", "JNFT") {
        
    }
}