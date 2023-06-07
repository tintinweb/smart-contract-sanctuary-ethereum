// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../plugins/trading/DutchTrade.sol";
import "../interfaces/IAsset.sol";
import "../interfaces/IAssetRegistry.sol";
import "../interfaces/IFacadeRead.sol";
import "../interfaces/IRToken.sol";
import "../interfaces/IStRSR.sol";
import "../libraries/Fixed.sol";
import "../p1/BasketHandler.sol";
import "../p1/RToken.sol";
import "../p1/StRSRVotes.sol";

/**
 * @title Facade
 * @notice A UX-friendly layer for reading out the state of a ^3.0.0 RToken in summary views.
 * @custom:static-call - Use ethers callStatic() to get result after update; do not execute
 */
contract FacadeRead is IFacadeRead {
    using FixLib for uint192;

    // === Static Calls ===

    /// @return {qRTok} How many RToken `account` can issue given current holdings
    /// @custom:static-call
    function maxIssuable(IRToken rToken, address account) external returns (uint256) {
        IMain main = rToken.main();
        main.poke();
        // {BU}

        BasketRange memory basketsHeld = main.basketHandler().basketsHeldBy(account);
        uint192 needed = rToken.basketsNeeded();

        int8 decimals = int8(rToken.decimals());

        // return {qRTok} = {BU} * {(1 RToken) qRTok/BU)}
        if (needed.eq(FIX_ZERO)) return basketsHeld.bottom.shiftl_toUint(decimals);

        uint192 totalSupply = shiftl_toFix(rToken.totalSupply(), -decimals); // {rTok}

        // {qRTok} = {BU} * {rTok} / {BU} * {qRTok/rTok}
        return basketsHeld.bottom.mulDiv(totalSupply, needed).shiftl_toUint(decimals);
    }

    /// @return tokens The erc20 needed for the issuance
    /// @return deposits {qTok} The deposits necessary to issue `amount` RToken
    /// @return depositsUoA {UoA} The UoA value of the deposits necessary to issue `amount` RToken
    /// @custom:static-call
    function issue(IRToken rToken, uint256 amount)
        external
        returns (
            address[] memory tokens,
            uint256[] memory deposits,
            uint192[] memory depositsUoA
        )
    {
        IMain main = rToken.main();
        main.poke();
        IRToken rTok = rToken;
        IBasketHandler bh = main.basketHandler();
        IAssetRegistry reg = main.assetRegistry();

        // Compute # of baskets to create `amount` qRTok
        uint192 baskets = (rTok.totalSupply() > 0) // {BU}
            ? rTok.basketsNeeded().muluDivu(amount, rTok.totalSupply()) // {BU * qRTok / qRTok}
            : _safeWrap(amount); // take advantage of RToken having 18 decimals

        (tokens, deposits) = bh.quote(baskets, CEIL);
        depositsUoA = new uint192[](tokens.length);

        for (uint256 i = 0; i < tokens.length; ++i) {
            IAsset asset = reg.toAsset(IERC20(tokens[i]));
            (uint192 low, uint192 high) = asset.price();
            // untestable:
            //      if high == FIX_MAX then low has to be zero, so this check will not be reached
            if (low == 0 || high == FIX_MAX) continue;

            uint192 mid = (low + high) / 2;

            // {UoA} = {tok} * {UoA/Tok}
            depositsUoA[i] = shiftl_toFix(deposits[i], -int8(asset.erc20Decimals())).mul(mid);
        }
    }

    /// @return tokens The erc20s returned for the redemption
    /// @return withdrawals The balances necessary to issue `amount` RToken
    /// @return isProrata True if the redemption is prorata and not full
    /// @custom:static-call
    function redeem(IRToken rToken, uint256 amount)
        external
        returns (
            address[] memory tokens,
            uint256[] memory withdrawals,
            bool isProrata
        )
    {
        IMain main = rToken.main();
        main.poke();
        IRToken rTok = rToken;
        IBasketHandler bh = main.basketHandler();
        uint256 supply = rTok.totalSupply();

        // D18{BU} = D18{BU} * {qRTok} / {qRTok}
        uint192 basketsRedeemed = rTok.basketsNeeded().muluDivu(amount, supply);

        (tokens, withdrawals) = bh.quote(basketsRedeemed, FLOOR);

        // Bound each withdrawal by the prorata share, in case we're currently under-collateralized
        address backingManager = address(main.backingManager());
        for (uint256 i = 0; i < tokens.length; ++i) {
            // {qTok} = {qTok} * {qRTok} / {qRTok}
            uint256 prorata = mulDiv256(
                IERC20Upgradeable(tokens[i]).balanceOf(backingManager),
                amount,
                supply
            ); // FLOOR

            if (prorata < withdrawals[i]) {
                withdrawals[i] = prorata;
                isProrata = true;
            }
        }
    }

    /// @return erc20s The ERC20 addresses in the current basket
    /// @return uoaShares {1} The proportion of the basket associated with each ERC20
    /// @return targets The bytes32 representations of the target unit associated with each ERC20
    /// @custom:static-call
    function basketBreakdown(IRToken rToken)
        external
        returns (
            address[] memory erc20s,
            uint192[] memory uoaShares,
            bytes32[] memory targets
        )
    {
        uint256[] memory deposits;
        IAssetRegistry assetRegistry = rToken.main().assetRegistry();
        IBasketHandler basketHandler = rToken.main().basketHandler();

        // (erc20s, deposits) = issue(rToken, FIX_ONE);

        // solhint-disable-next-line no-empty-blocks
        try rToken.main().furnace().melt() {} catch {}

        (erc20s, deposits) = basketHandler.quote(FIX_ONE, CEIL);

        // Calculate uoaAmts
        uint192 uoaSum;
        uint192[] memory uoaAmts = new uint192[](erc20s.length);
        targets = new bytes32[](erc20s.length);
        for (uint256 i = 0; i < erc20s.length; ++i) {
            ICollateral coll = assetRegistry.toColl(IERC20(erc20s[i]));
            int8 decimals = int8(IERC20Metadata(erc20s[i]).decimals());
            (uint192 lowPrice, ) = coll.price();

            // {UoA} = {qTok} * {tok/qTok} * {UoA/tok}
            uoaAmts[i] = shiftl_toFix(deposits[i], -decimals).mul(lowPrice);
            uoaSum += uoaAmts[i];
            targets[i] = coll.targetName();
        }

        uoaShares = new uint192[](erc20s.length);
        for (uint256 i = 0; i < erc20s.length; ++i) {
            uoaShares[i] = uoaAmts[i].div(uoaSum);
        }
    }

    /// @return erc20s The registered ERC20s
    /// @return balances {qTok} The held balances of each ERC20 across all traders
    /// @return balancesNeededByBackingManager {qTok} does not account for backingBuffer
    /// @custom:static-call
    function balancesAcrossAllTraders(IRToken rToken)
        external
        returns (
            IERC20[] memory erc20s,
            uint256[] memory balances,
            uint256[] memory balancesNeededByBackingManager
        )
    {
        IMain main = rToken.main();
        main.assetRegistry().refresh();
        main.furnace().melt();

        erc20s = main.assetRegistry().erc20s();
        balances = new uint256[](erc20s.length);
        balancesNeededByBackingManager = new uint256[](erc20s.length);

        uint192 basketsNeeded = rToken.basketsNeeded(); // {BU}

        for (uint256 i = 0; i < erc20s.length; ++i) {
            balances[i] = erc20s[i].balanceOf(address(main.backingManager()));
            balances[i] += erc20s[i].balanceOf(address(main.rTokenTrader()));
            balances[i] += erc20s[i].balanceOf(address(main.rsrTrader()));

            // {qTok} = {tok/BU} * {BU} * {tok} * {qTok/tok}
            uint192 balNeededFix = main.basketHandler().quantity(erc20s[i]).safeMul(
                basketsNeeded,
                RoundingMode.FLOOR // FLOOR to match redemption
            );

            balancesNeededByBackingManager[i] = balNeededFix.shiftl_toUint(
                int8(IERC20Metadata(address(erc20s[i])).decimals()),
                RoundingMode.FLOOR
            );
        }
    }

    // === Views ===

    /// @param account The account for the query
    /// @return unstakings All the pending StRSR unstakings for an account
    function pendingUnstakings(RTokenP1 rToken, address account)
        external
        view
        returns (Pending[] memory unstakings)
    {
        StRSRP1Votes stRSR = StRSRP1Votes(address(rToken.main().stRSR()));
        uint256 era = stRSR.currentEra();
        uint256 left = stRSR.firstRemainingDraft(era, account);
        uint256 right = stRSR.draftQueueLen(era, account);

        unstakings = new Pending[](right - left);
        for (uint256 i = 0; i < right - left; i++) {
            (uint192 drafts, uint64 availableAt) = stRSR.draftQueues(era, account, i + left);

            uint192 diff = drafts;
            if (i + left > 0) {
                (uint192 prevDrafts, ) = stRSR.draftQueues(era, account, i + left - 1);
                diff = drafts - prevDrafts;
            }

            unstakings[i] = Pending(i + left, availableAt, diff);
        }
    }

    /// Returns the prime basket
    /// @dev Indices are shared aross return values
    /// @return erc20s The erc20s in the prime basket
    /// @return targetNames The bytes32 name identifier of the target unit, per ERC20
    /// @return targetAmts {target/BU} The amount of the target unit in the basket, per ERC20
    function primeBasket(IRToken rToken)
        external
        view
        returns (
            IERC20[] memory erc20s,
            bytes32[] memory targetNames,
            uint192[] memory targetAmts
        )
    {
        return BasketHandlerP1(address(rToken.main().basketHandler())).getPrimeBasket();
    }

    /// @return tokens The ERC20s backing the RToken
    function basketTokens(IRToken rToken) external view returns (address[] memory tokens) {
        (tokens, ) = rToken.main().basketHandler().quote(FIX_ONE, RoundingMode.FLOOR);
    }

    /// Returns the backup configuration for a given targetName
    /// @param targetName The name of the target unit to lookup the backup for
    /// @return erc20s The backup erc20s for the target unit, in order of most to least desirable
    /// @return max The maximum number of tokens from the array to use at a single time
    function backupConfig(IRToken rToken, bytes32 targetName)
        external
        view
        returns (IERC20[] memory erc20s, uint256 max)
    {
        return BasketHandlerP1(address(rToken.main().basketHandler())).getBackupConfig(targetName);
    }

    /// @return stTokenAddress The address of the corresponding stToken for the rToken
    function stToken(IRToken rToken) external view returns (IStRSR stTokenAddress) {
        IMain main = rToken.main();
        stTokenAddress = main.stRSR();
    }

    /// @return backing {1} The worstcase collateralization % the protocol will have after trading
    /// @return overCollateralization {1} The over-collateralization value relative to the
    ///     fully-backed value as a %
    function backingOverview(IRToken rToken)
        external
        view
        returns (uint192 backing, uint192 overCollateralization)
    {
        uint256 supply = rToken.totalSupply();
        if (supply == 0) return (0, 0);

        uint192 basketsNeeded = rToken.basketsNeeded(); // {BU}
        uint192 uoaNeeded; // {UoA}
        uint192 uoaHeldInBaskets; // {UoA}
        {
            (address[] memory basketERC20s, uint256[] memory quantities) = rToken
                .main()
                .basketHandler()
                .quote(basketsNeeded, FLOOR);

            IAssetRegistry reg = rToken.main().assetRegistry();
            IBackingManager bm = rToken.main().backingManager();
            for (uint256 i = 0; i < basketERC20s.length; i++) {
                IAsset asset = reg.toAsset(IERC20(basketERC20s[i]));

                // {UoA/tok}
                (uint192 low, ) = asset.price();

                // {tok}
                uint192 needed = shiftl_toFix(quantities[i], -int8(asset.erc20Decimals()));

                // {UoA} = {UoA} + {tok}
                uoaNeeded += needed.mul(low);

                // {UoA} = {UoA} + {tok} * {UoA/tok}
                uoaHeldInBaskets += fixMin(needed, asset.bal(address(bm))).mul(low);
            }

            backing = uoaHeldInBaskets.div(uoaNeeded);
        }

        // Compute overCollateralization
        IAsset rsrAsset = rToken.main().assetRegistry().toAsset(rToken.main().rsr());

        // {tok} = {tok} + {tok}
        uint192 rsrBal = rsrAsset.bal(address(rToken.main().backingManager())).plus(
            rsrAsset.bal(address(rToken.main().stRSR()))
        );

        (uint192 lowPrice, ) = rsrAsset.price();

        // {UoA} = {tok} * {UoA/tok}
        uint192 rsrUoA = rsrBal.mul(lowPrice);

        // {1} = {UoA} / {UoA}
        overCollateralization = rsrUoA.div(uoaNeeded);
    }

    /// @return low {UoA/tok} The low price of the RToken as given by the relevant RTokenAsset
    /// @return high {UoA/tok} The high price of the RToken as given by the relevant RTokenAsset
    function price(IRToken rToken) external view returns (uint192 low, uint192 high) {
        return rToken.main().assetRegistry().toAsset(IERC20(address(rToken))).price();
    }

    /// @return erc20s The list of ERC20s that have auctions that can be settled, for given trader
    function auctionsSettleable(ITrading trader) external view returns (IERC20[] memory erc20s) {
        IERC20[] memory allERC20s = trader.main().assetRegistry().erc20s();

        // Calculate which erc20s can have auctions settled
        uint256 num;
        IERC20[] memory unfiltered = new IERC20[](allERC20s.length); // will filter down later
        for (uint256 i = 0; i < allERC20s.length; ++i) {
            ITrade trade = trader.trades(allERC20s[i]);
            if (address(trade) != address(0) && trade.canSettle()) {
                unfiltered[num] = allERC20s[i];
                ++num;
            }
        }

        // Filter down
        erc20s = new IERC20[](num);
        for (uint256 i = 0; i < num; ++i) {
            erc20s[i] = unfiltered[i];
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (governance/utils/IVotes.sol)
pragma solidity ^0.8.0;

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 *
 * _Available since v4.5._
 */
interface IVotesUpgradeable {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     */
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271Upgradeable {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
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
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
 *
 * @custom:storage-size 52
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

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
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
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
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
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
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
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
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
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
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
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
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
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
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.1) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../AddressUpgradeable.sol";
import "../../interfaces/IERC1271Upgradeable.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureCheckerUpgradeable {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSAUpgradeable.RecoverError error) = ECDSAUpgradeable.tryRecover(hash, signature);
        if (error == ECDSAUpgradeable.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271Upgradeable.isValidSignature.selector, hash, signature)
        );
        return (success &&
            result.length == 32 &&
            abi.decode(result, (bytes32)) == bytes32(IERC1271Upgradeable.isValidSignature.selector));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248) {
        require(value >= type(int248).min && value <= type(int248).max, "SafeCast: value doesn't fit in 248 bits");
        return int248(value);
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240) {
        require(value >= type(int240).min && value <= type(int240).max, "SafeCast: value doesn't fit in 240 bits");
        return int240(value);
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232) {
        require(value >= type(int232).min && value <= type(int232).max, "SafeCast: value doesn't fit in 232 bits");
        return int232(value);
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224) {
        require(value >= type(int224).min && value <= type(int224).max, "SafeCast: value doesn't fit in 224 bits");
        return int224(value);
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216) {
        require(value >= type(int216).min && value <= type(int216).max, "SafeCast: value doesn't fit in 216 bits");
        return int216(value);
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208) {
        require(value >= type(int208).min && value <= type(int208).max, "SafeCast: value doesn't fit in 208 bits");
        return int208(value);
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200) {
        require(value >= type(int200).min && value <= type(int200).max, "SafeCast: value doesn't fit in 200 bits");
        return int200(value);
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192) {
        require(value >= type(int192).min && value <= type(int192).max, "SafeCast: value doesn't fit in 192 bits");
        return int192(value);
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184) {
        require(value >= type(int184).min && value <= type(int184).max, "SafeCast: value doesn't fit in 184 bits");
        return int184(value);
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176) {
        require(value >= type(int176).min && value <= type(int176).max, "SafeCast: value doesn't fit in 176 bits");
        return int176(value);
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168) {
        require(value >= type(int168).min && value <= type(int168).max, "SafeCast: value doesn't fit in 168 bits");
        return int168(value);
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160) {
        require(value >= type(int160).min && value <= type(int160).max, "SafeCast: value doesn't fit in 160 bits");
        return int160(value);
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152) {
        require(value >= type(int152).min && value <= type(int152).max, "SafeCast: value doesn't fit in 152 bits");
        return int152(value);
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144) {
        require(value >= type(int144).min && value <= type(int144).max, "SafeCast: value doesn't fit in 144 bits");
        return int144(value);
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136) {
        require(value >= type(int136).min && value <= type(int136).max, "SafeCast: value doesn't fit in 136 bits");
        return int136(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120) {
        require(value >= type(int120).min && value <= type(int120).max, "SafeCast: value doesn't fit in 120 bits");
        return int120(value);
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112) {
        require(value >= type(int112).min && value <= type(int112).max, "SafeCast: value doesn't fit in 112 bits");
        return int112(value);
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104) {
        require(value >= type(int104).min && value <= type(int104).max, "SafeCast: value doesn't fit in 104 bits");
        return int104(value);
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96) {
        require(value >= type(int96).min && value <= type(int96).max, "SafeCast: value doesn't fit in 96 bits");
        return int96(value);
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88) {
        require(value >= type(int88).min && value <= type(int88).max, "SafeCast: value doesn't fit in 88 bits");
        return int88(value);
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80) {
        require(value >= type(int80).min && value <= type(int80).max, "SafeCast: value doesn't fit in 80 bits");
        return int80(value);
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72) {
        require(value >= type(int72).min && value <= type(int72).max, "SafeCast: value doesn't fit in 72 bits");
        return int72(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56) {
        require(value >= type(int56).min && value <= type(int56).max, "SafeCast: value doesn't fit in 56 bits");
        return int56(value);
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48) {
        require(value >= type(int48).min && value <= type(int48).max, "SafeCast: value doesn't fit in 48 bits");
        return int48(value);
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40) {
        require(value >= type(int40).min && value <= type(int40).max, "SafeCast: value doesn't fit in 40 bits");
        return int40(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= type(int24).min && value <= type(int24).max, "SafeCast: value doesn't fit in 24 bits");
        return int24(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
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
interface IERC20Permit {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableMap.sol)

pragma solidity ^0.8.0;

import "./EnumerableSet.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32`) since v4.6.0
 * - `uint256 -> uint256` (`UintToUintMap`) since v4.7.0
 * - `bytes32 -> uint256` (`Bytes32ToUintMap`) since v4.7.0
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableMap, you can either remove all elements one by one or create a fresh instance using an array of EnumerableMap.
 * ====
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Bytes32ToBytes32Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        bytes32 value
    ) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToBytes32Map storage map, bytes32 key) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Bytes32ToBytes32Map storage map) internal view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToBytes32Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function get(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), errorMessage);
        return value;
    }

    // UintToUintMap

    struct UintToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToUintMap storage map,
        uint256 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToUintMap storage map, uint256 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key)));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToUintMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key), errorMessage));
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key), errorMessage))));
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        AddressToUintMap storage map,
        address key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        AddressToUintMap storage map,
        address key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key))), errorMessage));
    }

    // Bytes32ToUintMap

    struct Bytes32ToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToUintMap storage map,
        bytes32 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, key, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToUintMap storage map, bytes32 key) internal returns (bool) {
        return remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool) {
        return contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(Bytes32ToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToUintMap storage map, uint256 index) internal view returns (bytes32, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (key, uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, key);
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToUintMap storage map, bytes32 key) internal view returns (uint256) {
        return uint256(get(map._inner, key));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToUintMap storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, key, errorMessage));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
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
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
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

        /// @solidity memory-safe-assembly
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../libraries/Fixed.sol";
import "./IMain.sol";
import "./IRewardable.sol";

// Not used directly in the IAsset interface, but used by many consumers to save stack space
struct Price {
    uint192 low; // {UoA/tok}
    uint192 high; // {UoA/tok}
}

/**
 * @title IAsset
 * @notice Supertype. Any token that interacts with our system must be wrapped in an asset,
 * whether it is used as RToken backing or not. Any token that can report a price in the UoA
 * is eligible to be an asset.
 */
interface IAsset is IRewardable {
    /// Refresh saved price
    /// The Reserve protocol calls this at least once per transaction, before relying on
    /// the Asset's other functions.
    /// @dev Called immediately after deployment, before use
    function refresh() external;

    /// Should not revert
    /// @return low {UoA/tok} The lower end of the price estimate
    /// @return high {UoA/tok} The upper end of the price estimate
    function price() external view returns (uint192 low, uint192 high);

    /// Should not revert
    /// lotLow should be nonzero when the asset might be worth selling
    /// @return lotLow {UoA/tok} The lower end of the lot price estimate
    /// @return lotHigh {UoA/tok} The upper end of the lot price estimate
    function lotPrice() external view returns (uint192 lotLow, uint192 lotHigh);

    /// @return {tok} The balance of the ERC20 in whole tokens
    function bal(address account) external view returns (uint192);

    /// @return The ERC20 contract of the token with decimals() available
    function erc20() external view returns (IERC20Metadata);

    /// @return The number of decimals in the ERC20; just for gas optimization
    function erc20Decimals() external view returns (uint8);

    /// @return If the asset is an instance of ICollateral or not
    function isCollateral() external view returns (bool);

    /// @return {UoA} The max trade volume, in UoA
    function maxTradeVolume() external view returns (uint192);

    /// @return {s} The timestamp of the last refresh() that saved prices
    function lastSave() external view returns (uint48);
}

// Used only in Testing. Strictly speaking an Asset does not need to adhere to this interface
interface TestIAsset is IAsset {
    /// @return The address of the chainlink feed
    function chainlinkFeed() external view returns (AggregatorV3Interface);

    /// {1} The max % deviation allowed by the oracle
    function oracleError() external view returns (uint192);

    /// @return {s} Seconds that an oracle value is considered valid
    function oracleTimeout() external view returns (uint48);

