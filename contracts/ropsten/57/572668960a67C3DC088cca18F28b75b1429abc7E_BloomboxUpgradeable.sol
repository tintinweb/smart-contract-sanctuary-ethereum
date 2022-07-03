// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./interfaces/ILiquidityManager.sol";
import "./interfaces/IWhitelist.sol";
import "./interfaces/IBloomNFT.sol";
import "./interfaces/IBloomsManagerUpgradeable.sol";

import "./implementations/NectarImplementationPointerUpgradeable.sol";

import "./libraries/BloomsManagerUpgradeableLib.sol";

/**
 * ERROR DESCRIPTIONS:
 * 1: ERC721 balance is not 0, createBloomsWithTokens func
 * 2: _bloomValue is less than creation min price, or values are 0
 * 3: No value added, _whitelistedDeposit func, usdc.transferFrom failed, _nonWhitelistedDeposit func
 * 4: tierStorage.rewardMult is not equal to _multiplier, _logTier func
 * 5: newAmountLockedInTier is less than 0, _logTier func
 * 6: invalid _duration startAutocompounding func, startAutoCompounding func
 * 7: already locked for AutoCompounding, startAutoCompounding func
 * 8: not autocompounding, emergencyClaim func
 * 9: bloomId is 0, invalid bloomId _bloomExists func
 * 10: bloom does not exist, _getBloomIdsOf func
 * 11: not owner of blooms, onlyBloomOwner modifier
 * 12: not approved or owner, onlyApprovedOrOwnerOfBloom modifier
 * 13: invalid name, onlyValidName modifier
 * 14: not processable, autoCompound, autoClaim func
 */

