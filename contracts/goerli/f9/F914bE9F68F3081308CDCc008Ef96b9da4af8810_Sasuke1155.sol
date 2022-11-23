// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ERC1155.sol";

contract Sasuke1155 is ERC1155{
    string public name;
    string public symbol;
    uint256 public tokenCount;

    mapping(uint256 => string) private _tokenURIs;

    constructor(string memory _name, string memory _symbol){
        name = _name;
        symbol =_symbol;
    }

    function uri(uint256 tokenId) public view  returns(string memory){
        return _tokenURIs[tokenId];
    }

    function mint(uint256 amount, string memory _uri ) public{
        require(msg.sender != address(0), "Mint to the zero address");
        tokenCount +=1;
        _balances[tokenCount][msg.sender] +=amount;
        _tokenURIs[tokenCount] = _uri;
        emit TransferSingle(msg.sender,address(0) , msg.sender,tokenCount,amount);
    }

    // function batchMint(uint[] amount, string[] memory _uri){

    // }

     function supportsInterface(bytes4 interfaceId) public pure override returns(bool){
        return interfaceId == 0xd9b67a26 || interfaceId == 0x0e89341c;
    }
}