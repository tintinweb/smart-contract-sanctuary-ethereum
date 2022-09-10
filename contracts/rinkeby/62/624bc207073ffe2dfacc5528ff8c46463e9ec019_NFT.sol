// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract NFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    struct NftCreateItem {
        uint256 tokenId;
        address payable creator;
    }
    mapping(uint256 => NftCreateItem) private NftCreatorLists;

    constructor(string memory _name ,string memory _symbol) ERC721(_name,_symbol) {}     
   

    // This function is called when the token is to be created
    function createToken(
        address payable _creator_address,
        string memory tokenURI
    ) public onlyOwner returns (uint256) {
        _tokenIds.increment(); // Increment the tokenIds counter
        uint256 newTokenId = _tokenIds.current(); 
        _mint(msg.sender, newTokenId); 
        _setTokenURI(newTokenId, tokenURI); 
        setApprovalForAll(msg.sender, true);
        NftCreatorLists[newTokenId] = NftCreateItem(
            newTokenId,
            _creator_address
        );

        return newTokenId;
    }

    function Creator(uint256 _token_id) public view returns (address) {
        return NftCreatorLists[_token_id].creator;
    }
    function setCreator(uint256 _token_id,address payable _address) public onlyOwner returns (bool) {
        NftCreatorLists[_token_id].creator = _address;
        return true;
    }
    function setPermanentURI(uint256 _token_id, string memory tokenURI) public onlyOwner returns(bool){
         _setTokenURI(_token_id, tokenURI); 
         return true;
    }
}