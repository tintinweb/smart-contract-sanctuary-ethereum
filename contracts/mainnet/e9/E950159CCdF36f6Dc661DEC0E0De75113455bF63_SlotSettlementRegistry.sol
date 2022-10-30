pragma solidity 0.8.13;

// SPDX-License-Identifier: BUSL-1.1

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import { StakeHouseUniverse } from "./StakeHouseUniverse.sol";
import { IMembershipRegistry } from "./IMembershipRegistry.sol";
import { ScaledMath } from "./ScaledMath.sol";
import { StakeHouseUUPSCoreModule } from "./StakeHouseUUPSCoreModule.sol";
import { sETH } from "./sETH.sol";
import { CollateralisedSlotManager } from "./CollateralisedSlotManager.sol";
import { ISlotSettlementRegistry } from "./ISlotSettlementRegistry.sol";

/// @title SLOT token manager and share issuer
/// @notice Each StakeHouse has its own share token called sETH. This is the circulating money where as SLOT is part of the broad money supply that is never in circulation.
contract SlotSettlementRegistry is Initializable, ISlotSettlementRegistry, CollateralisedSlotManager, StakeHouseUUPSCoreModule {
    using ScaledMath for uint256;

    /// @notice Constant used to scale up the exchange rate to deal with fractions
    uint256 public constant EXCHANGE_RATE_SCALE = 1e18;

    /// @notice The base exchange rate of SLOT to sETH for all new houses is 3:1 and based on total dETH in house / total SLOT
    uint256 public constant BASE_EXCHANGE_RATE = 3 ether;

    /// @notice maximum amount of SLOT available to slash per KNOT
    uint256 public constant SLASHING_COLLATERAL = 4 ether;

    /// @notice amount of SLOT allocated to free floating sETH of a house
    uint256 public constant FREE_FLOATING_SLOT = 4 ether;

    /// @notice Total amount of SLOT minted per KNOT
    uint256 public constant SLOT_MINTED_PER_KNOT = 8 ether;

    /// @dev Beacon for each sETH proxy deployed. See beacon proxy pattern
    address private sETHBeacon;

    /// @notice StakeHouse registry address -> sETH share token for the StakeHouse
    mapping(address => sETH) public stakeHouseShareTokens;

    /// @notice sETH share token => address of associated StakeHouse
    mapping(sETH => address) public shareTokensToStakeHouse;

    /// @notice StakeHouse address -> total amount of SLOT slashed across all KNOTs in the house. See redemption rate
    mapping(address => uint256) public stakeHouseCurrentSLOTSlashed;

    /// @notice Current amount of SLOT that has been slashed from collateralised slot owner(s) which has not been purchased yet
    mapping(bytes => uint256) public currentSlashedAmountOfSLOTForKnot;

    /// @notice Whether SLOT has been minted for a KNOT
    mapping(bytes => bool) public knotSlotSharesMinted;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function init(
        StakeHouseUniverse _universe,
        address _sETHBeacon
    ) external initializer {
        require(_sETHBeacon != address(0), "sETH beacon is zero");

        __StakeHouseUUPSCoreModule_init(_universe);

        sETHBeacon = _sETHBeacon;
    }

    /// @notice Deploys an sETH token contract for a StakeHouse
    /// @dev Only core module and a StakeHouse that's been deployed by the universe
    /// @param _stakeHouse Address of StakeHouse
    function deployStakeHouseShareToken(address _stakeHouse) external onlyModule onlyValidStakeHouse(_stakeHouse) {
        require(address(stakeHouseShareTokens[_stakeHouse]) == address(0), "Share token already created");

        // deploy and init new sETH
        BeaconProxy sETHProxy = new BeaconProxy(
            sETHBeacon,
            abi.encodeCall(sETH(sETHBeacon).init, ())
        );

        sETH token = sETH(address(sETHProxy));

        stakeHouseShareTokens[_stakeHouse] = token;
        shareTokensToStakeHouse[token] = _stakeHouse;

        emit StakeHouseShareTokenCreated(_stakeHouse);
    }

    /// @notice Adds 8 SLOT and issues shares to that KNOT based on the origin (which StakeHouse a KNOT belongs to)
    /// @dev Only core module and a StakeHouse that's been deployed by the universe
    function mintSLOTAndSharesBatch(
        address _stakeHouse,
        bytes calldata _memberId,
        address _recipient
    ) external onlyModule onlyValidStakeHouse(_stakeHouse) onlyValidStakeHouseKnot(_stakeHouse, _memberId) {
        require(_recipient != address(0), "Zero recipient");
        require(msg.sender == address(universe), "Only banking");

        // Make a note of the SLOT shares being minted - this must not be done more than once
        require(!knotSlotSharesMinted[_memberId], "SLOT shares minted");
        knotSlotSharesMinted[_memberId] = true;

        // Send recipient sETH representing half of the SLOT - they are free to do what they want with the sETH
        // Minted 3:1 effective but user can query active balance at any time which is affected by the dynamic exchange rate
        stakeHouseShareTokens[_stakeHouse].mint(_recipient, 12 ether);

        // The shares for the rest of the SLOT becomes collateral for the KNOT and are managed by the collateralised SLOT registry
        _increaseCollateralisedBalance(_stakeHouse, _recipient, _memberId, SLASHING_COLLATERAL);
    }

    /// @inheritdoc ISlotSettlementRegistry
    function slashAndBuySlot(
        address _stakeHouse,
        bytes calldata _memberId,
        address _slasher,
        uint256 _slashAmount,
        uint256 _buyAmount,
        bool _isKickRequired
    ) external override onlyModule { // both sub methods check stake house and KNOT are valid so no need for duplicate check
        // slash collateralised SLOT owners for the given KNOT
        slash(_stakeHouse, _memberId, _slashAmount, _isKickRequired);

        // buy slashed slot
        buySlashedSlot(_stakeHouse, _memberId, _buyAmount, _slasher);
    }

    /// @inheritdoc ISlotSettlementRegistry
    function slash(
        address _stakeHouse,
        bytes calldata _memberId,
        uint256 _amount,
        bool _isKickRequired
    ) public override onlyModule onlyValidStakeHouse(_stakeHouse) onlyKnotThatHasNotRageQuit(_stakeHouse, _memberId) {
        require(
            currentSlashedAmountOfSLOTForKnot[_memberId] + _amount <= SLASHING_COLLATERAL,
            "Collateral exhausted"
        );

        _slashOwners(_stakeHouse, _memberId, _amount);

        // update the current amount slashed at KNOT and house level
        unchecked {
            stakeHouseCurrentSLOTSlashed[_stakeHouse] += _amount;
            currentSlashedAmountOfSLOTForKnot[_memberId] += _amount;
        } // knot value should not overflow as we have require. House val should not overflow because it allows for (2^256)/(4e18) number of KNOTs to be each fully slashed

        // check whether module declares a kick is required or if all of the collateralised SLOT for a KNOT has been exhausted, then we must kick it
        if (_isKickRequired || ((SLASHING_COLLATERAL - currentSlashedAmountOfSLOTForKnot[_memberId]) < 0.1 ether)) {
            IMembershipRegistry(_stakeHouse).kick(_memberId);
        }

        emit SlotSlashed(_memberId, _amount);
    }

    /// @inheritdoc ISlotSettlementRegistry
    function buySlashedSlot(
        address _stakeHouse,
        bytes calldata _memberId,
        uint256 _amount, // wei amount
        address _recipient
    ) public override onlyModule onlyValidStakeHouse(_stakeHouse) onlyKnotThatHasNotRageQuit(_stakeHouse, _memberId) {
        require(_recipient != address(0), "Recipient cannot be zero");
        require(_amount > 0, "Amount cannot be zero");

        require(
            currentSlashedAmountOfSLOTForKnot[_memberId] >= _amount,
            "Cannot buy more SLOT than has been slashed"
        );

        // reduce the current amount slashed as its being purchased
        unchecked {
            stakeHouseCurrentSLOTSlashed[_stakeHouse] -= _amount; // wei amount
            currentSlashedAmountOfSLOTForKnot[_memberId] -= _amount; // wei amount
        } // require above ensures underflow is prevented

        // update the collateralised registry balances due to the slashed SLOT that has been purchased
        _increaseCollateralisedBalance(_stakeHouse, _recipient, _memberId, _amount);

        emit SlashedSlotPurchased(_memberId, _amount);
    }

    /// @notice a core module can assist a user in rage quitting a StakeHouse
    /// @notice A user MUST have 4 collateralised slot, 4 free circulating (sETH) + dETH of KNOT inside index
    /// @param _stakeHouse Address of the StakeHouse that the knot belongs to
    /// @param _memberId Knot ID
    /// @param _collateralisedSlotOwners The full list of accounts that own collateralised sETH for a KNOT
    /// @param _freeFloatingSlotOwner Owner of the free floating 4 SLOT
    /// @param _savETHIndexOwner Owner of the index that contains the knot rage quitting
    /// @param _amountOfETHInDepositQueue Amount of ETH below 1 ETH that is yet to be sent to the deposit contract
    function rageQuitKnotOnBehalfOf(
        address _stakeHouse,
        bytes calldata _memberId,
        address _ethRecipient,
        address[] calldata _collateralisedSlotOwners,
        address _freeFloatingSlotOwner,
        address _savETHIndexOwner,
        uint256 _amountOfETHInDepositQueue
    ) external onlyModule onlyValidStakeHouse(_stakeHouse) onlyKnotThatHasNotRageQuit(_stakeHouse, _memberId) {
        require(_amountOfETHInDepositQueue == 0, "No funds in the queue permitted");

        _burnTokensUnderRageQuit(
            _stakeHouse,
            _memberId,
            _ethRecipient,
            _collateralisedSlotOwners,
            _freeFloatingSlotOwner,
            _savETHIndexOwner
        );
    }

    /// @notice Account manager can mark a user withdrawn when they have claimed their original staked asset
    function markUserKnotAsWithdrawn(
        address _knotOwner,
        bytes calldata _memberId
    ) external onlyModule {
        require(msg.sender == address(universe.accountManager()), "Only account manager");
        _markUserAsWithdrawn(_knotOwner, _memberId);
    }

    /// @notice Total dETH minted by adding knots and minting inflation rewards within a house
    function dETHMintedInHouse(address _stakeHouse) public view returns (uint256) {
        return universe.saveETHRegistry().totalDETHMintedWithinHouse(_stakeHouse);
    }

    /// @inheritdoc ISlotSettlementRegistry
    function exchangeRate(address _stakeHouse) public override view returns (uint256) {
        uint256 totalDETHMintedWithinHouse = dETHMintedInHouse(_stakeHouse);
        uint256 totalSlotInHouse = activeSlotMintedInHouse(_stakeHouse);

        if (totalDETHMintedWithinHouse == 0 || totalSlotInHouse == 0) {
            return BASE_EXCHANGE_RATE; // 3:1
        }

        return totalDETHMintedWithinHouse.sDivision(totalSlotInHouse);
    }

    /// @inheritdoc ISlotSettlementRegistry
    function redemptionRate(address _stakeHouse) public override view returns (uint256) {
        uint256 totalDETHMintedWithinHouse = dETHMintedInHouse(_stakeHouse);
        uint256 circulatingSlotForHouse = circulatingSlot(_stakeHouse);

        if (totalDETHMintedWithinHouse == 0 || circulatingSlotForHouse == 0) {
            // Exchange rate for a house starts at 3 : 1
            return BASE_EXCHANGE_RATE;
        }

        return totalDETHMintedWithinHouse.sDivision(circulatingSlotForHouse);
    }

    /// @inheritdoc ISlotSettlementRegistry
    function circulatingSlot(
        address _stakeHouse
    ) public override onlyValidStakeHouse(_stakeHouse) view returns (uint256) {
        return activeSlotMintedInHouse(_stakeHouse) - stakeHouseCurrentSLOTSlashed[_stakeHouse];
    }

    /// @notice Total SLOT minted for all KNOTs that have not rage quit the house
    function activeSlotMintedInHouse(address _stakeHouse) public view returns (uint256) {
        return IMembershipRegistry(_stakeHouse).numberOfActiveKNOTsThatHaveNotRageQuit() * SLOT_MINTED_PER_KNOT;
    }

    /// @inheritdoc ISlotSettlementRegistry
    function circulatingCollateralisedSlot(
        address _stakeHouse
    ) public override onlyValidStakeHouse(_stakeHouse) view returns (uint256) {
        return activeCollateralisedSlotMintedInHouse(_stakeHouse) - stakeHouseCurrentSLOTSlashed[_stakeHouse];
    }

    /// @notice Total collateralised SLOT minted for all KNOTs that have not rage quit the house
    function activeCollateralisedSlotMintedInHouse(address _stakeHouse) public view returns (uint256) {
        return IMembershipRegistry(_stakeHouse).numberOfActiveKNOTsThatHaveNotRageQuit() * SLASHING_COLLATERAL;
    }

    /// @inheritdoc ISlotSettlementRegistry
    function currentSlashedAmountForKnot(bytes calldata _memberId) external override view returns (uint256 currentSlashedAmount) {
        return currentSlashedAmountOfSLOTForKnot[_memberId];
    }

    /// @inheritdoc ISlotSettlementRegistry
    function sETHRedemptionThreshold(address _stakeHouse) public override view returns (uint256) {
        // Equivalent to (SLASHING_COLLATERAL * redemptionRate(_stakeHouse))
        return (SLASHING_COLLATERAL * dETHMintedInHouse(_stakeHouse)) / circulatingSlot(_stakeHouse);
    }

    /// @inheritdoc ISlotSettlementRegistry
    function totalCollateralisedSETHForStakehouse(
        address _stakeHouse
    ) external override view returns (uint256) {
        return sETHForSLOTBalance(_stakeHouse, circulatingCollateralisedSlot(_stakeHouse));
    }

    /// @inheritdoc ISlotSettlementRegistry
    function totalUserCollateralisedSETHBalanceInHouse(
        address _stakeHouse,
        address _user
    ) external override view returns (uint256) {
        return sETHForSLOTBalance(
            _stakeHouse,
            totalUserCollateralisedSLOTBalanceInHouse[_stakeHouse][_user]
        );
    }

    /// @inheritdoc ISlotSettlementRegistry
    function totalUserCollateralisedSETHBalanceForKnot(
        address _stakeHouse,
        address _user,
        bytes calldata _memberId
    ) external override view returns (uint256) {
        return sETHForSLOTBalance(
            _stakeHouse,
            totalUserCollateralisedSLOTBalanceForKnot[_stakeHouse][_user][_memberId]
        );
    }

    /// @notice Helper for calculating an sETH balance from a SLOT amount
    /// @param _stakeHouse Target Stakehouse registry - each has their own exchange rate
    /// @param _slotAmount SLOT amount in wei
    function sETHForSLOTBalance(address _stakeHouse, uint256 _slotAmount) public view returns (uint256) {
        // Equivalent to SLOT * exchange rate
        return activeSlotMintedInHouse(_stakeHouse) == 0 ? _slotAmount * 3 :
            (_slotAmount * dETHMintedInHouse(_stakeHouse)) / activeSlotMintedInHouse(_stakeHouse);
    }

    /// @notice Helper for calculating a SLOT balance from an sETH amount
    /// @param _stakeHouse Target Stakehouse registry - each has their own exchange rate
    /// @param _sETHAmount sETH amount in wei
    function slotForSETHBalance(address _stakeHouse, uint256 _sETHAmount) public view returns (uint256) {
        return activeSlotMintedInHouse(_stakeHouse) == 0 ? _sETHAmount.sDivision(BASE_EXCHANGE_RATE) :
            (_sETHAmount * activeSlotMintedInHouse(_stakeHouse)) / dETHMintedInHouse(_stakeHouse);
    }

    /// @inheritdoc ISlotSettlementRegistry
    function getCollateralizedSlotAccumulation(
        address[] calldata _sETHList,
        address _owner
    ) external override view returns (uint256) {
        uint256 sum;
        uint256 listLength = _sETHList.length;

        for (uint256 i; i < listLength; i = _unchecked_inc(i)) {
            /// Used to prevent sETH address repetition, sorting must happen off-chain
            if (i > 0) {
                require(_sETHList[i - 1] < _sETHList[i], 'sETH addresses must be ordered in decreasing order');
            }

            address stakeHouse = shareTokensToStakeHouse[sETH(_sETHList[i])];
            sum += totalUserCollateralisedSLOTBalanceInHouse[stakeHouse][_owner];
        }

        return sum;
    }

    /// @dev Given a KNOT and all tokens minted for the KNOT over its lifecycle, burn the tokens and allow redemption rights to be exercised
    /// @param _stakeHouse Address of registry of associated KNOT
    /// @param _memberId ID of the KNOT
    /// @param _collateralisedSlotOwners The full list of accounts that own collateralised sETH for a KNOT - they all have to approve the rage quit
    /// @param _freeFloatingSlotOwner Account that is in possession of the sETH that freely circulates on the market
    /// @param _savETHIndexOwner Owner of the index in the savETH registry
    function _burnTokensUnderRageQuit(
        address _stakeHouse,
        bytes calldata _memberId,
        address _ethRecipient,
        // even though we have the owners in the contract we request a full list of owners which have signed the rage quit
        address[] calldata _collateralisedSlotOwners,
        address _freeFloatingSlotOwner,
        address _savETHIndexOwner
    ) internal {
        require(_collateralisedSlotOwners.length > 0, "No collateralised owners specified");

        // check that all the collateralised SLOT owners have enough SLOT collateral to rate quit i.e. 4 SLOT
        {
            // KNOT must have the full 8 SLOT to rage quit and if there is any slashing, the ETH has to be supplied to fix that
            require(currentSlashedAmountOfSLOTForKnot[_memberId] == 0, "Knot has been slashed");

            // sum up all the collateral owned by all collateralised KNOT owners
            (
                uint256 totalCollateralisedKnotBalanceFound,
                uint256 totalCollateralisedSLOTBalInHouseFound
            ) = _reduceCollateralisedBalanceForAllHolders(
                _stakeHouse,
                _memberId,
                _collateralisedSlotOwners
            );

            // if the SLOT for all collateralise SLOT owners does not add up to 4, then we are missing an owner
            require(
                totalCollateralisedKnotBalanceFound == SLASHING_COLLATERAL,
                "Missing member"
            );

            // The total collateralised sETH for a KNOT must be greater than or equal to the threshold sETH amount as
            // defined by the redemption rate
            require(
                sETHForSLOTBalance(_stakeHouse, totalCollateralisedSLOTBalInHouseFound) >= sETHRedemptionThreshold(_stakeHouse),
                "Threshold not met"
            );
        }

        // burn free floating SLOT
        stakeHouseShareTokens[_stakeHouse].burn(_freeFloatingSlotOwner, 12 ether);

        // this is the user nominated account that will receive the ETH balance from the beacon chain
        _enableUserForKnotWithdrawal(_ethRecipient, _memberId);

        // rageQuit savETH and burn all dETH tokens
        universe.saveETHRegistry().rageQuitKnot(_stakeHouse, _memberId, _savETHIndexOwner);

        // update the registry to reflect that the member has rage quit the house
        IMembershipRegistry(_stakeHouse).rageQuit(_memberId);

        // off chain logging
        emit RageQuitKnot(_memberId);
    }

    /// @dev Every collateralised SLOT holder for a particular KNOT must have their balance reduced under rage quit
    /// @dev This means also reducing the total collateral a user owns at a house level as well as updating the total collateral in the house
    function _reduceCollateralisedBalanceForAllHolders(
        address _stakeHouse,
        bytes calldata _memberId,
        address[] calldata _collateralisedSlotOwners
    ) internal returns (uint256, uint256) {
        // When iterating over collateralised SLOT owners, we need to total up minted collateralised balance
        // so that on exit we ensure that we have accounted for all collateralised SLOT owners
        uint256 numOfOwners = _collateralisedSlotOwners.length;
        if (numOfOwners == 1) {
            address owner = _collateralisedSlotOwners[0];
            require(isCollateralisedOwner[_memberId][owner], "Invalid owner");
            isCollateralisedOwner[_memberId][owner] = false;

            uint256 knotSLOTBalanceForOwner = totalUserCollateralisedSLOTBalanceForKnot[_stakeHouse][owner][_memberId];
            uint256 userSlotBalAcrossEntireHouse = totalUserCollateralisedSLOTBalanceInHouse[_stakeHouse][owner];

            _decreaseCollateralisedBalance(_stakeHouse, owner, _memberId, knotSLOTBalanceForOwner);

            return (knotSLOTBalanceForOwner, userSlotBalAcrossEntireHouse);
        } else {
            uint256 totalCollateralisedKnotBalanceFound;

            // possibility for 1 owner to have significantly more SLOT at house level than required
            // this is ok as long as rage quit checks that the total collateralised SLOT for a KNOT across all owners
            // is exactly 4 SLOT.
            uint256 totalCollateralisedSLOTBalInHouseFound;

            for (uint256 i; i < numOfOwners; i = _unchecked_inc(i)) {
                address collateralisedSlotOwner = _collateralisedSlotOwners[i];
                require(isCollateralisedOwner[_memberId][collateralisedSlotOwner], "Invalid owner");
                isCollateralisedOwner[_memberId][collateralisedSlotOwner] = false;

                // burn all SLOT balances for the house, user and knot
                uint256 knotSLOTBalanceForOwner = totalUserCollateralisedSLOTBalanceForKnot[_stakeHouse][collateralisedSlotOwner][_memberId];
                require(knotSLOTBalanceForOwner > 0, "Zero SLOT owned");

                totalCollateralisedKnotBalanceFound += knotSLOTBalanceForOwner;
                totalCollateralisedSLOTBalInHouseFound += totalUserCollateralisedSLOTBalanceInHouse[_stakeHouse][collateralisedSlotOwner];

                _decreaseCollateralisedBalance(_stakeHouse, collateralisedSlotOwner, _memberId, knotSLOTBalanceForOwner);
            }

            return (totalCollateralisedKnotBalanceFound, totalCollateralisedSLOTBalInHouseFound);
        }
    }

    /// @dev Starting with entity that tied the knot, slash each collateralised SLOT owner
    function _slashOwners(
        address _stakeHouse,
        bytes calldata _memberId,
        uint256 _amount
    ) internal {
        uint256 leftToSlash = _amount;
        if (leftToSlash > 0) {
            uint256 numOfCollateralisedOwners = collateralisedSLOTOwners[_memberId].length;
            if (numOfCollateralisedOwners == 1) {
                _decreaseCollateralisedBalance(_stakeHouse, collateralisedSLOTOwners[_memberId][0], _memberId, leftToSlash);
                leftToSlash = 0;
            } else { // else clause assumes the array has been set up correctly i.e. it is not possible to have zero owners
                for (uint256 i; i < numOfCollateralisedOwners; i = _unchecked_inc(i)) {
                    address owner = collateralisedSLOTOwners[_memberId][i];
                    uint256 slotBalance = totalUserCollateralisedSLOTBalanceForKnot[_stakeHouse][owner][_memberId];

                    if (slotBalance >= leftToSlash) {
                        _decreaseCollateralisedBalance(_stakeHouse, owner, _memberId, leftToSlash);
                        leftToSlash = 0;
                        break;
                    } else {
                        leftToSlash -= slotBalance;
                        _decreaseCollateralisedBalance(_stakeHouse, owner, _memberId, slotBalance);
                    }
                }
            }
        }
        assert(leftToSlash == 0);
    }

    /// @dev Save GAS by not using SafeMath on loop increment operations
    function _unchecked_inc(uint256 i) internal pure returns (uint256) {
        unchecked {
            return i + 1;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/BeaconProxy.sol)

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../Proxy.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from a {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract BeaconProxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializating the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    constructor(address beacon, bytes memory data) payable {
        assert(_BEACON_SLOT == bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1));
        _upgradeBeaconToAndCall(beacon, data, false);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address) {
        return _getBeacon();
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation() internal view virtual override returns (address) {
        return IBeacon(_getBeacon()).implementation();
    }

    /**
     * @dev Changes the proxy to use a new beacon. Deprecated: see {_upgradeBeaconToAndCall}.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    function _setBeacon(address beacon, bytes memory data) internal virtual {
        _upgradeBeaconToAndCall(beacon, data, false);
    }
}

pragma solidity 0.8.13;

// SPDX-License-Identifier: BUSL-1.1

import { StakeHouseAccessControls } from "./StakeHouseAccessControls.sol";
import { ISavETHRegistry } from "./ISavETHRegistry.sol";

interface StakeHouseUniverse {
    /// @notice Emitted when all of the core modules are initialised
    event CoreModulesInit();

    /// @notice Emitted after a Stakehouse has been deployed. A share token and brand are also deployed
    event NewStakeHouse(address indexed stakeHouse, uint256 indexed brandId);

    /// @notice Emitted after a member is added to an existing Stakehouse
    event MemberAddedToExistingStakeHouse(address indexed stakeHouse);

    /// @notice Emitted after a member is added to an existing house but a brand was created
    event MemberAddedToExistingStakeHouseAndBrandCreated(address indexed stakeHouse, uint256 indexed brandId);

    function accessControls() external view returns (StakeHouseAccessControls);

    function saveETHRegistry() external view returns (ISavETHRegistry);

    function slotRegistry() external view returns (address);

    function accountManager() external view returns (address);

    function stakeHouseToKNOTIndex(address _house) external view returns (uint256 houseIndex);

    /// @notice Adds a new StakeHouse into the universe
    /// @notice A StakeHouse only comes into existence if one KNOT is being added
    /// @param _summoner StakeHouse creator
    /// @param _ticker Desired StakeHouse internal identifier.
    /// @param _firstMember bytes of the public key of the first member
    /// @param _savETHIndexId ID of the savETH registry index that will receive savETH for the KNOT. Set to zero to create a new index owned by _summoner
    function newStakeHouse(
        address _summoner,
        string calldata _ticker,
        bytes calldata _firstMember,
        uint256 _savETHIndexId
    ) external returns (address);

    /// @notice Adds a KNOT into an existing StakeHouse (and does not create a brand)
    /// @param _stakeHouse Address of the house receiving the new member
    /// @param _memberId Public key of the KNOT
    /// @param _applicant Account adding the KNOT to the StakeHouse (derivative recipient)
    /// @param _savETHIndexId ID of the savETH registry index that will receive savETH for the KNOT. Set to zero to create a new index owned by _applicant
    function addMemberToExistingHouse(
        address _stakeHouse,
        bytes calldata _memberId,
        address _applicant,
        uint256 _brandTokenId,
        uint256 _savETHIndexId
    ) external;

    /// @notice Adds a KNOT into an existing house but this KNOT creates a brand
    /// @param _stakeHouse Address of the house receiving the new member
    /// @param _memberId Public key of the KNOT
    /// @param _applicant Account adding the KNOT to the StakeHouse (derivative recipient)
    /// @param _ticker Proposed 3-5 letter ticker for brand
    /// @param _savETHIndexId ID of the savETH registry index that will receive savETH for the KNOT. Set to zero to create a new index owned by _applicant
    function addMemberToHouseAndCreateBrand(
        address _stakeHouse,
        bytes calldata _memberId,
        address _applicant,
        string calldata _ticker,
        uint256 _savETHIndexId
    ) external;

    /// @notice Escape hatch for a user that wants to immediately exit the universe on entry
    /// @param _stakeHouse Address of the house user is rage quitting against
    /// @param _memberId Public key of the KNOT
    /// @param _rageQuitter Account rage quitting
    /// @param _amountOfETHInDepositQueue Amount of ETH below 1 ETH that is yet to be sent to the deposit contract
    function rageQuitKnot(
        address _stakeHouse,
        bytes calldata _memberId,
        address _rageQuitter,
        uint256 _amountOfETHInDepositQueue
    ) external;

    /// @notice Number of StakeHouses in the universe
    function numberOfStakeHouses() external view returns (uint256);

    /// @notice Returns the address of a StakeHouse assigned to an index
    /// @param _index Query which must be greater than zero
    function stakeHouseAtIndex(uint256 _index) external view returns (address);

    /// @notice number of members of a StakeHouse (aggregate number of KNOTs)
    /// @dev Imagine we have a rope loop attached to a StakeHouse KNOT, each KNOT on the loop is a member
    /// @dev This enumerable method is used along with `numberOfStakeHouses`
    /// @param _index of a StakeHouse
    /// @return uint256 The number of total KNOTs / members of a StakeHouse
    function numberOfSubKNOTsAtIndex(uint256 _index) external view returns (uint256);

    /// @notice Given a StakeHouse index and a member index (i.e. coordinates to a member), return the member ID
    /// @param _index Coordinate assigned to Stakehouse
    /// @param _subIndex Coordinate assigned to a member of a Stakehouse
    function subKNOTAtIndexCoordinates(uint256 _index, uint256 _subIndex) external view returns (bytes memory);

    /// @notice Get all info about a StakeHouse KNOT (a member a.k.a a validator) given index coordinates
    /// @param _index StakeHouse index
    /// @param _subIndex Member index within the StakeHouse
    function stakeHouseKnotInfoGivenCoordinates(uint256 _index, uint256 _subIndex) external view returns (
        address stakeHouse,
        address sETHAddress,
        address applicant,
        uint256 knotMemberIndex,
        uint256 flags,
        bool isActive
    );

    /// @notice Get all info about a StakeHouse KNOT (a member a.k.a a validator)
    /// @param _memberId ID of member (Validator public key) assigned to StakeHouse
    function stakeHouseKnotInfo(bytes memory _memberId) external view returns (
        address stakeHouse,     // Address of registered StakeHouse
        address sETHAddress,    // Address of sETH address associated with StakeHouse
        address applicant,      // Address of ETH account that added the member to the StakeHouse
        uint256 knotMemberIndex,// KNOT Index of the member within the StakeHouse
        uint256 flags,          // Flags associated with the member
        bool isActive           // Whether the member is active or knot
    );
}

pragma solidity 0.8.13;

// SPDX-License-Identifier: BUSL-1.1

import { IGateKeeper } from "./IGateKeeper.sol";

interface IMembershipRegistry {
    /// @notice A new member was added to the registry
    event MemberAdded(uint256 indexed knotIndex);

    /// @notice A member was kicked due to an action in another core module
    event MemberKicked(uint256 indexed knotIndex);

    /// @notice A member decided that they did not want to be part of the protocol
    event MemberRageQuit(uint256 indexed knotIndex);

    /// @notice Called by house creator to set up a gate keeper smart contracts used when adding members
    /// @param _gateKeeper Address of gate keeper contract that will perform member checks
    function setGateKeeper(IGateKeeper _gateKeeper) external;

    /// @notice View for establishing if a future validator is allowed to become a member of a Stakehouse
    /// @param _blsPubKey of the validator registered on the beacon chain
    function isMemberPermitted(bytes calldata _blsPubKey) external view returns (bool);

    /// @notice Adds a new member to a stake house if gatekeeper allows
    /// @dev Only a core module can undertake this operation
    /// @param _applicant ETH1 account applying to add the ETH2 member
    /// @param _memberId Bytes of the public key of the ETH2 member
    function addMember(address _applicant, bytes calldata _memberId) external;

    /// @notice Kick a member from a StakeHouse
    /// @dev Only core module
    /// @param _memberId ID of the member being kicked
    function kick(bytes calldata _memberId) external;

    /// @notice Allow rage quitting from a StakeHouse
    /// @dev Only core module
    /// @param _memberId ID of the member being kicked
    function rageQuit(bytes calldata _memberId) external;

    /// @notice number of members of a StakeHouse
    function numberOfMemberKNOTs() external view returns (uint256);

    /// @notice total number of KNOTs in the house that have not rage quit
    function numberOfActiveKNOTsThatHaveNotRageQuit() external view returns (uint256);

    /// @notice Allows an external entity to check if a member is part of a stake house
    /// @param _memberId Bytes of the public key of the member
    function isActiveMember(bytes calldata _memberId) external view returns (bool);

    /// @notice Check if a member is part of the registry but not rage quit (this ignores whether they have been kicked)
    /// @param _memberId Bytes of the public key of the member
    function hasMemberRageQuit(bytes calldata _memberId) external view returns (bool);

    /// @notice Get all info about a member at its assigned index
    function getMemberInfoAtIndex(uint256 _memberKNOTIndex) external view returns (
        address applicant,
        uint256 knotMemberIndex,
        uint16 flags,
        bool isActive
    );

    /// @notice Get all info about a member given its unique ID (validator pub key)
    function getMemberInfo(bytes memory _memberId) external view returns (
        address applicant,      // Address of ETH account that added the member to the StakeHouse
        uint256 knotMemberIndex,// KNOT Index of the member within the StakeHouse
        uint16 flags,          // Flags associated with the member
        bool isActive           // Whether the member is active or knot
    );
}

pragma solidity 0.8.13;

// SPDX-License-Identifier: BUSL-1.1

library ScaledMath {
    /// @dev Perform scaled division
    /// @dev As per Compound's exponential library, we scale the numerator by 1e18 before dividing
    /// @dev This means that the result is scaled by 1e18 and needs to be divided by 1e18 outside this fn to get the actual value
    function sDivision(uint256 _numerator, uint256 _denominator) internal pure returns (uint256) {
        uint256 numeratorScaled = _numerator * 1e18;
        return numeratorScaled / _denominator;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ModuleGuards } from "./ModuleGuards.sol";
import { StakeHouseUniverse } from "./StakeHouseUniverse.sol";
import { StakeHouseAccessControls } from "./StakeHouseAccessControls.sol";

abstract contract StakeHouseUUPSCoreModule is UUPSUpgradeable, ModuleGuards {
    function __StakeHouseUUPSCoreModule_init(StakeHouseUniverse _universe) internal {
        __initModuleGuards(_universe);
        __UUPSUpgradeable_init();
    }

    // address param is address of new implementation
    function _authorizeUpgrade(address) internal view override {
        require(address(universe) != address(0), "Init Err");
        StakeHouseAccessControls accessControls = universe.accessControls();
        require(!accessControls.isCoreModuleLocked(address(this)) && accessControls.isProxyAdmin(msg.sender), "Only mutable");
    }
}

pragma solidity 0.8.13;

// SPDX-License-Identifier: BUSL-1.1

import { ERC20PermitUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import { SlotSettlementRegistry } from "./SlotSettlementRegistry.sol";
import { IMembershipRegistry } from "./IMembershipRegistry.sol";
import { ScaledMath } from "./ScaledMath.sol";

contract sETH is ERC20PermitUpgradeable {
    using ScaledMath for uint256;

    /// @notice Address of registry of all SLOT tokens
    SlotSettlementRegistry public slotRegistry;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @notice Used in place of a constructor to support proxies
    /// @dev Can only be called once
    function init() external initializer {
        slotRegistry = SlotSettlementRegistry(msg.sender);

        __ERC20_init(
            "sETH",
            "sETH"
        );

        __ERC20Permit_init("sETH");
    }

    /// @notice Mints a given amount of tokens
    /// @dev Only slot settlement registry module can call
    /// @param _recipient of the tokens
    /// @param _amount of tokens to mint
    function mint(address _recipient, uint256 _amount) external {
        require(msg.sender == address(slotRegistry), "mint: Only SLOT registry");
        _mint(_recipient, _amount);
    }

    /// @notice Burns a given amount of tokens
    /// @dev Only slot settlement registry module can call
    /// @param _owner of the tokens
    /// @param _amount of tokens to burn
    function burn(address _owner, uint256 _amount) external {
        require(msg.sender == address(slotRegistry), "burn: Only SLOT registry");
        _burn(_owner, _amount);
    }

    /// @notice Get the address of the associated Stakehouse registry
    function stakehouse() public view returns (address) {
        return slotRegistry.shareTokensToStakeHouse(
            sETH(address(this))
        );
    }

    /// @notice Total collateralised SLOT associated with Stakehouse
    function stakehouseCollateralisedSlot() public view returns (uint256) {
        return slotRegistry.circulatingCollateralisedSlot(stakehouse());
    }

    /// @notice For an account with sETH, the amount of SLOT backing those tokens based on actual balance
    /// @param _owner Account containing sETH tokens
    function slot(address _owner) external view returns (uint256) {
        if (_owner == address(slotRegistry)) {
            return stakehouseCollateralisedSlot();
        }

        return slotRegistry.slotForSETHBalance(stakehouse(), balanceOf(_owner));
    }

    /// @notice For an account with sETH, the amount of SLOT backing those tokens based on active balance
    /// @param _owner Account containing sETH tokens
    function slotForActiveBalance(address _owner) external view returns (uint256) {
        if (_owner == address(slotRegistry)) {
            return stakehouseCollateralisedSlot();
        }

        return balanceOf(_owner).sDivision(slotRegistry.BASE_EXCHANGE_RATE());
    }

    /// @notice sETH balance of owner factoring in the latest exchange rate of the Stakehouse
    /// @param _owner Account containing sETH tokens
    function activeBalanceOf(address _owner) public view returns (uint256) {
        uint256 sETHBalance = slotRegistry.sETHForSLOTBalance(stakehouse(), balanceOf(_owner));
        return sETHBalance.sDivision(slotRegistry.BASE_EXCHANGE_RATE());
    }
}

pragma solidity 0.8.13;

// SPDX-License-Identifier: BUSL-1.1

/// @dev Management of the collateralised SLOT accounts for all users, KNOTs and StakeHouses
abstract contract CollateralisedSlotManager {

    event CollateralisedOwnerAddedToKnot(bytes knotId, address indexed owner);

    /// @notice User is able to trigger beacon chain withdrawal
    event UserEnabledForWithdrawal(address indexed user, bytes memberId);

    /// @notice User has withdrawn ETH from beacon chain - do not allow any more withdrawals
    event UserWithdrawn(address indexed user, bytes memberId);

    /// @notice Total collateralised SLOT owned by an account across all KNOTs in a given StakeHouse
    /// @dev Stakehouse address -> user account -> SLOT balance
    mapping(address => mapping(address => uint256)) public totalUserCollateralisedSLOTBalanceInHouse;

    /// @notice Total collateralised SLOT owned by an account for a given KNOT in a Stakehouse
    /// @dev Stakehouse address -> user account -> Knot ID (bls pub key) -> SLOT balance collateralised against the KNOT
    mapping(address => mapping(address => mapping(bytes => uint256))) public totalUserCollateralisedSLOTBalanceForKnot;

    /// @notice List of accounts that have ever owned collateralised SLOT for a given KNOT
    mapping(bytes => address[]) public collateralisedSLOTOwners;

    /// @notice Given a KNOT and account, a flag represents whether the account has been a collateralised SLOT owner in  the past
    /// @dev KNOT ID (bls pub key) -> user account -> Whether it has been a collateralised SLOT owner
    mapping(bytes => mapping(address => bool)) public isCollateralisedOwner;

    /// @notice If a user account has been able to rage quit a KNOT, this flag is set to true to allow ETH2 funds to be claimed
    /// @dev user account -> Knot ID (validator pub key) -> enabled for withdrawal
    mapping(address => mapping(bytes => bool)) public isUserEnabledForKnotWithdrawal;

    /// @notice Once ETH2 funds have been redeemed, this flag is set to true in order to block double withdrawals
    /// @dev user account -> Knot ID (validator pub key) -> has user withdrawn
    mapping(address => mapping(bytes => bool)) public userWithdrawn;

    /// @notice Total number of collateralised SLOT owners for a given KNOT
    /// @param _memberId BLS public key of the KNOT
    function numberOfCollateralisedSlotOwnersForKnot(bytes calldata _memberId) external view returns (uint256) {
        return collateralisedSLOTOwners[_memberId].length;
    }

    /// @notice Fetch a collateralised SLOT owner address for a specific KNOT at a specific index
    function getCollateralisedOwnerAtIndex(bytes calldata _memberId, uint256 _index) external view returns (address) {
        return collateralisedSLOTOwners[_memberId][_index];
    }

    /// @dev Increases the collateralised SLOT balance owned by an account under a given KNOT
    /// @dev This can happen when the KNOT is added to a StakeHouse and also when SLOT is bought after slashing events
    function _increaseCollateralisedBalance(address _stakeHouse, address _user, bytes memory _memberId, uint256 _amount) internal {
        // Maintain a list of historical collateralised SLOT owners
        if (!isCollateralisedOwner[_memberId][_user]) {
            collateralisedSLOTOwners[_memberId].push(_user);
            isCollateralisedOwner[_memberId][_user] = true;
            emit CollateralisedOwnerAddedToKnot(_memberId, _user);
        }

        // Increase the total amount of collateralised SLOT owned by an account across all KNOTs in a given stake house
        totalUserCollateralisedSLOTBalanceInHouse[_stakeHouse][_user] += _amount;

        // Increase the total sETH owned by the account for the given KNOT
        totalUserCollateralisedSLOTBalanceForKnot[_stakeHouse][_user][_memberId] += _amount;
    }

    /// @dev Decrease the collateralised SLOT balance owned by an account under a given KNOT
    /// @dev This can happen under slashing or rage quit
    function _decreaseCollateralisedBalance(address _stakeHouse, address _user, bytes memory _memberId, uint256 _amount) internal {
        totalUserCollateralisedSLOTBalanceInHouse[_stakeHouse][_user] -= _amount;
        totalUserCollateralisedSLOTBalanceForKnot[_stakeHouse][_user][_memberId] -= _amount;
    }

    /// @dev Once a rage quit has burnt all of a user's derivatives, this sets a flag that will authorise this account, for the specified KNOT to withdraw ETH
    /// @dev This method takes care of reducing balances as the associated tokens have been burnt
    function _enableUserForKnotWithdrawal(address _user, bytes memory _memberId) internal {
        require(!isUserEnabledForKnotWithdrawal[_user][_memberId], "User already enabled for withdrawal");

        isUserEnabledForKnotWithdrawal[_user][_memberId] = true;

        emit UserEnabledForWithdrawal(_user, _memberId);
    }

    /// @dev This method marks a KNOT as fully withdrawn due to the underlying ETH being unstaked
    function _markUserAsWithdrawn(address _user, bytes memory _memberId) internal {
        require(isUserEnabledForKnotWithdrawal[_user][_memberId], "Not enabled for withdrawal");
        require(!userWithdrawn[_user][_memberId], "User already withdrawn");

        userWithdrawn[_user][_memberId] = true;

        emit UserWithdrawn(_user, _memberId);
    }
}

pragma solidity 0.8.13;

// SPDX-License-Identifier: BUSL-1.1

interface ISlotSettlementRegistry {
    /// @notice sETH token deployed for new Stakehouse
    event StakeHouseShareTokenCreated(address indexed stakeHouse);

    /// @notice Collateralised SLOT deducted from a collateralised SLOT owner
    event SlotSlashed(bytes memberId, uint256 amount);

    /// @notice Collateralised SLOT purchased from KNOT
    event SlashedSlotPurchased(bytes memberId, uint256 amount);

    /// @notice KNOT has exited the protocol exercising their redemption rights
    event RageQuitKnot(bytes memberId);

    /// @notice Function to report a slashing event (balance reduction in this case) and buy the slashed SLOT at the same time
    /// @dev Only core module and a StakeHouse that's been deployed by the universe
    /// @param _stakeHouse registry address
    /// @param _memberId ID of the member in the StakeHouse
    /// @param _slasher Recipient of the new collateralised SLOT being purhased
    /// @param _slashAmount Amount of collateralised SLOT being slashed
    /// @param _buyAmount Amount of collatearlised SLOT being purchased
    /// @param _isKickRequired Whether the KNOT needs to be kicked from the protocol due to misbehaving on the beacon chain
    function slashAndBuySlot(
        address _stakeHouse,
        bytes calldata _memberId,
        address _slasher,
        uint256 _slashAmount,
        uint256 _buyAmount,
        bool _isKickRequired
    ) external;

    /// @notice Slashes a KNOT (due to balance reduction and or beacon chain cheating) in a StakeHouse up to a given amount before auto-kicking member
    /// @dev Only core module and a StakeHouse that's been deployed by the universe
    /// @param _stakeHouse registry address
    /// @param _memberId ID of the member in the StakeHouse
    /// @param _amount Amount of SLOT being slashed
    /// @param _isKickRequired Whether the KNOT needs to be kicked for severe cheating (double proposal and voting or surround voting)
    function slash(
        address _stakeHouse,
        bytes calldata _memberId,
        uint256 _amount,
        bool _isKickRequired
    ) external;

    /// @notice For a given KNOT that has been slashed in a StakeHouse, this allows the SLOT to be purchased
    /// @dev Only StakeHouse that's been deployed by the universe
    /// @param _stakeHouse Address of the registry
    /// @param _memberId ID of the slashed member of the StakeHouse
    /// @param _amount Amount of SLOT being purchased (which will dictate shares received)
    /// @param _recipient Recipient of the sETH shares that will be backed by the SLOT purchased
    function buySlashedSlot(
        address _stakeHouse,
        bytes calldata _memberId,
        uint256 _amount,
        address _recipient
    ) external;

    /// @dev Get the sum of total collateralized SLOT balances for multiple sETH tokens for specific address
    /// @param _sETHList - List of sETH token addresses
    /// @param _owner - Address whose balance is summed over
    function getCollateralizedSlotAccumulation(address[] calldata _sETHList, address _owner) external view returns (uint256);

    /// @notice Total amount of SLOT that has been slashed but not purchased
    /// @param _memberId BLS public key of KNOT
    function currentSlashedAmountForKnot(bytes calldata _memberId) external view returns (uint256 currentSlashedAmount);

    /// @notice Total amount of collateralised sETH owned by an account for a given KNOT
    /// @param _stakeHouse Address of Stakehouse registry contract
    /// @param _user Collateralised SLOT owner address
    /// @param _memberId BLS pub key of the validator
    function totalUserCollateralisedSETHBalanceForKnot(
        address _stakeHouse,
        address _user,
        bytes calldata _memberId
    ) external view returns (uint256);

    /// @notice Total collateralised sETH owned by a user across all KNOTs in the house
    /// @param _stakeHouse Address of the Stakehouse registry
    /// @param _user Collateralised SLOT owner in house
    function totalUserCollateralisedSETHBalanceInHouse(
        address _stakeHouse,
        address _user
    ) external view returns (uint256);

    /// @notice Based on full health of the collateralised SLOT, the collateralised sETH for the house
    /// @param _stakeHouse Address of the Stakehouse registry in order to fetch its exchange rate
    function totalCollateralisedSETHForStakehouse(
        address _stakeHouse
    ) external view returns (uint256);

    /// @notice Total sETH threshold need to be met in order to rage quit. User must have more or same sETH than this at the house level
    function sETHRedemptionThreshold(address _stakeHouse) external view returns (uint256);

    /// @notice Given the total SLOT in the house (8 * number of KNOTs), how much is in circulation when filtering out total slashed
    /// @param _stakeHouse Address of the Stakehouse registry
    function circulatingSlot(
        address _stakeHouse
    ) external view returns (uint256);

    /// @notice Given the total amount of collateralised SLOT in the house (4 * number of KNOTs), how much is in circulation when filtering out total slashed
    /// @param _stakeHouse Address of the Stakehouse registry
    function circulatingCollateralisedSlot(
        address _stakeHouse
    ) external view returns (uint256);

    /// @notice Amount of sETH required per SLOT in order to rage quit
    /// @param _stakeHouse Address of the Stakehouse registry in order to fetch its exchange rate
    function redemptionRate(address _stakeHouse) external view returns (uint256);

    /// @notice Amount of sETH per SLOT for a given house calculated as total dETH minted in house / total SLOT from all KNOTs
    /// @param _stakeHouse Address of the Stakehouse registry in order to fetch its exchange rate
    function exchangeRate(address _stakeHouse) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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
// OpenZeppelin Contracts v4.4.1 (proxy/Proxy.sol)

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
     * This function does not return to its internall call site, it will return directly to the external caller.
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
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
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
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
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
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlot.BooleanSlot storage rollbackTesting = StorageSlot.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            Address.functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
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
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

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
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

interface StakeHouseAccessControls {
    function isCoreModuleLocked(address _module) external view returns (bool);
    function isProxyAdmin(address _module) external view returns (bool);
    function isCoreModule(address _module) external view returns (bool);
}

pragma solidity 0.8.13;

// SPDX-License-Identifier: BUSL-1.1

interface ISavETHRegistry {
    /// @notice KNOT transferred from one index to another
    event KnotTransferredToAnotherIndex(bytes memberId, uint256 indexed newIndexId);

    /// @notice Account approved to move KNOT from one index to another
    event ApprovedSpenderForKnotInIndex(bytes memberId, address indexed spender);

    /// @notice KNOT moved from index into open index
    event KnotAddedToOpenIndex(bytes memberId, address indexed indexOwner, uint256 savETHSent);

    /// @notice KNOT moved from index into open index to withdraw dETH immediately
    event KnotAddedToOpenIndexAndDETHWithdrawn(bytes memberId);

    /// @notice dETH inflation rewards minted to KNOT part of index
    event dETHAddedToKnotInIndex(bytes memberId, uint256 dETH);

    /// @notice dETH withdrawn
    event dETHWithdrawnFromOpenIndex(uint256 amount);

    /// @notice dETH inflation rewards minted to know part of open index
    event dETHReservesAddedToOpenIndex(bytes memberId, uint256 amount);

    /// @notice KNOT has exercised redemption rights
    event RageQuitKnot(bytes memberId);

    /// @notice dETH brought back to registry
    event dETHDepositedIntoRegistry(address indexed depositor, uint256 amount);

    /// @notice KNOT added to index
    event KnotInsertedIntoIndex(bytes memberId, uint256 indexed indexId);

    /// @notice New index created
    event IndexCreated(uint256 indexed indexId);

    /// @notice Ownership of index given to new address
    event IndexOwnershipTransferred(uint256 indexId);

    /// @notice Account authorised to transfer ownership of index
    event ApprovedSpenderForIndexTransfer(uint256 indexed indexId, address indexed spender);

    /// @notice Allow an owner of an index to approve another account to transfer ownership (like a marketplace)
    /// @param _indexId ID of the index being approved
    /// @param _owner of the index
    /// @param _spender Authorised spender or zero address to clear approval
    function approveForIndexOwnershipTransfer(
        uint256 _indexId,
        address _owner,
        address _spender
    ) external;

    /// @notice Transfer ownership of the entire sub-index of KNOTs from one ETH account to another so long as the new owner does not already own an index
    /// @param _indexId ID of the index receiving a new owner
    /// @param _currentOwnerOrSpender Account initiating the index transfer which must either be the index owner or approved spender
    /// @param _newOwner New account receiving ownership of the index and all sub KNOTs
    function transferIndexOwnership(
        uint256 _indexId,
        address _currentOwnerOrSpender,
        address _newOwner
    ) external;

    /// @notice Allows an index owner or approved KNOT spender to transfer ownership of a KNOT from one index to another
    /// @param _stakeHouse Registry that the KNOT is part of
    /// @param _memberId of the KNOT
    /// @param _indexOwnerOrSpender Account initiating the transfer which is either index owner or spender of the KNOT
    /// @param _newIndexId ID of the index receiving the KNOT
    function transferKnotToAnotherIndex(
        address _stakeHouse,
        bytes calldata _memberId,
        address _indexOwnerOrSpender,
        uint256 _newIndexId
    ) external;

    /// @notice Allows an index owner to approve a marketplace to transfer a knot to another index
    /// @param _stakeHouse Registry that the KNOT is part of
    /// @param _memberId of the KNOT
    /// @param _indexOwner Address of the index owner who is the only account allowed to do this operation
    /// @param _spender Account that is auth to do the transfer. Set to address(0) to reset the allowance
    function approveSpendingOfKnotInIndex(
        address _stakeHouse,
        bytes calldata _memberId,
        address _indexOwner,
        address _spender
    ) external;

    /// @notice Bring a KNOT that is part of an index into the open index in order to get access to the savETH <> dETH
    /// @param _stakeHouse Registry that the KNOT is part of
    /// @param _memberId of the KNOT
    /// @param _owner Address of the index owner
    /// @param _recipient Address that will receive savETH
    function addKnotToOpenIndex(
        address _stakeHouse,
        bytes calldata _memberId,
        address _owner,
        address _recipient
    ) external;

    /// @notice Given a KNOT that is part of the open index, allow a savETH holder to isolate the KNOT from the index gaining exclusive rights to the network staking rewards
    /// @param _stakeHouse Address of StakeHouse that the KNOT belongs to
    /// @param _memberId KNOT ID within the StakeHouse
    /// @param _savETHOwner Caller that has the savETH funds required for isolation
    /// @param _indexId ID of the index receiving the isolated funds
    function isolateKnotFromOpenIndex(
        address _stakeHouse,
        bytes calldata _memberId,
        address _savETHOwner,
        uint256 _indexId
    ) external;

    /// @notice In a single transaction, add knot to open index and withdraw dETH in registry
    /// @param _stakeHouse Address of StakeHouse that the KNOT belongs to
    /// @param _memberId KNOT ID that belongs to an index
    /// @param _indexOwner Owner of the index
    /// @param _recipient Recipient of dETH tokens
    function addKnotToOpenIndexAndWithdraw(
        address _stakeHouse,
        bytes calldata _memberId,
        address _indexOwner,
        address _recipient
    ) external;

    /// @notice In a single transaction, deposit dETH and isolate a knot into an index
    /// @param _stakeHouse Address of StakeHouse that the KNOT belongs to
    /// @param _memberId KNOT ID that requires adding to an index
    /// @param _dETHOwner Address that owns dETH required for isolation
    /// @param _indexId ID of the index that the KNOT is being added into
    function depositAndIsolateKnotIntoIndex(
        address _stakeHouse,
        bytes calldata _memberId,
        address _dETHOwner,
        uint256 _indexId
    ) external;

    /// @notice Allows a SaveETH holder to exchange some or all of their SaveETH for dETH
    /// @param _savETHOwner Address of the savETH owner withdrawing dETH from registry
    /// @param _recipient Recipient of the dETH which can be user burning their savETH tokens or anyone else
    /// @param _amount of SaveETH to burn
    function withdraw(address _savETHOwner, address _recipient, uint128 _amount) external;

    /// @notice Deposit dETH in exchange for SaveETH
    /// @param _dETHOwner Address of the dETH owner depositing dETH into the registry
    /// @param _savETHRecipient Recipient of the savETH which can be anyone
    /// @param _amount of dETH being deposited
    function deposit(address _dETHOwner, address _savETHRecipient,  uint128 _amount) external;

    /// @notice For a given savETH registry is equal to ( 24 * active knots ) + all rewards reported to the savETH registry
    function totalDETHMintedWithinHouse(address _house) external view returns (uint256);

    /// @dev Core module clean up of rage quit - KNOT no longer wishes to be part of the protocol
    function rageQuitKnot(address _stakeHouse, bytes calldata _blsPubKey, address _savETHIndexOwner) external;
}

pragma solidity 0.8.13;

// SPDX-License-Identifier: BUSL-1.1

/// @notice Required interface for gate keeping whether a member is allowed in a Stakehouse registry, brand or anything else for that matter
interface IGateKeeper {
    /// @notice Called by the Stakehouse registry or Brand Central before adding a member to a house or brand
    /// @param _blsPubKey BLS public key of the KNOT being added to the Stakehouse registry or brand
    function isMemberPermitted(bytes calldata _blsPubKey) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

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
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
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
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
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
        _upgradeToAndCallSecure(newImplementation, data, true);
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
    uint256[50] private __gap;
}

pragma solidity 0.8.13;

// SPDX-License-Identifier: BUSL-1.1

import { IMembershipRegistry } from "./IMembershipRegistry.sol";
import { BaseModuleGuards } from "./BaseModuleGuards.sol";

/// @dev Contract guards that helps restrict the access to Core Modules
abstract contract ModuleGuards is BaseModuleGuards {

    /// @dev Validate that a KNOT is an active member of a StakeHouse
    /// @dev To save GAS, proxy through to an internal function to save the code being copied in many places and bloating contracts
    modifier onlyValidStakeHouseKnot(address _stakeHouse, bytes calldata _blsPubKey) {
        _onlyValidStakeHouseKnot(_stakeHouse, _blsPubKey);
        _;
    }

    /// @dev Validate that a KNOT is associated with a given Stakehouse and has not rage quit (ignoring any kicking)
    modifier onlyKnotThatHasNotRageQuit(address _stakeHouse, bytes calldata _blsPubKey) {
        _onlyStakeHouseKnotThatHasNotRageQuit(_stakeHouse, _blsPubKey);
        _;
    }

    function _onlyStakeHouseKnotThatHasNotRageQuit(address _stakeHouse, bytes calldata _blsPubKey) internal view virtual {
        require(!IMembershipRegistry(_stakeHouse).hasMemberRageQuit(_blsPubKey), "Rage Quit");
    }

    function _onlyValidStakeHouseKnot(address _stakeHouse, bytes calldata _blsPubKey) internal view virtual {
        require(IMembershipRegistry(_stakeHouse).isActiveMember(_blsPubKey), "Invalid knot");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
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
        __ERC1967Upgrade_init_unchained();
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
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
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
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

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
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

pragma solidity 0.8.13;

// SPDX-License-Identifier: BUSL-1.1

import { StakeHouseUniverse } from "./StakeHouseUniverse.sol";

/// @dev Contract guards that helps restrict the access to Core Modules
abstract contract BaseModuleGuards {

    /// @notice Address of the smart contract containing source of truth for all deployed contracts
    StakeHouseUniverse public universe;

    /// @dev Only allow registered core modules of the StakeHouse protocol to make a function call
    /// @dev To save GAS, proxy through to an internal function to save the code being copied in many places and bloating contracts
    modifier onlyModule() {
        _onlyModule();
        _;
    }

    /// @dev Only allow StakeHouse that has been deployed by the StakeHouse universe smart contract (there is no other source of truth)
    /// @dev To save GAS, proxy through to an internal function to save the code being copied in many places and bloating contracts
    modifier onlyValidStakeHouse(address _stakeHouse) {
        _onlyValidStakeHouse(_stakeHouse);
        _;
    }

    function _onlyModule() internal view virtual {
        // Ensure the sender is a core module in the StakeHouse universe
        require(
            universe.accessControls().isCoreModule(msg.sender),
            "Only core"
        );
    }

    function _onlyValidStakeHouse(address _stakeHouse) internal view virtual {
        // Ensure we are interacting with a legitimate StakeHouse from the universe
        require(
            universe.stakeHouseToKNOTIndex(_stakeHouse) > 0,
            "Invalid StakeHouse"
        );
    }

    /// @dev Init the module guards by supplying the address of the valid StakeHouse universe contract
    function __initModuleGuards(StakeHouseUniverse _universe) internal {
        require(address(_universe) != address(0), "Init Err");
        universe = _universe;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./draft-IERC20PermitUpgradeable.sol";
import "../ERC20Upgradeable.sol";
import "../../../utils/cryptography/draft-EIP712Upgradeable.sol";
import "../../../utils/cryptography/ECDSAUpgradeable.sol";
import "../../../utils/CountersUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

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
abstract contract ERC20PermitUpgradeable is Initializable, ERC20Upgradeable, IERC20PermitUpgradeable, EIP712Upgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    mapping(address => CountersUpgradeable.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    function __ERC20Permit_init(string memory name) internal onlyInitializing {
        __Context_init_unchained();
        __EIP712_init_unchained(name, "1");
        __ERC20Permit_init_unchained(name);
    }

    function __ERC20Permit_init_unchained(string memory name) internal onlyInitializing {
        _PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");}

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

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSAUpgradeable.recover(hash, v, r, s);
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
        CountersUpgradeable.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
    uint256[49] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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
        __Context_init_unchained();
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
    uint256[45] private __gap;
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
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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