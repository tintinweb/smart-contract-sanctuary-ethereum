/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import "../interfaces/IPotionBuyAction.sol";
import "../interfaces/IVault.sol";
import { PotionBuyInfo } from "../interfaces/IPotionBuyInfo.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IUniswapV3Oracle.sol";
import "../interfaces/IPotionProtocolOracle.sol";

/**  
    @title HedgingVaultOperatorHelper

    @author Roberto Cano <robercano>

    @notice Helper contract to allow the operator to enter and exit a position of a hedging vault using only
    one transaction. The Hedging Vault is an investment vault using the PotionBuyAction strategy. The helper
    talks to both the vault and the action separately to configure the necessary swap routes and potion buy
    counterparties, and then enters the position. This also allows to minimize the amount of slippage in the
    Uniswap V3 swap and the Potion Protocol buy.
 */
contract HedgingVaultOperatorHelper is Ownable {
    IVault public immutable hedgingVault;
    IPotionBuyAction public immutable potionBuyAction;

    /**
        @notice Initializes the helper with the vault and the action to be used to enter and exit the position.

        @param hedgingVault_ The vault to be used to enter and exit the position.
        @param potionBuyAction_ The action to be used to enter and exit the position.
    */
    constructor(address hedgingVault_, address potionBuyAction_) {
        hedgingVault = IVault(hedgingVault_);
        potionBuyAction = IPotionBuyAction(potionBuyAction_);
    }

    /**
        @notice Enters the position of the hedging vault by setting first the Potion buy counterparties list
        and the Uniswap V3 swap route, and then entering the position.

        @param swapInfo The Uniswap V3 route to swap some hedged asset for USDC to pay the Potion Protocol premium
        @param potionBuyInfo List of counterparties to use for the Potion Protocol buy

        @dev Only the owner of the contract (i.e. the Operator) can call this function
     */
    function enterPosition(IUniswapV3Oracle.SwapInfo calldata swapInfo, PotionBuyInfo calldata potionBuyInfo)
        external
        onlyOwner
    {
        potionBuyAction.setPotionBuyInfo(potionBuyInfo);
        potionBuyAction.setSwapInfo(swapInfo);
        hedgingVault.enterPosition();
    }

    /**
        @notice Exits the position of the hedging vault by setting first the Uniswap V3 swap route,
        and then exiting the position.

        @param swapInfo The Uniswap V3 route to swap the received pay-out from USDC back to the hedged asset

        @dev Only the owner of the contract (i.e. the Operator) can call this function
     */
    function exitPosition(IUniswapV3Oracle.SwapInfo calldata swapInfo) external onlyOwner {
        potionBuyAction.setSwapInfo(swapInfo);
        hedgingVault.exitPosition();
    }

    /**
        @notice Convenience function to know if a position can be entered or not

        @dev Just redirects the call to the hedging vault
     */
    function canPositionBeEntered() external view returns (bool) {
        return hedgingVault.canPositionBeEntered();
    }

    /**
        @notice Convenience function to know if a position can be exited or not

        @dev Just redirects the call to the hedging vault
     */
    function canPositionBeExited() external view returns (bool) {
        return hedgingVault.canPositionBeExited();
    }
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import "./IAction.sol";
import "./IUniswapV3Oracle.sol";
import "./IPotionProtocolOracle.sol";

/**
    @title IPotionBuyAction

    @author Roberto Cano <robercano>

    @dev See { PotionBuyAction }
    @dev See { PotionBuyActionV0 }

    @dev This interface is not inherited by PotionBuyAction itself and only serves to expose the functions
    that are used by the Operator to configure parameters. In particular it is used by { HedgingVaultOperatorHelper }
    to aid in the operation of the vault
    
 */
// solhint-disable-next-line no-empty-blocks
interface IPotionBuyAction is IAction, IUniswapV3Oracle, IPotionProtocolOracle {
    // Empty on purpose
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import { IRolesManager } from "../interfaces/IRolesManager.sol";
import { ILifecycleStates } from "../interfaces/ILifecycleStates.sol";
import { IEmergencyLock } from "../interfaces/IEmergencyLock.sol";
import { IRefundsHelper } from "../interfaces/IRefundsHelper.sol";
import { IFeeManager } from "../interfaces/IFeeManager.sol";

/**  
    @title IVault

    @author Roberto Cano <robercano>

    @notice Interface for the a vault that executes investment actions on each investment cycle

    @dev An IVault represents a vault that contains a set of investment actions. When entering the
    position, all the actions in the vault are executed in order, one after the other. If all
    actions succeed, then the position is entered. Once the position can be exited, the investment
    actions are also exited and the profit/loss of the investment cycle is realized.
 */
interface IVault is IRolesManager, ILifecycleStates, IEmergencyLock, IRefundsHelper, IFeeManager {
    /// EVENTS
    event VaultPositionEntered(uint256 totalPrincipalAmount, uint256 principalAmountInvested);
    event VaultPositionExited(uint256 newPrincipalAmount);

    /// FUNCTIONS
    /**
        @notice Function called to enter the investment position

        @dev When called, the vault will enter the position of all configured actions. For each action
        it will approve each action for the configured principal percentage so each action can access
        the funds in order to execute the specific investment strategy

        @dev Once the Vault enters the investment position no more immediate deposits or withdrawals
        are allowed
     */
    function enterPosition() external;

    /**
        @notice Function called to exit the investment position

        @return newPrincipalAmount The final amount of principal that is in the vault after the actions
        have exited their positions

        @dev When called, the vault will exit the position of all configured actions. Each action will send
        back the remaining funds (including profit or loss) to the vault
     */
    function exitPosition() external returns (uint256 newPrincipalAmount);

    /**
        @notice It inficates if the position can be entered or not

        @return canEnter true if the position can be entered, false otherwise

        @dev The function checks if the position can be entered for the current block. If it returns
        true then it indicates that the position can be entered at any moment from the current block.
        This invariant only takes into account the current state of the vault itself and not any external
        dependendencies that the vault or the actions may have
     */
    function canPositionBeEntered() external view returns (bool canEnter);

    /**
        @notice It indicates if the position can be exited or not

        @return canExit true if the position can be exited, false otherwise

        @dev The function checks if the position can be exited for the current block. If it returns
        true then it indicates that the position can be exited at any moment from the current block.
        This invariant only takes into account the current state of the vault itself and not any external
        dependendencies that the vault or the actions may have
     */
    function canPositionBeExited() external view returns (bool canExit);
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import { IPotionLiquidityPool } from "../interfaces/IPotionLiquidityPool.sol";

/**    
    @title IPotionBuyInfo
        
    @author Roberto Cano <robercano>

    @notice Structure for the PotionBuyInfo
 */

/**
        @notice The information required to buy a specific potion with a specific maximum premium requirement

        @custom:member targetPotionAddress The address of the potion (otoken) to buy
        @custom:member underlyingAsset The address of the underlying asset of the potion (otoken) to buy
        @custom:member strikePriceInUSDC The strike price of the potion (otoken) to buy, with 8 decimals
        @custom:member expirationTimestamp The expiration timestamp of the potion (otoken) to buy
        @custom:member sellers The list of liquidity providers that will be used to buy the potion
        @custom:member expectedPremiumInUSDC The expected premium to be paid for the given order size
                       and the given sellers, in USDC
        @custom:member totalSizeInPotions The total number of potions to buy using the given sellers list
     */
struct PotionBuyInfo {
    address targetPotionAddress;
    address underlyingAsset;
    uint256 strikePriceInUSDC;
    uint256 expirationTimestamp;
    IPotionLiquidityPool.CounterpartyDetails[] sellers;
    uint256 expectedPremiumInUSDC;
    uint256 totalSizeInPotions;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

/**
    @title IUniswapV3Oracle

    @notice Oracle contract for Uniswap V3 swaps. It takes care of holding information about the
    path to use for a specific swap, and the expected price for a that swap.
 */
interface IUniswapV3Oracle {
    /**
        @notice The information required to perform a safe swap

        @custom:member inputToken The address of the input token in the swap
        @custom:member outputToken The address of the output token in the swap
        @custom:member expectedPriceRate The expected price of the swap as a fixed point SD59x18 number
        @custom:member swapPath The path to use for the swap as an ABI encoded array of bytes

        @dev See [Multi-hop Swaps](https://docs.uniswap.org/protocol/guides/swaps/multihop-swaps) for
        more information on the `swapPath` format
     */
    struct SwapInfo {
        address inputToken;
        address outputToken;
        uint256 expectedPriceRate;
        bytes swapPath;
    }

    /// FUNCTIONS

    /**
        @notice Sets the swap information for an input/output token pair. The information
        includes the swap path and the expected swap price

        @param info The swap information for the pair

        @dev Only the Keeper role can call this function

        @dev See { SwapInfo }
     */
    function setSwapInfo(SwapInfo calldata info) external;

    /**
        @notice Gets the swap information for the given input/output token pair

        @param inputToken The address of the input token in the swap
        @param outputToken The address of the output token in the swap

        @return The swap information for the pair

     */
    function getSwapInfo(address inputToken, address outputToken) external view returns (SwapInfo memory);
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import { IPotionLiquidityPool } from "./IPotionLiquidityPool.sol";
import { PotionBuyInfo } from "./IPotionBuyInfo.sol";

/**
    @title IPotionProtocolOracle

    @notice Oracle contract for the Potion Protocol potion buy. It takes care of holding the information
    about the counterparties that will be used to buy a particular potion (potion) with a maximum allowed
    premium

    @dev It is very basic and it just aims to abstract the idea of an Oracle into a separate contract
    but it is still very coupled with PotionProtocolHelperUpgradeable
 */
interface IPotionProtocolOracle {
    /// FUNCTIONS

    /**
        @notice Sets the potion buy information for a specific potion

        @param info The information required to buy a specific potion with a specific maximum premium requirement

        @dev Only the Operator can call this function
     */
    function setPotionBuyInfo(PotionBuyInfo calldata info) external;

    /**
        @notice Gets the potion buy information for a given OToken

        @param underlyingAsset The address of the underlying token of the potion
        @param strikePrice The strike price of the potion
        @param expirationTimestamp The timestamp when the potion expires

        @return The Potion Buy information for the given potion

        @dev See { PotionBuyInfo }

     */
    function getPotionBuyInfo(
        address underlyingAsset,
        uint256 strikePrice,
        uint256 expirationTimestamp
    ) external view returns (PotionBuyInfo memory);
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

/**  
    @title IAction

    @author Roberto Cano <robercano>

    @notice Interface for the investment actions executed on each investment cycle

    @dev An IAction represents an investment action that can be executed by an external caller.
    This caller will typically be a Vault, but it could also be used in other strategies.

    @dev An Action receives a loan from its caller so it can perform a specific investment action.
    The asset and amount of the loan is indicated in the `enterPosition` call, and the Action can transfer
    up to the indicated amount from the caller for the specified asset, and use it in the investment.
    Once the action indicates that the investment cycle is over, by signaling it through the
    `canPositionBeExited` call, the  caller can call `exitPosition` to exit the position. Upon this call,
    the action will transfer to the caller what's remaining of the loan, and will also return this amount
    as the return value of the `exitPotision` call.

    @dev The Actions does not need to transfer all allowed assets to itself if it is not needed. It could,
    for example, transfer a small amount which is enough to cover the cost of the investment. However,
    when returning the remaining amount, it must take into account the whole amount for the loan. For
    example:
        - The Action enters a position with a loan of 100 units of asset A
        - The Action transfers 50 units of asset A to itself
        - The Action exits the position with 65 units of asset A
        - Because it was allowed to get 100 units of asset A, and it made a profit of 15,
          the returned amount in the `exitPosition` call is 115 units of asset A (100 + 15).
        - If instead of 65 it had made a loss of 30 units, the returned amount would be
          70 units of asset A (100 - 30)

    @dev The above logic helps the caller easily track the profit/loss for the last investment cycle

 */
interface IAction {
    /// EVENTS
    event ActionPositionEntered(address indexed investmentAsset, uint256 amountToInvest);
    event ActionPositionExited(address indexed investmentAsset, uint256 amountReturned);

    /// FUNCTIONS
    /**
        @notice Function called to enter the investment position

        @param investmentAsset The asset available to the action contract for the investment 
        @param amountToInvest The amount of the asset that the action contract is allowed to use in the investment

        @dev When called, the action should have been approved for the given amount
        of asset. The action will retrieve the required amount of asset from the caller
        and invest it according to its logic
     */
    function enterPosition(address investmentAsset, uint256 amountToInvest) external;

    /**
        @notice Function called to exit the investment position

        @param investmentAsset The asset reclaim from the investment position

        @return amountReturned The amount of asset that the action contract received from the caller
        plus the profit or minus the loss of the investment cycle

        @dev When called, the action must transfer all of its balance for `asset` to the caller,
        and then return the total amount of asset that it received from the caller, plus/minus
        the profit/loss of the investment cycle.

        @dev See { IAction } description for more information on `amountReturned`
     */
    function exitPosition(address investmentAsset) external returns (uint256 amountReturned);

    /**
        @notice It inficates if the position can be entered or not

        @param investmentAsset The asset for which position can be entered or not

        @return canEnter true if the position can be entered, false otherwise

        @dev The function checks if the position can be entered for the current block. If it returns
        true then it indicates that the position can be entered at any moment from the current block.
        This invariant only takes into account the current state of the action itself and not any external
        dependendencies that the action may have
     */
    function canPositionBeEntered(address investmentAsset) external view returns (bool canEnter);

    /**
        @notice It indicates if the position can be exited or not

        @param investmentAsset The asset for which position can be exited or not

        @return canExit true if the position can be exited, false otherwise

        @dev The function checks if the position can be exited for the current block. If it returns
        true then it indicates that the position can be exited at any moment from the current block.
        This invariant only takes into account the current state of the action itself and not any external
        dependendencies that the action may have
     */
    function canPositionBeExited(address investmentAsset) external view returns (bool canExit);
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import "./ICurveManager.sol";
import "./ICriteriaManager.sol";

import "./IOtoken.sol";

// TODO: Add a description of the interface
interface IPotionLiquidityPool {
    /*
        @notice The details of a given counterparty that will be used to buy a potion

        @custom:member lp The LP to buy from
        @custom:member poolId The pool (belonging to LP) that will colalteralize the otoken
        @custom:member curve The curve used to calculate the otoken premium
        @custom:member criteria The criteria associated with this curve, which matches the otoken
        @custom:member orderSizeInOtokens The number of otokens to buy from this particular counterparty
    */
    struct CounterpartyDetails {
        address lp;
        uint256 poolId;
        ICurveManager.Curve curve;
        ICriteriaManager.Criteria criteria;
        uint256 orderSizeInOtokens;
    }

    /**
        @notice The data associated with a given pool of capital, belonging to one LP

        @custom:member total The total (locked or unlocked) of capital in the pool, denominated in collateral tokens
        @custom:member locked The amount of locked capital in the pool, denominated in collateral tokens
        @custom:member curveHash Identifies the curve to use when pricing the premiums charged for any otokens
                                 sold (& collateralizated) by this pool
        @custom:member criteriaSetHash Identifies the set of otokens that this pool is willing to sell (& collateralize)
    */
    struct PoolOfCapital {
        uint256 total;
        uint256 locked;
        bytes32 curveHash;
        bytes32 criteriaSetHash;
    }

    /**
       @notice Buy a OTokens from the specified list of sellers.
       
       @param _otoken The identifier (address) of the OTokens being bought.
       @param _sellers The LPs to buy the new OTokens from. These LPs will charge a premium to collateralize the otoken.
       @param _maxPremium The maximum premium that the buyer is willing to pay, denominated in collateral tokens (wei) and aggregated across all sellers
       
       @return premium The aggregated premium paid.
     */
    function buyOtokens(
        IOtoken _otoken,
        CounterpartyDetails[] memory _sellers,
        uint256 _maxPremium
    ) external returns (uint256 premium);

    /**
        @notice Creates a new otoken, and then buy it from the specified list of sellers.
     
        @param underlyingAsset A property of the otoken that is to be created.
        @param strikeAsset A property of the otoken that is to be created.
        @param collateralAsset A property of the otoken that is to be created.
        @param strikePrice A property of the otoken that is to be created.
        @param expiry A property of the otoken that is to be created.
        @param isPut A property of the otoken that is to be created.
        @param sellers The LPs to buy the new otokens from. These LPs will charge a premium to collateralize the otoken.
        @param maxPremium The maximum premium that the buyer is willing to pay, denominated in collateral tokens (wei) and aggregated across all sellers
        
        @return premium The total premium paid.
     */
    function createAndBuyOtokens(
        address underlyingAsset,
        address strikeAsset,
        address collateralAsset,
        uint256 strikePrice,
        uint256 expiry,
        bool isPut,
        CounterpartyDetails[] memory sellers,
        uint256 maxPremium
    ) external returns (uint256 premium);

    /**
       @notice Retrieve unused collateral from Opyn into this contract. Does not redistribute it to our (unbounded number of) LPs.
               Redistribution can be done by calling redistributeSettlement(addresses).

       @param _otoken The identifier (address) of the expired OToken for which unused collateral should be retrieved.
     */
    function settleAfterExpiry(IOtoken _otoken) external;

    /**
        @notice Get the ID of the existing Opyn vault that Potion uses to collateralize a given OToken.
        
        @param _otoken The identifier (token contract address) of the OToken. Not checked for validity in this view function.
        
        @return The unique ID of the vault, > 0. If no vault exists, the returned value will be 0
     */
    function getVaultId(IOtoken _otoken) external view returns (uint256);

    /**
        @dev Returns the data about the pools of capital, indexed first by LP
             address and then by an (arbitrary) numeric poolId

        @param lpAddress The address of the LP that owns the pool
        @param poolId The ID of the pool owned by the LP

        @return The data about the pool of capital
    */
    function lpPools(address lpAddress, uint256 poolId) external view returns (PoolOfCapital memory);
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

/**
 * @title ICurveManager
 * @notice Keeps a registry of all Curves that are known to the Potion protocol
 */
interface ICurveManager {
    struct Curve {
        int256 a_59x18;
        int256 b_59x18;
        int256 c_59x18;
        int256 d_59x18;
        int256 max_util_59x18;
    }
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

// TODO: Add a description of the interface
interface ICriteriaManager {
    struct Criteria {
        address underlyingAsset;
        address strikeAsset;
        bool isPut;
        uint256 maxStrikePercent;
        uint256 maxDurationInDays; // Must be > 0 for valid criteria. Doubles as existence flag.
    }
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

// TODO: Add a description of the interface
interface IOtoken {
    function underlyingAsset() external view returns (address);

    function strikeAsset() external view returns (address);

    function collateralAsset() external view returns (address);

    function strikePrice() external view returns (uint256);

    function expiryTimestamp() external view returns (uint256);

    function isPut() external view returns (bool);

    function init(
        address _addressBook,
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external;

    function getOtokenDetails()
        external
        view
        returns (
            address,
            address,
            address,
            uint256,
            uint256,
            bool
        );

    function mintOtoken(address account, uint256 amount) external;

    function burnOtoken(address account, uint256 amount) external;
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

/**
    @title IRolesManager

    @author Roberto Cano <robercano>
    
    @notice The RolesManager contract is a helper contract that provides a three access roles: Admin,
    Strategist and Operator. The scope of the different roles is as follows:
      - Admin: The admin role is the only role that can change the other roles, including the Admin
      role itself. 
      - Strategist: The strategist role is the one that can change the vault and action parameters
      related to the investment strategy. Things like slippage percentage, maximum premium, principal
      percentages, etc...
      - Operator: The operator role is the one that can cycle the vault and the action through its
      different states

    @dev The Admin can always change the Strategist address, Operator address and also change the Admin address.
    The Strategist and Operator roles have no special access except the access given explcitiely by their
    respective modifiers `onlyStrategist` and `onlyOperator`.
 */

interface IRolesManager {
    /// EVENTS
    event AdminChanged(address indexed prevAdminAddress, address indexed newAdminAddress);
    event StrategistChanged(address indexed prevStrategistAddress, address indexed newStrategistAddress);
    event OperatorChanged(address indexed prevOperatorAddress, address indexed newOperatorAddress);
    event VaultChanged(address indexed prevVaultAddress, address indexed newVaultAddress);

    /// FUNCTIONS

    /**
        @notice Changes the existing Admin address to a new one

        @dev Only the previous Admin can change the address to a new one
     */
    function changeAdmin(address newAdminAddress) external;

    /**
        @notice Changes the existing Strategist address to a new one

        @dev Only the Admin can change the address to a new one
     */
    function changeStrategist(address newStrategistAddress) external;

    /**
        @notice Changes the existing Operator address to a new one

        @dev Only the Admin can change the address to a new one
     */
    function changeOperator(address newOperatorAddress) external;

    /**
        @notice Changes the existing Vault address to a new one

        @dev Only the Admin can change the address to a new one
     */
    function changeVault(address newVaultAddress) external;

    /**
        @notice Returns the current Admin address
     */
    function getAdmin() external view returns (address);

    /**
        @notice Returns the current Strategist address
     */
    function getStrategist() external view returns (address);

    /**
        @notice Returns the current Operator address
     */
    function getOperator() external view returns (address);

    /**
        @notice Returns the current Vault address
     */
    function getVault() external view returns (address);
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

/**
    @title ILifecycleStates

    @author Roberto Cano <robercano>
    
    @notice Handles the lifecycle of the hedging vault and provides the necessary modifiers
    to scope functions that must only work in certain states. It also provides a getter
    to query the current state and an internal setter to change the state
 */

interface ILifecycleStates {
    /// STATES

    /**
        @notice States defined for the vault. Although the exact meaning of each state is
        dependent on the HedgingVault contract, the following assumptions are made here:
            - Unlocked: the vault accepts immediate deposits and withdrawals and the specific
            configuration of the next investment strategy is not yet known.
            - Committed: the vault accepts immediate deposits and withdrawals but the specific
            configuration of the next investment strategy is already known
            - Locked: the vault is locked and cannot accept immediate deposits or withdrawals. All
            of the assets managed by the vault are locked in it. It could accept deferred deposits
            and withdrawals though
     */
    enum LifecycleState {
        Unlocked,
        Committed,
        Locked
    }

    /// EVENTS
    event LifecycleStateChanged(LifecycleState indexed prevState, LifecycleState indexed newState);

    /// FUNCTIONS

    /**
        @notice Function to get the current state of the vault
        @return The current state of the vault
     */
    function getLifecycleState() external view returns (LifecycleState);
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

/**
    @title EmergencyLock

    @author Roberto Cano <robercano>
    
    @notice Helper contract that allows the Admin to pause all the functionality of the vault in case
    of an emergency
 */

interface IEmergencyLock {
    // FUNCTIONS

    /**
        @notice Pauses the contract
     */
    function pause() external;

    /**
        @notice Unpauses the contract
     */
    function unpause() external;
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

/**
    @title IRefundsHelper

    @author Roberto Cano <robercano>
    
    @notice Helper contract that allows the Admin to refund tokens or ETH sent to the vault
    by mistake. At construction time it receives the list of tokens that cannot be refunded.
    Those tokens are typically the asset managed by the vault and any intermediary tokens
    that the vault may use to manage the asset.
 */
interface IRefundsHelper {
    /// FUNCTIONS

    /**
        @notice Refunds the given amount of tokens to the given address
        @param token address of the token to be refunded
        @param amount amount of tokens to be refunded
        @param recipient address to which the tokens will be refunded
     */
    function refund(
        address token,
        uint256 amount,
        address recipient
    ) external;

    /**
        @notice Refunds the given amount of ETH to the given address
        @param amount amount of tokens to be refunded
        @param recipient address to which the tokens will be refunded
     */
    function refundETH(uint256 amount, address payable recipient) external;

    /// GETTERS

    /**
        @notice Returns whether the given token is refundable or not

        @param token address of the token to be checked

        @return true if the token is refundable, false otherwise
     */
    function canRefund(address token) external view returns (bool);

    /**
        @notice Returns whether the ETH is refundable or not

        @return true if ETH is refundable, false otherwise
     */
    function canRefundETH() external view returns (bool);
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

/**
    @title IFeeManager

    @author Roberto Cano <robercano>
    
    @notice Handles the fees that the vault fees payment to the configured recipients

    @dev The contract uses PercentageUtils to handle the fee percentages. See { PercentageUtils } for
    more information on the format and precision of the percentages.
 */

interface IFeeManager {
    /// EVENTS
    event ManagementFeeChanged(uint256 oldManagementFee, uint256 newManagementFee);
    event PerformanceFeeChanged(uint256 oldPerformanceFee, uint256 newPerformanceFee);
    event FeesReceipientChanged(address indexed oldFeeReceipient, address indexed newFeeReceipient);
    event FeesSent(
        address indexed receipient,
        address indexed token,
        uint256 managementAmount,
        uint256 performanceAmount
    );
    event FeesETHSent(address indexed receipient, uint256 managementAmount, uint256 performanceAmount);

    /// FUNCTIONS

    /**
        @notice Sets the new management fee

        @param newManagementFee The new management fee in fixed point format (See { PercentageUtils })
     */
    function setManagementFee(uint256 newManagementFee) external;

    /**
        @notice Sets the new performance fee

        @param newPerformanceFee The new performance fee in fixed point format (See { PercentageUtils })
     */
    function setPerformanceFee(uint256 newPerformanceFee) external;

    /**
        @notice Returns the current management fee

        @return The current management fee in fixed point format (See { PercentageUtils })
     */
    function getManagementFee() external view returns (uint256);

    /**
        @notice Returns the current performance fee

        @return The current performance fee in fixed point format (See { PercentageUtils })
     */
    function getPerformanceFee() external view returns (uint256);

    /**
        @notice Sets the new fees recipient
     */
    function setFeesRecipient(address payable newFeesRecipient) external;

    /**
        @notice Returns the current fees recipient
     */
    function getFeesRecipient() external view returns (address);
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