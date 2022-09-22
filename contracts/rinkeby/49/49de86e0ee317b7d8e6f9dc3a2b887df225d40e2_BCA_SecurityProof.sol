// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// @title: Blockchain Contract Audit Security Proof
// @Webside: https://bcaservice.io/tw
// @creator: 思偉達創新科技- STARBIT Innovation 

/*
        ╔══╗╔═══╦═══╗────╔═══╗───────────╔╗─────────╔═══╗────────╔═╗
        ║╔╗║║╔═╗║╔═╗║────║╔═╗║──────────╔╝╚╗────────║╔═╗║────────║╔╝
        ║╚╝╚╣║─╚╣║─║║────║╚══╦══╦══╦╗╔╦═╬╗╔╬╗─╔╗────║╚═╝╠═╦══╦══╦╝╚╗
        ║╔═╗║║─╔╣╚═╝║────╚══╗║║═╣╔═╣║║║╔╬╣║║║─║║────║╔══╣╔╣╔╗║╔╗╠╗╔╝
        ║╚═╝║╚═╝║╔═╗║────║╚═╝║║═╣╚═╣╚╝║║║║╚╣╚═╝║────║║──║║║╚╝║╚╝║║║
        ╚═══╩═══╩╝─╚╝────╚═══╩══╩══╩══╩╝╚╩═╩═╗╔╝────╚╝──╚╝╚══╩══╝╚╝
                                           ╔═╝║
                                           ╚══╝
*/

import './ERC721A.sol';
import './Ownable.sol';

contract BCA_SecurityProof is ERC721A, Ownable {
    
    string public baseTokenURI;
    string public extension;

    constructor() ERC721A("BCA_SecurityProof", "BCA_SP") {}

    function publishProof(address _target) public onlyOwner {
        _mint(_target, 1);
    }

    function setbaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setExtension(string memory _extension) public onlyOwner {
        extension = _extension;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) 
            revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();

        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), extension)) : '';
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

}