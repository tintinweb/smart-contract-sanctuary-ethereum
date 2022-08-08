// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ERC721Connector.sol";

contract KryptoBird is ERC721Connector{
    constructor() ERC721Connector("KryptoBirdz","KBIRD"){

    }

    uint256 tokenID;
    string[] public Kbirdz;
    mapping(string => bool) kbirdexist;

    function mint(string  memory Kbird) public{
        require(kbirdexist[Kbird]!=true,"Krypto Bird already exist" );

        Kbirdz.push(Kbird);
        tokenID=Kbirdz.length -1;

        _mint(msg.sender,tokenID);
        kbirdexist[Kbird]=true;
        
    }
}