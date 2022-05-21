// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Royalties {

    mapping(uint => Royalty) royalties;
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
        Royalty memory _royalties = Royalty(
            _collection,
            _owner,
            _tokenId,
            _percent
        );
        uint newRoyaltiesId = _nextRoyaltiesId();
        royalties[newRoyaltiesId] = _royalties;
        return newRoyaltiesId;
    }

    function getRoyalties(uint256 _royaltiesId) external view returns(Royalty memory){
        return royalties[_royaltiesId];
    }
}