contract BloomboxUpgradeable is
    Initializable,
    IBloomsManagerUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    NectarImplementationPointerUpgradeable
{
    using BloomsManagerUpgradeableLib for uint256;

    //
    // PUBLIC STATE VARIABLES
    //

    IWhitelist public whitelist;
    ILiquidityManager public liquidityManager;
    IERC20 public usdc;
    IBloomNFT public bloomNFT;

    uint8[10] public tierSlope;
    uint24[10] public tierLevel;

    uint256 public totalValueLocked;
    uint256 public creationMinPrice;
    uint256 public burnedFromRenaming;
    uint256 public rewardPerDay;
    uint256 public bloomCounter;
    uint256 public compoundDelay;
    address public treasury;

    mapping(uint256 => TierStorage) public tierTracking;

    //
    // PRIVATE STATE VARIABLES
    //

    uint256 private _lastUpdatedNodeIndex;
    uint256 private _lastUpdatedClaimIndex;

    uint256[] private _tiersTracked;
    uint256[] private _bloomsCompounding;
    uint256[] private _bloomsClaimable;

    mapping(address => EmergencyStats) private _emergencyStats;
    mapping(uint256 => BloomEntity) private _blooms;
    mapping(uint256 => uint256) private _bloomId2Index;

    uint256 private constant STANDARD_FEE = 10;
    uint256 private constant PRECISION = 100;

    //
    // MODIFIERS
    //

    modifier onlyBloomOwner() {
        require(_isOwnerOfBlooms(_msgSender()), "11");

        _;
    }

    modifier onlyApprovedOrOwnerOfBloom(uint256 _bloomId) {
        require(_isApprovedOrOwnerOfBloom(_msgSender(), _bloomId), "12");

        _;
    }

    modifier onlyValidName(string memory _bloomName) {
        require(
            bytes(_bloomName).length > 1 && bytes(_bloomName).length < 32,
            "13"
        );

        _;
    }

    //
    // EXTERNAL FUNCTIONS
    //

    /**
     * @dev - Initializes the contract and initiates necessary state variables
     * @param _liquidityManager - Address of the LiquidityManager contract
     * @param _treasury - Address of the treasury
     * @param _usdc - Address of the $USDC.e token contract
     * @param _nctr - Address of the $NCTR token contract
     * @param _whitelist - Address of the whitelist contract
     * @param _rewardPerDay - Reward per day amount
     * @notice - Can only be initialized once
     */
    function initialize(
        address _liquidityManager,
        address _treasury,
        address _usdc,
        address _nctr,
        address _bloomNFT,
        address _whitelist,
        uint256 _rewardPerDay
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        usdc = IERC20(_usdc);
        nectar = INectar(_nctr);
        bloomNFT = IBloomNFT(_bloomNFT);
        whitelist = IWhitelist(_whitelist);
        liquidityManager = ILiquidityManager(_liquidityManager);
        treasury = _treasury;
        rewardPerDay = _rewardPerDay;

        // Initialize contract
        compoundDelay = 24 hours;
        creationMinPrice = 52000 ether; // TODO ask for min price

        tierLevel = [
            65000,
            80000,
            95000,
            110000,
            125000,
            140000,
            155000,
            170000,
            185000,
            200000
        ];
        tierSlope = [1, 5, 7, 11, 18, 29, 47, 77, 124, 200];
    }

    /**
     * @dev - Rename Bloom node
     * @param _bloomId - Id of the Bloom node
     * @param _bloomName - Name of the Bloom node
     */
    function renameBloom(uint256 _bloomId, string memory _bloomName)
        external
        nonReentrant
        whenNotPaused
        onlyApprovedOrOwnerOfBloom(_bloomId)
        onlyValidName(_bloomName)
    {
        BloomEntity storage bloom = _blooms[_bloomId];

        require(bloom.bloomValue > 0, "2");

        uint256 newBloomValue = (bloom.bloomValue * STANDARD_FEE) / PRECISION;
        uint256 feeAmount = bloom.bloomValue - newBloomValue;

        burnedFromRenaming += feeAmount;
        bloom.bloomValue = newBloomValue;

        _logTier(bloom.rewardMult, -int256(feeAmount));

        emit Rename(_msgSender(), bloom.name, _bloomName);

        bloom.name = _bloomName;
    }

    /**
     * @dev - Creates Bloom node
     * @param _bloomName - Name of the Bloom node
     * @param _bloomValue - Starting value of the Bloom node
     */
    function createBloomWithTokens(
        string memory _bloomName,
        uint256 _bloomValue
    ) external nonReentrant whenNotPaused onlyValidName(_bloomName) {
        require(_bloomValue >= creationMinPrice, "2");

        if (!whitelist.isWhitelisted(_msgSender())) {
            /// @notice user can possibly create more accounts and create one from each
            // If the user is not whitelisted, he can only create one node
            require(bloomNFT.balanceOf(_msgSender()) == 0, "1");
        }

        /// @notice - Actual _bloomValue, if the user deposited in $NCTR, returns _bloomValue
        ///           If not, quotes the value of $USDC.e deposit in $NCTR
        uint256 bloomValue = _deposit(_bloomValue);

        // Add this to the TVL
        totalValueLocked += bloomValue;

        _logTier(tierLevel[0], int256(bloomValue));

        // Add Bloom
        _blooms[++bloomCounter] = BloomEntity({
            owner: _msgSender(),
            id: bloomCounter,
            name: _bloomName,
            creationTime: block.timestamp,
            lastProcessingTimestamp: 0,
            rewardMult: tierLevel[0],
            bloomValue: bloomValue,
            totalClaimed: 0,
            timesCompounded: 0,
            lockedUntil: 0,
            lockPeriod: 0,
            exists: true
        });

        // Assign the Bloom to this account
        bloomNFT.mintBloom(_msgSender(), bloomCounter);

        emit Create(_msgSender(), bloomCounter, bloomValue);
    }

    /**
     * @dev - Adds more value to the existing Bloom node
     * @param _bloomId - Id of the Bloom node
     * @param _value - Value to add to the Bloom node
     */
    function addValue(uint256 _bloomId, uint256 _value)
        external
        nonReentrant
        whenNotPaused
        onlyApprovedOrOwnerOfBloom(_bloomId)
    {
        require(_value > 0, "2");

        BloomEntity storage bloom = _blooms[_bloomId];

        require(block.timestamp >= bloom.lockedUntil, "8");

        uint256 value = _deposit(_value);

        bloom.bloomValue += value;
        totalValueLocked += value;

        emit AdditionalDeposit(_bloomId, value);
    }

    /**
     * @dev - Registers the users Bloom node for auto compounding
     * @param _bloomId - Id of the Bloom node
     * @param _duration - Duration of the lock period for auto compounding, has to be in the specified timeframe
     */
    function startAutoCompounding(uint256 _bloomId, uint256 _duration)
        external
        onlyApprovedOrOwnerOfBloom(_bloomId)
    {
        BloomEntity storage bloom = _blooms[_bloomId];

        require(_isProcessable(bloom.lastProcessingTimestamp), "14");
        require(_duration >= 6 days && _duration <= 27 days, "6");
        require(block.timestamp >= bloom.lockedUntil, "7");

        bloom.lockedUntil = block.timestamp + _duration;
        bloom.lockPeriod = _duration;
        bloom.lastProcessingTimestamp = block.timestamp;

        if (_duration > 21 days) {
            // Increase reward multiplier by 0.25%
            bloom.rewardMult += 25000;
        } else if (_duration > 6 days) {
            // Increase reward multiplier by 0.15%
            bloom.rewardMult += 15000;
        }

        _bloomsCompounding.push(_bloomId);
        _bloomId2Index[_bloomId] = _bloomsCompounding.length - 1;
    }

    /**
     * @dev - Owner dependent auto compounding function, automatically compounds subscribed nodes
     * @param _numNodes- Number of the Bloom nodes to be compounded in one call
     * @notice - If the array is too large, the transaction wouldn't fit into the block,
     *         - therefore we introduced the _numNodes argument so the transaction wouldn't fail
     *         - It functions as a round robin system
     */
    // TODO test this
    function autoCompound(uint256 _numNodes) external onlyOwner {
        uint256 lastUpdatedNodeIndexLocal = _lastUpdatedNodeIndex;

        while (_numNodes > 0) {
            if (_bloomsCompounding.length == 0) {
                break;
            }
            if (_lastUpdatedNodeIndex >= _bloomsCompounding.length) {
                lastUpdatedNodeIndexLocal = 0;
            }

            // changed from _lastUpdatedNodeIndex to lastUpdatedNodeIndexLocal
            uint256 bloomId = _bloomsCompounding[lastUpdatedNodeIndexLocal];
            BloomEntity storage bloom = _blooms[bloomId];

            if (bloom.lockedUntil != 0 && block.timestamp > bloom.lockedUntil) {
                _resetRewardMultiplier(bloomId);
                _unsubscribeNodeFromAutoCompounding(lastUpdatedNodeIndexLocal);
                _bloomsClaimable.push(bloomId);
                continue;
            }

            (
                uint256 amountToCompound,
                uint256 feeAmount
            ) = _getRewardsAndCompound(bloomId);

            if (feeAmount > 0) {
                nectar.burnNectar(address(this), feeAmount);
            }

            lastUpdatedNodeIndexLocal++;
            _numNodes--;

            emit Autocompound(msg.sender, bloomId, amountToCompound);
        }

        _lastUpdatedNodeIndex = lastUpdatedNodeIndexLocal;
        // console.log(_lastUpdatedNodeIndex);
    }

    /**
     * @dev - Claims the rewards of nodes that finished their autocompounding lock period
     * @notice - Can only be called by the owner
     * @param _numNodes - Number of nodes to run through
     */
    function autoClaim(uint256 _numNodes) external onlyOwner {
        // TODO loop through _claimable array, which is updated when a node is unsubscribed from autocompounding
        // TODO calculate the rewards for each bloom with a STANDARD_FEE, and it should not affect tierLevel
        uint256 lastUpdatedClaimIndexLocal = _lastUpdatedClaimIndex;

        while (_numNodes > 0) {
            if (_bloomsClaimable.length == 0) {
                break;
            }
            // changed from _lastUpdatedClaimIndex to lastUpdatedClaimIndexLocal
            if (lastUpdatedClaimIndexLocal >= _bloomsClaimable.length) {
                lastUpdatedClaimIndexLocal = 0;
            }

            // changed from _lastUpdatedClaimIndex to lastUpdatedClaimIndexLocal
            uint256 bloomId = _bloomsClaimable[lastUpdatedClaimIndexLocal];
            BloomEntity storage bloom = _blooms[bloomId];

            _removeNodeFromClaimable(lastUpdatedClaimIndexLocal);

            uint256 rewardAmount = _autoclaimRewards(bloomId);

            _cashoutReward(rewardAmount, STANDARD_FEE, bloom.owner);

            lastUpdatedClaimIndexLocal++;
            _numNodes--;

            emit Autoclaim(bloom.owner, bloomId, rewardAmount);
        }

        _lastUpdatedClaimIndex = lastUpdatedClaimIndexLocal;
    }

    /**
     * @dev - Claims the rewards of the users locked-for-autocompounding Bloom node
     * @notice - Fees for the emergencyClaim function are substantially higher than the normal claim function
     * @param _bloomId - Id of the Bloom node
     */
    function emergencyClaim(uint256 _bloomId)
        external
        nonReentrant
        whenNotPaused
        onlyApprovedOrOwnerOfBloom(_bloomId)
    {
        BloomEntity storage bloom = _blooms[_bloomId];
        require(block.timestamp < bloom.lockedUntil, "8");

        // bug - _bloomId2Index[_bloomId] will try to access the array at an out-of-bounds index, due to place-swapping and poping methods
        // FIXED
        _unsubscribeNodeFromAutoCompounding(_bloomId2Index[_bloomId]);
        _resetRewardMultiplier(_bloomId);

        uint256 amountToReward = _emergencyReward(_bloomId);
        uint256 emergencyFee = _updateEmergencyStatus(_msgSender())
        ._getEmergencyFee();

        bloom.lockedUntil = block.timestamp;
        bloom.totalClaimed += amountToReward;
        _cashoutReward(amountToReward, emergencyFee, bloom.owner);

        emit EmergencyClaim(
            _msgSender(),
            _bloomId,
            amountToReward,
            emergencyFee
        );
    }

    /**
     * @dev - Burns the specified Bloom node
     * @param _bloomId - ID of the bloom node
     */
    function burn(uint256 _bloomId)
        external
        override
        nonReentrant
        whenNotPaused
        onlyApprovedOrOwnerOfBloom(_bloomId)
    {
        _burn(_bloomId);
    }

    //
    // OWNER SETTER FUNCTIONS
    //

    /**
     * @dev - Changes the minimum price for the creation of a Bloom node
     * @param _creationMinPrice - Wanted minimum price of a Bloom node
     */
    function setNodeMinPrice(uint256 _creationMinPrice) external onlyOwner {
        creationMinPrice = _creationMinPrice;
    }

    /**
     * @dev - Changes the compound delay time
     * @param _compoundDelay - Wanted compound delay
     */
    function setCompoundDelay(uint256 _compoundDelay) external onlyOwner {
        compoundDelay = _compoundDelay;
    }

    /**
     * @dev - Sets the reward per day to the specified _amount
     * @param _amount - Wanted reward per day cap
     */
    function setRewardPerDay(uint256 _amount) external onlyOwner {
        rewardPerDay = _amount;
    }

    /**
     * @dev - Sets the Liquidity Manager address
     * @param _liquidityManager - Address of the Liquidity Manager contract
     */
    function setLiquidityManager(address _liquidityManager) public onlyOwner {
        liquidityManager = ILiquidityManager(_liquidityManager);
    }

    /**
     * @dev - Changes the tier levels and tier slope
     * @param _tierLevel - Wanted tier level array
     * @param _tierSlope - Wanted tier slope array
     * @notice - _tierLevel array contains reward multipliers, white _tierSlope contains the amount of compounds needed to increase the _tierLevel
     */
    function changeTierSystem(
        uint24[10] memory _tierLevel,
        uint8[10] memory _tierSlope
    ) external onlyOwner {
        tierLevel = _tierLevel;
        tierSlope = _tierSlope;
    }

    //
    // EXTERNAL VIEW FUNCTIONS
    //

    /**
     * @dev - Gets the BloomInfo of the specified number of Bloom nodes
     * @param _bloomIds - IDs of the Bloom nodes
     * @return BloomInfoEntity[] - Returns an array of info for the specified number of Bloom nodes
     */
    function getBloomsByIds(uint256[] memory _bloomIds)
        external
        view
        override
        returns (BloomInfoEntity[] memory)
    {
        BloomInfoEntity[] memory bloomsInfo = new BloomInfoEntity[](
            _bloomIds.length
        );

        for (uint256 i = 0; i < _bloomIds.length; i++) {
            BloomEntity memory bloom = _blooms[_bloomIds[i]];

            bloomsInfo[i] = BloomInfoEntity(
                bloom,
                _bloomIds[i],
                _calculateReward(bloom),
                _rewardPerDayFor(bloom),
                compoundDelay
            );
        }

        return bloomsInfo;
    }

    /**
     * @dev - Calculates the total daily rewards of all the tiers combined
     * @return uint256 - Returns the calculated daily emission amount
     */
    function calculateTotalDailyEmission()
        external
        view
        override
        returns (uint256)
    {
        uint256 dailyEmission = 0;
        for (uint256 i = 0; i < _tiersTracked.length; i++) {
            TierStorage memory tierStorage = tierTracking[_tiersTracked[i]];
            dailyEmission += tierStorage
            .amountLockedInTier
            ._calculateRewardsFromValue(
                tierStorage.rewardMult,
                compoundDelay,
                rewardPerDay
            );
        }

        return dailyEmission;
    }

    //
    // PRIVATE FUNCTIONS
    //

    /**
     * @dev - Calculates Bloom cashout rewards and updates the state of the Bloom node
     * @param _bloomId - Id of the Bloom node
     * @notice - This function resets the progress of the Bloom node
     */
    function _emergencyReward(uint256 _bloomId) private returns (uint256) {
        BloomEntity storage bloom = _blooms[_bloomId];

        uint256 reward = _calculateReward(bloom);

        if (bloom.rewardMult > tierLevel[0]) {
            _logTier(bloom.rewardMult, -int256(bloom.bloomValue));

            for (uint256 i = 1; i < tierLevel.length; i++) {
                // TODO Is break necessary for the loop to stop?
                if (bloom.rewardMult == tierLevel[i]) {
                    bloom.rewardMult = tierLevel[i - 1];
                    bloom.timesCompounded = tierSlope[i - 1];

                    break;
                }
            }
            _logTier(bloom.rewardMult, int256(bloom.bloomValue));
        }

        bloom.lastProcessingTimestamp = block.timestamp;

        return reward;
    }

    /**
     * @dev - Calculates the Bloom compound rewards of the specified Bloom node and updates its state
     * @param _bloomId - Id of the Bloom node
     */
    function _getRewardsAndCompound(uint256 _bloomId)
        private
        returns (uint256, uint256)
    {
        BloomEntity storage bloom = _blooms[_bloomId];

        if (!_isProcessable(bloom.lastProcessingTimestamp)) {
            return (0, 0);
        }

        uint256 reward = _calculateReward(bloom);

        if (reward > 0) {
            (uint256 amountToCompound, uint256 feeAmount) = reward
            ._getProcessingFee(STANDARD_FEE);

            totalValueLocked += amountToCompound;

            // First remove the bloomValue out of the current tier, in case the reward multiplier increases
            _logTier(bloom.rewardMult, -int256(bloom.bloomValue));

            bloom.lastProcessingTimestamp = block.timestamp;
            bloom.bloomValue += amountToCompound;

            // Increase tierLevel
            bloom.rewardMult = _checkMultiplier(
                bloom.rewardMult,
                ++bloom.timesCompounded
            );

            // Add the bloomValue to the current tier
            _logTier(bloom.rewardMult, int256(bloom.bloomValue));

            return (amountToCompound, feeAmount);
        }

        return (0, 0);
    }

    /**
     * @dev - Mints the reward amount to the user, minus the fee, and burns the fee
     * @param _amount - Previously calculated reward amount of the user-owned Bloom node
     * @param _fee - Fee amount (could either be emergencyFee or constant CREATION_FEE)
     */
    function _cashoutReward(
        uint256 _amount,
        uint256 _fee,
        address _to
    ) private {
        require(_amount > 0, "2");
        (uint256 amountToReward, uint256 feeAmount) = _amount._getProcessingFee(
            _fee
        );

        nectar.mintNectar(_to, amountToReward);
        /// @notice - The burnNectar function will not work if there is not enough $NCTR in this contract
        ///           Meaning that the nectar.balanceOf(address(this)) always needs to be greater than the feeAmount
        nectar.burnNectar(address(this), feeAmount);
    }

    /**
     * @dev Updates tier storage
     * @param _multiplier - Bloom/Tier reward multiplier
     * @param _amount - Addition to amountLockedInTier
     */
    function _logTier(uint256 _multiplier, int256 _amount) private {
        TierStorage storage tierStorage = tierTracking[_multiplier];

        if (tierStorage.exists) {
            // TODO Check if this require is redundant
            require(tierStorage.rewardMult == _multiplier, "4");

            uint256 newAmountLockedInTier = uint256(
                int256(tierStorage.amountLockedInTier) + _amount
            );

            require(newAmountLockedInTier >= 0, "5");
            tierStorage.amountLockedInTier = newAmountLockedInTier;

            return;
        }

        // tier isn't registered exist, register it
        require(_amount > 0, "2");
        tierTracking[_multiplier] = TierStorage({
            rewardMult: _multiplier,
            amountLockedInTier: uint256(_amount),
            exists: true
        });

        _tiersTracked.push(_multiplier);
    }

    //
    // PRIVATE VIEW FUNCTIONS
    //

    /**
     * @dev - Increases the rewardMult param of the Bloom node if the number of compounds reached a certain threshold
     * @param _prevMult - Previous/current rewardMult of the Bloom node
     * @param _timesCompounded - Number of Bloom node compounds
     * @return - Either the increased or the previous/current multiplier
     */
    function _checkMultiplier(uint256 _prevMult, uint256 _timesCompounded)
        private
        view
        returns (uint256)
    {
        if (
            _prevMult < tierLevel[tierLevel.length - 1] &&
            _timesCompounded <= tierSlope[tierSlope.length - 1]
        ) {
            for (uint256 i = 0; i < tierSlope.length; i++) {
                if (_timesCompounded == tierSlope[i]) {
                    return tierLevel[i];
                }
            }
        }

        return _prevMult;
    }

    /**
     * @dev - Checks if the compoundDelay time has passed for the Bloom node
     * @param _lastProcessingTimestamp - Last time the Bloom node was processed
     * @return bool - Returns true if the compoundDelay has passed, false if it hasn't
     */
    function _isProcessable(uint256 _lastProcessingTimestamp)
        private
        view
        returns (bool)
    {
        return block.timestamp >= _lastProcessingTimestamp + compoundDelay;
    }

    /**
     * @dev - Calculates the rewards of the specified Bloom node
     * @param _bloom - Bloom node
     * @return uint256 - Returns the calculated reward amount
     */
    function _calculateReward(BloomEntity memory _bloom)
        private
        view
        returns (uint256)
    {
        return
            _bloom.bloomValue._calculateRewardsFromValue(
                _bloom.rewardMult,
                block.timestamp - _bloom.lastProcessingTimestamp,
                rewardPerDay
            );
    }

    /**
     * @dev - Calculates the rewards per day for the specified Bloom node
     * @param _bloom - Bloom node
     * @return uint256 - Returns the calculated reward per day amount
     */
    function _rewardPerDayFor(BloomEntity memory _bloom)
        private
        view
        returns (uint256)
    {
        return
            _bloom.bloomValue._calculateRewardsFromValue(
                _bloom.rewardMult,
                compoundDelay,
                rewardPerDay
            );
    }

    /**
     * @dev - Checks if the Bloom node exists
     * @param _bloomId - ID of the Bloom node
     */
    function _bloomExists(uint256 _bloomId) private view returns (bool) {
        require(_bloomId > 0, "9");
        BloomEntity memory bloom = _blooms[_bloomId];

        return bloom.exists;
    }

    /**
     * @dev - Checks if the user is an owner of a Bloom node
     * @param _account - Address of the specified user
     * @return bool - Returns True if the user is an owner, false if he's not
     */
    function _isOwnerOfBlooms(address _account) private view returns (bool) {
        return bloomNFT.balanceOf(_account) > 0;
    }

    /**
     * @dev - Checks if the specified user is the owner of the Bloom node or is approved
     * @param _account - Address of the specified user
     * @param _bloomId - ID of the Bloom node
     * @return bool - Returns true if the user is the owner or is approved by the owner
     */
    function _isApprovedOrOwnerOfBloom(address _account, uint256 _bloomId)
        private
        view
        returns (bool)
    {
        return bloomNFT.isApprovedOrOwner(_account, _bloomId);
    }

    //
    // TOKEN DISTRIBUTION FUNCTIONS
    //

    // /**
    //  * @dev - Swaps half the amount of deposited $USDC.e for $NCTR
    //  *      - Burns the percentage (80%) of the swapped-for $NCTR and trasnfers the same percentage of $USDC.e to the treasury address
    //  *      - Adds the leftover percentage of both tokens (20%) to the liquidity pool
    //  * @param _value - Deposited value amount
    //  * @notice - Called when users create Bloom nodes with $USDC.e
    //  */
    // function _swapAndBurn(uint256 _value) private {
    //     (
    //         uint256 half,
    //         uint256 usdcToTreasuryAmount,
    //         uint256 usdcToLiquidityAmount
    //     ) = _value._getAmounts();

    //     uint256 nctrAmountOut = _routerSwap(
    //         address(usdc),
    //         address(nectar),
    //         half
    //     );

    //     uint256 nctrBurnAmount = (nctrAmountOut * 80) / 100;
    //     uint256 nctrToLiquidityAmount = nctrAmountOut - nctrBurnAmount;

    //     nectar.burnNectar(address(this), nctrBurnAmount);
    //     usdc.transfer(treasury, usdcToTreasuryAmount);

    //     _routerAddLiquidity(nctrToLiquidityAmount, usdcToLiquidityAmount);
    // }

    // /**
    //  * @dev - Swaps tokenA for tokenB using the router function
    //  * @param _tokenA - Address of tokenA
    //  * @param _tokenB - Address of tokenB
    //  * @param _half - Half the deposited amount of tokens
    //  * @return uint256 - Returns the amount of tokenB it got out of the swap
    //  */
    // function _routerSwap(
    //     address _tokenA,
    //     address _tokenB,
    //     uint256 _half
    // ) private returns (uint256) {
    //     address[] memory path = new address[](2);
    //     path[0] = _tokenA;
    //     path[1] = _tokenB;

    //     uint256 tokenBAmountOut = router.swapExactTokensForTokens(
    //         _half,
    //         0,
    //         path,
    //         address(this),
    //         type(uint256).max
    //     )[1];

    //     return tokenBAmountOut;
    // }

    // /**
    //  * @dev - Adds liquidity to the liquidity pool
    //  * @param _nctrToLiquidityAmount - Amount of $NCTR to add
    //  * @param _usdcToLiquidityAmount - Amount of $USDC.e to add
    //  */
    // function _routerAddLiquidity(
    //     uint256 _nctrToLiquidityAmount,
    //     uint256 _usdcToLiquidityAmount
    // ) private {
    //     nectar.approve(address(router), _nctrToLiquidityAmount);
    //     usdc.approve(address(router), _usdcToLiquidityAmount);
    //     router.addLiquidity(
    //         address(usdc),
    //         address(nectar),
    //         _usdcToLiquidityAmount,
    //         _nctrToLiquidityAmount,
    //         0,
    //         0,
    //         address(router),
    //         type(uint256).max
    //     );
    // }

    //
    // HELPER FUNCTIONS
    //

    /**
     * @dev Deposits USDC or NCTR based on the whitelist status of sender
     * @param _value - Value to deposit
     * @return nctrValue - If the user deposits in $USDC.e, calculations need to be made to get actual $NCTR value of the deposit
     */
    function _deposit(uint256 _value) private returns (uint256 nctrValue) {
        if (whitelist.isWhitelisted(_msgSender())) {
            nctrValue = _whitelistedDeposit(_value);
        } else {
            nctrValue = _nonWhitelistedDeposit(_value);
        }
    }

    /**
     * @dev Whitelist only deposit
     * @notice Deposits NCTR if it is approved, else deposits USDC
     * @param _value - Value to deposit
     * @return nctrValue - $USDC.e value quoted in $NCTR
     */
    function _whitelistedDeposit(uint256 _value)
        private
        returns (uint256 nctrValue)
    {
        if (nectar.transferFrom(_msgSender(), address(this), _value)) {
            nectar.burnNectar(address(this), _value);

            nctrValue = _value;
        } else if (usdc.transferFrom(_msgSender(), address(this), _value)) {
            uint256 half = _value / 2;
            // uint256 usdcPriceInNectar = (usdc.balanceOf(address(liquidityManager)) *
            //     10**12) / nectar.balanceOf(address(liquidityManager));
            usdc.approve(address(nectar), half);
            nectar.swapUsdcForToken(half, half);

            // uint256 usdcTo18Decimals = usdc.balanceOf(address(liquidityManager)) *
            //     10**12;
            nctrValue = half;
        } else {
            revert("3");
        }
    }

    /**
     * @dev Non whitelist deposit
     * @notice Deposits USDC
     * @param _value - Value to deposit
     * @return nctrValue - $USDC.e value quoted in $NCTR
     */
    function _nonWhitelistedDeposit(uint256 _value)
        private
        returns (uint256 nctrValue)
    {
        require(usdc.transferFrom(_msgSender(), address(this), _value), "3");

        uint256 half = _value / 2;
        // uint256 usdcPriceInNectar = (usdc.balanceOf(address(liquidityManager)) *
        //     10**12) / nectar.balanceOf(address(liquidityManager));

        usdc.approve(address(liquidityManager), half);
        nectar.swapUsdcForToken(half, half);

        // uint256 usdcTo18Decimals = usdc.balanceOf(address(liquidityManager)) * 10**12;
        nctrValue = half;
    }

    /**
     * @dev - Unsubscribes the Bloom node from auto compounding when the specified lock period is over
     * @param _nodeIndex - Index of the Bloom node in the array
     */
    function _unsubscribeNodeFromAutoCompounding(uint256 _nodeIndex) private {
        if (_bloomsCompounding.length == 1) {
            _bloomsCompounding.pop();
            return;
        }

        // Get the bloomId of the node which will be swapped for and delete it from the current position
        uint256 bloomIdToKeep = _bloomsCompounding[
            _bloomsCompounding.length - 1
        ];
        uint256 indexTo = _nodeIndex;
        delete _bloomId2Index[bloomIdToKeep];

        // Swap to last position in the array so bloomId at _bloomsCompounding[_nodeIndex] can be popped
        _bloomsCompounding[_nodeIndex] = _bloomsCompounding[
            _bloomsCompounding.length - 1
        ];

        // Delete popped bloomId from mapping
        uint256 bloomIdToDelete = _bloomsCompounding[_nodeIndex];
        delete _bloomId2Index[bloomIdToDelete];

        // Add swapped-for bloomId back to the mapping at _nodeIndex
        _bloomId2Index[bloomIdToKeep] = indexTo;

        // Pop _bloomsCompounding[_nodeIndex] from the array
        _bloomsCompounding.pop();
    }

    /**
     * @dev - Removes the Bloom node from the _bloomsClaimable array once the rewards are claimed with the autoclaim function
     * @param _nodeIndex - Index of the Bloom node in the array
     */
    function _removeNodeFromClaimable(uint256 _nodeIndex) private {
        if (_bloomsClaimable.length == 1) {
            _bloomsClaimable.pop();
            return;
        }

        _bloomsClaimable[_nodeIndex] = _bloomsClaimable[
            _bloomsClaimable.length - 1
        ];
        _bloomsClaimable.pop();
    }

    /**
     * @dev - Checks and updates the emergency stats of the sender
     * @param _sender - Address of the emergencyClaim caller
     * @return uint256 - Returns the number of user emergency claims in a week
     */
    function _updateEmergencyStatus(address _sender) private returns (uint256) {
        EmergencyStats storage emergencyStats = _emergencyStats[_sender];

        if (block.timestamp >= 7 days + emergencyStats.emergencyClaimTime) {
            emergencyStats.userEmergencyClaims = 0;
            emergencyStats.emergencyClaimTime = block.timestamp;
        }

        return ++emergencyStats.userEmergencyClaims;
    }

    /**
     * @dev - Calculates the rewards for the autoclaim function and updates Bloom stats
     * @param _bloomId - Id of the Bloom node
     */
    function _autoclaimRewards(uint256 _bloomId) private returns (uint256) {
        BloomEntity storage bloom = _blooms[_bloomId];
        require(_isProcessable(bloom.lastProcessingTimestamp), "14");

        uint256 reward = _calculateReward(bloom);

        bloom.totalClaimed += reward;
        bloom.lastProcessingTimestamp = block.timestamp;

        return reward;
    }

    /**
     * @dev - Resets the reward multiplier if it was increased when the Bloom node was locked for autocompounding
     * @param _bloomId - Id of the Bloom node
     */
    function _resetRewardMultiplier(uint256 _bloomId) private {
        BloomEntity storage bloom = _blooms[_bloomId];

        uint256 multiplier;

        if (bloom.lockPeriod > 6 days) {
            multiplier = 15000;
        } else if (bloom.lockPeriod > 21 days) {
            multiplier = 25000;
        } else {
            multiplier = 0;
        }
        bloom.rewardMult -= multiplier;
    }

    //
    // OVERRIDES
    //

    /**
     * @dev - Burns the Bloom node of the _tokenId, and removes its value from the tier
     * @param _tokenId - ID of the Bloom node
     */
    // TODO Could possibly rename this function
    function _burn(uint256 _tokenId) internal {
        BloomEntity storage bloom = _blooms[_tokenId];
        bloom.exists = false;

        _logTier(bloom.rewardMult, -int256(bloom.bloomValue));

        bloomNFT.burnBloom(_tokenId);
    }
}

