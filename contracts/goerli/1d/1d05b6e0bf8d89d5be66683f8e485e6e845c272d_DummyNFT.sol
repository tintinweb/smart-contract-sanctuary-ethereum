/**
 *Submitted for verification at Etherscan.io on 2023-02-06
*/

pragma solidity ^0.8.0;

contract DummyNFT {
    uint256 public tokenId;
    mapping (uint256 => address) public ownerOf;

    event TokenTransferred(
        uint256 indexed tokenId,
        address indexed from,
        address indexed to
    );

    constructor() public {
        tokenId = 0;
    }

    function mint() public {
        tokenId++;
        ownerOf[tokenId] = msg.sender;
    }

    function transfer(uint256 _tokenId, address _to) public {
        require(ownerOf[_tokenId] == msg.sender, "Only the owner can transfer NFTs");
        ownerOf[_tokenId] = _to;
        emit TokenTransferred(_tokenId, msg.sender, _to);
    }
}