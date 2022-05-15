// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2022 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;

import "../interfaces/swappers/ISwapper.sol";
import "../interfaces/swappers/ISwappersRegistry.sol";
import "../Auth2.sol";


contract SwappersRegistry is ISwappersRegistry, Auth2 {

    struct SwapperInfo {
        uint240 id;
        bool exists;
    }

    mapping(ISwapper => SwapperInfo) internal swappersInfo;
    ISwapper[] internal swappers;

    constructor(address _vaultParameters) Auth2(_vaultParameters) {}

    function getSwappersLength() external view override returns (uint) {
        return swappers.length;
    }

    function getSwapperId(ISwapper _swapper) external view override returns (uint) {
        require(hasSwapper(_swapper), "Unit Protocol Swappers: SWAPPER_IS_NOT_EXIST");

        return uint(swappersInfo[_swapper].id);
    }

    function getSwapper(uint _id) external view override returns (ISwapper) {
        return swappers[_id];
    }

    function hasSwapper(ISwapper _swapper) public view override returns (bool) {
        return swappersInfo[_swapper].exists;
    }

    function getSwappers() external view override returns (ISwapper[] memory) {
        return swappers;
    }

    function add(ISwapper _swapper) public onlyManager {
        require(address(_swapper) != address(0), "Unit Protocol Swappers: ZERO_ADDRESS");
        require(!hasSwapper(_swapper), "Unit Protocol Swappers: SWAPPER_ALREADY_EXISTS");

        swappers.push(_swapper);
        swappersInfo[_swapper] = SwapperInfo(uint240(swappers.length - 1), true);

        emit SwapperAdded(_swapper);
    }

    function remove(ISwapper _swapper) public onlyManager {
        require(address(_swapper) != address(0), "Unit Protocol Swappers: ZERO_ADDRESS");
        require(hasSwapper(_swapper), "Unit Protocol Swappers: SWAPPER_IS_NOT_EXIST");

        uint id = uint(swappersInfo[_swapper].id);
        delete swappersInfo[_swapper];

        uint lastId = swappers.length - 1;
        if (id != lastId) {
            ISwapper lastSwapper = swappers[lastId];
            swappers[id] = lastSwapper;
            swappersInfo[lastSwapper] = SwapperInfo(uint240(id), true);
        }
        swappers.pop();

        emit SwapperRemoved(_swapper);
    }
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2022 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;


interface ISwapper {

    /**
     * @notice Predict asset amount after usdp swap
     */
    function predictAssetOut(address _asset, uint256 _usdpAmountIn) external view returns (uint predictedAssetAmount);

    /**
     * @notice Predict USDP amount after asset swap
     */
    function predictUsdpOut(address _asset, uint256 _assetAmountIn) external view returns (uint predictedUsdpAmount);

    /**
     * @notice usdp must be approved to swapper
     * @dev asset must be sent to user after swap
     */
    function swapUsdpToAsset(address _user, address _asset, uint256 _usdpAmount, uint256 _minAssetAmount) external returns (uint swappedAssetAmount);

    /**
     * @notice asset must be approved to swapper
     * @dev usdp must be sent to user after swap
     */
    function swapAssetToUsdp(address _user, address _asset, uint256 _assetAmount, uint256 _minUsdpAmount) external returns (uint swappedUsdpAmount);

    /**
     * @notice DO NOT SEND tokens to contract manually. For usage in contracts only.
     * @dev for gas saving with usage in contracts tokens must be send directly to contract instead
     * @dev asset must be sent to user after swap
     */
    function swapUsdpToAssetWithDirectSending(address _user, address _asset, uint256 _usdpAmount, uint256 _minAssetAmount) external returns (uint swappedAssetAmount);

    /**
     * @notice DO NOT SEND tokens to contract manually. For usage in contracts only.
     * @dev for gas saving with usage in contracts tokens must be send directly to contract instead
     * @dev usdp must be sent to user after swap
     */
    function swapAssetToUsdpWithDirectSending(address _user, address _asset, uint256 _assetAmount, uint256 _minUsdpAmount) external returns (uint swappedUsdpAmount);
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2022 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;

import "./ISwapper.sol";


interface ISwappersRegistry {
    event SwapperAdded(ISwapper swapper);
    event SwapperRemoved(ISwapper swapper);

    function getSwapperId(ISwapper _swapper) external view returns (uint);
    function getSwapper(uint _id) external view returns (ISwapper);
    function hasSwapper(ISwapper _swapper) external view returns (bool);

    function getSwappersLength() external view returns (uint);
    function getSwappers() external view returns (ISwapper[] memory);
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2021 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;

import "./VaultParameters.sol";


/**
 * @title Auth2
 * @dev Manages USDP's system access
 * @dev copy of Auth from VaultParameters.sol but with immutable vaultParameters for saving gas
 **/
contract Auth2 {

    // address of the the contract with vault parameters
    VaultParameters public immutable vaultParameters;

    constructor(address _parameters) {
        require(_parameters != address(0), "Unit Protocol: ZERO_ADDRESS");

        vaultParameters = VaultParameters(_parameters);
    }

    // ensures tx's sender is a manager
    modifier onlyManager() {
        require(vaultParameters.isManager(msg.sender), "Unit Protocol: AUTH_FAILED");
        _;
    }

    // ensures tx's sender is able to modify the Vault
    modifier hasVaultAccess() {
        require(vaultParameters.canModifyVault(msg.sender), "Unit Protocol: AUTH_FAILED");
        _;
    }

    // ensures tx's sender is the Vault
    modifier onlyVault() {
        require(msg.sender == vaultParameters.vault(), "Unit Protocol: AUTH_FAILED");
        _;
    }
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;



/**
 * @title Auth
 * @dev Manages USDP's system access
 **/
contract Auth {

    // address of the the contract with vault parameters
    VaultParameters public vaultParameters;

    constructor(address _parameters) {
        vaultParameters = VaultParameters(_parameters);
    }

    // ensures tx's sender is a manager
    modifier onlyManager() {
        require(vaultParameters.isManager(msg.sender), "Unit Protocol: AUTH_FAILED");
        _;
    }

    // ensures tx's sender is able to modify the Vault
    modifier hasVaultAccess() {
        require(vaultParameters.canModifyVault(msg.sender), "Unit Protocol: AUTH_FAILED");
        _;
    }

    // ensures tx's sender is the Vault
    modifier onlyVault() {
        require(msg.sender == vaultParameters.vault(), "Unit Protocol: AUTH_FAILED");
        _;
    }
}



/**
 * @title VaultParameters
 **/
contract VaultParameters is Auth {

    // map token to stability fee percentage; 3 decimals
    mapping(address => uint) public stabilityFee;

    // map token to liquidation fee percentage, 0 decimals
    mapping(address => uint) public liquidationFee;

    // map token to USDP mint limit
    mapping(address => uint) public tokenDebtLimit;

    // permissions to modify the Vault
    mapping(address => bool) public canModifyVault;

    // managers
    mapping(address => bool) public isManager;

    // enabled oracle types
    mapping(uint => mapping (address => bool)) public isOracleTypeEnabled;

    // address of the Vault
    address payable public vault;

    // The foundation address
    address public foundation;

    /**
     * The address for an Ethereum contract is deterministically computed from the address of its creator (sender)
     * and how many transactions the creator has sent (nonce). The sender and nonce are RLP encoded and then
     * hashed with Keccak-256.
     * Therefore, the Vault address can be pre-computed and passed as an argument before deployment.
    **/
    constructor(address payable _vault, address _foundation) Auth(address(this)) {
        require(_vault != address(0), "Unit Protocol: ZERO_ADDRESS");
        require(_foundation != address(0), "Unit Protocol: ZERO_ADDRESS");

        isManager[msg.sender] = true;
        vault = _vault;
        foundation = _foundation;
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Grants and revokes manager's status of any address
     * @param who The target address
     * @param permit The permission flag
     **/
    function setManager(address who, bool permit) external onlyManager {
        isManager[who] = permit;
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Sets the foundation address
     * @param newFoundation The new foundation address
     **/
    function setFoundation(address newFoundation) external onlyManager {
        require(newFoundation != address(0), "Unit Protocol: ZERO_ADDRESS");
        foundation = newFoundation;
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Sets ability to use token as the main collateral
     * @param asset The address of the main collateral token
     * @param stabilityFeeValue The percentage of the year stability fee (3 decimals)
     * @param liquidationFeeValue The liquidation fee percentage (0 decimals)
     * @param usdpLimit The USDP token issue limit
     * @param oracles The enables oracle types
     **/
    function setCollateral(
        address asset,
        uint stabilityFeeValue,
        uint liquidationFeeValue,
        uint usdpLimit,
        uint[] calldata oracles
    ) external onlyManager {
        setStabilityFee(asset, stabilityFeeValue);
        setLiquidationFee(asset, liquidationFeeValue);
        setTokenDebtLimit(asset, usdpLimit);
        for (uint i=0; i < oracles.length; i++) {
            setOracleType(oracles[i], asset, true);
        }
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Sets a permission for an address to modify the Vault
     * @param who The target address
     * @param permit The permission flag
     **/
    function setVaultAccess(address who, bool permit) external onlyManager {
        canModifyVault[who] = permit;
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Sets the percentage of the year stability fee for a particular collateral
     * @param asset The address of the main collateral token
     * @param newValue The stability fee percentage (3 decimals)
     **/
    function setStabilityFee(address asset, uint newValue) public onlyManager {
        stabilityFee[asset] = newValue;
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Sets the percentage of the liquidation fee for a particular collateral
     * @param asset The address of the main collateral token
     * @param newValue The liquidation fee percentage (0 decimals)
     **/
    function setLiquidationFee(address asset, uint newValue) public onlyManager {
        require(newValue <= 100, "Unit Protocol: VALUE_OUT_OF_RANGE");
        liquidationFee[asset] = newValue;
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Enables/disables oracle types
     * @param _type The type of the oracle
     * @param asset The address of the main collateral token
     * @param enabled The control flag
     **/
    function setOracleType(uint _type, address asset, bool enabled) public onlyManager {
        isOracleTypeEnabled[_type][asset] = enabled;
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Sets USDP limit for a specific collateral
     * @param asset The address of the main collateral token
     * @param limit The limit number
     **/
    function setTokenDebtLimit(address asset, uint limit) public onlyManager {
        tokenDebtLimit[asset] = limit;
    }
}