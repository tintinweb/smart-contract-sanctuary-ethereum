// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

import { VRFV2WrapperConsumerBase } from './VRFV2WrapperConsumerBase.sol';
import { GovernedContract } from './GovernedContract.sol';
import { StorageBase } from './StorageBase.sol';
import { Ownable } from './Ownable.sol';

import { IMetadataGovernedProxy } from './interfaces/IMetadataGovernedProxy.sol';
import { IGovernedContract } from './interfaces/IGovernedContract.sol';
import { IMetadataStorage } from './interfaces/IMetadataStorage.sol';
import { IERC20 } from './interfaces/IERC20.sol';

contract MetadataStorage is StorageBase, IMetadataStorage {
    // Array of ids for uploaded batches of metadata hashes
    bytes4[] private batchIds;
    // Array of ids for randomness requests to Chainlink VRF service
    uint256[] private requestIds;
    // Mapping from batchIds to requestIds
    mapping(bytes4 => uint256) private requestIdsByBatchId;
    // Mapping from requestIds to batchIds
    mapping(uint256 => bytes4) private batchIdsByRequestId;
    // Mapping from batchIds to startingIndexes
    mapping(bytes4 => uint256) private startingIndexes;
    // Mapping from batchIds to metadataHashes
    mapping(bytes4 => bytes32[]) private metadataHashes;

    // Getter functions
    //
    function getRequestIdsCount() external view override returns (uint256 _count) {
        _count = requestIds.length;
    }

    function getRequestIdByIndex(uint256 _index)
        external
        view
        override
        returns (uint256 _requestId)
    {
        _requestId = requestIds[_index];
    }

    function getBatchIdsCount() external view override returns (uint256 _count) {
        _count = batchIds.length;
    }

    function getBatchIdByIndex(uint256 _index) external view override returns (bytes4 _batchId) {
        _batchId = batchIds[_index];
    }

    function getRequestIdByBatchId(bytes4 _batchId)
        external
        view
        override
        returns (uint256 _requestId)
    {
        _requestId = requestIdsByBatchId[_batchId];
    }

    function getBatchIdByRequestId(uint256 _requestId)
        external
        view
        override
        returns (bytes4 _batchId)
    {
        _batchId = batchIdsByRequestId[_requestId];
    }

    function getStartingIndex(bytes4 _batchId)
        external
        view
        override
        returns (uint256 _startingIndex)
    {
        _startingIndex = startingIndexes[_batchId];
    }

    function getMetadataHashesBatchLength(bytes4 _batchId)
        external
        view
        override
        returns (uint256 _length)
    {
        _length = metadataHashes[_batchId].length;
    }

    function getMetadataHashByIndex(bytes4 _batchId, uint256 _index)
        external
        view
        override
        returns (bytes32 _metadataHash)
    {
        _metadataHash = metadataHashes[_batchId][_index];
    }

    // Setter functions
    //
    function pushRequestId(uint256 _requestId) external override requireOwner {
        requestIds.push(_requestId);
    }

    function popRequestId() external override requireOwner {
        requestIds.pop();
    }

    function setRequestIdAtIndex(uint256 _requestId, uint256 index) external override requireOwner {
        requestIds[index] = _requestId;
    }

    function pushBatchId(bytes4 _batchId) external override requireOwner {
        batchIds.push(_batchId);
    }

    function popBatchId() external override requireOwner {
        batchIds.pop();
    }

    function setBatchIdAtIndex(bytes4 _batchId, uint256 index) external override requireOwner {
        batchIds[index] = _batchId;
    }

    function setRequestIdByBatchId(uint256 _requestId, bytes4 _batchId)
        external
        override
        requireOwner
    {
        requestIdsByBatchId[_batchId] = _requestId;
    }

    function setBatchIdByRequestId(bytes4 _batchId, uint256 _requestId)
        external
        override
        requireOwner
    {
        batchIdsByRequestId[_requestId] = _batchId;
    }

    function setStartingIndex(bytes4 _batchId, uint256 _startingIndex)
        external
        override
        requireOwner
    {
        startingIndexes[_batchId] = _startingIndex;
    }

    function setMetadataHashesBatch(bytes4 _batchId, bytes32[] calldata _metadataHashes)
        external
        override
        requireOwner
    {
        metadataHashes[_batchId] = _metadataHashes;
    }

    function pushMetadataHash(bytes4 _batchId, bytes32 _metadataHash)
        external
        override
        requireOwner
    {
        metadataHashes[_batchId].push(_metadataHash);
    }

    function popMetadataHash(bytes4 _batchId) external override requireOwner {
        metadataHashes[_batchId].pop();
    }

    function setMetadataHashAtIndex(
        bytes32 _metadataHash,
        bytes4 _batchId,
        uint256 index
    ) external override requireOwner {
        metadataHashes[_batchId][index] = _metadataHash;
    }
}