    /// @return {s} Seconds that the lotPrice should decay over, after stale price
    function priceTimeout() external view returns (uint48);
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
    event CollateralStatusChanged(
        CollateralStatus indexed oldStatus,
        CollateralStatus indexed newStatus
    );

    /// @dev refresh()
    /// Refresh exchange rates and update default status.
    /// VERY IMPORTANT: In any valid implemntation, status() MUST become DISABLED in refresh() if
    /// refPerTok() has ever decreased since last call.

    /// @return The canonical name of this collateral's target unit.
    function targetName() external view returns (bytes32);

    /// @return The status of this collateral asset. (Is it defaulting? Might it soon?)
    function status() external view returns (CollateralStatus);

    // ==== Exchange Rates ====

    /// @return {ref/tok} Quantity of whole reference units per whole collateral tokens
    function refPerTok() external view returns (uint192);

    /// @return {target/ref} Quantity of whole target units per whole reference unit in the peg
    function targetPerRef() external view returns (uint192);
}

// Used only in Testing. Strictly speaking a Collateral does not need to adhere to this interface
interface TestICollateral is TestIAsset, ICollateral {
    /// @return The epoch timestamp when the collateral will default from IFFY to DISABLED
    function whenDefault() external view returns (uint256);

    /// @return The amount of time a collateral must be in IFFY status until being DISABLED
    function delayUntilDefault() external view returns (uint48);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IAsset.sol";
import "./IComponent.sol";

/// A serialization of the AssetRegistry to be passed around in the P1 impl for gas optimization
struct Registry {
    IERC20[] erc20s;
    IAsset[] assets;
}

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

    /// Register `asset`
    /// If either the erc20 address or the asset was already registered, fail
    /// @return true if the erc20 address was not already registered.
    /// @custom:governance
    function register(IAsset asset) external returns (bool);

    /// Register `asset` if and only if its erc20 address is already registered.
    /// If the erc20 address was not registered, revert.
    /// @return swapped If the asset was swapped for a previously-registered asset
    /// @custom:governance
    function swapRegistered(IAsset asset) external returns (bool swapped);

    /// Unregister an asset, requiring that it is already registered
    /// @custom:governance
    function unregister(IAsset asset) external;

    /// @return {s} The timestamp of the last refresh
    function lastRefresh() external view returns (uint48);

    /// @return The corresponding asset for ERC20, or reverts if not registered
    function toAsset(IERC20 erc20) external view returns (IAsset);

    /// @return The corresponding collateral, or reverts if unregistered or not collateral
    function toColl(IERC20 erc20) external view returns (ICollateral);

    /// @return If the ERC20 is registered
    function isRegistered(IERC20 erc20) external view returns (bool);

    /// @return A list of all registered ERC20s
    function erc20s() external view returns (IERC20[] memory);

    /// @return reg The list of registered ERC20s and Assets, in the same order
    function getRegistry() external view returns (Registry memory reg);

    /// @return The number of registered ERC20s
    function size() external view returns (uint256);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IBroker.sol";
import "./IComponent.sol";
import "./ITrading.sol";

/**
 * @title IBackingManager
 * @notice The BackingManager handles changes in the ERC20 balances that back an RToken.
 *   - It computes which trades to perform, if any, and initiates these trades with the Broker.
 *     - rebalance()
 *   - If already collateralized, excess assets are transferred to RevenueTraders.
 *     - forwardRevenue(IERC20[] calldata erc20s)
 */
interface IBackingManager is IComponent, ITrading {
    /// Emitted when the trading delay is changed
    /// @param oldVal The old trading delay
    /// @param newVal The new trading delay
    event TradingDelaySet(uint48 indexed oldVal, uint48 indexed newVal);

    /// Emitted when the backing buffer is changed
    /// @param oldVal The old backing buffer
    /// @param newVal The new backing buffer
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

    /// Apply the overall backing policy using the specified TradeKind, taking a haircut if unable
    /// @param kind TradeKind.DUTCH_AUCTION or TradeKind.BATCH_AUCTION
    /// @custom:interaction RCEI
    function rebalance(TradeKind kind) external;

    /// Forward revenue to RevenueTraders; reverts if not fully collateralized
    /// @param erc20s The tokens to forward
    /// @custom:interaction RCEI
    function forwardRevenue(IERC20[] calldata erc20s) external;
}

interface TestIBackingManager is IBackingManager, TestITrading {
    function tradingDelay() external view returns (uint48);

    function backingBuffer() external view returns (uint192);

    function setTradingDelay(uint48 val) external;

    function setBackingBuffer(uint192 val) external;
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/Fixed.sol";
import "./IAsset.sol";
import "./IComponent.sol";

struct BasketRange {
    uint192 bottom; // {BU}
    uint192 top; // {BU}
}

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
    /// @param nonce {basketNonce} The basket nonce
    /// @param erc20s The list of collateral tokens in the reference basket
    /// @param refAmts {ref/BU} The reference amounts of the basket collateral tokens
    /// @param disabled True when the list of erc20s + refAmts may not be correct
    event BasketSet(uint256 indexed nonce, IERC20[] erc20s, uint192[] refAmts, bool disabled);

    /// Emitted when a backup config is set for a target unit
    /// @param targetName The name of the target unit as a bytes32
    /// @param max The max number to use from `erc20s`
    /// @param erc20s The set of backup collateral tokens
    event BackupConfigSet(bytes32 indexed targetName, uint256 indexed max, IERC20[] erc20s);

    /// Emitted when the warmup period is changed
    /// @param oldVal The old warmup period
    /// @param newVal The new warmup period
    event WarmupPeriodSet(uint48 indexed oldVal, uint48 indexed newVal);

    /// Emitted when the status of a basket has changed
    /// @param oldStatus The previous basket status
    /// @param newStatus The new basket status
    event BasketStatusChanged(
        CollateralStatus indexed oldStatus,
        CollateralStatus indexed newStatus
    );

    // Initialization
    function init(IMain main_, uint48 warmupPeriod_) external;

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

    /// Track the basket status changes
    /// @custom:refresher
    function trackStatus() external;

    /// @return If the BackingManager has sufficient collateral to redeem the entire RToken supply
    function fullyCollateralized() external view returns (bool);

    /// @return status The worst CollateralStatus of all collateral in the basket
    function status() external view returns (CollateralStatus status);

    /// @return If the basket is ready to issue and trade
    function isReady() external view returns (bool);

    /// @param erc20 The ERC20 token contract for the asset
    /// @return {tok/BU} The whole token quantity of token in the reference basket
    /// Returns 0 if erc20 is not registered or not in the basket
    /// Returns FIX_MAX (in lieu of +infinity) if Collateral.refPerTok() is 0.
    /// Otherwise, returns (token's basket.refAmts / token's Collateral.refPerTok())
    function quantity(IERC20 erc20) external view returns (uint192);

    /// Like quantity(), but unsafe because it DOES NOT CONFIRM THAT THE ASSET IS CORRECT
    /// @param erc20 The ERC20 token contract for the asset
    /// @param asset The registered asset plugin contract for the erc20
    /// @return {tok/BU} The whole token quantity of token in the reference basket
    /// Returns 0 if erc20 is not registered or not in the basket
    /// Returns FIX_MAX (in lieu of +infinity) if Collateral.refPerTok() is 0.
    /// Otherwise, returns (token's basket.refAmts / token's Collateral.refPerTok())
    function quantityUnsafe(IERC20 erc20, IAsset asset) external view returns (uint192);

    /// @param amount {BU}
    /// @return erc20s The addresses of the ERC20 tokens in the reference basket
    /// @return quantities {qTok} The quantity of each ERC20 token to issue `amount` baskets
    function quote(uint192 amount, RoundingMode rounding)
        external
        view
        returns (address[] memory erc20s, uint256[] memory quantities);

    /// Return the redemption value of `amount` BUs for a linear combination of historical baskets
    /// @param basketNonces An array of basket nonces to do redemption from
    /// @param portions {1} An array of Fix quantities that must add up to FIX_ONE
    /// @param amount {BU}
    /// @return erc20s The backing collateral erc20s
    /// @return quantities {qTok} ERC20 token quantities equal to `amount` BUs
    function quoteCustomRedemption(
        uint48[] memory basketNonces,
        uint192[] memory portions,
        uint192 amount
    ) external view returns (address[] memory erc20s, uint256[] memory quantities);

    /// @return top {BU} The number of partial basket units: e.g max(coll.map((c) => c.balAsBUs())
    ///         bottom {BU} The number of whole basket units held by the account
    function basketsHeldBy(address account) external view returns (BasketRange memory);

    /// Should not revert
    /// @return low {UoA/BU} The lower end of the price estimate
    /// @return high {UoA/BU} The upper end of the price estimate
    function price() external view returns (uint192 low, uint192 high);

    /// Should not revert
    /// lotLow should be nonzero if a BU could be worth selling
    /// @return lotLow {UoA/tok} The lower end of the lot price estimate
    /// @return lotHigh {UoA/tok} The upper end of the lot price estimate
    function lotPrice() external view returns (uint192 lotLow, uint192 lotHigh);

    /// @return timestamp The timestamp at which the basket was last set
    function timestamp() external view returns (uint48);

    /// @return The current basket nonce, regardless of status
    function nonce() external view returns (uint48);
}

interface TestIBasketHandler is IBasketHandler {
    function warmupPeriod() external view returns (uint48);

    function setWarmupPeriod(uint48 val) external;
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.17;

import "./IAsset.sol";
import "./IComponent.sol";
import "./IGnosis.sol";
import "./ITrade.sol";

enum TradeKind {
    DUTCH_AUCTION,
    BATCH_AUCTION
}

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
    event GnosisSet(IGnosis indexed oldVal, IGnosis indexed newVal);
    event BatchTradeImplementationSet(ITrade indexed oldVal, ITrade indexed newVal);
    event DutchTradeImplementationSet(ITrade indexed oldVal, ITrade indexed newVal);
    event BatchAuctionLengthSet(uint48 indexed oldVal, uint48 indexed newVal);
    event DutchAuctionLengthSet(uint48 indexed oldVal, uint48 indexed newVal);
    event DisabledSet(bool indexed prevVal, bool indexed newVal);

    // Initialization
    function init(
        IMain main_,
        IGnosis gnosis_,
        ITrade batchTradeImplemention_,
        uint48 batchAuctionLength_,
        ITrade dutchTradeImplemention_,
        uint48 dutchAuctionLength_
    ) external;

    /// Request a trade from the broker
    /// @dev Requires setting an allowance in advance
    /// @custom:interaction
    function openTrade(TradeKind kind, TradeRequest memory req) external returns (ITrade);

    /// Only callable by one of the trading contracts the broker deploys
    function reportViolation() external;

    function disabled() external view returns (bool);
}

interface TestIBroker is IBroker {
    function gnosis() external view returns (IGnosis);

    function batchTradeImplementation() external view returns (ITrade);

    function dutchTradeImplementation() external view returns (ITrade);

    function batchAuctionLength() external view returns (uint48);

    function dutchAuctionLength() external view returns (uint48);

    function setGnosis(IGnosis newGnosis) external;

    function setBatchTradeImplementation(ITrade newTradeImplementation) external;

    function setBatchAuctionLength(uint48 newAuctionLength) external;

    function setDutchTradeImplementation(ITrade newTradeImplementation) external;

    function setDutchAuctionLength(uint48 newAuctionLength) external;

    function setDisabled(bool disabled_) external;
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.17;

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
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IComponent.sol";

uint256 constant MAX_DISTRIBUTION = 1e4; // 10,000
uint8 constant MAX_DESTINATIONS = 100; // maximum number of RevenueShare destinations

struct RevenueShare {
    uint16 rTokenDist; // {revShare} A value between [0, 10,000]
    uint16 rsrDist; // {revShare} A value between [0, 10,000]
}

/// Assumes no more than 100 independent distributions.
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
    function distribute(IERC20 erc20, uint256 amount) external;

    /// @return revTotals The total of all  destinations
    function totals() external view returns (RevenueTotals memory revTotals);
}

interface TestIDistributor is IDistributor {
    // solhint-disable-next-line func-name-mixedcase
    function FURNACE() external view returns (address);

    // solhint-disable-next-line func-name-mixedcase
    function ST_RSR() external view returns (address);

    /// @return rTokenDist The RToken distribution for the address
    /// @return rsrDist The RSR distribution for the address
    function distribution(address) external view returns (uint16 rTokenDist, uint16 rsrDist);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.17;

import "../p1/RToken.sol";
import "./IRToken.sol";
import "./IStRSR.sol";

/**
 * @title IFacadeRead
 * @notice A UX-friendly layer for read operations, especially those that first require refresh()
 *
 * - @custom:static-call - Use ethers callStatic() in order to get result after update
v */
interface IFacadeRead {
    // === Static Calls ===

    /// @return How many RToken `account` can issue given current holdings
    /// @custom:static-call
    function maxIssuable(IRToken rToken, address account) external returns (uint256);

    /// @return tokens The erc20 needed for the issuance
    /// @return deposits {qTok} The deposits necessary to issue `amount` RToken
    /// @return depositsUoA {UoA} The UoA value of the deposits necessary to issue `amount` RToken
    /// @custom:static-call
    function issue(IRToken rToken, uint256 amount)
        external
        returns (
            address[] memory tokens,
            uint256[] memory deposits,
            uint192[] memory depositsUoA
        );

    /// @return tokens The erc20s returned for the redemption
    /// @return withdrawals The balances necessary to issue `amount` RToken
    /// @return isProrata True if the redemption is prorata and not full
    /// @custom:static-call
    function redeem(IRToken rToken, uint256 amount)
        external
        returns (
            address[] memory tokens,
            uint256[] memory withdrawals,
            bool isProrata
        );

    /// @return erc20s The ERC20 addresses in the current basket
    /// @return uoaShares The proportion of the basket associated with each ERC20
    /// @return targets The bytes32 representations of the target unit associated with each ERC20
    /// @custom:static-call
    function basketBreakdown(IRToken rToken)
        external
        returns (
            address[] memory erc20s,
            uint192[] memory uoaShares,
            bytes32[] memory targets
        );

    /// @return erc20s The registered ERC20s
    /// @return balances {qTok} The held balances of each ERC20 across all traders
    /// @return balancesNeededByBackingManager {qTok} does not account for backingBuffer
    /// @custom:static-call
    function balancesAcrossAllTraders(IRToken rToken)
        external
        returns (
            IERC20[] memory erc20s,
            uint256[] memory balances,
            uint256[] memory balancesNeededByBackingManager
        );

    // === Views ===

    struct Pending {
        uint256 index;
        uint256 availableAt;
        uint256 amount;
    }

    /// @param account The account for the query
    /// @return All the pending StRSR unstakings for an account
    function pendingUnstakings(RTokenP1 rToken, address account)
        external
        view
        returns (Pending[] memory);

    /// Returns the prime basket
    /// @dev Indices are shared across return values
    /// @return erc20s The erc20s in the prime basket
    /// @return targetNames The bytes32 name identifier of the target unit, per ERC20
    /// @return targetAmts {target/BU} The amount of the target unit in the basket, per ERC20
    function primeBasket(IRToken rToken)
        external
        view
        returns (
            IERC20[] memory erc20s,
            bytes32[] memory targetNames,
            uint192[] memory targetAmts
        );

    /// Returns the backup configuration for a given targetName
    /// @param targetName The name of the target unit to lookup the backup for
    /// @return erc20s The backup erc20s for the target unit, in order of most to least desirable
    /// @return max The maximum number of tokens from the array to use at a single time
    function backupConfig(IRToken rToken, bytes32 targetName)
        external
        view
        returns (IERC20[] memory erc20s, uint256 max);

    /// @return tokens The ERC20s backing the RToken
    function basketTokens(IRToken rToken) external view returns (address[] memory tokens);

    /// @return stTokenAddress The address of the corresponding stToken address
    function stToken(IRToken rToken) external view returns (IStRSR stTokenAddress);

    /// @return backing The worst-case collaterazation % the protocol will have after done trading
    /// @return overCollateralization The over-collateralization value relative to the
    ///     fully-backed value
    function backingOverview(IRToken rToken)
        external
        view
        returns (uint192 backing, uint192 overCollateralization);

    /// @return low {UoA/tok} The low price of the RToken as given by the relevant RTokenAsset
    /// @return high {UoA/tok} The high price of the RToken as given by the relevant RTokenAsset
    function price(IRToken rToken) external view returns (uint192 low, uint192 high);

    /// @return erc20s The list of ERC20s that have auctions that can be settled, for given trader
    function auctionsSettleable(ITrading trader) external view returns (IERC20[] memory erc20s);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.17;

import "../libraries/Fixed.sol";
import "./IComponent.sol";

/**
 * @title IFurnace
 * @notice A helper contract to burn RTokens slowly and permisionlessly.
 */
interface IFurnace is IComponent {
    // Initialization
    function init(IMain main_, uint192 ratio_) external;

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
pragma solidity 0.8.17;

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
pragma solidity 0.8.17;

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

// Warning, assumption: Chain should have blocktimes of 12s
// See docs/system-design.md for discussion of handling longer or shorter times
uint48 constant ONE_BLOCK = 12; //{s}

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

    /// Emitted when the system is paused or unpaused for trading
    /// @param oldVal The old value of `tradingPaused`
    /// @param newVal The new value of `tradingPaused`
    event TradingPausedSet(bool indexed oldVal, bool indexed newVal);

    /// Emitted when the system is paused or unpaused for issuance
    /// @param oldVal The old value of `issuancePaused`
    /// @param newVal The new value of `issuancePaused`
    event IssuancePausedSet(bool indexed oldVal, bool indexed newVal);

    /**
     * Trading Paused: Disable everything except for OWNER actions, RToken.issue, RToken.redeem,
     * StRSR.stake, and StRSR.payoutRewards
     * Issuance Paused: Disable RToken.issue
     * Frozen: Disable everything except for OWNER actions + StRSR.stake (for governance)
     */

    function tradingPausedOrFrozen() external view returns (bool);

    function issuancePausedOrFrozen() external view returns (bool);

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

    function pauseTrading() external;

    function unpauseTrading() external;

    function pauseIssuance() external;

    function unpauseIssuance() external;
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

    function tradingPaused() external view returns (bool);

    function issuancePaused() external view returns (bool);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.17;

import "./IBroker.sol";
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

    /// Process a single token
    /// @dev Intended to be used with multicall
    /// @param erc20 The ERC20 token to manage; can be tokenToBuy or anything registered
    /// @param kind TradeKind.DUTCH_AUCTION or TradeKind.BATCH_AUCTION
    /// @custom:interaction
    function manageToken(IERC20 erc20, TradeKind kind) external;

    /// Distribute tokenToBuy to its destinations
    /// @dev Special-case of manageToken(tokenToBuy, *)
    /// @custom:interaction
    function distributeTokenToBuy() external;
}

// solhint-disable-next-line no-empty-blocks
interface TestIRevenueTrader is IRevenueTrader, TestITrading {
    function tokenToBuy() external view returns (IERC20);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IComponent.sol";
import "./IMain.sol";

/**
 * @title IRewardable
 * @notice A simple interface mixin to support claiming of rewards.
 */
interface IRewardable {
    /// Emitted whenever a reward token balance is claimed
    event RewardsClaimed(IERC20 indexed erc20, uint256 indexed amount);

    /// Claim rewards earned by holding a balance of the ERC20 token
    /// Must emit `RewardsClaimed` for each token rewards are claimed for
    /// @custom:interaction
    function claimRewards() external;
}

/**
 * @title IRewardableComponent
 * @notice A simple interface mixin to support claiming of rewards.
 */
interface IRewardableComponent is IRewardable {
    /// Claim rewards for a single ERC20
    /// Must emit `RewardsClaimed` for each token rewards are claimed for
    /// @custom:interaction
    function claimRewardsSingle(IERC20 erc20) external;
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
// solhint-disable-next-line max-line-length
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";
import "../libraries/Fixed.sol";
import "../libraries/Throttle.sol";
import "./IAsset.sol";
import "./IComponent.sol";
import "./IMain.sol";
import "./IRewardable.sol";

/**
 * @title IRToken
 * @notice An RToken is an ERC20 that is permissionlessly issuable/redeemable and tracks an
 *   exchange rate against a single unit: baskets, or {BU} in our type notation.
 */
interface IRToken is IComponent, IERC20MetadataUpgradeable, IERC20PermitUpgradeable {
    /// Emitted when an issuance of RToken occurs, whether it occurs via slow minting or not
    /// @param issuer The address holding collateral tokens
    /// @param recipient The address of the recipient of the RTokens
    /// @param amount The quantity of RToken being issued
    /// @param baskets The corresponding number of baskets
    event Issuance(
        address indexed issuer,
        address indexed recipient,
        uint256 indexed amount,
        uint192 baskets
    );

    /// Emitted when a redemption of RToken occurs
    /// @param redeemer The address holding RToken
    /// @param recipient The address of the account receiving the backing collateral tokens
    /// @param amount The quantity of RToken being redeemed
    /// @param baskets The corresponding number of baskets
    /// @param amount {qRTok} The amount of RTokens canceled
    event Redemption(
        address indexed redeemer,
        address indexed recipient,
        uint256 indexed amount,
        uint192 baskets
    );

    /// Emitted when the number of baskets needed changes
    /// @param oldBasketsNeeded Previous number of baskets units needed
    /// @param newBasketsNeeded New number of basket units needed
    event BasketsNeededChanged(uint192 oldBasketsNeeded, uint192 newBasketsNeeded);

    /// Emitted when RToken is melted, i.e the RToken supply is decreased but basketsNeeded is not
    /// @param amount {qRTok}
    event Melted(uint256 amount);

    /// Emitted when issuance SupplyThrottle params are set
    event IssuanceThrottleSet(ThrottleLib.Params oldVal, ThrottleLib.Params newVal);

    /// Emitted when redemption SupplyThrottle params are set
    event RedemptionThrottleSet(ThrottleLib.Params oldVal, ThrottleLib.Params newVal);

    // Initialization
    function init(
        IMain main_,
        string memory name_,
        string memory symbol_,
        string memory mandate_,
        ThrottleLib.Params calldata issuanceThrottleParams,
        ThrottleLib.Params calldata redemptionThrottleParams
    ) external;

