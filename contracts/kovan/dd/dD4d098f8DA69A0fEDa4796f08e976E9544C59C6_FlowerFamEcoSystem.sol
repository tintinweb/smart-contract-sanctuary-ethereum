// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./libraries/SimpleAccessUpgradable.sol";

import "./interfaces/IFlowerFam.sol";
import "./interfaces/IBee.sol";
import "./interfaces/IFlowerFamNewGen.sol";
import "./interfaces/IHoney.sol";
import "./interfaces/IFlowerFamRandomizer.sol";

contract FlowerFamEcoSystem is SimpleAccessUpgradable {
    IFlowerFam public flowerFamNFT;
    IBee public beeNFT;
    IFlowerFamNewGen public flowerFamNewGenNFT;
    IHoney public HoneyToken;
    IFlowerFamRandomizer private randomizer;

    /** Honey production */
    struct UserHoneyProduction {
        uint32 lastAction;
        uint112 totalProductionPerDay;
        uint112 totalAccumulated;
    }
    mapping(address => UserHoneyProduction) public userToProductionInfo;
    mapping(uint256 => uint256) public speciesToHoneyProduction;
    uint256 public newGenHoneyProduction;
    uint256 public upgradeProductionBonus;

    /** Bee system */
    struct FlowerBeeAttachement {
        uint128 reductionsStart; /// @dev records at which reduction period we start after stake or restore
        uint128 beeId;
    }
    uint256 public beeProductionBonus;
    mapping(uint256 => FlowerBeeAttachement) public flowerToBee;
    mapping(uint256 => FlowerBeeAttachement) public newGenFlowerToBee;

    mapping(address => uint256) public flowersToBeeCount;

    event UpdateTotalProductionPerDay(address indexed user, uint256 indexed amount);

    constructor(
        address _flowerFamNFT,
        address _beeNFT,
        address _flowerFamNewGen,
        address _honeyToken,
        address _randomizer
    ) {}

    function initialize(        
        address _flowerFamNFT,
        address _beeNFT,
        address _flowerFamNewGen,
        address _honeyToken,
        address _randomizer
    ) public initializer {
        __Ownable_init();

        flowerFamNFT = IFlowerFam(_flowerFamNFT);
        beeNFT = IBee(_beeNFT);
        flowerFamNewGenNFT = IFlowerFamNewGen(_flowerFamNewGen);
        HoneyToken = IHoney(_honeyToken);
        randomizer = IFlowerFamRandomizer(_randomizer);

        speciesToHoneyProduction[0] = 4 ether;
        speciesToHoneyProduction[1] = 6 ether;
        speciesToHoneyProduction[2] = 10 ether;
        speciesToHoneyProduction[3] = 18 ether;
        speciesToHoneyProduction[4] = 30 ether;
        newGenHoneyProduction = 2 ether;

        beeProductionBonus = 5; /// @dev 5% boost of flowers earnings for each reduction period
        upgradeProductionBonus = 5; /// @dev 5% boost of flowers earnings for each upgrade
    }

    receive() external payable {}

    /** Helpers */

    function _getNotAccumulatedProduction(
        uint256 lastAction,
        uint256 totalProductionPerDay
    ) internal view returns (uint256) {
        return ((block.timestamp - lastAction) * totalProductionPerDay) / 1 days;
    }

    function _getTotalNotAccumulatedProductionOfUser(address user, uint256[] memory flowersWithBees) internal view returns (uint256) {
        require(flowersWithBees.length == flowersToBeeCount[user], "Flower to bees count is not matched");
        UserHoneyProduction memory userHoneyProduction = userToProductionInfo[user];
        
        uint256 unAccumulated = _getNotAccumulatedProduction(
            userHoneyProduction.lastAction,
            userHoneyProduction.totalProductionPerDay
        );

        uint256 lastId;
        for (uint i = 0; i < flowersWithBees.length; i++) {
            uint256 flowerId = flowersWithBees[i];
            require(flowerId > lastId, "FlowersWithBees array needs to be ordered ascendingly");
            lastId = flowerId;

            if (flowerToBee[flowerId].beeId != 0 && flowerFamNFT.realOwnerOf(flowerId) == user)
                unAccumulated += _getProductionFromBee(flowerId, true, flowerToBee[flowerId].beeId);
            if (newGenFlowerToBee[flowerId].beeId != 0 && flowerFamNewGenNFT.realOwnerOf(flowerId) == user)
                unAccumulated += _getProductionFromBee(flowerId, false, newGenFlowerToBee[flowerId].beeId);     
        }

        return unAccumulated;
    }

    function _getProductionFromUpgrade(uint256 initialProduction, uint256 flowerFamId) internal view returns(uint256) {
        return initialProduction * upgradeProductionBonus * flowerFamNFT.getUpgradeCountOfFlower(flowerFamId) / 100;
    }

    function _getProductionFromBee(uint256 flowerId, bool isFam, uint256 beeId) internal view returns(uint256) {
        uint256 species = randomizer.getSpeciesOfId(flowerId);
        uint256 flowerBaseProduction = isFam ? 
            speciesToHoneyProduction[species] :
            newGenHoneyProduction;
        uint256 powerCycleBasePeriod = beeNFT.powerCycleBasePeriod();

        uint256 beeLastInteraction = beeNFT.getLastAction(beeId);
        uint256 powerCycleStart = beeNFT.getPowerCycleStart(beeId);
        uint256 reductions = beeNFT.getPowerReductionPeriods(beeId);
        uint256 reductionsStart = isFam ? flowerToBee[flowerId].reductionsStart : newGenFlowerToBee[flowerId].reductionsStart;

        uint256 totalEarned;
        for (uint i = 0; i <= reductions - reductionsStart; i++) {

            /// @dev nothing should be added at or beyond 20 reductions
            if (reductionsStart + i >= 20)
                continue;

            /// @dev at first reduction we add either period from last interaction until now
            /// or period from last interaction until next reduction. We calculate the bonus as
            /// this time multiplied by the initial reduction.
            if (i == 0) {
                uint256 nextReductionAfterStart = powerCycleStart + (powerCycleBasePeriod * (reductionsStart + 1));
                uint256 timeSpentBeforeFirstReduction = block.timestamp < nextReductionAfterStart ? 
                    block.timestamp - beeLastInteraction : 
                    nextReductionAfterStart - beeLastInteraction;
                
                uint256 additionalProduction = flowerBaseProduction * (100 - reductionsStart * beeProductionBonus) / 100;
                totalEarned += additionalProduction * timeSpentBeforeFirstReduction / 1 days;
            
            /// @dev Here we just calculate one week worth of rewards at that level
            } else if (i < reductions - reductionsStart) {
                uint256 additionalProduction = flowerBaseProduction * (100 - (reductionsStart + i) * beeProductionBonus) / 100;
                totalEarned += additionalProduction * powerCycleBasePeriod / 1 days;

            /// @dev At last reduction we add period from last reduction until now with that reduction rate as reward.
            } else {
                uint256 startTimeOfLastReduction = powerCycleStart + (powerCycleBasePeriod * reductions);
                uint256 timeSpentAtLastReduction = block.timestamp  - startTimeOfLastReduction;
                uint256 additionalProduction = flowerBaseProduction * (100 - reductions * beeProductionBonus) / 100;
                totalEarned +=  additionalProduction * timeSpentAtLastReduction / 1 days;
            }
        }

        return totalEarned;
    }

    /** User interactable (everything that does not require spending $honey) */

    function stakeFlowerFamFlower(uint256 flowerFamId) external {
        uint256 species = randomizer.getSpeciesOfId(flowerFamId);

        uint256 additionalHoneyProduction = speciesToHoneyProduction[species];
        additionalHoneyProduction += _getProductionFromUpgrade(additionalHoneyProduction, flowerFamId);

        UserHoneyProduction storage userHoneyProduction = userToProductionInfo[msg.sender];

        uint256 unAccumulated = _getNotAccumulatedProduction(
            userHoneyProduction.lastAction,
            userHoneyProduction.totalProductionPerDay
        );
        userHoneyProduction.lastAction = uint32(block.timestamp);
        userHoneyProduction.totalProductionPerDay += uint112(additionalHoneyProduction);
        userHoneyProduction.totalAccumulated += uint112(unAccumulated);

        flowerFamNFT.stake(msg.sender, flowerFamId);

        emit UpdateTotalProductionPerDay(msg.sender, userHoneyProduction.totalProductionPerDay);
    }

    function unstakeFlowerFamFlower(uint256 flowerFamId) external {
        uint256 species = randomizer.getSpeciesOfId(flowerFamId);

        if (flowerToBee[flowerFamId].beeId != 0) {
            releaseBeeFromFlower(flowerFamId, flowerToBee[flowerFamId].beeId);
        }

        uint256 reducedHoneyProduction = speciesToHoneyProduction[species];
        reducedHoneyProduction += _getProductionFromUpgrade(reducedHoneyProduction, flowerFamId);

        UserHoneyProduction storage userHoneyProduction = userToProductionInfo[msg.sender];

        uint256 unAccumulated = _getNotAccumulatedProduction(
            userHoneyProduction.lastAction,
            userHoneyProduction.totalProductionPerDay
        );
        userHoneyProduction.lastAction = uint32(block.timestamp);
        userHoneyProduction.totalProductionPerDay -= uint112(reducedHoneyProduction);
        userHoneyProduction.totalAccumulated += uint112(unAccumulated);

        flowerFamNFT.unstake(msg.sender, flowerFamId);

        emit UpdateTotalProductionPerDay(msg.sender, userHoneyProduction.totalProductionPerDay);
    }

    function stakeNewGenerationFlower(uint256 newGenId) external {
        uint256 additionalHoneyProduction = newGenHoneyProduction;

        UserHoneyProduction storage userHoneyProduction = userToProductionInfo[msg.sender];

        uint256 unAccumulated = _getNotAccumulatedProduction(
            userHoneyProduction.lastAction,
            userHoneyProduction.totalProductionPerDay
        );
        userHoneyProduction.lastAction = uint32(block.timestamp);
        userHoneyProduction.totalProductionPerDay += uint112(additionalHoneyProduction);
        userHoneyProduction.totalAccumulated += uint112(unAccumulated);

        flowerFamNewGenNFT.stake(msg.sender, newGenId);

        emit UpdateTotalProductionPerDay(msg.sender, userHoneyProduction.totalProductionPerDay);
    }

    function unstakeNewGenerationFlower(uint256 newGenId) external {
        if (newGenFlowerToBee[newGenId].beeId != 0) {
            releaseBeeFromNewGenFlower(newGenId, newGenFlowerToBee[newGenId].beeId);
        }
        
        uint256 reducedHoneyProduction = newGenHoneyProduction;

        UserHoneyProduction storage userHoneyProduction = userToProductionInfo[msg.sender];

        uint256 unAccumulated = _getNotAccumulatedProduction(
            userHoneyProduction.lastAction,
            userHoneyProduction.totalProductionPerDay
        );
        userHoneyProduction.lastAction = uint32(block.timestamp);
        userHoneyProduction.totalProductionPerDay -= uint112(reducedHoneyProduction);
        userHoneyProduction.totalAccumulated += uint112(unAccumulated);

        flowerFamNewGenNFT.unstake(msg.sender, newGenId);

        emit UpdateTotalProductionPerDay(msg.sender, userHoneyProduction.totalProductionPerDay);
    }

    /** Batch stake */

    function batchStakeFlowerFamFlowers(uint256[] calldata flowerFamIds) external {
        require(flowerFamIds.length > 0, "No fams provided");

        uint256 additionalHoneyProduction;
        for (uint i = 0; i < flowerFamIds.length; i++) {
            uint256 flowerFamId = flowerFamIds[i];
            uint256 species = randomizer.getSpeciesOfId(flowerFamId);

            uint256 flowerProduction = speciesToHoneyProduction[species];
            flowerProduction += _getProductionFromUpgrade(additionalHoneyProduction, flowerFamId);

            additionalHoneyProduction += flowerProduction;
        }
        
        UserHoneyProduction storage userHoneyProduction = userToProductionInfo[msg.sender];

        uint256 unAccumulated = _getNotAccumulatedProduction(
            userHoneyProduction.lastAction,
            userHoneyProduction.totalProductionPerDay
        );
        userHoneyProduction.lastAction = uint32(block.timestamp);
        userHoneyProduction.totalProductionPerDay += uint112(additionalHoneyProduction);
        userHoneyProduction.totalAccumulated += uint112(unAccumulated);

        for (uint i = 0; i < flowerFamIds.length; i++) {
            uint256 flowerFamId = flowerFamIds[i];
            flowerFamNFT.stake(msg.sender, flowerFamId);
        }            

        emit UpdateTotalProductionPerDay(msg.sender, userHoneyProduction.totalProductionPerDay);
    }

    function batchUnstakeFlowerFamFlower(uint256[] calldata flowerFamIds) external {
        require(flowerFamIds.length > 0, "No fams provided");

        uint256 reducedHoneyProduction;
        for (uint i = 0; i < flowerFamIds.length; i++) {
            uint256 flowerFamId = flowerFamIds[i];
            if (flowerToBee[flowerFamId].beeId != 0) {
                releaseBeeFromFlower(flowerFamId, flowerToBee[flowerFamId].beeId);
            }

            uint256 species = randomizer.getSpeciesOfId(flowerFamId);
            uint256 flowerProduction = speciesToHoneyProduction[species];
            flowerProduction += _getProductionFromUpgrade(reducedHoneyProduction, flowerFamId);
            reducedHoneyProduction += flowerProduction;
        }
            
        UserHoneyProduction storage userHoneyProduction = userToProductionInfo[msg.sender];

        uint256 unAccumulated = _getNotAccumulatedProduction(
            userHoneyProduction.lastAction,
            userHoneyProduction.totalProductionPerDay
        );
        userHoneyProduction.lastAction = uint32(block.timestamp);
        userHoneyProduction.totalProductionPerDay -= uint112(reducedHoneyProduction);
        userHoneyProduction.totalAccumulated += uint112(unAccumulated);

        for (uint i = 0; i < flowerFamIds.length; i++) {
            uint256 flowerFamId = flowerFamIds[i];
            flowerFamNFT.unstake(msg.sender, flowerFamId);
        }            

        emit UpdateTotalProductionPerDay(msg.sender, userHoneyProduction.totalProductionPerDay);
    }

    function batchStakeNewGenerationFlower(uint256[] calldata newGenIds) external {
        require(newGenIds.length > 0, "No new generation flowers provided");

        uint256 additionalHoneyProduction = newGenHoneyProduction * newGenIds.length;

        UserHoneyProduction storage userHoneyProduction = userToProductionInfo[msg.sender];

        uint256 unAccumulated = _getNotAccumulatedProduction(
            userHoneyProduction.lastAction,
            userHoneyProduction.totalProductionPerDay
        );
        userHoneyProduction.lastAction = uint32(block.timestamp);
        userHoneyProduction.totalProductionPerDay += uint112(additionalHoneyProduction);
        userHoneyProduction.totalAccumulated += uint112(unAccumulated);

        for (uint i = 0; i < newGenIds.length; i++)
            flowerFamNewGenNFT.stake(msg.sender, newGenIds[i]);

        emit UpdateTotalProductionPerDay(msg.sender, userHoneyProduction.totalProductionPerDay);
    }

    function batchUnstakeNewGenerationFlower(uint256[] calldata newGenIds) external {
        require(newGenIds.length > 0, "No new generation flowers provided");

        uint256 reducedHoneyProduction = newGenHoneyProduction * newGenIds.length;

        UserHoneyProduction storage userHoneyProduction = userToProductionInfo[msg.sender];

        uint256 unAccumulated = _getNotAccumulatedProduction(
            userHoneyProduction.lastAction,
            userHoneyProduction.totalProductionPerDay
        );
        userHoneyProduction.lastAction = uint32(block.timestamp);
        userHoneyProduction.totalProductionPerDay -= uint112(reducedHoneyProduction);
        userHoneyProduction.totalAccumulated += uint112(unAccumulated);

        for (uint i = 0; i < newGenIds.length; i++)
            flowerFamNewGenNFT.unstake(msg.sender, newGenIds[i]);

        emit UpdateTotalProductionPerDay(msg.sender, userHoneyProduction.totalProductionPerDay);
    }

    /** Minter stake */
    function mintAndStakeFlowerFamFlower(address staker, uint256 flowerFamId) external onlyAuthorized {
        uint256 species = randomizer.getSpeciesOfId(flowerFamId);

        uint256 additionalHoneyProduction = speciesToHoneyProduction[species];
        additionalHoneyProduction += _getProductionFromUpgrade(additionalHoneyProduction, flowerFamId);

        UserHoneyProduction storage userHoneyProduction = userToProductionInfo[staker];

        uint256 unAccumulated = _getNotAccumulatedProduction(
            userHoneyProduction.lastAction,
            userHoneyProduction.totalProductionPerDay
        );
        userHoneyProduction.lastAction = uint32(block.timestamp);
        userHoneyProduction.totalProductionPerDay += uint112(additionalHoneyProduction);
        userHoneyProduction.totalAccumulated += uint112(unAccumulated);

        flowerFamNFT.stake(staker, flowerFamId);

        emit UpdateTotalProductionPerDay(staker, userHoneyProduction.totalProductionPerDay);
    }

    function mintAndBatchStakeFlowerFamFlowers(address staker, uint256[] calldata flowerFamIds) external onlyAuthorized {
        require(flowerFamIds.length > 0, "No fams provided");

        uint256 additionalHoneyProduction;
        for (uint i = 0; i < flowerFamIds.length; i++) {
            uint256 flowerFamId = flowerFamIds[i];
            uint256 species = randomizer.getSpeciesOfId(flowerFamId);

            uint256 flowerProduction = speciesToHoneyProduction[species];
            flowerProduction += _getProductionFromUpgrade(additionalHoneyProduction, flowerFamId);

            additionalHoneyProduction += flowerProduction;
        }
        
        UserHoneyProduction storage userHoneyProduction = userToProductionInfo[staker];

        uint256 unAccumulated = _getNotAccumulatedProduction(
            userHoneyProduction.lastAction,
            userHoneyProduction.totalProductionPerDay
        );
        userHoneyProduction.lastAction = uint32(block.timestamp);
        userHoneyProduction.totalProductionPerDay += uint112(additionalHoneyProduction);
        userHoneyProduction.totalAccumulated += uint112(unAccumulated);

        for (uint i = 0; i < flowerFamIds.length; i++) {
            uint256 flowerFamId = flowerFamIds[i];
            flowerFamNFT.stake(staker, flowerFamId);
        }            

        emit UpdateTotalProductionPerDay(staker, userHoneyProduction.totalProductionPerDay);
    }

    /** Bees */

    function attachBeeToFlower(uint256 flowerFamId, uint256 beeId) external {
        require(flowerFamNFT.realOwnerOf(flowerFamId) == msg.sender, "Sender not owner of flower");
        require(flowerFamNFT.isAlreadyStaked(flowerFamId), "Cannot attach bee to unstaked flower");
        require(flowerToBee[flowerFamId].beeId == 0, "Flower already boosted by bee");

        beeNFT.stake(msg.sender, beeId); /// @dev contains checks for ownership and stake status
    
        flowerToBee[flowerFamId].reductionsStart = uint128(beeNFT.getPowerReductionPeriods(beeId));
        flowerToBee[flowerFamId].beeId = uint128(beeId);
                
        flowersToBeeCount[msg.sender] += 1;
    }

    function releaseBeeFromFlower(uint256 flowerFamId, uint256 beeId) public {
        require(flowerFamNFT.realOwnerOf(flowerFamId) == msg.sender, "Sender not owner of flower");
        require(flowerFamNFT.isAlreadyStaked(flowerFamId), "Cannot release from unstaked flower");        
        require(flowerToBee[flowerFamId].beeId == beeId, "Flower already boosted by bee");

        /// @dev add production from bee to total accumulated when unstaking the bee
        uint256 earnedSinceLastInteraction = _getProductionFromBee(flowerFamId, true, beeId);
        UserHoneyProduction storage userHoneyProduction = userToProductionInfo[msg.sender];
        userHoneyProduction.totalAccumulated += uint112(earnedSinceLastInteraction);

        delete flowerToBee[flowerFamId];
        beeNFT.unstake(msg.sender, beeId); /// @dev contains checks for ownership and stake status
        flowersToBeeCount[msg.sender] -= 1;
    }

    function attachBeeToNewGenFlower(uint256 flowerId, uint256 beeId) external {
        require(flowerFamNewGenNFT.realOwnerOf(flowerId) == msg.sender, "Sender not owner of flower");
        require(flowerFamNewGenNFT.isAlreadyStaked(flowerId), "Cannot attach bee to unstaked flower");
        require(newGenFlowerToBee[flowerId].beeId == 0, "Flower already boosted by bee");

        beeNFT.stake(msg.sender, beeId); /// @dev contains checks for ownership and stake status

        newGenFlowerToBee[flowerId].reductionsStart = uint128(beeNFT.getPowerReductionPeriods(beeId));
        newGenFlowerToBee[flowerId].beeId = uint128(beeId);
                
        flowersToBeeCount[msg.sender] += 1;
    }

    function releaseBeeFromNewGenFlower(uint256 flowerId, uint256 beeId) public {
        require(flowerFamNewGenNFT.realOwnerOf(flowerId) == msg.sender, "Sender not owner of flower");
        require(flowerFamNewGenNFT.isAlreadyStaked(flowerId), "Cannot release from unstaked flower");        
        require(newGenFlowerToBee[flowerId].beeId == beeId, "Flower already boosted by bee");

        /// @dev add production from bee to total accumulated when unstaking the bee
        uint256 earnedSinceLastInteraction = _getProductionFromBee(flowerId, false, beeId);
        UserHoneyProduction storage userHoneyProduction = userToProductionInfo[msg.sender];
        userHoneyProduction.totalAccumulated += uint112(earnedSinceLastInteraction);

        delete newGenFlowerToBee[flowerId];
        beeNFT.unstake(msg.sender, beeId); /// @dev contains checks for ownership and stake status
        flowersToBeeCount[msg.sender] -= 1;
    }

    /** Marketplace only (everything that requires spending $honey) */

    function upgradeFlower(address user, uint256 flowerFamId) external onlyAuthorized {
        require(flowerFamNFT.realOwnerOf(flowerFamId) == user, "Sender not owner of flower");
        require(flowerFamNFT.isAlreadyStaked(flowerFamId), "Cannot upgrade unstaked flower");

        uint256 species = randomizer.getSpeciesOfId(flowerFamId);
        uint256 additionalHoneyProduction = speciesToHoneyProduction[species];
        uint256 addedFromUpgrade = additionalHoneyProduction * upgradeProductionBonus / 100; /// @dev each upgrade adds upgradeProductionBonus

        UserHoneyProduction storage userHoneyProduction = userToProductionInfo[user];

        uint256 unAccumulated = _getNotAccumulatedProduction(
            userHoneyProduction.lastAction,
            userHoneyProduction.totalProductionPerDay
        );
        userHoneyProduction.lastAction = uint32(block.timestamp);
        userHoneyProduction.totalProductionPerDay += uint112(addedFromUpgrade);
        userHoneyProduction.totalAccumulated += uint112(unAccumulated);

        flowerFamNFT.upgrade(user, flowerFamId);

        emit UpdateTotalProductionPerDay(msg.sender, userHoneyProduction.totalProductionPerDay);
    }

    function restorePowerOfBee(address user, uint256 flowerId, bool isFam, uint256 beeId, uint256 restorePeriods) external onlyAuthorized {    
        if (isFam) {
            require(flowerFamNFT.realOwnerOf(flowerId) == user, "Sender not owner of flower");
            require(flowerFamNFT.isAlreadyStaked(flowerId), "Cannot restore bee from unstaked flower");
            require(flowerToBee[flowerId].beeId == beeId, "Flower already boosted by bee");
        }            
        else {
            require(flowerFamNewGenNFT.realOwnerOf(flowerId) == user, "Sender not owner of flower");
            require(flowerFamNewGenNFT.isAlreadyStaked(flowerId), "Cannot restore bee from unstaked flower");
            require(newGenFlowerToBee[flowerId].beeId == beeId, "Flower already boosted by bee");
        }            

        /// @dev add production from bee to total accumulated when unstaking the bee
        uint256 earnedSinceLastInteraction = _getProductionFromBee(flowerId, isFam, beeId);
        UserHoneyProduction storage userHoneyProduction = userToProductionInfo[user];
        userHoneyProduction.totalAccumulated += uint112(earnedSinceLastInteraction);

        if (isFam)
            flowerToBee[flowerId].reductionsStart = uint128(beeNFT.getPowerReductionPeriods(beeId));
        else
            newGenFlowerToBee[flowerId].reductionsStart = uint128(beeNFT.getPowerReductionPeriods(beeId));

        beeNFT.restorePowerOfBee(user, beeId, restorePeriods); /// @dev contains checks for ownership and stake status
    }

    /** View */

    function getAttachedFlowerOfBee(uint256 beeId) external view returns (uint256) {
        uint256 flowerId = 0;
        uint256 startToken = flowerFamNFT.startTokenId();
        for (uint i = startToken; i < startToken + flowerFamNFT.totalSupply(); i++) {
            if (flowerToBee[i].beeId == beeId)
                flowerId = i;
        }
        
        return flowerId;
    }

    function getAttachedNewGenFlowerOfBee(uint256 beeId) external view returns (uint256) {
        uint256 flowerId = 0;
        uint256 startToken = flowerFamNewGenNFT.startTokenId();
        for (uint i = startToken; i < startToken + flowerFamNewGenNFT.totalSupply(); i++) {
        if (newGenFlowerToBee[i].beeId == beeId)
            flowerId = i;
        }
        
        return flowerId;
    }

    function getFlowerFamFlowersOfUserWithBees(address user) public view returns (uint256[] memory) {
        uint256 counter;
        uint256 balance = flowerFamNFT.balanceOf(user);
        uint256[] memory userNFTs = new uint256[](balance);

        uint256 startToken = flowerFamNFT.startTokenId();

        for (uint i = startToken; i < startToken + flowerFamNFT.totalSupply(); i++) {
            if (flowerToBee[i].beeId != 0 && flowerFamNFT.realOwnerOf(i) == user) {
                userNFTs[counter] = i;
                counter++;
            }               
        }
        
        return userNFTs;
    }

    function getNewGenFlowersOfUserWithBees(address user) public view returns (uint256[] memory) {
        uint256 counter;
        uint256 balance = flowerFamNewGenNFT.balanceOf(user);
        uint256[] memory userNFTs = new uint256[](balance);

        uint256 startToken = flowerFamNewGenNFT.startTokenId();

        for (uint i = startToken; i < startToken + flowerFamNewGenNFT.totalSupply(); i++) {
            if (newGenFlowerToBee[i].beeId != 0 && flowerFamNewGenNFT.realOwnerOf(i) == user) {
                userNFTs[counter] = i;
                counter++;
            }               
        }
        
        return userNFTs;
    }

    function getTotalNotAccumulatedProductionOfUser(address user, uint256[] memory flowersWithBees) external view returns (uint256) {
        return _getTotalNotAccumulatedProductionOfUser(user, flowersWithBees);
    }

    function getTotalProductionOfUser(address user, uint256[] memory flowersWithBees) external view returns (uint256) {
        UserHoneyProduction storage userHoneyProduction = userToProductionInfo[user];

        return _getTotalNotAccumulatedProductionOfUser(user, flowersWithBees) + userHoneyProduction.totalAccumulated;
    }

    function setAddresses(address flowerfam, address newgen, address bee) external onlyOwner {
        flowerFamNFT = IFlowerFam(flowerfam);
        flowerFamNewGenNFT = IFlowerFamNewGen(newgen);
        beeNFT = IBee(bee);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract SimpleAccessUpgradable is OwnableUpgradeable {
    
    constructor() {}
    
    mapping(address => bool) public authorized;

    modifier onlyAuthorized() {
        require(
            authorized[msg.sender] || msg.sender == owner(),
            "Sender is not authorized"
        );
        _;
    }

    function setAuthorized(address _auth, bool _isAuth) external virtual onlyOwner {
        authorized[_auth] = _isAuth;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IFlowerFam {
    function prodigy() external view returns (uint256);
    function seedling() external view returns (uint256);
    function ancestor() external view returns (uint256);
    function elder() external view returns (uint256);
    function pioneer() external view returns (uint256);

    function upgradeCooldownTime() external view returns (uint256);
    
    function getUpgradeCountOfFlower(uint256 tokenId) external view returns (uint16);

    function exists(uint256 _tokenId) external view returns (bool);

    function isAlreadyStaked(uint256 _tokenId) external view returns (bool);

    function mint(address _to, uint256 _tokenId) external;

    function stake(address staker, uint256 tokenId) external;

    function unstake(address unstaker, uint256 tokenId) external;

    function realOwnerOf(uint256 tokenId) external view returns (address);

    function ownerOf(uint256 tokenId) external view returns (address);

    function setBaseURI(string memory _newBaseURI) external;

    function upgrade(address upgrader, uint256 tokenId) external;

    function balanceOf(address owner) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function startTokenId() external pure returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IBee {
    function stake(address staker, uint256 tokenId) external;
    function unstake(address unstaker, uint256 tokenId) external;
    function mint(address sender, uint256 amount) external;
    function restorePowerOfBee(address owner, uint256 tokenId, uint256 restorePeriods) external;

    function realOwnerOf(uint256 tokenId) external view returns (address);
    function ownerOf(uint256 tokenId) external view returns (address);
    function isAlreadyStaked(uint256 tokenId) external view returns (bool);
    function getPowerReductionPeriods(uint256 tokenId) external view returns (uint256);
    function getLastAction(uint256 tokenId) external view returns (uint88);
    function getPowerCycleStart(uint256 tokenId) external view returns (uint88);

    function powerCycleBasePeriod() external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IFlowerFamNewGen {
    function mint(
        address sender,
        uint256 amount
    ) external;

    function stake(address staker, uint256 tokenId) external;
    function unstake(address unstaker, uint256 tokenId) external;

    function balanceOf(address owner) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function realOwnerOf(uint256 tokenId) external view returns (address);
    function isAlreadyStaked(uint256 _tokenId) external view returns (bool);

    function startTokenId() external pure returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IHoney {
    function spendEcoSystemBalance(address user, uint128 amount, uint256[] memory flowersWithBees, bytes memory data) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IFlowerFamRandomizer {
    function rng(address _address) external view returns (uint256);
    function rngDecision(address _address, uint256 probability, uint256 base) external view returns (bool);
    function getSpeciesOfId(uint256 id) external view returns (uint8);
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