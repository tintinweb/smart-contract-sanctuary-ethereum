/**
 *Submitted for verification at Etherscan.io on 2023-02-04
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.4;

interface ArbitrumBridge {
    /**
     * @notice Put a message in the L2 inbox that can be reexecuted for some fixed amount of time if it reverts
     * @dev all msg.value will deposited to callValueRefundAddress on L2
     * @dev Gas limit and maxFeePerGas should not be set to 1 as that is used to trigger the RetryableData error
     * @param to destination L2 contract address
     * @param l2CallValue call value for retryable L2 message
     * @param maxSubmissionCost Max gas deducted from user's L2 balance to cover base submission fee
     * @param excessFeeRefundAddress gasLimit x maxFeePerGas - execution cost gets credited here on L2 balance
     * @param callValueRefundAddress l2Callvalue gets credited here on L2 if retryable txn times out or gets cancelled
     * @param gasLimit Max gas deducted from user's L2 balance to cover L2 execution. Should not be set to 1 (magic value used to trigger the RetryableData error)
     * @param maxFeePerGas price bid for L2 execution. Should not be set to 1 (magic value used to trigger the RetryableData error)
     * @param data ABI encoded data of L2 message
     * @return unique message number of the retryable transaction
     */
    function createRetryableTicket(
        address to,
        uint256 l2CallValue,
        uint256 maxSubmissionCost,
        address excessFeeRefundAddress,
        address callValueRefundAddress,
        uint256 gasLimit,
        uint256 maxFeePerGas,
        bytes calldata data
    ) external payable returns (uint256);

    /**
     * @notice Get the L1 fee for submitting a retryable
     * @dev This fee can be paid by funds already in the L2 aliased address or by the current message value
     * @dev This formula may change in the future, to future proof your code query this method instead of inlining!!
     * @param dataLength The length of the retryable's calldata, in bytes
     * @param baseFee The block basefee when the retryable is included in the chain, if 0 current block.basefee will be used
     */
    function calculateRetryableSubmissionFee(uint256 dataLength, uint256 baseFee) external view returns (uint256);
}

interface OptimismBridge {
    function sendMessage(address target, bytes calldata message, uint32 gasLimit) external;
}

interface PolygonBridge {
    function sendMessageToChild(address receiver, bytes calldata data) external;
}

interface ArbitraryMessageBridge {
    function maxGasPerTx() external view returns (uint256);
    function requireToPassMessage(address target, bytes calldata data, uint256 gas) external returns (bytes32);
}

/// @title Unified interface for sending messages from Ethereum to other chains and rollups
/// @author zefram.eth
/// @notice Enables sending messages from Ethereum to other chains via a single interface.
/// @dev This bridge is immutable, so other contracts using it should have the ability to
/// update the bridge address in order to upgrade to newer versions of the bridge in the future
/// and support more chains.
interface IUniversalBridge {
    function CHAINID_ARBITRUM() external pure returns (uint256);
    function BRIDGE_ARBITRUM() external pure returns (ArbitrumBridge);
    function CHAINID_OPTIMISM() external pure returns (uint256);
    function BRIDGE_OPTIMISM() external pure returns (OptimismBridge);
    function CHAINID_POLYGON() external pure returns (uint256);
    function BRIDGE_POLYGON() external pure returns (PolygonBridge);
    function CHAINID_BSC() external pure returns (uint256);
    function BRIDGE_BSC() external pure returns (ArbitraryMessageBridge);
    function CHAINID_GNOSIS() external pure returns (uint256);
    function BRIDGE_GNOSIS() external pure returns (ArbitraryMessageBridge);

    /// @notice Sends message to recipient on target chain with the given calldata.
    /// @dev For calls to Arbitrum, any extra msg.value above what getRequiredMessageValue() returns will
    /// be used as the msg.value of the L2 call to the recipient.
    /// @param chainId the target chain's ID
    /// @param recipient the message recipient on the target chain
    /// @param data the calldata the recipient will be called with
    /// @param gasLimit the gas limit of the call to the recipient
    function sendMessage(uint256 chainId, address recipient, bytes calldata data, uint256 gasLimit) external payable;

