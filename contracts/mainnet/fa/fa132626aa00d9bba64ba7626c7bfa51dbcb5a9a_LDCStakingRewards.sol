// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";

contract LDCStakingRewards is IERC721Receiver {

    uint256 public constant ONE_DAY_IN_SECONDS = 86400;
    uint256 public LDCTokensPerDayStaked = 3e18;
    mapping(uint256 => stakingInfo) public nftStakes;
    mapping(address => uint256[]) public stakedNftsByAddress;
    address private owner;
    IERC20 public immutable LDCToken;
    IERC721 public immutable LDCNFT;
    bool public stakingEnabled;

    struct stakingInfo {
        address nftOwner;
        uint64 initTimestamp;
        uint128 rewardsClaimed;
    }

    event Staked(address user, uint256 NFTid);
    event Unstaked(address user, uint256 NFTid);
    event Claimed(address user, uint256 rewardAmount);

    constructor(address _LDCToken, address _LDCNFT) {
        /* 
            Once the contract is deployed, the owner of the LDCToken contract 
            must assign this contract (LDCStakingRewards) the MINTER_ROLE

            MINTER_ROLE is required so users can get their rewards through the claimRewards() function
        */
        owner = msg.sender;
        LDCToken = IERC20(_LDCToken);
        LDCNFT = IERC721(_LDCNFT); // https://etherscan.io/address/0xacc908bbcd7f50f2e07afaec5455b73aea1d4f7d#code
        stakingEnabled = true; // Staking will be enabled as soon as the contract is deployed
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        owner = newOwner;
    }

    /*
        @info Used to enable/disable the staking function
        If stakingEnabled users will not be able to stake their NFTs
        Current staked NFTs can still be claimed
    */
    function toggleStaking() external onlyOwner {
        stakingEnabled = !stakingEnabled;
    }

    /*
        @param newRewardsPerDay the new amount of LilDudeClub tokens that will be rewarded per day of stake
    */
    function updateRewardsPerDay(uint256 newRewardsPerDay) external onlyOwner {
        LDCTokensPerDayStaked = newRewardsPerDay;
    }

    /*
        @param NFTid the id of the LDC collection NFT

        @info In order to call this function msg.sender should ERC721.approve this contract address
        as the NFT will be transferred to this smart contract during the staking period
    */

    function stakeLDC(uint256 NFTid) external {
        require(stakingEnabled, "Staking is currently disabled");

        nftStakes[NFTid] = stakingInfo({
            nftOwner: msg.sender,
            initTimestamp: uint64(block.timestamp),
            rewardsClaimed: 0
        });

        stakedNftsByAddress[msg.sender].push(NFTid);

        // Transferring the NFT to this contract
        LDCNFT.safeTransferFrom(
            msg.sender,
            address(this),
            NFTid,
            bytes("stake")
        );

        emit Staked(msg.sender, NFTid);
    }

    /*
        @param NFTid array of ids of the LDC collection NFT

        @info Works the same way as stakeLDC() but allows to stake multiple NFTs at once
        In order to call this function msg.sender should ERC721.approve this contract address
        for each of the NFTs staked
    */
    function stakeMultipleLDC(uint256[] calldata NFTid) external {
        require(stakingEnabled, "Staking is currently disabled");
        
        uint256 len = NFTid.length;
        for (uint256 i; i < len; ++i) {
            nftStakes[NFTid[i]] = stakingInfo({
                nftOwner: msg.sender,
                initTimestamp: uint64(block.timestamp),
                rewardsClaimed: 0
            });

            stakedNftsByAddress[msg.sender].push(NFTid[i]);

            // Transferring the NFT to this contract
            LDCNFT.safeTransferFrom(
                msg.sender,
                address(this),
                NFTid[i],
                bytes("stake")
            );
            emit Staked(msg.sender, NFTid[i]);
        }
    }

    /*
        @param NFTid the id of the LDC collection NFT

        @info Claims the rewards and then unstake the NFTid
    */
    function unstakeLDC(uint256 NFTid) external {
        require(nftStakes[NFTid].nftOwner == msg.sender, "You do not own this NFT");
        
        // Claiming the rewards for this NFT
        uint256 totalDaysStaked = (block.timestamp - nftStakes[NFTid].initTimestamp) / ONE_DAY_IN_SECONDS;
        uint256 tokensToMintAndSend = uint128(totalDaysStaked * LDCTokensPerDayStaked);
        uint256 tokensAlreadyRewarded = uint128(nftStakes[NFTid].rewardsClaimed);
        uint256 finalReward = tokensToMintAndSend - tokensAlreadyRewarded;

        // Updating the stakedNftsByAddress array
        uint256 indexToRemove;
        uint256 arrayLength = stakedNftsByAddress[msg.sender].length;
        for (uint256 i; i < arrayLength; ++i) {
            if (stakedNftsByAddress[msg.sender][i] == NFTid){
                indexToRemove = i;
                break;
            }
        }
        
        if (indexToRemove != arrayLength - 1){
             // Moving the last element of the array to the position that we need to remove, then deleting the last position
            stakedNftsByAddress[msg.sender][indexToRemove] = stakedNftsByAddress[msg.sender][arrayLength - 1];
        }
        stakedNftsByAddress[msg.sender].pop();

        delete nftStakes[NFTid];

        // Transferring the reward tokens
        if (finalReward > 0){
            LDCToken.mint(msg.sender, finalReward);
        }

        // Giving the user back his previously staked NFT
        LDCNFT.safeTransferFrom(
            address(this),
            msg.sender,
            NFTid,
            bytes("unstake")
        );

        emit Unstaked(msg.sender, NFTid);
    }

    /*
        @param NFTid array of ids of the LDC collection NFT to unstake

        @info Claims the rewards and then unstakes the NTFs of the NFTid array
    */
    function unstakeMultipleLDC(uint256[] calldata NFTid) external {
        uint256 len = NFTid.length;
        uint256 totalDaysStaked;
        uint256 tokensToMintAndSend;
        uint256 tokensAlreadyRewarded;
        uint256 indexToRemove;
        uint256 arrayLength;
        for (uint256 i; i < len; ++i) {
            require(nftStakes[NFTid[i]].nftOwner == msg.sender, "You do not own this NFT");
            totalDaysStaked = (block.timestamp - nftStakes[NFTid[i]].initTimestamp) / ONE_DAY_IN_SECONDS;
            tokensToMintAndSend += uint128(totalDaysStaked * LDCTokensPerDayStaked);
            tokensAlreadyRewarded += uint128(nftStakes[NFTid[i]].rewardsClaimed);
            delete nftStakes[NFTid[i]];

            // Updating the stakedNftsByAddress array
            arrayLength = stakedNftsByAddress[msg.sender].length;
            for (uint256 j; j < arrayLength; ++j) {
                if (stakedNftsByAddress[msg.sender][j] == NFTid[i]){
                    indexToRemove = j;
                    break;
                }
            }
            if (indexToRemove != arrayLength - 1){
                // Moving the last element of the array to the position that we need to remove, then deleting the last position
                stakedNftsByAddress[msg.sender][indexToRemove] = stakedNftsByAddress[msg.sender][arrayLength - 1];
            }
            stakedNftsByAddress[msg.sender].pop();
        }

        // Transferring the reward tokens
        uint256 finalReward = tokensToMintAndSend - tokensAlreadyRewarded;
        if(finalReward > 0){
            LDCToken.mint(msg.sender, finalReward);
        }

        // Giving the user back his previously staked NFTs
        for (uint256 i; i < len; ++i) {
            LDCNFT.safeTransferFrom(
                address(this),
                msg.sender,
                NFTid[i],
                bytes("unstake")
            );
            emit Unstaked(msg.sender, NFTid[i]);
        }
    }

    /*
        @param NFTid the id of the LDC collection NFT that was previously staked
    */
    function claimRewards() external {
        uint256[] memory allStakedTokens = getCurrentStakedTokensByUser(msg.sender);
        uint256 len = allStakedTokens.length;
        require(len > 0, "No NFTs currently staked");
        uint128 tokensToMintAndSend;
        uint128 tokensAlreadyRewarded;
        uint256 totalDaysStaked;
        for (uint256 i; i < len; ++i) {
            totalDaysStaked = (block.timestamp - nftStakes[allStakedTokens[i]].initTimestamp) / ONE_DAY_IN_SECONDS;
            // 3 tokens per day and per NFT staked
            tokensToMintAndSend += uint128(totalDaysStaked * LDCTokensPerDayStaked);
            tokensAlreadyRewarded += uint128(nftStakes[allStakedTokens[i]].rewardsClaimed);
            nftStakes[allStakedTokens[i]].rewardsClaimed = uint128(totalDaysStaked * LDCTokensPerDayStaked);
        }

        uint256 finalReward = tokensToMintAndSend - tokensAlreadyRewarded;
        require(finalReward > 0, "No rewards available yet");
        LDCToken.mint(msg.sender, finalReward);
        emit Claimed(msg.sender, finalReward);
    }

    /*
        Number of NFTs currently staked in the contract
    */
    function getCurrentTotalStakedTokens() public view returns (uint256)
    {
        return LDCNFT.balanceOf(address(this));
    }

    /*
        Allows the users to check the token IDs they have currently staked in the contract
    */
    function getCurrentStakedTokensByUser(address user) public view returns (uint256[] memory)
    {
        return stakedNftsByAddress[user];
    }

    /*
        Allows the users to see their total pending rewards
    */
    function getPendingRewards(address user) public view returns (uint256)
    {
        uint256[] memory allStakedTokens = getCurrentStakedTokensByUser(user);
        uint256 len = allStakedTokens.length;
        require(len > 0, "No NFTs currently staked");
        uint128 tokensToMintAndSend;
        uint128 tokensAlreadyRewarded;
        uint256 totalDaysStaked;
        for (uint256 i; i < len; ++i) {
            totalDaysStaked = (block.timestamp - nftStakes[allStakedTokens[i]].initTimestamp) / ONE_DAY_IN_SECONDS;
            // 3 tokens per day and per NFT staked
            tokensToMintAndSend += uint128(totalDaysStaked * LDCTokensPerDayStaked);
            tokensAlreadyRewarded += uint128(nftStakes[allStakedTokens[i]].rewardsClaimed);
        }
        uint256 finalReward = tokensToMintAndSend - tokensAlreadyRewarded;
        return finalReward;
    }

    /*
        Allows the users to see their total pending rewards
    */
    function getPendingRewardsByNFT(uint256 NFTid) public view returns (uint256)
    {
        uint256 totalDaysStaked = (block.timestamp - nftStakes[NFTid].initTimestamp) / ONE_DAY_IN_SECONDS;
        uint256 tokensToMintAndSend = uint128(totalDaysStaked * LDCTokensPerDayStaked);
        uint256 tokensAlreadyRewarded = uint128(nftStakes[NFTid].rewardsClaimed);
        return tokensToMintAndSend - tokensAlreadyRewarded;
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}