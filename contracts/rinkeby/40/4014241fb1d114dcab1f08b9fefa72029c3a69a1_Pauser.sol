//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {AccessControlEnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import {IPausableByPauser} from "../interfaces/IPausableByPauser.sol";
import {IPauser} from "../interfaces/IPauser.sol";
import {IVault} from "../interfaces/IVault.sol";
import {IVaultConfig} from "../interfaces/IVaultConfig.sol";
import {IRhoStrategy} from "../interfaces/IRhoStrategy.sol";
import {IRhoToken} from "../interfaces/IRhoToken.sol";

/**
 * @title Pauser Contract
 * @notice Pauses and unpauses all vaults, vault configs, strategies and rewards
 * in case of emergency.
 */
contract Pauser is IPauser, AccessControlEnumerableUpgradeable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    mapping(address => bool) public isRegistered;

    // vaults
    address[] public vaults;
    // vault configs
    address[] public vaultConfigs;
    // strategies
    address[] public strategies;
    // rewards
    address[] public rewards;
    // deposit unwinder
    address[] public depositUnwinders;
    struct ContractGroup {
        address vault;
        address vaultConfig;
        address rhoToken;
        address[] strategies;
    }

    mapping(address => ContractGroup) public groupByUnderlying;
    mapping(address => mapping(address => bool)) public isRegisteredToGroup;

    address[] public underlyings;

    function initialize() external initializer {
        AccessControlEnumerableUpgradeable.__AccessControlEnumerable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function pauseAll() external override onlyRole(PAUSER_ROLE) {
        for (uint256 i; i < underlyings.length; i++) {
            _pauseGroup(underlyings[i]);
        }

        _pauseRewards();
        _pauseDepositUnwinders();

        emit PausedAll(_msgSender());
    }

    function unpauseAll() external override onlyRole(PAUSER_ROLE) {
        for (uint256 i; i < underlyings.length; i++) {
            _unpauseGroup(underlyings[i]);
        }

        _unpauseRewards();
        _unpauseDepositUnwinders();

        emit UnpausedAll(_msgSender());
    }

    function pauseGroup(address underlying) external override notZeroAddress(underlying) onlyRole(PAUSER_ROLE) {
        _pauseGroup(underlying);
    }

    function _pauseGroup(address underlying) internal {
        // pause contracts group by underlying contract
        if (groupByUnderlying[underlying].vault != address(0))
            try IPausableByPauser(groupByUnderlying[underlying].vault).pause() {} catch {}

        if (groupByUnderlying[underlying].vaultConfig != address(0))
            try IPausableByPauser(groupByUnderlying[underlying].vaultConfig).pause() {} catch {}

        if (groupByUnderlying[underlying].rhoToken != address(0))
            try IPausableByPauser(groupByUnderlying[underlying].rhoToken).pause() {} catch {}

        for (uint256 i; i < groupByUnderlying[underlying].strategies.length; i++)
            try IPausableByPauser(groupByUnderlying[underlying].strategies[i]).pause() {} catch {
                continue;
            }

        emit PausedGroup(_msgSender(), underlying);
    }

    function unpauseGroup(address underlying) external override notZeroAddress(underlying) onlyRole(PAUSER_ROLE) {
        _unpauseGroup(underlying);
    }

    function _unpauseGroup(address underlying) internal {
        // pause contracts group by underlying contract
        if (groupByUnderlying[underlying].vault != address(0))
            try IPausableByPauser(groupByUnderlying[underlying].vault).unpause() {} catch {}

        if (groupByUnderlying[underlying].vaultConfig != address(0))
            try IPausableByPauser(groupByUnderlying[underlying].vaultConfig).unpause() {} catch {}

        if (groupByUnderlying[underlying].rhoToken != address(0))
            try IPausableByPauser(groupByUnderlying[underlying].rhoToken).unpause() {} catch {}

        for (uint256 i; i < groupByUnderlying[underlying].strategies.length; i++)
            try IPausableByPauser(groupByUnderlying[underlying].strategies[i]).unpause() {} catch {
                continue;
            }

        emit UnpausedGroup(_msgSender(), underlying);
    }

    function _pauseRewards() internal {
        for (uint256 i; i < rewards.length; i++)
            try IPausableByPauser(rewards[i]).pause() {} catch {
                continue;
            }

        emit PausedRewards(_msgSender());
    }

    function pauseRewards() public override onlyRole(PAUSER_ROLE) {
        _pauseRewards();
    }

    function _unpauseRewards() internal {
        for (uint256 i; i < rewards.length; i++)
            try IPausableByPauser(rewards[i]).unpause() {} catch {
                continue;
            }

        emit UnpausedRewards(_msgSender());
    }

    function unpauseRewards() public override onlyRole(PAUSER_ROLE) {
        _unpauseRewards();
    }

    function _pauseDepositUnwinders() internal {
        for (uint256 i; i < depositUnwinders.length; i++)
            try IPausableByPauser(depositUnwinders[i]).pause() {} catch {
                continue;
            }

        emit PausedDepositUnwinders(_msgSender());
    }

    function pauseDepositUnwinders() public override onlyRole(PAUSER_ROLE) {
        _pauseDepositUnwinders();
    }

    function _unpauseDepositUnwinders() internal {
        for (uint256 i; i < depositUnwinders.length; i++)
            try IPausableByPauser(depositUnwinders[i]).unpause() {} catch {
                continue;
            }

        emit UnpausedDepositUnwinders(_msgSender());
    }

    function unpauseDepositUnwinders() public override onlyRole(PAUSER_ROLE) {
        _unpauseDepositUnwinders();
    }

    function pauseRhoToken(address underlying) public override onlyRole(PAUSER_ROLE) {
        require(groupByUnderlying[underlying].rhoToken != address(0), "rhoToken is not registered");
        IPausableByPauser(groupByUnderlying[underlying].rhoToken).pause();
        emit PausedRhoToken(_msgSender(), groupByUnderlying[underlying].rhoToken);
    }

    function unpauseRhoToken(address underlying) public override onlyRole(PAUSER_ROLE) {
        require(groupByUnderlying[underlying].rhoToken != address(0), "rhoToken is not registered");
        IPausableByPauser(groupByUnderlying[underlying].rhoToken).unpause();
        emit UnpausedRhoToken(_msgSender(), groupByUnderlying[underlying].rhoToken);
    }

    function getVaults() external view override returns (address[] memory) {
        return vaults;
    }

    function getVaultConfigs() external view override returns (address[] memory) {
        return vaultConfigs;
    }

    function getStrategies() external view override returns (address[] memory) {
        return strategies;
    }

    function getRewards() external view override returns (address[] memory) {
        return rewards;
    }

    function getUnderlyings() external view override returns (address[] memory) {
        return underlyings;
    }

    function addVault(address addr) external override onlyRole(DEFAULT_ADMIN_ROLE) notZeroAddress(addr) {
        address underlying = address(IVault(addr).underlying());
        require(underlying != address(0), "underlying address is 0");
        require(groupByUnderlying[underlying].vault == address(0), "A Vault is already registered");
        groupByUnderlying[underlying].vault = addr;
        isRegisteredToGroup[underlying][addr] = true;

        if (isRegistered[addr]) return;
        vaults.push(addr);
        isRegistered[addr] = true;
    }

    function addVaultConfig(address addr) external override onlyRole(DEFAULT_ADMIN_ROLE) notZeroAddress(addr) {
        address underlying = IVaultConfig(addr).underlying();
        require(underlying != address(0), "underlying address is 0");
        require(groupByUnderlying[underlying].vaultConfig == address(0), "A VaultConfig is already registered");
        groupByUnderlying[underlying].vaultConfig = addr;
        isRegisteredToGroup[underlying][addr] = true;

        if (isRegistered[addr]) return;
        vaultConfigs.push(addr);
        isRegistered[addr] = true;
    }

    function addStrategy(address addr) external override onlyRole(DEFAULT_ADMIN_ROLE) notZeroAddress(addr) {
        address underlying = address(IRhoStrategy(addr).underlying());
        require(underlying != address(0), "underlying address is 0");
        if (isRegisteredToGroup[underlying][addr]) return;
        groupByUnderlying[underlying].strategies.push(addr);
        isRegisteredToGroup[underlying][addr] = true;

        if (isRegistered[addr]) return;
        strategies.push(addr);
        isRegistered[addr] = true;
    }

    function addRewards(address addr) external override onlyRole(DEFAULT_ADMIN_ROLE) notZeroAddress(addr) {
        if (isRegistered[addr]) return;
        rewards.push(addr);
        isRegistered[addr] = true;
    }

    function addRhoToken(address addr) external override onlyRole(DEFAULT_ADMIN_ROLE) notZeroAddress(addr) {
        address underlying = address(IRhoToken(addr).underlying());
        require(underlying != address(0), "underlying address is 0");
        require(groupByUnderlying[underlying].rhoToken == address(0), "A RhoToken is already registered");
        groupByUnderlying[underlying].rhoToken = addr;
        isRegisteredToGroup[underlying][addr] = true;

        if (isRegistered[addr]) return;
        isRegistered[addr] = true;
    }

    function removeVault(address addr) external override onlyRole(DEFAULT_ADMIN_ROLE) notZeroAddress(addr) {
        address underlying = address(IVault(addr).underlying());
        require(underlying != address(0), "underlying address is 0");
        require(addr == groupByUnderlying[underlying].vault, "vault was not registered");
        groupByUnderlying[underlying].vault = address(0);
        isRegisteredToGroup[underlying][addr] = false;

        if (!isRegistered[addr]) return;
        for (uint256 i; i < vaults.length; i++) {
            if (addr == vaults[i]) {
                vaults[i] = vaults[vaults.length - 1];
                vaults.pop();
                isRegistered[addr] = false;
                return;
            }
        }
    }

    function removeVaultConfig(address addr) external override onlyRole(DEFAULT_ADMIN_ROLE) notZeroAddress(addr) {
        address underlying = IVaultConfig(addr).underlying();
        require(underlying != address(0), "underlying address is 0");
        require(addr == groupByUnderlying[underlying].vaultConfig, "vaultConfig was not registered");
        groupByUnderlying[underlying].vaultConfig = address(0);
        isRegisteredToGroup[underlying][addr] = false;

        if (!isRegistered[addr]) return;
        for (uint256 i; i < vaultConfigs.length; i++) {
            if (addr == vaultConfigs[i]) {
                vaultConfigs[i] = vaultConfigs[vaultConfigs.length - 1];
                vaultConfigs.pop();
                isRegistered[addr] = false;
                return;
            }
        }
    }

    function removeStrategy(address addr) external override onlyRole(DEFAULT_ADMIN_ROLE) notZeroAddress(addr) {
        address underlying = address(IRhoStrategy(addr).underlying());
        require(underlying != address(0), "underlying address is 0");
        address[] storage s = groupByUnderlying[underlying].strategies;
        for (uint256 i; i < s.length; i++) {
            if (addr == s[i]) {
                s[i] = s[s.length - 1];
                s.pop();
                isRegisteredToGroup[underlying][addr] = false;
            }
        }

        if (!isRegistered[addr]) return;
        for (uint256 i; i < strategies.length; i++) {
            if (addr == strategies[i]) {
                strategies[i] = strategies[strategies.length - 1];
                strategies.pop();
                isRegistered[addr] = false;
                return;
            }
        }
    }

    function removeReward(address addr) external override onlyRole(DEFAULT_ADMIN_ROLE) notZeroAddress(addr) {
        if (!isRegistered[addr]) return;
        for (uint256 i; i < rewards.length; i++) {
            if (addr == rewards[i]) {
                rewards[i] = rewards[rewards.length - 1];
                rewards.pop();
                isRegistered[addr] = false;
                return;
            }
        }
    }

    function removeRhoToken(address addr) external override onlyRole(DEFAULT_ADMIN_ROLE) notZeroAddress(addr) {
        address underlying = address(IRhoToken(addr).underlying());
        require(underlying != address(0), "underlying address is 0");
        require(addr == groupByUnderlying[underlying].rhoToken, "rhoToken was not registered");
        groupByUnderlying[underlying].rhoToken = address(0);
        isRegisteredToGroup[underlying][addr] = false;

        if (!isRegistered[addr]) return;
        isRegistered[addr] = false;
    }

    function getDepositUnwinders() external view override returns (address[] memory) {
        return depositUnwinders;
    }

    function addDepositUnwinder(address addr) external override onlyRole(DEFAULT_ADMIN_ROLE) notZeroAddress(addr) {
        if (isRegistered[addr]) return;
        depositUnwinders.push(addr);
        isRegistered[addr] = true;
    }

    function removeDepositUnwinder(address addr) external override onlyRole(DEFAULT_ADMIN_ROLE) notZeroAddress(addr) {
        if (!isRegistered[addr]) return;
        for (uint256 i; i < depositUnwinders.length; i++) {
            if (addr == depositUnwinders[i]) {
                depositUnwinders[i] = depositUnwinders[depositUnwinders.length - 1];
                depositUnwinders.pop();
                isRegistered[addr] = false;
                return;
            }
        }
    }

    function addUnderlying(address addr) external override onlyRole(DEFAULT_ADMIN_ROLE) notZeroAddress(addr) {
        if (isRegistered[addr]) return;
        underlyings.push(addr);
        isRegistered[addr] = true;
    }

    function removeUnderlying(address addr) external override onlyRole(DEFAULT_ADMIN_ROLE) notZeroAddress(addr) {
        if (!isRegistered[addr]) return;
        for (uint256 i; i < underlyings.length; i++) {
            if (addr == underlyings[i]) {
                underlyings[i] = underlyings[underlyings.length - 1];
                underlyings.pop();
                isRegistered[addr] = false;
                return;
            }
        }
    }

    modifier notZeroAddress(address addr) {
        require(addr != address(0), "contract address is 0");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlEnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
    }

    function __AccessControlEnumerable_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override(AccessControlUpgradeable, IAccessControlUpgradeable) {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override(AccessControlUpgradeable, IAccessControlUpgradeable) {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override(AccessControlUpgradeable, IAccessControlUpgradeable) {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IPausableByPauser {
    /**
     * @notice pause the contract
     * Note: only callable by PAUSER_ROLE
     */
    function pause() external;

    /**
     * @notice unpause the contract
     * Note: only callable by PAUSER_ROLE
     */
    function unpause() external;

    /**
     * @notice returns the paused state
     */
    function paused() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @title Pauser Interface
 * @notice Pauses and unpauses all vaults, vault configs, strategies and rewards
 * in case of emergency.
 * Note: Owner is a multi-sig wallet.
 */
interface IPauser {
    /**
     * @dev Emitted when the pause is triggered by sender.
     */
    event PausedAll(address sender);

    /**
     * @dev Emitted when the pause is lifted by sender.
     */
    event UnpausedAll(address sender);

    /**
     * @dev Emitted when the pause is triggered by sender.
     */
    event PausedGroup(address sender, address underlying);

    /**
     * @dev Emitted when the pause is lifted by sender.
     */
    event UnpausedGroup(address sender, address underlying);

    /**
     * @dev Emitted when the pause is triggered by sender.
     */
    event PausedRewards(address sender);

    /**
     * @dev Emitted when the pause is lifted by sender.
     */
    event UnpausedRewards(address sender);

    /**
     * @dev Emitted when the pause is triggered by sender.
     */
    event PausedDepositUnwinders(address sender);

    /**
     * @dev Emitted when the pause is lifted by sender.
     */
    event UnpausedDepositUnwinders(address sender);

    /**
     * @dev Emitted when the pause is triggered by sender.
     */
    event PausedRhoToken(address sender, address rhoToken);

    /**
     * @dev Emitted when the pause is lifted by sender.
     */
    event UnpausedRhoToken(address sender, address rhoToken);

    function pauseAll() external;

    function unpauseAll() external;

    function pauseGroup(address underlying) external;

    function unpauseGroup(address underlying) external;

    function pauseRewards() external;

    function unpauseRewards() external;

    function pauseDepositUnwinders() external;

    function unpauseDepositUnwinders() external;

    function pauseRhoToken(address underlying) external;

    function unpauseRhoToken(address underlying) external;

    function getVaults() external view returns (address[] memory);

    function getVaultConfigs() external view returns (address[] memory);

    function getStrategies() external view returns (address[] memory);

    function getRewards() external view returns (address[] memory);

    function getUnderlyings() external view returns (address[] memory);

    function addVault(address addr) external;

    function addVaultConfig(address addr) external;

    function addStrategy(address addr) external;

    function addRewards(address addr) external;

    function addRhoToken(address addr) external;

    function removeVault(address addr) external;

    function removeVaultConfig(address addr) external;

    function removeStrategy(address addr) external;

    function removeReward(address addr) external;

    function removeRhoToken(address addr) external;

    function getDepositUnwinders() external view returns (address[] memory);

    function addDepositUnwinder(address addr) external;

    function removeDepositUnwinder(address addr) external;

    function addUnderlying(address addr) external;

    function removeUnderlying(address addr) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "./IRhoToken.sol";
import "./IVaultConfig.sol";

interface IVault {
    event ReserveChanged(uint256 reserveBalance);
    event RepurchasedFlurry(uint256 rhoTokenIn, uint256 flurryOut);
    event RepurchaseFlurryFailed(uint256 rhoTokenIn);
    event CollectRewardError(address indexed _from, address indexed _strategy, string _reason);
    event CollectRewardUnknownError(address indexed _from, address indexed _strategy);
    event VaultRatesChanged(uint256 supplyRate, uint256 indicativeSupplyRate);
    event NegativeRebase(uint256 oldMultiplier, uint256 newMultiplier);
    event Log(string message);

    /**
     * @return IERC20MetadataUpgradeable underlying
     */
    function underlying() external view returns (IERC20MetadataUpgradeable);

    /**
     * @return IRhoToken contract
     */
    function rhoToken() external view returns (IRhoToken);

    /**
     * @return accumulated rhoToken management fee in vault
     */
    function feesInRho() external view returns (uint256);

    /**
     * @dev getter function for cash reserve
     * @return return cash reserve balance (in underlying) for vault
     */
    function reserve() external view returns (uint256);

    /**
     * @return True if the asset is supported by this vault
     */
    function supportsAsset(address _asset) external view returns (bool);

    /**
     * @dev function that trigggers the distribution of interest earned to Rho token holders
     */
    function rebase() external;

    /**
     * @dev admin function that triggers the distribution of interest earned to Rho token holders
     * @param revertOnNegativeRebase option to revert when negative rebase occur
     */
    function rebaseWithOptions(bool revertOnNegativeRebase) external;

    /**
     * @dev function that trigggers allocation and unallocation of funds based on reserve pool bounds
     */
    function rebalance() external;

    /**
     * @dev function to mint RhoToken
     * @param amount amount in underlying stablecoin
     */
    function mint(uint256 amount) external;

    /**
     * @dev function to redeem RhoToken
     * @param amount amount of rhoTokens to be redeemed
     */
    function redeem(uint256 amount) external;

    /**
     * admin functions to withdraw random token transfer to this contract
     */
    function sweepERC20Token(address token, address to) external;

    function sweepRhoTokenContractERC20Token(address token, address to) external;

    /**
     * @dev function to check strategies shoud collect reward
     * @return List of boolean
     */
    function checkStrategiesCollectReward() external view returns (bool[] memory);

    /**
     * @return supply rate (pa) for Vault
     */
    function supplyRate() external view returns (uint256);

    /**
     * @dev function to collect strategies reward token
     * @param collectList strategies to be collect
     */
    function collectStrategiesRewardTokenByIndex(uint16[] memory collectList) external returns (bool[] memory);

    /**
     * admin functions to withdraw fees
     */
    function withdrawFees(uint256 amount, address to) external;

    /**
     * @return true if feeInRho >= repurchaseFlurryThreshold, false otherwise
     */
    function shouldRepurchaseFlurry() external view returns (bool);

    /**
     * @dev Calculates the amount of rhoToken used to repurchase FLURRY.
     * The selling is delegated to Token Exchange. FLURRY obtained
     * is directly sent to Flurry Staking Rewards.
     */
    function repurchaseFlurry() external;

    /**
     * @return reference to IVaultConfig contract
     */
    function config() external view returns (IVaultConfig);

    /**
     * @return list of strategy addresses
     */
    function getStrategiesList() external view returns (IVaultConfig.Strategy[] memory);

    /**
     * @return no. of strategies registered
     */
    function getStrategiesListLength() external view returns (uint256);

    /**
     * @dev retire rhoStrategy from the Vault
     * this is used by test suite only
     * @param strategy address of IRhoStrategy
     * should call shouldCollectReward instead
     */
    function retireStrategy(address strategy) external;

    /**
     * @dev indicative supply rate
     * signifies the supply rate after next rebase
     */
    function indicativeSupplyRate() external view returns (uint256);

    /**
     * @dev function to mint RhoToken using a deposit token
     * @param amount amount in deposit tokens
     * @param depositToken address of deposit token
     */
    function mintWithDepositToken(uint256 amount, address depositToken) external;

    /**
     * @return list of deposit tokens addresses
     */
    function getDepositTokens() external view returns (address[] memory);

    /**
     * @param token deposit token address
     * @return deposit unwinder (name and address)
     */
    function getDepositUnwinder(address token) external view returns (IVaultConfig.DepositUnwinder memory);

    /**
     * @dev retire deposit unwinder support for a deposit token
     * this is used by test suite only
     * @param token address of dpeosit token
     */
    function retireDepositUnwinder(address token) external;

    /**
     * @dev recall from rhoStrategies all funds to the vault
     * this is used to recall all funds from Rho Strategies back to vault
     * in case there is an attack on our rhoStrategies
     */
    function withdrawFromAllStrategies() external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IRhoStrategy.sol";
import "./IDepositUnwinder.sol";

interface IVaultConfig {
    event Log(string message);
    event StrategyAdded(string name, address addr);
    event StrategyRemoved(string name, address addr);
    event StrategyRatesChanged(address indexed strategy, uint256 effRate, uint256 supplyRate, uint256 bonusRate);
    event DepositUnwinderAdded(address token, address addr);
    event DepositUnwinderRemoved(address token, address addr);
    event UnderlyingNativePriceOracleSet(address addr);
    event MintingFeeSet(uint256 fee);
    event RedeemFeeSet(uint256 fee);
    event ManagementFeeSet(uint256 fee);
    event RewardCollectThresholdSet(uint256 threshold);
    event ReserveBoundarySet(uint256 lowerBound, uint256 upperBound);
    event FlurryTokenSet(address token);
    event FlurryStakingRewardsSet(address addr);
    event TokenExchangeSet(address addr);
    event RepurchaseFlurryRatioSet(uint256 ratio);
    event RepurchaseFlurryThresholdSet(uint256 threshold);
    event RhoTokenSet(address token);

    struct Strategy {
        string name;
        IRhoStrategy target;
    }

    struct DepositUnwinder {
        string tokenName;
        IDepositUnwinder target;
    }

    /**
     * @return FLURRY token address
     */
    function flurryToken() external view returns (address);

    /**
     * @return Returns the address of the Rho token contract
     */
    function rhoToken() external view returns (address);

    function rhoOne() external view returns (uint256);

    /**
     * Each Vault currently only supports one underlying asset
     * @return Returns the contract address of the underlying asset
     */
    function underlying() external view returns (address);

    function underlyingOne() external view returns (uint256);

    /**
     * @dev Getter function for Rho token minting fee
     * @return Return the minting fee (in bps)
     */
    function mintingFee() external view returns (uint256);

    /**
     * @dev Getter function for Rho token redemption fee
     * @return Return the redeem fee (in bps)
     */
    function redeemFee() external view returns (uint256);

    /**
     * @dev Getter function for allocation lowerbound and upperbound
     */
    function reserveBoundary(uint256 index) external view returns (uint256);

    function managementFee() external view returns (uint256);

    /**
     * @dev The threshold (denominated in underlying asset ) over which rewards tokens will automatically
     * be converted into the underlying asset
     */

    function rewardCollectThreshold() external view returns (uint256);

    function underlyingNativePriceOracle() external view returns (address);

    function setUnderlyingNativePriceOracle(address addr) external;

    /**
     * @dev Setter function for Rho token redemption fee
     */
    function setRedeemFee(uint256 _feeInBps) external;

    /**
     * @dev set the threshold for collect reward (denominated in underlying asset)
     */
    function setRewardCollectThreshold(uint256 _rewardCollectThreshold) external;

    function setManagementFee(uint256 _feeInBps) external;

    /**
     * @dev set the allocation threshold (denominated in underlying asset)
     */
    function setReserveBoundary(uint256 _lowerBound, uint256 _upperBound) external;

    /**
     * @dev Setter function for minting fee (in bps)
     */
    function setMintingFee(uint256 _feeInBps) external;

    function reserveLowerBound(uint256 tvl) external view returns (uint256);

    function reserveUpperBound(uint256 tvl) external view returns (uint256);

    function supplyRate() external view returns (uint256);

    /**
     * @dev Add strategy contract which implments the IRhoStrategy interface to the vault
     */
    function addStrategy(string memory name, address strategy) external;

    /**
     * @dev Remove strategy contract which implments the IRhoStrategy interface from the vault
     */
    function removeStrategy(address strategy) external;

    /**
     * @dev Check if a strategy is registered
     * @param s address of strategy contract
     * @return boolean
     */
    function isStrategyRegistered(address s) external view returns (bool);

    function getStrategiesList() external view returns (Strategy[] memory);

    function getStrategiesListLength() external view returns (uint256);

    function updateStrategiesDetail(uint256 vaultUnderlyingBalance)
        external
        returns (
            uint256[] memory,
            uint256[] memory,
            bool[] memory,
            uint256,
            uint256
        );

    function checkStrategiesCollectReward() external view returns (bool[] memory collectList);

    function indicativeSupplyRate() external view returns (uint256);

    function setFlurryToken(address addr) external;

    function flurryStakingRewards() external view returns (address);

    function setFlurryStakingRewards(address addr) external;

    function tokenExchange() external view returns (address);

    function setTokenExchange(address addr) external;

    /**
     * @notice Part of the management fee is used to buy back FLURRY
     * from AMM. The FLURRY tokens are sent to FlurryStakingRewards
     * to replendish the rewards pool.
     * @return ratio of repurchasing, with 1e18 representing 100%
     */
    function repurchaseFlurryRatio() external view returns (uint256);

    /**
     * @notice setter method for `repurchaseFlurryRatio`
     * @param _ratio new ratio to be set, must be <=1e18
     */
    function setRepurchaseFlurryRatio(uint256 _ratio) external;

    /**
     * @notice Triggers FLURRY repurchasing if management fee >= threshold
     * @return threshold for triggering FLURRY repurchasing
     */
    function repurchaseFlurryThreshold() external view returns (uint256);

    /**
     * @notice setter method for `repurchaseFlurryThreshold`
     * @param _threshold new threshold to be set
     */
    function setRepurchaseFlurryThreshold(uint256 _threshold) external;

    /**
     * @dev Vault should call this before repurchaseFlurry() for sanity check
     * @return true if all dependent contracts are valid
     */
    function repurchaseSanityCheck() external view returns (bool);

    /**
     * @dev Get the strategy which the deposit token belongs to
     * @param depositToken address of deposit token
     */
    function getStrategy(address depositToken) external view returns (address);

    /**
     * @dev Add unwinder contract which implments the IDepositUnwinder interface to the vault
     * @param token deposit token address
     * @param tokenName deposit token name
     * @param unwinder deposit unwinder address
     */
    function addDepositUnwinder(
        address token,
        string memory tokenName,
        address unwinder
    ) external;

    /**
     * @dev Remove unwinder contract which implments the IDepositUnwinder interface from the vault
     * @param token deposit token address
     */
    function removeDepositUnwinder(address token) external;

    /**
     * @dev Get the unwinder which the deposit token belongs to
     * @param token deposit token address
     * @return d unwinder object
     */
    function getDepositUnwinder(address token) external view returns (DepositUnwinder memory d);

    /**
     * @dev Get the deposit tokens
     * @return deposit token addresses
     */
    function getDepositTokens() external view returns (address[] memory);

    function setRhoToken(address token) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/**
 * @title RhoStrategy Interface
 * @notice Interface for yield farming strategies to integrate with various DeFi Protocols like Compound, Aave, dYdX.. etc
 */
interface IRhoStrategy {
    /**
     * Events
     */
    event WithdrawAllCashAvailable();
    event WithdrawUnderlying(uint256 amount);
    event Deploy(uint256 amount);
    event StrategyOutOfCash(uint256 balance, uint256 withdrawable);
    event BalanceOfUnderlyingChanged(uint256 balance);

    /**
     * @return name of protocol
     */
    function NAME() external view returns (string memory);

    /**
     * @dev for conversion bwtween APY and per block rate
     * @return number of blocks per year
     */
    function BLOCK_PER_YEAR() external view returns (uint256);

    /**
     * @dev setter function for `BLOCK_PER_YEAR`
     * @param blocksPerYear new number of blocks per year
     */
    function setBlocksPerYear(uint256 blocksPerYear) external;

    /**
     * @return underlying ERC20 token
     */
    function underlying() external view returns (IERC20MetadataUpgradeable);

    /**
     * @dev unlock when TVL exceed the this target
     */
    function switchingLockTarget() external view returns (uint256);

    /**
     * @dev duration for locking the strategy
     */
    function switchLockDuration() external view returns (uint256);

    /**
     * @return block number after which rewards are unlocked
     */
    function switchLockedUntil() external view returns (uint256);

    /**
     * @dev setter of switchLockDuration
     */
    function setSwitchLockDuration(uint256 durationInBlock) external;

    /**
     * @dev lock the strategy with a lock target
     */
    function switchingLock(uint256 lockTarget, bool extend) external;

    /**
     * @dev view function to return balance in underlying
     * @return balance (interest included) from DeFi protocol, in terms of underlying (in wei)
     */
    function balanceOfUnderlying() external view returns (uint256);

    /**
     * @dev updates the balance in underlying, and returns it. An `BalanceOfUnderlyingChanged` event is also emitted
     * @return updated balance (interest included) from DeFi protocol, in terms of underlying (in wei)
     */
    function updateBalanceOfUnderlying() external returns (uint256);

    /**
     * @dev deploy the underlying to DeFi platform
     * @param _amount amount of underlying (in wei) to deploy
     */
    function deploy(uint256 _amount) external;

    /**
     * @notice current supply rate per block excluding bonus token (such as Aave / Comp)
     * @return supply rate per block, excluding yield from reward token if any
     */
    function supplyRatePerBlock() external view returns (uint256);

    /**
     * @notice current supply rate excluding bonus token (such as Aave / Comp)
     * @return supply rate per year, excluding yield from reward token if any
     */
    function supplyRate() external view returns (uint256);

    /**
     * @return address of bonus token contract, or 0 if no bonus token
     */
    function bonusTokens() external view returns (address[] memory);

    /**
     * @notice current bonus rate per block for bonus token (such as Aave / Comp)
     * @return bonus supply rate per block
     */
    function bonusRatePerBlock() external view returns (uint256);

    /**
     * @return bonus tokens accrued
     * @notice may remove in the future
     */
    function bonusTokensAccrued() external view returns (uint256);

    function bonusTokensAccrued(address) external view returns (uint256);

    /**
     * @notice current bonus supply rate (such as Aave / Comp)
     * @return bonus supply rate per year
     */
    function bonusSupplyRate() external view returns (uint256);

    /**
     * @notice effective supply rate of the RhoStrategy
     * @dev returns the effective supply rate fomr the underlying DeFi protocol
     * taking into account any rewards tokens
     * @return supply rate per year, including yield from reward token if any (in wei)
     */
    function effectiveSupplyRate() external view returns (uint256);

    /**
     * @notice effective supply rate of the RhoStrategy
     * @dev returns the effective supply rate fomr the underlying DeFi protocol
     * taking into account any rewards tokens AND the change in deployed amount.
     * @param delta magnitude of underlying to be deployed / withdrawn
     * @param isPositive true if `delta` is deployed, false if `delta` is withdrawn
     * @return supply rate per year, including yield from reward token if any (in wei)
     */
    function effectiveSupplyRate(uint256 delta, bool isPositive) external view returns (uint256);

    /**
     * @dev Withdraw the amount in underlying from DeFi protocol and transfer to vault
     * @param _amount amount of underlying (in wei) to withdraw
     */
    function withdrawUnderlying(uint256 _amount) external;

    /**
     * @dev Withdraw all underlying from DeFi protocol and transfer to vault
     */
    function withdrawAllCashAvailable() external;

    /**
     * @dev Collect any bonus reward tokens available for the strategy
     */
    function collectRewardTokens(uint256 rewardCollectThreshold) external;

    /**
     * @dev admin function - withdraw random token transfer to this contract
     */
    function sweepERC20Token(address token, address to) external;

    function isLocked() external view returns (bool);

    /**
     * @notice Set the threshold (denominated in reward tokens) over which rewards tokens will automatically
     * be converted into the underlying asset
     * @dev default returns false. Override if the Protocol offers reward token (e.g. COMP for Compound)
     * @param rewardCollectThreshold minimum threshold for collecting reward token
     * @return true if reward in underlying > `rewardCollectThreshold`, false otherwise
     */
    function shouldCollectReward(uint256 rewardCollectThreshold) external view returns (bool);

    /**
     * @notice not all of the funds deployed to a strategy might be available for withdrawal
     * @return the amount of underlying tokens available for withdrawal from the rho strategy
     */
    function underlyingWithdrawable() external view returns (uint256);

    /**
     * @notice Get the deposit token contract address
     * @return address of deposit token contract, or 0 if no deposit token
     */
    function depositToken() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/**
 * @notice Interface for yield farming strategies to integrate with various DeFi Protocols like Compound, Aave, dYdX.. etc
 */
interface IRhoToken is IERC20MetadataUpgradeable {
    /**
     * @dev rebase option will be set when user calls setRebasingOption()
     * default is UNKNOWN, determined by EOA/contract type
     */
    enum RebaseOption {
        UNKNOWN,
        REBASING,
        NON_REBASING
    }

    event MultiplierChange(uint256 from, uint256 to);
    event RhoTokenSupplyChanged(uint256 totalSupply, uint256 rebasingSupply, uint256 nonRebasingSupply);
    event SetRebasingOption(address account, RebaseOption option);
    event SetUnderlying(address addr);

    /**
     * @notice specific to BEP-20 interface
     * @return the address of the contract owner
     */
    function getOwner() external view returns (address);

    /**
     * @dev adjusted supply is multiplied by multiplier from rebasing
     * @return issued amount of rhoToken that is rebasing
     * Total supply = adjusted rebasing supply + non-rebasing supply
     * Adjusted rebasing supply = unadjusted rebasing supply * multiplier
     */
    function adjustedRebasingSupply() external view returns (uint256);

    /**
     * @dev unadjusted supply is NOT multiplied by multiplier from rebasing
     * @return internally stored amount of rhoTokens that is rebasing
     */
    function unadjustedRebasingSupply() external view returns (uint256);

    /**
     * @return issued amount of rhoTokens that is non-rebasing
     */
    function nonRebasingSupply() external view returns (uint256);

    /**
     * @notice The multiplier is set during a rebase
     * @param multiplier - scaled by 1e36
     */
    function setMultiplier(uint256 multiplier) external;

    /**
     * @return multiplier - returns the muliplier of the rhoToken, scaled by 1e36
     * @return lastUpdate - last update time of the multiplier, equivalent to last rebase time
     */
    function getMultiplier() external view returns (uint256 multiplier, uint256 lastUpdate);

    /**
     * @notice function to mint rhoTokens - callable only by owner
     * @param account account for sending new minted tokens to
     * @param amount amount of tokens to be minted
     */
    function mint(address account, uint256 amount) external;

    /**
     * @notice function to burn rhoTokens - callable only by owner
     * @param account the account address for burning tokens from
     * @param amount amount of tokens to be burned
     */
    function burn(address account, uint256 amount) external;

    /**
     * @notice switches the account type of `msg.sender` between rebasing and non-rebasing
     * @param isRebasing true if setting to rebasing, false if setting to non-rebasing
     * NOTE: this function does nothing if caller is already in the same option
     */
    function setRebasingOption(bool isRebasing) external;

    /**
     * @param account address of account to check
     * @return true if `account` is a rebasing account
     */
    function isRebasingAccount(address account) external view returns (bool);

    /**
     * @notice Admin function - set reference token rewards contract
     * @param tokenRewards token rewards contract address
     */
    function setTokenRewards(address tokenRewards) external;

    /**
     * @notice Admin function to sweep ERC20s (other than rhoToken) accidentally sent to this contract
     * @param token token contract address
     * @param to which address to send sweeped ERC20s to
     */
    function sweepERC20Token(address token, address to) external;

    /**
     * @notice Admin function - set reference underlying token contract
     * @param token contract address
     */
    function setUnderlying(address token) external;

    /**
     * @return Returns the contract address of the underlying asset
     */
    function underlying() external view returns (address);

    /**
     * @notice Admin function - pause contract
     */
    function pause() external;

    /**
     * @notice Admin function - unpause contract
     */
    function unpause() external;

    /**
     * @return true if contract is paused
     */
    function paused() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

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
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
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
        _checkRole(role, _msgSender());
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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
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
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
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

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

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
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @title Deposit Token Converter Interface
 * @notice an adapter which unwinds the deposit token and retrieve the underlying tokens
 *
 */
interface IDepositUnwinder {
    event DepositTokenAdded(address depositToken, address underlyingToken);
    event DepositTokenSet(address depositToken, address underlyingToken);
    event DepositTokenRemoved(address depositToken, address underlyingToken);
    event DepositTokenUnwound(address depositToken, address underlyingToken, uint256 amountIn, uint256 amountOut);

    /**
     * @return name of protocol
     */
    function NAME() external view returns (string memory);

    /**
     * @param depositToken address of the deposit token
     * @return address of the corresponding underlying token contract
     */
    function underlyingToken(address depositToken) external view returns (address);

    /**
     * @notice Admin function - add deposit/underlying pair to this contract
     * @param depositTokenAddr the address of the deposit token contract
     * @param underlying the address of the underlying token contract
     */
    function addDepositToken(address depositTokenAddr, address underlying) external;

    /**
     * @notice Admin function - remove deposit/underlying pair to this contract
     * @param depositTokenAddr the address of the deposit token contract
     */
    function removeDepositToken(address depositTokenAddr) external;

    /**
     * @notice Admin function - change deposit/underlying pair to this contract
     * @param depositToken the address of the deposit token contract
     * @param underlying the address of the underlying token contract
     */
    function setDepositToken(address depositToken, address underlying) external;

    // /**
    //  * @notice Get deposit token list
    //  * @return list of deposit tokens address
    //  */

    /**
     * @notice Admin function - withdraw random token transfer to this contract
     * @param token ERC20 token address to be sweeped
     * @param to address for sending sweeped tokens to
     */
    function sweepERC20Token(address token, address to) external;

    /**
     * @notice Get exchange rate of a token to its underlying
     * @param token address of deposit token
     * @return uint256 which is the amount of underlying (after division of decimals)
     */
    function exchangeRate(address token) external view returns (uint256);

    /**
     * @notice A method to sell all input token in this contract into output token.
     * @param token address of deposit token
     * @param beneficiary to receive unwound underlying tokens
     * @return uint256 no. of underlying tokens retrieved
     */
    function unwind(address token, address beneficiary) external returns (uint256);
}