    /// @notice Sends message to recipient on target chain with the given calldata.
    /// @dev For calls to Arbitrum, any extra msg.value above what getRequiredMessageValue() returns will
    /// be used as the msg.value of the L2 call to the recipient.
    /// @param chainId the target chain's ID
    /// @param recipient the message recipient on the target chain
    /// @param data the calldata the recipient will be called with
    /// @param gasLimit the gas limit of the call to the recipient
    /// @param maxFeePerGas the max gas price used, only relevant for some chains (e.g. Arbitrum)
    function sendMessage(
        uint256 chainId,
        address recipient,
        bytes calldata data,
        uint256 gasLimit,
        uint256 maxFeePerGas
    ) external payable;

    /// @notice Computes the minimum msg.value needed when calling sendMessage()
    /// @param chainId the target chain's ID
    /// @param dataLength the length of the calldata the recipient will be called with, in bytes
    /// @param gasLimit the gas limit of the call to the recipient
    /// @return the minimum msg.value required
    function getRequiredMessageValue(uint256 chainId, uint256 dataLength, uint256 gasLimit)
        external
        view
        returns (uint256);

    /// @notice Computes the minimum msg.value needed when calling sendMessage()
    /// @param chainId the target chain's ID
    /// @param dataLength the length of the calldata the recipient will be called with, in bytes
    /// @param gasLimit the gas limit of the call to the recipient
    /// @param maxFeePerGas the max gas price used, only relevant for some chains (e.g. Arbitrum)
    /// @return the minimum msg.value required
    function getRequiredMessageValue(uint256 chainId, uint256 dataLength, uint256 gasLimit, uint256 maxFeePerGas)
        external
        view
        returns (uint256);
}

