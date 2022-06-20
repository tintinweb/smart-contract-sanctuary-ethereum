// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";
import "../release/core/fund-deployer/IFundDeployer.sol";
import "./interfaces/IFNDZController.sol";
import "./interfaces/IFNDZStaking.sol";

contract FNDZControllerTest is IFNDZController, OwnableUpgradeable {
    using SafeMath for uint256;
    using BytesLib for bytes;

    // Constants
    uint256 private constant RATE_DIVISOR = 10**18;

    // State Variables
    address public override fndzToken;
    mapping(address => FeeConfiguration) private feeConfigurations;
    mapping(address => bool) private approvedDenominationAssets;
    address private uniswapV2Router02;
    address public uniswapV2Factory;
    address public fndzStakingPool;
    address public override fndzDao;
    address public fndzDaoDesiredToken;
    address public fundDeployer;

    uint256 private managementFeeVaultOwnerSplit;
    uint256 private managementFeeStakingAndDaoSplit;
    uint256 private performanceFeeVaultOwnerSplitBase;
    uint256 private performanceFeeVaultOwnerSplitMax;
    uint256 private performanceFeeTierZeroAmountStaked;
    uint256 private performanceFeeAmountStakedIncrement;
    uint256 private performanceFeeVaultOwnerSplitIncreasePerTier;
    uint256 private inlineSwapDeadlineIncrement;
    uint256 private inlineSwapMinimumPercentReceived;
    uint256 private paraSwapFee;

    // Structs
    struct FeeConfiguration {
        bool valid;
        uint256[] parameterMinValues;
        uint256[] parameterMaxValues;
    }

    // Events
    event DenominationAssetAdded(address asset);
    event DenominationAssetRemoved(address asset);
    event InlineSwapRouterUpdated(address _oldRouter, address _newRouter);
    event InlineSwapFactoryUpdated(address _oldFactory, address _newFactory);
    event FndzStakingPoolUpdated(address _oldPool, address _newPool);
    event FndzDaoUpdated(address _oldDao, address _newDao);
    event FndzDaoDesiredTokenUpdated(address _oldToken, address _newToken);
    event FundDeployerUpdated(address _oldFundDeployer, address _newFundDeployer);
    event FeeConfigurationUpdated(address _feeAddress);
    event FeeConfigurationRemoved(address _feeAddress);
    event ParaSwapFeeUpdated(uint256 _fee);
    event ManagementFeeSplitUpdated(
        uint256 _oldVaultOwnerSplit,
        uint256 _oldDaoAndStakingSplit,
        uint256 _newVaultOwnerSplit,
        uint256 _newDaoAndStakingSplit
    );
    event PerformanceFeeSplitUpdated(
        uint256 _oldVaultOwnerSplitBase,
        uint256 _nextVaultOwnerSplitBase,
        uint256 _oldVaultOwnerSplitMax,
        uint256 _nextVaultOwnerSplitMax,
        uint256 _oldTierZeroAmountStaked,
        uint256 _nextTierZeroAmountStaked,
        uint256 _oldAmountStakedIncrement,
        uint256 _nextAmountStakedIncrement,
        uint256 _oldVaultOwnerSplitIncreasePerTier,
        uint256 _nextVaultOwnerSplitIncreasePerTier
    );
    event InlineSwapAllowancesUpdated(
        uint256 _oldDeadlineIncrement,
        uint256 _oldMinimumPercentageReceived,
        uint256 _newDeadlineIncrement,
        uint256 _newMinimumPercentageReceived
    );

    modifier notZeroAddress(address _address) {
        require(_address != address(0), "Address should not be zero address");
        _;
    }

    /// @notice Initialize the upgradeable FNDZController smart contract
    /// @param _uniswapV2Router02 The address of the Uniswap V2 Router 02 contract
    /// @param _uniswapV2Factory The address of the Uniswap V2 Factory contract
    /// @param _fndzDao The address of the FNDZ DAO
    /// @param _fndzDaoDesiredToken The address of the token in which the FNDZ DAO wishes to collect fee payments
    function initialize(
        address _fndzToken,
        address _uniswapV2Router02,
        address _uniswapV2Factory,
        address _fndzDao,
        address _fndzDaoDesiredToken
    ) public initializer {
        __Ownable_init();

        /// State Variable Initializations ///
        fndzToken = _fndzToken;
        // Management Fee splits
        managementFeeVaultOwnerSplit = 500000000000000000; // 50% of management fee  to vault owner
        managementFeeStakingAndDaoSplit = 250000000000000000; // 25% of management fee goes to staking and dao (each)
        // Performance Fee splits
        performanceFeeVaultOwnerSplitBase = 500000000000000000; // 50% of performance fee to vault owner
        performanceFeeVaultOwnerSplitMax = 750000000000000000; // vault owner is entitled to a maximum of 75% of the performance fee
        // To qualify for the first tier of a larger share of the performance fee, the vaultOwner must stake
        // performanceFeeTierZeroAmountStaked + performanceFeeAmountStakedIncrement = 1000 FNDZ Tokens
        performanceFeeTierZeroAmountStaked = 0;
        performanceFeeAmountStakedIncrement = 1000000000000000000000; // 1000 FNDZ
        // For every additional 1000 FNDZ staked, the vault owner gets 2.5% more of the performance fee
        performanceFeeVaultOwnerSplitIncreasePerTier = 25000000000000000;
        // Inline swap allowances
        inlineSwapDeadlineIncrement = 60; // the number of seconds within which a swap must succeed during inline fee share redemption
        inlineSwapMinimumPercentReceived = 950000000000000000; // the minimum percent of swap destination tokens that must be received relative to the spot price
        // ParaSwap Fee
        paraSwapFee = 20; // DivideFactor 10000 (Eg, 10% = 1000)

        uniswapV2Router02 = _uniswapV2Router02;
        uniswapV2Factory = _uniswapV2Factory;
        fndzDao = _fndzDao;
        fndzDaoDesiredToken = _fndzDaoDesiredToken;
        emit InlineSwapRouterUpdated(address(0), _uniswapV2Router02);
        emit InlineSwapFactoryUpdated(address(0), _uniswapV2Factory);
        emit FndzDaoUpdated(address(0), _fndzDao);
        emit FndzDaoDesiredTokenUpdated(address(0), _fndzDaoDesiredToken);
    }

    /// @notice Adds assets so that they may be used as the denomination asset of vaults
    /// @param _assets A list of denomination assets to approve
    function addDenominationAssets(address[] calldata _assets) external onlyOwner {
        for (uint256 i = 0; i < _assets.length; i++) {
            // check if Denomination Asset is unique
            require(
                approvedDenominationAssets[_assets[i]] == false,
                "addDenominationAssets: asset already added"
            );
            approvedDenominationAssets[_assets[i]] = true;
            emit DenominationAssetAdded(_assets[i]);
        }
    }

    /// @notice Removes assets so that they may not be used as the denomination asset of vaults
    /// @param _assets A list of denomination assets to remove
    function removeDenominationAssets(address[] calldata _assets) external onlyOwner {
        for (uint256 i = 0; i < _assets.length; i++) {
            require(
                approvedDenominationAssets[_assets[i]] == true,
                "removeDenominationAssets: cannot remove a denomination that has not been added"
            );
            delete approvedDenominationAssets[_assets[i]];
            emit DenominationAssetRemoved(_assets[i]);
        }
    }

    /// @notice Returns true if the asset is approved to be used as the denomination asset of a vault
    /// @param _asset The token address to check
    function isDenominationAssetApproved(address _asset) external view returns (bool) {
        return approvedDenominationAssets[_asset];
    }

    /// @notice Sets the Uniswap V2 Router 02 address used for inline swaps
    /// @param _uniswapV2Router02 The Uniswap V2 Router 02 contract address
    function updateInlineSwapRouterAddress(address _uniswapV2Router02)
        external
        onlyOwner
        notZeroAddress(_uniswapV2Router02)
    {
        address oldRouter = uniswapV2Router02;
        uniswapV2Router02 = _uniswapV2Router02;
        emit InlineSwapRouterUpdated(oldRouter, _uniswapV2Router02);
    }

    /// @notice Returns the Uniswap V2 Router 02 address used for inline swaps
    function getInlineSwapRouterAddress() external view override returns (address) {
        return uniswapV2Router02;
    }

    /// @notice Sets the Uniswap V2 Factory address used for inline swap during inline fee redemption
    /// @param _uniswapV2Factory The Uniswap V2 Factory contract address
    function updateInlineSwapFactoryAddress(address _uniswapV2Factory)
        external
        onlyOwner
        notZeroAddress(_uniswapV2Factory)
    {
        address oldFactory = uniswapV2Factory;
        uniswapV2Factory = _uniswapV2Factory;
        emit InlineSwapFactoryUpdated(oldFactory, _uniswapV2Factory);
    }

    /// @notice Sets the FNDZ Staking Pool address to which fees are paid out
    /// @param _fndzStakingPool The FNDZ Staking Pool contract address
    function updateFndzStakingPoolAddress(address _fndzStakingPool)
        external
        onlyOwner
        notZeroAddress(_fndzStakingPool)
    {
        address oldStaking = fndzStakingPool;
        fndzStakingPool = _fndzStakingPool;
        emit FndzStakingPoolUpdated(oldStaking, _fndzStakingPool);
    }

    /// @notice Sets the FNDZ DAO address to which fees are paid out
    /// @param _fndzDao The FNDZ DAO contract address
    function updateFndzDaoAddress(address _fndzDao) external onlyOwner notZeroAddress(_fndzDao) {
        address oldDao = fndzDao;
        fndzDao = _fndzDao;
        emit FndzDaoUpdated(oldDao, _fndzDao);
    }

    /// @notice Sets the token to which fees owed to the FNDZ DAO will be attempted to be
    /// swapped to during inline fee share redemption. In order for the swap to work correctly, the
    /// desired token should be selected such that there exists a trading pool between it and each
    /// of the assets traded by the vaults. If a pool does not exist between the desired token and a
    /// trade asset, the trade asset will be sent to the FNDZ DAO without being swapped.
    /// @param _fndzDaoDesiredToken The address of the token in which the FNDZ DAO wishes to collect fee payments
    function updateFndzDaoDesiredToken(address _fndzDaoDesiredToken)
        external
        notZeroAddress(_fndzDaoDesiredToken)
    {
        require(
            msg.sender == fndzDao,
            "updateFndzDaoDesiredToken: function may only be called by the FNDZ DAO"
        );
        address oldToken = fndzDaoDesiredToken;
        fndzDaoDesiredToken = _fndzDaoDesiredToken;
        emit FndzDaoDesiredTokenUpdated(oldToken, _fndzDaoDesiredToken);
    }

    /// @notice Sets the Fund Deployer address
    /// @param _fundDeployer The Fund Deployer contract address
    function updateFundDeployerAddress(address _fundDeployer) external onlyOwner {
        address oldFundDeployer = fundDeployer;
        fundDeployer = _fundDeployer;
        emit FundDeployerUpdated(oldFundDeployer, _fundDeployer);
    }

    /// @notice Sets the ParaSwap Fee percentage collected by the FNDZ DAO
    /// @param _fee The fee percentage
    function updateParaSwapFee(uint256 _fee) external onlyOwner {
        require(0 <= _fee && _fee <= 10000, "_fee should be >=0 and <= 10000");
        paraSwapFee = _fee;
        emit ParaSwapFeeUpdated(_fee);
    }

    /// @notice Returns the current ParaSwapFee percentage
    function getParaSwapFee() external view override returns (uint256 _fee) {
        return paraSwapFee;
    }

    /// @notice Returns the current owner of the FNDZ Controller
    /// @return owner_ The owner address
    function getOwner() external view override returns (address owner_) {
        return owner();
    }

    /// @notice Sets the percentages of the management fee that are paid to the vault owner,
    /// to the FNDZ Staking Pool, and to the FNDZ DAO
    /// @param _vaultOwnerSplit The percentage of the management fee that goes to the Vault Owner
    /// @param _stakingAndDaoSplit The percentage of the management fee per beneficiary that goes
    /// to the FNDZ Staking Pool and the FNDZ DAO
    function updateManagementFeeSplit(uint256 _vaultOwnerSplit, uint256 _stakingAndDaoSplit)
        external
        onlyOwner
    {
        require(
            (_vaultOwnerSplit + (_stakingAndDaoSplit * 2)) == RATE_DIVISOR,
            "updateManagementFeeSplit: _vaultOwnerSplit + (_stakingAndDaoSplit * 2) must equal RATE_DIVISOR"
        );
        uint256 oldVaultOwnerSplit = managementFeeVaultOwnerSplit;
        uint256 oldStakingAndDaoSplit = managementFeeStakingAndDaoSplit;
        managementFeeVaultOwnerSplit = _vaultOwnerSplit;
        managementFeeStakingAndDaoSplit = _stakingAndDaoSplit;
        emit ManagementFeeSplitUpdated(
            oldVaultOwnerSplit,
            oldStakingAndDaoSplit,
            _vaultOwnerSplit,
            _stakingAndDaoSplit
        );
    }

    /// @notice Sets the base and max percentage of the performance fee that is sent to the vault owner,
    /// staked FNDZ Token amount for the Tier Zero, increment and the split percentage increase amount per tier
    /// @param _vaultOwnerSplitBase The minimum percentage of the fee that the Vault Owner receives
    /// @param _vaultOwnerSplitMax The maximum percentage of the fee that the Vault Owner receives
    /// @param _tierZeroStakedAmount The amount of FNDZ Tokens the vault owner must stake to qualify for Tier Zero
    /// @param _amountStakedIncrement The amount of additional FNDZ Tokens the vault owner must stake to qualify for subsequent tiers
    /// @param _vaultOwnerSplitIncreasePerTier The percentage increment of the fee that the Vault Owner unlocks per tier
    function updatePerformanceFeeSplit(
        uint256 _vaultOwnerSplitBase,
        uint256 _vaultOwnerSplitMax,
        uint256 _tierZeroStakedAmount,
        uint256 _amountStakedIncrement,
        uint256 _vaultOwnerSplitIncreasePerTier
    ) external onlyOwner {
        require(
            _vaultOwnerSplitBase <= RATE_DIVISOR,
            "updatePerformanceFeeSplit: _vaultOwnerSplitBase should be less than or equal to RATE_DIVISOR"
        );
        require(
            _vaultOwnerSplitMax <= RATE_DIVISOR,
            "updatePerformanceFeeSplit: _vaultOwnerSplitMax should be less than or equal to RATE_DIVISOR"
        );
        require(
            _vaultOwnerSplitIncreasePerTier <= RATE_DIVISOR,
            "updatePerformanceFeeSplit: _vaultOwnerSplitIncreasePerTier should be less than or equal to RATE_DIVISOR"
        );

        emit PerformanceFeeSplitUpdated(
            performanceFeeVaultOwnerSplitBase,
            _vaultOwnerSplitBase,
            performanceFeeVaultOwnerSplitMax,
            _vaultOwnerSplitMax,
            performanceFeeTierZeroAmountStaked,
            _tierZeroStakedAmount,
            performanceFeeAmountStakedIncrement,
            _amountStakedIncrement,
            performanceFeeVaultOwnerSplitIncreasePerTier,
            _vaultOwnerSplitIncreasePerTier
        );

        performanceFeeVaultOwnerSplitBase = _vaultOwnerSplitBase;
        performanceFeeVaultOwnerSplitMax = _vaultOwnerSplitMax;
        performanceFeeTierZeroAmountStaked = _tierZeroStakedAmount;
        performanceFeeAmountStakedIncrement = _amountStakedIncrement;
        performanceFeeVaultOwnerSplitIncreasePerTier = _vaultOwnerSplitIncreasePerTier;
    }

    /// @notice Sets the time and slippage allowances permitted for swaps during inline fee share redemption
    /// @param _swapDeadlineIncrement The number of seconds before the inline swap fails
    /// @param _swapMinimumPercentageReceived The minimum percent of the nominal swap destination amount
    function updateInlineSwapAllowances(
        uint256 _swapDeadlineIncrement,
        uint256 _swapMinimumPercentageReceived
    ) external onlyOwner {
        require(
            _swapMinimumPercentageReceived <= RATE_DIVISOR,
            "_swapMinimumPercentageReceived is greater than RATE_DIVISOR"
        );

        uint256 oldDeadlineIncrement = inlineSwapDeadlineIncrement;
        uint256 oldMinimumPercentageReceived = inlineSwapMinimumPercentReceived;
        inlineSwapDeadlineIncrement = _swapDeadlineIncrement;
        inlineSwapMinimumPercentReceived = _swapMinimumPercentageReceived;
        emit InlineSwapAllowancesUpdated(
            oldDeadlineIncrement,
            oldMinimumPercentageReceived,
            _swapDeadlineIncrement,
            _swapMinimumPercentageReceived
        );
    }

    /// @notice Returns the Management Fee Split data
    function getManagementFeeData()
        external
        view
        override
        returns (
            address,
            address,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            fndzStakingPool,
            fndzDao,
            managementFeeVaultOwnerSplit,
            managementFeeStakingAndDaoSplit,
            RATE_DIVISOR
        );
    }

    /// @notice Returns performance fee split data
    function getPerformanceFeeData(address _vaultOwner)
        external
        view
        override
        returns (
            address,
            address,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 amountStakedByVaultOwner = IFNDZStaking(fndzStakingPool).getStakedAmount(
            _vaultOwner
        );
        uint256 vaultOwnerSplit = Math.max(
            Math.min(
                performanceFeeVaultOwnerSplitBase.add(
                    Math
                        .max(amountStakedByVaultOwner, performanceFeeTierZeroAmountStaked)
                        .sub(performanceFeeTierZeroAmountStaked)
                        .div(performanceFeeAmountStakedIncrement)
                        .mul(performanceFeeVaultOwnerSplitIncreasePerTier)
                ),
                performanceFeeVaultOwnerSplitMax
            ),
            performanceFeeVaultOwnerSplitBase
        );

        uint256 stakingAndDaoSplit = RATE_DIVISOR.sub(vaultOwnerSplit).div(2);
        return (fndzStakingPool, fndzDao, vaultOwnerSplit, stakingAndDaoSplit, RATE_DIVISOR);
    }

    /// @notice Returns the data required to perform inline swaps during inline fee share redemption
    function getFeeInlineSwapData()
        external
        view
        override
        returns (
            address,
            address,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            uniswapV2Factory,
            fndzDaoDesiredToken,
            inlineSwapDeadlineIncrement,
            inlineSwapMinimumPercentReceived,
            RATE_DIVISOR
        );
    }

    /// @notice Store the fee settings for a given fee smart contract
    /// @param _feeAddress The fee smart contract address
    /// @param _parameterMinValues The minimum acceptable values for the parameters,
    /// in the same order as encoded for the fee contract's addFundSettings method
    /// @param _parameterMaxValues The maximum acceptable values for the parameters,
    /// in the same order as encoded for the fee contract's addFundSettings method
    function setFeeConfiguration(
        address _feeAddress,
        uint256[] calldata _parameterMinValues,
        uint256[] calldata _parameterMaxValues
    ) external onlyOwner {
        FeeConfiguration storage feeConfig = feeConfigurations[_feeAddress];
        feeConfig.valid = true;
        require(
            _parameterMinValues.length == _parameterMaxValues.length,
            "setFeeConfiguration: _parameterMinValues and _parameterMaxValues lengths must be equal"
        );
        feeConfig.parameterMinValues = _parameterMinValues;
        feeConfig.parameterMaxValues = _parameterMaxValues;
        emit FeeConfigurationUpdated(_feeAddress);
    }

    /// @notice Removes a fee configuration that was previous set
    /// @param _feeAddress The fee smart contract address
    function removeFeeConfiguration(address _feeAddress) external onlyOwner {
        require(
            feeConfigurations[_feeAddress].valid,
            "removeFeeConfiguration: fee configuration is not set"
        );
        delete feeConfigurations[_feeAddress];
        emit FeeConfigurationRemoved(_feeAddress);
    }

    /// @notice Returns the configuration for the given fee smart contract address
    /// @param _feeAddress The fee smart contract address
    function getFeeConfiguration(address _feeAddress)
        external
        view
        returns (FeeConfiguration memory)
    {
        return feeConfigurations[_feeAddress];
    }

    /// @notice Gatekeeper function for FundDeployer to ensure that only acceptable vaults are created
    /// @param _fundOwner The address of the owner for the fund
    /// @param _fundName The name of the fund
    /// @param _denominationAsset The contract address of the denomination asset for the fund
    /// @param _sharesActionTimelock The minimum number of seconds between any two "shares actions"
    /// (buying or selling shares) by the same user
    /// @param _feeManagerConfigData Bytes data for the fees to be enabled for the fund
    /// @param _policyManagerConfigData Bytes data for the policies to be enabled for the fund
    function createNewFund(
        address _fundOwner,
        string calldata _fundName,
        address _denominationAsset,
        uint256 _sharesActionTimelock,
        bytes calldata _feeManagerConfigData,
        bytes calldata _policyManagerConfigData
    ) external returns (address comptrollerProxy_, address vaultProxy_) {
        require(fundDeployer != address(0), "createNewFund: Fund Deployer not set");
        require(
            approvedDenominationAssets[_denominationAsset],
            "createNewFund: denomination asset is not approved"
        );
        (address[] memory fees, bytes[] memory settingsData) = abi.decode(
            _feeManagerConfigData,
            (address[], bytes[])
        );
        for (uint256 i; i < fees.length; i++) {
            FeeConfiguration memory feeConfig = feeConfigurations[fees[i]];
            require(feeConfig.valid == true, "createNewFund: Unknown fee");
            bytes memory encodedUint = new bytes(32);
            for (uint256 j = 0; j < feeConfig.parameterMinValues.length; j++) {
                uint256 start = 32 * j;
                encodedUint = BytesLib.slice(settingsData[i], start, 32);
                uint256 parameterValue = abi.decode(encodedUint, (uint256));
                require(
                    parameterValue >= feeConfig.parameterMinValues[j] &&
                        parameterValue <= feeConfig.parameterMaxValues[j],
                    "createNewFund: fee parameter value is not within the acceptable range"
                );
            }
        }
        return
            IFundDeployer(fundDeployer).createNewFund(
                _fundOwner,
                _fundName,
                _denominationAsset,
                _sharesActionTimelock,
                _feeManagerConfigData,
                _policyManagerConfigData
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.5.0 <0.7.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes_slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes_slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes_slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes_slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes_slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes_slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_start + _length >= _start, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, "toAddress_overflow");
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_start + 1 >= _start, "toUint8_overflow");
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_start + 2 >= _start, "toUint16_overflow");
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_start + 4 >= _start, "toUint32_overflow");
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_start + 8 >= _start, "toUint64_overflow");
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_start + 12 >= _start, "toUint96_overflow");
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_start + 16 >= _start, "toUint128_overflow");
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_start + 32 >= _start, "toUint256_overflow");
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_start + 32 >= _start, "toBytes32_overflow");
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes_slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes_slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IFundDeployer Interface
/// @author Enzyme Council <[email protected]>
interface IFundDeployer {
    enum ReleaseStatus {PreLaunch, Live, Paused}

    function getOwner() external view returns (address);

    function getReleaseStatus() external view returns (ReleaseStatus);

    function isRegisteredVaultCall(address, bytes4) external view returns (bool);

    function createNewFund(
        address,
        string calldata,
        address,
        uint256,
        bytes calldata,
        bytes calldata
    ) external returns (address, address);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

interface IFNDZController {
    function getInlineSwapRouterAddress() external view returns (address);

    function getOwner() external view returns (address);

    function getParaSwapFee() external view returns (uint256);

    function fndzDao() external view returns (address);

    function fndzToken() external view returns (address);

    function getManagementFeeData()
        external
        view
        returns (
            address,
            address,
            uint256,
            uint256,
            uint256
        );

    function getPerformanceFeeData(address _vaultOwner)
        external
        view
        returns (
            address,
            address,
            uint256,
            uint256,
            uint256
        );

    function getFeeInlineSwapData()
        external
        view
        returns (
            address,
            address,
            uint256,
            uint256,
            uint256
        );
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

interface IFNDZStaking {
    function getStakedAmount(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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