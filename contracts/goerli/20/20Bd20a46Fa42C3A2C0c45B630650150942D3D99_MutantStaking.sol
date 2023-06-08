/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

/**
 *Submitted for verification at Etherscan.io on 2023-03-31
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title Staking contract
 * @author 0xSumo
 */

abstract contract Ownable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    address public owner;
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Not Owner");_; }
    function transferOwnership(address new_) external onlyOwner { address _old = owner; owner = new_; emit OwnershipTransferred(_old, new_); }
}

interface IERC721 {
    function ownerOf(uint256 tokenId_) external view returns (address);
    function balanceOf(address owner) external view returns (uint256 balance);
    function transferFrom(address _from, address _to, uint256 tokenId_) external;
}

interface IERC1155SS {
    function balanceOf(address owner, uint256 tokenId_) external view returns (uint256 balance);
}

contract MutantStaking is Ownable {

    IERC721 public ERC721 = IERC721(0x2061D3dc401A407cA98fecDBfCd84878981C670E);

    struct tokenInfo {
        uint256 lastStakedTime;
        address tokenOwner;
    }

    mapping(uint256 => tokenInfo) public stakedToken;
    mapping(address => uint256) public stakedTokenAmount;

    function setERC721contract(address _address) external onlyOwner {
        ERC721 = IERC721(_address);
    }

    function multiTransferFrom(address from_, address to_, uint256[] memory tokenIds_) internal {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            ERC721.transferFrom(from_, to_, tokenIds_[i]);
        }
    }

    function stake(uint256 tokenId_) external {
        require(ERC721.ownerOf(tokenId_) == msg.sender, "Not Owner");
        stakedToken[uint256(tokenId_)].lastStakedTime = uint256(block.timestamp);
        stakedToken[uint256(tokenId_)].tokenOwner = msg.sender;
        unchecked { ++stakedTokenAmount[msg.sender]; }
        ERC721.transferFrom(msg.sender, address(this), tokenId_);
    }

    function stakeBatch(uint256[] memory tokenIds_) external {
        for(uint256 i; i < tokenIds_.length;) {
            require(ERC721.ownerOf(tokenIds_[i]) == msg.sender, "Not Owner");
            stakedToken[tokenIds_[i]].lastStakedTime = uint256(block.timestamp);
            stakedToken[tokenIds_[i]].tokenOwner = msg.sender;
            unchecked { ++stakedTokenAmount[msg.sender]; ++i; }
        }
        multiTransferFrom(msg.sender, address(this), tokenIds_);
    }

    function unstake(uint256 tokenId_) external {
        require(stakedToken[uint256(tokenId_)].tokenOwner == msg.sender, "Not Owner");
        delete stakedToken[uint256(tokenId_)];
        unchecked { --stakedTokenAmount[msg.sender]; }
        ERC721.transferFrom(address(this), msg.sender, tokenId_);
    }

    function unstakeBatch(uint256[] memory tokenIds_) external {
        for(uint256 i; i < tokenIds_.length;) {
            require(stakedToken[tokenIds_[i]].tokenOwner == msg.sender, "Not Owner");
            delete stakedToken[tokenIds_[i]];
            unchecked {++i; --stakedTokenAmount[msg.sender]; }
        }
        multiTransferFrom(address(this), msg.sender, tokenIds_);
    }

    function ownerUnstake(uint256 tokenId_) external onlyOwner {
        delete stakedToken[uint256(tokenId_)];
        unchecked { --stakedTokenAmount[stakedToken[tokenId_].tokenOwner]; }
        ERC721.transferFrom(address(this), stakedToken[tokenId_].tokenOwner, tokenId_);
    }

    function ownerUnstakeBatch(uint256[] memory tokenIds_) external onlyOwner {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            uint256 tokenId_ = tokenIds_[i];
            require(stakedToken[tokenId_].tokenOwner != address(0), "Token not staked");
            address tokenOwner = stakedToken[tokenId_].tokenOwner;

            delete stakedToken[tokenId_];
            unchecked { --stakedTokenAmount[tokenOwner]; }
            ERC721.transferFrom(address(this), tokenOwner, tokenId_);
        }
    }

    function getUserStakedTokens(address user) public view returns (uint256[] memory) {
        uint256 stakedAmount = stakedTokenAmount[user];
        uint256[] memory stakedTokens = new uint256[](stakedAmount);
        uint256 counter = 0;
        for (uint256 i = 1; i < 1000; i++) { // 1000 is the total supply
            tokenInfo memory st = stakedToken[i];
            if (st.tokenOwner == user) {
                stakedTokens[counter] = i;
                counter++;
            }
        }
        return stakedTokens;
    }
}