//
// REDUNDANT FUNCTIONS
//

// /**
//  * @dev - Claims the earned reward of the Bloom node
//  * @param _bloomId - Id of the Bloom node
//  */
// function cashoutReward(uint256 _bloomId)
//     external
//     nonReentrant
//     whenNotPaused
//     onlyApprovedOrOwnerOfBloom(_bloomId)
// {
//     BloomEntity memory bloom = _blooms[_bloomId];
//     require(block.timestamp >= bloom.lockedUntil, "8");

//     uint256 amountToReward = _emergencyReward(_bloomId);
//     _cashoutReward(amountToReward, STANDARD_FEE);

//     emit Cashout(_msgSender(), _bloomId, amountToReward);
// }

// /**
//  * @dev - Claims the earned rewards of all the user-owned Bloom nodes
//  */
// function cashoutAll() external nonReentrant whenNotPaused onlyBloomOwner {
//     uint256 rewardsTotal = 0;
//     uint256[] memory bloomsOwned = _getBloomIdsOf(_msgSender());

//     for (uint256 i = 0; i < bloomsOwned.length; i++) {
//         if (block.timestamp < _blooms[bloomsOwned[i]].lockedUntil) {
//             continue;
//         }

//         rewardsTotal += _emergencyReward(bloomsOwned[i]);
//     }