    /// Issue an RToken with basket collateral
    /// @param amount {qRTok} The quantity of RToken to issue
    /// @custom:interaction
    function issue(uint256 amount) external;

    /// Issue an RToken with basket collateral, to a particular recipient
    /// @param recipient The address to receive the issued RTokens
    /// @param amount {qRTok} The quantity of RToken to issue
    /// @custom:interaction
    function issueTo(address recipient, uint256 amount) external;

    /// Redeem RToken for basket collateral
    /// @dev Use redeemCustom for non-current baskets
    /// @param amount {qRTok} The quantity {qRToken} of RToken to redeem
    /// @custom:interaction
    function redeem(uint256 amount) external;

    /// Redeem RToken for basket collateral to a particular recipient
    /// @dev Use redeemCustom for non-current baskets
    /// @param recipient The address to receive the backing collateral tokens
    /// @param amount {qRTok} The quantity {qRToken} of RToken to redeem
    /// @custom:interaction
    function redeemTo(address recipient, uint256 amount) external;

    /// Redeem RToken for a linear combination of historical baskets, to a particular recipient
    /// @dev Allows partial redemptions up to the minAmounts
    /// @param recipient The address to receive the backing collateral tokens
    /// @param amount {qRTok} The quantity {qRToken} of RToken to redeem
    /// @param basketNonces An array of basket nonces to do redemption from
    /// @param portions {1} An array of Fix quantities that must add up to FIX_ONE
    /// @param expectedERC20sOut An array of ERC20s expected out
    /// @param minAmounts {qTok} The minimum ERC20 quantities the caller should receive
    /// @custom:interaction
    function redeemCustom(
        address recipient,
        uint256 amount,
        uint48[] memory basketNonces,
        uint192[] memory portions,
        address[] memory expectedERC20sOut,
        uint256[] memory minAmounts
    ) external returns (address[] memory erc20sOut, uint256[] memory amountsOut);

    /// Mint an amount of RToken equivalent to baskets BUs, scaling basketsNeeded up
    /// Callable only by BackingManager
    /// @param baskets {BU} The number of baskets to mint RToken for
    /// @custom:protected
    function mint(uint192 baskets) external;

    /// Melt a quantity of RToken from the caller's account
    /// @param amount {qRTok} The amount to be melted
    /// @custom:protected
    function melt(uint256 amount) external;

    /// Burn an amount of RToken from caller's account and scale basketsNeeded down
    /// Callable only by BackingManager
    /// @custom:protected
    function dissolve(uint256 amount) external;

    /// Set the number of baskets needed directly, callable only by the BackingManager
    /// @param basketsNeeded {BU} The number of baskets to target
    ///                      needed range: pretty interesting
    /// @custom:protected
    function setBasketsNeeded(uint192 basketsNeeded) external;

    /// @return {BU} How many baskets are being targeted
    function basketsNeeded() external view returns (uint192);

    /// @return {qRTok} The maximum issuance that can be performed in the current block
    function issuanceAvailable() external view returns (uint256);

    /// @return {qRTok} The maximum redemption that can be performed in the current block
    function redemptionAvailable() external view returns (uint256);
}

interface TestIRToken is IRToken {
    function setIssuanceThrottleParams(ThrottleLib.Params calldata) external;

    function setRedemptionThrottleParams(ThrottleLib.Params calldata) external;

    function issuanceThrottleParams() external view returns (ThrottleLib.Params memory);

    function redemptionThrottleParams() external view returns (ThrottleLib.Params memory);

    function increaseAllowance(address, uint256) external returns (bool);

    function decreaseAllowance(address, uint256) external returns (bool);

    function monetizeDonations(IERC20) external;
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
// solhint-disable-next-line max-line-length
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";
import "../libraries/Fixed.sol";
import "./IComponent.sol";
import "./IMain.sol";

/**
 * @title IStRSR
 * @notice An ERC20 token representing shares of the RSR over-collateralization pool.
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

    /// Emitted when RSR unstaking is cancelled
    /// @param firstId The beginning of the range of draft IDs withdrawn in this transaction
    /// @param endId The end of range of draft IDs withdrawn in this transaction
    ///   (ID i was withdrawn if firstId <= i < endId)
    /// @param draftEra The era of the draft.
    ///   The triple (staker, draftEra, id) is a unique ID among drafts
    /// @param staker The address of the unstaker

    /// @param rsrAmount {qRSR} How much RSR this unstaking was worth
    event UnstakingCancelled(
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
    event RewardRatioSet(uint192 indexed oldVal, uint192 indexed newVal);
    event WithdrawalLeakSet(uint192 indexed oldVal, uint192 indexed newVal);

    // Initialization
    function init(
        IMain main_,
        string memory name_,
        string memory symbol_,
        uint48 unstakingDelay_,
        uint192 rewardRatio_,
        uint192 withdrawalLeak_
    ) external;

    /// Gather and payout rewards from rsrTrader
    /// @custom:interaction
    function payoutRewards() external;

    /// Stakes an RSR `amount` on the corresponding RToken to earn yield and over-collateralized
    /// the system
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

    /// Cancel unstaking for the account, up to (but not including!) `endId`
    /// @custom:interaction
    function cancelUnstake(uint256 endId) external;

    /// Seize RSR, only callable by main.backingManager()
    /// @custom:protected
    function seizeRSR(uint256 amount) external;

    /// Return the maximum valid value of endId such that withdraw(endId) should immediately work
    function endIdForWithdraw(address account) external view returns (uint256 endId);

    /// @return {qRSR/qStRSR} The exchange rate between RSR and StRSR
    function exchangeRate() external view returns (uint192);
}

interface TestIStRSR is IStRSR {
    function rewardRatio() external view returns (uint192);

    function setRewardRatio(uint192) external;

    function unstakingDelay() external view returns (uint48);

    function setUnstakingDelay(uint48) external;

    function withdrawalLeak() external view returns (uint192);

    function setWithdrawalLeak(uint192) external;

    function increaseAllowance(address, uint256) external returns (bool);

    function decreaseAllowance(address, uint256) external returns (bool);

    /// @return {qStRSR/qRSR} The exchange rate between StRSR and RSR
    function exchangeRate() external view returns (uint192);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/governance/utils/IVotesUpgradeable.sol";

interface IStRSRVotes is IVotesUpgradeable {
    /// @return The current era
    function currentEra() external view returns (uint256);

    /// @return The era at a past block number
    function getPastEra(uint256 blockNumber) external view returns (uint256);

    /// Stakes an RSR `amount` on the corresponding RToken and allows to delegate
    /// votes from the sender to `delegatee` or self
    function stakeAndDelegate(uint256 amount, address delegatee) external;
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./IBroker.sol";

enum TradeStatus {
    NOT_STARTED, // before init()
    OPEN, // after init() and before settle()
    CLOSED, // after settle()
    // === Intermediate-tx state ===
    PENDING // during init() or settle() (reentrancy protection)
}

/**
 * Simple generalized trading interface for all Trade contracts to obey
 *
 * Usage: if (canSettle()) settle()
 */
interface ITrade {
    /// Complete the trade and transfer tokens back to the origin trader
    /// @return soldAmt {qSellTok} The quantity of tokens sold
    /// @return boughtAmt {qBuyTok} The quantity of tokens bought
    function settle() external returns (uint256 soldAmt, uint256 boughtAmt);

    function sell() external view returns (IERC20Metadata);

    function buy() external view returns (IERC20Metadata);

    /// @return The timestamp at which the trade is projected to become settle-able
    function endTime() external view returns (uint48);

    /// @return True if the trade can be settled
    /// @dev Should be guaranteed to be true eventually as an invariant
    function canSettle() external view returns (bool);

    /// @return TradeKind.DUTCH_AUCTION or TradeKind.BATCH_AUCTION
    // solhint-disable-next-line func-name-mixedcase
    function KIND() external view returns (TradeKind);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/Fixed.sol";
import "./IAsset.sol";
import "./IComponent.sol";
import "./ITrade.sol";
import "./IRewardable.sol";

/**
 * @title ITrading
 * @notice Common events and refresher function for all Trading contracts
 */
interface ITrading is IComponent, IRewardableComponent {
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
    /// @param sell The sell token in the trade
    /// @return The trade settled
    /// @custom:refresher
    function settleTrade(IERC20 sell) external returns (ITrade);

    /// @return {%} The maximum trade slippage acceptable
    function maxTradeSlippage() external view returns (uint192);

    /// @return {UoA} The minimum trade volume in UoA, applies to all assets
    function minTradeVolume() external view returns (uint192);

    /// @return The ongoing trade for a sell token, or the zero address
    function trades(IERC20 sell) external view returns (ITrade);

    /// @return The number of ongoing trades open
    function tradesOpen() external view returns (uint48);

    /// Light wrapper around FixLib.mulDiv to support try-catch
    function mulDiv(
        uint192 x,
        uint192 y,
        uint192 z,
        RoundingMode rounding
    ) external pure returns (uint192);
}

interface TestITrading is ITrading {
    /// @custom:governance
    function setMaxTradeSlippage(uint192 val) external;

    /// @custom:governance
    function setMinTradeVolume(uint192 val) external;
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.17;

interface IVersioned {
    function version() external view returns (string memory);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library ArrayLib {
    /// O(n^2)
    /// @return If the array contains all unique addresses
    function allUnique(IERC20[] memory arr) internal pure returns (bool) {
        uint256 arrLen = arr.length;
        for (uint256 i = 1; i < arrLen; ++i) {
            for (uint256 j = 0; j < i; ++j) {
                if (arr[i] == arr[j]) return false;
            }
        }
        return true;
    }

    /// O(n) -- must already be in sorted ascending order!
    /// @return If the array contains all unique addresses, in ascending order
    function sortedAndAllUnique(IERC20[] memory arr) internal pure returns (bool) {
        uint256 arrLen = arr.length;
        for (uint256 i = 1; i < arrLen; ++i) {
            if (uint160(address(arr[i])) <= uint160(address(arr[i - 1]))) return false;
        }
        return true;
    }
}

// SPDX-License-Identifier: BlueOak-1.0.0
// solhint-disable func-name-mixedcase func-visibility
pragma solidity ^0.8.17;

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
bytes32 constant UIntOutofBoundsHash = keccak256(abi.encodeWithSignature("UIntOutOfBounds()"));

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
   See: https://docs.soliditylang.org/en/v0.8.17/080-breaking-changes.html#new-restrictions
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
    // conditions for avoiding overflow
    if (x == 0) return 0;
    if (shiftLeft <= -96) return (rounding == CEIL ? 1 : 0); // 0 < uint.max / 10**77 < 0.5
    if (40 <= shiftLeft) revert UIntOutOfBounds(); // 10**56 < FIX_MAX < 10**57

    shiftLeft += 18;

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
        // Handle overflow cases
        if (x == 0) return 0;
        if (decimals <= -59) return (rounding == CEIL ? 1 : 0); // 59, because 1e58 > 2**192
        if (58 <= decimals) revert UIntOutOfBounds(); // 58, because x * 1e58 > 2 ** 192 if x != 0

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

