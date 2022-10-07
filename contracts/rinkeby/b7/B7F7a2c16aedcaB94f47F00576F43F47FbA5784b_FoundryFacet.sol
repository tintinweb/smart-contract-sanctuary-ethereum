// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import {IFoundryFacet} from "../interfaces/IFoundryFacet.sol";
import {LibMeToken, MeTokenInfo} from "../libs/LibMeToken.sol";
import {LibMeta} from "../libs/LibMeta.sol";
import {Modifiers} from "../libs/LibAppStorage.sol";
import {LibFoundry} from "../libs/LibFoundry.sol";
import {LibHub, HubInfo} from "../libs/LibHub.sol";
import {IVault} from "../interfaces/IVault.sol";

/// @title meTokens Foundry Facet
/// @author @cartercarlson, @parv3213
/// @notice This contract manages all minting / burning for meTokens Protocol
contract FoundryFacet is IFoundryFacet, Modifiers {
    /// @inheritdoc IFoundryFacet
    function mint(
        address meToken,
        uint256 assetsDeposited,
        address recipient
    ) external override returns (uint256 meTokensMinted) {
        meTokensMinted = LibFoundry.mint(meToken, assetsDeposited, recipient);
    }

    /// @inheritdoc IFoundryFacet
    function mintWithPermit(
        address meToken,
        uint256 assetsDeposited,
        address recipient,
        uint256 deadline,
        uint8 vSig,
        bytes32 rSig,
        bytes32 sSig
    ) external override returns (uint256 meTokensMinted) {
        meTokensMinted = LibFoundry.mintWithPermit(
            meToken,
            assetsDeposited,
            recipient,
            deadline,
            vSig,
            rSig,
            sSig
        );
    }

    /// @inheritdoc IFoundryFacet
    function burn(
        address meToken,
        uint256 meTokensBurned,
        address recipient
    ) external override returns (uint256 assetsReturned) {
        assetsReturned = LibFoundry.burn(meToken, meTokensBurned, recipient);
    }

    /// @inheritdoc IFoundryFacet
    function donate(address meToken, uint256 assetsDeposited)
        external
        override
    {
        address sender = LibMeta.msgSender();
        MeTokenInfo memory meTokenInfo = s.meTokens[meToken];
        HubInfo memory hubInfo = s.hubs[meTokenInfo.hubId];
        require(meTokenInfo.migration == address(0), "meToken resubscribing");

        IVault vault = IVault(hubInfo.vault);
        address asset = hubInfo.asset;

        vault.handleDeposit(sender, asset, assetsDeposited, 0);

        LibMeToken.updateBalanceLocked(true, meToken, assetsDeposited);

        emit Donate(meToken, asset, sender, assetsDeposited);
    }

    /// @inheritdoc IFoundryFacet
    function calculateMeTokensMinted(address meToken, uint256 assetsDeposited)
        external
        view
        override
        returns (uint256 meTokensMinted)
    {
        meTokensMinted = LibFoundry.calculateMeTokensMinted(
            meToken,
            assetsDeposited
        );
    }

    /// @inheritdoc IFoundryFacet
    function calculateAssetsReturned(
        address meToken,
        uint256 meTokensBurned,
        address sender
    ) external view override returns (uint256 assetsReturned) {
        uint256 rawAssetsReturned = LibFoundry.calculateRawAssetsReturned(
            meToken,
            meTokensBurned
        );
        if (sender == address(0)) sender = LibMeta.msgSender();
        assetsReturned = LibFoundry.calculateActualAssetsReturned(
            sender,
            meToken,
            meTokensBurned,
            rawAssetsReturned
        );
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

/// @title meTokens Protocol Foundry Facet interface
/// @author Carter Carlson (@cartercarlson), Parv Garg (@parv3213)
interface IFoundryFacet {
    /// @notice Event of minting a meToken
    /// @param meToken         Address of meToken minted
    /// @param asset           Address of asset deposited
    /// @param depositor       Address to deposit asset
    /// @param recipient       Address to receive minted meTokens
    /// @param assetsDeposited Amount of assets deposited
    /// @param meTokensMinted  Amount of meTokens minted
    event Mint(
        address meToken,
        address asset,
        address depositor,
        address recipient,
        uint256 assetsDeposited,
        uint256 meTokensMinted
    );

    /// @notice Event of burning a meToken
    /// @param meToken         Address of meToken burned
    /// @param asset           Address of asset returned
    /// @param burner          Address to burn meTokens
    /// @param recipient       Address to receive underlying asset
    /// @param meTokensBurned  Amount of meTokens to burn
    /// @param assetsReturned  Amount of assets
    event Burn(
        address meToken,
        address asset,
        address burner,
        address recipient,
        uint256 meTokensBurned,
        uint256 assetsReturned
    );

    /// @notice Event of donating to meToken owner
    /// @param meToken         Address of meToken burned
    /// @param asset           Address of asset returned
    /// @param donor           Address donating the asset
    /// @param assetsDeposited Amount of asset to donate
    event Donate(
        address meToken,
        address asset,
        address donor,
        uint256 assetsDeposited
    );

    /// @notice Mint a meToken by depositing the underlying asset
    /// @param meToken          Address of meToken to mint
    /// @param assetsDeposited  Amount of assets to deposit
    /// @param recipient        Address to receive minted meTokens
    /// @return meTokensMinted  Amount of meTokens minted
    function mint(
        address meToken,
        uint256 assetsDeposited,
        address recipient
    ) external returns (uint256 meTokensMinted);

    /// @notice Mint a meToken by depositing a EIP compliant asset
    /// @param meToken          Address of meToken to mint
    /// @param assetsDeposited  Amount of assets to deposit
    /// @param recipient        Address to receive minted meTokens
    /// @param deadline         The time at which this expires (unix time)
    /// @param v                v of the signature
    /// @param r                r of the signature
    /// @param s                s of the signature
    /// @return meTokensMinted  Amount of meTokens minted
    function mintWithPermit(
        address meToken,
        uint256 assetsDeposited,
        address recipient,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 meTokensMinted);

    /// @notice Burn a meToken to receive the underlying asset
    /// @param meToken          Address of meToken to burn
    /// @param meTokensBurned   Amount of meTokens to burn
    /// @param recipient        Address to receive the underlying assets
    /// @return assetsReturned  Amount of assets returned
    function burn(
        address meToken,
        uint256 meTokensBurned,
        address recipient
    ) external returns (uint256 assetsReturned);

    /// @notice Donate a meToken's underlying asset to its owner
    /// @param meToken          Address of meToken to donate
    /// @param assetsDeposited  Amount of asset to donate
    function donate(address meToken, uint256 assetsDeposited) external;

    /// @notice Calculate meTokens minted based on assets deposited
    /// @param meToken          Address of meToken to mint
    /// @param assetsDeposited  Amount of assets to deposit
    /// @return meTokensMinted  Amount of meTokens to be minted
    function calculateMeTokensMinted(address meToken, uint256 assetsDeposited)
        external
        view
        returns (uint256 meTokensMinted);

    /// @notice Calculate assets returned based on meTokens burned
    /// @param meToken          Address of meToken to burn
    /// @param meTokensBurned   Amount of meTokens to burn
    /// @param sender           Address to burn the meTokens
    /// @return assetsReturned  Amount of assets to be returned to sender
    function calculateAssetsReturned(
        address meToken,
        uint256 meTokensBurned,
        address sender
    ) external view returns (uint256 assetsReturned);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {LibAppStorage, AppStorage} from "./LibAppStorage.sol";
import {IMigration} from "../interfaces/IMigration.sol";
import {IMeToken} from "../interfaces/IMeToken.sol";
import {IMeTokenFactory} from "../interfaces/IMeTokenFactory.sol";
import {LibCurve} from "./LibCurve.sol";

struct MeTokenInfo {
    address owner;
    uint256 hubId;
    uint256 balancePooled;
    uint256 balanceLocked;
    uint256 startTime;
    uint256 endTime;
    uint256 targetHubId;
    address migration;
}

library LibMeToken {
    /// @dev reference IMeTokenRegistryFacet
    event UpdateBalancePooled(bool add, address meToken, uint256 amount);
    event UpdateBalanceLocked(bool add, address meToken, uint256 amount);
    event Subscribe(
        address indexed meToken,
        address indexed owner,
        uint256 minted,
        address asset,
        uint256 assetsDeposited,
        string name,
        string symbol,
        uint256 hubId
    );
    event FinishResubscribe(address indexed meToken);

    function subscribe(
        address sender,
        string calldata name,
        string calldata symbol,
        uint256 hubId,
        uint256 assetsDeposited
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        // Create meToken erc20 contract
        address meTokenAddr = IMeTokenFactory(s.meTokenFactory).create(
            name,
            symbol,
            address(this)
        );

        // Register the address which created a meToken
        s.meTokenOwners[sender] = meTokenAddr;

        // Add meToken to registry
        s.meTokens[meTokenAddr].owner = sender;
        s.meTokens[meTokenAddr].hubId = hubId;
        s.meTokens[meTokenAddr].balancePooled = assetsDeposited;

        // Mint meToken to user
        uint256 meTokensMinted;
        if (assetsDeposited > 0) {
            meTokensMinted = LibCurve.viewMeTokensMinted(
                assetsDeposited, // deposit_amount
                hubId, // hubId
                0, // supply
                0 // balancePooled
            );
            IMeToken(meTokenAddr).mint(sender, meTokensMinted);
        }

        emit Subscribe(
            meTokenAddr,
            sender,
            meTokensMinted,
            s.hubs[hubId].asset,
            assetsDeposited,
            name,
            symbol,
            hubId
        );
    }

    /// @notice Update a meToken's balancePooled
    /// @param add     Boolean that is true if adding to balance, false if subtracting
    /// @param meToken Address of meToken
    /// @param amount  Amount to add/subtract
    function updateBalancePooled(
        bool add,
        address meToken,
        uint256 amount
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        if (add) {
            s.meTokens[meToken].balancePooled += amount;
        } else {
            s.meTokens[meToken].balancePooled -= amount;
        }

        emit UpdateBalancePooled(add, meToken, amount);
    }

    /// @notice Update a meToken's balanceLocked
    /// @param add     Boolean that is true if adding to balance, false if subtracting
    /// @param meToken Address of meToken
    /// @param amount  Amount to add/subtract
    function updateBalanceLocked(
        bool add,
        address meToken,
        uint256 amount
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        if (add) {
            s.meTokens[meToken].balanceLocked += amount;
        } else {
            s.meTokens[meToken].balanceLocked -= amount;
        }

        emit UpdateBalanceLocked(add, meToken, amount);
    }

    function finishResubscribe(address meToken)
        internal
        returns (MeTokenInfo memory)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        MeTokenInfo storage meTokenInfo = s.meTokens[meToken];

        require(meTokenInfo.targetHubId != 0, "No targetHubId");
        require(
            block.timestamp > meTokenInfo.endTime,
            "block.timestamp < endTime"
        );

        IMigration(meTokenInfo.migration).finishMigration(meToken);

        // Finish updating metoken info
        meTokenInfo.startTime = 0;
        meTokenInfo.endTime = 0;
        meTokenInfo.hubId = meTokenInfo.targetHubId;
        meTokenInfo.targetHubId = 0;
        meTokenInfo.migration = address(0);

        emit FinishResubscribe(meToken);
        return meTokenInfo;
    }

    function getMeTokenInfo(address token)
        internal
        view
        returns (MeTokenInfo memory meToken)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        meToken.owner = s.meTokens[token].owner;
        meToken.hubId = s.meTokens[token].hubId;
        meToken.balancePooled = s.meTokens[token].balancePooled;
        meToken.balanceLocked = s.meTokens[token].balanceLocked;
        meToken.startTime = s.meTokens[token].startTime;
        meToken.endTime = s.meTokens[token].endTime;
        meToken.targetHubId = s.meTokens[token].targetHubId;
        meToken.migration = s.meTokens[token].migration;
    }

    function warmup() internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.meTokenWarmup;
    }

    function duration() internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.meTokenDuration;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {LibAppStorage, AppStorage} from "./LibAppStorage.sol";

library LibMeta {
    bytes32 internal constant _EIP712_DOMAIN_TYPEHASH =
        keccak256(
            bytes(
                "EIP712Domain(string name,string version,uint256 salt,address verifyingContract)"
            )
        );

    function domainSeparator(string memory name, string memory version)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    _EIP712_DOMAIN_TYPEHASH,
                    keccak256(bytes(name)),
                    keccak256(bytes(version)),
                    getChainID(),
                    address(this)
                )
            );
    }

    function getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function msgSender() internal view returns (address sender) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (msg.sender == s.trustedForwarder) {
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IVaultRegistry} from "../interfaces/IVaultRegistry.sol";
import {IMigrationRegistry} from "../interfaces/IMigrationRegistry.sol";
import {HubInfo} from "./LibHub.sol";
import {MeTokenInfo} from "./LibMeToken.sol";
import {LibDiamond} from "./LibDiamond.sol";
import {LibMeta} from "./LibMeta.sol";

