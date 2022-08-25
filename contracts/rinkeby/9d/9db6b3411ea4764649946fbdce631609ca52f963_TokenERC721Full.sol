pragma solidity ^0.4.22;

import "./TokenERC721Enumerable.sol";
import "./TokenERC721Metadata.sol";

/// @title A scalable implementation of all ERC721 NFT standards combined.
/// @author Andrew Parker
/// @dev Extends TokenERC721Metadata, TokenERC721Enumerable
contract TokenERC721Full is TokenERC721Metadata, TokenERC721Enumerable{
    constructor(uint _initialSupply) public TokenERC721Metadata(_initialSupply,"TeacherJC","0824Excersie","uriBase") TokenERC721Enumerable(_initialSupply){
        //Nothing extra required, just need to make sure you explicitly call the other two constructors above ^^
    }
}