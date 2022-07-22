// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import './ERC721Connector.sol';

contract KryptoBird is ERC721Connector{
    

    constructor() ERC721Connector('KryptoBird','KBIRDZ') {
        
    }

    string[] public KryptoBirdz;
    mapping(string => bool) kbirdexist;
    uint public _id;

    function mint(string memory _Kbird) public{
        require(!kbirdexist[_Kbird]);
        KryptoBirdz.push(_Kbird);
         _id=KryptoBirdz.length-1;

        _mint(msg.sender,_id);
        kbirdexist[_Kbird]=true;
    }



}