struct AppStorage {
    // Fees-specific
    uint256 mintFee;
    uint256 burnBuyerFee;
    uint256 burnOwnerFee;
    // Constants
    uint256 MAX_REFUND_RATIO;
    uint256 PRECISION;
    uint256 MAX_FEE;
    // MeTokenRegistry-specific
    uint256 meTokenWarmup;
    uint256 meTokenDuration;
    mapping(address => MeTokenInfo) meTokens;
    mapping(address => address) meTokenOwners;
    mapping(address => address) pendingMeTokenOwners;
    // Hub-specific
    uint256 hubWarmup;
    uint256 hubDuration;
    uint256 hubCooldown;
    uint256 hubCount;
    mapping(uint256 => HubInfo) hubs;
    // reentrancy guard
    uint256 NOT_ENTERED;
    uint256 ENTERED;
    uint256 reentrancyStatus;
    // Widely-used addresses/interfaces
    address diamond;
    address meTokenFactory;
    IVaultRegistry vaultRegistry;
    IMigrationRegistry migrationRegistry;
    // Controllers
    address diamondController;
    address trustedForwarder;
    address feesController;
    address durationsController;
    address registerController;
    address deactivateController;
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }

    function initControllers(address _firstController) internal {
        AppStorage storage s = diamondStorage();
        s.diamondController = _firstController;
        s.feesController = _firstController;
        s.durationsController = _firstController;
        s.registerController = _firstController;
        s.deactivateController = _firstController;
    }
}

