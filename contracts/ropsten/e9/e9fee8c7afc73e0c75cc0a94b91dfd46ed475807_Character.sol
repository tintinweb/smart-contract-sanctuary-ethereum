// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ERC721.sol";

interface IToken {
    function balance(address owner) external view returns (uint256) ;
    function burn(address _owner, uint256 _noOfTokens) external;
}

contract Character is ERC721 {

    address owner;
    mapping (address => uint256) internal level;

    modifier isOwner {
        require(msg.sender == owner, "not an owner");
        _;
    }

    constructor(){
        owner = msg.sender;
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) isOwner public override {
        super.safeTransferFrom(_from, _to, _tokenId, data);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) isOwner public override {
        super.safeTransferFrom(_from, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) isOwner public override {
        super.transferFrom(_from, _to, _tokenId);
    }

    function getLevel() external view returns (uint256) {
        return level[msg.sender];
    }

    function mint(uint256 _tokenId, address _to, IToken _tokenAddress, string memory _tokeURI) isOwner public {
        IToken _token = IToken(_tokenAddress);
        require(_token.balance(msg.sender) == level[msg.sender] *2, "Not enough tokens of Token contract");
        //burn here
        _token.burn(msg.sender,level[msg.sender] *2);
        super.mint(_tokenId, _to, _tokeURI);
        level[msg.sender] += 1;
    }

}