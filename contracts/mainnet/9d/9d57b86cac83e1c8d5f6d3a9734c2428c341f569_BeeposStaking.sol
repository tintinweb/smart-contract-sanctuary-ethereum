// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./ERC721Holder.sol";
import "./Math.sol";
import "./EnumerableSet.sol";

contract BeeposStaking is Ownable, ERC721Holder, Pausable {

    using EnumerableSet for EnumerableSet.UintSet;
    IERC721 public nftContractInstance;
    IERC20 public tokenContractInstance;

    // Number of tokens per block. There are approx 6k blocks per day and 10 tokens are represented by 10**18 (after considering decimals).
    uint256 public rate;
	
    // Mapping of address to token numbers deposited
    mapping(address => EnumerableSet.UintSet) private _deposits;

    // Mapping of address -> token -> block number
    mapping(address => mapping(uint256 => uint256)) public _depositBlocks;

    constructor(address nftContractAddress, uint256 initialRate, address tokenAddress) {
        nftContractInstance = IERC721(nftContractAddress);
        rate = initialRate;
        tokenContractInstance = IERC20(tokenAddress);
    }
	
    function setAddresses(address nftContractAddress, address tokenAddress) public onlyOwner {
        nftContractInstance = IERC721(nftContractAddress);
        tokenContractInstance = IERC20(tokenAddress);
    }

    function setRate(uint256 newRate) public onlyOwner {
        rate = newRate;
    }
	
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function depositsOf(address owner) external view returns (uint256[] memory) {
        EnumerableSet.UintSet storage depositSet = _deposits[owner];
        uint256[] memory tokenIds = new uint256[](depositSet.length());

        for (uint256 i; i < depositSet.length(); i++) {
            tokenIds[i] = depositSet.at(i);
        }
        return tokenIds;
    }

    function hasDeposits(address owner, uint256[] memory tokenIds) external view returns (bool) {
        EnumerableSet.UintSet storage depositSet = _deposits[owner];
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (! depositSet.contains(tokenIds[i])) {
                return false;
            }
        }
        return true;
    }

    function hasDepositsOrOwns(address owner, uint256[] memory tokenIds) external view returns (bool) {
        EnumerableSet.UintSet storage depositSet = _deposits[owner];
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (! depositSet.contains(tokenIds[i]) && nftContractInstance.ownerOf(tokenIds[i]) != owner) {
                return false;
            }
        }

        return true;
    }

    function calculateRewards(address owner, uint256[] memory tokenIds) external view returns (uint256) {
        uint256 reward = 0;
        for (uint256 i; i < tokenIds.length; i++) {
            reward += calculateReward(owner, tokenIds[i]);
        }
        return reward;
    }

    function calculateReward(address owner, uint256 tokenId) public view returns (uint256) {
        require(block.number >= _depositBlocks[owner][tokenId], "Invalid block numbers");
        return rate * (_deposits[owner].contains(tokenId) ? 1 : 0) * (block.number - _depositBlocks[owner][tokenId]);
    }
	
    function claimRewards(uint256[] calldata tokenIds) public whenNotPaused {
        uint256 reward = 0;
        uint256 currentBlock = block.number;
        for (uint256 i; i < tokenIds.length; i++) {
            reward += calculateReward(msg.sender, tokenIds[i]);
            _depositBlocks[msg.sender][tokenIds[i]] = currentBlock;
        }
        if (reward > 0) 
		{
            tokenContractInstance.transfer(msg.sender, reward);
        }
    }

    function deposit(uint256[] calldata tokenIds) external whenNotPaused {
        require(msg.sender != address(nftContractInstance), "Invalid address");
        uint256 currentBlock = block.number;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            nftContractInstance.safeTransferFrom(msg.sender, address(this), tokenIds[i], "");
            _deposits[msg.sender].add(tokenIds[i]);
            _depositBlocks[msg.sender][tokenIds[i]] = currentBlock;
        }
    }
	
    function withdraw(uint256[] calldata tokenIds) external whenNotPaused {
        claimRewards(tokenIds);
        for (uint256 i; i < tokenIds.length; i++) {
            require(_deposits[msg.sender].contains(tokenIds[i]), "This token has not been deposited");
            _deposits[msg.sender].remove(tokenIds[i]);
            nftContractInstance.safeTransferFrom(address(this), msg.sender, tokenIds[i], "");
        }
    }
	
    function withdrawTokens(uint256 tokenAmount) external onlyOwner {
        tokenContractInstance.transfer(msg.sender, tokenAmount);
    }
}