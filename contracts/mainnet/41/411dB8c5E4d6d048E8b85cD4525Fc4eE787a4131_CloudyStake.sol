/**
 *Submitted for verification at Etherscan.io on 2022-06-30
*/

// SPDX-License-Identifier: MIT
// File: development/CloudyStake.sol


pragma solidity ^0.8.7;

interface IERC721A {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);

}

contract CloudyStake {
    address public cloudyAddress;
    address public owner;
    mapping(uint256 => address) public stakeOwnerOf;
    mapping(address => uint256[]) internal depositories;
    mapping(uint256 => uint256) internal tokenIdByIndex;

    constructor(address _cloudyAddress) {
        cloudyAddress = _cloudyAddress;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function stake(uint256 _tokenId) public {
        require(
            IERC721A(cloudyAddress).ownerOf(_tokenId) == msg.sender && stakeOwnerOf[_tokenId] == address(0),
            "You must own the NFT."
        );
        IERC721A(cloudyAddress).transferFrom(msg.sender,address(this),_tokenId);
        depositories[msg.sender].push(_tokenId);
        tokenIdByIndex[_tokenId] = depositories[msg.sender].length - 1;
        stakeOwnerOf[_tokenId]=msg.sender;
    }

    function unStake(uint256 _tokenId) public {
        require(stakeOwnerOf[_tokenId] == msg.sender, "Not original owner");
        uint256 tokenIndex = tokenIdByIndex[_tokenId];
        uint256 len = depositories[msg.sender].length;
        uint256 lastTokenId = depositories[msg.sender][len - 1];
        depositories[msg.sender][tokenIndex] = lastTokenId;
        tokenIdByIndex[lastTokenId]=tokenIndex;
        depositories[msg.sender].pop();
        stakeOwnerOf[_tokenId] = address(0);
        IERC721A(cloudyAddress).transferFrom(
            address(this),
            msg.sender,
            _tokenId
        );
    }
    
    function batchStake(uint256[] memory _tokenIds) external {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            stake(_tokenIds[i]);
        }
    }

    function batchUnStake(uint256[] memory _tokenIds)external{
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            unStake(_tokenIds[i]);
        }
    }

    function getDopositor(address _owner) external view returns (uint256[] memory) {
        return depositories[_owner];
    }

    function setCloudyAddress(address _cloudyAddress)external onlyOwner{
        cloudyAddress=_cloudyAddress;
    }

    function saveToken(uint256[] memory _tokenIds) external onlyOwner{
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            IERC721A(cloudyAddress).transferFrom(address(this),msg.sender,_tokenIds[i]);
        }
    }
    
}