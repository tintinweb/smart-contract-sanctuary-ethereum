// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Royalties {

    mapping(uint => Royalty) royalties;
    mapping(address => mapping(uint256 => uint256)) royaltiesIDs;
    uint256 private royaltiesId;

    struct Royalty {
        address collection;
        address owner;
        uint256 tokenId;
        uint256 percent;
    }

    constructor(){
        royaltiesId = 1;
    }
    
    function _nextRoyaltiesId() internal returns (uint256) {
        return royaltiesId++;
    }

    function setRoyalties(address _collection, uint256 _tokenId, address _owner, uint256 _percent) external returns(uint256){
        Royalty memory _royalties = Royalty(_collection, _owner, _tokenId, _percent);
        uint newRoyaltiesId = _nextRoyaltiesId();
        royalties[newRoyaltiesId] = _royalties;
        royaltiesIDs[_collection][_tokenId] = newRoyaltiesId;
        return newRoyaltiesId;
    }

    function getRoyalties(uint256 _royaltiesId) external view returns(Royalty memory){
        return royalties[_royaltiesId];
    }

    function getRoyaltiesCollection(address _collection, uint256 _tokenId, address _owner) external view returns(Royalty memory){
        uint256 _royaltiesId = royaltiesIDs[_collection][_tokenId];
        require(royalties[_royaltiesId].owner == _owner,"Royalties not found");
        return royalties[_royaltiesId];
    }
}