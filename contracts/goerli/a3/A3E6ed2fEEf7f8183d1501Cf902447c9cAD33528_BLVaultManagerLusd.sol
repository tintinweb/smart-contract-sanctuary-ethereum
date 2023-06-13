// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

// Import system dependencies
import {MINTRv1} from "src/modules/MINTR/MINTR.v1.sol";
import {ROLESv1, RolesConsumer} from "src/modules/ROLES/OlympusRoles.sol";
import {TRSRYv1} from "src/modules/TRSRY/TRSRY.v1.sol";
import {BLREGv1} from "src/modules/BLREG/BLREG.v1.sol";
import "src/Kernel.sol";

// Import external dependencies
import {AggregatorV3Interface} from "interfaces/AggregatorV2V3Interface.sol";
import {IAuraRewardPool, IAuraMiningLib, ISTASHToken} from "policies/BoostedLiquidity/interfaces/IAura.sol";
import {JoinPoolRequest, ExitPoolRequest, IVault, IBasePool, IBalancerHelper} from "policies/BoostedLiquidity/interfaces/IBalancer.sol";

// Import vault dependencies
import {RewardsData} from "policies/BoostedLiquidity/interfaces/IBLVault.sol";
import {IBLVaultManager} from "policies/BoostedLiquidity/interfaces/IBLVaultManager.sol";
import {BLVaultLusd} from "policies/BoostedLiquidity/BLVaultLusd.sol";

// Import types
import {OlympusERC20Token} from "src/external/OlympusERC20.sol";

// Import libraries
import {ClonesWithImmutableArgs} from "clones/ClonesWithImmutableArgs.sol";