contract Modifiers {
    AppStorage internal s;

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.

     * @dev Works identically to OZ's nonReentrant.
     * @dev Used to avoid state storage collision within diamond.
     */

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(
            s.reentrancyStatus != s.ENTERED,
            "ReentrancyGuard: reentrant call"
        );

        // Any calls to nonReentrant after this point will fail
        s.reentrancyStatus = s.ENTERED;
        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        s.reentrancyStatus = s.NOT_ENTERED;
    }

    modifier onlyDiamondController() {
        require(
            LibMeta.msgSender() == s.diamondController,
            "!diamondController"
        );
        _;
    }

    modifier onlyFeesController() {
        require(LibMeta.msgSender() == s.feesController, "!feesController");
        _;
    }

    modifier onlyDurationsController() {
        require(
            LibMeta.msgSender() == s.durationsController,
            "!durationsController"
        );
        _;
    }

    modifier onlyRegisterController() {
        require(
            LibMeta.msgSender() == s.registerController,
            "!registerController"
        );
        _;
    }

    modifier onlyDeactivateController() {
        require(
            LibMeta.msgSender() == s.deactivateController,
            "!deactivateController"
        );
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import {IVault} from "../interfaces/IVault.sol";
import {LibAppStorage, AppStorage} from "./LibAppStorage.sol";
import {IMeToken} from "../interfaces/IMeToken.sol";
import {LibMeToken, MeTokenInfo} from "../libs/LibMeToken.sol";
import {IMigration} from "../interfaces/IMigration.sol";
import {LibMeta} from "../libs/LibMeta.sol";
import {LibHub, HubInfo} from "../libs/LibHub.sol";
import {LibCurve} from "../libs/LibCurve.sol";
import {LibWeightedAverage} from "../libs/LibWeightedAverage.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library LibFoundry {
    event Mint(
        address meToken,
        address asset,
        address depositor,
        address recipient,
        uint256 assetsDeposited,
        uint256 meTokensMinted
    );

    event Burn(
        address meToken,
        address asset,
        address burner,
        address recipient,
        uint256 meTokensBurned,
        uint256 assetsReturned
    );

    // MINT FLOW CHART
    /****************************************************************************
    //                                                                         //
    //                                                 mint()                  //
    //                                                   |                     //
    //                                             CALCULATE MINT              //
    //                                                 /    \                  //
    // is hub updating or meToken migrating? -{      (Y)     (N)               //
    //                                               /         \               //
    //                                          CALCULATE       |              //
    //                                         TARGET MINT      |              //
    //                                             |            |              //
    //                                        TIME-WEIGHTED     |              //
    //                                           AVERAGE        |              //
    //                                               \         /               //
    //                                               MINT RETURN               //
    //                                                   |                     //
    //                                              .sub(fees)                 //
    //                                                                         //
    ****************************************************************************/
    function mint(
        address meToken,
        uint256 assetsDeposited,
        address recipient
    ) internal returns (uint256) {
        require(assetsDeposited > 0, "assetsDeposited==0");
        (address asset, address sender, uint256 meTokensMinted) = _handleMint(
            meToken,
            assetsDeposited
        );

        // Mint meToken to user
        IMeToken(meToken).mint(recipient, meTokensMinted);
        emit Mint(
            meToken,
            asset,
            sender,
            recipient,
            assetsDeposited,
            meTokensMinted
        );
        return meTokensMinted;
    }

    function mintWithPermit(
        address meToken,
        uint256 assetsDeposited,
        address recipient,
        uint256 deadline,
        uint8 vSig,
        bytes32 rSig,
        bytes32 sSig
    ) internal returns (uint256) {
        require(assetsDeposited > 0, "assetsDeposited==0");
        (
            address asset,
            uint256[2] memory amounts // 0-meTokensMinted 1-assetsDepositedAfterFees
        ) = _handleMintWithPermit(
                meToken,
                assetsDeposited,
                deadline,
                vSig,
                rSig,
                sSig
            );

        LibMeToken.updateBalancePooled(true, meToken, amounts[1]);
        // Mint meToken to user
        IMeToken(meToken).mint(recipient, amounts[0]);
        emit Mint(
            meToken,
            asset,
            LibMeta.msgSender(),
            recipient,
            assetsDeposited,
            amounts[0]
        );
        return amounts[0];
    }

    // BURN FLOW CHART
    /****************************************************************************
    //                                                                         //
    //                                                 burn()                  //
    //                                                   |                     //
    //                                             CALCULATE BURN              //
    //                                                /     \                  //
    // is hub updating or meToken migrating? -{     (Y)     (N)                //
    //                                              /         \                //
    //                                         CALCULATE       \               //
    //                                        TARGET BURN       \              //
    //                                           /               \             //
    //                                  TIME-WEIGHTED             \            //
    //                                     AVERAGE                 \           //
    //                                        |                     \          //
    //                              WEIGHTED BURN RETURN       BURN RETURN     //
    //                                     /     \               /    \        //
    // is msg.sender the -{              (N)     (Y)           (Y)    (N)      //
    // owner? (vs buyer)                 /         \           /        \      //
    //                                 GET           CALCULATE         GET     //
    //                            TIME-WEIGHTED    BALANCE LOCKED     REFUND   //
    //                            REFUND RATIO        RETURNED        RATIO    //
    //                                  |                |              |      //
    //                              .mul(wRR)        .add(BLR)      .mul(RR)   //
    //                                  \                |             /       //
    //                                     ACTUAL (WEIGHTED) BURN RETURN       //
    //                                                   |                     //
    //                                               .sub(fees)                //
    //                                                                         //
    ****************************************************************************/
    function burn(
        address meToken,
        uint256 meTokensBurned,
        address recipient
    ) internal returns (uint256) {
        require(meTokensBurned > 0, "meTokensBurned==0");
        AppStorage storage s = LibAppStorage.diamondStorage();
        address sender = LibMeta.msgSender();
        MeTokenInfo memory meTokenInfo = s.meTokens[meToken];
        HubInfo memory hubInfo = s.hubs[meTokenInfo.hubId];

        // Handling changes
        if (meTokenInfo.targetHubId != 0) {
            if (block.timestamp > meTokenInfo.endTime) {
                hubInfo = s.hubs[meTokenInfo.targetHubId];
                meTokenInfo = LibMeToken.finishResubscribe(meToken);
            } else if (block.timestamp > meTokenInfo.startTime) {
                // Handle migration actions if needed
                IMigration(meTokenInfo.migration).poke(meToken);
            }
        }
        if (hubInfo.updating && block.timestamp > hubInfo.endTime) {
            LibHub.finishUpdate(meTokenInfo.hubId);
        }
        // Calculate how many tokens are returned
        uint256 rawAssetsReturned = calculateRawAssetsReturned(
            meToken,
            meTokensBurned
        );
        uint256 assetsReturned = calculateActualAssetsReturned(
            sender,
            meToken,
            meTokensBurned,
            rawAssetsReturned
        );
        // Subtract tokens returned from balance pooled
        LibMeToken.updateBalancePooled(false, meToken, rawAssetsReturned);

        if (sender == meTokenInfo.owner) {
            // Is owner, subtract from balance locked
            LibMeToken.updateBalanceLocked(
                false,
                meToken,
                assetsReturned - rawAssetsReturned
            );
        } else {
            // Is buyer, add to balance locked using refund ratio
            LibMeToken.updateBalanceLocked(
                true,
                meToken,
                rawAssetsReturned - assetsReturned
            );
        }
        // Burn metoken from user
        IMeToken(meToken).burn(sender, meTokensBurned);

        _vaultWithdrawal(
            sender,
            recipient,
            meToken,
            meTokenInfo,
            hubInfo,
            meTokensBurned,
            assetsReturned
        );
        return assetsReturned;
    }

    function calculateMeTokensMinted(address meToken, uint256 assetsDeposited)
        internal
        view
        returns (uint256 meTokensMinted)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        MeTokenInfo memory meTokenInfo = s.meTokens[meToken];
        HubInfo memory hubInfo = s.hubs[meTokenInfo.hubId];
        // gas savings
        uint256 totalSupply = IERC20(meToken).totalSupply();
        // Calculate return assuming update/resubscribe is not happening
        meTokensMinted = LibCurve.viewMeTokensMinted(
            assetsDeposited,
            meTokenInfo.hubId,
            totalSupply,
            meTokenInfo.balancePooled
        );

        if (meTokenInfo.targetHubId != 0) {
            // Calculate return for a resubscribing meToken
            uint256 targetMeTokensMinted = LibCurve.viewMeTokensMinted(
                assetsDeposited,
                meTokenInfo.targetHubId,
                totalSupply,
                meTokenInfo.balancePooled
            );
            meTokensMinted = LibWeightedAverage.calculate(
                meTokensMinted,
                targetMeTokensMinted,
                meTokenInfo.startTime,
                meTokenInfo.endTime
            );
        } else if (hubInfo.reconfigure) {
            // Calculate return for a hub which is updating its' curveInfo
            uint256 targetMeTokensMinted = LibCurve.viewTargetMeTokensMinted(
                assetsDeposited,
                meTokenInfo.hubId,
                totalSupply,
                meTokenInfo.balancePooled
            );
            meTokensMinted = LibWeightedAverage.calculate(
                meTokensMinted,
                targetMeTokensMinted,
                hubInfo.startTime,
                hubInfo.endTime
            );
        }
    }

    function calculateRawAssetsReturned(address meToken, uint256 meTokensBurned)
        internal
        view
        returns (uint256 rawAssetsReturned)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        MeTokenInfo memory meTokenInfo = s.meTokens[meToken];
        HubInfo memory hubInfo = s.hubs[meTokenInfo.hubId];

        uint256 totalSupply = IERC20(meToken).totalSupply(); // gas savings

        // Calculate return assuming update is not happening
        rawAssetsReturned = LibCurve.viewAssetsReturned(
            meTokensBurned,
            meTokenInfo.hubId,
            totalSupply,
            meTokenInfo.balancePooled
        );

        if (meTokenInfo.targetHubId != 0) {
            // Calculate return for a resubscribing meToken
            uint256 targetAssetsReturned = LibCurve.viewAssetsReturned(
                meTokensBurned,
                meTokenInfo.targetHubId,
                totalSupply,
                meTokenInfo.balancePooled
            );
            rawAssetsReturned = LibWeightedAverage.calculate(
                rawAssetsReturned,
                targetAssetsReturned,
                meTokenInfo.startTime,
                meTokenInfo.endTime
            );
        } else if (hubInfo.reconfigure) {
            // Calculate return for a hub which is updating its' curveInfo
            uint256 targetAssetsReturned = LibCurve.viewTargetAssetsReturned(
                meTokensBurned,
                meTokenInfo.hubId,
                totalSupply,
                meTokenInfo.balancePooled
            );
            rawAssetsReturned = LibWeightedAverage.calculate(
                rawAssetsReturned,
                targetAssetsReturned,
                hubInfo.startTime,
                hubInfo.endTime
            );
        }
    }

    /// @dev applies refundRatio
    function calculateActualAssetsReturned(
        address sender,
        address meToken,
        uint256 meTokensBurned,
        uint256 rawAssetsReturned
    ) internal view returns (uint256 actualAssetsReturned) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        MeTokenInfo memory meTokenInfo = s.meTokens[meToken];
        HubInfo memory hubInfo = s.hubs[meTokenInfo.hubId];
        // If msg.sender == owner, give owner the sell rate. - all of tokens returned plus a %
        //      of balancePooled based on how much % of supply will be burned
        // If msg.sender != owner, give msg.sender the burn rate
        if (sender == meTokenInfo.owner) {
            actualAssetsReturned =
                rawAssetsReturned +
                (((s.PRECISION * meTokensBurned) /
                    IERC20(meToken).totalSupply()) *
                    meTokenInfo.balanceLocked) /
                s.PRECISION;
        } else {
            if (
                hubInfo.targetRefundRatio == 0 && meTokenInfo.targetHubId == 0
            ) {
                // Not updating targetRefundRatio or resubscribing
                actualAssetsReturned =
                    (rawAssetsReturned * hubInfo.refundRatio) /
                    s.MAX_REFUND_RATIO;
            } else {
                if (meTokenInfo.targetHubId != 0) {
                    // meToken is resubscribing
                    actualAssetsReturned =
                        (rawAssetsReturned *
                            LibWeightedAverage.calculate(
                                hubInfo.refundRatio,
                                s.hubs[meTokenInfo.targetHubId].refundRatio,
                                meTokenInfo.startTime,
                                meTokenInfo.endTime
                            )) /
                        s.MAX_REFUND_RATIO;
                } else {
                    // Hub is updating
                    actualAssetsReturned =
                        (rawAssetsReturned *
                            LibWeightedAverage.calculate(
                                hubInfo.refundRatio,
                                hubInfo.targetRefundRatio,
                                hubInfo.startTime,
                                hubInfo.endTime
                            )) /
                        s.MAX_REFUND_RATIO;
                }
            }
        }
    }

    function _handleMint(address meToken, uint256 assetsDeposited)
        private
        returns (
            address,
            address,
            uint256
        )
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        // 0-meTokensMinted 1-fee 2-assetsDepositedAfterFees
        address sender = LibMeta.msgSender();
        MeTokenInfo memory meTokenInfo = s.meTokens[meToken];
        HubInfo memory hubInfo = s.hubs[meTokenInfo.hubId];
        uint256[3] memory amounts;
        amounts[1] = (assetsDeposited * s.mintFee) / s.PRECISION; // fee
        amounts[2] = assetsDeposited - amounts[1]; //assetsDepositedAfterFees

        amounts[0] = calculateMeTokensMinted(meToken, amounts[2]); // meTokensMinted
        IVault vault = IVault(hubInfo.vault);
        address asset = hubInfo.asset;

        // Check if meToken is using a migration vault and in the active stage of resubscribing.
        // Sometimes a meToken may be resubscribing to a hub w/ the same asset,
        // in which case a migration vault isn't needed
        if (
            meTokenInfo.migration != address(0) &&
            block.timestamp > meTokenInfo.startTime &&
            IMigration(meTokenInfo.migration).isStarted(meToken)
        ) {
            // Use meToken address to get the asset address from the migration vault
            vault = IVault(meTokenInfo.migration);
            asset = s.hubs[meTokenInfo.targetHubId].asset;
        }
        vault.handleDeposit(sender, asset, assetsDeposited, amounts[1]);
        LibMeToken.updateBalancePooled(true, meToken, amounts[2]);

        // Handling changes
        if (meTokenInfo.targetHubId != 0) {
            if (block.timestamp > meTokenInfo.endTime) {
                hubInfo = s.hubs[meTokenInfo.targetHubId];
                meTokenInfo = LibMeToken.finishResubscribe(meToken);
            } else if (block.timestamp > meTokenInfo.startTime) {
                // Handle migration actions if needed
                IMigration(meTokenInfo.migration).poke(meToken);
            }
        }
        if (hubInfo.updating && block.timestamp > hubInfo.endTime) {
            LibHub.finishUpdate(meTokenInfo.hubId);
        }

        return (asset, sender, amounts[0]);
    }

    function _handleMintWithPermit(
        address meToken,
        uint256 assetsDeposited,
        uint256 deadline,
        uint8 vSig,
        bytes32 rSig,
        bytes32 sSig
    ) private returns (address asset, uint256[2] memory amounts) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        // 0-meTokensMinted 1-fee 2-assetsDepositedAfterFees

        MeTokenInfo memory meTokenInfo = s.meTokens[meToken];
        HubInfo memory hubInfo = s.hubs[meTokenInfo.hubId];

        amounts[1] =
            assetsDeposited -
            ((assetsDeposited * s.mintFee) / s.PRECISION); //assetsDepositedAfterFees

        amounts[0] = calculateMeTokensMinted(meToken, amounts[1]); // meTokensMinted

        asset = _handlingChangesWithPermit(
            amounts[1],
            meToken,
            meTokenInfo,
            hubInfo,
            assetsDeposited,
            deadline,
            vSig,
            rSig,
            sSig
        );
        return (asset, amounts);
    }

    function _handlingChangesWithPermit(
        uint256 assetsDepositedAfterFees,
        address meToken,
        MeTokenInfo memory meTokenInfo,
        HubInfo memory hubInfo,
        uint256 assetsDeposited,
        uint256 deadline,
        uint8 vSig,
        bytes32 rSig,
        bytes32 sSig
    ) private returns (address asset) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        IVault vault = IVault(hubInfo.vault);
        asset = hubInfo.asset;

        if (
            meTokenInfo.migration != address(0) &&
            block.timestamp > meTokenInfo.startTime &&
            IMigration(meTokenInfo.migration).isStarted(meToken)
        ) {
            // Use meToken address to get the asset address from the migration vault
            vault = IVault(meTokenInfo.migration);
            asset = s.hubs[meTokenInfo.targetHubId].asset;
        }
        vault.handleDepositWithPermit(
            LibMeta.msgSender(),
            asset,
            assetsDeposited,
            (assetsDeposited * s.mintFee) / s.PRECISION,
            deadline,
            vSig,
            rSig,
            sSig
        );
        LibMeToken.updateBalancePooled(true, meToken, assetsDepositedAfterFees);

        // Handling changes
        if (meTokenInfo.targetHubId != 0) {
            if (block.timestamp > meTokenInfo.endTime) {
                hubInfo = s.hubs[meTokenInfo.targetHubId];
                meTokenInfo = LibMeToken.finishResubscribe(meToken);
            } else if (block.timestamp > meTokenInfo.startTime) {
                // Handle migration actions if needed
                IMigration(meTokenInfo.migration).poke(meToken);
            }
        }
        if (hubInfo.updating && block.timestamp > hubInfo.endTime) {
            LibHub.finishUpdate(meTokenInfo.hubId);
        }
    }

    function _vaultWithdrawal(
        address sender,
        address recipient,
        address meToken,
        MeTokenInfo memory meTokenInfo,
        HubInfo memory hubInfo,
        uint256 meTokensBurned,
        uint256 assetsReturned
    ) private {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 fee;
        // If msg.sender == owner, give owner the sell rate. - all of tokens returned plus a %
        //      of balancePooled based on how much % of supply will be burned
        // If msg.sender != owner, give msg.sender the burn rate
        if (sender == meTokenInfo.owner) {
            fee = (s.burnOwnerFee * assetsReturned) / s.PRECISION;
        } else {
            fee = (s.burnBuyerFee * assetsReturned) / s.PRECISION;
        }

        assetsReturned = assetsReturned - fee;
        address asset;
        if (
            meTokenInfo.migration != address(0) &&
            block.timestamp > meTokenInfo.startTime
        ) {
            // meToken is in a live state of resubscription
            asset = s.hubs[meTokenInfo.targetHubId].asset;
            IVault(meTokenInfo.migration).handleWithdrawal(
                recipient,
                asset,
                assetsReturned,
                fee
            );
        } else {
            // meToken is *not* resubscribing
            asset = hubInfo.asset;
            IVault(hubInfo.vault).handleWithdrawal(
                recipient,
                asset,
                assetsReturned,
                fee
            );
        }

        emit Burn(
            meToken,
            asset,
            sender,
            recipient,
            meTokensBurned,
            assetsReturned
        );
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import {LibAppStorage, AppStorage} from "./LibAppStorage.sol";
import {LibCurve} from "./LibCurve.sol";

struct HubInfo {
    uint256 startTime;
    uint256 endTime;
    uint256 endCooldown;
    uint256 refundRatio;
    uint256 targetRefundRatio;
    address owner;
    address vault;
    address asset;
    bool updating;
    bool reconfigure;
    bool active;
}

library LibHub {
    event FinishUpdate(uint256 id);

    function finishUpdate(uint256 id) internal {
        HubInfo storage hubInfo = LibAppStorage.diamondStorage().hubs[id];

        require(hubInfo.updating, "Not updating");
        require(block.timestamp > hubInfo.endTime, "Still updating");

        if (hubInfo.targetRefundRatio != 0) {
            hubInfo.refundRatio = hubInfo.targetRefundRatio;
            hubInfo.targetRefundRatio = 0;
        }

        if (hubInfo.reconfigure) {
            LibCurve.finishReconfigure(id);
            hubInfo.reconfigure = false;
        }

        hubInfo.updating = false;
        hubInfo.startTime = 0;
        hubInfo.endTime = 0;

        emit FinishUpdate(id);
    }

    function getHubInfo(uint256 id)
        internal
        view
        returns (HubInfo memory hubInfo)
    {
        HubInfo storage sHubInfo = LibAppStorage.diamondStorage().hubs[id];
        hubInfo.active = sHubInfo.active;
        hubInfo.owner = sHubInfo.owner;
        hubInfo.vault = sHubInfo.vault;
        hubInfo.asset = sHubInfo.asset;
        hubInfo.refundRatio = sHubInfo.refundRatio;
        hubInfo.updating = sHubInfo.updating;
        hubInfo.startTime = sHubInfo.startTime;
        hubInfo.endTime = sHubInfo.endTime;
        hubInfo.endCooldown = sHubInfo.endCooldown;
        hubInfo.reconfigure = sHubInfo.reconfigure;
        hubInfo.targetRefundRatio = sHubInfo.targetRefundRatio;
    }

    function count() internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.hubCount;
    }

    function warmup() internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.hubWarmup;
    }

    function duration() internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.hubDuration;
    }

    function cooldown() internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.hubCooldown;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

/// @title Generic vault interface
/// @author Carter Carlson (@cartercarlson)
interface IVault {
    /// @notice Event of depositing an asset to the vault
    /// @param from            Address which is depositing the asset
    /// @param asset           Address of asset
    /// @param depositAmount   Amount of assets deposited
    /// @param feeAmount       Amount of fees paid
    event HandleDeposit(
        address from,
        address asset,
        uint256 depositAmount,
        uint256 feeAmount
    );

