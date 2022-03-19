// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 Crypto Barter - All rights reserved
// cryptobarter.io
// @title RevenueClaim
// @notice Provides functions to claim reward with a merkle tree pattern.
// @author Anibal Catalan <[email protected]>

pragma solidity = 0.8.9;

import "./IERC721.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

//solhint-disable-line
contract RevenueClaim is ReentrancyGuard {

    bytes32 internal _root;
    uint32 constant private granularity = 1000000; 
    bool internal initialized;
    address internal _nft;
    address internal _rewardToken;
    uint64 internal _blockNumber;
    uint256 internal _revenue;
    
    
    mapping(uint256 => bool) internal _claimed;

    constructor() {}

    // Initializer
    function initialize(address nft_, address rewardToken_, uint256 revenue_, bytes32 root_, uint64 blockNumber_) external {   
        require(!initialized, "already initialized");
        require(root_[0] != 0, "empty root");
        require(rewardToken_ != address(0) && nft_ != address(0), "reward token should not be 0");
        require(revenue_ > 0 && blockNumber_ > 0, "should be greater than 0");
        require(IERC20(rewardToken_).balanceOf(address(this)) >= revenue_, "out of funds");
        _nft = nft_;
        _rewardToken = rewardToken_;
        _root = root_;
        _revenue = revenue_;
        _blockNumber = blockNumber_;
        initialized = !initialized;
    }

    // External Functions

    function claim(uint256 tokenId, uint256 reward, bytes32[] memory merkleProof) external virtual nonReentrant {  
        _isInitialized();
        require(IERC721(_nft).ownerOf(tokenId) == msg.sender, "your are not the owner of ERC721");
        require(!_claimed[tokenId], "reward alrready claimed");
        require(_verifyClaim(tokenId, reward, merkleProof), "merkle proof fail");
        uint256 amount = ( reward * _revenue ) / granularity;
        require(_transferToken(msg.sender, amount), "reward transfer fail");
        _claimed[tokenId] = true;
        emit Claimed(msg.sender, tokenId, amount);
    }

    // Getters

    function nft() external view returns (address) {
        _isInitialized();
        return _nft;
    }

    function rewardToken() external view returns (address) {
        _isInitialized();
        return _rewardToken;
    }

    function revenue() external view returns (uint256) {
        _isInitialized();
        return _revenue;
    }

    function root() external view returns (bytes32) {
        _isInitialized();
        return _root;
    }

    function blockNumber() external view returns (uint64) {
        _isInitialized();
        return _blockNumber;
    }

    function claimed(uint256 id) external view returns (bool) {
        _isInitialized();
        return _claimed[id];
    }

    // Internal Functions
    function _isInitialized() internal view virtual {
        require(initialized, "contract it is not initialized");
    }

    function _transferToken(address to, uint256 amount) internal virtual returns (bool) {
        require(to != address(0), "must be valid address");
        require(amount > 0, "you must send something");
        SafeERC20.safeTransfer(IERC20(_rewardToken), to, amount);
        return true;
    }

    function _verifyClaim(uint256 tokenId, uint256 reward, bytes32[] memory merkleProof) private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(tokenId, reward));
        return MerkleProof.verify(merkleProof, _root, leaf);
    }

    // Events

    event Claimed(address indexed claimer, uint256 indexed NFTId, uint256 indexed amount);

}