//     if (rewardsTotal == 0) {
//         return;
//     }

//     _cashoutReward(rewardsTotal, STANDARD_FEE);

//     emit CashoutAll(_msgSender(), bloomsOwned, rewardsTotal);
// }

// /**
//  * @dev - Compounds the earned reward of the Bloom node
//  * @param _bloomId - Id of the Bloom node
//  */
// function compoundReward(uint256 _bloomId)
//     external
//     nonReentrant
//     whenNotPaused
//     onlyApprovedOrOwnerOfBloom(_bloomId)
// {
//     (uint256 amountToCompound, uint256 feeAmount) = _getRewardsAndCompound(
//         _bloomId
//     );

//     if (feeAmount > 0) {
//         nectar.liquidityReward(feeAmount);
//     }

//     if (amountToCompound <= 0) {
//         return;
//     }

//     emit Compound(_msgSender(), _bloomId, amountToCompound);
// }

// /**
//  * @dev - Compounds the earned rewards of all the user-owned Bloom nodes
//  */
// function compoundAll() external nonReentrant whenNotPaused onlyBloomOwner {
//     uint256 feesAmount = 0;
//     uint256 amountToCompoundSum = 0;

//     uint256[] memory bloomsOwned = _getBloomIdsOf(_msgSender());
//     uint256[] memory bloomsAffected = new uint256[](bloomsOwned.length);

