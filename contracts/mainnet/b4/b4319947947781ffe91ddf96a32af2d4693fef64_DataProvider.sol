// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec.
pragma solidity >=0.8.4;
import {AztecTypes} from "./libraries/AztecTypes.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IRollupProcessor} from "./interfaces/IRollupProcessor.sol";
import {BridgeBase} from "../bridges/base/BridgeBase.sol";
import {ISubsidy} from "./interfaces/ISubsidy.sol";

/**
 * @notice Helper used for mapping assets and bridges to more meaningful naming
 * @author Aztec Team
 */
contract DataProvider is Ownable {
    struct BridgeData {
        address bridgeAddress;
        uint256 bridgeAddressId;
        string label;
    }

    struct AssetData {
        address assetAddress;
        uint256 assetId;
        string label;
    }

    struct Bridges {
        mapping(uint256 => BridgeData) data;
        mapping(bytes32 => uint256) tagToId;
    }

    struct Assets {
        mapping(uint256 => AssetData) data;
        mapping(bytes32 => uint256) tagToId;
    }

    uint256 private constant INPUT_ASSET_ID_A_SHIFT = 32;
    uint256 private constant INPUT_ASSET_ID_B_SHIFT = 62;
    uint256 private constant OUTPUT_ASSET_ID_A_SHIFT = 92;
    uint256 private constant OUTPUT_ASSET_ID_B_SHIFT = 122;
    uint256 private constant BITCONFIG_SHIFT = 152;
    uint256 private constant AUX_DATA_SHIFT = 184;
    uint256 private constant VIRTUAL_ASSET_ID_FLAG_SHIFT = 29;
    uint256 private constant VIRTUAL_ASSET_ID_FLAG = 0x20000000; // 2 ** 29
    uint256 private constant MASK_THIRTY_TWO_BITS = 0xffffffff;
    uint256 private constant MASK_THIRTY_BITS = 0x3fffffff;
    uint256 private constant MASK_SIXTY_FOUR_BITS = 0xffffffffffffffff;

    ISubsidy public constant SUBSIDY = ISubsidy(0xABc30E831B5Cc173A9Ed5941714A7845c909e7fA);
    IRollupProcessor public immutable ROLLUP_PROCESSOR;
    Bridges internal bridges;
    Assets internal assets;

    constructor(address _rollupProcessor) {
        ROLLUP_PROCESSOR = IRollupProcessor(_rollupProcessor);
    }

    /**
     * @notice Adds a bridge with a specific tag
     * @dev Only callable by the owner
     * @param _bridgeAddressId The bridge address id for the bridge to list
     * @param _tag The tag to list with the bridge
     */
    function addBridge(uint256 _bridgeAddressId, string memory _tag) public onlyOwner {
        address bridgeAddress = ROLLUP_PROCESSOR.getSupportedBridge(_bridgeAddressId);
        bytes32 digest = keccak256(abi.encode(_tag));
        bridges.tagToId[digest] = _bridgeAddressId;
        bridges.data[_bridgeAddressId] = BridgeData({
            bridgeAddress: bridgeAddress,
            bridgeAddressId: _bridgeAddressId,
            label: _tag
        });
    }

    /**
     * @notice Adds an asset with a specific tag
     * @dev Only callable by the owner
     * @param _assetId The asset id of the asset to list
     * @param _tag The tag to list with the asset
     */
    function addAsset(uint256 _assetId, string memory _tag) public onlyOwner {
        address assetAddress = ROLLUP_PROCESSOR.getSupportedAsset(_assetId);
        bytes32 digest = keccak256(abi.encode(_tag));
        assets.tagToId[digest] = _assetId;
        assets.data[_assetId] = AssetData({assetAddress: assetAddress, assetId: _assetId, label: _tag});
    }

    /**
     * @notice Adds multiple bridges with specific tags
     * @dev Indirectly only callable by the owner
     * @param _assetIds List of asset Ids
     * @param _assetTags List of tags to be used for the asset ids
     * @param _bridgeAddressIds The list of bridge address ids
     * @param _bridgeTags List of tags to be used for the bridges
     */
    function addAssetsAndBridges(
        uint256[] memory _assetIds,
        string[] memory _assetTags,
        uint256[] memory _bridgeAddressIds,
        string[] memory _bridgeTags
    ) public {
        if (_assetIds.length != _assetTags.length || _bridgeAddressIds.length != _bridgeTags.length) {
            revert("Invalid input lengths");
        }
        for (uint256 i = 0; i < _assetTags.length; i++) {
            addAsset(_assetIds[i], _assetTags[i]);
        }
        for (uint256 i = 0; i < _bridgeTags.length; i++) {
            addBridge(_bridgeAddressIds[i], _bridgeTags[i]);
        }
    }

    /**
     * @notice Fetch the `BridgeData` related to a specific bridgeAddressId
     * @param _bridgeAddressId The bridge address id of the bridge to fetch
     * @return The BridgeData data structure for the given bridge
     */
    function getBridge(uint256 _bridgeAddressId) public view returns (BridgeData memory) {
        return bridges.data[_bridgeAddressId];
    }

    /**
     * @notice Fetch the `BridgeData` related to a specific tag
     * @param _tag The tag of the bridge to fetch
     * @return The BridgeData data structure for the given bridge
     */
    function getBridge(string memory _tag) public view returns (BridgeData memory) {
        return bridges.data[bridges.tagToId[keccak256(abi.encode(_tag))]];
    }

    /**
     * @notice Fetch the `AssetData` related to a specific assetId
     * @param _assetId The asset id of the asset to fetch
     * @return The AssetData data structure for the given asset
     */
    function getAsset(uint256 _assetId) public view returns (AssetData memory) {
        return assets.data[_assetId];
    }

    /**
     * @notice Fetch the `AssetData` related to a specific tag
     * @param _tag The tag of the asset to fetch
     * @return The AssetData data structure for the given asset
     */
    function getAsset(string memory _tag) public view returns (AssetData memory) {
        return assets.data[assets.tagToId[keccak256(abi.encode(_tag))]];
    }

    /**
     * @notice Fetch `AssetData` for all supported assets
     * @return A list of AssetData data structures, one for every asset
     */
    function getAssets() public view returns (AssetData[] memory) {
        uint256 assetCount = ROLLUP_PROCESSOR.getSupportedAssetsLength();
        AssetData[] memory assetDatas = new AssetData[](assetCount);
        for (uint256 i = 0; i < assetCount; i++) {
            assetDatas[i] = getAsset(i);
        }
        return assetDatas;
    }

    /**
     * @notice Fetch `BridgeData` for all supported bridges
     * @return A list of BridgeData data structures, one for every bridge
     */
    function getBridges() public view returns (BridgeData[] memory) {
        uint256 bridgeCount = ROLLUP_PROCESSOR.getSupportedBridgesLength();
        BridgeData[] memory bridgeDatas = new BridgeData[](bridgeCount);
        for (uint256 i = 1; i <= bridgeCount; i++) {
            bridgeDatas[i - 1] = getBridge(i);
        }
        return bridgeDatas;
    }

    /**
     * @notice Fetches the subsidy that can be claimed by the specific call, if it is the next performed.
     * @param _bridgeCallData The bridge call data for a specific bridge interaction
     * @return The amount of eth claimed at the current gas prices
     */
    function getAccumulatedSubsidyAmount(uint256 _bridgeCallData) public view returns (uint256) {
        uint256 bridgeAddressId = _bridgeCallData & MASK_THIRTY_TWO_BITS;
        address bridgeAddress = ROLLUP_PROCESSOR.getSupportedBridge(bridgeAddressId);

        uint256 inputAId = (_bridgeCallData >> INPUT_ASSET_ID_A_SHIFT) & MASK_THIRTY_BITS;
        uint256 inputBId = (_bridgeCallData >> INPUT_ASSET_ID_B_SHIFT) & MASK_THIRTY_BITS;
        uint256 outputAId = (_bridgeCallData >> OUTPUT_ASSET_ID_A_SHIFT) & MASK_THIRTY_BITS;
        uint256 outputBId = (_bridgeCallData >> OUTPUT_ASSET_ID_B_SHIFT) & MASK_THIRTY_BITS;
        uint256 bitconfig = (_bridgeCallData >> BITCONFIG_SHIFT) & MASK_THIRTY_TWO_BITS;
        uint256 auxData = (_bridgeCallData >> AUX_DATA_SHIFT) & MASK_SIXTY_FOUR_BITS;

        AztecTypes.AztecAsset memory inputA = _aztecAsset(inputAId);
        AztecTypes.AztecAsset memory inputB;
        if (bitconfig & 1 == 1) {
            inputB = _aztecAsset(inputBId);
        }

        AztecTypes.AztecAsset memory outputA = _aztecAsset(outputAId);
        AztecTypes.AztecAsset memory outputB;

        if (bitconfig & 2 == 2) {
            outputB = _aztecAsset(outputBId);
        }

        (bool success, bytes memory returnData) = bridgeAddress.staticcall(
            abi.encodeWithSelector(
                BridgeBase.computeCriteria.selector,
                inputA,
                inputB,
                outputA,
                outputB,
                uint64(auxData)
            )
        );

        if (!success) {
            return 0;
        }

        uint256 criteria = abi.decode(returnData, (uint256));

        return SUBSIDY.getAccumulatedSubsidyAmount(bridgeAddress, criteria);
    }

    function _aztecAsset(uint256 _assetId) internal view returns (AztecTypes.AztecAsset memory) {
        if (_assetId >= VIRTUAL_ASSET_ID_FLAG) {
            return
                AztecTypes.AztecAsset({
                    id: _assetId - VIRTUAL_ASSET_ID_FLAG,
                    erc20Address: address(0),
                    assetType: AztecTypes.AztecAssetType.VIRTUAL
                });
        }

        if (_assetId > 0) {
            return
                AztecTypes.AztecAsset({
                    id: _assetId,
                    erc20Address: ROLLUP_PROCESSOR.getSupportedAsset(_assetId),
                    assetType: AztecTypes.AztecAssetType.ERC20
                });
        }

        return AztecTypes.AztecAsset({id: 0, erc20Address: address(0), assetType: AztecTypes.AztecAssetType.ETH});
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

// @dev For documentation of the functions within this interface see RollupProcessor contract
interface IRollupProcessor {
    /*----------------------------------------
    EVENTS
    ----------------------------------------*/
    event OffchainData(uint256 indexed rollupId, uint256 chunk, uint256 totalChunks, address sender);
    event RollupProcessed(uint256 indexed rollupId, bytes32[] nextExpectedDefiHashes, address sender);
    event DefiBridgeProcessed(
        uint256 indexed encodedBridgeCallData,
        uint256 indexed nonce,
        uint256 totalInputValue,
        uint256 totalOutputValueA,
        uint256 totalOutputValueB,
        bool result,
        bytes errorReason
    );
    event AsyncDefiBridgeProcessed(
        uint256 indexed encodedBridgeCallData,
        uint256 indexed nonce,
        uint256 totalInputValue
    );
    event Deposit(uint256 indexed assetId, address indexed depositorAddress, uint256 depositValue);
    event WithdrawError(bytes errorReason);
    event AssetAdded(uint256 indexed assetId, address indexed assetAddress, uint256 assetGasLimit);
    event BridgeAdded(uint256 indexed bridgeAddressId, address indexed bridgeAddress, uint256 bridgeGasLimit);
    event RollupProviderUpdated(address indexed providerAddress, bool valid);
    event VerifierUpdated(address indexed verifierAddress);
    event Paused(address account);
    event Unpaused(address account);

    /*----------------------------------------
      MUTATING FUNCTIONS
      ----------------------------------------*/

    function pause() external;

    function unpause() external;

    function setRollupProvider(address _provider, bool _valid) external;

    function setVerifier(address _verifier) external;

    function setAllowThirdPartyContracts(bool _allowThirdPartyContracts) external;

    function setDefiBridgeProxy(address _defiBridgeProxy) external;

    function setSupportedAsset(address _token, uint256 _gasLimit) external;

    function setSupportedBridge(address _bridge, uint256 _gasLimit) external;

    function processRollup(bytes calldata _encodedProofData, bytes calldata _signatures) external;

    function receiveEthFromBridge(uint256 _interactionNonce) external payable;

    function approveProof(bytes32 _proofHash) external;

    function depositPendingFunds(
        uint256 _assetId,
        uint256 _amount,
        address _owner,
        bytes32 _proofHash
    ) external payable;

    function offchainData(
        uint256 _rollupId,
        uint256 _chunk,
        uint256 _totalChunks,
        bytes calldata _offchainTxData
    ) external;

    function processAsyncDefiInteraction(uint256 _interactionNonce) external returns (bool);

    /*----------------------------------------
      NON-MUTATING FUNCTIONS
      ----------------------------------------*/

    function rollupStateHash() external view returns (bytes32);

    function userPendingDeposits(uint256 _assetId, address _user) external view returns (uint256);

    function defiBridgeProxy() external view returns (address);

    function prevDefiInteractionsHash() external view returns (bytes32);

    function paused() external view returns (bool);

    function verifier() external view returns (address);

    function getDataSize() external view returns (uint256);

    function getPendingDefiInteractionHashesLength() external view returns (uint256);

    function getDefiInteractionHashesLength() external view returns (uint256);

    function getAsyncDefiInteractionHashesLength() external view returns (uint256);

    function getSupportedBridge(uint256 _bridgeAddressId) external view returns (address);

    function getSupportedBridgesLength() external view returns (uint256);

    function getSupportedAssetsLength() external view returns (uint256);

    function getSupportedAsset(uint256 _assetId) external view returns (address);

    function getEscapeHatchStatus() external view returns (bool, uint256);

    function assetGasLimits(uint256 _bridgeAddressId) external view returns (uint256);

    function bridgeGasLimits(uint256 _bridgeAddressId) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec.
pragma solidity >=0.8.4;

import {IDefiBridge} from "../../aztec/interfaces/IDefiBridge.sol";
import {ISubsidy} from "../../aztec/interfaces/ISubsidy.sol";
import {AztecTypes} from "../../aztec/libraries/AztecTypes.sol";
import {ErrorLib} from "./ErrorLib.sol";

/**
 * @title BridgeBase
 * @notice A base that bridges can be built upon which imports a limited set of features
 * @dev Reverts `convert` with missing implementation, and `finalise` with async disabled
 * @author Lasse Herskind
 */
abstract contract BridgeBase is IDefiBridge {
    error MissingImplementation();

    ISubsidy public constant SUBSIDY = ISubsidy(0xABc30E831B5Cc173A9Ed5941714A7845c909e7fA);
    address public immutable ROLLUP_PROCESSOR;

    constructor(address _rollupProcessor) {
        ROLLUP_PROCESSOR = _rollupProcessor;
    }

    modifier onlyRollup() {
        if (msg.sender != ROLLUP_PROCESSOR) {
            revert ErrorLib.InvalidCaller();
        }
        _;
    }

    function convert(
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        uint256,
        uint256,
        uint64,
        address
    )
        external
        payable
        virtual
        override(IDefiBridge)
        returns (
            uint256,
            uint256,
            bool
        )
    {
        revert MissingImplementation();
    }

    function finalise(
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        uint256,
        uint64
    )
        external
        payable
        virtual
        override(IDefiBridge)
        returns (
            uint256,
            uint256,
            bool
        )
    {
        revert ErrorLib.AsyncDisabled();
    }

    /**
     * @notice Computes the criteria that is passed on to the subsidy contract when claiming
     * @dev Should be overridden by bridge implementation if intended to limit subsidy.
     * @return The criteria to be passed along
     */
    function computeCriteria(
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        uint64
    ) public view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

// @dev documentation of this interface is in its implementation (Subsidy contract)
interface ISubsidy {
    /**
     * @notice Container for Subsidy related information
     * @member available Amount of ETH remaining to be paid out
     * @member gasUsage Amount of gas the interaction consumes (used to define max possible payout)
     * @member minGasPerMinute Minimum amount of gas per minute the subsidizer has to subsidize
     * @member gasPerMinute Amount of gas per minute the subsidizer is willing to subsidize
     * @member lastUpdated Last time subsidy was paid out or funded (if not subsidy was yet claimed after funding)
     */
    struct Subsidy {
        uint128 available;
        uint32 gasUsage;
        uint32 minGasPerMinute;
        uint32 gasPerMinute;
        uint32 lastUpdated;
    }

    function setGasUsageAndMinGasPerMinute(
        uint256 _criteria,
        uint32 _gasUsage,
        uint32 _minGasPerMinute
    ) external;

    function setGasUsageAndMinGasPerMinute(
        uint256[] calldata _criteria,
        uint32[] calldata _gasUsage,
        uint32[] calldata _minGasPerMinute
    ) external;

    function registerBeneficiary(address _beneficiary) external;

    function subsidize(
        address _bridge,
        uint256 _criteria,
        uint32 _gasPerMinute
    ) external payable;

    function topUp(address _bridge, uint256 _criteria) external payable;

    function claimSubsidy(uint256 _criteria, address _beneficiary) external returns (uint256);

    function withdraw(address _beneficiary) external returns (uint256);

    // solhint-disable-next-line
    function MIN_SUBSIDY_VALUE() external view returns (uint256);

    function claimableAmount(address _beneficiary) external view returns (uint256);

    function isRegistered(address _beneficiary) external view returns (bool);

    function getSubsidy(address _bridge, uint256 _criteria) external view returns (Subsidy memory);

    function getAccumulatedSubsidyAmount(address _bridge, uint256 _criteria) external view returns (uint256);
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

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

import {AztecTypes} from "../libraries/AztecTypes.sol";

interface IDefiBridge {
    /**
     * @notice A function which converts input assets to output assets.
     * @param _inputAssetA A struct detailing the first input asset
     * @param _inputAssetB A struct detailing the second input asset
     * @param _outputAssetA A struct detailing the first output asset
     * @param _outputAssetB A struct detailing the second output asset
     * @param _totalInputValue An amount of input assets transferred to the bridge (Note: "total" is in the name
     *                         because the value can represent summed/aggregated token amounts of users actions on L2)
     * @param _interactionNonce A globally unique identifier of this interaction/`convert(...)` call.
     * @param _auxData Bridge specific data to be passed into the bridge contract (e.g. slippage, nftID etc.)
     * @return outputValueA An amount of `_outputAssetA` returned from this interaction.
     * @return outputValueB An amount of `_outputAssetB` returned from this interaction.
     * @return isAsync A flag indicating if the interaction is async.
     * @dev This function is called from the RollupProcessor contract via the DefiBridgeProxy. Before this function is
     *      called _RollupProcessor_ contract will have sent you all the assets defined by the input params. This
     *      function is expected to convert input assets to output assets (e.g. on Uniswap) and return the amounts
     *      of output assets to be received by the _RollupProcessor_. If output assets are ERC20 tokens the bridge has
     *      to _RollupProcessor_ as a spender before the interaction is finished. If some of the output assets is ETH
     *      it has to be sent to _RollupProcessor_ via the `receiveEthFromBridge(uint256 _interactionNonce)` method
     *      inside before the `convert(...)` function call finishes.
     * @dev If there are two input assets, equal amounts of both assets will be transferred to the bridge before this
     *      method is called.
     * @dev **BOTH** output assets could be virtual but since their `assetId` is currently assigned as
     *      `_interactionNonce` it would simply mean that more of the same virtual asset is minted.
     * @dev If this interaction is async the function has to return `(0,0 true)`. Async interaction will be finalised at
     *      a later time and its output assets will be returned in a `IDefiBridge.finalise(...)` call.
     **/
    function convert(
        AztecTypes.AztecAsset calldata _inputAssetA,
        AztecTypes.AztecAsset calldata _inputAssetB,
        AztecTypes.AztecAsset calldata _outputAssetA,
        AztecTypes.AztecAsset calldata _outputAssetB,
        uint256 _totalInputValue,
        uint256 _interactionNonce,
        uint64 _auxData,
        address _rollupBeneficiary
    )
        external
        payable
        returns (
            uint256 outputValueA,
            uint256 outputValueB,
            bool isAsync
        );

    /**
     * @notice A function that finalises asynchronous interaction.
     * @param _inputAssetA A struct detailing the first input asset
     * @param _inputAssetB A struct detailing the second input asset
     * @param _outputAssetA A struct detailing the first output asset
     * @param _outputAssetB A struct detailing the second output asset
     * @param _interactionNonce A globally unique identifier of this interaction/`convert(...)` call.
     * @param _auxData Bridge specific data to be passed into the bridge contract (e.g. slippage, nftID etc.)
     * @return outputValueA An amount of `_outputAssetA` returned from this interaction.
     * @return outputValueB An amount of `_outputAssetB` returned from this interaction.
     * @dev This function should use the `BridgeBase.onlyRollup()` modifier to ensure it can only be called from
     *      the `RollupProcessor.processAsyncDefiInteraction(uint256 _interactionNonce)` method.
     **/
    function finalise(
        AztecTypes.AztecAsset calldata _inputAssetA,
        AztecTypes.AztecAsset calldata _inputAssetB,
        AztecTypes.AztecAsset calldata _outputAssetA,
        AztecTypes.AztecAsset calldata _outputAssetB,
        uint256 _interactionNonce,
        uint64 _auxData
    )
        external
        payable
        returns (
            uint256 outputValueA,
            uint256 outputValueB,
            bool interactionComplete
        );
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec.
pragma solidity >=0.8.4;

library ErrorLib {
    error InvalidCaller();

    error InvalidInput();
    error InvalidInputA();
    error InvalidInputB();
    error InvalidOutputA();
    error InvalidOutputB();
    error InvalidInputAmount();
    error InvalidAuxData();

    error ApproveFailed(address token);
    error TransferFailed(address token);

    error InvalidNonce();
    error AsyncDisabled();
}