contract BLVaultManagerLusd is Policy, IBLVaultManager, RolesConsumer {
    using ClonesWithImmutableArgs for address;

    // ========= ERRORS ========= //

    error BLManagerLusd_AlreadyActive();
    error BLManagerLusd_AlreadyInactive();
    error BLManagerLusd_Inactive();
    error BLManagerLusd_InvalidVault();
    error BLManagerLusd_LimitViolation();
    error BLManagerLusd_InvalidLpAmount();
    error BLManagerLusd_InvalidLimit();
    error BLManagerLusd_InvalidFee();
    error BLManagerLusd_BadPriceFeed();
    error BLManagerLusd_VaultAlreadyExists();
    error BLManagerLusd_NoUserVault();

    // ========= EVENTS ========= //

    event VaultDeployed(address vault, address owner, uint64 fee);

    // ========= STATE VARIABLES ========= //

    // Modules
    MINTRv1 public MINTR;
    TRSRYv1 public TRSRY;
    BLREGv1 public BLREG;

    // Tokens
    address public ohm;
    address public pairToken; // LUSD for this implementation
    address public aura;
    address public bal;

    // Exchange Info
    string public exchangeName;
    BalancerData public balancerData;

    // Aura Info
    AuraData public auraData;
    IAuraMiningLib public auraMiningLib;

    // Oracle Info
    OracleFeed public ohmEthPriceFeed;
    OracleFeed public ethUsdPriceFeed;
    OracleFeed public lusdUsdPriceFeed;

    // Vault Info
    BLVaultLusd public implementation;
    mapping(BLVaultLusd => address) public vaultOwners;
    mapping(address => BLVaultLusd) public userVaults;

    // Vaults State
    uint256 public totalLp;
    uint256 public deployedOhm;
    uint256 public circulatingOhmBurned;

    // System Configuration
    uint256 public ohmLimit;
    uint64 public currentFee;
    uint48 public minWithdrawalDelay;
    bool public isLusdBLVaultActive;

    // Constants
    uint32 public constant MAX_FEE = 10_000; // 100%
    uint8 private constant _ohmIndex = 1;
    uint8 private constant _lusdIndex = 0;

    //============================================================================================//
    //                                      POLICY SETUP                                          //
    //============================================================================================//

    constructor(
        Kernel kernel_,
        TokenData memory tokenData_,
        BalancerData memory balancerData_,
        AuraData memory auraData_,
        address auraMiningLib_,
        OracleFeed memory ohmEthPriceFeed_,
        OracleFeed memory ethUsdPriceFeed_,
        OracleFeed memory lusdUsdPriceFeed_,
        address implementation_,
        uint256 ohmLimit_,
        uint64 fee_,
        uint48 minWithdrawalDelay_
    ) Policy(kernel_) {
        // Set exchange name
        {
            exchangeName = "Balancer";
        }

        // Set tokens
        {
            ohm = tokenData_.ohm;
            pairToken = tokenData_.pairToken;
            aura = tokenData_.aura;
            bal = tokenData_.bal;
        }

        // Set exchange info
        {
            balancerData = balancerData_;
        }

        // Set Aura Pool
        {
            auraData = auraData_;
            auraMiningLib = IAuraMiningLib(auraMiningLib_);
        }

        // Set oracle info
        {
            ohmEthPriceFeed = ohmEthPriceFeed_;
            ethUsdPriceFeed = ethUsdPriceFeed_;
            lusdUsdPriceFeed = lusdUsdPriceFeed_;
        }

        // Set vault implementation
        {
            implementation = BLVaultLusd(implementation_);
        }

        // Configure system
        {
            ohmLimit = ohmLimit_;
            currentFee = fee_;
            minWithdrawalDelay = minWithdrawalDelay_;
        }
    }

    /// @inheritdoc Policy
    function configureDependencies() external override returns (Keycode[] memory dependencies) {
        dependencies = new Keycode[](4);
        dependencies[0] = toKeycode("MINTR");
        dependencies[1] = toKeycode("TRSRY");
        dependencies[2] = toKeycode("BLREG");
        dependencies[3] = toKeycode("ROLES");

        MINTR = MINTRv1(getModuleAddress(dependencies[0]));
        TRSRY = TRSRYv1(getModuleAddress(dependencies[1]));
        BLREG = BLREGv1(getModuleAddress(dependencies[2]));
        ROLES = ROLESv1(getModuleAddress(dependencies[3]));
    }

    /// @inheritdoc Policy
    function requestPermissions()
        external
        view
        override
        returns (Permissions[] memory permissions)
    {
        Keycode mintrKeycode = MINTR.KEYCODE();
        Keycode blregKeycode = BLREG.KEYCODE();

        permissions = new Permissions[](5);
        permissions[0] = Permissions(mintrKeycode, MINTR.mintOhm.selector);
        permissions[1] = Permissions(mintrKeycode, MINTR.burnOhm.selector);
        permissions[2] = Permissions(mintrKeycode, MINTR.increaseMintApproval.selector);
        permissions[3] = Permissions(blregKeycode, BLREG.addVault.selector);
        permissions[4] = Permissions(blregKeycode, BLREG.removeVault.selector);
    }

    //============================================================================================//
    //                                           MODIFIERS                                        //
    //============================================================================================//

    modifier onlyWhileActive() {
        if (!isLusdBLVaultActive) revert BLManagerLusd_Inactive();
        _;
    }

    modifier onlyVault() {
        if (vaultOwners[BLVaultLusd(msg.sender)] == address(0)) revert BLManagerLusd_InvalidVault();
        _;
    }

    //============================================================================================//
    //                                        VAULT DEPLOYMENT                                    //
    //============================================================================================//

    /// @inheritdoc IBLVaultManager
    function deployVault() external override onlyWhileActive returns (address vault) {
        if (address(userVaults[msg.sender]) != address(0))
            revert BLManagerLusd_VaultAlreadyExists();

        // Create clone of vault implementation
        bytes memory data = abi.encodePacked(
            msg.sender, // Owner
            this, // Vault Manager
            address(TRSRY), // Treasury
            address(MINTR), // Minter
            ohm, // OHM
            pairToken, // Pair Token (LUSD)
            aura, // Aura
            bal, // Balancer
            balancerData.vault, // Balancer Vault
            balancerData.liquidityPool, // Balancer Pool
            auraData.pid, // Aura PID
            auraData.auraBooster, // Aura Booster
            auraData.auraRewardPool, // Aura Reward Pool
            currentFee
        );
        BLVaultLusd clone = BLVaultLusd(address(implementation).clone(data));

        // Initialize clone of vault implementation (for reentrancy state)
        clone.initializeClone();

        // Set vault owner
        vaultOwners[clone] = msg.sender;
        userVaults[msg.sender] = clone;

        // Emit event
        emit VaultDeployed(address(clone), msg.sender, currentFee);

        // Return vault address
        return address(clone);
    }

    //============================================================================================//
    //                                         OHM MANAGEMENT                                     //
    //============================================================================================//

    /// @inheritdoc IBLVaultManager
    function mintOhmToVault(uint256 amount_) external override onlyWhileActive onlyVault {
        // Check that minting will not exceed limit
        if (deployedOhm + amount_ > ohmLimit + circulatingOhmBurned)
            revert BLManagerLusd_LimitViolation();

        deployedOhm += amount_;

        // Mint OHM
        MINTR.increaseMintApproval(address(this), amount_);
        MINTR.mintOhm(msg.sender, amount_);
    }

    /// @inheritdoc IBLVaultManager
    function burnOhmFromVault(uint256 amount_) external override onlyWhileActive onlyVault {
        // Account for how much OHM has been deployed by the Vault system or burned from circulating supply.
        // If we are burning more OHM than has been deployed by the system we are removing previously
        // circulating OHM which should be tracked separately.
        if (amount_ > deployedOhm) {
            circulatingOhmBurned += amount_ - deployedOhm;
            deployedOhm = 0;
        } else {
            deployedOhm -= amount_;
        }

        // Burn OHM
        MINTR.burnOhm(msg.sender, amount_);
    }

    //============================================================================================//
    //                                     VAULT STATE MANAGEMENT                                 //
    //============================================================================================//

    /// @inheritdoc IBLVaultManager
    function increaseTotalLp(uint256 amount_) external override onlyWhileActive onlyVault {
        totalLp += amount_;
    }

    /// @inheritdoc IBLVaultManager
    function decreaseTotalLp(uint256 amount_) external override onlyWhileActive onlyVault {
        if (amount_ > totalLp) amount_ = totalLp;
        totalLp -= amount_;
    }

    //============================================================================================//
    //                                         VIEW FUNCTIONS                                     //
    //============================================================================================//

    /// @inheritdoc IBLVaultManager
    function canWithdraw(address user_) external view override returns (bool) {
        if (address(userVaults[user_]) == address(0)) return false;
        return userVaults[user_].canWithdraw();
    }

    /// @inheritdoc IBLVaultManager
    function getLpBalance(address user_) external view override returns (uint256) {
        if (address(userVaults[user_]) == address(0)) return 0;
        return userVaults[user_].getLpBalance();
    }

    /// @inheritdoc IBLVaultManager
    function getUserPairShare(address user_) external view override returns (uint256) {
        if (address(userVaults[user_]) == address(0)) return 0;
        return userVaults[user_].getUserPairShare();
    }

    /// @inheritdoc IBLVaultManager
    function getOutstandingRewards(
        address user_
    ) external view override returns (RewardsData[] memory) {
        // Get user's vault address
        BLVaultLusd vault = userVaults[user_];
        if (address(vault) == address(0)) return new RewardsData[](0);

        RewardsData[] memory rewards = vault.getOutstandingRewards();
        return rewards;
    }

    /// @inheritdoc IBLVaultManager
    function getMaxDeposit() external view override returns (uint256) {
        uint256 maxOhmAmount = ohmLimit + circulatingOhmBurned - deployedOhm;

        // Convert max OHM mintable amount to pair token amount
        uint256 ohmTknPrice = getOhmTknPrice();
        uint256 maxTknAmount = (maxOhmAmount * 1e18) / ohmTknPrice;

        return maxTknAmount;
    }

    /// @inheritdoc IBLVaultManager
    /// @dev    This is an external function but should only be used in a callstatic from an external
    ///         source like the frontend.
    function getExpectedLpAmount(uint256 amount_) external override returns (uint256 bptAmount) {
        IBasePool pool = IBasePool(balancerData.liquidityPool);
        IBalancerHelper balancerHelper = IBalancerHelper(balancerData.balancerHelper);

        // Calculate OHM amount to mint
        uint256 ohmTknOraclePrice = getOhmTknPrice();
        uint256 ohmTknPoolPrice = getOhmTknPoolPrice();

        // If the expected oracle price mint amount is less than the expected pool price mint amount, use the oracle price
        // otherwise use the pool price
        uint256 ohmTknPrice = ohmTknOraclePrice < ohmTknPoolPrice
            ? ohmTknOraclePrice
            : ohmTknPoolPrice;
        uint256 ohmMintAmount = (amount_ * ohmTknPrice) / 1e18;

        // Build join pool request
        address[] memory assets = new address[](2);
        assets[_ohmIndex] = ohm;
        assets[_lusdIndex] = pairToken;

        uint256[] memory maxAmountsIn = new uint256[](2);
        maxAmountsIn[_ohmIndex] = ohmMintAmount;
        maxAmountsIn[_lusdIndex] = amount_;

        JoinPoolRequest memory joinPoolRequest = JoinPoolRequest({
            assets: assets,
            maxAmountsIn: maxAmountsIn,
            userData: abi.encode(1, maxAmountsIn, 0),
            fromInternalBalance: false
        });

        // Join pool query
        (bptAmount, ) = balancerHelper.queryJoin(
            pool.getPoolId(),
            address(this),
            address(this),
            joinPoolRequest
        );
    }

    /// @inheritdoc IBLVaultManager
    /// @dev    This is an external function but should only be used in a callstatic from an external
    ///         source like the frontend.
    function getExpectedTokensOutProtocol(
        uint256 lpAmount_
    ) external override returns (uint256[] memory expectedTokenAmounts) {
        IBasePool pool = IBasePool(balancerData.liquidityPool);
        IBalancerHelper balancerHelper = IBalancerHelper(balancerData.balancerHelper);

        // Build exit pool request
        address[] memory assets = new address[](2);
        assets[_ohmIndex] = ohm;
        assets[_lusdIndex] = pairToken;

        uint256[] memory minAmountsOut = new uint256[](2);
        minAmountsOut[_ohmIndex] = 0;
        minAmountsOut[_lusdIndex] = 0;

        ExitPoolRequest memory exitPoolRequest = ExitPoolRequest({
            assets: assets,
            minAmountsOut: minAmountsOut,
            userData: abi.encode(1, lpAmount_),
            toInternalBalance: false
        });

        (, expectedTokenAmounts) = balancerHelper.queryExit(
            pool.getPoolId(),
            address(this),
            address(this),
            exitPoolRequest
        );
    }

    /// @inheritdoc IBLVaultManager
    /// @dev    This is an external function but should only be used in a callstatic from an external
    ///         source like the frontend.
    function getExpectedPairTokenOutUser(
        uint256 lpAmount_
    ) external override returns (uint256 expectedTknAmount) {
        IBasePool pool = IBasePool(balancerData.liquidityPool);
        IBalancerHelper balancerHelper = IBalancerHelper(balancerData.balancerHelper);

        // Build exit pool request
        address[] memory assets = new address[](2);
        assets[_ohmIndex] = ohm;
        assets[_lusdIndex] = pairToken;

        uint256[] memory minAmountsOut = new uint256[](2);
        minAmountsOut[_ohmIndex] = 0;
        minAmountsOut[_lusdIndex] = 0;

        ExitPoolRequest memory exitPoolRequest = ExitPoolRequest({
            assets: assets,
            minAmountsOut: minAmountsOut,
            userData: abi.encode(1, lpAmount_),
            toInternalBalance: false
        });

        (, uint256[] memory expectedTokenAmounts) = balancerHelper.queryExit(
            pool.getPoolId(),
            address(this),
            address(this),
            exitPoolRequest
        );

        // Check against oracle price
        uint256 tknOhmPrice = getTknOhmPrice();
        uint256 expectedTknAmountOut = (expectedTokenAmounts[_ohmIndex] * tknOhmPrice) / 1e9;

        expectedTknAmount = expectedTokenAmounts[_lusdIndex] > expectedTknAmountOut
            ? expectedTknAmountOut
            : expectedTokenAmounts[_lusdIndex];
    }

    /// @inheritdoc IBLVaultManager
    function getRewardTokens() external view override returns (address[] memory) {
        IAuraRewardPool auraPool = IAuraRewardPool(auraData.auraRewardPool);

        uint256 numExtraRewards = auraPool.extraRewardsLength();
        address[] memory rewardTokens = new address[](numExtraRewards + 2);
        rewardTokens[0] = aura;
        rewardTokens[1] = auraPool.rewardToken();
        for (uint256 i; i < numExtraRewards; ) {
            IAuraRewardPool extraRewardPool = IAuraRewardPool(auraPool.extraRewards(i));
            rewardTokens[i + 2] = ISTASHToken(extraRewardPool.rewardToken()).baseToken();

            unchecked {
                ++i;
            }
        }
        return rewardTokens;
    }

    /// @inheritdoc IBLVaultManager
    function getRewardRate(
        address rewardToken_
    ) external view override returns (uint256 rewardRate) {
        IAuraRewardPool auraPool = IAuraRewardPool(auraData.auraRewardPool);

        if (rewardToken_ == bal) {
            // If reward token is Bal, return rewardRate from Aura Pool
            rewardRate = auraPool.rewardRate();
        } else if (rewardToken_ == aura) {
            // If reward token is Aura, calculate rewardRate from AuraMiningLib
            uint256 balRewardRate = auraPool.rewardRate();
            rewardRate = auraMiningLib.convertCrvToCvx(balRewardRate);
        } else {
            uint256 numExtraRewards = auraPool.extraRewardsLength();
            for (uint256 i; i < numExtraRewards; ) {
                IAuraRewardPool extraRewardPool = IAuraRewardPool(auraPool.extraRewards(i));
                if (rewardToken_ == ISTASHToken(extraRewardPool.rewardToken()).baseToken()) {
                    rewardRate = extraRewardPool.rewardRate();
                    break;
                }

                unchecked {
                    ++i;
                }
            }
        }
    }

    /// @inheritdoc IBLVaultManager
    function getPoolOhmShare() public view override returns (uint256) {
        // Cast addresses
        IVault vault = IVault(balancerData.vault);
        IBasePool pool = IBasePool(balancerData.liquidityPool);

        // Get pool total supply
        uint256 poolTotalSupply = pool.totalSupply();

        // Get token balances in pool
        (, uint256[] memory balances_, ) = vault.getPoolTokens(pool.getPoolId());

        // Balancer pool tokens are sorted alphabetically by token address. In the case of this
        // deployment, OHM is the second token in the pool. Therefore, the OHM balance is at index 1.
        if (poolTotalSupply == 0) return 0;
        else return (balances_[_ohmIndex] * totalLp) / poolTotalSupply;
    }

    /// @inheritdoc IBLVaultManager
    function getOhmSupplyChangeData()
        external
        view
        override
        returns (uint256 poolOhmShare, uint256 mintedOhm, uint256 netBurnedOhm)
    {
        // Using the pool's OHM share, the amount of OHM deployed by this system, and the amount of
        // OHM burned by this system we can calculate a whole host of useful data points. The most
        // important is to calculate what amount of OHM should not be considered part of circulating
        // supply which would be poolOhmShare. The rest of the data can be used to calculate whether
        // the system has net emitted or net removed OHM from the circulating supply. Net emitted is
        // the amount of OHM that was minted to the pool but is no longer in the pool beyond what has
        // been burned in the past (deployedOhm - poolOhmShare - circulatingOhmBurned). Net removed
        // is the amount of OHM that is in the pool but wasn’t minted there plus what has been burned
        // in the past (poolOhmShare + circulatingOhmBurned - deployedOhm). Here we just return
        // the data components to calculate these data points.

        poolOhmShare = getPoolOhmShare();
        mintedOhm = deployedOhm;
        netBurnedOhm = circulatingOhmBurned;
    }

    /// @inheritdoc IBLVaultManager
    function getOhmTknPrice() public view override returns (uint256) {
        // Get ETH per OHM (18 Decimals)
        uint256 ethPerOhm = _validatePrice(ohmEthPriceFeed.feed, ohmEthPriceFeed.updateThreshold);

        // Get USD per ETH (8 decimals)
        uint256 usdPerEth = _validatePrice(ethUsdPriceFeed.feed, ethUsdPriceFeed.updateThreshold);

        // Get USD per LUSD (8 decimals)
        uint256 usdPerLusd = _validatePrice(
            lusdUsdPriceFeed.feed,
            lusdUsdPriceFeed.updateThreshold
        );

        // Calculate OHM per LUSD (9 decimals)
        return (usdPerLusd * 1e27) / (ethPerOhm * usdPerEth);
    }

    /// @inheritdoc IBLVaultManager
    function getTknOhmPrice() public view override returns (uint256) {
        // Get ETH per OHM (18 Decimals)
        uint256 ethPerOhm = _validatePrice(ohmEthPriceFeed.feed, ohmEthPriceFeed.updateThreshold);

        // Get USD per ETH (8 decimals)
        uint256 usdPerEth = _validatePrice(ethUsdPriceFeed.feed, ethUsdPriceFeed.updateThreshold);

        // Get USD per LUSD (8 decimals)
        uint256 usdPerLusd = _validatePrice(
            lusdUsdPriceFeed.feed,
            lusdUsdPriceFeed.updateThreshold
        );

        // Calculate LUSD per OHM (18 decimals)
        return (ethPerOhm * usdPerEth) / (usdPerLusd);
    }

    // TODO: Update
    /// @inheritdoc IBLVaultManager
    function getOhmTknPoolPrice() public view override returns (uint256) {
        IBasePool pool = IBasePool(balancerData.liquidityPool);
        IVault vault = IVault(balancerData.vault);

        // Get token balances
        (, uint256[] memory balances, ) = vault.getPoolTokens(pool.getPoolId());

        // Get OHM per LUSD (9 decimals)
        if (balances[_lusdIndex] == 0) return 0;
        else return (balances[_ohmIndex] * 1e18) / balances[_lusdIndex];
    }

    //============================================================================================//
    //                                        ADMIN FUNCTIONS                                     //
    //============================================================================================//

    /// @inheritdoc IBLVaultManager
    function emergencyBurnOhm(uint256 amount_) external override onlyRole("liquidityvault_admin") {
        OlympusERC20Token(ohm).increaseAllowance(address(MINTR), amount_);
        MINTR.burnOhm(address(this), amount_);
    }

    /// @inheritdoc IBLVaultManager
    function setLimit(uint256 newLimit_) external override onlyRole("liquidityvault_admin") {
        if (newLimit_ + circulatingOhmBurned < deployedOhm) revert BLManagerLusd_InvalidLimit();
        ohmLimit = newLimit_;
    }

    /// @inheritdoc IBLVaultManager
    function setFee(uint64 newFee_) external override onlyRole("liquidityvault_admin") {
        if (newFee_ > MAX_FEE) revert BLManagerLusd_InvalidFee();
        currentFee = newFee_;
    }

    /// @inheritdoc IBLVaultManager
    function setWithdrawalDelay(
        uint48 newDelay_
    ) external override onlyRole("liquidityvault_admin") {
        minWithdrawalDelay = newDelay_;
    }

    function changeUpdateThresholds(
        uint48 ohmEthUpdateThreshold_,
        uint48 ethUsdUpdateThreshold_,
        uint48 lusdUsdUpdateThreshold_
    ) external onlyRole("liquidityvault_admin") {
        ohmEthPriceFeed.updateThreshold = ohmEthUpdateThreshold_;
        ethUsdPriceFeed.updateThreshold = ethUsdUpdateThreshold_;
        lusdUsdPriceFeed.updateThreshold = lusdUsdUpdateThreshold_;
    }

    /// @inheritdoc IBLVaultManager
    function activate() external override onlyRole("liquidityvault_admin") {
        if (isLusdBLVaultActive) revert BLManagerLusd_AlreadyActive();

        isLusdBLVaultActive = true;
        BLREG.addVault(address(this));
    }

    /// @inheritdoc IBLVaultManager
    function deactivate() external override onlyRole("emergency_admin") {
        if (!isLusdBLVaultActive) revert BLManagerLusd_AlreadyInactive();

        isLusdBLVaultActive = false;
        BLREG.removeVault(address(this));
    }

    //============================================================================================//
    //                                      INTERNAL FUNCTIONS                                    //
    //============================================================================================//

    function _validatePrice(
        AggregatorV3Interface priceFeed_,
        uint48 updateThreshold_
    ) internal view returns (uint256) {
        // Get price data
        (uint80 roundId, int256 priceInt, , uint256 updatedAt, uint80 answeredInRound) = priceFeed_
            .latestRoundData();

        // Validate chainlink price feed data
        // 1. Price should be greater than 0
        // 2. Updated at timestamp should be within the update threshold
        // 3. Answered in round ID should be the same as round ID
        if (
            priceInt <= 0 ||
            updatedAt < block.timestamp - updateThreshold_ ||
            answeredInRound != roundId
        ) revert BLManagerLusd_BadPriceFeed();

        return uint256(priceInt);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

import {OlympusERC20Token as OHM} from "src/external/OlympusERC20.sol";
import "src/Kernel.sol";

/// @notice Wrapper for minting and burning functions of OHM token.
abstract contract MINTRv1 is Module {
    // =========  EVENTS ========= //

    event IncreaseMintApproval(address indexed policy_, uint256 newAmount_);
    event DecreaseMintApproval(address indexed policy_, uint256 newAmount_);
    event Mint(address indexed policy_, address indexed to_, uint256 amount_);
    event Burn(address indexed policy_, address indexed from_, uint256 amount_);

    // ========= ERRORS ========= //

    error MINTR_NotApproved();
    error MINTR_ZeroAmount();
    error MINTR_NotActive();

    // =========  STATE ========= //

    OHM public ohm;

    /// @notice Status of the minter. If false, minting and burning OHM is disabled.
    bool public active;

    /// @notice Mapping of who is approved for minting.
    /// @dev    minter -> amount. Infinite approval is max(uint256).
    mapping(address => uint256) public mintApproval;

    // =========  FUNCTIONS ========= //

    modifier onlyWhileActive() {
        if (!active) revert MINTR_NotActive();
        _;
    }

    /// @notice Mint OHM to an address.
    function mintOhm(address to_, uint256 amount_) external virtual;

    /// @notice Burn OHM from an address. Must have approval.
    function burnOhm(address from_, uint256 amount_) external virtual;

    /// @notice Increase approval for specific withdrawer addresses
    /// @dev    Policies must explicity request how much they want approved before withdrawing.
    function increaseMintApproval(address policy_, uint256 amount_) external virtual;

    /// @notice Decrease approval for specific withdrawer addresses
    function decreaseMintApproval(address policy_, uint256 amount_) external virtual;

    /// @notice Emergency shutdown of minting and burning.
    function deactivate() external virtual;

    /// @notice Re-activate minting and burning after shutdown.
    function activate() external virtual;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

import {ROLESv1} from "src/modules/ROLES/ROLES.v1.sol";
import "src/Kernel.sol";

/// @notice Abstract contract to have the `onlyRole` modifier
/// @dev    Inheriting this automatically makes ROLES module a dependency
abstract contract RolesConsumer {
    ROLESv1 public ROLES;

    modifier onlyRole(bytes32 role_) {
        ROLES.requireRole(role_, msg.sender);
        _;
    }
}

/// @notice Module that holds multisig roles needed by various policies.
contract OlympusRoles is ROLESv1 {
    //============================================================================================//
    //                                        MODULE SETUP                                        //
    //============================================================================================//

    constructor(Kernel kernel_) Module(kernel_) {}

    /// @inheritdoc Module
    function KEYCODE() public pure override returns (Keycode) {
        return toKeycode("ROLES");
    }

    /// @inheritdoc Module
    function VERSION() external pure override returns (uint8 major, uint8 minor) {
        major = 1;
        minor = 0;
    }

    //============================================================================================//
    //                                       CORE FUNCTIONS                                       //
    //============================================================================================//

    /// @inheritdoc ROLESv1
    function saveRole(bytes32 role_, address addr_) external override permissioned {
        if (hasRole[addr_][role_]) revert ROLES_AddressAlreadyHasRole(addr_, role_);

        ensureValidRole(role_);

        // Grant role to the address
        hasRole[addr_][role_] = true;

        emit RoleGranted(role_, addr_);
    }

    /// @inheritdoc ROLESv1
    function removeRole(bytes32 role_, address addr_) external override permissioned {
        if (!hasRole[addr_][role_]) revert ROLES_AddressDoesNotHaveRole(addr_, role_);

        hasRole[addr_][role_] = false;

        emit RoleRevoked(role_, addr_);
    }

    //============================================================================================//
    //                                       VIEW FUNCTIONS                                       //
    //============================================================================================//

    /// @inheritdoc ROLESv1
    function requireRole(bytes32 role_, address caller_) external view override {
        if (!hasRole[caller_][role_]) revert ROLES_RequireRole(role_);
    }

    /// @inheritdoc ROLESv1
    function ensureValidRole(bytes32 role_) public pure override {
        for (uint256 i = 0; i < 32; ) {
            bytes1 char = role_[i];
            if ((char < 0x61 || char > 0x7A) && char != 0x5f && char != 0x00) {
                revert ROLES_InvalidRole(role_); // a-z only
            }
            unchecked {
                i++;
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";
import "src/Kernel.sol";

/// @notice Treasury holds all other assets under the control of the protocol.
abstract contract TRSRYv1 is Module {
    // =========  EVENTS ========= //

    event IncreaseWithdrawApproval(
        address indexed withdrawer_,
        ERC20 indexed token_,
        uint256 newAmount_
    );
    event DecreaseWithdrawApproval(
        address indexed withdrawer_,
        ERC20 indexed token_,
        uint256 newAmount_
    );
    event Withdrawal(
        address indexed policy_,
        address indexed withdrawer_,
        ERC20 indexed token_,
        uint256 amount_
    );
    event IncreaseDebtorApproval(address indexed debtor_, ERC20 indexed token_, uint256 newAmount_);
    event DecreaseDebtorApproval(address indexed debtor_, ERC20 indexed token_, uint256 newAmount_);
    event DebtIncurred(ERC20 indexed token_, address indexed policy_, uint256 amount_);
    event DebtRepaid(ERC20 indexed token_, address indexed policy_, uint256 amount_);
    event DebtSet(ERC20 indexed token_, address indexed policy_, uint256 amount_);

    // =========  ERRORS ========= //

    error TRSRY_NoDebtOutstanding();
    error TRSRY_NotActive();

    // =========  STATE ========= //

    /// @notice Status of the treasury. If false, no withdrawals or debt can be incurred.
    bool public active;

    /// @notice Mapping of who is approved for withdrawal.
    /// @dev    withdrawer -> token -> amount. Infinite approval is max(uint256).
    mapping(address => mapping(ERC20 => uint256)) public withdrawApproval;

    /// @notice Mapping of who is approved to incur debt.
    /// @dev    debtor -> token -> amount. Infinite approval is max(uint256).
    mapping(address => mapping(ERC20 => uint256)) public debtApproval;

    /// @notice Total debt for token across all withdrawals.
    mapping(ERC20 => uint256) public totalDebt;

    /// @notice Debt for particular token and debtor address
    mapping(ERC20 => mapping(address => uint256)) public reserveDebt;

    // =========  FUNCTIONS ========= //

    modifier onlyWhileActive() {
        if (!active) revert TRSRY_NotActive();
        _;
    }

    /// @notice Increase approval for specific withdrawer addresses
    function increaseWithdrawApproval(
        address withdrawer_,
        ERC20 token_,
        uint256 amount_
    ) external virtual;

    /// @notice Decrease approval for specific withdrawer addresses
    function decreaseWithdrawApproval(
        address withdrawer_,
        ERC20 token_,
        uint256 amount_
    ) external virtual;

    /// @notice Allow withdrawal of reserve funds from pre-approved addresses.
    function withdrawReserves(address to_, ERC20 token_, uint256 amount_) external virtual;

    /// @notice Increase approval for someone to accrue debt in order to withdraw reserves.
    /// @dev    Debt will generally be taken by contracts to allocate treasury funds in yield sources.
    function increaseDebtorApproval(
        address debtor_,
        ERC20 token_,
        uint256 amount_
    ) external virtual;

    /// @notice Decrease approval for someone to withdraw reserves as debt.
    function decreaseDebtorApproval(
        address debtor_,
        ERC20 token_,
        uint256 amount_
    ) external virtual;

    /// @notice Pre-approved policies can get a loan to perform operations with treasury assets.
    function incurDebt(ERC20 token_, uint256 amount_) external virtual;

    /// @notice Repay a debtor debt.
    /// @dev    Only confirmed to safely handle standard and non-standard ERC20s.
    /// @dev    Can have unforeseen consequences with ERC777. Be careful with ERC777 as reserve.
    function repayDebt(address debtor_, ERC20 token_, uint256 amount_) external virtual;

    /// @notice An escape hatch for setting debt in special cases, like swapping reserves to another token.
    function setDebt(address debtor_, ERC20 token_, uint256 amount_) external virtual;

    /// @notice Get total balance of assets inside the treasury + any debt taken out against those assets.
    function getReserveBalance(ERC20 token_) external view virtual returns (uint256);

    /// @notice Emergency shutdown of withdrawals.
    function deactivate() external virtual;

    /// @notice Re-activate withdrawals after shutdown.
    function activate() external virtual;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

import "src/Kernel.sol";

/// @title  Olympus Boosted Liquidity Vault Registry
/// @notice Olympus Boosted Liquidity Vault Registry (Module) Contract
/// @dev    The Olympus Boosted Liquidity Vault Registry Module tracks the boosted liquidity vaults
///         that are approved to be used by the Olympus protocol. This allows for a single-soure
///         of truth for reporting purposes around total OHM deployed and net emissions.
abstract contract BLREGv1 is Module {
    // ========= EVENTS ========= //

    event VaultAdded(address indexed vault);
    event VaultRemoved(address indexed vault);

    // ========= STATE ========= //

    /// @notice Count of active vaults
    /// @dev    This is a useless variable in contracts but useful for any frontends or
    ///         off-chain requests where the array is not easily accessible.
    uint256 public activeVaultCount;

    /// @notice Tracks all active vaults
    address[] public activeVaults;

    // ========= FUNCTIONS ========= //

    /// @notice         Adds an vault to the registry
    /// @param vault_   The address of the vault to add
    function addVault(address vault_) external virtual;

    /// @notice         Removes an vault from the registry
    /// @param vault_   The address of the vault to remove
    function removeVault(address vault_) external virtual;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

//     ███████    █████       █████ █████ ██████   ██████ ███████████  █████  █████  █████████
//   ███░░░░░███ ░░███       ░░███ ░░███ ░░██████ ██████ ░░███░░░░░███░░███  ░░███  ███░░░░░███
//  ███     ░░███ ░███        ░░███ ███   ░███░█████░███  ░███    ░███ ░███   ░███ ░███    ░░░
// ░███      ░███ ░███         ░░█████    ░███░░███ ░███  ░██████████  ░███   ░███ ░░█████████
// ░███      ░███ ░███          ░░███     ░███ ░░░  ░███  ░███░░░░░░   ░███   ░███  ░░░░░░░░███
// ░░███     ███  ░███      █    ░███     ░███      ░███  ░███         ░███   ░███  ███    ░███
//  ░░░███████░   ███████████    █████    █████     █████ █████        ░░████████  ░░█████████
//    ░░░░░░░    ░░░░░░░░░░░    ░░░░░    ░░░░░     ░░░░░ ░░░░░          ░░░░░░░░    ░░░░░░░░░

//============================================================================================//
//                                        GLOBAL TYPES                                        //
//============================================================================================//

/// @notice Actions to trigger state changes in the kernel. Passed by the executor
enum Actions {
    InstallModule,
    UpgradeModule,
    ActivatePolicy,
    DeactivatePolicy,
    ChangeExecutor,
    MigrateKernel
}

/// @notice Used by executor to select an action and a target contract for a kernel action
struct Instruction {
    Actions action;
    address target;
}

/// @notice Used to define which module functions a policy needs access to
struct Permissions {
    Keycode keycode;
    bytes4 funcSelector;
}

type Keycode is bytes5;

//============================================================================================//
//                                       UTIL FUNCTIONS                                       //
//============================================================================================//

error TargetNotAContract(address target_);
error InvalidKeycode(Keycode keycode_);

// solhint-disable-next-line func-visibility
function toKeycode(bytes5 keycode_) pure returns (Keycode) {
    return Keycode.wrap(keycode_);
}

// solhint-disable-next-line func-visibility
function fromKeycode(Keycode keycode_) pure returns (bytes5) {
    return Keycode.unwrap(keycode_);
}

// solhint-disable-next-line func-visibility
function ensureContract(address target_) view {
    if (target_.code.length == 0) revert TargetNotAContract(target_);
}

// solhint-disable-next-line func-visibility
function ensureValidKeycode(Keycode keycode_) pure {
    bytes5 unwrapped = Keycode.unwrap(keycode_);
    for (uint256 i = 0; i < 5; ) {
        bytes1 char = unwrapped[i];
        if (char < 0x41 || char > 0x5A) revert InvalidKeycode(keycode_); // A-Z only
        unchecked {
            i++;
        }
    }
}

//============================================================================================//
//                                        COMPONENTS                                          //
//============================================================================================//

/// @notice Generic adapter interface for kernel access in modules and policies.
abstract contract KernelAdapter {
    error KernelAdapter_OnlyKernel(address caller_);

    Kernel public kernel;

    constructor(Kernel kernel_) {
        kernel = kernel_;
    }

    /// @notice Modifier to restrict functions to be called only by kernel.
    modifier onlyKernel() {
        if (msg.sender != address(kernel)) revert KernelAdapter_OnlyKernel(msg.sender);
        _;
    }

    /// @notice Function used by kernel when migrating to a new kernel.
    function changeKernel(Kernel newKernel_) external onlyKernel {
        kernel = newKernel_;
    }
}

/// @notice Base level extension of the kernel. Modules act as independent state components to be
///         interacted with and mutated through policies.
/// @dev    Modules are installed and uninstalled via the executor.
abstract contract Module is KernelAdapter {
    error Module_PolicyNotPermitted(address policy_);

    constructor(Kernel kernel_) KernelAdapter(kernel_) {}

    /// @notice Modifier to restrict which policies have access to module functions.
    modifier permissioned() {
        if (!kernel.modulePermissions(KEYCODE(), Policy(msg.sender), msg.sig))
            revert Module_PolicyNotPermitted(msg.sender);
        _;
    }

    /// @notice 5 byte identifier for a module.
    function KEYCODE() public pure virtual returns (Keycode) {}

    /// @notice Returns which semantic version of a module is being implemented.
    /// @return major - Major version upgrade indicates breaking change to the interface.
    /// @return minor - Minor version change retains backward-compatible interface.
    function VERSION() external pure virtual returns (uint8 major, uint8 minor) {}

    /// @notice Initialization function for the module
    /// @dev    This function is called when the module is installed or upgraded by the kernel.
    /// @dev    MUST BE GATED BY onlyKernel. Used to encompass any initialization or upgrade logic.
    function INIT() external virtual onlyKernel {}
}

/// @notice Policies are application logic and external interface for the kernel and installed modules.
/// @dev    Policies are activated and deactivated in the kernel by the executor.
/// @dev    Module dependencies and function permissions must be defined in appropriate functions.
abstract contract Policy is KernelAdapter {
    error Policy_ModuleDoesNotExist(Keycode keycode_);

    constructor(Kernel kernel_) KernelAdapter(kernel_) {}

    /// @notice Easily accessible indicator for if a policy is activated or not.
    function isActive() external view returns (bool) {
        return kernel.isPolicyActive(this);
    }

    /// @notice Function to grab module address from a given keycode.
    function getModuleAddress(Keycode keycode_) internal view returns (address) {
        address moduleForKeycode = address(kernel.getModuleForKeycode(keycode_));
        if (moduleForKeycode == address(0)) revert Policy_ModuleDoesNotExist(keycode_);
        return moduleForKeycode;
    }

    /// @notice Define module dependencies for this policy.
    /// @return dependencies - Keycode array of module dependencies.
    function configureDependencies() external virtual returns (Keycode[] memory dependencies) {}

    /// @notice Function called by kernel to set module function permissions.
    /// @return requests - Array of keycodes and function selectors for requested permissions.
    function requestPermissions() external view virtual returns (Permissions[] memory requests) {}
}

/// @notice Main contract that acts as a central component registry for the protocol.
/// @dev    The kernel manages modules and policies. The kernel is mutated via predefined Actions,
/// @dev    which are input from any address assigned as the executor. The executor can be changed as needed.
contract Kernel {
    // =========  EVENTS ========= //

    event PermissionsUpdated(
        Keycode indexed keycode_,
        Policy indexed policy_,
        bytes4 funcSelector_,
        bool granted_
    );
    event ActionExecuted(Actions indexed action_, address indexed target_);

    // =========  ERRORS ========= //

    error Kernel_OnlyExecutor(address caller_);
    error Kernel_ModuleAlreadyInstalled(Keycode module_);
    error Kernel_InvalidModuleUpgrade(Keycode module_);
    error Kernel_PolicyAlreadyActivated(address policy_);
    error Kernel_PolicyNotActivated(address policy_);

    // =========  PRIVILEGED ADDRESSES ========= //

    /// @notice Address that is able to initiate Actions in the kernel. Can be assigned to a multisig or governance contract.
    address public executor;

    // =========  MODULE MANAGEMENT ========= //

    /// @notice Array of all modules currently installed.
    Keycode[] public allKeycodes;

    /// @notice Mapping of module address to keycode.
    mapping(Keycode => Module) public getModuleForKeycode;

    /// @notice Mapping of keycode to module address.
    mapping(Module => Keycode) public getKeycodeForModule;

    /// @notice Mapping of a keycode to all of its policy dependents. Used to efficiently reconfigure policy dependencies.
    mapping(Keycode => Policy[]) public moduleDependents;

    /// @notice Helper for module dependent arrays. Prevents the need to loop through array.
    mapping(Keycode => mapping(Policy => uint256)) public getDependentIndex;

    /// @notice Module <> Policy Permissions.
    /// @dev    Keycode -> Policy -> Function Selector -> bool for permission
    mapping(Keycode => mapping(Policy => mapping(bytes4 => bool))) public modulePermissions;

    // =========  POLICY MANAGEMENT ========= //

    /// @notice List of all active policies
    Policy[] public activePolicies;

    /// @notice Helper to get active policy quickly. Prevents need to loop through array.
    mapping(Policy => uint256) public getPolicyIndex;

    //============================================================================================//
    //                                       CORE FUNCTIONS                                       //
    //============================================================================================//

    constructor() {
        executor = msg.sender;
    }

    /// @notice Modifier to check if caller is the executor.
    modifier onlyExecutor() {
        if (msg.sender != executor) revert Kernel_OnlyExecutor(msg.sender);
        _;
    }

    function isPolicyActive(Policy policy_) public view returns (bool) {
        return activePolicies.length > 0 && activePolicies[getPolicyIndex[policy_]] == policy_;
    }

    /// @notice Main kernel function. Initiates state changes to kernel depending on Action passed in.
    function executeAction(Actions action_, address target_) external onlyExecutor {
        if (action_ == Actions.InstallModule) {
            ensureContract(target_);
            ensureValidKeycode(Module(target_).KEYCODE());
            _installModule(Module(target_));
        } else if (action_ == Actions.UpgradeModule) {
            ensureContract(target_);
            ensureValidKeycode(Module(target_).KEYCODE());
            _upgradeModule(Module(target_));
        } else if (action_ == Actions.ActivatePolicy) {
            ensureContract(target_);
            _activatePolicy(Policy(target_));
        } else if (action_ == Actions.DeactivatePolicy) {
            ensureContract(target_);
            _deactivatePolicy(Policy(target_));
        } else if (action_ == Actions.ChangeExecutor) {
            executor = target_;
        } else if (action_ == Actions.MigrateKernel) {
            ensureContract(target_);
            _migrateKernel(Kernel(target_));
        }

        emit ActionExecuted(action_, target_);
    }

    function _installModule(Module newModule_) internal {
        Keycode keycode = newModule_.KEYCODE();

        if (address(getModuleForKeycode[keycode]) != address(0))
            revert Kernel_ModuleAlreadyInstalled(keycode);

        getModuleForKeycode[keycode] = newModule_;
        getKeycodeForModule[newModule_] = keycode;
        allKeycodes.push(keycode);

        newModule_.INIT();
    }

    function _upgradeModule(Module newModule_) internal {
        Keycode keycode = newModule_.KEYCODE();
        Module oldModule = getModuleForKeycode[keycode];

        if (address(oldModule) == address(0) || oldModule == newModule_)
            revert Kernel_InvalidModuleUpgrade(keycode);

        getKeycodeForModule[oldModule] = Keycode.wrap(bytes5(0));
        getKeycodeForModule[newModule_] = keycode;
        getModuleForKeycode[keycode] = newModule_;

        newModule_.INIT();

        _reconfigurePolicies(keycode);
    }

    function _activatePolicy(Policy policy_) internal {
        if (isPolicyActive(policy_)) revert Kernel_PolicyAlreadyActivated(address(policy_));

        // Add policy to list of active policies
        activePolicies.push(policy_);
        getPolicyIndex[policy_] = activePolicies.length - 1;

        // Record module dependencies
        Keycode[] memory dependencies = policy_.configureDependencies();
        uint256 depLength = dependencies.length;

        for (uint256 i; i < depLength; ) {
            Keycode keycode = dependencies[i];

            moduleDependents[keycode].push(policy_);
            getDependentIndex[keycode][policy_] = moduleDependents[keycode].length - 1;

            unchecked {
                ++i;
            }
        }

        // Grant permissions for policy to access restricted module functions
        Permissions[] memory requests = policy_.requestPermissions();
        _setPolicyPermissions(policy_, requests, true);
    }

    function _deactivatePolicy(Policy policy_) internal {
        if (!isPolicyActive(policy_)) revert Kernel_PolicyNotActivated(address(policy_));

        // Revoke permissions
        Permissions[] memory requests = policy_.requestPermissions();
        _setPolicyPermissions(policy_, requests, false);

        // Remove policy from all policy data structures
        uint256 idx = getPolicyIndex[policy_];
        Policy lastPolicy = activePolicies[activePolicies.length - 1];

        activePolicies[idx] = lastPolicy;
        activePolicies.pop();
        getPolicyIndex[lastPolicy] = idx;
        delete getPolicyIndex[policy_];

        // Remove policy from module dependents
        _pruneFromDependents(policy_);
    }

    /// @notice All functionality will move to the new kernel. WARNING: ACTION WILL BRICK THIS KERNEL.
    /// @dev    New kernel must add in all of the modules and policies via executeAction.
    /// @dev    NOTE: Data does not get cleared from this kernel.
    function _migrateKernel(Kernel newKernel_) internal {
        uint256 keycodeLen = allKeycodes.length;
        for (uint256 i; i < keycodeLen; ) {
            Module module = Module(getModuleForKeycode[allKeycodes[i]]);
            module.changeKernel(newKernel_);
            unchecked {
                ++i;
            }
        }

        uint256 policiesLen = activePolicies.length;
        for (uint256 j; j < policiesLen; ) {
            Policy policy = activePolicies[j];

            // Deactivate before changing kernel
            policy.changeKernel(newKernel_);
            unchecked {
                ++j;
            }
        }
    }

    function _reconfigurePolicies(Keycode keycode_) internal {
        Policy[] memory dependents = moduleDependents[keycode_];
        uint256 depLength = dependents.length;

        for (uint256 i; i < depLength; ) {
            dependents[i].configureDependencies();

            unchecked {
                ++i;
            }
        }
    }

    function _setPolicyPermissions(
        Policy policy_,
        Permissions[] memory requests_,
        bool grant_
    ) internal {
        uint256 reqLength = requests_.length;
        for (uint256 i = 0; i < reqLength; ) {
            Permissions memory request = requests_[i];
            modulePermissions[request.keycode][policy_][request.funcSelector] = grant_;

            emit PermissionsUpdated(request.keycode, policy_, request.funcSelector, grant_);

            unchecked {
                ++i;
            }
        }
    }

    function _pruneFromDependents(Policy policy_) internal {
        Keycode[] memory dependencies = policy_.configureDependencies();
        uint256 depcLength = dependencies.length;

        for (uint256 i; i < depcLength; ) {
            Keycode keycode = dependencies[i];
            Policy[] storage dependents = moduleDependents[keycode];

            uint256 origIndex = getDependentIndex[keycode][policy_];
            Policy lastPolicy = dependents[dependents.length - 1];

            // Swap with last and pop
            dependents[origIndex] = lastPolicy;
            dependents.pop();

            // Record new index and delete deactivated policy index
            getDependentIndex[keycode][lastPolicy] = origIndex;
            delete getDependentIndex[keycode][policy_];

            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);

    function latestRound() external view returns (uint256);

    function getAnswer(uint256 roundId) external view returns (int256);

    function getTimestamp(uint256 roundId) external view returns (uint256);

    event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

    event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

// Define Booster Interface
interface IAuraBooster {
    function deposit(uint256 pid_, uint256 amount_, bool stake_) external returns (bool);
}

// Define Base Reward Pool interface
interface IAuraRewardPool {
    function balanceOf(address account_) external view returns (uint256);

    function earned(address account_) external view returns (uint256);

    function rewardRate() external view returns (uint256);

    function rewardToken() external view returns (address);

    function extraRewardsLength() external view returns (uint256);

    function extraRewards(uint256 index) external view returns (address);

    function deposit(uint256 assets_, address receiver_) external;

    function getReward(address account_, bool claimExtras_) external;

    function withdrawAndUnwrap(uint256 amount_, bool claim_) external returns (bool);
}

// Define Aura Mining Lib interface
interface IAuraMiningLib {
    function convertCrvToCvx(uint256 amount_) external view returns (uint256);
}

// Define Aura STASH Token Interface
interface ISTASHToken {
    function baseToken() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

// Import types
import {ERC20} from "solmate/tokens/ERC20.sol";

// Define Data Structures
struct JoinPoolRequest {
    address[] assets;
    uint256[] maxAmountsIn;
    bytes userData;
    bool fromInternalBalance;
}

struct ExitPoolRequest {
    address[] assets;
    uint256[] minAmountsOut;
    bytes userData;
    bool toInternalBalance;
}

// Define Vault Interface
interface IVault {
    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    function getPoolTokens(
        bytes32 poolId
    ) external view returns (address[] memory, uint256[] memory, uint256);
}

// Define Balancer Base Pool Interface
interface IBasePool {
    function getPoolId() external view returns (bytes32);

    function balanceOf(address user_) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function approve(address spender_, uint256 amount_) external returns (bool);
}

// Define Balancer Pool Factory Interface
interface IFactory {
    function create(
        string memory name,
        string memory symbol,
        ERC20[] memory tokens,
        uint256[] memory weights,
        uint256 swapFeePercentage,
        address owner
    ) external returns (address);
}

interface IBalancerHelper {
    function queryJoin(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external returns (uint256 bptOut, uint256[] memory amountsIn);

    function queryExit(
        bytes32 poolId,
        address sender,
        address recipient,
        ExitPoolRequest memory request
    ) external returns (uint256 bptIn, uint256[] memory amountsOut);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

struct RewardsData {
    address rewardToken;
    uint256 outstandingRewards;
}

interface IBLVault {
    //============================================================================================//
    //                                      LIQUIDITY FUNCTIONS                                   //
    //============================================================================================//

    /// @notice                         Mints OHM against a pair token deposit and uses the OHM and pair tokens to add liquidity to a Balancer pool
    /// @dev                            Can only be called by the owner of the vault
    /// @param amount_                  The amount of pair tokens to deposit
    /// @param minLpAmount_             The minimum acceptable amount of LP tokens to receive back
    /// @return lpAmountOut             The amount of LP tokens received by the transaction
    function deposit(uint256 amount_, uint256 minLpAmount_) external returns (uint256 lpAmountOut);

    /// @notice                         Withdraws LP tokens from Aura and Balancer, burns the OHM side, and returns the pair token side to the user
    /// @dev                            Can only be called by the owner of the vault
    /// @param lpAmount_                The amount of LP tokens to withdraw from Balancer
    /// @param minTokenAmountsBalancer_ The minimum acceptable amounts of OHM (first entry), and pair tokens (second entry) to receive back from Balancer
    /// @param minTokenAmountUser_      The minimum acceptable amount of pair tokens to receive back from the vault
    /// @param claim_                   Whether to claim outstanding rewards from Aura
    /// @return uint256                 The amount of OHM received
    /// @return uint256                 The amount of pair tokens received
    function withdraw(
        uint256 lpAmount_,
        uint256[] calldata minTokenAmountsBalancer_,
        uint256 minTokenAmountUser_,
        bool claim_
    ) external returns (uint256, uint256);

    /// @notice                         Withdraws LP tokens from Aura and Balancer, returns the pair tokens to the user
    /// @dev                            Can only be called by the owner of the vault. Can only be called when the vault is paused
    /// @param lpAmount_                The amount of LP tokens to withdraw from Balancer
    /// @param minTokenAmounts_         The minimum acceptable amounts of OHM (first entry), and pair tokens (second entry) to receive back from Balancer
    /// @return uint256                 The amount of OHM received
    /// @return uint256                 The amount of pair tokens received
    function emergencyWithdraw(
        uint256 lpAmount_,
        uint256[] calldata minTokenAmounts_
    ) external returns (uint256, uint256);

    //============================================================================================//
    //                                       REWARDS FUNCTIONS                                    //
    //============================================================================================//

    /// @notice                         Claims outstanding rewards from Aura
    /// @dev                            Can only be called by the owner of the vault
    function claimRewards() external;

    //============================================================================================//
    //                                        VIEW FUNCTIONS                                      //
    //============================================================================================//

    /// @notice                         Gets whether enough time has passed since the last deposit for the user to be ale to withdraw
    /// @return bool                    Whether enough time has passed since the last deposit for the user to be ale to withdraw
    function canWithdraw() external view returns (bool);

    /// @notice                         Gets the LP balance of the contract based on its deposits to Aura
    /// @return uint256                 LP balance deposited into Aura
    function getLpBalance() external view returns (uint256);

    /// @notice                         Gets the contract's claim on pair tokens based on its LP balance deposited into Aura
    /// @return uint256                 Claim on pair tokens
    function getUserPairShare() external view returns (uint256);

    /// @notice                         Returns the vault's unclaimed rewards in Aura
    /// @return RewardsData[]           The vault's unclaimed rewards in Aura
    function getOutstandingRewards() external view returns (RewardsData[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

// Import system dependencies
import {MINTRv1} from "src/modules/MINTR/MINTR.v1.sol";
import {ROLESv1} from "src/modules/ROLES/ROLES.v1.sol";
import {TRSRYv1} from "src/modules/TRSRY/TRSRY.v1.sol";

// Import external dependencies
import {AggregatorV3Interface} from "interfaces/AggregatorV2V3Interface.sol";
import {IAuraMiningLib} from "policies/BoostedLiquidity/interfaces/IAura.sol";

// Import vault dependencies
import {IBLVault, RewardsData} from "policies/BoostedLiquidity/interfaces/IBLVault.sol";

interface IBLVaultManager {
    // ========= DATA STRUCTURES ========= //

    struct TokenData {
        address ohm;
        address pairToken;
        address aura;
        address bal;
    }

    struct BalancerData {
        address vault;
        address liquidityPool;
        address balancerHelper;
    }

    struct AuraData {
        uint256 pid;
        address auraBooster;
        address auraRewardPool;
    }

    struct OracleFeed {
        AggregatorV3Interface feed;
        uint48 updateThreshold;
    }

    //============================================================================================//
    //                                        STATE VARIABLES                                     //
    //============================================================================================//

    /// @notice                         The minimum length of time between a deposit and a withdrawal
    function minWithdrawalDelay() external returns (uint48);

    //============================================================================================//
    //                                        VAULT DEPLOYMENT                                    //
    //============================================================================================//

    /// @notice                         Deploys a personal single sided vault for the user
    /// @dev                            The vault is deployed with the user as the owner
    /// @return vault                   The address of the deployed vault
    function deployVault() external returns (address);

    //============================================================================================//
    //                                         OHM MANAGEMENT                                     //
    //============================================================================================//

    /// @notice                         Mints OHM to the caller
    /// @dev                            Can only be called by an approved vault
    /// @param amount_                  The amount of OHM to mint
    function mintOhmToVault(uint256 amount_) external;

    /// @notice                         Burns OHM from the caller
    /// @dev                            Can only be called by an approved vault. The caller must have an OHM approval for the MINTR.
    /// @param amount_                  The amount of OHM to burn
    function burnOhmFromVault(uint256 amount_) external;

    //============================================================================================//
    //                                     VAULT STATE MANAGEMENT                                 //
    //============================================================================================//

    /// @notice                         Increases the tracked value for totalLP
    /// @dev                            Can only be called by an approved vault
    /// @param amount_                  The amount of LP tokens to add to the total
    function increaseTotalLp(uint256 amount_) external;

    /// @notice                         Decreases the tracked value for totalLP
    /// @dev                            Can only be called by an approved vault
    /// @param amount_                  The amount of LP tokens to remove from the total
    function decreaseTotalLp(uint256 amount_) external;

    //============================================================================================//
    //                                         VIEW FUNCTIONS                                     //
    //============================================================================================//

    /// @notice                         Returns whether enough time has passed since the last deposit for the user to be ale to withdraw
    /// @param user_                    The user to check the vault of
    /// @return bool                    Whether enough time has passed since the last deposit for the user to be ale to withdraw
    function canWithdraw(address user_) external view returns (bool);

    /// @notice                         Returns the user's vault's LP balance
    /// @param user_                    The user to check the vault of
    /// @return uint256                 The user's vault's LP balance
    function getLpBalance(address user_) external view returns (uint256);

    /// @notice                         Returns the user's vault's claim on the pair token
    /// @param user_                    The user to check the vault of
    /// @return uint256                 The user's vault's claim on the pair token
    function getUserPairShare(address user_) external view returns (uint256);

    /// @notice                         Returns the user's vault's unclaimed rewards in Aura
    /// @param user_                    The user to check the vault of
    /// @return RewardsData[]           The user's vault's unclaimed rewards in Aura
    function getOutstandingRewards(address user_) external view returns (RewardsData[] memory);

    /// @notice                         Calculates the max pair token deposit based on the limit and current amount of OHM minted
    /// @return uint256                 The max pair token deposit
    function getMaxDeposit() external view returns (uint256);

    /// @notice                         Calculates the amount of LP tokens that will be generated for a given amount of pair tokens
    /// @param amount_                  The amount of pair tokens to calculate the LP tokens for
    /// @return uint256                 The amount of LP tokens that will be generated
    function getExpectedLpAmount(uint256 amount_) external returns (uint256);

    /// @notice                         Calculates the amount of OHM and pair tokens that should be received by the vault for withdrawing a given amount of LP tokens
    /// @param lpAmount_                The amount of LP tokens to calculate the OHM and pair tokens for
    /// @return expectedTokenAmounts    The amount of OHM and pair tokens that should be received
    function getExpectedTokensOutProtocol(
        uint256 lpAmount_
    ) external returns (uint256[] memory expectedTokenAmounts);

    /// @notice                         Calculates the amount of pair tokens that should be received by the user for withdrawing a given amount of LP tokens after the treasury takes any arbs
    /// @param lpAmount_                The amount of LP tokens to calculate the pair tokens for
    /// @return expectedTknAmount       The amount of pair tokens that should be received
    function getExpectedPairTokenOutUser(
        uint256 lpAmount_
    ) external returns (uint256 expectedTknAmount);

    /// @notice                         Gets all the reward tokens from the Aura pool
    /// @return address[]               The addresses of the reward tokens
    function getRewardTokens() external view returns (address[] memory);

    /// @notice                         Gets the reward rate (tokens per second) of the passed reward token
    /// @return uint256                 The reward rate (tokens per second)
    function getRewardRate(address rewardToken_) external view returns (uint256);

    /// @notice                         Returns the amount of OHM in the pool that is owned by this vault system.
    /// @return uint256                 The amount of OHM in the pool that is owned by this vault system.
    function getPoolOhmShare() external view returns (uint256);

    /// @notice                         Gets the net OHM emitted or removed by the system since inception
    /// @return uint256                 Vault system's current claim on OHM from the Balancer pool
    /// @return uint256                 Current amount of OHM minted by the system into the Balancer pool
    /// @return uint256                 OHM that wasn't minted, but was previously circulating that has been burned by the system
    function getOhmSupplyChangeData() external view returns (uint256, uint256, uint256);

    /// @notice                         Gets the number of OHM per 1 pair token using oracle prices
    /// @return uint256                 OHM per 1 pair token (9 decimals)
    function getOhmTknPrice() external view returns (uint256);

    /// @notice                         Gets the number of pair tokens per 1 OHM using oracle prices
    /// @return uint256                 Pair tokens per 1 OHM (18 decimals)
    function getTknOhmPrice() external view returns (uint256);

    /// @notice                         Gets the number of OHM per 1 pair token using pool prices
    /// @return uint256                 OHM per 1 pair token (9 decimals)
    function getOhmTknPoolPrice() external view returns (uint256);

    //============================================================================================//
    //                                        ADMIN FUNCTIONS                                     //
    //============================================================================================//

    /// @notice                         Emergency burns OHM that has been sent to the manager in the event a user had to emergency withdraw
    /// @dev                            Can only be called by the admin
    /// @param amount_                  The amount of OHM to burn
    function emergencyBurnOhm(uint256 amount_) external;

    /// @notice                         Updates the limit on minting OHM
    /// @dev                            Can only be called by the admin. Cannot be set lower than the current outstanding minted OHM.
    /// @param newLimit_                The new OHM limit (9 decimals)
    function setLimit(uint256 newLimit_) external;

    /// @notice                         Updates the fee on reward tokens
    /// @dev                            Can only be called by the admin. Cannot be set beyond 10_000 (100%). Only is used by vaults deployed after the update.
    /// @param newFee_                  The new fee (in basis points)
    function setFee(uint64 newFee_) external;

    /// @notice                         Updates the minimum holding period before a user can withdraw
    /// @dev                            Can only be called by the admin
    /// @param newDelay_                The new minimum holding period (in seconds)
    function setWithdrawalDelay(uint48 newDelay_) external;

    /// @notice                         Activates the vault manager and all approved vaults
    /// @dev                            Can only be called by the admin
    function activate() external;

    /// @notice                         Deactivates the vault manager and all approved vaults
    /// @dev                            Can only be called by the admin
    function deactivate() external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

// Import system dependencies
import {IBLVault, RewardsData} from "policies/BoostedLiquidity/interfaces/IBLVault.sol";
import {IBLVaultManager} from "policies/BoostedLiquidity/interfaces/IBLVaultManager.sol";
import {BLVaultManagerLusd} from "policies/BoostedLiquidity/BLVaultManagerLusd.sol";

// Import external dependencies
import {JoinPoolRequest, ExitPoolRequest, IVault, IBasePool} from "policies/BoostedLiquidity/interfaces/IBalancer.sol";
import {IAuraBooster, IAuraRewardPool, IAuraMiningLib, ISTASHToken} from "policies/BoostedLiquidity/interfaces/IAura.sol";

// Import types
import {OlympusERC20Token} from "src/external/OlympusERC20.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

// Import libraries
import {Clone} from "clones/Clone.sol";
import {TransferHelper} from "libraries/TransferHelper.sol";
import {FullMath} from "libraries/FullMath.sol";

contract BLVaultLusd is IBLVault, Clone {
    using TransferHelper for ERC20;
    using FullMath for uint256;

    // ========= ERRORS ========= //

    error BLVaultLusd_AlreadyInitialized();
    error BLVaultLusd_OnlyOwner();
    error BLVaultLusd_Active();
    error BLVaultLusd_Inactive();
    error BLVaultLusd_Reentrancy();
    error BLVaultLusd_AuraDepositFailed();
    error BLVaultLusd_AuraWithdrawalFailed();
    error BLVaultLusd_WithdrawFailedPriceImbalance();
    error BLVaultLusd_WithdrawalDelay();

    // ========= EVENTS ========= //

    event Deposit(uint256 ohmAmount, uint256 lusdAmount);
    event Withdraw(uint256 ohmAmount, uint256 lusdAmount);
    event RewardsClaimed(address indexed rewardsToken, uint256 amount);

    // ========= STATE VARIABLES ========= //

    /// @notice The last timestamp a deposit was made. Used for enforcing minimum deposit lengths.
    uint256 public lastDeposit;

    uint256 private constant _OHM_DECIMALS = 1e9;
    uint256 private constant _LUSD_DECIMALS = 1e18;

    uint256 private _reentrancyStatus;

    uint8 private constant _ohmIndex = 1;
    uint8 private constant _lusdIndex = 0;

    // ========= CONSTRUCTOR ========= //

    constructor() {}

    // ========= INITIALIZER ========= //

    function initializeClone() external {
        if (_reentrancyStatus != 0) revert BLVaultLusd_AlreadyInitialized();
        _reentrancyStatus = 1;
    }

    // ========= IMMUTABLE CLONE ARGS ========= //

    function owner() public pure returns (address) {
        return _getArgAddress(0);
    }

    function manager() public pure returns (BLVaultManagerLusd) {
        return BLVaultManagerLusd(_getArgAddress(20));
    }

    function TRSRY() public pure returns (address) {
        return _getArgAddress(40);
    }

    function MINTR() public pure returns (address) {
        return _getArgAddress(60);
    }

    function ohm() public pure returns (OlympusERC20Token) {
        return OlympusERC20Token(_getArgAddress(80));
    }

    function lusd() public pure returns (ERC20) {
        return ERC20(_getArgAddress(100));
    }

    function aura() public pure returns (ERC20) {
        return ERC20(_getArgAddress(120));
    }

    function bal() public pure returns (ERC20) {
        return ERC20(_getArgAddress(140));
    }

    function vault() public pure returns (IVault) {
        return IVault(_getArgAddress(160));
    }

    function liquidityPool() public pure returns (IBasePool) {
        return IBasePool(_getArgAddress(180));
    }

    function pid() public pure returns (uint256) {
        return _getArgUint256(200);
    }

    function auraBooster() public pure returns (IAuraBooster) {
        return IAuraBooster(_getArgAddress(232));
    }

    function auraRewardPool() public pure returns (IAuraRewardPool) {
        return IAuraRewardPool(_getArgAddress(252));
    }

    function fee() public pure returns (uint64) {
        return _getArgUint64(272);
    }

    // ========= MODIFIERS ========= //

    modifier onlyOwner() {
        if (msg.sender != owner()) revert BLVaultLusd_OnlyOwner();
        _;
    }

    modifier onlyWhileActive() {
        if (!manager().isLusdBLVaultActive()) revert BLVaultLusd_Inactive();
        _;
    }

    modifier onlyWhileInactive() {
        if (manager().isLusdBLVaultActive()) revert BLVaultLusd_Active();
        _;
    }

    modifier nonReentrant() {
        if (_reentrancyStatus != 1) revert BLVaultLusd_Reentrancy();

        _reentrancyStatus = 2;

        _;

        _reentrancyStatus = 1;
    }

    //============================================================================================//
    //                                      LIQUIDITY FUNCTIONS                                   //
    //============================================================================================//

    /// @inheritdoc IBLVault
    function deposit(
        uint256 amount_,
        uint256 minLpAmount_
    ) external override onlyWhileActive onlyOwner nonReentrant returns (uint256 lpAmountOut) {
        // Cache variables into memory
        IBLVaultManager manager = manager();
        OlympusERC20Token ohm = ohm();
        ERC20 lusd = lusd();
        IBasePool liquidityPool = liquidityPool();
        IAuraBooster auraBooster = auraBooster();

        uint256 ohmMintAmount;

        // Set last deposit timestamp
        lastDeposit = block.timestamp;

        // Block scope to avoid stack too deep
        // Calculate OHM amount to mint
        {
            // getOhmTknPrice returns the amount of OHM per 1 LUSD
            uint256 ohmLusdOraclePrice = manager.getOhmTknPrice();
            uint256 ohmLusdPoolPrice = manager.getOhmTknPoolPrice();

            // If the expected oracle price mint amount is less than the expected pool price mint amount, use the oracle price
            // otherwise use the pool price
            uint256 ohmLusdPrice = ohmLusdOraclePrice < ohmLusdPoolPrice
                ? ohmLusdOraclePrice
                : ohmLusdPoolPrice;
            ohmMintAmount = (amount_ * ohmLusdPrice) / _LUSD_DECIMALS;
        }

        // Block scope to avoid stack too deep
        // Get tokens and deposit to Balancer and Aura
        {
            // Cache OHM-LUSD BPT before
            uint256 bptBefore = liquidityPool.balanceOf(address(this));

            // Transfer in LUSD
            lusd.safeTransferFrom(msg.sender, address(this), amount_);

            // Mint OHM
            manager.mintOhmToVault(ohmMintAmount);

            // Join Balancer pool
            _joinBalancerPool(ohmMintAmount, amount_, minLpAmount_);

            // OHM-PAIR BPT after
            lpAmountOut = liquidityPool.balanceOf(address(this)) - bptBefore;
            manager.increaseTotalLp(lpAmountOut);

            // Stake into Aura
            liquidityPool.approve(address(auraBooster), lpAmountOut);
            bool depositSuccess = auraBooster.deposit(pid(), lpAmountOut, true);
            if (!depositSuccess) revert BLVaultLusd_AuraDepositFailed();
        }

        // Return unused tokens
        uint256 unusedOhm = ohm.balanceOf(address(this));
        uint256 unusedLusd = lusd.balanceOf(address(this));

        if (unusedOhm > 0) {
            ohm.increaseAllowance(MINTR(), unusedOhm);
            manager.burnOhmFromVault(unusedOhm);
        }

        if (unusedLusd > 0) {
            lusd.safeTransfer(msg.sender, unusedLusd);
        }

        // Emit event
        emit Deposit(ohmMintAmount - unusedOhm, amount_ - unusedLusd);

        return lpAmountOut;
    }

    /// @inheritdoc IBLVault
    function withdraw(
        uint256 lpAmount_,
        uint256[] calldata minTokenAmountsBalancer_,
        uint256 minTokenAmountUser_,
        bool claim_
    ) external override onlyOwner nonReentrant returns (uint256, uint256) {
        // Cache variables into memory
        OlympusERC20Token ohm = ohm();
        ERC20 lusd = lusd();
        IBLVaultManager manager = manager();

        // Check if enough time has passed since the latest deposit
        if (block.timestamp - lastDeposit < manager.minWithdrawalDelay())
            revert BLVaultLusd_WithdrawalDelay();

        // Cache OHM and LUSD balances before
        uint256 ohmBefore = ohm.balanceOf(address(this));
        uint256 lusdBefore = lusd.balanceOf(address(this));

        // Decrease total LP
        manager.decreaseTotalLp(lpAmount_);

        // Unstake from Aura
        bool withdrawalSuccess = auraRewardPool().withdrawAndUnwrap(lpAmount_, claim_);
        if (!withdrawalSuccess) revert BLVaultLusd_AuraWithdrawalFailed();

        // Exit Balancer pool
        _exitBalancerPool(lpAmount_, minTokenAmountsBalancer_);

        // Calculate OHM and LUSD amounts received
        uint256 ohmAmountOut = ohm.balanceOf(address(this)) - ohmBefore;
        uint256 lusdAmountOut = lusd.balanceOf(address(this)) - lusdBefore;

        // Calculate oracle expected LUSD received amount
        // getTknOhmPrice returns the amount of LUSD per 1 OHM based on the oracle price
        uint256 lusdOhmPrice = manager.getTknOhmPrice();
        uint256 expectedLusdAmountOut = (ohmAmountOut * lusdOhmPrice) / _OHM_DECIMALS;

        // Take any arbs relative to the oracle price for the Treasury and return the rest to the owner
        uint256 lusdToReturn = lusdAmountOut > expectedLusdAmountOut
            ? expectedLusdAmountOut
            : lusdAmountOut;

        if (lusdToReturn < minTokenAmountUser_) revert BLVaultLusd_WithdrawFailedPriceImbalance();
        if (lusdAmountOut > lusdToReturn) lusd.safeTransfer(TRSRY(), lusdAmountOut - lusdToReturn);

        // Burn OHM
        ohm.increaseAllowance(MINTR(), ohmAmountOut);
        manager.burnOhmFromVault(ohmAmountOut);

        // Return LUSD to owner
        lusd.safeTransfer(msg.sender, lusdToReturn);

        // Return rewards to owner
        if (claim_) _sendRewards();

        // Emit event
        emit Withdraw(ohmAmountOut, lusdToReturn);

        return (ohmAmountOut, lusdToReturn);
    }

    /// @inheritdoc IBLVault
    function emergencyWithdraw(
        uint256 lpAmount_,
        uint256[] calldata minTokenAmounts_
    ) external override onlyWhileInactive onlyOwner nonReentrant returns (uint256, uint256) {
        // Cache variables into memory
        OlympusERC20Token ohm = ohm();
        ERC20 lusd = lusd();

        // Cache OHM and LUSD balances before
        uint256 ohmBefore = ohm.balanceOf(address(this));
        uint256 lusdBefore = lusd.balanceOf(address(this));

        // Unstake from Aura
        auraRewardPool().withdrawAndUnwrap(lpAmount_, false);

        // Exit Balancer pool
        _exitBalancerPool(lpAmount_, minTokenAmounts_);

        // Calculate OHM and LUSD amounts received
        uint256 ohmAmountOut = ohm.balanceOf(address(this)) - ohmBefore;
        uint256 lusdAmountOut = lusd.balanceOf(address(this)) - lusdBefore;

        // Transfer LUSD to owner
        lusd.safeTransfer(msg.sender, lusdAmountOut);

        // Transfer OHM to manager
        ohm.transfer(address(manager()), ohmAmountOut);

        return (ohmAmountOut, lusdAmountOut);
    }

    //============================================================================================//
    //                                       REWARDS FUNCTIONS                                    //
    //============================================================================================//

    /// @inheritdoc IBLVault
    function claimRewards() external override onlyWhileActive onlyOwner nonReentrant {
        // Claim rewards from Aura
        auraRewardPool().getReward(address(this), true);

        // Send rewards to owner
        _sendRewards();
    }

    //============================================================================================//
    //                                        VIEW FUNCTIONS                                      //
    //============================================================================================//

    /// @inheritdoc IBLVault
    function canWithdraw() external view override returns (bool) {
        return block.timestamp - lastDeposit >= manager().minWithdrawalDelay();
    }

    /// @inheritdoc IBLVault
    function getLpBalance() public view override returns (uint256) {
        return auraRewardPool().balanceOf(address(this));
    }

    /// @inheritdoc IBLVault
    function getUserPairShare() public view override returns (uint256) {
        // If total supply is 0 return 0
        if (liquidityPool().totalSupply() == 0) return 0;

        // Get user's LP balance
        uint256 userLpBalance = getLpBalance();

        // Get pool balances
        (, uint256[] memory balances, ) = vault().getPoolTokens(liquidityPool().getPoolId());

        // Get user's share of the LUSD
        uint256 userLusdShare = (userLpBalance * balances[_lusdIndex]) /
            liquidityPool().totalSupply();

        // Check pool against oracle price
        // getTknOhmPrice returns the amount of LUSD per 1 OHM based on the oracle price
        uint256 lusdOhmPrice = manager().getTknOhmPrice();
        uint256 expectedLusdShare = (userLpBalance * balances[_ohmIndex] * lusdOhmPrice) /
            (liquidityPool().totalSupply() * _OHM_DECIMALS);

        return userLusdShare > expectedLusdShare ? expectedLusdShare : userLusdShare;
    }

    /// @inheritdoc IBLVault
    function getOutstandingRewards() public view override returns (RewardsData[] memory) {
        uint256 numExtraRewards = auraRewardPool().extraRewardsLength();
        RewardsData[] memory rewards = new RewardsData[](numExtraRewards + 2);

        // Get Bal reward
        uint256 balRewards = auraRewardPool().earned(address(this));
        rewards[0] = RewardsData({rewardToken: address(bal()), outstandingRewards: balRewards});

        // Get Aura rewards
        uint256 auraRewards = manager().auraMiningLib().convertCrvToCvx(balRewards);
        rewards[1] = RewardsData({rewardToken: address(aura()), outstandingRewards: auraRewards});

        // Get extra rewards
        for (uint256 i; i < numExtraRewards; ) {
            IAuraRewardPool extraRewardPool = IAuraRewardPool(auraRewardPool().extraRewards(i));

            address extraRewardToken = ISTASHToken(extraRewardPool.rewardToken()).baseToken();
            uint256 extraRewardAmount = extraRewardPool.earned(address(this));

            rewards[i + 2] = RewardsData({
                rewardToken: extraRewardToken,
                outstandingRewards: extraRewardAmount
            });

            unchecked {
                ++i;
            }
        }

        return rewards;
    }

    //============================================================================================//
    //                                      INTERNAL FUNCTIONS                                    //
    //============================================================================================//

    function _joinBalancerPool(
        uint256 ohmAmount_,
        uint256 lusdAmount_,
        uint256 minLpAmount_
    ) internal {
        // Cache variables to memory
        OlympusERC20Token ohm = ohm();
        ERC20 lusd = lusd();
        IVault vault = vault();

        // Build join pool request
        address[] memory assets = new address[](2);
        assets[_ohmIndex] = address(ohm);
        assets[_lusdIndex] = address(lusd);

        uint256[] memory maxAmountsIn = new uint256[](2);
        maxAmountsIn[_ohmIndex] = ohmAmount_;
        maxAmountsIn[_lusdIndex] = lusdAmount_;

        JoinPoolRequest memory joinPoolRequest = JoinPoolRequest({
            assets: assets,
            maxAmountsIn: maxAmountsIn,
            userData: abi.encode(1, maxAmountsIn, minLpAmount_),
            fromInternalBalance: false
        });

        // Join pool
        ohm.increaseAllowance(address(vault), ohmAmount_);
        lusd.approve(address(vault), lusdAmount_);
        vault.joinPool(liquidityPool().getPoolId(), address(this), address(this), joinPoolRequest);
    }

    function _exitBalancerPool(uint256 lpAmount_, uint256[] calldata minTokenAmounts_) internal {
        // Cache variables to memory
        OlympusERC20Token ohm = ohm();
        ERC20 lusd = lusd();
        IBasePool liquidityPool = liquidityPool();
        IVault vault = vault();

        // Build exit pool request
        address[] memory assets = new address[](2);
        assets[_ohmIndex] = address(ohm);
        assets[_lusdIndex] = address(lusd);

        ExitPoolRequest memory exitPoolRequest = ExitPoolRequest({
            assets: assets,
            minAmountsOut: minTokenAmounts_,
            userData: abi.encode(1, lpAmount_),
            toInternalBalance: false
        });

        // Exit Balancer pool
        liquidityPool.approve(address(vault), lpAmount_);
        vault.exitPool(
            liquidityPool.getPoolId(),
            address(this),
            payable(address(this)),
            exitPoolRequest
        );
    }

    function _sendRewards() internal {
        // Send Bal rewards to owner
        {
            uint256 balRewards = bal().balanceOf(address(this));
            uint256 balFee = (balRewards * fee()) / 10_000;
            if (balRewards - balFee > 0) {
                bal().safeTransfer(owner(), balRewards - balFee);
                emit RewardsClaimed(address(bal()), balRewards - balFee);
            }
            if (balFee > 0) bal().safeTransfer(TRSRY(), balFee);
        }

        // Send Aura rewards to owner
        {
            uint256 auraRewards = aura().balanceOf(address(this));
            uint256 auraFee = (auraRewards * fee()) / 10_000;
            if (auraRewards - auraFee > 0) {
                aura().safeTransfer(owner(), auraRewards - auraFee);
                emit RewardsClaimed(address(aura()), auraRewards - auraFee);
            }
            if (auraFee > 0) aura().safeTransfer(TRSRY(), auraFee);
        }

        // Send extra rewards to owner
        {
            uint256 numExtraRewards = auraRewardPool().extraRewardsLength();
            for (uint256 i; i < numExtraRewards; ) {
                IAuraRewardPool extraRewardPool = IAuraRewardPool(auraRewardPool().extraRewards(i));
                ERC20 extraRewardToken = ERC20(
                    ISTASHToken(extraRewardPool.rewardToken()).baseToken()
                );

                uint256 extraRewardAmount = extraRewardToken.balanceOf(address(this));
                uint256 extraRewardFee = (extraRewardAmount * fee()) / 10_000;
                if (extraRewardAmount - extraRewardFee > 0) {
                    extraRewardToken.safeTransfer(owner(), extraRewardAmount - extraRewardFee);
                    emit RewardsClaimed(
                        address(extraRewardToken),
                        extraRewardAmount - extraRewardFee
                    );
                }
                if (extraRewardFee > 0) extraRewardToken.safeTransfer(TRSRY(), extraRewardFee);

                unchecked {
                    ++i;
                }
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5;

/// @notice Olympus OHM token
/// @dev This contract is the legacy v2 OHM token. Included in the repo for completeness,
///      since it is not being changed and is imported in some contracts.

interface IOlympusAuthority {
    // =========  EVENTS ========= //

    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event GuardianPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);

    // =========  VIEW ========= //

    function governor() external view returns (address);

    function guardian() external view returns (address);

    function policy() external view returns (address);

    function vault() external view returns (address);
}

// File: types/OlympusAccessControlled.sol

abstract contract OlympusAccessControlled {
    // =========  EVENTS ========= //

    event AuthorityUpdated(IOlympusAuthority indexed authority);

    string internal UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    // =========  STATE VARIABLES ========= //

    IOlympusAuthority public authority;

    // =========  Constructor ========= //

    constructor(IOlympusAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    // =========  MODIFIERS ========= //

    modifier onlyGovernor() {
        require(msg.sender == authority.governor(), UNAUTHORIZED);
        _;
    }

    modifier onlyGuardian() {
        require(msg.sender == authority.guardian(), UNAUTHORIZED);
        _;
    }

    modifier onlyPermitted() {
        require(msg.sender == authority.policy(), UNAUTHORIZED);
        _;
    }

    modifier onlyVault() {
        require(msg.sender == authority.vault(), UNAUTHORIZED);
        _;
    }

    // =========  GOV ONLY ========= //

    function setAuthority(IOlympusAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}

// File: cryptography/ECDSA.sol

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(
        bytes32 domainSeparator,
        bytes32 structHash
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// File: cryptography/EIP712.sol

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        uint256 chainID;
        assembly {
            chainID := chainid()
        }

        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = chainID;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        uint256 chainID;
        assembly {
            chainID := chainid()
        }

        if (chainID == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        uint256 chainID;
        assembly {
            chainID := chainid()
        }

        return keccak256(abi.encode(typeHash, nameHash, versionHash, chainID, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// File: interfaces/IERC20Permit.sol

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as th xe allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// File: interfaces/IERC20.sol

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// File: interfaces/IOHM.sol

interface IOHM is IERC20 {
    function mint(address account_, uint256 amount_) external;

    function burn(uint256 amount) external;

    function burnFrom(address account_, uint256 amount_) external;
}

// File: libraries/SafeMath.sol

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        assert(a == b * c + (a % b)); // There is no case in which this doesn't hold

        return c;
    }

    // Only used in the  BondingCalculator.sol
    function sqrrt(uint256 a) internal pure returns (uint256 c) {
        if (a > 3) {
            c = a;
            uint256 b = add(div(a, 2), 1);
            while (b < c) {
                c = b;
                b = div(add(div(a, b), b), 2);
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}

// File: libraries/Counters.sol

library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// File: types/ERC20.sol

abstract contract ERC20 is IERC20 {
    using SafeMath for uint256;

    // TODO comment actual hash value.
    bytes32 private constant ERC20TOKEN_ERC1820_INTERFACE_ID = keccak256("ERC20Token");

    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 internal _totalSupply;

    string internal _name;

    string internal _symbol;

    uint8 internal immutable _decimals;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance")
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from_, address to_, uint256 amount_) internal virtual {}
}

// File: types/ERC20Permit.sol

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(
            abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline)
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// File: OlympusERC20.sol

contract OlympusERC20Token is ERC20Permit, IOHM, OlympusAccessControlled {
    using SafeMath for uint256;

    constructor(
        address _authority
    )
        ERC20("Olympus", "OHM", 9)
        ERC20Permit("Olympus")
        OlympusAccessControlled(IOlympusAuthority(_authority))
    {}

    function mint(address account_, uint256 amount_) external override onlyVault {
        _mint(account_, amount_);
    }

    function burn(uint256 amount) external override {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account_, uint256 amount_) external override {
        _burnFrom(account_, amount_);
    }

    function _burnFrom(address account_, uint256 amount_) internal {
        uint256 decreasedAllowance_ = allowance(account_, msg.sender).sub(
            amount_,
            "ERC20: burn amount exceeds allowance"
        );

        _approve(account_, msg.sender, decreasedAllowance_);
        _burn(account_, amount_);
    }
}

// SPDX-License-Identifier: BSD

pragma solidity ^0.8.4;

/// @title ClonesWithImmutableArgs
/// @author wighawag, zefram.eth
/// @notice Enables creating clone contracts with immutable args
library ClonesWithImmutableArgs {
    error CreateFail();

    /// @notice Creates a clone proxy of the implementation contract, with immutable args
    /// @dev data cannot exceed 65535 bytes, since 2 bytes are used to store the data length
    /// @param implementation The implementation contract to clone
    /// @param data Encoded immutable args
    /// @return instance The address of the created clone
    function clone(address implementation, bytes memory data)
        internal
        returns (address instance)
    {
        // unrealistic for memory ptr or data length to exceed 256 bits
        unchecked {
            uint256 extraLength = data.length + 2; // +2 bytes for telling how much data there is appended to the call
            uint256 creationSize = 0x43 + extraLength;
            uint256 runSize = creationSize - 11;
            uint256 dataPtr;
            uint256 ptr;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                ptr := mload(0x40)

                // -------------------------------------------------------------------------------------------------------------
                // CREATION (11 bytes)
                // -------------------------------------------------------------------------------------------------------------

                // 3d          | RETURNDATASIZE        | 0                       | –
                // 61 runtime  | PUSH2 runtime (r)     | r 0                     | –
                mstore(
                    ptr,
                    0x3d61000000000000000000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x02), shl(240, runSize)) // size of the contract running bytecode (16 bits)

                // creation size = 0b
                // 80          | DUP1                  | r r 0                   | –
                // 60 creation | PUSH1 creation (c)    | c r r 0                 | –
                // 3d          | RETURNDATASIZE        | 0 c r r 0               | –
                // 39          | CODECOPY              | r 0                     | [0-2d]: runtime code
                // 81          | DUP2                  | 0 c  0                  | [0-2d]: runtime code
                // f3          | RETURN                | 0                       | [0-2d]: runtime code
                mstore(
                    add(ptr, 0x04),
                    0x80600b3d3981f300000000000000000000000000000000000000000000000000
                )

                // -------------------------------------------------------------------------------------------------------------
                // RUNTIME
                // -------------------------------------------------------------------------------------------------------------

                // 36          | CALLDATASIZE          | cds                     | –
                // 3d          | RETURNDATASIZE        | 0 cds                   | –
                // 3d          | RETURNDATASIZE        | 0 0 cds                 | –
                // 37          | CALLDATACOPY          | –                       | [0, cds] = calldata
                // 61          | PUSH2 extra           | extra                   | [0, cds] = calldata
                mstore(
                    add(ptr, 0x0b),
                    0x363d3d3761000000000000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x10), shl(240, extraLength))

                // 60 0x38     | PUSH1 0x38            | 0x38 extra              | [0, cds] = calldata // 0x38 (56) is runtime size - data
                // 36          | CALLDATASIZE          | cds 0x38 extra          | [0, cds] = calldata
                // 39          | CODECOPY              | _                       | [0, cds] = calldata
                // 3d          | RETURNDATASIZE        | 0                       | [0, cds] = calldata
                // 3d          | RETURNDATASIZE        | 0 0                     | [0, cds] = calldata
                // 3d          | RETURNDATASIZE        | 0 0 0                   | [0, cds] = calldata
                // 36          | CALLDATASIZE          | cds 0 0 0               | [0, cds] = calldata
                // 61 extra    | PUSH2 extra           | extra cds 0 0 0         | [0, cds] = calldata
                mstore(
                    add(ptr, 0x12),
                    0x603836393d3d3d36610000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x1b), shl(240, extraLength))

                // 01          | ADD                   | cds+extra 0 0 0         | [0, cds] = calldata
                // 3d          | RETURNDATASIZE        | 0 cds 0 0 0             | [0, cds] = calldata
                // 73 addr     | PUSH20 0x123…         | addr 0 cds 0 0 0        | [0, cds] = calldata
                mstore(
                    add(ptr, 0x1d),
                    0x013d730000000000000000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x20), shl(0x60, implementation))

                // 5a          | GAS                   | gas addr 0 cds 0 0 0    | [0, cds] = calldata
                // f4          | DELEGATECALL          | success 0               | [0, cds] = calldata
                // 3d          | RETURNDATASIZE        | rds success 0           | [0, cds] = calldata
                // 82          | DUP3                  | 0 rds success 0         | [0, cds] = calldata
                // 80          | DUP1                  | 0 0 rds success 0       | [0, cds] = calldata
                // 3e          | RETURNDATACOPY        | success 0               | [0, rds] = return data (there might be some irrelevant leftovers in memory [rds, cds] when rds < cds)
                // 90          | SWAP1                 | 0 success               | [0, rds] = return data
                // 3d          | RETURNDATASIZE        | rds 0 success           | [0, rds] = return data
                // 91          | SWAP2                 | success 0 rds           | [0, rds] = return data
                // 60 0x36     | PUSH1 0x36            | 0x36 sucess 0 rds       | [0, rds] = return data
                // 57          | JUMPI                 | 0 rds                   | [0, rds] = return data
                // fd          | REVERT                | –                       | [0, rds] = return data
                // 5b          | JUMPDEST              | 0 rds                   | [0, rds] = return data
                // f3          | RETURN                | –                       | [0, rds] = return data

                mstore(
                    add(ptr, 0x34),
                    0x5af43d82803e903d91603657fd5bf30000000000000000000000000000000000
                )
            }

            // -------------------------------------------------------------------------------------------------------------
            // APPENDED DATA (Accessible from extcodecopy)
            // (but also send as appended data to the delegatecall)
            // -------------------------------------------------------------------------------------------------------------

            extraLength -= 2;
            uint256 counter = extraLength;
            uint256 copyPtr = ptr + 0x43;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                dataPtr := add(data, 32)
            }
            for (; counter >= 32; counter -= 32) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    mstore(copyPtr, mload(dataPtr))
                }

                copyPtr += 32;
                dataPtr += 32;
            }
            uint256 mask = ~(256**(32 - counter) - 1);
            // solhint-disable-next-line no-inline-assembly
            assembly {
                mstore(copyPtr, and(mload(dataPtr), mask))
            }
            copyPtr += counter;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                mstore(copyPtr, shl(240, extraLength))
            }
            // solhint-disable-next-line no-inline-assembly
            assembly {
                instance := create(0, ptr, creationSize)
            }
            if (instance == address(0)) {
                revert CreateFail();
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

import "src/Kernel.sol";

abstract contract ROLESv1 is Module {
    // =========  EVENTS ========= //

    event RoleGranted(bytes32 indexed role_, address indexed addr_);
    event RoleRevoked(bytes32 indexed role_, address indexed addr_);

    // =========  ERRORS ========= //

    error ROLES_InvalidRole(bytes32 role_);
    error ROLES_RequireRole(bytes32 role_);
    error ROLES_AddressAlreadyHasRole(address addr_, bytes32 role_);
    error ROLES_AddressDoesNotHaveRole(address addr_, bytes32 role_);
    error ROLES_RoleDoesNotExist(bytes32 role_);

    // =========  STATE ========= //

    /// @notice Mapping for if an address has a policy-defined role.
    mapping(address => mapping(bytes32 => bool)) public hasRole;

    // =========  FUNCTIONS ========= //

    /// @notice Function to grant policy-defined roles to some address. Can only be called by admin.
    function saveRole(bytes32 role_, address addr_) external virtual;

    /// @notice Function to revoke policy-defined roles from some address. Can only be called by admin.
    function removeRole(bytes32 role_, address addr_) external virtual;

    /// @notice "Modifier" to restrict policy function access to certain addresses with a role.
    /// @dev    Roles are defined in the policy and granted by the ROLES admin.
    function requireRole(bytes32 role_, address caller_) external virtual;

    /// @notice Function that checks if role is valid (all lower case)
    function ensureValidRole(bytes32 role_) external pure virtual;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: BSD
pragma solidity ^0.8.4;

/// @title Clone
/// @author zefram.eth
/// @notice Provides helper functions for reading immutable args from calldata
contract Clone {
    /// @notice Reads an immutable arg with type address
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgAddress(uint256 argOffset)
        internal
        pure
        returns (address arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        assembly {
            arg := shr(0x60, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type uint256
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint256(uint256 argOffset)
        internal
        pure
        returns (uint256 arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := calldataload(add(offset, argOffset))
        }
    }

    /// @notice Reads an immutable arg with type uint64
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint64(uint256 argOffset)
        internal
        pure
        returns (uint64 arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xc0, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type uint8
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint8(uint256 argOffset) internal pure returns (uint8 arg) {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xf8, calldataload(add(offset, argOffset)))
        }
    }

    /// @return offset The offset of the packed immutable args in calldata
    function _getImmutableArgsOffset() internal pure returns (uint256 offset) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            offset := sub(
                calldatasize(),
                add(shr(240, calldataload(sub(calldatasize(), 2))), 2)
            )
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";

/// @notice Safe ERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap & old Solmate (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
library TransferHelper {
    function safeTransferFrom(ERC20 token, address from, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(ERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(ERC20 token, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(ERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(ERC20 token, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(ERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (type(uint256).max - denominator + 1) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        unchecked {
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}