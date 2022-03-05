/**
 *Submitted for verification at Etherscan.io on 2022-03-05
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

contract Rio {
    string public constant name = "rio";
    string public constant symbol = "RIO";
    address private immutable _owner;

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    constructor(address owner){
        _owner = owner;
        emit Transfer(address(0), owner, 0);
    }

    function tokenURI(uint256 tokenId) public view returns (string memory){
        require(tokenId == 0, "");
        return "ipfs://QmVqXswfdHnEkC7sV5QWDVdZeVZUtPRut5APeUnDyXUptz";
    }

    function balanceOf(address owner) public view returns(uint256){
        return owner == _owner ? 1 : 0;
    }

    function ownerOf(uint256 tokenId) public view returns(address){
        require(tokenId == 0, "");
        return _owner;
    }

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || 
            interfaceId == 0x80ac58cd || 
            interfaceId == 0x5b5e139f; 
    }
}