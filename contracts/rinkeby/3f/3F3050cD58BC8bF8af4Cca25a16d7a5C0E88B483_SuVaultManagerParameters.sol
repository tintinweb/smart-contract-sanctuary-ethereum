/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.8.0;

import "./SuVaultParameters.sol";

/**
 * @title VaultManagerParameters
 **/
contract SuVaultManagerParameters is Auth {

    // determines the minimum percentage of COL token part in collateral, 0 decimals
    mapping(address => uint) public minColPercent;

    // determines the maximum percentage of COL token part in collateral, 0 decimals
    mapping(address => uint) public maxColPercent;

    // map token to initial collateralization ratio; 0 decimals
    mapping(address => uint) public initialCollateralRatio;

    // map token to liquidation ratio; 0 decimals
    mapping(address => uint) public liquidationRatio;

    // map token to liquidation discount; 3 decimals
    mapping(address => uint) public liquidationDiscount;

    // map token to devaluation period in blocks
    mapping(address => uint) public devaluationPeriod;

    constructor(address _vaultParameters) Auth(_vaultParameters) {}

    function setCollateral(
        address asset,
        uint stabilityFeeValue,
        uint liquidationFeeValue,
        uint initialCollateralRatioValue,
        uint liquidationRatioValue,
        uint liquidationDiscountValue,
        uint devaluationPeriodValue,
        uint usdpLimit
    ) external onlyManager {
        vaultParameters.setCollateral(asset, stabilityFeeValue, liquidationFeeValue, usdpLimit);
        setInitialCollateralRatio(asset, initialCollateralRatioValue);
        setLiquidationRatio(asset, liquidationRatioValue);
        setDevaluationPeriod(asset, devaluationPeriodValue);
        setLiquidationDiscount(asset, liquidationDiscountValue);
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Sets the initial collateral ratio
     * @param asset The address of the main collateral token
     * @param newValue The collateralization ratio (0 decimals)
     **/
    function setInitialCollateralRatio(address asset, uint newValue) public onlyManager {
        require(newValue != 0 && newValue <= 100, "Unit Protocol: INCORRECT_COLLATERALIZATION_VALUE");
        initialCollateralRatio[asset] = newValue;
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Sets the liquidation ratio
     * @param asset The address of the main collateral token
     * @param newValue The liquidation ratio (0 decimals)
     **/
    function setLiquidationRatio(address asset, uint newValue) public onlyManager {
        require(newValue != 0 && newValue >= initialCollateralRatio[asset], "Unit Protocol: INCORRECT_COLLATERALIZATION_VALUE");
        liquidationRatio[asset] = newValue;
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Sets the liquidation discount
     * @param asset The address of the main collateral token
     * @param newValue The liquidation discount (3 decimals)
     **/
    function setLiquidationDiscount(address asset, uint newValue) public onlyManager {
        require(newValue < 1e5, "Unit Protocol: INCORRECT_DISCOUNT_VALUE");
        liquidationDiscount[asset] = newValue;
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Sets the devaluation period of collateral after liquidation
     * @param asset The address of the main collateral token
     * @param newValue The devaluation period in blocks
     **/
    function setDevaluationPeriod(address asset, uint newValue) public onlyManager {
        require(newValue != 0, "Unit Protocol: INCORRECT_DEVALUATION_VALUE");
        devaluationPeriod[asset] = newValue;
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Sets the percentage range of the COL token part for specific collateral token
     * @param asset The address of the main collateral token
     * @param min The min percentage (0 decimals)
     * @param max The max percentage (0 decimals)
     **/
    function setColPartRange(address asset, uint min, uint max) public onlyManager {
        require(max <= 100 && min <= max, "Unit Protocol: WRONG_RANGE");
        minColPercent[asset] = min;
        maxColPercent[asset] = max;
    }
}

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.8.0;


// proxy for VaultParameters - other contracts should be inherited from here
// this contract contains modifiers used in VaultParameters contract
// it should be an abstract class because it cannot by instantiated/deployed directly,
// its supposed to be inherited by VaultParameters contract which is deployed 
/// yes
contract Auth {
    // but actually it does store address to vaultParameters contract?
    SuVaultParameters public vaultParameters;

    // its the same time parent of VaultParameters (inheritance)
    // and same time its linking to VaultParameters (composition)
    // one approach should be chosen: either inheritance or composition
    // otherwise its very confusing
    /// No, it's singleton
    constructor(address _parameters) {
        vaultParameters = SuVaultParameters(_parameters);
    }

    // check manager permission
    modifier onlyManager() {
        require(vaultParameters.isManager(msg.sender), "Unit Protocol: onlyManager AUTH_FAILED");
        _;
    }

    // check permission to modify vault
    modifier hasVaultAccess() {
        require(vaultParameters.canModifyVault(msg.sender), "Unit Protocol: hasVaultAccess AUTH_FAILED");
        _;
    }

    // check vault permission
    modifier onlyVault() {
        require(msg.sender == vaultParameters.vault(), "Unit Protocol: onlyVault AUTH_FAILED");
        _;
    }
}


// VaultParameters is Singleton for Access Control
// this looks like configuration contract
// what are the rules to determine these configs for each new allowed collateral?
/// yes, and for all collaterals
// is DAO allowed to choose parameters for existing collaterals?
/// 
// are there any limits to be enforced? i.e. fee cannot be over 100% percent
/// No, but it's a good idea to have it
contract SuVaultParameters is Auth {
    // stability fee can be different for each collateral
    /// yes
    mapping(address => uint) public stabilityFee;

    // liquidation fee too can be different
    /// yes
    mapping(address => uint) public liquidationFee;

    // map token to USDP mint limit
    /// yes, limit for each collateral-assert
    mapping(address => uint) public tokenDebtLimit;

    // permissions to modify the Vault
    mapping(address => bool) public canModifyVault;

    // whether an account is manager
    mapping(address => bool) public isManager;

    // whether an oracle is enabled
    /// TODO:
    mapping(uint => mapping (address => bool)) public isOracleTypeEnabled;

    // linked to the vault contract
    // I think its better to inherit Vault from VaultParameters
    /// NO, needed for onlyVault modifier
    address payable public vault;

    // what is foundation, DAO?
    /// Beneficiaty as VotingEscrow.vy
    address public foundation;

    // creator of contract is manager, can it be the same as DAO or can it be removed later?
    /// YES
    // how can vault address be known at this moment?
    /// Precult based on CREATE spec
    // can be created another function to set vault address once deployed?
    /// Yes, possibly with some logic change
    constructor(address payable _vault, address _foundation) Auth(address(this)) {
        require(_vault != address(0), "Unit Protocol: ZERO_ADDRESS");
        require(_foundation != address(0), "Unit Protocol: ZERO_ADDRESS");

        isManager[msg.sender] = true;
        vault = _vault;
        foundation = _foundation;
    }

     // existing managers can enable other managers
     // one manager can disable all other managers - dangerous?
     /// YES, could be dangerous
    function setManager(address who, bool permit) external onlyManager {
        isManager[who] = permit;
    }

    // similar function can be added to setVault
    function setFoundation(address newFoundation) external onlyManager {
        require(newFoundation != address(0), "Unit Protocol: ZERO_ADDRESS");
        foundation = newFoundation;
    }

     // manager is allowed to add new collaterals and modify existing ones
     // I think creating new collaterals and modifying existing ones should be separate functions
     /// Yes, for sercurity reason, it's possible to add events for creating and edititing 
     // also different event should be emitted NewCollateral UpdatedCollateral accordingly
     // those events can be handled on frontend to notify user about any changes in rules
     /// Not sure it makes sense to split into create/edit functions
    function setCollateral(
        address asset,
        uint stabilityFeeValue,
        uint liquidationFeeValue,
        uint usdpLimit
    ) external onlyManager {
        // stability fee should be validated in range, what is stability fee should be described here?
        setStabilityFee(asset, stabilityFeeValue);
        // liquidation fee should be validated in range, what is liquidation fee should be explained?
        setLiquidationFee(asset, liquidationFeeValue);
        // why debt limit for collateral is necessary? to manage risks in case of collateral failure?
        setTokenDebtLimit(asset, usdpLimit);
    }

     // manager can choose who is allowed to modify vault, 
     // what does it mean to modify vault and why permission separate from manager himself?
     /// https://en.wikipedia.org/wiki/Principle_of_least_privilege 
    function setVaultAccess(address who, bool permit) external onlyManager {
        canModifyVault[who] = permit;
    }

    // stability fee is measured as the number of coins per year or percentage? 
    // this should be clarified in argument name i.e. stabilityFeePercentageYearly
    /// No, it's APR ( per year, see calculateFee) percentrage, fee percentage; 3 decimals.
    /// YES, self-documented code-style is the best practice.
    function setStabilityFee(address asset, uint newValue) public onlyManager {
        stabilityFee[asset] = newValue;
    }

    // the same with liquidation fee is not clear
    /// % 0 decimals, needede to get better variable names
    function setLiquidationFee(address asset, uint newValue) public onlyManager {
        require(newValue <= 100, "Unit Protocol: VALUE_OUT_OF_RANGE");
        liquidationFee[asset] = newValue;
    }

     // what are allowed types? enum should be defined
     // types out of range should fail transaction
    /// All oracles implementation are numbered, so some of them support this particular asset
    function setOracleType(uint _type, address asset, bool enabled) public onlyManager {
        isOracleTypeEnabled[_type][asset] = enabled;
    }

     // debt limit can be changed for any collateral along with liquidation and stability fees
     // seems like managers have too much power - that can be dangerous given multiple managers?
     /// Yes, application of  principle of least priviledge needed
    function setTokenDebtLimit(address asset, uint limit) public onlyManager {
        tokenDebtLimit[asset] = limit;
    }
}