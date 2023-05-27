/**
 *Submitted for verification at Etherscan.io on 2023-05-27
*/

// SPDX-License-Identifier: BLOBBY
pragma solidity >=0.7.5;
pragma abicoder v2;

contract REEE_LP_LOCK {
    address public blobby = msg.sender;
    address public nftContract = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    uint256 public lockUpEndTime;

    modifier onlyBlobby() {
        require(msg.sender == blobby);
        _;
    }

    function lockNFT(uint256 tokenId) external onlyBlobby {
        ERC721(nftContract).transferFrom(msg.sender, address(this), tokenId); // LP token ID is 514133
    }

    function beginTimedWithdrawal() external onlyBlobby {
        lockUpEndTime = block.timestamp + 180 days; 
    }

    function cancelWithdrawal() external onlyBlobby {
        require(lockUpEndTime != 0);
        lockUpEndTime = 0;
    }

    function withdrawNFT(uint256 tokenId) external onlyBlobby {
        require(lockUpEndTime != 0, "Withdrawal is not triggered");
        require(block.timestamp >= lockUpEndTime, "Lock-up period has not ended yet");

        ERC721(nftContract).transferFrom(address(this), msg.sender, tokenId); // LP token ID is 514133
        lockUpEndTime = 0;
    }

    function collectFees(uint256 tokenId) external onlyBlobby {
        UniswapManager(nftContract).collect(UniswapManager.CollectParams(tokenId, blobby, type(uint128).max, type(uint128).max));
    }

    function changeOwner(address newOwner) external onlyBlobby {
        require(newOwner != address(0));
        blobby = newOwner;
    }
}

interface ERC721 {
  function transferFrom(address from, address to, uint256 tokenId) external;
}

interface UniswapManager {
    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);
}