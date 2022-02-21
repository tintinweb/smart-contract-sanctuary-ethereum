/**
 *Submitted for verification at Etherscan.io on 2022-02-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

/**
 * @dev ERC721 Standard Token interface
 */
interface ERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external returns (bool);
    function ownerOf(uint256 tokenId) external returns (address);
}

/**
 * @dev ERC20 Standard Token interface
 */
interface ERC20 {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
}

contract MetaBillionaireStaking {

    mapping(address => uint256[]) public depositedTokenIds;
    mapping(uint256 => uint256) public depositCheckpoint;
    mapping(address => uint256) public claimedAmounts;

    ERC721 public immutable nftToken;
    ERC20 public immutable rewardToken;
    uint256 public immutable stakingEnd;
    uint256 public immutable stakingStart;
    uint256 public immutable reward;
    uint256[] public rewardBoosts;

    /**
     * @dev Constructor.
     * @param _nftToken Address of ERC721 smart contract
     * @param _rewardToken Address of ERC20 smart contract
     * @param _stakingEnd Timestamp of end of staking
     * @param _reward Total token given to stakinEnd for nftToken
     */
    constructor(ERC721 _nftToken, ERC20 _rewardToken, uint256 _stakingEnd, uint256 _reward, uint256[] memory _rewardBoosts) {
        nftToken = _nftToken;
        rewardToken = _rewardToken;
        stakingEnd = _stakingEnd;
        stakingStart = block.timestamp;
        reward = _reward;
        rewardBoosts = _rewardBoosts;
    }

    /**
     * @dev Deposit `owner`.
     * @param owner of a deposit.
     * @return The number of tokens
     */
    function depositedTokenAmounts(address owner) public view returns(uint256) {
        return depositedTokenIds[owner].length;
    }

    /**
     * @dev Deposit `tokenId` and set checkpoint for this tokenId.
     * @param tokenId The token id.
     */
    function deposit(uint256 tokenId) external {
        require(msg.sender == nftToken.ownerOf(tokenId), "Deposit: Sender must be owner");
        nftToken.transferFrom(msg.sender, address(this), tokenId);
        depositCheckpoint[tokenId] = block.timestamp;
        depositedTokenIds[msg.sender].push(tokenId);
    }

    /**
     * @dev Returns the maximum number of tokens currently claimable by `owner`.
     * @param owner The account to check the claimable amounts of.
     * @return The number of tokens currently claimable.
     */
    function claimableAmounts(address owner) public view returns(uint256) {
        uint256 claimable = 0;
        uint256 depositedAmounts = depositedTokenAmounts(owner);

        for (uint256 i = 0; i < depositedAmounts; i++) {
            claimable += ((reward * (block.timestamp - depositCheckpoint[depositedTokenIds[owner][i]])) / stakingEnd);
        }

        return ((claimable * rewardBoost(depositedAmounts)) / 100) - claimedAmounts[owner];
    }

    /**
     * @dev Returns reward boost for token size.
     * @param tokenAmount The account to check the claimable amounts of.
     * @return The number of tokens currently claimable.
     */
    function rewardBoost(uint256 tokenAmount) public view returns(uint256) {
        if(tokenAmount > rewardBoosts.length){
            return rewardBoosts[rewardBoosts.length-1];
        } else {
            return rewardBoosts[tokenAmount-1];
        }
    }

    /**
     * @dev Claim claimable token earned.
     */
    function claim(address recipient) public {
        uint256 claimable = claimableAmounts(recipient);
        claimedAmounts[recipient] += claimable;
        require(rewardToken.transfer(recipient, claimable), "Claim: Transfer failed");
    }

    /**
     * @dev Withdraw tokenId.
     * @param tokenId The token id to withdraw.
     */
    function withdraw(uint256 tokenId) external {
        require(depositedTokenIds[msg.sender][tokenId] != 0, "Withdraw: No tokens to withdarw");
        claim(msg.sender);
        delete depositedTokenIds[msg.sender][tokenId];
        delete depositCheckpoint[tokenId];
        nftToken.transferFrom(address(this), msg.sender, tokenId);
    }
}