contract Metadata is VRFV2WrapperConsumerBase, GovernedContract, Ownable {
    // Data for migration
    //---------------------------------
    MetadataStorage public _storage;
    //---------------------------------

    uint32 public callbackGasLimit = 400000;
    uint16 public requestConfirmations = 12;
    uint32 public numWords = 1;

    constructor(
        address _proxy,
        address _link,
        address _vrfV2Wrapper
    ) VRFV2WrapperConsumerBase(_link, _vrfV2Wrapper) GovernedContract(_proxy) {
        // Deploy Metadata storage
        _storage = new MetadataStorage();
        // Initialize proxy contract
        IMetadataGovernedProxy(_proxy).initialize(address(this));
    }

    // Governance functions
    //
    // This function allows to set sporkProxy address after deployment in order to enable upgrades
    function setSporkProxy(address payable _sporkProxy) external onlyOwner {
        IMetadataGovernedProxy(proxy).setSporkProxy(_sporkProxy);
    }

    // This function is called in order to upgrade to a new implementation
    function destroy(IGovernedContract _newImpl) external requireProxy {
        // Transfer _storage ownership to new implementation
        _storage.setOwner(_newImpl);
        // Transfer LINK token balance to new implementation
        LINK.transfer(address(_newImpl), LINK.balanceOf(address(this)));
        _destroy(_newImpl);
    }

    // This function would be called on the new implementation if necessary for the upgrade
    function migrate(IGovernedContract _oldImpl) external requireProxy {
        _migrate(_oldImpl);
    }

    function getMetadataHash(uint256 tokenId) external view returns (bytes32 metadataHash) {
        require(tokenId > 0, 'Metadata: invalid tokenId');
        uint256 hashesCount = 0;
        bytes4 batchId;
        uint256 batchLength;
        for (uint256 i = 0; i < _storage.getBatchIdsCount(); i++) {
            batchId = _storage.getBatchIdByIndex(i);
            batchLength = _storage.getMetadataHashesBatchLength(batchId);
            if (hashesCount + batchLength >= tokenId) {
                break;
            } else {
                require(
                    i < _storage.getBatchIdsCount() - 1, // Revert if total hashes count is smaller than tokenId
                    'Metadata: no metadata hash for tokenId'
                );
                hashesCount += batchLength;
            }
        }
        uint256 startingIndex = _storage.getStartingIndex(batchId);
        require(
            startingIndex > 0,
            'Metadata: metadata hash has not been attributed yet for tokenId'
        );
        metadataHash = _storage.getMetadataHashByIndex(
            batchId,
            (startingIndex + tokenId - hashesCount) % batchLength
        );
    }

    // Owner-protected functions
    //
    function uploadMetadataHashes(bytes4 batchId, bytes32[] calldata metadataHashes)
        external
        onlyOwner
    {
        // Store batchId
        _storage.pushBatchId(batchId);
        // Store metadata hashes
        _storage.setMetadataHashesBatch(batchId, metadataHashes);
        // Emit MetadataHashesUploaded event
        IMetadataGovernedProxy(proxy).emitMetadataHashesUploaded(batchId, metadataHashes.length);
    }

    // This function is called once
    function requestRandomnessForStartingIndex(bytes4 batchId)
        public
        onlyOwner
        returns (uint256 requestId)
    {
        // Make sure no request has been made yet for batchId
        require(
            _storage.getRequestIdByBatchId(batchId) == 0,
            'Metadata: randomness already requested for metadata hashes batch'
        );
        // Make sure LINK balance is enough to pay for request
        require(
            VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit) <= LINK.balanceOf(address(this)),
            'Metadata: LINK balance is too low'
        );
        /**
         * See: https://docs.chain.link/vrf/v2/direct-funding/#explanation
         *
         * requestConfirmations: The number of block confirmations the VRF service will wait to respond.
         * callbackGasLimit: The maximum amount of gas to pay for completing the callback VRF function.
         * numWords: The number of random numbers to request.
         */
        requestId = requestRandomness(callbackGasLimit, requestConfirmations, numWords);
        // Store requestId
        _storage.pushRequestId(requestId);
        // Store batchId and requestId
        _storage.setRequestIdByBatchId(requestId, batchId);
        _storage.setBatchIdByRequestId(batchId, requestId);
    }

    function setCallbackGasLimit(uint32 _callbackGasLimit) external onlyOwner {
        callbackGasLimit = _callbackGasLimit;
    }

    function setRequestConfirmations(uint16 _requestConfirmations) external onlyOwner {
        requestConfirmations = _requestConfirmations;
    }

    function setNumWords(uint32 _numWords) external onlyOwner {
        numWords = _numWords;
    }

    function transferERC20(
        address _erc20TokenAddress,
        address _recipient,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_erc20TokenAddress).transfer(_recipient, _amount);
    }

    // fulfillRandomWords callback implementation
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        // Get batchId
        bytes4 batchId = _storage.getBatchIdByRequestId(requestId);
        // Make sure starting index has not been set for batch
        require(
            _storage.getStartingIndex(batchId) == 0,
            'Metadata: starting index already set for metadata hashes batch'
        );
        uint256 batchLength = _storage.getMetadataHashesBatchLength(batchId);
        // Set starting index for batch
        uint256 startingIndex = randomWords[0] % batchLength;
        if (startingIndex == 0) {
            startingIndex = batchLength;
        }
        _storage.setStartingIndex(batchId, startingIndex);
        // Emit StartingIndexSet event
        IMetadataGovernedProxy(proxy).emitStartingIndexSet(batchId, startingIndex);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IVRFV2Wrapper {
    /**
     * @return the request ID of the most recent VRF V2 request made by this wrapper. This should only
     * be relied option within the same transaction that the request was made.
     */
    function lastRequestId() external view returns (uint256);

    /**
     * @notice Calculates the price of a VRF request with the given callbackGasLimit at the current
     * @notice block.
     *
     * @dev This function relies on the transaction gas price which is not automatically set during
     * @dev simulation. To estimate the price at a specific gas price, use the estimatePrice function.
     *
     * @param _callbackGasLimit is the gas limit used to estimate the price.
     */
    function calculateRequestPrice(uint32 _callbackGasLimit) external view returns (uint256);

    /**
     * @notice Estimates the price of a VRF request with a specific gas limit and gas price.
     *
     * @dev This is a convenience function that can be called in simulation to better understand
     * @dev pricing.
     *
     * @param _callbackGasLimit is the gas limit used to estimate the price.
     * @param _requestGasPriceWei is the gas price in wei used for the estimation.
     */
    function estimateRequestPrice(uint32 _callbackGasLimit, uint256 _requestGasPriceWei)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

interface IMetadataStorage {
    // Getter functions
    //
    function getRequestIdsCount() external view returns (uint256);

    function getRequestIdByIndex(uint256 _index) external view returns (uint256);

    function getBatchIdsCount() external view returns (uint256);

    function getBatchIdByIndex(uint256 _index) external view returns (bytes4);

    function getRequestIdByBatchId(bytes4 _batchId) external view returns (uint256);

    function getBatchIdByRequestId(uint256 _requestId) external view returns (bytes4);

    function getStartingIndex(bytes4 _batchId) external view returns (uint256);

    function getMetadataHashesBatchLength(bytes4 _batchId) external view returns (uint256);

    function getMetadataHashByIndex(bytes4 _batchId, uint256 _index)
        external
        view
        returns (bytes32);

    // Setter functions
    //
    function pushRequestId(uint256 _requestId) external;

    function popRequestId() external;

    function setRequestIdAtIndex(uint256 _requestId, uint256 index) external;

    function pushBatchId(bytes4 _batchId) external;

    function popBatchId() external;

    function setBatchIdAtIndex(bytes4 _batchId, uint256 index) external;

    function setRequestIdByBatchId(uint256 _requestId, bytes4 _batchId) external;

    function setBatchIdByRequestId(bytes4 _batchId, uint256 _requestId) external;

    function setStartingIndex(bytes4 _batchId, uint256 _startingIndex) external;

    function setMetadataHashesBatch(bytes4 _batchId, bytes32[] calldata _metadataHashes) external;

    function pushMetadataHash(bytes4 _batchId, bytes32 _metadataHash) external;

    function popMetadataHash(bytes4 _batchId) external;

    function setMetadataHashAtIndex(
        bytes32 _metadataHash,
        bytes4 _batchId,
        uint256 index
    ) external;
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

interface IMetadataGovernedProxy {
    function initialize(address _implementation) external;

    function setSporkProxy(address payable _sporkProxy) external;

    function emitMetadataHashesUploaded(bytes4 batchId, uint256 numItems) external;

    function emitStartingIndexSet(bytes4 batchId, uint256 startingIndex) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface ILinkToken {
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    function approve(address spender, uint256 value) external returns (bool success);

    function balanceOf(address owner) external view returns (uint256 balance);

    function decimals() external view returns (uint8 decimalPlaces);

    function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

    function increaseApproval(address spender, uint256 subtractedValue) external;

    function name() external view returns (string memory tokenName);

    function symbol() external view returns (string memory tokenSymbol);

    function totalSupply() external view returns (uint256 totalTokensIssued);

    function transfer(address to, uint256 value) external returns (bool success);

    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

// Energi Governance system is a fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

pragma solidity 0.8.0;

/**
 * Genesis version of GovernedContract interface.
 *
 * Base Consensus interface for upgradable contracts.
 * Unlike common approach, the implementation is NOT expected to be
 * called through delegatecall() to minimize risks of shared storage.
 *
 * NOTE: it MUST NOT change after blockchain launch!
 */

interface IGovernedContract {
    // Return actual proxy address for secure validation
    function proxy() external view returns (address);

    // It must check that the caller is the proxy
    // and copy all required data from the old address.
    function migrate(IGovernedContract _oldImpl) external;

    // It must check that the caller is the proxy
    // and self destruct to the new address.
    function destroy(IGovernedContract _newImpl) external;

    // function () external payable; // This line (from original Energi IGovernedContract) is commented because it
    // makes truffle migrations fail
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

pragma solidity 0.8.0;

import { ILinkToken } from './interfaces/ILinkToken.sol';
import { IVRFV2Wrapper } from './interfaces/IVRFV2Wrapper.sol';

/** *******************************************************************************
 * @notice Interface for contracts using VRF randomness through the VRF V2 wrapper
 * ********************************************************************************
 * @dev PURPOSE
 *
 * @dev Create VRF V2 requests without the need for subscription management. Rather than creating
 * @dev and funding a VRF V2 subscription, a user can use this wrapper to create one off requests,
 * @dev paying up front rather than at fulfillment.
 *
 * @dev Since the price is determined using the gas price of the request transaction rather than
 * @dev the fulfillment transaction, the wrapper charges an additional premium on callback gas
 * @dev usage, in addition to some extra overhead costs associated with the VRFV2Wrapper contract.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFV2WrapperConsumerBase. The consumer must be funded
 * @dev with enough LINK to make the request, otherwise requests will revert. To request randomness,
 * @dev call the 'requestRandomness' function with the desired VRF parameters. This function handles
 * @dev paying for the request based on the current pricing.
 *
 * @dev Consumers must implement the fullfillRandomWords function, which will be called during
 * @dev fulfillment with the randomness result.
 */
abstract contract VRFV2WrapperConsumerBase {
    ILinkToken internal immutable LINK;
    IVRFV2Wrapper internal immutable VRF_V2_WRAPPER;

    /**
     * @param _link is the address of LinkToken
     * @param _vrfV2Wrapper is the address of the VRFV2Wrapper contract
     */
    constructor(address _link, address _vrfV2Wrapper) {
        LINK = ILinkToken(_link);
        VRF_V2_WRAPPER = IVRFV2Wrapper(_vrfV2Wrapper);
    }

    /**
     * @dev Requests randomness from the VRF V2 wrapper.
     *
     * @param _callbackGasLimit is the gas limit that should be used when calling the consumer's
     *        fulfillRandomWords function.
     * @param _requestConfirmations is the number of confirmations to wait before fulfilling the
     *        request. A higher number of confirmations increases security by reducing the likelihood
     *        that a chain re-org changes a published randomness outcome.
     * @param _numWords is the number of random words to request.
     *
     * @return requestId is the VRF V2 request ID of the newly created randomness request.
     */
    function requestRandomness(
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint32 _numWords
    ) internal returns (uint256 requestId) {
        LINK.transferAndCall(
            address(VRF_V2_WRAPPER),
            VRF_V2_WRAPPER.calculateRequestPrice(_callbackGasLimit),
            abi.encode(_callbackGasLimit, _requestConfirmations, _numWords)
        );
        return VRF_V2_WRAPPER.lastRequestId();
    }

    /**
     * @notice fulfillRandomWords handles the VRF V2 wrapper response. The consuming contract must
     * @notice implement it.
     *
     * @param _requestId is the VRF V2 request ID.
     * @param _randomWords is the randomness result.
     */
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal virtual;

    function rawFulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) external {
        require(msg.sender == address(VRF_V2_WRAPPER), 'only VRF V2 wrapper can fulfill');
        fulfillRandomWords(_requestId, _randomWords);
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

import { IGovernedContract } from './interfaces/IGovernedContract.sol';

/**
 * Base for contract storage (SC-14).
 *
 * NOTE: it MUST NOT change after blockchain launch!
 */

contract StorageBase {
    address payable internal owner;

    modifier requireOwner() {
        require(msg.sender == address(owner), 'Not owner!');
        _;
    }

    constructor() {
        owner = payable(msg.sender);
    }

    function setOwner(IGovernedContract _newOwner) external requireOwner {
        owner = payable(address(_newOwner));
    }

    function kill() external requireOwner {
        selfdestruct(payable(msg.sender));
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of 'user permissions'.
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, 'Ownable: Not owner');
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), 'Ownable: Zero address not allowed');
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

// Energi Governance system is a fundamental part of Energi Core.

pragma solidity 0.8.0;

import { IGovernedContract } from './interfaces/IGovernedContract.sol';

/**
 * Genesis version of GovernedContract common base.
 *
 * Base Consensus interface for upgradable contracts.
 * Unlike common approach, the implementation is NOT expected to be
 * called through delegatecall() to minimize risks of shared storage.
 *
 * NOTE: it MUST NOT change after blockchain launch!
 */
contract GovernedContract {
    address public proxy;

    constructor(address _proxy) {
        proxy = _proxy;
    }

    modifier requireProxy() {
        require(msg.sender == proxy, 'Governed Contract: Not proxy');
        _;
    }

    function getProxy() internal view returns (address _proxy) {
        _proxy = proxy;
    }

    // solium-disable-next-line no-empty-blocks
    function _migrate(IGovernedContract) internal {}

    function _destroy(IGovernedContract _newImpl) internal {
        selfdestruct(payable(address(_newImpl)));
    }

    function _callerAddress() internal view returns (address payable) {
        if (msg.sender == proxy) {
            // This is guarantee of the GovernedProxy
            // solium-disable-next-line security/no-tx-origin
            return payable(tx.origin);
        } else {
            return payable(msg.sender);
        }
    }
}