// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@hyfi-corp/vault/contracts/interfaces/IHYFI_Vault.sol";
import "./interfaces/IHYFI_RewardsManager.sol";

// solhint-disable-next-line contract-name-camelcase
contract HYFI_Lottery is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    struct RewardsData {
        uint256 totalAmount;
        uint256 freeAmount;
        IHYFI_RewardsManager rewardManager;
    }

    struct RewardsSetData {
        uint256 rangeMin;
        uint256 rangeMax;
        uint256[] rewards;
    }

    struct GuaranteedRewardsSetData {
        uint256 rangeMin;
        uint256 rangeMax;
        uint256[] rewards;
    }

    /// @dev PAUSER_ROLE role identifier, PAUSER_ROLE is responsible to pause/unpause Lottery
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @dev max number from all ranges in rewards set, starts from 0
    uint256 internal _rangeMax;

    /// @dev max number from all ranges in guaranteed rewards set, starts from 0
    uint256 internal _guaranteedRangeMax;

    /// @dev the number of Vaults which should be opened at once to have Guaranteed rewards sets
    uint256 internal _guaranteedThreshold;

    /// @dev Vault smart contract (lottery tickets nfts)
    IHYFI_Vault internal _vault;

    /**
     * @dev the array with information about each reward using struct RewardsData
     *
     *      totalAmount - total amount of specific reward
     *      freeAmount - the remaining available amount of rewards
     *      rewardManager is smart contract responsible for revealing specific reward, follow interface IHYFI_RewardsManager
     */
    RewardsData[] internal _rewards;

    /**
     * @dev the array with information about each rewards set using struct RewardsSetData
     *
     *      rangeMin-rangeMax - is a range that the random number should fall into.
     *      rewards - array of rewards ids if the current set is in play
     *      so the structure in hyfi will be:
     *      0 => {0, 1, 20_000, 20_000, [1, 0, 1, 0, 0, 0, 0]}
     *          0,1 - range (20% probability),
     *          amount 20_000,
     *          rewards: [1, 0, 1, 0, 0, 0, 0] mean 1*Athena + 1*Pro + 0 other rewards
     *      1 => {2, 3, 20_000, 20_000, [1, 0, 1, 0, 0, 0, 0]}
     *          2,3 - range (20% probability),
     *          amount 20_000,
     *          rewards: [0, 1, 0, 1, 0, 0, 0] mean 1*AthenaAccess + 1*Ultimate + 0 other rewards
     *      2 => {4, 6, 30_000, 20_000, [1, 0, 1, 0, 0, 0, 0]}
     *          4,6 - range (30% probability),
     *          amount 30_000,
     *          rewards: [0, 1, 1, 0, 1, 0, 1] mean 1*AthenaAccess + 1*Pro + 1*HYFI50 + Voucher
     *      3 => {4, 6, 30_000, 20_000, [1, 0, 1, 0, 0, 0, 0]}
     *          7,9 - range (30% probability),
     *          amount 30_000,
     *          rewards: [0, 1, 1, 0, 0, 1, 1] mean 1*AthenaAccess + 1*Pro + 1*HYFI100 + Voucher
     */
    RewardsSetData[] internal _rewardsSets;

    /**
     * @dev the array with information about each guaranteed rewards sets using struct GuaranteedRewardsSetData
     *
     *      rangeMin-rangeMax (reflection of Probability to win this set)- is a range that the random number should fall into.
     *      example HYFI guaranteed rewards are A + UM + 4*AA + 3*(HYFI50 | HYFI100) + 3*V
     *      it means that we have two guaranteed sets:
     *      0 | A + UM + 4*AA + 3*HYFI50 + 3*V | 50%
     *      1 | A + UM + 4*AA + 3*HYFI100 + 3*V| 50%
     *      if we have two guaranteed sets of rewards with probability 50/50,
     *      it should be range 0-0 for the first guaranteed set and 1-1 for the second one
     *      if the generated number from 0 to _guaranteedRangeMax is in the set range - we generate for user this set of rewards
     *      rewards - array of rewards where key is rewardId and value is amount of Rewards
     *      so in hyfi the structure will be:
     *      0 => {0,0,[1,4,0,1,3,0,3]} -
     *          0,0 means 50% probability,
     *          [1,4,0,1,3,0,3] - mean A + UM + 4*AA + 3*HYFI50 + 3*V
     *      0 => {1,1,[1,4,0,1,0,3,3]} -
     *          1,1 means 50% probability,
     *          [1,4,0,1,0,3,3] - mean A + UM + 4*AA + 3*HYFI100 + 3*V
     */
    GuaranteedRewardsSetData[] internal _guaranteedRewardsSets;

    /**
     * @dev event on successfull vaults revealing
     * @param user the user address
     * @param vaultIds the vault ids user revealed
     * @param rewards the array with rewards where key is reward ID and value is amount of rewards which should be transfered to user
     */
    event VaultsRevealed(address user, uint256[] vaultIds, uint256[] rewards);

    /**
     * @dev check if rewards array length is correct
     * @param rewards the array with rewards
     */
    modifier checkRewardsLength(uint256[] memory rewards) {
        require(
            rewards.length == _rewards.length,
            "Rewards array length is incorrect"
        );
        _;
    }

    /**
     * @dev check if user owns more(or equal) vaults than amount
     * @param revealAmount the amount of vaults
     */
    modifier checkUserOwnsVaultsAmount(uint256 revealAmount) {
        require(
            revealAmount <= _vault.balanceOf(msg.sender),
            "User owns less vaults"
        );
        _;
    }

    /**
     * @dev check if user owns all vaults among array vaultIds
     * @param vaultIds the ids of the vaults
     */
    modifier checkUserOwnsVaultsIds(uint256[] memory vaultIds) {
        bool userIsOwner = true;
        for (uint256 i = 0; i < vaultIds.length; i++) {
            if (_vault.ownerOf(vaultIds[i]) != msg.sender) {
                userIsOwner = false;
                break;
            }
        }
        require(userIsOwner, "User is not owner of some vault");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev initializer
     */
    function initialize() external virtual initializer {
        __Pausable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }

    /**
     * @dev pause Lottery, tickets can not be revealed when paused
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev unpause Lottery, tickets can be revealed
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev set the new Vault NFT smart contract address
     * @param newVault the new Vault address
     */
    function setVaultAddress(
        address newVault
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _vault = IHYFI_Vault(newVault);
    }

    /**
     * @dev set the new guaranteed threshold value, the number of vaults should be revealed at once
     * @param newThreshold the new guaranteed threshold value. If user reveals this amount of tickets at once - he will have guaranteed set of rewards
     */
    function setGuaranteedThreshold(
        uint256 newThreshold
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _guaranteedThreshold = newThreshold;
    }

    /**
     * @dev set the new maximum range value, it will be used in random generator
     * @param newRangeMax the new max value in the normalized range of rewards sets
     */
    function setRangeMax(
        uint256 newRangeMax
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _rangeMax = newRangeMax;
    }

    /**
     * @dev set the new maximum guaranteed range value, it will be used in random generator
     * @param newRangeMax the new max value in the normalized range in guaranteed rewards sets
     */
    function setGuaranteedRangeMax(
        uint256 newRangeMax
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _guaranteedRangeMax = newRangeMax;
    }

    /**
     * @dev add new reward information
     * @param rewardManager the address of reward manager responsible for rewards revealing logic
     * @param totalAmount the total available amount of such type of rewards
     */
    function addReward(
        address rewardManager,
        uint256 totalAmount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        RewardsData memory reward;
        reward.rewardManager = IHYFI_RewardsManager(rewardManager);
        reward.totalAmount = totalAmount;
        reward.freeAmount = totalAmount;
        _rewards.push(reward);
    }

    /**
     * @dev update reward information
     * @param rewardManager the address of reward manager responsible for rewards revealing logic
     * @param totalAmount the total available amount of such type of rewards
     * @param resetFreeAmount true if the freeAmount value for this reward should be reset
     */
    function updateReward(
        uint256 rewardId,
        address rewardManager,
        uint256 totalAmount,
        bool resetFreeAmount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        RewardsData storage reward = _rewards[rewardId];
        reward.rewardManager = IHYFI_RewardsManager(rewardManager);
        reward.totalAmount = totalAmount;
        if (resetFreeAmount) {
            reward.freeAmount = totalAmount;
        }
    }

    /**
     * @dev delete the last reward from array
     */
    function deleteRewardTop() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _rewards.pop();
    }

    /**
     * @dev add new reward set data. Each reward set has probability (reslected in range), total amount and rewards
     * @param range array with min and max in range, for probability reflection, if the normalized range is 0-9, so the range 0-1 reflects probability 20%
     * @param rewards array of rewards, where key is rewardId and value is reward amount
     */
    function addRewardsSet(
        uint256[2] memory range,
        uint256[] memory rewards
    ) external onlyRole(DEFAULT_ADMIN_ROLE) checkRewardsLength(rewards) {
        RewardsSetData memory rewardsSet;
        rewardsSet.rangeMin = range[0];
        rewardsSet.rangeMax = range[1];
        rewardsSet.rewards = rewards;
        _rewardsSets.push(rewardsSet);
    }

    /**
     * @dev update rewardsSet data
     * @param range array with min and max in range, for probability reflection, if the normalized range is 0-9, so the range 0-1 reflects probability 20%
     * @param rewards array of rewards, where key is rewardId and value is reward amount
     */
    function updateRewardsSet(
        uint256 rewardsSetId,
        uint256[2] memory range,
        uint256[] memory rewards
    ) external onlyRole(DEFAULT_ADMIN_ROLE) checkRewardsLength(rewards) {
        RewardsSetData storage rewardsSet = _rewardsSets[rewardsSetId];
        rewardsSet.rangeMin = range[0];
        rewardsSet.rangeMax = range[1];
        rewardsSet.rewards = rewards;
    }

    /**
     * @dev delete the last reward set from array
     */
    function deleteRewardsSetTop() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _rewardsSets.pop();
    }

    /**
     * @dev add new guaranteed reward set data
     * @param range array with min and max in range, for probability reflection, if the normalized range is 0-9, so the range 0-1 reflects probability 20%
     * @param rewards array of rewards, where key is rewardId and value is reward amount
     */
    function addGuaranteedRewardsSet(
        uint256[2] memory range,
        uint256[] memory rewards
    ) external onlyRole(DEFAULT_ADMIN_ROLE) checkRewardsLength(rewards) {
        GuaranteedRewardsSetData memory guaranteedRewardsSet;
        guaranteedRewardsSet.rangeMin = range[0];
        guaranteedRewardsSet.rangeMax = range[1];
        guaranteedRewardsSet.rewards = rewards;
        _guaranteedRewardsSets.push(guaranteedRewardsSet);
    }

    /**
     * @dev update guaranteed reward set data
     * @param range array with min and max in range, for probability reflection, if the normalized range is 0-9, so the range 0-1 reflects probability 20%
     * @param rewards array of rewards, where key is rewardId and value is reward amount
     */
    function updateGuaranteedRewardsSet(
        uint256 guaranteedRewardsSetId,
        uint256[2] memory range,
        uint256[] memory rewards
    ) external onlyRole(DEFAULT_ADMIN_ROLE) checkRewardsLength(rewards) {
        GuaranteedRewardsSetData
            storage guaranteedRewardsSet = _guaranteedRewardsSets[
                guaranteedRewardsSetId
            ];
        guaranteedRewardsSet.rangeMin = range[0];
        guaranteedRewardsSet.rangeMax = range[1];
        guaranteedRewardsSet.rewards = rewards;
    }

    /**
     * @dev delete the last guaranteed reward set from array
     */
    function deleteGuaranteedRewardsSetTop()
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _guaranteedRewardsSets.pop();
    }

    /**
     * @dev reveal specific amount of vaults, user is able to reveal such amount only if he has enough vaults
     * @param revealAmount the number of vauls user is going to reveal
     */
    function revealVaults(
        uint256 revealAmount
    ) external whenNotPaused checkUserOwnsVaultsAmount(revealAmount) {
        require(revealAmount > 0, "Zero amount is going to reveal");

        uint256[] memory userVaultsIds = new uint256[](revealAmount);

        for (uint256 i = 0; i < revealAmount; i++) {
            userVaultsIds[i] = _vault.tokenOfOwnerByIndex(msg.sender, i);
        }
        _revealSpecificVaults(userVaultsIds);
    }

    /**
     * @dev reveal specific vaults by ids, user is able to reveal only if he owns all selected vault ids
     * @param vaultIds the array with vault numbers(ids) user is going to reveal
     */
    function revealSpecificVaults(
        uint256[] memory vaultIds
    ) external whenNotPaused checkUserOwnsVaultsIds(vaultIds) {
        _revealSpecificVaults(vaultIds);
    }

    /**
     * @dev get the information about specific reward
     * @param rewardId the id of reward
     * @return return totalAmount
     * @return return freeAmount
     * @return return reward manager address
     */
    function getReward(
        uint256 rewardId
    ) external view returns (uint256, uint256, address) {
        return (
            _rewards[rewardId].totalAmount,
            _rewards[rewardId].freeAmount,
            address(_rewards[rewardId].rewardManager)
        );
    }

    /**
     * @dev get the information about specific rewardsSet
     * @param rewardSetId the id of rewardSet
     * @return return rangeMin
     * @return return rangeMax
     * @return return rewards array
     */
    function getRewardsSet(
        uint256 rewardSetId
    ) external view returns (uint256, uint256, uint256[] memory) {
        return (
            _rewardsSets[rewardSetId].rangeMin,
            _rewardsSets[rewardSetId].rangeMax,
            _rewardsSets[rewardSetId].rewards
        );
    }

    /**
     * @dev get the information about specific guaranteed rewards Set
     * @param guaranteedRewardsSetId the id of guaranteed rewards Set
     * @return return rangeMin
     * @return return rangeMax
     * @return return rewards array
     */
    function getGuaranteedRewardsSet(
        uint256 guaranteedRewardsSetId
    ) external view returns (uint256, uint256, uint256[] memory) {
        return (
            _guaranteedRewardsSets[guaranteedRewardsSetId].rangeMin,
            _guaranteedRewardsSets[guaranteedRewardsSetId].rangeMax,
            _guaranteedRewardsSets[guaranteedRewardsSetId].rewards
        );
    }

    /**
     * @dev get the maximum range value, it is used in random generator
     * @return return max value in the normalized range of rewards sets
     */
    function getRangeMax() external view returns (uint256) {
        return _rangeMax;
    }

    /**
     * @dev get the maximum guaranteed range value, it is used in random generator
     * @return return max value in the normalized range of guaranteed rewards sets
     */
    function getGuaranteedRangeMax() external view returns (uint256) {
        return _guaranteedRangeMax;
    }

    /**
     * @dev get the guaranteed threshold - the number of tickets should be open all at once to have guaranteed rewards
     * @return return guaranteed threshold
     */
    function getGuaranteedThreshold() external view returns (uint256) {
        return _guaranteedThreshold;
    }

    /**
     * @dev get the Vault NFT smart contracts address
     * @return return vault address
     */
    function getVaultAddress() external view returns (address) {
        return address(_vault);
    }

    /**
     * @dev get array of user Vault ids (lottery ticket numbers)
     * @return return user address
     */
    function getUserVaultIds(
        address user
    ) external view returns (uint256[] memory) {
        uint256 tokensAmount = _vault.balanceOf(user);
        uint256[] memory tokenIds = new uint256[](tokensAmount);
        for (uint256 i = 0; i < tokensAmount; i++) {
            tokenIds[i] = _vault.tokenOfOwnerByIndex(user, i);
        }
        return tokenIds;
    }

    /**
     * @dev calculate the rewards set id with available rewards during revealing the ticket #vaultId
     * @param vaultId vault ID is going to be revealed. used as salt for random generation
     * @return return winning rewardsSet Id
     */
    function getWinningRewardsSetId(
        uint256 vaultId
    ) public view returns (uint256) {
        uint256 randomValue = getRandomValueN(vaultId, (_rangeMax + 1)); // 0 - 9
        uint256 j;
        uint256 rewardSetId;
        for (uint256 i = 0; i < _rewardsSets.length; i++) {
            if (
                randomValue >= _rewardsSets[i].rangeMin &&
                randomValue <= _rewardsSets[i].rangeMax
            ) {
                // do the loop in order to find available rewards set (all rewards within the set should have free amount > 0) strating from id = i
                // if some rewards are occupied in selected set - find next reward set which have all rewards available, move to the left
                // if we have 4 rewards sets - 0,1,2,3 and the random value is in the range from the reward set #2
                // it will check check availability in rewards sets in such order: 2,3,0,1
                for (j = 0; j < _rewardsSets.length; j++) {
                    rewardSetId = (i + j) % _rewardsSets.length;
                    if (isRewardsSetAvailable(rewardSetId)) {
                        return rewardSetId;
                    }
                }
            }
        }
        revert("No available rewards sets");
    }

    /**
     * @dev calculate the winning guaranteed set with sufficient available rewards and return rewards of guaranteed set
     * @param packNumber the order number of guaranteed pack is going to be revealed, used as salt for random generator
     * @return return array where key is rewardsSet id and value is amount of won rewardsSets
     */
    function getWinningGuaranteedRewards(
        uint256 packNumber
    ) public view returns (uint256[] memory) {
        uint256[] memory emptyRewards;
        // if the length is 1 it means that all guaranteed rewards have 100% probability
        if (_guaranteedRewardsSets.length == 1) {
            if (
                areSpecificRewardsAvailable(_guaranteedRewardsSets[0].rewards)
            ) {
                return _guaranteedRewardsSets[0].rewards;
            } else {
                return emptyRewards;
            }
        }

        // the logic for guaranteed rewards if they have probabilities
        uint256 randomValue = getRandomValueN(
            packNumber,
            _guaranteedRangeMax + 1
        );
        uint256 j;
        uint256 guaranteedSetId;
        for (uint256 i = 0; i < _guaranteedRewardsSets.length; i++) {
            if (
                randomValue >= _guaranteedRewardsSets[i].rangeMin &&
                randomValue <= _guaranteedRewardsSets[i].rangeMax
            ) {
                // do the loop in order to find available guaranteed rewards set (all rewards within set shoud have needed free amount)
                // strating from id = i
                // if no free amount in selected range - find next reward set which has free available rewards, move to the left
                // if we have 2 guaranteed rewards sets - 0,1 and the random value is in the range from the reward set #1
                // it will check availability in rewards sets in such order: 1,0
                for (j = 0; j < _guaranteedRewardsSets.length; j++) {
                    guaranteedSetId = (i + j) % _guaranteedRewardsSets.length;
                    if (
                        areSpecificRewardsAvailable(
                            _guaranteedRewardsSets[guaranteedSetId].rewards
                        )
                    ) {
                        return _guaranteedRewardsSets[guaranteedSetId].rewards;
                    }
                }
            }
        }
        return emptyRewards;
    }

    /**
     * @dev check if there is enough amount of rewards
     * @param id the id of the reward  (starts from 0)
     * @param amount the amount of rewards is needed to check for availability
     * @return return true if rewards are available and there are still free items >= the needed amount
     */
    function isRewardAvailable(
        uint256 id,
        uint256 amount
    ) public view returns (bool) {
        return _rewards[id].freeAmount >= amount;
    }

    /**
     * @dev check if there is enough amount of rewards in specific rewardsSet
     * @param id the id of the rewards set  (starts from 0)
     * @return return true if rewards set is available and there are all rewards needed available
     */
    function isRewardsSetAvailable(uint256 id) public view returns (bool) {
        return areSpecificRewardsAvailable(_rewardsSets[id].rewards);
    }

    /**
     * @dev check if there are enough amount of rewards
     * @param rewards the array of rewards needed to be checked, key is reward Id and value is amount of needed rewards
     * @return return true if all rewards in the array are available
     */
    function areSpecificRewardsAvailable(
        uint256[] memory rewards
    ) public view returns (bool) {
        bool isAvailable = true;
        for (uint256 i = 0; i < rewards.length; i++) {
            isAvailable = isAvailable && isRewardAvailable(i, rewards[i]);
        }
        return isAvailable;
    }

    /**
     * @dev get random value using seed, can be used for rewards sets and guaranteed rewards probabilities
     * @param seed the salt for randomness
     * @param normalized the value for normalization
     * @return return random value, normalized
     */
    function getRandomValueN(
        uint256 seed,
        uint256 normalized
    ) public view returns (uint256) {
        /* solhint-disable not-rely-on-time */
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        msg.sender,
                        seed
                    )
                )
            ) % normalized;
        /* solhint-enable not-rely-on-time */
    }

    /**
     * @dev calculate the max possible amount of guaranteed packs, if amount=21, the max possible amount of guaranteed packs will be 4 (4*5=20)
     * @param amount the amount of vaults are going to be revealed
     * @return return max amount of guaranteed packs
     */
    function getGuaranteedPacksAmount(
        uint256 amount
    ) public view returns (uint256) {
        return amount / _guaranteedThreshold;
    }

    /**
     * @dev calculate the number of vaults are needed to be revealed one-by-one, if vaults amount is 23, 3 tickets should be revealed one-by-one (23%5) or (23 - 4*5)
     * @param amount the amount of vaults are going to be revealed
     * @return return amount of vaults needed to be revealed one-by-one
     */
    function getOneByOneAmount(uint256 amount) public view returns (uint256) {
        return amount % _guaranteedThreshold;
    }

    /**
     * @dev common logic for revealing vaults by their ids and generating rewards (reward manager is responsible for rewards generation logic)
     * @param vaultIds the array with vault numbers(ids) need to be revealed
     * @return return array of user rewards where key is rewardId and value is won rewards amount
     */
    function _revealSpecificVaults(
        uint256[] memory vaultIds
    ) internal returns (uint256[] memory) {
        uint256 revealAmount = vaultIds.length;
        // calculate number of guaranteed sets (how many times we open tickets by 5(_guaranteedThreshold) at once)
        // if user opens 23 tickets at once, guaranteedSetsAmount should be 4 (4 times by 5 tickets = 20)
        // and oneByOneAmount will be 3 (3 tickets should be opened one by one)
        uint256 guaranteedPacksAmount = getGuaranteedPacksAmount(revealAmount);

        // get amount of each reward's set, won by user during revealing guaranteed amount
        (
            uint256[] memory userGuaranteedRewards,
            uint256 processedGuaranteedPacksAmount
        ) = _processGuaranteedPacks(guaranteedPacksAmount);

        // if guaranteed packs were not be processed completely (not enough guaranteed rewards), the rest should be processed one by one
        // if user opens 23 tickets at once, guaranteedPacksAmount should be 4 (4 times by 5 tickets = 20)
        // but only two guaranteed packs were processed - it means that oneByOneAmount will be 3 + (4-2)*5 = 13
        uint256 oneByOneAmount = getOneByOneAmount(revealAmount) +
            (guaranteedPacksAmount - processedGuaranteedPacksAmount) *
            _guaranteedThreshold;

        uint256[] memory userVaultsIdsOneByOne = new uint256[](oneByOneAmount);
        // get the array of vault ids which should be reveald one by one (for simplicity the first ones in the array are used)
        for (uint256 i = 0; i < oneByOneAmount; i++) {
            userVaultsIdsOneByOne[i] = vaultIds[i];
        }
        // get amount of each reward's set, won by user during revealing one by one tickets
        uint256[] memory userRewardsSetsOneByOne = _processVaultsOneByOne(
            userVaultsIdsOneByOne
        );

        uint256[] memory userRewards = new uint256[](_rewards.length);
        uint256 rewardSetId;

        for (uint256 rewardId = 0; rewardId < userRewards.length; rewardId++) {
            for (
                rewardSetId = 0;
                rewardSetId < userRewardsSetsOneByOne.length;
                rewardSetId++
            ) {
                if (userRewardsSetsOneByOne[rewardSetId] > 0) {
                    userRewards[rewardId] +=
                        _rewardsSets[rewardSetId].rewards[rewardId] *
                        userRewardsSetsOneByOne[rewardSetId];
                }
            }
            userRewards[rewardId] += userGuaranteedRewards[rewardId];
            if (userRewards[rewardId] > 0) {
                _rewards[rewardId].rewardManager.revealRewards(
                    msg.sender,
                    userRewards[rewardId],
                    rewardId
                );
            }
        }

        emit VaultsRevealed(msg.sender, vaultIds, userRewards);

        _burnVaults(vaultIds);
        return userRewards;
    }

    /**
     * @dev logic for revealing tickets one by one (define winning reward set ID per each vault and mark rewards from this set as occupied)
     * @param vaultIds array of vault IDs are going to be revealed
     * @return return array where key is rewardsSet id and value is amount of won rewardsSets
     */
    function _processVaultsOneByOne(
        uint256[] memory vaultIds
    ) internal returns (uint256[] memory) {
        uint256[] memory userRewardsSets = new uint256[](_rewardsSets.length);
        for (uint256 i = 0; i < vaultIds.length; i++) {
            uint256 winningRewardsSetId = getWinningRewardsSetId(vaultIds[i]);
            _holdSpecificRewards(_rewardsSets[winningRewardsSetId].rewards);
            userRewardsSets[winningRewardsSetId]++;
        }
        return userRewardsSets;
    }

    /**
     * @dev processing logic for revealing vaults as guaranteed (packs of _guaranteedThreshold), defining rewards per each pack and mark them as occupied
     * @param guaranteedPacksAmount the amount of guaranteed packs are going to be revealed
     * @return return memory array where key is rewardsSet id and value is amount of won rewardsSets
     * @return return amount of processed packs. it is possible that some packs can not be processed as guaranteed, because of insufficiency of some rewards
     */
    function _processGuaranteedPacks(
        uint256 guaranteedPacksAmount
    ) internal returns (uint256[] memory, uint256) {
        // is used on each iteration, stores won amount of each reward
        uint256[] memory rewardsAmounstById = new uint256[](_rewards.length);
        // is used to calculate total won amounts of each reward
        uint256[] memory totalRewardsAmounstById = new uint256[](
            _rewards.length
        );
        uint256 j;
        uint256 i;
        for (i = 0; i < guaranteedPacksAmount; i++) {
            rewardsAmounstById = getWinningGuaranteedRewards(i);

            if (rewardsAmounstById.length == 0) {
                //the last pack was not able to be proccessed, go out from loop
                break;
            }
            _holdSpecificRewards(rewardsAmounstById);

            for (j = 0; j < rewardsAmounstById.length; j++) {
                totalRewardsAmounstById[j] += rewardsAmounstById[j];
            }
        }
        return (totalRewardsAmounstById, i);
    }

    /**
     * @dev mark rewards as occipied (decrease free amount)
     * @param rewards the array of rewards needed to me marked as occipied, key is reward Id and value is amount of rewards
     */
    function _holdSpecificRewards(uint256[] memory rewards) internal {
        for (uint256 i = 0; i < rewards.length; i++) {
            _rewards[i].freeAmount -= rewards[i];
        }
    }

    /**
     * @dev internal logic for burning several vaults
     */
    function _burnVaults(uint256[] memory vaultIds) internal {
        for (uint256 i = 0; i < vaultIds.length; i++) {
            _vault.burn(vaultIds[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";

// solhint-disable-next-line contract-name-camelcase
interface IHYFI_RewardsManager is IAccessControlUpgradeable {
    /**
     * @dev event on successfull rewards revealing
     * @param user the user address
     * @param rewardId the reward ID needed to be revealed
     * @param amount the amount of rewords with id #rewardId needed to be revealed
     */
    event RewardsRevealed(address user, uint256 rewardId, uint256 amount);

    function revealRewards(
        address user,
        uint256 amount,
        uint256 rewardId
    ) external;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
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
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
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
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface IHYFI_Vault is IAccessControlUpgradeable {
    function MINTER_ROLE() external view returns (bytes32);

    function BURNER_ROLE() external view returns (bytes32);

    function safeMint(address to, uint256 amount) external;

    function balanceOf(address owner) external view returns (uint256 balance);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    function burn(uint256 tokenId) external;

    function ownerOf(uint256 tokenId) external view returns (address);
}