//     for (uint256 i = 0; i < bloomsOwned.length; i++) {
//         (
//             uint256 amountToCompound,
//             uint256 feeAmount
//         ) = _getRewardsAndCompound(bloomsOwned[i]);

//         if (amountToCompound > 0) {
//             bloomsAffected[i] = bloomsOwned[i];
//             feesAmount += feeAmount;
//             amountToCompoundSum += amountToCompound;
//         } else {
//             delete bloomsAffected[i];
//         }
//     }

//     if (feesAmount > 0) {
//         nectar.liquidityReward(feesAmount);
//     }

//     emit CompoundAll(_msgSender(), bloomsAffected, amountToCompoundSum);
// }

// /**
//  * @dev - Swaps half the amount of deposited $NCTR for $USDC.e
//  *      - Burns the percentage (80%) of the leftover $NCTR and trasnfers the same percentage of $USDC.e to the treasury address
//  *      - Adds the leftover percentage of both (20%) to the liquidity pool
//  * @param _value - Deposited value amount
//  * @notice - Called when whitelisted users create Bloom nodes with $NCTR
//  */
// function _burnAndSend(uint256 _value) private {
//     (
//         uint256 half,
//         uint256 nctrBurnAmount,
//         uint256 nctrToLiquidityAmount
//     ) = _value._getAmounts();

