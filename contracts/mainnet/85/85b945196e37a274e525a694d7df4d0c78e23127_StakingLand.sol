// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/******************* Imports **********************/
import "./stakingGlobals.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./IOracle.sol";
import "./MerkleProof.sol";


/// @title A Staking Contract
/// @author NoBorderz
/// @notice This smart contract serves as a staking pool where users can stake and earn rewards from loot boxes 
contract StakingLand is  OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable, GlobalsAndUtils {
    using SafeMathUpgradeable for uint256;
    using StringsUpgradeable for uint256;

    receive() external payable {}

    // constructor(address _rewardingToken, address _oracle) {
    //     rewardsToken = IERC721(_rewardingToken);
    //     oracle = _oracle;
    // }

    function initialize() public virtual initializer {
		__Pausable_init();
		__Ownable_init();
        __ReentrancyGuard_init();
        latestCampaignId = 6;
         MIN_STAKE_DAYS = 14 days;
         EARLY_UNSTAKE_PENALTY = 18;
         STAKING_TOKEN_DECIMALS = 1e18;
         CLAIM_X_TICKET_DURATION = 2 days;
        MIN_STAKE_TOKENS = 100 * STAKING_TOKEN_DECIMALS;
        LAND_ADDRESS = address(0x932F97A8Fd6536d868f209B14E66d0d984fE1606);
        GENESIS_ADDRESS = address(0x5b5cf41d9EC08D101ffEEeeBdA411677582c9448);
		
	}

    function setClaimXTicketDuration() onlyOwner public {
        CLAIM_X_TICKET_DURATION = 5 minutes;
    }

    /**********************************************************/
    /******************* Public Methods ***********************/
    /**********************************************************/

    /**
     * @dev PUBLIC FACING: Open a stake.
     */
    function stakeLand(uint256 tokenId, uint256 size, string calldata rarity, uint256[] memory genesisTokenIds, bytes32[] calldata proof) whenNotPaused external payable nonReentrant CampaignOnGoing {
       require(size.mul(size) == genesisTokenIds.length, "invalid genesis tokens");
        require(isWhitelisted(rarity,size, tokenId, proof), "invalid land tokenId");
        require(msg.sender == tx.origin, "invalid sender");
        require(msg.sender == IERC721(LAND_ADDRESS).ownerOf(tokenId), "land is not in your ownership");
        _addStake(tokenId, size,rarity,genesisTokenIds);
        totalStakedAmount++;
        userStakedAmount[msg.sender]++;
        IERC721(LAND_ADDRESS).transferFrom(msg.sender,address(this), tokenId);
        escrowGenesisTokenIds(genesisTokenIds);
        emit StakeStart(msg.sender, latestStakeId, tokenId, genesisTokenIds);
    }

    /**
     * @dev PUBLIC FACING: Closes a stake.
     * @param _stakeId ID of the stake to close
     */
    function claimUnstake(uint256 _stakeId) whenNotPaused nonReentrant public {
        UnStake memory usrStake = unStakes[msg.sender][_stakeId];
        require(usrStake.tokenId > 0, "stake doesn't exist");
        require(usrStake.isAppliedFor, "already claim");

        _removeAppliedFor(_stakeId);

        bool isClaimable = _calcPayoutAndPenalty(usrStake);

           // Transfer payout amount to stake owner
        require(isClaimable, "can not claim");
        
        IERC721(usrStake.landCollection).transferFrom(address(this), msg.sender, usrStake.tokenId);
        returnGenesisTokenIds(usrStake.genesisTokenIds);
        
        emit StakeEnd(msg.sender, _stakeId, usrStake.tokenId, usrStake.genesisTokenIds);
    }
    /**
     * @dev EXTERNAL METHOD: Method for emergency unstake
     * and updating state accordingly
     */
     function appplyForUnstake(uint256 _stakeId)  whenNotPaused external {
         Stake memory usrStake = stakes[msg.sender][_stakeId];
        require(usrStake.tokenId > 0, "stake doesn't exist");
        _unStake(_stakeId);
        emit AppliedUnstake(msg.sender, _stakeId, usrStake.tokenId, unStakes[msg.sender][_stakeId].genesisTokenIds);
    }

   

    /**
     * @dev PUBLIC FACING: Returns an array of ids of user's active stakes
     * @param stakeOwner Address of the user to get the stake ids
     * @return Stake Ids
     */
    function getUserStakesIds(address stakeOwner) external view returns (uint256[] memory) {
        return userStakeIds[stakeOwner];
    }

    


    /**
     * @dev PUBLIC FACING: Returns an array of ids of user's active stakes
     * @param stakeOwner Address of the user to get the stake ids
     * @return unStake Ids
     */
    function getUserUnStakesIds(address stakeOwner) external view returns (uint256[] memory) {
        return userUnStakeIds[stakeOwner];
    }

    /**
     * @dev PUBLIC FACING: Returns information about a specific stake
     * @param stakeOwner Address of the stake owner
     * @param stakeId ID of the stake
     * @return User stake
     */
    function getUnStake(address stakeOwner, uint256 stakeId) external view returns(UnStake memory) {
         
        return unStakes[stakeOwner][stakeId];
    }

    

    /**
     * @dev PUBLIC FACING: Returns information about a specific stake
     * @param stakeOwner Address of the stake owner
     * @param stakeId ID of the stake
     * @return User stake
     */
    function getStake(address stakeOwner, uint256 stakeId) external view returns(Stake memory) {
        return stakes[stakeOwner][stakeId];
    }
/**
     * @dev PUBLIC FACING: is emergency or claim
     * @param stakeOwner Address of the stake owner
     * @param stakeId ID of the stake
     * @return User stake
     */
    function getIsClaimable(address stakeOwner, uint256 stakeId) external view returns(bool) {
        UnStake memory usrStake = unStakes[stakeOwner][stakeId];
        return _calcPayoutAndPenalty(usrStake);
    }
    
    
    /**
     * @dev PUBLIC FACING: Returns information about a specific stake
     * @param stakeOwner Address of the stake owner
     * @param stakeId ID of the stake
     * @return User stake
     * this function is public now to check but it should be internal 
     */
    function userClaimable(address stakeOwner, uint256 stakeId) public view returns(uint256) {
        Stake memory usrStake = stakes[stakeOwner][stakeId];
        uint256 stakedDays;
        if (
            campaigns[latestCampaignId].endTime == 0 ||
            // campaigns[latestCampaignId].endTime < block.timestamp ||
            campaigns[latestCampaignId].startTime > block.timestamp
        ) stakedDays = 0;
        else (, stakedDays) = _getUserStakedDays(usrStake);
       
        uint256 usrStakedAmount = usrStake.xTickets;
        uint256 claimableTickets = stakedDays.mul(usrStakedAmount);

        uint256 newTickets = totalUserXTickets[stakeOwner][latestCampaignId] == 0 ? claimableTickets : 0;
        return newTickets;
    }

    /**
     * @dev PUBLIC FACING: Users can claim their
     * xtickets after staking for more than 24 hours
     * pausing contract
     */
    function pause() public onlyOwner {
        _pause();
    }
 /**
     * @dev PUBLIC FACING: Users can claim their
     * unpausing contract
     * 
     */
    function unpaused() public onlyOwner {
        _unpause();
    }

    /**
     * @dev PUBLIC FACING: Users can claim their
     * xtickets after staking for more than 24 hours
     * @return newClaimedTickets
     */
    function joinRuffle() whenNotPaused external ClaimXTicketAllowed returns (uint256 newClaimedTickets) {
        require(campaigns[latestCampaignId].endTime < block.timestamp && campaigns[latestCampaignId].endTime != 0, "can't claim");
        require( totalUserXTickets[msg.sender][latestCampaignId] == 0, "already claimed");
         userXTicketRange[msg.sender][latestCampaignId].start = totalClaimableTickets + 1;
         XTicketRange storage tempRange = userXTicketRange[msg.sender][latestCampaignId];
        newClaimedTickets = 0;
        for (uint256 x=0; x < userStakeIds[msg.sender].length; x++) {
            newClaimedTickets += _getClaimableXTickets(msg.sender, userStakeIds[msg.sender][x]);
        }
         userXTicketRange[msg.sender][latestCampaignId].end = totalClaimableTickets;
         require(tempRange.start <= totalClaimableTickets, "no tickets earned");
         emit RuffleJoined(msg.sender, latestCampaignId, tempRange.start, totalClaimableTickets);

    }

     /**
     * @dev INTERNAL METHOD: Update number of
     * claimable tickets a user currently has
     * and add it to the total claimable tickets
     * @param _stakeOwner Address of owner of the stake
     * @param _stakeId Id of the stake
     * @return Number of tickets claimed against stake
     */
    function _getClaimableXTicketsView(address _stakeOwner, uint256 _stakeId) private view returns(uint256) {
        Stake memory usrStake = stakes[_stakeOwner][_stakeId];
        uint256 usrStakedAmount = usrStake.xTickets;
        return usrStakedAmount;
    }

      /**
     * @dev PUBLIC FACING: Users can claim their
     * xtickets after staking for more than 24 hours
     * @return newClaimedTickets
     */
    function perDayXTicketsUserClaimable() public view  returns (uint256 newClaimedTickets) {
        newClaimedTickets = 0;
        for (uint256 x=0; x < userStakeIds[msg.sender].length; x++) {
            newClaimedTickets += _getClaimableXTicketsView(msg.sender, userStakeIds[msg.sender][x]);
        }
        
    }

    /**
     * @dev PUBLIC FACING: Users can claim their rewards (if any)
     */
    function claimStakingReward(uint256 campaignId, uint256 limit, bytes32[] calldata proof) whenNotPaused  external {
        require(rewardsReceived[msg.sender][campaignId] == 0, "already claimed");
        require(isRewardOpen[campaignId], "reward not open");
        require(limit > 0, "no reward");
        require(isUserWinner(limit, campaignId, proof),"not authorize");
        _rewardWinner(msg.sender,campaignId, limit);
    }

    /**
     * @dev PUBLIC FACING: Array of users that have active stakes
     * @return activeStakeOwners
     */
    function getActiveStakers() external view returns(address[] memory) {
        return activeStakeOwners;
    }

    /**
     * @dev PUBLIC FACING: Get details of the current campaign
     * @return campaignId
     * @return rewardCount
     * @return startTime
     * @return endTime
     */
    function getCurrentCampaignDetails() external view returns(uint256 campaignId, uint256 rewardCount, uint256 startTime, uint256 endTime,  uint256 ruffleTime) {
        campaignId = latestCampaignId;
        rewardCount = campaigns[latestCampaignId].rewardCount;
        startTime = campaigns[latestCampaignId].startTime;
        endTime = campaigns[latestCampaignId].endTime;
        ruffleTime = CLAIM_X_TICKET_DURATION;
    }

    function getCampaignDetails(uint256 _campaignId) external view returns(uint256 rewardCount, uint256 startTime, uint256 endTime, address collection) {
        rewardCount = campaigns[_campaignId].rewardCount;
        startTime = campaigns[_campaignId].startTime;
        endTime = campaigns[_campaignId].endTime;
        collection = campaigns[_campaignId].collection;
    }

    /**
     * @dev PUBLIC FACING: Get number of claimed tickets by a user
     * @return newClaimedTickets
     */
    function getClaimableTickets() external view returns(uint256 newClaimedTickets) {
          newClaimedTickets = 0;
        if( totalUserXTickets[msg.sender][latestCampaignId] > 0){
            newClaimedTickets =  0;
        }else {
            uint256 length = userStakeIds[msg.sender].length;
            uint256[] memory idsArray = userStakeIds[msg.sender];
            for (uint256 x=0; x < length; x++) {
            newClaimedTickets += userClaimable(msg.sender, idsArray[x]);
        }
        }
        
    }

    function getGlobals() public view returns(uint256, uint256){
           return (MIN_STAKE_DAYS, CLAIM_X_TICKET_DURATION);
    }

    
    /**
     * @dev PUBLIC METHOD: Method to get a nftID
     * from a collection
     */
    function getRewardClaimable(uint256 campaignId) public view  returns(uint256[] memory, uint256, uint256, uint256, uint256, uint256) {
        return (getXTicektedIDs(campaignId), campaigns[campaignId].rewardCount, campaigns[campaignId].startTime, campaigns[campaignId].endTime, rewardsReceived[msg.sender][campaignId], totalUserXTickets[msg.sender][campaignId]);
    }

    /**
     * @dev INTERNAL METHOD: Method to get a nftID
     * from a collection
     * @return stakerPenaltyBonus
     */
    function getWinningTickIds(uint256 campaignId) public view returns(uint256[] memory) {
        return winningTicketIds[campaignId];
    }

    function isWhitelisted(string memory rarity,  uint256 size, uint256 tokenId,bytes32[] calldata proof) public view returns (bool) {
        return _verify(_leaf(tokenId, rarity, size), proof, landRootHash);
    }
    function _leaf(uint256 tokenId, string memory rarity, uint256 size) public pure returns (bytes32) {
        return keccak256(abi.encode(tokenId, rarity, size));
    }
    function _verify(bytes32 leaf,bytes32[] memory proof,bytes32 root) internal pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    /**********************************************************/
    /******************* Admin Methods ************************/
    /**********************************************************/

    /**
     * @dev ADMIN METHOD: Start a campaign.
     * @param startTime Time at which the campaign will start
     * @param endTime Time at which the campaign will end
     * @param rewardCount Total number of rewards in the campaign
     */
    function startLootBox(uint256 startTime, uint256 endTime, uint256 rewardCount, address _awardCollection) external onlyOwner campaignEnded {
        require(startTime >= block.timestamp, "start cannot be in past");
        require(startTime < endTime, "cannot end before start");

        rewardsToken = IERC721(_awardCollection);

        // end cooldown period
        totalClaimableTickets = 0;

        // start a new campaign
        latestCampaignId += 1;
        campaigns[latestCampaignId] = Campaign(rewardCount, startTime, endTime, _awardCollection);

        emit CampaignStarted(rewardCount, startTime, endTime);
    }

    /**
     * @dev ADMIN METHOD: Start a campaign.
     * @param startTime Time at which the campaign will start
     * @param endTime Time at which the campaign will end
     */
    function editLootBox(uint256 startTime, uint256 endTime) external onlyOwner {        
        campaigns[latestCampaignId].startTime = startTime;
        campaigns[latestCampaignId].endTime = endTime;

        emit CampaignEdited(startTime, endTime);
    }

    function setRewardCanBeClaim(uint256 campaignId, bool status) onlyOwner public {
        require(campaignRewardsRoot[campaignId] != bytes32(0x0), "reward not distributed");
        isRewardOpen[campaignId] = status;
    }

    function setCampaignWinners(uint256 campaignId, bytes32 _root) onlyOwner public {
        campaignRewardsRoot[campaignId] = _root;
    }

    /**
     * @dev ADMIN METHOD: Pick winners from who have xtickets
     */
    function rewardLootBox(uint256 end, uint256 campaignId) external onlyOwner  {
        require(winningTicketIds[campaignId].length + end <= campaigns[campaignId].rewardCount, "exceeded reward limit");
        string memory api = campaignId.toString();
        string memory params = end.toString();
        IOracle(oracle).createRequest(api, params, address(this), "callback(uint256[],uint256)");
        
    }

    function callback(uint256[] memory ids, uint256 campaignId)onlyOracle public {
        require(winningTicketIds[campaignId].length + ids.length <= campaigns[campaignId].rewardCount, "exceeded reward limit");

        for(uint256 i = 0; i<ids.length; i++){
             winningTicketIds[campaignId].push(ids[i]);
            winningTixketIdExist[campaignId][ids[i]] = true;
        }
    }

    function setOracleAddress(address _add) onlyOwner public {
        oracle = _add;
    }

    function setLandRoot(bytes32 _root) onlyOwner external {
        landRootHash = _root;
    }

     function setTickEraned(string calldata rarity, uint256 size, uint256 amount) onlyOwner external {
       XticketEarnPerDay[rarity][size] = amount;
    }



    /**
     * @dev ADMIN METHOD: Add collections to a campaign
     * @param _collection Array of collections to add to the campaign
     */
    function updateRewardCollection(address _collection, uint256 campaignId) external onlyOwner {
        require(_collection != address(0), "invalid collection address");
        campaigns[campaignId].collection = _collection;
        rewardsToken = IERC721(campaigns[campaignId].collection);
    }


    /**
     * @dev ADMIN METHOD: Withdraw total tokens in contract
     * @param receiver Address of the user to transfer the nft to
     */
    function emergencyWithdraw(address receiver) external onlyOwner {
        require(receiver != address(0), "invalid address");

        (bool success, ) = receiver.call{value: address(this).balance}("");
        require(success, "couldn't transfer tokens");
    }

    /**
     * @dev ADMIN METHOD: Start a campaign.
     * @param rewardCount Total number of rewards in the campaign
     */
    function startLootBox(uint256 rewardCount) external onlyOwner campaignEnded {
       
        Campaign storage temp = campaigns[latestCampaignId + 1];
        // require(temp.startTime >= block.timestamp, "start cannot be in past");
        require(temp.startTime < temp.endTime, "cannot end before start");

        rewardsToken = IERC721(temp.collection);
        // start a new campaign
        latestCampaignId += 1;
        
        // end cooldown period


        totalClaimableTickets = 0;

        
        campaigns[latestCampaignId].rewardCount = rewardCount;

        emit CampaignStarted(rewardCount, temp.startTime, temp.endTime);
    }

    function setCampaignDetails(uint256 campaignId, uint256 rewardCount, uint256 startTime, uint256 endTime, address collection) external onlyOwner {
        require(startTime < endTime, "cannot end before start");
        campaigns[campaignId] = Campaign(rewardCount, startTime, endTime, collection);
    }

    
    /**********************************************************/
    /******************* Private Methods **********************/
    /**********************************************************/

   

    /**
     * @dev INTERNAL METHOD: Method for starting stake
     * and updating state accordingly
     * @param tokenId Amount of tokens staked
     */
    function _addStake(uint256 tokenId, uint256 size, string memory rarity, uint256[] memory genesisTokenIds) private {
        latestStakeId += 1;
        stakes[msg.sender][latestStakeId] = Stake(block.timestamp, tokenId, LAND_ADDRESS, genesisTokenIds, size, rarity, XticketEarnPerDay[rarity][size]);
        userStakeIds[msg.sender].push(latestStakeId);

        // update index of user address in activeStakeOwners to stakeOwnerIndex
        if (activeStakeOwners.length == 0) {
            activeStakeOwners.push(msg.sender);
            stakeOwnerIndex[msg.sender] = 0;
        } else if (activeStakeOwners.length > 0 && activeStakeOwners[stakeOwnerIndex[msg.sender]] != msg.sender) {
            activeStakeOwners.push(msg.sender);
            stakeOwnerIndex[msg.sender] = activeStakeOwners.length - 1;
        }
    }

    /**
     * @dev INTERNAL METHOD: Method for starting stake
     * and updating state accordingly
     * @param genesisTokenIds Amount of tokens staked
     */
    function escrowGenesisTokenIds(uint256[] memory genesisTokenIds) private {
        uint256 tokenId;
        for (uint256 index = 0; index < genesisTokenIds.length; index++) {
            tokenId = genesisTokenIds[index];
            IERC721(GENESIS_ADDRESS).transferFrom(msg.sender, address(this), tokenId);
        }
        
    }

    /**
     * @dev INTERNAL METHOD: Method for starting stake
     * and updating state accordingly
     * @param genesisTokenIds Amount of tokens staked
     */
    function returnGenesisTokenIds(uint256[] memory genesisTokenIds) private {
        uint256 tokenId;
        for (uint256 index = 0; index < genesisTokenIds.length; index++) {
            tokenId = genesisTokenIds[index];
            IERC721(GENESIS_ADDRESS).transferFrom(address(this), msg.sender, tokenId);
        }
        
    }

    /**
     * @dev INTERNAL METHOD: Method for ending stake
     * and updating state accordingly
     * @param _stakeId ID of the stake to unstake
     */
    function _unStake(uint256 _stakeId) private {
        // Remove stake id from users' stakIdArray
        if (userStakeIds[msg.sender].length > 1) {
            for (uint256 x = 0; x < userStakeIds[msg.sender].length; x++) {
                // find the index of stake id in userStakes
                if (userStakeIds[msg.sender][x] == _stakeId) {
                    if (userStakeIds[msg.sender].length > 1) {
                        userStakeIds[msg.sender][x] = userStakeIds[msg.sender][userStakeIds[msg.sender].length.sub(1)];
                        userStakeIds[msg.sender].pop();
                    } else {
                        userStakeIds[msg.sender].pop();
                    }
                }
            }
        } else {
            userStakeIds[msg.sender].pop();
        }

        // Remove address from current stake owner's array number if stakes are zero
        if (userStakeIds[msg.sender].length == 0) {
            if (activeStakeOwners.length > 1) {
                // replace address to be removed by last address to decrease array size
                activeStakeOwners[stakeOwnerIndex[msg.sender]] = activeStakeOwners[activeStakeOwners.length.sub(1)];

                // set the index of replaced address in the stakeOwnerIndex mapping to the removed index
                stakeOwnerIndex[activeStakeOwners[activeStakeOwners.length.sub(1)]] = stakeOwnerIndex[msg.sender];

                // remove address from last index
                activeStakeOwners.pop();
            } else {
                // set the index of replaced address in the stakeOwnerIndex mapping to the removed index
                stakeOwnerIndex[activeStakeOwners[activeStakeOwners.length.sub(1)]] = stakeOwnerIndex[msg.sender];

                // remove address from last index
                activeStakeOwners.pop();
            }

            // set the index of removed address to zero
            stakeOwnerIndex[msg.sender] = 0;
        }

        // remove staked amount from total staked amount
        totalStakedAmount--;

        userUnStakeIds[msg.sender].push(_stakeId);

        userStakedAmount[msg.sender]--; 

        unStakes[msg.sender][_stakeId] = UnStake(stakes[msg.sender][_stakeId].stakedAt, block.timestamp,0,stakes[msg.sender][_stakeId].tokenId,LAND_ADDRESS,stakes[msg.sender][_stakeId].genesisTokenIds,stakes[msg.sender][_stakeId].size,stakes[msg.sender][_stakeId].rarity,stakes[msg.sender][_stakeId].xTickets, true);

        // Remove user's stake values
        delete stakes[msg.sender][_stakeId];
    }

     /**
     * @dev INTERNAL METHOD: Method for ending stake
     * and updating state accordingly
     * @param _stakeId ID of the stake to unstake
     */
    function _removeAppliedFor(uint256 _stakeId) private {
        // Remove stake id from users' stakIdArray
       

        unStakes[msg.sender][_stakeId].isAppliedFor = false;
        unStakes[msg.sender][_stakeId].unStakedAt = block.timestamp;

        // Remove user's stake values
        // delete stakes[msg.sender][_stakeId];
    }

    /**
     * @dev INTERNAL METHOD: Return staked time of
     * a user in unix timestamp and days
     * @param usrStake Instance of stake to get time of
     */
    function _getUserStakedTime(UnStake memory usrStake) private view returns (uint256 unixStakedTime) {
        unixStakedTime =  block.timestamp.sub(usrStake.appliedAt);
    }

     /**
     * @dev INTERNAL METHOD: Return staked time of
     * a user in unix timestamp and days
     * @param usrStake Instance of stake to get time of
     */
    function _getUserStakedDays(Stake memory usrStake) private view returns (uint256 unixStakedTime, uint256 stakedDays) {
        uint256 stakedTime = usrStake.stakedAt;
        uint256 nowTime = block.timestamp;
        Campaign storage tempCampaign = campaigns[latestCampaignId];
        if( nowTime > tempCampaign.startTime && tempCampaign.startTime > usrStake.stakedAt)
        {
            stakedTime = tempCampaign.startTime;
        }
        if(stakedTime < tempCampaign.endTime && block.timestamp > tempCampaign.endTime &&  tempCampaign.endTime != 0){
            nowTime  = tempCampaign.endTime;
        }
        unixStakedTime = nowTime.sub(stakedTime);
        stakedDays = unixStakedTime.div(1 days);
    }

    /**
     * @dev INTERNAL METHOD: Update number of
     * claimable tickets a user currently has
     * and add it to the total claimable tickets
     * @param _stakeOwner Address of owner of the stake
     * @param _stakeId Id of the stake
     * @return Number of tickets claimed against stake
     */
    function _getClaimableXTickets(address _stakeOwner, uint256 _stakeId) private returns(uint256) {
        Stake memory usrStake = stakes[_stakeOwner][_stakeId];
        uint256 stakedDays;
        if (
            campaigns[latestCampaignId].endTime == 0 ||
            // campaigns[latestCampaignId].endTime < block.timestamp ||
            campaigns[latestCampaignId].startTime > block.timestamp
        ) stakedDays = 0;
        else (, stakedDays) = _getUserStakedDays(usrStake);
        
        uint256 usrStakedAmount = usrStake.xTickets;
        uint256 claimableTickets = stakedDays.mul(usrStakedAmount);

        // update total number of claimable tickets
        totalClaimableTickets += claimableTickets;

        totalUserXTickets[msg.sender][latestCampaignId] = totalUserXTickets[msg.sender][latestCampaignId] + claimableTickets;

        return claimableTickets;
    }

    /**
     * @dev INTERNAL METHOD: Calculate payout and penalty
     * @param usrStake Instance of stake to calculate payout and penalty of
     * @return isClaimAble
     */
    function _calcPayoutAndPenalty(UnStake memory usrStake) private view returns(bool isClaimAble) {
        (uint256 unixStakedTime) = _getUserStakedTime(usrStake);

        if (unixStakedTime >= MIN_STAKE_DAYS) {
            isClaimAble = true;
        } else {
            isClaimAble = false;
        }
    }  

    /**
     * @dev INTERNAL METHOD: Calculate penalty if
     * user unstakes before min stake period
     * @param _totalAmount total staked amount
     * @return payout
     */
    function _calcPenalty(uint256 _totalAmount) private view returns(uint256 payout) {
        return _totalAmount.mul(EARLY_UNSTAKE_PENALTY).div(100);
    }

    /**
     * @dev INTERNAL METHOD: Method to reward winner nfts
     * @param _winnerAddress address of the winner to transfer nfts to
     */
    function _rewardWinner(address _winnerAddress, uint256 campaignId, uint256 limit) private {
        
        rewardsReceived[_winnerAddress][campaignId] += limit;
        rewardsToken = IERC721(campaigns[campaignId].collection);
        (uint256 from, uint256 to) = rewardsToken.mint(msg.sender,  rewardsReceived[_winnerAddress][campaignId]);
        if (from == 0 || to == 0) revert("couldn't mint");
        emit CampaignReward(campaignId, address(rewardsToken), from, to, msg.sender);
    }    

    function isUserWinner(uint256 limit,uint256 campaignId, bytes32[] calldata proof) public view returns (bool) {
        return _verify(_leafWinner(limit, msg.sender), proof, campaignRewardsRoot[campaignId]);
    }
    function _leafWinner(uint256 limit, address user) public pure returns (bytes32) {
        return keccak256(abi.encode(user, limit));
    }
    /**
     * @dev INTERNAL METHOD: Method to get a nftID
     * from a collection
     * @return userXticketsIds
     */
    function getXTicektedIDs(uint256 campaignId) private view  returns(uint256[] memory) {
        if(rewardsReceived[msg.sender][campaignId] > 0){
            uint256[] memory tempArray;
            return tempArray;
        }
         uint256 rangeStart = userXTicketRange[msg.sender][campaignId].start;
       uint256 rangeEnd =  userXTicketRange[msg.sender][campaignId].end;
       uint256[] memory _winningTicketIds = winningTicketIds[campaignId];
       uint256 count;
        for (uint256 j; j < _winningTicketIds.length; j++) {
            uint256 winningTicketId = _winningTicketIds[j];
           if(winningTicketId >= rangeStart && winningTicketId <= rangeEnd){
                count++;
           }
        }
        uint256 i;
        uint256[] memory _userXticketsIds = new uint256[](count);
        for (uint256 j; j < _winningTicketIds.length; j++) {
            uint256 winningTicketId = _winningTicketIds[j];
           if(winningTicketId >= rangeStart && winningTicketId <= rangeEnd){
                _userXticketsIds[i] = winningTicketId;
                i++;
           }
        }
        return _userXticketsIds;
    }

    

   

    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/******************* Imports **********************/
import "./IERC721Mintable.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

/// @author NoBorderz
/// @notice Globals and utilities for staking contract
abstract contract GlobalsAndUtils {
    

    /******************* Events **********************/
    event StakeStart(address staker, uint256 stakeIndex, uint256 tokenId, uint256[] geneTokenIds);
    event StakeEnd(address staker, uint256 stakeIndex, uint256 tokenId, uint256[] geneTokenIds);
    event AppliedUnstake(address staker, uint256 stakeIndex, uint256 tokenId, uint256[] geneTokenIds);
    event CampaignStarted(uint256 rewardCount, uint256 startTime, uint256 endTime);
    event CampaignEdited(uint256 startTime, uint256 endTime);
    event CampaignReward(uint256 campaignId, address collection, uint256 from, uint256 to, address user);
    event RuffleJoined(address user, uint256 campaignId, uint256 start, uint256 end);

    /******************* Modifiers **********************/
    modifier campaignEnded() {
        if (latestCampaignId > 0) {
            Campaign storage campaign = campaigns[latestCampaignId];
            require(campaign.endTime <= block.timestamp, "Campaign not ended yet");
        }
        _;
    }

    modifier CampaignOnGoing() {
        require(latestCampaignId > 0, "Campaign not initalized");
        Campaign memory campaign = campaigns[latestCampaignId];
        require(campaign.startTime <= block.timestamp, "campign not started");
        require(campaign.endTime > block.timestamp, "campign has ended");
        _;
    }

    modifier ClaimXTicketAllowed() {
        require(latestCampaignId > 0, "Campaign not initalized");
        Campaign memory campaign = campaigns[latestCampaignId];

        require(campaign.endTime + CLAIM_X_TICKET_DURATION >= block.timestamp, "claim ticket time ended");
        _;
    }
   

    modifier CalculateRewardAllowed() {
        require(latestCampaignId > 0, "Campaign not initalized");
        Campaign memory campaign = campaigns[latestCampaignId];

        require(campaign.endTime + CLAIM_X_TICKET_DURATION < block.timestamp, "claim x duration");
        _;
    }



    modifier onlyOracle() {
        require(msg.sender == oracle, "not allowed");
        _;
    }

    /******************* State Variables **********************/
    uint256 internal  MIN_STAKE_DAYS;
    uint256 internal  EARLY_UNSTAKE_PENALTY;
    uint256 internal  STAKING_TOKEN_DECIMALS;
    uint256 internal  CLAIM_X_TICKET_DURATION;
    uint256 internal  MIN_STAKE_TOKENS;
    address internal  LAND_ADDRESS;
    address internal  GENESIS_ADDRESS;

   

    /// @notice This struct stores information regarding campaigns
    struct Campaign {
        uint256 rewardCount;
        uint256 startTime;
        uint256 endTime;
        address collection;
    }

    /// @notice Array to store campaigns.
    mapping(uint256 => Campaign) internal campaigns;

    /// @notice Stores the ID of the latest campaign
    uint256 internal latestCampaignId;

    /// @notice Stores the current total number of claimable xtickets.
    uint256 internal totalClaimableTickets;

    /// @notice Mapping to store current total claimable tickets for a user
    mapping(address => mapping(uint256 => uint256)) internal totalUserXTickets;

    /// @notice Stores the Id of the latest stake.
    uint256 internal latestStakeId;

    /// @notice This struct stores information regarding a user stakes
    struct Stake {
        uint256 stakedAt;
        uint256 tokenId;
        address landCollection;
        uint256[] genesisTokenIds;
        uint256 size;
        string  rarity;
        uint256 xTickets;
    }

    /// @notice Mapping to store user stakes.
    mapping(address => mapping(uint256 => Stake)) internal stakes;

    /// @notice Array to store users with active stakes
    address[] internal activeStakeOwners;

    /// @notice Mapping to store user stake ids in array
    mapping(address => uint256[]) internal userStakeIds;

    /// @notice This struct stores information regarding a user unstakes
    struct UnStake {
        uint256 stakedAt;
        uint256 appliedAt;
        uint256 unStakedAt;
        uint256 tokenId;
        address landCollection;
        uint256[] genesisTokenIds;
        uint256 size;
        string  rarity;
        uint256 xTickets;
        bool isAppliedFor;
    }

    /// @notice Mapping to store user unstakes.
    mapping(address => mapping(uint256 => UnStake)) internal unStakes;

     /// @notice Mapping to store user unstake ids in array
    mapping(address => uint256[]) internal userUnStakeIds;


    /// @notice Mapping to store index of owner address in activeStakeOwners array
    mapping(address => uint256) internal stakeOwnerIndex;

    /// @notice Mapping to nftsIds user was awarded against a collection
    mapping(address => mapping(address => uint256[])) internal claimableAwards;

    /// @notice Mapping to store total number of awards received by a user
    mapping(address => mapping(uint256 => uint256)) internal rewardsReceived;

    /// @notice ERC721 Token for awarding users NFTs
    IERC721 internal rewardsToken;

    /// @notice array of winning tickets ids against campaing id
    mapping(uint256 => uint256[]) internal winningTicketIds;

    struct XTicketRange {
        uint256 start;
        uint256 end;
    }

    /// @notice mapping for xticket range for each user
    mapping(address => mapping(uint256 => XTicketRange)) public userXTicketRange;

     /// @notice Variable to store total amount currently staked in the contract
    uint256 public totalStakedAmount;

    /// @notice Mapping to store total amount staked of a user
    mapping(address => uint256) public userStakedAmount;

    /// @notice Variable to store total amount currently staked in the contract
    uint256 public totalStakedNFT;

    /// @notice Mapping to store total amount staked of a user
    mapping(address => uint256) public userStakedAmountNFT;


    /// @notice Mapping campaign id, ticket id
    mapping(uint256 => mapping (uint256=>bool)) public ticketIdUsed;

    /// @notice Mapping campaign id, ticket id
    mapping(uint256 => mapping (uint256=>bool)) public winningTixketIdExist;

    address internal oracle;

    uint256 public isRequested;

    mapping(uint256 => bool) public isRewardOpen;

    bytes32 internal landRootHash;

    mapping(string => mapping(uint256 => uint256 )) XticketEarnPerDay;

    mapping (uint256=> bytes32) public campaignRewardsRoot;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOracle {
    function createRequest (
    string memory _urlToQuery,
    string memory _attributeToFetch,
    address callbackAddress,
    string memory sign
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

library MerkleProof {
    
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeMint(address to) external;

    function mint(address to, uint256 size) external returns(uint256 f, uint256 t);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}