/// @title Unified interface for sending messages from Ethereum to other chains and rollups
/// @author zefram.eth
/// @notice Enables sending messages from Ethereum to other chains via a single interface.
/// @dev This bridge is immutable, so other contracts using it should have the ability to
/// update the bridge address in order to upgrade to newer versions of the bridge in the future
/// and support more chains.
contract UniversalBridge is IUniversalBridge {
    /// -----------------------------------------------------------------------
    /// Constants
    /// -----------------------------------------------------------------------

    uint256 internal constant DEFAULT_MAX_FEE_PER_GAS = 0.1 gwei;

    uint256 public constant override CHAINID_ARBITRUM = 42161;
    ArbitrumBridge public constant override BRIDGE_ARBITRUM = ArbitrumBridge(0x4Dbd4fc535Ac27206064B68FfCf827b0A60BAB3f);

    uint256 public constant override CHAINID_OPTIMISM = 10;
    OptimismBridge public constant override BRIDGE_OPTIMISM = OptimismBridge(0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1);

    uint256 public constant override CHAINID_POLYGON = 137;
    PolygonBridge public constant override BRIDGE_POLYGON = PolygonBridge(0xfe5e5D361b2ad62c541bAb87C45a0B9B018389a2);

    uint256 public constant override CHAINID_BSC = 56;
    ArbitraryMessageBridge public constant override BRIDGE_BSC =
        ArbitraryMessageBridge(0x07955be2967B655Cf52751fCE7ccC8c61EA594e2);

    uint256 public constant override CHAINID_GNOSIS = 100;
    ArbitraryMessageBridge public constant override BRIDGE_GNOSIS =
        ArbitraryMessageBridge(0x4C36d2919e407f0Cc2Ee3c993ccF8ac26d9CE64e);

    /// -----------------------------------------------------------------------
    /// External functions
    /// -----------------------------------------------------------------------

    error UniversalBridge__GasLimitTooLarge();
    error UniversalBridge__ChainIdNotSupported();
    error UniversalBridge__MsgValueNotSupported();

    /// @inheritdoc IUniversalBridge
    function sendMessage(uint256 chainId, address recipient, bytes calldata data, uint256 gasLimit) external payable {
        _sendMessage(chainId, recipient, data, gasLimit, DEFAULT_MAX_FEE_PER_GAS);
    }

    /// @inheritdoc IUniversalBridge
    function sendMessage(
        uint256 chainId,
        address recipient,
        bytes calldata data,
        uint256 gasLimit,
        uint256 maxFeePerGas
    ) external payable {
        _sendMessage(chainId, recipient, data, gasLimit, maxFeePerGas);
    }

    /// @inheritdoc IUniversalBridge
    function getRequiredMessageValue(uint256 chainId, uint256 dataLength, uint256 gasLimit)
        external
        view
        override
        returns (uint256)
    {
        return _getRequiredMessageValue(chainId, dataLength, gasLimit, DEFAULT_MAX_FEE_PER_GAS);
    }

    /// @inheritdoc IUniversalBridge
    function getRequiredMessageValue(uint256 chainId, uint256 dataLength, uint256 gasLimit, uint256 maxFeePerGas)
        external
        view
        override
        returns (uint256)
    {
        return _getRequiredMessageValue(chainId, dataLength, gasLimit, maxFeePerGas);
    }

    /// -----------------------------------------------------------------------
    /// Internal helpers for sending message to different chains
    /// -----------------------------------------------------------------------

    function _sendMessage(
        uint256 chainId,
        address recipient,
        bytes calldata data,
        uint256 gasLimit,
        uint256 maxFeePerGas
    ) internal {
        if (chainId == CHAINID_ARBITRUM) _sendMessageArbitrum(recipient, data, gasLimit, maxFeePerGas);
        else if (chainId == CHAINID_OPTIMISM) _sendMessageOptimism(recipient, data, gasLimit);
        else if (chainId == CHAINID_POLYGON) _sendMessagePolygon(recipient, data);
        else if (chainId == CHAINID_BSC) _sendMessageAMB(BRIDGE_BSC, recipient, data, gasLimit);
        else if (chainId == CHAINID_GNOSIS) _sendMessageAMB(BRIDGE_GNOSIS, recipient, data, gasLimit);
        else revert UniversalBridge__ChainIdNotSupported();
    }

    function _getRequiredMessageValue(uint256 chainId, uint256 dataLength, uint256 gasLimit, uint256 maxFeePerGas)
        internal
        view
        returns (uint256)
    {
        if (chainId != CHAINID_ARBITRUM) {
            return 0;
        } else {
            uint256 submissionCost = BRIDGE_ARBITRUM.calculateRetryableSubmissionFee(dataLength, block.basefee);
            return gasLimit * maxFeePerGas + submissionCost;
        }
    }

    function _sendMessageArbitrum(address recipient, bytes calldata data, uint256 gasLimit, uint256 maxFeePerGas)
        internal
    {
        uint256 submissionCost = BRIDGE_ARBITRUM.calculateRetryableSubmissionFee(data.length, block.basefee);
        uint256 l2CallValue = msg.value - submissionCost - gasLimit * maxFeePerGas;
        BRIDGE_ARBITRUM.createRetryableTicket{value: msg.value}(
            recipient, l2CallValue, submissionCost, msg.sender, msg.sender, gasLimit, maxFeePerGas, data
        );
    }

    function _sendMessageOptimism(address recipient, bytes calldata data, uint256 gasLimit) internal {
        if (msg.value != 0) revert UniversalBridge__MsgValueNotSupported();
        if (gasLimit > type(uint32).max) revert UniversalBridge__GasLimitTooLarge();
        BRIDGE_OPTIMISM.sendMessage(recipient, data, uint32(gasLimit));
    }

    function _sendMessagePolygon(address recipient, bytes calldata data) internal {
        if (msg.value != 0) revert UniversalBridge__MsgValueNotSupported();
        BRIDGE_POLYGON.sendMessageToChild(recipient, data);
    }

    function _sendMessageAMB(ArbitraryMessageBridge bridge, address recipient, bytes calldata data, uint256 gasLimit)
        internal
    {
        if (msg.value != 0) revert UniversalBridge__MsgValueNotSupported();
        if (gasLimit > bridge.maxGasPerTx()) revert UniversalBridge__GasLimitTooLarge();
        bridge.requireToPassMessage(recipient, data, gasLimit);
    }
}