//     uint256 usdcAmountOut = _routerSwap(
//         address(nectar),
//         address(usdc),
//         half
//     );

//     uint256 usdcToTreasuryAmount = (usdcAmountOut * 80) / 100;
//     uint256 usdcToLiquidityAmount = usdcAmountOut - usdcToTreasuryAmount;

//     nectar.burnNectar(address(this), nctrBurnAmount);
//     usdc.transfer(treasury, usdcToTreasuryAmount);

//     _routerAddLiquidity(nctrToLiquidityAmount, usdcToLiquidityAmount);
// }

// /**
//  * @dev - Gets the IDs of all the user-owned Bloom nodes
//  * @param _account - User's address
//  * @return uint256[] - Returns an array of Bloom node IDs
//  */
// function _getBloomIdsOf(address _account)
//     private
//     view
//     returns (uint256[] memory)
// {
//     uint256 numberOfblooms = balanceOf(_account);
//     uint256[] memory bloomIds = new uint256[](numberOfblooms);

//     for (uint256 i = 0; i < numberOfblooms; i++) {
//         uint256 bloomId = tokenOfOwnerByIndex(_account, i);
//         require(_bloomExists(bloomId), "10");

//         bloomIds[i] = bloomId;
//     }

//     return bloomIds;
// }

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
pragma solidity ^0.8.13;

