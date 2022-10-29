// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "contracts/interfaces/IAsset.sol";
import "contracts/interfaces/IAssetRegistry.sol";
import "contracts/interfaces/IBackingManager.sol";
import "contracts/interfaces/IBasketHandler.sol";
import "contracts/interfaces/IBroker.sol";
import "contracts/interfaces/IDeployer.sol";
import "contracts/interfaces/IDistributor.sol";
import "contracts/interfaces/IFurnace.sol";
import "contracts/interfaces/IRevenueTrader.sol";
import "contracts/interfaces/IRToken.sol";
import "contracts/interfaces/IStRSR.sol";
import "contracts/mixins/Versioned.sol";
import "contracts/plugins/assets/Asset.sol";
import "contracts/plugins/assets/RTokenAsset.sol";
import "contracts/p1/Main.sol";
import "contracts/libraries/String.sol";

/**
 * @title DeployerP1
 * @notice The factory contract that deploys the entire P1 system.
 */
contract DeployerP1 is IDeployer, Versioned {
    using Clones for address;

    string public constant ENS = "reserveprotocol.eth";

    IERC20Metadata public immutable rsr;
    IGnosis public immutable gnosis;
    IAsset public immutable rsrAsset;

    // Implementation contracts for Upgradeability
    Implementations public implementations;

    // checks: every address in the input is nonzero
    // effects: post, all contract-state values are set
    constructor(
        IERC20Metadata rsr_,
        IGnosis gnosis_,
        IAsset rsrAsset_,
        Implementations memory implementations_
    ) {
        require(
            address(rsr_) != address(0) &&
                address(gnosis_) != address(0) &&
                address(rsrAsset_) != address(0) &&
                address(implementations_.main) != address(0) &&
                address(implementations_.trade) != address(0) &&
                address(implementations_.components.assetRegistry) != address(0) &&
                address(implementations_.components.backingManager) != address(0) &&
                address(implementations_.components.basketHandler) != address(0) &&
                address(implementations_.components.broker) != address(0) &&
                address(implementations_.components.distributor) != address(0) &&
                address(implementations_.components.furnace) != address(0) &&
                address(implementations_.components.rsrTrader) != address(0) &&
                address(implementations_.components.rTokenTrader) != address(0) &&
                address(implementations_.components.rToken) != address(0) &&
                address(implementations_.components.stRSR) != address(0),
            "invalid address"
        );

        rsr = rsr_;
        gnosis = gnosis_;
        rsrAsset = rsrAsset_;
        implementations = implementations_;
    }

    /// Deploys an instance of the entire system, oriented around some mandate.
    ///
    /// The mandate describes what goals its governors should try to achieve. By succinctly
    /// explaining the RToken’s purpose and what the RToken is intended to do, it provides common
    /// ground for the governors to decide upon priorities and how to weigh tradeoffs.
    ///
    /// Example Mandates:
    ///
    /// - Capital preservation first. Spending power preservation second. Permissionless
    ///     access third.
    /// - Capital preservation above all else. All revenues fund the insurance pool.
    /// - Risk-neutral pursuit of profit for token holders.
    ///     Maximize (gross revenue - payments for insurance and governance).
    /// - This RToken holds only FooCoin, to provide a trade for hedging against its
    ///     possible collapse.
    ///
    /// The mandate may also be a URI to a longer body of text
    /// @param name The name of the RToken to deploy
    /// @param symbol The symbol of the RToken to deploy
    /// @param mandate An IPFS link or direct string; describes what the RToken _should be_
    /// @param owner The address that should own the entire system, hopefully a governance contract
    /// @param params Deployment params
    /// @return The address of the newly deployed RToken.

    // effects:
    //   Deploy a proxy for Main and every component of Main
    //   Call init() on Main and every component of Main, using `params` for needed parameters
    //     While doing this, init assetRegistry with this.rsrAsset and a new rTokenAsset
    //   Set up Auth so that `owner` holds all roles and no one else has any
    function deploy(
        string memory name,
        string memory symbol,
        string calldata mandate,
        address owner,
        DeploymentParams memory params
    ) external returns (address) {
        require(owner != address(0) && owner != address(this), "invalid owner");

        // Main - Proxy
        MainP1 main = MainP1(
            address(new ERC1967Proxy(address(implementations.main), new bytes(0)))
        );

        // Components - Proxies
        IRToken rToken = IRToken(
            address(new ERC1967Proxy(address(implementations.components.rToken), new bytes(0)))
        );
        Components memory components = Components({
            stRSR: IStRSR(
                address(new ERC1967Proxy(address(implementations.components.stRSR), new bytes(0)))
            ),
            rToken: rToken,
            assetRegistry: IAssetRegistry(
                address(
                    new ERC1967Proxy(
                        address(implementations.components.assetRegistry),
                        new bytes(0)
                    )
                )
            ),
            basketHandler: IBasketHandler(
                address(
                    new ERC1967Proxy(
                        address(implementations.components.basketHandler),
                        new bytes(0)
                    )
                )
            ),
            backingManager: IBackingManager(
                address(
                    new ERC1967Proxy(
                        address(implementations.components.backingManager),
                        new bytes(0)
                    )
                )
            ),
            distributor: IDistributor(
                address(
                    new ERC1967Proxy(address(implementations.components.distributor), new bytes(0))
                )
            ),
            rsrTrader: IRevenueTrader(
                address(
                    new ERC1967Proxy(address(implementations.components.rsrTrader), new bytes(0))
                )
            ),
            rTokenTrader: IRevenueTrader(
                address(
                    new ERC1967Proxy(address(implementations.components.rTokenTrader), new bytes(0))
                )
            ),
            furnace: IFurnace(
                address(new ERC1967Proxy(address(implementations.components.furnace), new bytes(0)))
            ),
            broker: IBroker(
                address(new ERC1967Proxy(address(implementations.components.broker), new bytes(0)))
            )
        });

        // Init Main
        main.init(components, rsr, params.shortFreeze, params.longFreeze);

        // Init Backing Manager
        components.backingManager.init(
            main,
            params.tradingDelay,
            params.backingBuffer,
            params.maxTradeSlippage,
            params.minTradeVolume
        );

        // Init Basket Handler
        components.basketHandler.init(main);

        // Init Revenue Traders
        components.rsrTrader.init(main, rsr, params.maxTradeSlippage, params.minTradeVolume);
        components.rTokenTrader.init(
            main,
            IERC20(address(rToken)),
            params.maxTradeSlippage,
            params.minTradeVolume
        );

        // Init Distributor
        components.distributor.init(main, params.dist);

        // Init Furnace
        components.furnace.init(main, params.rewardPeriod, params.rewardRatio);

        components.broker.init(main, gnosis, implementations.trade, params.auctionLength);

        // Init StRSR
        {
            string memory stRSRSymbol = string(abi.encodePacked(StringLib.toLower(symbol), "RSR"));
            string memory stRSRName = string(abi.encodePacked(stRSRSymbol, " Token"));
            main.stRSR().init(
                main,
                stRSRName,
                stRSRSymbol,
                params.unstakingDelay,
                params.rewardPeriod,
                params.rewardRatio
            );
        }

        // Init RToken
        components.rToken.init(
            main,
            name,
            symbol,
            mandate,
            params.issuanceRate,
            params.scalingRedemptionRate,
            params.redemptionRateFloor
        );

        // Deploy RToken/RSR Assets
        IAsset[] memory assets = new IAsset[](2);
        assets[0] = new RTokenAsset(components.rToken, params.rTokenMaxTradeVolume);
        assets[1] = rsrAsset;

        // Init Asset Registry
        components.assetRegistry.init(main, assets);

        // Transfer Ownership
        main.grantRole(OWNER, owner);
        main.grantRole(SHORT_FREEZER, owner);
        main.grantRole(LONG_FREEZER, owner);
        main.grantRole(PAUSER, owner);
        main.renounceRole(OWNER, address(this));
        main.renounceRole(SHORT_FREEZER, address(this));
        main.renounceRole(LONG_FREEZER, address(this));
        main.renounceRole(PAUSER, address(this));

        emit RTokenCreated(main, components.rToken, components.stRSR, owner, version());
        return (address(components.rToken));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializing the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "contracts/libraries/Fixed.sol";
import "./IMain.sol";

/**
 * @title IAsset
 * @notice Supertype. Any token that interacts with our system must be wrapped in an asset,
 * whether it is used as RToken backing or not. Any token that can report a price in the UoA
 * is eligible to be an asset.
 */
interface IAsset {
    /// Can return 0, can revert
    /// Shortcut for price(false)
    /// @return {UoA/tok} The current price(), without considering fallback prices
    function strictPrice() external view returns (uint192);

    /// Can return 0
    /// Should not revert if `allowFallback` is true. Can revert if false.
    /// @param allowFallback Whether to try the fallback price in case precise price reverts
    /// @return isFallback If the price is a failover price
    /// @return {UoA/tok} The current price(), or if it's reverting, a fallback price
    function price(bool allowFallback) external view returns (bool isFallback, uint192);

    /// @return {tok} The balance of the ERC20 in whole tokens
    function bal(address account) external view returns (uint192);

    /// @return The ERC20 contract of the token with decimals() available
    function erc20() external view returns (IERC20Metadata);

    /// @return The number of decimals in the ERC20; just for gas optimization
    function erc20Decimals() external view returns (uint8);

    /// @return If the asset is an instance of ICollateral or not
    function isCollateral() external view returns (bool);

    /// @param {UoA} The max trade volume, in UoA
    function maxTradeVolume() external view returns (uint192);

    // ==== Rewards ====

    /// Get the message needed to call in order to claim rewards for holding this asset.
    /// Returns zero values if there is no reward function to call.
    /// @return _to The address to send the call to
    /// @return _calldata The calldata to send
    function getClaimCalldata() external view returns (address _to, bytes memory _calldata);

    /// The ERC20 token address that this Asset's rewards are paid in.
    /// If there are no rewards, will return a zero value.
    function rewardERC20() external view returns (IERC20 reward);
}

interface TestIAsset is IAsset {
    function chainlinkFeed() external view returns (AggregatorV3Interface);
}

/// CollateralStatus must obey a linear ordering. That is:
/// - being DISABLED is worse than being IFFY, or SOUND
/// - being IFFY is worse than being SOUND.
enum CollateralStatus {
    SOUND,
    IFFY, // When a peg is not holding or a chainlink feed is stale
    DISABLED // When the collateral has completely defaulted
}

/// Upgrade-safe maximum operator for CollateralStatus
library CollateralStatusComparator {
    /// @return Whether a is worse than b
    function worseThan(CollateralStatus a, CollateralStatus b) internal pure returns (bool) {
        return uint256(a) > uint256(b);
    }
}

/**
 * @title ICollateral
 * @notice A subtype of Asset that consists of the tokens eligible to back the RToken.
 */
interface ICollateral is IAsset {
    /// Emitted whenever the collateral status is changed
    /// @param newStatus The old CollateralStatus
    /// @param newStatus The updated CollateralStatus
    event DefaultStatusChanged(
        CollateralStatus indexed oldStatus,
        CollateralStatus indexed newStatus
    );

    /// Refresh exchange rates and update default status.
    /// The Reserve protocol calls this at least once per transaction, before relying on
    /// this collateral's prices or default status.
    function refresh() external;

    /// @return The canonical name of this collateral's target unit.
    function targetName() external view returns (bytes32);

    /// @return The status of this collateral asset. (Is it defaulting? Might it soon?)
    function status() external view returns (CollateralStatus);

    // ==== Exchange Rates ====

    /// @return {ref/tok} Quantity of whole reference units per whole collateral tokens
    function refPerTok() external view returns (uint192);

    /// @return {target/ref} Quantity of whole target units per whole reference unit in the peg
    function targetPerRef() external view returns (uint192);

    /// @return {UoA/target} The price of the target unit in UoA (usually this is {UoA/UoA} = 1)
    function pricePerTarget() external view returns (uint192);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/interfaces/IAsset.sol";
import "./IComponent.sol";

/**
 * @title IAssetRegistry
 * @notice The AssetRegistry is in charge of maintaining the ERC20 tokens eligible
 *   to be handled by the rest of the system. If an asset is in the registry, this means:
 *      1. Its ERC20 contract has been vetted
 *      2. The asset is the only asset for that ERC20
 *      3. The asset can be priced in the UoA, usually via an oracle
 */
interface IAssetRegistry is IComponent {
    /// Emitted when an asset is added to the registry
    /// @param erc20 The ERC20 contract for the asset
    /// @param asset The asset contract added to the registry
    event AssetRegistered(IERC20 indexed erc20, IAsset indexed asset);

    /// Emitted when an asset is removed from the registry
    /// @param erc20 The ERC20 contract for the asset
    /// @param asset The asset contract removed from the registry
    event AssetUnregistered(IERC20 indexed erc20, IAsset indexed asset);

    // Initialization
    function init(IMain main_, IAsset[] memory assets_) external;

    /// Fully refresh all asset state
    /// @custom:interaction
    function refresh() external;

    /// @return The corresponding asset for ERC20, or reverts if not registered
    function toAsset(IERC20 erc20) external view returns (IAsset);

    /// @return The corresponding collateral, or reverts if unregistered or not collateral
    function toColl(IERC20 erc20) external view returns (ICollateral);

    /// @return If the ERC20 is registered
    function isRegistered(IERC20 erc20) external view returns (bool);

    /// @return A list of all registered ERC20s
    function erc20s() external view returns (IERC20[] memory);

    function register(IAsset asset) external returns (bool);

    function swapRegistered(IAsset asset) external returns (bool swapped);

    function unregister(IAsset asset) external;
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IComponent.sol";
import "./ITrading.sol";

/**
 * @title IBackingManager
 * @notice The BackingManager handles changes in the ERC20 balances that back an RToken.
 *   - It computes which trades to perform, if any, and initiates these trades with the Broker.
 *   - If already capitalized, excess assets are transferred to RevenueTraders.
 *
 * `manageTokens(erc20s)` and `manageTokensSortedOrder(erc20s)` are handles for getting at the
 *   same underlying functionality. The former allows an ERC20 list in any order, while the
 *   latter requires a sorted array, and executes in O(n) rather than O(n^2) time. In the
 *   vast majority of cases we expect the the O(n^2) function to be acceptable.
 */
interface IBackingManager is IComponent, ITrading {
    event TradingDelaySet(uint48 indexed oldVal, uint48 indexed newVal);
    event BackingBufferSet(uint192 indexed oldVal, uint192 indexed newVal);

    // Initialization
    function init(
        IMain main_,
        uint48 tradingDelay_,
        uint192 backingBuffer_,
        uint192 maxTradeSlippage_,
        uint192 minTradeVolume_
    ) external;

    // Give RToken max allowance over a registered token
    /// @custom:refresher
    /// @custom:interaction
    function grantRTokenAllowance(IERC20) external;

    /// Mointain the overall backing policy; handout assets otherwise
    /// @dev Performs a uniqueness check on the erc20s list in O(n^2)
    /// @custom:interaction
    function manageTokens(IERC20[] memory erc20s) external;

    /// Mointain the overall backing policy; handout assets otherwise
    /// @dev Tokens must be in sorted order!
    /// @dev Performs a uniqueness check on the erc20s list in O(n)
    /// @custom:interaction
    function manageTokensSortedOrder(IERC20[] memory erc20s) external;
}

interface TestIBackingManager is IBackingManager, TestITrading {
    function tradingDelay() external view returns (uint48);

    function backingBuffer() external view returns (uint192);

    function setTradingDelay(uint48 val) external;

    function setBackingBuffer(uint192 val) external;
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/libraries/Fixed.sol";
import "./IAsset.sol";
import "./IComponent.sol";

/**
 * @title IBasketHandler
 * @notice The BasketHandler aims to maintain a reference basket of constant target unit amounts.
 * When a collateral token defaults, a new reference basket of equal target units is set.
 * When _all_ collateral tokens default for a target unit, only then is the basket allowed to fall
 *   in terms of target unit amounts. The basket is considered defaulted in this case.
 */
interface IBasketHandler is IComponent {
    /// Emitted when the prime basket is set
    /// @param erc20s The collateral tokens for the prime basket
    /// @param targetAmts {target/BU} A list of quantities of target unit per basket unit
    /// @param targetNames Each collateral token's targetName
    event PrimeBasketSet(IERC20[] erc20s, uint192[] targetAmts, bytes32[] targetNames);

    /// Emitted when the reference basket is set
    /// @param nonce The basket nonce
    /// @param erc20s The list of collateral tokens in the reference basket
    /// @param refAmts {ref/BU} The reference amounts of the basket collateral tokens
    /// @param disabled True when the list of erc20s + refAmts may not be correct
    event BasketSet(uint256 indexed nonce, IERC20[] erc20s, uint192[] refAmts, bool disabled);

    /// Emitted when a backup config is set for a target unit
    /// @param targetName The name of the target unit as a bytes32
    /// @param max The max number to use from `erc20s`
    /// @param erc20s The set of backup collateral tokens
    event BackupConfigSet(bytes32 indexed targetName, uint256 indexed max, IERC20[] erc20s);

    // Initialization
    function init(IMain main_) external;

    /// Set the prime basket
    /// @param erc20s The collateral tokens for the new prime basket
    /// @param targetAmts The target amounts (in) {target/BU} for the new prime basket
    ///                   required range: 1e9 values; absolute range irrelevant.
    /// @custom:governance
    function setPrimeBasket(IERC20[] memory erc20s, uint192[] memory targetAmts) external;

    /// Set the backup configuration for a given target
    /// @param targetName The name of the target as a bytes32
    /// @param max The maximum number of collateral tokens to use from this target
    ///            Required range: 1-255
    /// @param erc20s A list of ordered backup collateral tokens
    /// @custom:governance
    function setBackupConfig(
        bytes32 targetName,
        uint256 max,
        IERC20[] calldata erc20s
    ) external;

    /// Default the basket in order to schedule a basket refresh
    /// @custom:protected
    function disableBasket() external;

    /// Governance-controlled setter to cause a basket switch explicitly
    /// @custom:governance
    /// @custom:interaction
    function refreshBasket() external;

    /// @return If the BackingManager has sufficient collateral to redeem the entire RToken supply
    function fullyCollateralized() external view returns (bool);

    /// @return status The worst CollateralStatus of all collateral in the basket
    function status() external view returns (CollateralStatus status);

    /// @return {tok/BU} The whole token quantity of token in the reference basket
    /// Returns 0 if erc20 is not registered, disabled, or not in the basket
    /// Returns FIX_MAX (in lieu of +infinity) if Collateral.refPerTok() is 0.
    /// Otherwise, returns (token's basket.refAmts / token's Collateral.refPerTok())
    function quantity(IERC20 erc20) external view returns (uint192);

    /// @param amount {BU}
    /// @return erc20s The addresses of the ERC20 tokens in the reference basket
    /// @return quantities {qTok} The quantity of each ERC20 token to issue `amount` baskets
    function quote(uint192 amount, RoundingMode rounding)
        external
        view
        returns (address[] memory erc20s, uint256[] memory quantities);

    /// @return baskets {BU} The quantity of complete baskets at an address. A balance for BUs
    function basketsHeldBy(address account) external view returns (uint192 baskets);

    /// @param allowFallback Whether to fail over to the fallback price or not
    /// @return isFallback If any fallback prices were used
    /// @return p {UoA/BU} The protocol's best guess at what a BU would be priced at in UoA
    function price(bool allowFallback) external view returns (bool isFallback, uint192 p);

    /// @return The basket nonce, a monotonically increasing unique identifier
    function nonce() external view returns (uint48);

    /// @return timestamp The timestamp at which the basket was last set
    function timestamp() external view returns (uint48);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.9;

import "./IAsset.sol";
import "./IComponent.sol";
import "./IGnosis.sol";
import "./ITrade.sol";

/// The data format that describes a request for trade with the Broker
struct TradeRequest {
    IAsset sell;
    IAsset buy;
    uint256 sellAmount; // {qSellTok}
    uint256 minBuyAmount; // {qBuyTok}
}

/**
 * @title IBroker
 * @notice The Broker deploys oneshot Trade contracts for Traders and monitors
 *   the continued proper functioning of trading platforms.
 */
interface IBroker is IComponent {
    event AuctionLengthSet(uint48 indexed oldVal, uint48 indexed newVal);
    event DisabledSet(bool indexed prevVal, bool indexed newVal);

    // Initialization
    function init(
        IMain main_,
        IGnosis gnosis_,
        ITrade tradeImplementation_,
        uint48 auctionLength_
    ) external;

    /// Request a trade from the broker
    /// @dev Requires setting an allowance in advance
    /// @custom:interaction
    function openTrade(TradeRequest memory req) external returns (ITrade);

    /// Only callable by one of the trading contracts the broker deploys
    function reportViolation() external;

    function disabled() external view returns (bool);
}

interface TestIBroker is IBroker {
    function gnosis() external view returns (IGnosis);

    function auctionLength() external view returns (uint48);

    function setAuctionLength(uint48 newAuctionLength) external;

    function setDisabled(bool disabled_) external;
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./IAsset.sol";
import "./IDistributor.sol";
import "./IGnosis.sol";
import "./IMain.sol";
import "./IRToken.sol";
import "./IStRSR.sol";
import "./ITrade.sol";
import "./IVersioned.sol";

/**
 * @title DeploymentParams
 * @notice The set of protocol params needed to configure a new system deployment.
 * meaning that after deployment there is freedom to allow parametrizations to deviate.
 */
struct DeploymentParams {
    // === Revenue sharing ===
    RevenueShare dist; // revenue sharing splits between RToken and RSR
    //
    // === Trade sizing ===
    uint192 minTradeVolume; // {UoA}
    uint192 rTokenMaxTradeVolume; // {UoA}
    //
    // === Freezing ===
    uint48 shortFreeze; // {s} how long an initial freeze lasts
    uint48 longFreeze; // {s} how long each freeze extension lasts
    //
    // === Rewards (Furnace + StRSR) ===
    uint192 rewardRatio; // the fraction of available revenues that stRSR holders get each PayPeriod
    uint48 rewardPeriod; // {s} the atomic unit of rewards, determines # of exponential rounds
    //
    // === StRSR ===
    uint48 unstakingDelay; // {s} the "thawing time" of staked RSR before withdrawal
    //
    // === BackingManager ===
    uint48 tradingDelay; // {s} how long to wait until starting auctions after switching basket
    uint48 auctionLength; // {s} the length of an auction
    uint192 backingBuffer; // {1} how much extra backing collateral to keep
    uint192 maxTradeSlippage; // {1} max slippage acceptable in a trade
    //
    // === RToken ===
    uint192 issuanceRate; // {1/block} number of RToken to issue per block / (RToken value)
    uint192 scalingRedemptionRate; // {1/hour} max fraction of supply that can be redeemed hourly
    uint256 redemptionRateFloor; // {qRTok/hour} the lowest possible hourly redemption limit
}

/**
 * @title Implementations
 * @notice The set of implementation contracts to be used for proxies in the Deployer
 */
struct Implementations {
    IMain main;
    Components components;
    ITrade trade;
}

/**
 * @title IDeployer
 * @notice Factory contract for an RToken system instance
 */
interface IDeployer is IVersioned {
    /// Emitted when a new RToken and accompanying system is deployed
    /// @param main The address of `Main`
    /// @param rToken The address of the RToken ERC20
    /// @param stRSR The address of the StRSR ERC20 staking pool/token
    /// @param owner The owner of the newly deployed system
    /// @param version The semantic versioning version string (see: https://semver.org)
    event RTokenCreated(
        IMain indexed main,
        IRToken indexed rToken,
        IStRSR stRSR,
        address indexed owner,
        string version
    );

    //

    /// Deploys an instance of the entire system
    /// @param name The name of the RToken to deploy
    /// @param symbol The symbol of the RToken to deploy
    /// @param mandate An IPFS link or direct string; describes what the RToken _should be_
    /// @param owner The address that should own the entire system, hopefully a governance contract
    /// @param params Deployment params
    /// @return The address of the newly deployed Main instance.
    function deploy(
        string calldata name,
        string calldata symbol,
        string calldata mandate,
        address owner,
        DeploymentParams calldata params
    ) external returns (address);
}

interface TestIDeployer is IDeployer {
    /// A top-level ENS domain that should always point to the latest Deployer instance
    // solhint-disable-next-line func-name-mixedcase
    function ENS() external view returns (string memory);

    function rsr() external view returns (IERC20Metadata);

    function gnosis() external view returns (IGnosis);

    function rsrAsset() external view returns (IAsset);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IComponent.sol";

struct RevenueShare {
    uint16 rTokenDist; // {revShare} A value between [0, 10,000]
    uint16 rsrDist; // {revShare} A value between [0, 10,000]
}

/// Assumes no more than 1024 independent distributions.
struct RevenueTotals {
    uint24 rTokenTotal; // {revShare}
    uint24 rsrTotal; // {revShare}
}

/**
 * @title IDistributor
 * @notice The Distributor Component maintains a revenue distribution table that dictates
 *   how to divide revenue across the Furnace, StRSR, and any other destinations.
 */
interface IDistributor is IComponent {
    /// Emitted when a distribution is set
    /// @param dest The address set to receive the distribution
    /// @param rTokenDist The distribution of RToken that should go to `dest`
    /// @param rsrDist The distribution of RSR that should go to `dest`
    event DistributionSet(address dest, uint16 rTokenDist, uint16 rsrDist);

    /// Emitted when revenue is distributed
    /// @param erc20 The token being distributed, either RSR or the RToken itself
    /// @param source The address providing the revenue
    /// @param amount The amount of the revenue
    event RevenueDistributed(IERC20 indexed erc20, address indexed source, uint256 indexed amount);

    // Initialization
    function init(IMain main_, RevenueShare memory dist) external;

    /// @custom:governance
    function setDistribution(address dest, RevenueShare memory share) external;

    /// Distribute the `erc20` token across all revenue destinations
    /// @custom:interaction
    function distribute(
        IERC20 erc20,
        address from,
        uint256 amount
    ) external;

    /// @return revTotals The total of all  destinations
    function totals() external view returns (RevenueTotals memory revTotals);
}

interface TestIDistributor is IDistributor {
    // solhint-disable-next-line func-name-mixedcase
    function FURNACE() external view returns (address);

    // solhint-disable-next-line func-name-mixedcase
    function ST_RSR() external view returns (address);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.9;

import "contracts/libraries/Fixed.sol";
import "./IComponent.sol";

/**
 * @title IFurnace
 * @notice A helper contract to burn RTokens slowly and permisionlessly.
 */
interface IFurnace is IComponent {
    // Initialization
    function init(
        IMain main_,
        uint48 period_,
        uint192 ratio_
    ) external;

    /// Emitted when the melting period is changed
    /// @param oldPeriod The old period
    /// @param newPeriod The new period
    event PeriodSet(uint48 indexed oldPeriod, uint48 indexed newPeriod);

    function period() external view returns (uint48);

    /// @custom:governance
    function setPeriod(uint48) external;

    /// Emitted when the melting ratio is changed
    /// @param oldRatio The old ratio
    /// @param newRatio The new ratio
    event RatioSet(uint192 indexed oldRatio, uint192 indexed newRatio);

    function ratio() external view returns (uint192);

    ///    Needed value range: [0, 1], granularity 1e-9
    /// @custom:governance
    function setRatio(uint192) external;

    /// Performs any RToken melting that has vested since the last payout.
    /// @custom:refresher
    function melt() external;
}

interface TestIFurnace is IFurnace {
    function lastPayout() external view returns (uint256);

    function lastPayoutBal() external view returns (uint256);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.9;

import "./IComponent.sol";
import "./ITrading.sol";

/**
 * @title IRevenueTrader
 * @notice The RevenueTrader is an extension of the trading mixin that trades all
 *   assets at its address for a single target asset. There are two runtime instances
 *   of the RevenueTrader, 1 for RToken and 1 for RSR.
 */
interface IRevenueTrader is IComponent, ITrading {
    // Initialization
    function init(
        IMain main_,
        IERC20 tokenToBuy_,
        uint192 maxTradeSlippage_,
        uint192 minTradeVolume_
    ) external;

    /// Processes a single token; unpermissioned
    /// @dev Intended to be used with multicall
    /// @custom:interaction
    function manageToken(IERC20 sell) external;
}

// solhint-disable-next-line no-empty-blocks
interface TestIRevenueTrader is IRevenueTrader, TestITrading {
    function tokenToBuy() external view returns (IERC20);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
// solhint-disable-next-line max-line-length
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";
import "contracts/libraries/Fixed.sol";
import "./IAsset.sol";
import "./IComponent.sol";
import "./IMain.sol";
import "./IRewardable.sol";

/**
 * @title IRToken
 * @notice An RToken is an ERC20 that is permissionlessly issuable/redeemable and tracks an
 *   exchange rate against a single unit: baskets, or {BU} in our type notation.
 */
interface IRToken is IRewardable, IERC20MetadataUpgradeable, IERC20PermitUpgradeable {
    /// Emitted when issuance is started, at the point collateral is taken in
    /// @param issuer The account performing the issuance
    /// @param index The index off the issuance in the issuer's queue
    /// @param amount The quantity of RToken being issued
    /// @param baskets The basket unit-equivalent of the collateral deposits
    /// @param erc20s The ERC20 collateral tokens corresponding to the quantities
    /// @param quantities The quantities of tokens paid with
    /// @param blockAvailableAt The (continuous) block at which the issuance vests
    event IssuanceStarted(
        address indexed issuer,
        uint256 indexed index,
        uint256 indexed amount,
        uint192 baskets,
        address[] erc20s,
        uint256[] quantities,
        uint192 blockAvailableAt
    );

    /// Emitted when an RToken issuance is canceled, such as during a default
    /// @param issuer The account of the issuer
    /// @param firstId The first of the cancelled issuances in the issuer's queue
    /// @param endId The index _after_ the last of the cancelled issuances in the issuer's queue
    /// @param amount {qRTok} The amount of RTokens canceled
    /// That is, id was cancelled iff firstId <= id < endId
    event IssuancesCanceled(
        address indexed issuer,
        uint256 indexed firstId,
        uint256 indexed endId,
        uint256 amount
    );

    /// Emitted when an RToken issuance is completed successfully
    /// @param issuer The account of the issuer
    /// @param firstId The first of the completed issuances in the issuer's queue
    /// @param endId The id directly after the last of the completed issuances
    /// @param amount {qRTok} The amount of RTokens canceled
    event IssuancesCompleted(
        address indexed issuer,
        uint256 indexed firstId,
        uint256 indexed endId,
        uint256 amount
    );

    /// Emitted when an issuance of RToken occurs, whether it occurs via slow minting or not
    /// @param issuer The address of the account issuing RTokens
    /// @param amount The quantity of RToken being issued
    /// @param baskets The corresponding number of baskets
    event Issuance(address indexed issuer, uint256 indexed amount, uint192 indexed baskets);

    /// Emitted when a redemption of RToken occurs
    /// @param redeemer The address of the account redeeeming RTokens
    /// @param amount The quantity of RToken being redeemed
    /// @param baskets The corresponding number of baskets
    /// @param amount {qRTok} The amount of RTokens canceled
    event Redemption(address indexed redeemer, uint256 indexed amount, uint192 baskets);

    /// Emitted when the number of baskets needed changes
    /// @param oldBasketsNeeded Previous number of baskets units needed
    /// @param newBasketsNeeded New number of basket units needed
    event BasketsNeededChanged(uint192 oldBasketsNeeded, uint192 newBasketsNeeded);

    /// Emitted when RToken is melted, i.e the RToken supply is decreased but basketsNeeded is not
    /// @param amount {qRTok}
    event Melted(uint256 amount);

    /// Emitted when the IssuanceRate is set
    event IssuanceRateSet(uint192 indexed oldVal, uint192 indexed newVal);

    /// Emitted when the redemption battery max charge is set
    event ScalingRedemptionRateSet(uint192 indexed oldVal, uint192 indexed newVal);

    /// Emitted when the dust supply is set
    event RedemptionRateFloorSet(uint256 indexed oldVal, uint256 indexed newVal);

    // Initialization
    function init(
        IMain main_,
        string memory name_,
        string memory symbol_,
        string memory mandate_,
        uint192 issuanceRate_,
        uint192 redemptionBattery_,
        uint256 redemptionVirtualSupply_
    ) external;

    /// Begin a time-delayed issuance of RToken for basket collateral
    /// @param amount {qRTok} The quantity of RToken to issue
    /// @custom:interaction
    function issue(uint256 amount) external;

    /// Cancels a vesting slow issuance of _msgSender
    /// If earliest == true, cancel id if id < endId
    /// If earliest == false, cancel id if endId <= id
    /// @param endId One edge of the issuance range to cancel
    /// @param earliest If true, cancel earliest issuances; else, cancel latest issuances
    /// @custom:interaction
    function cancel(uint256 endId, bool earliest) external;

    /// Completes vested slow issuances for the account, up to endId.
    /// @param account The address of the account to vest issuances for
    /// @custom:interaction
    function vest(address account, uint256 endId) external;

    /// Redeem RToken for basket collateral
    /// @param amount {qRTok} The quantity {qRToken} of RToken to redeem
    /// @custom:interaction
    function redeem(uint256 amount) external;

    /// Mints a quantity of RToken to the `recipient`, callable only by the BackingManager
    /// @param recipient The recipient of the newly minted RToken
    /// @param amount {qRTok} The amount to be minted
    /// @custom:protected
    function mint(address recipient, uint256 amount) external;

    /// Melt a quantity of RToken from the caller's account
    /// @param amount {qRTok} The amount to be melted
    function melt(uint256 amount) external;

    /// Set the number of baskets needed directly, callable only by the BackingManager
    /// @param basketsNeeded {BU} The number of baskets to target
    ///                      needed range: pretty interesting
    /// @custom:protected
    function setBasketsNeeded(uint192 basketsNeeded) external;

    /// @return {BU} How many baskets are being targeted
    function basketsNeeded() external view returns (uint192);

    /// @return {qRTok} The maximum redemption that can be performed in the current block
    function redemptionLimit() external view returns (uint256);
}

interface TestIRToken is IRToken {
    /// Set the issuance rate as a % of RToken supply
    function setIssuanceRate(uint192) external;

    /// @return {1} The issuance rate as a percentage of the RToken supply
    function issuanceRate() external view returns (uint192);

    /// Set the fraction of the RToken supply that can be reedemed at once
    function setScalingRedemptionRate(uint192 val) external;

    /// @return {1/hour} The maximum fraction of the RToken supply that can be redeemed at once
    function scalingRedemptionRate() external view returns (uint192);

    /// Set the RToken supply at which full redemptions become enabled
    function setRedemptionRateFloor(uint256 val) external;

    /// @return {qRTok/hour} The lowest possible hourly redemption limit
    function redemptionRateFloor() external view returns (uint256);

    function increaseAllowance(address, uint256) external returns (bool);

    function decreaseAllowance(address, uint256) external returns (bool);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
// solhint-disable-next-line max-line-length
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";
import "contracts/libraries/Fixed.sol";
import "./IComponent.sol";
import "./IMain.sol";

/**
 * @title IStRSR
 * @notice An ERC20 token representing shares of the RSR insurance pool.
 *
 * StRSR permits the BackingManager to take RSR in times of need. In return, the BackingManager
 * benefits the StRSR pool with RSR rewards purchased with a portion of its revenue.
 *
 * In the absence of collateral default or losses due to slippage, StRSR should have a
 * monotonically increasing exchange rate with respect to RSR, meaning that over time
 * StRSR is redeemable for more RSR. It is non-rebasing.
 */
interface IStRSR is IERC20MetadataUpgradeable, IERC20PermitUpgradeable, IComponent {
    /// Emitted when RSR is staked
    /// @param era The era at time of staking
    /// @param staker The address of the staker
    /// @param rsrAmount {qRSR} How much RSR was staked
    /// @param stRSRAmount {qStRSR} How much stRSR was minted by this staking
    event Staked(
        uint256 indexed era,
        address indexed staker,
        uint256 rsrAmount,
        uint256 indexed stRSRAmount
    );

    /// Emitted when an unstaking is started
    /// @param draftId The id of the draft.
    /// @param draftEra The era of the draft.
    /// @param staker The address of the unstaker
    ///   The triple (staker, draftEra, draftId) is a unique ID
    /// @param rsrAmount {qRSR} How much RSR this unstaking will be worth, absent seizures
    /// @param stRSRAmount {qStRSR} How much stRSR was burned by this unstaking
    event UnstakingStarted(
        uint256 indexed draftId,
        uint256 indexed draftEra,
        address indexed staker,
        uint256 rsrAmount,
        uint256 stRSRAmount,
        uint256 availableAt
    );

    /// Emitted when RSR is unstaked
    /// @param firstId The beginning of the range of draft IDs withdrawn in this transaction
    /// @param endId The end of range of draft IDs withdrawn in this transaction
    ///   (ID i was withdrawn if firstId <= i < endId)
    /// @param draftEra The era of the draft.
    ///   The triple (staker, draftEra, id) is a unique ID among drafts
    /// @param staker The address of the unstaker

    /// @param rsrAmount {qRSR} How much RSR this unstaking was worth
    event UnstakingCompleted(
        uint256 indexed firstId,
        uint256 indexed endId,
        uint256 draftEra,
        address indexed staker,
        uint256 rsrAmount
    );

    /// Emitted whenever the exchange rate changes
    event ExchangeRateSet(uint192 indexed oldVal, uint192 indexed newVal);

    /// Emitted whenever RSR are paids out
    event RewardsPaid(uint256 indexed rsrAmt);

    /// Emitted if all the RSR in the staking pool is seized and all balances are reset to zero.
    event AllBalancesReset(uint256 indexed newEra);
    /// Emitted if all the RSR in the unstakin pool is seized, and all ongoing unstaking is voided.
    event AllUnstakingReset(uint256 indexed newEra);

    event UnstakingDelaySet(uint48 indexed oldVal, uint48 indexed newVal);
    event RewardPeriodSet(uint48 indexed oldVal, uint48 indexed newVal);
    event RewardRatioSet(uint192 indexed oldVal, uint192 indexed newVal);

    // Initialization
    function init(
        IMain main_,
        string memory name_,
        string memory symbol_,
        uint48 unstakingDelay_,
        uint48 rewardPeriod_,
        uint192 rewardRatio_
    ) external;

    /// Gather and payout rewards from rsrTrader
    /// @custom:interaction
    function payoutRewards() external;

    /// Stakes an RSR `amount` on the corresponding RToken to earn yield and insure the system
    /// @param amount {qRSR}
    /// @custom:interaction
    function stake(uint256 amount) external;

    /// Begins a delayed unstaking for `amount` stRSR
    /// @param amount {qStRSR}
    /// @custom:interaction
    function unstake(uint256 amount) external;

    /// Complete delayed unstaking for the account, up to (but not including!) `endId`
    /// @custom:interaction
    function withdraw(address account, uint256 endId) external;

    /// Seize RSR, only callable by main.backingManager()
    /// @custom:protected
    function seizeRSR(uint256 amount) external;

    /// Return the maximum valid value of endId such that withdraw(endId) should immediately work
    function endIdForWithdraw(address account) external view returns (uint256 endId);

    /// @return {qRSR/qStRSR} The exchange rate between RSR and StRSR
    function exchangeRate() external view returns (uint192);
}

interface TestIStRSR is IStRSR {
    function rewardPeriod() external view returns (uint48);

    function setRewardPeriod(uint48) external;

    function rewardRatio() external view returns (uint192);

    function setRewardRatio(uint192) external;

    function unstakingDelay() external view returns (uint48);

    function setUnstakingDelay(uint48) external;

    function setName(string calldata) external;

    function setSymbol(string calldata) external;

    function increaseAllowance(address, uint256) external returns (bool);

    function decreaseAllowance(address, uint256) external returns (bool);

    /// @return {qStRSR/qRSR} The exchange rate between StRSR and RSR
    function exchangeRate() external view returns (uint192);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.9;

import "contracts/interfaces/IVersioned.sol";

/**
 * @title Versioned
 * @notice A mix-in to track semantic versioning uniformly across contracts.
 */
abstract contract Versioned is IVersioned {
    function version() public pure virtual override returns (string memory) {
        return "1.2.0";
    }
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "contracts/interfaces/IAsset.sol";
import "./OracleLib.sol";

contract Asset is IAsset {
    using OracleLib for AggregatorV3Interface;

    AggregatorV3Interface public immutable chainlinkFeed;

    IERC20Metadata public immutable erc20;

    IERC20 public immutable override rewardERC20;

    uint8 public immutable erc20Decimals;

    uint192 public immutable override maxTradeVolume; // {UoA}

    uint192 public immutable fallbackPrice; // {UoA}

    uint48 public immutable oracleTimeout; // {s} Seconds that an oracle value is considered valid

    /// @param chainlinkFeed_ Feed units: {UoA/tok}
    /// @param maxTradeVolume_ {UoA} The max trade volume, in UoA
    /// @param oracleTimeout_ {s} The number of seconds until a oracle value becomes invalid
    constructor(
        uint192 fallbackPrice_,
        AggregatorV3Interface chainlinkFeed_,
        IERC20Metadata erc20_,
        IERC20Metadata rewardERC20_,
        uint192 maxTradeVolume_,
        uint48 oracleTimeout_
    ) {
        require(fallbackPrice_ > 0, "fallback price zero");
        require(address(chainlinkFeed_) != address(0), "missing chainlink feed");
        require(address(erc20_) != address(0), "missing erc20");
        require(maxTradeVolume_ > 0, "invalid max trade volume");
        require(oracleTimeout_ > 0, "oracleTimeout zero");
        fallbackPrice = fallbackPrice_;
        chainlinkFeed = chainlinkFeed_;
        erc20 = erc20_;
        erc20Decimals = erc20.decimals();
        rewardERC20 = rewardERC20_;
        maxTradeVolume = maxTradeVolume_;
        oracleTimeout = oracleTimeout_;
    }

    /// Can return 0, can revert
    /// @return {UoA/tok} The current price()
    function strictPrice() public view virtual returns (uint192) {
        return chainlinkFeed.price(oracleTimeout);
    }

    /// Can return 0
    /// Cannot revert if `allowFallback` is true. Can revert if false.
    /// @param allowFallback Whether to try the fallback price in case precise price reverts
    /// @return isFallback If the price is a allowFallback price
    /// @return {UoA/tok} The current price, or if it's reverting, a fallback price
    function price(bool allowFallback) public view virtual returns (bool isFallback, uint192) {
        try this.strictPrice() returns (uint192 p) {
            return (false, p);
        } catch {
            require(allowFallback, "price reverted without failover enabled");
            return (true, fallbackPrice);
        }
    }

    /// @return {tok} The balance of the ERC20 in whole tokens
    function bal(address account) external view returns (uint192) {
        return shiftl_toFix(erc20.balanceOf(account), -int8(erc20Decimals));
    }

    /// @return If the asset is an instance of ICollateral or not
    function isCollateral() external pure virtual returns (bool) {
        return false;
    }

    // solhint-disable no-empty-blocks

    /// (address, calldata) to call in order to claim rewards for holding this asset
    /// @dev The default impl returns zero values, implying that no reward function exists.
    function getClaimCalldata() external view virtual returns (address _to, bytes memory _cd) {}

    // solhint-enable no-empty-blocks
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.9;

import "contracts/plugins/assets/Asset.sol";
import "contracts/interfaces/IMain.sol";
import "contracts/interfaces/IRToken.sol";
import "contracts/p1/mixins/RecollateralizationLib.sol";

/// Once an RToken gets large eonugh to get a price feed, replacing this asset with
/// a simpler one will do wonders for gas usage
contract RTokenAsset is IAsset {
    using FixLib for uint192;
    using OracleLib for AggregatorV3Interface;

    // Component addresses are not mutable in protocol, so it's safe to cache these
    IBasketHandler public immutable basketHandler;
    IAssetRegistry public immutable assetRegistry;
    IBackingManager public immutable backingManager;

    IERC20Metadata public immutable erc20;

    IERC20 public immutable rewardERC20;

    uint8 public immutable erc20Decimals;

    uint192 public immutable override maxTradeVolume; // {UoA}

    /// @param maxTradeVolume_ {UoA} The max trade volume, in UoA
    constructor(IRToken erc20_, uint192 maxTradeVolume_) {
        require(address(erc20_) != address(0), "missing erc20");
        require(maxTradeVolume_ > 0, "invalid max trade volume");

        IMain main = erc20_.main();
        basketHandler = main.basketHandler();
        assetRegistry = main.assetRegistry();
        backingManager = main.backingManager();

        erc20 = IERC20Metadata(address(erc20_));
        erc20Decimals = erc20_.decimals();
        rewardERC20 = IERC20(address(0));
        maxTradeVolume = maxTradeVolume_;
    }

    /// Can return 0 and revert
    /// @return {UoA/tok} An estimate of the current RToken redemption price
    function strictPrice() public view virtual returns (uint192) {
        (bool isFallback, uint192 price_) = price(false);
        require(!isFallback, "RTokenAsset: need fallback prices");
        return price_;
    }

    /// Can return 0
    /// Should not revert if `allowFallback` is true. Can revert if false.
    /// @param allowFallback Whether to try the fallback price in case precise price reverts
    /// @return If the price is a failover price
    /// @return {UoA/tok} The current price(), or if it's reverting, a fallback price
    function price(bool allowFallback) public view virtual returns (bool, uint192) {
        // {UoA/BU}
        (bool isFallback_, uint192 price_) = basketHandler.price(allowFallback);

        // Here we take advantage of the fact that we know RToken has 18 decimals
        // to convert between uint256 an uint192. Fits due to assumed max totalSupply.
        uint192 supply = _safeWrap(IRToken(address(erc20)).totalSupply());

        if (supply == 0) return (isFallback_, price_);

        uint192 basketsBottom; // {BU}
        if (basketHandler.fullyCollateralized()) {
            basketsBottom = IRToken(address(erc20)).basketsNeeded();
        } else {
            // Note: Extremely this is extremely wasteful in terms of gas. This only exists so
            // there is _some_ asset to represent the RToken itself when it is deployed, in
            // the absence of an external price feed. Any RToken that gets reasonably big
            // should switch over to an asset with a price feed.

            IMain main = backingManager.main();
            ComponentCache memory components = ComponentCache({
                trader: backingManager,
                bh: main.basketHandler(),
                reg: main.assetRegistry(),
                stRSR: main.stRSR(),
                rsr: main.rsr(),
                rToken: main.rToken()
            });
            TradingRules memory rules = TradingRules({
                minTradeVolume: backingManager.minTradeVolume(),
                maxTradeSlippage: backingManager.maxTradeSlippage()
            });

            // will exclude UoA value from RToken balances at BackingManager
            RecollateralizationLibP1.BasketRange memory range = RecollateralizationLibP1
                .basketRange(components, rules, assetRegistry.erc20s());
            basketsBottom = range.bottom;
        }

        // {UoA/tok} = {BU} * {UoA/BU} / {tok}
        return (isFallback_, basketsBottom.mulDiv(price_, supply));
    }

    /// @return {tok} The balance of the ERC20 in whole tokens
    function bal(address account) external view returns (uint192) {
        // The RToken has 18 decimals, so there's no reason to waste gas here doing a shiftl_toFix
        // return shiftl_toFix(erc20.balanceOf(account), -int8(erc20Decimals));
        return _safeWrap(erc20.balanceOf(account));
    }

    /// @return If the asset is an instance of ICollateral or not
    function isCollateral() external pure virtual returns (bool) {
        return false;
    }

    // solhint-disable no-empty-blocks

    /// (address, calldata) to call in order to claim rewards for holding this asset
    /// @dev The default impl returns zero values, implying that no reward function exists.
    function getClaimCalldata() external view virtual returns (address _to, bytes memory _cd) {}

    // solhint-enable no-empty-blocks
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/interfaces/IMain.sol";
import "contracts/mixins/ComponentRegistry.sol";
import "contracts/mixins/Auth.sol";
import "contracts/mixins/Versioned.sol";

/**
 * @title Main
 * @notice The center of the system around which Components orbit.
 */
// solhint-disable max-states-count
contract MainP1 is Versioned, Initializable, Auth, ComponentRegistry, UUPSUpgradeable, IMain {
    IERC20 public rsr;

    /// @custom:oz-upgrades-unsafe-allow constructor
    // solhint-disable-next-line no-empty-blocks
    constructor() initializer {}

    /// Initializer
    function init(
        Components memory components,
        IERC20 rsr_,
        uint48 shortFreeze_,
        uint48 longFreeze_
    ) public virtual initializer {
        require(address(rsr_) != address(0), "invalid RSR address");
        __Auth_init(shortFreeze_, longFreeze_);
        __ComponentRegistry_init(components);
        __UUPSUpgradeable_init();

        rsr = rsr_;
        emit MainInitialized();
    }

    /// @custom:refresher
    /// @custom:interaction CEI
    function poke() external {
        // == Refresher ==
        assetRegistry.refresh();

        // == CE block ==
        require(!pausedOrFrozen(), "paused or frozen");
        furnace.melt();
        stRSR.payoutRewards();
    }

    function hasRole(bytes32 role, address account)
        public
        view
        override(IAccessControlUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.hasRole(role, account);
    }

    // === Upgradeability ===
    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(OWNER) {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.9;

// From https://gist.github.com/ottodevs/c43d0a8b4b891ac2da675f825b1d1dbf
library StringLib {
    /// Convert any basic uppercase chars (A-Z) in str to lowercase
    /// @dev This is safe for general Unicode strings in UTF-8, because every byte representing a
    /// multibyte codepoint has its high bit set to 1, and this only modifies bytes with a high bit
    /// set to 0. As a result, this function will _not_ transform any multi-byte capital letters,
    /// like Ö, À, or Æ, to lowercase. That's much harder, and this is sufficient for our purposes.
    function toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                // So we add 32 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
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

// SPDX-License-Identifier: BlueOak-1.0.0
// solhint-disable func-name-mixedcase func-visibility
pragma solidity ^0.8.9;

/// @title FixedPoint, a fixed-point arithmetic library defining the custom type uint192
/// @author Matt Elder <[email protected]> and the Reserve Team <https://reserve.org>

/** The logical type `uint192 ` is a 192 bit value, representing an 18-decimal Fixed-point
    fractional value.  This is what's described in the Solidity documentation as
    "fixed192x18" -- a value represented by 192 bits, that makes 18 digits available to
    the right of the decimal point.

    The range of values that uint192 can represent is about [-1.7e20, 1.7e20].
    Unless a function explicitly says otherwise, it will fail on overflow.
    To be clear, the following should hold:
    toFix(0) == 0
    toFix(1) == 1e18
*/

// Analysis notes:
//   Every function should revert iff its result is out of bounds.
//   Unless otherwise noted, when a rounding mode is given, that mode is applied to
//     a single division that may happen as the last step in the computation.
//   Unless otherwise noted, when a rounding mode is *not* given but is needed, it's FLOOR.
//   For each, we comment:
//   - @return is the value expressed  in "value space", where uint192(1e18) "is" 1.0
//   - as-ints: is the value expressed in "implementation space", where uint192(1e18) "is" 1e18
//   The "@return" expression is suitable for actually using the library
//   The "as-ints" expression is suitable for testing

// A uint value passed to this library was out of bounds for uint192 operations
error UIntOutOfBounds();

// Used by P1 implementation for easier casting
uint256 constant FIX_ONE_256 = 1e18;
uint8 constant FIX_DECIMALS = 18;

// If a particular uint192 is represented by the uint192 n, then the uint192 represents the
// value n/FIX_SCALE.
uint64 constant FIX_SCALE = 1e18;

// FIX_SCALE Squared:
uint128 constant FIX_SCALE_SQ = 1e36;

// The largest integer that can be converted to uint192 .
// This is a bit bigger than 3.1e39
uint192 constant FIX_MAX_INT = type(uint192).max / FIX_SCALE;

uint192 constant FIX_ZERO = 0; // The uint192 representation of zero.
uint192 constant FIX_ONE = FIX_SCALE; // The uint192 representation of one.
uint192 constant FIX_MAX = type(uint192).max; // The largest uint192. (Not an integer!)
uint192 constant FIX_MIN = 0; // The smallest uint192.

/// An enum that describes a rounding approach for converting to ints
enum RoundingMode {
    FLOOR, // Round towards zero
    ROUND, // Round to the nearest int
    CEIL // Round away from zero
}

RoundingMode constant FLOOR = RoundingMode.FLOOR;
RoundingMode constant ROUND = RoundingMode.ROUND;
RoundingMode constant CEIL = RoundingMode.CEIL;

/* @dev Solidity 0.8.x only allows you to change one of type or size per type conversion.
   Thus, all the tedious-looking double conversions like uint256(uint256 (foo))
   See: https://docs.soliditylang.org/en/v0.8.9/080-breaking-changes.html#new-restrictions
 */

/// Explicitly convert a uint256 to a uint192. Revert if the input is out of bounds.
function _safeWrap(uint256 x) pure returns (uint192) {
    if (FIX_MAX < x) revert UIntOutOfBounds();
    return uint192(x);
}

/// Convert a uint to its Fix representation.
/// @return x
// as-ints: x * 1e18
function toFix(uint256 x) pure returns (uint192) {
    return _safeWrap(x * FIX_SCALE);
}

/// Convert a uint to its fixed-point representation, and left-shift its value `shiftLeft`
/// decimal digits.
/// @return x * 10**shiftLeft
// as-ints: x * 10**(shiftLeft + 18)
function shiftl_toFix(uint256 x, int8 shiftLeft) pure returns (uint192) {
    return shiftl_toFix(x, shiftLeft, FLOOR);
}

/// @return x * 10**shiftLeft
// as-ints: x * 10**(shiftLeft + 18)
function shiftl_toFix(
    uint256 x,
    int8 shiftLeft,
    RoundingMode rounding
) pure returns (uint192) {
    shiftLeft += 18;

    if (x == 0) return 0;
    if (shiftLeft <= -77) return (rounding == CEIL ? 1 : 0); // 0 < uint.max / 10**77 < 0.5
    if (57 <= shiftLeft) revert UIntOutOfBounds(); // 10**56 < FIX_MAX < 10**57

    uint256 coeff = 10**abs(shiftLeft);
    uint256 shifted = (shiftLeft >= 0) ? x * coeff : _divrnd(x, coeff, rounding);

    return _safeWrap(shifted);
}

/// Divide a uint by a uint192, yielding a uint192
/// This may also fail if the result is MIN_uint192! not fixing this for optimization's sake.
/// @return x / y
// as-ints: x * 1e36 / y
function divFix(uint256 x, uint192 y) pure returns (uint192) {
    // If we didn't have to worry about overflow, we'd just do `return x * 1e36 / _y`
    // If it's safe to do this operation the easy way, do it:
    if (x < uint256(type(uint256).max / FIX_SCALE_SQ)) {
        return _safeWrap(uint256(x * FIX_SCALE_SQ) / y);
    } else {
        return _safeWrap(mulDiv256(x, FIX_SCALE_SQ, y));
    }
}

/// Divide a uint by a uint, yielding a  uint192
/// @return x / y
// as-ints: x * 1e18 / y
function divuu(uint256 x, uint256 y) pure returns (uint192) {
    return _safeWrap(mulDiv256(FIX_SCALE, x, y));
}

/// @return min(x,y)
// as-ints: min(x,y)
function fixMin(uint192 x, uint192 y) pure returns (uint192) {
    return x < y ? x : y;
}

/// @return max(x,y)
// as-ints: max(x,y)
function fixMax(uint192 x, uint192 y) pure returns (uint192) {
    return x > y ? x : y;
}

/// @return absoluteValue(x,y)
// as-ints: absoluteValue(x,y)
function abs(int256 x) pure returns (uint256) {
    return x < 0 ? uint256(-x) : uint256(x);
}

/// Divide two uints, returning a uint, using rounding mode `rounding`.
/// @return numerator / divisor
// as-ints: numerator / divisor
function _divrnd(
    uint256 numerator,
    uint256 divisor,
    RoundingMode rounding
) pure returns (uint256) {
    uint256 result = numerator / divisor;

    if (rounding == FLOOR) return result;

    if (rounding == ROUND) {
        if (numerator % divisor > (divisor - 1) / 2) {
            result++;
        }
    } else {
        if (numerator % divisor > 0) {
            result++;
        }
    }

    return result;
}

library FixLib {
    /// Again, all arithmetic functions fail if and only if the result is out of bounds.

    /// Convert this fixed-point value to a uint. Round towards zero if needed.
    /// @return x
    // as-ints: x / 1e18
    function toUint(uint192 x) internal pure returns (uint136) {
        return toUint(x, FLOOR);
    }

    /// Convert this uint192 to a uint
    /// @return x
    // as-ints: x / 1e18 with rounding
    function toUint(uint192 x, RoundingMode rounding) internal pure returns (uint136) {
        return uint136(_divrnd(uint256(x), FIX_SCALE, rounding));
    }

    /// Return the uint192 shifted to the left by `decimal` digits
    /// (Similar to a bitshift but in base 10)
    /// @return x * 10**decimals
    // as-ints: x * 10**decimals
    function shiftl(uint192 x, int8 decimals) internal pure returns (uint192) {
        return shiftl(x, decimals, FLOOR);
    }

    /// Return the uint192 shifted to the left by `decimal` digits
    /// (Similar to a bitshift but in base 10)
    /// @return x * 10**decimals
    // as-ints: x * 10**decimals
    function shiftl(
        uint192 x,
        int8 decimals,
        RoundingMode rounding
    ) internal pure returns (uint192) {
        uint256 coeff = uint256(10**abs(decimals));
        return _safeWrap(decimals >= 0 ? x * coeff : _divrnd(x, coeff, rounding));
    }

    /// Add a uint192 to this uint192
    /// @return x + y
    // as-ints: x + y
    function plus(uint192 x, uint192 y) internal pure returns (uint192) {
        return x + y;
    }

    /// Add a uint to this uint192
    /// @return x + y
    // as-ints: x + y*1e18
    function plusu(uint192 x, uint256 y) internal pure returns (uint192) {
        return _safeWrap(x + y * FIX_SCALE);
    }

    /// Subtract a uint192 from this uint192
    /// @return x - y
    // as-ints: x - y
    function minus(uint192 x, uint192 y) internal pure returns (uint192) {
        return x - y;
    }

    /// Subtract a uint from this uint192
    /// @return x - y
    // as-ints: x - y*1e18
    function minusu(uint192 x, uint256 y) internal pure returns (uint192) {
        return _safeWrap(uint256(x) - uint256(y * FIX_SCALE));
    }

    /// Multiply this uint192 by a uint192
    /// Round truncated values to the nearest available value. 5e-19 rounds away from zero.
    /// @return x * y
    // as-ints: x * y/1e18  [division using ROUND, not FLOOR]
    function mul(uint192 x, uint192 y) internal pure returns (uint192) {
        return mul(x, y, ROUND);
    }

    /// Multiply this uint192 by a uint192
    /// @return x * y
    // as-ints: x * y/1e18
    function mul(
        uint192 x,
        uint192 y,
        RoundingMode rounding
    ) internal pure returns (uint192) {
        return _safeWrap(_divrnd(uint256(x) * uint256(y), FIX_SCALE, rounding));
    }

    /// Multiply this uint192 by a uint
    /// @return x * y
    // as-ints: x * y
    function mulu(uint192 x, uint256 y) internal pure returns (uint192) {
        return _safeWrap(x * y);
    }

    /// Divide this uint192 by a uint192
    /// @return x / y
    // as-ints: x * 1e18 / y
    function div(uint192 x, uint192 y) internal pure returns (uint192) {
        return div(x, y, FLOOR);
    }

    /// Divide this uint192 by a uint192
    /// @return x / y
    // as-ints: x * 1e18 / y
    function div(
        uint192 x,
        uint192 y,
        RoundingMode rounding
    ) internal pure returns (uint192) {
        // Multiply-in FIX_SCALE before dividing by y to preserve precision.
        return _safeWrap(_divrnd(uint256(x) * FIX_SCALE, y, rounding));
    }

    /// Divide this uint192 by a uint
    /// @return x / y
    // as-ints: x / y
    function divu(uint192 x, uint256 y) internal pure returns (uint192) {
        return divu(x, y, FLOOR);
    }

    /// Divide this uint192 by a uint
    /// @return x / y
    // as-ints: x / y
    function divu(
        uint192 x,
        uint256 y,
        RoundingMode rounding
    ) internal pure returns (uint192) {
        return _safeWrap(_divrnd(x, y, rounding));
    }

    uint64 constant FIX_HALF = uint64(FIX_SCALE) / 2;

    /// Raise this uint192 to a nonnegative integer power.
    /// Intermediate muls do nearest-value rounding.
    /// Presumes that powu(0.0, 0) = 1
    /// @dev The gas cost is O(lg(y))
    /// @return x_ ** y
    // as-ints: x_ ** y / 1e18**(y-1)    <- technically correct for y = 0. :D
    function powu(uint192 x_, uint48 y) internal pure returns (uint192) {
        // The algorithm is exponentiation by squaring. See: https://w.wiki/4LjE
        if (y == 1) return x_;
        if (x_ == FIX_ONE || y == 0) return FIX_ONE;
        uint256 x = uint256(x_);
        uint256 result = FIX_SCALE;
        while (true) {
            if (y & 1 == 1) result = (result * x + FIX_HALF) / FIX_SCALE;
            if (y <= 1) break;
            y = y >> 1;
            x = (x * x + FIX_HALF) / FIX_SCALE;
        }
        return _safeWrap(result);
    }

    /// Comparison operators...
    function lt(uint192 x, uint192 y) internal pure returns (bool) {
        return x < y;
    }

    function lte(uint192 x, uint192 y) internal pure returns (bool) {
        return x <= y;
    }

    function gt(uint192 x, uint192 y) internal pure returns (bool) {
        return x > y;
    }

    function gte(uint192 x, uint192 y) internal pure returns (bool) {
        return x >= y;
    }

    function eq(uint192 x, uint192 y) internal pure returns (bool) {
        return x == y;
    }

    function neq(uint192 x, uint192 y) internal pure returns (bool) {
        return x != y;
    }

    /// Return whether or not this uint192 is less than epsilon away from y.
    /// @return |x - y| < epsilon
    // as-ints: |x - y| < epsilon
    function near(
        uint192 x,
        uint192 y,
        uint192 epsilon
    ) internal pure returns (bool) {
        uint192 diff = x <= y ? y - x : x - y;
        return diff < epsilon;
    }

    // ================ Chained Operations ================
    // The operation foo_bar() always means:
    //   Do foo() followed by bar(), and overflow only if the _end_ result doesn't fit in an uint192

    /// Shift this uint192 left by `decimals` digits, and convert to a uint
    /// @return x * 10**decimals
    // as-ints: x * 10**(decimals - 18)
    function shiftl_toUint(uint192 x, int8 decimals) internal pure returns (uint256) {
        return shiftl_toUint(x, decimals, FLOOR);
    }

    /// Shift this uint192 left by `decimals` digits, and convert to a uint.
    /// @return x * 10**decimals
    // as-ints: x * 10**(decimals - 18)
    function shiftl_toUint(
        uint192 x,
        int8 decimals,
        RoundingMode rounding
    ) internal pure returns (uint256) {
        decimals -= 18; // shift so that toUint happens at the same time.
        uint256 coeff = uint256(10**abs(decimals));
        return decimals >= 0 ? uint256(x * coeff) : uint256(_divrnd(x, coeff, rounding));
    }

    /// Multiply this uint192 by a uint, and output the result as a uint
    /// @return x * y
    // as-ints: x * y / 1e18
    function mulu_toUint(uint192 x, uint256 y) internal pure returns (uint256) {
        return mulDiv256(uint256(x), y, FIX_SCALE);
    }

    /// Multiply this uint192 by a uint, and output the result as a uint
    /// @return x * y
    // as-ints: x * y / 1e18
    function mulu_toUint(
        uint192 x,
        uint256 y,
        RoundingMode rounding
    ) internal pure returns (uint256) {
        return mulDiv256(uint256(x), y, FIX_SCALE, rounding);
    }

    /// Multiply this uint192 by a uint192 and output the result as a uint
    /// @return x * y
    // as-ints: x * y / 1e36
    function mul_toUint(uint192 x, uint192 y) internal pure returns (uint256) {
        return mulDiv256(uint256(x), uint256(y), FIX_SCALE_SQ);
    }

    /// Multiply this uint192 by a uint192 and output the result as a uint
    /// @return x * y
    // as-ints: x * y / 1e36
    function mul_toUint(
        uint192 x,
        uint192 y,
        RoundingMode rounding
    ) internal pure returns (uint256) {
        return mulDiv256(uint256(x), uint256(y), FIX_SCALE_SQ, rounding);
    }

    /// Compute x * y / z avoiding intermediate overflow
    /// @dev Only use if you need to avoid overflow; costlier than x * y / z
    /// @return x * y / z
    // as-ints: x * y / z
    function muluDivu(
        uint192 x,
        uint256 y,
        uint256 z
    ) internal pure returns (uint192) {
        return muluDivu(x, y, z, FLOOR);
    }

    /// Compute x * y / z, avoiding intermediate overflow
    /// @dev Only use if you need to avoid overflow; costlier than x * y / z
    /// @return x * y / z
    // as-ints: x * y / z
    function muluDivu(
        uint192 x,
        uint256 y,
        uint256 z,
        RoundingMode rounding
    ) internal pure returns (uint192) {
        return _safeWrap(mulDiv256(x, y, z, rounding));
    }

    /// Compute x * y / z on Fixes, avoiding intermediate overflow
    /// @dev Only use if you need to avoid overflow; costlier than x * y / z
    /// @return x * y / z
    // as-ints: x * y / z
    function mulDiv(
        uint192 x,
        uint192 y,
        uint192 z
    ) internal pure returns (uint192) {
        return mulDiv(x, y, z, FLOOR);
    }

    /// Compute x * y / z on Fixes, avoiding intermediate overflow
    /// @dev Only use if you need to avoid overflow; costlier than x * y / z
    /// @return x * y / z
    // as-ints: x * y / z
    function mulDiv(
        uint192 x,
        uint192 y,
        uint192 z,
        RoundingMode rounding
    ) internal pure returns (uint192) {
        return _safeWrap(mulDiv256(x, y, z, rounding));
    }
}

// ================ a couple pure-uint helpers================
// as-ints comments are omitted here, because they're the same as @return statements, because
// these are all pure uint functions

/// Return (x*y/z), avoiding intermediate overflow.
//  Adapted from sources:
//    https://medium.com/coinmonks/4db014e080b1, https://medium.com/wicketh/afa55870a65
//    and quite a few of the other excellent "Mathemagic" posts from https://medium.com/wicketh
/// @dev Only use if you need to avoid overflow; costlier than x * y / z
/// @return result x * y / z
function mulDiv256(
    uint256 x,
    uint256 y,
    uint256 z
) pure returns (uint256 result) {
    unchecked {
        (uint256 hi, uint256 lo) = fullMul(x, y);
        if (hi >= z) revert UIntOutOfBounds();
        uint256 mm = mulmod(x, y, z);
        if (mm > lo) hi -= 1;
        lo -= mm;
        uint256 pow2 = z & (0 - z);
        z /= pow2;
        lo /= pow2;
        lo += hi * ((0 - pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        result = lo * r;
    }
}

/// Return (x*y/z), avoiding intermediate overflow.
/// @dev Only use if you need to avoid overflow; costlier than x * y / z
/// @return x * y / z
function mulDiv256(
    uint256 x,
    uint256 y,
    uint256 z,
    RoundingMode rounding
) pure returns (uint256) {
    uint256 result = mulDiv256(x, y, z);
    if (rounding == FLOOR) return result;

    uint256 mm = mulmod(x, y, z);
    if (rounding == CEIL) {
        if (mm > 0) result += 1;
    } else {
        if (mm > ((z - 1) / 2)) result += 1; // z should be z-1
    }
    return result;
}

/// Return (x*y) as a "virtual uint512" (lo, hi), representing (hi*2**256 + lo)
///   Adapted from sources:
///   https://medium.com/wicketh/27650fec525d, https://medium.com/coinmonks/4db014e080b1
/// @dev Intended to be internal to this library
/// @return hi (hi, lo) satisfies  hi*(2**256) + lo == x * y
/// @return lo (paired with `hi`)
function fullMul(uint256 x, uint256 y) pure returns (uint256 hi, uint256 lo) {
    unchecked {
        uint256 mm = mulmod(x, y, uint256(0) - uint256(1));
        lo = x * y;
        hi = mm - lo;
        if (mm < lo) hi -= 1;
    }
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IAssetRegistry.sol";
import "./IBasketHandler.sol";
import "./IBackingManager.sol";
import "./IBroker.sol";
import "./IGnosis.sol";
import "./IFurnace.sol";
import "./IDistributor.sol";
import "./IRToken.sol";
import "./IRevenueTrader.sol";
import "./IStRSR.sol";
import "./ITrading.sol";
import "./IVersioned.sol";

// === Auth roles ===

bytes32 constant OWNER = bytes32(bytes("OWNER"));
bytes32 constant SHORT_FREEZER = bytes32(bytes("SHORT_FREEZER"));
bytes32 constant LONG_FREEZER = bytes32(bytes("LONG_FREEZER"));
bytes32 constant PAUSER = bytes32(bytes("PAUSER"));

/**
 * Main is a central hub that maintains a list of Component contracts.
 *
 * Components:
 *   - perform a specific function
 *   - defer auth to Main
 *   - usually (but not always) contain sizeable state that require a proxy
 */
struct Components {
    // Definitely need proxy
    IRToken rToken;
    IStRSR stRSR;
    IAssetRegistry assetRegistry;
    IBasketHandler basketHandler;
    IBackingManager backingManager;
    IDistributor distributor;
    IFurnace furnace;
    IBroker broker;
    IRevenueTrader rsrTrader;
    IRevenueTrader rTokenTrader;
}

interface IAuth is IAccessControlUpgradeable {
    /// Emitted when `unfreezeAt` is changed
    /// @param oldVal The old value of `unfreezeAt`
    /// @param newVal The new value of `unfreezeAt`
    event UnfreezeAtSet(uint48 indexed oldVal, uint48 indexed newVal);

    /// Emitted when the short freeze duration governance param is changed
    /// @param oldDuration The old short freeze duration
    /// @param newDuration The new short freeze duration
    event ShortFreezeDurationSet(uint48 indexed oldDuration, uint48 indexed newDuration);

    /// Emitted when the long freeze duration governance param is changed
    /// @param oldDuration The old long freeze duration
    /// @param newDuration The new long freeze duration
    event LongFreezeDurationSet(uint48 indexed oldDuration, uint48 indexed newDuration);

    /// Emitted when the system is paused or unpaused
    /// @param oldVal The old value of `paused`
    /// @param newVal The new value of `paused`
    event PausedSet(bool indexed oldVal, bool indexed newVal);

    /**
     * Paused: Disable everything except for OWNER actions and RToken.redeem/cancel
     * Frozen: Disable everything except for OWNER actions
     */

    function pausedOrFrozen() external view returns (bool);

    function frozen() external view returns (bool);

    function shortFreeze() external view returns (uint48);

    function longFreeze() external view returns (uint48);

    // ====

    // onlyRole(OWNER)
    function freezeForever() external;

    // onlyRole(SHORT_FREEZER)
    function freezeShort() external;

    // onlyRole(LONG_FREEZER)
    function freezeLong() external;

    // onlyRole(OWNER)
    function unfreeze() external;

    function pause() external;

    function unpause() external;
}

interface IComponentRegistry {
    // === Component setters/getters ===

    event RTokenSet(IRToken indexed oldVal, IRToken indexed newVal);

    function rToken() external view returns (IRToken);

    event StRSRSet(IStRSR indexed oldVal, IStRSR indexed newVal);

    function stRSR() external view returns (IStRSR);

    event AssetRegistrySet(IAssetRegistry indexed oldVal, IAssetRegistry indexed newVal);

    function assetRegistry() external view returns (IAssetRegistry);

    event BasketHandlerSet(IBasketHandler indexed oldVal, IBasketHandler indexed newVal);

    function basketHandler() external view returns (IBasketHandler);

    event BackingManagerSet(IBackingManager indexed oldVal, IBackingManager indexed newVal);

    function backingManager() external view returns (IBackingManager);

    event DistributorSet(IDistributor indexed oldVal, IDistributor indexed newVal);

    function distributor() external view returns (IDistributor);

    event RSRTraderSet(IRevenueTrader indexed oldVal, IRevenueTrader indexed newVal);

    function rsrTrader() external view returns (IRevenueTrader);

    event RTokenTraderSet(IRevenueTrader indexed oldVal, IRevenueTrader indexed newVal);

    function rTokenTrader() external view returns (IRevenueTrader);

    event FurnaceSet(IFurnace indexed oldVal, IFurnace indexed newVal);

    function furnace() external view returns (IFurnace);

    event BrokerSet(IBroker indexed oldVal, IBroker indexed newVal);

    function broker() external view returns (IBroker);
}

/**
 * @title IMain
 * @notice The central hub for the entire system. Maintains components and an owner singleton role
 */
interface IMain is IVersioned, IAuth, IComponentRegistry {
    function poke() external; // not used in p1

    // === Initialization ===

    event MainInitialized();

    function init(
        Components memory components,
        IERC20 rsr_,
        uint48 shortFreeze_,
        uint48 longFreeze_
    ) external;

    function rsr() external view returns (IERC20);
}

interface TestIMain is IMain {
    /// @custom:governance
    function setShortFreeze(uint48) external;

    /// @custom:governance
    function setLongFreeze(uint48) external;

    function shortFreeze() external view returns (uint48);

    function longFreeze() external view returns (uint48);

    function longFreezes(address account) external view returns (uint256);

    function paused() external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

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

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct GnosisAuctionData {
    IERC20 auctioningToken;
    IERC20 biddingToken;
    uint256 orderCancellationEndDate;
    uint256 auctionEndDate;
    bytes32 initialAuctionOrder;
    uint256 minimumBiddingAmountPerOrder;
    uint256 interimSumBidAmount;
    bytes32 interimOrder;
    bytes32 clearingPriceOrder;
    uint96 volumeClearingPriceOrder;
    bool minFundingThresholdNotReached;
    bool isAtomicClosureAllowed;
    uint256 feeNumerator;
    uint256 minFundingThreshold;
}

/// The relevant portion of the interface of the live Gnosis EasyAuction contract
/// https://github.com/gnosis/ido-contracts/blob/main/contracts/EasyAuction.sol
interface IGnosis {
    function initiateAuction(
        IERC20 auctioningToken,
        IERC20 biddingToken,
        uint256 orderCancellationEndDate,
        uint256 auctionEndDate,
        uint96 auctionedSellAmount,
        uint96 minBuyAmount,
        uint256 minimumBiddingAmountPerOrder,
        uint256 minFundingThreshold,
        bool isAtomicClosureAllowed,
        address accessManagerContract,
        bytes memory accessManagerContractData
    ) external returns (uint256 auctionId);

    function auctionData(uint256 auctionId) external view returns (GnosisAuctionData memory);

    /// @param auctionId The external auction id
    /// @dev See here for decoding: https://git.io/JMang
    /// @return encodedOrder The order, encoded in a bytes 32
    function settleAuction(uint256 auctionId) external returns (bytes32 encodedOrder);

    /// @return The numerator over a 1000-valued denominator
    function feeNumerator() external returns (uint256);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/libraries/Fixed.sol";
import "./IAsset.sol";
import "./ITrade.sol";
import "./IRewardable.sol";

/**
 * @title ITrading
 * @notice Common events and refresher function for all Trading contracts
 */
interface ITrading is IRewardable {
    event MaxTradeSlippageSet(uint192 indexed oldVal, uint192 indexed newVal);
    event MinTradeVolumeSet(uint192 indexed oldVal, uint192 indexed newVal);

    /// Emitted when a trade is started
    /// @param trade The one-time-use trade contract that was just deployed
    /// @param sell The token to sell
    /// @param buy The token to buy
    /// @param sellAmount {qSellTok} The quantity of the selling token
    /// @param minBuyAmount {qBuyTok} The minimum quantity of the buying token to accept
    event TradeStarted(
        ITrade indexed trade,
        IERC20 indexed sell,
        IERC20 indexed buy,
        uint256 sellAmount,
        uint256 minBuyAmount
    );

    /// Emitted after a trade ends
    /// @param trade The one-time-use trade contract
    /// @param sell The token to sell
    /// @param buy The token to buy
    /// @param sellAmount {qSellTok} The quantity of the token sold
    /// @param buyAmount {qBuyTok} The quantity of the token bought
    event TradeSettled(
        ITrade indexed trade,
        IERC20 indexed sell,
        IERC20 indexed buy,
        uint256 sellAmount,
        uint256 buyAmount
    );

    /// Settle a single trade, expected to be used with multicall for efficient mass settlement
    /// @custom:refresher
    function settleTrade(IERC20 sell) external;

    /// @return {%} The maximum trade slippage acceptable
    function maxTradeSlippage() external view returns (uint192);

    /// @return {UoA} The minimum trade volume in UoA, applies to all assets
    function minTradeVolume() external view returns (uint192);

    /// @return The ongoing trade for a sell token, or the zero address
    function trades(IERC20 sell) external view returns (ITrade);
}

interface TestITrading is ITrading {
    /// @custom:governance
    function setMaxTradeSlippage(uint192 val) external;

    /// @custom:governance
    function setMinTradeVolume(uint192 val) external;

    /// @return The number of ongoing trades open
    function tradesOpen() external view returns (uint48);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.9;

interface IVersioned {
    function version() external view returns (string memory);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.9;

import "./IMain.sol";
import "./IVersioned.sol";

/**
 * @title IComponent
 * @notice A Component is the central building block of all our system contracts. Components
 *   contain important state that must be migrated during upgrades, and they delegate
 *   their ownership to Main's owner.
 */
interface IComponent is IVersioned {
    function main() external view returns (IMain);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * Simple generalized trading interface for all Trade contracts to obey
 *
 * Usage: if (canSettle()) settle()
 */
interface ITrade {
    function sell() external view returns (IERC20Metadata);

    function buy() external view returns (IERC20Metadata);

    /// @return The timestamp at which the trade is projected to become settle-able
    function endTime() external view returns (uint48);

    /// @return True if the trade can be settled
    /// @dev Should be guaranteed to be true eventually as an invariant
    function canSettle() external view returns (bool);

    /// Complete the trade and transfer tokens back to the origin trader
    /// @return soldAmt {qSellTok} The quantity of tokens sold
    /// @return boughtAmt {qBuyTok} The quantity of tokens bought
    function settle() external returns (uint256 soldAmt, uint256 boughtAmt);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.9;

import "./IComponent.sol";
import "./IMain.sol";

/**
 * @title IRewardable
 * @notice A simple component mixin interface to support claiming + monetization of rewards
 */
interface IRewardable is IComponent {
    /// Emitted whenever rewards are claimed
    event RewardsClaimed(address indexed erc20, uint256 indexed amount);

    /// Claim reward tokens from integrated defi protocols such as Compound/Aave
    /// @custom:interaction
    function claimAndSweepRewards() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "contracts/libraries/Fixed.sol";

error StalePrice();
error PriceOutsideRange();

/// Used by asset plugins to price their collateral
library OracleLib {
    /// @dev Use for on-the-fly calculations that should revert
    /// @param timeout The number of seconds after which oracle values should be considered stale
    /// @return {UoA/tok}
    function price(AggregatorV3Interface chainlinkFeed, uint48 timeout)
        internal
        view
        returns (uint192)
    {
        (uint80 roundId, int256 p, , uint256 updateTime, uint80 answeredInRound) = chainlinkFeed
            .latestRoundData();

        if (updateTime == 0 || answeredInRound < roundId) {
            revert StalePrice();
        }
        // Downcast is safe: uint256(-) reverts on underflow; block.timestamp assumed < 2^48
        uint48 secondsSince = uint48(block.timestamp - updateTime);
        if (secondsSince > timeout) revert StalePrice();

        // {UoA/tok}
        uint192 scaledPrice = shiftl_toFix(uint256(p), -int8(chainlinkFeed.decimals()));

        if (scaledPrice == 0) revert PriceOutsideRange();
        return scaledPrice;
    }

    /// @dev Use when a try-catch is necessary
    /// @param timeout The number of seconds after which oracle values should be considered stale
    /// @return {UoA/tok}
    function price_(AggregatorV3Interface chainlinkFeed, uint48 timeout)
        external
        view
        returns (uint192)
    {
        return price(chainlinkFeed, timeout);
    }
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/interfaces/IAsset.sol";
import "contracts/interfaces/IAssetRegistry.sol";
import "contracts/interfaces/ITrading.sol";
import "contracts/libraries/Fixed.sol";
import "./TradeLib.sol";

/// Struct purposes:
///   1. Stay under stack limit with fewer vars
///   2. Cache information such as component addresses + trading rules to save on gas

struct ComponentCache {
    ITrading trader;
    IBasketHandler bh;
    IAssetRegistry reg;
    IStRSR stRSR;
    IERC20 rsr;
    IRToken rToken;
}

struct TradingRules {
    uint192 minTradeVolume; // {UoA}
    uint192 maxTradeSlippage; // {1}
}

struct TradeInfo {
    IAsset sell;
    IAsset buy;
    uint192 sellAmount; // {sellTok}
    uint192 buyAmount; // {buyTok}
    uint192 sellPrice; // {UoA/sellTok}
    uint192 buyPrice; // {UoA/buyTok}
}

/**
 * @title RecollateralizationLibP1
 * @notice An informal extension of the Trading mixin that provides trade preparation views
 *   Users:
 *     - BackingManager
 *     - RTokenAsset
 *
 * @dev The caller must implement the ITrading interface!
 *
 * Interface:
 *  1. prepareRecollateralizationTrade (external)
 *  2. basketRange (internal)
 */
library RecollateralizationLibP1 {
    using FixLib for uint192;
    using TradeLib for TradeInfo;

    /// Select and prepare a trade that moves us closer to capitalization, using the
    /// basket range to avoid overeager/duplicate trading.
    // This is the "main loop" for recollateralization trading:
    // actions:
    //   let range = basketRange(all erc20s)
    //   let trade = nextTradePair(...)
    //   if trade.sell is not a defaulted collateral, prepareTradeToCoverDeficit(...)
    //   otherwise, prepareTradeSell(trade) with a 0 minBuyAmount
    function prepareRecollateralizationTrade(ITrading trader)
        external
        view
        returns (bool doTrade, TradeRequest memory req)
    {
        // === Prepare cached values ===

        IMain main = trader.main();
        ComponentCache memory components = ComponentCache({
            trader: trader,
            bh: main.basketHandler(),
            reg: main.assetRegistry(),
            stRSR: main.stRSR(),
            rsr: main.rsr(),
            rToken: main.rToken()
        });
        TradingRules memory rules = TradingRules({
            minTradeVolume: trader.minTradeVolume(),
            maxTradeSlippage: trader.maxTradeSlippage()
        });
        IERC20[] memory erc20s = components.reg.erc20s();

        // ============================

        // Compute basket range -  {BU}
        BasketRange memory range = basketRange(components, rules, erc20s);

        // Select a pair to trade next, if one exists
        TradeInfo memory trade = nextTradePair(components, rules, erc20s, range);

        // Don't trade if no pair is selected
        if (address(trade.sell) == address(0) || address(trade.buy) == address(0)) {
            return (false, req);
        }

        // If we are selling UNSOUND collateral, eliminate the minBuyAmount requirement
        if (
            trade.sell.isCollateral() &&
            ICollateral(address(trade.sell)).status() != CollateralStatus.SOUND
        ) {
            (doTrade, req) = trade.prepareTradeSell(rules);
            req.minBuyAmount = 0;
        } else {
            (doTrade, req) = trade.prepareTradeToCoverDeficit(rules);
        }

        // At this point doTrade _must_ be true, otherwise nextTradePair assumptions are broken
        assert(doTrade);

        return (doTrade, req);
    }

    // Used to avoid stack-too-deep errors in basketRange
    struct BasketRange {
        uint192 top; // {BU}
        uint192 bottom; // {BU}
    }

    // It's a precondition for all of these private helpers that their `erc20s` argument contains at
    // least all basket collateral, plus any registered assets for which the BackingManager has a
    // nonzero balance. Any user of these functions should just pass in assetRegistry().erc20s(). We
    // would prefer to look it up from inside each function, and avoid the extra parameter to get
    // wrong, but the erc20s() call is pretty expensive.

    /// The plausible range of BUs that the BackingManager will own by the end of recapitalization.
    /// @param erc20s Assets this computation presumes may be traded to raise funds.
    //
    //
    // This function returns a "plausible range of BUs" assuming that the trading process follows
    //     the follwing rules:
    //
    // - We will not aim to hold more than rToken.basketsNeeded() BUs
    // - No double trades: if we buy B in one trade, we won't sell B in another trade
    // - The best amount of an asset we can sell is our balance;
    //       the worst is (our balance) - (its dust amount)
    // - The best price we might get for a trade is the current price estimate (frictionlessly)
    // - The worst price we might get for a trade between SOUND or IFFY collateral is the current
    //     price estimate * ( 1 - maxTradeSlippage )
    // - The worst price we might get for an UNPRICED or DISABLED collateral is 0.
    // - Given all that, we're aiming to hold as many BUs as possible using the assets we own.
    //
    // Given these assumptions, the following hold:
    //
    // range.top = min(rToken.basketsNeeded, totalAssetValue(erc20s).high / basket.price())
    //   because (totalAssetValue(erc20s).high / basket.price()) is how many BUs we can hold given
    //   "best plausible" prices, and we won't try to hold more than rToken(trader).basketsNeeded
    //
    // range.bottom = max(0, min(pessimisticBUs, range.top)), where:
    //   pessimisticBUs = (assetsLow - maxTradeSlippage * buShortfall(range.top)) / basket.price()
    //     is the number of BUs that we are *sure* we have the assets to collateralize
    //     (making the above assumptions about actual trade prices), and
    //   buShortfall(range.top) = the total value of the assets we'd need to buy in order
    //     in order to fully collataeralize `range.top` BUs,
    //
    function basketRange(
        ComponentCache memory components,
        TradingRules memory rules,
        IERC20[] memory erc20s
    ) internal view returns (BasketRange memory range) {
        // basketPrice: The current UoA value of one basket.
        (, uint192 basketPrice) = components.bh.price(true);

        // assetsHigh: The most value we could get from the assets in erc20,
        //             assuming frictionless trades at currently-estimated prices.
        // assetsLow: The least value we might get from the assets in erc20,
        //            assuming frictionless trades, zero value from unreliable prices, and
        //            dustAmount of assets left in each Asset.
        // {UoA}
        (uint192 assetsHigh, uint192 assetsLow) = totalAssetValue(components, rules, erc20s);

        // {UoA}, Optimistic estimate of the value of our basket units at the end of this
        //   recapitalization process.
        uint192 basketTargetHigh = fixMin(
            assetsHigh,
            components.rToken.basketsNeeded().mul(basketPrice)
        );

        // {UoA}, Total value of collateral in shortfall of `basketTargetHigh`. Specifically:
        //   sum( shortfall(c, basketTargetHigh / basketPrice) for each erc20 c in the basket)
        //   where shortfall(c, BUs) == (BUs * bh.quantity(c) - c.balanceOf(trader)) * c.price()
        //         (that is, shortfall(c, BUs) is the market value of the c that `this` would
        //          need to be given in order to have enough of c to cover `BUs` BUs)
        // {UoA}
        uint192 shortfall = collateralShortfall(components, erc20s, basketTargetHigh, basketPrice);

        // ==== Further adjust the low backing estimate downwards to account for trading frictions

        // {UoA}, Total value of the slippage we'd see if we made `shortfall` trades with
        //     slippage `maxTradeSlippage()`
        uint192 shortfallSlippage = rules.maxTradeSlippage.mul(shortfall);

        // {UoA}, Pessimistic estimate of the value of our basket units at the end of this
        //   recapitalization process.
        uint192 basketTargetLow = assetsLow.gt(shortfallSlippage)
            ? fixMin(assetsLow.minus(shortfallSlippage), basketTargetHigh)
            : 0;

        // {BU} = {UoA} / {BU/UoA}
        range.top = basketTargetHigh.div(basketPrice, CEIL);
        range.bottom = basketTargetLow.div(basketPrice, CEIL);
    }

    // ===========================================================================================

    // === Private ===

    /// Total value of the erc20s under management by BackingManager
    /// This may include BackingManager's balances _and_ staked RSR hold by stRSR
    /// @param erc20s tokens to consider "under management" by BackingManager in this computation
    /// @return assetsHigh {UoA} The high estimate of the total value of assets under management
    /// @return assetsLow {UoA} The low estimate of the total value of assets under management

    // preconditions:
    //   components.trader is backingManager
    //   erc20s has no duplicates
    // checks:
    //   for e in erc20s, e has a registered asset in the assetRegistry
    // return values:
    // assetsHigh: The most value we could get from the assets in erc20,
    //             assuming frictionless trades at currently-estimated prices.
    // assetsLow: The least value we might get from the assets in erc20,
    //            assuming frictionless trades, zero value from unreliable prices, and
    //            dustAmount of assets left in each Asset.
    function totalAssetValue(
        ComponentCache memory components,
        TradingRules memory rules,
        IERC20[] memory erc20s
    ) private view returns (uint192 assetsHigh, uint192 assetsLow) {
        // The low estimate is lower than the high estimate due to:
        // - Discounting assets with reverting strict prices
        // - Discounting dust amounts for collateral in the basket + non-dust assets

        uint192 potentialDustLoss; // {UoA}

        // Accumulate:
        // - assetsHigh: sum(bal(e)*price(e) for e ... )
        // - potentialDustLoss: sum(minTradeSize(e) for e ... )
        // - assetsLow: sum(bal(e)*price(e) for e ... if e.status() == SOUND or e is just an Asset)
        for (uint256 i = 0; i < erc20s.length; ++i) {
            // Exclude RToken balances, or else we double count
            if (erc20s[i] == IERC20(address(components.rToken))) continue;

            IAsset asset = components.reg.toAsset(erc20s[i]);
            uint192 bal = asset.bal(address(components.trader));

            // For RSR, include the staking balance
            if (erc20s[i] == components.rsr) bal = bal.plus(asset.bal(address(components.stRSR)));

            // Ignore dust amounts for assets not in the basket; their value is inaccessible
            bool inBasket = components.bh.quantity(erc20s[i]).gt(FIX_ZERO);
            (bool isFallback, uint192 price) = asset.price(true); // {UoA}
            if (!inBasket && !TradeLib.isEnoughToSell(asset, price, bal, rules.minTradeVolume)) {
                continue;
            }

            // {UoA} = {UoA} + {UoA/tok} * {tok}
            uint192 val = price.mul(bal, FLOOR);

            // Consider all managed assets at face-value prices
            assetsHigh = assetsHigh.plus(val);

            // Accumulate potential losses to dust
            potentialDustLoss = potentialDustLoss.plus(rules.minTradeVolume);

            // Consider only reliable sources of value for the assetsLow estimate
            if (!isFallback) {
                assetsLow = assetsLow.plus(val);
            }
        }

        // Account for all the places dust could get stuck
        // assetsLow' = max(assetsLow-potentialDustLoss, 0)
        assetsLow = assetsLow.gt(potentialDustLoss) ? assetsLow.minus(potentialDustLoss) : FIX_ZERO;
    }

    // Used in memory in `nextTradePair` to duck the stack limit
    struct MaxSurplusDeficit {
        CollateralStatus surplusStatus; // starts SOUND
        uint192 surplus; // {UoA}
        uint192 deficit; // {UoA}
    }

    // Choose next sell/buy pair to trade, with reference to the basket range
    // Exclude dust amounts for surplus
    /// @return trade
    ///   sell: Surplus collateral OR address(0)
    ///   deficit Deficit collateral OR address(0)
    ///   sellAmount {sellTok} Surplus amount (whole tokens)
    ///   buyAmount {buyTok} Deficit amount (whole tokens)
    ///   sellPrice {UoA/sellTok}
    ///   buyPrice {UoA/sellTok}
    ///
    // Defining "sell" and "buy":
    // If bal(e) > (quantity(e) * range.top), then e is in surplus by the difference
    // If bal(e) < (quantity(e) * range.bottom), then e is in deficit by the difference
    //
    // First, ignoring RSR:
    //   `trade.sell` is the token from erc20s with the greatest surplus value (in UoA),
    //   and sellAmount is the quantity of that token that it's in surplus (in qTok).
    //   if `trade.sell` == 0, then no token is in surplus by at least minTradeSize,
    //        and `trade.sellAmount` and `trade.sellPrice` are unset.
    //
    //   `trade.buy` is the token from erc20s with the greatest deficit value (in UoA),
    //   and buyAmount is the quantity of that token that it's in deficit (in qTok).
    //   if `trade.buy` == 0, then no token is in deficit at all,
    //        and `trade.buyAmount` and `trade.buyPrice` are unset.
    //
    // Then, just if we have a buy asset and no sell asset, consider selling available RSR.
    //
    // Prefer selling assets in this order: DISABLED -> SOUND -> IFFY.
    function nextTradePair(
        ComponentCache memory components,
        TradingRules memory rules,
        IERC20[] memory erc20s,
        BasketRange memory range
    ) private view returns (TradeInfo memory trade) {
        MaxSurplusDeficit memory maxes;
        maxes.surplusStatus = CollateralStatus.IFFY; // least-desirable sell status

        for (uint256 i = 0; i < erc20s.length; ++i) {
            if (erc20s[i] == components.rsr) continue;

            IAsset asset = components.reg.toAsset(erc20s[i]);

            uint192 bal = asset.bal(address(components.trader)); // {tok}

            // {tok} = {BU} * {tok/BU}
            // needed(Top): token balance needed for range.top baskets: quantity(e) * range.top
            uint192 needed = range.top.mul(components.bh.quantity(erc20s[i]), CEIL); // {tok}
            if (bal.gt(needed)) {
                (, uint192 price_) = asset.price(true); // {UoA/tok} allow fallback prices

                // {UoA} = {tok} * {UoA/tok}
                uint192 delta = bal.minus(needed).mul(price_, FLOOR);

                CollateralStatus status; // starts SOUND
                if (asset.isCollateral()) status = ICollateral(address(asset)).status();

                // Select the most-in-surplus "best" asset, as defined by (status, max surplusAmt)
                if (
                    (preferToSell(maxes.surplusStatus, status) ||
                        (delta.gt(maxes.surplus) && maxes.surplusStatus == status)) &&
                    TradeLib.isEnoughToSell(asset, price_, bal.minus(needed), rules.minTradeVolume)
                ) {
                    trade.sell = asset;
                    trade.sellAmount = bal.minus(needed);
                    trade.sellPrice = price_;

                    maxes.surplusStatus = status;
                    maxes.surplus = delta;
                }
            } else {
                // needed(Bottom): token balance needed at bottom of the basket range
                needed = range.bottom.mul(components.bh.quantity(erc20s[i]), CEIL); // {tok};
                if (bal.lt(needed)) {
                    uint192 amtShort = needed.minus(bal); // {tok}
                    (, uint192 price_) = asset.price(true); // {UoA/tok} allow fallback prices

                    // {UoA} = {tok} * {UoA/tok}
                    uint192 delta = amtShort.mul(price_, CEIL);
                    if (delta.gt(maxes.deficit)) {
                        trade.buy = ICollateral(address(asset));
                        trade.buyAmount = amtShort;
                        trade.buyPrice = price_;

                        maxes.deficit = delta;
                    }
                }
            }
        }

        // Use RSR if needed
        if (address(trade.sell) == address(0) && address(trade.buy) != address(0)) {
            IAsset rsrAsset = components.reg.toAsset(components.rsr);

            uint192 rsrAvailable = rsrAsset.bal(address(components.trader)).plus(
                rsrAsset.bal(address(components.stRSR))
            );
            (, uint192 price_) = rsrAsset.price(true); // {UoA/tok} allow fallback prices

            if (TradeLib.isEnoughToSell(rsrAsset, price_, rsrAvailable, rules.minTradeVolume)) {
                trade.sell = rsrAsset;
                trade.sellAmount = rsrAvailable;
                trade.sellPrice = price_;
            }
        }
    }

    /// @param backing {UoA} An amount of backing in UoA terms
    /// @param basketPrice {UoA/BU} The price of a BU in UoA terms, at precise prices
    /// @return shortfall {UoA} The missing re-collateralization in UoA terms
    // Specifically, returns:
    //   sum( shortfall(c, basketTargetHigh / basketPrice) for each erc20 c in the basket)
    //   where shortfall(c, numBUs) == (numBus * bh.quantity(c) - c.balanceOf(trader)) * c.price()
    //         (that is, shortfall(c, numBUs) is the market value of the c that `this` would
    //          need to be given in order to have enough of c to cover `numBUs` BUs)
    // precondition: erc20s contains no duplicates; all basket tokens are in erc20s
    function collateralShortfall(
        ComponentCache memory components,
        IERC20[] memory erc20s,
        uint192 backing,
        uint192 basketPrice
    ) private view returns (uint192 shortfall) {
        assert(basketPrice > 0); // div by zero further down in function

        // accumulate shortfall
        for (uint256 i = 0; i < erc20s.length; ++i) {
            uint192 quantity = components.bh.quantity(erc20s[i]); // {tok/BU}
            if (quantity.eq(FIX_ZERO)) continue; // skip any collateral not needed

            // Cast: if the quantity is nonzero, then it must be collateral
            ICollateral coll = components.reg.toColl(erc20s[i]);

            // {tok} = {UoA} * {tok/BU} / {UoA/BU}
            // needed: quantity of erc20s[i] needed in basketPrice's worth of baskets
            uint192 needed = backing.mulDiv(quantity, basketPrice, CEIL); // {tok}
            // held: quantity of erc20s[i] owned by `this`
            uint192 held = coll.bal(address(components.trader)); // {tok}

            if (held.lt(needed)) {
                (, uint192 price_) = coll.price(true); // allow fallback prices

                // {UoA} = {UoA} + ({tok} - {tok}) * {UoA/tok}
                shortfall = shortfall.plus(needed.minus(held).mul(price_, FLOOR));
            }
        }
    }

    /// Prefer selling assets in this order: DISABLED -> SOUND -> IFFY.
    /// @return If we prefer to sell `status2` over `status1`
    function preferToSell(CollateralStatus status1, CollateralStatus status2)
        private
        pure
        returns (bool)
    {
        // NOTE: If we change the CollaetralStatus enum then this has to change!
        if (status1 == CollateralStatus.DISABLED) return false;
        if (status1 == CollateralStatus.SOUND) return status2 == CollateralStatus.DISABLED;
        return status2 != CollateralStatus.IFFY;
    }
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/interfaces/IAsset.sol";
import "contracts/interfaces/IAssetRegistry.sol";
import "contracts/interfaces/ITrading.sol";
import "contracts/libraries/Fixed.sol";
import "./RecollateralizationLib.sol";

/**
 * @title TradeLib
 * @notice An internal lib for preparing individual trades on particular asset pairs
 *   Users:
 *     - BackingManagerLib
 *     - RevenueTrader
 */
library TradeLib {
    using FixLib for uint192;

    /// Prepare a trade to sell `trade.sellAmount` that guarantees a reasonable closing price,
    /// without explicitly aiming at a particular quantity to purchase.
    /// @param trade:
    ///   sell != 0, sellAmount >= 0 {sellTok}, sellPrice >= 0 {UoA/sellTok}
    ///   buy != 0, buyAmount (unused) {buyTok}, buyPrice > 0 {UoA/buyTok}
    /// @return notDust True when the trade is larger than the dust amount
    /// @return req The prepared trade request to send to the Broker
    //
    // If notDust is true, then the returned trade request satisfies:
    //   req.sell == trade.sell and req.buy == trade.buy,
    //   req.minBuyAmount * trade.buyPrice ~=
    //        trade.sellAmount * trade.sellPrice * (1-rules.maxTradeSlippage),
    //   req.sellAmount == min(trade.sell.maxTradeSize().toQTok(), trade.sellAmount.toQTok(sell)
    //   1 < req.sellAmount
    //
    // If notDust is false, no trade exists that satisfies those constraints.
    function prepareTradeSell(TradeInfo memory trade, TradingRules memory rules)
        internal
        view
        returns (bool notDust, TradeRequest memory req)
    {
        assert(trade.buyPrice > 0); // checked for in RevenueTrader / CollateralizatlionLib
        // assert(trade.sellPrice >= 0); not needed

        // Don't sell dust
        if (!isEnoughToSell(trade.sell, trade.sellPrice, trade.sellAmount, rules.minTradeVolume)) {
            return (false, req);
        }

        // {sellTok} - reads trade.sell.price(true)
        uint192 s = fixMin(trade.sellAmount, maxTradeSize(trade.sell, trade.sellPrice));

        // {buyTok} = {sellTok} * {UoA/sellTok} / {UoA/buyTok}
        uint192 b = s.mul(FIX_ONE.minus(rules.maxTradeSlippage)).mulDiv(
            trade.sellPrice,
            trade.buyPrice,
            CEIL
        );

        req.sell = trade.sell;
        req.buy = trade.buy;
        req.sellAmount = s.shiftl_toUint(int8(trade.sell.erc20Decimals()), FLOOR);
        req.minBuyAmount = b.shiftl_toUint(int8(trade.buy.erc20Decimals()), CEIL);

        return (true, req);
    }

    /// Assuming we have `trade.sellAmount` sell tokens available, prepare a trade to cover as
    /// much of our deficit of `trade.buyAmount` buy tokens as possible, given expected trade
    /// slippage and the sell asset's maxTradeVolume().
    /// @param trade:
    ///   sell != 0
    ///   buy != 0
    ///   sellAmount (unused) {sellTok}
    ///   buyAmount >= 0 {buyTok}
    ///   sellPrice > 0 {UoA/sellTok}
    ///   buyPrice > 0 {UoA/buyTok}
    /// @return notDust Whether the prepared trade is large enough to be worth trading
    /// @return req The prepared trade request to send to the Broker
    //
    // Returns prepareTradeSell(trade, rules), where
    //   req.sellAmount = min(trade.sellAmount,
    //                trade.buyAmount * (trade.buyPrice / trade.sellPrice) / (1-maxTradeSlippage))
    //   i.e, the minimum of trade.sellAmount and (a sale amount that, at current prices and
    //   maximum slippage, will yield at least the requested trade.buyAmount)
    //
    // Which means we should get that, if notDust is true, then:
    //   req.sell = sell and req.buy = buy
    //
    //   1 <= req.minBuyAmount <= max(trade.buyAmount, buy.minTradeSize()).toQTok(trade.buy)
    //   1 < req.sellAmount <= min(trade.sellAmount.toQTok(trade.sell),
    //                               sell.maxTradeSize().toQTok(trade.sell))
    //   req.minBuyAmount ~= trade.sellAmount * sellPrice / buyPrice * (1-maxTradeSlippage)
    //
    //   req.sellAmount (and req.minBuyAmount) are maximal satisfying all these conditions
    function prepareTradeToCoverDeficit(TradeInfo memory trade, TradingRules memory rules)
        internal
        view
        returns (bool notDust, TradeRequest memory req)
    {
        assert(trade.sellPrice > 0 && trade.buyPrice > 0);

        // Don't buy dust.
        trade.buyAmount = fixMax(
            trade.buyAmount,
            minTradeSize(rules.minTradeVolume, trade.buyPrice)
        );

        // {sellTok} = {buyTok} * {UoA/buyTok} / {UoA/sellTok}
        uint192 exactSellAmount = trade.buyAmount.mulDiv(trade.buyPrice, trade.sellPrice, CEIL);
        // exactSellAmount: Amount to sell to buy `deficitAmount` if there's no slippage

        // slippedSellAmount: Amount needed to sell to buy `deficitAmount`, counting slippage
        uint192 slippedSellAmount = exactSellAmount.div(
            FIX_ONE.minus(rules.maxTradeSlippage),
            CEIL
        );

        trade.sellAmount = fixMin(slippedSellAmount, trade.sellAmount); // {sellTok}
        return prepareTradeSell(trade, rules);
    }

    /// @param asset The asset in question
    /// @param price {UoA/tok} The price to use
    /// @param amt {tok} The number of whole tokens we plan to sell
    /// @param minTradeVolume {UoA} The min trade volume, passed in for gas optimization
    /// @return If amt is sufficiently large to be worth selling into our trading platforms
    function isEnoughToSell(
        IAsset asset,
        uint192 price,
        uint192 amt,
        uint192 minTradeVolume
    ) internal view returns (bool) {
        // The Gnosis EasyAuction trading platform rounds defensively, meaning it is possible
        // for it to keep 1 qTok for itself. Therefore we should not sell 1 qTok. This is
        // likely to be true of all the trading platforms we integrate with.
        return
            amt.gte(minTradeSize(minTradeVolume, price)) &&
            // {qTok} = {tok} / {tok/qTok}
            amt.shiftl_toUint(int8(asset.erc20Decimals())) > 1;
    }

    // === Private ===

    /// Calculates the minTradeSize for an asset based on the given minTradeVolume and price
    /// @param minTradeVolume {UoA} The min trade volume, passed in for gas optimization
    /// @return {tok} The min trade size for the asset in whole tokens
    function minTradeSize(uint192 minTradeVolume, uint192 price) private pure returns (uint192) {
        // {tok} = {UoA} / {UoA/tok}
        uint192 size = price == 0 ? FIX_MAX : minTradeVolume.div(price, ROUND);
        return size > 0 ? size : 1;
    }

    /// Calculates the maxTradeSize for an asset based on the asset's maxTradeVolume and price
    /// @return {tok} The max trade size for the asset in whole tokens
    function maxTradeSize(IAsset asset, uint192 price) private view returns (uint192) {
        uint192 size = price == 0 ? FIX_MAX : asset.maxTradeVolume().div(price, ROUND);
        return size > 0 ? size : 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
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
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
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
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/interfaces/IMain.sol";
import "contracts/mixins/Auth.sol";

/**
 * @title ComponentRegistry
 */
abstract contract ComponentRegistry is Initializable, Auth, IComponentRegistry {
    // solhint-disable-next-line func-name-mixedcase
    function __ComponentRegistry_init(Components memory components_) internal onlyInitializing {
        _setBackingManager(components_.backingManager);
        _setBasketHandler(components_.basketHandler);
        _setRSRTrader(components_.rsrTrader);
        _setRTokenTrader(components_.rTokenTrader);
        _setAssetRegistry(components_.assetRegistry);
        _setDistributor(components_.distributor);
        _setFurnace(components_.furnace);
        _setBroker(components_.broker);
        _setStRSR(components_.stRSR);
        _setRToken(components_.rToken);
    }

    // === Components ===

    IRToken public rToken;

    function _setRToken(IRToken val) private {
        require(address(val) != address(0), "invalid RToken address");
        emit RTokenSet(rToken, val);
        rToken = val;
    }

    IStRSR public stRSR;

    function _setStRSR(IStRSR val) private {
        require(address(val) != address(0), "invalid StRSR address");
        emit StRSRSet(stRSR, val);
        stRSR = val;
    }

    IAssetRegistry public assetRegistry;

    function _setAssetRegistry(IAssetRegistry val) private {
        require(address(val) != address(0), "invalid AssetRegistry address");
        emit AssetRegistrySet(assetRegistry, val);
        assetRegistry = val;
    }

    IBasketHandler public basketHandler;

    function _setBasketHandler(IBasketHandler val) private {
        require(address(val) != address(0), "invalid BasketHandler address");
        emit BasketHandlerSet(basketHandler, val);
        basketHandler = val;
    }

    IBackingManager public backingManager;

    function _setBackingManager(IBackingManager val) private {
        require(address(val) != address(0), "invalid BackingManager address");
        emit BackingManagerSet(backingManager, val);
        backingManager = val;
    }

    IDistributor public distributor;

    function _setDistributor(IDistributor val) private {
        require(address(val) != address(0), "invalid Distributor address");
        emit DistributorSet(distributor, val);
        distributor = val;
    }

    IRevenueTrader public rsrTrader;

    function _setRSRTrader(IRevenueTrader val) private {
        require(address(val) != address(0), "invalid RSRTrader address");
        emit RSRTraderSet(rsrTrader, val);
        rsrTrader = val;
    }

    IRevenueTrader public rTokenTrader;

    function _setRTokenTrader(IRevenueTrader val) private {
        require(address(val) != address(0), "invalid RTokenTrader address");
        emit RTokenTraderSet(rTokenTrader, val);
        rTokenTrader = val;
    }

    IFurnace public furnace;

    function _setFurnace(IFurnace val) private {
        require(address(val) != address(0), "invalid Furnace address");
        emit FurnaceSet(furnace, val);
        furnace = val;
    }

    IBroker public broker;

    function _setBroker(IBroker val) private {
        require(address(val) != address(0), "invalid Broker address");
        emit BrokerSet(broker, val);
        broker = val;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[40] private __gap;
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "contracts/interfaces/IMain.sol";

uint256 constant LONG_FREEZE_CHARGES = 6; // 6 uses
uint48 constant MAX_UNFREEZE_AT = type(uint48).max;
uint48 constant MAX_SHORT_FREEZE = 2592000; // 1 month
uint48 constant MAX_LONG_FREEZE = 31536000; // 1 year

/**
 * @title Auth
 * @notice Provides fine-grained access controls and exports frozen/paused states to Components.
 */
abstract contract Auth is AccessControlUpgradeable, IAuth {
    /**
     * System-wide states (does not impact ERC20 functions)
     *  - Frozen: only allow OWNER actions and staking
     *  - Paused: only allow OWNER actions, redemption, issuance cancellation, and staking
     *
     * Typically freezing thaws on its own in a predetemined number of blocks.
     *   However, OWNER can also freeze forever.
     */

    /// The rest of the contract uses the shorthand; these declarations are here for getters
    bytes32 public constant OWNER_ROLE = OWNER;
    bytes32 public constant SHORT_FREEZER_ROLE = SHORT_FREEZER;
    bytes32 public constant LONG_FREEZER_ROLE = LONG_FREEZER;
    bytes32 public constant PAUSER_ROLE = PAUSER;

    // === Freezing ===

    mapping(address => uint256) public longFreezes;

    uint48 public unfreezeAt; // {s} uint48.max to pause indefinitely
    uint48 public shortFreeze; // {s} length of an initial freeze
    uint48 public longFreeze; // {s} length of a freeze extension

    // === Pausing ===

    bool public paused;

    /* ==== Invariants ====
       0 <= longFreeze[a] <= LONG_FREEZE_CHARGES for all addrs a
       set{a has LONG_FREEZER} == set{a : longFreeze[a] == 0}
    */

    // checks:
    // - __Auth_init has not previously been called
    // - 0 < shortFreeze_ <= MAX_SHORT_FREEZE
    // - 0 < longFreeze_ <= MAX_LONG_FREEZE
    // effects:
    // - caller has all roles
    // - OWNER is the admin role for all roles
    // - longFreezes[caller] == LONG_FREEZE_CHARGES
    // - shortFreeze' == shortFreeze_
    // - longFreeze' == longFreeze_
    // questions: (what do I know about the values of paused and unfreezeAt?)
    // solhint-disable-next-line func-name-mixedcase
    function __Auth_init(uint48 shortFreeze_, uint48 longFreeze_) internal onlyInitializing {
        __AccessControl_init();

        // Role setup
        _setRoleAdmin(OWNER, OWNER);
        _setRoleAdmin(SHORT_FREEZER, OWNER);
        _setRoleAdmin(LONG_FREEZER, OWNER);
        _setRoleAdmin(PAUSER, OWNER);

        address msgSender = _msgSender();
        _grantRole(OWNER, msgSender);
        _grantRole(SHORT_FREEZER, msgSender);
        _grantRole(LONG_FREEZER, msgSender);
        _grantRole(PAUSER, msgSender);
        longFreezes[msgSender] = LONG_FREEZE_CHARGES;

        setShortFreeze(shortFreeze_);
        setLongFreeze(longFreeze_);
    }

    // checks: caller is an admin for role, account is not 0
    // effects:
    // - account has the `role` role
    // - if role is LONG_FREEZER, then longFreezes'[account] == LONG_FREEZE_CHARGES
    function grantRole(bytes32 role, address account)
        public
        override(AccessControlUpgradeable, IAccessControlUpgradeable)
        onlyRole(getRoleAdmin(role))
    {
        require(account != address(0), "cannot grant role to address 0");
        if (role == LONG_FREEZER) longFreezes[account] = LONG_FREEZE_CHARGES;
        _grantRole(role, account);
    }

    // ==== System-wide views ====
    // returns: bool(main is frozen) == now < unfreezeAt
    function frozen() public view returns (bool) {
        return block.timestamp < unfreezeAt;
    }

    /// @dev This -or- condition is a performance optimization for the consuming Component
    // returns: bool(main is frozen or paused) == paused || (now < unfreezeAt)
    function pausedOrFrozen() public view returns (bool) {
        return paused || block.timestamp < unfreezeAt;
    }

    // === Freezing ===

    /// Enter a freeze for the `shortFreeze` duration
    // checks:
    // - caller has the SHORT_FREEZER role
    // - now + shortFreeze >= unfreezeAt (that is, this call should increase unfreezeAt)
    // effects:
    // - unfreezeAt' = now + shortFreeze
    // - after, caller does not have the SHORT_FREEZER role
    function freezeShort() external onlyRole(SHORT_FREEZER) {
        // Revoke short freezer role after one use
        _revokeRole(SHORT_FREEZER, _msgSender());
        freezeUntil(uint48(block.timestamp) + shortFreeze);
    }

    /// Enter a freeze by the `longFreeze` duration
    // checks:
    // - caller has the LONG_FREEZER role
    // - longFreezes[caller] > 0
    // - now + longFreeze >= unfreezeAt (that is, this call should increase unfreezeAt)
    // effects:
    // - unfreezeAt' = now + longFreeze
    // - longFreezes'[caller] = longFreezes[caller] - 1
    // - if longFreezes'[caller] == 0 then caller loses the LONG_FREEZER role
    function freezeLong() external onlyRole(LONG_FREEZER) {
        longFreezes[_msgSender()] -= 1; // reverts on underflow

        // Revoke on 0 charges as a cleanup step
        if (longFreezes[_msgSender()] == 0) _revokeRole(LONG_FREEZER, _msgSender());
        freezeUntil(uint48(block.timestamp) + longFreeze);
    }

    /// Enter a permanent freeze
    // checks:
    // - caller has the OWNER role
    // - unfreezeAt != type(uint48).max
    // effects: unfreezeAt' = type(uint48).max
    function freezeForever() external onlyRole(OWNER) {
        freezeUntil(MAX_UNFREEZE_AT);
    }

    /// End all freezes
    // checks:
    // - unfreezeAt > now  (i.e, frozen() == true before the call)
    // - caller has the OWNER role
    // effects: unfreezeAt' = now  (i.e, frozen() == false after the call)
    function unfreeze() external onlyRole(OWNER) {
        emit UnfreezeAtSet(unfreezeAt, uint48(block.timestamp));
        unfreezeAt = uint48(block.timestamp);
    }

    // === Pausing ===
    // checks: caller has PAUSER
    // effects: paused' = true
    function pause() external onlyRole(PAUSER) {
        emit PausedSet(paused, true);
        paused = true;
    }

    // checks: caller has PAUSER
    // effects: paused' = false
    function unpause() external onlyRole(PAUSER) {
        emit PausedSet(paused, false);
        paused = false;
    }

    // === Gov params ===

    /// @custom:governance
    function setShortFreeze(uint48 shortFreeze_) public onlyRole(OWNER) {
        require(shortFreeze_ > 0 && shortFreeze_ <= MAX_SHORT_FREEZE, "short freeze out of range");
        emit ShortFreezeDurationSet(shortFreeze, shortFreeze_);
        shortFreeze = shortFreeze_;
    }

    /// @custom:governance
    function setLongFreeze(uint48 longFreeze_) public onlyRole(OWNER) {
        require(longFreeze_ > 0 && longFreeze_ <= MAX_LONG_FREEZE, "long freeze out of range");
        emit LongFreezeDurationSet(longFreeze, longFreeze_);
        longFreeze = longFreeze_;
    }

    // === Private Helper ===
    // checks: newUnfreezeAt > unfreezeAt
    // effects: unfreezeAt' = newUnfreezeAt
    function freezeUntil(uint48 newUnfreezeAt) private {
        require(newUnfreezeAt > unfreezeAt, "frozen");
        emit UnfreezeAtSet(unfreezeAt, newUnfreezeAt);
        unfreezeAt = newUnfreezeAt;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
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
        _checkRole(role);
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
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
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
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
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

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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