    /// @notice Event of withdrawing an asset from the vault
    /// @param to                  Address which will receive the asset
    /// @param asset               Address of asset
    /// @param withdrawalAmount    Amount of assets withdrawn
    /// @param feeAmount           Amount of fees paid
    event HandleWithdrawal(
        address to,
        address asset,
        uint256 withdrawalAmount,
        uint256 feeAmount
    );

    /// @notice Event of claiming the accrued fees of an asset
    /// @param recipient   Recipient of the asset
    /// @param asset       Address of asset
    /// @param amount      Amount of asset
    event Claim(address recipient, address asset, uint256 amount);

    /// @notice Event of setting the address to receive claimed fees
    /// @param newRecipient New address to receive the claim
    event SetFeeRecipient(address newRecipient);

    /// @notice Claim the accrued fees of an asset
    /// @param asset   Address of asset
    /// @param max     True if claiming all accrued fees of the asset, else false
    /// @param amount  Amount of asset to claim
    function claim(
        address asset,
        bool max,
        uint256 amount
    ) external;

    /// @notice Set the address to receive claimed fees
    /// @param newRecipient New address to receive the claim
    function setFeeRecipient(address newRecipient) external;

    /// @notice Deposit an asset to the vault
    /// @param from            Address which is depositing the asset
    /// @param asset           Address of asset
    /// @param depositAmount   Amount of assets deposited
    /// @param feeAmount       Amount of fees paid
    function handleDeposit(
        address from,
        address asset,
        uint256 depositAmount,
        uint256 feeAmount
    ) external;