interface ILiquidityManager {
    function swapUsdcForToken(
        address to,
        uint256 amountIn,
        uint256 amountOutMin
    ) external;

    function swapTokenForUsdc(
        address to,
        uint256 amountIn,
        uint256 amountOutMin
    ) external;

    function swapTokenForUSDCToWallet(
        address from,
        address destination,
        uint256 tokenAmount,
        uint256 slippage
    ) external;

    function enableLiquidityManager(bool value) external;

    function setRewardAddr(address _rewardPool) external;

    function setTreasuryAddr(address _treasury) external;

    function setTokenContractAddr(address _token) external;

    function setSwapPair(address _pair) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IWhitelist {
    function isWhitelisted(address _address) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IBloomNFT {
    /**
     * @dev - Mint function
     * @param _to - Address of the user
     * @param _tokenId - ID of the token the user wants
     */
    function mintBloom(address _to, uint256 _tokenId) external;

    /**
     * @dev - Burn function
     * @param _tokenId - ID of the token the user wants
     */
    function burnBloom(uint256 _tokenId) external;

    function isApprovedOrOwner(address _spender, uint256 _tokenId)
        external
        view
        returns (bool);

    function balanceOf(address owner) external view returns (uint256 balance);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IBloomsManagerUpgradeable {
    error Value();

    event Autoclaim(
        address indexed account,
        uint256 indexed bloomId,
        uint256 rewardAmount
    );

    event Autocompound(
        address indexed account,
        uint256 indexed bloomId,
        uint256 amountToCompound
    );

    event EmergencyClaim(
        address indexed account,
        uint256 indexed bloomId,
        uint256 amountToReward,
        uint256 emergencyFee
    );

    event Create(
        address indexed account,
        uint256 indexed newbloomId,
        uint256 amount
    );

    event Rename(
        address indexed account,
        string indexed previousName,
        string indexed newName
    );

    event AdditionalDeposit(uint256 indexed bloomId, uint256 amount);

    struct BloomInfoEntity {
        BloomEntity Bloom;
        uint256 id;
        uint256 pendingRewards;
        uint256 rewardPerDay;
        uint256 compoundDelay;
    }

    struct BloomEntity {
        address owner;
        uint256 id;
        string name;
        uint256 creationTime;
        uint256 lastProcessingTimestamp;
        uint256 rewardMult;
        uint256 bloomValue;
        uint256 totalClaimed;
        uint256 timesCompounded;
        uint256 lockedUntil;
        uint256 lockPeriod;
        bool exists;
    }

    struct TierStorage {
        uint256 rewardMult;
        uint256 amountLockedInTier;
        bool exists;
    }

    struct EmergencyStats {
        uint256 userEmergencyClaims;
        uint256 emergencyClaimTime;
    }

    function renameBloom(uint256 _bloomId, string memory _bloomName) external;

    function createBloomWithTokens(
        string memory _bloomName,
        uint256 _bloomValue
    ) external;

    function addValue(uint256 _bloomId, uint256 _value) external;

    function startAutoCompounding(uint256 _bloomId, uint256 _duration) external;

    function emergencyClaim(uint256 _bloomId) external;

    function calculateTotalDailyEmission() external view returns (uint256);

    function getBloomsByIds(uint256[] memory _bloomIds)
        external
        view
        returns (BloomInfoEntity[] memory);

    function burn(uint256 _bloomId) external;
}

//
// REDUNDANT FUNCTIONS
//

// function cashoutReward(uint256 _bloomId) external;

// function cashoutAll() external;

// function compoundReward(uint256 _bloomId) external;

// function compoundAll() external;

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../interfaces/INectar.sol";

abstract contract NectarImplementationPointerUpgradeable is OwnableUpgradeable {
    INectar internal nectar;

    event UpdateNectar(
        address indexed oldImplementation,
        address indexed newImplementation
    );

    modifier onlyNectar() {
        require(
            address(nectar) != address(0),
            "Implementations: nectar is not set"
        );
        address sender = _msgSender();
        require(sender == address(nectar), "Implementations: Not nectar");
        _;
    }

    function getNectarImplementation() public view returns (address) {
        return address(nectar);
    }

    function changeNectarImplementation(address newImplementation)
        public
        virtual
        onlyOwner
    {
        address oldImplementation = address(nectar);
        require(
            AddressUpgradeable.isContract(newImplementation) ||
                newImplementation == address(0),
            "Nectar: You can only set 0x0 or a contract address as a new implementation"
        );
        nectar = INectar(newImplementation);
        emit UpdateNectar(oldImplementation, newImplementation);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

library BloomsManagerUpgradeableLib {
    // Calculates the fee amount when the user uses the emergencyClaim function
    // based on the amount of emergency claims made in a week
    function _getEmergencyFee(uint256 _emergencyClaims)
        internal
        pure
        returns (uint256 emergencyFeeAmount)
    {
        if (_emergencyClaims == 1) {
            emergencyFeeAmount = 50;
        } else if (_emergencyClaims == 2) {
            emergencyFeeAmount = 60;
        } else if (_emergencyClaims == 3) {
            emergencyFeeAmount = 70;
        } else if (_emergencyClaims == 4) {
            emergencyFeeAmount = 80;
        } else {
            emergencyFeeAmount = 90;
        }
    }

    // Private view functions
    function _getProcessingFee(uint256 _rewardAmount, uint256 _feeAmount)
        internal
        pure
        returns (uint256, uint256)
    {
        uint256 feeAmount = 0;
        if (_feeAmount > 0) {
            feeAmount = (_rewardAmount * _feeAmount) / 100;
        }

        return (_rewardAmount - feeAmount, feeAmount);
    }

    function _calculateRewardsFromValue(
        uint256 _bloomValue,
        uint256 _rewardMult,
        uint256 _timeRewards,
        uint256 _rewardPerDay
    ) internal pure returns (uint256) {
        uint256 rewards = (_timeRewards * _rewardPerDay) / 1000000;
        uint256 rewardsMultiplied = (rewards * _rewardMult) / 100000;
        return (rewardsMultiplied * _bloomValue) / 100000;
    }

    function _getAmounts(uint256 _value)
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 half = _value / 2;
        uint256 burnOrTreasuryPercentage = (half * 80) / 100;
        uint256 liquidityPercentage = half - burnOrTreasuryPercentage;

        return (half, burnOrTreasuryPercentage, liquidityPercentage);
    }
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface INectar is IERC20 {
    function owner() external view returns (address);

    function burnNectar(address account, uint256 amount) external;

    function mintNectar(address account, uint256 amount) external;

    function liquidityReward(uint256 amount) external;

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) external;

    function swapUsdcForToken(uint256 amountIn, uint256 amountOutMin) external;

    function swapTokenForUsdc(uint256 amountIn, uint256 amountOutMin) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
}