    /// Raise this uint192 to a nonnegative integer power. Requires that x_ <= FIX_ONE
    /// Gas cost is O(lg(y)), precision is +- 1e-18.
    /// @return x_ ** y
    // as-ints: x_ ** y / 1e18**(y-1)    <- technically correct for y = 0. :D
    function powu(uint192 x_, uint48 y) internal pure returns (uint192) {
        require(x_ <= FIX_ONE);
        if (y == 1) return x_;
        if (x_ == FIX_ONE || y == 0) return FIX_ONE;
        uint256 x = uint256(x_) * FIX_SCALE; // x is D36
        uint256 result = FIX_SCALE_SQ; // result is D36
        while (true) {
            if (y & 1 == 1) result = (result * x + FIX_SCALE_SQ / 2) / FIX_SCALE_SQ;
            if (y <= 1) break;
            y = (y >> 1);
            x = (x * x + FIX_SCALE_SQ / 2) / FIX_SCALE_SQ;
        }
        return _safeWrap(result / FIX_SCALE);
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
        // Handle overflow cases
        if (x == 0) return 0; // always computable, no matter what decimals is
        if (decimals <= -42) return (rounding == CEIL ? 1 : 0);
        if (96 <= decimals) revert UIntOutOfBounds();

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

    // === safe*() ===

    /// Multiply two fixes, rounding up to FIX_MAX and down to 0
    /// @param a First param to multiply
    /// @param b Second param to multiply
    function safeMul(
        uint192 a,
        uint192 b,
        RoundingMode rounding
    ) internal pure returns (uint192) {
        // untestable:
        //      a will never = 0 here because of the check in _price()
        if (a == 0 || b == 0) return 0;
        // untestable:
        //      a = FIX_MAX iff b = 0
        if (a == FIX_MAX || b == FIX_MAX) return FIX_MAX;

        // return FIX_MAX instead of throwing overflow errors.
        unchecked {
            // p and mul *are* Fix values, so have 18 decimals (D18)
            uint256 rawDelta = uint256(b) * a; // {D36} = {D18} * {D18}
            // if we overflowed, then return FIX_MAX
            if (rawDelta / b != a) return FIX_MAX;
            uint256 shiftDelta = rawDelta;

            // add in rounding
            if (rounding == RoundingMode.ROUND) shiftDelta += (FIX_ONE / 2);
            else if (rounding == RoundingMode.CEIL) shiftDelta += FIX_ONE - 1;

            // untestable (here there be dragons):
            // (below explanation is for the ROUND case, but it extends to the FLOOR/CEIL too)
            //          A)  shiftDelta = rawDelta + (FIX_ONE / 2)
            //      shiftDelta overflows if:
            //          B)  shiftDelta = MAX_UINT256 - FIX_ONE/2 + 1
            //              rawDelta + (FIX_ONE/2) = MAX_UINT256 - FIX_ONE/2 + 1
            //              b * a = MAX_UINT256 - FIX_ONE + 1
            //      therefore shiftDelta overflows if:
            //          C)  b = (MAX_UINT256 - FIX_ONE + 1) / a
            //      MAX_UINT256 ~= 1e77 , FIX_MAX ~= 6e57 (6e20 difference in magnitude)
            //      a <= 1e21 (MAX_TARGET_AMT)
            //      a must be between 1e19 & 1e20 in order for b in (C) to be uint192,
            //      but a would have to be < 1e18 in order for (A) to overflow
            if (shiftDelta < rawDelta) return FIX_MAX;

            // return FIX_MAX if return result would truncate
            if (shiftDelta / FIX_ONE > FIX_MAX) return FIX_MAX;

            // return _div(rawDelta, FIX_ONE, rounding)
            return uint192(shiftDelta / FIX_ONE); // {D18} = {D36} / {D18}
        }
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
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";

/// Internal library for verifying metatx sigs for EOAs and smart contract wallets
/// See ERC1271
library PermitLib {
    function requireSignature(
        address owner,
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view {
        if (AddressUpgradeable.isContract(owner)) {
            require(
                IERC1271Upgradeable(owner).isValidSignature(hash, abi.encodePacked(r, s, v)) ==
                    0x1626ba7e,
                "ERC1271: Unauthorized"
            );
        } else {
            require(
                SignatureCheckerUpgradeable.isValidSignatureNow(
                    owner,
                    hash,
                    abi.encodePacked(r, s, v)
                ),
                "ERC20Permit: invalid signature"
            );
        }
    }
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.17;

import "./Fixed.sol";

uint48 constant ONE_HOUR = 3600; // {seconds/hour}

/**
 * @title ThrottleLib
 * A library that implements a usage throttle that can be used to ensure net issuance
 * or net redemption for an RToken never exceeds some bounds per unit time (hour).
 *
 * It is expected for the RToken to use this library with two instances, one for issuance
 * and one for redemption. Issuance causes the available redemption amount to increase, and
 * visa versa.
 */
library ThrottleLib {
    using FixLib for uint192;

    struct Params {
        uint256 amtRate; // {qRTok/hour} a quantity of RToken hourly; cannot be 0
        uint192 pctRate; // {1/hour} a fraction of RToken hourly; can be 0
    }

    struct Throttle {
        // === Gov params ===
        Params params;
        // === Cache ===
        uint48 lastTimestamp; // {seconds}
        uint256 lastAvailable; // {qRTok}
    }

    /// Reverts if usage amount exceeds available amount
    /// @param supply {qRTok} Total RToken supply beforehand
    /// @param amount {qRTok} Amount of RToken to use. Should be negative for the issuance
    ///   throttle during redemption and for the redemption throttle during issuance.
    function useAvailable(
        Throttle storage throttle,
        uint256 supply,
        int256 amount
    ) internal {
        // untestable: amtRate will always be greater > 0 due to previous validations
        if (throttle.params.amtRate == 0 && throttle.params.pctRate == 0) return;

        // Calculate hourly limit
        uint256 limit = hourlyLimit(throttle, supply); // {qRTok}

        // Calculate available amount before supply change
        uint256 available = currentlyAvailable(throttle, limit);

        // Calculate available amount after supply change
        if (amount > 0) {
            require(uint256(amount) <= available, "supply change throttled");
            available -= uint256(amount);
            // untestable: the final else statement, amount will never be 0
        } else if (amount < 0) {
            available += uint256(-amount);
        }

        // Update cached values
        throttle.lastAvailable = available;
        throttle.lastTimestamp = uint48(block.timestamp);
    }

    /// @param limit {qRTok/hour} The hourly limit
    /// @return available {qRTok} Amount currently available for consumption
    function currentlyAvailable(Throttle storage throttle, uint256 limit)
        internal
        view
        returns (uint256 available)
    {
        uint48 delta = uint48(block.timestamp) - throttle.lastTimestamp; // {seconds}
        available = throttle.lastAvailable + (limit * delta) / ONE_HOUR;
        if (available > limit) available = limit;
    }

    /// @return limit {qRTok} The hourly limit
    function hourlyLimit(Throttle storage throttle, uint256 supply)
        internal
        view
        returns (uint256 limit)
    {
        Params storage params = throttle.params;

        // Calculate hourly limit as: max(params.amtRate, supply.mul(params.pctRate))
        limit = (supply * params.pctRate) / FIX_ONE_256; // {qRTok}
        if (params.amtRate > limit) limit = params.amtRate;
    }
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.17;

import "../interfaces/IVersioned.sol";

// This value should be updated on each release
string constant VERSION = "3.0.0";

/**
 * @title Versioned
 * @notice A mix-in to track semantic versioning uniformly across contracts.
 */
abstract contract Versioned is IVersioned {
    function version() public pure virtual override returns (string memory) {
        return VERSION;
    }
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../interfaces/IAssetRegistry.sol";
import "../interfaces/IBasketHandler.sol";
import "../interfaces/IMain.sol";
import "../libraries/Array.sol";
import "../libraries/Fixed.sol";
import "./mixins/BasketLib.sol";
import "./mixins/Component.sol";

/**
 * @title BasketHandler
 * @notice Handles the basket configuration, definition, and evolution over time.
 */
contract BasketHandlerP1 is ComponentP1, IBasketHandler {
    using BasketLibP1 for Basket;
    using EnumerableMap for EnumerableMap.Bytes32ToUintMap;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using CollateralStatusComparator for CollateralStatus;
    using FixLib for uint192;

    uint192 public constant MAX_TARGET_AMT = 1e3 * FIX_ONE; // {target/BU} max basket weight
    uint48 public constant MIN_WARMUP_PERIOD = 60; // {s} 1 minute
    uint48 public constant MAX_WARMUP_PERIOD = 31536000; // {s} 1 year

    // Peer components
    IAssetRegistry private assetRegistry;
    IBackingManager private backingManager;
    IERC20 private rsr;
    IRToken private rToken;
    IStRSR private stRSR;

    // config is the basket configuration, from which basket will be computed in a basket-switch
    // event. config is only modified by governance through setPrimeBakset and setBackupConfig
    BasketConfig private config;

    // basket, disabled, nonce, and timestamp are only ever set by `_switchBasket()`
    // basket is the current basket.
    Basket private basket;

    uint48 public nonce; // {basketNonce} A unique identifier for this basket instance
    uint48 public timestamp; // The timestamp when this basket was last set

    // If disabled is true, status() is DISABLED, the basket is invalid,
    // and everything except redemption should be paused.
    bool private disabled;

    // === Function-local transitory vars ===

    // These are effectively local variables of _switchBasket.
    // Nothing should use their values from previous transactions.
    EnumerableSet.Bytes32Set private _targetNames;
    Basket private _newBasket;

    // === Warmup Period ===
    // Added in 3.0.0

    // Warmup Period
    uint48 public warmupPeriod; // {s} how long to wait until issuance/trading after regaining SOUND

    // basket status changes, mainly set when `trackStatus()` is called
    // used to enforce warmup period, after regaining SOUND
    uint48 private lastStatusTimestamp;
    CollateralStatus private lastStatus;

    // === Historical basket nonces ===
    // Added in 3.0.0

    // A history of baskets by basket nonce; includes current basket
    mapping(uint48 => Basket) private basketHistory;

    // Effectively local variable of `requireConstantConfigTargets()`
    EnumerableMap.Bytes32ToUintMap private _targetAmts; // targetName -> {target/BU}

    // ===

    // ==== Invariants ====
    // basket is a valid Basket:
    //   basket.erc20s is a valid collateral array and basket.erc20s == keys(basket.refAmts)
    // config is a valid BasketConfig:
    //   erc20s == keys(targetAmts) == keys(targetNames)
    //   erc20s is a valid collateral array
    //   for b in vals(backups), b.erc20s is a valid collateral array.
    // if basket.erc20s is empty then disabled == true

    // BasketHandler.init() just leaves the BasketHandler state zeroed
    function init(IMain main_, uint48 warmupPeriod_) external initializer {
        __Component_init(main_);

        assetRegistry = main_.assetRegistry();
        backingManager = main_.backingManager();
        rsr = main_.rsr();
        rToken = main_.rToken();
        stRSR = main_.stRSR();

        setWarmupPeriod(warmupPeriod_);

        // Set last status to DISABLED (default)
        lastStatus = CollateralStatus.DISABLED;
        lastStatusTimestamp = uint48(block.timestamp);

        disabled = true;
    }

    /// Disable the basket in order to schedule a basket refresh
    /// @custom:protected
    // checks: caller is assetRegistry
    // effects: disabled' = true
    function disableBasket() external {
        require(_msgSender() == address(assetRegistry), "asset registry only");

        uint256 len = basket.erc20s.length;
        uint192[] memory refAmts = new uint192[](len);
        for (uint256 i = 0; i < len; ++i) refAmts[i] = basket.refAmts[basket.erc20s[i]];
        emit BasketSet(nonce, basket.erc20s, refAmts, true);
        disabled = true;
    }

    /// Switch the basket, only callable directly by governance or after a default
    /// @custom:interaction OR @custom:governance
    // checks: either caller has OWNER,
    //         or (basket is disabled after refresh and we're unpaused and unfrozen)
    // actions: calls assetRegistry.refresh(), then _switchBasket()
    // effects:
    //   Either: (basket' is a valid nonempty basket, without DISABLED collateral,
    //            that satisfies basketConfig) and disabled' = false
    //   Or no such basket exists and disabled' = true
    function refreshBasket() external {
        assetRegistry.refresh();

        require(
            main.hasRole(OWNER, _msgSender()) ||
                (status() == CollateralStatus.DISABLED && !main.tradingPausedOrFrozen()),
            "basket unrefreshable"
        );
        _switchBasket();

        trackStatus();
    }

    /// Track basket status changes if they ocurred
    // effects: lastStatus' = status(), and lastStatusTimestamp' = current timestamp
    /// @custom:refresher
    function trackStatus() public {
        CollateralStatus currentStatus = status();
        if (currentStatus != lastStatus) {
            emit BasketStatusChanged(lastStatus, currentStatus);
            lastStatus = currentStatus;
            lastStatusTimestamp = uint48(block.timestamp);
        }
    }

    /// Set the prime basket in the basket configuration, in terms of erc20s and target amounts
    /// @param erc20s The collateral for the new prime basket
    /// @param targetAmts The target amounts (in) {target/BU} for the new prime basket
    /// @custom:governance
    // checks:
    //   caller is OWNER
    //   len(erc20s) == len(targetAmts)
    //   erc20s is a valid collateral array
    //   for all i, erc20[i] is in AssetRegistry as collateral
    //   for all i, 0 < targetAmts[i] <= MAX_TARGET_AMT == 1000
    //
    // effects:
    //   config'.erc20s = erc20s
    //   config'.targetAmts[erc20s[i]] = targetAmts[i], for i from 0 to erc20s.length-1
    //   config'.targetNames[e] = assetRegistry.toColl(e).targetName, for e in erc20s
    function setPrimeBasket(IERC20[] calldata erc20s, uint192[] calldata targetAmts)
        external
        governance
    {
        require(erc20s.length > 0, "cannot empty basket");
        require(erc20s.length == targetAmts.length, "must be same length");
        requireValidCollArray(erc20s);

        // If this isn't initial setup, require targets remain constant
        if (config.erc20s.length > 0) requireConstantConfigTargets(erc20s, targetAmts);

        // Clean up previous basket config
        for (uint256 i = 0; i < config.erc20s.length; ++i) {
            delete config.targetAmts[config.erc20s[i]];
            delete config.targetNames[config.erc20s[i]];
        }
        delete config.erc20s;

        // Set up new config basket
        bytes32[] memory names = new bytes32[](erc20s.length);

        for (uint256 i = 0; i < erc20s.length; ++i) {
            // This is a nice catch to have, but in general it is possible for
            // an ERC20 in the prime basket to have its asset unregistered.
            require(assetRegistry.toAsset(erc20s[i]).isCollateral(), "erc20 is not collateral");
            require(0 < targetAmts[i], "invalid target amount; must be nonzero");
            require(targetAmts[i] <= MAX_TARGET_AMT, "invalid target amount; too large");

            config.erc20s.push(erc20s[i]);
            config.targetAmts[erc20s[i]] = targetAmts[i];
            names[i] = assetRegistry.toColl(erc20s[i]).targetName();
            config.targetNames[erc20s[i]] = names[i];
        }

        emit PrimeBasketSet(erc20s, targetAmts, names);
    }

    /// Set the backup configuration for some target name
    /// @custom:governance
    // checks:
    //   caller is OWNER
    //   erc20s is a valid collateral array
    //   for all i, erc20[i] is in AssetRegistry as collateral
    //
    // effects:
    //   config'.backups[targetName] = {max: max, erc20s: erc20s}
    function setBackupConfig(
        bytes32 targetName,
        uint256 max,
        IERC20[] calldata erc20s
    ) external governance {
        requireValidCollArray(erc20s);
        BackupConfig storage conf = config.backups[targetName];
        conf.max = max;
        delete conf.erc20s;

        for (uint256 i = 0; i < erc20s.length; ++i) {
            // This is a nice catch to have, but in general it is possible for
            // an ERC20 in the backup config to have its asset altered.
            require(assetRegistry.toAsset(erc20s[i]).isCollateral(), "erc20 is not collateral");
            conf.erc20s.push(erc20s[i]);
        }
        emit BackupConfigSet(targetName, max, erc20s);
    }

    /// @return Whether this contract owns enough collateral to cover rToken.basketsNeeded() BUs
    /// ie, whether the protocol is currently fully collateralized
    function fullyCollateralized() external view returns (bool) {
        BasketRange memory held = basketsHeldBy(address(backingManager));
        return held.bottom >= rToken.basketsNeeded();
    }

    /// @return status_ The status of the basket
    // returns DISABLED if disabled == true, and worst(status(coll)) otherwise
    function status() public view returns (CollateralStatus status_) {
        uint256 size = basket.erc20s.length;

        // untestable:
        //      disabled is only set in _switchBasket, and only if size > 0.
        if (disabled || size == 0) return CollateralStatus.DISABLED;

        for (uint256 i = 0; i < size; ++i) {
            CollateralStatus s = assetRegistry.toColl(basket.erc20s[i]).status();
            if (s.worseThan(status_)) status_ = s;
        }
    }

    /// @return Whether the basket is ready to issue and trade
    function isReady() external view returns (bool) {
        return
            status() == CollateralStatus.SOUND &&
            (block.timestamp >= lastStatusTimestamp + warmupPeriod);
    }

    /// @param erc20 The token contract to check for quantity for
    /// @return {tok/BU} The token-quantity of an ERC20 token in the basket.
    // Returns 0 if erc20 is not registered or not in the basket
    // Returns FIX_MAX (in lieu of +infinity) if Collateral.refPerTok() is 0.
    // Otherwise returns (token's basket.refAmts / token's Collateral.refPerTok())
    function quantity(IERC20 erc20) public view returns (uint192) {
        try assetRegistry.toColl(erc20) returns (ICollateral coll) {
            return _quantity(erc20, coll);
        } catch {
            return FIX_ZERO;
        }
    }

    /// Like quantity(), but unsafe because it DOES NOT CONFIRM THAT THE ASSET IS CORRECT
    /// @param erc20 The ERC20 token contract for the asset
    /// @param asset The registered asset plugin contract for the erc20
    /// @return {tok/BU} The token-quantity of an ERC20 token in the basket.
    // Returns 0 if erc20 is not registered or not in the basket
    // Returns FIX_MAX (in lieu of +infinity) if Collateral.refPerTok() is 0.
    // Otherwise returns (token's basket.refAmts / token's Collateral.refPerTok())
    function quantityUnsafe(IERC20 erc20, IAsset asset) public view returns (uint192) {
        if (!asset.isCollateral()) return FIX_ZERO;
        return _quantity(erc20, ICollateral(address(asset)));
    }

    /// @param erc20 The token contract
    /// @param coll The registered collateral plugin contract
    /// @return {tok/BU} The token-quantity of an ERC20 token in the basket.
    // Returns 0 if coll is not in the basket
    // Returns FIX_MAX (in lieu of +infinity) if Collateral.refPerTok() is 0.
    // Otherwise returns (token's basket.refAmts / token's Collateral.refPerTok())
    function _quantity(IERC20 erc20, ICollateral coll) internal view returns (uint192) {
        uint192 refPerTok = coll.refPerTok();
        if (refPerTok == 0) return FIX_MAX;

        // {tok/BU} = {ref/BU} / {ref/tok}
        return basket.refAmts[erc20].div(refPerTok, CEIL);
    }

    /// Should not revert
    /// @return low {UoA/BU} The lower end of the price estimate
    /// @return high {UoA/BU} The upper end of the price estimate
    // returns sum(quantity(erc20) * price(erc20) for erc20 in basket.erc20s)
    function price() external view returns (uint192 low, uint192 high) {
        return _price(false);
    }

    /// Should not revert
    /// lowLow should be nonzero when the asset might be worth selling
    /// @return lotLow {UoA/BU} The lower end of the lot price estimate
    /// @return lotHigh {UoA/BU} The upper end of the lot price estimate
    // returns sum(quantity(erc20) * lotPrice(erc20) for erc20 in basket.erc20s)
    function lotPrice() external view returns (uint192 lotLow, uint192 lotHigh) {
        return _price(true);
    }

    /// Returns the price of a BU, using the lot prices if `useLotPrice` is true
    /// @return low {UoA/BU} The lower end of the price estimate
    /// @return high {UoA/BU} The upper end of the price estimate
    function _price(bool useLotPrice) internal view returns (uint192 low, uint192 high) {
        uint256 low256;
        uint256 high256;

        uint256 len = basket.erc20s.length;
        for (uint256 i = 0; i < len; ++i) {
            uint192 qty = quantity(basket.erc20s[i]);
            if (qty == 0) continue;

            (uint192 lowP, uint192 highP) = useLotPrice
                ? assetRegistry.toAsset(basket.erc20s[i]).lotPrice()
                : assetRegistry.toAsset(basket.erc20s[i]).price();

            low256 += qty.safeMul(lowP, RoundingMode.FLOOR);
            high256 += qty.safeMul(highP, RoundingMode.CEIL);
        }

        // safe downcast: FIX_MAX is type(uint192).max
        low = low256 >= FIX_MAX ? FIX_MAX : uint192(low256);
        high = high256 >= FIX_MAX ? FIX_MAX : uint192(high256);
    }

    /// Return the current issuance/redemption value of `amount` BUs
    /// @dev Subset of logic of quoteCustomRedemption; more gas efficient for current nonce
    /// @param amount {BU}
    /// @return erc20s The backing collateral erc20s
    /// @return quantities {qTok} ERC20 token quantities equal to `amount` BUs
    // Returns (erc20s, [quantity(e) * amount {as qTok} for e in erc20s])
    function quote(uint192 amount, RoundingMode rounding)
        external
        view
        returns (address[] memory erc20s, uint256[] memory quantities)
    {
        uint256 length = basket.erc20s.length;
        erc20s = new address[](length);
        quantities = new uint256[](length);

        for (uint256 i = 0; i < length; ++i) {
            erc20s[i] = address(basket.erc20s[i]);
            ICollateral coll = assetRegistry.toColl(IERC20(erc20s[i]));

            // {qTok} = {tok/BU} * {BU} * {tok} * {qTok/tok}
            quantities[i] = _quantity(basket.erc20s[i], coll)
                .safeMul(amount, rounding)
                .shiftl_toUint(
                    int8(IERC20Metadata(address(basket.erc20s[i])).decimals()),
                    rounding
                );
        }
    }

    /// Return the redemption value of `amount` BUs for a linear combination of historical baskets
    /// @param basketNonces An array of basket nonces to do redemption from
    /// @param portions {1} An array of Fix quantities
    /// @param amount {BU}
    /// @return erc20s The backing collateral erc20s
    /// @return quantities {qTok} ERC20 token quantities equal to `amount` BUs
    // Returns (erc20s, [quantity(e) * amount {as qTok} for e in erc20s])
    function quoteCustomRedemption(
        uint48[] memory basketNonces,
        uint192[] memory portions,
        uint192 amount
    ) external view returns (address[] memory erc20s, uint256[] memory quantities) {
        require(basketNonces.length == portions.length, "portions does not mirror basketNonces");

        IERC20[] memory erc20sAll = new IERC20[](assetRegistry.size());
        uint192[] memory refAmtsAll = new uint192[](erc20sAll.length);

        uint256 len; // length of return arrays

        // Calculate the linear combination basket
        for (uint48 i = 0; i < basketNonces.length; ++i) {
            require(basketNonces[i] <= nonce, "invalid basketNonce");
            Basket storage b = basketHistory[basketNonces[i]];

            // Add-in refAmts contribution from historical basket
            for (uint256 j = 0; j < b.erc20s.length; ++j) {
                IERC20 erc20 = b.erc20s[j];
                if (address(erc20) == address(0)) continue;

                // Ugly search through erc20sAll
                uint256 erc20Index = type(uint256).max;
                for (uint256 k = 0; k < len; ++k) {
                    if (erc20 == erc20sAll[k]) {
                        erc20Index = k;
                        continue;
                    }
                }

                // Add new ERC20 entry if not found
                uint192 amt = portions[i].mul(b.refAmts[erc20], FLOOR);
                if (erc20Index == type(uint256).max) {
                    erc20sAll[len] = erc20;

                    // {ref} = {1} * {ref}
                    refAmtsAll[len] = amt;
                    ++len;
                } else {
                    // {ref} = {1} * {ref}
                    refAmtsAll[erc20Index] += amt;
                }
            }
        }

        erc20s = new address[](len);
        quantities = new uint256[](len);

        // Calculate quantities
        for (uint256 i = 0; i < len; ++i) {
            erc20s[i] = address(erc20sAll[i]);

            try assetRegistry.toAsset(IERC20(erc20s[i])) returns (IAsset asset) {
                if (!asset.isCollateral()) continue; // skip token if no longer registered

                // {tok} = {BU} * {ref/BU} / {ref/tok}
                quantities[i] = safeMulDivFloor(
                    amount,
                    refAmtsAll[i],
                    ICollateral(address(asset)).refPerTok()
                ).shiftl_toUint(int8(asset.erc20Decimals()), FLOOR);
                // marginally more penalizing than its sibling calculation that uses _quantity()
                // because does not intermediately CEIL as part of the division
            } catch (bytes memory errData) {
                // untested:
                //     OOG pattern tested in other contracts, cost to test here is high
                // see: docs/solidity-style.md#Catching-Empty-Data
                if (errData.length == 0) revert(); // solhint-disable-line reason-string
            }
        }
    }

    /// @return baskets {BU}
    ///          .top The number of partial basket units: e.g max(coll.map((c) => c.balAsBUs())
    ///          .bottom The number of whole basket units held by the account
    /// @dev Returns (FIX_ZERO, FIX_MAX) for an empty or DISABLED basket
    // Returns:
    //    (0, 0), if (basket.erc20s is empty) or (disabled is true) or (status() is DISABLED)
    //    min(e.balanceOf(account) / quantity(e) for e in basket.erc20s if quantity(e) > 0),
    function basketsHeldBy(address account) public view returns (BasketRange memory baskets) {
        uint256 length = basket.erc20s.length;
        if (length == 0 || disabled) return BasketRange(FIX_ZERO, FIX_MAX);
        baskets.bottom = FIX_MAX;

        for (uint256 i = 0; i < length; ++i) {
            ICollateral coll = assetRegistry.toColl(basket.erc20s[i]);
            if (coll.status() == CollateralStatus.DISABLED) return BasketRange(FIX_ZERO, FIX_MAX);

            uint192 refPerTok = coll.refPerTok();
            // If refPerTok is 0, then we have zero of coll's reference unit.
            // We know that basket.refAmts[basket.erc20s[i]] > 0, so we have no baskets.
            if (refPerTok == 0) return BasketRange(FIX_ZERO, FIX_MAX);

            // {tok/BU} = {ref/BU} / {ref/tok}.  0-division averted by condition above.
            uint192 q = basket.refAmts[basket.erc20s[i]].div(refPerTok, CEIL);
            // q > 0 because q = (n).div(_, CEIL) and n > 0

            // {BU} = {tok} / {tok/BU}
            uint192 inBUs = coll.bal(account).div(q);
            baskets.bottom = fixMin(baskets.bottom, inBUs);
            baskets.top = fixMax(baskets.top, inBUs);
        }
    }

    // === Governance Setters ===

    /// @custom:governance
    function setWarmupPeriod(uint48 val) public governance {
        require(val >= MIN_WARMUP_PERIOD && val <= MAX_WARMUP_PERIOD, "invalid warmupPeriod");
        emit WarmupPeriodSet(warmupPeriod, val);
        warmupPeriod = val;
    }

    // === Private ===

    /// Select and save the next basket, based on the BasketConfig and Collateral statuses
    function _switchBasket() private {
        // Mark basket disabled. Pause most protocol functions unless there is a next basket
        disabled = true;

        bool success = _newBasket.nextBasket(_targetNames, config, assetRegistry);
        // if success is true: _newBasket is the next basket

        if (success) {
            // nonce' = nonce + 1
            // basket' = _newBasket
            // timestamp' = now

            nonce += 1;
            basket.setFrom(_newBasket);
            basketHistory[nonce].setFrom(_newBasket);
            timestamp = uint48(block.timestamp);
            disabled = false;
        }

        // Keep records, emit event
        uint256 len = basket.erc20s.length;
        uint192[] memory refAmts = new uint192[](len);
        for (uint256 i = 0; i < len; ++i) {
            refAmts[i] = basket.refAmts[basket.erc20s[i]];
        }
        emit BasketSet(nonce, basket.erc20s, refAmts, disabled);
    }

    /// Require that newERC20s and newTargetAmts preserve the current config targets
    function requireConstantConfigTargets(
        IERC20[] calldata newERC20s,
        uint192[] calldata newTargetAmts
    ) private {
        // Empty _targetAmts mapping
        while (_targetAmts.length() > 0) {
            (bytes32 key, ) = _targetAmts.at(0);
            _targetAmts.remove(key);
        }

        // Populate _targetAmts mapping with old basket config
        uint256 len = config.erc20s.length;
        for (uint256 i = 0; i < len; ++i) {
            IERC20 erc20 = config.erc20s[i];
            bytes32 targetName = config.targetNames[erc20];
            (bool contains, uint256 amt) = _targetAmts.tryGet(targetName);
            _targetAmts.set(
                targetName,
                contains ? amt + config.targetAmts[erc20] : config.targetAmts[erc20]
            );
        }

        // Require new basket is exactly equal to old basket, in terms of targetAmts by targetName
        len = newERC20s.length;
        for (uint256 i = 0; i < len; ++i) {
            bytes32 targetName = assetRegistry.toColl(newERC20s[i]).targetName();
            (bool contains, uint256 amt) = _targetAmts.tryGet(targetName);
            require(contains && amt >= newTargetAmts[i], "new basket adds target weights");
            if (amt > newTargetAmts[i]) _targetAmts.set(targetName, amt - newTargetAmts[i]);
            else _targetAmts.remove(targetName);
        }
        require(_targetAmts.length() == 0, "new basket missing target weights");
    }

    /// Require that erc20s is a valid collateral array
    function requireValidCollArray(IERC20[] calldata erc20s) private view {
        IERC20 zero = IERC20(address(0));

        for (uint256 i = 0; i < erc20s.length; i++) {
            require(erc20s[i] != rsr, "RSR is not valid collateral");
            require(erc20s[i] != IERC20(address(rToken)), "RToken is not valid collateral");
            require(erc20s[i] != IERC20(address(stRSR)), "stRSR is not valid collateral");
            require(erc20s[i] != zero, "address zero is not valid collateral");
        }

        require(ArrayLib.allUnique(erc20s), "contains duplicates");
    }

    // ==== FacadeRead views ====
    // Not used in-protocol; helpful for reconstructing state

    /// Get a reference basket in today's collateral tokens, by nonce
    /// @param basketNonce {basketNonce}
    /// @return erc20s The erc20s in the reference basket
    /// @return quantities {qTok/BU} The quantity of whole tokens per whole basket unit
    function getHistoricalBasket(uint48 basketNonce)
        external
        view
        returns (IERC20[] memory erc20s, uint256[] memory quantities)
    {
        Basket storage b = basketHistory[basketNonce];
        erc20s = new IERC20[](b.erc20s.length);
        quantities = new uint256[](erc20s.length);

        for (uint256 i = 0; i < b.erc20s.length; ++i) {
            erc20s[i] = b.erc20s[i];

            try assetRegistry.toAsset(IERC20(erc20s[i])) returns (IAsset asset) {
                if (!asset.isCollateral()) continue; // skip token if no longer registered

                // {tok} = {BU} * {ref/BU} / {ref/tok}
                quantities[i] = safeMulDivFloor(
                    FIX_ONE,
                    b.refAmts[erc20s[i]],
                    ICollateral(address(asset)).refPerTok()
                ).shiftl_toUint(int8(asset.erc20Decimals()), FLOOR);
            } catch (bytes memory errData) {
                // untested:
                //     OOG pattern tested in other contracts, cost to test here is high
                // see: docs/solidity-style.md#Catching-Empty-Data
                if (errData.length == 0) revert(); // solhint-disable-line reason-string
            }
        }
    }

    /// Getter part1 for `config` struct variable
    /// @dev Indices are shared across return values
    /// @return erc20s The erc20s in the prime basket
    /// @return targetNames The bytes32 name identifier of the target unit, per ERC20
    /// @return targetAmts {target/BU} The amount of the target unit in the basket, per ERC20
    function getPrimeBasket()
        external
        view
        returns (
            IERC20[] memory erc20s,
            bytes32[] memory targetNames,
            uint192[] memory targetAmts
        )
    {
        erc20s = new IERC20[](config.erc20s.length);
        targetNames = new bytes32[](erc20s.length);
        targetAmts = new uint192[](erc20s.length);

        for (uint256 i = 0; i < erc20s.length; ++i) {
            erc20s[i] = config.erc20s[i];
            targetNames[i] = config.targetNames[erc20s[i]];
            targetAmts[i] = config.targetAmts[erc20s[i]];
        }
    }

    /// Getter part2 for `config` struct variable
    /// @param targetName The name of the target unit to lookup the backup for
    /// @return erc20s The backup erc20s for the target unit, in order of most to least desirable
    /// @return max The maximum number of tokens from the array to use at a single time
    function getBackupConfig(bytes32 targetName)
        external
        view
        returns (IERC20[] memory erc20s, uint256 max)
    {
        BackupConfig storage backup = config.backups[targetName];
        erc20s = new IERC20[](backup.erc20s.length);
        for (uint256 i = 0; i < erc20s.length; ++i) {
            erc20s[i] = backup.erc20s[i];
        }
        max = backup.max;
    }

    // === Private ===

    /// @return The floored result of FixLib.mulDiv
    function safeMulDivFloor(
        uint192 x,
        uint192 y,
        uint192 z
    ) private view returns (uint192) {
        try backingManager.mulDiv(x, y, z, FLOOR) returns (uint192 result) {
            return result;
        } catch Panic(uint256 errorCode) {
            // 0x11: overflow
            // 0x12: div-by-zero
            assert(errorCode == 0x11 || errorCode == 0x12);
        } catch (bytes memory reason) {
            assert(keccak256(reason) == UIntOutofBoundsHash);
        }
        return FIX_MAX;
    }

    // ==== Storage Gap ====

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[37] private __gap;
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../../interfaces/IAssetRegistry.sol";
import "../../libraries/Fixed.sol";

// A "valid collateral array" is a IERC20[] array without rtoken/rsr/stRSR/zero address/duplicates

// A BackupConfig value is valid if erc20s is a valid collateral array
struct BackupConfig {
    uint256 max; // Maximum number of backup collateral erc20s to use in a basket
    IERC20[] erc20s; // Ordered list of backup collateral ERC20s
}

// What does a BasketConfig value mean?
//
// erc20s, targetAmts, and targetNames should be interpreted together.
// targetAmts[erc20] is the quantity of target units of erc20 that one BU should hold
// targetNames[erc20] is the name of erc20's target unit
// and then backups[tgt] is the BackupConfig to use for the target unit named tgt
//
// For any valid BasketConfig value:
//     erc20s == keys(targetAmts) == keys(targetNames)
//     if name is in values(targetNames), then backups[name] is a valid BackupConfig
//     erc20s is a valid collateral array
//
// In the meantime, treat erc20s as the canonical set of keys for the target* maps
struct BasketConfig {
    // The collateral erc20s in the prime (explicitly governance-set) basket
    IERC20[] erc20s;
    // Amount of target units per basket for each prime collateral token. {target/BU}
    mapping(IERC20 => uint192) targetAmts;
    // Cached view of the target unit for each erc20 upon setup
    mapping(IERC20 => bytes32) targetNames;
    // Backup configurations, per target name.
    mapping(bytes32 => BackupConfig) backups;
}

/// The type of BasketHandler.basket.
/// Defines a basket unit (BU) in terms of reference amounts of underlying tokens
// Logically, basket is just a mapping of erc20 addresses to ref-unit amounts.
//
// A Basket is valid if erc20s is a valid collateral array and erc20s == keys(refAmts)
struct Basket {
    IERC20[] erc20s; // enumerated keys for refAmts
    mapping(IERC20 => uint192) refAmts; // {ref/BU}
}

/**
 * @title BasketLibP1
 * @notice A helper library that implements a `nextBasket()` function for selecting a reference
 *   basket from the current basket config in combination with collateral statuses/exchange rates.
 */
library BasketLibP1 {
    using BasketLibP1 for Basket;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using FixLib for uint192;

    // === Basket Algebra ===

    /// Set self to a fresh, empty basket
    // self'.erc20s = [] (empty list)
    // self'.refAmts = {} (empty map)
    function empty(Basket storage self) internal {
        uint256 length = self.erc20s.length;
        for (uint256 i = 0; i < length; ++i) self.refAmts[self.erc20s[i]] = FIX_ZERO;
        delete self.erc20s;
    }

    /// Set `self` equal to `other`
    function setFrom(Basket storage self, Basket storage other) internal {
        empty(self);
        uint256 length = other.erc20s.length;
        for (uint256 i = 0; i < length; ++i) {
            self.erc20s.push(other.erc20s[i]);
            self.refAmts[other.erc20s[i]] = other.refAmts[other.erc20s[i]];
        }
    }

    /// Add `weight` to the refAmount of collateral token `tok` in the basket `self`
    // self'.refAmts[tok] = self.refAmts[tok] + weight
    // self'.erc20s is keys(self'.refAmts)
    function add(
        Basket storage self,
        IERC20 tok,
        uint192 weight
    ) internal {
        // untestable:
        //      Both calls to .add() use a weight that has been CEIL rounded in the
        //      Fixed library div function, so weight will never be 0 here.
        //      Additionally, setPrimeBasket() enforces prime-basket tokens must have a weight > 0.
        if (weight == FIX_ZERO) return;
        if (self.refAmts[tok].eq(FIX_ZERO)) {
            self.erc20s.push(tok);
            self.refAmts[tok] = weight;
        } else {
            self.refAmts[tok] = self.refAmts[tok].plus(weight);
        }
    }

    // === Basket Selection ===

    /* nextBasket() computes basket' from three inputs:
       - the basket configuration (config: BasketConfig)
       - the function (isGood: erc20 -> bool), implemented here by goodCollateral()
       - the function (targetPerRef: erc20 -> Fix) implemented by the Collateral plugin

       ==== Definitions ====

       We use e:IERC20 to mean any erc20 token address, and tgt:bytes32 to mean any target name

       // targetWeight(b, e) is the target-unit weight of token e in basket b
       Let targetWeight(b, e) = b.refAmt[e] * targetPerRef(e)

       // backups(tgt) is the list of sound backup tokens we plan to use for target `tgt`.
       Let backups(tgt) = config.backups[tgt].erc20s
                          .filter(isGood)
                          .takeUpTo(config.backups[tgt].max)

       Let primeWt(e) = if e in config.erc20s and isGood(e)
                        then config.targetAmts[e]
                        else 0
       Let backupWt(e) = if e in backups(tgt)
                         then unsoundPrimeWt(tgt) / len(Backups(tgt))
                         else 0
       Let unsoundPrimeWt(tgt) = sum(config.targetAmts[e]
                                     for e in config.erc20s
                                     where config.targetNames[e] == tgt and !isGood(e))

       ==== The correctness condition ====

       If unsoundPrimeWt(tgt) > 0 and len(backups(tgt)) == 0 for some tgt, then return false.
       Else, return true and targetWeight(basket', e) == primeWt(e) + backupWt(e) for all e.

       ==== Higher-level desideratum ====

       The resulting total target weights should equal the configured target weight. Formally:

       let configTargetWeight(tgt) = sum(config.targetAmts[e]
                                         for e in config.erc20s
                                         where targetNames[e] == tgt)

       let targetWeightSum(b, tgt) = sum(targetWeight(b, e)
                                         for e in config.erc20s
                                         where targetNames[e] == tgt)

       Given all that, if nextBasket() returns true, then for all tgt,
           targetWeightSum(basket', tgt) == configTargetWeight(tgt)
    */

    /// Select next reference basket from basket config
    /// Works in-place on `newBasket`
    /// @param targetNames Scratch space for computation; initial value unused
    /// @param newBasket Scratch space for computation; initial value unused
    /// @param config The current basket configuration
    /// @return success result; i.e newBasket can be expected to contain a valid reference basket
    function nextBasket(
        Basket storage newBasket,
        EnumerableSet.Bytes32Set storage targetNames,
        BasketConfig storage config,
        IAssetRegistry assetRegistry
    ) external returns (bool) {
        // targetNames := {}
        while (targetNames.length() > 0) targetNames.remove(targetNames.at(0));

        // newBasket := {}
        newBasket.empty();

        // targetNames = set(values(config.targetNames))
        // (and this stays true; targetNames is not touched again in this function)
        for (uint256 i = 0; i < config.erc20s.length; ++i) {
            targetNames.add(config.targetNames[config.erc20s[i]]);
        }
        uint256 targetsLength = targetNames.length();

        // "good" collateral is collateral with any status() other than DISABLED
        // goodWeights and totalWeights are in index-correspondence with targetNames
        // As such, they're each interepreted as a map from target name -> target weight

        // {target/BU} total target weight of good, prime collateral with target i
        // goodWeights := {}
        uint192[] memory goodWeights = new uint192[](targetsLength);

        // {target/BU} total target weight of all prime collateral with target i
        // totalWeights := {}
        uint192[] memory totalWeights = new uint192[](targetsLength);

        // For each prime collateral token:
        for (uint256 i = 0; i < config.erc20s.length; ++i) {
            // Find collateral's targetName index
            uint256 targetIndex;
            for (targetIndex = 0; targetIndex < targetsLength; ++targetIndex) {
                if (targetNames.at(targetIndex) == config.targetNames[config.erc20s[i]]) break;
            }
            assert(targetIndex < targetsLength);
            // now, targetNames[targetIndex] == config.targetNames[erc20]

            // Set basket weights for good, prime collateral,
            // and accumulate the values of goodWeights and targetWeights
            uint192 targetWeight = config.targetAmts[config.erc20s[i]];
            totalWeights[targetIndex] = totalWeights[targetIndex].plus(targetWeight);

            if (
                goodCollateral(
                    config.targetNames[config.erc20s[i]],
                    config.erc20s[i],
                    assetRegistry
                ) && targetWeight.gt(FIX_ZERO)
            ) {
                goodWeights[targetIndex] = goodWeights[targetIndex].plus(targetWeight);
                newBasket.add(
                    config.erc20s[i],
                    targetWeight.div(
                        // this div is safe: targetPerRef() > 0: goodCollateral check
                        assetRegistry.toColl(config.erc20s[i]).targetPerRef(),
                        CEIL
                    )
                );
            }
        }

        // Analysis: at this point:
        // for all tgt in target names,
        //   totalWeights(tgt)
        //   = sum(config.targetAmts[e] for e in config.erc20s where targetNames[e] == tgt), and
        //   goodWeights(tgt)
        //   = sum(primeWt(e) for e in config.erc20s where targetNames[e] == tgt)
        // for all e in config.erc20s,
        //   targetWeight(newBasket, e)
        //   = sum(primeWt(e) if goodCollateral(e), else 0)

        // For each tgt in target names, if we still need more weight for tgt then try to add the
        // backup basket for tgt to make up that weight:
        for (uint256 i = 0; i < targetsLength; ++i) {
            if (totalWeights[i].lte(goodWeights[i])) continue; // Don't need any backup weight

            // "tgt" = targetNames[i]
            // Now, unsoundPrimeWt(tgt) > 0

            uint256 size = 0; // backup basket size
            BackupConfig storage backup = config.backups[targetNames.at(i)];

            // Find the backup basket size: min(backup.max, # of good backup collateral)
            for (uint256 j = 0; j < backup.erc20s.length && size < backup.max; ++j) {
                if (goodCollateral(targetNames.at(i), backup.erc20s[j], assetRegistry)) size++;
            }

            // Now, size = len(backups(tgt)). If empty, fail.
            if (size == 0) return false;

            // Set backup basket weights...
            uint256 assigned = 0;

            // Loop: for erc20 in backups(tgt)...
            for (uint256 j = 0; j < backup.erc20s.length && assigned < size; ++j) {
                if (goodCollateral(targetNames.at(i), backup.erc20s[j], assetRegistry)) {
                    // Across this .add(), targetWeight(newBasket',erc20)
                    // = targetWeight(newBasket,erc20) + unsoundPrimeWt(tgt) / len(backups(tgt))
                    newBasket.add(
                        backup.erc20s[j],
                        totalWeights[i].minus(goodWeights[i]).div(
                            // this div is safe: targetPerRef > 0: goodCollateral check
                            assetRegistry.toColl(backup.erc20s[j]).targetPerRef().mulu(size),
                            CEIL
                        )
                    );
                    assigned++;
                }
            }
            // Here, targetWeight(newBasket, e) = primeWt(e) + backupWt(e) for all e targeting tgt
        }
        // Now we've looped through all values of tgt, so for all e,
        //   targetWeight(newBasket, e) = primeWt(e) + backupWt(e)

        return newBasket.erc20s.length > 0;
    }

    // === Private ===

    /// Good collateral is registered, collateral, SOUND, has the expected targetName,
    /// has nonzero targetPerRef() and refPerTok(), and is not a system token or 0 addr
    function goodCollateral(
        bytes32 targetName,
        IERC20 erc20,
        IAssetRegistry assetRegistry
    ) private view returns (bool) {
        // untestable:
        //      ERC20 is not address(0), validated when setting prime/backup baskets
        if (address(erc20) == address(0)) return false;
        // P1 gas optimization
        // We do not need to check that the ERC20 is not a system token
        // BasketHandlerP1.requireValidCollArray() has been run on all ERC20s already

        try assetRegistry.toColl(erc20) returns (ICollateral coll) {
            return
                targetName == coll.targetName() &&
                coll.status() == CollateralStatus.SOUND &&
                coll.refPerTok() > 0 &&
                coll.targetPerRef() > 0;
        } catch {
            return false;
        }
    }
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "../../interfaces/IComponent.sol";
import "../../interfaces/IMain.sol";
import "../../mixins/Versioned.sol";

/**
 * Abstract superclass for system contracts registered in Main
 */
abstract contract ComponentP1 is
    Versioned,
    Initializable,
    ContextUpgradeable,
    UUPSUpgradeable,
    IComponent
{
    IMain public main;

    /// @custom:oz-upgrades-unsafe-allow constructor
    // solhint-disable-next-line no-empty-blocks
    constructor() initializer {}

    // Sets main for the component - Can only be called during initialization
    // untestable:
    //      `else` branch of `onlyInitializing` (ie. revert) is currently untestable.
    //      This function is only called inside other `init` functions, each of which is wrapped
    //      in an `initializer` modifier, which would fail first.
    // solhint-disable-next-line func-name-mixedcase
    function __Component_init(IMain main_) internal onlyInitializing {
        require(address(main_) != address(0), "main is zero address");
        __UUPSUpgradeable_init();
        main = main_;
    }

    // === See docs/security.md ===

    modifier notTradingPausedOrFrozen() {
        require(!main.tradingPausedOrFrozen(), "frozen or trading paused");
        _;
    }

    modifier notIssuancePausedOrFrozen() {
        require(!main.issuancePausedOrFrozen(), "frozen or issuance paused");
        _;
    }

    modifier notFrozen() {
        require(!main.frozen(), "frozen");
        _;
    }

    modifier governance() {
        require(main.hasRole(OWNER, _msgSender()), "governance only");
        _;
    }

    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal view override governance {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.17;

// solhint-disable-next-line max-line-length
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../interfaces/IMain.sol";
import "../interfaces/IRToken.sol";
import "../libraries/Fixed.sol";
import "../libraries/Throttle.sol";
import "../vendor/ERC20PermitUpgradeable.sol";
import "./mixins/Component.sol";

/**
 * @title RTokenP1
 * An ERC20 with an elastic supply and governable exchange rate to basket units.
 */
contract RTokenP1 is ComponentP1, ERC20PermitUpgradeable, IRToken {
    using FixLib for uint192;
    using ThrottleLib for ThrottleLib.Throttle;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public constant MIN_THROTTLE_RATE_AMT = 1e18; // {qRTok}
    uint256 public constant MAX_THROTTLE_RATE_AMT = 1e48; // {qRTok}
    uint192 public constant MAX_THROTTLE_PCT_AMT = 1e18; // {qRTok}
    uint192 public constant MIN_EXCHANGE_RATE = 1e9; // D18{BU/rTok}
    uint192 public constant MAX_EXCHANGE_RATE = 1e27; // D18{BU/rTok}

    /// The mandate describes what goals its governors should try to achieve. By succinctly
    /// explaining the RToken’s purpose and what the RToken is intended to do, it provides common
    /// ground for the governors to decide upon priorities and how to weigh tradeoffs.
    ///
    /// Example Mandates:
    ///
    /// - Capital preservation first. Spending power preservation second. Permissionless
    ///     access third.
    /// - Capital preservation above all else. All revenues fund the over-collateralization pool.
    /// - Risk-neutral pursuit of profit for token holders.
    ///     Maximize (gross revenue - payments for over-collateralization and governance).
    /// - This RToken holds only FooCoin, to provide a trade for hedging against its
    ///     possible collapse.
    ///
    /// The mandate may also be a URI to a longer body of text, presumably on IPFS or some other
    /// immutable data store.
    string public mandate;

    // ==== Peer components ====
    IAssetRegistry private assetRegistry;
    IBasketHandler private basketHandler;
    IBackingManager private backingManager;
    IFurnace private furnace;

    // The number of baskets that backingManager must hold
    // in order for this RToken to be fully collateralized.
    // The exchange rate for issuance and redemption is totalSupply()/basketsNeeded {BU}/{qRTok}.
    uint192 public basketsNeeded; // D18{BU}

    // === Supply throttles ===
    ThrottleLib.Throttle private issuanceThrottle;
    ThrottleLib.Throttle private redemptionThrottle;

    function init(
        IMain main_,
        string calldata name_,
        string calldata symbol_,
        string calldata mandate_,
        ThrottleLib.Params calldata issuanceThrottleParams_,
        ThrottleLib.Params calldata redemptionThrottleParams_
    ) external initializer {
        require(bytes(name_).length > 0, "name empty");
        require(bytes(symbol_).length > 0, "symbol empty");
        require(bytes(mandate_).length > 0, "mandate empty");
        __Component_init(main_);
        __ERC20_init(name_, symbol_);
        __ERC20Permit_init(name_);

        assetRegistry = main_.assetRegistry();
        basketHandler = main_.basketHandler();
        backingManager = main_.backingManager();
        furnace = main_.furnace();

        mandate = mandate_;
        setIssuanceThrottleParams(issuanceThrottleParams_);
        setRedemptionThrottleParams(redemptionThrottleParams_);

        issuanceThrottle.lastTimestamp = uint48(block.timestamp);
        redemptionThrottle.lastTimestamp = uint48(block.timestamp);
    }

    /// Issue an RToken on the current basket
    /// @param amount {qTok} The quantity of RToken to issue
    /// @custom:interaction nearly CEI, but see comments around handling of refunds
    function issue(uint256 amount) public {
        issueTo(_msgSender(), amount);
    }

    /// Issue an RToken on the current basket, to a particular recipient
    /// @param recipient The address to receive the issued RTokens
    /// @param amount {qRTok} The quantity of RToken to issue
    /// @custom:interaction
    // BU exchange rate cannot decrease, and it can only increase when < FIX_ONE.
    function issueTo(address recipient, uint256 amount) public notIssuancePausedOrFrozen {
        require(amount > 0, "Cannot issue zero");

        // == Refresh ==

        assetRegistry.refresh();

        // == Checks-effects block ==

        address issuer = _msgSender(); // OK to save: it can't be changed in reentrant runs

        // Ensure basket is ready, SOUND and not in warmup period
        require(basketHandler.isReady(), "basket not ready");

        furnace.melt();
        uint256 supply = totalSupply();

        // Revert if issuance exceeds either supply throttle
        issuanceThrottle.useAvailable(supply, int256(amount)); // reverts on over-issuance
        redemptionThrottle.useAvailable(supply, -int256(amount)); // shouldn't revert

        // AT THIS POINT:
        //   all contract invariants hold
        //   furnace melting is up-to-date
        //   asset states are up-to-date
        //   throttle is up-to-date

        // amtBaskets: the BU change to be recorded by this issuance
        // D18{BU} = D18{BU} * {qRTok} / {qRTok}
        // revert-on-overflow provided by FixLib functions
        uint192 amtBaskets = supply > 0
            ? basketsNeeded.muluDivu(amount, supply, CEIL)
            : _safeWrap(amount);
        emit Issuance(issuer, recipient, amount, amtBaskets);

        (address[] memory erc20s, uint256[] memory deposits) = basketHandler.quote(
            amtBaskets,
            CEIL
        );

        // == Interactions: Create RToken + transfer tokens to BackingManager ==
        _scaleUp(recipient, amtBaskets, supply);

        for (uint256 i = 0; i < erc20s.length; ++i) {
            IERC20Upgradeable(erc20s[i]).safeTransferFrom(
                issuer,
                address(backingManager),
                deposits[i]
            );
        }
    }

    /// Redeem RToken for basket collateral
    /// @param amount {qTok} The quantity {qRToken} of RToken to redeem
    /// @custom:interaction CEI
    function redeem(uint256 amount) external {
        redeemTo(_msgSender(), amount);
    }

    /// Redeem RToken for basket collateral to a particular recipient
    // checks:
    //   amount > 0
    //   amount <= balanceOf(caller)
    //
    // effects:
    //   (so totalSupply -= amount and balanceOf(caller) -= amount)
    //   basketsNeeded' / totalSupply' >== basketsNeeded / totalSupply
    //   burn(caller, amount)
    //
    // actions:
    //   let erc20s = basketHandler.erc20s()
    //   for each token in erc20s:
    //     let tokenAmt = (amount * basketsNeeded / totalSupply) current baskets
    //     do token.transferFrom(backingManager, caller, tokenAmt)
    // BU exchange rate cannot decrease, and it can only increase when < FIX_ONE.
    /// @param recipient The address to receive the backing collateral tokens
    /// @param amount {qRTok} The quantity {qRToken} of RToken to redeem
    /// @custom:interaction RCEI
    function redeemTo(address recipient, uint256 amount) public notFrozen {
        // == Refresh ==

        assetRegistry.refresh();
        // solhint-disable-next-line no-empty-blocks
        try main.furnace().melt() {} catch {} // nice for the redeemer, but not necessary

        // == Checks and Effects ==

        require(amount > 0, "Cannot redeem zero");
        require(amount <= balanceOf(_msgSender()), "insufficient balance");
        require(basketHandler.fullyCollateralized(), "partial redemption; use redeemCustom");
        // redemption while IFFY/DISABLED allowed

        uint256 supply = totalSupply();

        // Revert if redemption exceeds either supply throttle
        issuanceThrottle.useAvailable(supply, -int256(amount));
        redemptionThrottle.useAvailable(supply, int256(amount)); // reverts on over-redemption

        // {BU}
        uint192 baskets = _scaleDown(_msgSender(), amount);
        emit Redemption(_msgSender(), recipient, amount, baskets);

        (address[] memory erc20s, uint256[] memory amounts) = basketHandler.quote(baskets, FLOOR);

        // === Interactions ===

        for (uint256 i = 0; i < erc20s.length; ++i) {
            if (amounts[i] == 0) continue;

            // Send withdrawal
            IERC20Upgradeable(erc20s[i]).safeTransferFrom(
                address(backingManager),
                recipient,
                amounts[i]
            );
        }
    }

    /// Redeem RToken for a linear combination of historical baskets, to a particular recipient
    // checks:
    //   amount > 0
    //   amount <= balanceOf(caller)
    //   sum(portions) == FIX_ONE
    //   nonce >= basketHandler.primeNonce() for nonce in basketNonces
    //
    // effects:
    //   (so totalSupply -= amount and balanceOf(caller) -= amount)
    //   basketsNeeded' / totalSupply' >== basketsNeeded / totalSupply
    //   burn(caller, amount)
    //
    // actions:
    //   for each token in erc20s:
    //     let tokenAmt = (amount * basketsNeeded / totalSupply) custom baskets
    //     let prorataAmt = (amount / totalSupply) * token.balanceOf(backingManager)
    //     do token.transferFrom(backingManager, caller, min(tokenAmt, prorataAmt))
    // BU exchange rate cannot decrease, and it can only increase when < FIX_ONE.
    /// @dev Allows partial redemptions up to the minAmounts
    /// @param recipient The address to receive the backing collateral tokens
    /// @param amount {qRTok} The quantity {qRToken} of RToken to redeem
    /// @param basketNonces An array of basket nonces to do redemption from
    /// @param portions {1} An array of Fix quantities that must add up to FIX_ONE
    /// @param expectedERC20sOut An array of ERC20s expected out
    /// @param minAmounts {qTok} The minimum ERC20 quantities the caller should receive
    /// @custom:interaction RCEI
    function redeemCustom(
        address recipient,
        uint256 amount,
        uint48[] memory basketNonces,
        uint192[] memory portions,
        address[] memory expectedERC20sOut,
        uint256[] memory minAmounts
    ) external notFrozen returns (address[] memory erc20sOut, uint256[] memory amountsOut) {
        // == Refresh ==

        assetRegistry.refresh();
        // solhint-disable-next-line no-empty-blocks
        try main.furnace().melt() {} catch {}

        // == Checks and Effects ==

        require(amount > 0, "Cannot redeem zero");
        require(amount <= balanceOf(_msgSender()), "insufficient balance");
        uint256 portionsSum;
        for (uint256 i = 0; i < portions.length; ++i) {
            portionsSum += portions[i];
        }
        require(portionsSum == FIX_ONE, "portions do not add up to FIX_ONE");

        uint256 supply = totalSupply();

        // Revert if redemption exceeds either supply throttle
        issuanceThrottle.useAvailable(supply, -int256(amount));
        redemptionThrottle.useAvailable(supply, int256(amount)); // reverts on over-redemption

        // {BU}
        uint192 baskets = _scaleDown(_msgSender(), amount);
        emit Redemption(_msgSender(), recipient, amount, baskets);

        // === Get basket redemption amounts ===

        (erc20sOut, amountsOut) = basketHandler.quoteCustomRedemption(
            basketNonces,
            portions,
            baskets
        );

        // ==== Prorate redemption ====
        // i.e, set amounts = min(amounts, balances * amount / totalSupply)
        //   where balances[i] = erc20sOut[i].balanceOf(backingManager)

        // Bound each withdrawal by the prorata share, in case we're currently under-collateralized
        for (uint256 i = 0; i < erc20sOut.length; ++i) {
            // {qTok} = {qTok} * {qRTok} / {qRTok}
            uint256 prorata = mulDiv256(
                IERC20(erc20sOut[i]).balanceOf(address(backingManager)),
                amount,
                supply
            ); // FLOOR

            if (prorata < amountsOut[i]) amountsOut[i] = prorata;
        }

        // === Save initial recipient balances ===

        uint256[] memory pastBals = new uint256[](expectedERC20sOut.length);
        for (uint256 i = 0; i < expectedERC20sOut.length; ++i) {
            pastBals[i] = IERC20(expectedERC20sOut[i]).balanceOf(recipient);
            // we haven't verified this ERC20 is registered but this is always a staticcall
        }

        // === Interactions ===

        // Distribute tokens; revert if empty redemption
        {
            bool allZero = true;
            for (uint256 i = 0; i < erc20sOut.length; ++i) {
                if (amountsOut[i] == 0) continue; // unregistered ERC20s will have 0 amount
                if (allZero) allZero = false;

                // Send withdrawal
                IERC20Upgradeable(erc20sOut[i]).safeTransferFrom(
                    address(backingManager),
                    recipient,
                    amountsOut[i]
                );
            }
            if (allZero) revert("empty redemption");
        }

        // === Post-checks ===

        // Check post-balances
        for (uint256 i = 0; i < expectedERC20sOut.length; ++i) {
            uint256 bal = IERC20(expectedERC20sOut[i]).balanceOf(recipient);
            // we haven't verified this ERC20 is registered but this is always a staticcall
            require(bal - pastBals[i] >= minAmounts[i], "redemption below minimum");
        }
    }

    /// Mint an amount of RToken equivalent to baskets BUs, scaling basketsNeeded up
    /// Callable only by BackingManager
    /// @param baskets {BU} The number of baskets to mint RToken for
    /// @custom:protected
    // checks: caller is backingManager
    // effects:
    //   bal'[recipient] = bal[recipient] + amtRToken
    //   totalSupply' = totalSupply + amtRToken
    //   basketsNeeded' = basketsNeeded + baskets
    // BU exchange rate cannot decrease, and it can only increase when < FIX_ONE.
    function mint(uint192 baskets) external {
        require(_msgSender() == address(backingManager), "not backing manager");
        _scaleUp(address(backingManager), baskets, totalSupply());
    }

    /// Melt a quantity of RToken from the caller's account, increasing the basket rate
    /// @param amtRToken {qRTok} The amtRToken to be melted
    /// @custom:protected
    // checks: caller is furnace
    // effects:
    //   bal'[caller] = bal[caller] - amtRToken
    //   totalSupply' = totalSupply - amtRToken
    // BU exchange rate cannot decrease
    // BU exchange rate CAN increase, but we already trust furnace to do this slowly
    function melt(uint256 amtRToken) external {
        require(_msgSender() == address(furnace), "furnace only");
        _burn(_msgSender(), amtRToken);
        emit Melted(amtRToken);
    }

    /// Burn an amount of RToken from caller's account and scale basketsNeeded down
    /// Callable only by backingManager
    /// @param amount {qRTok}
    /// @custom:protected
    // checks: caller is backingManager
    // effects:
    //   bal'[recipient] = bal[recipient] - amtRToken
    //   totalSupply' = totalSupply - amtRToken
    //   basketsNeeded' = basketsNeeded - baskets
    // BU exchange rate cannot decrease, and it can only increase when < FIX_ONE.
    function dissolve(uint256 amount) external {
        require(_msgSender() == address(backingManager), "not backing manager");
        _scaleDown(_msgSender(), amount);
    }

    /// An affordance of last resort for Main in order to ensure re-capitalization
    /// @custom:protected
    // checks: caller is backingManager
    // effects: basketsNeeded' = basketsNeeded_
    function setBasketsNeeded(uint192 basketsNeeded_) external notTradingPausedOrFrozen {
        require(_msgSender() == address(backingManager), "not backing manager");
        emit BasketsNeededChanged(basketsNeeded, basketsNeeded_);
        basketsNeeded = basketsNeeded_;

        // == P0 exchangeRateIsValidAfter modifier ==
        uint256 supply = totalSupply();
        require(supply > 0, "0 supply");

        // Note: These are D18s, even though they are uint256s. This is because
        // we cannot assume we stay inside our valid range here, as that is what
        // we are checking in the first place
        uint256 low = (FIX_ONE_256 * basketsNeeded) / supply; // D18{BU/rTok}
        uint256 high = (FIX_ONE_256 * basketsNeeded + (supply - 1)) / supply; // D18{BU/rTok}

        // here we take advantage of an implicit upcast from uint192 exchange rates
        require(low >= MIN_EXCHANGE_RATE && high <= MAX_EXCHANGE_RATE, "BU rate out of range");
    }

    /// Sends all token balance of erc20 (if it is registered) to the BackingManager
    /// @custom:interaction
    function monetizeDonations(IERC20 erc20) external notTradingPausedOrFrozen {
        require(assetRegistry.isRegistered(erc20), "erc20 unregistered");
        IERC20Upgradeable(address(erc20)).safeTransfer(
            address(backingManager),
            erc20.balanceOf(address(this))
        );
    }

    // ==== Throttle setters/getters ====

    /// @return {qRTok} The maximum issuance that can be performed in the current block
    function issuanceAvailable() external view returns (uint256) {
        return issuanceThrottle.currentlyAvailable(issuanceThrottle.hourlyLimit(totalSupply()));
    }

    /// @return available {qRTok} The maximum redemption that can be performed in the current block
    function redemptionAvailable() external view returns (uint256 available) {
        uint256 supply = totalSupply();
        uint256 hourlyLimit = redemptionThrottle.hourlyLimit(supply);
        available = redemptionThrottle.currentlyAvailable(hourlyLimit);
        if (supply < available) available = supply;
    }

    /// @return The issuance throttle parametrization
    function issuanceThrottleParams() external view returns (ThrottleLib.Params memory) {
        return issuanceThrottle.params;
    }

    /// @return The redemption throttle parametrization
    function redemptionThrottleParams() external view returns (ThrottleLib.Params memory) {
        return redemptionThrottle.params;
    }

    /// @custom:governance
    function setIssuanceThrottleParams(ThrottleLib.Params calldata params) public governance {
        require(params.amtRate >= MIN_THROTTLE_RATE_AMT, "issuance amtRate too small");
        require(params.amtRate <= MAX_THROTTLE_RATE_AMT, "issuance amtRate too big");
        require(params.pctRate <= MAX_THROTTLE_PCT_AMT, "issuance pctRate too big");
        emit IssuanceThrottleSet(issuanceThrottle.params, params);
        issuanceThrottle.params = params;
    }

    /// @custom:governance
    function setRedemptionThrottleParams(ThrottleLib.Params calldata params) public governance {
        require(params.amtRate >= MIN_THROTTLE_RATE_AMT, "redemption amtRate too small");
        require(params.amtRate <= MAX_THROTTLE_RATE_AMT, "redemption amtRate too big");
        require(params.pctRate <= MAX_THROTTLE_PCT_AMT, "redemption pctRate too big");
        emit RedemptionThrottleSet(redemptionThrottle.params, params);
        redemptionThrottle.params = params;
    }

    // ==== Private ====

    /// Mint an amount of RToken equivalent to amtBaskets and scale basketsNeeded up
    /// @param recipient The address to receive the RTokens
    /// @param amtBaskets {BU} The number of amtBaskets to mint RToken for
    /// @param totalSupply {qRTok} The current totalSupply
    // effects:
    //   bal'[recipient] = bal[recipient] + amtRToken
    //   totalSupply' = totalSupply + amtRToken
    //   basketsNeeded' = basketsNeeded + amtBaskets
    // BU exchange rate cannot decrease, and it can only increase when < FIX_ONE.
    function _scaleUp(
        address recipient,
        uint192 amtBaskets,
        uint256 totalSupply
    ) private {
        // take advantage of 18 decimals during casting
        uint256 amtRToken = totalSupply > 0
            ? amtBaskets.muluDivu(totalSupply, basketsNeeded) // {rTok} = {BU} * {qRTok} * {qRTok}
            : amtBaskets; // {rTok}
        emit BasketsNeededChanged(basketsNeeded, basketsNeeded + amtBaskets);
        basketsNeeded += amtBaskets;

        // Mint RToken to recipient
        _mint(recipient, amtRToken);
    }

    /// Burn an amount of RToken and scale basketsNeeded down
    /// @param account The address to dissolve RTokens from
    /// @param amtRToken {qRTok} The amount of RToken to be dissolved
    /// @return amtBaskets {BU} The equivalent number of baskets dissolved
    // effects:
    //   bal'[recipient] = bal[recipient] - amtRToken
    //   totalSupply' = totalSupply - amtRToken
    //   basketsNeeded' = basketsNeeded - amtBaskets
    // BU exchange rate cannot decrease, and it can only increase when < FIX_ONE.
    function _scaleDown(address account, uint256 amtRToken) private returns (uint192 amtBaskets) {
        // D18{BU} = D18{BU} * {qRTok} / {qRTok}
        amtBaskets = basketsNeeded.muluDivu(amtRToken, totalSupply()); // FLOOR
        emit BasketsNeededChanged(basketsNeeded, basketsNeeded - amtBaskets);
        basketsNeeded -= amtBaskets;

        // Burn RToken from account; reverts if not enough balance
        _burn(account, amtRToken);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfer(
        address,
        address to,
        uint256
    ) internal virtual override {
        require(to != address(this), "RToken transfer to self");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[42] private __gap;
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC1271Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IStRSR.sol";
import "../interfaces/IMain.sol";
import "../libraries/Fixed.sol";
import "../libraries/Permit.sol";
import "./mixins/Component.sol";

/*
 * @title StRSRP1
 * @notice StRSR is an ERC20 token contract that allows people to stake their RSR as
 *   over-collateralization behind an RToken. As compensation stakers receive a share of revenues
 *   in the form of RSR. Balances are generally non-rebasing. As rewards are paid out StRSR becomes
 *   redeemable for increasing quantities of RSR.
 *
 * The one time that StRSR will rebase is if the entirety of over-collateralization RSR is seized.
 *   If this happens, users balances are zereod out and StRSR is re-issued at a 1:1 exchange rate
 *   with RSR.
 *
 * There's an important asymmetry in StRSR: when RSR is added it must be split only
 *   across non-withdrawing stakes, while when RSR is seized it is seized uniformly from both
 *   stakes that are in the process of being withdrawn and those that are not.
 */
// solhint-disable max-states-count
abstract contract StRSRP1 is Initializable, ComponentP1, IStRSR, EIP712Upgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint48 public constant PERIOD = ONE_BLOCK; // {s} 12 seconds; 1 block on PoS Ethereum
    uint48 public constant MIN_UNSTAKING_DELAY = PERIOD * 2; // {s}
    uint48 public constant MAX_UNSTAKING_DELAY = 31536000; // {s} 1 year
    uint192 public constant MAX_REWARD_RATIO = FIX_ONE; // {1} 100%

    // === ERC20 ===
    string public name; // immutable
    string public symbol; // immutable
    // solhint-disable const-name-snakecase
    uint8 public constant decimals = 18;

    // Component addresses, immutable after init()
    IAssetRegistry private assetRegistry;
    IBackingManager private backingManager;
    IBasketHandler private basketHandler;
    IERC20 private rsr;

    /// === Financial State: Stakes (balances) ===
    // Era. If stake balances are wiped out due to RSR seizure, increment the era to zero balances.
    // Only ever directly written by beginEra()
    uint256 internal era;

    // Typically: "balances". These are the tokenized staking positions!
    // era => ({account} => {qStRSR})
    mapping(uint256 => mapping(address => uint256)) private stakes; // Stakes per account {qStRSR}
    uint256 private totalStakes; // Total of all stakes {qStRSR}
    uint256 private stakeRSR; // Amount of RSR backing all stakes {qRSR}
    uint192 private stakeRate; // The exchange rate between stakes and RSR. D18{qStRSR/qRSR}

    uint192 private constant MAX_STAKE_RATE = 1e9 * FIX_ONE; // 1e9 D18{qStRSR/qRSR}

    // era => (owner => (spender => {qStRSR}))
    mapping(uint256 => mapping(address => mapping(address => uint256))) private _allowances;

    // === Financial State: Drafts ===
    // Era. If drafts get wiped out due to RSR seizure, increment the era to zero draft values.
    // Only ever directly written by beginDraftEra()
    uint256 internal draftEra;
    // Drafts: share of the withdrawing tokens. Not transferrable and not revenue-earning.
    struct CumulativeDraft {
        // Avoid re-using uint192 in order to avoid confusion with our type system; 176 is enough
        uint176 drafts; // Total amount of drafts that will become available // {qDrafts}
        uint64 availableAt; // When the last of the drafts will become available
    }
    // draftEra => ({account} => {drafts})
    mapping(uint256 => mapping(address => CumulativeDraft[])) public draftQueues; // {drafts}
    mapping(uint256 => mapping(address => uint256)) public firstRemainingDraft; // draft index
    uint256 private totalDrafts; // Total of all drafts {qDrafts}
    uint256 private draftRSR; // Amount of RSR backing all drafts {qRSR}
    uint192 public draftRate; // The exchange rate between drafts and RSR. D18{qDrafts/qRSR}

    uint192 private constant MAX_DRAFT_RATE = 1e9 * FIX_ONE; // 1e9 D18{qDrafts/qRSR}

    // ==== Analysis Definitions for Financial State ====
    // Let `bal` be the map stakes[era]; so, bal[acct] == balanceOf(acct)

    // Entirely different concepts for the Drafts:
    // `draft[acct]` is a "draft record". If, say, r = draft[acct], then:
    //   Let `r.queue` be the map draftQueues[era][acct]
    //   Let `r.left` be the value firstRemainingDraft[era][acct] // ( minus 1? )
    //   Let `r.right` be the value draftsQueues[era][acct].length
    //   We further define r.queue[-1].drafts to be 0.
    //
    // So, for any keyval pair (acct, r) in draft:
    // r.left <= r.right
    // for all i and j with r.left <= i < j < r.right:
    //   r.queue[i].drafts < r.queue[j].drafts, and
    //   r.queue[i].availableAt <= r.queue[j].availableAt
    //
    // Define draftSum, the total amount of drafts eventually due to the account holder of record r:
    // Let draftSum(r:draftRecord) =
    //   r.queue[r.right-1].drafts - r.queue[r.left-1].drafts

    // ==== Invariants ====
    // [total-stakes]: totalStakes == sum(bal[acct] for acct in bal)
    // [max-stake-rate]: 0 < stakeRate <= MAX_STAKE_RATE
    // [stake-rate]: if totalStakes == 0, then stakeRSR == 0 and stakeRate == FIX_ONE
    //               else, stakeRSR * stakeRate >= totalStakes * 1e18
    //               (ie, stakeRSR covers totalStakes at stakeRate)
    //
    // [total-drafts]: totalDrafts == sum(draftSum(draft[acct]) for acct in draft)
    // [max-draft-rate]: 0 < draftRate <= MAX_DRAFT_RATE
    // [draft-rate]: if totalDrafts == 0, then draftRSR == 0 and draftRate == FIX_ONE
    //               else, draftRSR * draftRate >= totalDrafts * 1e18
    //               (ie, draftRSR covers totalDrafts at draftRate)
    //
    // === ERC20Permit ===
    mapping(address => CountersUpgradeable.Counter) private _nonces;
    // === Delegation ===
    mapping(address => CountersUpgradeable.Counter) private _delegationNonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    // ==== Gov Params ====
    // Promise: Each gov param is set _only_ by the appropriate "set" function.
    uint48 public unstakingDelay; // {s} The minimum length of time spent in the draft queue
    uint192 public rewardRatio; // {1} The fraction of the revenue balance to handout per period

    // === Rewards Cache ===
    // Promise: The two *payout* vars are modified only by init() and _payoutRewards()
    //   init() pretends that the "first" payout happens at initialization time
    //   _payoutRewards() updates them as described.
    // When init() or _payoutRewards() was last called:
    //     payoutLastPaid was the timestamp when the last paid-up block ended
    //     rsrRewardsAtLastPayout was the value of rsrRewards() at that time

    // {seconds} The last time when rewards were paid out
    uint48 public payoutLastPaid;

    // {qRSR} How much reward RSR was held the last time rewards were paid out
    uint256 private rsrRewardsAtLastPayout;

    // === 3.0.0 ===
    // The fraction of draftRSR + stakeRSR that may exit without a refresh
    uint192 private constant MAX_WITHDRAWAL_LEAK = 3e17; // {1} 30%

    uint192 private leaked; // {1} stake fraction that has withdrawn without a refresh
    uint48 private lastWithdrawRefresh; // {s} timestamp of last refresh() during withdraw()
    uint192 public withdrawalLeak; // {1} gov param -- % RSR that can be withdrawn without refresh

    // ======================

    // init() can only be called once (initializer)
    // ==== Financial State:
    // effects:
    //   draft' = {}, bal' = {}, all totals zero, all rates FIX_ONE.
    //   payoutLastPaid' = now
    //   rsrRewardsAtLastPayout' = current RSR balance ( == rsrRewards() given the above )
    function init(
        IMain main_,
        string calldata name_,
        string calldata symbol_,
        uint48 unstakingDelay_,
        uint192 rewardRatio_,
        uint192 withdrawalLeak_
    ) external initializer {
        require(bytes(name_).length > 0, "name empty");
        require(bytes(symbol_).length > 0, "symbol empty");
        __Component_init(main_);
        __EIP712_init(name_, VERSION);
        name = name_;
        symbol = symbol_;

        assetRegistry = main_.assetRegistry();
        backingManager = main_.backingManager();
        basketHandler = main_.basketHandler();
        rsr = IERC20(address(main_.rsr()));

        payoutLastPaid = uint48(block.timestamp);
        rsrRewardsAtLastPayout = main_.rsr().balanceOf(address(this));
        setUnstakingDelay(unstakingDelay_);
        setRewardRatio(rewardRatio_);
        setWithdrawalLeak(withdrawalLeak_);

        beginEra();
        beginDraftEra();
    }

    /// Assign reward payouts to the staker pool
    /// @custom:refresher
    function payoutRewards() external {
        requireNotFrozen();
        _payoutRewards();
    }

    /// Stakes an RSR `amount` on the corresponding RToken to earn yield and over-collateralize
    /// the system
    /// @param rsrAmount {qRSR}
    /// @dev Staking continues while paused/frozen, without reward handouts
    /// @custom:interaction CEI
    // checks:
    //   0 < rsrAmount
    //
    // effects:
    //   stakeRSR' = stakeRSR + rsrAmount
    //   totalStakes' = stakeRSR' * stakeRate / 1e18   (as required by invariant)
    //   bal'[caller] = bal[caller] + (totalStakes' - totalStakes)
    //   stakeRate' = stakeRate     (this could go without saying, but it's important!)
    //
    // actions:
    //   rsr.transferFrom(account, this, rsrAmount)
    function stake(uint256 rsrAmount) public {
        require(rsrAmount > 0, "Cannot stake zero");

        if (!main.frozen()) _payoutRewards();

        // Mint new stakes
        mintStakes(_msgSender(), rsrAmount);

        // == Interactions ==
        IERC20Upgradeable(address(rsr)).safeTransferFrom(_msgSender(), address(this), rsrAmount);
    }

    /// Begins a delayed unstaking for `amount` StRSR
    /// @param stakeAmount {qStRSR}
    /// @custom:interaction
    // checks:
    //   not paused (trading) or frozen
    //   0 < stakeAmount <= bal[caller]
    //
    // effects:
    //   totalStakes' = totalStakes - stakeAmount
    //   bal'[caller] = bal[caller] - stakeAmount
    //   stakeRSR' = ceil(totalStakes' * 1e18 / stakeRate)
    //   stakeRate' = stakeRate (no change)
    //
    //   draftRSR' + stakeRSR' = draftRSR + stakeRSR
    //   draftRate' = draftRate (no change)
    //   totalDrafts' = floor(draftRSR' + draftRate' / 1e18)
    //
    //   A draft for (totalDrafts' - totalDrafts) drafts
    //   is freshly appended to the caller's draft record.
    function unstake(uint256 stakeAmount) external {
        requireNotTradingPausedOrFrozen();

        address account = _msgSender();
        require(stakeAmount > 0, "Cannot withdraw zero");
        require(stakes[era][account] >= stakeAmount, "Not enough balance");

        _payoutRewards();

        // ==== Compute changes to stakes and RSR accounting
        // rsrAmount: how many RSR to move from the stake pool to the draft pool
        // pick rsrAmount as big as we can such that (newTotalStakes <= newStakeRSR * stakeRate)
        _burn(account, stakeAmount);

        // newStakeRSR: {qRSR} = D18 * {qStRSR} / D18{qStRSR/qRSR}
        uint256 newStakeRSR = (FIX_ONE_256 * totalStakes + (stakeRate - 1)) / stakeRate;
        uint256 rsrAmount = stakeRSR - newStakeRSR;
        stakeRSR = newStakeRSR;

        // Create draft
        (uint256 index, uint64 availableAt) = pushDraft(account, rsrAmount);
        emit UnstakingStarted(index, era, account, rsrAmount, stakeAmount, availableAt);
    }

    /// Complete an account's unstaking; callable by anyone
    /// @custom:interaction CEIC - Warning: violates CEI; has checks at the end
    // Let:
    //   r = draft[account]
    //   draftAmount = r.queue[endId - 1].drafts - r.queue[r.left-1].drafts
    //
    // checks:
    //   RToken is fully collateralized and the basket is sound.
    //   The system is not paused (trading) or frozen.
    //   endId <= r.right
    //   r.queue[endId - 1].availableAt <= now
    //
    // effects:
    //   r'.left = max(endId, r.left)
    //   draftSum'(account) = draftSum(account) + draftAmount)
    //   r'.right = r.right
    //   totalDrafts' = totalDrafts - draftAmount
    //   draftRSR' = ceil(totalDrafts' * 1e18 / draftRate)
    //
    // actions:
    //   rsr.transfer(account, rsrOut)
    function withdraw(address account, uint256 endId) external {
        requireNotTradingPausedOrFrozen();

        uint256 firstId = firstRemainingDraft[draftEra][account];
        CumulativeDraft[] storage queue = draftQueues[draftEra][account];
        if (endId == 0 || firstId >= endId) return;

        // == Checks + Effects ==
        require(endId <= queue.length, "index out-of-bounds");
        require(queue[endId - 1].availableAt <= block.timestamp, "withdrawal unavailable");

        // untestable:
        //      firstId will never be zero, due to previous checks against endId
        uint192 oldDrafts = firstId > 0 ? queue[firstId - 1].drafts : 0;
        uint192 draftAmount = queue[endId - 1].drafts - oldDrafts;

        // advance queue past withdrawal
        firstRemainingDraft[draftEra][account] = endId;

        // ==== Compute RSR amount
        uint256 newTotalDrafts = totalDrafts - draftAmount;
        // newDraftRSR: {qRSR} = {qDrafts} * D18 / D18{qDrafts/qRSR}
        uint256 newDraftRSR = (newTotalDrafts * FIX_ONE_256 + (draftRate - 1)) / draftRate;
        uint256 rsrAmount = draftRSR - newDraftRSR;

        if (rsrAmount == 0) return;

        // ==== Transfer RSR from the draft pool
        totalDrafts = newTotalDrafts;
        draftRSR = newDraftRSR;

        // == Interactions ==
        leakyRefresh(rsrAmount);
        IERC20Upgradeable(address(rsr)).safeTransfer(account, rsrAmount);
        emit UnstakingCompleted(firstId, endId, draftEra, account, rsrAmount);

        // == Checks ==
        require(basketHandler.fullyCollateralized(), "RToken uncollateralized");
        require(basketHandler.isReady(), "basket not ready");
    }

    /// Cancel an ongoing unstaking; resume staking
    /// @custom:interaction CEI
    function cancelUnstake(uint256 endId) external {
        requireNotFrozen();
        address account = _msgSender();

        // We specifically allow unstaking when under collateralized
        // require(basketHandler.fullyCollateralized(), "RToken uncollateralized");
        // require(basketHandler.isReady(), "basket not ready");

        uint256 firstId = firstRemainingDraft[draftEra][account];
        CumulativeDraft[] storage queue = draftQueues[draftEra][account];
        if (endId == 0 || firstId >= endId) return;

        require(endId <= queue.length, "index out-of-bounds");

        // Cancelling unstake does not require checking if the unstaking was available
        // require(queue[endId - 1].availableAt <= block.timestamp, "withdrawal unavailable");

        uint192 oldDrafts = firstId > 0 ? queue[firstId - 1].drafts : 0;
        uint192 draftAmount = queue[endId - 1].drafts - oldDrafts;

        // advance queue past withdrawal
        firstRemainingDraft[draftEra][account] = endId;

        // ==== Compute RSR amount
        uint256 newTotalDrafts = totalDrafts - draftAmount;
        // newDraftRSR: {qRSR} = {qDrafts} * D18 / D18{qDrafts/qRSR}
        uint256 newDraftRSR = (newTotalDrafts * FIX_ONE_256 + (draftRate - 1)) / draftRate;
        uint256 rsrAmount = draftRSR - newDraftRSR;

        if (rsrAmount == 0) return;

        // ==== Transfer RSR from the draft pool
        totalDrafts = newTotalDrafts;
        draftRSR = newDraftRSR;

        emit UnstakingCancelled(firstId, endId, draftEra, account, rsrAmount);

        // Mint new stakes
        mintStakes(account, rsrAmount);
    }

    /// @param rsrAmount {qRSR}
    /// Must seize at least `rsrAmount`, or revert
    /// @custom:protected
    // let:
    //   keepRatio = 1 - (rsrAmount / rsr.balanceOf(this))
    //
    // checks:
    //   0 < rsrAmount <= rsr.balanceOf(this)
    //   not paused (trading) or frozen
    //   caller is backingManager
    //
    // effects, in two phases. Phase 1: (from x to x')
    //   stakeRSR' = floor(stakeRSR * keepRatio)
    //   totalStakes' = totalStakes
    //   stakeRate' = ceil(totalStakes' * 1e18 / stakeRSR')
    //
    //   draftRSR' = floor(draftRSR * keepRatio)
    //   totalDrafts' = totalDrafts
    //   draftRate' = ceil(totalDrafts' * 1e18 / draftRSR')
    //
    //   let fromRewards = floor(rsrRewards() * (1 - keepRatio))
    //
    // effects phase 2: (from x' to x'')
    //   draftRSR'' = (draftRSR' <= MAX_DRAFT_RATE) ? draftRSR' : 0
    //   if draftRSR'' = 0, then totalDrafts'' = 0 and draftRate'' = FIX_ONE
    //   stakeRSR'' = (stakeRSR' <= MAX_STAKE_RATE) ? stakeRSR' : 0
    //   if stakeRSR'' = 0, then totalStakes'' = 0 and stakeRate'' = FIX_ONE
    //
    // actions:
    //   as (this), rsr.transfer(backingManager, seized)
    //   where seized = draftRSR - draftRSR'' + stakeRSR - stakeRSR'' + fromRewards
    //
    // other properties:
    //   seized >= rsrAmount, which should be a logical consequence of the above effects
    function seizeRSR(uint256 rsrAmount) external {
        requireNotTradingPausedOrFrozen();

        require(_msgSender() == address(backingManager), "not backing manager");
        require(rsrAmount > 0, "Amount cannot be zero");

        uint256 rsrBalance = rsr.balanceOf(address(this));
        require(rsrAmount <= rsrBalance, "Cannot seize more RSR than we hold");

        _payoutRewards();

        uint256 seizedRSR;
        uint192 initRate = exchangeRate();
        uint256 rewards = rsrRewards();

        // Remove RSR from stakeRSR
        uint256 stakeRSRToTake = (stakeRSR * rsrAmount + (rsrBalance - 1)) / rsrBalance;
        stakeRSR -= stakeRSRToTake;
        seizedRSR = stakeRSRToTake;

        // update stakeRate, possibly beginning a new stake era
        if (stakeRSR > 0) {
            // Downcast is safe: totalStakes is 1e38 at most so expression maximum value is 1e56
            stakeRate = uint192((FIX_ONE_256 * totalStakes + (stakeRSR - 1)) / stakeRSR);
        }
        if (stakeRSR == 0 || stakeRate > MAX_STAKE_RATE) {
            seizedRSR += stakeRSR;
            beginEra();
        }

        // Remove RSR from draftRSR
        uint256 draftRSRToTake = (draftRSR * rsrAmount + (rsrBalance - 1)) / rsrBalance;
        draftRSR -= draftRSRToTake;
        seizedRSR += draftRSRToTake;

        // update draftRate, possibly beginning a new draft era
        if (draftRSR > 0) {
            // Downcast is safe: totalDrafts is 1e38 at most so expression maximum value is 1e56
            draftRate = uint192((FIX_ONE_256 * totalDrafts + (draftRSR - 1)) / draftRSR);
        }

        if (draftRSR == 0 || draftRate > MAX_DRAFT_RATE) {
            seizedRSR += draftRSR;
            beginDraftEra();
        }

        // Remove RSR from yet-unpaid rewards (implicitly)
        seizedRSR += (rewards * rsrAmount + (rsrBalance - 1)) / rsrBalance;
        rsrRewardsAtLastPayout = rsrRewards() - seizedRSR;

        // Transfer RSR to caller
        emit ExchangeRateSet(initRate, exchangeRate());
        IERC20Upgradeable(address(rsr)).safeTransfer(_msgSender(), seizedRSR);
    }

    /// @return D18{qRSR/qStRSR} The exchange rate between RSR and StRSR
    function exchangeRate() public view returns (uint192) {
        // D18{qRSR/qStRSR} = D18 * D18 / D18{qStRSR/qRSR}
        return (FIX_SCALE_SQ + (stakeRate / 2)) / stakeRate; // ROUND method
    }

    /// Return the maximum value of endId such that withdraw(endId) can immediately work
    // let r = draft[account]
    // returns:
    //   if r.left == r.right: r.right (i.e, withdraw 0 drafts)
    //   else: the least id such that r.left <= id <= r.right and r.queue[id].availableAt > now
    function endIdForWithdraw(address account) external view returns (uint256) {
        uint256 time = block.timestamp;
        CumulativeDraft[] storage queue = draftQueues[draftEra][account];

        // Bounds our search for the current cumulative draft
        (uint256 left, uint256 right) = (firstRemainingDraft[draftEra][account], queue.length);

        // If there are no drafts to be found, return 0 drafts
        if (left >= right) return right;
        if (queue[left].availableAt > time) return left;

        // Otherwise, there *are* drafts with left <= index < right and availableAt <= time.
        // Binary search:
        uint256 test;
        while (left < right - 1) {
            // Loop invariants, because without great care a binary search is usually wrong:
            // - queue[left].availableAt <= time
            // - either right == queue.length or queue[right].availableAt > time
            test = (left + right) / 2; // left < test < right because left < right - 1
            if (queue[test].availableAt <= time) left = test;
            else right = test;
        }
        return right;
    }

    /// Used by FacadeP1
    /// @return The length of the draft queue for an account in an era
    function draftQueueLen(uint256 era_, address account) external view returns (uint256) {
        return draftQueues[era_][account].length;
    }

    /// @return {qDrafts} The amount of RSR currently being withdrawn
    function getDraftRSR() external view returns (uint256) {
        return draftRSR;
    }

    /// @return {qRSR} The amount of RSR currently being staked and earning rewards
    function getStakeRSR() external view returns (uint256) {
        return stakeRSR;
    }

    /// @return {qDrafts} The amount of StRSR currently being withdrawn
    function getTotalDrafts() external view returns (uint256) {
        return totalDrafts;
    }

    // ==== Internal Functions ====

    /// Assign reward payouts to the staker pool
    /// @dev do this by effecting stakeRSR and payoutLastPaid as appropriate, given the current
    /// value of rsrRewards()
    /// @dev perhaps astonishingly, this _isn't_ a refresher

    // let
    //   N = numPeriods; the number of whole rewardPeriods since the last payout
    //   payout = rsrRewards() * (1 - (1 - rewardRatio)^N)  (see [strsr-payout-formula])
    //
    // effects:
    //   stakeRSR' = stakeRSR + payout
    //   rsrRewards'() = rsrRewards() - payout   (implicit in the code, but true)
    //   stakeRate' = ceil(totalStakes' * 1e18 / stakeRSR')  (because [stake-rate])
    //     unless totalStakes == 0 or stakeRSR == 0, in which case stakeRate' = FIX_ONE
    //   totalStakes' = totalStakes
    //
    // [strsr-payout-formula]:
    //   The process we're modelling is:
    //     N = number of whole rewardPeriods since last _payoutRewards() call
    //     rewards_0 = rsrRewards()
    //     payout_{i+1} = rewards_i * payoutRatio
    //     rewards_{i+1} = rewards_i - payout_{i+1}
    //     payout = sum{payout_i for i in [1...N]}
    //   thus:
    //     rewards_N = rewards_0 - payout
    //     rewards_{i+1} = rewards_i - rewards_i * payoutRatio = rewards_i * (1-payoutRatio)
    //     rewards_N = rewards_0 * (1-payoutRatio) ^ N
    //     payout = rewards_N - rewards_0 = rewards_0 * (1 - (1-payoutRatio)^N)
    function _payoutRewards() internal {
        if (block.timestamp < payoutLastPaid + PERIOD) return;
        uint48 numPeriods = (uint48(block.timestamp) - payoutLastPaid) / PERIOD;

        uint192 initRate = exchangeRate();
        uint256 payout;

        // Do an actual payout if and only if enough RSR is staked!
        if (totalStakes >= FIX_ONE) {
            // Paying out the ratio r, N times, equals paying out the ratio (1 - (1-r)^N) 1 time.
            // Apply payout to RSR backing
            // payoutRatio: D18 = FIX_ONE: D18 - FixLib.powu(): D18
            // Both uses of uint192(-) are fine, as it's equivalent to FixLib.sub().
            uint192 payoutRatio = FIX_ONE - FixLib.powu(FIX_ONE - rewardRatio, numPeriods);

            // payout: {qRSR} = D18{1} * {qRSR} / D18
            payout = (payoutRatio * rsrRewardsAtLastPayout) / FIX_ONE;
            stakeRSR += payout;
        }

        payoutLastPaid += numPeriods * PERIOD;
        rsrRewardsAtLastPayout = rsrRewards();

        // stakeRate else case: D18{qStRSR/qRSR} = {qStRSR} * D18 / {qRSR}
        // downcast is safe: it's at most 1e38 * 1e18 = 1e56
        // untestable:
        //      the second half of the OR comparison is untestable because of the invariant:
        //      if totalStakes == 0, then stakeRSR == 0
        stakeRate = (stakeRSR == 0 || totalStakes == 0)
            ? FIX_ONE
            : uint192((totalStakes * FIX_ONE_256 + (stakeRSR - 1)) / stakeRSR);

        emit RewardsPaid(payout);
        emit ExchangeRateSet(initRate, exchangeRate());
    }

    /// @param rsrAmount {qRSR}
    /// @return index The index of the draft
    /// @return availableAt {s} The timestamp the cumulative draft vests
    // effects:
    //   draftRSR' = draftRSR + rsrAmount
    //   draftRate' = draftRate    (ie, unchanged)
    //   totalDrafts' = floor(draftRSR' * draftRate' / 1e18)
    //   r'.left = r.left
    //   r'.right = r.right + 1
    //   r'.queue is r.queue with a new entry appeneded for (totalDrafts' - totalDraft) drafts
    //   where r = draft[account] and r' = draft'[account]
    function pushDraft(address account, uint256 rsrAmount)
        internal
        returns (uint256 index, uint64 availableAt)
    {
        // draftAmount: how many drafts to create and assign to the user
        // pick draftAmount as big as we can such that (newTotalDrafts <= newDraftRSR * draftRate)
        draftRSR += rsrAmount;
        // newTotalDrafts: {qDrafts} = D18{qDrafts/qRSR} * {qRSR} / D18
        uint256 newTotalDrafts = (draftRate * draftRSR) / FIX_ONE;
        uint256 draftAmount = newTotalDrafts - totalDrafts;
        totalDrafts = newTotalDrafts;

        // Push drafts into account's draft queue
        CumulativeDraft[] storage queue = draftQueues[draftEra][account];
        index = queue.length;

        uint192 oldDrafts = index > 0 ? queue[index - 1].drafts : 0;
        uint64 lastAvailableAt = index > 0 ? queue[index - 1].availableAt : 0;
        availableAt = uint64(block.timestamp) + unstakingDelay;
        if (lastAvailableAt > availableAt) {
            availableAt = lastAvailableAt;
        }

        queue.push(CumulativeDraft(uint176(oldDrafts + draftAmount), availableAt));
    }

    /// Zero all stakes and withdrawals
    /// Overriden in StRSRVotes to handle rebases
    // effects:
    //   stakeRSR' = totalStakes' = 0
    //   stakeRate' = FIX_ONE
    function beginEra() internal virtual {
        stakeRSR = 0;
        totalStakes = 0;
        stakeRate = FIX_ONE;
        era++;

        emit AllBalancesReset(era);
    }

    // effects:
    //  draftRSR' = totalDrafts' = 0
    //  draftRate' = FIX_ONE
    function beginDraftEra() internal virtual {
        draftRSR = 0;
        totalDrafts = 0;
        draftRate = FIX_ONE;
        draftEra++;

        emit AllUnstakingReset(draftEra);
    }

    /// @return {qRSR} The balance of RSR that this contract owns dedicated to future RSR rewards.
    function rsrRewards() internal view returns (uint256) {
        return rsr.balanceOf(address(this)) - stakeRSR - draftRSR;
    }

    /// Refresh if too much RSR has exited since the last refresh occurred
    /// @param rsrWithdrawal {qRSR} How much RSR is being withdrawn
    /// Effects-Refresh
    function leakyRefresh(uint256 rsrWithdrawal) private {
        uint48 lastRefresh = assetRegistry.lastRefresh(); // {s}

        // Assumption: rsrWithdrawal has already been taken out of draftRSR
        uint256 totalRSR = stakeRSR + draftRSR + rsrWithdrawal; // {qRSR}
        uint192 withdrawal = _safeWrap((rsrWithdrawal * FIX_ONE + totalRSR - 1) / totalRSR); // {1}

        // == Effects ==
        leaked = lastWithdrawRefresh != lastRefresh ? withdrawal : leaked + withdrawal;
        lastWithdrawRefresh = lastRefresh;

        if (leaked > withdrawalLeak) {
            leaked = 0;
            lastWithdrawRefresh = uint48(block.timestamp);

            /// == Refresh ==
            assetRegistry.refresh();
        }
    }

    /// Mint stakes corresponding to rsrAmount to an account
    /// @param rsrAmount {qRSR} The RSR amount being staked
    function mintStakes(address account, uint256 rsrAmount) private {
        // This is not an overflow risk according to our expected ranges:
        //   rsrAmount <= 1e29, totalStaked <= 1e38, 1e29 * 1e38 < 2^256.
        // stakeAmount: how many stRSR the user shall receive.
        // pick stakeAmount as big as we can such that (newTotalStakes <= newStakeRSR * stakeRate)
        uint256 newStakeRSR = stakeRSR + rsrAmount;
        // newTotalStakes: {qStRSR} = D18{qStRSR/qRSR} * {qRSR} / D18
        uint256 newTotalStakes = (stakeRate * newStakeRSR) / FIX_ONE;
        uint256 stakeAmount = newTotalStakes - totalStakes;

        // Transfer RSR from account to this contract
        stakeRSR += rsrAmount;
        _mint(account, stakeAmount);
        emit Staked(era, account, rsrAmount, stakeAmount);
    }

    // contract-size-saver
    // solhint-disable-next-line no-empty-blocks
    function requireNotTradingPausedOrFrozen() private notTradingPausedOrFrozen {}

    // contract-size-saver
    // solhint-disable-next-line no-empty-blocks
    function requireNotFrozen() private notFrozen {}

    // contract-size-saver
    // solhint-disable-next-line no-empty-blocks
    function requireGovernanceOnly() private governance {}

    // ==== ERC20 ====
    // This section extracted from ERC20; adjusted to work with stakes/eras
    // name(), symbol(), and decimals() are all auto-generated

    function totalSupply() public view returns (uint256) {
        return totalStakes;
    }

    function balanceOf(address account) public view returns (uint256) {
        return stakes[era][account];
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[era][owner][spender];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        _spendAllowance(from, _msgSender(), amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[era][owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[era][owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    // checks: from != 0, to != 0,
    // effects: bal[from] -= amount; bal[to] += amount;
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        mapping(address => uint256) storage eraStakes = stakes[era];
        uint256 fromBalance = eraStakes[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            eraStakes[from] = fromBalance - amount;
        }
        eraStakes[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    // checks: account != 0; totalStakes' < 2^224 - 1  (for StRSRVotes)
    // effects: bal[account] += amount; totalStakes += amount
    // this must only be called from a function that will fixup stakeRSR/Rate
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        assert(totalStakes + amount < type(uint224).max);

        stakes[era][account] += amount;
        totalStakes += amount;

        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }

    // checks: account != 0; bal[account] >= amount
    // effects: bal[account] -= amount; totalStakes -= amount;
    // this must only be called from a function that will fixup stakeRSR/Rate
    function _burn(address account, uint256 amount) internal virtual {
        // untestable:
        //      _burn is only called from unstake(), which uses msg.sender as `account`
        require(account != address(0), "ERC20: burn from the zero address");

        mapping(address => uint256) storage eraStakes = stakes[era];
        uint256 accountBalance = eraStakes[account];
        // untestable:
        //      _burn is only called from unstake(), which already checks this
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            eraStakes[account] = accountBalance - amount;
        }
        totalStakes -= amount;

        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[era][owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = _allowances[era][owner][spender];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /// Used by StRSRVotes to track voting
    // solhint-disable no-empty-blocks
    function _afterTokenTransfer(
        address,
        address to,
        uint256
    ) internal virtual {
        require(to != address(this), "StRSR transfer to self");
    }

    // === ERC20Permit ===
    // This section extracted from OZ:ERC20PermitUpgradeable

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(
            abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline)
        );

        PermitLib.requireSignature(owner, _hashTypedDataV4(structHash), v, r, s);

        _approve(owner, spender, value);
    }

    function nonces(address owner) public view returns (uint256) {
        return _nonces[owner].current();
    }

    function delegationNonces(address owner) public view returns (uint256) {
        return _delegationNonces[owner].current();
    }

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    function _useNonce(address owner) internal returns (uint256 current) {
        CountersUpgradeable.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }

    function _useDelegationNonce(address owner) internal returns (uint256 current) {
        CountersUpgradeable.Counter storage nonce = _delegationNonces[owner];
        current = nonce.current();
        nonce.increment();
    }

    // ==== Gov Param Setters ====

    /// @custom:governance
    function setUnstakingDelay(uint48 val) public {
        requireGovernanceOnly();
        require(val > MIN_UNSTAKING_DELAY && val <= MAX_UNSTAKING_DELAY, "invalid unstakingDelay");
        emit UnstakingDelaySet(unstakingDelay, val);
        unstakingDelay = val;
    }

    /// @custom:governance
    function setRewardRatio(uint192 val) public {
        requireGovernanceOnly();
        if (!main.frozen()) _payoutRewards();
        require(val <= MAX_REWARD_RATIO, "invalid rewardRatio");
        emit RewardRatioSet(rewardRatio, val);
        rewardRatio = val;
    }

    /// @custom:governance
    function setWithdrawalLeak(uint192 val) public {
        requireGovernanceOnly();
        require(val <= MAX_WITHDRAWAL_LEAK, "invalid withdrawalLeak");
        emit WithdrawalLeakSet(withdrawalLeak, val);
        withdrawalLeak = val;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[28] private __gap;
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "../interfaces/IStRSRVotes.sol";
import "./StRSR.sol";

/*
 * @title StRSRP1Votes
 * @notice StRSRP1Votes is an extension of StRSRP1 that makes it IVotesUpgradeable.
 *   It is heavily based on OZ's ERC20VotesUpgradeable
 */
contract StRSRP1Votes is StRSRP1, IStRSRVotes {
    // A Checkpoint[] is a value history; it faithfully represents the history of value so long
    // as that value is only ever set by _writeCheckpoint. For any *previous* block number N, the
    // recorded value at the end of block N was cp.val, where cp in the value history is the
    // Checkpoint value with fromBlock maximal such that fromBlock <= N.

    // In particular, if the value changed during block N, there will be exactly one
    // entry cp with cp.fromBlock = N, and cp.val is the value at the _end_ of that block.
    struct Checkpoint {
        uint48 fromBlock;
        uint224 val;
    }

    bytes32 private constant _DELEGATE_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    // _delegates[account] is the address of the delegate that `accountt` has specified
    mapping(address => address) private _delegates;

    // era history
    Checkpoint[] private _eras; // {era}

    // {era} => ...
    // `_checkpoints[era][account]` is the history of voting power of `account` during era `era`
    mapping(uint256 => mapping(address => Checkpoint[])) private _checkpoints; // {qStRSR}
    // `_totalSupplyCheckpoints[era]` is the history of totalSupply values during era `era`
    mapping(uint256 => Checkpoint[]) private _totalSupplyCheckpoints; // {qStRSR}

    // When RSR is seized, stakeholders are divested not only of their economic position,
    // but also of their governance position.

    // ===

    /// Rebase hook
    /// No need to override beginDraftEra: we are only concerned with raw balances (stakes)
    function beginEra() internal override {
        super.beginEra();

        _writeCheckpoint(_eras, _add, 1);
    }

    function currentEra() external view returns (uint256) {
        return era;
    }

    function checkpoints(address account, uint48 pos) public view returns (Checkpoint memory) {
        return _checkpoints[era][account][pos];
    }

    function numCheckpoints(address account) public view returns (uint48) {
        return SafeCastUpgradeable.toUint48(_checkpoints[era][account].length);
    }

    function delegates(address account) public view returns (address) {
        return _delegates[account];
    }

    function getVotes(address account) public view returns (uint256) {
        uint256 pos = _checkpoints[era][account].length;
        return pos == 0 ? 0 : _checkpoints[era][account][pos - 1].val;
    }

    function getPastVotes(address account, uint256 blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        uint256 pastEra = _checkpointsLookup(_eras, blockNumber);
        return _checkpointsLookup(_checkpoints[pastEra][account], blockNumber);
    }

    function getPastTotalSupply(uint256 blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        uint256 pastEra = _checkpointsLookup(_eras, blockNumber);
        return _checkpointsLookup(_totalSupplyCheckpoints[pastEra], blockNumber);
    }

    function getPastEra(uint256 blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_eras, blockNumber);
    }

    /// Return the value from history `ckpts` that was current for block number `blockNumber`
    function _checkpointsLookup(Checkpoint[] storage ckpts, uint256 blockNumber)
        private
        view
        returns (uint256)
    {
        // We run a binary search to set `high` to the index of the earliest checkpoint
        // taken after blockNumber, or ckpts.length if no checkpoint was taken after blockNumber
        uint256 high = ckpts.length;
        uint256 low = 0;
        while (low < high) {
            uint256 mid = MathUpgradeable.average(low, high);
            if (ckpts[mid].fromBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return high == 0 ? 0 : ckpts[high - 1].val;
    }

    function delegate(address delegatee) public {
        _delegate(_msgSender(), delegatee);
    }

    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(block.timestamp <= expiry, "ERC20Votes: signature expired");
        address signer = ECDSAUpgradeable.recover(
            _hashTypedDataV4(keccak256(abi.encode(_DELEGATE_TYPEHASH, delegatee, nonce, expiry))),
            v,
            r,
            s
        );
        require(nonce == _useDelegationNonce(signer), "ERC20Votes: invalid nonce");
        _delegate(signer, delegatee);
    }

    /// Stakes an RSR `amount` on the corresponding RToken and allows to delegate
    /// votes from the sender to `delegatee` or self
    function stakeAndDelegate(uint256 rsrAmount, address delegatee) external {
        stake(rsrAmount);
        address msgSender = _msgSender();
        address currentDelegate = delegates(msgSender);

        if (delegatee == address(0) && currentDelegate == address(0)) {
            // Delegate to self if no delegate defined and no delegatee provided
            _delegate(msgSender, msgSender);
        } else if (delegatee != address(0) && currentDelegate != delegatee) {
            // Delegate to delegatee if provided and different than current delegate
            _delegate(msgSender, delegatee);
        }
    }

    function _mint(address account, uint256 amount) internal override {
        super._mint(account, amount);
        _writeCheckpoint(_totalSupplyCheckpoints[era], _add, amount);
    }

    function _burn(address account, uint256 amount) internal override {
        super._burn(account, amount);
        _writeCheckpoint(_totalSupplyCheckpoints[era], _subtract, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._afterTokenTransfer(from, to, amount);
        _moveVotingPower(delegates(from), delegates(to), amount);
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates(delegator);
        uint256 delegatorBalance = balanceOf(delegator);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveVotingPower(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveVotingPower(
        address src,
        address dst,
        uint256 amount
    ) private {
        if (src != dst && amount > 0) {
            if (src != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(
                    _checkpoints[era][src],
                    _subtract,
                    amount
                );
                emit DelegateVotesChanged(src, oldWeight, newWeight);
            }

            if (dst != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(
                    _checkpoints[era][dst],
                    _add,
                    amount
                );
                emit DelegateVotesChanged(dst, oldWeight, newWeight);
            }
        }
    }

    // Set this block's value in the history `ckpts`
    function _writeCheckpoint(
        Checkpoint[] storage ckpts,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) private returns (uint256 oldWeight, uint256 newWeight) {
        uint256 pos = ckpts.length;
        oldWeight = pos == 0 ? 0 : ckpts[pos - 1].val;
        newWeight = op(oldWeight, delta);

        if (pos > 0 && ckpts[pos - 1].fromBlock == block.number) {
            ckpts[pos - 1].val = SafeCastUpgradeable.toUint224(newWeight);
        } else {
            ckpts.push(
                Checkpoint({
                    fromBlock: SafeCastUpgradeable.toUint48(block.number),
                    val: SafeCastUpgradeable.toUint224(newWeight)
                })
            );
        }
    }

    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../libraries/Fixed.sol";
import "../../interfaces/IAsset.sol";
import "../../interfaces/ITrade.sol";

uint192 constant FORTY_PERCENT = 4e17; // {1} 0.4
uint192 constant SIXTY_PERCENT = 6e17; // {1} 0.6

// Exponential price decay with base (999999/1000000). Price starts at 1000x and decays to 1x
//   A 30-minute auction on a chain with a 12-second blocktime has a ~10.87% price drop per block
//   during the geometric/exponential period and a 0.05% drop during the linear period.
//   30-minutes is the recommended length of auction for a chain with 12-second blocktimes, but
//   longer and shorter times can be used as well. The pricing algorithm does not degrade
//   beyond the degree to which less overall blocktime means necessarily larger price drops.
uint192 constant MAX_EXP = 6907752 * FIX_ONE; // {1} (1000000/999999)^6907752 = ~1000x
uint192 constant BASE = 999999e12; // {1} (999999/1000000)

/**
 * @title DutchTrade
 * @notice Implements a wholesale dutch auction via a piecewise falling-price mechansim.
 *   Over the first 40% of the auction the price falls from ~1000x the best plausible price
 *   down to the best plausible price in a geometric series. The price decreases by the same %
 *   each time. At 30 minutes the decreases are 10.87% per block. Longer auctions have
 *   smaller price decreases, and shorter auctions have larger price decreases.
 *   This period DOES NOT expect to receive a bid; it just defends against manipulated prices.
 *
 *   Over the last 60% of the auction the price falls from the best plausible price to the worst
 *   price, linearly. The worst price is further discounted by the maxTradeSlippage as a fraction
 *   of how far from minTradeVolume to maxTradeVolume the trade lies.
 *   At maxTradeVolume, no further discount is applied.
 *
 * To bid:
 * - Call `bidAmount()` view to check prices at various timestamps
 * - Wait until a desirable block is reached (hopefully not in the first 40% of the auction)
 * - Provide approval of buy tokens and call bid(). The swap will be atomic
 */
contract DutchTrade is ITrade {
    using FixLib for uint192;
    using SafeERC20 for IERC20Metadata;

    TradeKind public constant KIND = TradeKind.DUTCH_AUCTION;

    TradeStatus public status; // reentrancy protection

    ITrading public origin; // the address that initialized the contract

    // === Auction ===
    IERC20Metadata public sell;
    IERC20Metadata public buy;
    uint192 public sellAmount; // {sellTok}

    // The auction runs from [startTime, endTime], inclusive
    uint48 public startTime; // {s} when the dutch auction begins (12s after init())
    uint48 public endTime; // {s} when the dutch auction ends if no bids are received

    // highPrice is always 1000x the middlePrice, so we don't need to track it explicitly
    uint192 public middlePrice; // {buyTok/sellTok} The price at which the function is piecewise
    uint192 public lowPrice; // {buyTok/sellTok} The price the auction ends at

    // === Bid ===
    address public bidder;
    // the bid amount is just whatever token balance is in the contract at settlement time

    // This modifier both enforces the state-machine pattern and guards against reentrancy.
    modifier stateTransition(TradeStatus begin, TradeStatus end) {
        require(status == begin, "Invalid trade state");
        status = TradeStatus.PENDING;
        _;
        assert(status == TradeStatus.PENDING);
        status = end;
    }

    // === Public Bid Helper ===

    /// Calculates how much buy token is needed to purchase the lot, at a particular timestamp
    /// @param timestamp {s} The block timestamp to get price for
    /// @return {qBuyTok} The amount of buy tokens required to purchase the lot
    function bidAmount(uint48 timestamp) public view returns (uint256) {
        require(timestamp >= startTime, "auction not started");
        require(timestamp <= endTime, "auction over");

        // {buyTok/sellTok}
        uint192 price = _price(timestamp);

        // {qBuyTok} = {sellTok} * {buyTok/sellTok} * {qBuyTok/buyTok}
        return sellAmount.mul(price, CEIL).shiftl_toUint(int8(buy.decimals()), CEIL);
    }

    // === External ===

    /// @param origin_ The Trader that originated the trade
    /// @param sell_ The asset being sold by the protocol
    /// @param buy_ The asset being bought by the protocol
    /// @param sellAmount_ {qSellTok} The amount to sell in the auction, in token quanta
    /// @param auctionLength {s} How many seconds the dutch auction should run for
    function init(
        ITrading origin_,
        IAsset sell_,
        IAsset buy_,
        uint256 sellAmount_,
        uint48 auctionLength
    ) external stateTransition(TradeStatus.NOT_STARTED, TradeStatus.OPEN) {
        assert(
            address(sell_) != address(0) &&
                address(buy_) != address(0) &&
                auctionLength >= 2 * ONE_BLOCK
        ); // misuse by caller

        // Only start dutch auctions under well-defined prices
        (uint192 sellLow, uint192 sellHigh) = sell_.price(); // {UoA/sellTok}
        (uint192 buyLow, uint192 buyHigh) = buy_.price(); // {UoA/buyTok}
        require(sellLow > 0 && sellHigh < FIX_MAX, "bad sell pricing");
        require(buyLow > 0 && buyHigh < FIX_MAX, "bad buy pricing");

        origin = origin_;
        sell = sell_.erc20();
        buy = buy_.erc20();

        require(sellAmount_ <= sell.balanceOf(address(this)), "unfunded trade");
        sellAmount = shiftl_toFix(sellAmount_, -int8(sell.decimals())); // {sellTok}
        startTime = uint48(block.timestamp) + ONE_BLOCK; // start in the next block
        endTime = startTime + auctionLength;

        // {1}
        uint192 slippage = _slippage(
            sellAmount.mul(sellHigh, FLOOR), // auctionVolume
            origin.minTradeVolume(), // minTradeVolume
            fixMin(sell_.maxTradeVolume(), buy_.maxTradeVolume()) // maxTradeVolume
        );

        // {buyTok/sellTok} = {UoA/sellTok} * {1} / {UoA/buyTok}
        lowPrice = sellLow.mulDiv(FIX_ONE - slippage, buyHigh, FLOOR);
        middlePrice = sellHigh.div(buyLow, CEIL); // no additional slippage
        // highPrice = 1000 * middlePrice

        assert(lowPrice <= middlePrice);
    }

    /// Bid for the auction lot at the current price; settling atomically via a callback
    /// @dev Caller must have provided approval
    /// @return amountIn {qBuyTok} The quantity of tokens the bidder paid
    function bid() external returns (uint256 amountIn) {
        require(bidder == address(0), "bid already received");

        // {qBuyTok}
        amountIn = bidAmount(uint48(block.timestamp)); // enforces auction ongoing

        // Transfer in buy tokens
        bidder = msg.sender;
        buy.safeTransferFrom(bidder, address(this), amountIn);

        // status must begin OPEN
        assert(status == TradeStatus.OPEN);

        // settle() via callback
        origin.settleTrade(sell);

        // confirm callback succeeded
        assert(status == TradeStatus.CLOSED);
    }

    /// Settle the auction, emptying the contract of balances
    /// @return soldAmt {qSellTok} Token quantity sold by the protocol
    /// @return boughtAmt {qBuyTok} Token quantity purchased by the protocol
    function settle()
        external
        stateTransition(TradeStatus.OPEN, TradeStatus.CLOSED)
        returns (uint256 soldAmt, uint256 boughtAmt)
    {
        require(msg.sender == address(origin), "only origin can settle");

        // Received bid
        if (bidder != address(0)) {
            sell.safeTransfer(bidder, sellAmount);
        } else {
            require(block.timestamp >= endTime, "auction not over");
        }

        uint256 sellBal = sell.balanceOf(address(this));
        soldAmt = sellAmount > sellBal ? sellAmount - sellBal : 0;
        boughtAmt = buy.balanceOf(address(this));

        // Transfer balances back to origin
        buy.safeTransfer(address(origin), boughtAmt);
        sell.safeTransfer(address(origin), sellBal);
    }

    /// Anyone can transfer any ERC20 back to the origin after the trade has been closed
    /// @dev Escape hatch in case of accidentally transferred tokens after auction end
    /// @custom:interaction CEI (and respects the state lock)
    function transferToOriginAfterTradeComplete(IERC20Metadata erc20) external {
        require(status == TradeStatus.CLOSED, "only after trade is closed");
        erc20.safeTransfer(address(origin), erc20.balanceOf(address(this)));
    }

    /// @return True if the trade can be settled.
    // Guaranteed to be true some time after init(), until settle() is called
    function canSettle() external view returns (bool) {
        return status == TradeStatus.OPEN && (bidder != address(0) || block.timestamp > endTime);
    }

    // === Private ===

    /// Return a sliding % from 0 (at maxTradeVolume) to maxTradeSlippage (at minTradeVolume)
    /// @param auctionVolume {UoA} The actual auction volume
    /// @param minTradeVolume {UoA} The minimum trade volume
    /// @param maxTradeVolume {UoA} The maximum trade volume
    /// @return slippage {1} The fraction of auctionVolume that should be permitted as slippage
    function _slippage(
        uint192 auctionVolume,
        uint192 minTradeVolume,
        uint192 maxTradeVolume
    ) private view returns (uint192 slippage) {
        slippage = origin.maxTradeSlippage(); // {1}
        if (maxTradeVolume <= minTradeVolume || auctionVolume < minTradeVolume) return slippage;
        if (auctionVolume > maxTradeVolume) return 0; // 0% slippage beyond maxTradeVolume

        // {1} = {1} * ({UoA} - {UoA}} / ({UoA} - {UoA})
        return
            slippage.mul(
                FIX_ONE - divuu(auctionVolume - minTradeVolume, maxTradeVolume - minTradeVolume)
            );
    }

    /// Return the price of the auction at a particular timestamp
    /// @param timestamp {s} The block timestamp
    /// @return {buyTok/sellTok}
    function _price(uint48 timestamp) private view returns (uint192) {
        /// Price Curve:
        ///   - first 40%: geometrically decrease the price from 1000x the middlePrice to 1x
        ///   - last 60: decrease linearly from middlePrice to lowPrice

        uint192 progression = divuu(timestamp - startTime, endTime - startTime); // {1}

        // Fast geometric decay -- 0%-40% of auction
        if (progression < FORTY_PERCENT) {
            uint192 exp = MAX_EXP.mulDiv(FORTY_PERCENT - progression, FORTY_PERCENT, ROUND);

            // middlePrice * ((1000000/999999) ^ exp) = middlePrice / ((999999/1000000) ^ exp)
            // safe uint48 downcast: exp is at-most 6907752
            // {buyTok/sellTok} = {buyTok/sellTok} / {1} ^ {1}
            return middlePrice.div(BASE.powu(uint48(exp.toUint(ROUND))), CEIL);
            // this reverts for middlePrice >= 6.21654046e36 * FIX_ONE
        }

        // Slow linear decay -- 40%-100% of auction
        return
            middlePrice -
            (middlePrice - lowPrice).mulDiv(progression - FORTY_PERCENT, SIXTY_PERCENT);
    }
}

// SPDX-License-Identifier: MIT
// Taken from OZ release 4.7.3 at commit a035b235b4f2c9af4ba88edc4447f02e37f8d124
// The only modification that has been made is in the body of the `permit` function at line 83,
/// where we failover to SignatureChecker in order to handle approvals for smart contracts.

pragma solidity 0.8.17;
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../libraries/Permit.sol";
import "../mixins/Versioned.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * Note: We have modified `permit` to support EIP-1271, technically violating EIP-2612.
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 51
 */
abstract contract ERC20PermitUpgradeable is
    Initializable,
    ERC20Upgradeable,
    IERC20PermitUpgradeable,
    EIP712Upgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    mapping(address => CountersUpgradeable.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    // untestable:
    //      `else` branch of `onlyInitializing` (ie. revert) is currently untestable.
    //      This function is only called inside other `init` functions, each of which is wrapped
    //      in an `initializer` modifier, which would fail first.
    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to
     *      the system-wide semver release version.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    function __ERC20Permit_init(string memory name) internal onlyInitializing {
        __EIP712_init_unchained(name, VERSION);
    }

    // untestable:
    //        This is not needed in the way we handle initializations
    function __ERC20Permit_init_unchained(string memory) internal onlyInitializing {}

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

        /// ==== MODIFICATIONS START ====

        PermitLib.requireSignature(owner, _hashTypedDataV4(structHash), v, r, s);

        /// ==== MODIFICATIONS END ====

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
        CountersUpgradeable.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}