    /// @notice Deposit an EIP2612 compliant asset to the vault
    /// @param from             Address which is depositing the asset
    /// @param asset            Address of asset
    /// @param depositAmount    Amount of assets deposited
    /// @param feeAmount        Amount of fees paid
    /// @param deadline         The time at which this expires (unix time)
    /// @param v                v of the signature
    /// @param r                r of the signature
    /// @param s                s of the signature
    function handleDepositWithPermit(
        address from,
        address asset,
        uint256 depositAmount,
        uint256 feeAmount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /// @notice Withdraw an asset from the vault
    /// @param to                  Address which will receive the asset
    /// @param asset               Address of asset
    /// @param withdrawalAmount    Amount of assets withdrawn
    function handleWithdrawal(
        address to,
        address asset,
        uint256 withdrawalAmount,
        uint256 feeAmount
    ) external;

    /// @notice View to see if an asset with encoded arguments passed
    ///           when a vault is registered to a new hub
    /// @param encodedArgs  Additional encoded arguments
    /// @return             True if encoded args are valid, else false
    function isValid(bytes memory encodedArgs) external pure returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

/// @title Generic migration vault interface
/// @author Carter Carlson (@cartercarlson)
interface IMigration {
    /// @notice Method returns true is the migration has started
    /// @param meToken Address of meToken
    function isStarted(address meToken) external view returns (bool);

    /// @notice Method to trigger actions from the migration vault if needed
    /// @param meToken Address of meToken
    function poke(address meToken) external;

    /// @notice Method called when a meToken starts resubscribing to a new hub
    /// @dev This is called within meTokenRegistry.initResubscribe()
    /// @param meToken     Address of meToken
    /// @param encodedArgs Additional encoded arguments
    function initMigration(address meToken, bytes memory encodedArgs) external;

    /// @notice Method to send assets from migration vault to the vault of the
    ///         target hub
    /// @param meToken      Address of meToken
    function finishMigration(address meToken) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

/// @title MeToken ERC20 interface
/// @author Carter Carlson (@cartercarlson)
/// @dev Required for all meTokens
interface IMeToken {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

/// @title MeToken factory interface
/// @author Carter Carlson (@cartercarlson)
interface IMeTokenFactory {
    /// @notice Create a meToken
    /// @param name        Name of meToken
    /// @param symbol      Symbol of meToken
    /// @param diamond     Address of diamond
    function create(
        string calldata name,
        string calldata symbol,
        address diamond
    ) external returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import {ABDKMathQuad} from "../utils/ABDKMathQuad.sol";

library LibCurve {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;
    struct CurveInfo {
        uint256 baseY;
        uint256 targetBaseY;
        uint32 reserveWeight;
        uint32 targetReserveWeight;
    }
    struct CurveStorage {
        // HubId to curve details
        mapping(uint256 => CurveInfo) curves;
        bytes16 one;
        bytes16 maxWeight;
        bytes16 baseX;
    }

    uint32 public constant MAX_WEIGHT = 1e6;
    bytes32 public constant CURVE_STORAGE_POSITION =
        keccak256("diamond.standard.bancor.curves.storage");

    modifier checkReserveWeight(uint256 reserveWeight) {
        require(
            reserveWeight > 0 && reserveWeight <= MAX_WEIGHT,
            "!reserveWeight"
        );
        _;
    }

    function register(
        uint256 hubId,
        uint256 baseY,
        uint32 reserveWeight
    ) internal checkReserveWeight(reserveWeight) {
        CurveInfo storage curveInfo = curveStorage().curves[hubId];

        require(baseY > 0, "!baseY");

        curveInfo.baseY = baseY;
        curveInfo.reserveWeight = reserveWeight;
    }

    function initReconfigure(uint256 hubId, uint32 targetReserveWeight)
        internal
        checkReserveWeight(targetReserveWeight)
    {
        CurveInfo storage curveInfo = curveStorage().curves[hubId];

        require(
            targetReserveWeight != curveInfo.reserveWeight,
            "targetWeight!=Weight"
        );

        // targetBaseX = (old baseY * oldR) / newR
        curveInfo.targetBaseY =
            (curveInfo.baseY * curveInfo.reserveWeight) /
            targetReserveWeight;
        curveInfo.targetReserveWeight = targetReserveWeight;
    }

    function finishReconfigure(uint256 hubId) internal {
        CurveInfo storage curveInfo = curveStorage().curves[hubId];

        curveInfo.reserveWeight = curveInfo.targetReserveWeight;
        curveInfo.baseY = curveInfo.targetBaseY;
        curveInfo.targetReserveWeight = 0;
        curveInfo.targetBaseY = 0;
    }

    function getCurveInfo(uint256 hubId)
        internal
        view
        returns (CurveInfo memory curveInfo)
    {
        CurveStorage storage cs = curveStorage();
        curveInfo.baseY = cs.curves[hubId].baseY;
        curveInfo.reserveWeight = cs.curves[hubId].reserveWeight;
        curveInfo.targetBaseY = cs.curves[hubId].targetBaseY;
        curveInfo.targetReserveWeight = cs.curves[hubId].targetReserveWeight;
    }

    function viewMeTokensMinted(
        uint256 assetsDeposited,
        uint256 hubId,
        uint256 supply,
        uint256 balancePooled
    ) internal view returns (uint256 meTokensMinted) {
        CurveStorage storage cs = curveStorage();

        if (supply > 0) {
            meTokensMinted = _viewMeTokensMinted(
                assetsDeposited,
                cs.curves[hubId].reserveWeight,
                supply,
                balancePooled
            );
        } else {
            meTokensMinted = _viewMeTokensMintedFromZero(
                assetsDeposited,
                cs.curves[hubId].reserveWeight,
                cs.curves[hubId].baseY
            );
        }
    }

    function viewTargetMeTokensMinted(
        uint256 assetsDeposited,
        uint256 hubId,
        uint256 supply,
        uint256 balancePooled
    ) internal view returns (uint256 meTokensMinted) {
        CurveStorage storage cs = curveStorage();
        if (supply > 0) {
            meTokensMinted = _viewMeTokensMinted(
                assetsDeposited,
                cs.curves[hubId].targetReserveWeight,
                supply,
                balancePooled
            );
        } else {
            meTokensMinted = _viewMeTokensMintedFromZero(
                assetsDeposited,
                cs.curves[hubId].targetReserveWeight,
                cs.curves[hubId].targetBaseY
            );
        }
    }

    function viewAssetsReturned(
        uint256 meTokensBurned,
        uint256 hubId,
        uint256 supply,
        uint256 balancePooled
    ) internal view returns (uint256 assetsReturned) {
        assetsReturned = _viewAssetsReturned(
            meTokensBurned,
            curveStorage().curves[hubId].reserveWeight,
            supply,
            balancePooled
        );
    }

    function viewTargetAssetsReturned(
        uint256 meTokensBurned,
        uint256 hubId,
        uint256 supply,
        uint256 balancePooled
    ) internal view returns (uint256 assetsReturned) {
        assetsReturned = _viewAssetsReturned(
            meTokensBurned,
            curveStorage().curves[hubId].targetReserveWeight,
            supply,
            balancePooled
        );
    }

    function curveStorage() internal pure returns (CurveStorage storage ds) {
        bytes32 position = CURVE_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    ///************************* CALCULATE FUNCTIONS **************************/
    ///**************** - USED BY MINT & BURN IN FOUNDRY.SOL - ****************/

    // CALCULATE MINT
    /*******************************************************************************
    //                                                                            //
    // T = meTokensReturned             / /             \      rW           \     //
    // D = assetsDeposited              | |        D    |  ^ ------         |     //
    // rW = reserveWeight        T = S *| |  1 + -----  |    100000    - 1  |     //
    // bP = balancePooled               | |       bP    |                   |     //
    // S = supply                       \ \             /                   /     //
    //                                                                            //
    *******************************************************************************/

    /// @dev Given a deposit (in the connector token), reserve weight, meToken supply and
    ///     balance pooled, calculate the return for a given conversion (in the meToken)
    /// @dev supply * ((1 + assetsDeposited / balancePooled) ^ (reserveWeight / 1000000) - 1)
    /// @param assetsDeposited  amount of collateral tokens to deposit
    /// @param reserveWeight    connector weight, represented in ppm, 1 - 1,000,000
    /// @param supply           current meToken supply
    /// @param balancePooled    total connector balance
    /// @return                 amount of meTokens minted
    function _viewMeTokensMinted(
        uint256 assetsDeposited,
        uint32 reserveWeight,
        uint256 supply,
        uint256 balancePooled
    ) private view returns (uint256) {
        // validate input
        require(balancePooled > 0, "!valid");
        // special case for 0 deposit amount
        if (assetsDeposited == 0) {
            return 0;
        }
        // special case if the weight = 100%
        if (reserveWeight == MAX_WEIGHT) {
            return (supply * assetsDeposited) / balancePooled;
        }
        CurveStorage storage cs = curveStorage();

        bytes16 exponent = uint256(reserveWeight).fromUInt().div(cs.maxWeight);
        // 1 + balanceDeposited/connectorBalance
        bytes16 part1 = cs.one.add(
            assetsDeposited.fromUInt().div(balancePooled.fromUInt())
        );
        //Instead of calculating "base ^ exp", we calculate "e ^ (log(base) * exp)".
        bytes16 res = supply.fromUInt().mul(
            (part1.ln().mul(exponent)).exp().sub(cs.one)
        );
        return res.toUInt();
    }

    // CALCULATE MINT (FROM ZERO)
    /***************************************************************************
    //                                                                        //
    // T = meTokensReturned          /             (1/rW)   \     rW          //
    // D = assetsDeposited           |      D * x ^         |  ^              //
    // rW = reserveWeight        T = |   ----------------   |                 //
    // x = baseX                     |     rW * x * y       |                 //
    // y = baseY                     \                      /                 //
    //                                                                        //
    ***************************************************************************/

    /// @dev Given a deposit (in the collateral token) meToken supply of 0, constant x and
    ///         constant y, calculates the return for a given conversion (in the meToken)
    /// @dev   ( assetsDeposited * baseX ^(1/reserveWeight ) / (reserveWeight * baseX  * baseY )) ^ reserveWeight
    /// @dev  baseX and baseY are needed as Bancor formula breaks from a divide-by-0 when supply=0
    /// @param assetsDeposited  amount of collateral tokens to deposit
    /// @param baseY            constant x
    /// @return                 amount of meTokens minted
    function _viewMeTokensMintedFromZero(
        uint256 assetsDeposited,
        uint256 reserveWeight,
        uint256 baseY
    ) private view returns (uint256) {
        CurveStorage storage cs = curveStorage();

        bytes16 reserveWeight_ = reserveWeight.fromUInt().div(cs.maxWeight);

        // assetsDeposited * baseX ^ (1/connectorWeight)
        bytes16 numerator = assetsDeposited.fromUInt().mul(
            cs.baseX.ln().mul(cs.one.div(reserveWeight_)).exp()
        );
        // as baseX == 1 ether and we want to result to be in ether too we simply remove
        // the multiplication by baseY
        bytes16 denominator = reserveWeight_.mul(baseY.fromUInt());
        // Instead of calculating "x ^ exp", we calculate "e ^ (log(x) * exp)".
        // (numerator/denominator) ^ (reserveWeight )
        // =>   e^ (log(numerator/denominator) * reserveWeight )
        // =>   log(numerator/denominator)  == (numerator.div(denominator)).ln()
        // =>   (numerator.div(denominator)).ln().mul(reserveWeight).exp();
        bytes16 res = (numerator.div(denominator))
            .ln()
            .mul(reserveWeight_)
            .exp();
        return res.toUInt();
    }

    // CALCULATE BURN
    /**************************************************************************************
    //                                                                                   //
    // T = tokensReturned                 /     /                \  ^    1,000,000   \   //
    // B = meTokensBurned                 |     |          B     |      -----------  |   //
    // rW = reserveWeight        T = bP * | 1 - |  1  -  ------  |          r        |   //
    // bP = balancePooled                 |     |          s     |                   |   //
    // S = supply                         \     \                /                   /   //
    //                                                                                   //
    **************************************************************************************/

    /// @dev Given an amount of meTokens to burn, connector weight, supply and collateral pooled,
    ///     calculates the return for a given conversion (in the collateral token)
    /// @dev balancePooled * (1 - (1 - meTokensBurned/supply) ^ (1,000,000 / reserveWeight))
    /// @param meTokensBurned   amount of meTokens to burn
    /// @param reserveWeight    connector weight, represented in ppm, 1 - 1,000,000
    /// @param supply           current meToken supply
    /// @param balancePooled    total connector balance
    /// @return                 amount of collateral tokens received
    function _viewAssetsReturned(
        uint256 meTokensBurned,
        uint32 reserveWeight,
        uint256 supply,
        uint256 balancePooled
    ) private view returns (uint256) {
        // validate input
        require(
            supply > 0 && balancePooled > 0 && meTokensBurned <= supply,
            "!valid"
        );
        // special case for 0 sell amount
        if (meTokensBurned == 0) {
            return 0;
        }
        // special case for selling the entire supply
        if (meTokensBurned == supply) {
            return balancePooled;
        }
        // special case if the weight = 100%
        if (reserveWeight == MAX_WEIGHT) {
            return (balancePooled * meTokensBurned) / supply;
        }
        // MAX_WEIGHT / reserveWeight
        CurveStorage storage cs = curveStorage();

        bytes16 exponent = cs.maxWeight.div(uint256(reserveWeight).fromUInt());

        // 1 - (meTokensBurned / supply)
        bytes16 s = cs.one.sub(
            meTokensBurned.fromUInt().div(supply.fromUInt())
        );
        // Instead of calculating "s ^ exp", we calculate "e ^ (log(s) * exp)".
        // balancePooled - ( balancePooled * s ^ exp))
        bytes16 res = balancePooled.fromUInt().sub(
            balancePooled.fromUInt().mul(s.ln().mul(exponent).exp())
        );
        return res.toUInt();
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

/// @title meTokens Protocol Vault Registry interface
/// @author Carter Carlson (@cartercarlson)
interface IVaultRegistry {
    /// @notice Event of approving an address
    /// @param addr Address to approve
    event Approve(address addr);

    /// @notice Event of unapproving an address
    /// @param addr Address to unapprove
    event Unapprove(address addr);

    /// @notice Approve an address
    /// @param addr Address to approve
    function approve(address addr) external;

    /// @notice Unapprove an address
    /// @param addr Address to unapprove
    function unapprove(address addr) external;

    /// @notice View to see if an address is approved
    /// @param addr     Address to view
    /// @return         True if address is approved, else false
    function isApproved(address addr) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

/// @title meTokens Protocol Migration Registry interface
/// @author Carter Carlson (@cartercarlson)
interface IMigrationRegistry {
    /// @notice Event of approving a meToken migration route
    /// @param initialVault    Vault for meToken to start migration from
    /// @param targetVault     Vault for meToken to migrate to
    /// @param migration       Address of migration vault
    event Approve(address initialVault, address targetVault, address migration);

    /// @notice Event of unapproving a meToken migration route
    /// @param initialVault    Vault for meToken to start migration from
    /// @param targetVault     Vault for meToken to migrate to
    /// @param migration       Address of migration vault
    event Unapprove(
        address initialVault,
        address targetVault,
        address migration
    );

    /// @notice Approve a vault migration route
    /// @param initialVault    Vault for meToken to start migration from
    /// @param targetVault     Vault for meToken to migrate to
    /// @param migration       Address of migration vault
    function approve(
        address initialVault,
        address targetVault,
        address migration
    ) external;

    /// @notice Unapprove a vault migration route
    /// @param initialVault    Vault for meToken to start migration from
    /// @param targetVault     Vault for meToken to migrate to
    /// @param migration       Address of migration vault
    function unapprove(
        address initialVault,
        address targetVault,
        address migration
    ) external;

    /// @notice View to see if a specific migration route is approved
    /// @param initialVault Vault for meToken to start migration from
    /// @param targetVault  Vault for meToken to migrate to
    /// @param migration    Address of migration vault
    /// @return             True if migration route is approved, else false
    function isApproved(
        address initialVault,
        address targetVault,
        address migration
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {IDiamondCutFacet} from "../interfaces/IDiamondCutFacet.sol";

/// @title meTokens Protocol diamond library
/// @author Nick Mudge <[email protected]> (https://twitter.com/mudgen)
/// @notice Diamond library to enable library storage of meTokens protocol.
/// @dev EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
library LibDiamond {
    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
        bytes4[] functionSelectors;
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    event DiamondCut(
        IDiamondCutFacet.FacetCut[] diamondCut,
        address init,
        bytes data
    );

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCutFacet.FacetCut[] memory cut,
        address init,
        bytes memory data
    ) internal {
        for (uint256 facetIndex; facetIndex < cut.length; facetIndex++) {
            IDiamondCutFacet.FacetCutAction action = cut[facetIndex].action;
            if (action == IDiamondCutFacet.FacetCutAction.Add) {
                addFunctions(
                    cut[facetIndex].facetAddress,
                    cut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCutFacet.FacetCutAction.Replace) {
                replaceFunctions(
                    cut[facetIndex].facetAddress,
                    cut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCutFacet.FacetCutAction.Remove) {
                removeFunctions(
                    cut[facetIndex].facetAddress,
                    cut[facetIndex].functionSelectors
                );
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(cut, init, data);
        initializeDiamondCut(init, data);
    }

    function addFunctions(
        address facetAddress,
        bytes4[] memory functionSelectors
    ) internal {
        require(
            functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress == address(0),
                "LibDiamondCut: Can't add function that already exists"
            );
            addFunction(ds, selector, selectorPosition, facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(
        address facetAddress,
        bytes4[] memory functionSelectors
    ) internal {
        require(
            functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress != facetAddress,
                "LibDiamondCut: Can't replace function with same function"
            );
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(
        address facetAddress,
        bytes4[] memory functionSelectors
    ) internal {
        require(
            functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(
            facetAddress == address(0),
            "LibDiamondCut: Remove facet address must be address(0)"
        );
        for (
            uint256 selectorIndex;
            selectorIndex < functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address facetAddress)
        internal
    {
        enforceHasContractCode(
            facetAddress,
            "LibDiamondCut: New facet has no code"
        );
        ds.facetFunctionSelectors[facetAddress].facetAddressPosition = ds
            .facetAddresses
            .length;
        ds.facetAddresses.push(facetAddress);
    }

    function addFunction(
        DiamondStorage storage ds,
        bytes4 selector,
        uint96 selectorPosition,
        address facetAddress
    ) internal {
        ds
            .selectorToFacetAndPosition[selector]
            .functionSelectorPosition = selectorPosition;
        ds.facetFunctionSelectors[facetAddress].functionSelectors.push(
            selector
        );
        ds.selectorToFacetAndPosition[selector].facetAddress = facetAddress;
    }

    function removeFunction(
        DiamondStorage storage ds,
        address facetAddress,
        bytes4 selector
    ) internal {
        require(
            facetAddress != address(0),
            "LibDiamondCut: Can't remove function that doesn't exist"
        );
        // an immutable function is a function defined directly in a diamond
        require(
            facetAddress != address(this),
            "LibDiamondCut: Can't remove immutable function"
        );
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds
            .selectorToFacetAndPosition[selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = ds
            .facetFunctionSelectors[facetAddress]
            .functionSelectors
            .length - 1;
        // if not the same then replace selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds
                .facetFunctionSelectors[facetAddress]
                .functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[facetAddress].functionSelectors[
                    selectorPosition
                ] = lastSelector;
            ds
                .selectorToFacetAndPosition[lastSelector]
                .functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds
                .facetFunctionSelectors[facetAddress]
                .facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[
                    lastFacetAddressPosition
                ];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds
                    .facetFunctionSelectors[lastFacetAddress]
                    .facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address init, bytes memory data) internal {
        if (init == address(0)) {
            require(
                data.length == 0,
                "LibDiamondCut: init is address(0) butcalldata is not empty"
            );
        } else {
            require(
                data.length > 0,
                "LibDiamondCut: calldata is empty but init is not address(0)"
            );
            if (init != address(this)) {
                enforceHasContractCode(
                    init,
                    "LibDiamondCut: init address has no code"
                );
            }
            (bool success, bytes memory error) = init.delegatecall(data);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address target, string memory errorMessage)
        internal
        view
    {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(target)
        }
        require(contractSize > 0, errorMessage);
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math Quad Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity 0.8.9;

/**
 * Smart contract library of mathematical functions operating with IEEE 754
 * quadruple-precision binary floating-point numbers (quadruple precision
 * numbers).  As long as quadruple precision numbers are 16-bytes long, they are
 * represented by bytes16 type.
 */
library ABDKMathQuad {
    /*
     * 0.
     */
    bytes16 private constant _POSITIVE_ZERO =
        0x00000000000000000000000000000000;

    /*
     * -0.
     */
    bytes16 private constant _NEGATIVE_ZERO =
        0x80000000000000000000000000000000;

    /*
     * +Infinity.
     */
    bytes16 private constant _POSITIVE_INFINITY =
        0x7FFF0000000000000000000000000000;

    /*
     * -Infinity.
     */
    bytes16 private constant _NEGATIVE_INFINITY =
        0xFFFF0000000000000000000000000000;

    /*
     * Canonical NaN value.
     */
    bytes16 private constant NaN = 0x7FFF8000000000000000000000000000;

    /**
     * Convert unsigned 256-bit integer number into quadruple precision number.
     *
     * @param x unsigned 256-bit integer number
     * @return quadruple precision number
     */
    function fromUInt(uint256 x) internal pure returns (bytes16) {
        unchecked {
            if (x == 0) return bytes16(0);
            else {
                uint256 result = x;

                uint256 msb = mostSignificantBit(result);
                if (msb < 112) result <<= 112 - msb;
                else if (msb > 112) result >>= msb - 112;

                result =
                    (result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF) |
                    ((16383 + msb) << 112);

                return bytes16(uint128(result));
            }
        }
    }

    /**
     * Convert quadruple precision number into unsigned 256-bit integer number
     * rounding towards zero.  Revert on underflow.  Note, that negative floating
     * point numbers in range (-1.0 .. 0.0) may be converted to unsigned integer
     * without error, because they are rounded to zero.
     *
     * @param x quadruple precision number
     * @return unsigned 256-bit integer number
     */
    function toUInt(bytes16 x) internal pure returns (uint256) {
        unchecked {
            uint256 exponent = (uint128(x) >> 112) & 0x7FFF;

            if (exponent < 16383) return 0; // Underflow

            require(uint128(x) < 0x80000000000000000000000000000000); // Negative

            require(exponent <= 16638); // Overflow
            uint256 result = (uint256(uint128(x)) &
                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF) |
                0x10000000000000000000000000000;

            if (exponent < 16495) result >>= 16495 - exponent;
            else if (exponent > 16495) result <<= exponent - 16495;

            return result;
        }
    }

    /**
     * Calculate sign (x - y).  Revert if either argument is NaN, or both
     * arguments are infinities of the same sign.
     *
     * @param x quadruple precision number
     * @param y quadruple precision number
     * @return sign (x - y)
     */
    function cmp(bytes16 x, bytes16 y) internal pure returns (int8) {
        unchecked {
            uint128 absoluteX = uint128(x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

            require(absoluteX <= 0x7FFF0000000000000000000000000000); // Not NaN

            uint128 absoluteY = uint128(y) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

            require(absoluteY <= 0x7FFF0000000000000000000000000000); // Not NaN

            // Not infinities of the same sign
            require(x != y || absoluteX < 0x7FFF0000000000000000000000000000);

            if (x == y) return 0;
            else {
                bool negativeX = uint128(x) >=
                    0x80000000000000000000000000000000;
                bool negativeY = uint128(y) >=
                    0x80000000000000000000000000000000;

                if (negativeX) {
                    if (negativeY) return absoluteX > absoluteY ? -1 : int8(1);
                    else return -1;
                } else {
                    if (negativeY) return 1;
                    else return absoluteX > absoluteY ? int8(1) : -1;
                }
            }
        }
    }

    /**
     * Calculate x + y.  Special values behave in the following way:
     *
     * NaN + x = NaN for any x.
     * Infinity + x = Infinity for any finite x.
     * -Infinity + x = -Infinity for any finite x.
     * Infinity + Infinity = Infinity.
     * -Infinity + -Infinity = -Infinity.
     * Infinity + -Infinity = -Infinity + Infinity = NaN.
     *
     * @param x quadruple precision number
     * @param y quadruple precision number
     * @return quadruple precision number
     */
    function add(bytes16 x, bytes16 y) internal pure returns (bytes16) {
        unchecked {
            uint256 xExponent = (uint128(x) >> 112) & 0x7FFF;
            uint256 yExponent = (uint128(y) >> 112) & 0x7FFF;

            if (xExponent == 0x7FFF) {
                if (yExponent == 0x7FFF) {
                    if (x == y) return x;
                    else return NaN;
                } else return x;
            } else if (yExponent == 0x7FFF) return y;
            else {
                bool xSign = uint128(x) >= 0x80000000000000000000000000000000;
                uint256 xSignifier = uint128(x) &
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                if (xExponent == 0) xExponent = 1;
                else xSignifier |= 0x10000000000000000000000000000;

                bool ySign = uint128(y) >= 0x80000000000000000000000000000000;
                uint256 ySignifier = uint128(y) &
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                if (yExponent == 0) yExponent = 1;
                else ySignifier |= 0x10000000000000000000000000000;

                if (xSignifier == 0)
                    return y == _NEGATIVE_ZERO ? _POSITIVE_ZERO : y;
                else if (ySignifier == 0)
                    return x == _NEGATIVE_ZERO ? _POSITIVE_ZERO : x;
                else {
                    int256 delta = int256(xExponent) - int256(yExponent);

                    if (xSign == ySign) {
                        if (delta > 112) return x;
                        else if (delta > 0) ySignifier >>= uint256(delta);
                        else if (delta < -112) return y;
                        else if (delta < 0) {
                            xSignifier >>= uint256(-delta);
                            xExponent = yExponent;
                        }

                        xSignifier += ySignifier;

                        if (xSignifier >= 0x20000000000000000000000000000) {
                            xSignifier >>= 1;
                            xExponent += 1;
                        }

                        if (xExponent == 0x7FFF)
                            return
                                xSign ? _NEGATIVE_INFINITY : _POSITIVE_INFINITY;
                        else {
                            if (xSignifier < 0x10000000000000000000000000000)
                                xExponent = 0;
                            else xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

                            return
                                bytes16(
                                    uint128(
                                        (
                                            xSign
                                                ? 0x80000000000000000000000000000000
                                                : 0
                                        ) |
                                            (xExponent << 112) |
                                            xSignifier
                                    )
                                );
                        }
                    } else {
                        if (delta > 0) {
                            xSignifier <<= 1;
                            xExponent -= 1;
                        } else if (delta < 0) {
                            ySignifier <<= 1;
                            xExponent = yExponent - 1;
                        }

                        if (delta > 112) ySignifier = 1;
                        else if (delta > 1)
                            ySignifier =
                                ((ySignifier - 1) >> uint256(delta - 1)) +
                                1;
                        else if (delta < -112) xSignifier = 1;
                        else if (delta < -1)
                            xSignifier =
                                ((xSignifier - 1) >> uint256(-delta - 1)) +
                                1;

                        if (xSignifier >= ySignifier) xSignifier -= ySignifier;
                        else {
                            xSignifier = ySignifier - xSignifier;
                            xSign = ySign;
                        }

                        if (xSignifier == 0) return _POSITIVE_ZERO;

                        uint256 msb = mostSignificantBit(xSignifier);

                        if (msb == 113) {
                            xSignifier =
                                (xSignifier >> 1) &
                                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                            xExponent += 1;
                        } else if (msb < 112) {
                            uint256 shift = 112 - msb;
                            if (xExponent > shift) {
                                xSignifier =
                                    (xSignifier << shift) &
                                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                                xExponent -= shift;
                            } else {
                                xSignifier <<= xExponent - 1;
                                xExponent = 0;
                            }
                        } else xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

                        if (xExponent == 0x7FFF)
                            return
                                xSign ? _NEGATIVE_INFINITY : _POSITIVE_INFINITY;
                        else
                            return
                                bytes16(
                                    uint128(
                                        (
                                            xSign
                                                ? 0x80000000000000000000000000000000
                                                : 0
                                        ) |
                                            (xExponent << 112) |
                                            xSignifier
                                    )
                                );
                    }
                }
            }
        }
    }

    /**
     * Calculate x - y.  Special values behave in the following way:
     *
     * NaN - x = NaN for any x.
     * Infinity - x = Infinity for any finite x.
     * -Infinity - x = -Infinity for any finite x.
     * Infinity - -Infinity = Infinity.
     * -Infinity - Infinity = -Infinity.
     * Infinity - Infinity = -Infinity - -Infinity = NaN.
     *
     * @param x quadruple precision number
     * @param y quadruple precision number
     * @return quadruple precision number
     */
    function sub(bytes16 x, bytes16 y) internal pure returns (bytes16) {
        unchecked {
            return add(x, y ^ 0x80000000000000000000000000000000);
        }
    }

    /**
     * Calculate x * y.  Special values behave in the following way:
     *
     * NaN * x = NaN for any x.
     * Infinity * x = Infinity for any finite positive x.
     * Infinity * x = -Infinity for any finite negative x.
     * -Infinity * x = -Infinity for any finite positive x.
     * -Infinity * x = Infinity for any finite negative x.
     * Infinity * 0 = NaN.
     * -Infinity * 0 = NaN.
     * Infinity * Infinity = Infinity.
     * Infinity * -Infinity = -Infinity.
     * -Infinity * Infinity = -Infinity.
     * -Infinity * -Infinity = Infinity.
     *
     * @param x quadruple precision number
     * @param y quadruple precision number
     * @return quadruple precision number
     */
    function mul(bytes16 x, bytes16 y) internal pure returns (bytes16) {
        unchecked {
            uint256 xExponent = (uint128(x) >> 112) & 0x7FFF;
            uint256 yExponent = (uint128(y) >> 112) & 0x7FFF;

            if (xExponent == 0x7FFF) {
                if (yExponent == 0x7FFF) {
                    if (x == y)
                        return x ^ (y & 0x80000000000000000000000000000000);
                    else if (x ^ y == 0x80000000000000000000000000000000)
                        return x | y;
                    else return NaN;
                } else {
                    if (y & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
                    else return x ^ (y & 0x80000000000000000000000000000000);
                }
            } else if (yExponent == 0x7FFF) {
                if (x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
                else return y ^ (x & 0x80000000000000000000000000000000);
            } else {
                uint256 xSignifier = uint128(x) &
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                if (xExponent == 0) xExponent = 1;
                else xSignifier |= 0x10000000000000000000000000000;

                uint256 ySignifier = uint128(y) &
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                if (yExponent == 0) yExponent = 1;
                else ySignifier |= 0x10000000000000000000000000000;

                xSignifier *= ySignifier;
                if (xSignifier == 0)
                    return
                        (x ^ y) & 0x80000000000000000000000000000000 > 0
                            ? _NEGATIVE_ZERO
                            : _POSITIVE_ZERO;

                xExponent += yExponent;

                uint256 msb = xSignifier >=
                    0x200000000000000000000000000000000000000000000000000000000
                    ? 225
                    : xSignifier >=
                        0x100000000000000000000000000000000000000000000000000000000
                    ? 224
                    : mostSignificantBit(xSignifier);

                if (xExponent + msb < 16496) {
                    // Underflow
                    xExponent = 0;
                    xSignifier = 0;
                } else if (xExponent + msb < 16608) {
                    // Subnormal
                    if (xExponent < 16496) xSignifier >>= 16496 - xExponent;
                    else if (xExponent > 16496)
                        xSignifier <<= xExponent - 16496;
                    xExponent = 0;
                } else if (xExponent + msb > 49373) {
                    xExponent = 0x7FFF;
                    xSignifier = 0;
                } else {
                    if (msb > 112) xSignifier >>= msb - 112;
                    else if (msb < 112) xSignifier <<= 112 - msb;

                    xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

                    xExponent = xExponent + msb - 16607;
                }

                return
                    bytes16(
                        uint128(
                            uint128(
                                (x ^ y) & 0x80000000000000000000000000000000
                            ) |
                                (xExponent << 112) |
                                xSignifier
                        )
                    );
            }
        }
    }

    /**
     * Calculate x / y.  Special values behave in the following way:
     *
     * NaN / x = NaN for any x.
     * x / NaN = NaN for any x.
     * Infinity / x = Infinity for any finite non-negative x.
     * Infinity / x = -Infinity for any finite negative x including -0.
     * -Infinity / x = -Infinity for any finite non-negative x.
     * -Infinity / x = Infinity for any finite negative x including -0.
     * x / Infinity = 0 for any finite non-negative x.
     * x / -Infinity = -0 for any finite non-negative x.
     * x / Infinity = -0 for any finite non-negative x including -0.
     * x / -Infinity = 0 for any finite non-negative x including -0.
     *
     * Infinity / Infinity = NaN.
     * Infinity / -Infinity = -NaN.
     * -Infinity / Infinity = -NaN.
     * -Infinity / -Infinity = NaN.
     *
     * Division by zero behaves in the following way:
     *
     * x / 0 = Infinity for any finite positive x.
     * x / -0 = -Infinity for any finite positive x.
     * x / 0 = -Infinity for any finite negative x.
     * x / -0 = Infinity for any finite negative x.
     * 0 / 0 = NaN.
     * 0 / -0 = NaN.
     * -0 / 0 = NaN.
     * -0 / -0 = NaN.
     *
     * @param x quadruple precision number
     * @param y quadruple precision number
     * @return quadruple precision number
     */
    function div(bytes16 x, bytes16 y) internal pure returns (bytes16) {
        unchecked {
            uint256 xExponent = (uint128(x) >> 112) & 0x7FFF;
            uint256 yExponent = (uint128(y) >> 112) & 0x7FFF;

            if (xExponent == 0x7FFF) {
                if (yExponent == 0x7FFF) return NaN;
                else return x ^ (y & 0x80000000000000000000000000000000);
            } else if (yExponent == 0x7FFF) {
                if (y & 0x0000FFFFFFFFFFFFFFFFFFFFFFFFFFFF != 0) return NaN;
                else
                    return
                        _POSITIVE_ZERO |
                        ((x ^ y) & 0x80000000000000000000000000000000);
            } else if (y & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) {
                if (x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
                else
                    return
                        _POSITIVE_INFINITY |
                        ((x ^ y) & 0x80000000000000000000000000000000);
            } else {
                uint256 ySignifier = uint128(y) &
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                if (yExponent == 0) yExponent = 1;
                else ySignifier |= 0x10000000000000000000000000000;

                uint256 xSignifier = uint128(x) &
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                if (xExponent == 0) {
                    if (xSignifier != 0) {
                        uint256 shift = 226 - mostSignificantBit(xSignifier);

                        xSignifier <<= shift;

                        xExponent = 1;
                        yExponent += shift - 114;
                    }
                } else {
                    xSignifier =
                        (xSignifier | 0x10000000000000000000000000000) <<
                        114;
                }

                xSignifier = xSignifier / ySignifier;
                if (xSignifier == 0)
                    return
                        (x ^ y) & 0x80000000000000000000000000000000 > 0
                            ? _NEGATIVE_ZERO
                            : _POSITIVE_ZERO;

                assert(xSignifier >= 0x1000000000000000000000000000);

                uint256 msb = xSignifier >= 0x80000000000000000000000000000
                    ? mostSignificantBit(xSignifier)
                    : xSignifier >= 0x40000000000000000000000000000
                    ? 114
                    : xSignifier >= 0x20000000000000000000000000000
                    ? 113
                    : 112;

                if (xExponent + msb > yExponent + 16497) {
                    // Overflow
                    xExponent = 0x7FFF;
                    xSignifier = 0;
                } else if (xExponent + msb + 16380 < yExponent) {
                    // Underflow
                    xExponent = 0;
                    xSignifier = 0;
                } else if (xExponent + msb + 16268 < yExponent) {
                    // Subnormal
                    if (xExponent + 16380 > yExponent)
                        xSignifier <<= xExponent + 16380 - yExponent;
                    else if (xExponent + 16380 < yExponent)
                        xSignifier >>= yExponent - xExponent - 16380;

                    xExponent = 0;
                } else {
                    // Normal
                    if (msb > 112) xSignifier >>= msb - 112;

                    xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

                    xExponent = xExponent + msb + 16269 - yExponent;
                }

                return
                    bytes16(
                        uint128(
                            uint128(
                                (x ^ y) & 0x80000000000000000000000000000000
                            ) |
                                (xExponent << 112) |
                                xSignifier
                        )
                    );
            }
        }
    }

    /**
     * Calculate square root of x.  Return NaN on negative x excluding -0.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function sqrt(bytes16 x) internal pure returns (bytes16) {
        unchecked {
            if (uint128(x) > 0x80000000000000000000000000000000) return NaN;
            else {
                uint256 xExponent = (uint128(x) >> 112) & 0x7FFF;
                if (xExponent == 0x7FFF) return x;
                else {
                    uint256 xSignifier = uint128(x) &
                        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                    if (xExponent == 0) xExponent = 1;
                    else xSignifier |= 0x10000000000000000000000000000;

                    if (xSignifier == 0) return _POSITIVE_ZERO;

                    bool oddExponent = xExponent & 0x1 == 0;
                    xExponent = (xExponent + 16383) >> 1;

                    if (oddExponent) {
                        if (xSignifier >= 0x10000000000000000000000000000)
                            xSignifier <<= 113;
                        else {
                            uint256 msb = mostSignificantBit(xSignifier);
                            uint256 shift = (226 - msb) & 0xFE;
                            xSignifier <<= shift;
                            xExponent -= (shift - 112) >> 1;
                        }
                    } else {
                        if (xSignifier >= 0x10000000000000000000000000000)
                            xSignifier <<= 112;
                        else {
                            uint256 msb = mostSignificantBit(xSignifier);
                            uint256 shift = (225 - msb) & 0xFE;
                            xSignifier <<= shift;
                            xExponent -= (shift - 112) >> 1;
                        }
                    }

                    uint256 r = 0x10000000000000000000000000000;
                    r = (r + xSignifier / r) >> 1;
                    r = (r + xSignifier / r) >> 1;
                    r = (r + xSignifier / r) >> 1;
                    r = (r + xSignifier / r) >> 1;
                    r = (r + xSignifier / r) >> 1;
                    r = (r + xSignifier / r) >> 1;
                    r = (r + xSignifier / r) >> 1; // Seven iterations should be enough
                    uint256 r1 = xSignifier / r;
                    if (r1 < r) r = r1;

                    return
                        bytes16(
                            uint128(
                                (xExponent << 112) |
                                    (r & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                            )
                        );
                }
            }
        }
    }

    /**
     * Calculate binary logarithm of x.  Return NaN on negative x excluding -0.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function log_2(bytes16 x) internal pure returns (bytes16) {
        unchecked {
            if (uint128(x) > 0x80000000000000000000000000000000) return NaN;
            else if (x == 0x3FFF0000000000000000000000000000)
                return _POSITIVE_ZERO;
            else {
                uint256 xExponent = (uint128(x) >> 112) & 0x7FFF;
                if (xExponent == 0x7FFF) return x;
                else {
                    uint256 xSignifier = uint128(x) &
                        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                    if (xExponent == 0) xExponent = 1;
                    else xSignifier |= 0x10000000000000000000000000000;

                    if (xSignifier == 0) return _NEGATIVE_INFINITY;

                    bool resultNegative;
                    uint256 resultExponent = 16495;
                    uint256 resultSignifier;

                    if (xExponent >= 0x3FFF) {
                        resultNegative = false;
                        resultSignifier = xExponent - 0x3FFF;
                        xSignifier <<= 15;
                    } else {
                        resultNegative = true;
                        if (xSignifier >= 0x10000000000000000000000000000) {
                            resultSignifier = 0x3FFE - xExponent;
                            xSignifier <<= 15;
                        } else {
                            uint256 msb = mostSignificantBit(xSignifier);
                            resultSignifier = 16493 - msb;
                            xSignifier <<= 127 - msb;
                        }
                    }

                    if (xSignifier == 0x80000000000000000000000000000000) {
                        if (resultNegative) resultSignifier += 1;
                        uint256 shift = 112 -
                            mostSignificantBit(resultSignifier);
                        resultSignifier <<= shift;
                        resultExponent -= shift;
                    } else {
                        uint256 bb = resultNegative ? 1 : 0;
                        while (
                            resultSignifier < 0x10000000000000000000000000000
                        ) {
                            resultSignifier <<= 1;
                            resultExponent -= 1;

                            xSignifier *= xSignifier;
                            uint256 b = xSignifier >> 255;
                            resultSignifier += b ^ bb;
                            xSignifier >>= 127 + b;
                        }
                    }

                    return
                        bytes16(
                            uint128(
                                (
                                    resultNegative
                                        ? 0x80000000000000000000000000000000
                                        : 0
                                ) |
                                    (resultExponent << 112) |
                                    (resultSignifier &
                                        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                            )
                        );
                }
            }
        }
    }

    /**
     * Calculate natural logarithm of x.  Return NaN on negative x excluding -0.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function ln(bytes16 x) internal pure returns (bytes16) {
        unchecked {
            return mul(log_2(x), 0x3FFE62E42FEFA39EF35793C7673007E5);
        }
    }

    /**
     * Calculate 2^x.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function pow_2(bytes16 x) internal pure returns (bytes16) {
        unchecked {
            bool xNegative = uint128(x) > 0x80000000000000000000000000000000;
            uint256 xExponent = (uint128(x) >> 112) & 0x7FFF;
            uint256 xSignifier = uint128(x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

            if (xExponent == 0x7FFF && xSignifier != 0) return NaN;
            else if (xExponent > 16397)
                return xNegative ? _POSITIVE_ZERO : _POSITIVE_INFINITY;
            else if (xExponent < 16255)
                return 0x3FFF0000000000000000000000000000;
            else {
                if (xExponent == 0) xExponent = 1;
                else xSignifier |= 0x10000000000000000000000000000;

                if (xExponent > 16367) xSignifier <<= xExponent - 16367;
                else if (xExponent < 16367) xSignifier >>= 16367 - xExponent;

                if (
                    xNegative &&
                    xSignifier > 0x406E00000000000000000000000000000000
                ) return _POSITIVE_ZERO;

                if (
                    !xNegative &&
                    xSignifier > 0x3FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                ) return _POSITIVE_INFINITY;

                uint256 resultExponent = xSignifier >> 128;
                xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                if (xNegative && xSignifier != 0) {
                    xSignifier = ~xSignifier;
                    resultExponent += 1;
                }

                uint256 resultSignifier = 0x80000000000000000000000000000000;
                if (xSignifier & 0x80000000000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x16A09E667F3BCC908B2FB1366EA957D3E) >>
                        128;
                if (xSignifier & 0x40000000000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1306FE0A31B7152DE8D5A46305C85EDEC) >>
                        128;
                if (xSignifier & 0x20000000000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1172B83C7D517ADCDF7C8C50EB14A791F) >>
                        128;
                if (xSignifier & 0x10000000000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10B5586CF9890F6298B92B71842A98363) >>
                        128;
                if (xSignifier & 0x8000000000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1059B0D31585743AE7C548EB68CA417FD) >>
                        128;
                if (xSignifier & 0x4000000000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x102C9A3E778060EE6F7CACA4F7A29BDE8) >>
                        128;
                if (xSignifier & 0x2000000000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10163DA9FB33356D84A66AE336DCDFA3F) >>
                        128;
                if (xSignifier & 0x1000000000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100B1AFA5ABCBED6129AB13EC11DC9543) >>
                        128;
                if (xSignifier & 0x800000000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10058C86DA1C09EA1FF19D294CF2F679B) >>
                        128;
                if (xSignifier & 0x400000000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1002C605E2E8CEC506D21BFC89A23A00F) >>
                        128;
                if (xSignifier & 0x200000000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100162F3904051FA128BCA9C55C31E5DF) >>
                        128;
                if (xSignifier & 0x100000000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000B175EFFDC76BA38E31671CA939725) >>
                        128;
                if (xSignifier & 0x80000000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100058BA01FB9F96D6CACD4B180917C3D) >>
                        128;
                if (xSignifier & 0x40000000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10002C5CC37DA9491D0985C348C68E7B3) >>
                        128;
                if (xSignifier & 0x20000000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000162E525EE054754457D5995292026) >>
                        128;
                if (xSignifier & 0x10000000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000B17255775C040618BF4A4ADE83FC) >>
                        128;
                if (xSignifier & 0x8000000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000058B91B5BC9AE2EED81E9B7D4CFAB) >>
                        128;
                if (xSignifier & 0x4000000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100002C5C89D5EC6CA4D7C8ACC017B7C9) >>
                        128;
                if (xSignifier & 0x2000000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000162E43F4F831060E02D839A9D16D) >>
                        128;
                if (xSignifier & 0x1000000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000B1721BCFC99D9F890EA06911763) >>
                        128;
                if (xSignifier & 0x800000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000058B90CF1E6D97F9CA14DBCC1628) >>
                        128;
                if (xSignifier & 0x400000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000002C5C863B73F016468F6BAC5CA2B) >>
                        128;
                if (xSignifier & 0x200000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000162E430E5A18F6119E3C02282A5) >>
                        128;
                if (xSignifier & 0x100000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000B1721835514B86E6D96EFD1BFE) >>
                        128;
                if (xSignifier & 0x80000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000058B90C0B48C6BE5DF846C5B2EF) >>
                        128;
                if (xSignifier & 0x40000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000002C5C8601CC6B9E94213C72737A) >>
                        128;
                if (xSignifier & 0x20000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000162E42FFF037DF38AA2B219F06) >>
                        128;
                if (xSignifier & 0x10000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000B17217FBA9C739AA5819F44F9) >>
                        128;
                if (xSignifier & 0x8000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000058B90BFCDEE5ACD3C1CEDC823) >>
                        128;
                if (xSignifier & 0x4000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000002C5C85FE31F35A6A30DA1BE50) >>
                        128;
                if (xSignifier & 0x2000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000162E42FF0999CE3541B9FFFCF) >>
                        128;
                if (xSignifier & 0x1000000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000B17217F80F4EF5AADDA45554) >>
                        128;
                if (xSignifier & 0x800000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000058B90BFBF8479BD5A81B51AD) >>
                        128;
                if (xSignifier & 0x400000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000002C5C85FDF84BD62AE30A74CC) >>
                        128;
                if (xSignifier & 0x200000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000162E42FEFB2FED257559BDAA) >>
                        128;
                if (xSignifier & 0x100000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000B17217F7D5A7716BBA4A9AE) >>
                        128;
                if (xSignifier & 0x80000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000058B90BFBE9DDBAC5E109CCE) >>
                        128;
                if (xSignifier & 0x40000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000002C5C85FDF4B15DE6F17EB0D) >>
                        128;
                if (xSignifier & 0x20000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000162E42FEFA494F1478FDE05) >>
                        128;
                if (xSignifier & 0x10000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000B17217F7D20CF927C8E94C) >>
                        128;
                if (xSignifier & 0x8000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000058B90BFBE8F71CB4E4B33D) >>
                        128;
                if (xSignifier & 0x4000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000002C5C85FDF477B662B26945) >>
                        128;
                if (xSignifier & 0x2000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000162E42FEFA3AE53369388C) >>
                        128;
                if (xSignifier & 0x1000000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000B17217F7D1D351A389D40) >>
                        128;
                if (xSignifier & 0x800000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000058B90BFBE8E8B2D3D4EDE) >>
                        128;
                if (xSignifier & 0x400000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000002C5C85FDF4741BEA6E77E) >>
                        128;
                if (xSignifier & 0x200000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000162E42FEFA39FE95583C2) >>
                        128;
                if (xSignifier & 0x100000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000B17217F7D1CFB72B45E1) >>
                        128;
                if (xSignifier & 0x80000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000058B90BFBE8E7CC35C3F0) >>
                        128;
                if (xSignifier & 0x40000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000002C5C85FDF473E242EA38) >>
                        128;
                if (xSignifier & 0x20000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000162E42FEFA39F02B772C) >>
                        128;
                if (xSignifier & 0x10000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000B17217F7D1CF7D83C1A) >>
                        128;
                if (xSignifier & 0x8000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000058B90BFBE8E7BDCBE2E) >>
                        128;
                if (xSignifier & 0x4000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000002C5C85FDF473DEA871F) >>
                        128;
                if (xSignifier & 0x2000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000162E42FEFA39EF44D91) >>
                        128;
                if (xSignifier & 0x1000000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000B17217F7D1CF79E949) >>
                        128;
                if (xSignifier & 0x800000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000058B90BFBE8E7BCE544) >>
                        128;
                if (xSignifier & 0x400000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000002C5C85FDF473DE6ECA) >>
                        128;
                if (xSignifier & 0x200000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000162E42FEFA39EF366F) >>
                        128;
                if (xSignifier & 0x100000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000000B17217F7D1CF79AFA) >>
                        128;
                if (xSignifier & 0x80000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000058B90BFBE8E7BCD6D) >>
                        128;
                if (xSignifier & 0x40000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000002C5C85FDF473DE6B2) >>
                        128;
                if (xSignifier & 0x20000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000000162E42FEFA39EF358) >>
                        128;
                if (xSignifier & 0x10000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000000B17217F7D1CF79AB) >>
                        128;
                if (xSignifier & 0x8000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000000058B90BFBE8E7BCD5) >>
                        128;
                if (xSignifier & 0x4000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000002C5C85FDF473DE6A) >>
                        128;
                if (xSignifier & 0x2000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000000162E42FEFA39EF34) >>
                        128;
                if (xSignifier & 0x1000000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000B17217F7D1CF799) >>
                        128;
                if (xSignifier & 0x800000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000000058B90BFBE8E7BCC) >>
                        128;
                if (xSignifier & 0x400000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000000002C5C85FDF473DE5) >>
                        128;
                if (xSignifier & 0x200000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000162E42FEFA39EF2) >>
                        128;
                if (xSignifier & 0x100000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000000000B17217F7D1CF78) >>
                        128;
                if (xSignifier & 0x80000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000058B90BFBE8E7BB) >>
                        128;
                if (xSignifier & 0x40000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000000002C5C85FDF473DD) >>
                        128;
                if (xSignifier & 0x20000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000000000162E42FEFA39EE) >>
                        128;
                if (xSignifier & 0x10000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000000000B17217F7D1CF6) >>
                        128;
                if (xSignifier & 0x8000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000000000058B90BFBE8E7A) >>
                        128;
                if (xSignifier & 0x4000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000002C5C85FDF473C) >>
                        128;
                if (xSignifier & 0x2000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000000000162E42FEFA39D) >>
                        128;
                if (xSignifier & 0x1000000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000000B17217F7D1CE) >>
                        128;
                if (xSignifier & 0x800000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000000000058B90BFBE8E6) >>
                        128;
                if (xSignifier & 0x400000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000000000002C5C85FDF472) >>
                        128;
                if (xSignifier & 0x200000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000000162E42FEFA38) >>
                        128;
                if (xSignifier & 0x100000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000000000000B17217F7D1B) >>
                        128;
                if (xSignifier & 0x80000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000000058B90BFBE8D) >>
                        128;
                if (xSignifier & 0x40000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000000000002C5C85FDF46) >>
                        128;
                if (xSignifier & 0x20000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000000000000162E42FEFA2) >>
                        128;
                if (xSignifier & 0x10000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000000000000B17217F7D0) >>
                        128;
                if (xSignifier & 0x8000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000000000000058B90BFBE7) >>
                        128;
                if (xSignifier & 0x4000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000000002C5C85FDF3) >>
                        128;
                if (xSignifier & 0x2000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000000000000162E42FEF9) >>
                        128;
                if (xSignifier & 0x1000000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000000000B17217F7C) >>
                        128;
                if (xSignifier & 0x800000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000000000000058B90BFBD) >>
                        128;
                if (xSignifier & 0x400000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000000000000002C5C85FDE) >>
                        128;
                if (xSignifier & 0x200000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000000000162E42FEE) >>
                        128;
                if (xSignifier & 0x100000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000000000000000B17217F6) >>
                        128;
                if (xSignifier & 0x80000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000000000058B90BFA) >>
                        128;
                if (xSignifier & 0x40000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000000000000002C5C85FC) >>
                        128;
                if (xSignifier & 0x20000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000000000000000162E42FD) >>
                        128;
                if (xSignifier & 0x10000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000000000000000B17217E) >>
                        128;
                if (xSignifier & 0x8000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000000000000000058B90BE) >>
                        128;
                if (xSignifier & 0x4000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000000000002C5C85E) >>
                        128;
                if (xSignifier & 0x2000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000000000000000162E42E) >>
                        128;
                if (xSignifier & 0x1000000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000000000000B17216) >>
                        128;
                if (xSignifier & 0x800000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000000000000000058B90A) >>
                        128;
                if (xSignifier & 0x400000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000000000000000002C5C84) >>
                        128;
                if (xSignifier & 0x200000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000000000000162E41) >>
                        128;
                if (xSignifier & 0x100000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000000000000000000B1720) >>
                        128;
                if (xSignifier & 0x80000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000000000000058B8F) >>
                        128;
                if (xSignifier & 0x40000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000000000000000002C5C7) >>
                        128;
                if (xSignifier & 0x20000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000000000000000000162E3) >>
                        128;
                if (xSignifier & 0x10000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000000000000000000B171) >>
                        128;
                if (xSignifier & 0x8000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000000000000000000058B8) >>
                        128;
                if (xSignifier & 0x4000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000000000000002C5B) >>
                        128;
                if (xSignifier & 0x2000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000000000000000000162D) >>
                        128;
                if (xSignifier & 0x1000 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000000000000000B16) >>
                        128;
                if (xSignifier & 0x800 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000000000000000000058A) >>
                        128;
                if (xSignifier & 0x400 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000000000000000000002C4) >>
                        128;
                if (xSignifier & 0x200 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000000000000000161) >>
                        128;
                if (xSignifier & 0x100 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x1000000000000000000000000000000B0) >>
                        128;
                if (xSignifier & 0x80 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000000000000000057) >>
                        128;
                if (xSignifier & 0x40 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000000000000000000002B) >>
                        128;
                if (xSignifier & 0x20 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000000000000000015) >>
                        128;
                if (xSignifier & 0x10 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x10000000000000000000000000000000A) >>
                        128;
                if (xSignifier & 0x8 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000000000000000004) >>
                        128;
                if (xSignifier & 0x4 > 0)
                    resultSignifier =
                        (resultSignifier *
                            0x100000000000000000000000000000001) >>
                        128;

                if (!xNegative) {
                    resultSignifier =
                        (resultSignifier >> 15) &
                        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                    resultExponent += 0x3FFF;
                } else if (resultExponent <= 0x3FFE) {
                    resultSignifier =
                        (resultSignifier >> 15) &
                        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                    resultExponent = 0x3FFF - resultExponent;
                } else {
                    resultSignifier =
                        resultSignifier >>
                        (resultExponent - 16367);
                    resultExponent = 0;
                }

                return
                    bytes16(uint128((resultExponent << 112) | resultSignifier));
            }
        }
    }

    /**
     * Calculate e^x.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function exp(bytes16 x) internal pure returns (bytes16) {
        unchecked {
            return pow_2(mul(x, 0x3FFF71547652B82FE1777D0FFDA0D23A));
        }
    }

    /**
     * Get index of the most significant non-zero bit in binary representation of
     * x.  Reverts if x is zero.
     *
     * @return index of the most significant non-zero bit in binary representation
     *         of x
     */
    function mostSignificantBit(uint256 x) private pure returns (uint256) {
        unchecked {
            require(x > 0);

            uint256 result = 0;

            if (x >= 0x100000000000000000000000000000000) {
                x >>= 128;
                result += 128;
            }
            if (x >= 0x10000000000000000) {
                x >>= 64;
                result += 64;
            }
            if (x >= 0x100000000) {
                x >>= 32;
                result += 32;
            }
            if (x >= 0x10000) {
                x >>= 16;
                result += 16;
            }
            if (x >= 0x100) {
                x >>= 8;
                result += 8;
            }
            if (x >= 0x10) {
                x >>= 4;
                result += 4;
            }
            if (x >= 0x4) {
                x >>= 2;
                result += 2;
            }
            if (x >= 0x2) result += 1; // No need to shift x anymore

            return result;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCutFacet {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        bytes4[] functionSelectors;
        address facetAddress;
        FacetCutAction action;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param cut Contains the facet addresses and function selectors
    /// @param init The address of the contract or facet to execute calldata
    /// @param data A function call, including function selector and arguments
    ///                  calldata is executed with delegatecall on init
    function diamondCut(
        FacetCut[] calldata cut,
        address init,
        bytes calldata data
    ) external;

    event DiamondCut(FacetCut[] diamondCut, address init, bytes data);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

library LibWeightedAverage {
    uint256 private constant _PRECISION = 10**18;

    // CALCULATE TIME-WEIGHTED AVERAGE
    /****************************************************************************
    //                                     __                      __          //
    // wA = weightedAmount                /                          \         //
    // a = amout                          |   (a - tA) * (bT - sT)   |         //
    // tA = targetAmount         wA = a + |   --------------------   |         //
    // sT = startTime                     |        (eT - sT)         |         //
    // eT = endTime                       \__                      __/         //
    // bT = block.timestame                                                    //
    //                                                                         //
    ****************************************************************************/

    function calculate(
        uint256 amount,
        uint256 targetAmount,
        uint256 startTime,
        uint256 endTime
    ) internal view returns (uint256) {
        if (block.timestamp < startTime) {
            // Update hasn't started, apply no weighting
            return amount;
        } else if (block.timestamp > endTime) {
            // Update is over, return target amount
            return targetAmount;
        } else {
            // Currently in an update, return weighted average
            if (targetAmount > amount) {
                // re-orders above visualized formula to handle negative numbers
                return
                    (_PRECISION *
                        amount +
                        (_PRECISION *
                            (targetAmount - amount) *
                            (block.timestamp - startTime)) /
                        (endTime - startTime)) / _PRECISION;
            } else {
                // follows order of visualized formula above
                return
                    (_PRECISION *
                        amount -
                        (_PRECISION *
                            (amount - targetAmount) *
                            (block.timestamp - startTime)) /
                        (endTime - startTime)) / _PRECISION;
            }
        }
    }
}