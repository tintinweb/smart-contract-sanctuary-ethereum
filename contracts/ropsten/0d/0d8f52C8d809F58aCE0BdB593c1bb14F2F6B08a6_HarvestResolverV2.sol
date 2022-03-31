// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

import "Ownable.sol";
import {IResolverV2} from "IResolverV2.sol";
import {IVaultMK2} from "IVaultMK2.sol";

//  ________  ________  ________
//  |\   ____\|\   __  \|\   __  \
//  \ \  \___|\ \  \|\  \ \  \|\  \
//   \ \  \  __\ \   _  _\ \  \\\  \
//    \ \  \|\  \ \  \\  \\ \  \\\  \
//     \ \_______\ \__\\ _\\ \_______\
//      \|_______|\|__|\|__|\|_______|

// gro protocol: https://github.com/groLabs

// Primary Author(s)
// Farhaan Ali: https://github.com/farhaan-ali

// Reviewer(s) / Contributor(s)
// Kristian Domanski: https://github.com/kristian-gro

/// @title Gelato Harvest Resolver
/// @notice To work with Gelato Ops to automate strategy harvests
contract HarvestResolverV2 is IResolverV2, Ownable {
    /*///////////////////////////////////////////////////////////////
                        Storage Variables
    //////////////////////////////////////////////////////////////*/
    /// @notice address for DAI Vault
    address public immutable DAIVAULT;
    /// @notice address for USDC Vault
    address public immutable USDCVAULT;
    /// @notice address for USDT Vault
    address public immutable USDTVAULT;
    /// @notice Nested mapping of (strategy index => gas cost) the gas limit
    ///     to harvest each strategy for each vault
    mapping(address => mapping(uint256 => uint256)) public strategyCosts;
    /// @notice Nested mapping of (strategy index => can harvest) to check
    ///     if we have turned on automated harvests for the strategy
    mapping(address => mapping(uint256 => bool)) public canHarvestStrategy;
    /// @notice max base fee we accept for a harvest
    uint256 public maxBaseFee;

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
    /// @notice set the gas limit for a specific strategy
    /// @param vaultAddress address for the vault associated with the strategy
    /// @param strategyIndex index of the strategy
    /// @param gasLimit gasLimit that the strategy harvest uses
    function setStrategyCost(
        address vaultAddress,
        uint256 strategyIndex,
        uint256 gasLimit
    ) external onlyOwner {
        require(
            vaultAddress == DAIVAULT ||
                vaultAddress == USDCVAULT ||
                vaultAddress == USDTVAULT,
            "not gro vault"
        );
        // check if address is a vault
        strategyCosts[vaultAddress][strategyIndex] = gasLimit;
    }

    /// @notice Maximum basefee allowed for harvests
    /// @param _maxBaseFee maximum allowed basefee in gwei (send in order of 1e9)
    function setmaxBaseFee(uint256 _maxBaseFee) external onlyOwner {
        maxBaseFee = _maxBaseFee;
    }

    /// @notice set if a strategy can be harvested
    /// @param vaultAddress address for the vault associated with the strategy
    /// @param strategyIndex index of the strategy
    /// @param _canHarvest set if the strategy can be harvested or not
    function setCanHarvestStrategy(
        address vaultAddress,
        uint256 strategyIndex,
        bool _canHarvest
    ) external onlyOwner {
        canHarvestStrategy[vaultAddress][strategyIndex] = _canHarvest;
    }

    /*///////////////////////////////////////////////////////////////
                        Harvest Check Logic
    //////////////////////////////////////////////////////////////*/

    /// @notice To allow the gelato network to check if a gro vault can be harvested
    /// @param vaultAddress address of the gro vault
    /// @return canExec if a harvest should occur and execPayload calldata to run harvest
    function checker(address vaultAddress)
        external
        view
        override
        returns (bool canExec, bytes memory execPayload)
    {
        require(
            vaultAddress == DAIVAULT ||
                vaultAddress == USDCVAULT ||
                vaultAddress == USDTVAULT,
            "not gro vault"
        );

        uint256 vaultStrategyLength = IVaultMK2(vaultAddress)
            .getStrategiesLength();

        for (uint256 i = 0; i < vaultStrategyLength; i++) {
            if (block.basefee > maxBaseFee) {
                continue;
            }

            if (!canHarvestStrategy[vaultAddress][i]) {
                continue;
            }

            uint256 callCost = block.basefee * strategyCosts[vaultAddress][i];

            if (IVaultMK2(vaultAddress).strategyHarvestTrigger(i, callCost)) {
                canExec = true;
                execPayload = abi.encodeWithSelector(
                    IVaultMK2.strategyHarvest.selector,
                    uint256(i)
                );
            }

            if (canExec) break;
        }
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
    function checker(address vaultAddress)
        external
        view
        returns (bool canExec, bytes memory execPayload);
}

// SPDX-License-Identifier: AGPLv3

pragma solidity 0.8.10;

interface IVaultMK2 {
    function withdraw(uint256 amount) external;

    function withdraw(uint256 amount, address recipient) external;

    function withdrawByStrategyOrder(
        uint256 amount,
        address recipient,
        bool reversed
    ) external;

    function withdrawByStrategyIndex(
        uint256 amount,
        address recipient,
        uint256 strategyIndex
    ) external;

    function deposit(uint256 amount) external;

    function setStrategyDebtRatio(uint256[] calldata strategyRetios) external;

    function totalAssets() external view returns (uint256);

    function getStrategiesLength() external view returns (uint256);

    function strategyHarvestTrigger(uint256 index, uint256 callCost) external view returns (bool);

    function strategyHarvest(uint256 index) external returns (bool);

    function getStrategyAssets(uint256 index) external view returns (uint256);

    function token() external view returns (address);

    function updateStrategyDebtRatio(address strategy, uint256 _debtRatio) external;
}