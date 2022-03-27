// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

contract regohiroJP {
    string public constant name = "regohiro.jp";
    string public constant symbol = "REGOHIRO_JP";
    address private constant _owner = 0xE3B2eFfedb0a696459DF47F1D6eE146599734eB3;

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    constructor(){
        emit Transfer(address(0), _owner, 0);
    }

    function tokenURI(uint256 tokenId) public view returns (string memory){
        require(tokenId == 0, "");
        return "ipfs://QmYa1Y4qJ7eQB95ek2fwvYjMS3ambgxr4grrRxYcPwtFmf";
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