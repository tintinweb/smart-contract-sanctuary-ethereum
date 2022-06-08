// SPDX-License-Identifier: GPL-2.0-only
// Copyright 2020 Spilsbury Holdings Ltd
pragma solidity >=0.6.10 <=0.8.10;
pragma experimental ABIEncoderV2;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IVault, IAsset, PoolSpecialization} from "./interfaces/IVault.sol";
import {IPool} from "./interfaces/IPool.sol";
import {ITranche} from "./interfaces/ITranche.sol";
import {IDeploymentValidator} from "./interfaces/IDeploymentValidator.sol";
import {IERC20Permit, IERC20} from "../../interfaces/IERC20Permit.sol";
import {IWrappedPosition} from "./interfaces/IWrappedPosition.sol";
import {IRollupProcessor} from "../../interfaces/IRollupProcessor.sol";
import {MinHeap} from "./MinHeap.sol";
import {FullMath} from "../uniswapv3/libraries/FullMath.sol";

import {IDefiBridge} from "../../interfaces/IDefiBridge.sol";

import {AztecTypes} from "../../aztec/AztecTypes.sol";

/**
 * @title Element Bridge
 * @dev Smart contract responsible for depositing, managing and redeeming Defi interactions with the Element protocol
 */

contract ElementBridge is IDefiBridge {
    using MinHeap for MinHeap.MinHeapData;

    /*----------------------------------------
      ERROR TAGS
      ----------------------------------------*/
    error INVALID_TRANCHE();
    error INVALID_WRAPPED_POSITION();
    error INVALID_POOL();
    error INVALID_CALLER();
    error ASSET_IDS_NOT_EQUAL();
    error ASSET_NOT_ERC20();
    error INPUT_ASSETB_NOT_UNUSED();
    error OUTPUT_ASSETB_NOT_UNUSED();
    error INTERACTION_ALREADY_EXISTS();
    error POOL_NOT_FOUND();
    error UNKNOWN_NONCE();
    error BRIDGE_NOT_READY();
    error ALREADY_FINALISED();
    error TRANCHE_POSITION_MISMATCH();
    error TRANCHE_UNDERLYING_MISMATCH();
    error POOL_UNDERLYING_MISMATCH();
    error POOL_EXPIRY_MISMATCH();
    error TRANCHE_EXPIRY_MISMATCH();
    error VAULT_ADDRESS_VERIFICATION_FAILED();
    error VAULT_ADDRESS_MISMATCH();
    error TRANCHE_ALREADY_EXPIRED();
    error UNREGISTERED_POOL();
    error UNREGISTERED_POSITION();
    error UNREGISTERED_PAIR();
    error INVALID_TOKEN_BALANCE_RECEIVED();
    error INVALID_CHANGE_IN_BALANCE();
    error RECEIVED_LESS_THAN_LIMIT();

    /*----------------------------------------
      STRUCTS
      ----------------------------------------*/
    /**
     * @dev Contains information that describes a specific interaction
     *
     * @param quantityPT the quantity of element principal tokens that were purchased by this interaction
     * @param trancheAddress the address of the element tranche for which principal tokens were purchased
     * @param expiry the time of expiry of this interaction's tranche
     * @param finalised flag specifying whether this interaction has been finalised
     * @param failed flag specifying whether this interaction failed to be finalised at any point
     */
    struct Interaction {
        uint256 quantityPT;
        address trancheAddress;
        uint64 expiry;
        bool finalised;
        bool failed;
    }

    /**
     * @dev Contains information that describes a specific element pool
     *
     * @param poolId the unique Id associated with the element pool
     * @param trancheAddress the address of the element tranche for which principal tokens are traded in the pool
     * @param poolAddress the address of the pool contract
     * @param wrappedPositionAddress the address of the underlying wrapped position token associated with the pool/tranche
     */
    struct Pool {
        bytes32 poolId;
        address trancheAddress;
        address poolAddress;
        address wrappedPositionAddress;
    }

    enum TrancheRedemptionStatus {
        NOT_REDEEMED,
        REDEMPTION_FAILED,
        REDEMPTION_SUCCEEDED
    }

    /**
     * @dev Contains information for managing all funds deposited/redeemed with a specific element tranche
     *
     * @param quantityTokensHeld total quantity of principal tokens purchased for the tranche
     * @param quantityAssetRedeemed total quantity of underlying tokens received from the element tranche on expiry
     * @param quantityAssetRemaining the current remainning quantity of underlying tokens held by the contract
     * @param numDeposits the total number of deposits (interactions) against the give tranche
     * @param numFinalised the current number of interactions against this tranche that have been finalised
     * @param redemptionStatus value describing the redemption status of the tranche
     */
    struct TrancheAccount {
        uint256 quantityTokensHeld;
        uint256 quantityAssetRedeemed;
        uint256 quantityAssetRemaining;
        uint32 numDeposits;
        uint32 numFinalised;
        TrancheRedemptionStatus redemptionStatus;
    }

    // Tranche factory address for Tranche contract address derivation
    address private immutable trancheFactory;
    // Tranche bytecode hash for Tranche contract address derivation.
    // This is constant as long as Tranche does not implement non-constant constructor arguments.
    bytes32 private immutable trancheBytecodeHash; // = 0xf481a073666136ab1f5e93b296e84df58092065256d0db23b2d22b62c68e978d;

    // cache of all of our Defi interactions. keyed on nonce
    mapping(uint256 => Interaction) public interactions;

    // cahce of all expiry values against the underlying asset address
    mapping(address => uint64[]) public assetToExpirys;

    // cache of all pools we have been configured to interact with
    mapping(uint256 => Pool) public pools;

    // cahce of all of our tranche accounts
    mapping(address => TrancheAccount) private trancheAccounts;

    // mapping containing the block number in which a tranche was configured
    mapping(address => uint256) private trancheDeploymentBlockNumbers;

    // the aztec rollup processor contract
    address public immutable rollupProcessor;

    // the balancer contract
    address private immutable balancerAddress;

    // the address of the element deployment validator contract
    address private immutable elementDeploymentValidatorAddress;

    // data structures used to manage the ongoing interaction deposit/redemption cycle
    MinHeap.MinHeapData private heap;
    mapping(uint64 => uint256[]) private expiryToNonce;

    // 48 hours in seconds, usd for calculating speeedbump expiries
    uint256 internal constant FORTY_EIGHT_HOURS = 172800;

    uint256 internal constant MAX_UINT = type(uint256).max;

    uint256 internal constant MIN_GAS_FOR_CHECK_AND_FINALISE = 40000;
    uint256 internal constant MIN_GAS_FOR_FUNCTION_COMPLETION = 2000;
    uint256 internal constant MIN_GAS_FOR_FAILED_INTERACTION = 20000;
    uint256 internal constant MIN_GAS_FOR_EXPIRY_REMOVAL = 25000;

    // event emitted on every successful convert call
    event LogConvert(uint256 indexed nonce, uint256 totalInputValue, int64 gasUsed);

    // event emitted on every attempt to finalise, successful or otherwise
    event LogFinalise(uint256 indexed nonce, bool success, string message, int64 gasUsed);

    // event emitted on wvery newly configured pool
    event LogPoolAdded(address poolAddress, address wrappedPositionAddress, uint64 expiry);

    /**
     * @dev Constructor
     * @param _rollupProcessor the address of the rollup contract
     * @param _trancheFactory the address of the element tranche factor contract
     * @param _trancheBytecodeHash the hash of the bytecode of the tranche contract, used for tranche contract address derivation
     * @param _balancerVaultAddress the address of the balancer router contract
     * @param _elementDeploymentValidatorAddress the address of the element deployment validator contract
     */
    constructor(
        address _rollupProcessor,
        address _trancheFactory,
        bytes32 _trancheBytecodeHash,
        address _balancerVaultAddress,
        address _elementDeploymentValidatorAddress
    ) {
        rollupProcessor = _rollupProcessor;
        trancheFactory = _trancheFactory;
        trancheBytecodeHash = _trancheBytecodeHash;
        balancerAddress = _balancerVaultAddress;
        elementDeploymentValidatorAddress = _elementDeploymentValidatorAddress;
        heap.initialise(100);
    }

    /**
     * @dev Function for retrieving the available expiries for the given asset
     * @param asset the asset address being queried
     * @return assetExpiries the list of available expiries for the provided asset address
     */
    function getAssetExpiries(address asset) public view returns (uint64[] memory assetExpiries) {
        assetExpiries = assetToExpirys[asset];
    }

    /// @dev Registers a convergent pool with the contract, setting up a new asset/expiry element tranche
    /// @param _convergentPool The pool's address
    /// @param _wrappedPosition The element wrapped position contract's address
    /// @param _expiry The expiry of the tranche being configured
    function registerConvergentPoolAddress(
        address _convergentPool,
        address _wrappedPosition,
        uint64 _expiry
    ) external {
        checkAndStorePoolSpecification(_convergentPool, _wrappedPosition, _expiry);
    }

    /// @dev This internal function produces the deterministic create2
    ///      address of the Tranche contract from a wrapped position contract and expiry
    /// @param position The wrapped position contract address
    /// @param expiry The expiration time of the tranche as a uint256
    /// @return trancheContract derived Tranche contract address
    function deriveTranche(address position, uint256 expiry) internal view virtual returns (address trancheContract) {
        bytes32 salt = keccak256(abi.encodePacked(position, expiry));
        bytes32 addressBytes = keccak256(abi.encodePacked(bytes1(0xff), trancheFactory, salt, trancheBytecodeHash));
        trancheContract = address(uint160(uint256(addressBytes)));
    }

    struct PoolSpec {
        uint256 poolExpiry;
        bytes32 poolId;
        address underlyingAsset;
        address trancheAddress;
        address tranchePosition;
        address trancheUnderlying;
        address poolUnderlying;
        address poolVaultAddress;
    }

    /// @dev Validates and stores a convergent pool specification
    /// @param poolAddress The pool's address
    /// @param wrappedPositionAddress The element wrapped position contract's address
    /// @param expiry The expiry of the tranche being configured
    function checkAndStorePoolSpecification(
        address poolAddress,
        address wrappedPositionAddress,
        uint64 expiry
    ) internal {
        PoolSpec memory poolSpec;
        IWrappedPosition wrappedPosition = IWrappedPosition(wrappedPositionAddress);
        // this underlying asset should be the real asset i.e. DAI stablecoin etc
        try wrappedPosition.token() returns (IERC20 wrappedPositionToken) {
            poolSpec.underlyingAsset = address(wrappedPositionToken);
        } catch {
            revert INVALID_WRAPPED_POSITION();
        }
        // this should be the address of the Element tranche for the asset/expiry pair
        poolSpec.trancheAddress = deriveTranche(wrappedPositionAddress, expiry);
        // get the wrapped position held in the tranche to cross check against that provided
        ITranche tranche = ITranche(poolSpec.trancheAddress);
        try tranche.position() returns (IERC20 tranchePositionToken) {
            poolSpec.tranchePosition = address(tranchePositionToken);
        } catch {
            revert INVALID_TRANCHE();
        }
        // get the underlying held in the tranche to cross check against that provided
        try tranche.underlying() returns (IERC20 trancheUnderlying) {
            poolSpec.trancheUnderlying = address(trancheUnderlying);
        } catch {
            revert INVALID_TRANCHE();
        }
        // get the tranche expiry to cross check against that provided
        uint64 trancheExpiry = 0;
        try tranche.unlockTimestamp() returns (uint256 trancheUnlock) {
            trancheExpiry = uint64(trancheUnlock);
        } catch {
            revert INVALID_TRANCHE();
        }
        if (trancheExpiry != expiry) {
            revert TRANCHE_EXPIRY_MISMATCH();
        }

        if (poolSpec.tranchePosition != wrappedPositionAddress) {
            revert TRANCHE_POSITION_MISMATCH();
        }
        if (poolSpec.trancheUnderlying != poolSpec.underlyingAsset) {
            revert TRANCHE_UNDERLYING_MISMATCH();
        }
        // get the pool underlying to cross check against that provided
        IPool pool = IPool(poolAddress);
        try pool.underlying() returns (IERC20 poolUnderlying) {
            poolSpec.poolUnderlying = address(poolUnderlying);
        } catch {
            revert INVALID_POOL();
        }
        // get the pool expiry to cross check against that provided
        try pool.expiration() returns (uint256 poolExpiry) {
            poolSpec.poolExpiry = poolExpiry;
        } catch {
            revert INVALID_POOL();
        }
        // get the vault associated with the pool
        try pool.getVault() returns (IVault poolVault) {
            poolSpec.poolVaultAddress = address(poolVault);
        } catch {
            revert INVALID_POOL();
        }
        // get the pool id associated with the pool
        try pool.getPoolId() returns (bytes32 poolId) {
            poolSpec.poolId = poolId;
        } catch {
            revert INVALID_POOL();
        }
        if (poolSpec.poolUnderlying != poolSpec.underlyingAsset) {
            revert POOL_UNDERLYING_MISMATCH();
        }
        if (poolSpec.poolExpiry != expiry) {
            revert POOL_EXPIRY_MISMATCH();
        }
        //verify that the vault address is equal to our balancer address
        if (poolSpec.poolVaultAddress != balancerAddress) {
            revert VAULT_ADDRESS_VERIFICATION_FAILED();
        }

        // retrieve the pool address for the given pool id from balancer
        // then test it against that given to us
        IVault balancerVault = IVault(balancerAddress);
        (address balancersPoolAddress, ) = balancerVault.getPool(poolSpec.poolId);
        if (poolAddress != balancersPoolAddress) {
            revert VAULT_ADDRESS_MISMATCH();
        }

        // verify with Element that the provided contracts are registered
        validatePositionAndPoolAddressesWithElementRegistry(wrappedPositionAddress, poolAddress);

        // we store the pool information against a hash of the asset and expiry
        uint256 assetExpiryHash = hashAssetAndExpiry(poolSpec.underlyingAsset, trancheExpiry);
        pools[assetExpiryHash] = Pool(poolSpec.poolId, poolSpec.trancheAddress, poolAddress, wrappedPositionAddress);
        uint64[] storage expiriesForAsset = assetToExpirys[poolSpec.underlyingAsset];
        uint256 expiryIndex = 0;
        while (expiryIndex < expiriesForAsset.length && expiriesForAsset[expiryIndex] != trancheExpiry) {
            unchecked {
                ++expiryIndex;
            }
        }
        if (expiryIndex == expiriesForAsset.length) {
            expiriesForAsset.push(trancheExpiry);
        }
        setTrancheDeploymentBlockNumber(poolSpec.trancheAddress);

        // initialising the expiry -> nonce mapping here like this reduces a chunk of gas later when we start to add interactions for this expiry
        uint256[] storage nonces = expiryToNonce[trancheExpiry];
        if (nonces.length == 0) {
            expiryToNonce[trancheExpiry].push(MAX_UINT);
        }
        emit LogPoolAdded(poolAddress, wrappedPositionAddress, trancheExpiry);
    }

    /**
     * @dev Sets the current block number as the block in which the given tranche was first configured
     * Only stores the block number if this is the first time this tranche has been configured
     * @param trancheAddress the address of the tranche against which to store the current block number
     */
    function setTrancheDeploymentBlockNumber(address trancheAddress) internal {
        uint256 trancheDeploymentBlock = trancheDeploymentBlockNumbers[trancheAddress];
        if (trancheDeploymentBlock == 0) {
            // only set the deployment block on the first time this tranche is configured
            trancheDeploymentBlockNumbers[trancheAddress] = block.number;
        }
    }

    /**
     * @dev Returns the block number in which a tranche was first configured on the bridge based on the nonce of an interaction in that tranche
     * @param interactionNonce the nonce of the interaction to query
     * @return blockNumber the number of the block in which the tranche was first configured
     */
    function getTrancheDeploymentBlockNumber(uint256 interactionNonce) public view returns (uint256 blockNumber) {
        Interaction storage interaction = interactions[interactionNonce];
        if (interaction.expiry == 0) {
            revert UNKNOWN_NONCE();
        }
        blockNumber = trancheDeploymentBlockNumbers[interaction.trancheAddress];
    }

    /**
     * @dev Verifies that the given pool and wrapped position addresses are registered in the Element deployment validator
     * Reverts if addresses don't validate successfully
     * @param wrappedPosition address of a wrapped position contract
     * @param pool address of a balancer pool contract
     */
    function validatePositionAndPoolAddressesWithElementRegistry(address wrappedPosition, address pool) internal {
        IDeploymentValidator validator = IDeploymentValidator(elementDeploymentValidatorAddress);
        if (!validator.checkPoolValidation(pool)) {
            revert UNREGISTERED_POOL();
        }
        if (!validator.checkWPValidation(wrappedPosition)) {
            revert UNREGISTERED_POSITION();
        }
        if (!validator.checkPairValidation(wrappedPosition, pool)) {
            revert UNREGISTERED_PAIR();
        }
    }

    /// @dev Produces a hash of the given asset and expiry value
    /// @param asset The asset address
    /// @param expiry The expiry value
    /// @return hashValue The resulting hash value
    function hashAssetAndExpiry(address asset, uint64 expiry) public pure returns (uint256 hashValue) {
        hashValue = uint256(keccak256(abi.encodePacked(asset, uint256(expiry))));
    }

    struct ConvertArgs {
        address inputAssetAddress;
        uint256 totalInputValue;
        uint256 interactionNonce;
        uint64 auxData;
    }

    /**
     * @dev Function to add a new interaction to the bridge
     * Converts the amount of input asset given to the market determined amount of tranche asset
     * @param inputAssetA The type of input asset for the new interaction
     * @param outputAssetA The type of output asset for the new interaction
     * @param totalInputValue The amount the the input asset provided in this interaction
     * @param interactionNonce The nonce value for this interaction
     * @param auxData The expiry value for this interaction
     * @return outputValueA The interaction's first ouptut value after this call - will be 0
     * @return outputValueB The interaction's second ouptut value after this call - will be 0
     * @return isAsync Flag specifying if this interaction is asynchronous - will be true
     */
    function convert(
        AztecTypes.AztecAsset calldata inputAssetA,
        AztecTypes.AztecAsset calldata inputAssetB,
        AztecTypes.AztecAsset calldata outputAssetA,
        AztecTypes.AztecAsset calldata outputAssetB,
        uint256 totalInputValue,
        uint256 interactionNonce,
        uint64 auxData,
        address
    )
        external
        payable
        override
        returns (
            uint256 outputValueA,
            uint256 outputValueB,
            bool isAsync
        )
    {
        int64 gasAtStart = int64(int256(gasleft()));
        int64 gasUsed = 0;
        // ### INITIALIZATION AND SANITY CHECKS
        if (msg.sender != rollupProcessor) {
            revert INVALID_CALLER();
        }
        if (inputAssetA.id != outputAssetA.id) {
            revert ASSET_IDS_NOT_EQUAL();
        }
        if (inputAssetA.assetType != AztecTypes.AztecAssetType.ERC20) {
            revert ASSET_NOT_ERC20();
        }
        if (inputAssetB.assetType != AztecTypes.AztecAssetType.NOT_USED) {
            revert INPUT_ASSETB_NOT_UNUSED();
        }
        if (outputAssetB.assetType != AztecTypes.AztecAssetType.NOT_USED) {
            revert OUTPUT_ASSETB_NOT_UNUSED();
        }
        if (interactions[interactionNonce].expiry != 0) {
            revert INTERACTION_ALREADY_EXISTS();
        }

        // operation is asynchronous
        isAsync = true;
        outputValueA = 0;
        outputValueB = 0;

        // capture the provided arguments in a struct to prevent 'stack too deep' errors
        ConvertArgs memory convertArgs = ConvertArgs({
            inputAssetAddress: inputAssetA.erc20Address,
            totalInputValue: totalInputValue,
            interactionNonce: interactionNonce,
            auxData: auxData
        });

        // retrieve the appropriate pool for this interaction and verify that it exists
        Pool storage pool = pools[hashAssetAndExpiry(convertArgs.inputAssetAddress, convertArgs.auxData)];
        address trancheAddress = pool.trancheAddress;
        if (trancheAddress == address(0)) {
            revert POOL_NOT_FOUND();
        }
        ITranche tranche = ITranche(trancheAddress);
        uint64 trancheExpiry = uint64(tranche.unlockTimestamp());
        if (block.timestamp >= trancheExpiry) {
            revert TRANCHE_ALREADY_EXPIRED();
        }

        // execute the swap on balancer
        uint256 principalTokensAmount = exchangeAssetForTrancheTokens(
            convertArgs.inputAssetAddress,
            pool,
            convertArgs.totalInputValue
        );
        // store the tranche that underpins our interaction, the expiry and the number of received tokens against the nonce
        Interaction storage newInteraction = interactions[convertArgs.interactionNonce];
        newInteraction.quantityPT = principalTokensAmount;
        newInteraction.trancheAddress = trancheAddress;
        newInteraction.expiry = trancheExpiry;

        // add the nonce and expiry to our expiry heap
        addNonceAndExpiryToNonceMapping(convertArgs.interactionNonce, trancheExpiry);
        // increase our tranche account deposits and holdings
        // other members are left as their initial values (all zeros)
        TrancheAccount storage trancheAccount = trancheAccounts[trancheAddress];
        trancheAccount.quantityTokensHeld += principalTokensAmount;
        unchecked {
            trancheAccount.numDeposits++;
            gasUsed = gasAtStart - int64(int256(gasleft()));
        }
        emit LogConvert(convertArgs.interactionNonce, convertArgs.totalInputValue, gasUsed);
        finaliseExpiredInteractions(MIN_GAS_FOR_FUNCTION_COMPLETION);
        // we need to get here with MIN_GAS_FOR_FUNCTION_COMPLETION gas to exit.
    }

    /**
     * @dev Function to exchange the input asset for tranche tokens on Balancer
     * @param inputAsset the address of the asset we want to swap
     * @param pool storage struct containing details of the pool we wish to use for the swap
     * @param inputQuantity the quantity of the input asset we wish to swap
     * @return quantityReceived amount of tokens recieved
     */
    function exchangeAssetForTrancheTokens(
        address inputAsset,
        Pool storage pool,
        uint256 inputQuantity
    ) internal returns (uint256 quantityReceived) {
        IVault.SingleSwap memory singleSwap = IVault.SingleSwap({
            poolId: pool.poolId, // the id of the pool we want to use
            kind: IVault.SwapKind.GIVEN_IN, // We are exchanging a given number of input tokens
            assetIn: IAsset(inputAsset), // the input asset for the swap
            assetOut: IAsset(pool.trancheAddress), // the tranche token address as the output asset
            amount: inputQuantity, // the total amount of input asset we wish to swap
            userData: "0x00" // set to 0 as per the docs, this is unused in current balancer pools
        });
        IVault.FundManagement memory fundManagement = IVault.FundManagement({
            sender: address(this), // the bridge has already received the tokens from the rollup so it owns totalInputValue of inputAssetA
            fromInternalBalance: false,
            recipient: payable(address(this)), // we want the output tokens transferred back to us
            toInternalBalance: false
        });

        // approve the transfer of tokens to the balancer address
        ERC20(inputAsset).approve(balancerAddress, inputQuantity);

        uint256 trancheTokenQuantityBefore = ERC20(pool.trancheAddress).balanceOf(address(this));
        quantityReceived = IVault(balancerAddress).swap(
            singleSwap,
            fundManagement,
            inputQuantity, // we won't accept less than 1 output token per input token
            block.timestamp
        );

        uint256 trancheTokenQuantityAfter = ERC20(pool.trancheAddress).balanceOf(address(this));
        // ensure we haven't lost tokens!
        if (trancheTokenQuantityAfter < trancheTokenQuantityBefore) {
            revert INVALID_CHANGE_IN_BALANCE();
        }
        // change in balance must be >= 0 here
        uint256 changeInBalance = trancheTokenQuantityAfter - trancheTokenQuantityBefore;
        // ensure the change in balance matches that reported to us
        if (changeInBalance != quantityReceived) {
            revert INVALID_TOKEN_BALANCE_RECEIVED();
        }
        // ensure we received at least the limit we placed
        if (quantityReceived < inputQuantity) {
            revert RECEIVED_LESS_THAN_LIMIT();
        }
    }

    /**
     * @dev Function to attempt finalising of as many interactions as possible within the specified gas limit
     * Continue checking for and finalising interactions until we expend the available gas
     * @param gasFloor The amount of gas that needs to remain after this call has completed
     */
    function finaliseExpiredInteractions(uint256 gasFloor) internal {
        // check and finalise interactions until we don't have enough gas left to reliably update our state without risk of reverting the entire transaction
        // gas left must be enough for check for next expiry, finalise and leave this function without breaching gasFloor
        uint256 gasLoopCondition = MIN_GAS_FOR_CHECK_AND_FINALISE + MIN_GAS_FOR_FUNCTION_COMPLETION + gasFloor;
        uint256 ourGasFloor = MIN_GAS_FOR_FUNCTION_COMPLETION + gasFloor;
        while (gasleft() > gasLoopCondition) {
            // check the heap to see if we can finalise an expired transaction
            // we provide a gas floor to the function which will enable us to leave this function without breaching our gasFloor
            (bool expiryAvailable, uint256 nonce) = checkForNextInteractionToFinalise(ourGasFloor);
            if (!expiryAvailable) {
                break;
            }
            // make sure we will have at least ourGasFloor gas after the finalise in order to exit this function
            uint256 gasRemaining = gasleft();
            if (gasRemaining <= ourGasFloor) {
                break;
            }
            uint256 gasForFinalise = gasRemaining - ourGasFloor;
            // make the call to finalise the interaction with the gas limit
            try IRollupProcessor(rollupProcessor).processAsyncDefiInteraction{gas: gasForFinalise}(nonce) returns (
                bool interactionCompleted
            ) {
                // no need to do anything here, we just need to know that the call didn't throw
            } catch {
                break;
            }
        }
    }

    /**
     * @dev Function to finalise an interaction
     * Converts the held amount of tranche asset for the given interaction into the output asset
     * @param interactionNonce The nonce value for the interaction that should be finalised
     */
    function finalise(
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata outputAssetA,
        AztecTypes.AztecAsset calldata,
        uint256 interactionNonce,
        uint64
    )
        external
        payable
        override
        returns (
            uint256 outputValueA,
            uint256 outputValueB,
            bool interactionCompleted
        )
    {
        int64 gasAtStart = int64(int256(gasleft()));
        int64 gasUsed = 0;
        if (msg.sender != rollupProcessor) {
            revert INVALID_CALLER();
        }
        // retrieve the interaction and verify it's ready for finalising
        Interaction storage interaction = interactions[interactionNonce];
        if (interaction.expiry == 0) {
            revert UNKNOWN_NONCE();
        }
        if (interaction.expiry >= block.timestamp) {
            revert BRIDGE_NOT_READY();
        }
        if (interaction.finalised) {
            revert ALREADY_FINALISED();
        }

        TrancheAccount storage trancheAccount = trancheAccounts[interaction.trancheAddress];
        // cache a couple of frequently used values from the tranche account here
        uint32 numDepositsIntoTranche = trancheAccount.numDeposits;
        uint256 trancheTokensHeld = trancheAccount.quantityTokensHeld;
        if (numDepositsIntoTranche == 0) {
            // shouldn't be possible, this means we have had no deposits against this tranche
            setInteractionAsFailure(interaction, interactionNonce, "NO_DEPOSITS_2", 0);
            popInteractionFromNonceMapping(interaction, interactionNonce);
            return (0, 0, false);
        }

        // we only want to redeem the tranche if it hasn't previously successfully been redeemed
        if (trancheAccount.redemptionStatus != TrancheRedemptionStatus.REDEMPTION_SUCCEEDED) {
            // tranche not redeemed, we need to withdraw the principal
            // convert the tokens back to underlying using the tranche
            ITranche tranche = ITranche(interaction.trancheAddress);
            try tranche.withdrawPrincipal(trancheTokensHeld, address(this)) returns (uint256 valueRedeemed) {
                trancheAccount.quantityAssetRedeemed = valueRedeemed;
                trancheAccount.quantityAssetRemaining = valueRedeemed;
                trancheAccount.redemptionStatus = TrancheRedemptionStatus.REDEMPTION_SUCCEEDED;
            } catch Error(string memory errorMessage) {
                unchecked {
                    gasUsed = gasAtStart - int64(int256(gasleft()));
                }
                setInteractionAsFailure(interaction, interactionNonce, errorMessage, gasUsed);
                trancheAccount.redemptionStatus = TrancheRedemptionStatus.REDEMPTION_FAILED;
                popInteractionFromNonceMapping(interaction, interactionNonce);
                return (0, 0, false);
            } catch {
                unchecked {
                    gasUsed = gasAtStart - int64(int256(gasleft()));
                }
                setInteractionAsFailure(interaction, interactionNonce, "WITHDRAW_ERR", gasUsed);
                trancheAccount.redemptionStatus = TrancheRedemptionStatus.REDEMPTION_FAILED;
                popInteractionFromNonceMapping(interaction, interactionNonce);
                return (0, 0, false);
            }
        }

        // at this point, the tranche must have been redeemed and we can allocate proportionately to this interaction
        uint256 amountToAllocate = 0;
        if (trancheTokensHeld == 0) {
            // what can we do here?
            // we seem to have 0 total principle tokens so we can't apportion the output asset as it must be the case that each interaction purchased 0
            // we know that the number of deposits against this tranche is > 0 as we check further up this function
            // so we will have to divide the output asset, if there is any, equally
            amountToAllocate = trancheAccount.quantityAssetRedeemed / numDepositsIntoTranche;
        } else {
            // apportion the output asset based on the interaction's holding of the principle token
            // protects against phantom overflow in the operation of
            // amountToAllocate = (trancheAccount.quantityAssetRedeemed * interaction.quantityPT) / trancheTokensHeld;
            amountToAllocate = FullMath.mulDiv(
                trancheAccount.quantityAssetRedeemed,
                interaction.quantityPT,
                trancheTokensHeld
            );
        }
        // numDeposits and numFinalised are uint32 types, so easily within range for an int256
        int256 numRemainingInteractionsForTranche = int256(uint256(numDepositsIntoTranche)) -
            int256(uint256(trancheAccount.numFinalised));
        // the number of remaining interactions should never be less than 1 here, but test for <= 1 to ensure we catch all possibilities
        if (numRemainingInteractionsForTranche <= 1 || amountToAllocate > trancheAccount.quantityAssetRemaining) {
            // if there are no more interactions to finalise after this then allocate all the remaining
            // likewise if we have managed to allocate more than the remaining
            amountToAllocate = trancheAccount.quantityAssetRemaining;
        }
        trancheAccount.quantityAssetRemaining -= amountToAllocate;
        unchecked {
            trancheAccount.numFinalised++;
        }

        // approve the transfer of funds back to the rollup contract
        ERC20(outputAssetA.erc20Address).approve(rollupProcessor, amountToAllocate);
        interaction.finalised = true;
        popInteractionFromNonceMapping(interaction, interactionNonce);
        outputValueA = amountToAllocate;
        outputValueB = 0;
        interactionCompleted = true;
        unchecked {
            gasUsed = gasAtStart - int64(int256(gasleft()));
        }
        emit LogFinalise(interactionNonce, interactionCompleted, "", gasUsed);
    }

    /**
     * @dev Function to mark an interaction as having failed and publish a finalise event
     * @param interaction The interaction that failed
     * @param interactionNonce The nonce of the failed interaction
     * @param message The reason for failure
     */
    function setInteractionAsFailure(
        Interaction storage interaction,
        uint256 interactionNonce,
        string memory message,
        int64 gasUsed
    ) internal {
        interaction.failed = true;
        emit LogFinalise(interactionNonce, false, message, gasUsed);
    }

    /**
     * @dev Function to add an interaction nonce and expiry to the heap data structures
     * @param nonce The nonce of the interaction to be added
     * @param expiry The expiry of the interaction to be added
     * @return expiryAdded Flag specifying whether the interactions expiry was added to the heap
     */
    function addNonceAndExpiryToNonceMapping(uint256 nonce, uint64 expiry) internal returns (bool expiryAdded) {
        // get the set of nonces already against this expiry
        // check for the MAX_UINT placeholder nonce that exists to reduce gas costs at this point in the code
        uint256[] storage nonces = expiryToNonce[expiry];
        uint256 noncesLength = nonces.length;
        if (noncesLength == 1 && nonces[0] == MAX_UINT) {
            nonces[0] = nonce;
        } else {
            nonces.push(nonce);
            unchecked {
                noncesLength++;
            }
        }
        // is this the first time this expiry has been requested?
        // if so then add it to our expiry heap
        if (noncesLength == 1) {
            heap.add(expiry);
            expiryAdded = true;
        }
    }

    /**
     * @dev Function to remove an interaction from the heap data structures
     * @param interaction The interaction should be removed
     * @param interactionNonce The nonce of the interaction to be removed
     * @return expiryRemoved Flag specifying whether the interactions expiry was removed from the heap
     */
    function popInteractionFromNonceMapping(Interaction storage interaction, uint256 interactionNonce)
        internal
        returns (bool expiryRemoved)
    {
        uint64 expiry = interaction.expiry;
        uint256[] storage nonces = expiryToNonce[expiry];
        uint256 noncesLength = nonces.length;
        if (noncesLength == 0) {
            return false;
        }
        uint256 index = noncesLength - 1;
        while (index > 0 && nonces[index] != interactionNonce) {
            unchecked {
                --index;
            }
        }
        if (nonces[index] != interactionNonce) {
            return false;
        }
        if (index != noncesLength - 1) {
            nonces[index] = nonces[noncesLength - 1];
        }
        nonces.pop();

        // if there are no more nonces left for this expiry then remove it from the heap
        // checking if length == 1 to account for the pop.
        if (noncesLength == 1) {
            heap.remove(expiry);
            delete expiryToNonce[expiry];
            return true;
        }
        return false;
    }

    /**
     * @dev Function to determine if we are able to finalise an interaction
     * @param gasFloor The amount of gas that needs to remain after this call has completed
     * @return expiryAvailable Flag specifying whether an expiry is available to be finalised
     * @return nonce The next interaction nonce to be finalised
     */
    function checkForNextInteractionToFinalise(uint256 gasFloor)
        internal
        returns (bool expiryAvailable, uint256 nonce)
    {
        // do we have any expiries and if so is the earliest expiry now expired
        if (heap.size() == 0) {
            return (false, 0);
        }
        // retrieve the minimum (oldest) expiry and determine if it is in the past
        uint64 nextExpiry = heap.min();
        if (nextExpiry >= block.timestamp) {
            // oldest expiry is still not expired
            return (false, 0);
        }
        // we have some expired interactions
        uint256[] storage nonces = expiryToNonce[nextExpiry];
        uint256 noncesLength = nonces.length;
        uint256 minGasForLoop = (gasFloor + MIN_GAS_FOR_FAILED_INTERACTION);
        while (noncesLength > 0 && gasleft() >= minGasForLoop) {
            uint256 nextNonce = nonces[noncesLength - 1];
            if (nextNonce == MAX_UINT) {
                // this shouldn't happen, this value is the placeholder for reducing gas costs on convert
                // we just need to pop and continue
                nonces.pop();
                unchecked {
                    noncesLength--;
                }
                continue;
            }
            Interaction storage interaction = interactions[nextNonce];
            if (interaction.expiry == 0 || interaction.finalised || interaction.failed) {
                // this shouldn't happen, suggests the interaction has been finalised already but not removed from the sets of nonces for this expiry
                // remove the nonce and continue searching
                nonces.pop();
                unchecked {
                    noncesLength--;
                }
                continue;
            }
            // we have valid interaction for the next expiry, check if it can be finalised
            (bool canBeFinalised, string memory message) = interactionCanBeFinalised(interaction);
            if (!canBeFinalised) {
                // can't be finalised, add to failures and pop from nonces
                setInteractionAsFailure(interaction, nextNonce, message, 0);
                nonces.pop();
                unchecked {
                    noncesLength--;
                }
                continue;
            }
            return (true, nextNonce);
        }

        // if we don't have enough gas to remove the expiry, it will be removed next time
        if (noncesLength == 0 && gasleft() >= (gasFloor + MIN_GAS_FOR_EXPIRY_REMOVAL)) {
            // if we are here then we have run out of nonces for this expiry so pop from the heap
            heap.remove(nextExpiry);
        }
        return (false, 0);
    }

    /**
     * @dev Determine if an interaction can be finalised
     * Performs a variety of check on the tranche and tranche account to determine
     * a. if the tranche has already been redeemed
     * b. if the tranche is currently under a speedbump
     * c. if the yearn vault has sufficient balance to support tranche redemption
     * @param interaction The interaction to be finalised
     * @return canBeFinalised Flag specifying whether the interaction can be finalised
     * @return message Message value giving the reason why an interaction can't be finalised
     */
    function interactionCanBeFinalised(Interaction storage interaction)
        internal
        returns (bool canBeFinalised, string memory message)
    {
        TrancheAccount storage trancheAccount = trancheAccounts[interaction.trancheAddress];
        if (trancheAccount.numDeposits == 0) {
            // shouldn't happen, suggests we don't have an account for this tranche!
            return (false, "NO_DEPOSITS_1");
        }
        if (trancheAccount.redemptionStatus == TrancheRedemptionStatus.REDEMPTION_FAILED) {
            return (false, "REDEMPTION_FAILED");
        }
        // determine if the tranche has already been redeemed
        if (trancheAccount.redemptionStatus == TrancheRedemptionStatus.REDEMPTION_SUCCEEDED) {
            // tranche was previously redeemed
            if (trancheAccount.quantityAssetRemaining == 0) {
                // this is a problem. we have already allocated out all of the redeemed assets!
                return (false, "FULLY_ALLOCATED");
            }
            // this interaction can be finalised. we don't need to redeem the tranche, we just need to allocate the redeemed asset
            return (true, "");
        }
        // tranche hasn't been redeemed, now check to see if we can redeem it
        ITranche tranche = ITranche(interaction.trancheAddress);
        uint256 speedbump = tranche.speedbump();
        if (speedbump != 0) {
            uint256 newExpiry = speedbump + FORTY_EIGHT_HOURS;
            if (newExpiry > block.timestamp) {
                // a speedbump is in force for this tranche and it is beyond the current time
                trancheAccount.redemptionStatus = TrancheRedemptionStatus.REDEMPTION_FAILED;
                return (false, "SPEEDBUMP");
            }
        }
        address wpAddress = address(tranche.position());
        IWrappedPosition wrappedPosition = IWrappedPosition(wpAddress);
        address underlyingAddress = address(wrappedPosition.token());
        address yearnVaultAddress = address(wrappedPosition.vault());
        uint256 vaultQuantity = ERC20(underlyingAddress).balanceOf(yearnVaultAddress);
        if (trancheAccount.quantityTokensHeld > vaultQuantity) {
            trancheAccount.redemptionStatus = TrancheRedemptionStatus.REDEMPTION_FAILED;
            return (false, "VAULT_BALANCE");
        }
        // at this point, we will need to redeem the tranche which should be possible
        return (true, "");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
    constructor(string memory name_, string memory symbol_) {
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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity <=0.8.10;
pragma abicoder v2;

import {IERC20} from "./IERC20Permit.sol";

interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

enum PoolSpecialization {
    GENERAL,
    MINIMAL_SWAP_INFO,
    TWO_TOKEN
}

interface IVault {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    /**
     * @dev Performs a swap with a single Pool.
     *
     * If the swap is 'given in' (the number of tokens to send to the Pool is known), it returns the amount of tokens
     * taken from the Pool, which must be greater than or equal to `limit`.
     *
     * If the swap is 'given out' (the number of tokens to take from the Pool is known), it returns the amount of tokens
     * sent to the Pool, which must be less than or equal to `limit`.
     *
     * Internal Balance usage and the recipient are determined by the `funds` struct.
     *
     * Emits a `Swap` event.
     */
    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    /**
     * @dev Data for a single swap executed by `swap`. `amount` is either `amountIn` or `amountOut` depending on
     * the `kind` value.
     *
     * `assetIn` and `assetOut` are either token addresses, or the IAsset sentinel value for ETH (the zero address).
     * Note that Pools never interact with ETH directly: it will be wrapped to or unwrapped from WETH by the Vault.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
     * `recipient` account.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
     * transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
     * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
     * `joinPool`.
     *
     * If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
     * transferred. This matches the behavior of `exitPool`.
     *
     * Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
     * revert.
     */
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    // will revert if poolId is not a registered pool
    function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);

    /**
     * @dev Simulates a call to `batchSwap`, returning an array of Vault asset deltas. Calls to `swap` cannot be
     * simulated directly, but an equivalent `batchSwap` call can and will yield the exact same result.
     *
     * Each element in the array corresponds to the asset at the same index, and indicates the number of tokens (or ETH)
     * the Vault would take from the sender (if positive) or send to the recipient (if negative). The arguments it
     * receives are the same that an equivalent `batchSwap` call would receive.
     *
     * Unlike `batchSwap`, this function performs no checks on the sender or recipient field in the `funds` struct.
     * This makes it suitable to be called by off-chain applications via eth_call without needing to hold tokens,
     * approve them for the Vault, or even know a user's address.
     *
     * Note that this function is not 'view' (due to implementation details): the client code must explicitly execute
     * eth_call instead of eth_sendTransaction.
     */

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds
    ) external view returns (int256[] memory assetDeltas);

    /**
     * @dev Returns a Pool's registered tokens, the total balance for each, and the latest block when *any* of
     * the tokens' `balances` changed.
     *
     * The order of the `tokens` array is the same order that will be used in `joinPool`, `exitPool`, as well as in all
     * Pool hooks (where applicable). Calls to `registerTokens` and `deregisterTokens` may change this order.
     *
     * If a Pool only registers tokens once, and these are sorted in ascending order, they will be stored in the same
     * order as passed to `registerTokens`.
     *
     * Total balances include both tokens held by the Vault and those withdrawn by the Pool's Asset Managers. These are
     * the amounts used by joins, exits and swaps. For a detailed breakdown of token balances, use `getPoolTokenInfo`
     * instead.
     */
    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            IERC20[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import {IERC20Permit, IERC20} from "./IERC20Permit.sol";
import {IVault} from "./IVault.sol";

interface IPool is IERC20Permit {
    /// @dev Returns the poolId for this pool
    /// @return The poolId for this pool
    function getPoolId() external view returns (bytes32);

    function underlying() external view returns (IERC20);

    function expiration() external view returns (uint256);

    function getVault() external view returns (IVault);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.6.10 <=0.8.10;

import "./IERC20Permit.sol";

interface ITranche is IERC20Permit {
    function deposit(uint256 _shares, address destination) external returns (uint256, uint256);

    function prefundedDeposit(address _destination) external returns (uint256, uint256);

    function withdrawPrincipal(uint256 _amount, address _destination) external returns (uint256);

    function withdrawInterest(uint256 _amount, address _destination) external returns (uint256);

    function interestSupply() external view returns (uint128);

    function position() external view returns (IERC20);

    function underlying() external view returns (IERC20);

    function speedbump() external view returns (uint256);

    function unlockTimestamp() external view returns (uint256);

    function hitSpeedbump() external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IDeploymentValidator {
    function validateWPAddress(address wrappedPosition) external;

    function validatePoolAddress(address pool) external;

    function validateAddresses(address wrappedPosition, address pool) external;

    function checkWPValidation(address wrappedPosition) external view returns (bool);

    function checkPoolValidation(address pool) external view returns (bool);

    function checkPairValidation(address wrappedPosition, address pool) external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-only
// Copyright 2022 Spilsbury Holdings Ltd
pragma solidity >=0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Permit is IERC20 {
    function nonces(address user) external view returns (uint256);

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IERC20Permit.sol";

interface IWrappedPosition is IERC20Permit {
    function token() external view returns (IERC20);

    function vault() external view returns (address);

    function balanceOfUnderlying(address who) external view returns (uint256);

    function getSharesToUnderlying(uint256 shares) external view returns (uint256);

    function deposit(address sender, uint256 amount) external returns (uint256);

    function withdraw(
        address sender,
        uint256 _shares,
        uint256 _minUnderlying
    ) external returns (uint256);

    function withdrawUnderlying(
        address _destination,
        uint256 _amount,
        uint256 _minUnderlying
    ) external returns (uint256, uint256);

    function prefundedDeposit(address _destination)
        external
        returns (
            uint256,
            uint256,
            uint256
        );
}

// SPDX-License-Identifier: GPL-2.0-only
// Copyright 2022 Spilsbury Holdings Ltd
pragma solidity >=0.8.4;

interface IRollupProcessor {
    function defiBridgeProxy() external view returns (address);

    function processRollup(
        bytes calldata proofData,
        bytes calldata signatures,
        bytes calldata offchainTxData
    ) external;

    function depositPendingFunds(
        uint256 assetId,
        uint256 amount,
        address owner,
        bytes32 proofHash
    ) external payable;

    function depositPendingFundsPermit(
        uint256 assetId,
        uint256 amount,
        address owner,
        bytes32 proofHash,
        address spender,
        uint256 permitApprovalAmount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function receiveEthFromBridge(uint256 interactionNonce) external payable;

    function setRollupProvider(address provderAddress, bool valid) external;

    function approveProof(bytes32 _proofHash) external;

    function pause() external;

    function setDefiBridgeProxy(address feeDistributorAddress) external;

    function setVerifier(address verifierAddress) external;

    function setSupportedAsset(
        address linkedToken,
        bool supportsPermit,
        uint256 gasLimit
    ) external;

    function setAssetPermitSupport(uint256 assetId, bool supportsPermit) external;

    function setSupportedBridge(address linkedBridge, uint256 gasLimit) external;

    function getSupportedAsset(uint256 assetId) external view returns (address);

    function getSupportedAssets() external view returns (address[] memory);

    function getSupportedBridge(uint256 bridgeAddressId) external view returns (address);

    function getBridgeGasLimit(uint256 bridgeAddressId) external view returns (uint256);

    function getSupportedBridges() external view returns (address[] memory);

    function getAssetPermitSupport(uint256 assetId) external view returns (bool);

    function getEscapeHatchStatus() external view returns (bool, uint256);

    function getUserPendingDeposit(uint256 assetId, address userAddress) external view returns (uint256);

    function processAsyncDefiInteraction(uint256 interactionNonce) external returns (bool);

    function getDefiInteractionBlockNumber(uint256 interactionNonce) external view returns (uint256);

    event DefiBridgeProcessed(
        uint256 indexed bridgeId,
        uint256 indexed nonce,
        uint256 totalInputValue,
        uint256 totalOutputValueA,
        uint256 totalOutputValueB,
        bool result
    );
    event AsyncDefiBridgeProcessed(
        uint256 indexed bridgeId,
        uint256 indexed nonce,
        uint256 totalInputValue,
        uint256 totalOutputValueA,
        uint256 totalOutputValueB,
        bool result
    );
}

pragma solidity 0.8.10;

/**
 * @title Min Heap
 * @dev Library for managing an array of uint64 values as a minimum heap
 */
library MinHeap {
    using MinHeap for MinHeapData;

    error HEAP_EMPTY();

    /**
     * @dev Encapsulates the underlying data structure used to manage the heap
     *
     * @param heap the array of values contained within the heap
     * @param heapSize the current size of the heap, usually different to the size of underlying array so tracked seperately
     */
    struct MinHeapData {
        uint32 heapSize;
        uint64[] heap;
    }

    /**
     * @dev used to pre-allocate the underlying array with dummy values
     * Useful for gas optimisation later when tru value start to be added
     * @param self reference to the underlying data structure of the heap
     * @param initialSize the amount of slots to pre-allocate
     */
    function initialise(MinHeapData storage self, uint32 initialSize) internal {
        uint256 i = 0;
        unchecked {
            while (i < initialSize) {
                self.heap.push(type(uint64).max);
                i++;
            }
            self.heapSize = 0;
        }
    }

    /**
     * @dev used to add a new value to the heap
     * @param self reference to the underlying data structure of the heap
     * @param value the value to add
     */
    function add(MinHeapData storage self, uint64 value) internal {
        uint32 hSize = self.heapSize;
        if (hSize == self.heap.length) {
            self.heap.push(value);
        } else {
            self.heap[hSize] = value;
        }
        unchecked {
            self.heapSize = hSize + 1;
        }
        siftUp(self, hSize);
    }

    /**
     * @dev retrieve the current minimum value in the heap
     * @param self reference to the underlying data structure of the heap
     * @return minimum the heap's current minimum value
     */
    function min(MinHeapData storage self) internal view returns (uint64 minimum) {
        if (self.heapSize == 0) {
            revert HEAP_EMPTY();
        }
        minimum = self.heap[0];
    }

    /**
     * @dev used to remove a value from the heap
     * will remove the first found occurence of the value from the heap, optimised for removal of the minimum value
     * @param self reference to the underlying data structure of the heap
     * @param value the value to be removed
     */
    function remove(MinHeapData storage self, uint64 value) internal {
        uint256 index = 0;
        uint32 hSize = self.heapSize;
        while (index < hSize && self.heap[index] != value) {
            unchecked {
                ++index;
            }
        }
        if (index == hSize) {
            return;
        }
        if (index != 0) {
            // the value was found but it is not the minimum value
            // to remove this we set it's value to 0 and sift it up to it's new position
            self.heap[index] = 0;
            siftUp(self, index);
        }
        // now we just need to pop the minimum value
        pop(self);
    }

    /**
     * @dev used to remove the minimum value from the heap
     * @param self reference to the underlying data structure of the heap
     */
    function pop(MinHeapData storage self) internal {
        // if the heap is empty then nothing to do
        uint32 hSize = self.heapSize;
        if (hSize == 0) {
            return;
        }
        // read the value in the last position and shrink the array by 1
        uint64 last = self.heap[--hSize];
        // now sift down
        // write the smallest child value into the parent each time
        // then once we no longer have any smaller children, we write the 'last' value into place
        // requires a total of O(logN) updates
        uint256 index = 0;
        uint256 leftChildIndex;
        uint256 rightChildIndex;
        while (index < hSize) {
            // get the indices of the child values
            unchecked {
                leftChildIndex = (index << 1) + 1; // as long as hSize is not gigantic, we are fine.
                rightChildIndex = leftChildIndex + 1;
            }
            uint256 swapIndex = index;
            uint64 smallestValue = last;
            uint64 leftChild; // Used only for cache

            // identify the smallest child, first check the left
            if (leftChildIndex < hSize && (leftChild = self.heap[leftChildIndex]) < smallestValue) {
                swapIndex = leftChildIndex;
                smallestValue = leftChild;
            }
            // then check the right
            if (rightChildIndex < hSize && self.heap[rightChildIndex] < smallestValue) {
                swapIndex = rightChildIndex;
            }
            // if neither child was smaller then nothing more to do
            if (swapIndex == index) {
                self.heap[index] = smallestValue;
                break;
            }
            // take the value from the smallest child and write in into our slot
            self.heap[index] = self.heap[swapIndex];
            index = swapIndex;
        }
        self.heapSize = hSize;
    }

    /**
     * @dev retrieve the current size of the heap
     * @param self reference to the underlying data structure of the heap
     * @return currentSize the heap's current size
     */
    function size(MinHeapData storage self) internal view returns (uint256 currentSize) {
        currentSize = self.heapSize;
    }

    /**
     * @dev move the value at the given index up to the correct position in the heap
     * @param self reference to the underlying data structure of the heap
     * @param index the index of the element that is to be correctly positioned
     */
    function siftUp(MinHeapData storage self, uint256 index) private {
        uint64 value = self.heap[index];
        uint256 parentIndex;
        while (index > 0) {
            uint64 parent;
            unchecked {
                parentIndex = (index - 1) >> 1;
            }
            if ((parent = self.heap[parentIndex]) <= value) {
                break;
            }
            self.heap[index] = parent; // update
            index = parentIndex;
        }
        self.heap[index] = value;
    }
}

// SPDX-License-Identifier: MIT
//pragma solidity >=0.4.0 <0.8.0;

pragma solidity >=0.6.10 <=0.8.10;

///note: @dev of Aztec Connect Uniswap V3 Bridge for LP. This library has been modified to conform to version 0.8.x of solidity.
///the first change is on line 74, which was originally a unary negation of an unsigned integer like thus:
///uint256 twos = -denominator & denominator;
/// unary negation on unsigned integers has been disallowed in solidity versions 0.8.x
///the fix for this is to change line 74 from uint256 twos = -denominator & denominator; to uint256 twos = (type(uint256).max - denominator + 1 ) & denominator;
///see https://docs.soliditylang.org/en/v0.8.11/080-breaking-changes.html
///the second change is the introduction of an unchecked block starting on line 70
///the code within this block relies on integer wraparound
/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        unchecked {
            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (type(uint256).max - denominator + 1) & denominator; //this line has been modified from the original Uniswap V3 library
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
        }

        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-only
// Copyright 2022 Spilsbury Holdings Ltd
pragma solidity >=0.8.4;

import {AztecTypes} from "../aztec/AztecTypes.sol";

interface IDefiBridge {
    /**
     * Input cases:
     * Case1: 1 real input.
     * Case2: 1 virtual asset input.
     * Case3: 1 real 1 virtual input.
     *
     * Output cases:
     * Case1: 1 real
     * Case2: 2 real
     * Case3: 1 real 1 virtual
     * Case4: 1 virtual
     *
     * Example use cases with asset mappings
     * 1 1: Swapping.
     * 1 2: Swapping with incentives (2nd output reward token).
     * 1 3: Borrowing. Lock up collateral, get back loan asset and virtual position asset.
     * 1 4: Opening lending position OR Purchasing NFT. Input real asset, get back virtual asset representing NFT or position.
     * 2 1: Selling NFT. Input the virtual asset, get back a real asset.
     * 2 2: Closing a lending position. Get back original asset and reward asset.
     * 2 3: Claiming fees from an open position.
     * 2 4: Voting on a 1 4 case.
     * 3 1: Repaying a borrow. Return loan plus interest. Get collateral back.
     * 3 2: Repaying a borrow. Return loan plus interest. Get collateral plus reward token. (AAVE)
     * 3 3: Partial loan repayment.
     * 3 4: DAO voting stuff.
     */

    // @dev This function is called from the RollupProcessor.sol contract via the DefiBridgeProxy. It receives the aggregate sum of all users funds for the input assets.
    // @param AztecAsset inputAssetA a struct detailing the first input asset, this will always be set
    // @param AztecAsset inputAssetB an optional struct detailing the second input asset, this is used for repaying borrows and should be virtual
    // @param AztecAsset outputAssetA a struct detailing the first output asset, this will always be set
    // @param AztecAsset outputAssetB a struct detailing an optional second output asset
    // @param uint256 inputValue, the total amount input, if there are two input assets, equal amounts of both assets will have been input
    // @param uint256 interactionNonce a globally unique identifier for this DeFi interaction. This is used as the assetId if one of the output assets is virtual
    // @param uint64 auxData other data to be passed into the bridge contract (slippage / nftID etc)
    // @return uint256 outputValueA the amount of outputAssetA returned from this interaction, should be 0 if async
    // @return uint256 outputValueB the amount of outputAssetB returned from this interaction, should be 0 if async or bridge only returns 1 asset.
    // @return bool isAsync a flag to toggle if this bridge interaction will return assets at a later date after some third party contract has interacted with it via finalise()
    function convert(
        AztecTypes.AztecAsset calldata inputAssetA,
        AztecTypes.AztecAsset calldata inputAssetB,
        AztecTypes.AztecAsset calldata outputAssetA,
        AztecTypes.AztecAsset calldata outputAssetB,
        uint256 inputValue,
        uint256 interactionNonce,
        uint64 auxData,
        address rollupBeneficiary
    )
        external
        payable
        virtual
        returns (
            uint256 outputValueA,
            uint256 outputValueB,
            bool isAsync
        );

    // @dev This function is called from the RollupProcessor.sol contract via the DefiBridgeProxy. It receives the aggregate sum of all users funds for the input assets.
    // @param AztecAsset inputAssetA a struct detailing the first input asset, this will always be set
    // @param AztecAsset inputAssetB an optional struct detailing the second input asset, this is used for repaying borrows and should be virtual
    // @param AztecAsset outputAssetA a struct detailing the first output asset, this will always be set
    // @param AztecAsset outputAssetB a struct detailing an optional second output asset
    // @param uint256 interactionNonce
    // @param uint64 auxData other data to be passed into the bridge contract (slippage / nftID etc)
    // @return uint256 outputValueA the return value of output asset A
    // @return uint256 outputValueB optional return value of output asset B
    // @dev this function should have a modifier on it to ensure it can only be called by the Rollup Contract
    function finalise(
        AztecTypes.AztecAsset calldata inputAssetA,
        AztecTypes.AztecAsset calldata inputAssetB,
        AztecTypes.AztecAsset calldata outputAssetA,
        AztecTypes.AztecAsset calldata outputAssetB,
        uint256 interactionNonce,
        uint64 auxData
    )
        external
        payable
        virtual
        returns (
            uint256 outputValueA,
            uint256 outputValueB,
            bool interactionComplete
        );
}

// SPDX-License-Identifier: GPL-2.0-only
// Copyright 2020 Spilsbury Holdings Ltd

pragma solidity >=0.6.10 <=0.8.10;
pragma experimental ABIEncoderV2;

library AztecTypes {
    enum AztecAssetType {
        NOT_USED,
        ETH,
        ERC20,
        VIRTUAL
    }

    struct AztecAsset {
        uint256 id;
        address erc20Address;
        AztecAssetType assetType;
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

// SPDX-License-Identifier: GPL-2.0-only
// Copyright 2020 Spilsbury Holdings Ltd
pragma solidity >=0.6.10 <=0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Permit is IERC20 {
    function nonces(address user) external view returns (uint256);

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