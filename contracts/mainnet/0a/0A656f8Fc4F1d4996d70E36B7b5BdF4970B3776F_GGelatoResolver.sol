// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

import "Ownable.sol";
import {IResolverV2} from "IResolverV2.sol";
import {IVaultMK2} from "IVaultMK2.sol";
import {IStrategyAPI} from "IStrategyAPI.sol";
import {IVaultAPI} from "IVaultAPI.sol";
import {GGuardedExecutor} from "GGuardedExecutor.sol";

//  ________  ________  ________
//  |\   ____\|\   __  \|\   __  \
//  \ \  \___|\ \  \|\  \ \  \|\  \
//   \ \  \  __\ \   _  _\ \  \\\  \
//    \ \  \|\  \ \  \\  \\ \  \\\  \
//     \ \_______\ \__\\ _\\ \_______\
//      \|_______|\|__|\|__|\|_______|

// gro protocol: https://github.com/groLabs

/// @title Gelato Harvest Resolver
/// @notice To work with Gelato Ops to automate strategy harvests
contract GGelatoResolver is IResolverV2, Ownable {
    /*///////////////////////////////////////////////////////////////
                    Storage Variables/Types/Modifier(s)
    //////////////////////////////////////////////////////////////*/
    /// @notice Struct holding relevant strategy params
    struct strategyParams {
        uint256 gasUsed;
        bool canHarvest;
        address _address;
        uint256 acceptableLoss;
    }
    /// @notice address for DAI Vault
    address public immutable DAIVAULT;
    /// @notice address for USDC Vault
    address public immutable USDCVAULT;
    /// @notice address for USDT Vault
    address public immutable USDTVAULT;
    /// @notice Nested mapping of (strategy index => strategy params)
    mapping(address => mapping(uint256 => strategyParams)) public strategyInfo;
    /// @notice max base fee we accept for a harvest
    uint256 public maxBaseFee;
    /// @notice modifier to check vault address passed is a gro vault
    modifier onlyGroVault(address vaultAddress) {
        require(
            vaultAddress == DAIVAULT ||
                vaultAddress == USDCVAULT ||
                vaultAddress == USDTVAULT,
            "!Gro vault"
        );
        _;
    }

    /*///////////////////////////////////////////////////////////////
                        Constructor
    //////////////////////////////////////////////////////////////*/
    constructor(
        address _daiVault,
        address _usdcVault,
        address _usdtVault
    ) {
        DAIVAULT = _daiVault;
        USDCVAULT = _usdcVault;
        USDTVAULT = _usdtVault;
    }

    /*///////////////////////////////////////////////////////////////
                            Setters
    //////////////////////////////////////////////////////////////*/
    /// @notice set the strategy params
    /// @param vaultAddress address for the vault associated with the strategy
    /// @param strategyIndex index of the strategy
    /// @param gasUsed gas used for harvesting the strategy
    /// @param canHarvest if harvesting via gelato is enabled for strategy
    /// @param strategyAddress address of strategy
    /// @param acceptableLoss accepted loss in which a harvest can still take place

    function setStrategyInfo(
        address vaultAddress,
        uint256 strategyIndex,
        uint256 gasUsed,
        bool canHarvest,
        address strategyAddress,
        uint256 acceptableLoss
    ) external onlyOwner onlyGroVault(vaultAddress) {
        strategyParams memory params = strategyParams(
            gasUsed,
            canHarvest,
            strategyAddress,
            acceptableLoss
        );

        strategyInfo[vaultAddress][strategyIndex] = params;
    }

    /// @notice Maximum basefee allowed for harvests
    /// @param _maxBaseFee maximum allowed basefee in gwei (send in order of 1e9)
    function setMaxBaseFee(uint256 _maxBaseFee) external onlyOwner {
        maxBaseFee = _maxBaseFee;
    }

    /*///////////////////////////////////////////////////////////////
                        Harvest Check Logic
    //////////////////////////////////////////////////////////////*/

    /// @notice To allow the gelato network to check if a gro vault can be harvested
    /// @param _vaultAddress address of the gro vault
    /// @param _strategyIndex index of strategy in the vault
    /// @return canExec if a harvest should occur and execPayload calldata to run harvest
    function harvestChecker(address _vaultAddress, uint256 _strategyIndex)
        external
        view
        override
        onlyGroVault(_vaultAddress)
        returns (bool canExec, bytes memory execPayload)
    {
        strategyParams memory params = strategyInfo[_vaultAddress][
            _strategyIndex
        ];
        if (block.basefee >= maxBaseFee) {
            return (canExec, execPayload);
        }

        if (!params.canHarvest) {
            return (canExec, execPayload);
        }

        if (!_canHarvestWithLoss(params._address, params.acceptableLoss)) {
            return (canExec, execPayload);
        }

        if (_investTrigger(_vaultAddress)) {
            return (canExec, execPayload);
        }

        uint256 callCost = block.basefee * params.gasUsed;

        if (
            IVaultMK2(_vaultAddress).strategyHarvestTrigger(
                _strategyIndex,
                callCost
            )
        ) {
            canExec = true;
            execPayload = abi.encodeWithSelector(
                GGuardedExecutor.executeHarvest.selector,
                _vaultAddress,
                uint256(_strategyIndex)
            );
            return (canExec, execPayload);
        }
    }

    /// @notice To allow the gelato network to check if a gro vault needs assets invested
    /// @param _vaultAddress address of the gro vault
    /// @return canExec if a invest action should occur and execPayload calldata to run invest
    function investChecker(address _vaultAddress)
        external
        view
        override
        onlyGroVault(_vaultAddress)
        returns (bool canExec, bytes memory execPayload)
    {
        if (_investTrigger(_vaultAddress)) {
            canExec = true;
            execPayload = abi.encodeWithSelector(
                GGuardedExecutor.executeInvest.selector,
                _vaultAddress
            );
        }
    }

    /// @notice Internal check if the vault needs to invest prior to the harvest
    /// @param _vaultAddress address of the gro vault
    /// @return needs_investment bool that indicating if the vault needs to invest assets
    ///     before harvesting
    function _investTrigger(address _vaultAddress)
        private
        view
        returns (bool needs_investment)
    {
        if (IVaultMK2(_vaultAddress).investTrigger()) return true;
        else return false;
    }

    /// @notice Internal check to ensure that we would want to realize a loss through harvest
    /// @param _strategyAddress address of vault strategy
    /// @param _acceptableLoss max loss amount we would want to realized
    /// @return needs_harvest bool that indicated if the strategy needs to be harveted or not
    /// @dev This should only be applicable to strategies that run against AMMs or similar
    ///     contracts that are expected to produce temporary flucations in values that are
    ///     expected to recover after some time - this in order to prevent realising gains
    ///     and losses multiple times during drop and recover phases.
    function _canHarvestWithLoss(
        address _strategyAddress,
        uint256 _acceptableLoss
    ) private view returns (bool needs_harvest) {
        IStrategyAPI strategyAPI = IStrategyAPI(_strategyAddress);
        uint256 total = strategyAPI.estimatedTotalAssets();
        address vault = strategyAPI.vault();
        uint256 totalDebt = IVaultAPI(vault)
            .strategies(_strategyAddress)
            .totalDebt;

        if (total > totalDebt - _acceptableLoss) return true;

        return false;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IResolverV2 {
    function harvestChecker(address vaultAddress, uint256 index)
        external
        view
        returns (bool canExec, bytes memory execPayload);

    function investChecker(address vaultAddress)
        external
        view
        returns (bool canExec, bytes memory execPayload);
}

// SPDX-License-Identifier: AGPLv3

pragma solidity 0.8.10;

interface IVaultMK2 {
    function getStrategiesLength() external view returns (uint256);

    function strategyHarvestTrigger(uint256 index, uint256 callCost) external view returns (bool);

    function strategyHarvest(uint256 index) external returns (bool);

    function investTrigger() external view returns (bool);

    function invest() external;
}

// SPDX-License-Identifier: AGPLv3

pragma solidity 0.8.10;

interface IStrategyAPI {
    function vault() external view returns (address);

    function estimatedTotalAssets() external view returns (uint256);
}

// SPDX-License-Identifier: AGPLv3

pragma solidity 0.8.10;

struct StrategyParams {
    uint256 activation;
    uint256 debtRatio;
    uint256 minDebtPerHarvest;
    uint256 maxDebtPerHarvest;
    uint256 lastReport;
    uint256 totalDebt;
    uint256 totalGain;
    uint256 totalLoss;
}

interface IVaultAPI {
    function strategies(address _strategy)
        external
        view
        returns (StrategyParams memory);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

import "Ownable.sol";
import {IResolverV2} from "IResolverV2.sol";
import {IVaultMK2} from "IVaultMK2.sol";
import {IStrategyAPI} from "IStrategyAPI.sol";
import {IVaultAPI} from "IVaultAPI.sol";
import {GGelatoResolver} from "GGelatoResolver.sol";

//  ________  ________  ________
//  |\   ____\|\   __  \|\   __  \
//  \ \  \___|\ \  \|\  \ \  \|\  \
//   \ \  \  __\ \   _  _\ \  \\\  \
//    \ \  \|\  \ \  \\  \\ \  \\\  \
//     \ \_______\ \__\\ _\\ \_______\
//      \|_______|\|__|\|__|\|_______|

// gro protocol: https://github.com/groLabs

contract GGuardedExecutor is Ownable {
    /*///////////////////////////////////////////////////////////////
                    Storage Variables/Types/Modifier(s)
    //////////////////////////////////////////////////////////////*/
    // @notice address for resolver
    GGelatoResolver public resolver;
    /// @notice keeper address
    address public keeper;

    modifier onlyKeeper() {
        require(msg.sender == keeper, "!Keeper");
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            Setters
    //////////////////////////////////////////////////////////////*/

    function setKeeper(address _keeper) external onlyOwner {
        keeper = _keeper;
    }

    function setResolver(GGelatoResolver _resolver) external onlyOwner {
        resolver = _resolver;
    }

    /*///////////////////////////////////////////////////////////////
                        Core Logic
    //////////////////////////////////////////////////////////////*/

    function executeHarvest(address _vault, uint256 _index)
        external
        onlyKeeper
    {
        (bool canExecute, ) = resolver.harvestChecker(_vault, _index);
        require(canExecute, "!Execute");

        IVaultMK2(_vault).strategyHarvest(_index);
    }

    function executeInvest(address _vault) external onlyKeeper {
        (bool canExecute, ) = resolver.investChecker(_vault);
        require(canExecute, "!Execute");
        IVaultMK2(_vault).invest();
    }
}